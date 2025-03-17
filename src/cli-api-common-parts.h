#ifndef CLIAPICOMMONPARTS_H
#define CLIAPICOMMONPARTS_H

#include <QJsonObject>

enum SendType {
    SendTypeText = 0,
    SendTypeFile = 1,
};

QJsonObject createCommonCreateSendParts(const QString &name, const uint &deletionDate, const uint &maximumAccessCount, const QString &password, const bool &hideEmail, const QString &privateNotes);

#endif // CLIAPICOMMONPARTS_H
