#include "bitwardenapi.h"

#include <QNetworkAccessManager>
#include <QNetworkRequest>
#include <QNetworkReply>
#include <QJsonDocument>
#include <QUrl>
#include <QDebug>
#include <QTcpSocket>
#include <QFile>
#include <QDir>

#include <sys/signal.h>

#include "cache-keys.h"
#include "cli-api-common-parts.h"

static const QString cacheKeyTempSends = "api_tempSends";

BitwardenApi::BitwardenApi(QObject *parent) : QObject(parent)
{

}

void BitwardenApi::getItem(const QString &id)
{
    sendRequest(apiUrl + "/object/item/" + id, [=](const auto &body, const auto &statusCode) {
        if (statusCode == 200) {
            auto document = QJsonDocument::fromJson(body).object()["data"].toObject();
            emit itemFetched(document);
        } else {
            emit itemFetchingFailed();
        }
    });
}

void BitwardenApi::isRunning()
{
    auto *socket = new QTcpSocket(this);
    socket->connectToHost(apiHost, apiPort);

    connect(socket, &QTcpSocket::connected, [=]() {
        emit isRunningResult(true);
        socket->disconnectFromHost();
        socket->deleteLater();
    });
    connect(socket, static_cast<void (QTcpSocket::*)(QAbstractSocket::SocketError)>(&QTcpSocket::error), [=](auto error) {
        Q_UNUSED(error);
        emit isRunningResult(false);
        socket->disconnectFromHost();
        socket->deleteLater();
    });
}

void BitwardenApi::killApi()
{
    QFile socketTable("/proc/net/tcp");
    if (!socketTable.exists()) {
        qDebug() << "TCP file not found";
        emit killingApiFailed();
        return;
    }

    if (!socketTable.open(QIODevice::ReadOnly | QIODevice::Text)) {
        qDebug() << "Cannot opent tcp file";
        emit killingApiFailed();
        return;
    }

    QTextStream stream(&socketTable);
    QString line;
    while (stream.readLineInto(&line)) {
        if (!line.contains("0100007F:1F97") || !line.contains("0A")) { // 127.0.0.1:8087 in hex, and 0A means listen
            continue;
        }
        const auto split = line.split(" ");
        bool ok;
        const auto inode = split[19].toInt(&ok);
        if (!ok) {
            qDebug() << "Failed parsing inode";
            emit killingApiFailed();
            return;
        }

        const QDir procDir("/proc");
        for (const auto &entry : procDir.entryList(QDir::Dirs | QDir::NoDotAndDotDot)) {
            bool ok;
            int pid = entry.toInt(&ok);
            if (!ok) {
                continue;
            }

            const QDir fdDir(QString("/proc/%1/fd").arg(pid));
            if (!fdDir.exists()) {
                continue;
            }

            for (const auto &fdInfo : fdDir.entryInfoList(QDir::NoDotAndDotDot | QDir::AllEntries)) {
                if (!fdInfo.isSymLink()) {
                    continue;
                }
                const auto linkTarget = fdInfo.symLinkTarget();
                if (!linkTarget.contains(QString("socket:[%1]").arg(inode))) {
                    continue;
                }

                qDebug() << "Found existing PID: " << pid;
                if(kill(pid, SIGTERM) != 0) {
                    qDebug() << "Failed killing";
                    emit killingApiFailed();
                } else {
                    emit killingApiSucceeded();
                }
                return;
            }
        }
    }

    qDebug() << "Could not find process to kill";
    emit killingApiFailed();
}

void BitwardenApi::getSends()
{
    sendRequest(apiUrl + "/list/object/send", [=](const auto &body, const auto &statusCode) {
        if (statusCode == 200) {
            auto document = QJsonDocument::fromJson(body).object()["data"].toObject()["data"].toArray();
            // the api does not return updated values
            const auto tempCreated = getTempSends();

            for (auto&& item : tempCreated) {
                document.append(item);
            }

            emit sendsResolved(document);
        } else {
            emit failedGettingSends();
        }
    });
}

void BitwardenApi::syncVault()
{
    sendRequest(Method::Post, apiUrl + "/sync", [=](const auto &body, const auto &statusCode) {
        Q_UNUSED(body);
        if (statusCode == 200) {
            runtimeCache->remove(cacheKeyItems);
            emit vaultSynced();
        } else {
            emit vaultSyncFailed();
        }
    });
}

void BitwardenApi::getItems()
{
    getItems(GetItemType::GetItems);
}

void BitwardenApi::getItems(GetItemType itemType)
{
    auto cache = runtimeCache->get(cacheKeyItems);
    if (!cache.isNull() && !cache.isEmpty()) {
        handleGetItems(runtimeCache->get(cacheKeyItems), itemType);
    } else {
        sendRequest(apiUrl + "/list/object/items", [=](const auto &body, const auto &statusCode) {
            if (statusCode == 200) {
                const auto document = QJsonDocument::fromJson(body).object()["data"].toObject()["data"].toArray();
                handleGetItems(QJsonDocument(document).toJson(), GetLogins);
            } else {
                emit failedGettingItems();
            }
        });
    }
}

