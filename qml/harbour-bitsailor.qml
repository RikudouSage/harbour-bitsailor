import QtQuick 2.0
import Sailfish.Silica 1.0
import Nemo.Notifications 1.0

import "pages"
import "components" as Components
import "helpers.js" as Helpers

import cz.chrastecky.bitsailor 1.0

ApplicationWindow {
    property alias toaster: toasterElement
    property var actionsWhenNotBusy: []

    id: app

    initialPage: Component { SystemCheckerPage { } }
    cover: Qt.resolvedUrl("cover/CoverPage.qml")
    allowedOrientations: defaultAllowedOrientations

    Connections {
        id: pageStackConnection
        target: pageStack

        onBusyChanged: {
            if (!pageStack.busy) {
                while (actionsWhenNotBusy.length) {
                    const callable = actionsWhenNotBusy.shift();
                    callable();
                }
            }
        }
    }

    BitwardenCli {
        id: cli
    }

    SecretsHandler {
        id: secrets
    }

    Notification {
        id: outdatedCliNotification
        summary: qsTr("Update Bitwarden CLI")
        body: qsTr("Your Bitwarden CLI might be out of date. You should check for new versions of Bitwarden CLI regularly. You can do so in the settings or by clicking this notification.")
        remoteActions: [
            {
                "name": "default",
            }
        ]
        onActionInvoked: {
            if (name === "default") {
                app.activate();
                const callable = function() {
                    pageStack.push("pages/UpdateBitwardenCliPage.qml");
                };

                pageStack.busy ? actionsWhenNotBusy.push(callable) : callable();
            }
        }
    }

    Component.onCompleted: {
        if (settings.persistentItemCache) {
            runtimeCache.set('items', runtimeCache.getPersistent('items')); // todo cache item name
        }

        // todo cache item name
        if (!runtimeCache.hasPersistent("hasLocalInstallation")) {
            runtimeCache.setPersistent("hasLocalInstallation", cli.binaryPath.indexOf(privateBinPath) === 0 ? "y" : "n");
        }

        if (runtimeCache.getPersistent("hasLocalInstallation") === "y") {
            // todo cache item name
            if (!runtimeCache.hasPersistent("lastUpdated")) {
                // date of first release, could be anything, so why not?
                runtimeCache.setPersistent("lastUpdated", new Date("2022-09-27 00:26:00").toISOString());
            }

            const week = 7 * 24 * 60 * 60 * 1000; // 1 week in milliseconds

            const date = new Date(runtimeCache.getPersistent("lastUpdated"));
            const now = new Date();

            const diff = now.getTime() - date.getTime();

            if (diff > week) {
                outdatedCliNotification.publish();
            }
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
