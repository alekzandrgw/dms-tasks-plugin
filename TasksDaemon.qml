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
        model: SettingsData.getFilteredScreens("tasks")

        delegate: DankSlideout {
            id: taskSlideout
            title: ""
            slideoutWidth: 480
            expandable: true
            expandedWidthValue: 960
            edgeGap: SettingsData.notepadEffectiveEdgeGap
            slideEdge: SettingsData.notepadSlideoutSide
            customTransparency: Theme.notepadTransparency
            layerNamespace: "dms:tasks"

            content: Component {
                TasksContent {
                    slideout: taskSlideout
                    tasksModel: root.tasksModel
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
