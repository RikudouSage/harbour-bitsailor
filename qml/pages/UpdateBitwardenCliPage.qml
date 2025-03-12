import QtQuick 2.0
import Sailfish.Silica 1.0

import cz.chrastecky.bitsailor 1.0

Page {
    id: page
    allowedOrientations: Orientation.All

    BitwardenInstaller {
        id: installer

        onUpdateFinished: {
            if (!success) {
                errorMessage.visible = true;
                loader.running = false;
            } else {
                runtimeCache.setPersistent(CacheKey.LastUpdated, new Date().toISOString());
                app.toaster.show(qsTr("Bitwarden CLI was updated successfully"));
                if (settings.useApi) {
                    // todo
                    app.toaster.show(qsTr("Please restart the app\nfor the changes to take effect."));
                }

                pageStack.pop();
            }
        }
    }

    BusyLabel {
        id: loader
        text: qsTr("Updating Bitwarden CLI... Please don't close the app or exit this page.");
        running: true
    }

    SilicaFlickable {
        anchors.fill: parent
        contentHeight: column.height
        visible: !loader.running

        Column {
            id: column

            width: page.width
            spacing: Theme.paddingLarge
            PageHeader {
                //: Page title
                title: qsTr("Updating Bitwarden CLI")
            }

            Label {
                id: errorMessage

                visible: false
                x: Theme.horizontalPageMargin
                text: qsTr("There was an error updating the Bitwarden CLI.");
                color: Theme.errorColor
                wrapMode: Label.WordWrap
                width: parent.width - Theme.horizontalPageMargin * 2
            }
        }
    }

    Component.onCompleted: {
        installer.update();
    }
}
