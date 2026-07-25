#include "bitsailorcore.h"

#include <cstring>
#include <QDebug>
#include <QJsonDocument>
#include <QtConcurrent>
#include <QJsonParseError>

#include "consts.h"

BitSailorCore::BitSailorCore(AppSettings *settings, SecretsHandler *secrets, QObject *parent) : QObject(parent)
{
    qRegisterMetaType<BitSailorCore::SessionStatus>("SessionStatus");

    this->settings = settings;
    this->secrets = secrets;
    initialize();
}

BitSailorCore::BitSailorCore(QObject *parent) : QObject(parent)
{
    // this constructor is for static data access from QML only, using anything else will probably cause a
}

BitSailorCore::~BitSailorCore()
{
    cleanup();
}

void BitSailorCore::getLoginStatus()
{
    if (session == 0) {
        emit loginStatusFetched(SessionStatusNone);
        return;
    }

    QtConcurrent::run([=] {
        BitwardenSessionStatus result;
        if (BitwardenGetSessionStatus(session, &result) != BitwardenSuccess) {
            qWarning() << "Failed getting session status: " << getLastError();
            emit loginStatusFetched(SessionStatusNone);
            return;
        }

        emit loginStatusFetched(static_cast<SessionStatus>(result));
    });
}

void BitSailorCore::changeServerUrl(const QString &url)
{
    QtConcurrent::run([=] {
        settings->setBaseUrl(url);
        initialize();
        if (!valid) {
            emit serverUrlChanged(false);
        } else {
            emit serverUrlChanged(true);
        }
    });
}

void BitSailorCore::loginApiKey(const QString &clientId, const QString &clientSecret)
{
    login([=] {
        return BitwardenLoginApiKey(client, ctx, clientId.toUtf8().data(), clientSecret.toUtf8().data(), &session);
    });
}

void BitSailorCore::loginEmailPassword(const QString &email, const QString &password)
{
    login([=] {
        return BitwardenLoginPassword(client, ctx, email.toUtf8().data(), password.toUtf8().data(), &session);
    });
}

void BitSailorCore::logout()
{
    QtConcurrent::run([=] {
        if (BitwardenCloseHandle(session) != BitwardenSuccess) {
            qWarning() << "Failed closing session: " << getLastError();
        }

        session = 0;
        secrets->clearAllSecrets();
        initialize();

        emit logoutFinished();
    });
}

void BitSailorCore::unlockVault(const QString &password)
{
    QtConcurrent::run([=] {
        const auto email = getEmail();
        if (email.isNull() || email.isEmpty()) {
            emit couldNotFetchEmail();
            return;
        }

        if (BitwardenUnlockSession(client, ctx, session, email.toUtf8().data(), password.toUtf8().data()) != BitwardenSuccess) {
            auto error = getLastError();
            qWarning() << "Failed unlocking session: " << error;
            emit unlockFinished(false, error);
            return;
        }

        QString exportError;
        exportSession(&exportError);
        if (!exportError.isNull()) {
            qWarning() << "Failed exporting session: " << exportError;
        }

        emit unlockFinished(true, "");
    });
}

void BitSailorCore::unlockVault(int pin)
{
    QtConcurrent::run([=] {
        auto providedPin = QString::number(pin);
        auto storedPin = secrets->getPin();

        if (providedPin != storedPin) {
            emit wrongPinProvided();
            return;
        }

        auto password = secrets->getPassword();

        unlockVault(password);
    });
}

void BitSailorCore::unlockVault()
{
    QtConcurrent::run([=] {
        auto password = secrets->getPassword();
        unlockVault(password);
    });
}

const QString BitSailorCore::getLastError() const
{
    std::size_t len = BitwardenGetLastError(nullptr, 0);

    if (len < 1) {
        return QString();
    }

    QByteArray buf(static_cast<int>(len), Qt::Uninitialized);
    BitwardenGetLastError(buf.data(), static_cast<std::size_t>(buf.size()));

    return QString::fromUtf8(buf.constData());
}

void BitSailorCore::initialize()
{
    valid = true;
    cleanup();

    if (settings->deviceUuid() == "") {
        settings->setDeviceUuid(uuidToString(generateUuid()));
    }

    if (BitwardenNewContext(&ctx) != BitwardenSuccess) {
        valid = false;
        qWarning() << "Failed initializing context: " << getLastError();
    }

    auto baseUrl = settings->baseUrl().toUtf8();
    if (baseUrl == defaultVaultUrl) {
        baseUrl.clear();
    }

    auto uuid = uuidFromString(settings->deviceUuid());
    if (BitwardenNewClient(&client, NewClientOptions {
        .baseUrl = baseUrl.constData(),
        .deviceId = &uuid,
    }) != BitwardenSuccess) {
        valid = false;
        qWarning() << "Failed initializing client: " << getLastError();
    }

    if (secrets->hasSessionJson()) {
        auto json = secrets->getSessionJson();
        if (json.isEmpty()) {
            qWarning() << "The session json is empty";
        }
        auto jsonStr = QJsonDocument(json).toJson();
        if (BitwardenImportSession(nullptr, jsonStr.data(), &session) != BitwardenSuccess) {
            valid = false;
            qWarning() << "Failed importing session: " << getLastError();
        }
    }
}

