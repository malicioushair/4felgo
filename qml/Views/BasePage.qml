import QtQuick
import QtQuick.Controls

import "../Helpers/colors.js" as Colors

/*!
    \qmltype BasePage
    \inqmlmodule PastViewer
    \brief Base page with themed background and Android back-key handling.
 */
Page {
    id: rootID

    background: Rectangle {
        color: Colors.palette.bg
    }

    Keys.onBackPressed: (event) => {
        if (rootID.StackView.view.depth > 1) {
            rootID.StackView.view.pop()
        }
    }
}
