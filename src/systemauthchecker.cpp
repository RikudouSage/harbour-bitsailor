#include "systemauthchecker.h"

#include <QCoreApplication>
#include <QDebug>

#include <QDBusArgument>
#include <QDBusInterface>
#include <QDBusConnection>
#include <QDBusPendingReply>
#include <QtDBus>

struct PolkitCheckResult {
    bool isAuthorized;
    bool isChallenge;
    QMap<QString, QString> details;
};
Q_DECLARE_METATYPE(PolkitCheckResult)

QDBusArgument &operator<<(QDBusArgument &argument, const PolkitCheckResult &result) {
    argument.beginStructure();
    argument << result.isAuthorized << result.isChallenge << result.details;
    argument.endStructure();

    return argument;
}

const QDBusArgument &operator>>(const QDBusArgument &argument, PolkitCheckResult &result) {
    argument.beginStructure();
    argument >> result.isAuthorized >> result.isChallenge >> result.details;
    argument.endStructure();

    return argument;
}

SystemAuthChecker::SystemAuthChecker(QObject *parent) : QObject(parent)
{
    qDBusRegisterMetaType<PolkitCheckResult>();
    qDBusRegisterMetaType<QMap<QString, QString>>();
}

void SystemAuthChecker::checkAuth()
{
    QDBusArgument subject;
    subject.beginStructure();
    subject << QString("unix-process");
    subject << QMap<QString, QVariant>{
        {"pid", static_cast<quint32>(QCoreApplication::applicationPid())},
        {"start-time", static_cast<quint64>(0)},
    };
    subject.endStructure();

    QDBusInterface polkit(
        "org.freedesktop.PolicyKit1",
        "/org/freedesktop/PolicyKit1/Authority",
        "org.freedesktop.PolicyKit1.Authority",
        QDBusConnection::systemBus()
    );

    auto pendingCall = polkit.asyncCall(
        "CheckAuthorization",
        QVariant::fromValue(subject),
        "cz.chrastecky.bitsailor.auth",
        QVariant::fromValue(QMap<QString, QString>{}),
        0x1u,
        ""
    );
    auto watcher = createCallWatcher(pendingCall);
    connect(watcher, &QDBusPendingCallWatcher::finished, this, &SystemAuthChecker::finished);
}

void SystemAuthChecker::finished(QDBusPendingCallWatcher *watcher)
{
    QDBusPendingReply<PolkitCheckResult> reply = *watcher;
    if (reply.isError()) {
        qWarning() << reply.error();
        return;
    }

    auto item = reply.argumentAt(0).value<QDBusArgument>();
    PolkitCheckResult result;
    item >> result;

    emit authResolved(result.isAuthorized);
}

QDBusPendingCallWatcher *SystemAuthChecker::createCallWatcher(QDBusPendingCall &dbusCall)
{
    if (callWatcher != nullptr) {
        delete callWatcher;
    }
    callWatcher = new QDBusPendingCallWatcher(dbusCall, this);

    return callWatcher;
}

