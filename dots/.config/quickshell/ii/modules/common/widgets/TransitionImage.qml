import QtQuick
import qs.services
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.common.functions

Item {
    id: root

    required property string imageSource

    property int animationDuration: 1000
    property var fillMode: Image.PreserveAspectCrop
    property bool animated: true
    property bool imgAIsBack: true

    onImageSourceChanged: fadeTo(imageSource)
    Component.onCompleted: imgA.source = imageSource

    function fadeTo(newSrc) {
        var back  = imgAIsBack ? imgA : imgB
        var front = imgAIsBack ? imgB : imgA

        if (newSrc === back.source) return

        front.source  = newSrc
        front.z       = 1
        back.z        = 0

        if (root.animated) {
            front.opacity = 0
            fadeAnim.target = front
            fadeAnim.restart()
        } else {
            front.opacity = 1
            root.imgAIsBack = !root.imgAIsBack
        }
    }

    NumberAnimation {
        id: fadeAnim
        property: "opacity"
        from: 0; to: 1
        duration: root.animationDuration
        easing.type: Easing.InOutQuad

        onFinished: {
            root.imgAIsBack = !root.imgAIsBack
        }
    }

    Image {
        id: imgA
        anchors.fill: parent
        fillMode: root.fillMode
        cache: false; antialiasing: true; asynchronous: true
    }

    Image {
        id: imgB
        anchors.fill: parent
        opacity: 0
        fillMode: root.fillMode
        cache: false; antialiasing: true; asynchronous: true
    }
}