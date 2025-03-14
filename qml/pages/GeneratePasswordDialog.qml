import QtQuick 2.0
import Sailfish.Silica 1.0

import "../components" as Components

Dialog {
    property alias password: generator.password

    id: page
    allowedOrientations: Orientation.All

    canAccept: !generator.loading

    Components.GeneratePasswordContent {
        id: generator
        title: DialogHeader {
            //: Dialog accept
            acceptText: qsTr("Use password")
            cancelText: qsTr("Cancel")
        }
    }
}
