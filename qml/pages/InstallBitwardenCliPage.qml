import QtQuick 2.0
import Sailfish.Silica 1.0

import cz.chrastecky.bitsailor 1.0

Page {
    id: page
    allowedOrientations: Orientation.All

    BitwardenInstaller {
        id: installer

        onFinished: {
            if (!success) {
                errorMessage.visible = true;
            } else {
                pageStack.replace("LoginCheckPage.qml");
            }
        }
    }

    BusyLabel {
        id: loader
        text: qsTr("Installing... Please don't close the app.");
        running: !errorMessage.visible
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
                title: qsTr("Installing Bitwarden CLI")
            }

            Label {
                id: errorMessage

                visible: false
                x: Theme.horizontalPageMargin
                text: qsTr("There was an error installing the Bitwarden CLI.");
                color: Theme.errorColor
                wrapMode: Label.WordWrap
                width: parent.width - Theme.horizontalPageMargin * 2
            }
        }
    }

    Component.onCompleted: {
        installer.install();
    }
}
