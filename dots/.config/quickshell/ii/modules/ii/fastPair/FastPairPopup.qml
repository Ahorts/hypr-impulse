pragma ComponentBehavior: Bound

import qs
import qs.modules.common
import qs.modules.common.widgets
import qs.services
import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Hyprland
import Quickshell.Wayland

Scope {
    id: fastPairPopup

    PanelWindow {
        id: root

        // Stays mapped until the card has finished sliding back off-screen.
        visible: (FastPair.popupShown || card.x < root.width) && !GlobalStates.screenLocked
        screen: Quickshell.screens.find(s => s.name === Hyprland.focusedMonitor?.name) ?? null
        color: "transparent"

        WlrLayershell.namespace: "quickshell:fastPairPopup"
        WlrLayershell.layer: WlrLayer.Overlay
        // Reserve nothing, but do respect what the bar reserves. That is what
        // puts the card the same distance from the edge as every other panel,
        // and it handles a vertical or bottom bar without special-casing it.
        exclusiveZone: 0

        // Full height on purpose, like NotificationPopup: the card changes height
        // when the options expand, and resizing a layer surface every animation
        // frame is what makes that stutter. The mask keeps the slack
        // click-through.
        anchors {
            top: true
            right: true
            bottom: true
        }

        // Slide inwards so the right sidebar can have the corner, and drift back
        // out once it closes. This has to move the card rather than the window's
        // right margin: changing margins does not reconfigure an already
        // committed layer surface, so the window instead stays put and is made
        // wide enough to cover both positions. The mask keeps the slack
        // click-through.
        readonly property real sidebarInset: GlobalStates.effectiveRightOpen ? Appearance.sizes.sidebarWidth : 0

        // Notifications own this corner, so drop below them rather than
        // overlapping. card.y adds the gutter on top of this, which is what
        // leaves the same gap here as the card keeps from the screen edge.
        // Clamped so a tall stack cannot push the card off screen.
        readonly property real notificationInset: {
            if (GlobalStates.notificationPopupHeight <= 0)
                return 0;
            const room = root.height - card.height - card.gutter * 2;
            return Math.max(0, Math.min(GlobalStates.notificationPopupHeight, room));
        }

        // Gutter to the screen edge, elevationMargin of slack on the far side
        // for the shadow: the same split SidebarDashboard uses.
        implicitWidth: card.width + card.gutter + Appearance.sizes.elevationMargin + Appearance.sizes.sidebarWidth

        mask: Region {
            item: card
        }

        Item {
            id: card

            // Same outer spacing as the sidebars, notifications and bar popups.
            readonly property real gutter: Appearance.sizes.hyprlandGapsOut
            readonly property real padding: 24
            property bool optionsOpen: false

            readonly property bool shown: FastPair.popupShown
            onShownChanged: if (card.shown) card.optionsOpen = false

            readonly property string statusText: {
                // Names the binary rather than any one distro's package name.
                if (FastPair.agentUnavailable)
                    return Translation.tr("Can't pair: bluetoothctl not available");
                if (FastPair.failed)
                    return Translation.tr("Couldn't connect, try again");
                if (!FastPair.busy)
                    return Translation.tr("Nearby and ready to pair");
                if (FastPair.candidate?.connected)
                    return Translation.tr("Connected");
                if (FastPair.candidate?.paired)
                    return Translation.tr("Connecting...");
                return Translation.tr("Pairing...");
            }

            readonly property var snoozePresets: [
                { label: Translation.tr("10m"), ms: 600000 },
                { label: Translation.tr("30m"), ms: 1800000 },
                { label: Translation.tr("1h"), ms: 3600000 },
                { label: Translation.tr("6h"), ms: 21600000 }
            ]

            width: 344
            height: content.implicitHeight + card.padding * 2
            y: card.gutter + root.notificationInset
            // Slides out past the screen edge, so there is nothing to clip.
            x: FastPair.popupShown ? root.width - card.width - card.gutter - root.sidebarInset : root.width + card.gutter

            Behavior on x {
                animation: Appearance.animation.elementMoveEnter.numberAnimation.createObject(this)
            }

            Behavior on y {
                animation: Appearance.animation.elementMoveEnter.numberAnimation.createObject(this)
            }

            StyledRectangularShadow {
                target: background
            }

            Rectangle {
                id: background
                anchors.fill: parent
                radius: Appearance.rounding.verylarge
                color: Appearance.colors.colLayer0
            }

            component Chip: DialogButton {
                padding: 10
                implicitHeight: 32
            }

            ColumnLayout {
                id: content
                anchors {
                    left: parent.left
                    right: parent.right
                    verticalCenter: parent.verticalCenter
                    leftMargin: card.padding
                    rightMargin: card.padding
                }
                spacing: 6

                StyledText {
                    Layout.fillWidth: true
                    horizontalAlignment: Text.AlignHCenter
                    font.pixelSize: Appearance.font.pixelSize.larger
                    color: Appearance.colors.colOnLayer0
                    elide: Text.ElideRight
                    textFormat: Text.PlainText
                    text: FastPair.candidate?.name || Translation.tr("Bluetooth device")
                }

                StyledText {
                    Layout.fillWidth: true
                    Layout.bottomMargin: 10
                    horizontalAlignment: Text.AlignHCenter
                    wrapMode: Text.Wrap
                    font.pixelSize: Appearance.font.pixelSize.smaller
                    color: Appearance.colors.colSubtext
                    textFormat: Text.PlainText
                    text: card.statusText
                }

                MaterialShapeWrappedMaterialSymbol {
                    Layout.alignment: Qt.AlignHCenter
                    Layout.bottomMargin: 12
                    shape: MaterialShape.Shape.Cookie12Sided
                    iconSize: 72
                    padding: 32
                    text: Icons.getBluetoothDeviceMaterialSymbol(FastPair.candidate?.icon ?? "")
                }

                // Revealer clips and animates the reveal rather than snapping the
                // card to a new height. Held visible at zero height so the
                // layout's spacing does not pop once it finishes collapsing.
                Revealer {
                    Layout.fillWidth: true
                    vertical: true
                    reveal: card.optionsOpen
                    visible: true

                    ColumnLayout {
                        // Explicit width: taking it from the Revealer would make
                        // the Revealer's implicitWidth depend on its own child.
                        width: card.width - card.padding * 2
                        spacing: 4

                        StyledText {
                            text: Translation.tr("Snooze this device")
                            font.pixelSize: Appearance.font.pixelSize.smaller
                            color: Appearance.colors.colSubtext
                        }

                        RowLayout {
                            Layout.fillWidth: true
                            spacing: 4

                            Repeater {
                                model: card.snoozePresets

                                Chip {
                                    required property var modelData
                                    Layout.fillWidth: true
                                    buttonText: modelData.label
                                    onClicked: FastPair.dismiss(modelData.ms)
                                }
                            }
                        }

                        Chip {
                            Layout.fillWidth: true
                            Layout.topMargin: 2
                            colText: Appearance.colors.colError
                            buttonText: Translation.tr("Never show this device")
                            onClicked: FastPair.ignoreCandidate()
                        }

                        StyledText {
                            Layout.topMargin: 6
                            text: Translation.tr("Mute all pairing popups")
                            font.pixelSize: Appearance.font.pixelSize.smaller
                            color: Appearance.colors.colSubtext
                        }

                        RowLayout {
                            Layout.bottomMargin: 10
                            Layout.fillWidth: true
                            spacing: 4

                            Repeater {
                                model: card.snoozePresets

                                Chip {
                                    required property var modelData
                                    Layout.fillWidth: true
                                    buttonText: modelData.label
                                    onClicked: FastPair.muteAll(modelData.ms)
                                }
                            }
                        }
                    }
                }

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 8

                    DialogButton {
                        Layout.fillWidth: true
                        buttonText: Translation.tr("Close")
                        onClicked: FastPair.dismiss(FastPair.options.snoozeSeconds * 1000)
                    }

                    DialogButton {
                        implicitWidth: 36
                        padding: 6
                        onClicked: card.optionsOpen = !card.optionsOpen

                        contentItem: MaterialSymbol {
                            anchors.centerIn: parent
                            text: "expand_more"
                            iconSize: Appearance.font.pixelSize.larger
                            color: Appearance.colors.colPrimary
                            rotation: card.optionsOpen ? 180 : 0

                            Behavior on rotation {
                                animation: Appearance.animation.elementMoveFast.numberAnimation.createObject(this)
                            }
                        }

                        StyledToolTip {
                            text: Translation.tr("More options")
                        }
                    }

                    DialogButton {
                        Layout.fillWidth: true
                        enabled: !FastPair.busy
                        colBackground: Appearance.colors.colPrimary
                        colBackgroundHover: Appearance.colors.colPrimaryHover
                        colRipple: Appearance.colors.colPrimaryActive
                        colEnabled: Appearance.colors.colOnPrimary
                        buttonText: Translation.tr("Connect")
                        onClicked: FastPair.connectCandidate()
                    }
                }
            }
        }
    }
}
