import QtQuick
import Quickshell
import qs.Common
import qs.Widgets
import qs.Modules.Plugins

PluginComponent {
    id: root

    layerNamespacePlugin: "tasks"

    PluginGlobalVar {
        id: pendingCountVar
        varName: "pendingCount"
        defaultValue: 0
    }

    PluginGlobalVar {
        id: toggleRequestVar
        varName: "toggleRequest"
        defaultValue: 0
    }

    function toggleTasks() {
        toggleRequestVar.set(toggleRequestVar.value + 1);
        Quickshell.execDetached(["dms", "ipc", "call", "tasks", "toggle"]);
    }

    horizontalBarPill: Component {
        Item {
            implicitWidth: contentRow.implicitWidth
            implicitHeight: contentRow.implicitHeight

            Row {
                id: contentRow
                spacing: Theme.spacingXS
                anchors.verticalCenter: parent.verticalCenter

                DankIcon {
                    name: "checklist"
                    size: Theme.iconSize - 2
                    color: Theme.surfaceText
                    anchors.verticalCenter: parent.verticalCenter
                }

                Rectangle {
                    visible: pendingCountVar.value > 0
                    width: Math.max(16, countLabel.implicitWidth + Theme.spacingXS * 2)
                    height: 16
                    radius: 8
                    color: Theme.primary
                    anchors.verticalCenter: parent.verticalCenter

                    StyledText {
                        id: countLabel
                        anchors.centerIn: parent
                        text: pendingCountVar.value.toString()
                        font.pixelSize: Theme.fontSizeSmall - 3
                        font.weight: Font.Bold
                        color: Theme.surface
                    }
                }
            }

            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: root.toggleTasks()
            }
        }
    }

    verticalBarPill: Component {
        Item {
            implicitWidth: contentCol.implicitWidth
            implicitHeight: contentCol.implicitHeight

            Column {
                id: contentCol
                spacing: Theme.spacingXS
                anchors.horizontalCenter: parent.horizontalCenter

                DankIcon {
                    name: "checklist"
                    size: Theme.iconSize - 2
                    color: Theme.surfaceText
                    anchors.horizontalCenter: parent.horizontalCenter
                }

                Rectangle {
                    visible: pendingCountVar.value > 0
                    width: Math.max(16, countLabelVert.implicitWidth + Theme.spacingXS * 2)
                    height: 16
                    radius: 8
                    color: Theme.primary
                    anchors.horizontalCenter: parent.horizontalCenter

                    StyledText {
                        id: countLabelVert
                        anchors.centerIn: parent
                        text: pendingCountVar.value.toString()
                        font.pixelSize: Theme.fontSizeSmall - 3
                        font.weight: Font.Bold
                        color: Theme.surface
                    }
                }
            }

            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: root.toggleTasks()
            }
        }
    }
}
