import QtQuick
import QtQuick.Shapes

import "../Helpers/colors.js" as Colors

/*!
    \qmltype PovDirection
    \inqmlmodule PastViewer
    \ingroup pastviewer-gui-items
    \brief Map marker with a directional arrow indicating photo point of view.
 */
Rectangle {
    id: rootID

    /*!
        Diameter of the marker in pixels.
     */
    required property int size
    /*!
        Photo bearing in degrees clockwise from north.
     */
    required property real bearing // degrees, 0=N, 90=E (clockwise)
    /*!
        Current map rotation in degrees clockwise from north.
     */
    required property real mapBearing

    /*!
        Whether the marker is currently selected.
     */
    property bool selected: false

    /*!
        \qmlsignal void PovDirection::clicked()
        Emitted when the user taps the marker.
     */
    signal clicked()

    /*!
        Color used to draw the direction arrow.
     */
    property color arrowColor: "black"

    width: size
    height: size

    radius: width / 2
    color: selected ? Colors.palette.selected : "white"
    border.color: Colors.palette.border

    TapHandler {
        gesturePolicy: TapHandler.ReleaseWithinBounds | TapHandler.WithinBounds
        onTapped: rootID.clicked()
    }

    Item {
        id: arrowID

        anchors.fill: parent

        transform: Rotation {
            origin.x: arrowID.width / 2
            origin.y: arrowID.height / 2
            angle: ((bearing - mapBearing) % 360 + 360) % 360
        }

        Rectangle {
            id: arrowShaftID

            width: 2
            height: rootID.height * 0.42
            color: rootID.arrowColor

            anchors.horizontalCenter: parent.horizontalCenter
            anchors.verticalCenter: parent.verticalCenter
            anchors.verticalCenterOffset: -rootID.height * 0.08

            antialiasing: true
        }

        Shape {
            id: arrowHeadID

            width: rootID.height * 0.30
            height: width

            anchors.horizontalCenter: parent.horizontalCenter
            anchors.top: parent.top
            anchors.topMargin: rootID.height * 0.14

            ShapePath {
                fillColor: rootID.arrowColor
                strokeColor: "transparent"
                PathMove {
                    x: arrowHeadID.width / 2
                    y: 0
                }
                PathLine {
                    x: 0
                    y: arrowHeadID.height
                }
                PathLine {
                    x: arrowHeadID.width
                    y: arrowHeadID.height
                }
            }
        }
    }
}
