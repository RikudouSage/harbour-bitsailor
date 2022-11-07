import QtQuick 2.0
import Sailfish.Silica 1.0

import "../components" as Components

Dialog {
    property alias password: generator.password

    id: page
    allowedOrientations: Orientation.All

    canAccept: !generator.loading

    BusyLabel {
        id: loader
        text: qsTr("Generating password")
        running: generator.loading
    }

    SilicaFlickable {
        anchors.fill: parent
        contentHeight: generator.height
        visible: !loader.running

        PullDownMenu {
            MenuItem {
                text: qsTr("Generate new password")
                onClicked: {
                    generator.generatePassword();
                }
            }
        }

        Components.GeneratePasswordContent {
            id: generator
            title: DialogHeader {
                //: Page title
                acceptText: qsTr("Use password")
                cancelText: qsTr("Cancel")
            }
        }

    }
}
