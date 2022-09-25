#include "appsettings.h"

#include <QDebug>

AppSettings::AppSettings(QObject *parent) : QObject(parent)
{
    prop_LockOnCLose = settings->value("lockOnClose", true).toBool();
    prop_EagerLoading = settings->value("eagerLoading", true).toBool();
    prop_PersistentItemCache = settings->value("persistentItemCache", false).toBool();
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

void AppSettings::saveConfig(const QString &name, const QVariant &value)
{
    settings->setValue(name, value);
}
