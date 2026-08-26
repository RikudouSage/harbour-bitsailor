import QtQuick 2.0
import Sailfish.Silica 1.0

import cz.chrastecky.bitsailor 1.0

import "../components" as Components

Page {
    property CreateSendPage dialog
    property bool loading: false
    property var doAfterLoad: []

    id: page
    allowedOrientations: Orientation.All

    function safeCall(callable) {
        if (page.status !== PageStatus.Active || pageStack.busy) {
            doAfterLoad.push(callable);
        } else {
            callable();
        }
    }

    function runDeferredCalls() {
        if (page.status !== PageStatus.Active || pageStack.busy) {
            return;
        }

        while (doAfterLoad.length && !pageStack.busy) {
            const callable = doAfterLoad.shift();
            callable();
        }
    }

    function onSendCreated(item) {
        Clipboard.text = item.accessUrl;
        app.toaster.show(qsTr("URL copied to clipboard"));
        safeCall(function() {
            pageStack.pop();
        });
    }

    function handleDialog() {
        dialog.accepted.connect(function() {
            loading = true;
            if (dialog.sendType === "text") {
                core.createTextSend(dialog.name, dialog.text, dialog.hideText, dialog.deletionDate, dialog.maximumAccessCount, dialog.password, dialog.hideEmail, dialog.privateNotes);
            } else {
                core.createFileSend(dialog.name, dialog.file, dialog.deletionDate, dialog.maximumAccessCount, dialog.password, dialog.hideEmail, dialog.privateNotes);
            }
        });
    }

    Connections {
        target: core

        onSendCreated: {
            if (!success) {
                loading = false;
                app.toaster.show(qsTr("Failed creating Send"));
                return;
            }

            page.onSendCreated(item);
        }
    }

    Connections {
        target: pageStack

        onBusyChanged: {
            page.runDeferredCalls();
        }
    }

    PageHeader {
        title: qsTr("Create a Send")
    }

    BusyLabel {
        text: qsTr("Creating")
        running: loading
    }

    Column {
        anchors.centerIn: parent
        spacing: Theme.paddingLarge
        visible: !loading

        Button {
            id: fileDialog
            text: qsTr("File")
            onClicked: {
                const fileToShareParts = app.fileToShare ? app.fileToShare.split('/') : [];

                dialog = pageStack.push("CreateSendPage.qml", {
                    sendType: 'file',
                    file: app.fileToShare || '',
                    name: app.fileToShare ? fileToShareParts[fileToShareParts.length - 1] : '',
                })
                app.fileToShare = '';
                handleDialog();
            }
        }

        Button {
            id: textDialog
            text: qsTr("Text")
            onClicked: {
                dialog = pageStack.push("CreateSendPage.qml", {sendType: 'text', text: app.textToShare});
                app.textToShare = '';
                handleDialog();
            }
        }
    }

    Component.onCompleted: {
        if (app.fileToShare) {
            safeCall(function() {
                fileDialog.clicked(true);
            });
        }
        if (app.textToShare) {
            safeCall(function() {
                textDialog.clicked(true);
            });
        }
    }

    onStatusChanged: {
        page.runDeferredCalls();
    }
}
