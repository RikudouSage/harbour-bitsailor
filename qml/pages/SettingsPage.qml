import QtQuick 2.0
import Sailfish.Silica 1.0

import cz.chrastecky.bitsailor 1.0

Page {
    property int pinToStore
    property string passwordToStore

    property string errorText
    property string authCheckType

    property var doAfterLoad: []

    property bool hasAnyPin: secrets.hasInternalPin() || secrets.hasPin()

    function refreshHasAnyPin() {
        hasAnyPin = secrets.hasInternalPin() || secrets.hasPin();
        if (!hasAnyPin) {
            settings.persistentItemCache = false;
        }
    }

    id: page
    allowedOrientations: Orientation.All

    SecretsHandler {
        id: secrets
    }

    BitwardenCli {
        id: cli

        onVaultUnlockFinished: {
            busyIndicator.running = false;

            if (success) {
                secrets.setPassword(passwordToStore);

                if (authCheckType === "pin") {
                    secrets.setPin(pinToStore);
                    pinSetting.checked = true;
                    systemAuthSetting.disable();
                } else if (authCheckType === "system") {
                    secrets.setInternalPin(pinGenerator.generate());
                    settings.useSystemAuth = true;
                    pinSetting.disable();
                }

                pinToStore = 0;
                passwordToStore = "";
            } else {
                errorText = qsTr("The password you provided is invalid.");
            }
        }
    }

    RandomPinGenerator {
        id: pinGenerator
    }

    BusyLabel {
        id: busyIndicator
        text: qsTr("Validating password")
        running: false
    }

    SilicaFlickable {
        anchors.fill: parent
        contentHeight: column.height
        visible: !busyIndicator.running

        VerticalScrollDecorator {}

        PullDownMenu {
            visible: runtimeCache.getPersistent("hasLocalInstallation") === "y"

            MenuItem {
                text: qsTr("Update Bitwarden CLI")
                visible: runtimeCache.getPersistent("hasLocalInstallation") === "y"
                onClicked: {
                    pageStack.push("UpdateBitwardenCliPage.qml");
                }
            }
        }

        PushUpMenu {
            MenuItem {
                text: qsTr("Clean Up Everything");
                onClicked: {
                    const dialog = pageStack.push("ConfirmSettingPage.qml", {
                        description: qsTr("This will delete everything that this app stores on your system, including system secrets collection, Bitwarden CLI (if it was installed via this app), temporary files etc. Bitwarden CLI will also be logged out. Do you wish to continue?")
                    });
                    dialog.accepted.connect(function() {
                        doAfterLoad.push(function() {
                            pageStack.replaceAbove(null, "CleanupPage.qml");
                        });
                    });
                }
            }
        }

        Column {
            id: column

            width: page.width
            spacing: Theme.paddingLarge

            PageHeader {
                //: Page title
                title: qsTr("Settings")
            }

            Label {
                x: Theme.horizontalPageMargin
                color: Theme.errorColor
                text: errorText
                visible: errorText.length
                wrapMode: Label.WordWrap
                width: parent.width - Theme.horizontalPageMargin * 2
            }

            SectionHeader {
                text: qsTr("General")
            }

            TextSwitch {
                id: eagerLoadingSetting

                checked: settings.eagerLoading
                text: qsTr("Load vault items eagerly in main view")
                automaticCheck: false

                onClicked: {
                    const description = qsTr("When this option is enabled, all items are loaded right when you enter the main screen. If disabled, the options are only loaded when you actually need to load them, meaning when you enter an item list like '%1', '%2' etc.").arg(qsTr('Logins')).arg(qsTr('Cards'));

                    if (!checked) {
                        const dialog = pageStack.push("ConfirmSettingPage.qml", {
                            description: description,
                        });
                        dialog.accepted.connect(function() {
                            settings.eagerLoading = true;
                        });
                    } else {
                        const dialog = pageStack.push("ConfirmSettingPage.qml", {
                            description: description,
                        });
                        dialog.accepted.connect(function() {
                            settings.eagerLoading = false;
                        });
                    }
                }
            }

            SectionHeader {
                text: qsTr("Security")
            }

            TextSwitch {
                id: lockOnCloseSetting
                checked: settings.lockOnClose
                text: qsTr("Lock vault when app is closed")

                onCheckedChanged: {
                    settings.lockOnClose = checked;
                    if (checked) {
                        settings.useAuthorizationOnUnlocked = false;
                    }
                }
            }

            TextSwitch {
                id: pinSetting

                function disable() {
                    secrets.removePin();
                    checked = false;
                    if (!systemAuthSetting.checked) {
                        secrets.removePassword();
                    }
                    refreshHasAnyPin();
                }

                checked: secrets.hasPin()
                automaticCheck: false
                text: qsTr("Use PIN to unlock vault")
                onClicked: {
                    errorText = "";

                    if (!checked) {
                        const dialog = pageStack.push("SetupPinPage.qml", {
                            systemAuthEnabled: settings.useSystemAuth,
                            systemAuthSettingName: systemAuthSetting.text
                        });
                        dialog.accepted.connect(function() {
                            authCheckType = "pin";
                            busyIndicator.running = true;
                            pinToStore = Number(dialog.pinText);
                            passwordToStore = dialog.passwordText;
                            cli.unlockVault(passwordToStore);

                            refreshHasAnyPin();
                        });
                    } else {
                        disable();
                    }
                }
            }

            TextSwitch {
                id: systemAuthSetting

                function disable() {
                    settings.useSystemAuth = false;
                    settings.useAuthorizationOnUnlocked = false;
                    if (!pinSetting.checked) {
                        secrets.removePassword();
                    }
                    refreshHasAnyPin();
                }

                checked: settings.useSystemAuth
                automaticCheck: false
                text: qsTr("Use OS authorization to unlock vault")
                onClicked: {
                    errorText = "";

                    if (!checked) {
                        const dialog = pageStack.push("SetupSystemAuthPage.qml", {
                            pinEnabled: secrets.hasPin(),
                            pinSettingName: pinSetting.text
                        });
                        dialog.accepted.connect(function() {
                            authCheckType = "system";
                            busyIndicator.running = true;
                            passwordToStore = dialog.passwordText;
                            cli.unlockVault(passwordToStore);
                            refreshHasAnyPin();
                        });
                        dialog.rejected.connect(function() {
                            if (dialog.failedSystemAuth) {
                                errorText = qsTr("OS authorization check failed.");
                                if (isDebug) {
                                    errorText += " " + qsTr("Note that this is normal when running inside emulator.");
                                }
                            }
                            refreshHasAnyPin();
                        });
                    } else {
                        disable();
                    }
                }
            }

            SectionHeader {
                text: qsTr("Performance")
            }

            TextSwitch {
                enabled: hasAnyPin
                checked: settings.persistentItemCache
                text: qsTr("Save items in cache for faster load")
                automaticCheck: false

                onClicked: {
                    if (!checked) {
                        const dialog = pageStack.push("ConfirmSettingPage.qml", {
                            description: qsTr("Enabling this option will fasten load times for items in the vault significantly - your data are <strong>stored on disk encrypted</strong> without any sensitive data (card numbers, passwords etc.)."),
                        });
                        dialog.accepted.connect(function() {
                            settings.persistentItemCache = true;
                        });
                    } else {
                        settings.persistentItemCache = false;
                        runtimeCache.removePersistent('items'); // todo get the 'items' key from somewhere
                    }
                }
            }

            TextSwitch {
                checked: settings.fastAuth
                text: qsTr("Fast authentication")
                automaticCheck: false

                onClicked: {
                    const description = qsTr("When this option is enabled, authentication is skipped and you are assumed to be logged in regardless of the actual status. What this means in practice is that logged in check is postponed until you're on the main page and is done in the background, this gives anyone opening this app a few seconds to look around before transfering you to the login/unlock screen. This should be ok because all vault operations fail when you're not logged in. <strong>Warning</strong>: if used in combination with the setting <strong>'%1'</strong> some data may be leaked to whoever opens this app. Use at your own risk.").arg(eagerLoadingSetting.text);

                    if (!checked) {
                        const dialog = pageStack.push("ConfirmSettingPage.qml", {
                            description: description,
                        });
                        dialog.accepted.connect(function() {
                            settings.fastAuth = true;
                        });
                    } else {
                        settings.fastAuth = false;
                    }
                }
            }

            TextSwitch {
                enabled: settings.useSystemAuth
                checked: settings.useAuthorizationOnUnlocked
                automaticCheck: false
                text: qsTr("Require OS authorization on unlocked vault")

                onClicked: {
                    if (!checked) {
                        const dialog = pageStack.push("ConfirmSettingPage.qml", {
                            description: qsTr("By enabling this option you will force the app to authorize you using OS authorization even when the vault is unlocked. If the authorization fails your vault will be locked and you will be redirected to unlock vault screen. This can speed up getting your vault data significantly. <strong>Warning</strong>: Disables '%1'").arg(lockOnCloseSetting.text),
                        });
                        dialog.accepted.connect(function() {
                            settings.useAuthorizationOnUnlocked = true;
                            lockOnCloseSetting.checked = false;
                        });
                    } else {
                        settings.useAuthorizationOnUnlocked = false;
                    }
                }
            }

            Item {
                width: parent.width
                height: Theme.paddingMedium
            }
        }
    }

    onStatusChanged: {
        if (status == PageStatus.Active) {
            while (doAfterLoad.length) {
                const callable = doAfterLoad.shift();
                callable();
            }
        }
    }
}
