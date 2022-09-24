#include "bitwardencli.h"

#include <QDebug>

BitwardenCli::BitwardenCli(QObject *parent) : QObject(parent)
{
}

void BitwardenCli::checkLoginStatus()
{
    startProcess({"login", "--check"}, LoginCheck);
}

void BitwardenCli::checkVaultUnlocked()
{
    auto sessionId = secretsHandler->getSessionId();
    if (sessionId.isNull() || sessionId.isEmpty()) {
        emit vaultLockStatusResolved(false);
        return;
    }

    startProcess({"unlock", "--check", "--session", sessionId}, VaultUnlocked);
}

void BitwardenCli::onFinished(int exitCode, Method method)
{
    auto process = processes.take(method);

    switch (method) {
    case LoginCheck:
        emit loginStatusResolved(exitCode == 0);
        break;
    case VaultUnlocked:
        emit vaultLockStatusResolved(exitCode == 0);
        break;
    }

    delete process;
}

void BitwardenCli::startProcess(const QStringList &arguments, Method method)
{
    QProcess* process = new QProcess(this);
    process->setWorkingDirectory(getDataPath());

    if (processes.contains(method)) {
        auto oldProcess = processes.take(method);
        oldProcess->terminate();
        oldProcess->deleteLater();
    }

    connect(process, static_cast<void (QProcess::*)(int, QProcess::ExitStatus)>(&QProcess::finished), [=](int exitCode, QProcess::ExitStatus exitStatus) {
        Q_UNUSED(exitStatus);
        onFinished(exitCode, method);
    });
    connect(process, &QProcess::errorOccurred, [=] (QProcess::ProcessError error) {
        qWarning() << error;
    });

    processes.insert(method, process);
    process->start(bw, arguments);
}
