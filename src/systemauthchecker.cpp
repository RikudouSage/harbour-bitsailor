#include "systemauthchecker.h"

#include <QCoreApplication>
#include <QDebug>

#include <QDBusArgument>
#include <QDBusInterface>
#include <QDBusConnection>
#include <QDBusPendingReply>
#include <QtDBus>

#include "authlogger.h"

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
    AuthLogger::log(QStringLiteral("SystemAuthChecker: constructed"));
}

void SystemAuthChecker::checkAuth()
{
    AuthLogger::log(QStringLiteral("SystemAuthChecker: checkAuth requested pid=%1 systemBusConnected=%2").arg(
        QString::number(QCoreApplication::applicationPid()),
        QDBusConnection::systemBus().isConnected() ? QStringLiteral("true") : QStringLiteral("false")
    ));

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

    AuthLogger::log(QStringLiteral("SystemAuthChecker: polkit interface valid=%1 lastError=%2").arg(
        polkit.isValid() ? QStringLiteral("true") : QStringLiteral("false"),
        polkit.lastError().message()
    ));

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
    AuthLogger::log(QStringLiteral("SystemAuthChecker: async CheckAuthorization call started"));
}

void SystemAuthChecker::finished(QDBusPendingCallWatcher *watcher)
{
    AuthLogger::log(QStringLiteral("SystemAuthChecker: CheckAuthorization finished"));
    QDBusPendingReply<PolkitCheckResult> reply = *watcher;
    if (reply.isError()) {
        qWarning() << reply.error();
        AuthLogger::log(QStringLiteral("SystemAuthChecker: CheckAuthorization error name=%1 message=%2").arg(
            reply.error().name(),
            reply.error().message()
        ));
        return;
    }

    auto item = reply.argumentAt(0).value<QDBusArgument>();
    PolkitCheckResult result;
    item >> result;

    AuthLogger::log(QStringLiteral("SystemAuthChecker: CheckAuthorization result authorized=%1 challenge=%2 detailCount=%3").arg(
        result.isAuthorized ? QStringLiteral("true") : QStringLiteral("false"),
        result.isChallenge ? QStringLiteral("true") : QStringLiteral("false"),
        QString::number(result.details.size())
    ));
    emit authResolved(result.isAuthorized);
}

QDBusPendingCallWatcher *SystemAuthChecker::createCallWatcher(QDBusPendingCall &dbusCall)
{
    if (callWatcher != nullptr) {
        delete callWatcher;
    }
    callWatcher = new QDBusPendingCallWatcher(dbusCall, this);

    AuthLogger::log(QStringLiteral("SystemAuthChecker: DBus call watcher created"));
    return callWatcher;
}
