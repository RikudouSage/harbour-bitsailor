#ifndef RUNTIMECACHE_H
#define RUNTIMECACHE_H

#include <QObject>
#include <QMap>
#include <QSettings>
#include <QStandardPaths>

class RuntimeCache : public QObject
{
    Q_OBJECT
public:
    explicit RuntimeCache(QObject *parent = nullptr);
    Q_INVOKABLE void set(const QString &key, const QString &value);
    Q_INVOKABLE QString get(const QString &key);
    Q_INVOKABLE bool has(const QString &key);
    Q_INVOKABLE void remove(const QString &key);

    Q_INVOKABLE void setPersistent(const QString &key, const QString &value);
    Q_INVOKABLE QString getPersistent(const QString &key);
    Q_INVOKABLE bool hasPersistent(const QString &key);
    Q_INVOKABLE void removePersistent(const QString &key);

    static RuntimeCache* getInstance(QObject *parent = nullptr);

signals:

private:
    QMap<QString, QString> settings;
    QSettings* persistentSettings = new QSettings(
        QStandardPaths::writableLocation(QStandardPaths::CacheLocation) + "/cache.ini",
        QSettings::IniFormat,
        this
    );

    static RuntimeCache* instance;
};

#endif // RUNTIMECACHE_H
