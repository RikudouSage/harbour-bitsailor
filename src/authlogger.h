#ifndef AUTHLOGGER_H
#define AUTHLOGGER_H

#include <QString>

class AuthLogger
{
public:
    static void log(const QString &message);
    static QString logFilePath();
};

#endif // AUTHLOGGER_H
