import QtQuick 2.0
import Sailfish.Silica 1.0

import "../helpers.js" as Helpers

Dialog {
    property string emailText
    property string passwordText
    property string clientIdText
    property string clientSecretText

    property bool error: false

    id: page
    allowedOrientations: Orientation.All
    canAccept: Helpers.xor(emailText.length && passwordText.length, clientIdText.length && clientSecretText.length)

    SilicaFlickable {
        anchors.fill: parent
        contentHeight: column.height

        Column {
            id: column

            width: page.width
            spacing: Theme.paddingLarge

            DialogHeader {
                acceptText: qsTr("Login")
            }

            Label {
                text: qsTr("The credentials you provided are incorrect. Please try again.");
                color: Theme.errorColor
                width: parent.width - Theme.horizontalPageMargin * 2
                wrapMode: Label.WordWrap
                x: Theme.horizontalPageMargin
                visible: page.error
            }

            ExpandingSectionGroup {
                currentIndex: -1

                ExpandingSection {
                    title: qsTr("Email & password");

                    content.sourceComponent: Column {
                        Label {
                            text: qsTr("If you have 2FA activated, please login using api key and not email and password. See <a href='%1'>Bitwarden help</a> for more information.").arg("https://bitwarden.com/help/personal-api-key/");
                            color: Theme.highlightColor
                            width: parent.width - Theme.horizontalPageMargin * 2
                            wrapMode: Label.WordWrap
                            x: Theme.horizontalPageMargin
                            font.pixelSize: Theme.fontSizeSmall
                            linkColor: Theme.lightPrimaryColor
                        }

                        SectionHeader {}

                        TextField {
                            id: email
                            label: qsTr("Email")

                            EnterKey.iconSource: "image://theme/icon-m-enter-next"
                            EnterKey.onClicked: {
                                password.focus = true;
                            }

                            onTextChanged: {
                                emailText = text;
                            }
                        }

                        TextField {
                            property bool passwordVisible: false

                            id: password
                            label: qsTr("Password")
                            echoMode: passwordVisible ? TextInput.Normal : TextInput.Password
                            rightItem: IconButton {
                                icon.source: !password.passwordVisible
                                             ? "image://theme/icon-splus-hide-password"
                                             : "image://theme/icon-splus-show-password"
                                onClicked: {
                                    password.passwordVisible = !password.passwordVisible;
                                }
                            }

                            onTextChanged: {
                                passwordText = text;
                            }

                            EnterKey.iconSource: "image://theme/icon-m-enter-accept"
                            EnterKey.onClicked: {
                                page.accept();
                            }
                        }
                    }
                }

                ExpandingSection {
                    title: qsTr("API key");

                    content.sourceComponent: Column {
                        Label {
                            text: qsTr("See <a href='%1'>Bitwarden help</a> for information on how to create an api key.").arg("https://bitwarden.com/help/personal-api-key/");
                            color: Theme.highlightColor
                            width: parent.width - Theme.horizontalPageMargin * 2
                            wrapMode: Label.WordWrap
                            x: Theme.horizontalPageMargin
                            font.pixelSize: Theme.fontSizeSmall
                            linkColor: Theme.lightPrimaryColor
                        }

                        SectionHeader {}

                        TextField {
                            id: clientId
                            label: qsTr("Client ID")

                            onTextChanged: {
                                clientIdText = text;
                            }

                            EnterKey.iconSource: "image://theme/icon-m-enter-next"
                            EnterKey.onClicked: {
                                clientSecret.focus = true;
                            }
                        }

                        TextField {
                            property bool passwordVisible: false

                            id: clientSecret
                            label: qsTr("Client Secret")
                            echoMode: passwordVisible ? TextInput.Normal : TextInput.Password
                            rightItem: IconButton {
                                icon.source: !clientSecret.passwordVisible
                                             ? "image://theme/icon-splus-hide-password"
                                             : "image://theme/icon-splus-show-password"
                                onClicked: {
                                    clientSecret.passwordVisible = !clientSecret.passwordVisible;
                                }
                            }

                            onTextChanged: {
                                clientSecretText = text;
                            }

                            EnterKey.iconSource: "image://theme/icon-m-enter-accept"
                            EnterKey.onClicked: {
                                page.accept();
                            }
                        }
                    }
                }
            }
        }
    }

    onRejected: {
        Qt.quit();
    }
}
