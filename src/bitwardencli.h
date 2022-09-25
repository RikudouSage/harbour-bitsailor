#ifndef BITWARDENCLI_H
#define BITWARDENCLI_H

#include <QObject>
#include <QProcess>
#include <QMap>
#include <QMetaEnum>

#include "pathhelper.h"
#include "secretshandler.h"

class BitwardenCli : public QObject
{
    Q_OBJECT
public:
    explicit BitwardenCli(QObject *parent = nullptr);

    Q_INVOKABLE void checkLoginStatus();
    Q_INVOKABLE void checkVaultUnlocked();
    Q_INVOKABLE void loginEmailPassword(const QString &email, const QString &password);
    Q_INVOKABLE void loginApiKey(const QString &clientId, const QString &clientSecret);
    Q_INVOKABLE void logout();
    Q_INVOKABLE void unlockVault(QString password);
    Q_INVOKABLE void unlockVault(int pin);
    Q_INVOKABLE void lockVault();
    Q_INVOKABLE void lockVaultInBackground();

    enum Method {
        LoginCheck,
        VaultUnlocked,
        LoginEmailPassword,
        LoginApiKey,
        Logout,
        UnlockVault,
        LockVault,
    };

signals:
    void loginStatusResolved(bool loggedIn);
    void vaultLockStatusResolved(bool unlocked);
    void logInFinished(bool success);
    void logoutFinished();
    void vaultUnlockFinished(bool success);
    void wrongPinProvided();
    void authenticatorRequired();
    void vaultLocked();

private slots:
    void onFinished(int exitCode, Method method);

private:
    const QString bw = getPrivateBinDirPath() + "/bw";
    QMap<Method, QProcess*> processes;

    void startProcess(const QStringList &arguments, Method method);
    void startProcess(const QStringList &arguments, const QProcessEnvironment &environment, Method method);
    SecretsHandler* secretsHandler = new SecretsHandler(this);
};

#endif // BITWARDENCLI_H
