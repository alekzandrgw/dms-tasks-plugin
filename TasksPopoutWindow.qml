import QtQuick
import Quickshell
import qs.Common
import qs.Services
import qs.Widgets

DankFloatingWindow {
    id: win

    property var tasksModel: null
    property alias tasksContent: contentItemInstance

    signal dockRequested

    function show() {
        visible = true;
    }

    function hide() {
        visible = false;
    }

    function toggle() {
        visible = !visible;
    }

    title: I18n.tr("Tasks")
    minimumSize: Qt.size(360, 420)
    implicitWidth: 480
    implicitHeight: 640
    surfaceColor: Theme.floatingWindowSurface
    visible: false

    onClosed: win.visible = false

    Item {
        anchors.fill: parent

        TasksContent {
            id: contentItemInstance
            anchors.fill: parent
            anchors.margins: Theme.spacingM
            tasksModel: win.tasksModel
            inPopout: true
            onDockRequested: {
                win.hide();
                win.dockRequested();
            }
        }
    }
}
