import QtQuick 2.0
import Sailfish.Silica 1.0

import cz.chrastecky.bitsailor 1.0

import "../helpers.js" as Helpers

Page {
    property int pinToStore
    property string passwordToStore

    property string errorText
    property string authCheckType

    property var doAfterLoad: []
    property var safeCaller: Helpers.safeCallerFactory(doAfterLoad, page)

    property bool hasAnyPin: secrets.hasInternalPin() || secrets.hasPin()

    property var currentServerUrl: null

    function refreshHasAnyPin() {
        hasAnyPin = secrets.hasInternalPin() || secrets.hasPin();
        if (!hasAnyPin) {
            settings.persistentItemCache = false;
        }
    }

    function onServerUrlResolved(serverUrl) {
        currentServerUrl = serverUrl;
        busyIndicatorServerUrl.running = false;
    }

    id: page
    allowedOrientations: Orientation.All

    Timer {
        id: apiRunningCheckTimer
        repeat: true
        interval: 200
        running: false

        onTriggered: {
            api.isRunning();
        }
    }

    Connections {
        target: core

        onServerUrlResolved: {
            page.onServerUrlChanged(url);
        }

        onServerUrlChanged: {
            if (success) {
                pageStack.replace("LoginCheck.qml");
            }
        }

        onCouldNotFetchEmail: {
            busyIndicatorPassword.running = false;
            errorText = qsTr("Could not fetch your email address, the session is in an invalid state. Logout is advised");
        }

        onMasterPasswordValidationFinished: {
            busyIndicatorPassword.running = false;
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
        id: busyIndicatorPassword
        text: qsTr("Validating password")
        running: false
    }

    BusyLabel {
        id: busyIndicatorServerUrl
        //: As in the action of setting url (present continuous)
        text: qsTr("Setting URL")
        running: false
    }

    SilicaFlickable {
        anchors.fill: parent
        contentHeight: column.height
        visible: !busyIndicatorPassword.running && !busyIndicatorServerUrl.running

        VerticalScrollDecorator {}

        PushUpMenu {
            MenuItem {
                text: qsTr("Clean Up Everything");
                onClicked: {
                    const dialog = pageStack.push("ConfirmSettingPage.qml", {
                        description: qsTr("This will delete everything that this app stores on your system, including system secrets collection, Bitwarden CLI (if it was installed via this app), temporary files etc. Bitwarden CLI will also be logged out. Do you wish to continue?")
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
                            busyIndicatorPassword.running = true;
                            pinToStore = Number(dialog.pinText);
                            passwordToStore = dialog.passwordText;
                            core.validateMasterPassword(passwordToStore);

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
                            busyIndicatorPassword.running = true;
                            passwordToStore = dialog.passwordText;
                            core.validateMasterPassword(passwordToStore);
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
                text: qsTr("Advanced")
            }

            TextSwitch {
                enabled: currentServerUrl !== null
                checked: currentServerUrl !== null && currentServerUrl !== 'https://bitwarden.com'
                automaticCheck: false
                text: qsTr("Custom Bitwarden URL")

                onClicked: {
                    if (checked) {
                        core.changeServerUrl('https://bitwarden.com');
                    } else {
                        const dialog = pageStack.push("ConfirmStringSettingPage.qml", {
                            description: qsTr("Note: You will be logged out."),
                            inputLabel: qsTr("Bitwarden URL"),
                            value: currentServerUrl,
                        });
                        dialog.accepted.connect(function() {
                            busyIndicatorServerUrl.running = true;
                            core.changeServerUrl(dialog.value);
                        });
                    }
                }

                Component.onCompleted: {
                    core.getServerUrl();
                }
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
            while (doAfterLoad.length) {
                const callable = doAfterLoad.shift();
                callable();
            }
        }
    }
}
