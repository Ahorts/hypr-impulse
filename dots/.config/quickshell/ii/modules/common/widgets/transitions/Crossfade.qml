import QtQuick

Item {
    id: effect
    property Item frontImg
    property Item backImg
    property int duration

    property bool hideFront: false
    property bool waitForReady: false
    signal finished()

    function start() {
        frontImg.opacity = 0
        fadeAnim.restart()
    }

    function cleanup() {
        fadeAnim.stop()
    }

    NumberAnimation {
        id: fadeAnim
        target: effect.frontImg
        property: "opacity"
        from: 0
        to: 1
        duration: effect.duration
        easing.type: Easing.InOutQuad
        onFinished: effect.finished()
    }
}
