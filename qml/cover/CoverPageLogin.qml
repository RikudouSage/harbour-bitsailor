import QtQuick 2.0
import Sailfish.Silica 1.0

import cz.chrastecky.bitsailor 1.0

// todo find out how to hide cover actions to avoid duplicating stuff
CoverBackground {
    property bool isLocked: !secrets.hasSessionId()
    property var item: {type: BitwardenCli.NoType}

    SecretsHandler {
        id: secrets
    }

    BitwardenCli {
        id: cli

        onVaultLockStatusResolved: {
            isLocked = !unlocked;
        }

        onVaultLocked: {
            pageStack.replace("../pages/LoginCheckPage.qml");
            isLocked = !secrets.hasSessionId();
            lockAction.iconSource = lockAction.finalIcon;
        }
    }

    Column {
        y: Theme.horizontalPageMargin
        anchors.horizontalCenter: parent.horizontalCenter
        width: parent.width
        spacing: Theme.paddingMedium

        Icon {
            source: "file:///usr/share/harbour-bitsailor/icons/logo-black-white.png" // todo find out if some standard path exists for this
            anchors.horizontalCenter: parent.horizontalCenter
            sourceSize: "80x80"
        }
        Column {
            width: parent.width
            Label {
                id: itemFiled

                visible: item.type !== BitwardenCli.NoType && item.name
                //: Item name on the cover page for login detail, should be short, use abbreviations if needed
                text: qsTr("Item") + ":"
                font.pixelSize: Theme.fontSizeExtraSmall
                anchors.horizontalCenter: parent.horizontalCenter
                font.bold: true
            }
            Label {
                visible: item.type !== BitwardenCli.NoType && item.name
                text: item.name
                font.pixelSize: Theme.fontSizeExtraSmall
                anchors.horizontalCenter: parent.horizontalCenter
            }

            Label {
                id: usernameField

                visible: item.type !== BitwardenCli.NoType && item.username
                //: On cover page, should be short, use abbreviations if needed
                text: qsTr("Username") + ":"
                font.pixelSize: Theme.fontSizeExtraSmall
                anchors.horizontalCenter: parent.horizontalCenter
                font.bold: true
            }
            Label {
                visible: item.type !== BitwardenCli.NoType && item.username
                text: item.username
                font.pixelSize: Theme.fontSizeExtraSmall
                anchors.horizontalCenter: parent.horizontalCenter
            }

            Label {
                id: passwordField
                visible: item.type !== BitwardenCli.NoType && item.password
                //: On cover page, should be short, use abbreviations if needed
                text: qsTr("Password") + ":"
                font.pixelSize: Theme.fontSizeExtraSmall
                anchors.horizontalCenter: parent.horizontalCenter
                font.bold: true
            }
            Label {
                visible: item.type !== BitwardenCli.NoType && item.password
                text: "••••••"
                font.pixelSize: Theme.fontSizeExtraSmall
                anchors.horizontalCenter: parent.horizontalCenter
            }
        }
    }

    CoverActionList {
        CoverAction {
            property string icon: isLocked ? "lock-solid.svg" : "lock-open-solid.svg"
            property string finalIcon: "file:///usr/share/harbour-bitsailor/icons/" + icon // todo find out if some standard path exists for this
            id: lockAction
            iconSource: finalIcon
            onTriggered: {
                if (isLocked) {
                    app.activate();
                } else {
                    iconSource = "file:///usr/share/harbour-bitsailor/icons/loader.gif"
                    cli.lockVault();
                }
            }
        }

        CoverAction {
            iconSource: "image://theme/icon-cover-people" // icon-m-contact
            onTriggered: {
                Clipboard.text = item.username || ''
            }
        }
        CoverAction {
            iconSource: "image://theme/icon-m-keys"
            onTriggered: {
                Clipboard.text = item.password || ''
            }
        }
    }

    Timer {
        interval: 10000
        repeat: true
        running: true

        onTriggered: {
            isLocked = !secrets.hasSessionId();
            lockAction.iconSource = lockAction.finalIcon;
        }
    }

    Timer {
        interval: 120000 // two minutes
        repeat: true
        running: !Qt.application.active

        onTriggered: {
            cli.checkVaultUnlocked();
        }
    }

    onIsLockedChanged: {
        item = {type: BitwardenCli.NoType}
    }
}
