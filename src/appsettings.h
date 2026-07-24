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
    Q_PROPERTY(bool useApi READ useApi WRITE setUseApi NOTIFY useApiChanged)
    Q_PROPERTY(bool forceUnsafeApi READ forceUnsafeApi WRITE setForceUnsafeApi NOTIFY forceUnsafeApiChanged)
    Q_PROPERTY(bool useSystemCaStore READ useSystemCaStore WRITE setUseSystemCaStore NOTIFY useSystemCaStoreChanged)

    Q_PROPERTY(QString deviceUuid READ deviceUuid WRITE setDeviceUuid NOTIFY deviceUuidChanged)
    Q_PROPERTY(QString baseUrl READ baseUrl WRITE setBaseUrl NOTIFY baseUrlChanged)
public:
    explicit AppSettings(QObject *parent = nullptr);
    ~AppSettings();

    bool lockOnClose() const;
    void setLockOnClose(bool lock);
    bool eagerLoading() const;
    void setEagerLoading(bool enabled);
    bool persistentItemCache() const;
    void setPersistentItemCache(bool enabled);
    bool fastAuth() const;
    void setFastAuth(bool enabled);
    bool useSystemAuth() const;
    void setUseSystemAuth(bool enabled);
    bool useAuthorizationOnUnlocked() const;
    void setUseAuthorizationOnUnlocked(bool enabled);
    bool useApi() const;
    void setUseApi(bool enabled);
    bool forceUnsafeApi() const;
    void setForceUnsafeApi(bool enabled);
    bool useSystemCaStore() const;
    void setUseSystemCaStore(bool enabled);
    QString deviceUuid();
    void setDeviceUuid(const QString &value);
    QString baseUrl();
    void setBaseUrl(const QString &value);

signals:
    void lockOnCloseChanged();
    void eagerLoadingChanged();
    void persistentItemCacheChanged();
    void fastAuthChanged();
    void useSystemAuthChanged();
    void useAuthorizationOnUnlockedChanged();
    void useApiChanged();
    void forceUnsafeApiChanged();
    void useSystemCaStoreChanged();
    void deviceUuidChanged();
    void baseUrlChanged();

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
    bool prop_UseApi;
    bool prop_ForceUnsafeApi;
    bool prop_UseSystemCaStore;
    QString prop_DeviceUuid;
    QString prop_BaseUrl;
};

#endif // APPSETTINGS_H
