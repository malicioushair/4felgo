import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

import "../../Helpers/colors.js" as Colors

/*!
    \qmltype Header
    \inqmlmodule PastViewer
    \brief Navigation header with back button and page title.
 */
ToolBar {
    id: rootID

    /*!
        Optional component loaded at the right side of the header.
     */
    property Component secondaryButton
    /*!
        Whether the title label uses a bold font.
     */
    property bool boldTitle: false
    /*!
        Alias to the title Label for page-specific customization.
     */
    property alias label: labelID

    background: Rectangle {
        implicitHeight: 50
        color: Colors.palette.toolbar
    }
    RowLayout {
        anchors.fill: parent
        ToolButton {
            implicitHeight: rootID.height
            implicitWidth: implicitHeight
            text: "←"
            font.pointSize: 20
            onClicked: rootID.parent.StackView.view.pop()
            background: Rectangle {
                color: Colors.palette.accent
            }
        }
        Label {
            id: labelID

            Layout.fillWidth: true
            text: rootID.parent.title
            color: Colors.palette.text
            wrapMode: Text.Wrap
        }

        Loader {
            sourceComponent: rootID.secondaryButton
        }
    }
}
