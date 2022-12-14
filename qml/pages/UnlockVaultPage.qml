import QtQuick 2.0
import Sailfish.Silica 1.0

import "../helpers.js" as Helpers

import cz.chrastecky.bitsailor 1.0

Dialog {
    property bool isPinEnabled: secrets.hasPin()
    property bool systemAuthEnabled: settings.useSystemAuth
    property string error: ""

    property string passwordText: password.text
    property int pinText: Number(pin.text)
    property bool systemAuthSucceeded: false

    id: page
    allowedOrientations: Orientation.All

    canAccept: Helpers.xor(password.text.length, pin.text.length);

    BitwardenCli {
        id: cli

        onLogoutFinished: {
            pageStack.replace("LoginCheckPage.qml");
        }
    }

    SecretsHandler {
        id: secrets
    }

    SystemAuthChecker {
        id: systemAuthChecker

        onAuthResolved: {
            if (success) {
                systemAuthSucceeded = true;
                canAccept = true;
                page.accept();
            } else {
                error = qsTr("OS authorization failed");
            }
        }
    }

    SilicaFlickable {
        anchors.fill: parent
        contentHeight: column.height

        PullDownMenu {
            MenuItem {
                text: qsTr("Logout");

                onClicked: {
                    loggingOutLabel.visible = true;

                    descriptionLabel.visible = false;
                    page.canAccept = false;
                    password.visible = false
                    pin.visible = false;
                    errorLabel.visible = false;

                    cli.logout();
                }
            }
        }

        Column {
            id: column

            width: page.width
            spacing: Theme.paddingLarge
            DialogHeader {
                //: Dialog accept text
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


            Label {
                id: errorLabel
                visible: error.length

                x: Theme.horizontalPageMargin
                text: error;
                color: Theme.errorColor
                wrapMode: Label.WordWrap
                width: parent.width - Theme.horizontalPageMargin * 2
            }

            TextField {
                property bool passwordVisible: false

                id: password
                label: qsTr("Password")
                visible: !isPinEnabled && !systemAuthEnabled
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

            Row {
                visible: isPinEnabled
                anchors.horizontalCenter: parent.horizontalCenter

                Button {
                    text: qsTr("Reset PIN")
                    onClicked: {
                        const dialog = pageStack.push("ResetAuthStylePage.qml", {
                            infoText: qsTr("The PIN will be deleted and you can unlock the vault using your password. Once you unlock your vault you can set a PIN code again."),
                        });
                        dialog.accepted.connect(function() {
                            secrets.removePin();
                            secrets.removePassword();
                            isPinEnabled = secrets.hasPin();
                        });
                    }
                }
            }

            Row {
                visible: systemAuthEnabled
                anchors.horizontalCenter: parent.horizontalCenter

                Button {
                    text: qsTr("Try again")
                    onClicked: {
                        systemAuthChecker.checkAuth();
                    }
                }

                Button {
                    text: qsTr("Reset OS Authorization")
                    onClicked: {
                        const dialog = pageStack.push("ResetAuthStylePage.qml", {
                            infoText: qsTr("OS authorization will be disabled and you can unlock the vault using your password. Once you unlock your vault you can enable OS authorization again."),
                        });
                        dialog.accepted.connect(function() {
                            secrets.removePassword();
                            settings.useSystemAuth = false;
                        });
                    }
                }
            }
        }
    }

    Component.onCompleted: {
        if (settings.useSystemAuth) {
            systemAuthChecker.checkAuth();
        }
    }

    onRejected: {
        Qt.quit();
    }
}