void BitwardenApi::getLogins()
{
    getItems(GetItemType::GetLogins);
}

void BitwardenApi::getCards()
{
    getItems(GetItemType::GetCards);
}

void BitwardenApi::getNotes()
{
    getItems(GetItemType::GetNotes);
}

void BitwardenApi::getIdentities()
{
    getItems(GetItemType::GetIdentities);
}

void BitwardenApi::getServerUrl()
{
    sendRequest(apiUrl + "/status", [=](const auto &body, const auto &statusCode) {
        if (statusCode == 200) {
            auto url = QJsonDocument::fromJson(body).object()["data"].toObject()["template"].toObject()["serverUrl"].toString();
            if (url.isNull()) {
                url = "https://bitwarden.com";
            }
            emit serverUrlResolved(url);
        } else {
            emit serverUrlResolvingFailed();
        }
    });
}

void BitwardenApi::checkVaultUnlocked()
{
    sendRequest(apiUrl + "/status", [=](const auto &body, const auto &statusCode) {
        if (statusCode == 200) {
            auto unlocked = QJsonDocument::fromJson(body).object()["data"].toObject()["template"].toObject()["status"].toString() == "unlocked";
            emit vaultLockStatusResolved(unlocked);
        } else {
            emit vaultLockStatusResolved(false);
        }
    });
}

void BitwardenApi::generatePassword(bool lowercase, bool uppercase, bool numbers, bool special, bool avoidAmbiguous, int minimumNumbers, int minimumSpecial, int length)
{
    auto url = QString(apiUrl + "/generate?length=%1&minNumber=%2&minSpecial=%3").arg(length).arg(minimumNumbers).arg(minimumSpecial);
    if (lowercase) {
        url += "&lowercase=1";
    }
    if (uppercase) {
        url += "&uppercase=1";
    }
    if (numbers) {
        url += "&number=1";
    }
    if (special) {
        url += "&special=1";
    }
    if (avoidAmbiguous) {
        url += "&ambiguous=1";
    }

    sendRequest(url, [=](const auto &body, const auto &statusCode) {
        if (statusCode == 200) {
            const auto password = QJsonDocument::fromJson(body).object()["data"].toObject()["data"].toString();
            emit passwordGenerated(password);
        } else {
            emit generatingPasswordFailed();
        }
    });
}

void BitwardenApi::generatePassphrase(uint wordsCount, bool capitalize, bool includeNumber, const QString &separator)
{
    auto url = QString(apiUrl + "/generate?passphrase=1&words=%1&separator=%2").arg(wordsCount).arg(separator);
    if (capitalize) {
        url += "&capitalize=1";
    }
    if (includeNumber) {
        url += "&includeNumber=1";
    }

    sendRequest(url, [=](const auto &body, const auto &statusCode) {
        if (statusCode == 200) {
            const auto password = QJsonDocument::fromJson(body).object()["data"].toObject()["data"].toString();
            emit passphraseGenerated(password);
        } else {
            emit generatingPassphraseFailed();
        }
    });
}

void BitwardenApi::createFileSend(const QString &name, const QString &filePath, const uint &deletionDate, const uint &maximumAccessCount, const QString &password, const bool &hideEmail, const QString &privateNotes)
{
    auto json = createCommonCreateSendParts(name, deletionDate, maximumAccessCount, password, hideEmail, privateNotes);
    json["type"] = SendType::SendTypeFile;

    QJsonObject file;
    file["fileName"] = filePath;
    json["file"] = file;

    sendRequest(Method::Post, apiUrl + "/object/send", json, [=](const auto body, const auto statusCode) {
        Q_UNUSED(statusCode);
        const auto item = QJsonDocument::fromJson(body).object()["data"].toObject();
        addTempSend(item);
        const auto url = item["accessUrl"].toString();
        emit sendCreated(url);
    });
}

void BitwardenApi::createTextSend(const QString &name, const QString &text, const bool &hideText, const uint &deletionDate, const uint &maximumAccessCount, const QString &password, const bool &hideEmail, const QString &privateNotes)
{
    auto json = createCommonCreateSendParts(name, deletionDate, maximumAccessCount, password, hideEmail, privateNotes);
    json["type"] = SendType::SendTypeText;

    QJsonObject textNode;
    textNode["text"] = text;
    textNode["hidden"] = hideText;
    json["text"] = textNode;

    sendRequest(Method::Post, apiUrl + "/object/send", json, [=](const auto body, const auto statusCode) {
        Q_UNUSED(statusCode);
        const auto item = QJsonDocument::fromJson(body).object()["data"].toObject();
        addTempSend(item);
        const auto url = item["accessUrl"].toString();
        emit sendCreated(url);
    });
}

