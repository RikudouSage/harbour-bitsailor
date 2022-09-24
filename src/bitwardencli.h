#ifndef BITWARDENCLI_H
#define BITWARDENCLI_H

#include <QObject>
#include <QProcess>
#include <QMap>
#include <QMetaEnum>

#include "pathhelper.h"
#include "secretshandler.h"

class BitwardenCli : public QObject
{
    Q_OBJECT
public:
    explicit BitwardenCli(QObject *parent = nullptr);

    Q_INVOKABLE void checkLoginStatus();
    Q_INVOKABLE void checkVaultUnlocked();

    enum Method {
        LoginCheck,
        VaultUnlocked,
    };

signals:
    void loginStatusResolved(bool loggedIn);
    void vaultLockStatusResolved(bool unlocked);

private slots:
    void onFinished(int exitCode, Method method);

private:
    const QString bw = getPrivateBinDirPath() + "/bw";
    QMap<Method, QProcess*> processes;

    void startProcess(const QStringList &arguments, Method method);
    SecretsHandler* secretsHandler = new SecretsHandler(this);
};

#endif // BITWARDENCLI_H
