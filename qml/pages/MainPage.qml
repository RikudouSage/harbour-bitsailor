import QtQuick 2.0
import Sailfish.Silica 1.0

import cz.chrastecky.bitsailor 1.0

import "../components" as Components

Page {
    property string loadingMessage
    property bool loadItemsUsingApiOnceAvailable: false
    property bool checkUnlockUsingApiOnceAvailable: false
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

    function safeCall(callable) {
        if (page.status == PageStatus.Active && loaded) {
            callable();
        } else {
            doAfterLoad.push(callable);
        }
    }

    function onVaultSynced() {
        hideMessage();
        loginsCount = null;
        cardsCount = null;
        notesCount = null;
        identitiesCount = null;

        if (settings.eagerLoading) {
            // @disable-check M127
            settings.useApi ? api.getItems() : cli.getItems();
            displayLoadingVaultItems();
        }
    }

    function onVaultSyncFailed() {
        // todo
        hideMessage();
    }

    function onItemsResolved(items) {
        if (!currentCount) {
            hideMessage();
            doAfterLoad.push(function() { hideMessage(); });
            currentCount = "logins";
            // @disable-check M127
            settings.useApi ? api.getLogins() : cli.getLogins();
        } else {
            switch (currentCount) {
            case "logins":
                loginsCount = items.length;
                currentCount = "cards";
                // @disable-check M127
                settings.useApi ? api.getCards() : cli.getCards();
                break;
            case "cards":
                cardsCount = items.length;
                currentCount = "notes";
                // @disable-check M127
                settings.useApi ? api.getNotes() : cli.getNotes();
                break;
            case "notes":
                notesCount = items.length;
                currentCount = "identities";
                // @disable-check M127
                settings.useApi ? api.getIdentities() : cli.getIdentities();
                break;
            case "identities":
                identitiesCount = items.length;
                currentCount = "";
                initialLoadCompleted = true;
                break;
            }
        }
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
                return;
            }
        }
    }

    Connections {
        target: settings

        onUseApiChanged: {
            if (settings.useApi) {
                cli.serve(settings.forceUnsafeApi);
            } else {
                cli.stopServer();
            }
        }

        onForceUnsafeApiChanged: {
            if (settings.forceUnsafeApi && settings.useApi) {
                cli.serve(true);
            } else if (!settings.forceUnsafeApi) {
                cli.stopServer();
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

    BitwardenApi {
        id: api

        onApiNotRunning: {
            app.toaster.show(qsTr("The BitWarden server is not running,\nplease restart the app"), 100000);
        }

        onVaultSyncFailed: {
            page.onVaultSyncFailed();
        }

        onVaultSynced: {
            page.onVaultSynced();
        }

        onItemsResolved: {
            page.onItemsResolved(items);
        }

        onVaultLockStatusResolved: {
            page.onVaultLockStatusResolved(unlocked);
        }

        onIsRunningResult: {
            if (settings.eagerLoading) {
                if (running) {
                    api.getItems();
                } else {
                    loadItemsUsingApiOnceAvailable = true;
                }
            }
            if (settings.fastAuth) {
                if (running) {
                    api.checkVaultUnlocked();
                } else {
                    checkUnlockUsingApiOnceAvailable = true;
                }
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
            page.onItemsResolved(items);
        }

        onVaultSyncFailed: {
            page.onVaultSyncFailed();
        }

        onVaultSynced: {
            page.onVaultSynced();
        }

        onVaultLockStatusResolved: {
            page.onVaultLockStatusResolved(unlocked);
        }

        onServerStarted: {
            if (loadItemsUsingApiOnceAvailable) {
                api.getItems();
                loadItemsUsingApiOnceAvailable = false;
            }
            if (checkUnlockUsingApiOnceAvailable) {
                api.checkVaultUnlocked();
                checkUnlockUsingApiOnceAvailable = false;
            }
        }

        onServerShouldBePatched: {
            safeCall(function() {
                const dialog = pageStack.push("PatchServerPage.qml");
                dialog.accepted.connect(function() {
                    if (dialog.ignored) {
                        settings.forceUnsafeApi = true;
                    } else {
                        settings.forceUnsafeApi = false;
                        displayMessage(qsTr("Patching the server..."));
                        cli.patchServer();
                    }
                });
                dialog.rejected.connect(function() {
                    console.log('disabling api');
                    settings.useApi = false;
                });
            });
        }

        onServerPatched: {
            cli.serve(settings.forceUnsafeApi);
        }

        onServerPatchError: {
            safeCall(function() {
                const dialog = pageStack.push("PatchServerPage.qml", {
                    canOnlyIgnore: true,
                    description: qsTr("There was an error while patching the server, please contact the developer to let him know to fix it.<br><br>Meanwhile you can disable the server patch (<strong>which is not recommended because it poses a security risk</strong>) or you can cancel this disalog to disable api and use the CLI again."),
                });
                dialog.accepted.connect(function() {
                    settings.forceUnsafeApi = true;
                });
                dialog.rejected.connect(function() {
                    settings.useApi = false;
                });
            });
        }

        onServerUnpatchable: {
            safeCall(function() {
                const dialog = pageStack.push("PatchServerPage.qml", {
                    canOnlyIgnore: true,
                    description: qsTr("The BitWarden CLI is not installed locally and thus the server cannot be patched.<br><br>You can ignore this and continue using the api regardless <strong>but it poses a security risk</strong>.<br><br>The recommended approach is to <strong>cancel this dialog which will disable api</strong> altogether and you will fall back to using the CLI which is slower but safer."),
                });
                dialog.accepted.connect(function() {
                    settings.forceUnsafeApi = true;
                });
                dialog.rejected.connect(function() {
                    settings.useApi = false;
                });
            });
            console.log('server unpatchable');
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
                    settings.useApi ? api.syncVault() : cli.syncVault();
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
        if (settings.useApi) {
            cli.serve(settings.forceUnsafeApi);
        }

        if (settings.eagerLoading) {
            if (settings.useApi) {
                api.isRunning(); // handled async in onIsRunningResult
            } else {
                cli.getItems();
            }

            displayLoadingVaultItems();
        }

        if (settings.fastAuth) {
            if (settings.useApi) {
                api.isRunning(); // handled async in onIsRunningResult
            } else {
                cli.checkVaultUnlocked();
            }
        }

        if (settings.useSystemAuth && settings.useAuthorizationOnUnlocked) {
            authChecker.checkAuth();
        }
    }

    onStatusChanged: {
        if (status == PageStatus.Active) {
            if (loaded && initialLoadCompleted) {
                settings.useApi ? api.getItems() : cli.getItems();
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
