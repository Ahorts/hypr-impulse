import QtQuick

QtObject {
    id: root
    property bool trigger: false
    property bool returnOnTrue: false
    property Animation animation

    onTriggerChanged: {
        if (returnOnTrue && trigger || !returnOnTrue && !trigger) return
        if (animation) animation.restart()
    }
}
