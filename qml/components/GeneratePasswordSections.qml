import QtQuick 2.0
import Sailfish.Silica 1.0

SilicaFlickable {
    property bool loading: false
    property bool passwordLoading: false
    property bool passphraseLoading: false

    id: root
    width: parent.width
    height: parent.height
    contentHeight: innerContent.height
    clip: true

    Column {
        id: innerContent
        width: parent.width

        PageHeader {
            //: Page title for the password/passphrase generator screen
            title: qsTr("Generate")
        }

        ExpandingSectionGroup {
            width: parent.width
            currentIndex: 0

            ExpandingSection {
                //: Section title for generated passwords
                title: qsTr("Password")

                content.sourceComponent: GeneratePasswordContent {
                    embedded: true
                    title: Item {}

                    onLoadingChanged: {
                        root.passwordLoading = loading;
                    }

                    Component.onCompleted: {
                        root.passwordLoading = loading;
                    }
                }
            }

            ExpandingSection {
                //: Section title for generated passphrases
                title: qsTr("Passphrase")

                content.sourceComponent: GeneratePassphraseContent {
                    embedded: true
                    title: Item {}

                    onLoadingChanged: {
                        root.passphraseLoading = loading;
                    }

                    Component.onCompleted: {
                        root.passphraseLoading = loading;
                    }
                }
            }
        }

        Item {
            width: parent.width
            height: Theme.paddingLarge
        }
    }

    onPasswordLoadingChanged: {
        loading = passwordLoading || passphraseLoading;
    }

    onPassphraseLoadingChanged: {
        loading = passwordLoading || passphraseLoading;
    }
}
