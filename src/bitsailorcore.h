#ifndef BITSAILORCORE_H
#define BITSAILORCORE_H

#include <functional>

#include <QObject>
#include <QUuid>
#include <QJsonArray>

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

    Q_ENUM(SessionStatus)
    Q_ENUM(ItemType)
    Q_ENUM(SendType)

    explicit BitSailorCore(AppSettings *settings, SecretsHandler *secrets, QObject *parent = nullptr);
    explicit BitSailorCore(QObject *parent = nullptr);
    ~BitSailorCore();

    Q_INVOKABLE void initialize();
    Q_INVOKABLE void getServerUrl();
    Q_INVOKABLE void changeServerUrl(const QString &url);

    Q_INVOKABLE void lockVault(bool sync = false);
    Q_INVOKABLE void unlockVault(const QString &password);
    Q_INVOKABLE void unlockVault(int pin);
    Q_INVOKABLE void unlockVault();
    Q_INVOKABLE void validateMasterPassword(const QString &password);

    Q_INVOKABLE void getLoginStatus();
    Q_INVOKABLE void loginApiKey(const QString &clientId, const QString &clientSecret);
    Q_INVOKABLE void loginEmailPassword(const QString &email, const QString &password);
    Q_INVOKABLE void logout();

    Q_INVOKABLE void syncVault();
    Q_INVOKABLE void fetchItems();
    Q_INVOKABLE void fetchSends();
    Q_INVOKABLE void deleteItem(const QString &id, bool emitEvents = true);
    Q_INVOKABLE void fetchItem(const QString &id);

signals:
    void serverUrlChanged(bool success);
    void serverUrlResolved(const QString &url);

    void vaultLocked(bool success);
    void unlockFinished(bool success, const QString &error);
    void masterPasswordValidationFinished(bool success);

    void loginStatusFetched(SessionStatus status);
    void loginFinished(bool success, const QString &error);
    void twoFactorNeeded();
    void logoutFinished();
    void couldNotFetchEmail();
    void wrongPinProvided();

    void syncVaultFinished(bool success);
    void itemsResolved(const QJsonArray &items);
    void itemResolvingFailed();
    void sendsResolved(bool success, const QJsonArray &items);
    void deletingFinished(bool success);
    void itemFetchFinished(bool success, const QJsonObject &item);

private:
    const QString getLastError() const;

    void cleanup();

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
    QJsonObject mapItem(const BitwardenItem &item) const;

private:
    bool valid = true;

    ContextHandle ctx = 0;
    ClientHandle client = 0;
    SessionHandle session = 0;
    VaultHandle vault = 0;

    QString email;

private: // dependencies
    AppSettings *settings;
    SecretsHandler *secrets;
};

Q_DECLARE_METATYPE(BitSailorCore::SessionStatus)
Q_DECLARE_METATYPE(BitSailorCore::ItemType)
Q_DECLARE_METATYPE(BitSailorCore::SendType)

#endif // BITSAILORCORE_H
