#include "appsettings.h"

#include <QDebug>

AppSettings::AppSettings(QObject *parent) : QObject(parent)
{
    prop_LockOnCLose = settings->value("lockOnClose", true).toBool();
    prop_EagerLoading = settings->value("eagerLoading", true).toBool();
    prop_PersistentItemCache = settings->value("persistentItemCache", false).toBool();
    prop_FastAuth = settings->value("fastAuth", false).toBool();
    prop_UseSystemAuth = settings->value("useSystemAuth", false).toBool();
}

AppSettings::~AppSettings()
{
    settings->sync();
}

bool AppSettings::lockOnClose()
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

bool AppSettings::eagerLoading()
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

bool AppSettings::persistentItemCache()
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

bool AppSettings::fastAuth()
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

bool AppSettings::useSystemAuth()
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

void AppSettings::saveConfig(const QString &name, const QVariant &value)
{
    settings->setValue(name, value);
}
