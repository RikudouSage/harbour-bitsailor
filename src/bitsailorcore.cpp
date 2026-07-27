#include "bitsailorcore.h"

#include <cstring>
#include <cstdlib>
#include <vector>
#include <QDebug>
#include <QFileInfo>
#include <QJsonDocument>
#include <QtConcurrent>
#include <QJsonParseError>

#include "authlogger.h"
#include "consts.h"

namespace {

char *jsonStringOrNull(const QJsonObject &object, const QString &key, QByteArray *storage)
{
    const auto value = object.value(key);
    if (value.isUndefined() || value.isNull()) {
        return nullptr;
    }

    *storage = value.toString().toUtf8();
    return storage->data();
}

struct BitwardenItemInput
{
    QByteArray name;
    QByteArray notes;
    QByteArray loginUsername;
    QByteArray loginPassword;
    QByteArray loginTotp;
    std::vector<QByteArray> loginUriValues;
    std::vector<BitwardenItemLoginUri> loginUris;
    QByteArray cardCardholderName;
    QByteArray cardBrand;
    QByteArray cardNumber;
    QByteArray cardExpirationMonth;
    QByteArray cardExpirationYear;
    QByteArray cardCode;
    BitwardenItemLogin login = {};
    BitwardenItemCard card = {};
    BitwardenItemSecureNote secureNote = {};
    BitwardenItem item = {};

    BitwardenItemInput(const UUID &id, const QJsonObject &object)
    {
        item.id = id;
        item.type = static_cast<BitwardenItemType>(object.value("type").toInt());
        item.favorite = object.value("favorite").toBool(false);
        item.reprompt = object.value("reprompt").toBool(false);

        name = object.value("name").toString().toUtf8();
        item.name = name.data();
        item.notes = jsonStringOrNull(object, "notes", &notes);

        switch (item.type) {
        case BitwardenItemTypeLogin:
            fillLogin(object.value("login").toObject());
            item.login = &login;
            break;
        case BitwardenItemTypeSecureNote:
            fillSecureNote(object.value("secureNote").toObject());
            item.secureNote = &secureNote;
            break;
        case BitwardenItemTypeCard:
            fillCard(object.value("card").toObject());
            item.card = &card;
            break;
        default:
            break;
        }
    }

    void fillLogin(const QJsonObject &object)
    {
        login.username = jsonStringOrNull(object, "username", &loginUsername);
        login.password = jsonStringOrNull(object, "password", &loginPassword);
        login.totp = jsonStringOrNull(object, "totp", &loginTotp);

        const auto uris = object.value("uris").toArray();
        loginUriValues.reserve(static_cast<size_t>(uris.size()));
        loginUris.reserve(static_cast<size_t>(uris.size()));
        for (const auto &uriValue : uris) {
            const auto uriObject = uriValue.toObject();
            const auto uri = uriObject.value("uri").toString();
            if (uri.isEmpty()) {
                continue;
            }

            loginUriValues.push_back(uri.toUtf8());
            BitwardenItemLoginUri outUri = {};
            outUri.uri = loginUriValues.back().data();
            outUri.match = static_cast<BitwardenUriMatchType>(uriObject.value("match").toInt());
            loginUris.push_back(outUri);
        }

        if (!loginUris.empty()) {
            login.uris.items = loginUris.data();
            login.uris.len = loginUris.size();
        }
    }

    void fillSecureNote(const QJsonObject &object)
    {
        secureNote.type = object.value("type").toInt(0);
    }

    void fillCard(const QJsonObject &object)
    {
        card.cardholderName = jsonStringOrNull(object, "cardholderName", &cardCardholderName);
        card.brand = jsonStringOrNull(object, "brand", &cardBrand);
        card.number = jsonStringOrNull(object, "number", &cardNumber);
        card.expirationMonth = jsonStringOrNull(object, "expMonth", &cardExpirationMonth);
        card.expirationYear = jsonStringOrNull(object, "expYear", &cardExpirationYear);
        card.code = jsonStringOrNull(object, "code", &cardCode);
    }
};

struct BitwardenSendInput
{
    QByteArray name;
    QByteArray notes;
    QByteArray password;
    QByteArray textValue;
    QByteArray filePath;
    QByteArray fileName;
    uint maximumAccessCountValue = 0;
    BitwardenSendText text = {};
    BitwardenSendFile file = {};
    BitwardenSend send = {};

    BitwardenSendInput(
            BitwardenSendType type,
            const QString &name,
            int deletionDate,
            int maximumAccessCount,
            const QString &password,
            bool hideEmail,
            const QString &notes
    ) {
        this->name = name.toUtf8();
        send.name = this->name.data();
        send.type = type;
        send.authType = password.isEmpty() ? BitwardenSendAuthTypeNoAuth : BitwardenSendAuthTypePassword;
        send.deletionDate = QDateTime::currentDateTimeUtc().addSecs(deletionDate).toMSecsSinceEpoch();
        send.hideEmail = hideEmail;
        send.notes = stringOrNull(notes, &this->notes);
        send.password = stringOrNull(password, &this->password);
        if (maximumAccessCount > 0) {
            maximumAccessCountValue = static_cast<uint>(maximumAccessCount);
            send.maxAccessCount = &maximumAccessCountValue;
        }
    }

