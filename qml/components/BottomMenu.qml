import QtQuick 2.0
import Sailfish.Silica 1.0

Row {
    property double inactiveOpacity: 0.7

    function makeAllInactive() {
        vaultsColumn.opacity = inactiveOpacity;
        sendColumn.opacity = inactiveOpacity;
    }

    function activateVaults() {
        makeAllInactive();
        vaultsColumn.opacity = 1;
    }

    function activateSend() {
        makeAllInactive();
        sendColumn.opacity = 1;
    }

    function findPageByType(type) {
        return pageStack.find(function(page) {
            const regex = /(.+?)_QML/;
            const matches = regex.exec(pageStack.currentPage.toString());
            const typeName = matches[1];
            if (!typeName) {
                return false;
            }

            return typeName === type;
        });
    }

    id: root
    height: Theme.itemSizeMedium + Theme.paddingLarge
    anchors.horizontalCenter: parent.horizontalCenter
    anchors.bottom: parent.bottom
    spacing: Theme.horizontalPageMargin

    Column {
        id: vaultsColumn
        opacity: inactiveOpacity
        IconButton {
            icon.source: "file:///usr/share/harbour-bitsailor/icons/lock-vault.svg"
            icon.width: Theme.iconSizeSmallPlus
            icon.height: icon.width
            anchors.horizontalCenter: parent.horizontalCenter
            onClicked: {
                pageStack.pop(findPageByType("MainPage"));
            }
        }
        Label {
            text: qsTr("Vaults")
            anchors.horizontalCenter: parent.horizontalCenter
            font.pixelSize: Theme.fontSizeExtraSmall
        }
    }

    Column {
        id: sendColumn
        opacity: inactiveOpacity
        IconButton {
            icon.source: "file:///usr/share/harbour-bitsailor/icons/paper-plane-send.svg"
            icon.width: Theme.iconSizeSmallPlus
            icon.height: icon.width
            anchors.horizontalCenter: parent.horizontalCenter
            onClicked: {
                pageStack.pop(findPageByType("MainPage"), PageStackAction.Immediate);
                pageStack.push("../pages/SendListPage.qml");
            }
        }
        Label {
            //: Probably shouldn't be translated as it's the official name of the service, Bitwarden Send
            text: qsTr("Send")
            anchors.horizontalCenter: parent.horizontalCenter
            font.pixelSize: Theme.fontSizeExtraSmall
        }
    }
}
