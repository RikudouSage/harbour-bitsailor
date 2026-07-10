#include "accountmanager.h"

AccountManager *AccountManager::instance = nullptr;

constexpr auto CurrentGroupName = "current";

AccountManager::AccountManager(QObject *parent) : QObject(parent)
{
}

QString AccountManager::currentAccount() const
{
    settings->beginGroup(CurrentGroupName);
    const auto val = settings->value("accountId", "").toString();
    settings->endGroup();

    return val;
}

void AccountManager::setCurrentAccount(const QString &account)
{
    if (account == currentAccount()) {
        return;
    }

    if (!settings->childGroups().contains(account)) {
        settings->beginGroup(account);
        settings->setValue("initialized", true);
        settings->endGroup();
        emit accountsChanged();
    }

    settings->beginGroup(CurrentGroupName);
    settings->setValue("accountId", account);
    settings->endGroup();

    emit currentAccountChanged();
}

QStringList AccountManager::accounts() const
{
    auto groups = settings->childGroups();
    if (groups.contains(CurrentGroupName)) {
        groups.removeAt(groups.indexOf(CurrentGroupName));
    }

    return groups;
}

AccountManager *AccountManager::getInstance(QObject *parent)
{
    if (instance == nullptr) {
        instance = new AccountManager(parent);
    }

    return instance;
}
