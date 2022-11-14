import QtQuick 2.0
import Sailfish.Silica 1.0

import "." as Components

Row {
    property double inactiveOpacity: 0.7

    function makeAllInactive() {
        vaults.opacity = inactiveOpacity;
        send.opacity = inactiveOpacity;
        generator.opacity = inactiveOpacity;
    }

    function activateVaults() {
        makeAllInactive();
        vaults.opacity = 1;
    }

    function activateSend() {
        makeAllInactive();
        send.opacity = 1;
    }

    function activateGenerator() {
        makeAllInactive();
        generator.opacity = 1;
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

    Components.BottomMenuItem {
        id: vaults
        image: "file:///usr/share/harbour-bitsailor/icons/lock-vault.svg"
        text: qsTr("Vaults")
        onClicked: {
            pageStack.pop(findPageByType("MainPage"));
        }
    }

    Components.BottomMenuItem {
        id: send
        image: "file:///usr/share/harbour-bitsailor/icons/paper-plane-send.svg"
        //: Probably shouldn't be translated as it's the official name of the service, Bitwarden Send
        text: qsTr("Send")
        onClicked: {
            pageStack.pop(findPageByType("MainPage"), PageStackAction.Immediate);
            pageStack.push("../pages/SendListPage.qml");
        }
    }

    Components.BottomMenuItem {
        id: generator
        image: 'image://theme/icon-m-refresh' // todo
        text: qsTr("Generator")
        onClicked: {
            pageStack.pop(findPageByType("MainPage"), PageStackAction.Immediate);
            pageStack.push("../pages/GeneratePasswordPage.qml");
        }
    }
}
