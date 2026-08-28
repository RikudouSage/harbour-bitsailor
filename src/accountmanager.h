#ifndef ACCOUNTMANAGER_H
#define ACCOUNTMANAGER_H

#include <QObject>
#include <QSettings>
#include <QStandardPaths>
#include <QJsonObject>
#include <QJsonArray>
#include <QList>

#include "appsettings.h"

class AccountManager : public QObject
{
    Q_OBJECT
    Q_PROPERTY(QJsonObject currentAccount READ currentAccount WRITE setCurrentAccount NOTIFY currentAccountChanged)
    Q_PROPERTY(QJsonArray accounts READ accounts WRITE setAccounts NOTIFY accountsChanged)
private:
    struct Account {
        const QString id;

        const QString name;
        const QString email;
        const QString server;

        bool valid;
    };

public:
    explicit AccountManager(AppSettings *appSettings, QObject *parent = nullptr);

    Q_INVOKABLE QString generateAccountId() const;
    Q_INVOKABLE bool setAccountIdAfterMigration(const QString &accountId);

    Account getCurrentAccount();

    QJsonObject currentAccount();
    void setCurrentAccount(const QJsonObject &value);

    QJsonArray accounts();
    void setAccounts(const QJsonArray &value);

    Q_INVOKABLE void setCurrentAccountId(const QString &accountId);

signals:
    void currentAccountChanged();
    void accountsChanged();

private:
    QSettings* settings = new QSettings(
        QStandardPaths::writableLocation(QStandardPaths::AppConfigLocation) + "/accounts.ini",
        QSettings::IniFormat,
        this
    );
    AppSettings *appSettings;

private:
    Account getAccount(const QString &accountId);
    bool storeAccount(const Account &account);
    const QString getCurrentAccountId();

    QJsonObject convertAccountToJson(const Account &account) const;
    Account convertAccountToStruct(const QJsonObject &value) const;
    QList<Account> getAccounts();
};

#endif // ACCOUNTMANAGER_H
