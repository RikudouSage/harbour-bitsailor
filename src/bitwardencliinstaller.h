#ifndef BITWARDENCLIINSTALLER_H
#define BITWARDENCLIINSTALLER_H

#include <QObject>
#include <QProcess>

class BitwardenCliInstaller : public QObject
{
    Q_OBJECT
public:
    explicit BitwardenCliInstaller(QObject *parent = nullptr);
    Q_INVOKABLE void install();
    Q_INVOKABLE void update();

signals:
    void installFinished(bool success);
    void updateFinished(bool success);

private slots:
    void installProcessExited(int exitCode);
    void updateProcessExited(int exitCode);

private:
    QProcess* installProcess = new QProcess(this);
    QProcess* updateProcess = new QProcess(this);
};

#endif // BITWARDENCLIINSTALLER_H
