import QtQuick 2.0
import Sailfish.Silica 1.0

import cz.chrastecky.bitsailor 1.0

Page {
    property var allLogins: []
    property var logins: []
    property bool loaded: false
    property string errorText

    property bool searchActive: false

    id: page
    allowedOrientations: Orientation.All

    BusyLabel {
        id: loader
        text: qsTr("Loading")
        running: !loaded
    }

    BitwardenCli {
        id: cli

        onFailedGettingItems: {
            errorText = qsTr("An error occured while loading items. Please try again.")
        }

        onItemsResolved: {
            allLogins = items;
            logins = items;
            loaded = true;
        }
    }

    SilicaFlickable {
        anchors.fill: parent
        contentHeight: column.height
        visible: !loader.running

        VerticalScrollDecorator {}

        PullDownMenu {
            /*MenuItem {
                text: qsTr("Add login")
                onClicked: {
                    app.toaster.show(qsTr("This functionality is not implemented yet."));
                }
            }*/

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

            SearchField {
                id: search

                width: parent.width - Theme.horizontalPageMargin * 2
                placeholderText: qsTr("Search")
                active: searchActive
                focus: active

                onTextChanged: {
                    if (!text) {
                        cli.getLogins();
                    } else {
                        logins = allLogins.filter(function(item) {
                            const searchable = [item.name, item.login.username];
                            var index;
                            for (index in item.fields || []) {
                                if (!item.fields.hasOwnProperty(index)) {
                                    continue;
                                }
                                searchable.push(item.fields[index].name, item.fields[index].value)
                            }
                            for (index in item.login.uris || []) {
                                if (!item.login.uris.hasOwnProperty(index)) {
                                    continue;
                                }
                                searchable.push(item.login.uris[index].uri);
                            }

                            for (index in searchable) {
                                if (!searchable.hasOwnProperty(index)) {
                                    continue;
                                }
                                if (String(searchable[index]).toLocaleLowerCase().indexOf(text.toLocaleLowerCase()) > -1) {
                                    return true;
                                }
                            }

                            return false;
                        });
                    }
                }
            }

            Repeater {
                model: logins
                width: parent.width

                delegate: ListItem {
                    property var item: logins[index];

                    function remove() {
                        remorseDelete(function() {
                            cli.deleteItemInBackground(item.id);
                            visible = false;
                        });
                    }

                    id: listItem
                    menu: contextMenu
                    width: parent.width - Theme.horizontalPageMargin * 2
                    x: Theme.horizontalPageMargin

                    contentHeight: Theme.itemSizeMedium

                    onClicked: {
                        pageStack.push("ItemDetailPage.qml", {itemId: item.id});
                    }

                    Label {
                        id: itemTitle
                        text: item.name
                    }

                    Label {
                        anchors.top: itemTitle.bottom
                        text: item.login.username || ''
                        font.pixelSize: Theme.fontSizeSmall
                        color: Theme.secondaryHighlightColor
                    }

                    Component {
                         id: contextMenu
                         ContextMenu {
                             IconMenuItem {
                                 text: qsTr("Remove")
                                 icon.source: "image://theme/icon-m-remove"

                                 onClicked: {
                                     remove();
                                 }
                             }
                         }
                     }
                }
            }
        }
    }

    Component.onCompleted: {
        cli.getLogins();
    }
}
