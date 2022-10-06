import QtQuick 2.0
import Sailfish.Silica 1.0

Dialog {
    id: page
    allowedOrientations: Orientation.All

    SilicaFlickable {
        anchors.fill: parent
        contentHeight: column.height

        Column {
            id: column

            width: page.width
            spacing: Theme.paddingLarge

            DialogHeader {
                //: Dialog accept text
                acceptText: qsTr("Continue")
                //: Dialog reject text
                cancelText: qsTr("Exit")
            }

            Label {
                x: Theme.horizontalPageMargin
                text: qsTr("The Bitwarden CLI is not installed, do you wish to install it using <strong>npm</strong>? The app cannot continue without Bitwarden CLI.");
                color: Theme.secondaryHighlightColor
                wrapMode: Label.WordWrap
                width: parent.width - Theme.horizontalPageMargin * 2
            }
        }
    }

    onRejected: {
        Qt.quit();
    }
}
