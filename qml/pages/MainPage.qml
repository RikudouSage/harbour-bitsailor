import QtQuick 2.0
import Sailfish.Silica 1.0

import cz.chrastecky.bitsailor 1.0

import "../components" as Components

Page {
    property string loadingMessage

    property string currentCount

    property var loginsCount: null
    property var cardsCount: null
    property var notesCount: null
    property var identitiesCount: null

    property bool loaded: false
    property var doAfterLoad: []

    id: page
    allowedOrientations: Orientation.All

    function redoLogin() {
        pageStack.replace("LoginCheckPage.qml");
    }

    function displayMessage(message) {
        pullDownMenu.enabled = false;
        loadingMessage = message;
    }

    function hideMessage() {
        pullDownMenu.enabled = true;
        loadingMessage = "";
    }

    function displayPleaseWait() {
        displayMessage(qsTr("Please wait..."));
    }

    function displayLoadingVaultItems() {
        displayMessage(qsTr("Loading vault items"));
    }

    SecretsHandler {
        id: secrets
    }

    SystemAuthChecker {
        id: authChecker

        onAuthResolved: {
            if (!success) {
                secrets.removeSessionId();
                const handler = function() {
                    pageStack.replace("LoginCheckPage.qml");
                };
                loaded ? handler() : doAfterLoad.push(handler);
            }
        }
    }

    BitwardenCli {
        id: cli

        onLogoutFinished: {
            redoLogin();
        }

        onVaultLocked: {
            redoLogin();
        }

        onItemsResolved: {
            if (!currentCount) {
                hideMessage();
                doAfterLoad.push(function() { hideMessage(); });
                currentCount = "logins";
                getLogins();
            } else {
                switch (currentCount) {
                case "logins":
                    loginsCount = items.length;
                    currentCount = "cards";
                    getCards();
                    break;
                case "cards":
                    cardsCount = items.length;
                    currentCount = "notes";
                    getNotes();
                    break;
                case "notes":
                    notesCount = items.length;
                    currentCount = "identities";
                    getIdentities();
                    break;
                case "identities":
                    identitiesCount = items.length;
                    currentCount = "";
                    break;
                }
            }
        }

        onVaultSyncFailed: {
            // todo
            hideMessage();
        }

        onVaultSynced: {
            hideMessage();
            loginsCount = null;
            cardsCount = null;
            notesCount = null;
            identitiesCount = null;

            if (settings.eagerLoading) {
                cli.getItems();
                displayLoadingVaultItems();
            }
        }

        onVaultLockStatusResolved: {
            if (!unlocked) {
                runtimeCache.remove(CacheKey.Items);
                runtimeCache.removePersistent(CacheKey.Items);
                secrets.removeSessionId();

                var handle = function() {
                    pageStack.replace("LoginCheckPage.qml");
                };
                loaded ? handle() : doAfterLoad.push(handle);
            }
        }
    }

    SilicaFlickable {
        id: flickable
        anchors.fill: parent
        contentHeight: column.height
        visible: !loader.running

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

            MenuItem {
                text: qsTr("Sync Vault")
                onClicked: {
                    displayMessage(qsTr("Syncing vault"));
                    cli.syncVault();
                }
            }

            MenuItem {
                text: qsTr("Search")
                onClicked: {
                    pageStack.push("VaultPage.qml", {searchActive: true});
                }
            }
        }

        Column {
            id: column

            width: page.width
            spacing: Theme.paddingLarge
            PageHeader {
                //: Page title
                title: qsTr("BitSailor")
            }

            Components.MainPageItem {
                text: loginsCount !== null ? qsTr("Logins (%1)").arg(loginsCount) : qsTr("Logins");
                onClicked: {
                    pageStack.push("VaultPage.qml", {
                        itemLoader: 'getLogins',
                        //: Page title
                        title: qsTr("Logins"),
                        addItemTitle: qsTr('Add login'),
                        addItemType: BitwardenCli.Login,
                    });
                }
            }

            Components.MainPageItem {
                text: cardsCount !== null ? qsTr("Cards (%1)").arg(cardsCount) : qsTr("Cards")
                onClicked: {
                    pageStack.push("VaultPage.qml", {
                        itemLoader: 'getCards',
                        //: Page title
                        title: qsTr("Cards"),
                        addItemTitle: qsTr("Add card"),
                        addItemType: BitwardenCli.Card,
                    });
                }
            }

            Components.MainPageItem {
                text: notesCount !== null ? qsTr("Notes (%1)").arg(notesCount) : qsTr("Notes")
                onClicked: {
                    pageStack.push("VaultPage.qml", {
                        itemLoader: 'getNotes',
                        //: Page title
                        title: qsTr("Notes"),
                        addItemTitle: qsTr("Add note"),
                        addItemType: BitwardenCli.SecureNote,
                    });
                }
            }

            Components.MainPageItem {
                text: identitiesCount !== null ? qsTr("Identities (%1)").arg(identitiesCount) : qsTr("Identities")
                onClicked: {
                    pageStack.push("VaultPage.qml", {
                        itemLoader: 'getIdentities',
                        //: Page title
                        title: qsTr("Identities"),
                        addItemTitle: qsTr("Add identity"),
                        addItemType: BitwardenCli.Identity,
                    });
                }
            }
        }
    }

    BusyLabel {
        id: loader
        running: loadingMessage.length;
        text: loadingMessage
    }

    Component.onCompleted: {
        if (settings.eagerLoading) {
            cli.getItems();
            displayLoadingVaultItems();
        }

        if (settings.fastAuth) {
            cli.checkVaultUnlocked();
        }

        if (settings.useSystemAuth && settings.useAuthorizationOnUnlocked) {
            authChecker.checkAuth();
        }
    }

    onStatusChanged: {
        if (status == PageStatus.Active) {
            if (loaded) {
                cli.getItems();
            }

            loaded = true;

            pageStack.pushAttached("SettingsPage.qml");
            while (doAfterLoad.length) {
                const callable = doAfterLoad.shift();
                callable();
            }

            // todo remove
            pageStack.push("AddItemPage.qml", {type: BitwardenCli.Login});
        }
    }
}
