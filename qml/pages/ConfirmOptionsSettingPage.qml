import QtQuick 2.0
import Sailfish.Silica 1.0

Page {
    id: page
    property string title
    property alias items: listView.model
    signal itemSelected(int id)

    SilicaListView {
        id: listView
        anchors.fill: parent
        header: PageHeader {
            title: page.title
        }

        VerticalScrollDecorator {}

        delegate: ListItem {
            Label {
                x: Theme.horizontalPageMargin
                wrapMode: Label.WordWrap
                width: parent.width - Theme.horizontalPageMargin * 2
                text: modelData.name
            }

            onClicked: {
                itemSelected(modelData.id)
                pageStack.pop()
            }
        }
    }
}
