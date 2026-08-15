#include "accountmanager.h"

#include <QDebug>

#include "defer.h"
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

    setCurrentAccountId(accountId);
    return true;
}

AccountManager::Account AccountManager::getCurrentAccount()
{
    return getAccount(getCurrentAccountId());
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
    settings->beginGroup(GlobalGroupName);
    defer({
        settings->endGroup();
    });

    settings->setValue("currentAccountId", accountId);
}
