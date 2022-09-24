import QtQuick 2.0
import Sailfish.Silica 1.0

import cz.chrastecky.bitsailor 1.0

Page {
    id: page
    allowedOrientations: Orientation.All

    BitwardenCli {
        id: cli

        onLoginStatusResolved: {
            if (loggedIn) {
                cli.checkVaultUnlocked();
            } else {
                pageStack.replace("LoginPage.qml"); // todo make dialog?
            }
        }

        onVaultLockStatusResolved: {
            if (unlocked) {
                pageStack.replace("MainPage.qml");
            } else {
                pageStack.replace("UnlockVaultPage.qml"); // todo make dialog?
            }
        }
    }

    SilicaFlickable {
        anchors.fill: parent
        contentHeight: column.height

        Column {
            id: column

            width: page.width
            spacing: Theme.paddingLarge
            PageHeader {
                title: qsTr("Authenticating...")
            }
        }
    }

    Component.onCompleted: {
        cli.checkLoginStatus();
    }
}
