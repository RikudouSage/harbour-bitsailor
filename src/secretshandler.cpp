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
#include <QJsonDocument>
#include <QJsonParseError>
#include <QSettings>

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

const QString SecretsHandler::collectionName(QStringLiteral("bitsailorv2"));

static const QString encryptedVaultName = "encryptedVault";
static const QString sessionJsonName = "sessionJson";
static const QString usernameName = "username";
static const QString passwordName = "password";
static const QString clientIdName = "clientId";
static const QString pinName = "pin";
static const QString internalPinName = "internalPin";
static const QString apiKeyName = "apiKey";
static const QString invalidCertsName = "invalidCertsAllowed";

#ifdef QT_DEBUG
static QSettings &insecureEmulatorSecrets()
{
    static QSettings settings(QStringLiteral("cz.chrastecky"), QStringLiteral("bitsailor-insecure-emulator-secrets"));
    return settings;
}
#endif

SecretsHandler::SecretsHandler(QObject *parent) : QObject(parent)
{
#ifdef QT_DEBUG
    qWarning() << "Using insecure debug secrets storage. Do not enable this in release builds.";
    hasBitsailorCollection = true;
#else
    CollectionNamesRequest cnr;
    cnr.setManager(secretManager);
    cnr.setStoragePluginName(SecretManager::DefaultEncryptedStoragePluginName);
    cnr.startRequest();
    cnr.waitForFinished();

    hasBitsailorCollection = isResultValid(cnr) && cnr.collectionNames().contains(collectionName);
#endif
}

QJsonObject SecretsHandler::getSessionJson()
{
    const auto json = getData(sessionJsonName);
    QJsonParseError err;
    auto doc = QJsonDocument::fromJson(json.toUtf8(), &err);
    if (err.error) {
        qWarning() << "Failed parsing session: " << err.errorString();
        return QJsonObject();
    }

    return doc.object();
}

QJsonObject SecretsHandler::getEncryptedVault()
{
    const auto json = getData(encryptedVaultName);
    QJsonParseError err;
    auto doc = QJsonDocument::fromJson(json.toUtf8(), &err);
    if (err.error) {
        qWarning() << "Failed parsing vault: " << err.errorString();
        return QJsonObject();
    }

    return doc.object();
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

QString SecretsHandler::getPin()
{
    return getData(pinName);
}

QString SecretsHandler::getInternalPin()
{
    return getData(internalPinName);
}

QString SecretsHandler::getServerApiKey()
{
    return getData(apiKeyName);
}

bool SecretsHandler::invalidCertificatesAllowed()
{
    return getData(invalidCertsName) == "true";
}

bool SecretsHandler::hasEncryptedVault()
{
    auto value = getData(encryptedVaultName);
    return !value.isNull() && !value.isEmpty();
}

bool SecretsHandler::hasSessionJson()
{
    auto sessionJson = getData(sessionJsonName);
    return !sessionJson.isNull() && !sessionJson.isEmpty();
}

bool SecretsHandler::hasPin()
{
    auto pin = getPin();
    return !pin.isNull() && !pin.isEmpty();
}

void SecretsHandler::removePin()
{
    deleteSecret(pinName);
}

void SecretsHandler::removePassword()
{
    deleteSecret(passwordName);
}

void SecretsHandler::removeSessionJson()
{
    deleteSecret(sessionJsonName);
}

void SecretsHandler::removeEncryptedVault()
{
    deleteSecret(encryptedVaultName);
}

bool SecretsHandler::clearAllSecrets()
{
#ifdef QT_DEBUG
    auto &settings = insecureEmulatorSecrets();
    settings.clear();
    settings.sync();
    return settings.status() == QSettings::NoError;
#else
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
#endif
}

bool SecretsHandler::hasInternalPin()
{
    auto pin = getInternalPin();
    return !pin.isNull() && !pin.isEmpty();
}

void SecretsHandler::allowInvalidCertificates()
{
    storeData(invalidCertsName, "true");
}

void SecretsHandler::disallowInvalidCertificates()
{
    deleteSecret(invalidCertsName);
}

void SecretsHandler::setSessionJson(const QJsonObject &sessionJson)
{
    storeData(sessionJsonName, QString::fromUtf8(QJsonDocument(sessionJson).toJson(QJsonDocument::Compact)));
}

void SecretsHandler::setEncryptedVault(const QJsonObject &json)
{
    storeData(encryptedVaultName, QString::fromUtf8(QJsonDocument(json).toJson(QJsonDocument::Compact)));
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

void SecretsHandler::setPin(const QString &pin)
{
    storeData(pinName, pin);
}

void SecretsHandler::setInternalPin(const QString &pin)
{
    storeData(internalPinName, pin);
}

void SecretsHandler::setServerApiKey(const QString &apiKey)
{
    storeData(apiKeyName, apiKey);
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
#ifdef QT_DEBUG
    auto &settings = insecureEmulatorSecrets();
    settings.setValue(name, data);
    settings.sync();
    return settings.status() == QSettings::NoError;
#else
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
#endif
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
#ifdef QT_DEBUG
    auto &settings = insecureEmulatorSecrets();
    settings.remove(name);
    settings.sync();
    return settings.status() == QSettings::NoError;
#else
    DeleteSecretRequest dsr;
    dsr.setManager(secretManager);
    dsr.setIdentifier(toIdentifier(name));
    dsr.setUserInteractionMode(SecretManager::SystemInteraction);
    dsr.startRequest();
    dsr.waitForFinished();

    return isResultValid(dsr);
#endif
}

QString SecretsHandler::getData(const QString &name)
{
#ifdef QT_DEBUG
    return insecureEmulatorSecrets().value(name).toString();
#else
    auto secret = getSecret(name);
    if (!isSecretValid(secret)) {
        return QString();
    }

    return QString::fromUtf8(secret.data());
#endif
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