    void setText(const QString &text, bool hidden)
    {
        textValue = text.toUtf8();
        this->text.text = textValue.data();
        this->text.hidden = hidden;
        send.text = &this->text;
    }

    void setFile(const QString &path)
    {
        filePath = path.toUtf8();
        fileName = QFileInfo(path).fileName().toUtf8();
        file.fileName = fileName.data();
        send.file = &file;
        send.inputFilePath = filePath.data();
    }

private:
    static char *stringOrNull(const QString &value, QByteArray *storage)
    {
        if (value.isEmpty()) {
            return nullptr;
        }

        *storage = value.toUtf8();
        return storage->data();
    }
};

}

BitSailorCore::BitSailorCore(AppSettings *settings, SecretsHandler *secrets, QObject *parent) : QObject(parent)
{
    AuthLogger::log(QStringLiteral("BitSailorCore: constructing core bridge"));
    qRegisterMetaType<BitSailorCore::SessionStatus>("SessionStatus");
    qRegisterMetaType<BitSailorCore::ItemType>("ItemType");
    qRegisterMetaType<BitSailorCore::SendType>("SendType");
    qRegisterMetaType<BitSailorCore::FieldType>("FieldType");
    qRegisterMetaType<BitSailorCore::UriMatchType>("UriMatchType");

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
    AuthLogger::log(QStringLiteral("BitSailorCore: getLoginStatus requested sessionPresent=%1").arg(
        session == 0 ? QStringLiteral("false") : QStringLiteral("true")
    ));
    if (session == 0) {
        AuthLogger::log(QStringLiteral("BitSailorCore: getLoginStatus result status=None reason=no-session-handle"));
        emit loginStatusFetched(SessionStatusNone);
        return;
    }

    QtConcurrent::run([=] {
        AuthLogger::log(QStringLiteral("BitSailorCore: BitwardenGetSessionStatus starting sessionPresent=%1").arg(
            session == 0 ? QStringLiteral("false") : QStringLiteral("true")
        ));
        BitwardenSessionStatus result;
        if (BitwardenGetSessionStatus(session, &result) != BitwardenSuccess) {
            const auto error = getLastError();
            qWarning() << "Failed getting session status: " << error;
            AuthLogger::log(QStringLiteral("BitSailorCore: BitwardenGetSessionStatus failed error=%1").arg(error));
            emit loginStatusFetched(SessionStatusNone);
            return;
        }

        AuthLogger::log(QStringLiteral("BitSailorCore: BitwardenGetSessionStatus result status=%1").arg(QString::number(result)));
        emit loginStatusFetched(static_cast<SessionStatus>(result));
    });
}

void BitSailorCore::logAuthEvent(const QString &event)
{
    AuthLogger::log(QStringLiteral("QML auth: %1").arg(event));
}

void BitSailorCore::changeServerUrl(const QString &url)
{
    AuthLogger::log(QStringLiteral("BitSailorCore: changeServerUrl requested url=%1").arg(url));
    QtConcurrent::run([=] {
        settings->setBaseUrl(url);
        initialize();
        if (!valid) {
            AuthLogger::log(QStringLiteral("BitSailorCore: changeServerUrl result success=false"));
            emit serverUrlChanged(false);
        } else {
            AuthLogger::log(QStringLiteral("BitSailorCore: changeServerUrl result success=true"));
            emit serverUrlChanged(true);
        }
    });
}