void BitwardenApi::sendRequest(const QString &url, const std::function<void (QByteArray, int)> &callback)
{
    sendRequest(QUrl(url), callback);
}

void BitwardenApi::sendRequest(Method method, const QString &url, const QByteArray &data, const std::function<void (QByteArray, int)> &callback)
{
    sendRequest(method, QUrl(url), data, callback);
}

void BitwardenApi::sendRequest(const QUrl &url, const std::function<void (QByteArray, int)> &callback)
{
    sendRequest(Method::Get, url, QByteArray(), callback);
}

void BitwardenApi::sendRequest(Method method, const QString &url, const std::function<void (QByteArray, int)> &callback)
{
    sendRequest(method, QUrl(url), callback);
}

void BitwardenApi::sendRequest(Method method, const QUrl &url, const std::function<void (QByteArray, int)> &callback)
{
    sendRequest(method, url, QByteArray(), callback);
}

void BitwardenApi::sendRequest(Method method, const QString &url, const QJsonObject &data, const std::function<void (QByteArray, int)> &callback)
{
    sendRequest(method, url, QJsonDocument(data), callback);
}

void BitwardenApi::sendRequest(Method method, const QString &url, const QJsonDocument &data, const std::function<void (QByteArray, int)> &callback)
{
    sendRequest(method, QUrl(url), data, callback);
}

void BitwardenApi::sendRequest(Method method, const QUrl &url, const QByteArray &data, const std::function<void (QByteArray, int)> &callback)
{
    QNetworkRequest request(url);
    request.setRawHeader("Authorization", secretsHandler->getServerApiKey().toUtf8());

    QNetworkReply *reply;

    QString methodName;
    if (method == Method::Get) {
        reply = manager.get(request);
        methodName = "GET";
    } else if (method == Method::Post) {
        request.setRawHeader("Content-Type", "application/json");
        reply = manager.post(request, data);
        methodName = "POST";
    }

    qDebug() << "Sending " + methodName + " request to " + url.toString();

    connect(reply, &QNetworkReply::finished, [=]() {
        reply->deleteLater();
        const auto body = reply->readAll();
        const auto statusCode = reply->attribute(QNetworkRequest::Attribute::HttpStatusCodeAttribute).toInt();

#ifdef QT_DEBUG
        qDebug() << "Got " + QString::number(statusCode) + " response for " + methodName + " request to " + url.toString() + ": " + QString(body);
#endif

        if (reply->error() == QNetworkReply::ConnectionRefusedError) {
            emit apiNotRunning();
            return;
        }

        callback(body, statusCode);
    });
}

const QJsonArray BitwardenApi::getTempSends()
{
    return runtimeCache->has(cacheKeyTempSends)
            ? QJsonDocument::fromJson(runtimeCache->get(cacheKeyTempSends).toUtf8()).array()
            : QJsonArray();
}

void BitwardenApi::addTempSend(const QJsonObject &object)
{
    auto tempSends = getTempSends();
    tempSends.append(object);
    runtimeCache->set(cacheKeyTempSends, QJsonDocument(tempSends).toJson(QJsonDocument::JsonFormat::Compact));
}

void BitwardenApi::handleGetItems(const QString &rawJson, GetItemType getItemType)
{
    runtimeCache->set(cacheKeyItems, rawJson);
    auto document = QJsonDocument::fromJson(rawJson.toUtf8()).array();

    switch (getItemType) {
    case GetItems:
        emit itemsResolved(document);
        break;
    case GetLogins:
    {
        QJsonArray result;

        for (const auto &item : document) {
            auto object = item.toObject();
            if (object.value("type").toInt() == Login) {
                result.append(object);
            }
        }

        emit itemsResolved(result);
        break;
    }
    case GetCards:
    {
        QJsonArray result;

        for (const auto &item : document) {
            auto object = item.toObject();
            if (object.value("type").toInt() == Card) {
                result.append(object);
            }
        }

        emit itemsResolved(result);
        break;
    }
    case GetNotes:
    {
        QJsonArray result;

        for (const auto &item : document) {
            auto object = item.toObject();
            if (object.value("type").toInt() == SecureNote) {
                result.append(object);
            }
        }

        emit itemsResolved(result);
        break;
    }
    case GetIdentities:
    {
        QJsonArray result;

        for (const auto &item : document) {
            auto object = item.toObject();
            if (object.value("type").toInt() == Identity) {
                result.append(object);
            }
        }

        emit itemsResolved(result);
        break;
    }
    default:
        break;
    }
}

void BitwardenApi::sendRequest(Method method, const QUrl &url, const QJsonDocument &data, const std::function<void (QByteArray, int)> &callback)
{
    sendRequest(method, url, data.toJson(), callback);
}

