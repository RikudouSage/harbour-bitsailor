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

        PullDownMenu {
            MenuItem {
                text: qsTr("Search")
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

            Repeater {
                model: logins
                width: parent.width

                delegate: ListItem {
                    property var item: logins[index];

                    function remove() {
                        remorseDelete(function() {
                            logins = logins.filter(function(itemToFilter) {
                                return item.id !== itemToFilter.id;
                            });
                        });
                    }

                    id: listItem
                    menu: contextMenu
                    width: parent.width - Theme.horizontalPageMargin * 2
                    x: Theme.horizontalPageMargin

                    contentHeight: Theme.itemSizeMedium

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
                                 text: "Remove"
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
