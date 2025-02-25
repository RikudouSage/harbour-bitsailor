#include "parsedurl.h"

#include <QUrlQuery>

ParsedUrl::ParsedUrl(QObject *parent): QObject(parent)
{

}

ParsedUrl::ParsedUrl(const QUrl &url, QObject *parent): QObject(parent), mUrl(url)
{
}

const QString ParsedUrl::scheme() const
{
    return mUrl.scheme();
}

const QString ParsedUrl::host() const
{
    return mUrl.host();
}

const QString ParsedUrl::query(const QString &paramName) const
{
    if (!mUrl.hasQuery()) {
        return QString();
    }

    const QUrlQuery query(mUrl);
    if (!query.hasQueryItem(paramName)) {
        return QString();
    }

    return query.queryItemValue(paramName);
}
