#include "systemauthchecker.h"

#include <QCoreApplication>
#include <QDebug>

SystemAuthChecker::SystemAuthChecker(QObject *parent) : QObject(parent)
{
    connect(checkProcess, static_cast<void (QProcess::*)(int, QProcess::ExitStatus)>(&QProcess::finished), this, &SystemAuthChecker::processFinished);
}

void SystemAuthChecker::checkAuth()
{
    checkProcess->start("pkcheck", {
        "--process",
        QString::number(QCoreApplication::applicationPid()),
        "--action-id",
        "cz.chrastecky.bitsailor.auth",
        "--allow-user-interaction"
    });
}

void SystemAuthChecker::processFinished(int exitCode, QProcess::ExitStatus exitStatus)
{
    Q_UNUSED(exitStatus);
    emit authResolved(exitCode == 0);
}
