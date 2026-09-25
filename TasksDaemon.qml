import QtQuick
import Quickshell
import Quickshell.Io
import qs.Common
import qs.Services
import qs.Widgets
import qs.Modules.Plugins

PluginComponent {
    id: root

    property alias tasksModel: tasksModel

    TasksModel {
        id: tasksModel
        pluginService: root.pluginService
        pluginId: root.pluginId
    }

    readonly property var _settingsDep: typeof SettingsData !== "undefined" ? SettingsData.pluginSettings : null

    readonly property string defaultMode: {
        _settingsDep;
        if (typeof SettingsData !== "undefined" && SettingsData.getPluginSetting) {
            return SettingsData.getPluginSetting("tasks", "defaultMode", "slideout");
        }
        return "slideout";
    }

    readonly property string slideoutSide: {
        _settingsDep;
        if (typeof SettingsData !== "undefined" && SettingsData.getPluginSetting) {
            return SettingsData.getPluginSetting("tasks", "slideoutSide", "right");
        }
        return "right";
    }

    readonly property bool useCompositorGap: {
        _settingsDep;
        if (typeof SettingsData !== "undefined" && SettingsData.getPluginSetting) {
            return SettingsData.getPluginSetting("tasks", "useCompositorGap", true);
        }
        return true;
    }

    readonly property int edgeGapSetting: {
        _settingsDep;
        if (typeof SettingsData !== "undefined" && SettingsData.getPluginSetting) {
            return SettingsData.getPluginSetting("tasks", "edgeGap", 8);
        }
        return 8;
    }

    readonly property real transparencyOverride: {
        _settingsDep;
        if (typeof SettingsData !== "undefined" && SettingsData.getPluginSetting) {
            return SettingsData.getPluginSetting("tasks", "transparencyOverride", -1);
        }
        return -1;
    }

    readonly property int effectiveEdgeGap: {
        if (useCompositorGap && typeof SettingsData !== "undefined") {
            var g = -1;
            switch (SettingsData.activeCompositor) {
            case "niri":
                g = SettingsData.niriLayoutGapsOverride;
                break;
            case "hyprland":
                g = SettingsData.hyprlandLayoutGapsOverride;
                break;
            case "mango":
                g = SettingsData.mangoLayoutGapsOverride;
                break;
            }
            if (g >= 0)
                return g;
            return SettingsData.notepadEffectiveEdgeGap ?? 8;
        }
        return Math.max(0, edgeGapSetting);
    }

    PluginGlobalVar {
        id: toggleRequestVar
        varName: "toggleRequest"
        defaultValue: 0

        onValueChanged: {
            if (value > 0) {
                root.toggleTasks();
            }
        }
    }

    // Floating Popout Window Component for popout mode
    Component {
        id: popoutComponent
        TasksPopoutWindow {
            tasksModel: root.tasksModel
            onDockRequested: {
                root.openSlideout();
            }
        }
    }

    property var taskPopoutWindow: null

    function getPopoutWindow() {
        if (!taskPopoutWindow) {
            taskPopoutWindow = popoutComponent.createObject(null);
        }
        return taskPopoutWindow;
    }

    Variants {
        id: taskSlideoutVariants
        model: SettingsData.getFilteredScreens("tasks")

        delegate: DankSlideout {
            id: taskSlideout
            title: ""
            slideoutWidth: 480
            expandable: true
            expandedWidthValue: 960
            edgeGap: root.effectiveEdgeGap
            slideEdge: root.slideoutSide
            customTransparency: root.transparencyOverride >= 0 ? root.transparencyOverride : Theme.notepadTransparency
            layerNamespace: "dms:tasks"

            content: Component {
                TasksContent {
                    slideout: taskSlideout
                    tasksModel: root.tasksModel
                    inPopout: false
                    onPopoutRequested: {
                        taskSlideout.hide();
                        root.openPopout();
                    }
                }
            }
        }
    }

    function getFocusedScreenName() {
        if (CompositorService.isNiri && typeof NiriService !== "undefined" && NiriService.currentOutput) {
            return NiriService.currentOutput;
        }
        if (CompositorService.isHyprland && typeof Hyprland !== "undefined" && Hyprland.focusedMonitor) {
            return Hyprland.focusedMonitor.name || "";
        }
        return "";
    }

    function getActiveSlideout() {
        const instances = taskSlideoutVariants.instances;
        if (!instances || instances.length === 0)
            return null;

        // If one is already visible, return it
        for (let i = 0; i < instances.length; i++) {
            if (instances[i] && instances[i].isVisible) {
                return instances[i];
            }
        }

        // Match focused screen
        const focused = getFocusedScreenName();
        if (focused) {
            for (let j = 0; j < instances.length; j++) {
                if (instances[j] && instances[j].modelData && instances[j].modelData.name === focused) {
                    return instances[j];
                }
            }
        }

        return instances[0];
    }

    function openPopout() {
        closeSlideouts();
        const win = getPopoutWindow();
        if (win)
            win.show();
    }

    function closePopout() {
        if (taskPopoutWindow)
            taskPopoutWindow.hide();
    }

    function togglePopout() {
        const win = getPopoutWindow();
        if (win && win.visible) {
            win.hide();
            return false;
        } else if (win) {
            closeSlideouts();
            win.show();
            return true;
        }
        return false;
    }

    function openSlideout() {
        closePopout();
        const inst = getActiveSlideout();
        if (inst) {
            inst.show();
            return true;
        }
        return false;
    }

    function closeSlideouts() {
        const instances = taskSlideoutVariants.instances || [];
        for (let i = 0; i < instances.length; i++) {
            if (instances[i])
                instances[i].hide();
        }
    }

    function toggleActiveSlideout() {
        closePopout();
        const inst = getActiveSlideout();
        if (inst) {
            inst.toggle();
            return inst.isVisible;
        }
        return false;
    }

    function toggleTasks() {
        if (defaultMode === "popout") {
            return togglePopout();
        } else {
            return toggleActiveSlideout();
        }
    }

    function openTasks() {
        if (defaultMode === "popout") {
            openPopout();
            return true;
        } else {
            return openSlideout();
        }
    }

    function closeTasks() {
        closePopout();
        closeSlideouts();
    }

    IpcHandler {
        target: "tasks"

        function toggle(): string {
            const isOpen = root.toggleTasks();
            return isOpen ? "TASKS_OPEN" : "TASKS_CLOSED";
        }

        function open(): string {
            const ok = root.openTasks();
            return ok ? "TASKS_OPEN_SUCCESS" : "TASKS_OPEN_FAILED";
        }

        function close(): string {
            root.closeTasks();
            return "TASKS_CLOSE_SUCCESS";
        }

        function popout(): string {
            root.openPopout();
            return "TASKS_POPOUT_OPEN";
        }

        function slideout(): string {
            root.openSlideout();
            return "TASKS_SLIDEOUT_OPEN";
        }

        function toggleExpand(): string {
            const inst = root.getActiveSlideout();
            if (inst && inst.expandable) {
                inst.expandedWidth = !inst.expandedWidth;
                return "TASKS_EXPAND_TOGGLED";
            }
            return "TASKS_EXPAND_FAILED";
        }

        function expand(): string {
            const inst = root.getActiveSlideout();
            if (inst && inst.expandable) {
                inst.expandedWidth = true;
                return "TASKS_EXPANDED";
            }
            return "TASKS_EXPAND_FAILED";
        }

        function collapse(): string {
            const inst = root.getActiveSlideout();
            if (inst && inst.expandable) {
                inst.expandedWidth = false;
                return "TASKS_COLLAPSED";
            }
            return "TASKS_COLLAPSE_FAILED";
        }

        function add(text: string): string {
            if (!text || !text.trim())
                return "TASK_EMPTY";
            tasksModel.addTask(text.trim());
            return "TASK_ADDED";
        }

        function move(fromIdx: int, toIdx: int): string {
            tasksModel.moveTask(fromIdx, toIdx);
            return "TASK_MOVED";
        }

        function toggleDone(taskId: string): string {
            tasksModel.toggleTask(taskId);
            return "TASK_TOGGLED";
        }
    }

    Component.onCompleted: {
        console.info("TasksDaemon: Initialized tasks daemon service");
    }
}
