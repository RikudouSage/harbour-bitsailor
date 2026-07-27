#ifndef FILEACCESSOR_H
#define FILEACCESSOR_H

#include <QObject>

class FileAccessor : public QObject
{
    Q_OBJECT
public:
    explicit FileAccessor(QObject *parent = nullptr);
    Q_INVOKABLE bool deleteConfigDirectory();
    Q_INVOKABLE bool deleteTemporaryFilesDirectory();
private:
    bool deleteDirectory(QString path);
};

#endif // FILEACCESSOR_H
