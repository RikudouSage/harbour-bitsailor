import QtQuick 2.0
import Sailfish.Silica 1.0

import cz.chrastecky.bitsailor 1.0

Column {
    property alias title: componentLoader.sourceComponent

    property bool loading: false

    property bool uppercase: runtimeCache.hasPersistent(CacheKey.GenerateUppercase) ? runtimeCache.getPersistent(CacheKey.GenerateUppercase) === '1' : true
    property bool lowercase: runtimeCache.hasPersistent(CacheKey.GenerateLowercase) ? runtimeCache.getPersistent(CacheKey.GenerateLowercase) === '1' : true
    property bool numbers: runtimeCache.hasPersistent(CacheKey.GenerateNumbers) ? runtimeCache.getPersistent(CacheKey.GenerateNumbers) === '1' : true
    property bool special: runtimeCache.hasPersistent(CacheKey.GenerateSpecial) ? runtimeCache.getPersistent(CacheKey.GenerateSpecial) === '1' : false
    property int length: runtimeCache.hasPersistent(CacheKey.GenerateLength) ? Number(runtimeCache.getPersistent(CacheKey.GenerateLength)) : 14

    property alias password: passwordField.text

    function generatePassword() {
        cli.generatePassword(lowercase, uppercase, numbers, special, length);
        loading = true;
    }

    id: root
    width: parent.width
    spacing: Theme.paddingLarge

    BitwardenCli {
        id: cli

        onPasswordGenerated: {
            passwordField.text = password;
            loading = false;
        }
    }

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

    Component.onCompleted: {
        generatePassword();
    }
}
