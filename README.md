# DankMaterialShell Tasks Plugin

A native, fast, and lightweight **Tasks & Scratchpad plugin** for [DankMaterialShell](https://github.com/DankLinux/DankMaterialShell) (DMS), built with Quickshell and Qt Quick / QML.

Seamlessly integrated with your desktop environment, it provides an edge slideout panel, a floating window mode, a DankBar widget with a live pending tasks count badge, and full IPC command support for compositor keybindings (e.g. Niri, Hyprland, Mango).

---

## ✨ Features

- **Slideout & Popout Modes**:
  - **Slideout**: Slides in smoothly from either the screen edge (right or left) with customizable edge gaps.
  - **Popout**: Detach or toggle into a freestanding floating window.
  - Quick toggle button in the footer to dock or pop out on the fly.
- **DankBar Widget**:
  - Displays a clean checklist icon with an animated badge indicating pending tasks.
  - Single-click to toggle the tasks panel directly from your top/bottom bar.
- **Intuitive Task Management**:
  - Inline task creation with immediate focus.
  - Mark tasks complete/incomplete with Material checkboxes.
  - Double-click any task to edit inline; press <kbd>Enter</kbd> or click the checkmark to save.
  - Smooth drag-and-drop reordering with live placement hints.
  - Expand/collapse view for longer task descriptions.
  - One-click "Clear completed tasks" button with non-blocking dismissible tooltips.
- **Customizable In-App Settings**:
  - **Storage Location**: Customize the JSON storage path (e.g., sync via Nextcloud, Syncthing, or Git).
  - **Default Presentation**: Choose between edge slideout or floating popout window.
  - **Slideout Edge**: Dock to either the right or left edge of your screen.
  - **Compositor Gaps**: Automatically sync gaps with your active window manager (Niri, Hyprland, Mango) or set manual margins.
  - **Transparency Override**: Independently configure background opacity or adhere to your DMS theme.
- **Atomic Persistence**:
  - Stores all tasks locally in standard JSON format using atomic file writes to prevent corruption.
- **Full IPC Support**:
  - Scriptable or bindable through `dms ipc call tasks <command>`.

---

## 🚀 Installation

### 1. Clone the Repository

Clone directly into your DankMaterialShell plugins directory:

```bash
git clone https://github.com/alekzandrgw/dms-tasks-plugin.git ~/.config/DankMaterialShell/plugins/tasks
```

Or clone anywhere and use the provided deployment script:

```bash
git clone https://github.com/alekzandrgw/dms-tasks-plugin.git
cd dms-tasks-plugin
./deploy.sh --restart
```

### 2. Enable the Plugin in DMS

If you cloned directly into `~/.config/DankMaterialShell/plugins/tasks`:

```bash
dms ipc call plugin-scan scan
dms ipc call plugins enable tasks
systemctl --user restart dms
```

### 3. Add the DankBar Widget (Optional)

1. Open your **DMS Settings** (`Super + ,` or via system menu).
2. Navigate to **DankBar / Widgets**.
3. Add the **Tasks** widget to your preferred bar position (left, center, or right).

---

## ⌨️ Compositor Keybindings

Bind a global keyboard shortcut to toggle Tasks from anywhere.

### Niri (`~/.config/niri/config.kdl` or `~/.config/niri/dms/binds.kdl`)

```kdl
Mod+Alt+T hotkey-overlay-title="Tasks" { spawn "dms" "ipc" "call" "tasks" "toggle"; }
```

### Hyprland (`~/.config/hypr/hyprland.conf`)

```ini
bind = $mainMod ALT, T, exec, dms ipc call tasks toggle
```

---

## 📡 IPC Command Reference

Control Tasks from the terminal, scripts, or window manager bindings via DMS IPC:

| Command | Description | Example |
| :--- | :--- | :--- |
| `toggle` | Toggle slideout/popout visibility | `dms ipc call tasks toggle` |
| `open` | Open the tasks panel | `dms ipc call tasks open` |
| `close` | Close the tasks panel | `dms ipc call tasks close` |
| `popout` | Open in floating popout window mode | `dms ipc call tasks popout` |
| `slideout` | Open in edge slideout mode | `dms ipc call tasks slideout` |
| `add "<text>"` | Add a new task directly from CLI | `dms ipc call tasks add "Review pull requests"` |
| `toggleExpand` | Toggle between standard and wide view | `dms ipc call tasks toggleExpand` |
| `expand` | Expand the slideout width | `dms ipc call tasks expand` |
| `collapse` | Collapse the slideout width | `dms ipc call tasks collapse` |

---

## ⚙️ Configuration & Storage

### Storage Location
By default, tasks are saved to:
```
~/.local/state/DankMaterialShell/tasks.json
```
You can change this path at any time via the in-app **Tasks Settings** overlay (gear icon in the bottom footer) to point to any custom directory (such as a shared cloud folder).

### Settings Storage
Plugin preferences (slideout side, default presentation, gap handling, custom path) are managed by DankMaterialShell in:
```
~/.config/DankMaterialShell/plugin_settings.json
```

---

## 🛠️ Development

- `plugin.json` — Composite plugin manifest (daemon & bar widget).
- `TasksDaemon.qml` — Background daemon, IPC handler, and screen slideout variants.
- `TasksBarWidget.qml` — DankBar pill UI component with live count.
- `TasksContent.qml` — Main tasks UI, input bar, list view, drag-and-drop, and footer.
- `TasksModel.qml` — Reactive data model and atomic JSON persistence.
- `TasksPopoutWindow.qml` — Standalone floating window wrapper.
- `TasksSettings.qml` — In-app settings modal.
- `deploy.sh` — Syncs files to DMS plugin directory and restarts the shell:
  ```bash
  ./deploy.sh --restart
  ```

---

## 👤 Author

- **AlekzandrGW** — [GitHub](https://github.com/alekzandrgw)

---

## 📄 License

MIT License. See [LICENSE](LICENSE) for details.
