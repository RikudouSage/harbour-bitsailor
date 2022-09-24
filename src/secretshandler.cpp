#include "secretshandler.h"

#include <Sailfish/Secrets/collectionnamesrequest.h>
#include <Sailfish/Secrets/createcollectionrequest.h>
#include <Sailfish/Secrets/result.h>
#include <Sailfish/Secrets/secret.h>
#include <Sailfish/Secrets/storesecretrequest.h>
#include <Sailfish/Secrets/storedsecretrequest.h>

#include <QDebug>

using Sailfish::Secrets::CollectionNamesRequest;
using Sailfish::Secrets::SecretManager;
using Sailfish::Secrets::Request;
using Sailfish::Secrets::Result;
using Sailfish::Secrets::CreateCollectionRequest;
using Sailfish::Secrets::Secret;
using Sailfish::Secrets::StoreSecretRequest;
using Sailfish::Secrets::StoredSecretRequest;

const QString SecretsHandler::collectionName(QStringLiteral("bitsailor"));

static const QString sessionIdName = "sessionId";
static const QString usernameName = "username";
static const QString passwordName = "password";
static const QString clientIdName = "clientId";

SecretsHandler::SecretsHandler(QObject *parent) : QObject(parent)
{
    CollectionNamesRequest cnr;
    cnr.setManager(secretManager);
    cnr.setStoragePluginName(SecretManager::DefaultEncryptedStoragePluginName);
    cnr.startRequest();
    cnr.waitForFinished();

    hasBitsailorCollection = isResultValid(cnr) && cnr.collectionNames().contains(collectionName);

    qDebug() << hasBitsailorCollection;
}

QString SecretsHandler::getSessionId()
{
    return getData(sessionIdName);
}

QString SecretsHandler::getUsername()
{
    return getData(usernameName);
}

QString SecretsHandler::getPassword()
{
    return getData(passwordName);
}

QString SecretsHandler::getClientId()
{
    return getData(clientIdName);
}

void SecretsHandler::setSessionId(const QString &sessionId)
{
    storeData(sessionIdName, sessionId);
}

void SecretsHandler::setUsername(const QString &username)
{
    storeData(usernameName, username);
}

void SecretsHandler::setPassword(const QString &password)
{
    storeData(passwordName, password);
}

void SecretsHandler::setClientId(const QString &clientId)
{
    storeData(clientIdName, clientId);
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

bool SecretsHandler::storeData(const QString &name, const QString &data)
{
    if (!hasBitsailorCollection) {
        createCollection();
        // todo handle case where collection isn't created
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

QString SecretsHandler::getData(const QString &name)
{
    if (!hasBitsailorCollection) {
        return QString();
    }

    StoredSecretRequest ssr;
    ssr.setManager(secretManager);
    ssr.setUserInteractionMode(SecretManager::SystemInteraction);
    ssr.setIdentifier(toIdentifier(name));
    ssr.startRequest();
    ssr.waitForFinished();

    auto success = isResultValid(ssr);
    if (!success) {
        return QString();
    }

    return QString::fromUtf8(ssr.secret().data());
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

    return isResultValid(ccr);
}

Secret::Identifier SecretsHandler::toIdentifier(const QString &name)
{
    return Secret::Identifier(name, collectionName, SecretManager::DefaultEncryptedStoragePluginName);
}
