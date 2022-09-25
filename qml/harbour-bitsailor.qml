import QtQuick 2.0
import Sailfish.Silica 1.0
import "pages"

import cz.chrastecky.bitsailor 1.0

ApplicationWindow {
    initialPage: Component { SystemCheckerPage { } }
    cover: Qt.resolvedUrl("cover/CoverPage.qml")
    allowedOrientations: defaultAllowedOrientations

    BitwardenCli {
        id: cli
    }

    Component.onDestruction: {
        if (settings.lockOnClose) {
            cli.lockVaultInBackground();
        }
    }
}
