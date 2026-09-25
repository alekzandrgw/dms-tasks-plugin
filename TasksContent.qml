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
        const textVal = taskInput.text ? taskInput.text.trim() : "";
        if (!textVal)
            return;
        if (root.tasksModel) {
            root.tasksModel.addTask(textVal);
            taskInput.text = "";
            taskInput.forceActiveFocus();
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
            taskInput.forceActiveFocus();
        }
    }

    Item {
        id: taskKeyHandler
        Keys.onReturnPressed: root.submitNewTask()
        Keys.onEnterPressed: root.submitNewTask()
    }

    ColumnLayout {
        anchors.fill: parent
        spacing: Theme.spacingM

        // Single Top Title Bar: [icon] Tasks  ...  [x]
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
                    visible: (root.tasksModel?.totalPending ?? 0) > 0
                    width: Math.max(20, countText.implicitWidth + Theme.spacingS * 2)
                    height: 20
                    radius: 10
                    color: Theme.primary
                    anchors.verticalCenter: parent.verticalCenter

                    StyledText {
                        id: countText
                        anchors.centerIn: parent
                        text: (root.tasksModel?.totalPending ?? 0).toString()
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
                    visible: (root.tasksModel?.totalCompleted ?? 0) > 0
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

        // Quick Add Input Row (icon: plus, adds task and jumps to new entry on Enter)
        DankTextField {
            id: taskInput
            Layout.fillWidth: true
            placeholderText: I18n.tr("Add a task... (Press Enter)")
            leftIconName: "add"
            showClearButton: true
            keyForwardTargets: [taskKeyHandler]

            onAccepted: root.submitNewTask()
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

                delegate: StyledRect {
                    id: taskItemRoot
                    width: taskListView.width
                    height: 48
                    radius: Theme.cornerRadiusSmall
                    color: modelData.done ? Theme.withAlpha(Theme.surfaceContainerHigh, 0.4) : Theme.surfaceContainerHigh

                    Row {
                        anchors.left: parent.left
                        anchors.leftMargin: Theme.spacingM
                        anchors.right: removeBtn.left
                        anchors.rightMargin: Theme.spacingS
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: Theme.spacingM

                        // Checkbox toggle (changes from plus mark to checkbox to mark tasks as completed)
                        MouseArea {
                            width: 28
                            height: 28
                            anchors.verticalCenter: parent.verticalCenter
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

                        // Task Text
                        StyledText {
                            width: parent.width - 36
                            text: modelData.text || ""
                            font.pixelSize: Theme.fontSizeMedium
                            font.strikeout: modelData.done
                            color: modelData.done ? Theme.surfaceVariantText : Theme.surfaceText
                            opacity: modelData.done ? 0.6 : 1.0
                            elide: Text.ElideRight
                            anchors.verticalCenter: parent.verticalCenter
                        }
                    }

                    // Remove Task Button
                    DankActionButton {
                        id: removeBtn
                        anchors.right: parent.right
                        anchors.rightMargin: Theme.spacingXS
                        anchors.verticalCenter: parent.verticalCenter
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
