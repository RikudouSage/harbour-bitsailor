import QtQuick 2.0
import Sailfish.Silica 1.0

import cz.chrastecky.bitsailor 1.0

import "../components" as Components

Page {
    property CreateSendPage dialog
    property bool loading: false

    id: page
    allowedOrientations: Orientation.All

    function onSendCreated(link) {
        loading = false;
        Clipboard.text = link;
        app.toaster.show(qsTr("URL copied to clipboard"));
        console.log(link);
        pageStack.pop();
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
                if (settings.useApi) {
                    api.createFileSend(dialog.name, dialog.file, dialog.deletionDate, dialog.maximumAccessCount, dialog.password, dialog.hideEmail, dialog.privateNotes);
                } else {
                    cli.createFileSend(dialog.name, dialog.file, dialog.deletionDate, dialog.maximumAccessCount, dialog.password, dialog.hideEmail, dialog.privateNotes);
                }
            }
        });
    }

    BitwardenCli {
        id: cli

        onSendCreated: {
            page.onSendCreated(link);
        }
    }

    BitwardenApi {
        id: api

        onSendCreated: {
            page.onSendCreated(link);
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
            text: qsTr("File")
            onClicked: {
                dialog = pageStack.push("CreateSendPage.qml", {sendType: 'file'})
                handleDialog();
            }
        }

        Button {
            text: qsTr("Text")
            onClicked: {
                dialog = pageStack.push("CreateSendPage.qml", {sendType: 'text'})
                handleDialog();
            }
        }
    }
}
