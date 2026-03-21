import QtQuick
import QtQuick.Layouts
import Qt5Compat.GraphicalEffects
import qs.modules.common
import qs.modules.common.widgets
import Quickshell
import Quickshell.Hyprland
import Quickshell.Widgets
import qs.services
import qs

Loader {
    id: root

    property string filePath:   ""
    property Item   anchorItem: parent

    property bool isClosing: false

    signal closed()

    function open() {
        if (active && !isClosing) return
        isClosing = false
        active    = true
        if (root.item) root.item.startOpenAnimation()
    }

    function close() {
        if (!active || isClosing) return
        isClosing = true
        if (root.item) root.item.startCloseAnimation()
    }

    onActiveChanged: { if (!root.active) root.closed() }

    active:  false
    visible: active

    readonly property string fileName: {
        const parts = (filePath ?? "").split("/").filter(s => s.length > 0)
        return parts[parts.length - 1] ?? filePath
    }

    readonly property string containingDir: {
        const idx = (filePath ?? "").lastIndexOf("/")
        return idx > 0 ? filePath.substring(0, idx) : ""
    }

    sourceComponent: PopupWindow {
        id: popupWindow
        visible: true
        color: "transparent"

        property real dockMargin:   -16
        property real shadowMargin:  20

        anchor {
            adjustment: PopupAdjustment.None
            window: root.anchorItem?.QsWindow.window
            onAnchoring: {
                const item   = root.anchorItem
                if (!item) return
                const pos    = GlobalStates.dockEffectivePosition
                const win    = item.QsWindow.window
                const mapped = item.mapToItem(null, item.width / 2, item.height / 2)
                const dm     = popupWindow.dockMargin
                const dock   = (pos === "left" || pos === "right") ? win.width / 2 : win.height / 2

                if (pos === "bottom") {
                    anchor.rect.x = mapped.x - popupWindow.implicitWidth / 2
                    anchor.rect.y = mapped.y - dock - popupWindow.implicitHeight - dm
                } else if (pos === "top") {
                    anchor.rect.x = mapped.x - popupWindow.implicitWidth / 2
                    anchor.rect.y = mapped.y + dock + dm
                } else if (pos === "left") {
                    anchor.rect.x = mapped.x + dock + dm
                    anchor.rect.y = mapped.y - popupWindow.implicitHeight / 2
                } else {
                    anchor.rect.x = mapped.x - dock - popupWindow.implicitWidth - dm
                    anchor.rect.y = mapped.y - popupWindow.implicitHeight / 2
                }
            }
        }

        implicitWidth:  menuContent.implicitWidth  + popupWindow.shadowMargin * 2
        implicitHeight: menuContent.implicitHeight + popupWindow.shadowMargin * 2

        function startOpenAnimation() {
            menuContent.scale   = 1.0
            menuContent.opacity = 1.0
        }

        function startCloseAnimation() {
            menuContent.scale   = 0.8
            menuContent.opacity = 0.0
        }

        HyprlandFocusGrab {
            active:  root.active && !root.isClosing
            windows: [popupWindow]
            onCleared: root.close()
        }

        StyledRectangularShadow {
            target:  menuContent
            opacity: menuContent.opacity
            visible: menuContent.visible
        }

        Rectangle {
            id: menuContent
            property real menuMargin: 8
            anchors.centerIn: parent
            color:  Appearance.m3colors.m3surfaceContainer
            radius: Appearance.rounding.normal
            implicitWidth:  menuColumn.implicitWidth  + (fileNameRow.Layout.leftMargin * 2) + (menuMargin * 2)
            implicitHeight: menuColumn.implicitHeight + fileNameRow.Layout.topMargin + menuMargin * 2

            opacity: 0.0
            scale:   0.8
            transformOrigin: Item.Center

            // Switch animation curve based on open/close state
            readonly property var currentAnimConfig: root.isClosing
                ? Appearance.animation.elementMoveExit
                : Appearance.animation.elementMoveEnter

            Component.onCompleted: startOpenAnimation()

            Behavior on opacity {
                NumberAnimation {
                    duration:           menuContent.currentAnimConfig.duration
                    easing.type:        menuContent.currentAnimConfig.type
                    easing.bezierCurve: menuContent.currentAnimConfig.bezierCurve
                }
            }

            Behavior on scale {
                NumberAnimation {
                    duration:           menuContent.currentAnimConfig.duration
                    easing.type:        menuContent.currentAnimConfig.type
                    easing.bezierCurve: menuContent.currentAnimConfig.bezierCurve
                }
            }

            // Deactivate the loader only after the close animation finishes
            onOpacityChanged: {
                if (opacity === 0.0 && root.isClosing) {
                    root.active    = false
                    root.isClosing = false
                }
            }

            ColumnLayout {
                id: menuColumn
                anchors.fill: parent
                anchors.leftMargin:   menuContent.menuMargin
                anchors.rightMargin:  menuContent.menuMargin
                anchors.topMargin:    menuContent.menuMargin / 2
                anchors.bottomMargin: menuContent.menuMargin
                spacing: 0

                // Header: MIME icon + file name
                Item {
                    id: fileNameRow
                    Layout.fillWidth:    true
                    Layout.topMargin:    menuContent.menuMargin
                    Layout.bottomMargin: menuContent.menuMargin
                    Layout.leftMargin:   2
                    Layout.rightMargin:  2
                    implicitHeight: nameRowLayout.implicitHeight
                    implicitWidth:  nameRowLayout.implicitWidth

                    RowLayout {
                        id: nameRowLayout
                        anchors {
                            left:           parent.left
                            verticalCenter: parent.verticalCenter
                        }
                        spacing: 6

                        MaterialSymbol {
                            text:     root.anchorItem?.mimeIcon ?? "insert_drive_file"
                            iconSize: 22
                            color:    Appearance.colors.colOnLayer0
                        }

                        StyledText {
                            text:                root.fileName
                            font.pixelSize:      Appearance.font.pixelSize.small
                            color:               Appearance.colors.colOnLayer0
                            font.weight:         Font.DemiBold
                            elide:               Text.ElideMiddle
                            Layout.maximumWidth: 200
                        }
                    }
                }

                Rectangle {
                    Layout.fillWidth:    true
                    Layout.bottomMargin: menuContent.menuMargin
                    implicitHeight: 1
                    color: Appearance.colors.colLayer0Border
                }

                DockMenuButton {
                    Layout.fillWidth: true
                    symbolName: "open_in_new"
                    labelText:  qsTr("Open")
                    onTriggered: {
                        Qt.openUrlExternally("file://" + root.filePath)
                        root.close()
                    }
                }

                DockMenuButton {
                    Layout.fillWidth: true
                    symbolName: "folder_open"
                    labelText:  qsTr("Open containing folder")
                    visible:    root.containingDir !== ""
                    onTriggered: {
                        Qt.openUrlExternally("file://" + root.containingDir)
                        root.close()
                    }
                }

                Rectangle {
                    Layout.fillWidth:    true
                    Layout.topMargin:    menuContent.menuMargin
                    Layout.bottomMargin: menuContent.menuMargin
                    implicitHeight: 1
                    color: Appearance.colors.colLayer0Border
                }

                DockMenuButton {
                    Layout.fillWidth: true
                    symbolName:    "do_not_disturb_on"
                    labelText:     qsTr("Remove from dock")
                    isDestructive: true
                    onTriggered: {
                        TaskbarApps.removePinnedFile(root.filePath)
                        root.close()
                    }
                }
            }
        }
    }
}
