import QtQuick 2.0
import Sailfish.Silica 1.0

import cz.chrastecky.bitsailor 1.0

CoverBackground {
    property bool isLocked: !secrets.hasSessionJson();
    property var item: ({type: BitSailorCore.ItemTypeNone})
    property var lockActions: [lockAction1, lockAction2, lockAction3, lockAction4]

    function lockActionFinalIcon() {
        lockActions.forEach(function(action) {
            action.iconSource = action.finalIcon;
        });
    }

    Connections {
        target: core

        onLoginStatusFetched: {
            isLocked = status !== BitSailorCore.SessionStatusUnlocked;
        }

        onVaultLocked: {
            if (success) {
                pageStack.replace("../pages/LoginCheckPage.qml");
                isLocked = !secrets.hasSessionJson();
                lockActionFinalIcon();
            }
        }
    }

    Column {
        anchors.centerIn: parent
        width: parent.width
        spacing: Theme.paddingLarge

        Label {
            visible: item.type === BitSailorCore.ItemTypeNone
            text: qsTr("BitSailor")
            id: label
            anchors.horizontalCenter: parent.horizontalCenter
        }
        Icon {
            visible: item.type === BitSailorCore.ItemTypeNone
            source: "file:///usr/share/harbour-bitsailor/icons/logo-black-white.png" // todo find out if some standard path exists for this
            anchors.horizontalCenter: parent.horizontalCenter
            sourceSize: "100x100"
        }

        Label {
            visible: [BitSailorCore.ItemTypeCard, BitSailorCore.ItemTypeLogin].indexOf(item.type) > -1
            //: Item name on the cover page for card detail, should be short, use abbreviations if needed
            text: qsTr("Item") + ":"
            font.pixelSize: Theme.fontSizeExtraSmall
            anchors.horizontalCenter: parent.horizontalCenter
            font.bold: true
        }
        Label {
            visible: [BitSailorCore.ItemTypeCard, BitSailorCore.ItemTypeLogin].indexOf(item.type) > -1 && item.name
            text: item.name ? item.name : ''
            font.pixelSize: Theme.fontSizeExtraSmall
            anchors.horizontalCenter: parent.horizontalCenter
        }

        Label {
            visible: item.type === BitSailorCore.ItemTypeCard && item.cardNumber
            //: On cover page, should be short, use abbreviations if needed
            text: qsTr("Card Number") + ":"
            font.pixelSize: Theme.fontSizeExtraSmall
            anchors.horizontalCenter: parent.horizontalCenter
            font.bold: true
        }
        Label {
            visible: item.type === BitSailorCore.ItemTypeCard && item.cardNumber
            text: item.cardNumber ? '•••• •••• •••• ' + item.cardNumber.slice(-4) : ''
            font.pixelSize: Theme.fontSizeExtraSmall
            anchors.horizontalCenter: parent.horizontalCenter
        }

        Label {
            visible: item.type === BitSailorCore.ItemTypeCard && item.expiration
            //: On cover page, should be short, use abbreviations if needed
            text: qsTr("Expiration") + ":"
            font.pixelSize: Theme.fontSizeExtraSmall
            anchors.horizontalCenter: parent.horizontalCenter
            font.bold: true
        }
        Label {
            visible: item.type === BitSailorCore.ItemTypeCard && item.expiration
            text: item.expiration ? item.expiration : ''
            font.pixelSize: Theme.fontSizeExtraSmall
            anchors.horizontalCenter: parent.horizontalCenter
        }

        Label {
            visible: item.type === BitSailorCore.ItemTypeCard && item.securityCode
            //: On cover page, should be short, use abbreviations if needed
            text: qsTr("Security Code") + ":"
            font.pixelSize: Theme.fontSizeExtraSmall
            anchors.horizontalCenter: parent.horizontalCenter
            font.bold: true
        }
        Label {
            visible: item.type === BitSailorCore.ItemTypeCard && item.securityCode
            text: "•••"
            font.pixelSize: Theme.fontSizeExtraSmall
            anchors.horizontalCenter: parent.horizontalCenter
        }

        Label {
            visible: item.type === BitSailorCore.ItemTypeLogin && item.username
            //: On cover page, should be short, use abbreviations if needed
            text: qsTr("Username") + ":"
            font.pixelSize: Theme.fontSizeExtraSmall
            anchors.horizontalCenter: parent.horizontalCenter
            font.bold: true
        }
        Label {
            visible: item.type === BitSailorCore.ItemTypeLogin && item.username
            text: item.username ? item.username : ''
            font.pixelSize: Theme.fontSizeExtraSmall
            anchors.horizontalCenter: parent.horizontalCenter
        }

        Label {
            visible: item.type === BitSailorCore.ItemTypeLogin && item.password
            //: On cover page, should be short, use abbreviations if needed
            text: qsTr("Password") + ":"
            font.pixelSize: Theme.fontSizeExtraSmall
            anchors.horizontalCenter: parent.horizontalCenter
            font.bold: true
        }
        Label {
            visible: item.type === BitSailorCore.ItemTypeLogin && item.password
            text: "••••••"
            font.pixelSize: Theme.fontSizeExtraSmall
            anchors.horizontalCenter: parent.horizontalCenter
        }

        Label {
            id: totpField
            visible: item.type === BitSailorCore.ItemTypeLogin && item.totp
            //: TOTP (two factor auth code) on cover page, should be short, use abbreviations if needed
            text: qsTr("TOTP") + ":"
            font.pixelSize: Theme.fontSizeExtraSmall
            anchors.horizontalCenter: parent.horizontalCenter
            font.bold: true
        }
        Label {
            visible: item.type === BitSailorCore.ItemTypeLogin && item.totp
            text: item.totp ? item.totp.match(/.{1,3}/g).join(' ') : ''
            font.pixelSize: Theme.fontSizeExtraSmall
            anchors.horizontalCenter: parent.horizontalCenter
        }

        Label {
            visible: item.type === BitSailorCore.ItemTypeSecureNote && item.note
            //: On cover page, should be short, use abbreviations if needed
            text: qsTr("Note") + ":"
            font.pixelSize: Theme.fontSizeExtraSmall
            anchors.horizontalCenter: parent.horizontalCenter
            font.bold: true
        }
        Label {
            visible: item.type === BitSailorCore.ItemTypeSecureNote && item.note
            text: "••••••"
            font.pixelSize: Theme.fontSizeExtraSmall
            anchors.horizontalCenter: parent.horizontalCenter
        }
    }

    CoverActionList {
        enabled: item.type === BitSailorCore.ItemTypeNone
        CoverAction {
            property string icon: isLocked ? "lock-solid.svg" : "lock-open-solid.svg"
            property string finalIcon: "file:///usr/share/harbour-bitsailor/icons/" + icon // todo find out if some standard path exists for this
            id: lockAction1
            iconSource: finalIcon
            onTriggered: {
                if (isLocked) {
                    app.activate();
                } else {
                    iconSource = "file:///usr/share/harbour-bitsailor/icons/loader.gif"
                    core.lockVault();
                }
            }
        }
    }

    CoverActionList {
        enabled: item.type === BitSailorCore.ItemTypeCard

        CoverAction {
            iconSource: "file:///usr/share/harbour-bitsailor/icons/hashtag-solid.svg"
            onTriggered: {
                Clipboard.text = item.cardNumber || ''
            }
        }

        CoverAction {
            iconSource: "image://theme/icon-s-date"
            onTriggered: {
                Clipboard.text = item.expiration || ''
            }
        }

        CoverAction {
            iconSource: "file:///usr/share/harbour-bitsailor/icons/key-solid.svg"
            onTriggered: {
                Clipboard.text = item.securityCode || ''
            }
        }
    }

    CoverActionList {
        enabled: item.type === BitSailorCore.ItemTypeLogin && !item.totp
        CoverAction {
            property string icon: isLocked ? "lock-solid.svg" : "lock-open-solid.svg"
            property string finalIcon: "file:///usr/share/harbour-bitsailor/icons/" + icon // todo find out if some standard path exists for this
            id: lockAction2
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

    CoverActionList {
        enabled: item.type === BitSailorCore.ItemTypeLogin && item.totp

        CoverAction {
            property string icon: isLocked ? "lock-solid.svg" : "lock-open-solid.svg"
            property string finalIcon: "file:///usr/share/harbour-bitsailor/icons/" + icon // todo find out if some standard path exists for this
            id: lockAction4
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

        CoverAction {
            iconSource: "image://theme/icon-s-time"
            onTriggered: Clipboard.text = item.totp || ""
        }
    }


    CoverActionList {
        enabled: item.type === BitSailorCore.ItemTypeSecureNote
        CoverAction {
            property string icon: isLocked ? "lock-solid.svg" : "lock-open-solid.svg"
            property string finalIcon: "file:///usr/share/harbour-bitsailor/icons/" + icon // todo find out if some standard path exists for this
            id: lockAction3
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
            iconSource: "image://theme/icon-m-note"
            onTriggered: {
                Clipboard.text = item.note || ''
            }
        }
    }

    Timer {
        interval: 10000
        repeat: true
        running: true

        onTriggered: {
            isLocked = !secrets.hasSessionJson();
            lockActionFinalIcon();
        }
    }

    Timer {
        interval: 120000 // two minutes
        repeat: true
        running: !Qt.application.active

        onTriggered: {
            core.getLoginStatus();
        }
    }
}
