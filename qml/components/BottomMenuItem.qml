import QtQuick 2.0
import Sailfish.Silica 1.0

Column {
    property string image
    property alias text: label.text
    signal clicked();

    id: root
    opacity: inactiveOpacity
    IconButton {
        id: iconButton
        icon.source: root.image
        icon.width: Theme.iconSizeSmallPlus
        icon.height: icon.width
        anchors.horizontalCenter: parent.horizontalCenter
        onClicked: {
            root.clicked();
        }
    }
    Label {
        id: label
        anchors.horizontalCenter: parent.horizontalCenter
        font.pixelSize: Theme.fontSizeExtraSmall
    }
}
