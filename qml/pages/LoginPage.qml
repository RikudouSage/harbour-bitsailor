import QtQuick 2.0
import Sailfish.Silica 1.0

import cz.chrastecky.bitsailor 1.0;

import "../helpers.js" as Helpers

Dialog {
    property alias currentTab: sectionWrapper.currentIndex

    property string emailText
    property string passwordText
    property string clientIdText
    property string clientSecretText
    property string customServerUrl
    property string twoFaCode
    property bool twoFaFlow: false

    property string error

    property var doAfterLoad: []

    id: page
    allowedOrientations: Orientation.All
    canAccept: Helpers.xor(emailText.length && passwordText.length, clientIdText.length && clientSecretText.length)

    SilicaFlickable {
        anchors.fill: parent
        contentHeight: column.height

        PullDownMenu {
            MenuItem {
                text: qsTr("Clean Up Data")
                onClicked: {
                    const dialog = pageStack.push("ConfirmSettingPage.qml", {
                        description: qsTr("This will delete everything that this app stores on your system, including system secrets collection, temporary files etc. Do you wish to continue?")
                    });
                    dialog.accepted.connect(function() {
                        doAfterLoad.push(function() {
                            pageStack.replaceAbove(null, "CleanupPage.qml");
                        });
                    });
                }
            }
        }

        Column {
            id: column

            width: page.width
            spacing: Theme.paddingLarge

            DialogHeader {
                //: Dialog accept text
                acceptText: qsTr("Login")
            }

            Label {
                text: page.error;
                color: Theme.errorColor
                width: parent.width - Theme.horizontalPageMargin * 2
                wrapMode: Label.WordWrap
                x: Theme.horizontalPageMargin
                visible: page.error.length
            }

            Label {
                text: qsTr("You must log in before continuing.");
                color: Theme.secondaryHighlightColor
                width: parent.width - Theme.horizontalPageMargin * 2
                wrapMode: Label.WordWrap
                x: Theme.horizontalPageMargin
                visible: page.error.length
            }

            ExpandingSectionGroup {
                id: sectionWrapper
                currentIndex: -1

                ExpandingSection {
                    title: qsTr("API key");

                    content.sourceComponent: Column {
                        Label {
                            text: qsTr("See <a href='%1'>Bitwarden help</a> for information on how to create an API key.").arg("https://bitwarden.com/help/personal-api-key/");
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

                            text: secrets.getClientId()
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
                ExpandingSection {
                    title: qsTr("Email & password");

                    content.sourceComponent: Column {
                        Label {
                            visible: twoFaFlow
                            text: qsTr("Please provide the code from your authenticator app below.")
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

                            onTextChanged: {
                                emailText = text;
                            }

                            EnterKey.iconSource: "image://theme/icon-m-enter-next"
                            EnterKey.onClicked: {
                                password.focus = true;
                            }

                            Component.onCompleted: {
                                if (emailText) {
                                    text = emailText;
                                } else if(secrets.getUsername()) {
                                    text = secrets.getUsername();
                                }
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

                            EnterKey.iconSource: twoFa.visible ? "image://theme/icon-m-enter-next" : "image://theme/icon-m-enter-accept"
                            EnterKey.onClicked: {
                                if (twoFa.visible) {
                                    twoFa.focus = true;
                                } else {
                                    page.accept();
                                }
                            }

                            Component.onCompleted: {
                                if (passwordText) {
                                    text = passwordText;
                                }
                            }
                        }

                        TextField {
                            id: twoFa
                            label: qsTr("Authenticator code")
                            visible: twoFaFlow

                            EnterKey.iconSource: "image://theme/icon-m-enter-accept"
                            EnterKey.onClicked: {
                                page.accept();
                            }

                            onTextChanged: {
                                twoFaCode = text;
                            }
                        }
                    }
                }
                ExpandingSection {
                    title: qsTr("Advanced")

                    content.sourceComponent: Column {
                        TextField {
                            id: customUrl
                            label: qsTr("Custom server URL")

                            EnterKey.iconSource: "image://theme/icon-m-enter-accept"
                            EnterKey.onClicked: {
                                page.accept();
                            }

                            onTextChanged: {
                                customServerUrl = text;
                            }

                            text: customServerUrl
                        }

                        Label {
                            text: qsTr("If you use your own server for Bitwarden, set its URL here.");
                            color: Theme.highlightColor
                            width: parent.width - Theme.horizontalPageMargin * 2
                            wrapMode: Label.WordWrap
                            x: Theme.horizontalPageMargin
                            font.pixelSize: Theme.fontSizeSmall
                            linkColor: Theme.lightPrimaryColor
                        }
                    }
                }
            }
        }
    }

    onRejected: {
        Qt.quit();
    }

    onStatusChanged: {
        if (status == PageStatus.Active) {
            while (doAfterLoad.length) {
                const callable = doAfterLoad.shift();
                callable();
            }
        }
    }
}
