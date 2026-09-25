#!/usr/bin/env bash
# ==============================================================================
# deploy.sh — Build & Deploy Tasks Plugin to DankMaterialShell (DMS)
# ==============================================================================
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TARGET_DIR="${HOME}/.config/DankMaterialShell/plugins/tasks"

RESTART_SHELL=false

for arg in "$@"; do
    case "$arg" in
        --restart|-r)
            RESTART_SHELL=true
            shift
            ;;
        --help|-h)
            echo "Usage: ./deploy.sh [OPTIONS]"
            echo ""
            echo "Options:"
            echo "  -r, --restart    Restart dms.service to clear Qt QML memory cache (recommended when editing QML files)"
            echo "  -h, --help       Show this help message"
            exit 0
            ;;
    esac
done

echo "==> Deploying Tasks plugin from '${SCRIPT_DIR}' to '${TARGET_DIR}'..."
mkdir -p "${TARGET_DIR}"

# Copy all plugin files (manifest and QML sources)
cp -f "${SCRIPT_DIR}/plugin.json" "${TARGET_DIR}/"
cp -f "${SCRIPT_DIR}/"*.qml "${TARGET_DIR}/"

echo "==> Files deployed:"
ls -lh "${TARGET_DIR}"

if [ "${RESTART_SHELL}" = true ]; then
    echo "==> Restarting dms.service (clearing QML cache)..."
    systemctl --user restart dms
    sleep 1.5
    echo "==> Rescanning and enabling plugin..."
    dms ipc call plugin-scan scan || true
    dms ipc call plugins enable tasks || true
else
    echo "==> Triggering DMS rescan..."
    dms ipc call plugin-scan rescan tasks || dms ipc call plugin-scan scan || true
    echo "==> Reloading plugin in DMS..."
    # Note: If Qt QML caches subcomponents, run with --restart
    dms ipc call plugins reload tasks || {
        echo "(!) Notice: In-process reload had an issue. Restarting dms.service to reload cleanly..."
        systemctl --user restart dms
        sleep 1.5
        dms ipc call plugins enable tasks || true
    }
fi

echo "==> Plugin Status:"
dms ipc call plugins status tasks || true

echo "==> Deployment complete! Test with: dms ipc call tasks toggle"
