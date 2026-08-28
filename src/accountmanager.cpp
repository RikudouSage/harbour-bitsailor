#include "accountmanager.h"

#include <QDebug>
#include <QSet>

#include "defer.h"
#include "consts.h"
#include "uuid.h"

constexpr auto GlobalGroupName = "global";

AccountManager::AccountManager(AppSettings *appSettings, QObject *parent)
    : QObject(parent), appSettings(appSettings)
{
}

QString AccountManager::generateAccountId() const
{
    return uuidToString(generateUuid());
}

bool AccountManager::setAccountIdAfterMigration(const QString &accountId)
{
    if (!getCurrentAccountId().isEmpty()) {
        qWarning() << "Failed setting current account id after migration, not empty";
        return false;
    }

    settings->beginGroup(GlobalGroupName);
    defer({
        settings->endGroup();
    });

    settings->setValue("currentAccountId", accountId);
    emit currentAccountChanged();
    return true;
}

AccountManager::Account AccountManager::getCurrentAccount()
{
    return getAccount(getCurrentAccountId());
}

QJsonObject AccountManager::currentAccount()
{
    const auto account = getCurrentAccount();
    return convertAccountToJson(account);
}

void AccountManager::setCurrentAccount(const QJsonObject &value)
{
    auto account = Account{
        .id = value.value("id").toString(""),
        .name = value.value("name").toString(""),
        .email = value.value("email").toString(""),
        .server = value.value("server").toString(),
    };
    account.valid = account.server != "" && account.email != "" && account.id != "";

    storeAccount(account);
    setCurrentAccountId(account.id);
}

QJsonArray AccountManager::accounts()
{
    QJsonArray result;
    for (const auto &account : getAccounts()) {
        result.append(convertAccountToJson(account));
    }

    return result;
}

void AccountManager::setAccounts(const QJsonArray &value)
{
    QSet<QString> wantedAccountIds;
    QList<Account> wantedAccounts;

    for (const auto &item : value) {
        auto account = convertAccountToStruct(item.toObject());
        if (!account.valid) {
            qWarning() << "Ignoring invalid account while setting accounts";
            continue;
        }

        wantedAccountIds.insert(account.id);
        wantedAccounts.append(account);
    }

    for (const auto &account : getAccounts()) {
        if (!wantedAccountIds.contains(account.id)) {
            settings->remove(account.id);
        }
    }

    for (const auto &account : wantedAccounts) {
        storeAccount(account);
    }

    settings->sync();
    if (settings->status() != QSettings::NoError) {
        qWarning() << "Failed setting accounts";
        return;
    }

    const auto currentAccountId = getCurrentAccountId();
    if (!currentAccountId.isEmpty() && !wantedAccountIds.contains(currentAccountId)) {
        setCurrentAccountId("");
    }

    emit accountsChanged();
}

bool AccountManager::removeAccount(const QString &accountId)
{
    if (accountId.isEmpty() || accountId == GlobalGroupName) {
        qWarning() << "Cannot remove account with invalid account ID";
        return false;
    }

    settings->remove(accountId);
    settings->sync();
    if (settings->status() != QSettings::NoError) {
        qWarning() << "Failed removing account";
        return false;
    }

    if (getCurrentAccountId() == accountId) {
        setCurrentAccountId("");
    }

    emit accountsChanged();
    return true;
}

AccountManager::Account AccountManager::getAccount(const QString &accountId)
{
    settings->beginGroup(accountId);
    defer({
        settings->endGroup();
    });

    const auto name = settings->value("name", "").toString();
    const auto email = settings->value("email", "").toString();
    const auto server = settings->value("server", "").toString();

    return Account {
        .id = accountId,
        .name = name,
        .email = email,
        .server = server,
        .valid = server != "" && email != "",
    };
}

bool AccountManager::storeAccount(const Account &account)
{
    if (!account.valid) {
        qWarning() << "Trying to store an invalid account";
        return false;
    }

    settings->beginGroup(account.id);
    defer({
        settings->endGroup();
    });

    settings->setValue("name", account.name);
    settings->setValue("email", account.email);
    settings->setValue("server", account.server);

    return true;
}

const QString AccountManager::getCurrentAccountId()
{
    settings->beginGroup(GlobalGroupName);
    defer({
        settings->endGroup();
    });

    return settings->value("currentAccountId", "").toString();
}

void AccountManager::setCurrentAccountId(const QString &accountId)
{
    {
        settings->beginGroup(GlobalGroupName);
        defer({
            settings->endGroup();
        });

        settings->setValue("currentAccountId", accountId);
    }

    const auto account = getAccount(accountId);
    if (account.valid) {
        appSettings->setBaseUrl(account.server);
    } else {
        appSettings->setBaseUrl(defaultVaultUrl);
    }

    emit currentAccountChanged();
}

QJsonObject AccountManager::convertAccountToJson(const Account &account) const
{
    QJsonObject result;
    result.insert("id", account.id);
    result.insert("name", account.name);
    result.insert("email", account.email);
    result.insert("server", account.server);
    result.insert("valid", account.valid);

    return result;
}

AccountManager::Account AccountManager::convertAccountToStruct(const QJsonObject &value) const
{
    auto account = Account{
        .id = value.value("id").toString(""),
        .name = value.value("name").toString(""),
        .email = value.value("email").toString(),
        .server = value.value("server").toString(),
    };
    account.valid = account.server != "" && account.email != "" && account.id != "";

    return account;
}

QList<AccountManager::Account> AccountManager::getAccounts()
{
    QList<Account> result;
    for (const auto &group : settings->childGroups()) {
        if (group == GlobalGroupName) {
            continue;
        }
        result.append(getAccount(group));
    }

    return result;
}
