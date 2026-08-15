#ifndef ACCOUNTMANAGER_H
#define ACCOUNTMANAGER_H

#include <QObject>
#include <QSettings>
#include <QStandardPaths>

#include "appsettings.h"

class AccountManager : public QObject
{
    Q_OBJECT
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

private:
    QSettings* settings = new QSettings(
        QStandardPaths::writableLocation(QStandardPaths::AppConfigLocation) + "/accounts.ini",
        QSettings::IniFormat,
        this
    );
    AppSettings *appSettings;

private:
    Account getAccount(const QString &accountId);
    const QString getCurrentAccountId();
    void setCurrentAccountId(const QString &accountId);
};

#endif // ACCOUNTMANAGER_H
