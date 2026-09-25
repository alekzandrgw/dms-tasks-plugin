# Important File Locations & Environment Reference

This document maps all critical files and paths used for development, deployment, and debugging of the **Tasks** plugin for DankMaterialShell (DMS).

---

## 1. Development & Source Code
- **Plugin Source Directory**: `/home/alex/Documents/Computer/dms-tasks-plugin/`
  - `plugin.json` — Composite plugin manifest (declares `daemon` and `widget` components).
  - `TasksDaemon.qml` — Background service: hosts `DankSlideout` and registers the `IpcHandler` (`target: "tasks"`).
  - `TasksBarWidget.qml` — DankBar pill UI: displays task icon and reactive pending task count badge.
  - `TasksContent.qml` — Slideout content view: Material text input, task list view, completion toggles, delete action.
  - `TasksModel.qml` — Task state management & atomic persistence via `Quickshell.Io.FileView`.
  - `deploy.sh` — Deployment automation script to sync source code to DMS and activate.

---

## 2. DankMaterialShell (DMS) Plugin Locations
- **Active Plugin Directory**: `/home/alex/.config/DankMaterialShell/plugins/tasks/`
  - This is the required location where DMS looks for the installed plugin.
- **DMS Config Root**: `/home/alex/.config/DankMaterialShell/`
  - `settings.json` — Global shell configuration (bar layout, themes, built-in features).
  - `plugin_settings.json` — Per-plugin settings and enabled/disabled states.
  - `plugins.lock.json` — Plugin registry lockfile.
- **Backup Directory**: `/home/alex/.config/DankMaterialShell/plugins/tasks-caldav-backup/`
  - Preserved clone of external community CalDAV plugin.

---

## 3. Persistent Data & State
- **Tasks Database**: `/home/alex/.local/state/DankMaterialShell/tasks.json`
  - Active JSON array of tasks: `[ { "id", "text", "done", "createdAt" } ]`.
- **DMS Plugins State Directory**: `/home/alex/.local/state/DankMaterialShell/plugins/`

---

## 4. Compositor & Keybindings (Niri)
- **Niri Keybindings File**: `/home/alex/.config/niri/dms/binds.kdl`
  - Contains shortcut:
    ```kdl
    Mod+Alt+T hotkey-overlay-title="Tasks" { spawn "dms" "ipc" "call" "tasks" "toggle"; }
    ```
- **Niri Config Root**: `/home/alex/.config/niri/`

---

## 5. DMS Internal & Reference Files (Read-Only)
- **Extracted DMS QML Tree**: `/run/user/1000/danklinux-shell/<hash>/`
  - (Find dynamic path with `ls -d /run/user/1000/danklinux-shell/*/`)
  - Key reference files:
    - `Widgets/DankSlideout.qml` — The slideout window component used by Notepad and Tasks.
    - `Modules/Notepad/` — Notepad implementation reference (`Notepad.qml`, `NotepadTextEditor.qml`).
    - `DMSShellIPC.qml` — Shell-level IPC handlers.
    - `Services/PluginService.qml` — Plugin loader, scanner, and state service.
- **IPC Socket**: `/run/user/1000/danklinux-<pid>.sock`

---

## 6. Service & Process Management
- **DMS Systemd Service**: `dms.service`
  - Restart: `systemctl --user restart dms`
  - Check status: `systemctl --user status dms`
  - View live logs: `journalctl --user -u dms.service -f`
- **Quickshell Process**: `qs` (running under `dms run --session`)
