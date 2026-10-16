# Event setup checklist

## Before the event
- [ ] Every game shows up in the list without *NOT INSTALLED*.
- [ ] Launch every game once, quit it, confirm you land back in the launcher.
- [ ] Every game has a controller-reachable quit (see GAME_INTEGRATION.md).
- [ ] Logo, team name, thumbnails and descriptions are filled in.
- [ ] Test with the actual controllers (and with 2+ connected if you have multiplayer games).
- [ ] Test the START + BACK close-game combo on the event laptop.
- [ ] Set `footer_text` to tell people where to leave feedback.
- [ ] Keep a spare keyboard in the bag: Ctrl+Q (hold) quits the launcher, F5 reloads the config.

## Machine setup
- Disable sleep, screen saver and lock screen; plug into power.
- Turn off notifications (Windows: Focus assist / Do not disturb) so popups don't cover the games.
- Set the display resolution to the monitor's native one and match the games' resolution.
- Close everything else: chat apps, cloud sync, updaters.
- Windows: pause Windows Update for the day.

## Starting the launcher automatically
- **Windows**: put a shortcut to `GameLauncher.exe` in `shell:startup`.
- **Linux**: add a `.desktop` file to `~/.config/autostart/`.
- **macOS**: System Settings → General → Login Items.

## Running the day
- Check the session log afterwards (`sessions.csv`, see README) to see play counts and durations per game.
- If something gets stuck: hold START + BACK + LB + RB (or Ctrl+Q) to exit the launcher, then start it again.
- Edit `launcher_config.json` between sessions to reorder or hide games, then press X (or F5) in the launcher to reload.

## Backup plan
Keep a copy of the whole folder (launcher + games + config) on a USB stick and on cloud storage.
