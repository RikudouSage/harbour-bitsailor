import QtQuick 2.0
import Sailfish.Silica 1.0

import "pages"
import "components" as Components
import "helpers.js" as Helpers

import cz.chrastecky.bitsailor 1.0

ApplicationWindow {
    id: app
    property alias toaster: toasterElement

    initialPage: Component { SystemCheckerPage { } }
    cover: Qt.resolvedUrl("cover/CoverPage.qml")
    allowedOrientations: defaultAllowedOrientations

    BitwardenCli {
        id: cli
    }

    SecretsHandler {
        id: secrets
    }

    Component.onCompleted: {
        if (settings.persistentItemCache) {
            runtimeCache.set('items', runtimeCache.getPersistent('items')); // todo cache item name
        }
    }

    Component.onDestruction: {
        if (settings.lockOnClose) {
            cli.lockVaultInBackground();
        }

        if (settings.persistentItemCache) {
            // todo encrypt
            runtimeCache.setPersistent('items', Helpers.filterOutSensitiveItems(runtimeCache.get('items'))); // todo cache item name
        }
    }

    Components.Toaster {
        id: toasterElement
    }
}
