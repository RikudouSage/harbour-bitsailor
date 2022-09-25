#include "runtimecache.h"

#include <QDebug>
#include <QStandardPaths>
#include <QFile>

RuntimeCache* RuntimeCache::instance = nullptr;

RuntimeCache::RuntimeCache(QObject *parent) : QObject(parent)
{
}

void RuntimeCache::set(const QString &key, const QString &value)
{
    settings.insert(key, value);
}

QString RuntimeCache::get(const QString &key)
{
    return settings.value(key);
}

bool RuntimeCache::has(const QString &key)
{
    return settings.contains(key);
}

void RuntimeCache::remove(const QString &key)
{
    settings.remove(key);
}

void RuntimeCache::setPersistent(const QString &key, const QString &value)
{
    persistentSettings->setValue(key, value);
}

QString RuntimeCache::getPersistent(const QString &key)
{
    return persistentSettings->value(key).toString();
}

bool RuntimeCache::hasPersistent(const QString &key)
{
    return persistentSettings->contains(key);
}

void RuntimeCache::removePersistent(const QString &key)
{
    persistentSettings->remove(key);
}

RuntimeCache *RuntimeCache::getInstance(QObject *parent)
{
    if (instance == nullptr) {
        instance = new RuntimeCache(parent);
    }

    return instance;
}

