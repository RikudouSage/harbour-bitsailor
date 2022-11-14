import QtQuick 2.0
import Sailfish.Silica 1.0

Dialog {
    id: page
    allowedOrientations: Orientation.All

    property alias acceptButtonText: header.acceptText
    property alias description: descriptionText.text
    property alias inputLabel: input.label
    property alias value: input.text

    SilicaFlickable {
        anchors.fill: parent
        contentHeight: column.height

        Column {
            id: column

            width: page.width
            spacing: Theme.paddingLarge
            DialogHeader {
                id: header
                //: Dialog accept text
                acceptText: qsTr("Confirm")
            }
            Label {
                id: descriptionText
                x: Theme.horizontalPageMargin
                color: Theme.secondaryHighlightColor
                wrapMode: Label.WordWrap
                width: parent.width - Theme.horizontalPageMargin * 2
            }

            TextField {
                id: input
                label: ''
            }
        }
    }
}
