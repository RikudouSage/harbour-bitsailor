#ifndef UUID_H
#define UUID_H

#include <QUuid>
#include <QString>

QUuid generateUuid();
QString uuidToString(const QUuid &uuid);
QUuid qUuidFromString(const QString &uuid);

#endif // UUID_H
