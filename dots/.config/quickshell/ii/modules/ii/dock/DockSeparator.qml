import QtQuick
import qs.modules.common
import qs.services
import qs

Rectangle {
    id: root
    anchors.fill: parent
    color: "transparent"

    readonly property bool   isVertical: GlobalStates.dockIsVertical
    readonly property string dockPos:    GlobalStates.dockEffectivePosition

    property alias isResizing: dragArea.pressed

    onIsResizingChanged: {
        GlobalStates.dockIsResizing = isResizing
    }

    // Visual separator line: full length, 15% margin on the short sides
    Rectangle {
        readonly property real sepMargin: Math.round((root.isVertical
            ? root.width : root.height) * 0.15)

        anchors.centerIn: parent
        width:  root.isVertical ? root.width  - sepMargin * 2 : root.width
        height: root.isVertical ? root.height : root.height - sepMargin * 2
        radius: Appearance.rounding.full
        color:  Appearance.colors.colOutlineVariant
    }

    // Drag area extends beyond the visible line for easier grabbing
    MouseArea {
        id: dragArea
        anchors.fill: parent
        anchors.margins: -10

        cursorShape: root.isVertical ? Qt.SplitHCursor : Qt.SplitVCursor

        property real startPos:    0
        property real startHeight: 0

        onPressed: (mouse) => {
            const absPos = dragArea.mapToItem(null, mouse.x, mouse.y)
            startPos    = root.isVertical ? absPos.x : absPos.y
            startHeight = Config.options.dock.height ?? 60
        }

        onPositionChanged: (mouse) => {
            if (!pressed) return

            const absPos     = dragArea.mapToItem(null, mouse.x, mouse.y)
            const currentPos = root.isVertical ? absPos.x : absPos.y
            const delta      = currentPos - startPos

            // A sensitivity of 0.5 requires 2px of movement per 1px of size change
            const sensitivity = 0.5

            let newHeight = startHeight
            switch (dockPos) {
                case "bottom": newHeight = startHeight - (delta * sensitivity); break
                case "top":    newHeight = startHeight + (delta * sensitivity); break
                case "left":   newHeight = startHeight + (delta * sensitivity); break
                case "right":  newHeight = startHeight - (delta * sensitivity); break
            }

            newHeight = Math.round(Math.max(40, Math.min(newHeight, 80)))
            if (Config.options.dock.height !== newHeight)
                Config.options.dock.height = newHeight
        }
    }
}
