#include "pathhelper.h"

#include <QStandardPaths>

QStringList getPaths()
{
    auto paths = QString::fromUtf8(qgetenv("PATH")).split(":");
    paths.prepend(getPrivateBinDirPath());

    return paths;
}

QString getDataPath()
{
    return QStandardPaths::writableLocation(QStandardPaths::DataLocation);
}

QString getPrivateBinDirPath()
{
    return getDataPath() + "/bin";
}
