#ifndef BITWARDENAPI_H
#define BITWARDENAPI_H

#include <QObject>
#include <QJsonArray>
#include <QJsonObject>
#include <QNetworkAccessManager>

#include "runtimecache.h"
#include "secretshandler.h"

class BitwardenApi : public QObject
{
    Q_OBJECT
public:
    explicit BitwardenApi(QObject *parent = nullptr);
    Q_INVOKABLE void getItem(const QString &id);
    Q_INVOKABLE void isRunning();
    Q_INVOKABLE void killApi();
    Q_INVOKABLE void getSends();

signals:
    void apiIsRunning();
    void apiNotRunning();
    void killingApiFailed();
    void killingApiSucceeded();
    void itemFetched(QJsonObject item);
    void itemFetchingFailed();
    void failedGettingSends();
    void sendsResolved(QJsonArray items);

private:
    QNetworkAccessManager manager;
    RuntimeCache* runtimeCache = RuntimeCache::getInstance(this);
    SecretsHandler* secretsHandler = new SecretsHandler(this);

    const QString apiUrl = "http://127.0.0.1:8087";
};

#endif // BITWARDENAPI_H
