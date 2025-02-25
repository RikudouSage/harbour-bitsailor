#include "bitwardencli.h"

#include <QDebug>
#include <QJsonDocument>
#include <QJsonObject>
#include <QList>
#include <QFile>
#include <QTimer>
#include <QNetworkRequest>
#include <QUrl>
#include <QNetworkReply>

#include "pathhelper.h"

static const QString cacheKeyItems = "items";

BitwardenCli::BitwardenCli(QObject *parent) : QObject(parent)
{
    for (const auto &path : getPaths()) {
        QFile file(path + "/bw");
        if (file.exists()) {
            bw = path + "/bw";
            break;
        }
    }
}

BitwardenCli::~BitwardenCli()
{
    for (const auto process : processes) {
#ifdef QT_DEBUG
        qDebug() << "Destroying: " << process->program() << process->arguments();
#endif
        process->disconnect();
        process->terminate();
        process->deleteLater();
    }
}

void BitwardenCli::checkLoginStatus()
{
    startProcess({"login", "--check"}, LoginCheck);
}

void BitwardenCli::checkVaultUnlocked()
{
    auto sessionId = secretsHandler->getSessionId();
    if (sessionId.isNull() || sessionId.isEmpty()) {
        emit vaultLockStatusResolved(false);
        return;
    }

    startProcess({"unlock", "--check"}, VaultUnlocked);
}

void BitwardenCli::loginEmailPassword(const QString &email, const QString &password)
{
    secretsHandler->setUsername(email);

    startProcess({"login", email, password, "--raw"}, LoginEmailPassword);
}

void BitwardenCli::loginApiKey(const QString &clientId, const QString &clientSecret)
{
    secretsHandler->setClientId(clientId);

    auto env = QProcessEnvironment::systemEnvironment();
    env.insert("BW_CLIENTID", clientId);
    env.insert("BW_CLIENTSECRET", clientSecret);

    startProcess({"login", "--apikey"}, env, LoginApiKey);
}

void BitwardenCli::logout()
{
    secretsHandler->clearAllSecrets();
    startProcess({"logout"}, Logout);
}

void BitwardenCli::unlockVault(QString password)
{
    startProcess({"unlock", password, "--raw"}, UnlockVault);
}

void BitwardenCli::unlockVault(int pin)
{
    auto providedPin = QString::number(pin);
    auto storedPin = secretsHandler->getPin();

    if (providedPin != storedPin) {
        emit wrongPinProvided();
        return;
    }

    auto password = secretsHandler->getPassword();

    unlockVault(password);
}

void BitwardenCli::unlockVault()
{
    auto password = secretsHandler->getPassword();

    unlockVault(password);
}

void BitwardenCli::lockVault()
{
    secretsHandler->removeSessionId();
    startProcess({"lock"}, LockVault);
}

void BitwardenCli::lockVaultInBackground()
{
    secretsHandler->removeSessionId();
    QProcess* process = new QProcess(); // intentionally no parent
    process->setWorkingDirectory(getDataPath());
    process->setStandardInputFile(QProcess::nullDevice());
    process->start(bw, {"lock"});
    connect(process, static_cast<void (QProcess::*)(int, QProcess::ExitStatus)>(&QProcess::finished), process, &QProcess::deleteLater);
}

void BitwardenCli::getSends()
{
    startProcess({"send", "list"}, GetSends);
}

void BitwardenCli::getItems()
{
    getItems(GetItems);
}

void BitwardenCli::getItems(Method method)
{
    auto cache = runtimeCache->get(cacheKeyItems);
    if (!cache.isNull() && !cache.isEmpty()) {
        handleGetItems(runtimeCache->get(cacheKeyItems), method);
    } else {
        startProcess({"list", "items"}, GetLogins);
    }
}

void BitwardenCli::getLogins()
{
    getItems(GetLogins);
}

void BitwardenCli::getCards()
{
    getItems(GetCards);
}

void BitwardenCli::getNotes()
{
    getItems(GetNotes);
}

void BitwardenCli::getIdentities()
{
    getItems(GetIdentities);
}

void BitwardenCli::syncVault()
{
    startProcess({"sync"}, SyncVault);
}

