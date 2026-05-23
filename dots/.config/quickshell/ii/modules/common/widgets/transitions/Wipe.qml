import QtQuick
import Qt5Compat.GraphicalEffects
import qs.modules.common

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
        revealAnim.to = pivot.diagonal
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
        easing.type: Easing.BezierSpline
        easing.bezierCurve: [0.227, 0.877, 0.959, 0.310, 1.0, 1.0]
        onFinished: effect.finished()
    }

    Item {
        id: maskContainer
        width: effect.width
        height: effect.height
        visible: false
        layer.enabled: false

        Item {
            id: pivot
            x: effect.width / 2
            y: effect.height / 2
            rotation: Config.options.background.wipeAngle ?? 0
            
            property real diagonal: Math.ceil(Math.sqrt(effect.width * effect.width + effect.height * effect.height))

            Rectangle {
                id: wipeRect
                color: "black"
                height: pivot.diagonal
                y: -pivot.diagonal / 2
                x: -pivot.diagonal / 2
                width: 0
            }
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
