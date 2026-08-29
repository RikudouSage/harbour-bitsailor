#include "bitwardeniteminput.h"

#include <cstring>

#include <QDateTime>
#include <QJsonValue>

#include "uuid.h"

namespace {

char *jsonStringOrNull(const QJsonObject &object, const QString &key, QByteArray *storage)
{
    const auto value = object.value(key);
    if (value.isUndefined() || value.isNull()) {
        return nullptr;
    }

    *storage = value.toString().toUtf8();
    return storage->data();
}

bool *jsonBoolOrNull(const QJsonObject &object, const QString &key, bool *storage)
{
    const auto value = object.value(key);
    if (value.isUndefined() || value.isNull()) {
        return nullptr;
    }

    *storage = value.toBool();
    return storage;
}

int64_t jsonDateOrZero(const QJsonObject &object, const QString &key)
{
    const auto value = object.value(key);
    if (value.isUndefined() || value.isNull()) {
        return 0;
    }
    if (value.isDouble()) {
        return static_cast<int64_t>(value.toDouble());
    }

    const auto date = QDateTime::fromString(value.toString(), Qt::ISODate);
    return date.isValid() ? date.toMSecsSinceEpoch() : 0;
}

int64_t *jsonDateOrNull(const QJsonObject &object, const QString &key, int64_t *storage)
{
    const auto value = object.value(key);
    if (value.isUndefined() || value.isNull()) {
        return nullptr;
    }

    *storage = jsonDateOrZero(object, key);
    return storage;
}

UUID uuidFromJson(const QJsonObject &object, const QString &key)
{
    const auto value = object.value(key);
    if (value.isUndefined() || value.isNull()) {
        return {};
    }

    const auto uuid = qUuidFromString(value.toString());
    const auto raw = uuid.toRfc4122();
    UUID out = {};
    std::memcpy(out.bytes, raw.constData(), 16);
    return out;
}

}

BitwardenItemInput::BitwardenItemInput(const UUID &id, const QJsonObject &object)
{
    item.id = id;
    item.type = static_cast<BitwardenItemType>(object.value("type").toInt());
    item.organizationUseTotp = jsonBoolOrNull(object, "organizationUseTotp", &organizationUseTotpValue);
    item.revisionDate = jsonDateOrZero(object, "revisionDate");
    item.deletedDate = jsonDateOrNull(object, "deletedDate", &deletedDateValue);
    item.favorite = object.value("favorite").toBool(false);
    item.organizationId = uuidFromJson(object, "organizationId");
    item.key = jsonStringOrNull(object, "key", &key);
    fillPermissions(object.value("permissions").toObject());
    item.edit = object.value("edit").toBool(false);
    item.archivedDate = jsonDateOrNull(object, "archivedDate", &archivedDateValue);
    item.folderId = uuidFromJson(object, "folderId");
    item.viewPassword = object.value("viewPassword").toBool(false);
    item.creationDate = jsonDateOrZero(object, "creationDate");
    item.reprompt = object.value("reprompt").toBool(false);

    name = object.value("name").toString().toUtf8();
    item.name = name.data();
    item.notes = jsonStringOrNull(object, "notes", &notes);
    fillCollectionIds(object.value("collectionIds").toArray());
    fillFields(object.value("fields").toArray());
    item.decryptionError = jsonStringOrNull(object, "decryptionError", &decryptionError);

    switch (item.type) {
    case BitwardenItemTypeLogin:
        fillLogin(object.value("login").toObject());
        item.login = &login;
        break;
    case BitwardenItemTypeSecureNote:
        fillSecureNote(object.value("secureNote").toObject());
        item.secureNote = &secureNote;
        break;
    case BitwardenItemTypeCard:
        fillCard(object.value("card").toObject());
        item.card = &card;
        break;
    case BitwardenItemTypeIdentity:
        fillIdentity(object.value("identity").toObject());
        item.identity = &identity;
        break;
    case BitwardenItemTypeSshKey:
        fillSshKey(object.value("sshKey").toObject());
        item.sshKey = &sshKey;
        break;
    default:
        break;
    }
}

void BitwardenItemInput::fillPermissions(const QJsonObject &object)
{
    if (object.isEmpty()) {
        return;
    }

    permissions.canDelete = object.value("delete").toBool(false);
    permissions.canRestore = object.value("restore").toBool(false);
    item.permissions = &permissions;
}

void BitwardenItemInput::fillCollectionIds(const QJsonArray &array)
{
    collectionIds.reserve(static_cast<size_t>(array.size()));
    for (const auto &collectionIdValue : array) {
        const auto collectionId = collectionIdValue.toString();
        if (collectionId.isEmpty()) {
            continue;
        }

        const auto uuid = qUuidFromString(collectionId);
        const auto raw = uuid.toRfc4122();
        UUID out = {};
        std::memcpy(out.bytes, raw.constData(), 16);
        collectionIds.push_back(out);
    }

    if (!collectionIds.empty()) {
        item.collectionIds.items = collectionIds.data();
        item.collectionIds.len = collectionIds.size();
    }
}

