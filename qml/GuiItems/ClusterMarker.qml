import QtQuick
import QtQuick.Shapes

import "../Helpers/colors.js" as Colors

/*!
    \qmltype ClusterMarker
    \inqmlmodule PastViewer
    \ingroup pastviewer-gui-items
    \brief Circular map marker showing the number of photos in a cluster.
 */
Rectangle {
    id: rootID

    /*!
        Diameter of the circular marker in pixels.
     */
    required property int size
    /*!
        Number of photos represented by the cluster.
     */
    required property int clusterCount

    /*!
        Whether the marker is currently selected.
     */
    property bool selected: false

    /*!
        \qmlsignal void ClusterMarker::clicked()
        Emitted when the user taps the marker.
     */
    signal clicked()

    width: size
    height: size

    radius: width / 2
    color: selected ? Colors.palette.selected : Colors.palette.accent
    border.color: Colors.palette.border
    border.width: 2

    TapHandler {
        gesturePolicy: TapHandler.ReleaseWithinBounds | TapHandler.WithinBounds
        onTapped: rootID.clicked()
    }

    Text {
        id: countTextID

        anchors.centerIn: parent
        text: rootID.clusterCount
        color: "white"
        font.pixelSize: Math.max(10, rootID.size * 0.4)
        font.bold: true
        horizontalAlignment: Text.AlignHCenter
        verticalAlignment: Text.AlignVCenter
    }
}
