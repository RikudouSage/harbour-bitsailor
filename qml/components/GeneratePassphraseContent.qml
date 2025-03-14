import QtQuick 2.0
import Sailfish.Silica 1.0

import cz.chrastecky.bitsailor 1.0

SilicaFlickable {
    property alias title: componentLoader.sourceComponent

    property bool loading: true

    property int wordsCount: Number(runtimeCache.getOrSetPersistent(CacheKey.GenerateWordCount, "3"))
    property bool capitalize: runtimeCache.getOrSetPersistent(CacheKey.GenerateCapitalizePassphrase, '0') === '1'
    property bool includeNumber: runtimeCache.getOrSetPersistent(CacheKey.GeneratePassphraseIncludeNumber, '0') === '1'
    property string separator: runtimeCache.getOrSetPersistent(CacheKey.GeneratePassphraseSeparator, '-')

    id: root
    height: parent.height
    width: parent.width
    contentHeight: innerContent.height

    function generatePassphrase() {
        if (settings.useApi) {
            api.generatePassphrase(wordsCount, capitalize, includeNumber, separator);
        } else {
            cli.generatePassphrase(wordsCount, capitalize, includeNumber, separator);
        }
        loadingDelayTimer.restart();
    }

    function onPassphraseGenerated(password) {
        passphraseField.text = password;
        loading = false;
        loadingDelayTimer.stop();
    }

    PullDownMenu {
        MenuItem {
            text: qsTr("Generate new passphrase")
            onClicked: {
                root.generatePassphrase();
            }
        }
    }

    BusyLabel {
        id: loader
        text: qsTr("Generating passphrase")
        running: root.loading
    }

    BitwardenApi {
        id: api

        onPassphraseGenerated: {
            root.onPassphraseGenerated(passphrase);
        }
    }

    BitwardenCli {
        id: cli

        onPassphraseGenerated: {
            root.onPassphraseGenerated(passphrase);
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
            id: passphraseField
            readOnly: true
            label: qsTr("Passphrase")

            rightItem: Row {
                IconButton {
                    icon.source: "image://theme/icon-m-clipboard"
                    onClicked: {
                        Clipboard.text = passphraseField.text;
                        app.toaster.show(qsTr("Copied to clipboard"));
                    }
                }
            }
        }

        Slider {
             width: parent.width
             minimumValue: 3
             maximumValue: 20
             value: wordsCount
             label: qsTr("Words count")
             valueText: String(sliderValue)
             stepSize: 1

             onDownChanged: {
                 if (sliderValue !== wordsCount) {
                     wordsCount = sliderValue;
                     runtimeCache.setPersistent(CacheKey.GenerateWordCount, String(sliderValue));
                     root.generatePassphrase();
                 }
             }
        }

        TextSwitch {
            text: qsTr("Capitalize words")
            checked: capitalize
            automaticCheck: false
            onClicked: {
                capitalize = !checked;
                runtimeCache.setPersistent(CacheKey.GenerateCapitalizePassphrase, capitalize ? '1' : '0');
                root.generatePassphrase();
            }
        }

        TextSwitch {
            text: qsTr("Include numbers")
            checked: includeNumber
            automaticCheck: false
            onClicked: {
                includeNumber = !checked;
                runtimeCache.setPersistent(CacheKey.GeneratePassphraseIncludeNumber, includeNumber ? '1' : '0');
                root.generatePassphrase();
            }
        }

        TextField {
            id: separatorField
            label: qsTr("Word separator")
            text: separator
            acceptableInput: text.length <= 1

            onTextChanged: {
                if (!acceptableInput) {
                    return;
                }

                separator = text;
                runtimeCache.setPersistent(CacheKey.GeneratePassphraseSeparator, separator);
                generateTimer.restart();
            }
        }
    }

    Timer {
        id: generateTimer
        interval: 300
        repeat: false

        onTriggered: {
            root.generatePassphrase();
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
        root.generatePassphrase();
    }
}
