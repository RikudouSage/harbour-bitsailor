#ifndef URLPARSER_H
#define URLPARSER_H

#include <QObject>

#include "parsedurl.h"

class UrlParser : public QObject
{
    Q_OBJECT
public:
    explicit UrlParser(QObject *parent = nullptr);

public slots:
    ParsedUrl* parse(const QString &url);
};

#endif // URLPARSER_H
