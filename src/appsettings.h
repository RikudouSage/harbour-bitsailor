#ifndef APPSETTINGS_H
#define APPSETTINGS_H

#include <QObject>
#include <QSettings>
#include <QStandardPaths>

class AppSettings : public QObject
{
    Q_OBJECT
    Q_PROPERTY(bool lockOnClose READ lockOnClose WRITE setLockOnClose NOTIFY lockOnCloseChanged)
    Q_PROPERTY(bool useSystemAuth READ useSystemAuth WRITE setUseSystemAuth NOTIFY useSystemAuthChanged)
    Q_PROPERTY(QString deviceUuid READ deviceUuid WRITE setDeviceUuid NOTIFY deviceUuidChanged)
    Q_PROPERTY(QString baseUrl READ baseUrl WRITE setBaseUrl NOTIFY baseUrlChanged)
public:
    explicit AppSettings(QObject *parent = nullptr);
    ~AppSettings();

    bool lockOnClose() const;
    void setLockOnClose(bool lock);
    bool useSystemAuth() const;
    void setUseSystemAuth(bool enabled);
    QString deviceUuid();
    void setDeviceUuid(const QString &value);
    QString baseUrl();
    void setBaseUrl(const QString &value);

signals:
    void lockOnCloseChanged();
    void useSystemAuthChanged();
    void deviceUuidChanged();
    void baseUrlChanged();

private:
    void saveConfig(const QString &name, const QVariant &value);

    QSettings* settings = new QSettings(
        QStandardPaths::writableLocation(QStandardPaths::AppConfigLocation) + "/settings_v2.ini",
        QSettings::IniFormat,
        this
    );

    bool prop_LockOnCLose;
    bool prop_UseSystemAuth;
    QString prop_DeviceUuid;
    QString prop_BaseUrl;
};

#endif // APPSETTINGS_H
