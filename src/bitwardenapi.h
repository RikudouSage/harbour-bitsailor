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
private:
    enum Method {
        Get,
        Post,
    };
    // todo consolidate with CLI
    enum ItemType {
        NoType = -1,
        Login = 1,
        SecureNote = 2,
        Card = 3,
        Identity = 4,
    };

    // todo remove
    enum GetItemType {
        GetItems,
        GetLogins,
        GetCards,
        GetNotes,
        GetIdentities,
    };
public:
    explicit BitwardenApi(QObject *parent = nullptr);
    Q_INVOKABLE void getItem(const QString &id);
    Q_INVOKABLE void isRunning();
    Q_INVOKABLE void killApi();
    Q_INVOKABLE void getSends();
    Q_INVOKABLE void syncVault();
    Q_INVOKABLE void getItems();
    void getItems(GetItemType itemType);
    Q_INVOKABLE void getLogins();
    Q_INVOKABLE void getCards();
    Q_INVOKABLE void getNotes();
    Q_INVOKABLE void getIdentities();
    Q_INVOKABLE void getServerUrl();
    Q_INVOKABLE void checkVaultUnlocked();
    Q_INVOKABLE void generatePassword(bool lowercase, bool uppercase, bool numbers, bool special, bool avoidAmbiguous, int minimumNumbers, int minimumSpecial, int length);
    Q_INVOKABLE void generatePassphrase(uint wordsCount, bool capitalize, bool includeNumber, const QString &separator);
    Q_INVOKABLE void createFileSend(
            const QString &name,
            const QString &filePath,
            const uint &deletionDate,
            const uint &maximumAccessCount,
            const QString &password,
            const bool &hideEmail,
            const QString &privateNotes
    );
    Q_INVOKABLE void createTextSend(
            const QString &name,
            const QString &text,
            const bool &hideText,
            const uint &deletionDate,
            const uint &maximumAccessCount,
            const QString &password,
            const bool &hideEmail,
            const QString &privateNotes
    );
    // todo make this private if file Sends via api get supported
    Q_INVOKABLE void addTempSend(const QJsonObject &object);

signals:
    void isRunningResult(bool running);
    void apiNotRunning();
    void killingApiFailed();
    void killingApiSucceeded();
    void itemFetched(QJsonObject item);
    void itemFetchingFailed();
    void failedGettingSends();
    void sendsResolved(QJsonArray items);
    void vaultSynced();
    void vaultSyncFailed();
    void failedGettingItems();
    void itemsResolved(QJsonArray items);
    void serverUrlResolved(QString serverUrl);
    void serverUrlResolvingFailed();
    void vaultLockStatusResolved(bool unlocked);
    void passwordGenerated(QString password);
    void generatingPasswordFailed();
    void passphraseGenerated(const QString &passphrase);
    void generatingPassphraseFailed();
    void sendCreated(const QJsonObject &item);

private:
    QNetworkAccessManager manager;
    RuntimeCache* runtimeCache = RuntimeCache::getInstance(this);
    SecretsHandler* secretsHandler = new SecretsHandler(this);

    const QString apiHost = "127.0.0.1";
    const int apiPort = 8087;
    const QString apiUrl = "http://" + apiHost + ":" + QString::number(apiPort);

private:
    void sendRequest(const QString &url, const std::function<void(QByteArray, int)> &callback);
    void sendRequest(const QUrl &url, const std::function<void(QByteArray, int)> &callback);
    void sendRequest(Method method, const QString &url, const std::function<void(QByteArray, int)> &callback);
    void sendRequest(Method method, const QUrl &url, const std::function<void(QByteArray, int)> &callback);
    void sendRequest(Method method, const QString &url, const QJsonObject &data, const std::function<void(QByteArray, int)> &callback);
    void sendRequest(Method method, const QString &url, const QJsonDocument &data, const std::function<void(QByteArray, int)> &callback);
    void sendRequest(Method method, const QUrl &url, const QJsonDocument &data, const std::function<void(QByteArray, int)> &callback);
    void sendRequest(Method method, const QString &url, const QByteArray &data, const std::function<void(QByteArray, int)> &callback);
    void sendRequest(Method method, const QUrl &url, const QByteArray &data, const std::function<void(QByteArray, int)> &callback);

    const QJsonArray getTempSends();

    // todo remove
    void handleGetItems(const QString &rawJson, GetItemType getItemType = GetItems);
};

#endif // BITWARDENAPI_H
