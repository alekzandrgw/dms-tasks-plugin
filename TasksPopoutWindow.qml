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

    property int _settingsDep: 0

    Connections {
        target: SettingsData
        enabled: typeof SettingsData !== "undefined"
        function onPluginSettingsChanged() {
            win._settingsDep++;
        }
    }

    readonly property real transparencyOverride: {
        _settingsDep;
        if (typeof SettingsData !== "undefined" && SettingsData.getPluginSetting) {
            return SettingsData.getPluginSetting("tasks", "transparencyOverride", -1);
        }
        return -1;
    }

    surfaceColor: Theme.withAlpha(Theme.surfaceContainer, win.transparencyOverride >= 0 ? win.transparencyOverride : Theme.floatingWindowTransparency)
    visible: false

    onClosed: win.visible = false

    Item {
        anchors.fill: parent

        TasksContent {
            id: contentItemInstance
            anchors.fill: parent
            anchors.margins: Theme.spacingL
            tasksModel: win.tasksModel
            inPopout: true
            onDockRequested: {
                win.hide();
                win.dockRequested();
            }
        }
    }
}
