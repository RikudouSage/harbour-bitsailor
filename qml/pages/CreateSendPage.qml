import QtQuick 2.0
import Sailfish.Silica 1.0
import Sailfish.Pickers 1.0

Dialog {
    property string sendType // file or text

    property string file: chooseField.value
    property string text: textField.text
    property string name: nameField.text
    property bool hideText: hideTextField.checked
    property int deletionDate: deletionDateSelect.value

    property int maximumAccessCount
    property string password
    property bool hideEmail
    property string privateNotes

    id: page
    allowedOrientations: Orientation.All
    canAccept: name.length > 0 && (sendType === 'file' ? file : text)

    SilicaFlickable {
        property bool loading: false

        id: root
        height: parent.height
        width: parent.width
        contentHeight: innerContent.height

        Column {
            id: innerContent
            width: parent.width
            visible: !root.loading
            spacing: Theme.paddingLarge

            DialogHeader {
                //: Dialog accept
                acceptText: qsTr("Create")
                cancelText: qsTr("Cancel")
            }

            TextField {
                id: textField
                acceptableInput: textField.length > 0
                label: qsTr("Text to share")
                visible: sendType === "text"
            }

            Button {
                property string value: ""
                property var parts: value.split("/")

                id: chooseField
                text: qsTr("Choose file") + (value ? ": " + parts[parts.length - 1] : "")
                visible: sendType === "file"
                anchors.horizontalCenter: parent.horizontalCenter
                onClicked: {
                    pageStack.push(filePickerDialog);
                }
            }
            Component {
                id: filePickerDialog

                FilePickerPage {
                    onSelectedContentPropertiesChanged: {
                        chooseField.value = selectedContentProperties.filePath
                    }
                }
            }

            TextField {
                id: nameField
                acceptableInput: text.length > 0
                label: qsTr("Send name")
            }

            TextSwitch {
                id: hideTextField
                text: qsTr("When accessing the Send, hide the text by default")
                visible: sendType === "text"
            }

            ComboBox {
                property int value

                id: deletionDateSelect
                label: qsTr("Deletion date")
                currentIndex: 4

                menu: ContextMenu {
                    MenuItem {
                        property int value: 1 * 60 * 60
                        text: qsTr("1 hour")
                    }
                    MenuItem {
                        property int value: 1 * 24 * 60 * 60
                        text: qsTr("1 day")
                    }
                    MenuItem {
                        property int value: 2 * 24 * 60 * 60
                        text: qsTr("2 days")
                    }
                    MenuItem {
                        property int value: 3 * 24 * 60 * 60
                        text: qsTr("3 days")
                    }
                    MenuItem {
                        property int value: 7 * 24 * 60 * 60
                        text: qsTr("7 days")
                    }
                    MenuItem {
                        property int value: 30 * 24 * 60 * 60
                        text: qsTr("30 days")
                    }
                }

                onCurrentItemChanged: {
                    value = currentItem.value;
                }
            }

            ExpandingSectionGroup {
                currentIndex: -1

                ExpandingSection {
                    title: qsTr("Additional settings")

                    content.sourceComponent: Column {
                        TextField {
                            id: maximumAccessCountField
                            label: qsTr("Maximum access count")
                            // @disable-check M325
                            acceptableInput: text == '' || (String(Number(text)) === text && Number(text) >= 0)
                            inputMethodHints: Qt.ImhDigitsOnly

                            rightItem: Row {
                                IconButton {
                                    icon.source: "image://theme/icon-splus-remove"
                                    onClicked: maximumAccessCountField.text = String(Number(maximumAccessCountField.text) - 1)
                                }
                                IconButton {
                                    icon.source: "image://theme/icon-splus-add"
                                    onClicked: maximumAccessCountField.text = String(Number(maximumAccessCountField.text) + 1)
                                }
                            }

                            onTextChanged: {
                                if (Number(text) < 0) {
                                    text = "0";
                                }

                                maximumAccessCount = Number(text)
                            }
                        }

                        PasswordField {
                            id: passwordField
                            label: qsTr("Password")
                            description: qsTr("Require this password to view the Send.")

                            onTextChanged: {
                                password = text;
                            }
                        }

                        TextSwitch {
                            id: hideEmailField
                            text: qsTr("Hide my email address from recipients")
                            onCheckedChanged: {
                                hideEmail = checked;
                            }
                        }

                        TextField {
                            id: privateNotesField
                            label: qsTr("Private notes")
                            onTextChanged: {
                                privateNotes = text;
                            }
                        }
                    }
                }
            }
        }
    }
}
