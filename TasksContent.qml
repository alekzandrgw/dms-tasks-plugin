import QtQuick
import QtQuick.Layouts
import qs.Common
import qs.Widgets

FocusScope {
    id: root

    property var slideout: null
    property var tasksModel: null

    readonly property var pendingTasks: (root.tasksModel && root.tasksModel.pendingTasks) ? root.tasksModel.pendingTasks : []
    readonly property var completedTasks: (root.tasksModel && root.tasksModel.completedTasks) ? root.tasksModel.completedTasks : []
    readonly property int totalCount: (root.tasksModel && root.tasksModel.tasks) ? root.tasksModel.tasks.length : 0

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

    Keys.onEscapePressed: {
        if (draggedIndex >= 0) {
            draggedIndex = -1;
            hoverTargetIndex = -1;
            return;
        }
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
                                            // Dragging DOWN: items between (draggedIndex, hoverTargetIndex] shift UP
                                            if (index > root.draggedIndex && index <= root.hoverTargetIndex) {
                                                return -slotStep;
                                            }
                                        } else if (root.draggedIndex > root.hoverTargetIndex) {
                                            // Dragging UP: items between [hoverTargetIndex, draggedIndex) shift DOWN
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
                                        radius: Theme.cornerRadiusSmall
                                        clip: true
                                        color: isDragging ? Theme.surfaceContainerHighest : Theme.surfaceContainerHigh
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

                                        onYChanged: {
                                            if (isDragging) {
                                                root.updateDragHover(index, delegateRoot.y + taskItemRoot.y + taskItemRoot.height / 2);
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
                                            const fromIdx = root.draggedIndex;
                                            const toIdx = root.hoverTargetIndex;
                                            taskItemRoot.y = 0;
                                            root.draggedIndex = -1;
                                            root.hoverTargetIndex = -1;
                                            if (fromIdx >= 0 && toIdx >= 0 && fromIdx !== toIdx && root.tasksModel) {
                                                root.tasksModel.movePendingTask(fromIdx, toIdx);
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
                                                    color: Theme.surfaceText
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

            Behavior on Layout.preferredHeight {
                NumberAnimation {
                    duration: 160
                    easing.type: Easing.OutQuad
                }
            }

            ColumnLayout {
                anchors.fill: parent
                spacing: Theme.spacingXS

                // Section Header: [collapse/expand] [check] Completed (N) ─── [clear]
                Item {
                    id: completedHeader
                    Layout.fillWidth: true
                    Layout.preferredHeight: 32

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

                                    StyledRect {
                                        id: completedCard
                                        width: parent.width
                                        radius: Theme.cornerRadiusSmall
                                        clip: true
                                        color: Theme.withAlpha(Theme.surfaceContainerHigh, 0.4)
                                        border.color: isEditing ? Theme.primary : "transparent"
                                        border.width: isEditing ? 1 : 0

                                        property bool isExpanded: false
                                        property bool isEditing: false

                                        readonly property real collapsedHeight: 48
                                        readonly property real maxAllowedHeight: collapsedHeight * 4
                                        readonly property real fullContentHeight: Math.max(collapsedHeight, completedFullTextMeasure.contentHeight + 24)

                                        height: isEditing ? Math.min(Math.max(collapsedHeight, completedInlineEditInput.contentHeight + 24), maxAllowedHeight)
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
                                            completedInlineEditInput.text = modelData.text || "";
                                            Qt.callLater(() => completedInlineEditInput.forceActiveFocus());
                                        }

                                        function saveEdit() {
                                            const newText = completedInlineEditInput.text ? completedInlineEditInput.text.trim() : "";
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

                                        RowLayout {
                                            anchors.fill: parent
                                            anchors.leftMargin: Theme.spacingS
                                            anchors.rightMargin: Theme.spacingXS
                                            spacing: Theme.spacingXS

                                            // NO drag handle! (Completed tasks cannot be arranged)

                                            // Checkbox toggle (clicking unchecks and moves back to pending)
                                            Item {
                                                Layout.preferredWidth: 28
                                                Layout.preferredHeight: 28
                                                Layout.alignment: completedCard.isExpanded ? Qt.AlignTop : Qt.AlignVCenter
                                                Layout.topMargin: completedCard.isExpanded ? 10 : 0

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

                                                // Invisible text for calculating accurate expanded height
                                                StyledText {
                                                    id: completedFullTextMeasure
                                                    visible: false
                                                    width: Math.max(100, completedTextAreaItem.width)
                                                    text: modelData.text || ""
                                                    font.pixelSize: Theme.fontSizeMedium
                                                    wrapMode: Text.Wrap
                                                }

                                                // Collapsed single-line view (strikeout, muted)
                                                StyledText {
                                                    id: completedDisplayText
                                                    visible: !completedCard.isEditing && !completedCard.isExpanded
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

                                                // Expanded view with text wrapping and scrollbar if exceeding 4x cap
                                                DankFlickable {
                                                    id: completedTextFlickable
                                                    visible: !completedCard.isEditing && completedCard.isExpanded
                                                    anchors.fill: parent
                                                    anchors.topMargin: 12
                                                    anchors.bottomMargin: 12
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

                                                // Click to expand / collapse
                                                MouseArea {
                                                    anchors.fill: parent
                                                    anchors.rightMargin: (completedCard.isExpanded && completedItemScrollbar.visible) ? 14 : 0
                                                    visible: !completedCard.isEditing
                                                    cursorShape: Qt.PointingHandCursor
                                                    onClicked: completedCard.isExpanded = !completedCard.isExpanded
                                                }
                                            }

                                            // Action Buttons Row (right)
                                            Row {
                                                Layout.alignment: completedCard.isExpanded ? Qt.AlignTop : Qt.AlignVCenter
                                                Layout.topMargin: completedCard.isExpanded ? 6 : 0
                                                spacing: Theme.spacingXXS

                                                // Edit / Save Button
                                                DankActionButton {
                                                    circular: false
                                                    iconName: completedCard.isEditing ? "check" : "edit"
                                                    iconSize: Theme.iconSize - 6
                                                    iconColor: completedCard.isEditing ? Theme.primary : Theme.surfaceVariantText
                                                    tooltipText: completedCard.isEditing ? I18n.tr("Save (Enter)") : I18n.tr("Edit task")
                                                    onClicked: {
                                                        if (completedCard.isEditing) {
                                                            completedCard.saveEdit();
                                                        } else {
                                                            completedCard.startEdit();
                                                        }
                                                    }
                                                }

                                                // Cancel Edit Button (when editing)
                                                DankActionButton {
                                                    visible: completedCard.isEditing
                                                    circular: false
                                                    iconName: "close"
                                                    iconSize: Theme.iconSize - 6
                                                    iconColor: Theme.surfaceVariantText
                                                    tooltipText: I18n.tr("Cancel edit (Esc)")
                                                    onClicked: completedCard.cancelEdit()
                                                }

                                                // Delete Task Button (when not editing)
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
    }
}
