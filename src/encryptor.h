#ifndef ENCRYPTOR_H
#define ENCRYPTOR_H

#include <QObject>

#include <Sailfish/Crypto/key.h>
#include <Sailfish/Crypto/cryptomanager.h>

using Sailfish::Crypto::Key;
using Sailfish::Crypto::CryptoManager;

class Encryptor : public QObject
{
    Q_OBJECT
public:
    explicit Encryptor(QObject *parent = nullptr);
    QString encrypt(QString data, QString encryptionKey);
    QString decrypt(QString data, QString encryptionKey);

private:
    Key getKey(const QString &encryptionKey);
    CryptoManager* cryptoManager = new CryptoManager(this);
};

#endif // ENCRYPTOR_H
