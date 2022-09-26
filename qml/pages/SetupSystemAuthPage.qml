import QtQuick 2.0
import Sailfish.Silica 1.0

import cz.chrastecky.bitsailor 1.0

Dialog {
    property string passwordText: password.text
    property bool pinEnabled
    property string pinSettingName
    property bool failedSystemAuth: false

    id: page
    allowedOrientations: Orientation.All

    canAccept: passwordText.length

    SystemAuthChecker {
        id: authChecker

        onAuthResolved: {
            if (!success) {
                failedSystemAuth = true;
                reject();
            }

            console.log(success);
        }
    }

    SilicaFlickable {
        anchors.fill: parent
        contentHeight: column.height

        Column {
            id: column

            width: page.width
            spacing: Theme.paddingLarge
            DialogHeader {
                acceptText: qsTr("Continue")
            }

            Label {
                x: Theme.horizontalPageMargin
                width: parent.width - Theme.horizontalPageMargin * 2
                color: Theme.secondaryHighlightColor
                wrapMode: Label.WordWrap

                text: qsTr("To continue please provide your password. Your password will be stored securely using Sailfish OS secrets storage and used automatically whenever you authorize using Sailfish OS.")
            }

            Label {
                x: Theme.horizontalPageMargin
                width: parent.width - Theme.horizontalPageMargin * 2
                color: Theme.secondaryHighlightColor
                wrapMode: Label.WordWrap
                font.pixelSize: Theme.fontSizeSmall

                text: qsTr("Note: This option enables unlocking vault using fingerprint if your device supports it.");
            }

            Label {
                x: Theme.horizontalPageMargin
                width: parent.width - Theme.horizontalPageMargin * 2
                color: Theme.secondaryHighlightColor
                wrapMode: Label.WordWrap
                font.bold: true
                visible: pinEnabled

                text: qsTr("Warning: Enabling this option will disable <i>%1</i>.").arg(pinSettingName)
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

                EnterKey.iconSource: "image://theme/icon-m-enter-next"
                EnterKey.onClicked: {
                    pin.focus = true;
                }
            }
        }
    }

    onStatusChanged: {
        if (status === PageStatus.Active) {
            authChecker.checkAuth();
        }
    }
}
