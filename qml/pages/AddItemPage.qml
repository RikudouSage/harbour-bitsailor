import QtQuick 2.0
import Sailfish.Silica 1.0

import cz.chrastecky.bitsailor 1.0
import "../components" as Components

Dialog {
    property int type: BitwardenCli.NoType
    readonly property var itemTemplate: {
        "organizationId": null,
        "collectionIds": null,
        "folderId": null,
        "type": null,
        "name": null,
        "notes": null,
        "favorite": false,
        "fields": [],
        "login": null,
        "secureNote": null,
        "card": null,
        "identity": null,
        "reprompt": 0
    }
    readonly property var loginItemTemplate: {
        "uris": [],
        "username": null,
        "password": null,
        "totp": null
    }
    readonly property var secureNoteItemTemplate: {
        "type": 0
    }
    readonly property var cardItemTemplate: {
        "cardholderName": null,
        "brand": null,
        "number": null,
        "expMonth": null,
        "expYear": null,
        "code": null
    }

    property alias nameValue: name.text
    property alias loginUsernameValue: loginUsername.text
    property alias loginPasswordValue: loginPassword.text
    property alias loginTotpValue: loginTotp.text
    property alias loginNotesValue: loginNotes.text
    property alias cardCardholderNameValue: cardCardholderName.text
    property alias cardBrandValue: cardBrand.value
    property alias cardNumberValue: cardNumber.text
    property alias cardExpirationMonthValue: cardExpirationMonth.value
    property alias cardExpirationYearValue: cardExpirationYear.text
    property alias cardCvvValue: cardCvv.text
    property alias secureNoteNoteValue: secureNoteNote.text
    function getUris() {
        const result = [];
        for (var i = 0; i < urisModel.count; ++i) {
            const item = urisModel.get(i);
            if (!item.value) {
                continue;
            }

            result.push({
                uri: item.value,
                match: item.matchType >= 0 ? item.matchType : null
            });
        }
        return result;
    }

    id: page
    allowedOrientations: Orientation.All

    canAccept: name.text && type !== BitwardenCli.NoType

    SilicaFlickable {
        anchors.fill: parent
        contentHeight: column.height

        Column {
            id: column

            width: page.width
            spacing: Theme.paddingLarge
            DialogHeader {
                //: Page title
                acceptText: qsTr("Add item")
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
                    //{text: qsTr("Identity"), value: BitwardenCli.Identity},
                ]

                label: qsTr("Type")

                menu: ContextMenu {
                    Components.IntValueMenuItem {text: typeSelect.itemData[0].text; value: typeSelect.itemData[0].value}
                    Components.IntValueMenuItem {text: typeSelect.itemData[1].text; value: typeSelect.itemData[1].value}
                    Components.IntValueMenuItem {text: typeSelect.itemData[2].text; value: typeSelect.itemData[2].value}
                    Components.IntValueMenuItem {text: typeSelect.itemData[3].text; value: typeSelect.itemData[3].value}
                    //Components.IntValueMenuItem {text: typeSelect.itemData[4].text; value: typeSelect.itemData[4].value}
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
                id: mainColumn
                width: parent.width
                visible: type !== BitwardenCli.NoType

                SectionHeader {
                    text: qsTr("Item information")
                }

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
/*                        IconButton {
                            // todo check for password leaks
                            icon.source: "image://theme/icon-s-checkmark"
                        }
*/
                        IconButton {
                            icon.source: loginPassword.passwordVisible ? "image://theme/icon-splus-hide-password" : "image://theme/icon-splus-show-password"
                            onClicked: {
                                loginPassword.passwordVisible = !loginPassword.passwordVisible;
                            }
                        }

                        IconButton {
                            icon.source: "image://theme/icon-s-sync"
                            onClicked: {
                                const dialog = pageStack.push("GeneratePasswordDialog.qml");
                                dialog.accepted.connect(function() {
                                    loginPassword.text = dialog.password;
                                });
                            }
                        }
                    }
                }

                TextField {
                    id: loginTotp
                    label: qsTr("Authenticator key (TOTP)")
                    visible: type === BitwardenCli.Login
                }

                SectionHeader {
                    text: qsTr("URIs")
                    visible: type === BitwardenCli.Login
                }

                ListModel {
                    id: urisModel

                    ListElement {
                        value: ''
                        matchType: BitwardenCli.NoType
                    }
                }

                Repeater {
                    id: urisRepeater
                    model: urisModel

                    Column {
                        width: mainColumn.width

                        TextField {
                            property var uri: urisModel.get(index)

                            id: uriField
                            text: typeof uri !== 'undefined' ? uri.value : ''
                            label: qsTr("URI %1").arg(index + 1)
                            visible: page.type === BitwardenCli.Login

                            onTextChanged: {
                                uri.value = text;
                            }

                            rightItem: Row {
                                IconButton {
                                    icon.source: "image://theme/icon-s-setting"
                                    onClicked: {
                                        matchTypeSelect.visible = !matchTypeSelect.visible;
                                    }
                                }

                                IconButton {
                                    visible: index > 0
                                    icon.source: "image://theme/icon-splus-remove"
                                    icon.color: "red"
                                    onClicked: {
                                        urisModel.remove(index);
                                    }
                                }
                            }
                        }

                        ComboBox {
                            property var uri: urisModel.get(index)

                            id: matchTypeSelect
                            visible: false
                            label: qsTr("Match type")

                            property var itemData: [
                                //: URI match type
                                {text: qsTr("Default match detection"), value: BitwardenCli.NoType},
                                //: URI match type
                                {text: qsTr("Base domain"), value: BitwardenCli.Domain},
                                //: URI match type
                                {text: qsTr("Host"), value: BitwardenCli.Host},
                                //: URI match type
                                {text: qsTr("Starts with"), value: BitwardenCli.StartsWith},
                                //: URI match type
                                {text: qsTr("Exact"), value: BitwardenCli.Exact},
                                //: URI match type
                                {text: qsTr("Regular expression"), value: BitwardenCli.RegularExpression},
                                //: URI match type
                                {text: qsTr("Never"), value: BitwardenCli.Never},
                            ]

                            menu: ContextMenu {
                                Components.IntValueMenuItem {text: matchTypeSelect.itemData[0].text; value: matchTypeSelect.itemData[0].value}
                                Components.IntValueMenuItem {text: matchTypeSelect.itemData[1].text; value: matchTypeSelect.itemData[1].value}
                                Components.IntValueMenuItem {text: matchTypeSelect.itemData[2].text; value: matchTypeSelect.itemData[2].value}
                                Components.IntValueMenuItem {text: matchTypeSelect.itemData[3].text; value: matchTypeSelect.itemData[3].value}
                                Components.IntValueMenuItem {text: matchTypeSelect.itemData[4].text; value: matchTypeSelect.itemData[4].value}
                                Components.IntValueMenuItem {text: matchTypeSelect.itemData[5].text; value: matchTypeSelect.itemData[5].value}
                                Components.IntValueMenuItem {text: matchTypeSelect.itemData[6].text; value: matchTypeSelect.itemData[6].value}
                            }

                            onCurrentItemChanged: {
                                uri.matchType = currentItem.value;
                            }

                            Component.onCompleted: {
                                const index = itemData.map(function(item) {
                                    return item.value;
                                }).indexOf(uri.matchType);
                                currentIndex = index;
                            }
                        }
                    }
                }

                Button {
                    text: qsTr("New URI")
                    x: Theme.horizontalPageMargin
                    visible: type === BitwardenCli.Login
                    width: parent.width - Theme.horizontalPageMargin * 2
                    onClicked: {
                        urisModel.append({value: '', matchType: BitwardenCli.NoType});
                    }
                }

                SectionHeader {
                    visible: type === BitwardenCli.Login
                    text: qsTr("Notes")
                }

                TextArea {
                    id: loginNotes
                    visible: type === BitwardenCli.Login
                    label: qsTr("Note")
                }

                /*SectionHeader {
                    visible: type === BitwardenCli.Login
                    text: qsTr("Custom fields")
                }

                ListModel {
                    id: customFieldsModel
                }

                Repeater {
                    model: customFieldsModel
                    // todo
                }

                ComboBox {
                    id: newFieldTypeSelect
                    label: qsTr("New field type")
                    visible: type === BitwardenCli.Login

                    property var itemData: [
                        //: Custom field type
                        {text: qsTr("Text"), value: BitwardenCli.FieldTypeText},
                        //: Custom field type
                        {text: qsTr("Hidden"), value: BitwardenCli.FieldTypeHidden},
                        //: Custom field type
                        {text: qsTr("Boolean"), value: BitwardenCli.FieldTypeBoolean},
                    ]

                    menu: ContextMenu {
                        Components.IntValueMenuItem {text: newFieldTypeSelect.itemData[0].text; value: newFieldTypeSelect.itemData[0].value}
                        Components.IntValueMenuItem {text: newFieldTypeSelect.itemData[1].text; value: newFieldTypeSelect.itemData[1].value}
                        Components.IntValueMenuItem {text: newFieldTypeSelect.itemData[2].text; value: newFieldTypeSelect.itemData[2].value}
                    }
                }
                Button {
                    text: qsTr("Add new field")
                    x: Theme.horizontalPageMargin
                    width: parent.width - Theme.horizontalPageMargin * 2
                    visible: type === BitwardenCli.Login

                    onClicked: {
                        customFieldsModel.append({fieldType: newFieldTypeSelect.currentItem.value, value: ''});
                    }
                }*/

                TextField {
                    id: cardCardholderName
                    label: qsTr("Cardholder Name")
                    visible: type === BitwardenCli.Card
                }

                ComboBox {
                    id: cardBrand
                    label: qsTr("Brand")
                    visible: type === BitwardenCli.Card
                    menu: ContextMenu {
                        //: Choose a card brand from a ComboBox
                        Components.StringValueMenuItem {text: qsTr("-- choose --"); value: ''}
                        Components.StringValueMenuItem {text: "Visa"}
                        Components.StringValueMenuItem {text: "Mastercard"}
                        Components.StringValueMenuItem {text: "American Express"}
                        Components.StringValueMenuItem {text: "Discover"}
                        Components.StringValueMenuItem {text: "Diners Club"}
                        Components.StringValueMenuItem {text: "JCB"}
                        Components.StringValueMenuItem {text: "Maestro"}
                        Components.StringValueMenuItem {text: "UnionPay"}
                        //: Card brand
                        Components.StringValueMenuItem {text: qsTr("Other"); value: 'Other'}
                    }
                }

                TextField {
                    property bool passwordVisible: false

                    id: cardNumber
                    label: qsTr("Card Number")
                    visible: type === BitwardenCli.Card
                    echoMode: passwordVisible ? TextInput.Normal : TextInput.Password

                    rightItem: Row {
                        IconButton {
                            icon.source: cardNumber.passwordVisible ? "image://theme/icon-splus-hide-password" : "image://theme/icon-splus-show-password"
                            onClicked: {
                                cardNumber.passwordVisible = !cardNumber.passwordVisible;
                            }
                        }
                    }
                }

                ComboBox {
                    id: cardExpirationMonth
                    label: qsTr("Expiration month")
                    visible: type === BitwardenCli.Card

                    menu: ContextMenu {
                        Components.StringValueMenuItem {text: '01'}
                        Components.StringValueMenuItem {text: '02'}
                        Components.StringValueMenuItem {text: '03'}
                        Components.StringValueMenuItem {text: '04'}
                        Components.StringValueMenuItem {text: '05'}
                        Components.StringValueMenuItem {text: '06'}
                        Components.StringValueMenuItem {text: '07'}
                        Components.StringValueMenuItem {text: '08'}
                        Components.StringValueMenuItem {text: '09'}
                        Components.StringValueMenuItem {text: '10'}
                        Components.StringValueMenuItem {text: '11'}
                        Components.StringValueMenuItem {text: '12'}
                    }
                }

                TextField {
                    id: cardExpirationYear
                    label: qsTr("Expiration year")
                    visible: type === BitwardenCli.Card
                    inputMethodHints: Qt.ImhDigitsOnly
                    validator: IntValidator {
                        bottom: 2000
                        top: 2100
                    }
                }

                TextField {
                    property bool passwordVisible: false

                    id: cardCvv
                    label: qsTr("Security Code")
                    visible: type === BitwardenCli.Card
                    echoMode: passwordVisible ? TextInput.Normal : TextInput.Password
                    inputMethodHints: Qt.ImhDigitsOnly
                    validator: RegExpValidator {
                        regExp: /^[0-9]{3,4}$/
                    }

                    rightItem: Row {
                        IconButton {
                            icon.source: cardCvv.passwordVisible ? "image://theme/icon-splus-hide-password" : "image://theme/icon-splus-show-password"
                            onClicked: {
                                cardCvv.passwordVisible = !cardCvv.passwordVisible;
                            }
                        }
                    }
                }

                TextArea {
                    id: secureNoteNote
                    visible: type === BitwardenCli.SecureNote
                    label: qsTr("Note")
                }
            }
        }
    }
}
