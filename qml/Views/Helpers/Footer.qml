import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

import "../../Helpers/colors.js" as Colors

/*!
    \qmltype Footer
    \inqmlmodule PastViewer
    \brief Bottom toolbar displaying contextual page information.
 */
ToolBar {
    id: rootID

    /*!
        Text displayed by the footer label.
     */
    required property string text

    background: Rectangle {
        color: Colors.palette.toolbar
    }
    RowLayout {
        anchors.fill: parent
        Label {
            Layout.leftMargin: 10
            text: rootID.text
            color: Colors.palette.text
            font {
                bold: true
                pixelSize: 16
            }
            wrapMode: Text.WordWrap
        }
        Item {
            Layout.fillWidth: true
        }
    }
}
