import QtQuick
import QtQuick.Layouts
import qs.Common
import qs.Widgets

FocusScope {
    id: root

    property var slideout: null
    property var tasksModel: null

    property bool showSettingsMenu: false
    property bool showSearchBar: false
    property string searchQuery: ""

    readonly property var allTasks: (root.tasksModel && root.tasksModel.tasks) ? root.tasksModel.tasks : []
    readonly property var filteredTasks: {
        if (!root.showSearchBar || !root.searchQuery || !root.searchQuery.trim()) {
            return allTasks;
        }
        var q = root.searchQuery.trim().toLowerCase();
        return allTasks.filter(function(task) {
            return task && task.text && task.text.toLowerCase().indexOf(q) !== -1;
        });
    }

    anchors.fill: parent

    function showSearch() {
        root.showSearchBar = true;
        Qt.callLater(function() {
            searchField.forceActiveFocus();
        });
    }

    function hideSearch() {
        root.showSearchBar = false;
        root.searchQuery = "";
        if (searchField)
            searchField.text = "";
        taskInput.forceActiveFocus();
    }

    Keys.onPressed: function(event) {
        if ((event.modifiers & Qt.ControlModifier) && event.key === Qt.Key_F) {
            event.accepted = true;
            root.showSearch();
        }
    }

    Keys.onEscapePressed: function(event) {
        if (root.showSettingsMenu) {
            root.showSettingsMenu = false;
            event.accepted = true;
            return;
        }
        if (root.showSearchBar) {
            root.hideSearch();
            event.accepted = true;
            return;
        }
        if (slideout) {
            slideout.hide();
            event.accepted = true;
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
        anchors.fill: parent

        ColumnLayout {
            anchors.fill: parent
            spacing: Theme.spacingM

            // Header Row
            Item {
                Layout.fillWidth: true
                Layout.preferredHeight: 40

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

                    // Settings Button
                    DankActionButton {
                        circular: false
                        iconName: "more_horiz"
                        iconSize: Theme.iconSize - 4
                        iconColor: root.showSettingsMenu ? Theme.primary : Theme.surfaceText
                        tooltipText: I18n.tr("Tasks Settings")
                        onClicked: {
                            root.showSettingsMenu = !root.showSettingsMenu;
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
                            if (root.slideout)
                                root.slideout.hide();
                        }
                    }
                }
            }

            // Search Bar Row (toggleable via Find in Text or Ctrl+F)
            RowLayout {
                id: searchBarRow
                visible: root.showSearchBar
                Layout.fillWidth: true
                Layout.preferredHeight: 40
                spacing: Theme.spacingS

                DankTextField {
                    id: searchField
                    Layout.fillWidth: true
                    placeholderText: I18n.tr("Find in tasks...")
                    leftIconName: "search"
                    showClearButton: true
                    text: root.searchQuery
                    onTextChanged: {
                        root.searchQuery = text;
                    }
                    Keys.onEscapePressed: function(event) {
                        root.hideSearch();
                        event.accepted = true;
                    }
                }

                DankActionButton {
                    id: closeSearchBtn
                    Layout.alignment: Qt.AlignVCenter
                    circular: false
                    iconName: "close"
                    iconSize: Theme.iconSize - 4
                    iconColor: Theme.surfaceVariantText
                    tooltipText: I18n.tr("Close search (Esc)")
                    onClicked: root.hideSearch()
                }
            }

            // Quick Add Input Row
            DankTextField {
                id: taskInput
                Layout.fillWidth: true
                placeholderText: I18n.tr("Add a task... (Press Enter)")
                leftIconName: "add"
                showClearButton: true

                onAccepted: {
                    if (text && text.trim() && root.tasksModel) {
                        root.tasksModel.addTask(text);
                        clear();
                    }
                }
            }

            // Task List or Empty State Container
            Item {
                Layout.fillWidth: true
                Layout.fillHeight: true

                // Empty state (all tasks completed or list empty)
                Column {
                    anchors.centerIn: parent
                    visible: root.allTasks.length === 0
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

                // Empty search results state
                Column {
                    anchors.centerIn: parent
                    visible: root.allTasks.length > 0 && root.filteredTasks.length === 0
                    spacing: Theme.spacingM

                    DankIcon {
                        anchors.horizontalCenter: parent.horizontalCenter
                        name: "search_off"
                        size: 48
                        color: Theme.outlineMedium
                    }

                    StyledText {
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: I18n.tr("No matching tasks found")
                        font.pixelSize: Theme.fontSizeMedium
                        color: Theme.surfaceVariantText
                    }
                }

                // List View
                DankListView {
                    id: taskListView
                    anchors.fill: parent
                    visible: root.filteredTasks.length > 0
                    model: root.filteredTasks
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

                            // Checkbox toggle
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
                                    name: modelData.done ? "check_circle" : "radio_button_unchecked"
                                    size: 22
                                    color: modelData.done ? Theme.primary : Theme.outlineMedium
                                }
                            }

                            // Task Text
                            StyledText {
                                width: parent.width - 36
                                text: modelData.text || ""
                                font.family: tasksSettings.useMonospace ? SettingsData.monoFontFamily : SettingsData.fontFamily
                                font.pixelSize: tasksSettings.fontSize
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

    // Settings overlay
    TasksSettings {
        id: tasksSettings
        anchors.fill: parent
        anchors.margins: -Theme.spacingL
        z: 100
        isVisible: root.showSettingsMenu
        onSettingsRequested: root.showSettingsMenu = !root.showSettingsMenu
        onFindRequested: {
            root.showSettingsMenu = false;
            root.showSearch();
        }
    }
}
