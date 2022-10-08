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

        onCurrentPageChanged: {
            bottomMenu.visible = false;
            currentPageConnection.target = pageStack.currentPage;
            currentPageConnection.handleBottomMenuDisplay();
        }
    }

    Connections {
        id: currentPageConnection
        target: pageStack.currentPage
        ignoreUnknownSignals: true

        function handleBottomMenuDisplay() {
            const page = pageStack.currentPage;
            if (!page.loaded) {
                return;
            }

            const regex = /(.+?)_QML/;
            const matches = regex.exec(pageStack.currentPage.toString());
            const typeName = matches[1];
            if (!typeName) {
                return;
            }

            switch (typeName) {
            case "MainPage":
                bottomMenu.activateVaults();
                bottomMenu.visible = true;
                break;
            case "SendListPage":
                bottomMenu.activateSend();
                bottomMenu.visible = true;
                break;
            }
        }

        onLoadedChanged: {
            handleBottomMenuDisplay();
        }
    }

    Timer {
        id: checkLoadedTimer
        running: false
    }

    BitwardenCli {
        id: cli
    }

    SecretsHandler {
        id: secrets
    }

    Notification {
        id: outdatedCliNotification
        //: notification title
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
            runtimeCache.set(CacheKey.Items, runtimeCache.getPersistent(CacheKey.Items));
        }

        if (!runtimeCache.hasPersistent(CacheKey.HasLocalInstallation)) {
            runtimeCache.setPersistent(CacheKey.HasLocalInstallation, cli.binaryPath.indexOf(privateBinPath) === 0 ? "y" : "n");
        }

        if (runtimeCache.getPersistent(CacheKey.HasLocalInstallation) === "y") {
            if (!runtimeCache.hasPersistent(CacheKey.LastUpdated)) {
                // date of first release, could be anything, so why not?
                runtimeCache.setPersistent(CacheKey.LastUpdated, new Date("2022-09-27 00:26:00").toISOString());
            }

            const week = 7 * 24 * 60 * 60 * 1000; // 1 week in milliseconds

            const date = new Date(runtimeCache.getPersistent(CacheKey.LastUpdated));
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
            runtimeCache.setPersistent(CacheKey.Items, Helpers.filterOutSensitiveItems(runtimeCache.get(CacheKey.Items)));
        }
    }

    Components.Toaster {
        id: toasterElement
    }

    Components.BottomMenu {
        id: bottomMenu
        visible: false
    }
}
