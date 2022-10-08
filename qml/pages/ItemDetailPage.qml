import QtQuick 2.0
import Sailfish.Silica 1.0

import cz.chrastecky.bitsailor 1.0

import "../helpers.js" as Helpers
import "../components" as Components

Page {
    property string itemId
    property var item: {type: BitwardenCli.NoType}
    property bool loaded: false
    property bool pageLoaded: false
    property string errorText

    id: page
    allowedOrientations: Orientation.All

    function createCover() {
        var pageName = 'CoverPage.qml';

        if (item.type === BitwardenCli.Login) {
            pageName = 'CoverPageLogin.qml';
            if (item.login !== 'undefined' && item.login.totp) {
                pageName = 'CoverPageLoginTotp.qml';
            }
        } else if(item.type === BitwardenCli.SecureNote) {
            pageName = 'CoverPageNote.qml';
        } else if(item.type === BitwardenCli.Card) {
            pageName = 'CoverPageCard.qml';
        }

        const cover = Qt.createComponent("../cover/" + pageName).createObject(app, {
            item: {
                type: item.type,
                name: item.name,
                username: typeof item.login !== 'undefined' && typeof item.login.username !== 'undefined' ? item.login.username : null,
                password: typeof item.login !== 'undefined' && typeof item.login.username !== 'undefined' ? item.login.password : null,
                totp: typeof item.login !== 'undefined' && item.login.totp ? Helpers.getTotp(item.login.totp) : null,
                note: typeof item.notes !== 'undefined' ? item.notes : null,
                cardNumber: typeof item.card !== 'undefined' && typeof item.card.number !== 'undefined' ? item.card.number : null,
                securityCode: typeof item.card !== 'undefined' && typeof item.card.code !== 'undefined' ? item.card.code : null,
                expiration: typeof item.card !== 'undefined' && item.card.expMonth && item.card.expYear ? String("0" + item.card.expMonth).slice(-2) + "/" + item.card.expYear : null,
            }
        });
        app.cover = cover;
    }

    BitwardenCli {
        id: cli

        onItemFetched: {
            if (isDebug) {
                console.log(JSON.stringify(item));
            }

            page.item = item;
            loaded = true;
            createCover();
        }

        onItemFetchingFailed: {
            loaded = true;
            errorText = qsTr("Failed loading the item, please try again later or sync your vault and check that it wasn't deleted.");
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
                visible: item.type !== BitwardenCli.NoType
            }

            TextField {
                id: usernameField
                text: visible ? item.login.username : ''
                label: qsTr("Username")
                visible: item.type === BitwardenCli.Login && typeof item.login !== 'undefined' && item.login.username
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

                label: qsTr("Identity Name")
                visible: item.type === BitwardenCli.Identity && (item.identity.title || item.identity.firstName || item.identity.middleName || item.identity.lastName)
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
                visible: item.type === BitwardenCli.Identity && item.identity.username
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
                visible: item.type === BitwardenCli.Identity && item.identity.company
                readOnly: true
                rightItem: IconButton {
                    icon.source: "image://theme/icon-m-clipboard"
                    onClicked: {
                        Clipboard.text = item.login.company;
                        app.toaster.show(qsTr("Copied to clipboard"));
                    }
                }
            }

            TextField {
                id: socialSecurityNumberField
                text: visible ? item.identity.ssn : '';
                //: Translate as local equivalent, see https://en.wikipedia.org/wiki/National_identification_number
                label: qsTr("Social Security Number")
                visible: item.type === BitwardenCli.Identity && item.identity.ssn
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
                visible: item.type === BitwardenCli.Identity && item.identity.passportNumber
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
                visible: item.type === BitwardenCli.Identity && item.identity.licenseNumber
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
                visible: item.type === BitwardenCli.Identity && item.identity.email
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
                visible: item.type === BitwardenCli.Identity && item.identity.phone
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
                visible: item.type === BitwardenCli.Identity && (item.identity.address1 || item.identity.address2 || item.identity.address3 || item.identity.city || item.identity.country || item.identity.postalCode || item.identity.state)
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
                property bool passwordVisible: false

                id: passwordField
                text: passwordVisible ? item.login.password : 'aaaa aaaa aaaa'
                label: qsTr("Password")
                visible: item.type === BitwardenCli.Login && typeof item.login !== 'undefined'
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
                            Clipboard.text = addressField.text;
                            app.toaster.show(qsTr("Copied to clipboard"));
                        }
                    }
                }
            }

            TextField {
                property bool isActive: typeof item.login !== 'undefined' && typeof item.login.totp !== 'undefined' && item.login.totp

                id: totpField
                text: loaded && isActive ? Helpers.getTotp(item.login.totp).match(/.{1,3}/g).join(' ') : ''
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
                                totpField.text = Helpers.getTotp(item.login.totp).match(/.{1,3}/g).join(' ');
                                createCover();
                                //start(Helpers.totpRemainingTime(30), 30);
                            }
                        }
                    }

                    IconButton {
                        icon.source: "image://theme/icon-m-clipboard"
                        onClicked: {
                            Clipboard.text = Helpers.getTotp(item.login.totp);
                            app.toaster.show(qsTr("Copied to clipboard"));
                        }
                    }
                }
            }


            TextField {
                text: visible ? item.card.cardholderName : ''
                label: qsTr("Cardholder Name")
                visible: item.type === BitwardenCli.Card && typeof item.card !== 'undefined' && item.card.cardholderName
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
                visible: item.type === BitwardenCli.Card && typeof item.card !== 'undefined' && item.card.brand
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
                visible: item.type === BitwardenCli.Card && typeof item.card !== 'undefined' && item.card.number
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
                visible: item.type === BitwardenCli.Card && typeof item.card !== 'undefined' && item.card.expMonth && item.card.expYear
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
                visible: item.type === BitwardenCli.Card && typeof item.card !== 'undefined' && item.card.code
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

                visible: item.type === BitwardenCli.Login && typeof item.login !== 'undefined' && typeof item.login.uris !== 'undefined' && item.login.uris.length
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
                property bool passwordEnabled: item.type === BitwardenCli.SecureNote
                property bool passwordVisible: item.type !== BitwardenCli.SecureNote

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
                        visible: field.type === BitwardenCli.FieldTypeText
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
                        visible: field.type === BitwardenCli.FieldTypeLinked
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
                        visible: field.type === BitwardenCli.FieldTypeHidden
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
                        visible: field.type === BitwardenCli.FieldTypeBoolean
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
                cli.getItem(itemId);
            }

            pageLoaded = true;
        } else {
            app.cover = Qt.resolvedUrl("../cover/CoverPage.qml");
        }
    }
}
