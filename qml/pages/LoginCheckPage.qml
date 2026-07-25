import QtQuick 2.0
import Sailfish.Silica 1.0

import cz.chrastecky.bitsailor 1.0
import "../helpers.js" as Helpers

Page {
    readonly property string stateLogin: 'login'
    readonly property string stateUnlock: 'unlock'

    property var doAfterLoad: []
    property var safeCaller: Helpers.safeCallerFactory(doAfterLoad, page);
    property string checkState: stateLogin

    // these are only set if changing server url
    property string clientId
    property string clientSecret
    property string email
    property string password

    // this is set always
    property string customServerUrl

    id: page
    allowedOrientations: Orientation.All

    Connections {
        target: core

        function displayLoginPage(error) {
            safeCaller(function() {
                if (!error) {
                    error = "";
                }

                const dialog = pageStack.push("LoginPage.qml", {error: error, customServerUrl: customServerUrl});
                dialog.accepted.connect(function() {
                    customServerUrl = dialog.customServerUrl || 'https://bitwarden.com';
                    clientId = dialog.clientIdText;
                    clientSecret = dialog.clientSecretText;
                    email = dialog.emailText;
                    password = dialog.passwordText;

                    core.changeServerUrl(customServerUrl);
                });
            });
        }

        function displayUnlockPage(error) {
            safeCaller(function() {
                if (!error) {
                    error = "";
                }

                const dialog = pageStack.push("UnlockVaultPage.qml", {error: error});
                dialog.accepted.connect(function() {
                    if (dialog.passwordText) {
                        core.unlockVault(dialog.passwordText);
                    } else if (dialog.pinText) {
                        core.unlockVault(dialog.pinText);
                    } else if (dialog.systemAuthSucceeded) {
                        core.unlockVault();
                    }
                });
            });
        }

        onLoginStatusFetched: {
            if (status === BitSailorCore.SessionStatusNone) {
                if (checkState === stateLogin) {
                    displayLoginPage();
                } else {
                    displayLoginPage(qsTr("There was an unknown error while logging in."));
                    console.error("The page was logged in but then session status check was None");
                }
            } else if (status === BitSailorCore.SessionStatusLocked) {
                displayUnlockPage();
            } else if (status === BitSailorCore.SessionStatusUnlocked) {
                pageStack.replace("MainPage.qml");
            } else {
                displayLoginPage(qsTr("Unknown status: %1").arg(status));
                console.error("Unknown status: " + status);
            }
        }

        onServerUrlChanged: {
            if (!status) {
                displayLoginPage(qsTr("There was an error while changing the URL, please report that to the developers."));
                return;
            }

            if (clientId.length && clientSecret.length) {
                core.loginApiKey(clientId, clientSecret);
            } else {
                core.loginEmailPassword(email, password);
            }
        }

        onTwoFactorNeeded: {
            displayLoginPage(qsTr("Your account has 2-factor logging in enabled which is currently unsupported. Please login using your api key."));
        }

        onLoginFinished: {
            if (!success) {
                displayLoginPage(qsTr("There was an error while logging in: %1").arg(error));
                return;
            }

            checkState = stateUnlock
            core.getLoginStatus();
        }

        onUnlockFinished: {
            if (success) {
                pageStack.replace("MainPage.qml");
            } else {
                displayUnlockPage(qsTr("Failed unlocking, did you provide the correct password?"));
            }
        }

        onCouldNotFetchEmail: {
            secrets.removeSessionJson();
            secrets.removeEncryptedVault();
            core.initialize();
            displayLoginPage(qsTr("Failed unlocking because the session got in an invalid state. We logged you out."))
        }
    }

    BitwardenCli {
        id: cli

        onServerUrlSet: {
            if (clientId.length && clientSecret.length) {
                cli.loginApiKey(clientId, clientSecret);
            } else {
                cli.loginEmailPassword(email, password);
            }
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
                runtimeCache.remove(CacheKey.Items);
                runtimeCache.removePersistent(CacheKey.Items);
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

        onInvalidCertificate: {
            const handle = function() {
                pageStack.replace("InvalidCertificatePage.qml");
            };
            if (pageStack.busy) {
                doAfterLoad.push(handle);
            } else {
                handle();
            }
        }
    }

    BusyLabel {
        running: true
        text: qsTr("Authenticating...")
    }

    Component.onCompleted: {
        core.getLoginStatus();
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
