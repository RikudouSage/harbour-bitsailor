import QtQuick 2.0
import Sailfish.Silica 1.0

import cz.chrastecky.bitsailor 1.0;

import "../helpers.js" as Helpers

Dialog {
    readonly property string defaultServerUrl: "https://bitwarden.com"
    readonly property string europeanServerUrl: "https://bitwarden.eu"
    readonly property string customServerValue: "custom"

    property alias currentTab: sectionWrapper.currentIndex

    property string emailText
    property string passwordText
    property string clientIdText
    property string clientSecretText
    property string serverUrl: defaultServerUrl
    property string customServerUrl
    property string twoFaCode
    property bool twoFaFlow: false

    property string error

    property var doAfterLoad: []

    function selectedServerUrl() {
        return serverUrl === customServerValue ? customServerUrl : serverUrl;
    }

    function applyInitialServerUrl(url) {
        if (!url || url === defaultServerUrl || url === europeanServerUrl) {
            serverUrl = url || defaultServerUrl;
            return;
        }

        serverUrl = customServerValue;
        customServerUrl = url;
    }

    function indexForServerUrl(url) {
        if (url === europeanServerUrl) {
            return 1;
        }

        if (url && url !== defaultServerUrl) {
            return 2;
        }

        return 0;
    }

    id: page
    allowedOrientations: Orientation.All
    canAccept: Helpers.xor(emailText.length && passwordText.length, clientIdText.length && clientSecretText.length) && (serverUrl !== customServerValue || customServerUrl.length)

    Component {
        id: serverUrlFields

        Column {
            id: serverUrlFieldsRoot
            width: parent ? parent.width : page.width

            function syncServerUrl() {
                serverSelect.currentIndex = page.indexForServerUrl(page.serverUrl);
            }

            function syncCustomServerUrl() {
                if (customUrl.text !== page.customServerUrl) {
                    customUrl.text = page.customServerUrl;
                }
            }

            ComboBox {
                id: serverSelect
                //: Label for choosing the Bitwarden server instance
                label: qsTr("Server")

                property var itemData: [
                    {text: "bitwarden.com", value: page.defaultServerUrl},
                    {text: "bitwarden.eu", value: page.europeanServerUrl},
                    //: Server option for entering a custom Bitwarden server URL
                    {text: qsTr("Custom"), value: page.customServerValue}
                ]

                menu: ContextMenu {
                    MenuItem {
                        property string value: serverSelect.itemData[0].value
                        text: serverSelect.itemData[0].text
                    }

                    MenuItem {
                        property string value: serverSelect.itemData[1].value
                        text: serverSelect.itemData[1].text
                    }

                    MenuItem {
                        property string value: serverSelect.itemData[2].value
                        text: serverSelect.itemData[2].text
                    }
                }

                onCurrentItemChanged: {
                    if (currentItem) {
                        page.serverUrl = currentItem.value;
                    }
                }
            }

            TextField {
                id: customUrl
                //: Label for the input containing a custom Bitwarden server URL
                label: qsTr("Custom server URL")
                inputMethodHints: Qt.ImhUrlCharactersOnly | Qt.ImhNoAutoUppercase | Qt.ImhNoPredictiveText
                visible: page.serverUrl === page.customServerValue

                EnterKey.iconSource: "image://theme/icon-m-enter-accept"
                EnterKey.onClicked: {
                    page.accept();
                }

                onTextChanged: {
                    page.customServerUrl = text;
                }

                text: page.customServerUrl
            }

            Connections {
                target: page

                onServerUrlChanged: {
                    serverUrlFieldsRoot.syncServerUrl();
                }

                onCustomServerUrlChanged: {
                    serverUrlFieldsRoot.syncCustomServerUrl();
                }
            }

            Label {
                visible: customUrl.visible
                text: qsTr("If you use your own server for Bitwarden, set its URL here.");
                color: Theme.highlightColor
                width: parent.width - Theme.horizontalPageMargin * 2
                wrapMode: Label.WordWrap
                x: Theme.horizontalPageMargin
                font.pixelSize: Theme.fontSizeSmall
                linkColor: Theme.lightPrimaryColor
            }

            Component.onCompleted: {
                syncServerUrl();
                syncCustomServerUrl();
            }
        }
    }

    SilicaFlickable {
        anchors.fill: parent
        contentHeight: column.height

        PullDownMenu {
            MenuItem {
                text: qsTr("Clean Up Data")
                onClicked: {
                    const dialog = pageStack.push("ConfirmSettingPage.qml", {
                        description: qsTr("This will delete everything that this app stores on your system, including system secrets collection, temporary files etc. Do you wish to continue?")
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

            DialogHeader {
                //: Dialog accept text
                acceptText: qsTr("Login")
            }

            Label {
                text: page.error;
                color: Theme.errorColor
                width: parent.width - Theme.horizontalPageMargin * 2
                wrapMode: Label.WordWrap
                x: Theme.horizontalPageMargin
                visible: page.error.length
            }

            Label {
                text: qsTr("You must log in before continuing.");
                color: Theme.secondaryHighlightColor
                width: parent.width - Theme.horizontalPageMargin * 2
                wrapMode: Label.WordWrap
                x: Theme.horizontalPageMargin
                visible: page.error.length
            }

            ExpandingSectionGroup {
                id: sectionWrapper
                currentIndex: -1

                ExpandingSection {
                    title: qsTr("API key");

                    content.sourceComponent: Column {
                        Label {
                            text: qsTr("See <a href='%1'>Bitwarden help</a> for information on how to create an API key.").arg("https://bitwarden.com/help/personal-api-key/");
                            color: Theme.highlightColor
                            width: parent.width - Theme.horizontalPageMargin * 2
                            wrapMode: Label.WordWrap
                            x: Theme.horizontalPageMargin
                            font.pixelSize: Theme.fontSizeSmall
                            linkColor: Theme.lightPrimaryColor
                        }

                        SectionHeader {}

                        TextField {
                            id: clientId
                            label: qsTr("Client ID")
                            inputMethodHints: Qt.ImhNoAutoUppercase | Qt.ImhNoPredictiveText

                            onTextChanged: {
                                clientIdText = text;
                            }

                            EnterKey.iconSource: "image://theme/icon-m-enter-next"
                            EnterKey.onClicked: {
                                clientSecret.focus = true;
                            }

                            text: secrets.getClientId()
                        }

                        TextField {
                            property bool passwordVisible: false

                            id: clientSecret
                            label: qsTr("Client Secret")
                            echoMode: passwordVisible ? TextInput.Normal : TextInput.Password
                            inputMethodHints: Qt.ImhNoAutoUppercase | Qt.ImhNoPredictiveText | Qt.ImhSensitiveData
                            rightItem: IconButton {
                                icon.source: !clientSecret.passwordVisible
                                             ? "image://theme/icon-splus-hide-password"
                                             : "image://theme/icon-splus-show-password"
                                onClicked: {
                                    clientSecret.passwordVisible = !clientSecret.passwordVisible;
                                }
                            }

                            onTextChanged: {
                                clientSecretText = text;
                            }

                            EnterKey.iconSource: "image://theme/icon-m-enter-accept"
                            EnterKey.onClicked: {
                                page.accept();
                            }
                        }

                        SectionHeader {
                            //: Section title for Bitwarden server settings
                            text: qsTr("Server")
                        }

                        Loader {
                            width: parent.width
                            sourceComponent: serverUrlFields
                        }
                    }
                }
                ExpandingSection {
                    title: qsTr("Email & password");

                    content.sourceComponent: Column {
                        Label {
                            visible: twoFaFlow
                            text: qsTr("Please provide the code from your authenticator app below.")
                            color: Theme.highlightColor
                            width: parent.width - Theme.horizontalPageMargin * 2
                            wrapMode: Label.WordWrap
                            x: Theme.horizontalPageMargin
                            font.pixelSize: Theme.fontSizeSmall
                            linkColor: Theme.lightPrimaryColor
                        }

                        SectionHeader {}

                        TextField {
                            id: email
                            label: qsTr("Email")
                            inputMethodHints: Qt.ImhEmailCharactersOnly | Qt.ImhNoAutoUppercase | Qt.ImhNoPredictiveText

                            onTextChanged: {
                                emailText = text;
                            }

                            EnterKey.iconSource: "image://theme/icon-m-enter-next"
                            EnterKey.onClicked: {
                                password.focus = true;
                            }

                            Component.onCompleted: {
                                if (emailText) {
                                    text = emailText;
                                } else if(secrets.getUsername()) {
                                    text = secrets.getUsername();
                                }
                            }
                        }

                        TextField {
                            property bool passwordVisible: false

                            id: password
                            label: qsTr("Password")
                            echoMode: passwordVisible ? TextInput.Normal : TextInput.Password
                            inputMethodHints: Qt.ImhNoAutoUppercase | Qt.ImhNoPredictiveText | Qt.ImhSensitiveData
                            rightItem: IconButton {
                                icon.source: !password.passwordVisible
                                             ? "image://theme/icon-splus-hide-password"
                                             : "image://theme/icon-splus-show-password"
                                onClicked: {
                                    password.passwordVisible = !password.passwordVisible;
                                }
                            }

                            onTextChanged: {
                                passwordText = text;
                            }

                            EnterKey.iconSource: twoFa.visible ? "image://theme/icon-m-enter-next" : "image://theme/icon-m-enter-accept"
                            EnterKey.onClicked: {
                                if (twoFa.visible) {
                                    twoFa.focus = true;
                                } else {
                                    page.accept();
                                }
                            }

                            Component.onCompleted: {
                                if (passwordText) {
                                    text = passwordText;
                                }
                            }
                        }

                        TextField {
                            id: twoFa
                            label: qsTr("Authenticator code")
                            inputMethodHints: Qt.ImhDigitsOnly | Qt.ImhSensitiveData
                            visible: twoFaFlow

                            EnterKey.iconSource: "image://theme/icon-m-enter-accept"
                            EnterKey.onClicked: {
                                page.accept();
                            }

                            onTextChanged: {
                                twoFaCode = text;
                            }
                        }

                        SectionHeader {
                            //: Section title for Bitwarden server settings
                            text: qsTr("Server")
                        }

                        Loader {
                            width: parent.width
                            sourceComponent: serverUrlFields
                        }
                    }
                }
            }
        }
    }

    onRejected: {
        Qt.quit();
    }

    onStatusChanged: {
        if (status == PageStatus.Active) {
            while (doAfterLoad.length) {
                const callable = doAfterLoad.shift();
                callable();
            }
        }
    }

    Component.onCompleted: {
        applyInitialServerUrl(customServerUrl);
    }
}
