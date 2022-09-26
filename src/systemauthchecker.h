#ifndef SYSTEMAUTHCHECKER_H
#define SYSTEMAUTHCHECKER_H

#include <QObject>
#include <QProcess>

class SystemAuthChecker : public QObject
{
    Q_OBJECT
public:
    explicit SystemAuthChecker(QObject *parent = nullptr);
    Q_INVOKABLE void checkAuth();

signals:
    void authResolved(bool success);

private slots:
    void processFinished(int exitCode, QProcess::ExitStatus exitStatus);

private:
    QProcess* checkProcess = new QProcess(this);
};

#endif // SYSTEMAUTHCHECKER_H
