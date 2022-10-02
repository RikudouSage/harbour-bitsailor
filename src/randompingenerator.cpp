#include "randompingenerator.h"

#include <sys/random.h>
#include <QFile>
#include <iostream>
#include <cstring>

RandomPinGenerator::RandomPinGenerator(QObject *parent) : QObject(parent)
{

}

QString RandomPinGenerator::generate()
{
    unsigned char randomBytes[32];
    getrandom((void*) &randomBytes[0], 32, GRND_RANDOM);

    long long result;
    std::memcpy(&result, randomBytes, sizeof (long long));

    return QString::number(abs(result));
}
