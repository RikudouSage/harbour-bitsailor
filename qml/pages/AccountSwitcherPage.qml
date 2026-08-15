import QtQuick 2.0
import Sailfish.Silica 1.0

Page {
    id: page
    allowedOrientations: Orientation.All

    ListModel {
        id: accounts

        ListElement {
            name: "Dominik Personal"
            email: "dominik@example.com"
            server: "bitwarden.com"
            isCurrent: true
        }

        ListElement {
            name: "Work Vault"
            email: "dominik@company.example"
            server: "bitwarden.eu"
            isCurrent: false
        }

        ListElement {
            name: ""
            email: "family@example.net"
            server: "vault.example.net"
            isCurrent: false
        }
    }

    SilicaFlickable {
        anchors.fill: parent
        contentHeight: column.height

        VerticalScrollDecorator {}

        PullDownMenu {
            MenuItem {
                text: qsTr("Add Account")
                onClicked: {
                    app.toaster.show(qsTr("Account management is not connected yet."));
                }
            }
        }

        Column {
            id: column

            width: page.width
            spacing: Theme.paddingLarge

            PageHeader {
                //: Page title
                title: qsTr("Accounts")
            }

            Label {
                x: Theme.horizontalPageMargin
                width: parent.width - Theme.horizontalPageMargin * 2
                text: qsTr("Choose which Bitwarden account should be active on this device.")
                color: Theme.secondaryHighlightColor
                wrapMode: Label.WordWrap
                font.pixelSize: Theme.fontSizeSmall
            }

            SectionHeader {
                text: qsTr("Signed in")
            }

            Repeater {
                model: accounts

                delegate: ListItem {
                    id: accountItem

                    menu: accountContextMenu
                    width: parent.width
                    contentHeight: Math.max(Theme.itemSizeLarge, accountDetails.height + Theme.paddingMedium * 2)

                    onClicked: {
                        app.toaster.show(qsTr("Account switching is not connected yet."));
                    }

                    Rectangle {
                        anchors.fill: parent
                        visible: isCurrent
                        color: Theme.rgba(Theme.highlightBackgroundColor, accountItem.highlighted ? 0.26 : 0.16)
                    }

                    Rectangle {
                        id: currentMarker
                        anchors {
                            left: parent.left
                            top: parent.top
                            bottom: parent.bottom
                        }
                        width: Theme.paddingSmall
                        visible: isCurrent
                        color: Theme.highlightColor
                    }

                    Image {
                        id: accountIcon
                        anchors {
                            left: parent.left
                            leftMargin: Theme.horizontalPageMargin
                            verticalCenter: parent.verticalCenter
                        }
                        width: Theme.iconSizeMedium
                        height: width
                        source: "image://theme/icon-m-contact?" + (accountItem.highlighted ? Theme.highlightColor : Theme.primaryColor)
                    }

                    Column {
                        id: accountDetails
                        anchors {
                            left: accountIcon.right
                            right: accountState.left
                            leftMargin: Theme.paddingMedium
                            rightMargin: Theme.paddingMedium
                            verticalCenter: parent.verticalCenter
                        }
                        spacing: Theme.paddingSmall / 2

                        Label {
                            width: parent.width
                            text: name || email
                            color: accountItem.highlighted ? Theme.highlightColor : Theme.primaryColor
                            truncationMode: TruncationMode.Fade
                        }

                        Label {
                            width: parent.width
                            text: email
                            color: Theme.secondaryHighlightColor
                            font.pixelSize: Theme.fontSizeSmall
                            truncationMode: TruncationMode.Fade
                            visible: name.length
                        }

                        Label {
                            width: parent.width
                            text: server
                            color: Theme.secondaryColor
                            font.pixelSize: Theme.fontSizeExtraSmall
                            truncationMode: TruncationMode.Fade
                        }
                    }

                    Column {
                        id: accountState
                        anchors {
                            right: parent.right
                            rightMargin: Theme.horizontalPageMargin
                            verticalCenter: parent.verticalCenter
                        }
                        width: Math.min(Theme.itemSizeLarge + Theme.paddingLarge, page.width * 0.28)
                        spacing: Theme.paddingSmall / 2

                        Label {
                            width: parent.width
                            horizontalAlignment: Text.AlignRight
                            text: isCurrent ? qsTr("Current") : ""
                            color: Theme.highlightColor
                            font.pixelSize: Theme.fontSizeExtraSmall
                            truncationMode: TruncationMode.Fade
                        }

                    }

                    Component {
                        id: accountContextMenu

                        ContextMenu {
                            IconMenuItem {
                                text: qsTr("Remove")
                                icon.source: "image://theme/icon-m-remove"

                                onClicked: {
                                    app.toaster.show(qsTr("Account removal is not connected yet."));
                                }
                            }
                        }
                    }
                }
            }

            Item {
                width: parent.width
                height: Theme.paddingMedium
            }
        }
    }
}
