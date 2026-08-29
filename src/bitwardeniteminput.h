#ifndef BITWARDENITEMINPUT_H
#define BITWARDENITEMINPUT_H

#include <cstdint>
#include <vector>

#include <QByteArray>
#include <QJsonArray>
#include <QJsonObject>

#include "core/bw_item.h"

struct BitwardenItemInput
{
    BitwardenItem item = {};

    BitwardenItemInput(const UUID &id, const QJsonObject &object);

private:
    QByteArray name;
    QByteArray notes;
    std::vector<QByteArray> fieldNames;
    std::vector<QByteArray> fieldValues;
    std::vector<int> fieldLinkedIds;
    std::vector<BitwardenItemField> fields;
    bool organizationUseTotpValue = false;
    int64_t deletedDateValue = 0;
    QByteArray key;
    BitwardenItemPermissions permissions = {};
    std::vector<UUID> collectionIds;
    int64_t archivedDateValue = 0;
    QByteArray loginUsername;
    QByteArray loginPassword;
    QByteArray loginTotp;
    int64_t loginPasswordRevisionDateValue = 0;
    QByteArray loginUriValue;
    std::vector<QByteArray> loginUriValues;
    std::vector<QByteArray> loginUriChecksums;
    std::vector<BitwardenItemLoginUri> loginUris;
    QByteArray cardCardholderName;
    QByteArray cardBrand;
    QByteArray cardNumber;
    QByteArray cardExpirationMonth;
    QByteArray cardExpirationYear;
    QByteArray cardCode;
    QByteArray identityFirstName;
    QByteArray identityMiddleName;
    QByteArray identityLastName;
    QByteArray identityTitle;
    QByteArray identityPassportNumber;
    QByteArray identityUsername;
    QByteArray identityEmail;
    QByteArray identityPhone;
    QByteArray identityAddressLine1;
    QByteArray identityAddressLine2;
    QByteArray identityAddressLine3;
    QByteArray identityCity;
    QByteArray identityState;
    QByteArray identityPostalCode;
    QByteArray identityCountry;
    QByteArray identitySsn;
    QByteArray identityCompany;
    QByteArray sshKeyPrivateKey;
    QByteArray sshKeyPublicKey;
    QByteArray sshKeyKeyFingerprint;
    QByteArray decryptionError;
    BitwardenItemLogin login = {};
    BitwardenItemCard card = {};
    BitwardenItemSecureNote secureNote = {};
    BitwardenItemIdentity identity = {};
    BitwardenItemSshKey sshKey = {};
    void fillPermissions(const QJsonObject &object);
    void fillCollectionIds(const QJsonArray &array);
    void fillFields(const QJsonArray &array);
    void fillLogin(const QJsonObject &object);
    void fillSecureNote(const QJsonObject &object);
    void fillCard(const QJsonObject &object);
    void fillIdentity(const QJsonObject &object);
    void fillSshKey(const QJsonObject &object);
};

#endif // BITWARDENITEMINPUT_H
