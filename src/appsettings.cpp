#include "appsettings.h"

#include <QDebug>

AppSettings::AppSettings(QObject *parent) : QObject(parent)
{
    prop_LockOnCLose = settings->value("lockOnClose", false).toBool();
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

void AppSettings::saveConfig(const QString &name, const QVariant &value)
{
    settings->setValue(name, value);
}
