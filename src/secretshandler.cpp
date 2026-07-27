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

#include "authlogger.h"

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
    AuthLogger::log(QStringLiteral("SecretsHandler: initializing secrets collection name=%1").arg(collectionName));
#ifdef QT_DEBUG
    qWarning() << "Using insecure debug secrets storage. Do not enable this in release builds.";
    AuthLogger::log(QStringLiteral("SecretsHandler: using insecure debug secrets storage"));
    hasBitsailorCollection = true;
#else
    CollectionNamesRequest cnr;
    cnr.setManager(secretManager);
    cnr.setStoragePluginName(SecretManager::DefaultEncryptedStoragePluginName);
    cnr.startRequest();
    cnr.waitForFinished();

    hasBitsailorCollection = isResultValid(cnr) && cnr.collectionNames().contains(collectionName);
    AuthLogger::log(QStringLiteral("SecretsHandler: collection names fetched success=%1 collectionPresent=%2 collectionCount=%3").arg(
        isResultValid(cnr) ? QStringLiteral("true") : QStringLiteral("false"),
        hasBitsailorCollection ? QStringLiteral("true") : QStringLiteral("false"),
        QString::number(cnr.collectionNames().size())
    ));
#endif
}

QJsonObject SecretsHandler::getSessionJson()
{
    AuthLogger::log(QStringLiteral("SecretsHandler: getSessionJson requested"));
    const auto json = getData(sessionJsonName);
    QJsonParseError err;
    auto doc = QJsonDocument::fromJson(json.toUtf8(), &err);
    if (err.error) {
        qWarning() << "Failed parsing session: " << err.errorString();
        AuthLogger::log(QStringLiteral("SecretsHandler: getSessionJson parse failed error=%1 rawPresent=%2").arg(
            err.errorString(),
            json.isEmpty() ? QStringLiteral("false") : QStringLiteral("true")
        ));
        return QJsonObject();
    }

    AuthLogger::log(QStringLiteral("SecretsHandler: getSessionJson parsed keys=%1 rawBytes=%2").arg(
        QString::number(doc.object().size()),
        QString::number(json.toUtf8().size())
    ));
    return doc.object();
}

QJsonObject SecretsHandler::getEncryptedVault()
{
    AuthLogger::log(QStringLiteral("SecretsHandler: getEncryptedVault requested"));
    const auto json = getData(encryptedVaultName);
    QJsonParseError err;
    auto doc = QJsonDocument::fromJson(json.toUtf8(), &err);
    if (err.error) {
        qWarning() << "Failed parsing vault: " << err.errorString();
        AuthLogger::log(QStringLiteral("SecretsHandler: getEncryptedVault parse failed error=%1 rawPresent=%2").arg(
            err.errorString(),
            json.isEmpty() ? QStringLiteral("false") : QStringLiteral("true")
        ));
        return QJsonObject();
    }

    AuthLogger::log(QStringLiteral("SecretsHandler: getEncryptedVault parsed keys=%1 rawBytes=%2").arg(
        QString::number(doc.object().size()),
        QString::number(json.toUtf8().size())
    ));
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
    AuthLogger::log(QStringLiteral("SecretsHandler: clearAllSecrets requested"));
#ifdef QT_DEBUG
    auto &settings = insecureEmulatorSecrets();
    settings.clear();
    settings.sync();
    const auto success = settings.status() == QSettings::NoError;
    AuthLogger::log(QStringLiteral("SecretsHandler: clearAllSecrets debug result success=%1").arg(success ? QStringLiteral("true") : QStringLiteral("false")));
    return success;
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
    AuthLogger::log(QStringLiteral("SecretsHandler: clearAllSecrets result success=%1 collectionPresent=%2").arg(
        success ? QStringLiteral("true") : QStringLiteral("false"),
        hasBitsailorCollection ? QStringLiteral("true") : QStringLiteral("false")
    ));
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
    AuthLogger::log(QStringLiteral("SecretsHandler: setSessionJson keys=%1").arg(QString::number(sessionJson.size())));
    storeData(sessionJsonName, QString::fromUtf8(QJsonDocument(sessionJson).toJson(QJsonDocument::Compact)));
}

