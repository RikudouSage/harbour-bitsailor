import QtQuick 2.0
import Sailfish.Silica 1.0

import cz.chrastecky.bitsailor 1.0

Page {
    id: page
    allowedOrientations: Orientation.All

    BitwardenCli {
        id: cli

        function displayLoginPage(error) {
            if (!error) {
                error = false;
            }

            const dialog = pageStack.push("LoginPage.qml", {error: error});
            dialog.accepted.connect(function() {
                if (dialog.clientIdText.length && dialog.clientSecretText.length) {
                    cli.loginApiKey(dialog.clientIdText, dialog.clientSecretText);
                } else {
                    cli.loginEmailPassword(dialog.emailText, dialog.passwordText);
                }
            });
        }

        onLoginStatusResolved: {
            if (loggedIn) {
                cli.checkVaultUnlocked();
            } else {
                displayLoginPage();
            }
        }

        onVaultLockStatusResolved: {
            if (unlocked) {
                pageStack.replace("MainPage.qml");
            } else {
                const dialog = pageStack.push("UnlockVaultPage.qml");
            }
        }

        onLogInFinished: {
            if (success) {
                cli.checkVaultUnlocked();
            } else {
                displayLoginPage(true);
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
