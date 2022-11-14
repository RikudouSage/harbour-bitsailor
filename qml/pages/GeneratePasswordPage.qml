import QtQuick 2.0
import Sailfish.Silica 1.0

import "../components" as Components

Page {
    property bool loaded: !loader.running

    id: page
    allowedOrientations: Orientation.All

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
            title: PageHeader {
                //: Page title
                title: qsTr("Generate Password")
            }
        }

    }
}
