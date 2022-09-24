#ifndef SYSTEMCHECKER_H
#define SYSTEMCHECKER_H

#include <QObject>

class SystemChecker : public QObject
{
    Q_OBJECT
public:
    explicit SystemChecker(QObject *parent = nullptr);
    Q_INVOKABLE void checkDependencies();

signals:
    void everythingOk();
    void missingRequiredDependency(const QString &name);
    void missingBitwardenCli();
    void unknownErrorOccured();
};

#endif // SYSTEMCHECKER_H
