#ifndef SECRETSHANDLER_H
#define SECRETSHANDLER_H

#include <QObject>

#include <Sailfish/Secrets/secretmanager.h>
#include <Sailfish/Secrets/request.h>
#include <Sailfish/Secrets/secret.h>

using Sailfish::Secrets::SecretManager;
using Sailfish::Secrets::Request;
using Sailfish::Secrets::Secret;

class SecretsHandler : public QObject
{
    Q_OBJECT
public:
    explicit SecretsHandler(QObject *parent = nullptr);

    QString getSessionId();
    QString getUsername();
    QString getPassword();
    QString getClientId();

    void setSessionId(const QString &sessionId);
    void setUsername(const QString &username);
    void setPassword(const QString &password);
    void setClientId(const QString &clientId);

private:
    static const QString collectionName;
    SecretManager* secretManager = new SecretManager(this);
    bool hasBitsailorCollection = false;

    bool isResultValid(const Request &request);
    bool storeData(const QString &name, const QString &data);
    QString getData(const QString &name);
    bool createCollection();
    Secret::Identifier toIdentifier(const QString &name);
};

#endif // SECRETSHANDLER_H
