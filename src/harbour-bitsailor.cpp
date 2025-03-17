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

#include "systemchecker.h"
#include "bitwardencliinstaller.h"
#include "bitwardencli.h"
#include "secretshandler.h"
#include "appsettings.h"
#include "runtimecache.h"
#include "systemauthchecker.h"
#include "fileaccessor.h"
#include "randompingenerator.h"
#include "pathhelper.h"
#include "cachekey.h"
#include "otp/onetimepasswordgenerator.h"
#include "parsedurl.h"
#include "urlparser.h"
#include "bitwardenapi.h"

int main(int argc, char *argv[])
{
    QScopedPointer<QGuiApplication> app(SailfishApp::application(argc, argv));
    QScopedPointer<QQuickView> v(SailfishApp::createView());

    qmlRegisterType<SystemChecker>("cz.chrastecky.bitsailor", 1, 0, "SystemChecker");
    qmlRegisterType<BitwardenCliInstaller>("cz.chrastecky.bitsailor", 1, 0, "BitwardenInstaller");
    qmlRegisterType<BitwardenCli>("cz.chrastecky.bitsailor", 1, 0, "BitwardenCli");
    qmlRegisterType<SecretsHandler>("cz.chrastecky.bitsailor", 1, 0, "SecretsHandler");
    qmlRegisterType<SystemAuthChecker>("cz.chrastecky.bitsailor", 1, 0, "SystemAuthChecker");
    qmlRegisterType<FileAccessor>("cz.chrastecky.bitsailor", 1, 0, "FileAccessor");
    qmlRegisterType<RandomPinGenerator>("cz.chrastecky.bitsailor", 1, 0, "RandomPinGenerator");
    qmlRegisterType<OneTimePasswordGenerator>("cz.chrastecky.bitsailor", 1, 0, "OneTimePasswordGenerator");
    qmlRegisterType<ParsedUrl>("cz.chrastecky.bitasilor", 1, 0, "ParsedUrl");
    qmlRegisterType<BitwardenApi>("cz.chrastecky.bitsailor", 1, 0, "BitwardenApi");
    qmlRegisterSingletonType<CacheKey>("cz.chrastecky.bitsailor", 1, 0, "CacheKey", [](QQmlEngine* engine, QJSEngine* scriptEngine) -> QObject* {
        Q_UNUSED(engine);
        Q_UNUSED(scriptEngine);

        return new CacheKey();
    });

    v->rootContext()->setContextProperty("settings", new AppSettings(app.data()));
    v->rootContext()->setContextProperty("runtimeCache", RuntimeCache::getInstance(app.data()));
    v->rootContext()->setContextProperty("privateBinPath", getPrivateBinDirPath());
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
