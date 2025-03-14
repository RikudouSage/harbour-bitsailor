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
        }
    }
    model: [passwordTab]

    Component {
        id: passwordTab

        TabItem {
            flickable: passwordContent
            GeneratePasswordContent {
                id: passwordContent
                title: PageHeader {
                }
            }
        }
    }
}
