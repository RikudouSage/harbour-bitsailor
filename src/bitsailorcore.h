#ifndef BITSAILORCORE_H
#define BITSAILORCORE_H

#include <functional>

#include <QObject>
#include <QUuid>
#include <QDateTime>
#include <QJsonArray>
#include <QJsonObject>

#include "appsettings.h"
#include "secretshandler.h"
#include "core/libbw.h"

class BitSailorCore : public QObject
{
    Q_OBJECT
public:
    enum SessionStatus {
        SessionStatusUnlocked = ::BitwardenSessionStatusUnlocked,
        SessionStatusLocked = ::BitwardenSessionStatusLocked,
        SessionStatusNone = ::BitwardenSessionStatusNone,
    };
    enum ItemType {
        ItemTypeNone = 0,
        ItemTypeLogin = ::BitwardenItemTypeLogin,
        ItemTypeSecureNote = ::BitwardenItemTypeSecureNote,
        ItemTypeCard = ::BitwardenItemTypeCard,
        ItemTypeIdentity = ::BitwardenItemTypeIdentity,
        ItemTypeSshKey = ::BitwardenItemTypeSshKey,
        ItemTypeBankAccount = ::BitwardenItemTypeBankAccount,
        ItemTypeDriversLicense = ::BitwardenItemTypeDriversLicense,
        ItemTypePassport = ::BitwardenItemTypePassport,
    };
    enum SendType {
        SendTypeText = ::BitwardenSendTypeText,
        SendTypeFile = ::BitwardenSendTypeFile,
    };
    enum FieldType {
        FieldTypeText = ::BitwardenFieldTypeText,
        FieldTypeHidden = ::BitwardenFieldTypeHidden,
        FieldTypeCheckbox = ::BitwardenFieldTypeCheckbox,
        FieldTypeLinkedId = ::BitwardenFieldTypeLinkedId,
    };
    enum UriMatchType {
        UriMatchTypeNone = -1,
        UriMatchTypeDomain = ::BitwardenUriMatchTypeDomain,
        UriMatchTypeHost = ::BitwardenUriMatchTypeHost,
        UriMatchTypeStartsWith = ::BitwardenUriMatchTypeStartsWith,
        UriMatchTypeExact = ::BitwardenUriMatchTypeExact,
        UriMatchTypeRegularExpression = ::BitwardenUriMatchTypeRegularExpression,
        UriMatchTypeNever = ::BitwardenUriMatchTypeNever,
    };

    Q_ENUM(SessionStatus)
    Q_ENUM(ItemType)
    Q_ENUM(SendType)
    Q_ENUM(FieldType)
    Q_ENUM(UriMatchType)

    explicit BitSailorCore(AppSettings *settings, SecretsHandler *secrets, QObject *parent = nullptr);
    explicit BitSailorCore(QObject *parent = nullptr);
    ~BitSailorCore();

    Q_INVOKABLE void initialize(bool withNotifications = false);
    Q_INVOKABLE void initializeNotifications();

    Q_INVOKABLE void getServerUrl();
    Q_INVOKABLE void changeServerUrl(const QString &url);

    Q_INVOKABLE void lockVault(bool sync = false);
    Q_INVOKABLE void unlockVault(const QString &password);
    Q_INVOKABLE void unlockVault(int pin);
    Q_INVOKABLE void unlockVault();
    Q_INVOKABLE void validateMasterPassword(const QString &password);

    Q_INVOKABLE void getLoginStatus();
    Q_INVOKABLE void loginApiKey(const QString &clientId, const QString &clientSecret);
    Q_INVOKABLE void loginEmailPassword(const QString &email, const QString &password, const QString &twoFaCode = "");
    Q_INVOKABLE void logout();

    Q_INVOKABLE void syncVault();
    Q_INVOKABLE void fetchItems();
    Q_INVOKABLE void fetchSends();
    Q_INVOKABLE void createItem(const QJsonObject &item);
    Q_INVOKABLE void createTextSend(const QString &name, const QString &text, bool hideText, int deletionDate, int maximumAccessCount, const QString &password, bool hideEmail, const QString &notes);
    Q_INVOKABLE void createFileSend(const QString &name, const QString &filePath, int deletionDate, int maximumAccessCount, const QString &password, bool hideEmail, const QString &notes);
    Q_INVOKABLE void deleteItem(const QString &id, bool emitEvents = true);
    Q_INVOKABLE void deleteSend(const QString &id, bool emitEvents = true);
    Q_INVOKABLE void fetchItem(const QString &id);
    Q_INVOKABLE void updateItem(const QString &id, const QJsonObject &item);

    Q_INVOKABLE void generatePassword(bool lowercase, bool uppercase, bool numbers, bool special, bool avoidAmbiguous, int minimumNumbers, int minimumSpecial, int length);
    Q_INVOKABLE void generatePassphrase(uint wordsCount, bool capitalize, bool includeNumber, const QString &separator);

signals:
    void serverUrlChanged(bool success);
    void serverUrlResolved(const QString &url);

    void vaultLocked(bool success);
    void unlockFinished(bool success, const QString &error);
    void masterPasswordValidationFinished(bool success);

    void loginStatusFetched(SessionStatus status);
    void loginFinished(bool success, const QString &error);
    void twoFactorNeeded();
    void unsupportedTwoFactorNeeded();
    void logoutFinished();
    void couldNotFetchEmail();
    void wrongPinProvided();

    void syncVaultFinished(bool success);
    void itemsResolved(const QJsonArray &items);
    void itemResolvingFailed();
    void sendsResolved(bool success, const QJsonArray &items);
    void itemCreationFinished(bool success);
    void sendCreated(bool success, const QJsonObject &item);
    void deletingFinished(bool success);
    void sendDeletingFinished(bool success);
    void itemFetchFinished(bool success, const QJsonObject &item);
    void itemUpdated(bool success);

    void passwordGeneratingFinished(bool success, const QString &password);
    void passphraseGeneratingFinished(bool success, const QString &passphrase);

    void invalidCertificate(); // todo implement on core side and then here

private:
    const QString getLastError() const;

    void cleanup();
    void registerListeners();

    QUuid generateUuid() const;
    QString uuidToString(const QUuid &uuid) const;
    QString uuidToString(const UUID &uuid) const;
    QUuid qUuidFromString(const QString &uuid) const;
    UUID uuidFromString(const QString &uuid) const;
    UUID uuidToCoreUuid(const QUuid &uuid) const;
    QUuid uuidToQUuid(const UUID &uuid) const;
    QDateTime cTimeToQDate(int64_t time) const;
    QString getEmail();

    void login(const std::function<BitwardenResult()> &loginCallable);
    bool syncRaw();
    void exportSession(QString *error);
    void exportVault(QString *error);
    QJsonObject mapItem(const BitwardenItem &item) const;
    QJsonObject mapSend(const BitwardenSend &send) const;

private:
    bool valid = true;

    ContextHandle ctx = 0;
    ClientHandle client = 0;
    SessionHandle session = 0;
    VaultHandle vault = 0;
    QList<NotificationSubscriptionHandle> notificationSubscriptions;

    QString email;

private: // dependencies
    AppSettings *settings;
    SecretsHandler *secrets;
};

Q_DECLARE_METATYPE(BitSailorCore::SessionStatus)
Q_DECLARE_METATYPE(BitSailorCore::ItemType)
Q_DECLARE_METATYPE(BitSailorCore::SendType)
Q_DECLARE_METATYPE(BitSailorCore::FieldType)
Q_DECLARE_METATYPE(BitSailorCore::UriMatchType)

#endif // BITSAILORCORE_H
