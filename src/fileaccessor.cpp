#include "fileaccessor.h"

#include <QDir>
#include <QStandardPaths>

FileAccessor::FileAccessor(QObject *parent) : QObject(parent)
{

}

bool FileAccessor::deleteConfigDirectory()
{
    return deleteDirectory(QStandardPaths::writableLocation(QStandardPaths::AppConfigLocation));
}

bool FileAccessor::deleteTemporaryFilesDirectory()
{
    return deleteDirectory(QStandardPaths::writableLocation(QStandardPaths::CacheLocation));
}

bool FileAccessor::deleteDirectory(QString path)
{
    QDir dir(path);
    return dir.removeRecursively();
}
