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
    auto pin = secrets->hasPin() ? secrets->getPin() : secrets->getInternalPin();
    if (pin.isNull() || pin.isEmpty()) {
        emit encryptionKeyNotFound();
        return;
    }
    auto encrypted = encryptor->encrypt(value, pin);
    persistentSettings->setValue(key, encrypted);
}

QString RuntimeCache::getPersistent(const QString &key)
{
    auto pin = secrets->hasPin() ? secrets->getPin() : secrets->getInternalPin();
    if (pin.isNull() || pin.isEmpty()) {
        emit encryptionKeyNotFound();
        return "";
    }
    auto encrypted = persistentSettings->value(key).toString();

    return encryptor->decrypt(encrypted, pin);
}

bool RuntimeCache::hasPersistent(const QString &key)
{
    return persistentSettings->contains(key);
}

void RuntimeCache::removePersistent(const QString &key)
{
    persistentSettings->remove(key);
}

QString RuntimeCache::getOrSetPersistent(const QString &key, const QString &defaultValue)
{
    if (hasPersistent(key)) {
        return getPersistent(key);
    }
    setPersistent(key, defaultValue);

    return defaultValue;
}

RuntimeCache *RuntimeCache::getInstance(QObject *parent)
{
    if (instance == nullptr) {
        instance = new RuntimeCache(parent);
    }

    return instance;
}

