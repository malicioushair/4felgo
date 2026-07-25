import QtQuick

import PastViewer 1.0

import "colors.js" as Colors

/*!
    \qmltype RectangleWithHoles
    \inqmlmodule PastViewer
    \ingroup pastviewer-helpers
    \brief Dimmed overlay with transparent rectangular cutouts.

    Renders framing rectangles around the first hole for a spotlight effect and
    uses the C++ \l {PastViewer::HoleItem} type to forward pointer events.
 */
Item {
    id: rectWithHolesID

    /*!
        Rectangles that remain transparent and accept pointer events.
     */
    property var holes: []
    /*!
        Corner radius used for highlighted holes.
     */
    property int holeRadius: 8
    /*!
        Color of the dimmed area around the holes.
     */
    property color overlayColor: Colors.palette.overlayDim

    /*!
        Color of each highlighted hole border.
     */
    property color highlightBorderColor: "white"
    /*!
        Width of each highlighted hole border.
     */
    property int highlightBorderWidth: 2

    // Dimmed overlay: 4 rectangles framing the hole
    Repeater {
        model: {
            if (holes.length === 0)
                return []
            const r = holes[0]
            const pw = rectWithHolesID.width
            const ph = rectWithHolesID.height
            return [
                { x: 0, y: 0, w: pw, h: Math.max(0, r.y) },
                { x: 0, y: r.y + r.height, w: pw, h: Math.max(0, ph - r.y - r.height) },
                { x: 0, y: r.y, w: Math.max(0, r.x), h: r.height },
                { x: r.x + r.width, y: r.y, w: Math.max(0, pw - r.x - r.width), h: r.height }
            ]
        }

        Rectangle {
            x: modelData.x
            y: modelData.y
            width: modelData.w
            height: modelData.h
            color: rectWithHolesID.overlayColor
        }
    }

    // Highlight border around the hole
    Repeater {
        model: rectWithHolesID.holes

        Rectangle {
            x: modelData.x - rectWithHolesID.highlightBorderWidth
            y: modelData.y - rectWithHolesID.highlightBorderWidth
            width: modelData.width + 2 * rectWithHolesID.highlightBorderWidth
            height: modelData.height + 2 * rectWithHolesID.highlightBorderWidth

            radius: rectWithHolesID.holeRadius + rectWithHolesID.highlightBorderWidth
            color: "transparent"
            border.width: rectWithHolesID.highlightBorderWidth
            border.color: rectWithHolesID.highlightBorderColor
        }
    }

    HoleItem {
        anchors.fill: parent
        holes: rectWithHolesID.holes
    }
}
