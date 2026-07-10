#include "secretshandler.h"

#include <Sailfish/Secrets/collectionnamesrequest.h>
#include <Sailfish/Secrets/createcollectionrequest.h>
#include <Sailfish/Secrets/result.h>
#include <Sailfish/Secrets/secret.h>
#include <Sailfish/Secrets/storesecretrequest.h>
#include <Sailfish/Secrets/storedsecretrequest.h>
#include <Sailfish/Secrets/deletesecretrequest.h>
#include <Sailfish/Secrets/deletecollectionrequest.h>

#include <QDebug>

using Sailfish::Secrets::CollectionNamesRequest;
using Sailfish::Secrets::SecretManager;
using Sailfish::Secrets::Request;
using Sailfish::Secrets::Result;
using Sailfish::Secrets::CreateCollectionRequest;
using Sailfish::Secrets::Secret;
using Sailfish::Secrets::StoreSecretRequest;
using Sailfish::Secrets::StoredSecretRequest;
using Sailfish::Secrets::DeleteSecretRequest;
using Sailfish::Secrets::DeleteCollectionRequest;

const QString SecretsHandler::collectionName(QStringLiteral("bitsailor"));

static const QString sessionIdName = "sessionId";
static const QString usernameName = "username";
static const QString passwordName = "password";
static const QString clientIdName = "clientId";
static const QString pinName = "pin";
static const QString internalPinName = "internalPin";
static const QString apiKeyName = "apiKey";
static const QString invalidCertsName = "invalidCertsAllowed";

SecretsHandler::SecretsHandler(QObject *parent) : QObject(parent)
{
    CollectionNamesRequest cnr;
    cnr.setManager(secretManager);
    cnr.setStoragePluginName(SecretManager::DefaultEncryptedStoragePluginName);
    cnr.startRequest();
    cnr.waitForFinished();

    hasBitsailorCollection = isResultValid(cnr) && cnr.collectionNames().contains(collectionName);
}

QString SecretsHandler::getSessionId()
{
    return getData(prefixed(sessionIdName));
}

QString SecretsHandler::getUsername()
{
    return getData(prefixed(usernameName));
}

QString SecretsHandler::getPassword()
{
    return getData(prefixed(passwordName));
}

QString SecretsHandler::getClientId()
{
    return getData(prefixed(clientIdName));
}

QString SecretsHandler::getPin()
{
    return getData(prefixed(pinName));
}

QString SecretsHandler::getInternalPin()
{
    return getData(prefixed(internalPinName));
}

QString SecretsHandler::getServerApiKey()
{
    return getData(prefixed(apiKeyName));
}

bool SecretsHandler::invalidCertificatesAllowed()
{
    return getData(prefixed(invalidCertsName)) == "true";
}

bool SecretsHandler::hasPin()
{
    auto pin = getPin();
    return !pin.isNull() && !pin.isEmpty();
}

void SecretsHandler::removePin()
{
    deleteSecret(prefixed(pinName));
}

void SecretsHandler::removePassword()
{
    deleteSecret(prefixed(passwordName));
}

bool SecretsHandler::hasSessionId()
{
    auto sessionId = getSessionId();
    return !sessionId.isNull() && !sessionId.isEmpty();
}

void SecretsHandler::removeSessionId()
{
    deleteSecret(prefixed(sessionIdName));
}

bool SecretsHandler::clearAllSecrets()
{
    DeleteCollectionRequest dcr;
    dcr.setCollectionName(collectionName);
    dcr.setStoragePluginName(SecretManager::DefaultEncryptedStoragePluginName);
    dcr.setUserInteractionMode(SecretManager::SystemInteraction);
    dcr.setManager(secretManager);
    dcr.startRequest();
    dcr.waitForFinished();

    auto success = isResultValid(dcr);

    hasBitsailorCollection = !success;
    return success;
}

bool SecretsHandler::hasInternalPin()
{
    auto pin = getInternalPin();
    return !pin.isNull() && !pin.isEmpty();
}

void SecretsHandler::allowInvalidCertificates()
{
    storeData(prefixed(invalidCertsName), "true");
}

void SecretsHandler::disallowInvalidCertificates()
{
    deleteSecret(prefixed(invalidCertsName));
}

