#ifdef QT_QML_DEBUG
#include <QtQuick>
#endif

#include <QQuickView>
#include <QScopedPointer>
#include <QGuiApplication>
#include <QtQml>
#include <QQmlEngine>
#include <QDBusConnection>

#include <sailfishapp.h>

#include "secretshandler.h"
#include "authlogger.h"
#include "appsettings.h"
#include "runtimecache.h"
#include "systemauthchecker.h"
#include "fileaccessor.h"
#include "randompingenerator.h"
#include "cachekey.h"
#include "otp/onetimepasswordgenerator.h"
#include "parsedurl.h"
#include "urlparser.h"
#include "bitsailorcore.h"

int main(int argc, char *argv[])
{
    QScopedPointer<QGuiApplication> app(SailfishApp::application(argc, argv));
    QScopedPointer<QQuickView> v(SailfishApp::createView());

    AuthLogger::log(QStringLiteral("application starting executable=%1 authLog=%2").arg(
        QCoreApplication::applicationFilePath(),
        AuthLogger::logFilePath()
    ));

    auto secrets = new SecretsHandler(app.data());
    auto settings = new AppSettings(app.data());
    auto core = new BitSailorCore(settings, secrets, app.data());

    qmlRegisterType<SystemAuthChecker>("cz.chrastecky.bitsailor", 1, 0, "SystemAuthChecker");
    qmlRegisterType<FileAccessor>("cz.chrastecky.bitsailor", 1, 0, "FileAccessor");
    qmlRegisterType<RandomPinGenerator>("cz.chrastecky.bitsailor", 1, 0, "RandomPinGenerator");
    qmlRegisterType<OneTimePasswordGenerator>("cz.chrastecky.bitsailor", 1, 0, "OneTimePasswordGenerator");
    qmlRegisterType<ParsedUrl>("cz.chrastecky.bitasilor", 1, 0, "ParsedUrl");
    qmlRegisterSingletonType<CacheKey>("cz.chrastecky.bitsailor", 1, 0, "CacheKey", [](QQmlEngine* engine, QJSEngine* scriptEngine) -> QObject* {
        Q_UNUSED(engine);
        Q_UNUSED(scriptEngine);

        return new CacheKey();
    });
    qmlRegisterSingletonType<BitSailorCore>("cz.chrastecky.bitsailor", 1, 0, "BitSailorCore", [](QQmlEngine* engine, QJSEngine* scriptEngine) -> QObject* {
        Q_UNUSED(engine);
        Q_UNUSED(scriptEngine);

        return new BitSailorCore(QCoreApplication::instance());
    });

    v->rootContext()->setContextProperty("settings", settings);
    v->rootContext()->setContextProperty("secrets", secrets);
    v->rootContext()->setContextProperty("core", core);
    v->rootContext()->setContextProperty("runtimeCache", RuntimeCache::getInstance(app.data()));
    v->rootContext()->setContextProperty("urlParser", new UrlParser(app.data()));

#ifdef QT_DEBUG
    v->rootContext()->setContextProperty("isDebug", true);
#else
    v->rootContext()->setContextProperty("isDebug", false);
#endif

    v->setSource(SailfishApp::pathToMainQml());
    QDBusConnection::sessionBus().registerService("cz.chrastecky.bitsailor");
    v->show();

    return app->exec();
}
