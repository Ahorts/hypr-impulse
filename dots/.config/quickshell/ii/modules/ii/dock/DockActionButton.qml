import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.common.functions

RippleButton {
    id: root

    property int    buttonSize:    Appearance.sizes.dockButtonSize
    property int    symbolSize:    Math.round(root.buttonSize * 0.5)
    property bool   isVertical:    false
    property string symbolName:    ""
    property color  activeColor:   Appearance.m3colors.m3onPrimary
    property color  inactiveColor: Appearance.colors.colOnLayer0
    property bool   dragActive:    false
    property string dragSymbol:    ""
    property int    normalShape:   MaterialShape.Shape.Pill
    property int    activeShape:   MaterialShape.Shape.Cookie9Sided
    property bool   dragOver:      false
    property string fileDropIcon:  ""
    property bool   fileDropActive: false

    width:  buttonSize
    height: buttonSize

    rippleEnabled: false
    padding:       0

    colBackground:             "transparent"
    colBackgroundHover:        "transparent"
    colBackgroundToggled:      "transparent"
    colBackgroundToggledHover: "transparent"
    
    background.implicitWidth:  0
    background.implicitHeight: 0

    contentItem: Item {
        MaterialShapeWrappedMaterialSymbol {
            id: shapeSymbol
            anchors.centerIn: parent

            shape: (root.dragActive || root.fileDropActive) ? root.activeShape : root.normalShape

            implicitSize: root.dragOver ? root.buttonSize * 1.1 : root.buttonSize * 0.9
            Behavior on implicitSize {
                animation: Appearance.animation.elementResize.numberAnimation.createObject(this)
            }

            rotation: root.dragOver ? 90 : ((root.dragActive || root.fileDropActive) ? 45 : 0)
            Behavior on rotation {
                animation: Appearance.animation.elementMoveFast.numberAnimation.createObject(this)
            }

            color: {
                if (root.dragActive || root.fileDropActive) {
                    return root.down ? Appearance.colors.colSecondaryContainerActive :
                           root.hovered ? Appearance.colors.colSecondaryContainerHover :
                           Appearance.colors.colSecondaryContainer
                }
                
                if (root.toggled) {
                    return root.down ? Appearance.colors.colPrimaryActive :
                           root.hovered ? Appearance.colors.colPrimaryHover :
                           Appearance.colors.colPrimary
                }
                return root.down ? Appearance.colors.colLayer1Active :
                       root.hovered ? Appearance.colors.colLayer1Hover :
                       "transparent"
            }
            
            Behavior on color {
                animation: Appearance.animation.elementMoveFast.colorAnimation.createObject(this)
            }

            text: root.fileDropActive ? root.fileDropIcon
                : root.dragActive     ? root.dragSymbol
                :                       root.symbolName

            iconSize: (root.dragActive || root.fileDropActive)
                ? Math.round(root.buttonSize * 0.4)
                : root.symbolSize
            Behavior on iconSize {
                animation: Appearance.animation.elementResize.numberAnimation.createObject(this)
            }

            colSymbol: (root.dragActive || root.fileDropActive)
                ? Appearance.colors.colOnSecondaryContainer
                : (root.toggled ? root.activeColor : root.inactiveColor)
            Behavior on colSymbol {
                animation: Appearance.animation.elementMoveFast.colorAnimation.createObject(this)
            }
        }
    }
}