void BitwardenCli::deleteItem(QString id)
{
    startProcess({"delete", "item", id}, DeleteItem);
}

void BitwardenCli::deleteItemInBackground(QString id)
{
    auto env = QProcessEnvironment::systemEnvironment();
    if (secretsHandler->hasSessionId()) {
        env.insert("BW_SESSION", secretsHandler->getSessionId());
    }

    QProcess* process = new QProcess(); // intentionally no parent
    process->setProcessEnvironment(env);
    process->setWorkingDirectory(getDataPath());
    process->setStandardInputFile(QProcess::nullDevice());
    process->start(bw, {"delete", "item", id});
    connect(process, static_cast<void (QProcess::*)(int, QProcess::ExitStatus)>(&QProcess::finished), process, &QProcess::deleteLater);

    if (runtimeCache->has(cacheKeyItems)) {
        auto rawJson = runtimeCache->get(cacheKeyItems);
        auto document = QJsonDocument::fromJson(rawJson.toUtf8()).array();

        QJsonArray result;

        for (const auto &item : document) {
            auto object = item.toObject();
            if (object.value("id").toString() != id) {
                result.append(object);
            }
        }

        QJsonDocument newDocument(result);

        runtimeCache->set(cacheKeyItems, newDocument.toJson());
    }
}

void BitwardenCli::getItem(QString id)
{
    startProcess({"get", "item", id}, GetItem);
}

void BitwardenCli::generatePassword(bool lowercase, bool uppercase, bool numbers, bool special, int length)
{
    auto args = QStringList() << "generate";
    args << "--length" << QString::number(length);
    if (lowercase) {
        args << "--lowercase";
    }
    if (uppercase) {
        args << "--uppercase";
    }
    if (numbers) {
        args << "--number";
    }
    if (special) {
        args << "--special";
    }

    startProcess(args, GeneratePassword);
}

void BitwardenCli::getServerUrl()
{
    startProcess({"config", "server"}, GetServerUrl);
}

void BitwardenCli::setServerUrl(QString url)
{
    startProcess({"config", "server", url}, SetServerUrl);
}

void BitwardenCli::createItem(const QString &encodedData)
{
    startProcess({"create", "item", encodedData}, CreateItem);
}

void BitwardenCli::serve()
{
    startProcess({"serve"}, Serve);

    QTimer *timer = new QTimer(this);
    timer->setInterval(200);
    timer->setTimerType(Qt::TimerType::PreciseTimer);
    timer->start();

    connect(timer, &QTimer::timeout, [=]() {
        QNetworkRequest request(QUrl("http://127.0.0.1:8087"));
        auto reply = networkManager.get(request);
        connect(reply, &QNetworkReply::finished, [=]() {
            reply->deleteLater();
            if (reply->error() == QNetworkReply::ConnectionRefusedError) {
                return;
            }

            emit serverStarted();

            timer->stop();
            timer->disconnect();
            timer->deleteLater();
        });
    });
}

void BitwardenCli::stopServer()
{
    if (!processes.contains(Serve)) {
        return;
    }

    const auto process = processes.value(Serve);
    process->terminate();
}

