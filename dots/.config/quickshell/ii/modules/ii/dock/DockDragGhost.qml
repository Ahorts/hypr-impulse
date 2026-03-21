import Qt5Compat.GraphicalEffects
import QtQuick
import Quickshell
import Quickshell.Widgets
import qs.modules.common
import qs.modules.common.widgets
import qs.services
import qs.modules.common.functions

Item {
    id: root
    width:  Appearance.sizes.dockButtonSize
    height: Appearance.sizes.dockButtonSize

    property string draggedAppId: ""
    property bool   willUnpin:    false

    property bool   isFile:           false
    property bool   fileIsImage:      false
    property string filePath:         ""
    property string fileResolvedIcon: ""

    Item {
        anchors.fill: parent
        visible: !root.isFile

        IconImage {
            id: ghostIcon
            anchors.centerIn: parent
            implicitSize: Appearance.sizes.dockButtonSize
            source: draggedAppId !== ""
                ? Quickshell.iconPath(TaskbarApps.getCachedIcon(draggedAppId), "image-missing")
                : ""
        }

        Loader {
            active: Config.options.dock.monochromeIcons
            anchors.fill: ghostIcon
            sourceComponent: Item {
                Desaturate {
                    id: desaturatedIcon
                    visible: false
                    anchors.fill: parent
                    source: ghostIcon
                    desaturation: 0.8
                }
                ColorOverlay {
                    anchors.fill: desaturatedIcon
                    source: desaturatedIcon
                    color: ColorUtils.transparentize(Appearance.colors.colPrimary, 0.9)
                }
            }
        }
    }

    Item {
        anchors.fill: parent
        visible: root.isFile

        Image {
            id: ghostThumbnail
            anchors.fill: parent
            visible:      root.fileIsImage
            source:       root.fileIsImage ? ("file://" + root.filePath) : ""
            fillMode:     Image.PreserveAspectCrop
            asynchronous: true
            cache:        true
            sourceSize:   Qt.size(Appearance.sizes.dockButtonSize * 2, Appearance.sizes.dockButtonSize * 2)

            layer.enabled: true
            layer.effect: OpacityMask {
                maskSource: Rectangle {
                    width:  ghostThumbnail.width
                    height: ghostThumbnail.height
                    radius: Appearance.rounding.small
                }
            }
        }

        MaterialSymbol {
            anchors.centerIn: parent
            visible:  root.fileIsImage && ghostThumbnail.status !== Image.Ready
            text:     "image"
            iconSize: Appearance.sizes.dockButtonSize
            color:    Appearance.colors.colOnLayer0
        }

        IconImage {
            anchors.fill: parent
            visible:  !root.fileIsImage
            source:   root.fileResolvedIcon
        }
    }
}
