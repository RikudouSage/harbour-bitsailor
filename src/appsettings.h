#ifndef APPSETTINGS_H
#define APPSETTINGS_H

#include <QObject>
#include <QSettings>
#include <QStandardPaths>

class AppSettings : public QObject
{
    Q_OBJECT
    Q_PROPERTY(bool lockOnClose READ lockOnClose WRITE setLockOnClose NOTIFY lockOnCloseChanged)
    Q_PROPERTY(bool eagerLoading READ eagerLoading WRITE setEagerLoading NOTIFY eagerLoadingChanged)
    Q_PROPERTY(bool persistentItemCache READ persistentItemCache WRITE setPersistentItemCache NOTIFY persistentItemCacheChanged)
public:
    explicit AppSettings(QObject *parent = nullptr);
    ~AppSettings();

    bool lockOnClose();
    void setLockOnClose(bool lock);
    bool eagerLoading();
    void setEagerLoading(bool enabled);
    bool persistentItemCache();
    void setPersistentItemCache(bool enabled);

signals:
    void lockOnCloseChanged();
    void eagerLoadingChanged();
    void persistentItemCacheChanged();

private:
    void saveConfig(const QString &name, const QVariant &value);

    QSettings* settings = new QSettings(
        QStandardPaths::writableLocation(QStandardPaths::AppConfigLocation) + "/settings.ini",
        QSettings::IniFormat,
        this
    );

    bool prop_LockOnCLose;
    bool prop_EagerLoading;
    bool prop_PersistentItemCache;
};

#endif // APPSETTINGS_H
