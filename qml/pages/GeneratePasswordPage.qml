import QtQuick 2.0
import Sailfish.Silica 1.0

import cz.chrastecky.bitsailor 1.0

Page {
    property bool uppercase: runtimeCache.hasPersistent("generate_uppercase") ? runtimeCache.getPersistent("generate_uppercase") === '1' : true
    property bool lowercase: runtimeCache.hasPersistent("generate_lowercase") ? runtimeCache.getPersistent("generate_lowercase") === '1' : true
    property bool numbers: runtimeCache.hasPersistent("generate_numbers") ? runtimeCache.getPersistent("generate_numbers") === '1' : true
    property bool special: runtimeCache.hasPersistent("generate_special") ? runtimeCache.getPersistent("generate_special") === '1' : false
    property int length: runtimeCache.hasPersistent("generate_length") ? Number(runtimeCache.getPersistent("generate_length")) : 14

    id: page
    allowedOrientations: Orientation.All

    function generatePassword() {
        cli.generatePassword(lowercase, uppercase, numbers, special, length);
        loader.running = true;
    }

    BusyLabel {
        id: loader
        text: qsTr("Generating")
        running: true
    }

    BitwardenCli {
        id: cli

        onPasswordGenerated: {
            passwordField.text = password;
            loader.running = false;
        }
    }

    SilicaFlickable {
        anchors.fill: parent
        contentHeight: column.height
        visible: !loader.running

        PullDownMenu {
            MenuItem {
                text: qsTr("Generate new password")
                onClicked: {
                    generatePassword();
                }
            }
        }

        Column {
            id: column

            width: page.width
            spacing: Theme.paddingLarge

            PageHeader {
                title: qsTr("Generate Password")
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
                    runtimeCache.setPersistent("generate_uppercase", uppercase ? '1' : '0');
                    generatePassword();
                }
            }
            TextSwitch {
                text: qsTr("Lowercase letters")
                checked: lowercase
                automaticCheck: false
                onClicked: {
                    lowercase = !checked;
                    runtimeCache.setPersistent("generate_lowercase", lowercase ? '1' : '0');
                    generatePassword();
                }
            }
            TextSwitch {
                text: qsTr("Numbers")
                checked: numbers
                automaticCheck: false
                onClicked: {
                    numbers = !checked;
                    runtimeCache.setPersistent("generate_numbers", numbers ? '1' : '0');
                    generatePassword();
                }
            }
            TextSwitch {
                text: qsTr("Special characters")
                checked: special
                automaticCheck: false
                onClicked: {
                    special = !checked;
                    runtimeCache.setPersistent("generate_special", special ? '1' : '0');
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
                         runtimeCache.setPersistent("generate_length", String(sliderValue));
                         generatePassword();
                     }
                 }
             }
        }
    }

    onStatusChanged: {
        if (status === PageStatus.Active) {
            generatePassword();
        }
    }
}
