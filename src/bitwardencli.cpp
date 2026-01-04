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
#include "random-helper.h"
#include "cache-keys.h"
#include "appsettings.h"

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
    if (secretsHandler->invalidCertificatesAllowed()) {
        env.insert("NODE_TLS_REJECT_UNAUTHORIZED", "0");
    }
    const AppSettings settingsSnapshot;
    if (settingsSnapshot.useSystemCaStore()) {
        env.insert("NODE_OPTIONS", "--use-openssl-ca");
    }

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

void BitwardenCli::generatePassword(bool lowercase, bool uppercase, bool numbers, bool special, bool avoidAmbiguous, int minimumNumbers, int minimumSpecial, int length)
{
    auto args = QStringList() << "generate";
    args << "--length" << QString::number(length) << "--minNumber" << QString::number(minimumNumbers) << "--minSpecial" << QString::number(minimumSpecial);
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
    if (avoidAmbiguous) {
        args << "--ambiguous";
    }

    startProcess(args, GeneratePassword);
}

void BitwardenCli::generatePassphrase(uint wordsCount, bool capitalize, bool includeNumber, const QString &separator)
{
    auto args = QStringList() << "generate" << "--passphrase";
    args << "--words" << QString::number(wordsCount) << "--separator" << separator;
    if (capitalize) {
        args << "--capitalize";
    }
    if (includeNumber) {
        args << "--includeNumber";
    }

    startProcess(args, GeneratePassphrase);
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

void BitwardenCli::serve(bool force)
{
    if (!force && serverNeedsPatching()) {
        emit serverShouldBePatched();
        return;
    }
    auto env = QProcessEnvironment::systemEnvironment();
    if (secretsHandler->hasSessionId()) {
        env.insert("BW_SESSION", secretsHandler->getSessionId());
    }
    secretsHandler->setServerApiKey(generateRandomString(32));
    env.insert("BITSAILOR_BW_API_KEY", secretsHandler->getServerApiKey());

    startProcess({"serve"}, env, Serve);

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

    process->deleteLater();
    if (invalidCert) {
        emit invalidCertificate();
        invalidCert = false;
        return;
    }

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
    case BitwardenCli::GeneratePassphrase:
        emit passphraseGenerated(process->readAllStandardOutput());
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
    case BitwardenCli::CreateSend:
        const auto item = QJsonDocument::fromJson(process->readAll()).object();
        emit sendCreated(item);
        break;
    }
}

void BitwardenCli::startProcess(const QStringList &arguments, Method method)
{
    auto env = QProcessEnvironment::systemEnvironment();
    if (secretsHandler->hasSessionId()) {
        env.insert("BW_SESSION", secretsHandler->getSessionId());
    }
    if (secretsHandler->invalidCertificatesAllowed()) {
        env.insert("NODE_TLS_REJECT_UNAUTHORIZED", "0");
    }
    const AppSettings settingsSnapshot;
    if (settingsSnapshot.useSystemCaStore()) {
        env.insert("NODE_OPTIONS", "--use-openssl-ca");
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
        oldProcess->disconnect();
        connect(oldProcess, static_cast<void (QProcess::*)(int, QProcess::ExitStatus)>(&QProcess::finished), oldProcess, &QObject::deleteLater);
        oldProcess->terminate();
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
        if (stdErr.contains(QRegExp("unable to verify .+ certificate"))) {
            invalidCert = true;
        }
#ifdef QT_DEBUG
        qDebug() << stdErr;
#endif
    });

#ifdef QT_DEBUG
    if (method == Serve) {
        connect(process, &QProcess::readyReadStandardOutput, [=](auto signal) {
            Q_UNUSED(signal);
            QString stdOut = process->readAllStandardOutput();
            if (method == Serve) {
                qDebug() << stdOut;
            }
        });
    }
#endif

    processes.insert(method, process);
    process->start(bw, arguments);
}

// todo remove
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

