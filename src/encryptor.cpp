#include "encryptor.h"

Encryptor::Encryptor(QObject *parent) : QObject(parent)
{

}

QString Encryptor::encrypt(QString data, QString encryptionKey)
{
    Q_UNUSED(encryptionKey);
    return data; // todo
}

QString Encryptor::decrypt(QString data, QString encryptionKey)
{
    Q_UNUSED(encryptionKey);
    return data; // todo
}
