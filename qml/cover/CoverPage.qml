import QtQuick 2.0
import Sailfish.Silica 1.0

import cz.chrastecky.bitsailor 1.0

CoverBackground {
    property bool isLocked: !secrets.hasSessionId()

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
        anchors.centerIn: parent
        width: parent.width
        spacing: Theme.paddingLarge

        Label {
            text: qsTr("BitSailor")
            id: label
            anchors.horizontalCenter: parent.horizontalCenter
        }
        Icon {
            source: "file:///usr/share/harbour-bitsailor/icons/logo-black-white.png" // todo find out if some standard path exists for this
            anchors.horizontalCenter: parent.horizontalCenter
            sourceSize: "100x100"
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
}
