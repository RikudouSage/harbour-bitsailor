#ifdef QT_QML_DEBUG
#include <QtQuick>
#endif

#include <sailfishapp.h>

#include "systemchecker.h"
#include "bitwardencliinstaller.h"
#include "bitwardencli.h"
#include "secretshandler.h"
#include "appsettings.h"

int main(int argc, char *argv[])
{
    QScopedPointer<QGuiApplication> app(SailfishApp::application(argc, argv));
    QScopedPointer<QQuickView> v(SailfishApp::createView());
    qmlRegisterType<SystemChecker>("cz.chrastecky.bitsailor", 1, 0, "SystemChecker");
    qmlRegisterType<BitwardenCliInstaller>("cz.chrastecky.bitsailor", 1, 0, "BitwardenInstaller");
    qmlRegisterType<BitwardenCli>("cz.chrastecky.bitsailor", 1, 0, "BitwardenCli");
    qmlRegisterType<SecretsHandler>("cz.chrastecky.bitsailor", 1, 0, "SecretsHandler");
    v->rootContext()->setContextProperty("settings", new AppSettings(app.data()));
    v->setSource(SailfishApp::pathToMainQml());
    v->show();

    return app->exec();
}
