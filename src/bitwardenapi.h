#ifndef BITWARDENAPI_H
#define BITWARDENAPI_H

#include <QObject>
#include <QJsonArray>
#include <QJsonObject>
#include <QNetworkAccessManager>

#include "runtimecache.h"

class BitwardenApi : public QObject
{
    Q_OBJECT
public:
    explicit BitwardenApi(QObject *parent = nullptr);
    Q_INVOKABLE void getItem(const QString &id);

signals:
    void apiNotRunning();
    void itemFetched(QJsonObject item);
    void itemFetchingFailed();

private:
    QNetworkAccessManager manager;
    RuntimeCache* runtimeCache = RuntimeCache::getInstance(this);
};

#endif // BITWARDENAPI_H
