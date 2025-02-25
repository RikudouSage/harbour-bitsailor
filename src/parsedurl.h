#ifndef PARSEDURL_H
#define PARSEDURL_H

#include <QObject>
#include <QUrl>

class ParsedUrl : public QObject
{
    Q_OBJECT
    Q_PROPERTY(QString scheme READ scheme CONSTANT)
    Q_PROPERTY(QString host READ host CONSTANT)
public:
    explicit ParsedUrl(QObject *parent = nullptr);
    explicit ParsedUrl(const QUrl &url, QObject *parent = nullptr);

    const QString scheme() const;
    const QString host() const;

    Q_INVOKABLE const QString query(const QString &paramName) const;

private:
    const QUrl mUrl;
};

#endif // PARSEDURL_H
