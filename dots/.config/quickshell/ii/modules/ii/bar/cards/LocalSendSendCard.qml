import qs.modules.common
import qs.modules.common.widgets
import qs.services
import QtQuick
import QtQuick.Layouts

SectionCard {
    title: Translation.tr("Dropped Files")
    icon: "attach_file"
    shapeColor: Appearance.colors.colPrimaryContainer
    symbolColor: Appearance.colors.colOnPrimaryContainer
    showDivider: false

    ColumnLayout {
        spacing: 8

        // Dropped files list
        Repeater {
            model: LocalSend.droppedFiles

            delegate: RowLayout {
                spacing: 8

                MaterialSymbol {
                    text: "description"
                    iconSize: 16
                    color: Appearance.colors.colSubtext
                }

                StyledText {
                    Layout.fillWidth: true
                    text: modelData.size > 0 ? modelData.name + " (" + LocalSend.formatFileSize(modelData.size) + ")" : modelData.name
                    color: Appearance.colors.colOnSurface
                    font.pixelSize: Appearance.font.pixelSize.normal
                    elide: Text.ElideMiddle
                }

                RippleButton {
                    implicitWidth: 24
                    implicitHeight: 24
                    buttonRadius: Appearance.rounding.full
                    colBackground: "transparent"
                    onClicked: LocalSend.removeDroppedFile(index)
                    contentItem: MaterialSymbol {
                        anchors.centerIn: parent
                        text: "close"
                        iconSize: 14
                        color: Appearance.colors.colSubtext
                        fill: 1
                    }
                }
            }
        }

        StyledText {
            visible: LocalSend.discoveredDevices.length > 0
            text: Translation.tr("Devices")
            font.pixelSize: Appearance.font.pixelSize.small
            font.weight: Font.Bold
            color: Appearance.colors.colOnSurfaceVariant
        }

        // Device list
        Repeater {
            model: LocalSend.discoveredDevices

            delegate: RowLayout {
                spacing: 8

                MaterialSymbol {
                    text: "smartphone"
                    iconSize: 18
                    color: Appearance.colors.colSubtext
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 0

                    StyledText {
                        text: modelData.name
                        font.pixelSize: Appearance.font.pixelSize.normal
                        font.weight: Font.Bold
                        color: Appearance.colors.colOnSurface
                        elide: Text.ElideMiddle
                    }

                    StyledText {
                        text: modelData.ip
                        font.pixelSize: Appearance.font.pixelSize.small
                        color: Appearance.colors.colSubtext
                    }
                }

                Item {
                    Layout.fillWidth: true
                }

                RippleButton {
                    buttonRadius: Appearance.rounding.normal
                    colBackground: Appearance.colors.colPrimary
                    colBackgroundHover: Appearance.colors.colPrimaryHover
                    enabled: !LocalSend.sending
                    onClicked: LocalSend.sendToDevice(modelData.ip)
                    contentItem: RowLayout {
                        spacing: 4
                        anchors.centerIn: parent
                        MaterialSymbol {
                            text: "send"
                            iconSize: 14
                            color: Appearance.colors.colOnPrimary
                        }
                        StyledText {
                            text: Translation.tr("Send")
                            color: Appearance.colors.colOnPrimary
                            font.pixelSize: Appearance.font.pixelSize.small
                        }
                    }
                }
            }
        }

        // Sending indicator
        StyledText {
            visible: LocalSend.sending
            text: Translation.tr("Sending... (Check your device for the status)")
            font.pixelSize: Appearance.font.pixelSize.small
            color: Appearance.colors.colPrimary
            horizontalAlignment: Text.AlignHCenter
            Layout.fillWidth: true
        }

        // No devices placeholder
        StyledText {
            visible: LocalSend.discoveredDevices.length === 0 && LocalSend.serverRunning
            text: Translation.tr("Devices waiting...")
            font.pixelSize: Appearance.font.pixelSize.normal
            color: Appearance.colors.colSubtext
            horizontalAlignment: Text.AlignHCenter
            Layout.fillWidth: true
        }

        StyledText {
            visible: LocalSend.discoveredDevices.length === 0 && !LocalSend.serverRunning
            text: Translation.tr("LocalSend server is offline")
            font.pixelSize: Appearance.font.pixelSize.normal
            color: Appearance.colors.colSubtext
            horizontalAlignment: Text.AlignHCenter
            Layout.fillWidth: true
        }
    }
}
