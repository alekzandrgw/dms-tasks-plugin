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
    property var pendingTasks: []
    property var completedTasks: []
    property int totalPending: 0
    property int totalCompleted: 0
    readonly property string baseDir: Paths.strip(StandardPaths.writableLocation(StandardPaths.GenericStateLocation) + "/DankMaterialShell")
    readonly property string storagePath: baseDir + "/tasks.json"

    onTasksChanged: {
        updateCounts();
    }

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
                    const list = Array.isArray(data) ? data : (data.tasks || []);
                    const pending = [];
                    const completed = [];
                    for (let i = 0; i < list.length; i++) {
                        if (list[i] && list[i].done) {
                            completed.push(list[i]);
                        } else if (list[i]) {
                            pending.push(list[i]);
                        }
                    }
                    root.tasks = pending.concat(completed);
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
        const pending = [];
        const completed = [];
        for (let i = 0; i < tasks.length; i++) {
            if (tasks[i] && tasks[i].done) {
                completed.push(tasks[i]);
            } else if (tasks[i]) {
                pending.push(tasks[i]);
            }
        }
        pendingTasks = pending;
        completedTasks = completed;
        totalPending = pending.length;
        totalCompleted = completed.length;

        if (typeof PluginService !== "undefined" && PluginService.setGlobalVar) {
            PluginService.setGlobalVar(pluginId, "pendingCount", pending.length);
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
        const updated = [];
        let inserted = false;
        for (let i = 0; i < tasks.length; i++) {
            if (!inserted && tasks[i].done) {
                updated.push(newTask);
                inserted = true;
            }
            updated.push(tasks[i]);
        }
        if (!inserted) {
            updated.push(newTask);
        }
        tasks = updated;
        save();
    }

    function toggleTask(taskId) {
        let toggledItem = null;
        const remaining = [];
        for (let i = 0; i < tasks.length; i++) {
            const item = Object.assign({}, tasks[i]);
            if (item.id === taskId) {
                item.done = !item.done;
                toggledItem = item;
            } else {
                remaining.push(item);
            }
        }
        if (!toggledItem)
            return;

        const updated = [];
        if (toggledItem.done) {
            // Task marked completed: move to the bottom
            for (let i = 0; i < remaining.length; i++) {
                updated.push(remaining[i]);
            }
            updated.push(toggledItem);
        } else {
            // Task marked pending: place right above the first completed task
            let inserted = false;
            for (let i = 0; i < remaining.length; i++) {
                if (!inserted && remaining[i].done) {
                    updated.push(toggledItem);
                    inserted = true;
                }
                updated.push(remaining[i]);
            }
            if (!inserted) {
                updated.push(toggledItem);
            }
        }
        tasks = updated;
        save();
    }

    function moveTask(fromIndex, toIndex) {
        if (fromIndex === toIndex || fromIndex < 0 || toIndex < 0 || fromIndex >= tasks.length || toIndex >= tasks.length)
            return;
        const updated = tasks.slice(0);
        const item = updated.splice(fromIndex, 1)[0];
        updated.splice(toIndex, 0, item);
        tasks = updated;
        save();
    }

    function movePendingTask(fromIndex, toIndex) {
        if (fromIndex === toIndex || fromIndex < 0 || toIndex < 0 || fromIndex >= pendingTasks.length || toIndex >= pendingTasks.length)
            return;
        moveTask(fromIndex, toIndex);
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