void BitSailorCore::lockVault(bool sync)
{
    AuthLogger::log(QStringLiteral("BitSailorCore: lockVault requested sync=%1 sessionPresent=%2").arg(
        sync ? QStringLiteral("true") : QStringLiteral("false"),
        session == 0 ? QStringLiteral("false") : QStringLiteral("true")
    ));
    auto handler = [=] {
        if (BitwardenLockSession(session) != BitwardenSuccess) {
            const auto error = getLastError();
            qWarning() << "Failed locking session: " << error;
            AuthLogger::log(QStringLiteral("BitSailorCore: BitwardenLockSession failed error=%1").arg(error));
            emit vaultLocked(false);
            return;
        }
        AuthLogger::log(QStringLiteral("BitSailorCore: BitwardenLockSession succeeded"));

        QString error;
        exportSession(&error);
        if (!error.isNull()) {
            qWarning() << "Failed exporting locked session: " << error;
            AuthLogger::log(QStringLiteral("BitSailorCore: lockVault exportSession failed error=%1").arg(error));
            emit vaultLocked(false);
            return;
        }

        AuthLogger::log(QStringLiteral("BitSailorCore: lockVault result success=true"));
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
    AuthLogger::log(QStringLiteral("BitSailorCore: loginApiKey requested clientIdPresent=%1 clientSecretPresent=%2").arg(
        clientId.isEmpty() ? QStringLiteral("false") : QStringLiteral("true"),
        clientSecret.isEmpty() ? QStringLiteral("false") : QStringLiteral("true")
    ));
    login([=] {
        return BitwardenLoginApiKey(client, ctx, clientId.toUtf8().data(), clientSecret.toUtf8().data(), &session);
    });
}

void BitSailorCore::loginEmailPassword(const QString &email, const QString &password)
{
    AuthLogger::log(QStringLiteral("BitSailorCore: loginEmailPassword requested emailPresent=%1 passwordPresent=%2 emailLength=%3").arg(
        email.isEmpty() ? QStringLiteral("false") : QStringLiteral("true"),
        password.isEmpty() ? QStringLiteral("false") : QStringLiteral("true"),
        QString::number(email.size())
    ));
    login([=] {
        return BitwardenLoginPassword(client, ctx, email.toUtf8().data(), password.toUtf8().data(), &session);
    });
}

void BitSailorCore::logout()
{
    AuthLogger::log(QStringLiteral("BitSailorCore: logout requested sessionPresent=%1").arg(
        session == 0 ? QStringLiteral("false") : QStringLiteral("true")
    ));
    QtConcurrent::run([=] {
        if (BitwardenCloseHandle(session) != BitwardenSuccess) {
            const auto error = getLastError();
            qWarning() << "Failed closing session: " << error;
            AuthLogger::log(QStringLiteral("BitSailorCore: logout close session failed error=%1").arg(error));
        }

        session = 0;
        secrets->clearAllSecrets();
        initialize();

        AuthLogger::log(QStringLiteral("BitSailorCore: logout finished"));
        emit logoutFinished();
    });
}

void BitSailorCore::unlockVault(const QString &password)
{
    AuthLogger::log(QStringLiteral("BitSailorCore: unlockVault(password) requested passwordPresent=%1 sessionPresent=%2").arg(
        password.isEmpty() ? QStringLiteral("false") : QStringLiteral("true"),
        session == 0 ? QStringLiteral("false") : QStringLiteral("true")
    ));
    QtConcurrent::run([=] {
        const auto email = getEmail();
        if (email.isNull() || email.isEmpty()) {
            AuthLogger::log(QStringLiteral("BitSailorCore: unlockVault failed reason=email-missing"));
            emit couldNotFetchEmail();
            return;
        }

        AuthLogger::log(QStringLiteral("BitSailorCore: BitwardenUnlockSession starting emailPresent=true passwordPresent=%1").arg(
            password.isEmpty() ? QStringLiteral("false") : QStringLiteral("true")
        ));
        if (BitwardenUnlockSession(client, ctx, session, email.toUtf8().data(), password.toUtf8().data()) != BitwardenSuccess) {
            auto error = getLastError();
            qWarning() << "Failed unlocking session: " << error;
            AuthLogger::log(QStringLiteral("BitSailorCore: BitwardenUnlockSession failed error=%1").arg(error));
            emit unlockFinished(false, error);
            return;
        }
        AuthLogger::log(QStringLiteral("BitSailorCore: BitwardenUnlockSession succeeded"));

        QString exportError;
        exportSession(&exportError);
        if (!exportError.isNull()) {
            qWarning() << "Failed exporting session: " << exportError;
            AuthLogger::log(QStringLiteral("BitSailorCore: unlockVault exportSession failed error=%1").arg(exportError));
        }

        AuthLogger::log(QStringLiteral("BitSailorCore: unlockVault result success=true"));
        emit unlockFinished(true, "");
    });
}

void BitSailorCore::unlockVault(int pin)
{
    AuthLogger::log(QStringLiteral("BitSailorCore: unlockVault(pin) requested"));
    QtConcurrent::run([=] {
        auto providedPin = QString::number(pin);
        auto storedPin = secrets->getPin();

        if (providedPin != storedPin) {
            AuthLogger::log(QStringLiteral("BitSailorCore: unlockVault(pin) failed reason=pin-mismatch storedPinPresent=%1").arg(
                storedPin.isEmpty() ? QStringLiteral("false") : QStringLiteral("true")
            ));
            emit wrongPinProvided();
            return;
        }
        AuthLogger::log(QStringLiteral("BitSailorCore: unlockVault(pin) matched stored pin, unlocking with stored password"));

        auto password = secrets->getPassword();

        unlockVault(password);
    });
}

void BitSailorCore::unlockVault()
{
    AuthLogger::log(QStringLiteral("BitSailorCore: unlockVault(system-auth) requested"));
    QtConcurrent::run([=] {
        auto password = secrets->getPassword();
        AuthLogger::log(QStringLiteral("BitSailorCore: unlockVault(system-auth) fetched stored password present=%1").arg(
            password.isEmpty() ? QStringLiteral("false") : QStringLiteral("true")
        ));
        unlockVault(password);
    });
}

void BitSailorCore::validateMasterPassword(const QString &password)
{
    AuthLogger::log(QStringLiteral("BitSailorCore: validateMasterPassword requested passwordPresent=%1").arg(
        password.isEmpty() ? QStringLiteral("false") : QStringLiteral("true")
    ));
    QtConcurrent::run([=] {
        auto email = getEmail();
        if (email.isNull()) {
            qWarning() << "Failed fetching email";
            AuthLogger::log(QStringLiteral("BitSailorCore: validateMasterPassword failed reason=email-missing"));
            emit couldNotFetchEmail();
            return;
        }

        if (BitwardenValidatePassword(client, ctx, email.toUtf8().data(), password.toUtf8().data(), session) != BitwardenSuccess) {
            const auto error = getLastError();
            qWarning () << "Validation of password did not succeed: " << error;
            AuthLogger::log(QStringLiteral("BitSailorCore: BitwardenValidatePassword failed error=%1").arg(error));
            emit masterPasswordValidationFinished(false);
            return;
        }

        AuthLogger::log(QStringLiteral("BitSailorCore: BitwardenValidatePassword succeeded"));
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
            result.append(mapItem(item));
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
            result.append(mapSend(item));
        }
        BitwardenFreeSends(&items);

        emit sendsResolved(true, result);
    });
}

