import QtQuick 2.0
import Sailfish.Silica 1.0

import cz.chrastecky.bitsailor 1.0

import "../helpers.js" as Helpers

Page {
    readonly property string defaultServerUrl: "https://bitwarden.com"
    readonly property string europeanServerUrl: "https://bitwarden.eu"
    readonly property string customServerValue: "custom"

    property int pinToStore
    property string passwordToValidate

    property string errorText
    property string authCheckType

    property var doAfterLoad: []
    property var safeCaller: Helpers.safeCallerFactory(doAfterLoad, page)

    property var currentServerUrl: null

    function onServerUrlResolved(serverUrl) {
        currentServerUrl = serverUrl;
        customServerUrl.text = isPresetServerUrl(serverUrl) ? "" : serverUrl;
        serverUrlSelect.currentIndex = serverUrlSelect.indexForServerUrl(serverUrl);
        busyIndicatorServerUrl.running = false;
    }

    function isPresetServerUrl(serverUrl) {
        return serverUrl === defaultServerUrl || serverUrl === europeanServerUrl;
    }

    function selectedServerUrl() {
        if (!serverUrlSelect.currentItem) {
            return "";
        }

        return serverUrlSelect.currentItem.value === customServerValue
            ? customServerUrl.text
            : serverUrlSelect.currentItem.value;
    }

    function hasServerUrlChange() {
        return currentServerUrl !== null && serverUrlSelect.currentItem && selectedServerUrl() !== currentServerUrl;
    }

    id: page
    allowedOrientations: Orientation.All

    Connections {
        target: core

        onServerUrlResolved: {
            page.onServerUrlResolved(url);
        }

        onServerUrlChanged: {
            if (success) {
                pageStack.replace("LoginCheckPage.qml");
            }
        }

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

            SectionHeader {
                text: qsTr("Advanced")
            }

            ComboBox {
                id: serverUrlSelect
                enabled: currentServerUrl !== null
                //: Label for choosing the Bitwarden server instance
                label: qsTr("Server")

                property var itemData: [
                    {text: "bitwarden.com", value: page.defaultServerUrl},
                    {text: "bitwarden.eu", value: page.europeanServerUrl},
                    //: Server option for entering a custom Bitwarden server URL
                    {text: qsTr("Custom"), value: page.customServerValue}
                ]

                function indexForServerUrl(serverUrl) {
                    if (serverUrl === page.europeanServerUrl) {
                        return 1;
                    }

                    if (serverUrl && serverUrl !== page.defaultServerUrl) {
                        return 2;
                    }

                    return 0;
                }

                menu: ContextMenu {
                    MenuItem {
                        property string value: serverUrlSelect.itemData[0].value
                        text: serverUrlSelect.itemData[0].text
                    }

                    MenuItem {
                        property string value: serverUrlSelect.itemData[1].value
                        text: serverUrlSelect.itemData[1].text
                    }

                    MenuItem {
                        property string value: serverUrlSelect.itemData[2].value
                        text: serverUrlSelect.itemData[2].text
                    }
                }

                Component.onCompleted: {
                    core.getServerUrl();
                }
            }

            TextField {
                id: customServerUrl
                //: Label for the input containing a custom Bitwarden server URL
                label: qsTr("Custom server URL")
                visible: serverUrlSelect.currentItem && serverUrlSelect.currentItem.value === customServerValue
                text: currentServerUrl !== null && !isPresetServerUrl(currentServerUrl) ? currentServerUrl : ""

                EnterKey.iconSource: "image://theme/icon-m-enter-accept"
                EnterKey.onClicked: {
                    if (changeServerUrlButton.enabled) {
                        changeServerUrlButton.clicked();
                    }
                }
            }

            Button {
                id: changeServerUrlButton
                anchors.horizontalCenter: parent.horizontalCenter
                enabled: hasServerUrlChange() && serverUrlSelect.currentItem && (serverUrlSelect.currentItem.value !== customServerValue || customServerUrl.text.length)
                //: Button that applies the selected Bitwarden server
                text: qsTr("Change server")

                onClicked: {
                    const dialog = pageStack.push("ConfirmSettingPage.qml", {
                        description: qsTr("Note: You will be logged out.")
                    });
                    dialog.accepted.connect(function() {
                        busyIndicatorServerUrl.running = true;
                        core.changeServerUrl(selectedServerUrl());
                    });
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
