#ifndef SYSTEMAUTHCHECKER_H
#define SYSTEMAUTHCHECKER_H

#include <QObject>
#include <QDBusPendingCallWatcher>
#include <QDBusPendingCall>

class SystemAuthChecker : public QObject
{
    Q_OBJECT
public:
    explicit SystemAuthChecker(QObject *parent = nullptr);
    Q_INVOKABLE void checkAuth();

signals:
    void authResolved(bool success);

private slots:
    void finished(QDBusPendingCallWatcher* watcher);

private:
    QDBusPendingCallWatcher* createCallWatcher(QDBusPendingCall &dbusCall);

private:
    QDBusPendingCallWatcher* callWatcher = nullptr;
};

#endif // SYSTEMAUTHCHECKER_H
