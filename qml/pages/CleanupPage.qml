import QtQuick 2.0
import Sailfish.Silica 1.0

import cz.chrastecky.bitsailor 1.0

Page {
    property var secretsCleared: null
    property var temporaryFilesDeleted: null
    property var configFilesDeleted: null

    id: page
    allowedOrientations: Orientation.All

    Connections {
        target: core

        onLogoutFinished: {
            loggedOut = true;
            secretsCleared = true;
        }
    }

    FileAccessor {
        id: fileAccessor
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
                title: qsTr("Cleaning Up")
            }

            IconTextSwitch {
                property alias propertyToCheck: page.secretsCleared
                property string iconName: propertyToCheck === null ? "icon-m-clock" : propertyToCheck ? "icon-m-certificates" : "icon-m-cancel"
                icon.source: "image://theme/" + iconName
                icon.color: propertyToCheck === null ? Theme.primaryColor : propertyToCheck ? Theme.secondaryHighlightColor : Theme.errorColor
                text: qsTr("Deleted all secrets")
                automaticCheck: false
                checked: propertyToCheck
                description: qsTr("Includes secrets like your password, username or PIN code.")
            }
            IconTextSwitch {
                property alias propertyToCheck: page.temporaryFilesDeleted
                property string iconName: propertyToCheck === null ? "icon-m-clock" : propertyToCheck ? "icon-m-certificates" : "icon-m-cancel"
                icon.source: "image://theme/" + iconName
                icon.color: propertyToCheck === null ? Theme.primaryColor : propertyToCheck ? Theme.secondaryHighlightColor : Theme.errorColor
                text: qsTr("Deleted temporary files")
                automaticCheck: false
                checked: propertyToCheck
                description: qsTr("Temporary files include some of your settings.")
            }
            IconTextSwitch {
                property alias propertyToCheck: page.configFilesDeleted
                property string iconName: propertyToCheck === null ? "icon-m-clock" : propertyToCheck ? "icon-m-certificates" : "icon-m-cancel"
                icon.source: "image://theme/" + iconName
                icon.color: propertyToCheck === null ? Theme.primaryColor : propertyToCheck ? Theme.secondaryHighlightColor : Theme.errorColor
                text: qsTr("Deleted all config files")
                automaticCheck: false
                checked: propertyToCheck
                description: qsTr("Config files include all the settings you have made in this app.")
            }
        }
    }

    onStatusChanged: {
        if (status === PageStatus.Active) {
            core.logout();
            temporaryFilesDeleted = fileAccessor.deleteTemporaryFilesDirectory();
            configFilesDeleted = fileAccessor.deleteConfigDirectory();
        }
    }
}