void SecretsHandler::setSessionId(const QString &sessionId)
{
    storeData(prefixed(sessionIdName), sessionId);
}

void SecretsHandler::setUsername(const QString &username)
{
    storeData(prefixed(usernameName), username);
}

void SecretsHandler::setPassword(const QString &password)
{
    storeData(prefixed(passwordName), password);
}

void SecretsHandler::setClientId(const QString &clientId)
{
    storeData(prefixed(clientIdName), clientId);
}

void SecretsHandler::setPin(const QString &pin)
{
    storeData(prefixed(pinName), pin);
}

void SecretsHandler::setInternalPin(const QString &pin)
{
    storeData(prefixed(internalPinName), pin);
}

void SecretsHandler::setServerApiKey(const QString &apiKey)
{
    storeData(prefixed(apiKeyName), apiKey);
}

const QString SecretsHandler::prefixed(const QString &name)
{
    return accountManager->currentAccount() + ":" + name;
}

bool SecretsHandler::isResultValid(const Request &request)
{
    auto result = request.result();
    auto isSuccess = result.errorCode() == Result::NoError;
    if (!isSuccess) {
        qWarning() << result.errorMessage();
    }

    return isSuccess;
}

bool SecretsHandler::isSecretValid(const Secret &secret)
{
    return !secret.name().isNull() && !secret.name().isEmpty();
}

bool SecretsHandler::storeData(const QString &name, const QString &data)
{
    if (!hasBitsailorCollection) {
        createCollection();
        // todo handle case where collection isn't created
    }

    auto existingSecret = getSecret(name);
    if (isSecretValid(existingSecret)) {
        deleteSecret(name);
    }

    Secret secret(toIdentifier(name));
    secret.setData(data.toUtf8());

    StoreSecretRequest ssr;
    ssr.setManager(secretManager);
    ssr.setSecretStorageType(StoreSecretRequest::CollectionSecret);
    ssr.setUserInteractionMode(SecretManager::SystemInteraction);
    ssr.setSecret(secret);
    ssr.startRequest();
    ssr.waitForFinished();

    return isResultValid(ssr);
}

Secret SecretsHandler::getSecret(const QString &name)
{
    if (!hasBitsailorCollection) {
        return Secret();
    }

    StoredSecretRequest ssr;
    ssr.setManager(secretManager);
    ssr.setUserInteractionMode(SecretManager::SystemInteraction);
    ssr.setIdentifier(toIdentifier(name));
    ssr.startRequest();
    ssr.waitForFinished();

    auto success = isResultValid(ssr);
    if (!success) {
        return Secret();
    }

    return ssr.secret();
}

bool SecretsHandler::deleteSecret(const QString &name)
{
    DeleteSecretRequest dsr;
    dsr.setManager(secretManager);
    dsr.setIdentifier(toIdentifier(name));
    dsr.setUserInteractionMode(SecretManager::SystemInteraction);
    dsr.startRequest();
    dsr.waitForFinished();

    return isResultValid(dsr);
}

QString SecretsHandler::getData(const QString &name)
{
    auto secret = getSecret(name);
    if (!isSecretValid(secret)) {
        return QString();
    }

    return QString::fromUtf8(secret.data());
}

bool SecretsHandler::createCollection()
{
    CreateCollectionRequest ccr;
    ccr.setManager(secretManager);
    ccr.setCollectionName(collectionName);
    ccr.setAccessControlMode(SecretManager::OwnerOnlyMode);
    ccr.setCollectionLockType(CreateCollectionRequest::DeviceLock);
    ccr.setDeviceLockUnlockSemantic(SecretManager::DeviceLockKeepUnlocked);
    ccr.setStoragePluginName(SecretManager::DefaultEncryptedStoragePluginName);
    ccr.setEncryptionPluginName(SecretManager::DefaultEncryptedStoragePluginName);
    ccr.startRequest();
    ccr.waitForFinished();

    auto success = isResultValid(ccr);
    hasBitsailorCollection = success;

    return success;
}

Secret::Identifier SecretsHandler::toIdentifier(const QString &name)
{
    return Secret::Identifier(name, collectionName, SecretManager::DefaultEncryptedStoragePluginName);
}
