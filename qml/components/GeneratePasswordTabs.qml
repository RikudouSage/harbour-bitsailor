import QtQuick 2.0
import Sailfish.Silica 1.0
import Sailfish.Silica.private 1.0

TabView {
    currentIndex: 0
    width: parent.width
    height: parent.height

    header: TabBar {
        model: ListModel {
            ListElement {
                title: qsTr("Password")
            }
            ListElement {
                //: As an alternative to passwords, this is generally composed of English words separated by a separator, not characters, for example Punctual-Defeat-Exile
                title: qsTr("Passphrase")
            }
        }
    }
    model: [passwordTab, passphraseTab]

    Component {
        id: passwordTab

        TabItem {
            flickable: passwordContent
            GeneratePasswordContent {
                id: passwordContent
                title: PageHeader {}
            }
        }
    }

    Component {
        id: passphraseTab

        TabItem {
            flickable: passphraseContent
            GeneratePassphraseContent {
                id: passphraseContent
                title: PageHeader {}
            }
        }
    }
}
