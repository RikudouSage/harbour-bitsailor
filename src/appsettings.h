#ifndef APPSETTINGS_H
#define APPSETTINGS_H

#include <QObject>
#include <QSettings>
#include <QStandardPaths>

class AppSettings : public QObject
{
    Q_OBJECT
    Q_PROPERTY(bool lockOnClose READ lockOnClose WRITE setLockOnClose NOTIFY lockOnCloseChanged)
public:
    explicit AppSettings(QObject *parent = nullptr);
    ~AppSettings();
    bool lockOnClose();
    void setLockOnClose(bool lock);
signals:
    void lockOnCloseChanged();

private:
    void saveConfig(const QString &name, const QVariant &value);

    QSettings* settings = new QSettings(
        QStandardPaths::writableLocation(QStandardPaths::AppConfigLocation),
        QSettings::IniFormat,
        this
    );

    bool prop_LockOnCLose;
};

#endif // APPSETTINGS_H
