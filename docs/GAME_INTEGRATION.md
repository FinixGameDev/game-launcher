# Making games work well with the launcher

The launcher starts each game as its own process and returns when that process ends.
Nothing needs to be added to your games, but visitors need a way to quit.

## Recommended: a hold-to-quit shortcut in every game

Pick one consistent exit for all prototypes and tell testers once: **hold START + BACK** (and/or **hold ESC**) for 1.5 seconds.

### Godot games
Copy `integration/quit_to_launcher.gd` into your game and register it under
**Project Settings → Globals → Autoload**. Done.

### Unity (Input System, rough sketch)
```csharp
using UnityEngine; using UnityEngine.InputSystem;
public class QuitToLauncher : MonoBehaviour {
    float held;
    void Update() {
        var pad = Gamepad.current;
        bool combo = (pad != null && pad.startButton.isPressed && pad.selectButton.isPressed)
                  || (Keyboard.current != null && Keyboard.current.escapeKey.isPressed);
        held = combo ? held + Time.unscaledDeltaTime : 0f;
        if (held > 1.5f) Application.Quit();
    }
}
```

### Other engines
Any equivalent works: poll the buttons, count seconds, call the engine's quit function.

## Practical tips

- **Build windowed-fullscreen / borderless** rather than exclusive fullscreen. It switches cleanly between the launcher and the game.
- **Controller-only play**: make sure menus and pause screens work without a mouse and keyboard.
- **Command-line args**: use `args` in the config for per-event switches (`["--fullscreen"]`, `["--demo-mode"]`, `["--skip-intro"]`). Godot games read them with `OS.get_cmdline_user_args()`.
- **Autosave / reset**: for event builds, reset game state on launch so each visitor gets a fresh start.
- **Settings the game saves** (resolution, volume) persist between visitors. Consider a "kiosk mode" flag that ignores saved settings.
- **Wrapper scripts**: if a game needs a launcher script, keep the script alive until the game exits.
  - Windows `.bat`: `start /wait "" "%~dp0Game.exe"`
  - Linux `.sh`: just run the binary in the foreground (no trailing `&`).
- **Feedback**: add a "scan this QR code" screen to the game's exit or pause menu, or put a QR on the table and mention it in the launcher's `footer_text`.

## Where the launcher's own safety net fits

While a game runs, the launcher watches for START + BACK held for `force_quit_hold_seconds` (default 3 s) and ends the process. It's meant as a backup for a game that has hung or has no quit option. Whether it works while the launcher is minimized depends on the OS and controller, so test it on your event hardware.
