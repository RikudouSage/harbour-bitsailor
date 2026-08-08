#include "bitsailorcore.h"

#include <cstring>
#include <cstdlib>
#include <vector>
#include <QDebug>
#include <QFileInfo>
#include <QJsonDocument>
#include <QtConcurrent>
#include <QJsonParseError>

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

void BitSailorCore::loginEmailPassword(const QString &email, const QString &password, const QString &twoFaCode)
{
    login([=] {
        return BitwardenLoginPassword(
            client,
            ctx,
            email.toUtf8().data(),
            password.toUtf8().data(),
            twoFaCode.toUtf8().data(),
            &session
        );
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
        const auto legacyPassword = secrets->getPassword();
        const auto migrateLegacyPassword = !legacyPassword.isNull() && !legacyPassword.isEmpty() && legacyPassword == password;

        QString error;
        if (!unlockWithPassword(password, &error)) {
            emit unlockFinished(false, error);
            return;
        }

        if (migrateLegacyPassword) {
            if (!migrateLegacyPasswordToUserKey()) {
                qWarning() << "Failed migrating stored password to user key.";
            }
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

        QString error;
        if (secrets->hasUserKey()) {
            if (!unlockWithStoredUserKey(&error)) {
                qWarning() << "Failed unlocking session using stored user key: " << error;
                emit unlockFinished(false, error);
            } else {
                emit unlockFinished(true, "");
            }
            return;
        }

        auto password = secrets->getPassword();
        if (password.isNull() || password.isEmpty()) {
            emit unlockFinished(false, tr("Stored unlock key is missing."));
            return;
        }

        if (!unlockWithPassword(password, &error)) {
            emit unlockFinished(false, error);
            return;
        }

        if (!migrateLegacyPasswordToUserKey()) {
            qWarning() << "Failed migrating stored password to user key.";
        }

        emit unlockFinished(true, "");
    });
}

void BitSailorCore::unlockVault()
{
    QtConcurrent::run([=] {
        QString error;
        if (secrets->hasUserKey()) {
            if (!unlockWithStoredUserKey(&error)) {
                qWarning() << "Failed unlocking session using stored user key: " << error;
                emit unlockFinished(false, error);
            } else {
                emit unlockFinished(true, "");
            }
            return;
        }

        auto password = secrets->getPassword();
        if (password.isNull() || password.isEmpty()) {
            emit unlockFinished(false, tr("Stored unlock key is missing."));
            return;
        }

        if (!unlockWithPassword(password, &error)) {
            emit unlockFinished(false, error);
            return;
        }

        if (!migrateLegacyPasswordToUserKey()) {
            qWarning() << "Failed migrating stored password to user key.";
        }

        emit unlockFinished(true, "");
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

bool BitSailorCore::unlockWithPassword(const QString &password, QString *error)
{
    const auto email = getEmail();
    if (email.isNull() || email.isEmpty()) {
        emit couldNotFetchEmail();
        return false;
    }

    auto emailBytes = email.toUtf8();
    auto passwordBytes = password.toUtf8();
    if (BitwardenUnlockSession(client, ctx, session, emailBytes.data(), passwordBytes.data()) != BitwardenSuccess) {
        *error = getLastError();
        qWarning() << "Failed unlocking session: " << *error;
        return false;
    }

    QString exportError;
    exportSession(&exportError);
    if (!exportError.isNull()) {
        qWarning() << "Failed exporting session: " << exportError;
    }

    return true;
}

bool BitSailorCore::unlockWithStoredUserKey(QString *error)
{
    const auto userKey = secrets->getUserKey();
    if (userKey.isNull() || userKey.isEmpty()) {
        *error = tr("Stored unlock key is missing.");
        return false;
    }

    auto userKeyBytes = userKey.toUtf8();
    if (BitwardenUnlockSessionWithUserKey(session, userKeyBytes.data()) != BitwardenSuccess) {
        *error = getLastError();
        return false;
    }

    QString exportError;
    exportSession(&exportError);
    if (!exportError.isNull()) {
        qWarning() << "Failed exporting session: " << exportError;
    }

    return true;
}

bool BitSailorCore::migrateLegacyPasswordToUserKey()
{
    return secrets->storeUserKeyFromSessionJson();
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

void BitSailorCore::fetchAuthRequest(const QString &id)
{
    QtConcurrent::run([=] {
        auto uuid = uuidFromString(id);
        Handle request = 0;
        char *fingerPrintPhrase = nullptr;
        if (BitwardenFetchAuthRequest(client, vault, ctx, session, uuid, &request, &fingerPrintPhrase) != BitwardenSuccess) {
            emit authRequestFetchFinished(false);
            qWarning() << "Failed fetching auth request: " << getLastError();

            return;
        }

        auto fingerPrintPhraseStr = QString::fromUtf8(fingerPrintPhrase);
        std::free(fingerPrintPhrase);

        emit authRequestFetchFinished(true, request, fingerPrintPhraseStr);
    });
}

void BitSailorCore::answerToFetchRequest(int handle, bool approve)
{
    QtConcurrent::run([=] {
        if (BitwardenRespondToAuthRequest(client, ctx, session, handle, approve) != BitwardenSuccess) {
            qWarning() << "Failed responding to auth request: " << getLastError();
            emit authRequestApprovalSendFinished(false);
            return;
        }

        if (BitwardenCloseHandle(handle) != BitwardenSuccess) {
            qWarning() << "Failed closing the request handle: " << getLastError();
        }

        emit authRequestApprovalSendFinished(true);
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

void BitSailorCore::initialize(bool withNotifications)
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

    bool ignoreCerts = secrets->invalidCertificatesAllowed();
    auto uuid = uuidFromString(settings->deviceUuid());
    if (BitwardenNewClient(&client, NewClientOptions {
        .baseUrl = baseUrl.constData(),
        .deviceId = &uuid,
        .ignoreCerts = &ignoreCerts,
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

    if (withNotifications) {
        initializeNotifications();
    }
}

void BitSailorCore::initializeNotifications()
{
    QtConcurrent::run([=] {
        if (BitwardenStartNotifications(client, ctx, session) != BitwardenSuccess) {
            qWarning() << "Failed starting notification service: " << getLastError();
        } else {
            registerListeners();
        }
    });
}

void BitSailorCore::getServerUrl()
{
    QtConcurrent::run([=] {
        emit serverUrlResolved(settings->baseUrl());
    });
}

void BitSailorCore::cleanup()
{
    for (const auto subscription : notificationSubscriptions) {
        if (BitwardenRemoveNotificationHandler(subscription) != BitwardenSuccess) {
            qWarning() << "Failed removing notification handler: " << getLastError();
        }
    }
    notificationSubscriptions.clear();
    if (client != 0 && BitwardenStopNotifications(client, ctx) != BitwardenSuccess) {
        qWarning() << "Failed stopping notifications: " << getLastError();
    }

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

void BitSailorCore::registerListeners()
{
    auto syncCallback = [](void *userData, const BitwardenNotification* notification) -> BitwardenResult {
        auto self = static_cast<BitSailorCore*>(userData);

        qDebug() << "Got sync notification, syncing";
        self->syncVault();

        return BitwardenSuccess;
    };

    const auto wantedSyncListeners = QList<BitwardenNotificationType>({
        BitwardenNotificationSyncCipherUpdate,
        BitwardenNotificationSyncCipherCreate,
        BitwardenNotificationSyncLoginDelete,
        BitwardenNotificationSyncCiphers,
        BitwardenNotificationSyncVault,
        BitwardenNotificationSyncOrgKeys,
        BitwardenNotificationSyncCipherDelete,
        BitwardenNotificationSyncSettings,
        BitwardenNotificationSyncSendCreate,
        BitwardenNotificationSyncSendUpdate,
        BitwardenNotificationSyncSendDelete,
        BitwardenNotificationSyncOrganizations,
        BitwardenNotificationSyncOrganizationStatusChanged,
        BitwardenNotificationSyncOrganizationCollectionSettingChanged,
        BitwardenNotificationSyncPolicy,
    });

    for (const auto listenerType : wantedSyncListeners) {
        NotificationSubscriptionHandle handle;
        if (BitwardenAddNotificationHandler(client, listenerType, syncCallback, this, &handle) != BitwardenSuccess) {
            qWarning() << "Failed attaching a handler for type " << listenerType << ": " << getLastError();
        } else {
            notificationSubscriptions.append(handle);
        }
    }

    NotificationSubscriptionHandle logoutHandle;
    if (BitwardenAddNotificationHandler(client, BitwardenNotificationLogOut, [](void *userData, const BitwardenNotification* notification) -> BitwardenResult {
        Q_UNUSED(notification)

        auto self = static_cast<BitSailorCore*>(userData);
        self->logout();

        return BitwardenSuccess;
    }, this, &logoutHandle) != BitwardenSuccess) {
        qWarning() << "Failed attaching logout handler: " << getLastError();
    } else {
        notificationSubscriptions.append(logoutHandle);
    }

    NotificationSubscriptionHandle authRequestHandle;
    auto authRequestHandler = [](void *userData, const BitwardenNotification *notification) -> BitwardenResult {
        auto self = static_cast<BitSailorCore*>(userData);
        auto payload = QJsonDocument::fromJson(QString::fromUtf8(
            reinterpret_cast<const char *>(notification->payload),
            notification->payloadLen
        ).toUtf8());

        auto requestId = payload.object()["Id"].toString();
        emit self->authRequestApprovalRequested(requestId);

        return BitwardenSuccess;
    };
    if (BitwardenAddNotificationHandler(client, BitwardenNotificationAuthRequest, authRequestHandler, this, &authRequestHandle) != BitwardenSuccess) {
        qWarning() << "Failed registering an auth request handler: " << getLastError();
    } else {
        notificationSubscriptions.append(authRequestHandle);
    }
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
        if (BitwardenGetEmail(vault, &out) != BitwardenSuccess) {
            qWarning() << "Failed getting email even after sync";
            return QString();
        }
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
            if (error == unsupportedTwoFactorNeededError) {
                emit unsupportedTwoFactorNeeded();
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
    VaultHandle syncedVault = 0;
    if (BitwardenSyncVault(client, ctx, session, &syncedVault) != BitwardenSuccess) {
        qWarning() << "Failed syncing: " << getLastError();
        return false;
    }

    auto previousVault = vault;
    vault = syncedVault;

    if (previousVault != 0) {
        if (BitwardenCloseHandle(previousVault) != BitwardenSuccess) {
            qWarning() << "Failed closing vault: " << getLastError();
        }
    }

    QString exportError;
    exportVault(&exportError);
    if (!exportError.isNull()) {
        qWarning() << "Failed exporting vault after sync: " << exportError;
        return false;
    }

    return true;
}

void BitSailorCore::exportSession(QString *error)
{
    char* rawExport = nullptr;
    if (BitwardenExportSession(session, &rawExport) != BitwardenSuccess) {
        *error = getLastError();
        qWarning() << "Exporting session failed: " << *error;
        return;
    }
    QJsonParseError err;
    auto sessionJson = QJsonDocument::fromJson(QByteArray(rawExport), &err);
    free(rawExport);

    if (err.error) {
        *error = err.errorString();
        qWarning() << "Failed parsing exported session JSON: " << *error;
        return;
    }

    secrets->setSessionJson(sessionJson.object());
}

void BitSailorCore::exportVault(QString *error)
{
    char *rawExport = nullptr;
    if (BitwardenExportEncryptedVault(vault, &rawExport) != BitwardenSuccess) {
        *error = getLastError();
        qWarning() << "Exporting vault failed: " << *error;
        return;
    }

    QJsonParseError err;
    const auto vaultJson = QJsonDocument::fromJson(QByteArray(rawExport), &err);
    free(rawExport);

    if (err.error || !vaultJson.isObject()) {
        *error = err.error ? err.errorString() : QString("Exported vault JSON is not an object");
        qWarning() << "Failed parsing exported vault JSON: " << *error;
        return;
    }

    secrets->setEncryptedVault(vaultJson.object());
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
