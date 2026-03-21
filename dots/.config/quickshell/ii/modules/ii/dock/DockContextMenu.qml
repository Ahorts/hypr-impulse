import QtQuick
import QtQuick.Layouts
import Qt5Compat.GraphicalEffects
import qs.services
import qs.modules.common
import qs.modules.common.widgets
import Quickshell
import Quickshell.Hyprland
import Quickshell.Widgets
import qs

Loader {
    id: root

    property var  appToplevel:  null
    property var  desktopEntry: null
    property Item anchorItem:   parent

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

    onActiveChanged: {
        if (!root.active) root.closed()
    }

    active:  false
    visible: active

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
            id: focusGrab
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

            implicitWidth:  menuColumn.implicitWidth  + (appName.Layout.leftMargin * 2) + (menuMargin * 2)
            implicitHeight: menuColumn.implicitHeight + appName.Layout.topMargin + menuMargin * 2

            opacity: 0.0
            scale:   0.8

            transformOrigin: Item.Center

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

                // App name header
                Item {
                    id: appName
                    Layout.fillWidth:   true
                    Layout.topMargin:   menuContent.menuMargin
                    Layout.bottomMargin: menuContent.menuMargin
                    Layout.leftMargin:  2
                    Layout.rightMargin: 2
                    implicitHeight: appNameRow.implicitHeight
                    implicitWidth:  appNameRow.implicitWidth

                    RowLayout {
                        id: appNameRow
                        anchors {
                            left:            parent.left
                            verticalCenter:  parent.verticalCenter
                        }
                        spacing: 6

                        Item {
                            implicitWidth:    22
                            implicitHeight:   22
                            Layout.alignment: Qt.AlignLeft

                            IconImage {
                                id: menuAppIcon
                                anchors.fill: parent
                                source: root.appToplevel
                                    ? Quickshell.iconPath(TaskbarApps.getCachedIcon(root.appToplevel.appId), "image-missing")
                                    : ""
                                visible: !(Config.options.dock.monochromeIcons ?? false)
                            }

                            // Monochrome icon variant: desaturate then tint with the primary color
                            Loader {
                                active: Config.options.dock.monochromeIcons ?? false
                                anchors.fill: parent
                                sourceComponent: Item {
                                    anchors.fill: parent
                                    Desaturate {
                                        id: menuMonoDesat
                                        anchors.fill: parent
                                        source:       menuAppIcon
                                        desaturation: 0.8
                                        visible:      false
                                    }
                                    ColorOverlay {
                                        anchors.fill: menuMonoDesat
                                        source: menuMonoDesat
                                        color:  ColorUtils.transparentize(Appearance.colors.colPrimary, 0.9)
                                    }
                                }
                            }
                        }

                        StyledText {
                            text:           root.desktopEntry?.name ?? (root.appToplevel ? root.appToplevel.appId : "")
                            font.pixelSize: Appearance.font.pixelSize.small
                            color:          Appearance.colors.colOnLayer0
                            font.weight:    Font.DemiBold
                        }
                    }
                }

                Rectangle {
                    Layout.fillWidth:   true
                    Layout.bottomMargin: menuContent.menuMargin
                    implicitHeight: 1
                    color: Appearance.colors.colLayer0Border
                }

                // Desktop entry actions (e.g. "New Window", "New Private Window")
                Repeater {
                    model: root.desktopEntry?.actions ?? []
                    delegate: DockMenuButton {
                        required property var modelData
                        required property int index
                        Layout.fillWidth: true

                        readonly property var shapePool: [
                            "Flower", "Gem", "SoftBurst", "Clover4Leaf",
                            "Heart", "Puffy", "Diamond", "Pentagon",
                            "Cookie6Sided", "SoftBoom", "Bun", "PuffyDiamond"
                        ]

                        shapeString: shapePool[index % shapePool.length]
                        labelText:   modelData.name ?? ""
                        onTriggered: { modelData.execute(); root.close() }
                    }
                }

                Rectangle {
                    visible: (root.desktopEntry?.actions?.length ?? 0) > 0
                    Layout.fillWidth:    true
                    Layout.topMargin:    menuContent.menuMargin
                    Layout.bottomMargin: menuContent.menuMargin
                    implicitHeight: 1
                    color: Appearance.colors.colLayer0Border
                }

                DockMenuButton {
                    Layout.fillWidth: true
                    symbolName: "launch"
                    labelText:  qsTr("Launch")
                    onTriggered: { root.desktopEntry?.execute(); root.close() }
                }

                DockMenuButton {
                    Layout.fillWidth:  true
                    Layout.leftMargin: 2
                    symbolName: (root.appToplevel && TaskbarApps.isPinned(root.appToplevel.appId)) ? "keep_off" : "keep"
                    labelText:  (root.appToplevel && TaskbarApps.isPinned(root.appToplevel.appId)) ? qsTr("Unpin") : qsTr("Pin")
                    onTriggered: {
                        if (root.appToplevel) TaskbarApps.togglePin(root.appToplevel.appId)
                        root.close()
                    }
                }

                DockMenuButton {
                    visible: (root.appToplevel?.toplevels?.length ?? 0) > 0
                    Layout.fillWidth: true
                    symbolName: "close"
                    labelText: (root.appToplevel?.toplevels?.length ?? 0) > 1
                               ? qsTr("Close all windows") : qsTr("Close window")
                    isDestructive: true
                    onTriggered: {
                        if (root.appToplevel)
                            for (const t of root.appToplevel.toplevels) t.close()
                        root.close()
                    }
                }
            }
        }
    }
}
