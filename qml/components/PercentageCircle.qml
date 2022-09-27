
// ByteBau (Jörn Buchholz) @bytebau.com

import QtQuick 2.0
import QtQml 2.2
import Sailfish.Silica 1.0

import "../helpers.js" as Helpers

Item {
    id: root

    signal finished();

    width: size
    height: size
    property int total: 30
    property int current: total

    property color okColor: Theme.secondaryHighlightColor
    property color nearEndColor: Theme.errorColor

    property int size: Theme.iconSizeSmall
    property real arcBegin: 0
    property real arcEnd: current / total * 360
    property real arcOffset: 0
    property bool showBackground: false
    property real lineWidth: Theme.paddingSmall / 3
    property color colorCircle: current < 5 ? nearEndColor : okColor
    property string colorBackground: "#779933"

    property alias beginAnimation: animationArcBegin.enabled
    property alias endAnimation: animationArcEnd.enabled

    property int animationDuration: 200

    onArcBeginChanged: canvas.requestPaint()
    onArcEndChanged: canvas.requestPaint()

    function start(current, total) {
        root.current = current;
        root.total = total;
        timer.start();
    }

    function stop() {
        timer.stop();
    }

    onCurrentChanged: {
        if (current === 0) {
            root.finished();
        }
    }

    Timer {
        id: timer
        running: false
        interval: 1000
        repeat: true

        onTriggered: {
            current -= 1;
            if (current === 0) {
                current = total;
            }

            console.log(current, Helpers.totpRemainingTime(30));
        }
    }

    Behavior on arcBegin {
       id: animationArcBegin
       enabled: true
       NumberAnimation {
           duration: root.animationDuration
           easing.type: Easing.InOutCubic
       }
    }

    Behavior on arcEnd {
       id: animationArcEnd
       enabled: true
       NumberAnimation {
           duration: root.animationDuration
           easing.type: Easing.InOutCubic
       }
    }

    Canvas {
        id: canvas
        anchors.fill: parent
        rotation: -90 + parent.arcOffset

        onPaint: {
            var ctx = getContext("2d")
            var x = width / 2
            var y = height / 2
            var start = Math.PI * (parent.arcBegin / 180)
            var end = Math.PI * (parent.arcEnd / 180)
            ctx.reset()

            {
                if (root.showBackground) {
                    ctx.beginPath();
                    ctx.arc(x, y, (width / 2) - parent.lineWidth / 2, 0, Math.PI * 2, false)
                    ctx.lineWidth = root.lineWidth
                    ctx.strokeStyle = root.colorBackground
                    ctx.stroke()
                }
                ctx.beginPath();
                ctx.arc(x, y, (width / 2) - parent.lineWidth / 2, start, end, false)
                ctx.lineWidth = root.lineWidth
                ctx.strokeStyle = root.colorCircle
                ctx.stroke()
            }
        }
    }

    Label {
        text: current
        color: colorCircle
        anchors.centerIn: canvas
        font.pixelSize: Theme.fontSizeExtraSmall * 0.75
    }
}
