# Agent Development Rules: DankMaterialShell Tasks Plugin

## 1. Project Overview & Locations
This project is a native **Tasks scratchpad plugin** for DankMaterialShell (DMS), built similarly to the built-in Notepad slideout.

- **Source Code**: `/home/alex/Documents/Computer/dms-tasks-plugin/`
- **Deployment Target**: `/home/alex/.config/DankMaterialShell/plugins/tasks/`
- **Persistent Data**: `/home/alex/.local/state/DankMaterialShell/tasks.json`
- **Niri Shortcut**: `/home/alex/.config/niri/dms/binds.kdl` (`Mod+Alt+T`)
- **Deployment Script**: `/home/alex/Documents/Computer/dms-tasks-plugin/deploy.sh`
- **Location Reference**: `/home/alex/Documents/Computer/dms-tasks-plugin/LOCATIONS.md`

---

## 2. Development & Modification Rules

1. **Always Edit Source First**:
   - Edit files exclusively in `/home/alex/Documents/Computer/dms-tasks-plugin/`.
   - Never make manual changes directly in `~/.config/DankMaterialShell/plugins/tasks/` without syncing the source directory.

2. **Always Deploy & Test Using `deploy.sh`**:
   - After any edit, run:
     ```bash
     /home/alex/Documents/Computer/dms-tasks-plugin/deploy.sh
     ```
   - If Qt QML cached old bytecode in memory or an in-process reload fails, run:
     ```bash
     /home/alex/Documents/Computer/dms-tasks-plugin/deploy.sh --restart
     ```

3. **Verify Functionality via IPC**:
   - Always verify the daemon is responsive after deployment:
     ```bash
     dms ipc call tasks toggle
     dms ipc call tasks add "Verification Task"
     dms ipc call tasks toggle
     ```

---

## 3. Architecture & QML Technical Constraints

1. **Composite Plugin Architecture (`plugin.json`)**:
   - Must declare `"type": "composite"` with both `"daemon"` and `"widget"` components.
   - `"requires_dms": ">=1.5.0"` is mandatory for composite surfaces.

2. **Daemon Surface (`TasksDaemon.qml`)**:
   - Must import `Quickshell.Io` to expose `IpcHandler { target: "tasks" }`.
   - Hosts `Variants { model: Quickshell.screens delegate: DankSlideout { ... } }` to render the slideout on the active display.

3. **State Management & Persistence (`TasksModel.qml`)**:
   - Root element **must be `Item`** (not `QtObject`), so that child QObjects like `FileView` instantiate properly.
   - **Do NOT** use `PluginService.savePluginState()` (DMS 1.6 contains a bug attempting `fv.loaded.connect` on boolean property).
   - Use `Quickshell.Io.FileView` with `atomicWrites: true` directly to write to `~/.local/state/DankMaterialShell/tasks.json`.
   - Update reactive pill count using `PluginService.setGlobalVar("tasks", "pendingCount", pending)`.

4. **UI Styling (`TasksContent.qml` & `TasksBarWidget.qml`)**:
   - Always use DMS theme tokens (`Theme.primary`, `Theme.surfaceContainer`, `Theme.fontSizeMedium`, `Theme.cornerRadius`). Never hardcode hex colors or pixel sizes.
   - Keyboard handling: input auto-focuses on `slideout.revealed`, <kbd>Enter</kbd> submits, <kbd>Esc</kbd> closes slideout.

5. **Backup Preservation**:
   - Keep `/home/alex/.config/DankMaterialShell/plugins/tasks-caldav-backup/` intact; do not overwrite or delete it.
