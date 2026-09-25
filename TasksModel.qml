import QtQuick
import QtCore
import Quickshell
import Quickshell.Io
import qs.Common
import qs.Services

Item {
    id: root

    property var pluginService: null
    property string pluginId: "tasks"
    property var tasks: []
    property int totalPending: 0
    property int totalCompleted: 0
    readonly property string baseDir: Paths.strip(StandardPaths.writableLocation(StandardPaths.GenericStateLocation) + "/DankMaterialShell")
    readonly property string storagePath: baseDir + "/tasks.json"

    FileView {
        id: storageFile
        path: root.storagePath
        blockLoading: true
        blockWrites: false
        atomicWrites: true

        onLoaded: {
            try {
                const raw = text();
                if (raw && raw.trim()) {
                    const data = JSON.parse(raw);
                    root.tasks = Array.isArray(data) ? data : (data.tasks || []);
                } else {
                    root.tasks = [];
                }
            } catch (e) {
                console.warn("TasksModel: Failed to parse tasks JSON:", e);
                root.tasks = [];
            }
            root.updateCounts();
        }

        onLoadFailed: {
            root.tasks = [];
            root.updateCounts();
        }
    }

    function load() {
        storageFile.path = "";
        storageFile.path = root.storagePath;
    }

    function save() {
        updateCounts();
        if (storageFile) {
            storageFile.setText(JSON.stringify(tasks, null, 2));
        }
    }

    function updateCounts() {
        let pending = 0;
        let completed = 0;
        for (let i = 0; i < tasks.length; i++) {
            if (tasks[i] && tasks[i].done) {
                completed++;
            } else {
                pending++;
            }
        }
        totalPending = pending;
        totalCompleted = completed;

        if (typeof PluginService !== "undefined" && PluginService.setGlobalVar) {
            PluginService.setGlobalVar(pluginId, "pendingCount", pending);
        }
    }

    function addTask(text) {
        if (!text || !text.trim())
            return;
        const newTask = {
            id: Date.now().toString() + "_" + Math.floor(Math.random() * 10000),
            text: text.trim(),
            done: false,
            createdAt: Date.now()
        };
        const updated = tasks.concat([newTask]);
        tasks = updated;
        save();
    }

    function toggleTask(taskId) {
        const updated = [];
        for (let i = 0; i < tasks.length; i++) {
            const item = Object.assign({}, tasks[i]);
            if (item.id === taskId) {
                item.done = !item.done;
            }
            updated.push(item);
        }
        tasks = updated;
        save();
    }

    function editTask(taskId, newText) {
        if (!newText || !newText.trim())
            return;
        const updated = [];
        for (let i = 0; i < tasks.length; i++) {
            const item = Object.assign({}, tasks[i]);
            if (item.id === taskId) {
                item.text = newText.trim();
            }
            updated.push(item);
        }
        tasks = updated;
        save();
    }

    function removeTask(taskId) {
        const updated = [];
        for (let i = 0; i < tasks.length; i++) {
            if (tasks[i].id !== taskId) {
                updated.push(tasks[i]);
            }
        }
        tasks = updated;
        save();
    }

    function clearCompleted() {
        const updated = [];
        for (let i = 0; i < tasks.length; i++) {
            if (!tasks[i].done) {
                updated.push(tasks[i]);
            }
        }
        tasks = updated;
        save();
    }

    Component.onCompleted: {
        load();
    }
}
