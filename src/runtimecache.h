#ifndef RUNTIMECACHE_H
#define RUNTIMECACHE_H

#include <QObject>
#include <QMap>

class RuntimeCache : public QObject
{
    Q_OBJECT
public:
    explicit RuntimeCache(QObject *parent = nullptr);
    Q_INVOKABLE void set(const QString &key, const QString &value);
    Q_INVOKABLE QString get(const QString &key);
    Q_INVOKABLE bool has(const QString &key);
    Q_INVOKABLE void remove(const QString &key);
    static RuntimeCache* getInstance(QObject *parent = nullptr);

signals:

private:
    QMap<QString, QString> settings;
    static RuntimeCache* instance;
};

#endif // RUNTIMECACHE_H
