import QtQuick 2.0
import Sailfish.Silica 1.0

import cz.chrastecky.bitsailor 1.0

Page {
    property string itemId
    property var item: {type: -1}
    property bool loaded: false
    property bool pageLoaded: false
    property string errorText

    id: page
    allowedOrientations: Orientation.All

    BitwardenCli {
        id: cli

        onItemFetched: {
            loaded = true;
            page.item = item;
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
                text: item.name
                label: qsTr("Name")
                readOnly: true
                visible: item.type !== -1
            }

            TextField {
                id: usernameField
                text: item.login.username
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
                            Clipboard.text = item.login.password;
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
                model: item.login.uris

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
                id: notesTextarea
                text: item.notes
                visible: typeof item.notes !== 'undefined' && item.notes
                readOnly: true
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
                        text: field.value
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
                        text: field.linkedId
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
                visible: item.revisionDate
                font.pixelSize: Theme.fontSizeSmall
                text: qsTr("Last update: %1").arg(new Date(item.revisionDate).toLocaleString(Qt.locale(), Locale.ShortFormat))
            }
        }
    }

    onStatusChanged: {
        if (status === PageStatus.Active) {
            if (!pageLoaded) {
                cli.getItem(itemId);
            }

            pageLoaded = true;

            //app.cover = Qt.resolvedUrl("../cover/ItemDetailCoverPage.qml");
        } else {
            //app.cover = Qt.resolvedUrl("../cover/CoverPage.qml");
        }
    }
}
