#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BIN_DST="$HOME/.local/bin"
PLUGINS_DST="$HOME/.config/omarchy/plugins"
SHELL_JSON="$HOME/.config/omarchy/shell.json"
HYPR_MAIN="$HOME/.config/hypr/hyprland.lua"
HYPR_COSMOS="$HOME/.config/hypr/cosmos.lua"
STATE_HOME="${XDG_STATE_HOME:-$HOME/.local/state}"

echo "==> Installing Cosmos CLI utilities to $BIN_DST..."
mkdir -p "$BIN_DST" "$STATE_HOME/cosmos"
cp -f "$SCRIPT_DIR/bin/cosmos-ctl" "$BIN_DST/cosmos-ctl"
cp -f "$SCRIPT_DIR/bin/cosmos-agent-watcher" "$BIN_DST/cosmos-agent-watcher"
chmod +x "$BIN_DST/cosmos-ctl" "$BIN_DST/cosmos-agent-watcher"

"$BIN_DST/cosmos-ctl" init
"$BIN_DST/cosmos-agent-watcher" --once >/dev/null || true

ALL_PLUGINS=(
  cosmos.bar
  cosmos.workspaces
  cosmos.vinyl-media
  cosmos.agent-pill
  cosmos.studio
  cosmos.menu
  cosmos.lock
  cosmos.background
  cosmos.settings
)

echo "==> Validating Cosmos plugins..."
for p in "${ALL_PLUGINS[@]}"; do
  omarchy plugin validate "$SCRIPT_DIR/plugins/$p"
done

echo "==> Installing plugins into $PLUGINS_DST (no symlinks)..."
mkdir -p "$PLUGINS_DST"

for p in "${ALL_PLUGINS[@]}"; do
  rm -rf "$PLUGINS_DST/$p"
  cp -a "$SCRIPT_DIR/plugins/$p" "$PLUGINS_DST/$p"
  omarchy plugin validate "$PLUGINS_DST/$p"
done

echo "==> Installing Hyprland configuration ($HYPR_COSMOS)..."
cp -f "$SCRIPT_DIR/hypr/cosmos.lua" "$HYPR_COSMOS"
python3 - "$HYPR_MAIN" <<'PY'
import sys
from pathlib import Path

p = Path(sys.argv[1])
txt = p.read_text(encoding="utf-8") if p.exists() else ""
if 'require("hypr.cosmos")' not in txt:
    txt = txt.rstrip() + '\n\n-- >>> omarchy-cosmos >>>\nrequire("hypr.cosmos")\n-- <<< omarchy-cosmos <<<\n'
p.write_text(txt, encoding="utf-8")
PY

echo "==> Updating ~/.config/omarchy/shell.json..."
python3 - "$SHELL_JSON" <<'PY'
import json
import sys
from pathlib import Path

path = Path(sys.argv[1])
cfg = json.loads(path.read_text(encoding="utf-8"))

bar = cfg.setdefault("bar", {})
layout = bar.setdefault("layout", {})

pinned = []
for section_items in layout.values():
    if isinstance(section_items, list):
        for item in section_items:
            if isinstance(item, dict) and item.get("id") == "omarchy.tray" and "pinned" in item:
                pinned = item["pinned"]

right_items = [
    {"id": "omarchy.tray", "pinned": pinned} if pinned else {"id": "omarchy.tray"},
    {"id": "cosmos.agent-pill"},
    {"id": "omarchy.agents"},
    {"id": "omarchy.bluetooth"},
    {"id": "omarchy.network"},
    {"id": "omarchy.audio"},
    {"id": "omarchy.monitor"},
    {"id": "omarchy.power"},
]
if (Path.home() / ".config/omarchy/plugins/io.github.denonmaryland.theme-studio").is_dir():
    right_items.append({"id": "io.github.denonmaryland.theme-studio"})
right_items.append({"id": "cosmos.settings"})

bar["id"] = "cosmos.bar"
bar["position"] = bar.get("position", "top")
bar["background"] = "glassy"
bar["layout"] = {
    "left": [
        {"id": "cosmos.menu"},
        {"id": "cosmos.workspaces"},
    ],
    "centerBegin": [
        {"id": "omarchy.indicators"},
        {"id": "cosmos.vinyl-media"},
    ],
    "center": [
        {
            "id": "omarchy.clock",
            "format": "HH:mm  ddd d MMM",
            "formatAlt": "dddd d MMMM 'W'ww yyyy",
            "verticalFormat": "HH\n—\nmm",
        }
    ],
    "centerEnd": [
        {"id": "omarchy.weather"},
        {"id": "omarchy.keyboard-layout"},
        {"id": "omarchy.system-update"},
    ],
    "right": right_items,
    "tray": layout.get("tray", []),
}

plugins = [
    p for p in cfg.get("plugins", [])
    if not (isinstance(p, dict) and str(p.get("id", "")).startswith("cosmos."))
]
for req_id in ("cosmos.studio", "cosmos.lock", "cosmos.background", "cosmos.settings"):
    plugins.append({"id": req_id})
cfg["plugins"] = plugins

disabled = cfg.setdefault("disabledPlugins", [])
for src_id in ("omarchy.menu", "omarchy.lock", "omarchy.background"):
    if src_id not in disabled:
        disabled.append(src_id)

path.write_text(json.dumps(cfg, indent=2) + "\n", encoding="utf-8")
PY

if [[ "${1:-}" == "--with-starship" ]]; then
  echo "==> Applying Cosmos Starship prompt (~/.config/starship.toml)..."
  [[ -f "$HOME/.config/starship.toml" ]] && cp -f "$HOME/.config/starship.toml" "$HOME/.config/starship.toml.bak.cosmos"
  cp -f "$SCRIPT_DIR/config/starship-cosmos.toml" "$HOME/.config/starship.toml"
fi

echo "==> Restarting Omarchy shell & validating Hyprland..."
omarchy-restart-shell >/dev/null 2>&1 || omarchy-shell shell rescanPlugins || true
hyprctl reload
hyprctl configerrors
echo "==> Omarchy Cosmos installed and active!"