void BitSailorCore::cleanup()
{
    if (ctx != 0 && BitwardenCloseHandle(ctx) != BitwardenSuccess) {
        qWarning() << "Failed closing context: " << getLastError();
    }
    if (client != 0 && BitwardenCloseHandle(client) != BitwardenSuccess) {
        qWarning() << "Failed closing client: " << getLastError();
    }
    if (session != 0 && BitwardenCloseHandle(session) != BitwardenSuccess) {
        qWarning() << "Failed closing session: " << getLastError();
    }
    if (vault != 0 && BitwardenCloseHandle(vault) != BitwardenSuccess) {
        qWarning() << "Failed closing vault: " << getLastError();
    }

    ctx = 0;
    client = 0;
    session = 0;
    vault = 0;
    email = "";
}

QUuid BitSailorCore::generateUuid() const
{
    return QUuid::createUuid();
}

QString BitSailorCore::uuidToString(const QUuid &uuid) const
{
    auto uuidStr = uuid.toString();
    uuidStr = uuidStr.mid(1, uuidStr.size() - 2);

    return uuidStr;
}

QString BitSailorCore::uuidToString(const UUID &uuid) const
{
    return uuidToString(uuidToQUuid(uuid));
}

QUuid BitSailorCore::qUuidFromString(const QString &uuid) const
{
    QString copy = uuid;

    if (!copy.startsWith('{')) {
        copy.prepend('{');
    }

    if (!copy.endsWith('}')) {
        copy.append('}');
    }

    return copy;
}

UUID BitSailorCore::uuidFromString(const QString &uuid) const
{
    return uuidToCoreUuid(qUuidFromString(uuid));
}

UUID BitSailorCore::uuidToCoreUuid(const QUuid &uuid) const
{
    QByteArray raw = uuid.toRfc4122();
    UUID cUuid;
    std::memcpy(cUuid.bytes, raw.constData(), 16);

    return cUuid;
}

QUuid BitSailorCore::uuidToQUuid(const UUID &uuid) const
{
    QByteArray raw(reinterpret_cast<const char *>(uuid.bytes), 16);
    return QUuid::fromRfc4122(raw);
}

QString BitSailorCore::getEmail()
{
    if (!email.isNull() && !email.isEmpty()) {
        return email;
    }

    char *out = nullptr;
    if (BitwardenGetEmail(vault, &out) != BitwardenSuccess) {
        if (!syncRaw()) {
            qWarning() << "Failed syncing";
            return QString();
        }
    }
    if (BitwardenGetEmail(vault, &out) != BitwardenSuccess) {
        qWarning() << "Failed getting email even after sync";
        return QString();
    }
    const auto result = QString::fromUtf8(out);
    free(out);

    return result;
}

void BitSailorCore::login(const std::function<BitwardenResult ()> &loginCallable)
{
    QtConcurrent::run([=] {
        auto result = loginCallable();
        if (result != BitwardenSuccess) {
            auto error = getLastError();
            if (error == twoFactorNeededError) {
                emit twoFactorNeeded();
                return;
            }
            qWarning() << "Login failed: " << error;
            emit loginFinished(false, error);
            return;
        }

        QString exportError;
        exportSession(&exportError);
        if (!exportError.isNull()) {
            qWarning() << "Login failed: " << exportError;
            emit loginFinished(false, exportError);
        }

        emit loginFinished(true, "");
    });
}

bool BitSailorCore::syncRaw()
{
    if (vault != 0) {
        if (BitwardenCloseHandle(vault) != BitwardenSuccess) {
            qWarning() << "Failed closing vault: " << getLastError();
        }
    }

    if (BitwardenSyncVault(client, ctx, session, &vault) != BitwardenSuccess) {
        qWarning() << "Failed syncing: " << getLastError();
        return false;
    }

    char *out = nullptr;
    if (BitwardenExportEncryptedVault(vault, &out) != BitwardenSuccess) {
        qWarning() << "Failed exporting: " << getLastError();
        return false;
    }
    QJsonParseError err;
    auto json = QJsonDocument::fromJson(QByteArray(out), &err);
    free(out);

    if (err.error) {
        qWarning() << "Failed parsing exported vault JSON: " << err.errorString();
        return false;
    }

    secrets->setEncryptedVault(json.object());
    return true;
}

void BitSailorCore::exportSession(QString *error)
{
    char* rawExport = nullptr;
    if (BitwardenExportSession(session, &rawExport) != BitwardenSuccess) {
        *error = getLastError();
        qWarning() << "Exporting session failed: " << error;
        return;
    }
    QJsonParseError err;
    auto sessionJson = QJsonDocument::fromJson(QByteArray(rawExport), &err);
    free(rawExport);

    if (err.error) {
        *error = err.errorString();
        qWarning() << "Failed parsing exported session JSON: " << error;
        return;
    }

    secrets->setSessionJson(sessionJson.object());
}
