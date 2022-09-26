import QtQuick 2.0
import Sailfish.Silica 1.0

import cz.chrastecky.bitsailor 1.0

Page {
    property string itemId
    property var item
    property bool loaded: false
    property bool pageLoaded: false
    property string errorText

    id: page
    allowedOrientations: Orientation.All

    BitwardenCli {
        id: cli

        onItemFetched: {
            loaded = true;
        }

        onItemFetchingFailed: {
            loaded = true;
            errorText = qsTr("Failed loading the item, please try again later or sync your vault an check that it wasn't deleted.");
        }
    }

    BusyLabel {
        id: loader
        running: !loaded
        text: qsTr("Loading...");
    }

    SilicaFlickable {
        anchors.fill: parent
        contentHeight: column.height
        visible: !loader.running

        Column {
            id: column

            width: page.width
            spacing: Theme.paddingLarge
            PageHeader {
                title: qsTr("Item detail")
            }

            Label {
                x: Theme.horizontalPageMargin
                text: errorText
                color: Theme.errorColor
                wrapMode: Label.WordWrap
                width: parent.width - Theme.horizontalPageMargin * 2
                visible: errorText.length
            }
        }
    }

    onStatusChanged: {
        if (status === PageStatus.Active) {
            if (!pageLoaded) {
                cli.getItem(itemId);
            }

            pageLoaded = true;
        }
    }
}
