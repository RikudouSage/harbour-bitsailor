import QtQuick 2.0
import Sailfish.Silica 1.0

import cz.chrastecky.bitsailor 1.0

import "../components" as Components
import "../helpers.js" as Helpers

Page {
    property var safeCall: Helpers.safeCallerFactory(doAfterLoad, page, function() {
        return loaded;
    });

    property string loadingMessage
    property bool initialLoadCompleted: false

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

    function onVaultSynced() {
        hideMessage();
        loginsCount = null;
        cardsCount = null;
        notesCount = null;
        identitiesCount = null;

        core.fetchItems();
    }

    function onVaultSyncFailed() {
        // todo
        hideMessage();
    }

    function onItemsResolved(items) {
        safeCall(function() {
            hideMessage();

            loginsCount = 0;
            cardsCount = 0;
            notesCount = 0;
            identitiesCount = 0;

            console.log(JSON.stringify(items))

            for (var i in items) {
                if (!items.hasOwnProperty(i)) {
                    continue;
                }
                const item = items[i];

                switch (item.type) {
                case BitSailorCore.ItemTypeLogin:
                    ++loginsCount;
                    break;
                case BitSailorCore.ItemTypeCard:
                    ++cardsCount;
                    break;
                case BitSailorCore.ItemTypeSecureNote:
                    ++notesCount;
                    break;
                case BitSailorCore.ItemTypeIdentity:
                    ++identitiesCount;
                    break;
                }
            }


            initialLoadCompleted = true;
        });
    }

    function onVaultLockStatusResolved(unlocked) {
        if (!unlocked) {
            runtimeCache.remove(CacheKey.Items);
            runtimeCache.removePersistent(CacheKey.Items);
            secrets.removeSessionId();

            var handle = function() {
                pageStack.replace("LoginCheckPage.qml");
            };
            // @disable-check M127
            loaded ? handle() : doAfterLoad.push(handle);
            return;
        }

        if (app.fileToShare || app.textToShare) {
            safeCall(function() {
                pageStack.push("CreateSendChooseTypePage.qml");
            });
        }
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
                return;
            }
        }
    }

    Connections {
        target: app
        onFileToShareChanged: {
            if (!app.fileToShare) {
                return;
            }

            safeCall(function() {
                pageStack.push("CreateSendChooseTypePage.qml");
            });
        }
        onTextToShareChanged: {
            if (!app.textToShare) {
                return;
            }
            safeCall(function() {
                pageStack.push("CreateSendChooseTypePage.qml");
            });
        }
    }

    Connections {
        target: core

        onLoginStatusFetched: {
            if (status != BitSailorCore.SessionStatusUnlocked) {
                redoLogin();
                return;
            }

            core.fetchItems();
        }

        onItemsResolved: {
            page.onItemsResolved(items);
        }

        onItemResolvingFailed: {
            page.onVaultSyncFailed();
        }

        onLogoutFinished: {
            redoLogin();
        }

        onVaultLocked: {
            redoLogin();
        }

        onSyncVaultFinished: {
            if (success) {
                page.onVaultSynced();
                return;
            }

            page.onVaultSyncFailed();
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
                    core.logout();
                }
            }

            MenuItem {
                text: qsTr("Lock")
                onClicked: {
                    displayPleaseWait();
                    core.lockVault();
                }
            }

            MenuItem {
                text: qsTr("Sync Vault")
                onClicked: {
                    displayMessage(qsTr("Syncing vault"));
                    core.syncVault();
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
                        addItemType: BitSailorCore.ItemTypeLogin,
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
                        addItemType: BitSailorCore.ItemTypeCard,
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
                        addItemType: BitSailorCore.ItemTypeSecureNote,
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
                        addItemType: BitSailorCore.ItemTypeIdentity,
                        addItemEnabled: false,
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
        if (settings.useSystemAuth && settings.useAuthorizationOnUnlocked) {
            authChecker.checkAuth();
        }

        core.getLoginStatus();
    }

    onStatusChanged: {
        if (status == PageStatus.Active) {
            if (loaded && initialLoadCompleted) {
                core.fetchItems();
            }

            loaded = true;

            pageStack.pushAttached("SettingsPage.qml");
            while (doAfterLoad.length) {
                const callable = doAfterLoad.shift();
                callable();
            }
        }
    }
}