void BitwardenCli::patchServer()
{
    if (bw != getDataPath() + "/bin/bw") {
        qDebug() << "Server unpatchable";
        emit serverUnpatchable();
        return;
    }

    const auto source1 = serverPatchScripts + "/plugin-runner.js";
    const auto source2 = serverPatchScripts + "/plugin.js";
    const auto destination1 = getDataPath() + "/runner.js";
    const auto destination2 = getDataPath() + "/plugin.js";

    if (QFile::exists(destination1) && !QFile::remove(destination1)) {
        qWarning() << destination1 + " already exists and failed to be removed";
        emit serverPatchError();
        return;
    }
    if (QFile::exists(destination2) && !QFile::remove(destination2)) {
        qWarning() << destination2 + " already exists and failed to be removed";
        emit serverPatchError();
        return;
    }
    if (!QFile::copy(source1, destination1) || !QFile::copy(source2, destination2)) {
        emit serverPatchError();
        qDebug() << "Could not copy patches";
        return;
    }

    QProcess* process = new QProcess();
    process->setWorkingDirectory(getDataPath());
    process->setStandardInputFile(QProcess::nullDevice());

    connect(process, static_cast<void (QProcess::*)(int, QProcess::ExitStatus)>(&QProcess::finished), [=](int exitCode, QProcess::ExitStatus exitStatus) {
        process->deleteLater();

        qDebug() << process->readAllStandardOutput();
        qDebug() << exitCode;
        qDebug() << exitStatus;

        if (exitStatus != QProcess::ExitStatus::NormalExit || exitCode != 0) {
            qWarning() << process->readAllStandardError();
            qDebug() << process->readAllStandardOutput();
            emit serverPatchError();
        } else {
            if (serverNeedsPatching()) {
                emit serverPatchError();
            } else {
                emit serverPatched();
            }
        }
    });

    qDebug() << "Starting server patch script:" << "node" << getDataPath() + "/runner.js";
    process->start("node", {getDataPath() + "/runner.js"});
}

void BitwardenCli::createFileSend(const QString &name, const QString &filePath, const uint &deletionDate, const uint &maximumAccessCount, const QString &password, const bool &hideEmail, const QString &privateNotes)
{
    auto json = createCommonCreateSendParts(name, deletionDate, maximumAccessCount, password, hideEmail, privateNotes);
    json["type"] = SendType::SendTypeFile;

    QJsonObject file;
    file["fileName"] = filePath;
    json["file"] = file;

    const QString jsonString = QJsonDocument(json).toJson(QJsonDocument::JsonFormat::Compact).toBase64();
    startProcess({"send", "create", jsonString}, CreateSend);
}

void BitwardenCli::createTextSend(const QString &name, const QString &text, const bool &hideText, const uint &deletionDate, const uint &maximumAccessCount, const QString &password, const bool &hideEmail, const QString &privateNotes)
{
    auto json = createCommonCreateSendParts(name, deletionDate, maximumAccessCount, password, hideEmail, privateNotes);
    json["type"] = SendType::SendTypeText;

    QJsonObject textNode;
    textNode["text"] = text;
    textNode["hidden"] = hideText;
    json["text"] = textNode;

    const QString jsonString = QJsonDocument(json).toJson(QJsonDocument::JsonFormat::Compact).toBase64();
    startProcess({"send", "create", jsonString}, CreateSend);
}

bool BitwardenCli::serverNeedsPatching()
{
    if (bw != getDataPath() + "/bin/bw") {
        return true;
    }

    QFile patchableScript(getDataPath() + "/node_modules/@bitwarden/cli/build/bw.js");
    if (!patchableScript.exists()) {
        return true;
    }

    if (!patchableScript.open(QIODevice::ReadOnly | QIODevice::Text)) {
        return true;
    }

    QTextStream stream(&patchableScript);
    const QString &content = stream.readAll();
    patchableScript.close();

    return !content.contains("BITSAILOR_BW_API_KEY");
}
