#ifndef BITWARDENAPI_H
#define BITWARDENAPI_H

#include <QObject>
#include <QJsonArray>
#include <QJsonObject>
#include <QNetworkAccessManager>
#include <QUrl>

#include <functional>

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
    Q_INVOKABLE void syncVault();

signals:
    void apiIsRunning();
    void apiNotRunning();
    void killingApiFailed();
    void killingApiSucceeded();
    void itemFetched(QJsonObject item);
    void itemFetchingFailed();
    void failedGettingSends();
    void sendsResolved(QJsonArray items);
    void vaultSynced();
    void vaultSyncFailed();

private:
    QNetworkAccessManager manager;
    RuntimeCache* runtimeCache = RuntimeCache::getInstance(this);
    SecretsHandler* secretsHandler = new SecretsHandler(this);

    const QString apiHost = "127.0.0.1";
    const int apiPort = 8087;
    const QString apiUrl = "http://" + apiHost + ":" + QString::number(apiPort);

private:
    enum Method {
        Get,
        Post,
    };

    void sendRequest(const QString &url, const std::function<void(QByteArray, int)> &callback);
    void sendRequest(const QUrl &url, const std::function<void(QByteArray, int)> &callback);
    void sendRequest(Method method, const QString &url, const std::function<void(QByteArray, int)> &callback);
    void sendRequest(Method method, const QUrl &url, const std::function<void(QByteArray, int)> &callback);
    void sendRequest(Method method, const QString &url, const QJsonDocument &data, const std::function<void(QByteArray, int)> &callback);
    void sendRequest(Method method, const QUrl &url, const QJsonDocument &data, const std::function<void(QByteArray, int)> &callback);
    void sendRequest(Method method, const QString &url, const QByteArray &data, const std::function<void(QByteArray, int)> &callback);
    void sendRequest(Method method, const QUrl &url, const QByteArray &data, const std::function<void(QByteArray, int)> &callback);
};

#endif // BITWARDENAPI_H
