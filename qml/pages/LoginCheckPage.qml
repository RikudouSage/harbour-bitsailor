import QtQuick 2.0
import Sailfish.Silica 1.0

import cz.chrastecky.bitsailor 1.0

Page {
    property var doAfterLoad: []

    id: page
    allowedOrientations: Orientation.All

    SecretsHandler {
        id: secrets
    }

    BitwardenCli {
        id: cli

        function displayLoginPage(error) {
            if (!error) {
                error = "";
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

        function displayUnlockPage(error) {
            if (!error) {
                error = "";
            }

            const dialog = pageStack.push("UnlockVaultPage.qml", {error: error});
            dialog.accepted.connect(function() {
                if (dialog.passwordText) {
                    cli.unlockVault(dialog.passwordText);
                } else if (dialog.pinText) {
                    cli.unlockVault(dialog.pinText);
                } else if (dialog.systemAuthSucceeded) {
                    cli.unlockVault();
                }
            });
        }

        onLoginStatusResolved: {
            if (loggedIn) {
                if (!secrets.hasSessionId()) {
                    displayUnlockPage();
                } else {
                    cli.checkVaultUnlocked();
                }
            } else {
                displayLoginPage();
            }
        }

        onVaultLockStatusResolved: {
            if (unlocked) {
                pageStack.replace("MainPage.qml");
            } else {
                runtimeCache.remove('items');
                runtimeCache.removePersistent('items');
                secrets.removeSessionId();

                displayUnlockPage();
            }
        }

        onLogInFinished: {
            if (success) {
                cli.checkVaultUnlocked();
            } else {
                displayLoginPage(qsTr("The credentials you provided are incorrect. Please try again."));
            }
        }

        onAuthenticatorRequired: {
            displayLoginPage(qsTr("An authenticator is required, please use API key login."));
        }

        onVaultUnlockFinished: {
            if (!success) {
                displayUnlockPage(qsTr("Wrong password or PIN"));
            } else {
                cli.checkVaultUnlocked();
            }
        }

        onWrongPinProvided: {
            displayUnlockPage(qsTr("Invalid PIN."));
        }
    }

    BusyLabel {
        running: true
        text: qsTr("Authenticating...")
    }

    Component.onCompleted: {
        if (settings.fastAuth && secrets.hasSessionId()) {
            doAfterLoad.push(function() {
                pageStack.replace("MainPage.qml");
            });
        } else {
            cli.checkLoginStatus();
        }
    }

    onStatusChanged: {
        if (status === PageStatus.Active) {
            while (doAfterLoad.length) {
                const callable = doAfterLoad.shift();
                callable();
            }
        }
    }
}
