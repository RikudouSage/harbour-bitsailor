import QtQuick 2.0
import Sailfish.Silica 1.0

CoverBackground {

    Column {
        anchors.centerIn: parent
        width: parent.width
        spacing: Theme.paddingLarge

        Label {
            text: qsTr("BitSailor")
            id: label
            anchors.horizontalCenter: parent.horizontalCenter
        }
        Icon {
            source: "file:///usr/share/harbour-bitsailor/logo-black-white.png" // todo find out if some standard path exists for this
            anchors.horizontalCenter: parent.horizontalCenter
            sourceSize: "100x100"
        }
    }

    CoverActionList {
        id: coverAction

        /*CoverAction {
            iconSource: "image://theme/icon-cover-next"
        }

        CoverAction {
            iconSource: "image://theme/icon-cover-pause"
        }*/
    }
}
