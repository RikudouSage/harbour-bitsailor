#include "bitwardenapi.h"

#include <QNetworkAccessManager>
#include <QNetworkRequest>
#include <QNetworkReply>
#include <QJsonDocument>
#include <QUrl>
#include <QDebug>

BitwardenApi::BitwardenApi(QObject *parent) : QObject(parent)
{

}

void BitwardenApi::getItem(const QString &id)
{
    QUrl url("http://127.0.0.1:8087/object/item/" + id);
    QNetworkRequest request(url);
    request.setRawHeader("Authorization", secretsHandler->getServerApiKey().toUtf8());

    auto reply = manager.get(request);

    connect(reply, &QNetworkReply::finished, [=]() {
        reply->deleteLater();
        if (reply->error() == QNetworkReply::ConnectionRefusedError) {
            emit apiNotRunning();
            return;
        }
        if (reply->error() == QNetworkReply::NoError) {
            auto body = reply->readAll();
            auto document = QJsonDocument::fromJson(body).object()["data"].toObject();

            emit itemFetched(document);
        } else {
            qDebug() << reply->readAll();
            emit itemFetchingFailed();
        }
    });
}

