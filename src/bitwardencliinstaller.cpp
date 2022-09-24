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

    connect(installProcess, SIGNAL(finished(int)), this, SLOT(installProcessExited(int)));
}

void BitwardenCliInstaller::install()
{
    for (const auto &path : getPaths()) {
        QFile file(path + "/bw");
        if (file.exists()) {
            emit finished(true);
            return;
        }
    }

    installProcess->start("npm", {"install", "@bitwarden/cli"});
}

void BitwardenCliInstaller::installProcessExited(int exitCode)
{
    if (exitCode != 0) {
        emit finished(false);
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

    emit finished(result);
}
