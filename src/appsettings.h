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
    Q_PROPERTY(bool fastAuth READ fastAuth WRITE setFastAuth NOTIFY fastAuthChanged)
    Q_PROPERTY(bool useSystemAuth READ useSystemAuth WRITE setUseSystemAuth NOTIFY useSystemAuthChanged)
    Q_PROPERTY(bool useAuthorizationOnUnlocked READ useAuthorizationOnUnlocked WRITE setUseAuthorizationOnUnlocked NOTIFY useAuthorizationOnUnlockedChanged)
public:
    explicit AppSettings(QObject *parent = nullptr);
    ~AppSettings();

    bool lockOnClose();
    void setLockOnClose(bool lock);
    bool eagerLoading();
    void setEagerLoading(bool enabled);
    bool persistentItemCache();
    void setPersistentItemCache(bool enabled);
    bool fastAuth();
    void setFastAuth(bool enabled);
    bool useSystemAuth();
    void setUseSystemAuth(bool enabled);
    bool useAuthorizationOnUnlocked();
    void setUseAuthorizationOnUnlocked(bool enabled);

signals:
    void lockOnCloseChanged();
    void eagerLoadingChanged();
    void persistentItemCacheChanged();
    void fastAuthChanged();
    void useSystemAuthChanged();
    void useAuthorizationOnUnlockedChanged();

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
    bool prop_FastAuth;
    bool prop_UseSystemAuth;
    bool prop_UseAuthorizationOnUnlocked;
};

#endif // APPSETTINGS_H
