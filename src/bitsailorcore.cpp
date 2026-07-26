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
    qRegisterMetaType<BitSailorCore::ItemType>("ItemType");
    qRegisterMetaType<BitSailorCore::SendType>("SendType");

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

void BitSailorCore::lockVault(bool sync)
{
    auto handler = [=] {
        if (BitwardenLockSession(session) != BitwardenSuccess) {
            qWarning() << "Failed locking session: " << getLastError();
            emit vaultLocked(false);
            return;
        }

        QString error;
        exportSession(&error);
        if (!error.isNull()) {
            qWarning() << "Failed exporting locked session: " << error;
            emit vaultLocked(false);
            return;
        }

        emit vaultLocked(true);
    };

    if (sync) {
        handler();
    } else {
        QtConcurrent::run(handler);
    }
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

void BitSailorCore::validateMasterPassword(const QString &password)
{
    QtConcurrent::run([=] {
        auto email = getEmail();
        if (email.isNull()) {
            qWarning() << "Failed fetching email";
            emit couldNotFetchEmail();
            return;
        }

        if (BitwardenValidatePassword(client, ctx, email.toUtf8().data(), password.toUtf8().data(), session) != BitwardenSuccess) {
            qWarning () << "Validation of password did not succeed: " << getLastError();
            emit masterPasswordValidationFinished(false);
            return;
        }

        emit masterPasswordValidationFinished(true);
    });
}

void BitSailorCore::fetchItems()
{
    QtConcurrent::run([=] {
        BitwardenItemSlice items = {};
        if (BitwardenGetItems(vault, ctx, session, &items) != BitwardenSuccess) {
            qWarning() << "Failed getting items: " << getLastError();
            emit itemResolvingFailed();
            return;
        }

        QJsonArray result;
        for (size_t i = 0; i < items.len; ++i) {
            auto item = items.items[i];
            QJsonObject outItem;
            outItem.insert("type", item.type);
            outItem.insert("name", item.name);
            outItem.insert("notes", item.notes);

            if (item.type == BitwardenItemTypeLogin) {
                QJsonObject login;
                login.insert("username", item.login->username);
                login.insert("password", item.login->password);
                login.insert("totp", item.login->totp);
                if (item.login->uris.len > 0) {
                    QJsonArray uris;
                    for (size_t j = 0; j < item.login->uris.len; ++j) {
                        auto uri = item.login->uris.items[j];
                        QJsonObject outUri;
                        outUri.insert("uri", uri.uri);
                    }
                    login.insert("uris", uris);
                }

                outItem.insert("login", login);
            } else if (item.type == BitwardenItemTypeCard) {
                QJsonObject card;
                card.insert("cardholderName", item.card->cardholderName);
                card.insert("brand", item.card->brand);
                card.insert("number", item.card->number);
                card.insert("expMonth", item.card->expirationMonth);
                card.insert("expYear", item.card->expirationYear);
                card.insert("code", item.card->code);
                outItem.insert("card", card);
            }
            result.append(outItem);
        }
        BitwardenFreeItems(&items);
        emit itemsResolved(result);
    });
}

void BitSailorCore::fetchSends()
{
    QtConcurrent::run([=] {
        BitwardenSendSlice items = {};
        if (BitwardenGetSends(vault, ctx, session, &items) != BitwardenSuccess) {
            qWarning() << "Failed fetching sends: " << getLastError();
            emit sendsResolved(false, {});
            return;
        }

        QJsonArray result;
        for (size_t i = 0; i < items.len; ++i) {
            auto item = items.items[i];
            QJsonObject outItem;
            outItem.insert("name", item.name);
            outItem.insert("type", item.type);
            outItem.insert("deletionDate", cTimeToQDate(item.deletionDate).toUTC().toString(Qt::ISODate));
            outItem.insert("accessUrl", item.accessUrl);

            result.append(outItem);
        }
        BitwardenFreeSends(&items);

        emit sendsResolved(true, result);
    });
}

void BitSailorCore::deleteItem(const QString &id, bool emitEvents)
{
    QtConcurrent::run([=] {
        if (BitwardenDeleteItem(vault, ctx, session, uuidToCoreUuid(qUuidFromString(id))) != BitwardenSuccess) {
            qWarning() << "Failed deleting item: " << getLastError();
            if (emitEvents) {
                emit deletingFinished(false);
            }
            return;
        }

        if (emitEvents) {
            emit deletingFinished(true);
        }
    });
}

void BitSailorCore::syncVault()
{
    QtConcurrent::run([=] {
        if (!syncRaw()) {
            emit syncVaultFinished(false);
            return;
        }

        emit syncVaultFinished(true);
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
#ifdef QT_DEBUG
        qDebug() << "Device ID: " << settings->deviceUuid();
#endif
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

    if (BitwardenGetVault(client, &vault) != BitwardenSuccess) {
        valid = false;
        qWarning() << "Failded getting a vault: " << getLastError();
    }

    if (secrets->hasSessionJson()) {
        auto json = secrets->getSessionJson();
#ifdef QT_DEBUG
        qDebug() << "Session JSON: " << json;
#endif
        if (json.isEmpty()) {
            qWarning() << "The session json is empty";
        }
        auto jsonStr = QJsonDocument(json).toJson();
        if (BitwardenImportSession(nullptr, jsonStr.data(), &session) != BitwardenSuccess) {
            valid = false;
            qWarning() << "Failed importing session: " << getLastError();
        }
    }

    if (secrets->hasEncryptedVault()) {
        auto json = secrets->getEncryptedVault();
        if (json.isEmpty()) {
            qWarning() << "The session json is empty";
        }
        auto jsonStr = QJsonDocument(json).toJson();
        VaultHandle newVault;
        if (BitwardenImportVault(vault, jsonStr.data(), &newVault) != BitwardenSuccess) {
            valid = false;
            qWarning() << "Failed importing session: " << getLastError();
        } else {
            if (BitwardenCloseHandle(vault) != BitwardenSuccess) {
                qWarning() << "Failed closing vault handle: " << getLastError();
            }
            vault = newVault;
        }
    }
}

void BitSailorCore::getServerUrl()
{
    QtConcurrent::run([=] {
        emit serverUrlResolved(settings->baseUrl());
    });
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

QDateTime BitSailorCore::cTimeToQDate(int64_t time) const
{
    return QDateTime::fromMSecsSinceEpoch(time);
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
