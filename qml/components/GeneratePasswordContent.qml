import QtQuick 2.0
import Sailfish.Silica 1.0

import cz.chrastecky.bitsailor 1.0

SilicaFlickable {
    property alias title: componentLoader.sourceComponent

    property bool loading: true

    property bool uppercase: runtimeCache.hasPersistent(CacheKey.GenerateUppercase) ? runtimeCache.getPersistent(CacheKey.GenerateUppercase) === '1' : true
    property bool lowercase: runtimeCache.hasPersistent(CacheKey.GenerateLowercase) ? runtimeCache.getPersistent(CacheKey.GenerateLowercase) === '1' : true
    property bool numbers: runtimeCache.hasPersistent(CacheKey.GenerateNumbers) ? runtimeCache.getPersistent(CacheKey.GenerateNumbers) === '1' : true
    property bool special: runtimeCache.hasPersistent(CacheKey.GenerateSpecial) ? runtimeCache.getPersistent(CacheKey.GenerateSpecial) === '1' : false
    property bool avoidAmbiguous: runtimeCache.hasPersistent(CacheKey.GenerateAvoidAmbiguous) ? runtimeCache.getPersistent(CacheKey.GenerateAvoidAmbiguous) === '1' : false
    property int minimumNumbers: runtimeCache.hasPersistent(CacheKey.GenerateMinimumNumbers) ? Number(runtimeCache.getPersistent(CacheKey.GenerateMinimumNumbers)) : 0
    property int minimumSpecial: runtimeCache.hasPersistent(CacheKey.GenerateMinimumSpecial) ? Number(runtimeCache.getPersistent(CacheKey.GenerateMinimumSpecial)) : 0
    property int length: runtimeCache.hasPersistent(CacheKey.GenerateLength) ? Number(runtimeCache.getPersistent(CacheKey.GenerateLength)) : 14

    property alias password: passwordField.text

    function generatePassword() {
        if (settings.useApi) {
            api.generatePassword(lowercase, uppercase, numbers, special, avoidAmbiguous, minimumNumbers, minimumSpecial, length);
        } else {
            cli.generatePassword(lowercase, uppercase, numbers, special, avoidAmbiguous, minimumNumbers, minimumSpecial, length);
        }
        loadingDelayTimer.restart();
    }

    function onPasswordGenerated(password) {
        passwordField.text = password;
        loading = false;
        loadingDelayTimer.stop();
    }

    function onPasswordGeneratingFailed() {
        loading = false;
        app.toaster.show(qsTr("Generating password failed"));
    }

    id: root
    height: parent.height
    width: parent.width
    contentHeight: innerContent.height

    PullDownMenu {
        MenuItem {
            text: qsTr("Generate new password")
            onClicked: {
                root.generatePassword();
            }
        }
    }

    BitwardenApi {
        id: api

        onPasswordGenerated: {
            root.onPasswordGenerated(password);
        }
    }

    BusyLabel {
        id: loader
        text: qsTr("Generating password")
        running: root.loading
    }

    BitwardenCli {
        id: cli

        onPasswordGenerated: {
            root.onPasswordGenerated(password);
        }
    }

    Column {
        id: innerContent
        width: parent.width
        visible: !root.loading
        spacing: Theme.paddingLarge

        Loader {
            id: componentLoader
            width: parent.width
        }

        TextField {
            id: passwordField
            readOnly: true
            label: qsTr("Password")

            rightItem: Row {
                IconButton {
                    icon.source: "image://theme/icon-m-clipboard"
                    onClicked: {
                        Clipboard.text = passwordField.text;
                        app.toaster.show(qsTr("Copied to clipboard"));
                    }
                }
            }
        }

        Slider {
             width: parent.width
             minimumValue: 5
             maximumValue: 100
             value: length
             label: qsTr("Password length")
             valueText: String(sliderValue)
             stepSize: 1

             onDownChanged: {
                 if (sliderValue !== length) {
                     length = sliderValue;
                     runtimeCache.setPersistent(CacheKey.GenerateLength, String(sliderValue));
                     generatePassword();
                 }
             }
        }

        TextSwitch {
            text: qsTr("Uppercase letters")
            checked: uppercase
            automaticCheck: false
            onClicked: {
                uppercase = !checked;
                runtimeCache.setPersistent(CacheKey.GenerateUppercase, uppercase ? '1' : '0');
                generatePassword();
            }
        }
        TextSwitch {
            text: qsTr("Lowercase letters")
            checked: lowercase
            automaticCheck: false
            onClicked: {
                lowercase = !checked;
                runtimeCache.setPersistent(CacheKey.GenerateLowercase, lowercase ? '1' : '0');
                generatePassword();
            }
        }
        TextSwitch {
            text: qsTr("Numbers")
            checked: numbers
            automaticCheck: false
            onClicked: {
                numbers = !checked;
                runtimeCache.setPersistent(CacheKey.GenerateNumbers, numbers ? '1' : '0');
                generatePassword();
            }
        }
        TextSwitch {
            text: qsTr("Special characters")
            checked: special
            automaticCheck: false
            onClicked: {
                special = !checked;
                runtimeCache.setPersistent(CacheKey.GenerateSpecial, special ? '1' : '0');
                generatePassword();
            }
        }
        TextSwitch {
            text: qsTr("Avoid ambiguous characters")
            checked: avoidAmbiguous
            automaticCheck: false
            onClicked: {
                avoidAmbiguous = !checked
                runtimeCache.setPersistent(CacheKey.GenerateAvoidAmbiguous, avoidAmbiguous ? '1' : '0');
                generatePassword();
            }
        }

        Separator {
            height: 5
            width: parent.width
            color: Theme.highlightColor
            horizontalAlignment: Qt.AlignHCenter
        }

        TextField {
            id: minimumNumbersField
            //: How many numbers at minimum should be part of the generated password
            label: qsTr("Minimum numbers")
            text: minimumNumbers
            // @disable-check M325
            acceptableInput: String(Number(text)) === text && Number(text) >= 0
            inputMethodHints: Qt.ImhDigitsOnly

            rightItem: Row {
                IconButton {
                    icon.source: "image://theme/icon-splus-remove"
                    onClicked: minimumNumbersField.text = String(Number(minimumNumbersField.text) - 1)
                }
                IconButton {
                    icon.source: "image://theme/icon-splus-add"
                    onClicked: minimumNumbersField.text = String(Number(minimumNumbersField.text) + 1)
                }
            }

            onTextChanged: {
                if (Number(text) < 0) {
                    text = "0";
                }

                minimumNumbers = Number(text);
                runtimeCache.setPersistent(CacheKey.GenerateMinimumNumbers, text);
                generateTimer.restart();
            }
        }

        TextField {
            id: minimumSpecialField
            //: How many special chars at minimum should be part of the generated password
            label: qsTr("Minimum special")
            text: minimumSpecial
            // @disable-check M325
            acceptableInput: String(Number(text)) === text && Number(text) >= 0
            inputMethodHints: Qt.ImhDigitsOnly

            rightItem: Row {
                IconButton {
                    icon.source: "image://theme/icon-splus-remove"
                    onClicked: minimumSpecialField.text = String(Number(minimumSpecialField.text) - 1)
                }
                IconButton {
                    icon.source: "image://theme/icon-splus-add"
                    onClicked: minimumSpecialField.text = String(Number(minimumSpecialField.text) + 1)
                }
            }

            onTextChanged: {
                if (Number(text) < 0) {
                    text = "0";
                }

                minimumSpecial = Number(text);
                runtimeCache.setPersistent(CacheKey.GenerateMinimumSpecial, text);
                generateTimer.restart();
            }
        }
    }

    Timer {
        id: generateTimer
        interval: 300
        repeat: false

        onTriggered: {
            generatePassword();
        }
    }

    Timer {
        id: loadingDelayTimer
        interval: 300
        repeat: false

        onTriggered: {
            loading = true;
        }
    }

    Component.onCompleted: {
        generatePassword();
    }
}
