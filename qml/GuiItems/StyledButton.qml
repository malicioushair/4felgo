import QtQuick
import QtQuick.Controls

import "../Helpers/colors.js" as Colors

/*!
    \qmltype StyledButton
    \inqmlmodule PastViewer
    \ingroup pastviewer-gui-items
    \brief Themed push button with accent background and rounded corners.
 */
Button {
    id: controlID

    background: Rectangle {
        color: controlID.pressed ? Colors.palette.accentAlt : Colors.palette.accent
        radius: 8
        border {
            color: Colors.palette.border
            width: 2
        }

        Behavior on color {
            ColorAnimation {
                duration: 150
            }
        }
    }

    contentItem: Text {
        text: controlID.text
        font {
            pixelSize: 16
            bold: true
        }
        color: "white"
        horizontalAlignment: Text.AlignHCenter
        verticalAlignment: Text.AlignVCenter
    }

    padding: 12
    implicitHeight: 44
}
