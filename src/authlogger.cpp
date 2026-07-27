#include "authlogger.h"

#include <QCoreApplication>
#include <QDateTime>
#include <QDir>
#include <QFile>
#include <QMutex>
#include <QStandardPaths>
#include <QTextStream>
#include <QThread>

namespace {

QMutex logMutex;
constexpr qint64 maxLogSize = 512 * 1024;

QString logDirPath()
{
    auto path = QStandardPaths::writableLocation(QStandardPaths::AppDataLocation);
    if (path.isEmpty()) {
        path = QDir::homePath() + QStringLiteral("/.local/share/harbour-bitsailor");
    }

    return path;
}

QString sanitizedMessage(QString message)
{
    message.replace(QLatin1Char('\n'), QLatin1Char(' '));
    message.replace(QLatin1Char('\r'), QLatin1Char(' '));
    return message;
}

void rotateIfNeeded(const QString &path)
{
    QFile file(path);
    if (!file.exists() || file.size() <= maxLogSize) {
        return;
    }

    QFile::remove(path + QStringLiteral(".1"));
    file.rename(path + QStringLiteral(".1"));
}

}

QString AuthLogger::logFilePath()
{
    return logDirPath() + QStringLiteral("/auth.log");
}

void AuthLogger::log(const QString &message)
{
    QMutexLocker locker(&logMutex);

    const auto dirPath = logDirPath();
    QDir dir(dirPath);
    if (!dir.exists() && !dir.mkpath(QStringLiteral("."))) {
        return;
    }

    const auto path = logFilePath();
    rotateIfNeeded(path);

    QFile file(path);
    if (!file.open(QIODevice::WriteOnly | QIODevice::Append | QIODevice::Text)) {
        return;
    }

    QTextStream out(&file);
    out << QDateTime::currentDateTimeUtc().toString(QStringLiteral("yyyy-MM-dd'T'HH:mm:ss.zzz'Z'"))
        << " pid=" << QCoreApplication::applicationPid()
        << " thread=" << reinterpret_cast<quintptr>(QThread::currentThreadId())
        << " " << sanitizedMessage(message)
        << '\n';
}
