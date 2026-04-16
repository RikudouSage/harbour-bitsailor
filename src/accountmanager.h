#ifndef ACCOUNTMANAGER_H
#define ACCOUNTMANAGER_H

#include <QObject>
#include <QSettings>
#include <QStandardPaths>

class AccountManager : public QObject
{
    Q_OBJECT
    Q_PROPERTY(QString currentAccount READ currentAccount WRITE setCurrentAccount NOTIFY currentAccountChanged)
    Q_PROPERTY(QStringList accounts READ accounts NOTIFY accountsChanged)
public:
    explicit AccountManager(QObject *parent = nullptr);

    QString currentAccount() const;
    void setCurrentAccount(const QString &account);

    QStringList accounts() const;

    static AccountManager *getInstance(QObject *parent = nullptr);

private:
    static AccountManager *instance;
    QSettings* settings = new QSettings(
        QStandardPaths::writableLocation(QStandardPaths::AppConfigLocation) + "/accounts.ini",
        QSettings::IniFormat,
        this
    );

signals:
    void currentAccountChanged();
    void accountsChanged();
};

#endif // ACCOUNTMANAGER_H
