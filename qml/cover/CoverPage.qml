import QtQuick 2.0
import Sailfish.Silica 1.0

import cz.chrastecky.bitsailor 1.0

CoverBackground {
    property bool isLocked: !secrets.hasSessionJson();
    property var item: ({type: BitSailorCore.ItemTypeNone})
    property var lockActions: [lockAction1, lockAction2, lockAction3, lockAction4]

    property string expiration: item.card !== undefined && item.card.expMonth && item.card.expYear ? String("0" + item.card.expMonth).slice(-2) + "/" + item.card.expYear : ''

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
        spacing: item.type === BitSailorCore.ItemTypeNone ? Theme.paddingLarge : Theme.paddingSmall

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
        Icon {
            visible: item.type === BitSailorCore.ItemTypeCard
            source: "file:///usr/share/harbour-bitsailor/icons/logo-black-white.png"
            anchors.horizontalCenter: parent.horizontalCenter
            sourceSize: "40x40"
        }
        Icon {
            visible: item.type === BitSailorCore.ItemTypeLogin && item && item.login
            source: "file:///usr/share/harbour-bitsailor/icons/logo-black-white.png"
            anchors.horizontalCenter: parent.horizontalCenter
            sourceSize: item && item.login && item.login.username && item.login.password && item.login.username && item.login.totp ? '80x80' : '40x40'
        }
        Icon {
            visible: item.type === BitSailorCore.ItemTypeSecureNote
            source: "file:///usr/share/harbour-bitsailor/icons/logo-black-white.png"
            anchors.horizontalCenter: parent.horizontalCenter
            sourceSize: "80x80"
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
            visible: item.type === BitSailorCore.ItemTypeCard && item.card.number
            //: On cover page, should be short, use abbreviations if needed
            text: qsTr("Card Number") + ":"
            font.pixelSize: Theme.fontSizeExtraSmall
            anchors.horizontalCenter: parent.horizontalCenter
            font.bold: true
        }
        Label {
            visible: item.type === BitSailorCore.ItemTypeCard && item.card.number
            text: item && item.card && item.card.number ? '•••• •••• •••• ' + item.card.number.slice(-4) : ''
            font.pixelSize: Theme.fontSizeExtraSmall
            anchors.horizontalCenter: parent.horizontalCenter
        }

        Label {
            visible: item.type === BitSailorCore.ItemTypeCard && expiration
            //: On cover page, should be short, use abbreviations if needed
            text: qsTr("Expiration") + ":"
            font.pixelSize: Theme.fontSizeExtraSmall
            anchors.horizontalCenter: parent.horizontalCenter
            font.bold: true
        }
        Label {
            visible: item.type === BitSailorCore.ItemTypeCard && expiration
            text: expiration
            font.pixelSize: Theme.fontSizeExtraSmall
            anchors.horizontalCenter: parent.horizontalCenter
        }

        Label {
            visible: item.type === BitSailorCore.ItemTypeCard && item.card.code
            //: On cover page, should be short, use abbreviations if needed
            text: qsTr("Security Code") + ":"
            font.pixelSize: Theme.fontSizeExtraSmall
            anchors.horizontalCenter: parent.horizontalCenter
            font.bold: true
        }
        Label {
            visible: item.type === BitSailorCore.ItemTypeCard && item.card.code
            text: "•••"
            font.pixelSize: Theme.fontSizeExtraSmall
            anchors.horizontalCenter: parent.horizontalCenter
        }

        Label {
            visible: item.type === BitSailorCore.ItemTypeLogin && item.login !== undefined && item.login.username !== undefined
            //: On cover page, should be short, use abbreviations if needed
            text: qsTr("Username") + ":"
            font.pixelSize: Theme.fontSizeExtraSmall
            anchors.horizontalCenter: parent.horizontalCenter
            font.bold: true
        }
        Label {
            visible: item.type === BitSailorCore.ItemTypeLogin && item.login !== undefined && item.login.username !== undefined
            text: item && item.login && item.login.username ? item.login.username : ''
            font.pixelSize: Theme.fontSizeExtraSmall
            anchors.horizontalCenter: parent.horizontalCenter
        }

        Label {
            visible: item.type === BitSailorCore.ItemTypeLogin && item.login !== undefined && item.login.password !== undefined
            //: On cover page, should be short, use abbreviations if needed
            text: qsTr("Password") + ":"
            font.pixelSize: Theme.fontSizeExtraSmall
            anchors.horizontalCenter: parent.horizontalCenter
            font.bold: true
        }
        Label {
            visible: item.type === BitSailorCore.ItemTypeLogin && item.login !== undefined && item.login.password !== undefined
            text: "••••••"
            font.pixelSize: Theme.fontSizeExtraSmall
            anchors.horizontalCenter: parent.horizontalCenter
        }

        Label {
            id: totpField
            visible: item.type === BitSailorCore.ItemTypeLogin && item.login !== undefined && item.login.totp !== undefined
            //: TOTP (two factor auth code) on cover page, should be short, use abbreviations if needed
            text: qsTr("TOTP") + ":"
            font.pixelSize: Theme.fontSizeExtraSmall
            anchors.horizontalCenter: parent.horizontalCenter
            font.bold: true
        }
        Label {
            visible: item.type === BitSailorCore.ItemTypeLogin && item.login !== undefined && item.login.totp !== undefined
            text: item && item.metadata && item.metadata.totp ? item.metadata.totp.match(/.{1,3}/g).join(' ') : ''
            font.pixelSize: Theme.fontSizeExtraSmall
            anchors.horizontalCenter: parent.horizontalCenter
        }

        Label {
            visible: item.type === BitSailorCore.ItemTypeSecureNote && item.notes
            //: On cover page, should be short, use abbreviations if needed
            text: qsTr("Note") + ":"
            font.pixelSize: Theme.fontSizeExtraSmall
            anchors.horizontalCenter: parent.horizontalCenter
            font.bold: true
        }
        Label {
            visible: item.type === BitSailorCore.ItemTypeSecureNote && item.notes
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
                Clipboard.text = item.card.number || ''
            }
        }

        CoverAction {
            iconSource: "image://theme/icon-s-date"
            onTriggered: {
                Clipboard.text = expiration;
            }
        }

        CoverAction {
            iconSource: "file:///usr/share/harbour-bitsailor/icons/key-solid.svg"
            onTriggered: {
                Clipboard.text = item.card.code || ''
            }
        }
    }

    CoverActionList {
        enabled: item.type === BitSailorCore.ItemTypeLogin && item.login !== undefined && !item.login.totp
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
                    core.lockVault();
                }
            }
        }

        CoverAction {
            iconSource: "image://theme/icon-cover-people" // icon-m-contact
            onTriggered: {
                Clipboard.text = item.login.username || ''
            }
        }
        CoverAction {
            iconSource: "image://theme/icon-m-keys"
            onTriggered: {
                Clipboard.text = item.login.password || ''
            }
        }
    }

    CoverActionList {
        enabled: item.type === BitSailorCore.ItemTypeLogin && item.login !== undefined && item.login.totp !== undefined

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
                    core.lockVault();
                }
            }
        }

        CoverAction {
            iconSource: "image://theme/icon-cover-people" // icon-m-contact
            onTriggered: {
                Clipboard.text = item.login.username || ''
            }
        }
        CoverAction {
            iconSource: "image://theme/icon-m-keys"
            onTriggered: {
                Clipboard.text = item.login.password || ''
            }
        }

        CoverAction {
            iconSource: "image://theme/icon-s-time"
            onTriggered: Clipboard.text = item.metadata.totp || ""
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
                    core.lockVault();
                }
            }
        }

        CoverAction {
            iconSource: "image://theme/icon-m-note"
            onTriggered: {
                Clipboard.text = item.notes || ''
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
