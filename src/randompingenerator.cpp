#include "randompingenerator.h"

#include <sys/random.h>
#include <QFile>
#include <iostream>
#include <cstring>
#include "random-helper.h"

RandomPinGenerator::RandomPinGenerator(QObject *parent) : QObject(parent)
{

}

QString RandomPinGenerator::generate()
{
    return generateRandomPin(4);
}
