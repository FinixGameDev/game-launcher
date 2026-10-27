# Game Launcher

CODED BY CLAUDE AI

A controller-driven launcher for showing game prototypes at events and playtests.
Visitors pick a game with a gamepad, the game starts, and when it closes the
launcher comes back. Styled after EmulationStation, with a slot for your team
logo and name.

Made with **Godot 4.3+** (works in newer 4.x versions as well). 2D only, uses the
Compatibility renderer, so it runs fine on modest event laptops.

---

## Quick start

1. Open this folder in Godot (**Import** → select `project.godot`). Let it import once.
2. Press **F5** (it opens `main.tscn`). You'll see the launcher with three example entries marked *NOT INSTALLED*.
3. Edit `config/launcher_config.json`:
   - set your team name / tagline,
   - drop your logo at `config/assets/logo.png`,
   - point each game's `executable` at your builds (see below).
4. Press **F5** again (or **X** on a controller inside the launcher) to reload.
5. To restyle, open `theme/launcher_theme.tres` or any scene in `scenes/` (see [docs/CUSTOMIZING.md](docs/CUSTOMIZING.md)).

While running from the editor the launcher stays windowed and does not minimize itself,
so you can iterate quickly. These behaviours only apply to exported builds.

## Folder layout

```
project.godot
main.tscn                 main screen (compose / rearrange the UI here)
scenes/                   one scene per UI part
  header.tscn               logo, team name, tagline, clock, controller status
  game_details.tscn         preview image + title / meta / description
  footer.tscn               button hints, message, counter
  button_hint.tscn          reusable "(A) Play" hint
  info_overlay.tscn         the Y screen
  playing_overlay.tscn      cover shown while a game runs
  toast.tscn                pop-up messages
  hold_indicator.tscn       "keep holding..." bar
theme/
  launcher_theme.tres       <- ALL colors, fonts sizes and panel styles
  background.tres           <- background gradient
scripts/
  main.gd                   input + launch flow
  launcher_config.gd        reads the JSON config
  game_entry.gd             one game
  game_runner.gd            starts / watches the game process
  ui/                       one small script per scene (+ the game list widget)
config/                   content you edit without opening Godot
  launcher_config.json      <- team, settings and the list of games
  assets/logo.png           <- your logo (you add this)
  assets/thumbnails/        <- one preview image per game
  games/                    <- put your game builds here
integration/quit_to_launcher.gd   optional helper for your Godot games
docs/                     extra guides
```

**Look vs. content.** Everything visual (colors, fonts, spacing, layout, texts like
"Press A or B to close") lives in Godot scenes and the theme resource, edited in the
Godot editor. Everything event-specific (which games, team name, logo, timings) lives in
`launcher_config.json`, which you can change without Godot, even on an exported build.
See [docs/CUSTOMIZING.md](docs/CUSTOMIZING.md).

In an **exported** launcher, the same `config/` contents sit **next to the executable**:

```
GameLauncher.exe
launcher_config.json
assets/logo.png
assets/thumbnails/...
games/space_gardeners/SpaceGardeners.exe
games/...
```

Relative paths in the config are always relative to the config file's folder.
You can also point to a config somewhere else with `--config=/path/to/launcher_config.json`.

---

## Configuring games

Each entry in `"games"`:

| Key | Required | Description |
|---|---|---|
| `title` | yes | Name shown in the list |
| `executable` | yes | Path to the build. A string, or a per-OS object `{ "windows": "...", "linux": "...", "macos": "..." }` |
| `args` | no | List of command-line arguments, e.g. `["--fullscreen"]` |
| `id` | no | Short unique id used in the session log (defaults to the title) |
| `description` | no | Pitch text under the preview image |
| `genre`, `players`, `developer`, `version` | no | Shown in the line under the title |
| `controls` | no | Shown when pressing **Y** (Info). Use `\n` for line breaks |
| `thumbnail` | no | Preview image (png, jpg, webp, svg). 16:9 looks best |
| `enabled` | no | Set `false` to hide a game without deleting the entry |

Notes:

- A game whose executable can't be found is shown greyed out as **NOT INSTALLED** and can't be launched. Handy for checking that every path is right before an event.
- A bare command with no slashes (e.g. `"executable": "notepad"`) is looked up on the system PATH. Useful for testing.
- macOS `.app` bundles are started with `open -W`, so the launcher waits until the app quits.
- On Linux/macOS make sure builds are executable: `chmod +x MyGame.x86_64`.
- The launcher starts the game as a separate process and waits for **that process** to end. If you use a wrapper script (`.bat`, `.sh`), make sure it stays running until the game exits (for example `start /wait game.exe` in a `.bat` file).

