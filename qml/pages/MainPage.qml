import QtQuick 2.0
import Sailfish.Silica 1.0

import cz.chrastecky.bitsailor 1.0

Page {
    property string loadingMessage

    id: page
    allowedOrientations: Orientation.All

    function redoLogin() {
        pageStack.replace("LoginCheckPage.qml");
    }

    function displayMessage(message) {
        pullDownMenu.enabled = false;
        loadingMessage = message;
    }

    function displayPleaseWait() {
        displayMessage(qsTr("Please wait..."));
    }

    BitwardenCli {
        id: cli

        onLogoutFinished: {
            redoLogin();
        }

        onVaultLocked: {
            redoLogin();
        }
    }

    SilicaFlickable {
        anchors.fill: parent
        contentHeight: column.height

        PullDownMenu {
            id: pullDownMenu

            MenuItem {
                text: qsTr("Logout");
                onClicked: {
                    displayPleaseWait();
                    cli.logout();
                }
            }

            MenuItem {
                text: qsTr("Lock")
                onClicked: {
                    displayPleaseWait();
                    cli.lockVault();
                }
            }
        }

        Column {
            id: column

            width: page.width
            spacing: Theme.paddingLarge
            PageHeader {
                title: qsTr("Main Page")
            }

            Label {
                x: Theme.horizontalPageMargin
                text: qsTr("Yay, logged in.");
                color: Theme.secondaryHighlightColor
                wrapMode: Label.WordWrap
                width: parent.width - Theme.horizontalPageMargin * 2
            }
        }
    }

    BusyLabel {
        running: loadingMessage.length;
        text: loadingMessage
    }

    onStatusChanged: {
        if (status == PageStatus.Active) {
            pageStack.pushAttached("SettingsPage.qml");
        }
    }
}
