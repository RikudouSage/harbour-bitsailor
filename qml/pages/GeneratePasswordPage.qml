import QtQuick 2.0
import Sailfish.Silica 1.0

Page {
    property bool loaded: generator.item ? !generator.item.loading : false

    id: page
    allowedOrientations: Orientation.All

    Loader {
        id: generator
        clip: true
        anchors {
            top: parent.top
            left: parent.left
            right: parent.right
            bottom: parent.bottom
            bottomMargin: app.bottomMenuRef.visible ? app.bottomMenuRef.height : 0
        }
        source: isStoreBuild
                ? "../components/GeneratePasswordSections.qml"
                : "../components/GeneratePasswordTabs.qml"
    }
}
