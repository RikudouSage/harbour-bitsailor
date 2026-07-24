#ifndef BITSAILORCORE_H
#define BITSAILORCORE_H

#include <QObject>
#include <QUuid>

#include "appsettings.h"
#include "core/libbw.h"

class BitSailorCore : public QObject
{
    Q_OBJECT
public:
    explicit BitSailorCore(AppSettings *settings, QObject *parent = nullptr);
    ~BitSailorCore();

private:
    const QString getLastError() const;
    QUuid generateUuid() const;

    QString uuidToString(const QUuid &uuid) const;
    QString uuidToString(const UUID &uuid) const;
    QUuid qUuidFromString(const QString &uuid) const;
    UUID uuidFromString(const QString &uuid) const;
    UUID uuidToCoreUuid(const QUuid &uuid) const;
    QUuid uuidToQUuid(const UUID &uuid) const;

private:
    bool valid = true;

    ContextHandle ctx = 0;
    ClientHandle client = 0;
};

#endif // BITSAILORCORE_H
