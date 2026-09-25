import QtQuick
import QtQuick.Layouts
import qs.Common
import qs.Widgets

FocusScope {
    id: root
    focus: true

    property var slideout: null
    property var tasksModel: null
    property bool inPopout: false
    property bool showSettingsMenu: false

    signal popoutRequested
    signal dockRequested

    readonly property var pendingTasks: (root.tasksModel && root.tasksModel.pendingTasks) ? root.tasksModel.pendingTasks : []
    readonly property var completedTasks: (root.tasksModel && root.tasksModel.completedTasks) ? root.tasksModel.completedTasks : []
    readonly property int totalCount: (root.tasksModel && root.tasksModel.tasks) ? root.tasksModel.tasks.length : 0

    property int _settingsDep: 0

    Connections {
        target: SettingsData
        enabled: typeof SettingsData !== "undefined"
        function onPluginSettingsChanged() {
            root._settingsDep++;
        }
    }

    readonly property real effectiveOpacity: {
        _settingsDep;
        if (typeof SettingsData !== "undefined" && SettingsData.getPluginSetting) {
            const val = SettingsData.getPluginSetting("tasks", "transparencyOverride", -1);
            if (val >= 0)
                return val;
        }
        return root.inPopout ? (Theme.floatingWindowTransparency ?? 0.95) : (Theme.notepadTransparency ?? 0.95);
    }

    // Keyboard navigation state
    property int selectedSection: 0 // 0 = pending, 1 = completed
    property int selectedIndex: -1   // -1 = input, >= 0 = card index
    property bool isEditingTask: false

    // Drag-and-drop state
    property int draggedIndex: -1
    property int hoverTargetIndex: -1
    property real draggedItemHeight: 48
    property real currentDragCenterY: 0

    anchors.fill: parent

    function submitNewTask() {
        const textVal = taskTextEdit.text ? taskTextEdit.text.trim() : "";
        if (!textVal)
            return;
        if (root.tasksModel) {
            root.tasksModel.addTask(textVal);
            taskTextEdit.text = "";
            taskTextEdit.forceActiveFocus();
        } else {
            console.warn("TasksContent: root.tasksModel is not bound!");
        }
    }

    function updateDragHover(draggedIdx, centerY) {
        currentDragCenterY = centerY;
        if (draggedIdx < 0 || root.pendingTasks.length <= 1) {
            hoverTargetIndex = draggedIdx;
            return;
        }
        let bestIdx = draggedIdx;
        let minDist = 999999;
        for (let i = 0; i < pendingRepeater.count; i++) {
            const item = pendingRepeater.itemAt(i);
            if (item) {
                const itemCenter = item.y + item.height / 2;
                const dist = Math.abs(itemCenter - centerY);
                if (dist < minDist) {
                    minDist = dist;
                    bestIdx = i;
                }
            }
        }
        hoverTargetIndex = Math.max(0, Math.min(bestIdx, root.pendingTasks.length - 1));
    }

    Timer {
        id: autoScrollTimer
        interval: 16
        repeat: true
        running: root.draggedIndex >= 0

        onTriggered: {
            if (!tasksFlickable || root.draggedIndex < 0)
                return;
            const pt = pendingColumn.mapToItem(tasksFlickable, 0, root.currentDragCenterY);
            const topThreshold = 40;
            const bottomThreshold = tasksFlickable.height - 40;
            const scrollSpeed = 6;
            if (pt.y < topThreshold && tasksFlickable.contentY > 0) {
                tasksFlickable.contentY = Math.max(0, tasksFlickable.contentY - scrollSpeed);
            } else if (pt.y > bottomThreshold && tasksFlickable.contentY < tasksFlickable.contentHeight - tasksFlickable.height) {
                tasksFlickable.contentY = Math.min(tasksFlickable.contentHeight - tasksFlickable.height, tasksFlickable.contentY + scrollSpeed);
            }
        }
    }

    function ensurePendingVisible(idx) {
        if (!tasksFlickable || idx < 0 || idx >= pendingRepeater.count)
            return;
        const item = pendingRepeater.itemAt(idx);
        if (!item)
            return;
        const itemTop = item.y;
        const itemBottom = item.y + item.height;
        if (itemTop < tasksFlickable.contentY) {
            tasksFlickable.contentY = itemTop;
        } else if (itemBottom > tasksFlickable.contentY + tasksFlickable.height) {
            tasksFlickable.contentY = itemBottom - tasksFlickable.height;
        }
    }

    function ensureCompletedVisible(idx) {
        if (!completedFlickable || idx < 0 || idx >= completedRepeater.count)
            return;
        const item = completedRepeater.itemAt(idx);
        if (!item)
            return;
        const itemTop = item.y;
        const itemBottom = item.y + item.height;
        if (itemTop < completedFlickable.contentY) {
            completedFlickable.contentY = itemTop;
        } else if (itemBottom > completedFlickable.contentY + completedFlickable.height) {
            completedFlickable.contentY = itemBottom - completedFlickable.height;
        }
    }

    function startCurrentEdit() {
        if (selectedIndex < 0)
            return;
        if (selectedSection === 0) {
            const item = pendingRepeater.itemAt(selectedIndex);
            if (item && item.taskCard) {
                item.taskCard.startEdit();
                isEditingTask = true;
            }
        } else if (selectedSection === 1) {
            const item = completedRepeater.itemAt(selectedIndex);
            if (item && item.completedCard) {
                item.completedCard.startEdit();
                isEditingTask = true;
            }
        }
    }

    function saveCurrentEdit() {
        if (selectedIndex < 0)
            return;
        if (selectedSection === 0) {
            const item = pendingRepeater.itemAt(selectedIndex);
            if (item && item.taskCard) {
                item.taskCard.saveEdit();
            }
        } else if (selectedSection === 1) {
            const item = completedRepeater.itemAt(selectedIndex);
            if (item && item.completedCard) {
                item.completedCard.saveEdit();
            }
        }
        isEditingTask = false;
        root.forceActiveFocus();
    }

    function cancelCurrentEdit() {
        if (selectedIndex < 0)
            return;
        if (selectedSection === 0) {
            const item = pendingRepeater.itemAt(selectedIndex);
            if (item && item.taskCard) {
                item.taskCard.cancelEdit();
            }
        } else if (selectedSection === 1) {
            const item = completedRepeater.itemAt(selectedIndex);
            if (item && item.completedCard) {
                item.completedCard.cancelEdit();
            }
        }
        isEditingTask = false;
        root.forceActiveFocus();
    }

    function toggleCurrentTask() {
        if (selectedIndex < 0 || !root.tasksModel)
            return;
        if (selectedSection === 0 && selectedIndex < root.pendingTasks.length) {
            const task = root.pendingTasks[selectedIndex];
            if (task) {
                root.tasksModel.toggleTask(task.id);
                if (selectedIndex >= root.pendingTasks.length - 1) {
                    selectedIndex = Math.max(0, root.pendingTasks.length - 2);
                }
            }
        } else if (selectedSection === 1 && selectedIndex < root.completedTasks.length) {
            const task = root.completedTasks[selectedIndex];
            if (task) {
                root.tasksModel.toggleTask(task.id);
                if (selectedIndex >= root.completedTasks.length - 1) {
                    selectedIndex = Math.max(0, root.completedTasks.length - 2);
                }
            }
        }
    }

    function toggleCurrentExpand() {
        if (selectedIndex < 0)
            return;
        if (selectedSection === 0) {
            const item = pendingRepeater.itemAt(selectedIndex);
            if (item && item.taskCard && item.taskCard.isLongText) {
                item.taskCard.isExpanded = !item.taskCard.isExpanded;
            }
        } else if (selectedSection === 1) {
            const item = completedRepeater.itemAt(selectedIndex);
            if (item && item.completedCard && item.completedCard.isLongText) {
                item.completedCard.isExpanded = !item.completedCard.isExpanded;
            }
        }
    }

    Keys.onPressed: function(event) {
        // Ctrl + N: Jump to new task input
        if ((event.modifiers & Qt.ControlModifier) && event.key === Qt.Key_N) {
            event.accepted = true;
            root.selectedIndex = -1;
            root.isEditingTask = false;
            taskTextEdit.forceActiveFocus();
            return;
        }

        // When settings menu is open, Esc closes it
        if (root.showSettingsMenu) {
            if (event.key === Qt.Key_Escape) {
                event.accepted = true;
                root.showSettingsMenu = false;
            }
            return;
        }

        // If currently editing inline in a task
        if (root.isEditingTask) {
            if ((event.modifiers & Qt.ControlModifier) && event.key === Qt.Key_E) {
                event.accepted = true;
                root.saveCurrentEdit();
                return;
            }
            if (event.key === Qt.Key_Escape) {
                event.accepted = true;
                root.cancelCurrentEdit();
                return;
            }
            return;
        }

        // Ctrl + Tab: Switch between pending and completed section
        if ((event.modifiers & Qt.ControlModifier) && (event.key === Qt.Key_Tab || event.key === Qt.Key_Backtab)) {
            event.accepted = true;
            taskTextEdit.focus = false;
            root.forceActiveFocus();
            if (root.selectedSection === 0 && root.completedTasks.length > 0) {
                root.selectedSection = 1;
                root.selectedIndex = Math.max(0, Math.min(root.selectedIndex, root.completedTasks.length - 1));
                root.ensureCompletedVisible(root.selectedIndex);
            } else if (root.selectedSection === 1 && root.pendingTasks.length > 0) {
                root.selectedSection = 0;
                root.selectedIndex = Math.max(0, Math.min(root.selectedIndex, root.pendingTasks.length - 1));
                root.ensurePendingVisible(root.selectedIndex);
            } else if (root.pendingTasks.length > 0) {
                root.selectedSection = 0;
                root.selectedIndex = 0;
                root.ensurePendingVisible(0);
            }
            return;
        }

        // If input box is focused:
        if (taskTextEdit.activeFocus) {
            if (event.key === Qt.Key_Down && taskTextEdit.lineCount <= 1) {
                if (root.pendingTasks.length > 0) {
                    event.accepted = true;
                    taskTextEdit.focus = false;
                    root.forceActiveFocus();
                    root.selectedSection = 0;
                    root.selectedIndex = 0;
                    root.ensurePendingVisible(0);
                } else if (root.completedTasks.length > 0) {
                    event.accepted = true;
                    taskTextEdit.focus = false;
                    root.forceActiveFocus();
                    root.selectedSection = 1;
                    root.selectedIndex = 0;
                    root.ensureCompletedVisible(0);
                }
                return;
            }
            return;
        }

        // Down arrow: Navigate forward
        if (event.key === Qt.Key_Down) {
            event.accepted = true;
            if (root.selectedSection === 0) {
                if (root.selectedIndex < root.pendingTasks.length - 1) {
                    root.selectedIndex++;
                    root.ensurePendingVisible(root.selectedIndex);
                } else if (root.completedTasks.length > 0) {
                    root.selectedSection = 1;
                    root.selectedIndex = 0;
                    root.ensureCompletedVisible(0);
                }
            } else if (root.selectedSection === 1) {
                if (root.selectedIndex < root.completedTasks.length - 1) {
                    root.selectedIndex++;
                    root.ensureCompletedVisible(root.selectedIndex);
                }
            }
            return;
        }

        // Up arrow: Navigate backward
        if (event.key === Qt.Key_Up) {
            event.accepted = true;
            if (root.selectedSection === 1) {
                if (root.selectedIndex > 0) {
                    root.selectedIndex--;
                    root.ensureCompletedVisible(root.selectedIndex);
                } else if (root.pendingTasks.length > 0) {
                    root.selectedSection = 0;
                    root.selectedIndex = root.pendingTasks.length - 1;
                    root.ensurePendingVisible(root.selectedIndex);
                } else {
                    root.selectedIndex = -1;
                    taskTextEdit.forceActiveFocus();
                }
            } else if (root.selectedSection === 0) {
                if (root.selectedIndex > 0) {
                    root.selectedIndex--;
                    root.ensurePendingVisible(root.selectedIndex);
                } else {
                    root.selectedIndex = -1;
                    taskTextEdit.forceActiveFocus();
                }
            }
            return;
        }

        // Ctrl + E: Edit selected task
        if ((event.modifiers & Qt.ControlModifier) && event.key === Qt.Key_E) {
            event.accepted = true;
            root.startCurrentEdit();
            return;
        }

        // Space: Toggle task completion
        if (event.key === Qt.Key_Space) {
            event.accepted = true;
            root.toggleCurrentTask();
            return;
        }

        // Enter: Toggle expand / collapse
        if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
            event.accepted = true;
            root.toggleCurrentExpand();
            return;
        }

        // Escape: Close panel / cancel drag
        if (event.key === Qt.Key_Escape) {
            event.accepted = true;
            if (root.draggedIndex >= 0) {
                root.draggedIndex = -1;
                root.hoverTargetIndex = -1;
                return;
            }
            if (slideout) {
                slideout.hide();
            }
            return;
        }
    }

    Connections {
        target: slideout
        enabled: slideout !== null
        function onRevealed() {
            root.forceActiveFocus();
            taskTextEdit.forceActiveFocus();
        }
    }

    // Background click handler to clear focus/selection when clicking blank space
    MouseArea {
        anchors.fill: parent
        z: -1
        onClicked: {
            root.selectedIndex = -1;
        }
    }

    ColumnLayout {
        anchors.fill: parent
        spacing: Theme.spacingM

        // Single Top Title Bar: [icon] Tasks  ... [clear] [expand] [close]
        Item {
            Layout.fillWidth: true
            Layout.preferredHeight: 32

            MouseArea {
                anchors.fill: parent
                z: 0
                onClicked: {
                    root.selectedIndex = -1;
                }
            }

            Row {
                anchors.left: parent.left
                anchors.verticalCenter: parent.verticalCenter
                spacing: Theme.spacingS

                DankIcon {
                    name: "checklist"
                    size: Theme.iconSize
                    color: Theme.primary
                    anchors.verticalCenter: parent.verticalCenter
                }

                StyledText {
                    text: I18n.tr("Tasks")
                    font.pixelSize: Theme.fontSizeLarge
                    font.weight: Font.DemiBold
                    color: Theme.surfaceText
                    anchors.verticalCenter: parent.verticalCenter
                }

                // Pending count pill
                Rectangle {
                    visible: Boolean(root.tasksModel && root.tasksModel.totalPending > 0)
                    width: Math.max(20, countText.implicitWidth + Theme.spacingS * 2)
                    height: 20
                    radius: 10
                    color: Theme.primary
                    anchors.verticalCenter: parent.verticalCenter

                    StyledText {
                        id: countText
                        anchors.centerIn: parent
                        text: (root.tasksModel ? root.tasksModel.totalPending : 0).toString()
                        font.pixelSize: Theme.fontSizeSmall - 2
                        font.weight: Font.Bold
                        color: Theme.surface
                    }
                }
            }

            Row {
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                spacing: Theme.spacingXS

                // Clear Completed Button
                DankActionButton {
                    visible: Boolean(root.tasksModel && root.tasksModel.totalCompleted > 0)
                    circular: false
                    iconName: "remove_done"
                    iconSize: Theme.iconSize - 4
                    iconColor: Theme.surfaceVariantText
                    tooltipText: I18n.tr("Clear completed tasks")
                    onClicked: {
                        if (root.tasksModel)
                            root.tasksModel.clearCompleted();
                    }
                }

                // Expand / Collapse Button (slideout only)
                DankActionButton {
                    id: expandButton
                    visible: Boolean(!root.inPopout && root.slideout && root.slideout.expandable)
                    circular: false
                    iconName: (root.slideout && root.slideout.expandedWidth) ? "unfold_less" : "unfold_more"
                    iconSize: Theme.iconSize - 4
                    iconColor: Theme.surfaceText
                    tooltipText: (root.slideout && root.slideout.expandedWidth) ? I18n.tr("Collapse") : I18n.tr("Expand")
                    transform: Rotation {
                        angle: 90
                        origin.x: expandButton.width / 2
                        origin.y: expandButton.height / 2
                    }
                    onClicked: {
                        if (root.slideout)
                            root.slideout.expandedWidth = !root.slideout.expandedWidth;
                    }
                }

                // Close Button
                DankActionButton {
                    circular: false
                    iconName: "close"
                    iconSize: Theme.iconSize - 4
                    iconColor: Theme.surfaceText
                    tooltipText: I18n.tr("Close (Esc)")
                    onClicked: {
                        if (root.inPopout) {
                            root.dockRequested();
                        } else if (root.slideout) {
                            root.slideout.hide();
                        }
                    }
                }
            }
        }

        // Auto-expanding Quick Add Input Box
        StyledRect {
            id: taskInputContainer
            Layout.fillWidth: true
            Layout.preferredHeight: Math.min(160, Math.max(40, taskTextEdit.contentHeight + 16))
            radius: Theme.cornerRadius
            color: Theme.withAlpha(Theme.surfaceContainerHigh, root.effectiveOpacity * 0.7)
            border.color: taskTextEdit.activeFocus ? Theme.primary : Theme.outlineMedium
            border.width: taskTextEdit.activeFocus ? 2 : 1

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: Theme.spacingM
                anchors.rightMargin: Theme.spacingS
                spacing: Theme.spacingS

                DankIcon {
                    Layout.alignment: taskTextEdit.lineCount > 1 ? Qt.AlignTop : Qt.AlignVCenter
                    Layout.topMargin: taskTextEdit.lineCount > 1 ? 10 : 0
                    name: "add"
                    size: Theme.iconSizeSmall
                    color: taskTextEdit.activeFocus ? Theme.primary : Theme.surfaceVariantText
                }

                Item {
                    Layout.fillWidth: true
                    Layout.fillHeight: true

                    DankFlickable {
                        id: inputFlickable
                        anchors.fill: parent
                        anchors.topMargin: taskTextEdit.lineCount > 1 ? 8 : 0
                        anchors.bottomMargin: taskTextEdit.lineCount > 1 ? 8 : 0
                        clip: true
                        contentWidth: width
                        contentHeight: taskTextEdit.contentHeight

                        TextEdit {
                            id: taskTextEdit
                            width: inputFlickable.width - (inputScrollbar.visible ? 12 : 0)
                            y: taskTextEdit.lineCount > 1 ? 0 : Math.max(0, Math.floor((inputFlickable.height - contentHeight) / 2))
                            font.pixelSize: Theme.fontSizeMedium
                            font.family: Theme.fontFamily
                            color: Theme.surfaceText
                            selectionColor: Theme.primaryContainer
                            selectedTextColor: Theme.primary
                            wrapMode: TextEdit.Wrap
                            selectByMouse: true
                            cursorDelegate: DankTextCursor {
                                color: taskTextEdit.color
                                shown: taskTextEdit.cursorVisible
                            }

                            onActiveFocusChanged: {
                                if (activeFocus) {
                                    root.selectedIndex = -1;
                                }
                            }

                            onCursorRectangleChanged: {
                                if (cursorRectangle.y < inputFlickable.contentY) {
                                    inputFlickable.contentY = cursorRectangle.y;
                                } else if (cursorRectangle.y + cursorRectangle.height > inputFlickable.contentY + inputFlickable.height) {
                                    inputFlickable.contentY = cursorRectangle.y + cursorRectangle.height - inputFlickable.height;
                                }
                            }

                            Keys.onReturnPressed: function(event) {
                                if (event.modifiers & Qt.ShiftModifier) {
                                    event.accepted = false;
                                } else {
                                    event.accepted = true;
                                    root.submitNewTask();
                                }
                            }
                            Keys.onEnterPressed: function(event) {
                                if (event.modifiers & Qt.ShiftModifier) {
                                    event.accepted = false;
                                } else {
                                    event.accepted = true;
                                    root.submitNewTask();
                                }
                            }
                        }

                        // Placeholder label
                        StyledText {
                            anchors.left: parent.left
                            anchors.verticalCenter: taskTextEdit.verticalCenter
                            text: I18n.tr("Add a task... (Press Enter)")
                            font: taskTextEdit.font
                            color: Theme.surfaceVariantText
                            visible: taskTextEdit.text.length === 0 && !taskTextEdit.activeFocus && !taskTextEdit.inputMethodComposing
                        }

                        DankScrollbar {
                            id: inputScrollbar
                            targetFlickable: inputFlickable
                            anchors.right: parent.right
                            anchors.top: parent.top
                            anchors.bottom: parent.bottom
                        }
                    }
                }

                DankActionButton {
                    Layout.alignment: taskTextEdit.lineCount > 1 ? Qt.AlignTop : Qt.AlignVCenter
                    Layout.topMargin: taskTextEdit.lineCount > 1 ? 4 : 0
                    visible: taskTextEdit.text.length > 0
                    circular: false
                    iconName: "close"
                    iconSize: Theme.iconSizeSmall - 2
                    iconColor: Theme.surfaceVariantText
                    tooltipText: I18n.tr("Clear")
                    onClicked: {
                        taskTextEdit.text = "";
                        taskTextEdit.forceActiveFocus();
                    }
                }
            }
        }

        // Active / Pending Tasks Scrollable Area (takes all available middle space)
        Item {
            Layout.fillWidth: true
            Layout.fillHeight: true

            DankFlickable {
                id: tasksFlickable
                anchors.fill: parent
                clip: true
                contentWidth: width
                contentHeight: mainContentColumn.implicitHeight

                // Blank space click handler
                MouseArea {
                    width: parent.width
                    height: Math.max(tasksFlickable.height, mainContentColumn.implicitHeight)
                    z: 0
                    onClicked: {
                        root.selectedIndex = -1;
                    }
                }

                Column {
                    id: mainContentColumn
                    width: tasksFlickable.width - (tasksScrollbar.visible ? 12 : 0)
                    spacing: Theme.spacingM

                    // Overall Empty state (when total tasks === 0)
                    Item {
                        width: parent.width
                        height: Math.max(160, tasksFlickable.height - 40)
                        visible: root.totalCount === 0

                        Column {
                            anchors.centerIn: parent
                            spacing: Theme.spacingM

                            DankIcon {
                                anchors.horizontalCenter: parent.horizontalCenter
                                name: "task_alt"
                                size: 48
                                color: Theme.outlineMedium
                            }

                            StyledText {
                                anchors.horizontalCenter: parent.horizontalCenter
                                text: I18n.tr("No tasks yet")
                                font.pixelSize: Theme.fontSizeMedium
                                color: Theme.surfaceVariantText
                            }
                        }
                    }

                    // All pending tasks completed info pill (when pending === 0 && completed > 0)
                    Item {
                        width: parent.width
                        height: Math.max(120, tasksFlickable.height - 40)
                        visible: root.pendingTasks.length === 0 && root.completedTasks.length > 0

                        Column {
                            anchors.centerIn: parent
                            spacing: Theme.spacingS

                            DankIcon {
                                anchors.horizontalCenter: parent.horizontalCenter
                                name: "task_alt"
                                size: 36
                                color: Theme.primary
                            }

                            StyledText {
                                anchors.horizontalCenter: parent.horizontalCenter
                                text: I18n.tr("All tasks complete!")
                                font.pixelSize: Theme.fontSizeMedium
                                font.weight: Font.Medium
                                color: Theme.surfaceText
                            }

                            StyledText {
                                anchors.horizontalCenter: parent.horizontalCenter
                                text: I18n.tr("Completed tasks are saved at the bottom")
                                font.pixelSize: Theme.fontSizeSmall
                                color: Theme.surfaceVariantText
                            }
                        }
                    }

                    // Pending / Active Tasks Section (Draggable with interactive displacement animation)
                    Column {
                        id: pendingColumn
                        width: parent.width
                        spacing: Theme.spacingXS
                        visible: root.pendingTasks.length > 0
                        z: 10

                        Repeater {
                            id: pendingRepeater
                            model: root.pendingTasks

                            delegate: Item {
                                id: delegateRoot
                                width: pendingColumn.width
                                height: taskItemRoot.height
                                z: taskItemRoot.isDragging ? 100 : 1

                                property alias taskCard: taskItemRoot

                                readonly property bool isSelected: root.selectedSection === 0 && root.selectedIndex === index && !taskTextEdit.activeFocus

                                onIsSelectedChanged: {
                                    if (!isSelected) {
                                        taskItemRoot.isExpanded = false;
                                        if (taskItemRoot.isEditing) {
                                            taskItemRoot.saveEdit();
                                        }
                                    }
                                }

                                Item {
                                    id: displacer
                                    width: parent.width
                                    height: parent.height

                                    // Real-time displacement calculation to "make room" for the dragged item
                                    readonly property real slotStep: (root.draggedItemHeight > 0 ? root.draggedItemHeight : 48) + pendingColumn.spacing
                                    readonly property real targetY: {
                                        if (root.draggedIndex < 0 || root.hoverTargetIndex < 0 || root.draggedIndex === index) {
                                            return 0;
                                        }
                                        if (root.draggedIndex < root.hoverTargetIndex) {
                                            if (index > root.draggedIndex && index <= root.hoverTargetIndex) {
                                                return -slotStep;
                                            }
                                        } else if (root.draggedIndex > root.hoverTargetIndex) {
                                            if (index >= root.hoverTargetIndex && index < root.draggedIndex) {
                                                return slotStep;
                                            }
                                        }
                                        return 0;
                                    }

                                    y: taskItemRoot.isDragging ? 0 : targetY

                                    Behavior on y {
                                        enabled: !taskItemRoot.isDragging
                                        NumberAnimation {
                                            duration: 180
                                            easing.type: Easing.OutCubic
                                        }
                                    }

                                    StyledRect {
                                        id: taskItemRoot
                                        width: parent.width
                                        radius: Theme.cornerRadius
                                        clip: true
                                        color: isDragging ? Theme.withAlpha(Theme.surfaceContainerHighest, root.effectiveOpacity)
                                                          : (delegateRoot.isSelected ? Theme.withAlpha(Theme.surfaceContainerHighest, root.effectiveOpacity)
                                                                                     : (taskCardHoverHandler.hovered
                                                                                         ? Theme.withAlpha(Theme.surfaceContainerHighest, root.effectiveOpacity * 0.75)
                                                                                         : Theme.withAlpha(Theme.surfaceContainerHigh, root.effectiveOpacity * 0.85)))
                                        border.color: isDragging ? Theme.primary : (isEditing ? Theme.primary : (delegateRoot.isSelected ? Theme.primary : "transparent"))
                                        border.width: (isDragging || delegateRoot.isSelected) ? 2 : (isEditing ? 1 : 0)
                                        z: isDragging ? 100 : 1

                                        HoverHandler {
                                            id: taskCardHoverHandler
                                        }

                                        Behavior on color {
                                            ColorAnimation { duration: 120 }
                                        }
                                        Behavior on border.color {
                                            ColorAnimation { duration: 120 }
                                        }

                                        property bool isExpanded: false
                                        property bool isEditing: false
                                        property bool isDragging: false

                                        readonly property bool isLongText: fullTextMeasure.lineCount > 1
                                        readonly property real collapsedHeight: 48
                                        readonly property real maxAllowedHeight: collapsedHeight * 4
                                        readonly property real fullContentHeight: Math.max(collapsedHeight, fullTextMeasure.contentHeight + 24)

                                        height: isEditing ? Math.min(Math.max(collapsedHeight, inlineEditInput.contentHeight + 24), maxAllowedHeight)
                                                          : (isExpanded && isLongText ? Math.min(fullContentHeight, maxAllowedHeight) : collapsedHeight)

                                        Behavior on height {
                                            NumberAnimation {
                                                duration: 120
                                                easing.type: Easing.OutCubic
                                            }
                                        }

                                        onYChanged: {
                                            if (isDragging) {
                                                root.updateDragHover(index, delegateRoot.y + taskItemRoot.y + taskItemRoot.height / 2);
                                            }
                                        }

                                        onIsEditingChanged: {
                                            if (!isEditing && root.isEditingTask) {
                                                root.isEditingTask = false;
                                            }
                                        }

                                        function startEdit() {
                                            root.isEditingTask = true;
                                            isEditing = true;
                                            isExpanded = true;
                                            inlineEditInput.text = modelData.text || "";
                                            Qt.callLater(() => inlineEditInput.forceActiveFocus());
                                        }

                                        function saveEdit() {
                                            const newText = inlineEditInput.text ? inlineEditInput.text.trim() : "";
                                            inlineEditInput.focus = false;
                                            if (newText && root.tasksModel) {
                                                root.tasksModel.editTask(modelData.id, newText);
                                            }
                                            isEditing = false;
                                            isExpanded = false;
                                            root.isEditingTask = false;
                                            root.forceActiveFocus();
                                            Qt.callLater(() => root.forceActiveFocus());
                                        }

                                        function cancelEdit() {
                                            inlineEditInput.focus = false;
                                            isEditing = false;
                                            isExpanded = false;
                                            root.isEditingTask = false;
                                            root.forceActiveFocus();
                                            Qt.callLater(() => root.forceActiveFocus());
                                        }

                                        function finishDrag() {
                                            const fromIdx = root.draggedIndex;
                                            const toIdx = root.hoverTargetIndex;
                                            taskItemRoot.y = 0;
                                            root.draggedIndex = -1;
                                            root.hoverTargetIndex = -1;
                                            if (fromIdx >= 0 && toIdx >= 0 && fromIdx !== toIdx && root.tasksModel) {
                                                root.tasksModel.movePendingTask(fromIdx, toIdx);
                                            }
                                        }

                                        // Background click & double click fallback
                                        MouseArea {
                                            anchors.fill: parent
                                            z: -1
                                            cursorShape: Qt.PointingHandCursor
                                            onClicked: {
                                                root.selectedSection = 0;
                                                root.selectedIndex = index;
                                            }
                                            onDoubleClicked: {
                                                root.selectedSection = 0;
                                                root.selectedIndex = index;
                                                taskItemRoot.startEdit();
                                            }
                                        }

                                        RowLayout {
                                            anchors.fill: parent
                                            anchors.leftMargin: Theme.spacingS
                                            anchors.rightMargin: Theme.spacingXS
                                            spacing: Theme.spacingXS

                                            // Drag Handle
                                            Item {
                                                id: dragHandleItem
                                                Layout.preferredWidth: 20
                                                Layout.preferredHeight: 28
                                                Layout.alignment: (taskItemRoot.isExpanded && taskItemRoot.height > taskItemRoot.collapsedHeight) ? Qt.AlignTop : Qt.AlignVCenter
                                                Layout.topMargin: (taskItemRoot.isExpanded && taskItemRoot.height > taskItemRoot.collapsedHeight) ? 10 : 0

                                                DankIcon {
                                                    anchors.centerIn: parent
                                                    name: "drag_indicator"
                                                    size: 18
                                                    color: taskItemRoot.isDragging
                                                           ? Theme.primary
                                                           : (dragHandleArea.containsMouse ? Theme.surfaceText : Theme.outline)
                                                    opacity: (taskItemRoot.isDragging || dragHandleArea.containsMouse) ? 1.0 : 0.45

                                                    Behavior on color { ColorAnimation { duration: 120 } }
                                                    Behavior on opacity { NumberAnimation { duration: 120 } }
                                                }

                                                MouseArea {
                                                    id: dragHandleArea
                                                    anchors.fill: parent
                                                    anchors.margins: -4
                                                    hoverEnabled: true
                                                    cursorShape: pressed ? Qt.ClosedHandCursor : Qt.OpenHandCursor
                                                    preventStealing: true
                                                    enabled: !taskItemRoot.isEditing

                                                    drag.target: taskItemRoot
                                                    drag.axis: Drag.YAxis
                                                    drag.minimumY: -delegateRoot.y
                                                    drag.maximumY: Math.max(0, pendingColumn.height - delegateRoot.height - delegateRoot.y)

                                                    onPressed: {
                                                        taskItemRoot.isExpanded = false;
                                                        root.draggedIndex = index;
                                                        root.hoverTargetIndex = index;
                                                        root.draggedItemHeight = delegateRoot.height;
                                                        taskItemRoot.isDragging = true;
                                                        taskItemRoot.z = 100;
                                                        delegateRoot.z = 100;
                                                    }

                                                    onReleased: {
                                                        taskItemRoot.isDragging = false;
                                                        taskItemRoot.z = 1;
                                                        delegateRoot.z = 1;
                                                        taskItemRoot.finishDrag();
                                                    }
                                                }
                                            }

                                            // Checkbox toggle
                                            Item {
                                                Layout.preferredWidth: 28
                                                Layout.preferredHeight: 28
                                                Layout.alignment: (taskItemRoot.isExpanded && taskItemRoot.height > taskItemRoot.collapsedHeight) ? Qt.AlignTop : Qt.AlignVCenter
                                                Layout.topMargin: (taskItemRoot.isExpanded && taskItemRoot.height > taskItemRoot.collapsedHeight) ? 10 : 0

                                                MouseArea {
                                                    anchors.fill: parent
                                                    cursorShape: Qt.PointingHandCursor
                                                    onClicked: {
                                                        if (root.tasksModel)
                                                            root.tasksModel.toggleTask(modelData.id);
                                                    }

                                                    DankIcon {
                                                        anchors.centerIn: parent
                                                        name: "check_box_outline_blank"
                                                        size: 22
                                                        color: Theme.outlineMedium
                                                    }
                                                }
                                            }

                                            // Task Text Area
                                            Item {
                                                id: textAreaItem
                                                Layout.fillWidth: true
                                                Layout.fillHeight: true

                                                // Pre-measured text height for instantaneous expansion calculation
                                                StyledText {
                                                    id: fullTextMeasure
                                                    visible: false
                                                    width: Math.max(100, textAreaItem.width)
                                                    text: modelData.text || ""
                                                    font.pixelSize: Theme.fontSizeMedium
                                                    wrapMode: Text.Wrap
                                                }

                                                // Collapsed single-line view (static and vertically centered)
                                                StyledText {
                                                    id: taskDisplayText
                                                    visible: !taskItemRoot.isEditing && (!taskItemRoot.isExpanded || !taskItemRoot.isLongText)
                                                    anchors.left: parent.left
                                                    anchors.right: parent.right
                                                    anchors.verticalCenter: parent.verticalCenter
                                                    text: modelData.text || ""
                                                    font.pixelSize: Theme.fontSizeMedium
                                                    color: Theme.surfaceText
                                                    wrapMode: Text.NoWrap
                                                    maximumLineCount: 1
                                                    elide: Text.ElideRight
                                                }

                                                // Expanded view with text wrapping and scrollbar
                                                DankFlickable {
                                                    id: textFlickable
                                                    visible: !taskItemRoot.isEditing && taskItemRoot.isExpanded && taskItemRoot.isLongText
                                                    anchors.fill: parent
                                                    anchors.topMargin: 14
                                                    anchors.bottomMargin: 14
                                                    clip: true
                                                    contentWidth: width
                                                    contentHeight: expandedDisplayText.contentHeight

                                                    StyledText {
                                                        id: expandedDisplayText
                                                        width: textFlickable.width - (itemScrollbar.visible ? 12 : 0)
                                                        text: modelData.text || ""
                                                        font.pixelSize: Theme.fontSizeMedium
                                                        color: Theme.surfaceText
                                                        wrapMode: Text.Wrap
                                                    }

                                                    DankScrollbar {
                                                        id: itemScrollbar
                                                        targetFlickable: textFlickable
                                                        anchors.right: parent.right
                                                        anchors.top: parent.top
                                                        anchors.bottom: parent.bottom
                                                    }
                                                }

                                                // Inline edit input view
                                                DankFlickable {
                                                    id: editFlickable
                                                    visible: taskItemRoot.isEditing
                                                    anchors.fill: parent
                                                    anchors.topMargin: 8
                                                    anchors.bottomMargin: 8
                                                    clip: true
                                                    contentWidth: width
                                                    contentHeight: inlineEditInput.contentHeight

                                                    TextEdit {
                                                        id: inlineEditInput
                                                        width: editFlickable.width - (editScrollbar.visible ? 12 : 0)
                                                        y: inlineEditInput.lineCount > 1 ? 0 : Math.max(0, Math.floor((editFlickable.height - contentHeight) / 2))
                                                        font.pixelSize: Theme.fontSizeMedium
                                                        font.family: Theme.fontFamily
                                                        color: Theme.surfaceText
                                                        selectionColor: Theme.primaryContainer
                                                        selectedTextColor: Theme.primary
                                                        wrapMode: TextEdit.Wrap
                                                        selectByMouse: true
                                                        cursorDelegate: DankTextCursor {
                                                            color: inlineEditInput.color
                                                            shown: inlineEditInput.cursorVisible
                                                        }

                                                        onCursorRectangleChanged: {
                                                            if (cursorRectangle.y < editFlickable.contentY) {
                                                                editFlickable.contentY = cursorRectangle.y;
                                                            } else if (cursorRectangle.y + cursorRectangle.height > editFlickable.contentY + editFlickable.height) {
                                                                editFlickable.contentY = cursorRectangle.y + cursorRectangle.height - editFlickable.height;
                                                            }
                                                        }

                                                        Keys.onReturnPressed: function(event) {
                                                            if (event.modifiers & Qt.ShiftModifier) {
                                                                event.accepted = false;
                                                            } else {
                                                                event.accepted = true;
                                                                taskItemRoot.saveEdit();
                                                            }
                                                        }
                                                        Keys.onEnterPressed: function(event) {
                                                            if (event.modifiers & Qt.ShiftModifier) {
                                                                event.accepted = false;
                                                            } else {
                                                                event.accepted = true;
                                                                taskItemRoot.saveEdit();
                                                            }
                                                        }
                                                        Keys.onEscapePressed: function(event) {
                                                            event.accepted = true;
                                                            taskItemRoot.cancelEdit();
                                                        }
                                                    }

                                                    DankScrollbar {
                                                        id: editScrollbar
                                                        targetFlickable: editFlickable
                                                        anchors.right: parent.right
                                                        anchors.top: parent.top
                                                        anchors.bottom: parent.bottom
                                                    }
                                                }

                                                // Click to expand / collapse, double click to edit
                                                MouseArea {
                                                    anchors.fill: parent
                                                    anchors.rightMargin: (taskItemRoot.isExpanded && itemScrollbar.visible) ? 14 : 0
                                                    visible: !taskItemRoot.isEditing
                                                    cursorShape: Qt.PointingHandCursor
                                                    onClicked: {
                                                        root.selectedSection = 0;
                                                        root.selectedIndex = index;
                                                        if (taskItemRoot.isLongText) {
                                                            taskItemRoot.isExpanded = !taskItemRoot.isExpanded;
                                                        }
                                                    }
                                                    onDoubleClicked: {
                                                        root.selectedSection = 0;
                                                        root.selectedIndex = index;
                                                        taskItemRoot.startEdit();
                                                    }
                                                }
                                            }

                                            // Action Buttons Row (right)
                                            Row {
                                                Layout.alignment: (taskItemRoot.isExpanded && taskItemRoot.height > taskItemRoot.collapsedHeight) ? Qt.AlignTop : Qt.AlignVCenter
                                                Layout.topMargin: (taskItemRoot.isExpanded && taskItemRoot.height > taskItemRoot.collapsedHeight) ? 10 : 0
                                                spacing: Theme.spacingXXS

                                                // Edit / Save Button
                                                DankActionButton {
                                                    circular: false
                                                    iconName: taskItemRoot.isEditing ? "check" : "edit"
                                                    iconSize: Theme.iconSize - 6
                                                    iconColor: taskItemRoot.isEditing ? Theme.primary : Theme.surfaceVariantText
                                                    tooltipText: taskItemRoot.isEditing ? I18n.tr("Save (Enter)") : I18n.tr("Edit task")
                                                    onClicked: {
                                                        root.selectedSection = 0;
                                                        root.selectedIndex = index;
                                                        if (taskItemRoot.isEditing) {
                                                            taskItemRoot.saveEdit();
                                                        } else {
                                                            taskItemRoot.startEdit();
                                                        }
                                                    }
                                                }

                                                // Cancel Edit Button
                                                DankActionButton {
                                                    visible: taskItemRoot.isEditing
                                                    circular: false
                                                    iconName: "close"
                                                    iconSize: Theme.iconSize - 6
                                                    iconColor: Theme.surfaceVariantText
                                                    tooltipText: I18n.tr("Cancel edit (Esc)")
                                                    onClicked: taskItemRoot.cancelEdit()
                                                }

                                                // Delete Task Button
                                                DankActionButton {
                                                    visible: !taskItemRoot.isEditing
                                                    circular: false
                                                    iconName: "close"
                                                    iconSize: Theme.iconSize - 6
                                                    iconColor: Theme.surfaceVariantText
                                                    tooltipText: I18n.tr("Delete task")
                                                    onClicked: {
                                                        if (root.tasksModel)
                                                            root.tasksModel.removeTask(modelData.id);
                                                    }
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                }

                DankScrollbar {
                    id: tasksScrollbar
                    targetFlickable: tasksFlickable
                    anchors.right: parent.right
                    anchors.top: parent.top
                    anchors.bottom: parent.bottom
                }
            }
        }

        // Dedicated Completed Tasks Section pinned at the bottom of the panel
        Item {
            id: completedSectionContainer
            Layout.fillWidth: true
            visible: root.completedTasks.length > 0

            property bool sectionExpanded: true
            readonly property real maxCompletedHeight: root.pendingTasks.length === 0
                ? Math.max(120, root.height - 180)
                : Math.min(Math.floor(root.height * 0.45), 280)

            Layout.preferredHeight: {
                if (!visible) return 0;
                if (!sectionExpanded) return 32;
                return Math.min(maxCompletedHeight, completedHeader.height + Theme.spacingXS + completedColumn.implicitHeight);
            }

            ColumnLayout {
                anchors.fill: parent
                spacing: Theme.spacingXS

                // Section Header: [collapse/expand] [check] Completed (N) ─── [clear]
                Item {
                    id: completedHeader
                    Layout.fillWidth: true
                    Layout.preferredHeight: 32

                    MouseArea {
                        anchors.fill: parent
                        z: 0
                        onClicked: {
                            root.selectedIndex = -1;
                        }
                    }

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: Theme.spacingXS
                        anchors.rightMargin: Theme.spacingXS
                        spacing: Theme.spacingS

                        DankActionButton {
                            circular: false
                            iconName: completedSectionContainer.sectionExpanded ? "keyboard_arrow_down" : "keyboard_arrow_right"
                            iconSize: Theme.iconSizeSmall
                            iconColor: Theme.surfaceVariantText
                            tooltipText: completedSectionContainer.sectionExpanded ? I18n.tr("Collapse completed tasks") : I18n.tr("Expand completed tasks")
                            onClicked: completedSectionContainer.sectionExpanded = !completedSectionContainer.sectionExpanded
                        }

                        DankIcon {
                            name: "check_circle"
                            size: 16
                            color: Theme.primary
                            opacity: 0.8
                        }

                        StyledText {
                            text: I18n.tr("Completed (%1)").arg(root.completedTasks.length)
                            font.pixelSize: Theme.fontSizeSmall
                            font.weight: Font.DemiBold
                            color: Theme.surfaceVariantText
                        }

                        Rectangle {
                            Layout.fillWidth: true
                            height: 1
                            color: Theme.outlineMedium
                            opacity: 0.25
                        }

                        DankActionButton {
                            circular: false
                            iconName: "delete_sweep"
                            iconSize: Theme.iconSizeSmall - 2
                            iconColor: Theme.surfaceVariantText
                            tooltipText: I18n.tr("Clear completed")
                            onClicked: {
                                if (root.tasksModel)
                                    root.tasksModel.clearCompleted();
                            }
                        }
                    }
                }

                // Completed tasks list (scrollable if exceeding max height)
                Item {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    visible: completedSectionContainer.sectionExpanded
                    clip: true

                    DankFlickable {
                        id: completedFlickable
                        anchors.fill: parent
                        clip: true
                        contentWidth: width
                        contentHeight: completedColumn.implicitHeight

                        // Blank space click handler
                        MouseArea {
                            width: parent.width
                            height: Math.max(completedFlickable.height, completedColumn.implicitHeight)
                            z: 0
                            onClicked: {
                                root.selectedIndex = -1;
                            }
                        }

                        Column {
                            id: completedColumn
                            width: completedFlickable.width - (completedScrollbar.visible ? 12 : 0)
                            spacing: Theme.spacingXS

                            Repeater {
                                id: completedRepeater
                                model: root.completedTasks

                                delegate: Item {
                                    id: completedDelegateRoot
                                    width: completedColumn.width
                                    height: completedCard.height

                                    property alias completedCard: completedCard
                                    readonly property bool isSelected: root.selectedSection === 1 && root.selectedIndex === index && !taskTextEdit.activeFocus

                                    onIsSelectedChanged: {
                                        if (!isSelected) {
                                            completedCard.isExpanded = false;
                                            if (completedCard.isEditing) {
                                                completedCard.saveEdit();
                                            }
                                        }
                                    }

                                    StyledRect {
                                        id: completedCard
                                        width: parent.width
                                        radius: Theme.cornerRadius
                                        clip: true
                                        color: completedDelegateRoot.isSelected ? Theme.withAlpha(Theme.surfaceContainerHighest, root.effectiveOpacity)
                                                                                : (completedCardHoverHandler.hovered
                                                                                    ? Theme.withAlpha(Theme.surfaceContainerHighest, root.effectiveOpacity * 0.55)
                                                                                    : Theme.withAlpha(Theme.surfaceContainerHigh, root.effectiveOpacity * 0.45))
                                        border.color: isEditing ? Theme.primary : (completedDelegateRoot.isSelected ? Theme.primary : "transparent")
                                        border.width: (isEditing || completedDelegateRoot.isSelected) ? 2 : 0

                                        HoverHandler {
                                            id: completedCardHoverHandler
                                        }

                                        Behavior on color {
                                            ColorAnimation { duration: 120 }
                                        }
                                        Behavior on border.color {
                                            ColorAnimation { duration: 120 }
                                        }

                                        property bool isExpanded: false
                                        property bool isEditing: false

                                        readonly property bool isLongText: completedFullTextMeasure.lineCount > 1
                                        readonly property real collapsedHeight: 48
                                        readonly property real maxAllowedHeight: collapsedHeight * 4
                                        readonly property real fullContentHeight: Math.max(collapsedHeight, completedFullTextMeasure.contentHeight + 24)

                                        height: isEditing ? Math.min(Math.max(collapsedHeight, completedInlineEditInput.contentHeight + 24), maxAllowedHeight)
                                                          : (isExpanded && isLongText ? Math.min(fullContentHeight, maxAllowedHeight) : collapsedHeight)

                                        Behavior on height {
                                            NumberAnimation {
                                                duration: 120
                                                easing.type: Easing.OutCubic
                                            }
                                        }

                                        onIsEditingChanged: {
                                            if (!isEditing && root.isEditingTask) {
                                                root.isEditingTask = false;
                                            }
                                        }

                                        function startEdit() {
                                            root.isEditingTask = true;
                                            isEditing = true;
                                            isExpanded = true;
                                            completedInlineEditInput.text = modelData.text || "";
                                            Qt.callLater(() => completedInlineEditInput.forceActiveFocus());
                                        }

                                        function saveEdit() {
                                            const newText = completedInlineEditInput.text ? completedInlineEditInput.text.trim() : "";
                                            completedInlineEditInput.focus = false;
                                            if (newText && root.tasksModel) {
                                                root.tasksModel.editTask(modelData.id, newText);
                                            }
                                            isEditing = false;
                                            isExpanded = false;
                                            root.isEditingTask = false;
                                            root.forceActiveFocus();
                                            Qt.callLater(() => root.forceActiveFocus());
                                        }

                                        function cancelEdit() {
                                            completedInlineEditInput.focus = false;
                                            isEditing = false;
                                            isExpanded = false;
                                            root.isEditingTask = false;
                                            root.forceActiveFocus();
                                            Qt.callLater(() => root.forceActiveFocus());
                                        }

                                        // Background click & double click fallback
                                        MouseArea {
                                            anchors.fill: parent
                                            z: -1
                                            cursorShape: Qt.PointingHandCursor
                                            onClicked: {
                                                root.selectedSection = 1;
                                                root.selectedIndex = index;
                                            }
                                            onDoubleClicked: {
                                                root.selectedSection = 1;
                                                root.selectedIndex = index;
                                                completedCard.startEdit();
                                            }
                                        }

                                        RowLayout {
                                            anchors.fill: parent
                                            anchors.leftMargin: Theme.spacingS
                                            anchors.rightMargin: Theme.spacingXS
                                            spacing: Theme.spacingXS

                                            // Checkbox toggle
                                            Item {
                                                Layout.preferredWidth: 28
                                                Layout.preferredHeight: 28
                                                Layout.alignment: (completedCard.isExpanded && completedCard.height > completedCard.collapsedHeight) ? Qt.AlignTop : Qt.AlignVCenter
                                                Layout.topMargin: (completedCard.isExpanded && completedCard.height > completedCard.collapsedHeight) ? 10 : 0

                                                MouseArea {
                                                    anchors.fill: parent
                                                    cursorShape: Qt.PointingHandCursor
                                                    onClicked: {
                                                        if (root.tasksModel)
                                                            root.tasksModel.toggleTask(modelData.id);
                                                    }

                                                    DankIcon {
                                                        anchors.centerIn: parent
                                                        name: "check_box"
                                                        size: 22
                                                        color: Theme.primary
                                                    }
                                                }
                                            }

                                            // Task Text Area
                                            Item {
                                                id: completedTextAreaItem
                                                Layout.fillWidth: true
                                                Layout.fillHeight: true

                                                // Pre-measured text height for instantaneous expansion calculation
                                                StyledText {
                                                    id: completedFullTextMeasure
                                                    visible: false
                                                    width: Math.max(100, completedTextAreaItem.width)
                                                    text: modelData.text || ""
                                                    font.pixelSize: Theme.fontSizeMedium
                                                    wrapMode: Text.Wrap
                                                }

                                                // Collapsed single-line view (static and vertically centered)
                                                StyledText {
                                                    id: completedDisplayText
                                                    visible: !completedCard.isEditing && (!completedCard.isExpanded || !completedCard.isLongText)
                                                    anchors.left: parent.left
                                                    anchors.right: parent.right
                                                    anchors.verticalCenter: parent.verticalCenter
                                                    text: modelData.text || ""
                                                    font.pixelSize: Theme.fontSizeMedium
                                                    font.strikeout: true
                                                    color: Theme.surfaceVariantText
                                                    opacity: 0.6
                                                    wrapMode: Text.NoWrap
                                                    maximumLineCount: 1
                                                    elide: Text.ElideRight
                                                }

                                                // Expanded view with text wrapping and scrollbar
                                                DankFlickable {
                                                    id: completedTextFlickable
                                                    visible: !completedCard.isEditing && completedCard.isExpanded && completedCard.isLongText
                                                    anchors.fill: parent
                                                    anchors.topMargin: 14
                                                    anchors.bottomMargin: 14
                                                    clip: true
                                                    contentWidth: width
                                                    contentHeight: completedExpandedDisplayText.contentHeight

                                                    StyledText {
                                                        id: completedExpandedDisplayText
                                                        width: completedTextFlickable.width - (completedItemScrollbar.visible ? 12 : 0)
                                                        text: modelData.text || ""
                                                        font.pixelSize: Theme.fontSizeMedium
                                                        font.strikeout: true
                                                        color: Theme.surfaceVariantText
                                                        opacity: 0.6
                                                        wrapMode: Text.Wrap
                                                    }

                                                    DankScrollbar {
                                                        id: completedItemScrollbar
                                                        targetFlickable: completedTextFlickable
                                                        anchors.right: parent.right
                                                        anchors.top: parent.top
                                                        anchors.bottom: parent.bottom
                                                    }
                                                }

                                                // Inline edit input view
                                                DankFlickable {
                                                    id: completedEditFlickable
                                                    visible: completedCard.isEditing
                                                    anchors.fill: parent
                                                    anchors.topMargin: 8
                                                    anchors.bottomMargin: 8
                                                    clip: true
                                                    contentWidth: width
                                                    contentHeight: completedInlineEditInput.contentHeight

                                                    TextEdit {
                                                        id: completedInlineEditInput
                                                        width: completedEditFlickable.width - (completedEditScrollbar.visible ? 12 : 0)
                                                        y: completedInlineEditInput.lineCount > 1 ? 0 : Math.max(0, Math.floor((completedEditFlickable.height - contentHeight) / 2))
                                                        font.pixelSize: Theme.fontSizeMedium
                                                        font.family: Theme.fontFamily
                                                        color: Theme.surfaceText
                                                        selectionColor: Theme.primaryContainer
                                                        selectedTextColor: Theme.primary
                                                        wrapMode: TextEdit.Wrap
                                                        selectByMouse: true
                                                        cursorDelegate: DankTextCursor {
                                                            color: completedInlineEditInput.color
                                                            shown: completedInlineEditInput.cursorVisible
                                                        }

                                                        onCursorRectangleChanged: {
                                                            if (cursorRectangle.y < completedEditFlickable.contentY) {
                                                                completedEditFlickable.contentY = cursorRectangle.y;
                                                            } else if (cursorRectangle.y + cursorRectangle.height > completedEditFlickable.contentY + completedEditFlickable.height) {
                                                                completedEditFlickable.contentY = cursorRectangle.y + cursorRectangle.height - completedEditFlickable.height;
                                                            }
                                                        }

                                                        Keys.onReturnPressed: function(event) {
                                                            if (event.modifiers & Qt.ShiftModifier) {
                                                                event.accepted = false;
                                                            } else {
                                                                event.accepted = true;
                                                                completedCard.saveEdit();
                                                            }
                                                        }
                                                        Keys.onEnterPressed: function(event) {
                                                            if (event.modifiers & Qt.ShiftModifier) {
                                                                event.accepted = false;
                                                            } else {
                                                                event.accepted = true;
                                                                completedCard.saveEdit();
                                                            }
                                                        }
                                                        Keys.onEscapePressed: function(event) {
                                                            event.accepted = true;
                                                            completedCard.cancelEdit();
                                                        }
                                                    }

                                                    DankScrollbar {
                                                        id: completedEditScrollbar
                                                        targetFlickable: completedEditFlickable
                                                        anchors.right: parent.right
                                                        anchors.top: parent.top
                                                        anchors.bottom: parent.bottom
                                                    }
                                                }

                                                // Click to expand / collapse, double click to edit
                                                MouseArea {
                                                    anchors.fill: parent
                                                    anchors.rightMargin: (completedCard.isExpanded && completedItemScrollbar.visible) ? 14 : 0
                                                    visible: !completedCard.isEditing
                                                    cursorShape: Qt.PointingHandCursor
                                                    onClicked: {
                                                        root.selectedSection = 1;
                                                        root.selectedIndex = index;
                                                        if (completedCard.isLongText) {
                                                            completedCard.isExpanded = !completedCard.isExpanded;
                                                        }
                                                    }
                                                    onDoubleClicked: {
                                                        root.selectedSection = 1;
                                                        root.selectedIndex = index;
                                                        completedCard.startEdit();
                                                    }
                                                }
                                            }

                                            // Action Buttons Row (right)
                                            Row {
                                                Layout.alignment: (completedCard.isExpanded && completedCard.height > completedCard.collapsedHeight) ? Qt.AlignTop : Qt.AlignVCenter
                                                Layout.topMargin: (completedCard.isExpanded && completedCard.height > completedCard.collapsedHeight) ? 10 : 0
                                                spacing: Theme.spacingXXS

                                                // Edit / Save Button
                                                DankActionButton {
                                                    circular: false
                                                    iconName: completedCard.isEditing ? "check" : "edit"
                                                    iconSize: Theme.iconSize - 6
                                                    iconColor: completedCard.isEditing ? Theme.primary : Theme.surfaceVariantText
                                                    tooltipText: completedCard.isEditing ? I18n.tr("Save (Enter)") : I18n.tr("Edit task")
                                                    onClicked: {
                                                        root.selectedSection = 1;
                                                        root.selectedIndex = index;
                                                        if (completedCard.isEditing) {
                                                            completedCard.saveEdit();
                                                        } else {
                                                            completedCard.startEdit();
                                                        }
                                                    }
                                                }

                                                // Cancel Edit Button
                                                DankActionButton {
                                                    visible: completedCard.isEditing
                                                    circular: false
                                                    iconName: "close"
                                                    iconSize: Theme.iconSize - 6
                                                    iconColor: Theme.surfaceVariantText
                                                    tooltipText: I18n.tr("Cancel edit (Esc)")
                                                    onClicked: completedCard.cancelEdit()
                                                }

                                                // Delete Task Button
                                                DankActionButton {
                                                    visible: !completedCard.isEditing
                                                    circular: false
                                                    iconName: "close"
                                                    iconSize: Theme.iconSize - 6
                                                    iconColor: Theme.surfaceVariantText
                                                    tooltipText: I18n.tr("Delete task")
                                                    onClicked: {
                                                        if (root.tasksModel)
                                                            root.tasksModel.removeTask(modelData.id);
                                                    }
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                        }

                        DankScrollbar {
                            id: completedScrollbar
                            targetFlickable: completedFlickable
                            anchors.right: parent.right
                            anchors.top: parent.top
                            anchors.bottom: parent.bottom
                        }
                    }
                }
            }
        }

        // Bottom Footer Bar: Settings and Popout / Dock at bottom right
        Item {
            id: bottomBar
            Layout.fillWidth: true
            Layout.preferredHeight: 32

            MouseArea {
                anchors.fill: parent
                z: 0
                onClicked: {
                    root.selectedIndex = -1;
                }
            }

            Row {
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                spacing: Theme.spacingXS

                // Settings Button
                DankActionButton {
                    circular: false
                    iconName: "settings"
                    iconSize: Theme.iconSize - 4
                    iconColor: root.showSettingsMenu ? Theme.primary : Theme.surfaceText
                    tooltipText: I18n.tr("Tasks Settings")
                    onClicked: root.showSettingsMenu = !root.showSettingsMenu
                }

                // Popout / Dock Button
                DankActionButton {
                    circular: false
                    iconName: root.inPopout ? "dock_to_right" : "open_in_new"
                    iconSize: Theme.iconSize - 4
                    iconColor: Theme.surfaceText
                    tooltipText: root.inPopout ? I18n.tr("Dock to slideout") : I18n.tr("Popout window")
                    onClicked: {
                        if (root.inPopout) {
                            root.dockRequested();
                        } else {
                            root.popoutRequested();
                        }
                    }
                }
            }
        }
    }

    // Settings overlay modal
    TasksSettings {
        id: settingsOverlay
        anchors.fill: parent
        isVisible: root.showSettingsMenu
        tasksModel: root.tasksModel
        onSettingsRequested: root.showSettingsMenu = !root.showSettingsMenu
    }
}