void BitwardenItemInput::fillFields(const QJsonArray &array)
{
    fieldNames.reserve(static_cast<size_t>(array.size()));
    fieldValues.reserve(static_cast<size_t>(array.size()));
    fieldLinkedIds.reserve(static_cast<size_t>(array.size()));
    fields.reserve(static_cast<size_t>(array.size()));

    for (const auto &fieldValue : array) {
        const auto fieldObject = fieldValue.toObject();
        BitwardenItemField field = {};
        field.type = static_cast<BitwardenFieldType>(fieldObject.value("type").toInt());

        fieldNames.push_back(fieldObject.value("name").toString().toUtf8());
        field.name = fieldNames.back().data();

        const auto value = fieldObject.value("value");
        if (!value.isUndefined() && !value.isNull()) {
            fieldValues.push_back(value.toString().toUtf8());
            field.value = fieldValues.back().data();
        }

        const auto linkedId = fieldObject.value("linkedId");
        if (!linkedId.isUndefined() && !linkedId.isNull()) {
            fieldLinkedIds.push_back(linkedId.toInt());
            field.linkedId = &fieldLinkedIds.back();
        }

        fields.push_back(field);
    }

    if (!fields.empty()) {
        item.fields.items = fields.data();
        item.fields.len = fields.size();
    }
}

void BitwardenItemInput::fillLogin(const QJsonObject &object)
{
    login.uri = jsonStringOrNull(object, "uri", &loginUriValue);
    login.username = jsonStringOrNull(object, "username", &loginUsername);
    login.password = jsonStringOrNull(object, "password", &loginPassword);
    login.passwordRevisionDate = jsonDateOrNull(object, "passwordRevisionDate", &loginPasswordRevisionDateValue);
    login.totp = jsonStringOrNull(object, "totp", &loginTotp);

    const auto uris = object.value("uris").toArray();
    loginUriValues.reserve(static_cast<size_t>(uris.size()));
    loginUriChecksums.reserve(static_cast<size_t>(uris.size()));
    loginUris.reserve(static_cast<size_t>(uris.size()));
    for (const auto &uriValue : uris) {
        const auto uriObject = uriValue.toObject();
        const auto uri = uriObject.value("uri").toString();
        if (uri.isEmpty()) {
            continue;
        }

        loginUriValues.push_back(uri.toUtf8());
        loginUriChecksums.push_back(QByteArray());
        BitwardenItemLoginUri outUri = {};
        outUri.uri = loginUriValues.back().data();
        outUri.uriChecksum = jsonStringOrNull(uriObject, "uriChecksum", &loginUriChecksums.back());
        outUri.match = static_cast<BitwardenUriMatchType>(uriObject.value("match").toInt());
        loginUris.push_back(outUri);
    }

    if (!loginUris.empty()) {
        login.uris.items = loginUris.data();
        login.uris.len = loginUris.size();
    }
}

void BitwardenItemInput::fillSecureNote(const QJsonObject &object)
{
    secureNote.type = object.value("type").toInt(0);
}

void BitwardenItemInput::fillCard(const QJsonObject &object)
{
    card.cardholderName = jsonStringOrNull(object, "cardholderName", &cardCardholderName);
    card.brand = jsonStringOrNull(object, "brand", &cardBrand);
    card.number = jsonStringOrNull(object, "number", &cardNumber);
    card.expirationMonth = jsonStringOrNull(object, "expMonth", &cardExpirationMonth);
    card.expirationYear = jsonStringOrNull(object, "expYear", &cardExpirationYear);
    card.code = jsonStringOrNull(object, "code", &cardCode);
}

void BitwardenItemInput::fillIdentity(const QJsonObject &object)
{
    identity.firstName = jsonStringOrNull(object, "firstName", &identityFirstName);
    identity.middleName = jsonStringOrNull(object, "middleName", &identityMiddleName);
    identity.lastName = jsonStringOrNull(object, "lastName", &identityLastName);
    identity.title = jsonStringOrNull(object, "title", &identityTitle);
    identity.passportNumber = jsonStringOrNull(object, "passportNumber", &identityPassportNumber);
    identity.username = jsonStringOrNull(object, "username", &identityUsername);
    identity.email = jsonStringOrNull(object, "email", &identityEmail);
    identity.phone = jsonStringOrNull(object, "phone", &identityPhone);
    identity.addressLine1 = jsonStringOrNull(object, "addressLine1", &identityAddressLine1);
    identity.addressLine2 = jsonStringOrNull(object, "addressLine2", &identityAddressLine2);
    identity.addressLine3 = jsonStringOrNull(object, "addressLine3", &identityAddressLine3);
    identity.city = jsonStringOrNull(object, "city", &identityCity);
    identity.state = jsonStringOrNull(object, "state", &identityState);
    identity.postalCode = jsonStringOrNull(object, "postalCode", &identityPostalCode);
    identity.country = jsonStringOrNull(object, "country", &identityCountry);
    identity.ssn = jsonStringOrNull(object, "ssn", &identitySsn);
    identity.company = jsonStringOrNull(object, "company", &identityCompany);
}

void BitwardenItemInput::fillSshKey(const QJsonObject &object)
{
    sshKey.privateKey = jsonStringOrNull(object, "privateKey", &sshKeyPrivateKey);
    sshKey.publicKey = jsonStringOrNull(object, "publicKey", &sshKeyPublicKey);
    sshKey.keyFingerprint = jsonStringOrNull(object, "keyFingerprint", &sshKeyKeyFingerprint);
}