void BitwardenCli::onFinished(int exitCode, Method method)
{
    auto process = processes.take(method);

#ifdef QT_DEBUG
    qDebug() << "method " << method << " exit code: " << exitCode;
    if (exitCode != 0) {
        qDebug() << "stderr: " << QString(process->readAllStandardError());
        qDebug() << "stdout: " << QString(process->readAllStandardOutput());
    }
#endif

    switch (method) {
    case BitwardenCli::CreateItem:
        emit itemCreationFinished(exitCode == 0);
        break;
    case BitwardenCli::SetServerUrl:
        emit serverUrlSet(exitCode == 0);
        break;
    case BitwardenCli::GetServerUrl:
        emit serverUrlResolved(process->readAllStandardOutput());
        break;
    case BitwardenCli::GetSends:
        if (exitCode != 0) {
            emit failedGettingSends();
        } else {
            auto document = QJsonDocument::fromJson(process->readAllStandardOutput()).array();
            emit sendsResolved(document);
        }
        break;
    case BitwardenCli::GeneratePassword:
        emit passwordGenerated(process->readAllStandardOutput());
        break;
    case BitwardenCli::GetItem:
        if (exitCode != 0) {
            emit itemFetchingFailed();
        } else {
            emit itemFetched(QJsonDocument::fromJson(process->readAllStandardOutput()).object());
        }
        break;
    case BitwardenCli::DeleteItem:
        emit itemDeleted(exitCode == 0);
        break;
    case BitwardenCli::SyncVault:
        if (exitCode != 0) {
            emit vaultSyncFailed();
        } else {
            runtimeCache->remove(cacheKeyItems);
            emit vaultSynced();
        }
        break;
    case BitwardenCli::GetItems:
    case BitwardenCli::GetLogins:
    case BitwardenCli::GetCards:
    case BitwardenCli::GetNotes:
    case BitwardenCli::GetIdentities:
        if (exitCode != 0) {
            emit failedGettingItems();
        } else {
            handleGetItems(process->readAllStandardOutput(), method);
        }
        break;
    case BitwardenCli::LockVault:
        emit vaultLocked();
        break;
    case BitwardenCli::UnlockVault:
    {
        auto success = exitCode == 0;
        if (success) {
            auto sessionKey = QString::fromUtf8(process->readAll()).trimmed();
            secretsHandler->setSessionId(sessionKey);
        }
        emit vaultUnlockFinished(success);
        break;
    }
    case BitwardenCli::Logout:
        emit logoutFinished();
        break;
    case BitwardenCli::LoginEmailPassword:
    {
        if (exitCode == 15) {
            emit authenticatorRequired();
        } else {
            auto success = exitCode == 0;
            if (success) {
                auto sessionKey = QString::fromUtf8(process->readAll()).trimmed();
                secretsHandler->setSessionId(sessionKey);
            }
            emit logInFinished(success);
        }
        break;
    }
    case BitwardenCli::LoginApiKey:
        emit logInFinished(exitCode == 0);
        break;
    case LoginCheck:
        emit loginStatusResolved(exitCode == 0);
        break;
    case VaultUnlocked:
        emit vaultLockStatusResolved(exitCode == 0);
        break;
    }

    delete process;
}

void BitwardenCli::startProcess(const QStringList &arguments, Method method)
{
    auto env = QProcessEnvironment::systemEnvironment();
    if (secretsHandler->hasSessionId()) {
        env.insert("BW_SESSION", secretsHandler->getSessionId());
    }
    startProcess(arguments, env, method);
}

void BitwardenCli::startProcess(const QStringList &arguments, const QProcessEnvironment &environment, Method method)
{
#ifdef QT_DEBUG
    qDebug() << "Starting command: " << "bw " << arguments.join(" ");
#endif
    QProcess* process = new QProcess();
    process->setWorkingDirectory(getDataPath());
    process->setProcessEnvironment(environment);
    process->setStandardInputFile(QProcess::nullDevice());

    if (processes.contains(method)) {
        auto oldProcess = processes.take(method);
        oldProcess->terminate();
        oldProcess->deleteLater();
    }

    connect(process, static_cast<void (QProcess::*)(int, QProcess::ExitStatus)>(&QProcess::finished), [=](int exitCode, QProcess::ExitStatus exitStatus) {
        Q_UNUSED(exitStatus);
        onFinished(exitCode, method);
    });
    connect(process, &QProcess::errorOccurred, [=] (QProcess::ProcessError error) {
        qWarning() << error;
    });

    connect(process, &QProcess::readyReadStandardError, [=] (auto signal) {
        Q_UNUSED(signal);
        QString stdErr = process->readAllStandardError();
        if (method == LoginEmailPassword && stdErr.contains("Authenticator")) {
            process->terminate();
        }
    });

    processes.insert(method, process);
    process->start(bw, arguments);
}

void BitwardenCli::handleGetItems(const QString &rawJson, Method method)
{
    runtimeCache->set(cacheKeyItems, rawJson);
    auto document = QJsonDocument::fromJson(rawJson.toUtf8()).array();

    switch (method) {
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
