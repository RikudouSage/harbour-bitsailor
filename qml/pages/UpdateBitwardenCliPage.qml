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
                // todo cache item name
                runtimeCache.setPersistent("lastUpdated", new Date().toISOString());
                app.toaster.show(qsTr("Bitwarden CLI was updated successfully"));
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
