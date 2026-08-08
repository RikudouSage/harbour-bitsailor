#ifndef SECRETSHANDLER_H
#define SECRETSHANDLER_H

#include <QObject>
#include <QJsonObject>

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

    QJsonObject getSessionJson();
    QJsonObject getEncryptedVault();
    Q_INVOKABLE QString getUsername();
    QString getPassword();
    QString getUserKey();
    Q_INVOKABLE QString getClientId();
    QString getPin();
    QString getInternalPin();
    Q_INVOKABLE bool invalidCertificatesAllowed();

    bool hasEncryptedVault();
    Q_INVOKABLE bool hasSessionJson();
    bool hasUserKey();
    Q_INVOKABLE bool hasPin();
    Q_INVOKABLE bool hasInternalPin();

    Q_INVOKABLE void removePin();
    Q_INVOKABLE void removePassword();
    void removeLegacyPassword();
    void removeUserKey();
    Q_INVOKABLE void removeSessionJson();
    Q_INVOKABLE void removeEncryptedVault();
    Q_INVOKABLE bool clearAllSecrets();

    Q_INVOKABLE void allowInvalidCertificates();
    Q_INVOKABLE void disallowInvalidCertificates();

    void setSessionJson(const QJsonObject &sessionJson);
    void setEncryptedVault(const QJsonObject &json);
    void setUsername(const QString &username);
    Q_INVOKABLE void setPassword(const QString &password);
    void setUserKey(const QString &userKey);
    Q_INVOKABLE bool storeUserKeyFromSessionJson();
    void setClientId(const QString &clientId);
    Q_INVOKABLE void setPin(const QString &pin);
    Q_INVOKABLE void setInternalPin(const QString &pin);

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
