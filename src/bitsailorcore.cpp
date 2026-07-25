#include "bitsailorcore.h"

#include <cstring>
#include <QDebug>
#include <QJsonDocument>

#include "consts.h"

BitSailorCore::BitSailorCore(AppSettings *settings, SecretsHandler *secrets, QObject *parent) : QObject(parent)
{
    if (settings->deviceUuid() == "") {
        settings->setDeviceUuid(uuidToString(generateUuid()));
    }

    if (BitwardenNewContext(&ctx) != BitwardenSuccess) {
        valid = false;
        qWarning() << "Failed initializing context: " << getLastError();
    }

    auto baseUrl = settings->baseUrl().toUtf8();
    if (baseUrl == defaultVaultUrl) {
        baseUrl.clear();
    }

    auto uuid = uuidFromString(settings->deviceUuid());
    if (BitwardenNewClient(&client, NewClientOptions {
        .baseUrl = baseUrl.constData(),
        .deviceId = &uuid,
    }) != BitwardenSuccess) {
        valid = false;
        qWarning() << "Failed initializing client: " << getLastError();
    }

    if (secrets->hasSessionJson()) {
        auto json = secrets->getSessionJson();
        if (json.isEmpty()) {
            qWarning() << "The session json is empty";
        }
        auto jsonStr = QJsonDocument(json).toJson();
        if (BitwardenImportSession(nullptr, jsonStr.data(), &session) != BitwardenSuccess) {
            qWarning() << "Failed importing session: " << getLastError();
        }
    }
}

BitSailorCore::~BitSailorCore()
{
    if (ctx != 0 && BitwardenCloseHandle(ctx) != BitwardenSuccess) {
        qWarning() << "Failed closing context: " << getLastError();
    }
    if (client != 0 && BitwardenCloseHandle(client) != BitwardenSuccess) {
        qWarning() << "Failed closing client: " << getLastError();
    }
    if (session != 0 && BitwardenCloseHandle(session) != BitwardenSuccess) {
        qWarning() << "Failed closing session: " << getLastError();
    }
}

const QString BitSailorCore::getLastError() const
{
    std::size_t len = BitwardenGetLastError(nullptr, 0);

    if (len < 1) {
        return QString();
    }

    QByteArray buf(static_cast<int>(len), Qt::Uninitialized);
    BitwardenGetLastError(buf.data(), static_cast<std::size_t>(buf.size()));

    return QString::fromUtf8(buf.constData());
}

QUuid BitSailorCore::generateUuid() const
{
    return QUuid::createUuid();
}

QString BitSailorCore::uuidToString(const QUuid &uuid) const
{
    auto uuidStr = uuid.toString();
    uuidStr = uuidStr.mid(1, uuidStr.size() - 2);

    return uuidStr;
}

QString BitSailorCore::uuidToString(const UUID &uuid) const
{
    return uuidToString(uuidToQUuid(uuid));
}

QUuid BitSailorCore::qUuidFromString(const QString &uuid) const
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

UUID BitSailorCore::uuidFromString(const QString &uuid) const
{
    return uuidToCoreUuid(qUuidFromString(uuid));
}

UUID BitSailorCore::uuidToCoreUuid(const QUuid &uuid) const
{
    QByteArray raw = uuid.toRfc4122();
    UUID cUuid;
    std::memcpy(cUuid.bytes, raw.constData(), 16);

    return cUuid;
}

QUuid BitSailorCore::uuidToQUuid(const UUID &uuid) const
{
    QByteArray raw(reinterpret_cast<const char *>(uuid.bytes), 16);
    return QUuid::fromRfc4122(raw);
}