void BitSailorCore::createItem(const QJsonObject &item)
{
    QtConcurrent::run([=] {
        auto input = BitwardenItemInput({}, item);
        if (BitwardenCreateItem(vault, ctx, session, &input.item, nullptr) != BitwardenSuccess) {
            qWarning() << "Failed creating item: " << getLastError();
            emit itemCreationFinished(false);
            return;
        }

        QString exportError;
        exportVault(&exportError);
        if (!exportError.isNull()) {
            qWarning() << "Failed exporting vault after item creation: " << exportError;
            emit itemCreationFinished(false);
            return;
        }

        emit itemCreationFinished(true);
    });
}

void BitSailorCore::createTextSend(
        const QString &name,
        const QString &text,
        bool hideText,
        int deletionDate,
        int maximumAccessCount,
        const QString &password,
        bool hideEmail,
        const QString &notes
) {
    QtConcurrent::run([=] {
        BitwardenSendInput input(BitwardenSendTypeText, name, deletionDate, maximumAccessCount, password, hideEmail, notes);
        input.setText(text, hideText);

        BitwardenSend out = {};
        if (BitwardenCreateSend(vault, ctx, session, &input.send, &out) != BitwardenSuccess) {
            qWarning() << "Failed creating text send: " << getLastError();
            emit sendCreated(false, {});
            return;
        }

        BitwardenSend created = {};
        if (BitwardenGetSend(vault, ctx, session, out.id, &created) != BitwardenSuccess) {
            qWarning() << "Failed fetching created text send: " << getLastError();
            BitwardenFreeSend(&out);
            emit sendCreated(false, {});
            return;
        }

        auto result = mapSend(created);
        BitwardenFreeSend(&out);
        BitwardenFreeSend(&created);

        QString exportError;
        exportVault(&exportError);
        if (!exportError.isNull()) {
            qWarning() << "Failed exporting vault after send creation: " << exportError;
            emit sendCreated(false, {});
            return;
        }

        emit sendCreated(true, result);
    });
}

