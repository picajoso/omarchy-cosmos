# Omarchy Cosmos

**Omarchy Cosmos** is a lightweight, 100% open-source (`MIT`) desktop suite for **Omarchy 4.x** (`quickshell` + `hyprland` + `owe` + `qt6-shadertools`).

Every plugin, GLSL shader, QML scene, and CLI daemon is built natively on top of Omarchy's official plugin architecture (`~/.config/omarchy/plugins/`) without touching `/usr/share/omarchy/`.

---

## Features

- **`cosmos.bar` & `cosmos.workspaces`** — Multi-mode frosted-glass top bar (**Bar**, **Islands**, **Solid**, **Transparent**) with adaptive contrast, dynamic workspace capsules with per-app glyphs, and a bottom dock for minimized windows.
- **`cosmos.studio` & `cosmos.agent-pill`** — Live AI Agent Command Center side drawer and top-bar status pill. Monitors **Antigravity**, **Claude Desktop / Claude Code**, **ChatGPT Desktop**, **Codex**, and **Hermes Agent** (`~/.hermes/state.db`) locally via `cosmos-agent-watcher` with zero external network calls, rendering custom procedural **Mecha-Chibi robots** that react in real time (`working`, `waiting_input`, `idle`).
- **`cosmos.vinyl-media`** — Spinning MPRIS vinyl disc pill in the top bar + integrated **Turntable** / **Aurora** media card inside Cosmos Studio, paired with a centered floating YouTube Music drawer.
- **`cosmos.menu`** — 5-layout Omarchy Menu & Launcher replacement (**Left**, **Center**, **Top**, **Right**, **Full**) with instant live layout switching and system stats footer.
- **`cosmos.lock`** — Custom GPU-accelerated optical rain refraction shader (`rain.frag.qsb` with **Off / Drizzle / Rain / Storm** modes) and theme-reactive gradient clock (`gradient_clock.frag.qsb`).
- **`cosmos.background`** — Optional pixel-art `OMARCHY` gradient wordmark overlay (`logo_gradient.frag.qsb`, off by default, toggleable anytime) + `owe` one-shot Arrival video wallpaper support.
- **`cosmos.settings`** — Right-side **Appearances & Settings** drawer with 6 curated theme presets, custom appearance snapshots, live **Undo / Keep** preview bar, and unified controls for bar, menu, rain, player, and wallpaper wordmark.
- **`config/starship-cosmos.toml`** *(optional)* — Two-line Pastel-Powerline Starship prompt with OS, path, Git branch/status, language runtimes, and command duration capsules.

---

## Requirements

- **Omarchy Linux 4.x** (`omarchy-shell` / `quickshell`, `hyprland`, `playerctl`, `python3`)
- Optional: `omarchy-wallpaper-engine` (`owe`) for animated Arrival wallpapers, `starship` for the optional terminal prompt.

---

## Installation

Clone the repository anywhere and run `./install.sh`:

```bash
git clone https://github.com/picajoso/omarchy-cosmos.git
cd omarchy-cosmos
./install.sh
```

To also install the 2-line Pastel-Powerline Starship prompt (`~/.config/starship.toml`, backing up any existing file to `~/.config/starship.toml.bak.cosmos`):

```bash
./install.sh --with-starship
```

### Uninstall (Restore Stock Omarchy)

```bash
./uninstall.sh
```

---

## Keyboard Shortcuts

Designed with single-modifier `SUPER` bindings (friendly for both native keyboards and remote VNC / Mac `OPT` remaps):

| Shortcut | Action |
| :--- | :--- |
| `SUPER + SPACE` | Open Cosmos Menu / App Launcher |
| `SUPER + E` | Cycle Menu layout (`Left` → `Center` → `Top` → `Right` → `Full`) |
| `SUPER + B` | Cycle Top Bar style (`Bar` → `Islands` → `Solid` → `Transparent`) |
| `SUPER + D` | Toggle **Cosmos Studio** side panel (AI Robots + Turntable) |
| `SUPER + N` | Jump directly to the most urgent AI agent window |
| `SUPER + Z` | Toggle **Appearances & Settings** drawer |
| `SUPER + R` | Preview **Rain Lock Screen** (press `ESC` to close preview) |
| `SUPER + .` | Toggle `OMARCHY` pixel-art wallpaper wordmark |
| `SUPER + Y` | Toggle floating YouTube Music window |
| `SUPER + S` | Show / restore desktop windows (`special:cosmos_desk`) |
| `SUPER + H` / `SUPER + U` | Minimize active window to dock / restore last minimized window |

---

## Repository Structure

```text
omarchy-cosmos/
├── bin/
│   ├── cosmos-ctl             # State, IPC, window & appearance controller CLI
│   └── cosmos-agent-watcher   # Read-only local AI agent state daemon
├── config/
│   └── starship-cosmos.toml   # Optional 2-line Pastel-Powerline Starship prompt
├── hypr/
│   └── cosmos.lua             # Hyprland glass layer rules & SUPER keybindings
├── plugins/
│   ├── cosmos.agent-pill/     # Top-bar live AI agent status pill
│   ├── cosmos.background/     # Wallpaper + optional gradient wordmark overlay
│   ├── cosmos.bar/            # 4-mode adaptive frosted-glass bar
│   ├── cosmos.lock/           # Optical GLSL rain & gradient clock lock screen
│   ├── cosmos.menu/           # 5-mode launcher & system menu drawer
│   ├── cosmos.settings/       # Appearances & live customization drawer
│   ├── cosmos.studio/         # Mecha-Chibi AI Studio & Vinyl/Aurora player
│   ├── cosmos.vinyl-media/    # Top-bar spinning MPRIS vinyl widget
│   └── cosmos.workspaces/     # Dynamic workspace & app-icon pills
├── install.sh                 # Portable installer & validator
├── uninstall.sh               # Clean stock-Omarchy restorer
└── LICENSE                    # MIT License
```

---

## License

Released under the [MIT License](./LICENSE) — Copyright © 2026 Javier Pastor.
