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
                acceptText: qsTr("Proceed")
            }
            Label {
                x: Theme.horizontalPageMargin
                text: qsTr("The PIN will be deleted and you can unlock the vault using your password. Once you unlock your vault you can set a PIN code again.")
                color: Theme.secondaryHighlightColor
                wrapMode: Label.WordWrap
                width: parent.width - Theme.horizontalPageMargin * 2
            }
        }
    }
}
