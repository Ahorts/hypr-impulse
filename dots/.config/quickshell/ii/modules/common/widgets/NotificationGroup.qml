import qs.services
import qs.modules.common
import qs.modules.common.functions
import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Services.Notifications

/**
 * A group of notifications from the same app.
 * Similar to Android's notifications
 */
Item { // Notification group area
    id: root
    property var notificationGroup
    property var notifications: notificationGroup?.notifications ?? []
    property int notificationCount: notifications.length
    property bool multipleNotifications: notificationCount > 1
    property bool expanded: false
    property bool popup: false
    property real iconSize: 48
    property real padding: 8
    readonly property real collapsedSize: iconSize + (padding * 2)
    implicitHeight: background.implicitHeight

    TextMetrics {
        id: titleMetrics
        font.family: Appearance.font.family.main
        font.pixelSize: Appearance.font.pixelSize.small
        text: (root.multipleNotifications ? notificationGroup?.appName : notificationGroup?.notifications[0]?.summary) || ""
    }
    TextMetrics {
        id: bodyMetrics
        font.family: Appearance.font.family.main
        font.pixelSize: Appearance.font.pixelSize.small
        text: notificationGroup?.notifications[0]?.body || ""
    }
    // TODO:Max notification max width when no size is defined.
    // Some notifications don't seem to report width.
    readonly property real dynamicTargetWidth: {
        if (!root.popup || root.expanded) return root.width;
        // 8px left margin + 48px icon + 10px spacing = 66px
        // 8px right margin + 10px right padding = 18px
        // Base chrome overhead = 84px + 20px padding buffer
        const maxTextWidth = Math.max(titleMetrics.width, bodyMetrics.width);
        const desired = 84 + maxTextWidth + 20;
        const minW = 200;
        const maxW = 400;
        return Math.min(maxW, Math.max(minW, desired));
    }

    property real dragConfirmThreshold: 70 // Drag further to discard notification
    property real dismissOvershoot: 20 // Account for gaps and bouncy animations
    property var qmlParent: root?.parent?.parent // There's something between this and the parent ListView
    property var parentDragIndex: qmlParent?.dragIndex
    property var parentDragDistance: qmlParent?.dragDistance
    property var dragIndexDiff: Math.abs(parentDragIndex - index)
    property real xOffset: dragIndexDiff == 0 ? parentDragDistance : 
        Math.abs(parentDragDistance) > dragConfirmThreshold ? 0 :
        dragIndexDiff == 1 ? (parentDragDistance * 0.3) :
        dragIndexDiff == 2 ? (parentDragDistance * 0.1) : 0

    function destroyWithAnimation(left = false) {
        root.qmlParent.resetDrag()
        background.anchors.horizontalCenterOffset = background.anchors.horizontalCenterOffset; // Break binding
        destroyAnimation.left = left;
        destroyAnimation.running = true;
    }

    SequentialAnimation {
      id: popMorphAnim

      ParallelAnimation {
          NumberAnimation {
            target: background
            property: "scale"
            from: 0.3
            to: 1.0
            duration: 200
            easing.type: Easing.OutBack
          }
          NumberAnimation {
          target: background
          property: "opacity"
          from: 0.0 
          to: 1.0
          duration: 150
        }
      }

      ParallelAnimation {
          NumberAnimation {
              target: background
              property: "width"
              from: root.collapsedSize
              to: root.dynamicTargetWidth
              duration: 280
              easing.type: Easing.OutCubic
          }
          NumberAnimation {
            target: contentColumn
            property: "opacity"
            from: 0.0
            to: 1.0
            duration: 280
          }
      }

      onFinished: {
          if (root.popup) popupTimer.start();
      }
    }

    // Using this as a workaround instead of creating new timer events on mouse enter and leave
    // This resumes the notification timer instead of restarting it
    PauseAnimation {
        id: popupTimer
        duration: Config?.options?.notifications?.timeout ?? 5000
        onFinished: collapseExitAnim.start()
    }
  
    // The reverse of the pop up for exit animation
    SequentialAnimation {
        id: collapseExitAnim

        NumberAnimation {
            target: contentColumn
            property: "opacity"
            to: 0.0
            duration: 120
        }

        NumberAnimation {
            target: background
            property: "width"
            to: root.collapsedSize
            duration: 200
            easing.type: Easing.InCubic
        }

        ParallelAnimation {
            NumberAnimation {
                target: background
                property: "scale"
                to: 0.3
                duration: 150
                easing.type: Easing.InBack
            }
            NumberAnimation {
                target: background
                property: "opacity"
                to: 0.0
                duration: 150
            }
        }

        onFinished: {
            root.notifications.forEach(notif => {
                Notifications.timeoutNotification(notif.notificationId);
            });
        }
    }

    SequentialAnimation { // Drag finish animation
        id: destroyAnimation
        property bool left: true
        running: false

        NumberAnimation {
            target: background.anchors
            property: "horizontalCenterOffset"
            to: (root.width + root.dismissOvershoot) * (destroyAnimation.left ? -1 : 1)
            duration: Appearance.animation.elementMove.duration
            easing.type: Appearance.animation.elementMove.type
            easing.bezierCurve: Appearance.animation.elementMove.bezierCurve
        }
        onFinished: () => {
            // one batched removal instead of N full reactive-graph recomputes
            Notifications.discardByAppName(root.notifications[0]?.appName);
        }
    }

    function toggleExpanded() {
        if (expanded) implicitHeightAnim.enabled = true;
        else implicitHeightAnim.enabled = false;
        root.expanded = !root.expanded;
    }

    DragManager { // Drag manager
        id: dragManager
        anchors.fill: background
        z: 99 // fixes notifications collapsing even on hover
        interactive: !expanded
        automaticallyReset: false
        acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton
        hoverEnabled: true

        onContainsMouseChanged: {
            if (!root.popup) return;
            if (dragManager.containsMouse) {
                if (collapseExitAnim.running) {
                    collapseExitAnim.stop();
                    popMorphAnim.start();
                } else if (popupTimer.running) {
                    popupTimer.pause();
                }
            } else {
                if (popupTimer.paused) {
                    popupTimer.resume();
                } else if (!collapseExitAnim.running && !popMorphAnim.running) {
                    popupTimer.start();
                }
            }
        }

        onPressed: {
            if (mouse.button === Qt.RightButton) 
                root.toggleExpanded();
        }

        onClicked: (mouse) => {
            if (mouse.button === Qt.MiddleButton) {
                root.destroyWithAnimation();
            } else if (mouse.button === Qt.LeftButton && root.popup && !root.expanded) {
                if (!collapseExitAnim.running) {
                    popupTimer.stop();
                    collapseExitAnim.start();
                }
            }
        }

        onDraggingChanged: () => {
            if (dragging) {
                root.qmlParent.dragIndex = root.index ?? root.parent.children.indexOf(root);
            }
        }

        onDragDiffXChanged: () => {
            root.qmlParent.dragDistance = dragDiffX;
        }

        onDragReleased: (diffX, diffY) => {
            if (Math.abs(diffX) > root.dragConfirmThreshold)
                root.destroyWithAnimation(diffX < 0);
            else 
                dragManager.resetDrag();
        }
    }

    StyledRectangularShadow {
        target: background
        visible: popup && background.opacity > 0.01
        opacity: background.opacity
    }
    Rectangle { // Background of the notification
        id: background
        width: root.popup ? root.collapsedSize : parent.width
        scale: root.popup ? 0.3 : 1.0
        opacity: root.popup ? 0.0 : 1.0
        color: popup ? Appearance.colors.colBackgroundSurfaceContainer : Appearance.colors.colLayer2
        radius: (root.popup && !root.expanded) ? (height / 2) : Appearance.rounding.normal
        Behavior on radius {
            NumberAnimation { duration: 200 }
        }
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.horizontalCenterOffset: root.xOffset

        Behavior on anchors.horizontalCenterOffset {
            enabled: !dragManager.dragging
            NumberAnimation {
                duration: Appearance.animation.elementMove.duration
                easing.type: Appearance.animation.elementMove.type
                easing.bezierCurve: Appearance.animationCurves.expressiveFastSpatial
            }
        }
        
        clip: true
        implicitHeight: root.expanded ? 
            row.implicitHeight + padding * 2 :
            root.popup ? root.collapsedSize :
            Math.min(80, row.implicitHeight + padding * 2)

        Behavior on implicitHeight {
            id: implicitHeightAnim
            animation: Appearance.animation.elementMoveFast.numberAnimation.createObject(this)
        }

        RowLayout { // Left column for icon, right column for content
            id: row
            // a bit messy but oh well
            anchors.verticalCenter: (root.popup && !root.expanded) ? parent.verticalCenter : undefined
            anchors.top: (root.popup && !root.expanded) ? undefined : parent.top
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.margins: root.padding
            spacing: 10

            NotificationAppIcon { // Icons
                Layout.alignment: root.expanded ? Qt.AlignTop : Qt.AlignVCenter
                Layout.fillWidth: false
                Layout.preferredWidth: root.iconSize
                Layout.preferredHeight: root.iconSize
                image: root?.multipleNotifications ? "" : notificationGroup?.notifications[0]?.image ?? ""
                appIcon: root.notificationGroup?.appIcon
                summary: root.notificationGroup?.notifications[root.notificationCount - 1]?.summary
                urgency: root.notifications.some(n => n.urgency === NotificationUrgency.Critical.toString()) ? 
                    NotificationUrgency.Critical : NotificationUrgency.Normal
            }

            ColumnLayout { // Content
                id: contentColumn
                opacity: root.popup ? 0.0 : 1.0
                visible: opacity > 0.001
                Layout.fillWidth: true
                Layout.rightMargin: (root.popup && !root.expanded) ? 10 : 0
                spacing: expanded ? (root.multipleNotifications ? 
                    (notificationGroup?.notifications[root.notificationCount - 1].image != "") ? 35 : 
                    5 : 0) : 0
                // spacing: 00
                Behavior on spacing {
                    animation: Appearance.animation.elementMoveFast.numberAnimation.createObject(this)
                }

                Item { // App name (or summary when there's only 1 notif) and time
                    id: topRow
                    // spacing: 0
                    Layout.fillWidth: true
                    property real fontSize: Appearance.font.pixelSize.smaller
                    property bool showAppName: root.multipleNotifications
                    implicitHeight: Math.max(topTextRow.implicitHeight, expandButton.visible ? expandButton.implicitHeight : 0)

                    RowLayout {
                        id: topTextRow
                        anchors.left: parent.left
                        anchors.right: expandButton.visible ? expandButton.left : parent.right
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: 5
                        StyledText {
                            id: appName
                            elide: Text.ElideRight
                            Layout.fillWidth: true
                            text: (topRow.showAppName ?
                                notificationGroup?.appName :
                                notificationGroup?.notifications[0]?.summary) || ""
                            font.pixelSize: topRow.showAppName ?
                                topRow.fontSize :
                                Appearance.font.pixelSize.small
                            color: topRow.showAppName ?
                                Appearance.colors.colSubtext :
                                Appearance.colors.colOnLayer2
                        }
                        StyledText {
                            id: timeText
                            visible: !root.popup || root.expanded
                            // Layout.fillWidth: true
                            Layout.rightMargin: 10
                            horizontalAlignment: Text.AlignLeft
                            text: NotificationUtils.getFriendlyNotifTimeString(notificationGroup?.time)
                            font.pixelSize: topRow.fontSize
                            color: Appearance.colors.colSubtext
                        }
                    }
                    NotificationGroupExpandButton {
                        id: expandButton
                        visible: !root.popup || root.expanded
                        anchors.right: parent.right
                        anchors.verticalCenter: parent.verticalCenter
                        count: root.notificationCount
                        expanded: root.expanded
                        fontSize: topRow.fontSize
                        onClicked: { root.toggleExpanded() }
                        altAction: () => { root.toggleExpanded() }

                        StyledToolTip {
                            text: Translation.tr("Tip: right-clicking a group\nalso expands it")
                        }
                    }
                }

                StyledListView { // Notification body (expanded)
                    id: notificationsColumn
                    // Do not bind implicitHeight to contentHeight while nested in a ColumnLayout: it
                    // forms a Layout<->contentHeight polish() feedback loop that pegs a CPU core on
                    // Qt 6.11 (same class as upstream #3388). Drive the Layout height off contentHeight
                    // and recycle delegates.
                    Layout.preferredHeight: contentHeight
                    implicitHeight: contentHeight
                    reuseItems: true
                    Layout.fillWidth: true
                    spacing: expanded ? 5 : 3
                    // clip: true
                    interactive: false
                    Behavior on spacing {
                        animation: Appearance.animation.elementMoveFast.numberAnimation.createObject(this)
                    }
                    model: ScriptModel {
                        values: root.expanded ? root.notifications.slice().reverse() : 
                            root.notifications.slice().reverse().slice(0, 2)
                    }
                    delegate: NotificationItem {
                        required property int index
                        required property var modelData
                        notificationObject: modelData
                        expanded: root.expanded
                        onlyNotification: (root.notificationCount === 1)
                        opacity: (!root.expanded && index == 1 && root.notificationCount > 2) ? 0.5 : 1
                        visible: root.expanded || (index < 2)
                        anchors.left: parent?.left
                        anchors.right: parent?.right
                    }
                }

            }
        }
    }

    function cancelAllServiceTimeouts() {
        if (!root.popup) return;
        try {
            root.notifications.forEach(notif => {
                Notifications.cancelTimeout(notif.notificationId);
            });
        } catch (e) {
            console.log("[NotificationGroup] cancelTimeout error:", e);
        }
    }

    Component.onCompleted: {
        if (root.popup){
            cancelAllServiceTimeouts();
            popMorphAnim.start();
        }
    }

    onNotificationsChanged: {
        if (root.popup) {
            cancelAllServiceTimeouts();
            if (!collapseExitAnim.running && !popMorphAnim.running) {
                popupTimer.restart();
            }
        }
    }
}
