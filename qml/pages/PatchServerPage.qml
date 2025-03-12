import QtQuick 2.0
import Sailfish.Silica 1.0

Dialog {
    property alias ignored: ignoreButton.checked
    property alias description: descriptionText.text
    property bool canOnlyIgnore: false

    id: page
    allowedOrientations: Orientation.All
    canAccept: canOnlyIgnore ? ignoreButton.checked : true

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
                acceptText: ignoreButton.checked ? qsTr("Ignore patching") : qsTr("Patch server")
            }

            Label {
                id: descriptionText
                x: Theme.horizontalPageMargin
                color: Theme.secondaryHighlightColor
                wrapMode: Label.WordWrap
                width: parent.width - Theme.horizontalPageMargin * 2
                text: qsTr("The built-in BitWarden server is insecure and allows anyone to access it once it's running. To fix that we can patch the server to force it to require authentication before revealing its secrets.<br><br>You can also ignore this, but it's <strong>highly discouraged</strong> and you should <strong>really</strong> know what you're doing.<br><br>If you cancel, the api will be disabled.")
            }

            TextSwitch {
                id: ignoreButton
                text: qsTr("Ignore the above warning, don't patch the server")
            }
        }
    }
}
