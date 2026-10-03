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

    // this is set always
    property string email
    property string password
    property string twoFaCode
    property string customServerUrl
    property int tfaKind: BitSailorCore.KindAuthenticator
    property var tfaDialog: null

    id: page
    allowedOrientations: Orientation.All

    Connections {
        target: core

        function displayLoginPage(error, supportedTfaMethods, tfaProviderInitialized, initializeDefaultTfa) {
            safeCaller(function() {
                if (!error) {
                    error = "";
                }

                const data = {error: error, customServerUrl: customServerUrl};

                if (supportedTfaMethods !== undefined) {
                    data.twoFaFlow = true;
                    data.passwordText = password;
                    data.emailText = email;
                    data.currentTab = 1;
                    data.supportedTfaMethods = supportedTfaMethods;
                    data.tfaKind = tfaKind;
                    data.tfaProviderInitialized = tfaProviderInitialized === true;
                    data.tfaProviderInitializing = initializeDefaultTfa === true;
                }

                const dialog = pageStack.push("LoginPage.qml", data);
                if (supportedTfaMethods !== undefined) {
                    tfaDialog = dialog;
                    dialog.tfaProviderChanged.connect(function(kind) {
                        tfaKind = kind;
                        dialog.tfaProviderInitializing = true;
                        core.initializeTfa(email, password, tfaKind);
                    });
                }
                if (initializeDefaultTfa) {
                    core.initializeTfa(email, password, tfaKind);
                }
                dialog.accepted.connect(function() {
                    tfaDialog = null;
                    customServerUrl = dialog.selectedServerUrl();
                    clientId = dialog.clientIdText;
                    clientSecret = dialog.clientSecretText;
                    email = dialog.emailText;
                    password = dialog.passwordText;
                    email = dialog.emailText;
                    twoFaCode = dialog.twoFaCode;
                    tfaKind = dialog.tfaKind;

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
                safeCaller(function() {
                    pageStack.replace("MainPage.qml");
                });
            } else {
                displayLoginPage(qsTr("Unknown status: %1").arg(status));
                console.error("Unknown status: " + status);
            }
        }

        onServerUrlChanged: {
            if (!success) {
                displayLoginPage(qsTr("There was an error while changing the URL, please report that to the developers."));
                return;
            }

            if (clientId.length && clientSecret.length) {
                core.loginApiKey(clientId, clientSecret);
            } else if (twoFaCode.length) {
                core.loginEmailPassword(email, password, tfaKind, twoFaCode);
            } else {
                core.loginEmailPassword(email, password);
            }
        }

        onTwoFactorNeeded: {
            if (!supportedMethods || supportedMethods.length === 0) {
                displayLoginPage(qsTr("Your account uses a two-factor method which is currently not supported by this app. Please log in using your API key."));
            } else {
                tfaKind = supportedMethods[0];
                displayLoginPage(null, supportedMethods, false, true);
            }
        }

        onUnsupportedTwoFactorNeeded: {
            displayLoginPage(qsTr("Your account uses a two-factor method which is currently not supported by this app. Please log in using your API key."));
        }

        onInitializeTfaFinished: {
            if (!success) {
                if (tfaDialog) {
                    tfaDialog.tfaProviderInitializing = false;
                    tfaDialog.error = qsTr("Failed to initialize the selected two-factor authentication method. Please choose a method and try again.");
                } else {
                    displayLoginPage(qsTr("Failed to initialize the two-factor authentication method. Please try logging in again."));
                }
                return;
            }

            if (tfaDialog) {
                tfaDialog.tfaProviderInitializing = false;
                tfaDialog.tfaProviderInitialized = true;
            }
        }

        onLoginFinished: {
            if (!success) {
                displayLoginPage(qsTr("There was an error while logging in: %1").arg(error));
                return;
            }

            checkState = stateUnlock
            core.getLoginStatus();
            settings.migratedToMultiAccounts = true;
        }

        onUnlockFinished: {
            if (success) {
                safeCaller(function() {
                    pageStack.replace("MainPage.qml");
                });
            } else {
                displayUnlockPage(qsTr("Failed unlocking, did you provide the correct password/PIN?"));
            }
        }

        onCouldNotFetchEmail: {
            secrets.removeSessionJson();
            secrets.removeEncryptedVault();
            core.initialize();
            displayLoginPage(qsTr("Failed unlocking because the session got in an invalid state. We logged you out."))
        }

        onInvalidCertificate: {
            safeCaller(function() {
                pageStack.replace("InvalidCertificatePage.qml");
            });
        }
    }

    BusyLabel {
        running: !errorText.visible
        text: qsTr("Authenticating...")
    }

    Label {
        id: errorText
        y: Theme.paddingLarge
        x: Theme.horizontalPageMargin
        color: Theme.errorColor
        wrapMode: Label.WordWrap
        width: parent.width - Theme.horizontalPageMargin * 2
        visible: text.length
    }

    Component.onCompleted: {
        if (!settings.migratedToMultiAccounts) {
            const accountId = accountManager.generateAccountId();

            if (!secrets.migrateUnprefixed(accountId)) {
                errorText.text = qsTr("Failed migrating your data to the new multi-account structure, your account data were deleted. Please close the app and log in again.");
                return;
            }

            if (!accountManager.setAccountIdAfterMigration(accountId)) {
                errorText.text = qsTr("Failed setting current account ID after migrating to the multi-account structure. Please close the app and log in again.");
                return;
            }

            settings.migratedToMultiAccounts = true;
            core.initialize();
        }

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
