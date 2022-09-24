#include "systemchecker.h"

#include <QDebug>
#include <QFile>

#include "pathhelper.h"

SystemChecker::SystemChecker(QObject *parent) : QObject(parent)
{
}

void SystemChecker::checkDependencies()
{
    const QStringList dependencies {"node", "npm", "bw"};

    bool found;
    for (const auto &dependency : dependencies) {
        found = false;
        for (const auto &path : getPaths()) {
            QFile file(path + "/" + dependency);
            if (file.exists()) {
                found = true;
                break;
            }
        }
        if (!found) {
            if (dependency == "node" || dependency == "npm") {
                emit missingRequiredDependency(dependency);
            } else if (dependency == "bw") {
                emit missingBitwardenCli();
            } else {
                emit unknownErrorOccured();
            }
            return;
        }
    }

    emit everythingOk();
}

