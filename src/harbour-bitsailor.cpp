#ifdef QT_QML_DEBUG
#include <QtQuick>
#endif

#include <QQuickView>
#include <QScopedPointer>
#include <QGuiApplication>
#include <QtQml>
#include <QQmlEngine>

#include <sailfishapp.h>

#include "systemchecker.h"
#include "bitwardencliinstaller.h"
#include "bitwardencli.h"
#include "secretshandler.h"
#include "appsettings.h"
#include "runtimecache.h"
#include "systemauthchecker.h"

int main(int argc, char *argv[])
{
    QScopedPointer<QGuiApplication> app(SailfishApp::application(argc, argv));
    QScopedPointer<QQuickView> v(SailfishApp::createView());

    qmlRegisterType<SystemChecker>("cz.chrastecky.bitsailor", 1, 0, "SystemChecker");
    qmlRegisterType<BitwardenCliInstaller>("cz.chrastecky.bitsailor", 1, 0, "BitwardenInstaller");
    qmlRegisterType<BitwardenCli>("cz.chrastecky.bitsailor", 1, 0, "BitwardenCli");
    qmlRegisterType<SecretsHandler>("cz.chrastecky.bitsailor", 1, 0, "SecretsHandler");
    qmlRegisterType<SystemAuthChecker>("cz.chrastecky.bitsailor", 1, 0, "SystemAuthChecker");

    v->rootContext()->setContextProperty("settings", new AppSettings(app.data()));
    v->rootContext()->setContextProperty("runtimeCache", RuntimeCache::getInstance(app.data()));

#ifdef QT_DEBUG
    v->rootContext()->setContextProperty("isDebug", true);
#else
    v->rootContext()->setContextProperty("isDebug", false);
#endif

    v->setSource(SailfishApp::pathToMainQml());
    v->show();

    return app->exec();
}
