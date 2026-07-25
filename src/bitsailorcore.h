#ifndef BITSAILORCORE_H
#define BITSAILORCORE_H

#include <functional>

#include <QObject>
#include <QUuid>

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
    Q_ENUM(SessionStatus)

    explicit BitSailorCore(AppSettings *settings, SecretsHandler *secrets, QObject *parent = nullptr);
    explicit BitSailorCore(QObject *parent = nullptr);
    ~BitSailorCore();

    Q_INVOKABLE void initialize();

    Q_INVOKABLE void getLoginStatus();
    Q_INVOKABLE void changeServerUrl(const QString &url);
    Q_INVOKABLE void loginApiKey(const QString &clientId, const QString &clientSecret);
    Q_INVOKABLE void loginEmailPassword(const QString &email, const QString &password);
    Q_INVOKABLE void logout();
    Q_INVOKABLE void unlockVault(const QString &password);
    Q_INVOKABLE void unlockVault(int pin);
    Q_INVOKABLE void unlockVault();

signals:
    void loginStatusFetched(SessionStatus status);
    void serverUrlChanged(bool success);
    void loginFinished(bool success, const QString &error);
    void twoFactorNeeded();
    void logoutFinished();
    void couldNotFetchEmail();
    void unlockFinished(bool success, const QString &error);
    void wrongPinProvided();

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
    QString getEmail();

    void login(const std::function<BitwardenResult()> &loginCallable);
    bool syncRaw();
    void exportSession(QString *error);

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

#endif // BITSAILORCORE_H
