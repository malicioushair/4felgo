import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtLocation
import QtPositioning
import QtQuick.Shapes

import PastViewer 1.0

import "ErrorMessageDialog"
import "GuiItems"
import "Helpers"
import "Views"

import "Helpers/colors.js" as Colors

/*!
    \qmltype MainWindow
    \inqmlmodule PastViewer
    \brief Root visual container with navigation stack and error handling.
 */
Rectangle {
    id: mainWindowID

    /*!
        \qmlproperty MapAnimationHelper MainWindow::mapAnimationHelper
        Shared animation helper for smooth map transitions.
     */
    property alias mapAnimationHelper: mapAnimationHelperID

    /*!
        \qmlmethod void MainWindow::openPhotoDetails(string photo, string thumbnail, string title, int year)
        Pushes PhotoDetails for \a photo and \a thumbnail with \a title and \a year.
     */
    function openPhotoDetails(photo, thumbnail, title, year) {
        stackViewID.push("Views/PhotoDetails.qml", {
            imageSource: photo,
            thumbnailSource: thumbnail,
            title: title,
            year: year
        })
    }

    /*!
        \qmlmethod void MainWindow::openSettings()
        Pushes Settings onto the navigation stack.
     */
    function openSettings() {
        stackViewID.push("Views/Settings.qml")
    }

    color: Colors.palette.bg

    MapAnimationHelper {
        id: mapAnimationHelperID

        map: stackViewID.currentItem ? stackViewID.currentItem.map : null
    }

    StackView {
        id: stackViewID

        anchors.fill: parent
        focus: true

        initialItem: MapPage {
            id: mapPageInstance
        }
    }

    ErrorMessageDialog {
        id: errorDialogID

        anchors.centerIn: Overlay.overlay
    }

    Connections {
        target: guiController

        function onShowErrorDialog(message) {
            errorDialogID.errorMessage = message
            errorDialogID.open()
        }
    }

}
