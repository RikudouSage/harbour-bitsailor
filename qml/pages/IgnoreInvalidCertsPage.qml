import QtQuick 2.0
import Sailfish.Silica 1.0

import cz.chrastecky.bitsailor 1.0

Dialog {
    id: page
    allowedOrientations: Orientation.All
    canAccept: acknowledge.checked

    SilicaFlickable {
        anchors.fill: parent
        contentHeight: column.height

        Column {
            id: column

            width: page.width
            spacing: Theme.paddingLarge
            DialogHeader {
                //: Dialog accept
                acceptText: qsTr("Ignore Invalid Certificates")
                //: Dialog reject
                cancelText: qsTr("Cancel")
            }

            Label {
                x: Theme.horizontalPageMargin
                text: qsTr("If you ignore certificate errors you make yourself vulnerable to man-in-the-middle attacks which is exactly what issuer verification is meant to prevent. If you disable verification, anyone can use any certificate to impersonate any page. A malicious actor could impersonate your Bitwarden server using any https certificate, log any passwords that come through and then simply forward the response to you, thus stealing your passwords without you ever knowing.")
                color: Theme.errorColor
                wrapMode: Label.WordWrap
                width: parent.width - Theme.horizontalPageMargin * 2
            }

            TextSwitch {
                id: acknowledge
                text: qsTr("I acknowledge the above warning and that I'm making myself available to man-in-the-middle attacks which https is meant to prevent and which I'm knowingly circumventing")
            }
        }
    }
}
