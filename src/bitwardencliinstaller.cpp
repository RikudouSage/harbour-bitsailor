#include "bitwardencliinstaller.h"

#include <QFile>
#include <QDebug>
#include <QStandardPaths>
#include <QProcess>
#include <QDir>

#include "pathhelper.h"

BitwardenCliInstaller::BitwardenCliInstaller(QObject *parent) : QObject(parent)
{
    QDir dataDir(getDataPath());
    dataDir.exists();

    if (!dataDir.exists()) {
        dataDir.mkpath(".");
    }
    installProcess->setWorkingDirectory(getDataPath());
    updateProcess->setWorkingDirectory(getDataPath());

    connect(installProcess, SIGNAL(finished(int)), this, SLOT(installProcessExited(int)));
    connect(updateProcess, SIGNAL(finished(int)), this, SLOT(updateProcessExited(int)));

#ifdef QT_DEBUG
    connect(installProcess, &QProcess::readyReadStandardError, [=] (auto signal) {
        Q_UNUSED(signal);
        qDebug() << static_cast<QString>(installProcess->readAllStandardError());
    });
    connect(installProcess, &QProcess::readyReadStandardOutput, [=] (auto signal) {
        Q_UNUSED(signal);
        qDebug() << static_cast<QString>(installProcess->readAllStandardOutput());
    });
    connect(updateProcess, &QProcess::readyReadStandardError, [=] (auto signal) {
        Q_UNUSED(signal);
        qDebug() << static_cast<QString>(updateProcess->readAllStandardError());
    });
    connect(updateProcess, &QProcess::readyReadStandardOutput, [=] (auto signal) {
        Q_UNUSED(signal);
        qDebug() << static_cast<QString>(updateProcess->readAllStandardOutput());
    });
#endif
}

void BitwardenCliInstaller::install()
{
    for (const auto &path : getPaths()) {
        QFile file(path + "/bw");
        if (file.exists()) {
            emit installFinished(true);
            return;
        }
    }

    installProcess->start("npm", {"install", "@bitwarden/cli", "@babel/core"});
}

void BitwardenCliInstaller::update()
{
    updateProcess->start("npm", {"update"});
}

void BitwardenCliInstaller::installProcessExited(int exitCode)
{
#ifdef QT_DEBUG
    qDebug() << "Install process exited with " + QString::number(exitCode);
#endif
    if (exitCode != 0) {
        emit installFinished(false);
        return;
    }
    QDir binDir(getPrivateBinDirPath());
    if (!binDir.exists()) {
        binDir.mkpath(".");
    }

    QFile bw(getPrivateBinDirPath() + "/bw");
    if (bw.exists()) {
        bw.remove();
    }
    auto result = QFile::link(getDataPath() + "/node_modules/.bin/bw", bw.fileName());

    emit installFinished(result);
}

void BitwardenCliInstaller::updateProcessExited(int exitCode)
{
#ifdef QT_DEBUG
    qDebug() << "Update process exited with " + QString::number(exitCode);
#endif
    emit updateFinished(exitCode == 0);
}
