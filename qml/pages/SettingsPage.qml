import QtQuick 2.0
import Sailfish.Silica 1.0

import cz.chrastecky.bitsailor 1.0

import "../helpers.js" as Helpers

Page {
    property int pinToStore
    property string passwordToValidate

    property string errorText
    property string authCheckType

    property var doAfterLoad: []
    property var safeCaller: Helpers.safeCallerFactory(doAfterLoad, page)

    id: page
    allowedOrientations: Orientation.All

    Connections {
        target: core

        onCouldNotFetchEmail: {
            busyIndicatorPassword.running = false;
            errorText = qsTr("Could not fetch your email address, the session is in an invalid state. Logout is advised");
        }

        onMasterPasswordValidationFinished: {
            busyIndicatorPassword.running = false;
            if (success) {
                if (!secrets.storeUserKeyFromSessionJson()) {
                    errorText = qsTr("Could not store the unlock key.");
                    pinToStore = 0;
                    passwordToValidate = "";
                    return;
                }

                if (authCheckType === "pin") {
                    secrets.setPin(pinToStore);
                    pinSetting.checked = true;
                    systemAuthSetting.disable();
                } else if (authCheckType === "system") {
                    secrets.setInternalPin(pinGenerator.generate());
                    settings.useSystemAuth = true;
                    systemAuthSetting.checked = true;
                    pinSetting.disable();
                }

                pinToStore = 0;
                passwordToValidate = "";
            } else {
                errorText = qsTr("The password you provided is invalid.");
            }
        }
    }

    RandomPinGenerator {
        id: pinGenerator
    }

    BusyLabel {
        id: busyIndicatorPassword
        text: qsTr("Validating password")
        running: false
    }

    SilicaFlickable {
        anchors.fill: parent
        contentHeight: column.height
        visible: !busyIndicatorPassword.running

        VerticalScrollDecorator {}

        PushUpMenu {
            MenuItem {
                text: qsTr("Clean Up Everything");
                onClicked: {
                    const dialog = pageStack.push("ConfirmSettingPage.qml", {
                        description: qsTr("This will delete everything that this app stores on your system, including system secrets collection, temporary files etc. Do you wish to continue?")
                    });
                    dialog.accepted.connect(function() {
                        safeCaller(function() {
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
                text: qsTr("Security")
            }

            TextSwitch {
                id: lockOnCloseSetting
                checked: settings.lockOnClose
                text: qsTr("Lock vault when app is closed")

                onCheckedChanged: {
                    settings.lockOnClose = checked;
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
                            busyIndicatorPassword.running = true;
                            pinToStore = Number(dialog.pinText);
                            passwordToValidate = dialog.passwordText;
                            core.validateMasterPassword(passwordToValidate);
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
                    if (!pinSetting.checked) {
                        secrets.removePassword();
                    }
                }

                checked: settings.useSystemAuth
                automaticCheck: false
                text: qsTr("Use OS authorization to unlock vault")
                description: isStoreBuild ? qsTr("The Jolla Store does not allow this setting, if you want to be able to unlock your vault using a fingerprint, please install the version from OpenRepos/Storeman") : ''
                onClicked: {
                    if (isStoreBuild) {
                        return;
                    }

                    errorText = "";

                    if (!checked) {
                        const dialog = pageStack.push("SetupSystemAuthPage.qml", {
                            pinEnabled: secrets.hasPin(),
                            pinSettingName: pinSetting.text
                        });
                        dialog.accepted.connect(function() {
                            authCheckType = "system";
                            busyIndicatorPassword.running = true;
                            passwordToValidate = dialog.passwordText;
                            core.validateMasterPassword(passwordToValidate);
                        });
                        dialog.rejected.connect(function() {
                            if (dialog.failedSystemAuth) {
                                errorText = qsTr("OS authorization check failed.");
                                if (isDebug) {
                                    errorText += " " + qsTr("Note that this is normal when running inside emulator.");
                                }
                            }
                        });
                    } else {
                        disable();
                    }
                }
            }

            TextSwitch {
                property var model: [
                    {id: 0, name: qsTr("Off")},
                    //: Amount of seconds
                    {id: 15, name: qsTr("%1s").arg(15)},
                    //: Amount of seconds
                    {id: 30, name: qsTr("%1s").arg(30)},
                    //: Amount of seconds
                    {id: 45, name: qsTr("%1s").arg(45)},
                    //: Amount of minutes
                    {id: 60, name: qsTr("%1m").arg(1)},
                    //: Amount of minutes
                    {id: 120, name: qsTr("%1m").arg(2)},
                ];

                function findByAmount(amount) {
                    for (var i in model) {
                        if (!model.hasOwnProperty(i)) {
                            continue;
                        }
                        const item = model[i];

                        if (item.id === amount) {
                            return item;
                        }
                    }

                    return model[0];
                }

                checked: settings.clearClipboardTimeout > 0
                automaticCheck: false
                text: qsTr("Automatically clear clipboard") + (" (" + findByAmount(settings.clearClipboardTimeout).name + ")")
                description: qsTr("Note that this only works when the app is running - if you close the app, the timer will not execute")

                onClicked: {
                    const dialog = pageStack.push("ConfirmOptionsSettingPage.qml", {
                        items: model,
                        title: qsTr("Select interval")
                    });
                    dialog.itemSelected.connect(function(seconds) {
                        settings.clearClipboardTimeout = seconds;
                    });
                }
            }

            TextSwitch {
                checked: settings.clearClipboardOnClosing
                automaticCheck: false
                text: qsTr("Clear clipboard on closing")
                description: qsTr("Note that this only works when the app is closed cleanly - if it closes because of a crash, the clipboard won't be cleared")

                onClicked: {
                    settings.clearClipboardOnClosing = !settings.clearClipboardOnClosing;
                }
            }

            TextSwitch {
                checked: settings.showFavicons
                automaticCheck: false
                text: qsTr("Show website icons")
                description: qsTr("Downloads favicons for visible login items and stores them in the app cache")

                onClicked: {
                    var enabled = !settings.showFavicons;
                    settings.showFavicons = enabled;
                    if (!enabled) {
                        core.clearIconCache();
                    }
                }
            }

            SectionHeader {
                text: qsTr("Advanced")
            }

            TextSwitch {
                // todo
                visible: enabled
                enabled: secrets.invalidCertificatesAllowed()
                checked: !secrets.invalidCertificatesAllowed()
                automaticCheck: false
                text: qsTr("Enable certificate validation")

                onClicked: {
                    const dialog = pageStack.push("ConfirmSettingPage.qml", {
                        description: qsTr("Using this toggle you'll again enable https certificate checks when communicating with Bitwarden servers."),
                    });
                    dialog.accepted.connect(function() {
                        secrets.disallowInvalidCertificates();
                        app.toaster.show(qsTr("Please restart the app"), 100000);
                    });
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
            pageStack.pushAttached("AccountSwitcherPage.qml");

            while (doAfterLoad.length) {
                const callable = doAfterLoad.shift();
                callable();
            }
        }
    }
}
