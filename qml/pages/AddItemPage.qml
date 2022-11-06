import QtQuick 2.0
import Sailfish.Silica 1.0

import cz.chrastecky.bitsailor 1.0
import "../components" as Components

Page {
    property int type: BitwardenCli.NoType

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

            ComboBox {
                id: typeSelect

                property var itemData: [
                    //: Item type
                    {text: qsTr("-- choose type --"), value: BitwardenCli.NoType},
                    //: Item type
                    {text: qsTr("Login"), value: BitwardenCli.Login},
                    //: Item type
                    {text: qsTr("Card"), value: BitwardenCli.Card},
                    //: Item type
                    {text: qsTr("Note"), value: BitwardenCli.SecureNote},
                    //: Item type
                    {text: qsTr("Identity"), value: BitwardenCli.Identity},
                ]

                label: qsTr("Type")

                menu: ContextMenu {
                    Components.IntValueMenuItem {text: typeSelect.itemData[0].text; value: typeSelect.itemData[0].value}
                    Components.IntValueMenuItem {text: typeSelect.itemData[1].text; value: typeSelect.itemData[1].value}
                    Components.IntValueMenuItem {text: typeSelect.itemData[2].text; value: typeSelect.itemData[2].value}
                    Components.IntValueMenuItem {text: typeSelect.itemData[3].text; value: typeSelect.itemData[3].value}
                    Components.IntValueMenuItem {text: typeSelect.itemData[4].text; value: typeSelect.itemData[4].value}
                }

                onCurrentItemChanged: {
                    type = currentItem.value;
                }

                Component.onCompleted: {
                    const index = itemData.map(function(item) {
                        return item.value;
                    }).indexOf(type);
                    currentIndex = index;
                }
            }

            Column {
                width: parent.width
                visible: type !== BitwardenCli.NoType

                TextField {
                    id: name
                    //: Name of the item
                    label: qsTr("Name")
                }

                TextField {
                    id: loginUsername
                    label: qsTr("Username")
                    visible: type === BitwardenCli.Login
                }

                TextField {
                    property bool passwordVisible: false

                    id: loginPassword
                    label: qsTr("Password")
                    visible: type === BitwardenCli.Login
                    echoMode: passwordVisible ? TextInput.Normal : TextInput.Password

                    rightItem: Row {
                        IconButton {
                            icon.source: loginPassword.passwordVisible ? "image://theme/icon-splus-hide-password" : "image://theme/icon-splus-show-password"
                            onClicked: {
                                loginPassword.passwordVisible = !loginPassword.passwordVisible;
                            }
                        }
                    }
                }
            }
        }
    }
}
