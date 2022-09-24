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

signals:
    void finished(bool success);

private slots:
    void installProcessExited(int exitCode);

private:
    QProcess* installProcess = new QProcess(this);
};

#endif // BITWARDENCLIINSTALLER_H
