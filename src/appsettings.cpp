#include "appsettings.h"

#include <QDebug>

AppSettings::AppSettings(QObject *parent) : QObject(parent)
{
    prop_LockOnCLose = settings->value("lockOnClose", false).toBool();
    prop_EagerLoading = settings->value("eagerLoading", true).toBool();
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

void AppSettings::saveConfig(const QString &name, const QVariant &value)
{
    settings->setValue(name, value);
}
