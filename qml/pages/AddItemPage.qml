import QtQuick 2.0
import Sailfish.Silica 1.0

Page {
    property int type

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
                //: Page title
                title: qsTr("Add item")
            }
        }
    }
}
