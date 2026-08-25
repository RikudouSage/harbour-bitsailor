import QtQuick 2.0
import Sailfish.Silica 1.0

import cz.chrastecky.bitsailor 1.0
import "../components" as Components

Dialog {
    property int type: BitSailorCore.ItemTypeNone
    property bool typeEditable: true
    //: Page title
    property string acceptText: qsTr("Add item")

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

    property var initialUris: []
    property var initialFields: []
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
    function getFields() {
        const result = [];
        for (var i = 0; i < customFieldsModel.count; ++i) {
            const field = customFieldsModel.get(i);
            if (!field.fieldName && !field.fieldValue && field.fieldLinkedId == null) {
                continue;
            }

            result.push({
                type: field.fieldType,
                name: field.fieldName,
                value: field.fieldType === BitSailorCore.FieldTypeCheckbox
                    ? (field.fieldChecked ? "true" : "false")
                    : (field.fieldValue || null),
                linkedId: field.fieldLinkedId == null ? null : field.fieldLinkedId
            });
        }
        return result;
    }
    function addField(fieldType) {
        customFieldsModel.append({
            fieldType: fieldType,
            fieldName: '',
            fieldValue: '',
            fieldChecked: false,
            fieldLinkedId: fieldType === BitSailorCore.FieldTypeLinkedId ? 100 : null
        });
    }

    id: page
    allowedOrientations: Orientation.All

    canAccept: name.text && type !== BitSailorCore.ItemTypeNone

    SilicaFlickable {
        anchors.fill: parent
        contentHeight: column.height

        Column {
            id: column

            width: page.width
            spacing: Theme.paddingLarge
            DialogHeader {
                //: Page title
                acceptText: page.acceptText
            }

            ComboBox {
                id: typeSelect
                visible: typeEditable

                property var itemData: [
                    //: Item type
                    {text: qsTr("-- choose type --"), value: BitSailorCore.ItemTypeNone},
                    //: Item type
                    {text: qsTr("Login"), value: BitSailorCore.ItemTypeLogin},
                    //: Item type
                    {text: qsTr("Card"), value: BitSailorCore.ItemTypeCard},
                    //: Item type
                    {text: qsTr("Note"), value: BitSailorCore.ItemTypeSecureNote},
                    //: Item type
                    //{text: qsTr("Identity"), value: BitSailorCore.ItemTypeIdentity},
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
                visible: type !== BitSailorCore.ItemTypeNone

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
                    visible: type === BitSailorCore.ItemTypeLogin
                }

                TextField {
                    property bool passwordVisible: false

                    id: loginPassword
                    label: qsTr("Password")
                    visible: type === BitSailorCore.ItemTypeLogin
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
                    visible: type === BitSailorCore.ItemTypeLogin
                }

                SectionHeader {
                    text: qsTr("URIs")
                    visible: type === BitSailorCore.ItemTypeLogin
                }

                ListModel {
                    id: urisModel

                    ListElement {
                        value: ''
                        matchType: BitSailorCore.UriMatchTypeNone
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
                            visible: page.type === BitSailorCore.ItemTypeLogin

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
                                {text: qsTr("Default match detection"), value: BitSailorCore.UriMatchTypeNone},
                                //: URI match type
                                {text: qsTr("Base domain"), value: BitSailorCore.UriMatchTypeDomain},
                                //: URI match type
                                {text: qsTr("Host"), value: BitSailorCore.UriMatchTypeHost},
                                //: URI match type
                                {text: qsTr("Starts with"), value: BitSailorCore.UriMatchTypeStartsWith},
                                //: URI match type
                                {text: qsTr("Exact"), value: BitSailorCore.UriMatchTypeExact},
                                //: URI match type
                                {text: qsTr("Regular expression"), value: BitSailorCore.UriMatchTypeRegularExpression},
                                //: URI match type
                                {text: qsTr("Never"), value: BitSailorCore.UriMatchTypeNever},
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
                    visible: type === BitSailorCore.ItemTypeLogin
                    width: parent.width - Theme.horizontalPageMargin * 2
                    onClicked: {
                        urisModel.append({value: '', matchType: BitSailorCore.UriMatchTypeNone});
                    }
                }

                SectionHeader {
                    visible: type === BitSailorCore.ItemTypeLogin
                    text: qsTr("Notes")
                }

                TextArea {
                    id: loginNotes
                    visible: type === BitSailorCore.ItemTypeLogin
                    label: qsTr("Note")
                }

                SectionHeader {
                    visible: type !== BitSailorCore.ItemTypeNone
                    text: qsTr("Custom fields")
                }

                ListModel {
                    id: customFieldsModel
                }

                Repeater {
                    id: customFieldsRepeater
                    model: customFieldsModel

                    Column {
                        width: mainColumn.width
                        visible: page.type !== BitSailorCore.ItemTypeNone
                        spacing: Theme.paddingSmall

                        Item {
                            visible: index > 0
                            width: parent.width
                            height: Theme.paddingLarge
                        }

                        Separator {
                            visible: index > 0
                            x: Theme.horizontalPageMargin
                            width: parent.width - 2 * Theme.horizontalPageMargin
                            height: 1
                            color: Theme.secondaryHighlightColor
                            opacity: Theme.opacityLow
                        }

                        TextField {
                            id: customFieldName
                            text: fieldName || ''
                            label: qsTr("Field name")

                            onTextChanged: {
                                if (index >= 0) {
                                    customFieldsModel.setProperty(index, "fieldName", text);
                                }
                            }

                            rightItem: IconButton {
                                icon.source: "image://theme/icon-splus-remove"
                                icon.color: "red"
                                onClicked: {
                                    customFieldsModel.remove(index);
                                }
                            }
                        }

                        TextField {
                            id: customFieldText
                            visible: fieldType === BitSailorCore.FieldTypeText
                            text: fieldValue || ''
                            label: qsTr("Text")

                            onTextChanged: {
                                if (index >= 0) {
                                    customFieldsModel.setProperty(index, "fieldValue", text);
                                }
                            }
                        }

                        TextField {
                            property bool passwordVisible: false

                            id: customFieldHidden
                            visible: fieldType === BitSailorCore.FieldTypeHidden
                            text: fieldValue || ''
                            label: qsTr("Hidden")
                            echoMode: passwordVisible ? TextInput.Normal : TextInput.Password

                            onTextChanged: {
                                if (index >= 0) {
                                    customFieldsModel.setProperty(index, "fieldValue", text);
                                }
                            }

                            rightItem: IconButton {
                                icon.source: customFieldHidden.passwordVisible ? "image://theme/icon-splus-hide-password" : "image://theme/icon-splus-show-password"
                                onClicked: {
                                    customFieldHidden.passwordVisible = !customFieldHidden.passwordVisible;
                                }
                            }
                        }

                        TextSwitch {
                            visible: fieldType === BitSailorCore.FieldTypeCheckbox
                            text: qsTr("Value")
                            checked: fieldChecked || false

                            onCheckedChanged: {
                                if (index >= 0) {
                                    customFieldsModel.setProperty(index, "fieldChecked", checked);
                                }
                            }
                        }

                        ComboBox {
                            id: customFieldLinkedId

                            visible: fieldType === BitSailorCore.FieldTypeLinkedId
                            label: qsTr("Linked field")

                            property var itemData: [
                                {text: qsTr("Username"), value: 100},
                                {text: qsTr("Password"), value: 101},
                            ]

                            menu: ContextMenu {
                                Components.IntValueMenuItem {text: customFieldLinkedId.itemData[0].text; value: customFieldLinkedId.itemData[0].value}
                                Components.IntValueMenuItem {text: customFieldLinkedId.itemData[1].text; value: customFieldLinkedId.itemData[1].value}
                            }

                            onCurrentItemChanged: {
                                if (index >= 0 && currentItem) {
                                    customFieldsModel.setProperty(index, "fieldLinkedId", currentItem.value);
                                }
                            }

                            Component.onCompleted: {
                                const selectedIndex = itemData.map(function(item) {
                                    return item.value;
                                }).indexOf(fieldLinkedId);
                                currentIndex = selectedIndex >= 0 ? selectedIndex : 0;
                            }
                        }
                    }
                }

                ListItem {
                    id: addCustomFieldMenuHost

                    width: parent.width
                    visible: type !== BitSailorCore.ItemTypeNone
                    contentHeight: addCustomFieldButton.height

                    Button {
                        id: addCustomFieldButton

                        text: qsTr("Add field")
                        x: Theme.horizontalPageMargin
                        width: parent.width - Theme.horizontalPageMargin * 2

                        onClicked: {
                            addCustomFieldMenuHost.openMenu();
                        }
                    }

                    menu: ContextMenu {
                        MenuItem {
                            text: qsTr("Text")

                            onClicked: {
                                page.addField(BitSailorCore.FieldTypeText);
                            }
                        }

                        MenuItem {
                            text: qsTr("Hidden")

                            onClicked: {
                                page.addField(BitSailorCore.FieldTypeHidden);
                            }
                        }

                        MenuItem {
                            text: qsTr("Boolean")

                            onClicked: {
                                page.addField(BitSailorCore.FieldTypeCheckbox);
                            }
                        }

                        MenuItem {
                            text: qsTr("Linked")
                            visible: page.type === BitSailorCore.ItemTypeLogin

                            onClicked: {
                                page.addField(BitSailorCore.FieldTypeLinkedId);
                            }
                        }
                    }
                }

                TextField {
                    id: cardCardholderName
                    label: qsTr("Cardholder Name")
                    visible: type === BitSailorCore.ItemTypeCard
                }

                ComboBox {
                    id: cardBrand
                    label: qsTr("Brand")
                    visible: type === BitSailorCore.ItemTypeCard
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
                    visible: type === BitSailorCore.ItemTypeCard
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
                    visible: type === BitSailorCore.ItemTypeCard

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
                    visible: type === BitSailorCore.ItemTypeCard
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
                    visible: type === BitSailorCore.ItemTypeCard
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
                    visible: type === BitSailorCore.ItemTypeSecureNote
                    label: qsTr("Note")
                }
            }
        }
    }

    Component.onCompleted: {
        if (initialUris.length) {
            urisModel.remove(0);
            for (var i in initialUris) {
                if (!initialUris.hasOwnProperty(i)) {
                    continue;
                }

                const uri = initialUris[i];
                urisModel.append({value: uri.uri, matchType: uri.match});
            }

            initialUris = [];
        }
        if (initialFields.length) {
            for (var j in initialFields) {
                if (!initialFields.hasOwnProperty(j)) {
                    continue;
                }

                const field = initialFields[j];
                customFieldsModel.append({
                    fieldType: field.type,
                    fieldName: field.name || '',
                    fieldValue: field.value || '',
                    fieldChecked: field.value === "true",
                    fieldLinkedId: typeof field.linkedId === 'undefined' ? null : field.linkedId
                });
            }

            initialFields = [];
        }
    }
}
