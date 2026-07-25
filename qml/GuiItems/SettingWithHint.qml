import QtQuick
import QtQuick.Layouts

/*!
    \qmltype SettingWithHint
    \inqmlmodule PastViewer
    \ingroup pastviewer-gui-items
    \brief Layout row that places a setting control next to an optional help hint.
 */
RowLayout {
    id: rootID

    Layout.fillWidth: true
    spacing: 8

    /*!
        Optional help text passed to \l SettingHelpHint.
     */
    property string description: ""

    /*!
        Default content inserted into the setting-control host.
     */
    default property alias contents: contentHost.data

    Item {
        id: contentHost

        implicitHeight: childrenRect.height
        implicitWidth: childrenRect.width
    }

    SettingHelpHint {
        Layout.alignment: Qt.AlignRight
        description: rootID.description
        visible: rootID.description.length > 0
    }
}
