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
        if (page.status == PageStatus.Active) {
            callable();
        } else {
            doAfterLoad.push(callable);
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
                if (settings.useApi) {
                    api.createTextSend(dialog.name, dialog.text, dialog.hideText, dialog.deletionDate, dialog.maximumAccessCount, dialog.password, dialog.hideEmail, dialog.privateNotes);
                } else {
                    cli.createTextSend(dialog.name, dialog.text, dialog.hideText, dialog.deletionDate, dialog.maximumAccessCount, dialog.password, dialog.hideEmail, dialog.privateNotes);
                }
            } else {
                // api does not support creating file Sends
                cli.createFileSend(dialog.name, dialog.file, dialog.deletionDate, dialog.maximumAccessCount, dialog.password, dialog.hideEmail, dialog.privateNotes);
            }
        });
    }

    BitwardenCli {
        id: cli

        onSendCreated: {
            if (settings.useApi && item.type === BitwardenCli.SendTypeFile) {
                api.addTempSend(item);
            }
            page.onSendCreated(item);
        }
    }

    BitwardenApi {
        id: api

        onSendCreated: {
            page.onSendCreated(item);
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
        if (status == PageStatus.Active) {
            while (doAfterLoad.length) {
                const callable = doAfterLoad.shift();
                callable();
            }
        }
    }
}
