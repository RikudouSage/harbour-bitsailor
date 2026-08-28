#include "uuid.h"

QUuid generateUuid()
{
    return QUuid::createUuid();
}

QString uuidToString(const QUuid &uuid)
{
    auto uuidStr = uuid.toString();
    uuidStr = uuidStr.mid(1, uuidStr.size() - 2);

    return uuidStr;
}

QUuid qUuidFromString(const QString &uuid)
{
    QString copy = uuid;

    if (!copy.startsWith('{')) {
        copy.prepend('{');
    }

    if (!copy.endsWith('}')) {
        copy.append('}');
    }

    return copy;
}
