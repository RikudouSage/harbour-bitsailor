import QtQuick 2.0
import Sailfish.Silica 1.0
import Nemo.Notifications 1.0
import Sailfish.Share 1.0

import "pages"
import "components" as Components
import "helpers.js" as Helpers
import "cover" as Covers

import cz.chrastecky.bitsailor 1.0

ApplicationWindow {
    property alias toaster: toasterElement
    property alias bottomMenuRef: bottomMenu
    property var actionsWhenNotBusy: []
    property string fileToShare
    property string textToShare
    property bool invalidCertsAllowed: secrets.invalidCertificatesAllowed()
    id: app

    initialPage: Component { LoginCheckPage { } }
    cover: Covers.CoverPage {}
    allowedOrientations: defaultAllowedOrientations

    onInvalidCertsAllowedChanged: core.initialize();

    ShareProvider {
        method: "anything"
        capabilities: ["*"]
        registerName: true

        onTriggered: {
            if (!resources.length) {
                return;
            }

            app.activate();
            if (resources[0].type === ShareResource.StringDataType) {
                app.textToShare = resources[0].data
            } else {
                app.fileToShare = resources[0].filePath;
            }
        }
    }

    Connections {
        id: pageStackConnection
        target: pageStack

        onBusyChanged: {
            if (!pageStack.busy) {
                while (actionsWhenNotBusy.length) {
                    const callable = actionsWhenNotBusy.shift();
                    callable();
                }
            }
        }

        onCurrentPageChanged: {
            bottomMenu.visible = false;
            currentPageConnection.target = pageStack.currentPage;
            currentPageConnection.handleBottomMenuDisplay();
        }
    }

    Connections {
        id: currentPageConnection
        target: pageStack.currentPage
        ignoreUnknownSignals: true

        function handleBottomMenuDisplay() {
            const page = pageStack.currentPage;
            if (!page.loaded) {
                return;
            }

            const regex = /(.+?)_QML/;
            const matches = regex.exec(pageStack.currentPage.toString());
            const typeName = matches[1];
            if (!typeName) {
                return;
            }

            switch (typeName) {
            case "MainPage":
                bottomMenu.activateVaults();
                bottomMenu.visible = true;
                break;
            case "SendListPage":
                bottomMenu.activateSend();
                bottomMenu.visible = true;
                break;
            case "GeneratePasswordPage":
                bottomMenu.activateGenerator();
                bottomMenu.visible = true;
                break;
            }
        }

        onLoadedChanged: {
            handleBottomMenuDisplay();
        }
    }

    Timer {
        id: checkLoadedTimer
        running: false
    }

    Column {
        id: warningBanners
        visible: invalidCertsBanner.visible || debugSecretsBanner.visible
        z: 1000
        width: parent.width
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.top

        Rectangle {
            id: debugSecretsBanner
            color: Theme.errorColor
            visible: isDebug
            width: parent.width
            height: debugSecretsLabel.height + Theme.paddingMedium

            Label {
                id: debugSecretsLabel
                anchors.centerIn: parent
                width: parent.width - Theme.horizontalPageMargin * 2
                horizontalAlignment: Text.AlignHCenter
                wrapMode: Text.WordWrap
                color: Theme.lightPrimaryColor
                text: qsTr("Debug secret storage is used. Uninstall this version immediately unless you are developing BitSailor itself.")
            }
        }

        Rectangle {
            id: invalidCertsBanner
            color: Theme.errorColor
            visible: app.invalidCertsAllowed
            width: parent.width
            height: Theme.itemSizeLarge

            Label {
                anchors.bottom: parent.bottom
                anchors.bottomMargin: Theme.paddingSmall
                anchors.horizontalCenter: parent.horizontalCenter
                horizontalAlignment: Text.AlignHCenter
                color: Theme.lightPrimaryColor
                text: qsTr("Certificate validation is ignored")
            }
        }
    }

    Binding {
        target: pageStack
        property: "anchors.topMargin"
        value: warningBanners.visible ? warningBanners.height : 0
    }

    Component.onDestruction: {
        if (settings.lockOnClose) {
            core.lockVault(true)
        }
    }

    Components.Toaster {
        id: toasterElement
    }

    Components.BottomMenu {
        id: bottomMenu
        visible: false
    }
}
