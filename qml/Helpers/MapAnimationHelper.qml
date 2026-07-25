import QtQuick
import QtLocation
import QtPositioning

import PastViewer 1.0

/*!
    \qmltype MapAnimationHelper
    \inqmlmodule PastViewer
    \ingroup pastviewer-helpers
    \brief Smooth map center and zoom animations with cluster-split detection.

    Provides animated transitions when the user selects a photo from the carousel
    or taps a clustered marker. After animation completes, triggers a viewport
    update on \c pastVuModelController.
 */
Item {
    id: rootID

    visible: false

    /*!
        The Map instance to animate. This property is required.
     */
    required property var map

    // Exposed to make the user code handle the animatedSmthChanged signals
    property real animatedLat: 0
    property real animatedLon: 0
    property real animatedZoom: 0

    property var pendingClusterCheck: null
    /*!
        Read-only; \c true while a center or zoom animation is in progress.
     */
    readonly property bool running: animationGroup.running

    ParallelAnimation {
        id: animationGroup

        NumberAnimation {
            id: latAnimation
            target: rootID
            property: "animatedLat"
            duration: 500
            easing.type: Easing.InOutCubic
        }

        NumberAnimation {
            id: lonAnimation
            target: rootID
            property: "animatedLon"
            duration: 500
            easing.type: Easing.InOutCubic
        }

        NumberAnimation {
            id: zoomAnimation
            target: rootID
            property: "animatedZoom"
            duration: 500
            easing.type: Easing.InOutCubic
        }

        onFinished: {
            if (rootID.pendingClusterCheck)
                rootID._handleAnimationFinished()
        }
    }


    // Internal: set up center animation from targetCoordinate (null keeps current).
    function _setupCenterAnimation(targetCoordinate) {
        if (!targetCoordinate || !targetCoordinate.isValid)
            return

        animatedLat = map.center.latitude
        animatedLon = map.center.longitude

        latAnimation.from = map.center.latitude
        latAnimation.to = targetCoordinate.latitude
        lonAnimation.from = map.center.longitude
        lonAnimation.to = targetCoordinate.longitude
    }

    // Internal: set up zoom animation; targetZoom <= 0 keeps current zoom.
    function _setupZoomAnimation(targetZoom) {
        animatedZoom = map.zoomLevel

        if (targetZoom > 0 && targetZoom !== map.zoomLevel) {
            zoomAnimation.from = map.zoomLevel
            zoomAnimation.to = targetZoom
        } else {
            // Keep current zoom
            zoomAnimation.from = map.zoomLevel
            zoomAnimation.to = map.zoomLevel
        }
    }

    // Animate map center to targetCoordinate without changing zoom.
    /*!
        \qmlmethod void MapAnimationHelper::animateMapCenter(targetCoordinate)
        Animates the map center to \a targetCoordinate without changing zoom.
     */
    function animateMapCenter(targetCoordinate) {
        if (!map || !targetCoordinate || !targetCoordinate.isValid)
            return

        map.follow = false

        _setupCenterAnimation(targetCoordinate)
        _setupZoomAnimation(0)

        animationGroup.start()
    }

    // Store cluster info for viewport refresh after animation.
    function _handleClustering(targetZoom, clusterCoordinate) {
        pendingClusterCheck = {
            map: map,
            clusterCoordinate: clusterCoordinate,
            currentZoom: targetZoom
        }
    }

    // Animate zoom to targetZoom and schedule viewport refresh on completion.
    /*!
        \qmlmethod void MapAnimationHelper::animateMapZoom(targetZoom, clusterCoordinate)
        Animates zoom to \a targetZoom; \a clusterCoordinate is used for viewport refresh.
     */
    function animateMapZoom(targetZoom, clusterCoordinate) {
        if (!map || targetZoom <= 0 || targetZoom === map.zoomLevel)
            return

        map.follow = false

        _setupZoomAnimation(targetZoom)
        _handleClustering(targetZoom, clusterCoordinate)

        animationGroup.start()
    }

    // Animate center and zoom in parallel.
    /*!
        \qmlmethod void MapAnimationHelper::animateMapCenterAndZoom(targetCoordinate, targetZoom, clusterCoordinate)
        Animates center to \a targetCoordinate, zoom to \a targetZoom;
        \a clusterCoordinate is used for viewport refresh.
     */
    function animateMapCenterAndZoom(targetCoordinate, targetZoom, clusterCoordinate) {
        if (!map || !targetCoordinate || !targetCoordinate.isValid)
            return

        map.follow = false

        _setupCenterAnimation(targetCoordinate)
        _setupZoomAnimation(targetZoom)
        _handleClustering(targetZoom, clusterCoordinate)

        animationGroup.start()
    }

    // Refresh viewport after animation completes.
    function _handleAnimationFinished() {
        if (!pendingClusterCheck)
            return

        const mapObj = pendingClusterCheck.map
        const topLeftCoord = mapObj.toCoordinate(Qt.point(0, 0), false)
        const bottomRightCoord = mapObj.toCoordinate(Qt.point(mapObj.width, mapObj.height), false)
        pastVuModelController.SetViewportCoordinates(QtPositioning.rectangle(topLeftCoord, bottomRightCoord))

        pendingClusterCheck = null
    }
}
