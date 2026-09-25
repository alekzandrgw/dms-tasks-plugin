import QtQuick
import QtQuick.Layouts
import qs.Common
import qs.Widgets

Item {
    id: root

    property bool isVisible: false
    property var tasksModel: null
    property bool editingFilePath: false

    signal settingsRequested

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

    readonly property int edgeGap: {
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

    function updateSetting(key, val) {
        if (typeof SettingsData !== "undefined" && SettingsData.setPluginSetting) {
            SettingsData.setPluginSetting("tasks", key, val);
        }
    }

    // Backdrop overlay
    Rectangle {
        anchors.fill: parent
        visible: root.isVisible
        z: 50
        color: Theme.withAlpha(Theme.surface, 0.85)

        WheelHandler {
            onWheel: event => {
                event.accepted = true;
            }
        }

        MouseArea {
            anchors.fill: parent
            onClicked: root.settingsRequested()
        }
    }

    // Modal dialog
    Rectangle {
        id: settingsMenu
        visible: root.isVisible
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.verticalCenter: parent.verticalCenter
        width: Math.min(380, root.width - Theme.spacingL * 2)
        height: Math.min(settingsColumn.implicitHeight + Theme.spacingXL * 2, root.height - Theme.spacingL * 2)
        radius: Theme.cornerRadius
        color: Theme.withAlpha(Theme.surfaceContainer, root.transparencyOverride >= 0 ? root.transparencyOverride : Theme.floatingWindowTransparency)
        border.color: Theme.outlineMedium
        border.width: 1
        z: 100

        Rectangle {
            anchors.fill: parent
            anchors.topMargin: 4
            anchors.leftMargin: 2
            anchors.rightMargin: -2
            anchors.bottomMargin: -4
            radius: parent.radius
            color: Qt.rgba(0, 0, 0, 0.15)
            z: parent.z - 1
        }

        DankFlickable {
            id: settingsFlickable
            anchors.fill: parent
            clip: true
            contentWidth: width
            contentHeight: settingsColumn.implicitHeight + Theme.spacingXL * 2

            Column {
                id: settingsColumn
                x: Theme.spacingXL
                y: Theme.spacingXL
                width: settingsFlickable.width - Theme.spacingXL * 2
                spacing: Theme.spacingS

                // Header
                Item {
                    width: parent.width
                    height: 36

                    Row {
                        anchors.left: parent.left
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: Theme.spacingS

                        DankIcon {
                            name: "settings"
                            size: Theme.iconSize - 2
                            color: Theme.primary
                            anchors.verticalCenter: parent.verticalCenter
                        }

                        StyledText {
                            text: I18n.tr("Tasks Settings")
                            font.pixelSize: Theme.fontSizeMedium
                            font.weight: Font.Medium
                            color: Theme.surfaceText
                            anchors.verticalCenter: parent.verticalCenter
                        }
                    }

                    DankActionButton {
                        anchors.right: parent.right
                        anchors.verticalCenter: parent.verticalCenter
                        circular: false
                        iconName: "close"
                        iconSize: Theme.iconSizeSmall
                        iconColor: Theme.surfaceVariantText
                        tooltipText: I18n.tr("Close Settings (Esc)")
                        onClicked: root.settingsRequested()
                    }
                }

                Rectangle {
                    width: parent.width
                    height: 1
                    color: Theme.outlineHeavy
                }

                // Setting 1: Tasks File Location
                Column {
                    width: parent.width
                    spacing: Theme.spacingXS

                    StyledText {
                        text: I18n.tr("Tasks Storage Location")
                        font.pixelSize: Theme.fontSizeSmall
                        font.weight: Font.Medium
                        color: Theme.surfaceText
                    }

                    StyledText {
                        text: I18n.tr("Location of the tasks JSON database on disk")
                        font.pixelSize: Theme.fontSizeSmall - 2
                        color: Theme.surfaceVariantText
                    }

                    // Display current path or editable input
                    StyledRect {
                        width: parent.width
                        height: root.editingFilePath ? 40 : 36
                        radius: Theme.cornerRadius
                        color: Theme.surfaceVariantAlpha
                        border.color: root.editingFilePath ? Theme.primary : Theme.outlineMedium
                        border.width: 1

                        RowLayout {
                            anchors.fill: parent
                            anchors.leftMargin: Theme.spacingS
                            anchors.rightMargin: Theme.spacingXS
                            spacing: Theme.spacingXS

                            TextInput {
                                id: filePathInput
                                Layout.fillWidth: true
                                visible: root.editingFilePath
                                text: root.tasksModel ? root.tasksModel.storagePath : ""
                                font.pixelSize: Theme.fontSizeSmall
                                font.family: Theme.fontFamilyMono
                                color: Theme.surfaceText
                                clip: true
                                selectByMouse: true

                                Keys.onReturnPressed: {
                                    if (root.tasksModel) {
                                        root.tasksModel.setStoragePath(filePathInput.text);
                                    }
                                    root.editingFilePath = false;
                                }
                                Keys.onEscapePressed: {
                                    root.editingFilePath = false;
                                }
                            }

                            StyledText {
                                Layout.fillWidth: true
                                visible: !root.editingFilePath
                                text: root.tasksModel ? root.tasksModel.storagePath : ""
                                font.pixelSize: Theme.fontSizeSmall - 1
                                font.family: Theme.fontFamilyMono
                                color: Theme.surfaceVariantText
                                elide: Text.ElideMiddle
                            }

                            DankActionButton {
                                circular: false
                                iconName: root.editingFilePath ? "check" : "edit"
                                iconSize: Theme.iconSizeSmall - 2
                                iconColor: root.editingFilePath ? Theme.primary : Theme.surfaceVariantText
                                tooltipText: root.editingFilePath ? I18n.tr("Save Path (Enter)") : I18n.tr("Edit Path")
                                onClicked: {
                                    if (root.editingFilePath) {
                                        if (root.tasksModel) {
                                            root.tasksModel.setStoragePath(filePathInput.text);
                                        }
                                        root.editingFilePath = false;
                                    } else {
                                        root.editingFilePath = true;
                                        Qt.callLater(() => filePathInput.forceActiveFocus());
                                    }
                                }
                            }

                            DankActionButton {
                                visible: root.editingFilePath || (root.tasksModel && root.tasksModel.customStoragePath !== "")
                                circular: false
                                iconName: "restart_alt"
                                iconSize: Theme.iconSizeSmall - 2
                                iconColor: Theme.surfaceVariantText
                                tooltipText: I18n.tr("Reset to default path")
                                onClicked: {
                                    if (root.tasksModel) {
                                        root.tasksModel.setStoragePath("");
                                    }
                                    root.editingFilePath = false;
                                }
                            }
                        }
                    }
                }

                Rectangle {
                    width: parent.width
                    height: 1
                    color: Theme.outlineHeavy
                    opacity: 0.5
                }

                // Setting 2: Default Mode (Slideout vs Popout)
                Column {
                    width: parent.width
                    spacing: Theme.spacingXS

                    StyledText {
                        text: I18n.tr("Default Mode")
                        font.pixelSize: Theme.fontSizeSmall
                        font.weight: Font.Medium
                        color: Theme.surfaceText
                    }

                    StyledText {
                        text: I18n.tr("Open Tasks in an edge slideout or a floating popout window")
                        font.pixelSize: Theme.fontSizeSmall - 2
                        color: Theme.surfaceVariantText
                    }

                    DankButtonGroup {
                        model: [I18n.tr("Slideout"), I18n.tr("Popout")]
                        size: "small"
                        currentIndex: root.defaultMode === "popout" ? 1 : 0
                        onSelectionChanged: (index, selected) => {
                            if (!selected)
                                return;
                            root.updateSetting("defaultMode", index === 1 ? "popout" : "slideout");
                        }
                    }
                }

                // Setting 3: Panel Location (Right vs Left side)
                Column {
                    width: parent.width
                    spacing: Theme.spacingXS
                    visible: root.defaultMode !== "popout"

                    StyledText {
                        text: I18n.tr("Open From (Slideout Side)")
                        font.pixelSize: Theme.fontSizeSmall
                        font.weight: Font.Medium
                        color: Theme.surfaceText
                    }

                    StyledText {
                        text: I18n.tr("Select screen edge where the Tasks panel slides out from")
                        font.pixelSize: Theme.fontSizeSmall - 2
                        color: Theme.surfaceVariantText
                    }

                    DankButtonGroup {
                        model: [I18n.tr("Right"), I18n.tr("Left")]
                        size: "small"
                        currentIndex: root.slideoutSide === "left" ? 1 : 0
                        onSelectionChanged: (index, selected) => {
                            if (!selected)
                                return;
                            root.updateSetting("slideoutSide", index === 1 ? "left" : "right");
                        }
                    }
                }

                Rectangle {
                    width: parent.width
                    height: 1
                    color: Theme.outlineHeavy
                    opacity: 0.5
                }

                // Setting 4: Gaps & Transparency
                Column {
                    width: parent.width
                    spacing: Theme.spacingS

                    DankToggle {
                        anchors.left: parent.left
                        anchors.leftMargin: -Theme.spacingM
                        width: parent.width + Theme.spacingM
                        text: I18n.tr("Auto Compositor Gaps")
                        description: I18n.tr("Inset Tasks from screen edges using compositor gaps")
                        checked: root.useCompositorGap
                        onToggled: checked => {
                            root.updateSetting("useCompositorGap", checked);
                        }
                    }

                    Column {
                        width: parent.width
                        spacing: Theme.spacingXS
                        visible: !root.useCompositorGap

                        StyledText {
                            text: I18n.tr("Manual Edge Gap")
                            font.pixelSize: Theme.fontSizeSmall
                            font.weight: Font.Medium
                            color: Theme.surfaceText
                        }

                        DankSlider {
                            anchors.left: parent.left
                            anchors.leftMargin: -Theme.spacingXS
                            width: parent.width + Theme.spacingXS * 2
                            height: 24
                            value: root.edgeGap
                            minimum: 0
                            maximum: 64
                            unit: "px"
                            showValue: true
                            wheelEnabled: false
                            onSliderValueChanged: newValue => {
                                root.updateSetting("edgeGap", newValue);
                            }
                        }
                    }

                    DankToggle {
                        anchors.left: parent.left
                        anchors.leftMargin: -Theme.spacingM
                        width: parent.width + Theme.spacingM
                        text: I18n.tr("Surface Opacity Override")
                        description: I18n.tr("Custom background transparency for Tasks")
                        checked: root.transparencyOverride >= 0
                        onToggled: checked => {
                            if (checked) {
                                root.updateSetting("transparencyOverride", 0.95);
                            } else {
                                root.updateSetting("transparencyOverride", -1);
                            }
                        }
                    }

                    DankSlider {
                        anchors.left: parent.left
                        anchors.leftMargin: -Theme.spacingXS
                        width: parent.width + Theme.spacingXS * 2
                        height: 24
                        visible: root.transparencyOverride >= 0
                        value: Math.round((root.transparencyOverride >= 0 ? root.transparencyOverride : 0.95) * 100)
                        minimum: 10
                        maximum: 100
                        unit: "%"
                        showValue: true
                        wheelEnabled: false
                        onSliderValueChanged: newValue => {
                            if (root.transparencyOverride >= 0) {
                                root.updateSetting("transparencyOverride", newValue / 100);
                            }
                        }
                    }
                }


            }
        }

        DankScrollbar {
            id: settingsScrollbar
            targetFlickable: settingsFlickable
            anchors.right: parent.right
            anchors.top: parent.top
            anchors.bottom: parent.bottom
        }
    }
}
