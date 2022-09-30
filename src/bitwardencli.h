#ifndef BITWARDENCLI_H
#define BITWARDENCLI_H

#include <QObject>
#include <QProcess>
#include <QMap>
#include <QMetaEnum>
#include <QJsonArray>
#include <QList>
#include <QJsonObject>

#include "pathhelper.h"
#include "secretshandler.h"
#include "runtimecache.h"

class BitwardenCli : public QObject
{
    Q_OBJECT
public:
    explicit BitwardenCli(QObject *parent = nullptr);

    enum Method {
        LoginCheck,
        VaultUnlocked,
        LoginEmailPassword,
        LoginApiKey,
        Logout,
        UnlockVault,
        LockVault,
        GetItems,
        GetLogins,
        GetCards,
        GetNotes,
        GetIdentities,
        SyncVault,
        DeleteItem,
        GetItem,
        GeneratePassword,
    };

    enum TwoStepLoginMethods {
        Authenticator = 0,
        Email = 1,
        YubiKey = 3,
    };
    Q_ENUM(TwoStepLoginMethods);

    enum ItemType {
        NoType = -1,
        Login = 1,
        SecureNote = 2,
        Card = 3,
        Identity = 4,
    };
    Q_ENUM(ItemType);

    enum LoginUriMatchType {
        Domain = 0,
        Host = 1,
        StartsWith = 2,
        Exact = 3,
        RegularExpression = 4,
        Never = 5,
    };
    Q_ENUM(LoginUriMatchType);

    enum FieldType {
        FieldTypeText = 0,
        FieldTypeHidden = 1,
        FieldTypeBoolean = 2,
        FieldTypeLinked = 3,
    };
    Q_ENUM(FieldType);

    Q_INVOKABLE void checkLoginStatus();
    Q_INVOKABLE void checkVaultUnlocked();
    Q_INVOKABLE void loginEmailPassword(const QString &email, const QString &password);
    Q_INVOKABLE void loginApiKey(const QString &clientId, const QString &clientSecret);
    Q_INVOKABLE void logout();
    Q_INVOKABLE void unlockVault(QString password);
    Q_INVOKABLE void unlockVault(int pin);
    Q_INVOKABLE void unlockVault();
    Q_INVOKABLE void lockVault();
    Q_INVOKABLE void lockVaultInBackground();
    Q_INVOKABLE void getItems();
    void getItems(Method method);
    Q_INVOKABLE void getLogins();
    Q_INVOKABLE void getCards();
    Q_INVOKABLE void getNotes();
    Q_INVOKABLE void getIdentities();
    Q_INVOKABLE void syncVault();
    Q_INVOKABLE void deleteItem(QString id);
    Q_INVOKABLE void deleteItemInBackground(QString id);
    Q_INVOKABLE void getItem(QString id);
    Q_INVOKABLE void generatePassword(bool lowercase, bool uppercase, bool numbers, bool special, int length);

signals:
    void loginStatusResolved(bool loggedIn);
    void vaultLockStatusResolved(bool unlocked);
    void logInFinished(bool success);
    void logoutFinished();
    void vaultUnlockFinished(bool success);
    void wrongPinProvided();
    void authenticatorRequired();
    void vaultLocked();
    void failedGettingItems();
    void itemsResolved(QJsonArray items);
    void vaultSynced();
    void vaultSyncFailed();
    void itemDeleted(bool success);
    void itemFetched(QJsonObject item);
    void itemFetchingFailed();
    void passwordGenerated(QString password);

private slots:
    void onFinished(int exitCode, Method method);

private:
    const QString bw = getPrivateBinDirPath() + "/bw";
    QMap<Method, QProcess*> processes;
    SecretsHandler* secretsHandler = new SecretsHandler(this);
    RuntimeCache* runtimeCache = RuntimeCache::getInstance(this);

    void startProcess(const QStringList &arguments, Method method);
    void startProcess(const QStringList &arguments, const QProcessEnvironment &environment, Method method);
    void handleGetItems(const QString &rawJson, Method method = GetItems);
};

#endif // BITWARDENCLI_H