### Launcher settings (`"launcher"`)

| Key | Default | Description |
|---|---|---|
| `fullscreen` | `true` | Run fullscreen |
| `hide_mouse_cursor` | `true` | Hide the cursor |
| `minimize_while_playing` | `true` | Minimize the launcher while a game runs, restore it afterwards |
| `return_cooldown_seconds` | `1.0` | Ignore input for this long after returning, so the button that closed the game doesn't also start another one |
| `force_quit_hold_seconds` | `3.0` | Hold time for the close-game combo (`0` disables it) |
| `operator_exit_hold_seconds` | `3.0` | Hold time to quit the launcher (`0` disables it) |
| `footer_text` | `""` | Centered text in the bottom bar, e.g. "Feedback form at the table!" |

### Branding

- **Team name / tagline**: `"team": { "name": "...", "tagline": "..." }`. They replace the placeholder texts in `scenes/header.tscn`.
- **Logo**: `"team": { "logo": "assets/logo.png" }`. The slot is 300x108 px on the 1080p layout; wide transparent PNGs work best. Until the file exists, a "YOUR LOGO HERE" placeholder is shown. You can also bake the logo into the scene (see CUSTOMIZING).
- **Colors, fonts, panel styles**: edit `theme/launcher_theme.tres` in Godot. There is no theme section in the JSON any more.

---

## Controls

| Action | Controller | Keyboard |
|---|---|---|
| Move | D-pad / left stick up-down | ↑ ↓ |
| Launch | A | Enter / Space |
| Game info & controls | Y | I |
| Jump a page | LB / RB, D-pad left-right | ← → / PageUp / PageDown |
| Close info | A or B | Esc |
| Reload config | X | F5 |
| Close running game (best effort) | Hold START + BACK | |
| Quit launcher | Hold START + BACK + LB + RB | Hold Ctrl + Q |

Every connected controller works; no pairing needed. Button names follow Godot's
Xbox-style layout (A = bottom button). PlayStation and Switch pads work too.

## Returning to the launcher

Games are separate programs. The launcher comes back when the game's process ends, so each prototype needs *some* way to quit that a visitor can reach with a controller. See [docs/GAME_INTEGRATION.md](docs/GAME_INTEGRATION.md). For Godot games, copy `integration/quit_to_launcher.gd` and add it as an Autoload.

As a safety net the launcher watches for **START + BACK held for 3 s** and kills the running game. This relies on the launcher still receiving controller input while minimized, which depends on OS and controller type, so **test it on your event machine** and don't rely on it as the only exit.

## Session log

Every play session is appended to `sessions.csv` (game, duration, whether it was force-closed). This is a cheap way to see which prototypes people actually played and for how long.

- Windows: `%APPDATA%\Godot\app_userdata\Game Launcher\sessions.csv`
- macOS: `~/Library/Application Support/Godot/app_userdata/Game Launcher/sessions.csv`
- Linux: `~/.local/share/godot/app_userdata/Game Launcher/sessions.csv`

(In Godot: **Project → Open User Data Folder**.)

## Exporting the launcher

Scenes and the theme are packed into the exported launcher, so **re-export after changing the look**. Config, logo, thumbnails and games are read from disk next to the executable and can be changed without re-exporting.

1. **Project → Export…**, add a preset for your platform (download export templates if asked).
2. Export to a folder, e.g. `dist/GameLauncher.exe`.
3. Copy `config/launcher_config.json`, `config/assets/` and `config/games/` next to the exported executable (drop the `config/` wrapper folder, put the contents directly beside the exe).
4. Run it. If the config is missing you'll see an error banner with the exact path it looked for.

More event-day tips are in [docs/EVENT_SETUP.md](docs/EVENT_SETUP.md).

## Troubleshooting

| Problem | Likely cause |
|---|---|
| "Config file not found" banner | Config isn't next to the exe (exported) or `--config=` path is wrong |
| Game shows *NOT INSTALLED* | Path typo, wrong OS key in the `executable` object, or file not copied |
| "Closed immediately" banner | Build isn't executable (Linux/macOS), missing runtime libs, or a wrapper script that exits right away |
| Launcher doesn't come back after quitting a game | The game process is still running (check Task Manager), or a wrapper script exited early |
| Controller not responding | Check the top-right label; try another USB port; on Linux make sure the pad is recognised by the system |
| Hold START+BACK doesn't close the game | Background controller input isn't delivered on your setup; use the game's own quit option |
| Launcher doesn't regain focus on Windows | Windows can block focus stealing; set `minimize_while_playing` to `true` (default) and avoid exclusive-fullscreen in games |
