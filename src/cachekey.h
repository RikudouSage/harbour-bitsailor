#ifndef CACHEKEY_H
#define CACHEKEY_H

#include <QObject>
#include <QString>

class CacheKey : public QObject
{
    Q_OBJECT
    Q_PROPERTY(QString Items MEMBER items CONSTANT)
    Q_PROPERTY(QString LastUpdated MEMBER lastUpdated CONSTANT)
    Q_PROPERTY(QString HasLocalInstallation MEMBER hasLocalInstallation CONSTANT)
    Q_PROPERTY(QString GenerateUppercase MEMBER generateUppercase CONSTANT)
    Q_PROPERTY(QString GenerateLowercase MEMBER generateLowercase CONSTANT)
    Q_PROPERTY(QString GenerateNumbers MEMBER generateNumbers CONSTANT)
    Q_PROPERTY(QString GenerateSpecial MEMBER generateSpecial CONSTANT)
    Q_PROPERTY(QString GenerateLength MEMBER generateLength CONSTANT)
    Q_PROPERTY(QString GenerateAvoidAmbiguous MEMBER generateAvoidAmbiguous CONSTANT)
    Q_PROPERTY(QString GenerateMinimumNumbers MEMBER generateMinimumNumbers CONSTANT)
    Q_PROPERTY(QString GenerateMinimumSpecial MEMBER generateMinimumSpecial CONSTANT)
public:
    explicit CacheKey(QObject *parent = nullptr);

private:
    const QString items = "items";
    const QString lastUpdated = "lastUpdated";
    const QString hasLocalInstallation = "hasLocalInstallation";
    const QString generateUppercase = "generate_uppercase";
    const QString generateLowercase = "generate_lowercase";
    const QString generateNumbers = "generate_numbers";
    const QString generateSpecial = "generate_special";
    const QString generateLength = "generate_length";
    const QString generateAvoidAmbiguous = "generate_ambiguous";
    const QString generateMinimumNumbers = "generate_min_numbers";
    const QString generateMinimumSpecial = "generate_min_special";
};

#endif // CACHEKEY_H
