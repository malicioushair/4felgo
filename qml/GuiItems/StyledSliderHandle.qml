import QtQuick

import "../Helpers/colors.js" as Colors

/*!
    \qmltype StyledSliderHandle
    \inqmlmodule PastViewer
    \ingroup pastviewer-gui-items
    \brief Circular drag handle for \l StyledRangeSlider.
 */
Rectangle {
    /*!
        Whether the corresponding slider handle is currently pressed.
     */
    property bool pressed: false
    /*!
        Normalized position of the handle in the range from zero to one.
     */
    property real visualPosition: 0
    /*!
        Horizontal distance available to the handle.
     */
    property real availableWidth: 0
    /*!
        Horizontal adjustment applied after positioning.
     */
    property real xOffset: 0
    /*!
        Vertical adjustment applied after positioning.
     */
    property real yOffset: 0

    implicitWidth: 20
    implicitHeight: 20
    radius: 10
    color: pressed ? Colors.palette.accentAltPressed : Colors.palette.accentAlt

    x: visualPosition * availableWidth + xOffset
    y: -height / 4 + yOffset
    antialiasing: true
    border.color: Colors.palette.shadowSoft
    border.width: 1
}
