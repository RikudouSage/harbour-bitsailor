import QtQuick 2.0
import Sailfish.Silica 1.0

import cz.chrastecky.bitsailor 1.0

Page {
    property int pinToStore
    property string passwordToStore

    property string errorText


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
                secrets.setPin(pinToStore);
                secrets.setPassword(passwordToStore);
                pinSetting.checked = true;

                pinToStore = 0;
                passwordToStore = "";
            } else {
                errorText = qsTr("The password you provided is invalid.");
            }
        }
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

        Column {
            id: column

            width: page.width
            spacing: Theme.paddingLarge

            PageHeader {
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

            TextSwitch {
                checked: settings.lockOnClose
                text: qsTr("Lock vault when app is closed")
                onCheckedChanged: {
                    settings.lockOnClose = checked;
                }
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

            TextSwitch {
                checked: settings.persistentItemCache
                text: qsTr("Save items in cache for faster load")
                automaticCheck: false

                onClicked: {
                    if (!checked) {
                        const dialog = pageStack.push("ConfirmSettingPage.qml", {
                            description: qsTr("Enabling this option will fasten load times for items in the vault significantly but it means that your vault is dumped to disk. While a great care has been taken to avoid dumping any sensitive information, bugs are possible and those sensitive informations could be leaked. Enable at your own risk."),
                        });
                        dialog.accepted.connect(function() {
                            settings.persistentItemCache = true;
                        });
                    } else {
                        settings.persistentItemCache = false;
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
                id: pinSetting

                checked: secrets.hasPin()
                automaticCheck: false
                text: qsTr("Use PIN to unlock vault")
                onClicked: {
                    errorText = "";

                    if (!checked) {
                        const dialog = pageStack.push("SetupPinPage.qml");
                        dialog.accepted.connect(function() {
                            busyIndicator.running = true;
                            pinToStore = Number(dialog.pinText);
                            passwordToStore = dialog.passwordText;
                            cli.unlockVault(passwordToStore);
                        });
                    } else {
                        secrets.removePinAndPassword();
                        checked = false;
                    }
                }
            }
        }
    }

    Component.onCompleted: {
    }
}
