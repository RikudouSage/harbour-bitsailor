import QtQuick 2.0
import Sailfish.Silica 1.0

import cz.chrastecky.bitsailor 1.0

Page {
    property var doAfterLoad: []

    function safeCall(callable) {
        if (page.status == PageStatus.Active) {
            callable();
        } else {
            doAfterLoad.push(callable);
        }
    }

    id: page
    allowedOrientations: Orientation.All

    SecretsHandler {
        id: secrets
    }

    SilicaFlickable {
        anchors.fill: parent
        contentHeight: column.height

        Column {
            id: column

            width: page.width
            spacing: Theme.paddingLarge
            PageHeader {
                //: Page title
                title: qsTr("Invalid Certificate")
            }

            Label {
                x: Theme.horizontalPageMargin
                text: qsTr("The certificate of the server you're trying to access is invalid. If that's intentional (e.g. a self-signed certificate), you can ignore certificate errors using the button below.")
                color: Theme.errorColor
                wrapMode: Label.WordWrap
                width: parent.width - Theme.horizontalPageMargin * 2
            }

            Button {
                anchors.horizontalCenter: parent.horizontalCenter
                text: qsTr("Ignore certificate validation")
                onClicked: {
                    const dialog = pageStack.push("IgnoreInvalidCertsPage.qml");
                    dialog.accepted.connect(function() {
                        secrets.allowInvalidCertificates();
                        safeCall(function() {
                            pageStack.replace("LoginCheckPage.qml");
                        });
                    });
                }
            }
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
