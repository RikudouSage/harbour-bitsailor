#include "cli-api-common-parts.h"

#include <QDateTime>

QJsonObject createCommonCreateSendParts(const QString &name, const uint &deletionDate, const uint &maximumAccessCount, const QString &password, const bool &hideEmail, const QString &privateNotes)
{
    QJsonObject result;

    result["object"] = "send";
    result["name"] = name;
    result["disabled"] = false;

    if (deletionDate > 0) {
        QDateTime now = QDateTime::currentDateTimeUtc();
        auto targetDateTime = now.addSecs(deletionDate);
        result["deletionDate"] = targetDateTime.toString(Qt::DateFormat::ISODate);
    }

    if (maximumAccessCount > 0) {
        result["maxAccessCount"] = static_cast<const qint64>(maximumAccessCount);
    }
    if (!password.isNull() && !password.isEmpty()) {
        result["password"] = password;
    }
    result["hideEmail"] = hideEmail;

    if (!privateNotes.isNull() && !privateNotes.isEmpty()) {
        result["notes"] = privateNotes;
    }

    return result;
}
