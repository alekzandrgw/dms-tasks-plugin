import QtQuick
import Quickshell
import Quickshell.Io
import qs.Common
import qs.Services
import qs.Widgets
import qs.Modules.Plugins

PluginComponent {
    id: root

    property var popoutService: null

    TasksModel {
        id: tasksModel
        pluginService: root.pluginService
        pluginId: root.pluginId
    }

    readonly property var _settingsDep: SettingsData.pluginSettings
    readonly property string slideoutSide: {
        _settingsDep;
        return SettingsData.getPluginSetting("tasks", "slideoutSide", "right");
    }
    readonly property bool useCompositorGap: {
        _settingsDep;
        return SettingsData.getPluginSetting("tasks", "useCompositorGap", true);
    }
    readonly property int edgeGapSetting: {
        _settingsDep;
        return SettingsData.getPluginSetting("tasks", "edgeGap", 8);
    }
    readonly property real transparencyOverride: {
        _settingsDep;
        return SettingsData.getPluginSetting("tasks", "transparencyOverride", -1);
    }
    readonly property int effectiveEdgeGap: {
        if (useCompositorGap) {
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
                root.toggleActiveSlideout();
            }
        }
    }

    Variants {
        id: taskSlideoutVariants
        model: Quickshell.screens

        delegate: DankSlideout {
            id: taskSlideout
            title: ""
            slideoutWidth: 440
            edgeGap: root.effectiveEdgeGap
            slideEdge: root.slideoutSide
            customTransparency: root.transparencyOverride
            layerNamespace: "dms:tasks"

            content: Component {
                TasksContent {
                    slideout: taskSlideout
                    tasksModel: tasksModel
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
                if (instances[j]?.modelData?.name === focused) {
                    return instances[j];
                }
            }
        }

        return instances[0];
    }

    function toggleActiveSlideout() {
        const inst = getActiveSlideout();
        if (inst) {
            inst.toggle();
            return inst.isVisible;
        }
        return false;
    }

    IpcHandler {
        target: "tasks"

        function toggle(): string {
            const inst = root.getActiveSlideout();
            if (inst) {
                const wasVisible = inst.isVisible;
                inst.toggle();
                return wasVisible ? "TASKS_CLOSED" : "TASKS_OPEN";
            }
            return "TASKS_TOGGLE_FAILED";
        }

        function open(): string {
            const inst = root.getActiveSlideout();
            if (inst) {
                inst.show();
                return "TASKS_OPEN_SUCCESS";
            }
            return "TASKS_OPEN_FAILED";
        }

        function close(): string {
            const instances = taskSlideoutVariants.instances || [];
            for (let i = 0; i < instances.length; i++) {
                if (instances[i])
                    instances[i].hide();
            }
            return "TASKS_CLOSE_SUCCESS";
        }

        function add(text: string): string {
            if (!text || !text.trim())
                return "TASK_EMPTY";
            tasksModel.addTask(text.trim());
            return "TASK_ADDED";
        }
    }

    Component.onCompleted: {
        console.info("TasksDaemon: Initialized tasks daemon service");
    }
}
