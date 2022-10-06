import QtQuick 2.0
import Sailfish.Silica 1.0

import cz.chrastecky.bitsailor 1.0

Page {
    property var secretsCleared: null
    property var loggedOut: null
    property var temporaryFilesDeleted: null
    property var permanentFilesDeleted: null
    property var configFilesDeleted: null

    id: page
    allowedOrientations: Orientation.All

    BitwardenCli {
        id: cli
        onLogoutFinished: {
            loggedOut = true;
            secretsCleared = true;
            permanentFilesDeleted = fileAccessor.deletePermanentFilesDirectory();
        }
    }

    SecretsHandler {
        id: secrets
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
                property alias propertyToCheck: page.loggedOut
                property string iconName: propertyToCheck === null ? "icon-m-clock" : propertyToCheck ? "icon-m-certificates" : "icon-m-cancel"
                icon.source: "image://theme/" + iconName
                icon.color: propertyToCheck === null ? Theme.primaryColor : propertyToCheck ? Theme.secondaryHighlightColor : Theme.errorColor
                text: qsTr("Logged out of Bitwarden CLI")
                automaticCheck: false
                checked: propertyToCheck
                description: qsTr("The Bitwarden CLI could be used on its own even without this app, that's why it's safer to log out.")
            }
            IconTextSwitch {
                property alias propertyToCheck: page.temporaryFilesDeleted
                property string iconName: propertyToCheck === null ? "icon-m-clock" : propertyToCheck ? "icon-m-certificates" : "icon-m-cancel"
                icon.source: "image://theme/" + iconName
                icon.color: propertyToCheck === null ? Theme.primaryColor : propertyToCheck ? Theme.secondaryHighlightColor : Theme.errorColor
                text: qsTr("Deleted temporary files")
                automaticCheck: false
                checked: propertyToCheck
                description: qsTr("Temporary files include your cached vault for faster loading.")
            }
            IconTextSwitch {
                property alias propertyToCheck: page.permanentFilesDeleted
                property string iconName: propertyToCheck === null ? "icon-m-clock" : propertyToCheck ? "icon-m-certificates" : "icon-m-cancel"
                icon.source: "image://theme/" + iconName
                icon.color: propertyToCheck === null ? Theme.primaryColor : propertyToCheck ? Theme.secondaryHighlightColor : Theme.errorColor
                text: qsTr("Deleted all permanent files")
                automaticCheck: false
                checked: propertyToCheck
                description: qsTr("Permanent files include Bitwarden CLI (if it was installed using this app).")
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
            cli.logout();
            temporaryFilesDeleted = fileAccessor.deleteTemporaryFilesDirectory();
            configFilesDeleted = fileAccessor.deleteConfigDirectory();
        }
    }
}
