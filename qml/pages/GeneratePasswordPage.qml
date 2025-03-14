import QtQuick 2.0
import Sailfish.Silica 1.0

import "../components" as Components

Page {
    property bool loaded: !generator.loading

    id: page
    allowedOrientations: Orientation.All

    Components.GeneratePasswordTabs {
        id: generator
        height: parent.height - app.bottomMenuRef.height
    }
}
