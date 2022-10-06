import QtQuick 2.0
import Sailfish.Silica 1.0

Dialog {
    property string passwordText: password.text
    property string pinText: pin.text
    property bool systemAuthEnabled
    property string systemAuthSettingName

    id: page
    allowedOrientations: Orientation.All

    canAccept: passwordText.length && pinText.length && pinText === pinRepeat.text

    SilicaFlickable {
        anchors.fill: parent
        contentHeight: column.height

        Column {
            id: column

            width: page.width
            spacing: Theme.paddingLarge
            DialogHeader {
                //: Dialog accept text
                acceptText: qsTr("Continue")
            }

            Label {
                x: Theme.horizontalPageMargin
                width: parent.width - Theme.horizontalPageMargin * 2
                color: Theme.secondaryHighlightColor
                wrapMode: Label.WordWrap

                text: qsTr("To continue please provide your password and set your desired PIN code. Your password will be stored securely using Sailfish OS secrets storage and used automatically whenever you use your PIN.")
            }

            Label {
                x: Theme.horizontalPageMargin
                width: parent.width - Theme.horizontalPageMargin * 2
                color: Theme.secondaryHighlightColor
                wrapMode: Label.WordWrap
                font.bold: true
                visible: systemAuthEnabled

                text: qsTr("Warning: Enabling this option will disable <i>%1</i>.").arg(systemAuthSettingName)
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

            TextField {
                property bool passwordVisible: true

                id: pin
                label: qsTr("PIN")
                inputMethodHints: Qt.ImhDigitsOnly
                echoMode: passwordVisible ? TextInput.Normal : TextInput.Password
                rightItem: IconButton {
                    icon.source: !pin.passwordVisible
                                 ? "image://theme/icon-splus-hide-password"
                                 : "image://theme/icon-splus-show-password"
                    onClicked: {
                        pin.passwordVisible = !pin.passwordVisible;
                    }
                }

                EnterKey.iconSource: "image://theme/icon-m-enter-next"
                EnterKey.onClicked: {
                    pinRepeat.focus = true;
                }
            }

            TextField {
                property bool passwordVisible: true

                id: pinRepeat
                label: qsTr("Repeat PIN")
                inputMethodHints: Qt.ImhDigitsOnly
                echoMode: passwordVisible ? TextInput.Normal : TextInput.Password
                rightItem: IconButton {
                    icon.source: !pinRepeat.passwordVisible
                                 ? "image://theme/icon-splus-hide-password"
                                 : "image://theme/icon-splus-show-password"
                    onClicked: {
                        pinRepeat.passwordVisible = !pinRepeat.passwordVisible;
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
