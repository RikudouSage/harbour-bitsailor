function xor(a, b) {
    return (a && !b) || (b && !a);
}

// todo: rename? the name may be misleading because it doesn't filter out data but instead constructs a new structure
// using only data needed by ui
function filterOutSensitiveItems(rawData) {
    var newData = [];
    var data = JSON.parse(rawData);

    for (var i = 0; i < data.length; ++i) {
        var item = data[i];
        var newItem = {};

        newItem.object = item.object;
        newItem.id = item.id;
        newItem.type = item.type;
        newItem.name = item.name;

        if (typeof item.login !== "undefined") {
            newItem.login = {};
            newItem.login.username = item.login.username;
            newItem.login.uris = item.login.uris;
        }

        if (typeof item.card !== "undefined") {
            newItem.card = {};
            newItem.card.cardholderName = item.card.cardholderName;
            newItem.card.brand = item.card.brand;
            newItem.card.number = item.card.number.slice(-4);
        }

        if (typeof item.identity !== "undefined") {
            newItem.identity = {};
            newItem.identity.firstName = item.identity.firstName;
            newItem.identity.middleName = item.identity.middleName;
            newItem.identity.lastName = item.identity.lastName;
        }

        newData.push(newItem);
    }

    return JSON.stringify(newData);
}
