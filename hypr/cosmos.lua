-- >>> omarchy-cosmos >>>
-- Frosted glass blur for Cosmos Bar, Studio, Menu Drawer, Pins & Settings
-- ignore_alpha = 0.25 ensures Transparent mode and gaps between islands stay crystal clear.
require("default.hypr.glass")()

local cosmos_ctl = os.getenv("HOME") .. "/.local/bin/cosmos-ctl"

-- Keep normal windows crisp (never blur or dim the desktop behind overlays)
hl.config({
  decoration = {
    dim_special = 0.0,
    blur = {
      special = false,
    },
  },
})

hl.layer_rule({
  match = { namespace = "^omarchy-bar$" },
  blur = true,
  ignore_alpha = 0.25,
})

hl.layer_rule({
  match = { namespace = "^cosmos-pins$" },
  blur = true,
  ignore_alpha = 0.20,
})

hl.layer_rule({
  match = { namespace = "^cosmos-studio$" },
  blur = true,
  ignore_alpha = 0.25,
})

hl.layer_rule({
  match = { namespace = "^omarchy-menu$" },
  blur = true,
  ignore_alpha = 0.20,
})

hl.layer_rule({
  match = { namespace = "^cosmos-settings$" },
  blur = true,
  ignore_alpha = 0.22,
})

-- YouTube Music webapp: float centered instead of tiling half the screen
local yt_music = "^chrome-music\\.youtube\\.com__.*$"
o.window(yt_music, { tag = "-chromium-based-browser" })
o.window(yt_music, { float = true, center = true, size = { 1280, 820 } })

-- Single-modifier shortcuts (VNC + Mac/Karabiner friendly: SUPER/OPT + 1 key)
hl.unbind("SUPER + S")
o.bind("SUPER + S", "Cosmos: Show desktop (hide/restore all windows)", cosmos_ctl .. " desktop-toggle")
o.bind("SUPER + D", "Cosmos: Toggle Cosmos Studio side panel", cosmos_ctl .. " studio toggle")
o.bind("SUPER + N", "Cosmos: Focus most urgent AI agent", cosmos_ctl .. " focus-agent")
o.bind("SUPER + Y", "Cosmos: Toggle YouTube Music drawer", cosmos_ctl .. " music-open")
o.bind("SUPER + H", "Cosmos: Minimize active window", cosmos_ctl .. " window-hide")
o.bind("SUPER + U", "Cosmos: Restore last minimized window", cosmos_ctl .. " window-restore")
o.bind("SUPER + B", "Cosmos: Cycle bar style", cosmos_ctl .. " bar-style cycle")
o.bind("SUPER + E", "Cosmos: Cycle menu drawer style", cosmos_ctl .. " menu-style cycle")
o.bind("SUPER + R", "Cosmos: Preview Rain Lock Screen", cosmos_ctl .. " lock-preview")
o.bind("SUPER + Z", "Cosmos: Toggle Appearances & Settings", cosmos_ctl .. " settings toggle")
o.bind("SUPER + PERIOD", "Cosmos: Toggle OMARCHY wallpaper logo", cosmos_ctl .. " logo toggle")

-- Additional Cosmos shortcuts (SUPER + CTRL + ALT prefix)
o.bind("SUPER + CTRL + ALT + G", "Cosmos: Cycle bar style", cosmos_ctl .. " bar-style cycle")
o.bind("SUPER + CTRL + ALT + O", "Cosmos: Theme Studio", "omarchy-shell shell toggle io.github.denonmaryland.theme-studio")
o.bind("SUPER + CTRL + ALT + M", "Cosmos: YouTube Music", cosmos_ctl .. " music-open")
-- <<< omarchy-cosmos <<<
