import QtQuick

SequentialAnimation {
    id: root
    property Item target
    property string propertyName: "scale"
    property real peak: 1.1
    property int totalDuration: 250

    NumberAnimation {
        target: root.target
        property: root.propertyName
        to: root.peak
        duration: root.totalDuration / 2
        easing.type: Easing.OutCubic
    }
    NumberAnimation {
        target: root.target
        property: root.propertyName
        to: 1
        duration: root.totalDuration / 2
        easing.type: Easing.OutCubic
    }
}
