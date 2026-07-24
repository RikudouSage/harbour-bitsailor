#include "appsettings.h"

#include <QDebug>

#include "consts.h"

AppSettings::AppSettings(QObject *parent) : QObject(parent)
{
    prop_LockOnCLose = settings->value("lockOnClose", true).toBool();
    prop_EagerLoading = settings->value("eagerLoading", true).toBool();
    prop_PersistentItemCache = settings->value("persistentItemCache", false).toBool();
    prop_FastAuth = settings->value("fastAuth", false).toBool();
    prop_UseSystemAuth = settings->value("useSystemAuth", false).toBool();
    prop_UseAuthorizationOnUnlocked = settings->value("useAuthorizationOnUnlocked", false).toBool();
    prop_UseApi = settings->value("useApi", false).toBool();
    prop_ForceUnsafeApi = settings->value("forceUnsafeApi", false).toBool();
    prop_UseSystemCaStore = settings->value("useSystemCaStore", false).toBool();
    prop_DeviceUuid = settings->value("deviceUuid", "").toString();
    prop_BaseUrl = settings->value("baseUrl", defaultVaultUrl).toString();
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

bool AppSettings::eagerLoading() const
{
    return prop_EagerLoading;
}

void AppSettings::setEagerLoading(bool enabled)
{
    if (enabled == prop_EagerLoading) {
        return;
    }

    saveConfig("eagerLoading", enabled);
    prop_EagerLoading = enabled;
    emit eagerLoadingChanged();
}

bool AppSettings::persistentItemCache() const
{
    return prop_PersistentItemCache;
}

void AppSettings::setPersistentItemCache(bool enabled)
{
    if (enabled == prop_PersistentItemCache) {
        return;
    }

    saveConfig("persistentItemCache", enabled);
    prop_PersistentItemCache = enabled;
    emit persistentItemCacheChanged();
}

bool AppSettings::fastAuth() const
{
    return prop_FastAuth;
}

void AppSettings::setFastAuth(bool enabled)
{
    if (enabled == prop_FastAuth) {
        return;
    }

    saveConfig("fastAuth", enabled);
    prop_FastAuth = enabled;
    emit fastAuthChanged();
}

bool AppSettings::useSystemAuth() const
{
    return prop_UseSystemAuth;
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

bool AppSettings::useAuthorizationOnUnlocked() const
{
    return prop_UseAuthorizationOnUnlocked;
}

void AppSettings::setUseAuthorizationOnUnlocked(bool enabled)
{
    if (enabled == prop_UseAuthorizationOnUnlocked) {
        return;
    }

    saveConfig("useAuthorizationOnUnlocked", enabled);
    prop_UseAuthorizationOnUnlocked = enabled;
    emit useAuthorizationOnUnlockedChanged();
}

bool AppSettings::useApi() const
{
    return prop_UseApi;
}

void AppSettings::setUseApi(bool enabled)
{
    if (enabled == prop_UseApi) {
        return;
    }

    saveConfig("useApi", enabled);
    prop_UseApi = enabled;
    emit useApiChanged();
}

bool AppSettings::forceUnsafeApi() const
{
    return prop_ForceUnsafeApi;
}

void AppSettings::setForceUnsafeApi(bool enabled)
{
    if (enabled == prop_ForceUnsafeApi) {
        return;
    }

    saveConfig("forceUnsafeApi", enabled);
    prop_ForceUnsafeApi = enabled;
    emit forceUnsafeApiChanged();
}

bool AppSettings::useSystemCaStore() const
{
    return prop_UseSystemCaStore;
}

void AppSettings::setUseSystemCaStore(bool enabled)
{
    if (enabled == prop_UseSystemCaStore) {
        return;
    }

    saveConfig("useSystemCaStore", enabled);
    prop_UseSystemCaStore = enabled;
    emit useSystemCaStoreChanged();
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

void AppSettings::saveConfig(const QString &name, const QVariant &value)
{
    settings->setValue(name, value);
}
