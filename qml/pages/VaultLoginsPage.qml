import QtQuick 2.0
import Sailfish.Silica 1.0

import cz.chrastecky.bitsailor 1.0

Page {
    property var logins: []
    property bool loaded: false
    property string errorText

    id: page
    allowedOrientations: Orientation.All

    BusyLabel {
        text: qsTr("Loading")
        running: !loaded
    }

    BitwardenCli {
        id: cli

        onFailedGettingItems: {
            errorText = qsTr("An error occured while loading items. Please try again.")
        }

        onItemsResolved: {
            logins = items;
            loaded = true;
        }
    }

    SilicaFlickable {
        anchors.fill: parent
        contentHeight: column.height

        Column {
            id: column

            width: page.width
            spacing: Theme.paddingLarge
            PageHeader {
                title: qsTr("Logins")
            }

            Label {
                x: Theme.horizontalPageMargin
                text: errorText
                visible: errorText.length
                color: Theme.errorColor
                wrapMode: Label.WordWrap
                width: parent.width - Theme.horizontalPageMargin * 2
            }
        }
    }

    Component.onCompleted: {
        cli.getLogins();
    }
}
