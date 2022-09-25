import QtQuick 2.0
import Sailfish.Silica 1.0

import "pages"
import "helpers.js" as Helpers

import cz.chrastecky.bitsailor 1.0

ApplicationWindow {
    initialPage: Component { SystemCheckerPage { } }
    cover: Qt.resolvedUrl("cover/CoverPage.qml")
    allowedOrientations: defaultAllowedOrientations

    BitwardenCli {
        id: cli
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
            runtimeCache.setPersistent('items', Helpers.filterOutSensitiveItems(runtimeCache.get('items'))); // todo cache item name
        }
    }
}
