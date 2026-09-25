pragma ComponentBehavior: Bound
import QtQuick
import qs.Common
import qs.Widgets

Item {
    id: root

    property bool isVisible: false
    property bool shortcutsExpanded: false

    signal settingsRequested
    signal findRequested

    readonly property var _settingsDep: SettingsData.pluginSettings

    readonly property bool useMonospace: {
        _settingsDep;
        return SettingsData.getPluginSetting("tasks", "useMonospace", false);
    }
    readonly property bool autoSave: {
        _settingsDep;
        return SettingsData.getPluginSetting("tasks", "autoSave", true);
    }
    readonly property int fontSize: {
        _settingsDep;
        return SettingsData.getPluginSetting("tasks", "fontSize", 14);
    }
    readonly property real transparencyOverride: {
        _settingsDep;
        return SettingsData.getPluginSetting("tasks", "transparencyOverride", -1);
    }
    readonly property string defaultMode: {
        _settingsDep;
        return SettingsData.getPluginSetting("tasks", "defaultMode", "slideout");
    }
    readonly property string slideoutSide: {
        _settingsDep;
        return SettingsData.getPluginSetting("tasks", "slideoutSide", "right");
    }
    readonly property bool useCompositorGap: {
        _settingsDep;
        return SettingsData.getPluginSetting("tasks", "useCompositorGap", true);
    }
    readonly property int edgeGap: {
        _settingsDep;
        return SettingsData.getPluginSetting("tasks", "edgeGap", 8);
    }

    function updateSetting(key, val) {
        SettingsData.setPluginSetting("tasks", key, val);
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
        width: Math.min(360, root.width - Theme.spacingL * 2)
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
                Rectangle {
                    width: parent.width
                    height: 36
                    color: "transparent"

                    StyledText {
                        anchors.left: parent.left
                        anchors.leftMargin: -Theme.spacingXS
                        anchors.verticalCenter: parent.verticalCenter
                        text: I18n.tr("Tasks Settings")
                        font.pixelSize: Theme.fontSizeMedium
                        font.weight: Font.Medium
                        color: Theme.surfaceText
                    }
                }

                Rectangle {
                    width: parent.width
                    height: 1
                    color: Theme.outlineHeavy
                }

                // 1. Use Monospace Font
                DankToggle {
                    anchors.left: parent.left
                    anchors.leftMargin: -Theme.spacingM
                    width: parent.width + Theme.spacingM
                    text: I18n.tr("Use Monospace Font")
                    description: I18n.tr("Toggle fonts")
                    checked: root.useMonospace
                    onToggled: checked => {
                        root.updateSetting("useMonospace", checked);
                    }
                }

                // 2. Auto-save to disk
                DankToggle {
                    anchors.left: parent.left
                    anchors.leftMargin: -Theme.spacingM
                    width: parent.width + Theme.spacingM
                    text: I18n.tr("Auto-save to disk")
                    description: I18n.tr("Automatically save changes to opened files as you type")
                    checked: root.autoSave
                    onToggled: checked => {
                        root.updateSetting("autoSave", checked);
                    }
                }

                // 3. Find in Text
                StyledRect {
                    width: parent.width
                    height: 60
                    radius: Theme.cornerRadius
                    color: "transparent"

                    StateLayer {
                        anchors.fill: parent
                        anchors.leftMargin: -Theme.spacingM
                        width: parent.width + Theme.spacingM
                        stateColor: Theme.primary
                        cornerRadius: parent.radius
                        onClicked: root.findRequested()
                    }

                    Row {
                        anchors.left: parent.left
                        anchors.leftMargin: -Theme.spacingM
                        anchors.right: parent.right
                        anchors.rightMargin: Theme.spacingM
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: Theme.spacingM

                        DankIcon {
                            name: "search"
                            size: Theme.iconSize - 2
                            color: Theme.primary
                            anchors.verticalCenter: parent.verticalCenter
                        }

                        Column {
                            anchors.verticalCenter: parent.verticalCenter
                            spacing: Theme.spacingXS

                            StyledText {
                                text: I18n.tr("Find in Text")
                                font.pixelSize: Theme.fontSizeMedium
                                font.weight: Font.Medium
                                color: Theme.surfaceText
                            }

                            StyledText {
                                text: I18n.tr("Open search bar to find text")
                                font.pixelSize: Theme.fontSizeSmall
                                color: Theme.surfaceVariantText
                            }
                        }
                    }
                }

                // 4. Font Size
                Rectangle {
                    width: parent.width
                    height: fontSizeRow.height + Theme.spacingS
                    color: "transparent"

                    Row {
                        id: fontSizeRow
                        width: parent.width
                        spacing: Theme.spacingS

                        Column {
                            width: parent.width - fontSizeControls.width - Theme.spacingM
                            spacing: Theme.spacingXS

                            StyledText {
                                text: I18n.tr("Font Size")
                                font.pixelSize: Theme.fontSizeSmall
                                font.weight: Font.Medium
                                color: Theme.surfaceText
                            }

                            StyledText {
                                text: root.fontSize + "px"
                                font.pixelSize: Theme.fontSizeSmall
                                color: Theme.surfaceVariantText
                                width: parent.width
                            }
                        }

                        Row {
                            id: fontSizeControls
                            spacing: Theme.spacingS
                            anchors.verticalCenter: parent.verticalCenter

                            DankActionButton {
                                buttonSize: 32
                                iconName: "remove"
                                iconSize: Theme.iconSizeSmall
                                enabled: root.fontSize > 8
                                backgroundColor: Theme.withAlpha(Theme.surfaceVariant, 0.5)
                                iconColor: Theme.surfaceText
                                onClicked: {
                                    var newSize = Math.max(8, root.fontSize - 1);
                                    root.updateSetting("fontSize", newSize);
                                }
                            }

                            Rectangle {
                                width: 60
                                height: 32
                                radius: Theme.cornerRadius
                                color: Theme.withAlpha(Theme.surfaceVariant, 0.3)
                                border.color: Theme.outlineHeavy
                                border.width: 1

                                StyledText {
                                    anchors.centerIn: parent
                                    text: root.fontSize + "px"
                                    font.pixelSize: Theme.fontSizeSmall
                                    font.weight: Font.Medium
                                    color: Theme.surfaceText
                                }
                            }

                            DankActionButton {
                                buttonSize: 32
                                iconName: "add"
                                iconSize: Theme.iconSizeSmall
                                enabled: root.fontSize < 48
                                backgroundColor: Theme.withAlpha(Theme.surfaceVariant, 0.5)
                                iconColor: Theme.surfaceText
                                onClicked: {
                                    var newSize = Math.min(48, root.fontSize + 1);
                                    root.updateSetting("fontSize", newSize);
                                }
                            }
                        }
                    }
                }

                // 5. Surface Opacity
                Rectangle {
                    width: parent.width
                    height: transparencySliderColumn.height + Theme.spacingS
                    color: "transparent"

                    Column {
                        id: transparencySliderColumn
                        width: parent.width
                        spacing: Theme.spacingS

                        DankToggle {
                            anchors.left: parent.left
                            anchors.leftMargin: -Theme.spacingM
                            width: parent.width + Theme.spacingM
                            text: I18n.tr("Surface Opacity")
                            description: I18n.tr("Override floating window transparency for Tasks")
                            checked: root.transparencyOverride >= 0
                            onToggled: checked => {
                                if (checked) {
                                    root.updateSetting("transparencyOverride", 0.9);
                                } else {
                                    root.updateSetting("transparencyOverride", -1);
                                }
                            }
                        }

                        DankSlider {
                            anchors.left: parent.left
                            anchors.leftMargin: -Theme.spacingM
                            width: parent.width + Theme.spacingM
                            height: 24
                            visible: root.transparencyOverride >= 0
                            value: Math.round((root.transparencyOverride >= 0 ? root.transparencyOverride : Theme.floatingWindowTransparency) * 100)
                            minimum: 0
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

                // 6. Default Mode & Open From & Compositor Gaps
                Rectangle {
                    width: parent.width
                    height: gapColumn.height + Theme.spacingS
                    color: "transparent"

                    Column {
                        id: gapColumn
                        width: parent.width
                        spacing: Theme.spacingS

                        // Default Mode
                        Column {
                            width: parent.width
                            spacing: Theme.spacingXS

                            StyledText {
                                text: I18n.tr("Default Mode")
                                font.pixelSize: Theme.fontSizeSmall
                                font.weight: Font.Medium
                                color: Theme.surfaceText
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

                        // Open From
                        Column {
                            width: parent.width
                            spacing: Theme.spacingXS
                            visible: root.defaultMode !== "popout"

                            StyledText {
                                text: I18n.tr("Open From")
                                font.pixelSize: Theme.fontSizeSmall
                                font.weight: Font.Medium
                                color: Theme.surfaceText
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

                        // Auto Compositor Gaps
                        DankToggle {
                            anchors.left: parent.left
                            anchors.leftMargin: -Theme.spacingM
                            width: parent.width + Theme.spacingM
                            text: I18n.tr("Auto Compositor Gaps")
                            description: I18n.tr("Inset Tasks from screen edges using the compositor's configured gaps")
                            checked: root.useCompositorGap
                            onToggled: checked => {
                                root.updateSetting("useCompositorGap", checked);
                            }
                        }

                        StyledText {
                            visible: !root.useCompositorGap
                            text: I18n.tr("Manual Gaps")
                            font.pixelSize: Theme.fontSizeSmall
                            font.weight: Font.Medium
                            color: Theme.surfaceText
                        }

                        DankSlider {
                            anchors.left: parent.left
                            anchors.leftMargin: Theme.spacingXS
                            width: parent.width - Theme.spacingXS * 2
                            height: 24
                            visible: !root.useCompositorGap
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
                }

                // Global Font Note
                StyledText {
                    width: parent.width
                    text: root.useMonospace ? I18n.tr("Using global monospace font from Settings → Personalization") : I18n.tr("Global fonts can be configured in Settings → Personalization")
                    font.pixelSize: Theme.fontSizeSmall
                    color: Theme.surfaceTextMedium
                    wrapMode: Text.WordWrap
                    opacity: 0.8
                }

                // Keyboard Shortcuts Drawer
                StyledRect {
                    width: parent.width
                    implicitHeight: shortcutsHeader.height + (root.shortcutsExpanded ? shortcutsColumn.implicitHeight + Theme.spacingM : 0)
                    radius: Theme.cornerRadius
                    color: root.shortcutsExpanded ? Theme.withAlpha(Theme.surfaceContainer, 0.95) : Theme.withAlpha(Theme.surfaceContainer, 0)
                    border.color: root.shortcutsExpanded ? Theme.primary : Theme.outlineMedium
                    border.width: root.shortcutsExpanded ? 2 : 1

                    StateLayer {
                        anchors.fill: parent
                        stateColor: Theme.primary
                        cornerRadius: parent.radius
                        onClicked: root.shortcutsExpanded = !root.shortcutsExpanded
                    }

                    Row {
                        id: shortcutsHeader
                        anchors.top: parent.top
                        anchors.left: parent.left
                        anchors.right: parent.right
                        anchors.leftMargin: Theme.spacingM
                        anchors.rightMargin: Theme.spacingS
                        height: 36
                        spacing: Theme.spacingS

                        DankIcon {
                            name: root.shortcutsExpanded ? "expand_less" : "expand_more"
                            size: Theme.iconSizeSmall
                            color: Theme.surfaceText
                            anchors.verticalCenter: parent.verticalCenter
                        }

                        StyledText {
                            text: I18n.tr("Keyboard Shortcuts")
                            font.pixelSize: Theme.fontSizeSmall
                            font.weight: Font.Medium
                            color: Theme.surfaceText
                            anchors.verticalCenter: parent.verticalCenter
                        }
                    }

                    Column {
                        id: shortcutsColumn
                        visible: root.shortcutsExpanded
                        width: parent.width - Theme.spacingL * 2
                        anchors.top: shortcutsHeader.bottom
                        anchors.horizontalCenter: parent.horizontalCenter
                        spacing: Theme.spacingXXS

                        StyledText {
                            width: parent.width
                            text: I18n.tr("Mod+Alt+T: Toggle Tasks • Enter: Add Task • Ctrl+F: Search")
                            font.pixelSize: Theme.fontSizeSmall
                            color: Theme.surfaceText
                            wrapMode: Text.WordWrap
                            horizontalAlignment: Text.AlignHCenter
                        }

                        StyledText {
                            width: parent.width
                            text: I18n.tr("Esc: Close Tasks / Settings • Click Outside: Dismiss")
                            font.pixelSize: Theme.fontSizeSmall
                            color: Theme.surfaceText
                            wrapMode: Text.WordWrap
                            horizontalAlignment: Text.AlignHCenter
                        }
                    }
                }
            }
        }
    }
}
