import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

import "../Helpers/colors.js" as Colors

/*!
    \qmltype SettingsButton
    \inqmlmodule PastViewer
    \ingroup pastviewer-gui-items
    \brief Hamburger-menu icon button that opens settings.
 */
Rectangle {
    id: rootID

    /*!
        \qmlsignal void SettingsButton::clicked()
        Emitted when the user taps the button.
     */
    signal clicked()

    width: 40
    height: 40
    radius: 10

    color: Colors.palette.accentAlt

    ColumnLayout{
        id: burgerMenu
        anchors.centerIn: parent

        Repeater {
            model: 3

            Rectangle {
                width: 25
                height: 2

                color: Colors.palette.toolbar
            }
        }
    }

    TapHandler {
        onTapped: clicked()
    }
}
