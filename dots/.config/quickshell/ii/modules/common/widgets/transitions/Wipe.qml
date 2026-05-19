import QtQuick
import Qt5Compat.GraphicalEffects

Item {
    id: effect
    property Item frontImg
    property Item backImg
    property int duration

    property bool hideFront: true
    signal finished()

    function start() {
        maskContainer.layer.enabled = true
        wipeRect.width = 0
        wipeMask.visible = true
        
        revealAnim.from = 0
        revealAnim.to = effect.width
        revealAnim.restart()
    }

    function cleanup() {
        wipeMask.visible = false
        wipeRect.width = 0
        maskContainer.layer.enabled = false
    }

    NumberAnimation {
        id: revealAnim
        target: wipeRect
        property: "width"
        duration: effect.duration
        easing.type: Easing.Bezier
        easing.bezierCurve: [0.227, 0.877, 0.959, 0.310, 1.0, 1.0]
        onFinished: effect.finished()
    }

    Item {
        id: maskContainer
        width: effect.width
        height: effect.height
        visible: false
        layer.enabled: false

        Rectangle {
            id: wipeRect
            width: 0
            height: effect.height
            color: "black"
            x: 0
            y: 0
        }
    }

    OpacityMask {
        id: wipeMask
        anchors.fill: parent
        visible: false
        source: effect.frontImg
        maskSource: maskContainer
    }
}
