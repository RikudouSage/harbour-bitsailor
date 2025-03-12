import QtQuick 2.0
import Sailfish.Silica 1.0

import cz.chrastecky.bitsailor 1.0

Page {
    property bool loaded: false;
    property string errorMessage: ''
    property bool searchActive: false
    property var items: []

    function onSendsResolved() {
        page.items = items;
        loaded = true;
    }

    function onFailedGettingSends() {
        loaded = true;
        errorMessage = qsTr("Failed loading list of sends");
    }

    id: page
    allowedOrientations: Orientation.All

    BusyLabel {
        id: loader
        running: !loaded
        text: qsTr("Loading items")
    }

    BitwardenCli {
        id: cli

        onSendsResolved: {
            page.onSendsResolved();
        }

        onFailedGettingSends: {
            page.onFailedGettingSends();
        }
    }

    BitwardenApi {
        id: api

        onApiNotRunning: {
            app.toaster.show(qsTr("The BitWarden server is not running,\nplease restart the app"), 100000);
        }

        onSendsResolved: {
            page.onSendsResolved();
        }

        onFailedGettingSends: {
            page.onFailedGettingSends();
        }
    }

    SilicaFlickable {
        anchors.fill: parent
        contentHeight: column.height
        visible: !loader.running

        PullDownMenu {
            MenuItem {
                text: searchActive ? qsTr("Hide search") : qsTr("Search")
                onClicked: {
                    searchActive = !searchActive;
                    if (searchActive) {
                        search.focus = true;
                    }
                }
            }
        }

        Column {
            id: column

            width: page.width
            spacing: Theme.paddingLarge
            PageHeader {
                //: Page title, probably shouldn't be translated as it's the official name of the service, Bitwarden Send
                title: qsTr("Send")
            }
            Label {
                x: Theme.horizontalPageMargin
                text: errorMessage
                color: Theme.errorColor
                wrapMode: Label.WordWrap
                width: parent.width - Theme.horizontalPageMargin * 2
                visible: errorMessage.length
            }

            SearchField {
                id: search

                width: parent.width - Theme.horizontalPageMargin * 2
                placeholderText: qsTr("Search")
                active: searchActive
                focus: active

                onTextChanged: {

                }
            }

            Label {
                x: Theme.horizontalPageMargin
                text: qsTr("No sends were found.")
                wrapMode: Label.WordWrap
                width: parent.width - Theme.horizontalPageMargin * 2
                visible: items.length < 1
            }

            Repeater {
                model: items
                width: parent.width

                delegate: ListItem {
                    property var item: items[index];

                    id: listItem
                    //menu: contextMenu
                    width: parent.width - Theme.horizontalPageMargin * 2
                    x: Theme.horizontalPageMargin

                    contentHeight: Theme.itemSizeMedium

                    onClicked: {
                        console.log('todo');
                    }

                    Label {
                        id: itemTitle
                        text: item.name
                        width: parent.width
                    }

                    Label {
                        anchors.top: itemTitle.bottom
                        font.pixelSize: Theme.fontSizeSmall
                        color: Theme.secondaryHighlightColor
                        text: (item.type === BitwardenCli.SendTypeText ? qsTr('Text') : qsTr('File')) + ', ' + new Date(item.deletionDate).toLocaleString(Qt.locale(), Locale.ShortFormat)
                    }

                    IconButton {
                        anchors.right: itemTitle.right
                        anchors.top: itemTitle.top
                        height: itemTitle.height
                        icon.source: "image://theme/icon-m-clipboard"
                        onClicked: {
                            Clipboard.text = item.accessUrl;
                            app.toaster.show(qsTr("URL copied to clipboard"));
                        }
                    }
                }
            }
        }
    }

    onStatusChanged: {
        if (status === PageStatus.Active) {
            settings.useApi ? api.getSends() : cli.getSends();
        }
    }
}
