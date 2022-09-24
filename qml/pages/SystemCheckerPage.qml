import QtQuick 2.0
import Sailfish.Silica 1.0

import cz.chrastecky.bitsailor 1.0

Page {
    id: page
    allowedOrientations: Orientation.All

    property var doAfterLoad: []

    SystemChecker {
        id: checker

        onMissingRequiredDependency: {
            pageStack.replace("MissingRequiredBinaryPage.qml", {binaryName: name});
        }

        onMissingBitwardenCli: {
            const dialog = pageStack.push("MissingBitwardenCliPage.qml");
            dialog.accepted.connect(function() {
                doAfterLoad.push(function() {
                    pageStack.replace("InstallBitwardenCliPage.qml")
                });
            });
        }

        onUnknownErrorOccured: {
            pageStack.replace("UnknownErrorOccuredPage.qml");
        }

        onEverythingOk: {
            pageStack.replace("LoginCheckPage.qml");
        }
    }

    SilicaFlickable {
        anchors.fill: parent

        contentHeight: column.height

        Column {
            id: column

            width: page.width
            spacing: Theme.paddingLarge
            PageHeader {
                title: qsTr("System Check")
            }
            Label {
                x: Theme.horizontalPageMargin
                text: qsTr("Checking if system is ready...")
                color: Theme.secondaryHighlightColor
                font.pixelSize: Theme.fontSizeLarge
            }
        }
    }

    Component.onCompleted: {
        doAfterLoad.push(function() {
            checker.checkDependencies()
        });
    }

    onStatusChanged: {
        if (status === PageStatus.Active) {
            while (doAfterLoad.length) {
                const callable = doAfterLoad.shift();
                callable();
            }
        }
    }
}
