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

#include "defer.h"

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
static const QString userKeyName = "userKey";
static const QString clientIdName = "clientId";
static const QString pinName = "pin";
static const QString internalPinName = "internalPin";
static const QString invalidCertsName = "invalidCertsAllowed";

#ifdef QT_DEBUG
static QSettings &insecureEmulatorSecrets()
{
    static QSettings settings(QStringLiteral("cz.chrastecky"), QStringLiteral("bitsailor-insecure-emulator-secrets"));
    return settings;
}
#endif

SecretsHandler::SecretsHandler(AccountManager *manager, QObject *parent)
    : QObject(parent), accountManager(manager)
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
    const auto json = getData(prefixed(sessionJsonName));
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
    const auto json = getData(prefixed(encryptedVaultName));
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
    return getData(prefixed(usernameName));
}

QString SecretsHandler::getPassword()
{
    return getData(prefixed(passwordName));
}

QString SecretsHandler::getUserKey()
{
    return getData(prefixed(userKeyName));
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

bool SecretsHandler::invalidCertificatesAllowed()
{
    return getData(prefixed(invalidCertsName)) == "true";
}

bool SecretsHandler::hasEncryptedVault()
{
    auto value = getData(prefixed(encryptedVaultName));
    return !value.isNull() && !value.isEmpty();
}

bool SecretsHandler::hasSessionJson()
{
    auto sessionJson = getData(prefixed(sessionJsonName));
    return !sessionJson.isNull() && !sessionJson.isEmpty();
}

bool SecretsHandler::hasUserKey()
{
    auto userKey = getUserKey();
    return !userKey.isNull() && !userKey.isEmpty();
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
    deleteSecret(prefixed(userKeyName));
}

void SecretsHandler::removeLegacyPassword()
{
    deleteSecret(prefixed(passwordName));
}

void SecretsHandler::removeUserKey()
{
    deleteSecret(prefixed(userKeyName));
}

void SecretsHandler::removeSessionJson()
{
    deleteSecret(prefixed(sessionJsonName));
}

void SecretsHandler::removeEncryptedVault()
{
    deleteSecret(prefixed(encryptedVaultName));
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
    storeData(prefixed(invalidCertsName), "true");
}

void SecretsHandler::disallowInvalidCertificates()
{
    deleteSecret(prefixed(invalidCertsName));
}

void SecretsHandler::setSessionJson(const QJsonObject &sessionJson)
{
    storeData(prefixed(sessionJsonName), QString::fromUtf8(QJsonDocument(sessionJson).toJson(QJsonDocument::Compact)));
}

void SecretsHandler::setEncryptedVault(const QJsonObject &json)
{
    storeData(prefixed(encryptedVaultName), QString::fromUtf8(QJsonDocument(json).toJson(QJsonDocument::Compact)));
}

void SecretsHandler::setUsername(const QString &username)
{
    storeData(prefixed(usernameName), username);
}

void SecretsHandler::setPassword(const QString &password)
{
    storeData(prefixed(passwordName), password);
}

void SecretsHandler::setUserKey(const QString &userKey)
{
    storeData(prefixed(userKeyName), userKey);
}

bool SecretsHandler::storeUserKeyFromSessionJson()
{
    const auto encryption = getSessionJson().value("encryption").toObject();
    const auto userKey = encryption.value("userKey").toString();
    if (userKey.isNull() || userKey.isEmpty()) {
        qWarning() << "Current session JSON does not contain an unlocked user key.";
        return false;
    }

    setUserKey(userKey);
    removeLegacyPassword();
    return true;
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

bool SecretsHandler::migrateUnprefixed(const QString &id)
{
    const auto keys = {
        encryptedVaultName, sessionJsonName, usernameName, passwordName, userKeyName, clientIdName,
        pinName, internalPinName, invalidCertsName,
    };

    bool failed = false;
    defer({
        for (const auto &key : keys) {
            deleteSecret(key);
            if (failed) {
                deleteSecret(prefixed(key, id));
            }
        }
    });

    for (const auto &key : keys) {
        const auto value = getData(key);
        if (value.isEmpty()) {
            continue;
        }

        if (!storeData(prefixed(key, id), value)) {
            failed = true;
            return false;
        }
    }

    return true;
}

const QString SecretsHandler::prefixed(const QString &name)
{
    return prefixed(name, accountManager->getCurrentAccount().id);
}

const QString SecretsHandler::prefixed(const QString &name, const QString &prefix)
{
    return prefix + ":" + name;
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
