import QtQuick 2.0
import Sailfish.Silica 1.0

Page {
    id: page
    allowedOrientations: Orientation.All

    property string binaryName

    SilicaFlickable {
        anchors.fill: parent
        contentHeight: column.height

        Column {
            id: column

            width: page.width
            spacing: Theme.paddingLarge
            PageHeader {
                //: Page title
                title: qsTr("Missing Required Dependencies")
            }
            Label {
                x: Theme.horizontalPageMargin
                text: qsTr("Required dependency is missing: <strong>%1</strong>. This dependency should be installed automatically if you installed the app from store using the provided rpm. Please reinstall using the rpm package or install the missing dependency manually and then restart the app.").arg(binaryName)
                color: Theme.secondaryHighlightColor
                wrapMode: Label.WordWrap
                width: parent.width - Theme.horizontalPageMargin * 2
            }
        }
    }
}
