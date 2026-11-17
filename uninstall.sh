#!/bin/bash
set -euo pipefail

BIN_DST="$HOME/.local/bin"
PLUGINS_DST="$HOME/.config/omarchy/plugins"
SHELL_JSON="$HOME/.config/omarchy/shell.json"
HYPR_MAIN="$HOME/.config/hypr/hyprland.lua"
HYPR_COSMOS="$HOME/.config/hypr/cosmos.lua"

echo "==> Restoring stock Omarchy plugins in ~/.config/omarchy/shell.json..."
python3 - "$SHELL_JSON" <<'PY'
import json
import sys
from pathlib import Path

path = Path(sys.argv[1])
if path.exists():
    cfg = json.loads(path.read_text(encoding="utf-8"))
    bar = cfg.setdefault("bar", {})
    bar.pop("id", None)
    layout = bar.get("layout", {})
    if isinstance(layout, dict):
        layout["left"] = [
            {"id": "omarchy.menu"},
            {"id": "omarchy.workspaces"},
        ]
        layout["centerBegin"] = [
            x for x in layout.get("centerBegin", [])
            if not (isinstance(x, dict) and str(x.get("id", "")).startswith("cosmos."))
        ]
        layout["right"] = [
            x for x in layout.get("right", [])
            if not (isinstance(x, dict) and str(x.get("id", "")).startswith("cosmos."))
        ]
    cfg["plugins"] = [
        p for p in cfg.get("plugins", [])
        if not (isinstance(p, dict) and str(p.get("id", "")).startswith("cosmos."))
    ]
    if "disabledPlugins" in cfg and isinstance(cfg["disabledPlugins"], list):
        cfg["disabledPlugins"] = [
            x for x in cfg["disabledPlugins"]
            if x not in ("omarchy.menu", "omarchy.lock", "omarchy.background")
        ]
    path.write_text(json.dumps(cfg, indent=2) + "\n", encoding="utf-8")
PY

echo "==> Removing Cosmos plugins and binaries..."
for p in cosmos.bar cosmos.workspaces cosmos.vinyl-media cosmos.agent-pill cosmos.studio cosmos.menu cosmos.lock cosmos.background cosmos.settings; do
  rm -rf "$PLUGINS_DST/$p"
done
rm -f "$BIN_DST/cosmos-ctl" "$BIN_DST/cosmos-agent-watcher"

echo "==> Removing Cosmos Hyprland hook..."
rm -f "$HYPR_COSMOS"
if [[ -f "$HYPR_MAIN" ]]; then
  python3 - "$HYPR_MAIN" <<'PY'
import re
import sys
from pathlib import Path

p = Path(sys.argv[1])
txt = p.read_text(encoding="utf-8")
txt = re.sub(r"\n?-- >>> omarchy-cosmos >>>.*?-- <<< omarchy-cosmos <<<\n?", "\n", txt, flags=re.S)
p.write_text(txt, encoding="utf-8")
PY
fi

omarchy-restart-shell >/dev/null 2>&1 || omarchy-shell shell rescanPlugins || true
hyprctl reload
hyprctl configerrors
echo "==> Reverted cleanly to stock Omarchy!"
