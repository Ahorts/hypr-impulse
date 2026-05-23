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
        
        let marginX = effect.width * 0.25
        let marginY = effect.height * 0.25
        let cx = marginX + Math.random() * (effect.width - marginX * 2)
        let cy = marginY + Math.random() * (effect.height - marginY * 2)
        circleMask.centerX = cx
        circleMask.centerY = cy

        let d1 = Math.sqrt(cx * cx + cy * cy)
        let d2 = Math.sqrt((effect.width - cx) * (effect.width - cx) + cy * cy)
        let d3 = Math.sqrt(cx * cx + (effect.height - cy) * (effect.height - cy))
        let d4 = Math.sqrt((effect.width - cx) * (effect.width - cx) + (effect.height - cy) * (effect.height - cy))
        let targetDiameter = Math.ceil(Math.max(d1, d2, d3, d4)) * 2
        let targetScale = targetDiameter / circleMask.width

        circleMask.scale = 0
        wipeMask.visible = true

        revealAnim.from = 0
        revealAnim.to = targetScale
        revealAnim.restart()
    }

    function cleanup() {
        wipeMask.visible = false
        circleMask.scale = 0
        maskContainer.layer.enabled = false
    }

    NumberAnimation {
        id: revealAnim
        target: circleMask
        property: "scale"
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
            x: circleMask.centerX
            y: circleMask.centerY
            width: 1
            height: 1

            Rectangle {
                id: circleMask
                anchors.centerIn: parent
                width: 200
                height: 200
                color: "black"
                scale: 0
                rotation: 45
                transformOrigin: Item.Center

                property real centerX: effect.width / 2
                property real centerY: effect.height / 2
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
