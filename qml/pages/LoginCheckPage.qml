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
            core.logAuthEvent("LoginCheckPage displayLoginPage errorPresent=" + (!!error));
            safeCaller(function() {
                if (!error) {
                    error = "";
                }

                const dialog = pageStack.push("LoginPage.qml", {error: error, customServerUrl: customServerUrl});
                dialog.accepted.connect(function() {
                    core.logAuthEvent("LoginCheckPage login dialog accepted customServerUrlPresent=" + (!!dialog.customServerUrl)
                                      + " apiKeyLogin=" + (!!dialog.clientIdText && !!dialog.clientSecretText)
                                      + " emailPasswordLogin=" + (!!dialog.emailText && !!dialog.passwordText));
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
            core.logAuthEvent("LoginCheckPage displayUnlockPage errorPresent=" + (!!error));
            safeCaller(function() {
                if (!error) {
                    error = "";
                }

                const dialog = pageStack.push("UnlockVaultPage.qml", {error: error});
                dialog.accepted.connect(function() {
                    core.logAuthEvent("LoginCheckPage unlock dialog accepted password=" + (!!dialog.passwordText)
                                      + " pin=" + (!!dialog.pinText)
                                      + " systemAuth=" + (!!dialog.systemAuthSucceeded));
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
            core.logAuthEvent("LoginCheckPage onLoginStatusFetched status=" + status + " checkState=" + checkState);
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
                safeCaller(function() {
                    pageStack.replace("MainPage.qml");
                });
            } else {
                displayLoginPage(qsTr("Unknown status: %1").arg(status));
                console.error("Unknown status: " + status);
            }
        }

        onServerUrlChanged: {
            core.logAuthEvent("LoginCheckPage onServerUrlChanged success=" + success
                              + " apiKeyLogin=" + (!!clientId && !!clientSecret));
            if (!success) {
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
            core.logAuthEvent("LoginCheckPage onTwoFactorNeeded");
            displayLoginPage(qsTr("Your account has two-factor authentication enabled, which is currently unsupported. Please log in using your API key."));
        }

        onLoginFinished: {
            core.logAuthEvent("LoginCheckPage onLoginFinished success=" + success + " errorPresent=" + (!!error));
            if (!success) {
                displayLoginPage(qsTr("There was an error while logging in: %1").arg(error));
                return;
            }

            checkState = stateUnlock
            core.getLoginStatus();
        }

        onUnlockFinished: {
            core.logAuthEvent("LoginCheckPage onUnlockFinished success=" + success + " errorPresent=" + (!!error));
            if (success) {
                safeCaller(function() {
                    pageStack.replace("MainPage.qml");
                });
            } else {
                displayUnlockPage(qsTr("Failed unlocking, did you provide the correct password/PIN?"));
            }
        }

        onCouldNotFetchEmail: {
            core.logAuthEvent("LoginCheckPage onCouldNotFetchEmail");
            secrets.removeSessionJson();
            secrets.removeEncryptedVault();
            core.initialize();
            displayLoginPage(qsTr("Failed unlocking because the session got in an invalid state. We logged you out."))
        }

        onInvalidCertificate: {
            core.logAuthEvent("LoginCheckPage onInvalidCertificate");
            safeCaller(function() {
                pageStack.replace("InvalidCertificatePage.qml");
            });
        }
    }

    BusyLabel {
        running: true
        text: qsTr("Authenticating...")
    }

    Component.onCompleted: {
        core.logAuthEvent("LoginCheckPage completed, requesting login status");
        core.getLoginStatus();
    }

    onStatusChanged: {
        core.logAuthEvent("LoginCheckPage statusChanged status=" + status + " queuedCallCount=" + doAfterLoad.length);
        if (status === PageStatus.Active) {
            while (doAfterLoad.length) {
                const callable = doAfterLoad.shift();
                callable();
            }
        }
    }
}
