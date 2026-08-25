import QtQuick 2.0
import Sailfish.Silica 1.0

import cz.chrastecky.bitsailor 1.0

Page {
    property var allLogins: []
    property var logins: []
    property bool loaded: false
    property string errorText

    property bool searchActive: false
    property string searchText: ""

    property string itemLoader: "getItems"
    property string title: qsTr("Vault")

    property string addItemTitle: qsTr("Add item")
    property int addItemType: BitSailorCore.ItemTypeNone
    property bool addItemEnabled: true

    id: page
    allowedOrientations: Orientation.All

    function itemMatchesSearch(item, text) {
        if (typeof item.login === 'undefined') {
            item.login = {};
        }
        if (typeof item.card === 'undefined') {
            item.card = {number: ''};
        }

        const searchable = [
            item.name,
            item.login.username,
            item.card.number.slice(-4),
            item.card.brand,
        ];
        var index;
        for (index in item.fields || []) {
            if (!item.fields.hasOwnProperty(index)) {
                continue;
            }
            searchable.push(item.fields[index].name, item.fields[index].value)
        }
        for (index in item.login.uris || []) {
            if (!item.login.uris.hasOwnProperty(index)) {
                continue;
            }
            searchable.push(item.login.uris[index].uri);
        }

        for (index in searchable) {
            if (!searchable.hasOwnProperty(index)) {
                continue;
            }
            if (String(searchable[index]).toLocaleLowerCase().indexOf(text.toLocaleLowerCase()) > -1) {
                return true;
            }
        }

        return false;
    }

    function applySearchFilter() {
        if (!searchText) {
            logins = allLogins;
            return;
        }

        logins = allLogins.filter(function(item) {
            return itemMatchesSearch(item, searchText);
        });
    }

    BusyLabel {
        id: loader
        text: qsTr("Loading")
        running: !loaded
    }

    Connections {
        target: core

        onItemsResolved: {
            if (page.status !== PageStatus.Active && page.status !== PageStatus.Activating) {
                return;
            }

            var wantedType = 0;

            switch (itemLoader) {
            case 'getLogins':
                wantedType = BitSailorCore.ItemTypeLogin;
                break;
            case 'getCards':
                wantedType = BitSailorCore.ItemTypeCard;
                break;
            case 'getNotes':
                wantedType = BitSailorCore.ItemTypeSecureNote;
                break;
            case 'getIdentities':
                wantedType = BitSailorCore.ItemTypeIdentity;
                break;
            }

            if (wantedType !== 0) {
                items = items.filter(function(item) {
                    return item.type === wantedType;
                });
            }

            allLogins = items;
            applySearchFilter();
            loaded = true;
        }

        onItemResolvingFailed: {
            if (page.status !== PageStatus.Active && page.status !== PageStatus.Activating) {
                return;
            }
            errorText = qsTr("An error occured while loading items. Please try again.")
            loaded = true;
        }

        onSyncVaultFinished: {
            if (!success) {
                errorText = qsTr("There was an error while synchronizing the vault, please try again.");
                return;
            }

            core.fetchItems();
        }

        onItemCreationFinished: {
            if (page.status !== PageStatus.Active && page.status !== PageStatus.Activating) {
                return;
            }

            if (success) {
                loaded = false;
                core.fetchItems();
            } else {
                loaded = true;
                errorText = qsTr("There was an error when creating the new item");
            }
        }
    }

    SilicaListView {
        id: listView
        anchors.fill: parent
        visible: !loader.running
        model: logins

        VerticalScrollDecorator {}

        PullDownMenu {
            MenuItem {
                text: addItemTitle
                visible: addItemEnabled
                onClicked: {
                    const dialog = pageStack.push("EditItemPage.qml", {type: addItemType});
                    dialog.accepted.connect(function() {
                        const object = JSON.parse(JSON.stringify(dialog.itemTemplate));
                        const type = dialog.type;
                        switch (type) {
                        case BitSailorCore.ItemTypeLogin:
                            object.login = JSON.parse(JSON.stringify(dialog.loginItemTemplate));
                            object.login.password = dialog.loginPasswordValue || null;
                            object.login.totp = dialog.loginTotpValue || null;
                            object.login.username = dialog.loginUsernameValue || null;
                            object.login.uris = dialog.getUris() || null;
                            break;
                        case BitSailorCore.ItemTypeSecureNote:
                            object.secureNote = JSON.parse(JSON.stringify(dialog.secureNoteItemTemplate));
                            break;
                        case BitSailorCore.ItemTypeCard:
                            object.card = JSON.parse(JSON.stringify(dialog.cardItemTemplate));
                            object.card.cardholderName = dialog.cardCardholderNameValue || null;
                            object.card.brand = dialog.cardBrandValue || null;
                            object.card.number = dialog.cardNumberValue || null;
                            object.card.expMonth = dialog.cardExpirationMonthValue || null;
                            object.card.expYear = dialog.cardExpirationYearValue || null;
                            object.card.code = dialog.cardCvvValue || null
                            break;
                        }

                        object.type = dialog.type;
                        object.name = dialog.nameValue;
                        object.notes = dialog.loginNotesValue || dialog.secureNoteNoteValue || null;
                        object.fields = dialog.getFields();

                        loaded = false;
                        errorText = "";
                        core.createItem(object);
                    });
                }
            }

        }

        header: Column {
            width: listView.width
            spacing: Theme.paddingLarge

            PageHeader {
                title: page.title
            }

            Label {
                x: Theme.horizontalPageMargin
                text: errorText
                visible: errorText.length
                color: Theme.errorColor
                wrapMode: Label.WordWrap
                width: parent.width - Theme.horizontalPageMargin * 2
            }

            SearchField {
                id: search

                function focusIfRequested() {
                    if (searchActive && listView.visible) {
                        forceActiveFocus();
                    }
                }

                width: parent.width - Theme.horizontalPageMargin * 2
                placeholderText: qsTr("Search")
                active: true
                focus: searchActive
                text: searchText

                onTextChanged: {
                    searchText = text;
                    applySearchFilter();
                }

                onVisibleChanged: {
                    focusTimer.restart();
                }

                Component.onCompleted: {
                    focusTimer.restart();
                }

                Connections {
                    target: page

                    onSearchActiveChanged: {
                        focusTimer.restart();
                    }
                }

                Timer {
                    id: focusTimer
                    interval: 1
                    repeat: false
                    onTriggered: search.focusIfRequested()
                }
            }

            Item {
                width: parent.width
                height: Theme.paddingLarge
            }
        }

        delegate: ListItem {
            property var item: modelData
            property bool failed: item.decryptionError !== null && typeof item.decryptionError !== 'undefined'

            function remove() {
                var removedId = item.id;
                remorseDelete(function() {
                    core.deleteItem(removedId, false);
                    allLogins = allLogins.filter(function(item) {
                        return item.id !== removedId;
                    });
                    applySearchFilter();
                });
            }

            function errorText() {
                return qsTr("error fetching %1: %2").arg(item.id).arg(item.decryptionError);
            }

            id: listItem
            menu: contextMenu
            width: listView.width - Theme.horizontalPageMargin * 2
            x: Theme.horizontalPageMargin

            contentHeight: Theme.itemSizeMedium

            onClicked: {
                if (!failed) {
                    pageStack.push("ItemDetailPage.qml", {itemId: item.id});
                }
            }

            Label {
                id: itemTitle
                text: failed ? qsTr("invalid item (decryption failed): %1").arg(item.id) : item.name
                color: failed ? Theme.errorColor : Theme.primaryColor
            }

            Label {
                anchors.top: itemTitle.bottom
                text: typeof item.login !== 'undefined' ? item.login.username || '' : ''
                font.pixelSize: Theme.fontSizeSmall
                color: Theme.secondaryHighlightColor
                visible: !failed && item.type === BitSailorCore.ItemTypeLogin
            }

            Label {
                anchors.top: itemTitle.bottom
                text: {
                    if (typeof item.card === 'undefined') {
                        return '';
                    }

                    var result = item.card.brand || '';
                    if (result && item.card.number) {
                        result += ', ';
                    }
                    result += item.card.number ? '*' + item.card.number.slice(-4) : '';

                    return result;
                }

                font.pixelSize: Theme.fontSizeSmall
                color: Theme.secondaryHighlightColor
                visible: !failed && item.type === BitSailorCore.ItemTypeCard
            }

            Label {
                anchors.top: itemTitle.bottom
                text: typeof item.identity !== 'undefined' ? [item.identity.firstName || '', item.identity.lastName || ''].filter(function(item) {
                    return item !== '';
                }).join(' ') : ''
                font.pixelSize: Theme.fontSizeSmall
                color: Theme.secondaryHighlightColor
                visible: !failed && item.type === BitSailorCore.ItemTypeIdentity
            }

            Component {
                 id: contextMenu
                 ContextMenu {
                     IconMenuItem {
                         text: qsTr("Copy error")
                         icon.source: "image://theme/icon-m-clipboard"
                         visible: failed

                         onClicked: {
                             Clipboard.text = errorText();
                             app.toaster.show(qsTr("Copied to clipboard"));
                         }
                     }

                     IconMenuItem {
                         text: qsTr("Remove")
                         icon.source: "image://theme/icon-m-remove"

                         onClicked: {
                             remove();
                         }
                     }
                 }
            }
        }
    }

    Component.onCompleted: {
        core.fetchItems();
    }
}
