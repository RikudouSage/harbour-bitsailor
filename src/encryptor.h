#ifndef ENCRYPTOR_H
#define ENCRYPTOR_H

#include <QObject>

class Encryptor : public QObject
{
    Q_OBJECT
public:
    explicit Encryptor(QObject *parent = nullptr);
    QString encrypt(QString data, QString encryptionKey);
    QString decrypt(QString data, QString encryptionKey);
};

#endif // ENCRYPTOR_H
