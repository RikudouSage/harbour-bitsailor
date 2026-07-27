import QtQuick 2.0
import Sailfish.Silica 1.0

import cz.chrastecky.bitsailor 1.0

import "../helpers.js" as Helpers
import "../components" as Components

Page {
    property string itemId
    property var item: {type: BitSailorCore.ItemTypeNone;}
    property bool loaded: false
    property bool pageLoaded: false
    property string errorText

    id: page
    allowedOrientations: Orientation.All

    function reloadPage() {
        core.fetchItem(itemId)
    }

    function createCover() {
        item.metadata = {};
        if (item.type === BitSailorCore.ItemTypeLogin && item.login.totp) {
            item.metadata.totp = otpGenerator.generateTotpSafe(item.login.totp);
        }
        app.cover.item = item;
    }

    function onItemFetched(item) {
        if (isDebug) {
            console.log(JSON.stringify(item));
        }

        page.item = item;
        loaded = true;
        createCover();
    }

    function onItemFetchingFailed() {
        loaded = true;
        errorText = qsTr("Failed loading the item, please try again later or sync your vault and check that it wasn't deleted.");
    }

    OneTimePasswordGenerator {
        id: otpGenerator

        function generateTotpSafe(totpData) {
            var secret = totpData;
            var digits = 6;
            var hash = "SHA1";

            const url = urlParser.parse(totpData);
            if (url.scheme === "otpauth" && url.host === "totp") {
                secret = url.query("secret");
                digits = Number(url.query("digits") || 6);
                hash = url.query("algorithm") || "SHA1";
            }

            return generateTOTP(secret, digits, hash);
        }
    }

    Connections {
        target: core

        onItemFetchFinished: {
            if (!success) {
                page.onItemFetchingFailed();
                return;
            }

            page.onItemFetched(item);
        }

        onItemUpdated: {
            if (page.status !== PageStatus.Active && page.status !== PageStatus.Activating) {
                return;
            }

            if (success) {
                reloadPage();
            } else {
                loaded = true;
                errorText = qsTr("There was an error when updating the item");
            }
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

        PullDownMenu {
            MenuItem {
                //: Pull down menu in detail
                text: qsTr("Edit")
                onClicked: {
                    const values = {
                        type: item.type,
                        nameValue: item.name,
                        typeEditable: false,
                        //: Accept button for updating an item
                        acceptText: qsTr("Update"),
                    };

                    if (item.type === BitSailorCore.ItemTypeLogin) {
                        values.loginUsernameValue = item.login.username;
                        values.loginPasswordValue = item.login.password;
                        values.loginTotpValue = item.login.totp;
                        values.loginNotesValue = item.notes;
                        values.initialUris = item.login.uris;
                    }
                    if (item.type === BitSailorCore.ItemTypeCard) {
                        values.cardCardholderNameValue = item.card.cardholderName;
                        values.cardBrandValue = item.card.brand;
                        values.cardNumberValue = item.card.number;
                        values.cardExpirationMonthValue = item.card.expMonth;
                        values.cardExpirationYearValue = item.card.expYear;
                        values.cardCvvValue = item.card.code;
                    }
                    if (item.type === BitSailorCore.ItemTypeSecureNote) {
                        values.secureNoteNoteValue = item.notes;
                    }

                    const dialog = pageStack.push("EditItemPage.qml", values);
                    // todo deduplicate with VaultPage
                    dialog.accepted.connect(function() {
                        const object = page.item;
                        const type = dialog.type;
                        switch (type) {
                        case BitSailorCore.ItemTypeLogin:
                            object.login = JSON.parse(JSON.stringify(dialog.loginItemTemplate));
                            object.login.password = dialog.loginPasswordValue || null;
                            object.login.totp = dialog.loginTotpValue || null;
                            object.login.username = dialog.loginUsernameValue || null;
                            object.login.uris = dialog.getUris() || null;
                            break;
                        case BitSailorCore.ItemTypeSecureNote:
                            object.secureNote = JSON.parse(JSON.stringify(dialog.secureNoteItemTemplate));
                            break;
                        case BitSailorCore.ItemTypeCard:
                            object.card = JSON.parse(JSON.stringify(dialog.cardItemTemplate));
                            object.card.cardholderName = dialog.cardCardholderNameValue || null;
                            object.card.brand = dialog.cardBrandValue || null;
                            object.card.number = dialog.cardNumberValue || null;
                            object.card.expMonth = dialog.cardExpirationMonthValue || null;
                            object.card.expYear = dialog.cardExpirationYearValue || null;
                            object.card.code = dialog.cardCvvValue || null
                            break;
                        }

                        object.type = dialog.type;
                        object.name = dialog.nameValue;
                        object.notes = dialog.loginNotesValue || dialog.secureNoteNoteValue || null;

                        loaded = false;
                        errorText = "";
                        core.updateItem(page.itemId, object);
                    });
                }
            }
        }

        VerticalScrollDecorator {}

        Column {
            id: column

            width: page.width
            spacing: Theme.paddingLarge
            PageHeader {
                //: Page title
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

            SectionHeader {
                text: qsTr("Item info")
            }

            TextField {
                text: visible ? item.name : ''
                label: qsTr("Name")
                readOnly: true
                visible: item.type !== BitSailorCore.ItemTypeNone
            }

            TextField {
                id: usernameField
                text: visible ? item.login.username : ''
                label: qsTr("Username")
                visible: item.type === BitSailorCore.ItemTypeLogin && typeof item.login !== 'undefined' && item.login.username
                readOnly: true
                rightItem: IconButton {
                    icon.source: "image://theme/icon-m-clipboard"
                    onClicked: {
                        Clipboard.text = item.login.username;
                        app.toaster.show(qsTr("Copied to clipboard"));
                    }
                }
            }

            TextField {
                id: nameField
                text: {
                    if (!visible) {
                        return '';
                    }

                    var text = '';
                    if (item.identity.title) {
                        text += item.identity.title + " ";
                    }
                    if (item.identity.firstName) {
                        text += item.identity.firstName + " ";
                    }
                    if (item.identity.middleName) {
                        text += item.identity.middleName + " ";
                    }
                    if (item.identity.lastName) {
                        text += item.identity.lastName + " ";
                    }
                    text = text.slice(0, -1);

                    return text;
                }
                //: Name as in "person's name", this text is taken from Android Bitwarden app and seems wrong, will probably be reworded in future
                label: qsTr("Identity Name")
                visible: item.type === BitSailorCore.ItemTypeIdentity && (item.identity.title || item.identity.firstName || item.identity.middleName || item.identity.lastName)
                readOnly: true
                rightItem: IconButton {
                    icon.source: "image://theme/icon-m-clipboard"
                    onClicked: {
                        Clipboard.text = nameField.text;
                        app.toaster.show(qsTr("Copied to clipboard"));
                    }
                }
            }

            TextField {
                id: usernameFieldIdentity
                text: visible ? item.identity.username : '';
                label: qsTr("Username")
                visible: item.type === BitSailorCore.ItemTypeIdentity && item.identity.username
                readOnly: true
                rightItem: IconButton {
                    icon.source: "image://theme/icon-m-clipboard"
                    onClicked: {
                        Clipboard.text = item.identity.username;
                        app.toaster.show(qsTr("Copied to clipboard"));
                    }
                }
            }

            TextField {
                id: companyField
                text: visible ? item.identity.company : '';
                label: qsTr("Company")
                visible: item.type === BitSailorCore.ItemTypeIdentity && item.identity.company
                readOnly: true
                rightItem: IconButton {
                    icon.source: "image://theme/icon-m-clipboard"
                    onClicked: {
                        Clipboard.text = item.identity.company;
                        app.toaster.show(qsTr("Copied to clipboard"));
                    }
                }
            }

            TextField {
                id: socialSecurityNumberField
                text: visible ? item.identity.ssn : '';
                //: Translate as local equivalent, see https://en.wikipedia.org/wiki/National_identification_number
                label: qsTr("Social Security Number")
                visible: item.type === BitSailorCore.ItemTypeIdentity && item.identity.ssn
                readOnly: true
                rightItem: IconButton {
                    icon.source: "image://theme/icon-m-clipboard"
                    onClicked: {
                        Clipboard.text = item.identity.ssn;
                        app.toaster.show(qsTr("Copied to clipboard"));
                    }
                }
            }

            TextField {
                id: passportNumberField
                text: visible ? item.identity.passportNumber : '';
                label: qsTr("Passport Number")
                visible: item.type === BitSailorCore.ItemTypeIdentity && item.identity.passportNumber
                readOnly: true
                rightItem: IconButton {
                    icon.source: "image://theme/icon-m-clipboard"
                    onClicked: {
                        Clipboard.text = item.identity.passportNumber;
                        app.toaster.show(qsTr("Copied to clipboard"));
                    }
                }
            }

            TextField {
                id: licenseNumberField
                text: visible ? item.identity.licenseNumber : '';
                //: Translate as local equivalent, for example "ID card number"
                label: qsTr("License Number")
                visible: item.type === BitSailorCore.ItemTypeIdentity && item.identity.licenseNumber
                readOnly: true
                rightItem: IconButton {
                    icon.source: "image://theme/icon-m-clipboard"
                    onClicked: {
                        Clipboard.text = item.identity.licenseNumber;
                        app.toaster.show(qsTr("Copied to clipboard"));
                    }
                }
            }

            TextField {
                id: emailField
                text: visible ? item.identity.email : '';
                label: qsTr("Email")
                visible: item.type === BitSailorCore.ItemTypeIdentity && item.identity.email
                readOnly: true
                rightItem: IconButton {
                    icon.source: "image://theme/icon-m-clipboard"
                    onClicked: {
                        Clipboard.text = item.identity.email;
                        app.toaster.show(qsTr("Copied to clipboard"));
                    }
                }
            }

            TextField {
                id: phoneField
                text: visible ? item.identity.phone : '';
                //: Phone number
                label: qsTr("Phone")
                visible: item.type === BitSailorCore.ItemTypeIdentity && item.identity.phone
                readOnly: true
                rightItem: IconButton {
                    icon.source: "image://theme/icon-m-clipboard"
                    onClicked: {
                        Clipboard.text = item.identity.phone;
                        app.toaster.show(qsTr("Copied to clipboard"));
                    }
                }
            }

            TextArea {
                id: addressField
                text: {
                    if (!visible) {
                        return '';
                    }

                    var text = '';
                    if (item.identity.address1) {
                        text += item.identity.address1 + "\n";
                    }
                    if (item.identity.address2) {
                        text += item.identity.address2 + "\n";
                    }
                    if (item.identity.address3) {
                        text += item.identity.address3 + "\n";
                    }

                    var city = '';
                    if (item.identity.city) {
                        city += item.identity.city + ", ";
                    }
                    if (item.identity.state) {
                        city += item.identity.state + ", ";
                    }
                    if (item.identity.postalCode) {
                        city += item.identity.postalCode + ", ";
                    }
                    city = city.slice(0, -2);

                    if (city) {
                        text += city + "\n";
                    }

                    if (item.identity.country) {
                        text += item.identity.country + "\n";
                    }

                    text = text.slice(0, -1);

                    return text;
                }

                label: qsTr("Address")
                visible: item.type === BitSailorCore.ItemTypeIdentity && (item.identity.address1 || item.identity.address2 || item.identity.address3 || item.identity.city || item.identity.country || item.identity.postalCode || item.identity.state)
                readOnly: true
                rightItem: IconButton {
                    icon.source: "image://theme/icon-m-clipboard"
                    onClicked: {
                        Clipboard.text = addressField.text;
                        app.toaster.show(qsTr("Copied to clipboard"));
                    }
                }
            }

            TextField {
                property bool passwordVisible: false

                id: passwordField
                text: passwordVisible ? item.login.password : 'aaaa aaaa aaaa'
                label: qsTr("Password")
                visible: item.type === BitSailorCore.ItemTypeLogin && typeof item.login !== 'undefined'
                echoMode: passwordVisible ? TextInput.Normal : TextInput.Password
                readOnly: true

                rightItem: Row {
                    IconButton {
                        icon.source: passwordField.passwordVisible ? "image://theme/icon-splus-hide-password" : "image://theme/icon-splus-show-password"
                        onClicked: {
                            passwordField.passwordVisible = !passwordField.passwordVisible;
                        }
                    }
                    IconButton {
                        icon.source: "image://theme/icon-m-clipboard"
                        onClicked: {
                            Clipboard.text = item.login.password;
                            app.toaster.show(qsTr("Copied to clipboard"));
                        }
                    }
                }
            }

            TextField {
                property bool isActive: typeof item.login !== 'undefined' && typeof item.login.totp !== 'undefined' && item.login.totp

                id: totpField
                text: loaded && isActive ? otpGenerator.generateTotpSafe(item.login.totp).match(/.{1,3}/g).join(' ') : ''
                label: qsTr("Verification Code (TOTP)")
                visible: isActive
                readOnly: true

                rightItem: Row {
                    Components.PercentageCircle {
                        id: circle
                        y: height

                        Component.onCompleted: {
                            start(Helpers.totpRemainingTime(30), 30);
                        }

                        onFinished: {
                            if (totpField.isActive) {
                                totpField.text = otpGenerator.generateTotpSafe(item.login.totp).match(/.{1,3}/g).join(' ');
                                createCover();
                                //start(Helpers.totpRemainingTime(30), 30);
                            }
                        }
                        onTick: {
                            if (totpField.isActive) {
                                totpField.text = otpGenerator.generateTotpSafe(item.login.totp).match(/.{1,3}/g).join(' ');
                            }
                        }
                    }

                    IconButton {
                        icon.source: "image://theme/icon-m-clipboard"
                        onClicked: {
                            Clipboard.text = otpGenerator.generateTotpSafe(item.login.totp);
                            app.toaster.show(qsTr("Copied to clipboard"));
                        }
                    }
                }
            }


            TextField {
                text: visible ? item.card.cardholderName : ''
                label: qsTr("Cardholder Name")
                visible: item.type === BitSailorCore.ItemTypeCard && typeof item.card !== 'undefined' && item.card.cardholderName
                readOnly: true
                rightItem: IconButton {
                    icon.source: "image://theme/icon-m-clipboard"
                    onClicked: {
                        Clipboard.text = item.card.cardholderName;
                        app.toaster.show(qsTr("Copied to clipboard"));
                    }
                }
            }

            TextField {
                text: visible ? item.card.brand : ''
                label: qsTr("Brand")
                visible: item.type === BitSailorCore.ItemTypeCard && typeof item.card !== 'undefined' && item.card.brand
                readOnly: true
                rightItem: IconButton {
                    icon.source: "image://theme/icon-m-clipboard"
                    onClicked: {
                        Clipboard.text = item.card.brand;
                        app.toaster.show(qsTr("Copied to clipboard"));
                    }
                }
            }

            TextField {
                property bool passwordVisible: false

                id: cardNumberField
                text: passwordVisible ? item.card.number : 'aaaabbbbccccdddd'
                label: qsTr("Card Number")
                visible: item.type === BitSailorCore.ItemTypeCard && typeof item.card !== 'undefined' && item.card.number
                echoMode: passwordVisible ? TextInput.Normal : TextInput.Password
                readOnly: true

                rightItem: Row {
                    IconButton {
                        icon.source: cardNumberField.passwordVisible ? "image://theme/icon-splus-hide-password" : "image://theme/icon-splus-show-password"
                        onClicked: {
                            cardNumberField.passwordVisible = !cardNumberField.passwordVisible;
                        }
                    }
                    IconButton {
                        icon.source: "image://theme/icon-m-clipboard"
                        onClicked: {
                            Clipboard.text = item.card.number;
                            app.toaster.show(qsTr("Copied to clipboard"));
                        }
                    }
                }
            }

            TextField {
                text: visible ? String("0" + item.card.expMonth).slice(-2) + " / " + item.card.expYear : ''
                label: qsTr("Expiration")
                visible: item.type === BitSailorCore.ItemTypeCard && typeof item.card !== 'undefined' && item.card.expMonth && item.card.expYear
                readOnly: true
                rightItem: IconButton {
                    icon.source: "image://theme/icon-m-clipboard"
                    onClicked: {
                        Clipboard.text = String("0" + item.card.expMonth).slice(-2) + "/" + item.card.expYear;
                        app.toaster.show(qsTr("Copied to clipboard"));
                    }
                }
            }

            TextField {
                property bool passwordVisible: false

                id: cvvField
                text: passwordVisible ? item.card.code : 'aaa'
                label: qsTr("Security Code (CVV)")
                visible: item.type === BitSailorCore.ItemTypeCard && typeof item.card !== 'undefined' && item.card.code
                echoMode: passwordVisible ? TextInput.Normal : TextInput.Password
                readOnly: true

                rightItem: Row {
                    IconButton {
                        icon.source: cvvField.passwordVisible ? "image://theme/icon-splus-hide-password" : "image://theme/icon-splus-show-password"
                        onClicked: {
                            cvvField.passwordVisible = !cvvField.passwordVisible;
                        }
                    }
                    IconButton {
                        icon.source: "image://theme/icon-m-clipboard"
                        onClicked: {
                            Clipboard.text = item.card.code;
                            app.toaster.show(qsTr("Copied to clipboard"));
                        }
                    }
                }
            }

            SectionHeader {
                text: qsTr("URIs")
                visible: urisRepeater.visible
            }

            Repeater {
                id: urisRepeater

                visible: item.type === BitSailorCore.ItemTypeLogin && typeof item.login !== 'undefined' && typeof item.login.uris !== 'undefined' && item.login.uris.length
                model: visible ? item.login.uris : []

                delegate: TextField {
                    property var uri: urisRepeater.model[index]

                    id: uriField
                    text: uri.uri
                    label: uri.uri.indexOf('http://') === 0 || uri.uri.indexOf('https://') === 0 ? qsTr("Website") : qsTr("URI")
                    readOnly: true
                    rightItem: Row {
                        IconButton {
                            icon.source: "image://theme/icon-m-website"
                            onClicked: {
                                Qt.openUrlExternally(uri.uri);
                            }
                        }
                        IconButton {
                            icon.source: "image://theme/icon-m-clipboard"
                            onClicked: {
                                Clipboard.text = uri.uri;
                                app.toaster.show(qsTr("Copied to clipboard"));
                            }
                        }
                    }
                }
            }

            SectionHeader {
                text: qsTr("Notes")
                visible: notesTextarea.visible
            }

            TextArea {
                property bool passwordEnabled: item.type === BitSailorCore.ItemTypeSecureNote
                property bool passwordVisible: item.type !== BitSailorCore.ItemTypeSecureNote

                id: notesTextarea
                text: visible ? (passwordVisible ? item.notes : '••••••••••••••••') : ''
                visible: typeof item.notes !== 'undefined' && item.notes
                readOnly: true

                rightItem: Row {
                    visible: notesTextarea.passwordEnabled

                    IconButton {
                        icon.source: notesTextarea.passwordVisible ? "image://theme/icon-splus-hide-password" : "image://theme/icon-splus-show-password"
                        onClicked: {
                            notesTextarea.passwordVisible = !notesTextarea.passwordVisible;
                        }
                    }
                    IconButton {
                        icon.source: "image://theme/icon-m-clipboard"
                        onClicked: {
                            Clipboard.text = item.notes;
                            app.toaster.show(qsTr("Copied to clipboard"));
                        }
                    }
                }
            }

            SectionHeader {
                text: qsTr("Custom fields")
                visible: customFieldsRepeater.visible
            }

            Repeater {
                id: customFieldsRepeater

                visible: typeof item.fields !== 'undefined' && item.fields.length
                model: item.fields

                delegate: Row {
                    property var field: customFieldsRepeater.model[index]
                    width: page.width

                    TextField {
                        id: fieldText
                        visible: field.type === BitSailorCore.FieldTypeText
                        label: field.name
                        text: visible ? field.value : ''
                        readOnly: true

                        rightItem: IconButton {
                            icon.source: "image://theme/icon-m-clipboard"
                            onClicked: {
                                Clipboard.text = fieldText.text;
                                app.toaster.show(qsTr("Copied to clipboard"));
                            }
                        }
                    }

                    TextField {
                        id: fieldLinked
                        visible: field.type === BitSailorCore.FieldTypeLinkedId
                        label: field.name
                        text: visible ? field.linkedId : ''
                        readOnly: true
                        description: qsTr("Linked fields are not supported properly because the official documentation is missing. Will be updated in the future.")
                    }

                    TextField {
                        property bool passwordVisible: false

                        id: fieldHidden
                        text: passwordVisible ? field.value : 'aaaa aaaa aaaa'
                        label: field.name
                        visible: field.type === BitSailorCore.FieldTypeHidden
                        echoMode: passwordVisible ? TextInput.Normal : TextInput.Password
                        readOnly: true

                        rightItem: Row {
                            IconButton {
                                icon.source: fieldHidden.passwordVisible ? "image://theme/icon-splus-hide-password" : "image://theme/icon-splus-show-password"
                                onClicked: {
                                    fieldHidden.passwordVisible = !fieldHidden.passwordVisible;
                                }
                            }
                            IconButton {
                                icon.source: "image://theme/icon-m-clipboard"
                                onClicked: {
                                    Clipboard.text = field.value;
                                    app.toaster.show(qsTr("Copied to clipboard"));
                                }
                            }
                        }
                    }

                    Item {
                        width: parent.width
                        visible: field.type === BitSailorCore.FieldTypeCheckbox
                        x: Theme.horizontalPageMargin
                        height: Math.max(fieldBooleanField.height, fieldBooleanIcon.height)

                        Icon {
                            id: fieldBooleanIcon
                            property string iconName: field.value === 'true' ? "icon-s-accept" : "icon-s-decline"
                            source: "image://theme/" + iconName
                            anchors.left: parent.left
                            anchors.leftMargin: Theme.horizontalPageMargin
                        }
                        TextField {
                            id: fieldBooleanField
                            label: field.name
                            readOnly: true
                            text: ' '
                            anchors.left: parent.left
                        }
                    }
                }
            }

            Label {
                x: Theme.horizontalPageMargin
                color: Theme.secondaryHighlightColor
                wrapMode: Label.WordWrap
                width: parent.width - Theme.horizontalPageMargin * 2
                visible: typeof item.revisionDate !== 'undefined'
                font.pixelSize: Theme.fontSizeSmall
                text: qsTr("Last update: %1").arg(new Date(item.revisionDate).toLocaleString(Qt.locale(), Locale.ShortFormat))
            }

            Item {
                width: parent.width
                height: Theme.paddingSmall
            }
        }
    }

    onStatusChanged: {
        if (status === PageStatus.Active) {
            if (!pageLoaded) {
                reloadPage();
            }

            pageLoaded = true;
        } else {
            app.cover.item = {type: BitSailorCore.ItemTypeNone};
        }
    }
}