void BitSailorCore::createFileSend(
        const QString &name,
        const QString &filePath,
        int deletionDate,
        int maximumAccessCount,
        const QString &password,
        bool hideEmail,
        const QString &notes
) {
    QtConcurrent::run([=] {
        BitwardenSendInput input(BitwardenSendTypeFile, name, deletionDate, maximumAccessCount, password, hideEmail, notes);
        input.setFile(filePath);

        BitwardenSend out = {};
        if (BitwardenCreateSend(vault, ctx, session, &input.send, &out) != BitwardenSuccess) {
            qWarning() << "Failed creating file send: " << getLastError();
            emit sendCreated(false, {});
            return;
        }

        BitwardenSend created = {};
        if (BitwardenGetSend(vault, ctx, session, out.id, &created) != BitwardenSuccess) {
            qWarning() << "Failed fetching created file send: " << getLastError();
            BitwardenFreeSend(&out);
            emit sendCreated(false, {});
            return;
        }

        auto result = mapSend(created);
        BitwardenFreeSend(&out);
        BitwardenFreeSend(&created);

        QString exportError;
        exportVault(&exportError);
        if (!exportError.isNull()) {
            qWarning() << "Failed exporting vault after send creation: " << exportError;
            emit sendCreated(false, {});
            return;
        }

        emit sendCreated(true, result);
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

void BitSailorCore::deleteSend(const QString &id, bool emitEvents)
{
    QtConcurrent::run([=] {
        if (BitwardenDeleteSend(vault, ctx, session, uuidToCoreUuid(qUuidFromString(id))) != BitwardenSuccess) {
            qWarning() << "Failed deleting send: " << getLastError();
            if (emitEvents) {
                emit sendDeletingFinished(false);
            }
            return;
        }

        QString exportError;
        exportVault(&exportError);
        if (!exportError.isNull()) {
            qWarning() << "Failed exporting vault after send deletion: " << exportError;
            if (emitEvents) {
                emit sendDeletingFinished(false);
            }
            return;
        }

        if (emitEvents) {
            emit sendDeletingFinished(true);
        }
    });
}

void BitSailorCore::fetchItem(const QString &id)
{
    QtConcurrent::run([=] {
        auto uuid = uuidToCoreUuid(qUuidFromString(id));
        BitwardenItem item;
        if (BitwardenGetItem(vault, ctx, session, uuid, &item) != BitwardenSuccess) {
            qWarning() << "Failed fetching item: " << getLastError();
            emit itemFetchFinished(false, {});
            return;
        }

        auto result = mapItem(item);
        BitwardenFreeItem(&item);

        emit itemFetchFinished(true, result);
    });
}

void BitSailorCore::updateItem(const QString &id, const QJsonObject &item)
{
    QtConcurrent::run([=] {
        auto input = BitwardenItemInput(uuidToCoreUuid(qUuidFromString(id)), item);
        if (BitwardenUpdateItem(vault, ctx, session, &input.item, nullptr) != BitwardenSuccess) {
            qWarning() << "Failed updating item: " << getLastError();
            emit itemUpdated(false);
            return;
        }

        QString exportError;
        exportVault(&exportError);
        if (!exportError.isNull()) {
            qWarning() << "Failed exporting vault after item update: " << exportError;
            emit itemUpdated(false);
            return;
        }

        emit itemUpdated(true);
    });
}

void BitSailorCore::generatePassword(
        bool lowercase,
        bool uppercase,
        bool numbers,
        bool special,
        bool avoidAmbiguous,
        int minimumNumbers,
        int minimumSpecial,
        int length
) {
    QtConcurrent::run([=] {
        bool lowercaseCopy = lowercase;
        bool uppercaseCopy = uppercase;
        bool numbersCopy = numbers;
        bool specialCopy = special;
        bool avoidAmbiguousCopy = avoidAmbiguous;
        int minimumNumbersCopy = minimumNumbers;
        int minimumSpecialCopy = minimumSpecial;
        int lengthCopy = length;

        BitwardenPasswordGeneratorRequest req = {
            .lowercase = &lowercaseCopy,
            .uppercase = &uppercaseCopy,
            .numbers = &numbersCopy,
            .special = &specialCopy,

            .length = &lengthCopy,

            .avoidAmbiguous = &avoidAmbiguousCopy,
            .minNumber = &minimumNumbersCopy,
            .minSpecial = &minimumSpecialCopy,
        };

        char* out = nullptr;
        if (BitwardenGeneratePassword(client, req, &out) != BitwardenSuccess) {
            qWarning() << "Failed generating password: " << getLastError();
            emit passwordGeneratingFinished(false, "");
            return;
        }

        auto outStr = QString::fromUtf8(out);
        std::free(out);

        emit passwordGeneratingFinished(true, outStr);
    });
}

void BitSailorCore::generatePassphrase(uint wordsCount, bool capitalize, bool includeNumber, const QString &separator)
{
    QtConcurrent::run([=] {
        int wordsCountCopy = wordsCount;
        bool capitalizeCopy = capitalize;
        bool includeNumberCopy = includeNumber;
        QByteArray separatorCopy = separator.toUtf8();

        BitwardenPassphraseGeneratorRequest req = {
            .numWords = &wordsCountCopy,
            .wordSeparator = separatorCopy.data(),
            .capitalize = &capitalizeCopy,
            .includeNumber = &includeNumberCopy,
        };

        char *out = nullptr;
        if (BitwardenGeneratePassphrase(client, req, &out) != BitwardenSuccess) {
            qWarning() << "Failed generating passphrase: " << getLastError();
            emit passphraseGeneratingFinished(false, "");
            return;
        }

        auto outStr = QString::fromUtf8(out);
        std::free(out);

        emit passphraseGeneratingFinished(true, outStr);
    });
}

void BitSailorCore::syncVault()
{
    AuthLogger::log(QStringLiteral("BitSailorCore: syncVault requested"));
    QtConcurrent::run([=] {
        if (!syncRaw()) {
            AuthLogger::log(QStringLiteral("BitSailorCore: syncVault result success=false"));
            emit syncVaultFinished(false);
            return;
        }

        AuthLogger::log(QStringLiteral("BitSailorCore: syncVault result success=true"));
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
    AuthLogger::log(QStringLiteral("BitSailorCore: initialize starting"));
    valid = true;
    cleanup();

    if (settings->deviceUuid() == "") {
        settings->setDeviceUuid(uuidToString(generateUuid()));
        AuthLogger::log(QStringLiteral("BitSailorCore: initialize generated new device UUID"));
#ifdef QT_DEBUG
        qDebug() << "Device ID: " << settings->deviceUuid();
#endif
    }

    if (BitwardenNewContext(&ctx) != BitwardenSuccess) {
        valid = false;
        const auto error = getLastError();
        qWarning() << "Failed initializing context: " << error;
        AuthLogger::log(QStringLiteral("BitSailorCore: BitwardenNewContext failed error=%1").arg(error));
    } else {
        AuthLogger::log(QStringLiteral("BitSailorCore: BitwardenNewContext succeeded"));
    }

    auto baseUrl = settings->baseUrl().toUtf8();
    const auto configuredBaseUrl = settings->baseUrl();
    if (baseUrl == defaultVaultUrl) {
        baseUrl.clear();
    }

    bool ignoreCerts = secrets->invalidCertificatesAllowed();
    auto uuid = uuidFromString(settings->deviceUuid());
    AuthLogger::log(QStringLiteral("BitSailorCore: BitwardenNewClient starting baseUrl=%1 defaultBaseUrl=%2 ignoreCerts=%3 deviceUuidPresent=%4").arg(
        configuredBaseUrl,
        configuredBaseUrl == defaultVaultUrl ? QStringLiteral("true") : QStringLiteral("false"),
        ignoreCerts ? QStringLiteral("true") : QStringLiteral("false"),
        settings->deviceUuid().isEmpty() ? QStringLiteral("false") : QStringLiteral("true")
    ));
    if (BitwardenNewClient(&client, NewClientOptions {
        .baseUrl = baseUrl.constData(),
        .deviceId = &uuid,
        .ignoreCerts = &ignoreCerts,
    }) != BitwardenSuccess) {
        valid = false;
        const auto error = getLastError();
        qWarning() << "Failed initializing client: " << error;
        AuthLogger::log(QStringLiteral("BitSailorCore: BitwardenNewClient failed error=%1").arg(error));
    } else {
        AuthLogger::log(QStringLiteral("BitSailorCore: BitwardenNewClient succeeded"));
    }

    if (BitwardenGetVault(client, &vault) != BitwardenSuccess) {
        valid = false;
        const auto error = getLastError();
        qWarning() << "Failded getting a vault: " << error;
        AuthLogger::log(QStringLiteral("BitSailorCore: BitwardenGetVault failed error=%1").arg(error));
    } else {
        AuthLogger::log(QStringLiteral("BitSailorCore: BitwardenGetVault succeeded"));
    }

    const auto hasSessionJson = secrets->hasSessionJson();
    AuthLogger::log(QStringLiteral("BitSailorCore: initialize stored session present=%1").arg(
        hasSessionJson ? QStringLiteral("true") : QStringLiteral("false")
    ));
    if (hasSessionJson) {
        auto json = secrets->getSessionJson();
#ifdef QT_DEBUG
        qDebug() << "Session JSON: " << json;
#endif
        if (json.isEmpty()) {
            qWarning() << "The session json is empty";
            AuthLogger::log(QStringLiteral("BitSailorCore: stored session JSON is empty"));
        }
        auto jsonStr = QJsonDocument(json).toJson();
        AuthLogger::log(QStringLiteral("BitSailorCore: BitwardenImportSession starting jsonKeys=%1 jsonBytes=%2").arg(
            QString::number(json.size()),
            QString::number(jsonStr.size())
        ));
        if (BitwardenImportSession(nullptr, jsonStr.data(), &session) != BitwardenSuccess) {
            valid = false;
            const auto error = getLastError();
            qWarning() << "Failed importing session: " << error;
            AuthLogger::log(QStringLiteral("BitSailorCore: BitwardenImportSession failed error=%1").arg(error));
        } else {
            AuthLogger::log(QStringLiteral("BitSailorCore: BitwardenImportSession succeeded"));
        }
    }

    const auto hasEncryptedVault = secrets->hasEncryptedVault();
    AuthLogger::log(QStringLiteral("BitSailorCore: initialize encrypted vault present=%1").arg(
        hasEncryptedVault ? QStringLiteral("true") : QStringLiteral("false")
    ));
    if (hasEncryptedVault) {
        auto json = secrets->getEncryptedVault();
        if (json.isEmpty()) {
            qWarning() << "The session json is empty";
            AuthLogger::log(QStringLiteral("BitSailorCore: stored encrypted vault JSON is empty"));
        }
        auto jsonStr = QJsonDocument(json).toJson();
        VaultHandle newVault;
        AuthLogger::log(QStringLiteral("BitSailorCore: BitwardenImportVault starting jsonKeys=%1 jsonBytes=%2").arg(
            QString::number(json.size()),
            QString::number(jsonStr.size())
        ));
        if (BitwardenImportVault(vault, jsonStr.data(), &newVault) != BitwardenSuccess) {
            valid = false;
            const auto error = getLastError();
            qWarning() << "Failed importing session: " << error;
            AuthLogger::log(QStringLiteral("BitSailorCore: BitwardenImportVault failed error=%1").arg(error));
        } else {
            if (BitwardenCloseHandle(vault) != BitwardenSuccess) {
                const auto error = getLastError();
                qWarning() << "Failed closing vault handle: " << error;
                AuthLogger::log(QStringLiteral("BitSailorCore: closing old vault after import failed error=%1").arg(error));
            }
            vault = newVault;
            AuthLogger::log(QStringLiteral("BitSailorCore: BitwardenImportVault succeeded"));
        }
    }
    AuthLogger::log(QStringLiteral("BitSailorCore: initialize finished valid=%1 ctx=%2 client=%3 session=%4 vault=%5").arg(
        valid ? QStringLiteral("true") : QStringLiteral("false"),
        ctx == 0 ? QStringLiteral("false") : QStringLiteral("true"),
        client == 0 ? QStringLiteral("false") : QStringLiteral("true"),
        session == 0 ? QStringLiteral("false") : QStringLiteral("true"),
        vault == 0 ? QStringLiteral("false") : QStringLiteral("true")
    ));
}

void BitSailorCore::getServerUrl()
{
    QtConcurrent::run([=] {
        emit serverUrlResolved(settings->baseUrl());
    });
}

void BitSailorCore::cleanup()
{
    AuthLogger::log(QStringLiteral("BitSailorCore: cleanup starting ctx=%1 client=%2 session=%3 vault=%4").arg(
        ctx == 0 ? QStringLiteral("false") : QStringLiteral("true"),
        client == 0 ? QStringLiteral("false") : QStringLiteral("true"),
        session == 0 ? QStringLiteral("false") : QStringLiteral("true"),
        vault == 0 ? QStringLiteral("false") : QStringLiteral("true")
    ));
    if (ctx != 0 && BitwardenCloseHandle(ctx) != BitwardenSuccess) {
        const auto error = getLastError();
        qWarning() << "Failed closing context: " << error;
        AuthLogger::log(QStringLiteral("BitSailorCore: cleanup close context failed error=%1").arg(error));
    }
    if (client != 0 && BitwardenCloseHandle(client) != BitwardenSuccess) {
        const auto error = getLastError();
        qWarning() << "Failed closing client: " << error;
        AuthLogger::log(QStringLiteral("BitSailorCore: cleanup close client failed error=%1").arg(error));
    }
    if (session != 0 && BitwardenCloseHandle(session) != BitwardenSuccess) {
        const auto error = getLastError();
        qWarning() << "Failed closing session: " << error;
        AuthLogger::log(QStringLiteral("BitSailorCore: cleanup close session failed error=%1").arg(error));
    }
    if (vault != 0 && BitwardenCloseHandle(vault) != BitwardenSuccess) {
        const auto error = getLastError();
        qWarning() << "Failed closing vault: " << error;
        AuthLogger::log(QStringLiteral("BitSailorCore: cleanup close vault failed error=%1").arg(error));
    }

    ctx = 0;
    client = 0;
    session = 0;
    vault = 0;
    email = "";
    AuthLogger::log(QStringLiteral("BitSailorCore: cleanup finished"));
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
        AuthLogger::log(QStringLiteral("BitSailorCore: getEmail returning cached email"));
        return email;
    }

    AuthLogger::log(QStringLiteral("BitSailorCore: BitwardenGetEmail starting vaultPresent=%1").arg(
        vault == 0 ? QStringLiteral("false") : QStringLiteral("true")
    ));
    char *out = nullptr;
    if (BitwardenGetEmail(vault, &out) != BitwardenSuccess) {
        AuthLogger::log(QStringLiteral("BitSailorCore: BitwardenGetEmail failed, attempting sync error=%1").arg(getLastError()));
        if (!syncRaw()) {
            qWarning() << "Failed syncing";
            AuthLogger::log(QStringLiteral("BitSailorCore: getEmail sync failed"));
            return QString();
        }
        if (BitwardenGetEmail(vault, &out) != BitwardenSuccess) {
            qWarning() << "Failed getting email even after sync";
            AuthLogger::log(QStringLiteral("BitSailorCore: BitwardenGetEmail failed after sync error=%1").arg(getLastError()));
            return QString();
        }
    }

    const auto result = QString::fromUtf8(out);
    free(out);

    AuthLogger::log(QStringLiteral("BitSailorCore: BitwardenGetEmail succeeded emailPresent=%1 emailLength=%2").arg(
        result.isEmpty() ? QStringLiteral("false") : QStringLiteral("true"),
        QString::number(result.size())
    ));
    return result;
}

void BitSailorCore::login(const std::function<BitwardenResult ()> &loginCallable)
{
    QtConcurrent::run([=] {
        AuthLogger::log(QStringLiteral("BitSailorCore: login callable starting ctx=%1 client=%2 currentSession=%3").arg(
            ctx == 0 ? QStringLiteral("false") : QStringLiteral("true"),
            client == 0 ? QStringLiteral("false") : QStringLiteral("true"),
            session == 0 ? QStringLiteral("false") : QStringLiteral("true")
        ));
        auto result = loginCallable();
        if (result != BitwardenSuccess) {
            auto error = getLastError();
            if (error == twoFactorNeededError) {
                AuthLogger::log(QStringLiteral("BitSailorCore: login failed reason=two-factor-needed"));
                emit twoFactorNeeded();
                return;
            }
            qWarning() << "Login failed: " << error;
            AuthLogger::log(QStringLiteral("BitSailorCore: login failed error=%1").arg(error));
            emit loginFinished(false, error);
            return;
        }
        AuthLogger::log(QStringLiteral("BitSailorCore: login callable succeeded sessionPresent=%1").arg(
            session == 0 ? QStringLiteral("false") : QStringLiteral("true")
        ));

        QString exportError;
        exportSession(&exportError);
        if (!exportError.isNull()) {
            qWarning() << "Login failed: " << exportError;
            AuthLogger::log(QStringLiteral("BitSailorCore: login exportSession failed error=%1").arg(exportError));
            emit loginFinished(false, exportError);
            return;
        }

        AuthLogger::log(QStringLiteral("BitSailorCore: login result success=true"));
        emit loginFinished(true, "");
    });
}

bool BitSailorCore::syncRaw()
{
    AuthLogger::log(QStringLiteral("BitSailorCore: syncRaw starting client=%1 ctx=%2 session=%3 vault=%4").arg(
        client == 0 ? QStringLiteral("false") : QStringLiteral("true"),
        ctx == 0 ? QStringLiteral("false") : QStringLiteral("true"),
        session == 0 ? QStringLiteral("false") : QStringLiteral("true"),
        vault == 0 ? QStringLiteral("false") : QStringLiteral("true")
    ));
    if (vault != 0) {
        if (BitwardenCloseHandle(vault) != BitwardenSuccess) {
            const auto error = getLastError();
            qWarning() << "Failed closing vault: " << error;
            AuthLogger::log(QStringLiteral("BitSailorCore: syncRaw close existing vault failed error=%1").arg(error));
        }
    }

    if (BitwardenSyncVault(client, ctx, session, &vault) != BitwardenSuccess) {
        const auto error = getLastError();
        qWarning() << "Failed syncing: " << error;
        AuthLogger::log(QStringLiteral("BitSailorCore: BitwardenSyncVault failed error=%1").arg(error));
        return false;
    }
    AuthLogger::log(QStringLiteral("BitSailorCore: BitwardenSyncVault succeeded vaultPresent=%1").arg(
        vault == 0 ? QStringLiteral("false") : QStringLiteral("true")
    ));

    QString exportError;
    exportVault(&exportError);
    if (!exportError.isNull()) {
        qWarning() << "Failed exporting vault after sync: " << exportError;
        AuthLogger::log(QStringLiteral("BitSailorCore: syncRaw exportVault failed error=%1").arg(exportError));
        return false;
    }

    AuthLogger::log(QStringLiteral("BitSailorCore: syncRaw result success=true"));
    return true;
}

void BitSailorCore::exportSession(QString *error)
{
    AuthLogger::log(QStringLiteral("BitSailorCore: exportSession starting sessionPresent=%1").arg(
        session == 0 ? QStringLiteral("false") : QStringLiteral("true")
    ));
    char* rawExport = nullptr;
    if (BitwardenExportSession(session, &rawExport) != BitwardenSuccess) {
        *error = getLastError();
        qWarning() << "Exporting session failed: " << *error;
        AuthLogger::log(QStringLiteral("BitSailorCore: BitwardenExportSession failed error=%1").arg(*error));
        return;
    }
    QJsonParseError err;
    const auto rawBytes = QByteArray(rawExport).size();
    auto sessionJson = QJsonDocument::fromJson(QByteArray(rawExport), &err);
    free(rawExport);

    if (err.error) {
        *error = err.errorString();
        qWarning() << "Failed parsing exported session JSON: " << *error;
        AuthLogger::log(QStringLiteral("BitSailorCore: exportSession JSON parse failed error=%1 rawBytes=%2").arg(
            *error,
            QString::number(rawBytes)
        ));
        return;
    }

    AuthLogger::log(QStringLiteral("BitSailorCore: exportSession parsed keys=%1 rawBytes=%2").arg(
        QString::number(sessionJson.object().size()),
        QString::number(rawBytes)
    ));
    secrets->setSessionJson(sessionJson.object());
    AuthLogger::log(QStringLiteral("BitSailorCore: exportSession stored"));
}

void BitSailorCore::exportVault(QString *error)
{
    AuthLogger::log(QStringLiteral("BitSailorCore: exportVault starting vaultPresent=%1").arg(
        vault == 0 ? QStringLiteral("false") : QStringLiteral("true")
    ));
    char *rawExport = nullptr;
    if (BitwardenExportEncryptedVault(vault, &rawExport) != BitwardenSuccess) {
        *error = getLastError();
        qWarning() << "Exporting vault failed: " << *error;
        AuthLogger::log(QStringLiteral("BitSailorCore: BitwardenExportEncryptedVault failed error=%1").arg(*error));
        return;
    }

    QJsonParseError err;
    const auto rawBytes = QByteArray(rawExport).size();
    const auto vaultJson = QJsonDocument::fromJson(QByteArray(rawExport), &err);
    free(rawExport);

    if (err.error || !vaultJson.isObject()) {
        *error = err.error ? err.errorString() : QString("Exported vault JSON is not an object");
        qWarning() << "Failed parsing exported vault JSON: " << *error;
        AuthLogger::log(QStringLiteral("BitSailorCore: exportVault JSON parse failed error=%1 rawBytes=%2 isObject=%3").arg(
            *error,
            QString::number(rawBytes),
            vaultJson.isObject() ? QStringLiteral("true") : QStringLiteral("false")
        ));
        return;
    }

    AuthLogger::log(QStringLiteral("BitSailorCore: exportVault parsed keys=%1 rawBytes=%2").arg(
        QString::number(vaultJson.object().size()),
        QString::number(rawBytes)
    ));
    secrets->setEncryptedVault(vaultJson.object());
    AuthLogger::log(QStringLiteral("BitSailorCore: exportVault stored"));
}

QJsonObject BitSailorCore::mapItem(const BitwardenItem &item) const
{
    QJsonObject outItem;
    outItem.insert("id", uuidToString(item.id));
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
                outUri.insert("match", uri.match);
                uris.append(outUri);
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
    } else if(item.type == BitwardenItemTypeIdentity) {
        QJsonObject identity;
        identity.insert("title", item.identity->title);
        identity.insert("firstName", item.identity->firstName);
        identity.insert("middleName", item.identity->middleName);
        identity.insert("lastName", item.identity->lastName);
        identity.insert("username", item.identity->username);
        identity.insert("company", item.identity->company);
        identity.insert("ssn", item.identity->ssn);
        identity.insert("passportNumber", item.identity->passportNumber);
        identity.insert("licenseNumber", ""); // todo license number?
        identity.insert("email", item.identity->email);
        identity.insert("phone", item.identity->phone);
        identity.insert("address1", item.identity->addressLine1);
        identity.insert("address2", item.identity->addressLine2);
        identity.insert("address3", item.identity->addressLine3);
        identity.insert("city", item.identity->city);
        identity.insert("state", item.identity->state);
        identity.insert("city", item.identity->city);
        identity.insert("postalCode", item.identity->postalCode);
        identity.insert("country", item.identity->country);
        outItem.insert("identity", identity);
    }

    return outItem;
}

QJsonObject BitSailorCore::mapSend(const BitwardenSend &send) const
{
    QJsonObject outSend;
    outSend.insert("id", uuidToString(send.id));
    outSend.insert("name", send.name);
    outSend.insert("type", send.type);
    outSend.insert("deletionDate", cTimeToQDate(send.deletionDate).toUTC().toString(Qt::ISODate));
    outSend.insert("accessUrl", send.accessUrl);

    return outSend;
}
