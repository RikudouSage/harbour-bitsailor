import QtQuick 2.0
import Sailfish.Silica 1.0

Item {
    function show(text, timeout) {
        if (!timeout) {
            timeout = 5000;
        }

        textLabel.text = text;
        notificationHideTimer.interval = timeout;
        notificationHideTimer.start();
        opacity = 1;
    }

    id: toaster
    opacity: 0
    z: 100

    Behavior on opacity {
        NumberAnimation {
            duration: 300
        }
    }

    Timer {
        id: notificationHideTimer
        running: false
        repeat: false

        onTriggered: {
            opacity = 0;
        }
    }

    Rectangle {
        color: "black"
        width: textLabel.width + Theme.horizontalPageMargin * 2
        x: Screen.width / 2 - width / 2
        y: Screen.height - Theme.itemSizeMedium
        height: textLabel.height + Theme.paddingSmall * 2
        radius: 20
        opacity: 0.9

        Label {
            anchors.centerIn: parent
            id: textLabel
            color: Theme.lightPrimaryColor
        }
    }
}
