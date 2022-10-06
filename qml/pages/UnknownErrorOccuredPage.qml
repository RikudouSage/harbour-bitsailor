import QtQuick 2.0
import Sailfish.Silica 1.0

Page {
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
                title: qsTr("Unknown Error")
            }
            Label {
                x: Theme.horizontalPageMargin
                text: qsTr("There was an unknown error and app cannot proceed. Please contact the developer on <a href='%1'>OpenRepos</a>.").arg("https://openrepos.net/users/rikudousennin")
                color: Theme.errorColor
                wrapMode: Label.WordWrap
                width: parent.width - Theme.horizontalPageMargin * 2
            }
        }
    }
}
