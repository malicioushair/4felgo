import Felgo
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Window
import QtLocation
import QtPositioning

App {
    id: mainWindowID

    property bool isMobile: Qt.platform.os === "android" || Qt.platform.os === "ios"

    width: isMobile ? Screen.width : 1080 / 3
    height: isMobile ? Screen.height : 1920 / 3
    flags: Qt.Window
    visibility: Window.AutomaticVisibility
    visible: true

    title: "Past Viewer"

    Component.onCompleted: {
        if (typeof felgoHotReloadEngine !== "undefined")
            felgoHotReloadEngine.contentLoader = mainWindowLoaderID
    }

    Loader {
        id: mainWindowLoaderID

        anchors.fill: parent

        source: "MainWindow.qml"
        focus: true
    }
}
