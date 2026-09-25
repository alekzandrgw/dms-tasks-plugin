import QtQuick
import QtQuick.Layouts
import qs.Common
import qs.Widgets

FocusScope {
    id: root

    property var slideout: null
    property var tasksModel: null

    readonly property var taskList: (root.tasksModel && root.tasksModel.tasks) ? root.tasksModel.tasks.slice(0) : []

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

    Keys.onEscapePressed: {
        if (slideout) {
            slideout.hide();
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

    ColumnLayout {
        anchors.fill: parent
        spacing: Theme.spacingM

        // Single Top Title Bar: [icon] Tasks  ...  [expand] [close]
        Item {
            Layout.fillWidth: true
            Layout.preferredHeight: 32

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

                // Expand / Collapse Button (matches Notepad)
                DankActionButton {
                    id: expandButton
                    visible: Boolean(root.slideout && root.slideout.expandable)
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

                // Single Close Button
                DankActionButton {
                    circular: false
                    iconName: "close"
                    iconSize: Theme.iconSize - 4
                    iconColor: Theme.surfaceText
                    tooltipText: I18n.tr("Close (Esc)")
                    onClicked: {
                        if (root.slideout)
                            root.slideout.hide();
                    }
                }
            }
        }

        // Auto-expanding Quick Add Input Box (default 40px, auto-expands up to 4x = 160px with scrollbar)
        StyledRect {
            id: taskInputContainer
            Layout.fillWidth: true
            Layout.preferredHeight: Math.min(160, Math.max(40, taskTextEdit.contentHeight + 16))
            radius: Theme.cornerRadius
            color: Theme.surfaceVariantAlpha
            border.color: taskTextEdit.activeFocus ? Theme.primary : Theme.outlineMedium
            border.width: taskTextEdit.activeFocus ? 2 : 1

            Behavior on Layout.preferredHeight {
                NumberAnimation {
                    duration: 120
                    easing.type: Easing.OutQuad
                }
            }

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

        // Task List or Empty State
        Item {
            Layout.fillWidth: true
            Layout.fillHeight: true

            // Empty state
            Column {
                anchors.centerIn: parent
                visible: root.taskList.length === 0
                spacing: Theme.spacingM

                DankIcon {
                    anchors.horizontalCenter: parent.horizontalCenter
                    name: "task_alt"
                    size: 48
                    color: Theme.outlineMedium
                }

                StyledText {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: I18n.tr("All tasks complete!")
                    font.pixelSize: Theme.fontSizeMedium
                    color: Theme.surfaceVariantText
                }
            }

            // List View
            DankListView {
                id: taskListView
                anchors.fill: parent
                visible: root.taskList.length > 0
                model: root.taskList
                spacing: Theme.spacingXS
                clip: true

                delegate: Item {
                    id: delegateRoot
                    width: taskListView.width
                    height: taskItemRoot.height

                    StyledRect {
                        id: taskItemRoot
                        width: parent.width
                        radius: Theme.cornerRadiusSmall
                        clip: true
                        color: isDragging ? Theme.surfaceContainerHighest : (modelData.done ? Theme.withAlpha(Theme.surfaceContainerHigh, 0.4) : Theme.surfaceContainerHigh)
                        border.color: isDragging ? Theme.primary : (isEditing ? Theme.primary : "transparent")
                        border.width: isDragging ? 2 : (isEditing ? 1 : 0)
                        scale: isDragging ? 1.02 : 1.0
                        z: isDragging ? 100 : 1

                        Behavior on scale {
                            NumberAnimation { duration: 120; easing.type: Easing.OutQuad }
                        }
                        Behavior on color {
                            ColorAnimation { duration: 120 }
                        }
                        Behavior on border.color {
                            ColorAnimation { duration: 120 }
                        }
                        Behavior on y {
                            enabled: !taskItemRoot.isDragging
                            NumberAnimation {
                                duration: 160
                                easing.type: Easing.OutQuad
                            }
                        }

                        property bool isExpanded: false
                        property bool isEditing: false
                        property bool isDragging: false

                        readonly property real collapsedHeight: 48
                        readonly property real maxAllowedHeight: collapsedHeight * 4
                        readonly property real fullContentHeight: Math.max(collapsedHeight, fullTextMeasure.contentHeight + 24)

                        height: isEditing ? Math.min(Math.max(collapsedHeight, inlineEditInput.contentHeight + 24), maxAllowedHeight)
                                          : (isExpanded ? Math.min(fullContentHeight, maxAllowedHeight) : collapsedHeight)

                        Behavior on height {
                            NumberAnimation {
                                duration: 160
                                easing.type: Easing.OutQuad
                            }
                        }

                        function startEdit() {
                            isEditing = true;
                            isExpanded = true;
                            inlineEditInput.text = modelData.text || "";
                            Qt.callLater(() => inlineEditInput.forceActiveFocus());
                        }

                        function saveEdit() {
                            const newText = inlineEditInput.text ? inlineEditInput.text.trim() : "";
                            if (newText && root.tasksModel) {
                                root.tasksModel.editTask(modelData.id, newText);
                            }
                            isEditing = false;
                            isExpanded = false;
                        }

                        function cancelEdit() {
                            isEditing = false;
                            isExpanded = false;
                        }

                        function finishDrag() {
                            if (!root.tasksModel || root.taskList.length <= 1) {
                                taskItemRoot.y = 0;
                                return;
                            }
                            const centerInContent = taskItemRoot.mapToItem(taskListView.contentItem, taskItemRoot.width / 2, taskItemRoot.height / 2);
                            let targetIdx = taskListView.indexAt(centerInContent.x, centerInContent.y);
                            if (targetIdx === -1) {
                                if (centerInContent.y <= 0) {
                                    targetIdx = 0;
                                } else if (centerInContent.y >= taskListView.contentHeight) {
                                    targetIdx = root.taskList.length - 1;
                                } else {
                                    const slotH = taskItemRoot.collapsedHeight + Theme.spacingXS;
                                    targetIdx = Math.max(0, Math.min(Math.floor(centerInContent.y / slotH), root.taskList.length - 1));
                                }
                            }
                            targetIdx = Math.max(0, Math.min(targetIdx, root.taskList.length - 1));
                            const fromIdx = index;
                            taskItemRoot.y = 0;
                            if (targetIdx !== fromIdx) {
                                root.tasksModel.moveTask(fromIdx, targetIdx);
                            }
                        }

                        RowLayout {
                            anchors.fill: parent
                            anchors.leftMargin: Theme.spacingS
                            anchors.rightMargin: Theme.spacingXS
                            spacing: Theme.spacingXS

                            // Drag Handle (left-side of checkbox)
                            Item {
                                id: dragHandleItem
                                Layout.preferredWidth: 20
                                Layout.preferredHeight: 28
                                Layout.alignment: taskItemRoot.isExpanded ? Qt.AlignTop : Qt.AlignVCenter
                                Layout.topMargin: taskItemRoot.isExpanded ? 10 : 0

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

                                    onPressed: {
                                        taskItemRoot.isDragging = true;
                                        taskItemRoot.z = 100;
                                    }

                                    onReleased: {
                                        taskItemRoot.isDragging = false;
                                        taskItemRoot.z = 1;
                                        taskItemRoot.finishDrag();
                                    }
                                }
                            }

                            // Checkbox toggle (left)
                            Item {
                                Layout.preferredWidth: 28
                                Layout.preferredHeight: 28
                                Layout.alignment: taskItemRoot.isExpanded ? Qt.AlignTop : Qt.AlignVCenter
                                Layout.topMargin: taskItemRoot.isExpanded ? 10 : 0

                                MouseArea {
                                    anchors.fill: parent
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: {
                                        if (root.tasksModel)
                                            root.tasksModel.toggleTask(modelData.id);
                                    }

                                    DankIcon {
                                        anchors.centerIn: parent
                                        name: modelData.done ? "check_box" : "check_box_outline_blank"
                                        size: 22
                                        color: modelData.done ? Theme.primary : Theme.outlineMedium
                                    }
                                }
                            }

                            // Task Text Area
                            Item {
                                id: textAreaItem
                                Layout.fillWidth: true
                            Layout.fillHeight: true

                            // Invisible text for calculating accurate expanded height
                            StyledText {
                                id: fullTextMeasure
                                visible: false
                                width: Math.max(100, textAreaItem.width)
                                text: modelData.text || ""
                                font.pixelSize: Theme.fontSizeMedium
                                wrapMode: Text.Wrap
                            }

                            // Collapsed single-line view (strictly centered vertically)
                            StyledText {
                                id: taskDisplayText
                                visible: !taskItemRoot.isEditing && !taskItemRoot.isExpanded
                                anchors.left: parent.left
                                anchors.right: parent.right
                                anchors.verticalCenter: parent.verticalCenter
                                text: modelData.text || ""
                                font.pixelSize: Theme.fontSizeMedium
                                font.strikeout: modelData.done
                                color: modelData.done ? Theme.surfaceVariantText : Theme.surfaceText
                                opacity: modelData.done ? 0.6 : 1.0
                                wrapMode: Text.NoWrap
                                maximumLineCount: 1
                                elide: Text.ElideRight
                            }

                            // Expanded view with text wrapping and scrollbar if exceeding 4x cap
                            DankFlickable {
                                id: textFlickable
                                visible: !taskItemRoot.isEditing && taskItemRoot.isExpanded
                                anchors.fill: parent
                                anchors.topMargin: 12
                                anchors.bottomMargin: 12
                                clip: true
                                contentWidth: width
                                contentHeight: expandedDisplayText.contentHeight

                                StyledText {
                                    id: expandedDisplayText
                                    width: textFlickable.width - (itemScrollbar.visible ? 12 : 0)
                                    text: modelData.text || ""
                                    font.pixelSize: Theme.fontSizeMedium
                                    font.strikeout: modelData.done
                                    color: modelData.done ? Theme.surfaceVariantText : Theme.surfaceText
                                    opacity: modelData.done ? 0.6 : 1.0
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

                        // Click to expand / collapse
                        MouseArea {
                            anchors.fill: parent
                            anchors.rightMargin: (taskItemRoot.isExpanded && itemScrollbar.visible) ? 14 : 0
                            visible: !taskItemRoot.isEditing
                            cursorShape: Qt.PointingHandCursor
                            onClicked: taskItemRoot.isExpanded = !taskItemRoot.isExpanded
                        }
                    }

                    // Action Buttons Row (right)
                    Row {
                        Layout.alignment: taskItemRoot.isExpanded ? Qt.AlignTop : Qt.AlignVCenter
                        Layout.topMargin: taskItemRoot.isExpanded ? 6 : 0
                        spacing: Theme.spacingXXS

                        // Edit / Save Button
                        DankActionButton {
                            circular: false
                            iconName: taskItemRoot.isEditing ? "check" : "edit"
                            iconSize: Theme.iconSize - 6
                            iconColor: taskItemRoot.isEditing ? Theme.primary : Theme.surfaceVariantText
                            tooltipText: taskItemRoot.isEditing ? I18n.tr("Save (Enter)") : I18n.tr("Edit task")
                            onClicked: {
                                if (taskItemRoot.isEditing) {
                                    taskItemRoot.saveEdit();
                                } else {
                                    taskItemRoot.startEdit();
                                }
                            }
                        }

                        // Cancel Edit Button (when editing)
                        DankActionButton {
                            visible: taskItemRoot.isEditing
                            circular: false
                            iconName: "close"
                            iconSize: Theme.iconSize - 6
                            iconColor: Theme.surfaceVariantText
                            tooltipText: I18n.tr("Cancel edit (Esc)")
                            onClicked: taskItemRoot.cancelEdit()
                        }

                        // Delete Task Button (when not editing)
                        DankActionButton {
                            id: removeBtn
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
