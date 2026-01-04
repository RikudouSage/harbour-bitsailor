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
    Q_INVOKABLE QString getUsername();
    QString getPassword();
    Q_INVOKABLE QString getClientId();
    QString getPin();
    QString getInternalPin();
    QString getServerApiKey();
    bool invalidCertificatesAllowed();

    Q_INVOKABLE bool hasPin();
    Q_INVOKABLE void removePin();
    Q_INVOKABLE void removePassword();
    Q_INVOKABLE bool hasSessionId();
    Q_INVOKABLE void removeSessionId();
    Q_INVOKABLE bool clearAllSecrets();
    Q_INVOKABLE bool hasInternalPin();
    Q_INVOKABLE void allowInvalidCertificates();
    void disallowInvalidCertificates();

    void setSessionId(const QString &sessionId);
    void setUsername(const QString &username);
    Q_INVOKABLE void setPassword(const QString &password);
    void setClientId(const QString &clientId);
    Q_INVOKABLE void setPin(const QString &pin);
    Q_INVOKABLE void setInternalPin(const QString &pin);
    void setServerApiKey(const QString &apiKey);

private:
    static const QString collectionName;
    SecretManager* secretManager = new SecretManager(this);
    bool hasBitsailorCollection = false;

    bool isResultValid(const Request &request);
    bool isSecretValid(const Secret &secret);
    bool storeData(const QString &name, const QString &data);
    Secret getSecret(const QString &name);
    bool deleteSecret(const QString &name);
    QString getData(const QString &name);
    bool createCollection();
    Secret::Identifier toIdentifier(const QString &name);
};

#endif // SECRETSHANDLER_H
