#include "appsettings.h"

#include <QDebug>

#include "consts.h"

AppSettings::AppSettings(QObject *parent) : QObject(parent)
{
    prop_LockOnCLose = settings->value("lockOnClose", true).toBool();
    prop_UseSystemAuth = settings->value("useSystemAuth", false).toBool();
    prop_DeviceUuid = settings->value("deviceUuid", "").toString();
    prop_BaseUrl = settings->value("baseUrl", defaultVaultUrl).toString();
    prop_ClearClipboardTimeout = settings->value("clearClipboardTimeout", 60).toInt();
    prop_ClearClipboardOnClosing = settings->value("clearClipboardOnClosing", true).toBool();
    prop_ShowFavicons = settings->value("showFavicons", false).toBool();
    prop_migratedToMultiAccounts = settings->value("migratedToMultiAccounts", false).toBool();
}

AppSettings::~AppSettings()
{
    settings->sync();
}

bool AppSettings::lockOnClose() const
{
    return prop_LockOnCLose;
}

void AppSettings::setLockOnClose(bool lock)
{
    if (lock == prop_LockOnCLose) {
        return;
    }

    saveConfig("lockOnClose", lock);
    prop_LockOnCLose = lock;
    emit lockOnCloseChanged();
}

bool AppSettings::useSystemAuth() const
{
#ifdef HARBOUR_STORE
    return false;
#else
    return prop_UseSystemAuth;
#endif
}

void AppSettings::setUseSystemAuth(bool enabled)
{
    if (enabled == prop_UseSystemAuth) {
        return;
    }

    saveConfig("useSystemAuth", enabled);
    prop_UseSystemAuth = enabled;
    emit useSystemAuthChanged();
}

QString AppSettings::deviceUuid()
{
    return prop_DeviceUuid;
}

void AppSettings::setDeviceUuid(const QString &value)
{
    if (value == prop_DeviceUuid) {
        return;
    }

    saveConfig("deviceUuid", value);
    prop_DeviceUuid = value;
    emit deviceUuidChanged();
}

QString AppSettings::baseUrl()
{
    return prop_BaseUrl;
}

void AppSettings::setBaseUrl(const QString &value)
{
    if (value == prop_BaseUrl) {
        return;
    }

    saveConfig("baseUrl", value);
    prop_BaseUrl = value;
    emit baseUrlChanged();
}

int AppSettings::clearClipboardTimeout()
{
    return prop_ClearClipboardTimeout;
}

void AppSettings::setClearClipboardTimeout(int value)
{
    if (value == prop_ClearClipboardTimeout) {
        return;
    }

    saveConfig("clearClipboardTimeout", value);
    prop_ClearClipboardTimeout = value;
    emit clearClipboardTimeoutChanged();
}

bool AppSettings::clearClipboardOnClosing()
{
    return prop_ClearClipboardOnClosing;
}

void AppSettings::setClearClipboardOnClosing(bool value)
{
    if (value == prop_ClearClipboardOnClosing) {
        return;
    }

    saveConfig("clearClipboardOnClosing", value);
    prop_ClearClipboardOnClosing = value;
    emit clearClipboardOnClosingChanged();
}

bool AppSettings::showFavicons()
{
    return prop_ShowFavicons;
}

void AppSettings::setShowFavicons(bool value)
{
    if (value == prop_ShowFavicons) {
        return;
    }

    saveConfig("showFavicons", value);
    prop_ShowFavicons = value;
    emit showFaviconsChanged();
}

bool AppSettings::migratedToMultiAccounts()
{
    return prop_migratedToMultiAccounts;
}

void AppSettings::setMigratedToMultiAccounts(bool value)
{
    if (value == prop_migratedToMultiAccounts) {
        return;
    }

    saveConfig("migratedToMultiAccounts", value);
    prop_migratedToMultiAccounts = value;
    emit migratedToMultiAccountsChanged();
}

void AppSettings::saveConfig(const QString &name, const QVariant &value)
{
    settings->setValue(name, value);
}
