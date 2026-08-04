import QtQuick 2.0
import Sailfish.Silica 1.0

import cz.chrastecky.bitsailor 1.0

Dialog {
    property string requestId

    property string errorText
    property int handle
    property string fingerprint

    id: page
    allowedOrientations: Orientation.All
    canAccept: errorText === ''

    Connections {
        target: core

        onAuthRequestFetchFinished: {
            loader.running = false;

            if (!success) {
                errorText = qsTr("The authentication request could not be fetched. Please try again later.")
                return;
            }

            page.handle = handle;
            page.fingerprint = fingerprint;
        }
    }

    BusyLabel {
        id: loader
        text: qsTr("Loading")
        running: true
    }

    SilicaFlickable {
        anchors.fill: parent
        contentHeight: column.height
        visible: !loader.running

        Column {
            id: column

            width: page.width
            spacing: Theme.paddingLarge
            DialogHeader {
                //: Dialog accept text - approve other device's login
                acceptText: qsTr("Approve")
                //: Dialog cancel text - reject other device's login
                cancelText: qsTr("Reject")
            }

            Label {
                x: Theme.horizontalPageMargin
                text: errorText
                visible: errorText.length
                color: Theme.errorColor
                wrapMode: Label.WordWrap
                width: parent.width - Theme.horizontalPageMargin * 2
            }

            Label {
                x: Theme.horizontalPageMargin
                text: qsTr("A new device is asking you to approve login.<br><strong>Please make sure that the fingerprint phrase below matches the one on the device</strong>:<br><br><code>%1</code>").arg(fingerprint)
                visible: fingerprint.length
                wrapMode: Label.WordWrap
                width: parent.width - Theme.horizontalPageMargin * 2
                textFormat: Text.RichText
            }
        }
    }

    Component.onCompleted: {
        core.fetchAuthRequest(requestId);
    }
}
