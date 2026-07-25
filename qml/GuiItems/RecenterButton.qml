import QtQuick
import QtQuick.Controls

import "../Helpers/colors.js" as Colors

/*!
    \qmltype RecenterButton
    \inqmlmodule PastViewer
    \ingroup pastviewer-gui-items
    \brief Button that recenters the map on the user's current location.
 */
Rectangle {
    id: rootID

    /*!
        \qmlsignal void RecenterButton::tapped()
        Emitted when the user taps the button.
     */
    signal tapped()

    radius: width/2
    color: Colors.palette.seeThroughBlack
    border {
        color: Colors.palette.border
        width: 1
    }

    Text {
        anchors.centerIn: parent

        text: qsTr("Re-center")
        color: "white"
    }

    TapHandler {
        grabPermissions: PointerHandler.TakeOverForbidden
        onTapped: rootID.tapped()
    }
}
