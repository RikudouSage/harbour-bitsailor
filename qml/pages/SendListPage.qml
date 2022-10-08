import QtQuick 2.0
import Sailfish.Silica 1.0

Page {
    property bool loaded: true;

    id: page
    allowedOrientations: Orientation.All

    SilicaFlickable {
        anchors.fill: parent
        contentHeight: column.height

        Column {
            id: column

            width: page.width
            spacing: Theme.paddingLarge
            PageHeader {
                //: Page title, probably shouldn't be translated as it's the official name of the service, Bitwarden Send
                title: qsTr("Send")
            }
        }
    }
}
