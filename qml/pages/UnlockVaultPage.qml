import QtQuick 2.0
import Sailfish.Silica 1.0

import "../helpers.js" as Helpers

import cz.chrastecky.bitsailor 1.0

Dialog {
    property bool isPinEnabled: false // todo

    id: page
    allowedOrientations: Orientation.All

    canAccept: Helpers.xor(password.text.length, pin.text.length);

    BitwardenCli {
        id: cli

        onLogoutFinished: {
            pageStack.replace("LoginCheckPage.qml");
        }
    }

    SilicaFlickable {
        anchors.fill: parent
        contentHeight: column.height

        PullDownMenu {
            MenuItem {
                text: qsTr("Logout");

                onClicked: {
                    descriptionLabel.visible = false;
                    loggingOutLabel.visible = true;
                    page.canAccept = false;

                    // todo hide fields

                    cli.logout();
                }
            }
        }

        Column {
            id: column

            width: page.width
            spacing: Theme.paddingLarge
            DialogHeader {
                acceptText: qsTr("Unlock Vault")
            }

            Label {
                id: descriptionLabel

                x: Theme.horizontalPageMargin
                text: qsTr("Your vault is locked and must be unlocked before continuing.");
                color: Theme.secondaryHighlightColor
                wrapMode: Label.WordWrap
                width: parent.width - Theme.horizontalPageMargin * 2
            }

            Label {
                id: loggingOutLabel
                visible: false

                x: Theme.horizontalPageMargin
                text: qsTr("Logging out, please wait...");
                color: Theme.secondaryHighlightColor
                wrapMode: Label.WordWrap
                width: parent.width - Theme.horizontalPageMargin * 2
            }

            TextField {
                property bool passwordVisible: false

                id: password
                label: qsTr("Password")
                visible: !isPinEnabled
                echoMode: passwordVisible ? TextInput.Normal : TextInput.Password
                rightItem: IconButton {
                    icon.source: !password.passwordVisible
                                 ? "image://theme/icon-splus-hide-password"
                                 : "image://theme/icon-splus-show-password"
                    onClicked: {
                        password.passwordVisible = !password.passwordVisible;
                    }
                }

                EnterKey.iconSource: "image://theme/icon-m-enter-accept"
                EnterKey.onClicked: {
                    page.accept();
                }
            }

            TextField {
                property bool passwordVisible: false

                id: pin
                label: qsTr("PIN")
                visible: isPinEnabled
                echoMode: passwordVisible ? TextInput.Normal : TextInput.Password
                inputMethodHints: Qt.ImhDigitsOnly
                rightItem: IconButton {
                    icon.source: !pin.passwordVisible
                                 ? "image://theme/icon-splus-hide-password"
                                 : "image://theme/icon-splus-show-password"
                    onClicked: {
                        pin.passwordVisible = !pin.passwordVisible;
                    }
                }

                EnterKey.iconSource: "image://theme/icon-m-enter-accept"
                EnterKey.onClicked: {
                    page.accept();
                }
            }
        }
    }
}
