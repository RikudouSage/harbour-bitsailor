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

BitwardenApi::BitwardenApi(QObject *parent) : QObject(parent)
{

}

void BitwardenApi::getItem(const QString &id)
{
    QUrl url(apiUrl + "/object/item/" + id);
    QNetworkRequest request(url);
    request.setRawHeader("Authorization", secretsHandler->getServerApiKey().toUtf8());

    auto reply = manager.get(request);

    connect(reply, &QNetworkReply::finished, [=]() {
        reply->deleteLater();
        if (reply->error() == QNetworkReply::ConnectionRefusedError) {
            emit apiNotRunning();
            return;
        }
        if (reply->error() == QNetworkReply::NoError) {
            auto body = reply->readAll();
            auto document = QJsonDocument::fromJson(body).object()["data"].toObject();

            emit itemFetched(document);
        } else {
            qDebug() << reply->readAll();
            emit itemFetchingFailed();
        }
    });
}

void BitwardenApi::isRunning()
{
    auto *socket = new QTcpSocket(this);
    socket->connectToHost("127.0.0.1", 8087);

    connect(socket, &QTcpSocket::connected, [=]() {
        emit apiIsRunning();
        socket->disconnectFromHost();
        socket->deleteLater();
    });
    connect(socket, static_cast<void (QTcpSocket::*)(QAbstractSocket::SocketError)>(&QTcpSocket::error), [=](auto error) {
        Q_UNUSED(error);
        emit apiNotRunning();
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
    QUrl url(apiUrl + "/list/object/send");
    QNetworkRequest request(url);
    request.setRawHeader("Authorization", secretsHandler->getServerApiKey().toUtf8());

    auto reply = manager.get(request);

    connect(reply, &QNetworkReply::finished, [=]() {
        reply->deleteLater();
        if (reply->error() == QNetworkReply::ConnectionRefusedError) {
            emit apiNotRunning();
            return;
        }
        if (reply->error() == QNetworkReply::NoError) {
            auto body = reply->readAll();
            auto document = QJsonDocument::fromJson(body).object()["data"].toArray();

            emit sendsResolved(document);
        } else {
            qDebug() << reply->readAll();
            emit failedGettingSends();
        }
    });
}

