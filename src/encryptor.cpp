#include "encryptor.h"

#include <QDebug>

#include <Sailfish/Crypto/keyderivationparameters.h>
#include <Sailfish/Crypto/generatekeyrequest.h>
#include <Sailfish/Crypto/generateinitializationvectorrequest.h>
#include <Sailfish/Crypto/result.h>
#include <Sailfish/Crypto/encryptrequest.h>
#include <Sailfish/Crypto/decryptrequest.h>

using Sailfish::Crypto::Key;
using Sailfish::Crypto::CryptoManager;
using Sailfish::Crypto::KeyDerivationParameters;
using Sailfish::Crypto::GenerateKeyRequest;
using Sailfish::Crypto::GenerateInitializationVectorRequest;
using Sailfish::Crypto::Result;
using Sailfish::Crypto::EncryptRequest;
using Sailfish::Crypto::DecryptRequest;

Encryptor::Encryptor(QObject *parent) : QObject(parent)
{

}

QString Encryptor::encrypt(QString data, QString encryptionKey)
{
    auto bytes = data.toUtf8();
    if (bytes.isEmpty()) {
        return data;
    }
    if (bytes.isNull()) {
        return "";
    }

    GenerateInitializationVectorRequest initVector;
    initVector.setManager(cryptoManager);
    initVector.setAlgorithm(CryptoManager::AlgorithmAes);
    initVector.setBlockMode(CryptoManager::BlockModeCbc);
    initVector.setCryptoPluginName(CryptoManager::DefaultCryptoStoragePluginName);
    initVector.setKeySize(256); // for AES the IV size is 16 bytes, independent of key size.
    initVector.startRequest();
    initVector.waitForFinished();

    if (initVector.result().code() != Result::Succeeded) {
        qWarning() << "Failed to generate initialization vector!";
        qWarning() << "Error:" << initVector.result().errorCode()
                               << initVector.result().errorMessage();
        return "";
    }

    EncryptRequest encrypt;
    encrypt.setManager(cryptoManager);
    encrypt.setData(bytes);
    encrypt.setInitializationVector(initVector.generatedInitializationVector());
    encrypt.setKey(getKey(encryptionKey));
    encrypt.setBlockMode(CryptoManager::BlockModeCbc);
    encrypt.setPadding(CryptoManager::EncryptionPaddingNone);
    encrypt.setCryptoPluginName(CryptoManager::DefaultCryptoStoragePluginName);
    encrypt.startRequest();
    encrypt.waitForFinished();

    if (encrypt.result().code() != Result::Succeeded) {
        qWarning() << "Failed to encrypt the data!";
        qWarning() << "Error:" << encrypt.result().errorCode()
                               << encrypt.result().errorMessage();
        return "";
    }

    return QByteArray("IV:") + encrypt.initializationVector().toBase64() + QByteArray("\n") + encrypt.ciphertext().toBase64();
}

QString Encryptor::decrypt(QString data, QString encryptionKey)
{
    auto encodedData = data.toUtf8();
    if (encodedData.isEmpty()) {
        return "";
    }

    auto chunks = encodedData.split('\n');
    if (chunks.size() != 2 || !chunks.first().startsWith("IV:")) {
        qWarning() << "Invalid encrypted data stored";
        return "";
    }

    auto iv = QByteArray::fromBase64(chunks.first().mid(3));
    auto rawData = QByteArray::fromBase64(chunks.last());

    DecryptRequest decrypt;
    decrypt.setManager(cryptoManager);
    decrypt.setData(rawData);
    decrypt.setInitializationVector(iv);
    decrypt.setKey(getKey(encryptionKey));
    decrypt.setPadding(CryptoManager::EncryptionPaddingNone);
    decrypt.setBlockMode(CryptoManager::BlockModeCbc);
    decrypt.setCryptoPluginName(CryptoManager::DefaultCryptoStoragePluginName);
    decrypt.startRequest();
    decrypt.waitForFinished();

    if (decrypt.result().code() != Result::Succeeded) {
        qWarning() << "Failed to decrypt the data!";
        qWarning() << "Error:" << decrypt.result().errorCode()
                               << decrypt.result().errorMessage();
        return "";
    }

    return decrypt.plaintext();
}

Key Encryptor::getKey(const QString &encryptionKey)
{
    Key keyTemplate;
    keyTemplate.setOrigin(Key::OriginDevice);
    keyTemplate.setAlgorithm(CryptoManager::AlgorithmAes);
    keyTemplate.setOperations(CryptoManager::OperationEncrypt | CryptoManager::OperationDecrypt);

    KeyDerivationParameters kdfParams;
    kdfParams.setKeyDerivationFunction(CryptoManager::KdfPkcs5Pbkdf2);
    kdfParams.setKeyDerivationMac(CryptoManager::MacHmac);
    kdfParams.setKeyDerivationDigestFunction(CryptoManager::DigestSha512);
    kdfParams.setIterations(16384);
    kdfParams.setOutputKeySize(256);
    kdfParams.setSalt(QByteArray("cz.chrastecky.bitsailor"));
    kdfParams.setInputData(encryptionKey.toUtf8());

    GenerateKeyRequest generateKey;
    generateKey.setManager(cryptoManager);
    generateKey.setKeyTemplate(keyTemplate);
    generateKey.setKeyDerivationParameters(kdfParams);
    generateKey.setCryptoPluginName(CryptoManager::DefaultCryptoStoragePluginName);
    generateKey.startRequest();
    generateKey.waitForFinished();
    if (generateKey.result().code() != Sailfish::Crypto::Result::Succeeded) {
        qWarning() << "Failed to generate symmetric key!";
        qWarning() << "Error:" << generateKey.result().errorCode()
                               << generateKey.result().errorMessage();
        return Key();
    }

    return generateKey.generatedKey();
}
