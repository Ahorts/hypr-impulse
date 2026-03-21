import qs.services
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.common.functions
import qs
import Qt5Compat.GraphicalEffects
import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Widgets

DockButton {
    id: root

    property var appToplevel:   null
    property var dockContent:   null
    property int delegateIndex: -1
    property int lastFocused:   -1

    property int iconSize:       Appearance.sizes.dockButtonSize
    property int dotMargin:      Math.round((Config.options?.dock.height ?? 60) * 0.2)
    property int countDotWidth:  Math.round((Config.options?.dock.height ?? 60) * 0.17)
    property int countDotHeight: Math.round((Config.options?.dock.height ?? 60) * 0.07)

    readonly property var desktopEntry: appToplevel
        ? TaskbarApps.getCachedDesktopEntry(appToplevel.appId)
        : null

    property bool isVertical: dockContent?.isVertical ?? false

    readonly property bool isDragging: dockContent?.draggedAppId === appToplevel?.appId

    property bool appIsActive: appToplevel && appToplevel.toplevels.find(t => t.activated === true) !== undefined

    readonly property int focusedWindowIndex: {
        if (!appToplevel || !appToplevel.toplevels) return -1
        for (let i = 0; i < appToplevel.toplevels.length; i++) {
            if (appToplevel.toplevels[i].activated) return i
        }
        return -1
    }

    readonly property bool appIsRunning: appToplevel && appToplevel.toplevels && appToplevel.toplevels.length > 0

    readonly property string dockPos: GlobalStates.dockEffectivePosition

    pointingHandCursor: false

    width:  buttonSize + dotMargin * 2
    height: buttonSize + dotMargin * 2

    opacity: isDragging ? 0.0 : 1.0

    Behavior on opacity {
        enabled: !isDragging && !(dockContent?.suppressAnimation ?? false)
        animation: Appearance.animation.elementMoveFast.numberAnimation.createObject(this)
    }

    z: isDragging ? 100 : 0

    // Computes how much this delegate should shift to make room for the dragged item
    readonly property real shiftOffset: {
        if (!dockContent || !dockContent.dragActive) return 0
        if (delegateIndex === dockContent.draggedIndex) return 0

        const step           = buttonSize + dotMargin * 2
        const isThisPinned   = TaskbarApps.isPinned(appToplevel?.appId ?? "")
        const isDraggedPinned = TaskbarApps.isPinned(dockContent.draggedAppId)
        const intent         = dockContent.dragIntent

        // Case 1: reordering among pinned apps
        if (isThisPinned && isDraggedPinned) {
            const d = dockContent.draggedIndex

            if (intent === "unpin") {
                if (delegateIndex > d) return step
                return 0
            }

            if (intent === "reorder") {
                const t = dockContent.dropTargetIndex
                if (t > d && delegateIndex > d && delegateIndex <= t) return  step
                if (t < d && delegateIndex >= t && delegateIndex < d) return -step
            }
            return 0
        }

        // Case 2: pinning a running app — shift running delegates out of the way
        if (!isDraggedPinned && !isThisPinned && intent === "pin") {
            if (delegateIndex > dockContent.draggedIndex) return -step
        }

        return 0
    }

    transform: Translate {
        x: root.isVertical ? 0 : root.shiftOffset
        y: root.isVertical ? root.shiftOffset : 0

        Behavior on x {
            enabled: !root.isDragging && !(dockContent?.suppressAnimation ?? false)
            NumberAnimation {
                duration:           Appearance.animation.elementMoveFast.duration
                easing.type:        Appearance.animation.elementMoveFast.type
                easing.bezierCurve: Appearance.animation.elementMoveFast.bezierCurve
            }
        }
        Behavior on y {
            enabled: !root.isDragging && !(dockContent?.suppressAnimation ?? false)
            NumberAnimation {
                duration:           Appearance.animation.elementMoveFast.duration
                easing.type:        Appearance.animation.elementMoveFast.type
                easing.bezierCurve: Appearance.animation.elementMoveFast.bezierCurve
            }
        }
    }

    MouseArea {
        id: mainMouseArea
        width:  root.buttonSize
        height: root.buttonSize
        anchors.centerIn: parent

        hoverEnabled:    true
        acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton
        preventStealing: drag.active

        drag.target:    appToplevel ? dockContent.dragGhostItem : null
        drag.axis:      root.isVertical ? Drag.YAxis : Drag.XAxis
        drag.threshold: 0

        readonly property real ghostHalf: (dockContent?.dragGhostItem?.width ?? 0) / 2

        drag.minimumX: root.isVertical ? 0 : (dockContent?.pinButtonCenter   ?? 0) - ghostHalf
        drag.maximumX: root.isVertical ? 0 : (dockContent?.unpinButtonCenter ?? 0) - ghostHalf
        drag.minimumY: root.isVertical ? (dockContent?.pinButtonCenter   ?? 0) - ghostHalf : 0
        drag.maximumY: root.isVertical ? (dockContent?.unpinButtonCenter ?? 0) - ghostHalf : 0

        property bool wasDragging: false

        onEntered: {
            if (dockContent?.suppressHover) return
            if (appToplevel?.toplevels?.length > 0) {
                dockContent.lastHoveredButton = root
                dockContent.buttonHovered     = true
            } else {
                dockContent.buttonHovered   = false
                dockContent.popupIsResizing = false
            }
            if (appToplevel && appToplevel.toplevels)
                lastFocused = appToplevel.toplevels.length - 1
        }

        onExited: {
            if (dockContent?.lastHoveredButton === root)
                dockContent.buttonHovered = false
        }

        onPressed: (mouse) => {
            wasDragging = false
            if (dockContent?.dragGhostItem && appToplevel) {
                const p = root.mapToItem(dockContent, 0, 0)
                dockContent.dragGhostItem.x = p.x + root.dotMargin
                dockContent.dragGhostItem.y = p.y + root.dotMargin
            }
        }

        onPositionChanged: (mouse) => {
            if (!drag.active || !appToplevel) return
            if (!wasDragging) {
                wasDragging = true
                dockContent.startDrag(root.appToplevel.appId, root.delegateIndex)
            }
            dockContent.moveDrag()
        }

        onReleased: (mouse) => {
            if (wasDragging) {
                wasDragging = false
                dockContent.endDrag()
                return
            }
            if (mouse.button === Qt.RightButton) {
                dockContent.buttonHovered     = false
                dockContent.lastHoveredButton = null
                dockContextMenu.open()
                return
            }
            if (mouse.button === Qt.MiddleButton) {
                root.desktopEntry?.execute()
                return
            }
            if (!appToplevel || appToplevel.toplevels.length === 0) {
                root.desktopEntry?.execute()
                return
            }
            // Cycle through open windows on left click
            lastFocused = (lastFocused + 1) % appToplevel.toplevels.length
            appToplevel.toplevels[lastFocused].activate()
        }
    }

    altAction: () => {
        dockContent.buttonHovered     = false
        dockContent.lastHoveredButton = null
        dockContextMenu.open()
    }

    DockContextMenu {
        id: dockContextMenu
        appToplevel:  root.appToplevel
        desktopEntry: root.desktopEntry
        anchorItem:   root
    }

    Connections {
        target: dockContextMenu
        function onActiveChanged() {
            if (dockContent)
                dockContent.anyContextMenuOpen = dockContextMenu.active
        }
    }

    contentItem: Loader {
        active: true
        sourceComponent: Item {
            anchors.fill: parent

            // ── Icon ─────────────────────────────────────────────────────
            Item {
                id: iconZone
                width:  root.buttonSize
                height: root.buttonSize
                anchors.centerIn: parent

                Item {
                    id: iconContainer
                    width:  root.iconSize
                    height: root.iconSize
                    anchors.centerIn: parent

                    IconImage {
                        id: baseIcon
                        anchors.fill: parent
                        source: Quickshell.iconPath(
                            TaskbarApps.getCachedIcon(root.appToplevel?.appId),
                            "image-missing"
                        )
                        visible: !(Config.options.dock.monochromeIcons ?? false)
                        opacity: root.appIsRunning ? 1.0
                                : (Config.options.dock.dimInactiveIcons ? 0.55 : 1.0)
                        Behavior on opacity {
                            animation: Appearance.animation.elementMoveFast.numberAnimation.createObject(this)
                        }
                    }

                    // Desaturated overlay for inactive pinned apps
                    Desaturate {
                        anchors.fill: parent
                        source:       baseIcon
                        desaturation: 0.8
                        visible: !root.appIsRunning
                            && !Config.options.dock.monochromeIcons
                            && Config.options.dock.dimInactiveIcons
                        opacity: baseIcon.opacity
                    }

                    // Monochrome icon: desaturate then tint with the primary color
                    Loader {
                        active: Config.options.dock.monochromeIcons
                        anchors.fill: parent
                        sourceComponent: Item {
                            Desaturate {
                                id: monoDesat
                                anchors.fill: parent
                                source:       baseIcon
                                desaturation: 0.8
                                visible:      false
                            }
                            ColorOverlay {
                                anchors.fill: monoDesat
                                source: monoDesat
                                color:  ColorUtils.transparentize(Appearance.colors.colPrimary, 0.9)
                            }
                        }
                    }
                }
            }

            // ── Window indicator dots ─────────────────────────────────────
            Item {
                id: indicatorContainer
                visible: root.appIsRunning

                readonly property int totalCount:    root.appToplevel ? root.appToplevel.toplevels.length : 0
                readonly property int maxVisibleDots: 5
                readonly property int visibleCount:  Math.min(totalCount, maxVisibleDots)
                readonly property int focusedIndex:  root.focusedWindowIndex

                // Use wider dots when there are 3 or fewer windows
                readonly property bool useWide: totalCount <= 3

                readonly property real baseDotW: root.isVertical
                    ? root.countDotHeight
                    : (useWide ? root.countDotWidth : root.countDotHeight)
                readonly property real baseDotH: root.isVertical
                    ? (useWide ? root.countDotWidth : root.countDotHeight)
                    : root.countDotHeight

                readonly property real dotSpacing: 3
                readonly property real pitchX: root.isVertical ? 0 : (baseDotW + dotSpacing)
                readonly property real pitchY: root.isVertical ? (baseDotH + dotSpacing) : 0

                // Keep the focused dot visible by sliding the window of visible dots
                readonly property int windowStart: {
                    if (totalCount <= maxVisibleDots) return 0
                    const centeredStart = focusedIndex - Math.floor(maxVisibleDots / 2)
                    const maxStart      = totalCount - maxVisibleDots
                    return Math.max(0, Math.min(maxStart, centeredStart))
                }
                readonly property bool hasHiddenLeft:  windowStart > 0
                readonly property bool hasHiddenRight: (windowStart + visibleCount) < totalCount

                width: root.isVertical
                    ? baseDotW
                    : (visibleCount * baseDotW + Math.max(0, visibleCount - 1) * dotSpacing)
                height: root.isVertical
                    ? (visibleCount * baseDotH + Math.max(0, visibleCount - 1) * dotSpacing)
                    : baseDotH

                x: root.isVertical
                    ? (root.dockPos === "left"
                        ? (root.dotMargin - width) / 2
                        : parent.width - width - (root.dotMargin - width) / 2)
                    : (parent.width - width) / 2

                y: root.isVertical
                    ? (parent.height - height) / 2
                    : (root.dockPos === "top"
                        ? (root.dotMargin - height) / 2
                        : parent.height - height - (root.dotMargin - height) / 2)

                Repeater {
                    model: indicatorContainer.visibleCount
                    delegate: Rectangle {
                        id: dotRect

                        readonly property int  absoluteIndex:  indicatorContainer.windowStart + index
                        readonly property bool isFocused:      absoluteIndex === indicatorContainer.focusedIndex

                        // Edge dots that hint at hidden windows are rendered smaller
                        readonly property bool isOverflowHint:
                            (index === 0 && indicatorContainer.hasHiddenLeft) ||
                            (index === indicatorContainer.visibleCount - 1 && indicatorContainer.hasHiddenRight)

                        readonly property real shrinkFactor: (isOverflowHint && !isFocused) ? 0.72 : 1.0

                        width:  indicatorContainer.baseDotW * shrinkFactor
                        height: indicatorContainer.baseDotH * shrinkFactor

                        radius: Appearance.rounding.full

                        x: root.isVertical
                            ? (indicatorContainer.baseDotW - width) / 2
                            : (index * indicatorContainer.pitchX + (indicatorContainer.baseDotW - width) / 2)

                        y: root.isVertical
                            ? (index * indicatorContainer.pitchY + (indicatorContainer.baseDotH - height) / 2)
                            : (indicatorContainer.baseDotH - height) / 2

                        color: (isFocused && indicatorContainer.focusedIndex >= 0)
                            ? Appearance.colors.colPrimary
                            : ColorUtils.transparentize(Appearance.colors.colOnLayer0, 0.4)

                        opacity: (isOverflowHint && !isFocused) ? 0.55 : 1.0

                        Behavior on color {
                            animation: Appearance.animation.elementMoveFast.colorAnimation.createObject(this)
                        }
                        Behavior on width {
                            animation: Appearance.animation.elementResize.numberAnimation.createObject(this)
                        }
                        Behavior on height {
                            animation: Appearance.animation.elementResize.numberAnimation.createObject(this)
                        }
                    }
                }
            }
        }
    }
}
