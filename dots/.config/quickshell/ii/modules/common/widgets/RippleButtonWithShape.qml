import QtQuick
import QtQuick.Layouts
import qs.modules.common
import qs.modules.common.widgets

RippleButton {
    id: buttonWithIconRoot
    property bool showDropDown: false
    property string shapeString: ""
    property string mainText: ""
    property Component mainContentComponent: Component {
        StyledText {
            visible: text !== ""
            text: buttonWithIconRoot.mainText
            font.pixelSize: Appearance.font.pixelSize.small
            color: Appearance.colors.colOnSecondaryContainer
        }
    }
    implicitWidth: showDropDown ? 55 : 40
    implicitHeight: 35
    horizontalPadding: 10
    buttonRadius: Appearance.rounding.full

    colBackground: Appearance.colors.colSecondaryContainer
    colBackgroundHover: Appearance.colors.colSecondaryContainerHover
    colRipple: Appearance.colors.colSecondaryContainerActive

    contentItem: RowLayout {
        anchors.verticalCenter: parent.verticalCenter
        spacing: 0
        Loader {
            id: materialShapeLoader
            anchors.verticalCenter: parent.verticalCenter
            active: buttonWithIconRoot.shapeString !== ""
            sourceComponent: MaterialShape {
                shapeString: buttonWithIconRoot.shapeString
                width: Appearance.font.pixelSize.larger
                height: Appearance.font.pixelSize.larger
                color: Appearance.colors.colOnSecondaryContainer
            }
        }
        MaterialSymbol {
            visible: showDropDown
            anchors.verticalCenter: parent.verticalCenter
            text: "arrow_drop_down"
            iconSize: Appearance.font.pixelSize.huge
        }
        /* Loader {
            Layout.fillWidth: true
            sourceComponent: buttonWithIconRoot.mainContentComponent
            Layout.alignment: Qt.AlignVCenter
        } */
    }
}
