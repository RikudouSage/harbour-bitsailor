#include "urlparser.h"

UrlParser::UrlParser(QObject *parent) : QObject(parent)
{
}

ParsedUrl* UrlParser::parse(const QString &url)
{
    return new ParsedUrl(QUrl(url), this);
}
