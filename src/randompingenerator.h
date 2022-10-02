#ifndef RANDOMPINGENERATOR_H
#define RANDOMPINGENERATOR_H

#include <QObject>

class RandomPinGenerator : public QObject
{
    Q_OBJECT
public:
    explicit RandomPinGenerator(QObject *parent = nullptr);
    Q_INVOKABLE QString generate();

signals:

};

#endif // RANDOMPINGENERATOR_H