void SecretsHandler::setEncryptedVault(const QJsonObject &json)
{
    AuthLogger::log(QStringLiteral("SecretsHandler: setEncryptedVault keys=%1").arg(QString::number(json.size())));
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

bool SecretsHandler::isResultValid(const Request &request)
{
    auto result = request.result();
    auto isSuccess = result.errorCode() == Result::NoError;
    if (!isSuccess) {
        qWarning() << result.errorMessage();
        AuthLogger::log(QStringLiteral("SecretsHandler: Sailfish Secrets request failed code=%1 message=%2").arg(
            QString::number(result.errorCode()),
            result.errorMessage()
        ));
    }

    return isSuccess;
}

bool SecretsHandler::isSecretValid(const Secret &secret)
{
    return !secret.name().isNull() && !secret.name().isEmpty();
}

bool SecretsHandler::storeData(const QString &name, const QString &data)
{
    AuthLogger::log(QStringLiteral("SecretsHandler: storeData requested name=%1 dataPresent=%2 dataBytes=%3").arg(
        name,
        data.isEmpty() ? QStringLiteral("false") : QStringLiteral("true"),
        QString::number(data.toUtf8().size())
    ));
#ifdef QT_DEBUG
    auto &settings = insecureEmulatorSecrets();
    settings.setValue(name, data);
    settings.sync();
    const auto success = settings.status() == QSettings::NoError;
    AuthLogger::log(QStringLiteral("SecretsHandler: storeData debug result name=%1 success=%2").arg(
        name,
        success ? QStringLiteral("true") : QStringLiteral("false")
    ));
    return success;
#else
    if (!hasBitsailorCollection) {
        AuthLogger::log(QStringLiteral("SecretsHandler: storeData collection missing, creating before storing name=%1").arg(name));
        createCollection();
        // todo handle case where collection isn't created
    }

    auto existingSecret = getSecret(name);
    if (isSecretValid(existingSecret)) {
        AuthLogger::log(QStringLiteral("SecretsHandler: storeData replacing existing secret name=%1").arg(name));
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

    const auto success = isResultValid(ssr);
    AuthLogger::log(QStringLiteral("SecretsHandler: storeData result name=%1 success=%2").arg(
        name,
        success ? QStringLiteral("true") : QStringLiteral("false")
    ));
    return success;
#endif
}

Secret SecretsHandler::getSecret(const QString &name)
{
    AuthLogger::log(QStringLiteral("SecretsHandler: getSecret requested name=%1 collectionPresent=%2").arg(
        name,
        hasBitsailorCollection ? QStringLiteral("true") : QStringLiteral("false")
    ));
    if (!hasBitsailorCollection) {
        AuthLogger::log(QStringLiteral("SecretsHandler: getSecret skipped because collection is missing name=%1").arg(name));
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
        AuthLogger::log(QStringLiteral("SecretsHandler: getSecret failed name=%1").arg(name));
        return Secret();
    }

    AuthLogger::log(QStringLiteral("SecretsHandler: getSecret result name=%1 valid=%2 dataPresent=%3 dataBytes=%4").arg(
        name,
        isSecretValid(ssr.secret()) ? QStringLiteral("true") : QStringLiteral("false"),
        ssr.secret().data().isEmpty() ? QStringLiteral("false") : QStringLiteral("true"),
        QString::number(ssr.secret().data().size())
    ));
    return ssr.secret();
}

bool SecretsHandler::deleteSecret(const QString &name)
{
    AuthLogger::log(QStringLiteral("SecretsHandler: deleteSecret requested name=%1").arg(name));
#ifdef QT_DEBUG
    auto &settings = insecureEmulatorSecrets();
    settings.remove(name);
    settings.sync();
    const auto success = settings.status() == QSettings::NoError;
    AuthLogger::log(QStringLiteral("SecretsHandler: deleteSecret debug result name=%1 success=%2").arg(
        name,
        success ? QStringLiteral("true") : QStringLiteral("false")
    ));
    return success;
#else
    DeleteSecretRequest dsr;
    dsr.setManager(secretManager);
    dsr.setIdentifier(toIdentifier(name));
    dsr.setUserInteractionMode(SecretManager::SystemInteraction);
    dsr.startRequest();
    dsr.waitForFinished();

    const auto success = isResultValid(dsr);
    AuthLogger::log(QStringLiteral("SecretsHandler: deleteSecret result name=%1 success=%2").arg(
        name,
        success ? QStringLiteral("true") : QStringLiteral("false")
    ));
    return success;
#endif
}

QString SecretsHandler::getData(const QString &name)
{
    AuthLogger::log(QStringLiteral("SecretsHandler: getData requested name=%1").arg(name));
#ifdef QT_DEBUG
    const auto data = insecureEmulatorSecrets().value(name).toString();
    AuthLogger::log(QStringLiteral("SecretsHandler: getData debug result name=%1 present=%2 bytes=%3").arg(
        name,
        data.isEmpty() ? QStringLiteral("false") : QStringLiteral("true"),
        QString::number(data.toUtf8().size())
    ));
    return data;
#else
    auto secret = getSecret(name);
    if (!isSecretValid(secret)) {
        AuthLogger::log(QStringLiteral("SecretsHandler: getData result name=%1 valid=false").arg(name));
        return QString();
    }

    const auto data = QString::fromUtf8(secret.data());
    AuthLogger::log(QStringLiteral("SecretsHandler: getData result name=%1 valid=true present=%2 bytes=%3").arg(
        name,
        data.isEmpty() ? QStringLiteral("false") : QStringLiteral("true"),
        QString::number(secret.data().size())
    ));
    return data;
#endif
}

bool SecretsHandler::createCollection()
{
    AuthLogger::log(QStringLiteral("SecretsHandler: createCollection requested name=%1").arg(collectionName));
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

    AuthLogger::log(QStringLiteral("SecretsHandler: createCollection result success=%1 collectionPresent=%2").arg(
        success ? QStringLiteral("true") : QStringLiteral("false"),
        hasBitsailorCollection ? QStringLiteral("true") : QStringLiteral("false")
    ));
    return success;
}

Secret::Identifier SecretsHandler::toIdentifier(const QString &name)
{
    return Secret::Identifier(name, collectionName, SecretManager::DefaultEncryptedStoragePluginName);
}
