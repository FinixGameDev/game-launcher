# Customizing the look

Open the project in Godot 4.3+. Everything visual is a normal scene or resource,
so you edit it with the Inspector and the Theme editor. No code needed.

## 1. The theme (`theme/launcher_theme.tres`)

Double-click it to open the **Theme editor** at the bottom of the editor. It holds:

| What | Where in the theme |
|---|---|
| Panel colors and rounded corners | Type **HeaderPanel**, **FooterPanel**, **CardPanel**, **OverlayPanel**, **ToastPanel**, **ToastPanelError**, **HoldPanel**, **LogoPlaceholder** (StyleBox *panel*) |
| Accent line under the header | Type **AccentLine** (StyleBox *panel*) |
| Dim backdrop behind the Y screen / full-screen "now playing" cover | Types **DimBackdrop**, **PlayingBackdrop** |
| Text colors and sizes | Label variations: **TeamNameLabel**, **TaglineLabel**, **ClockLabel**, **StatusLabel**, **StatusLabelWarn**, **GameTitleLabel**, **MetaLabel**, **DescriptionLabel**, **FooterLabel**, **CounterLabel**, **OverlayTitle**, **OverlayBody**, **OverlayHint**, **PlayingLabel**, **ToastLabel**, **HintLabel**, **HintGlyph**, **PlaceholderLabel**, **LogoHintLabel** |
| Button hint circles | **HintPill** (shape), **HintGlyph** / **HintLabel** (text). Per-button colors are set on each hint instance (see below) |
| Hold-to-quit progress bar | **ProgressBar** (*background*, *fill*) |
| The game list | Custom type **GameList**: colors `font_color`, `font_selected_color`, `selection_color`, `accent_color`, `separator_color`, `missing_color`; constants `row_height`, `text_margin`; font sizes `font_size`, `tag_font_size` |

How to change things:

- **Change the accent color**: it appears in a few places on purpose (AccentLine, MetaLabel, StatusLabelWarn, OverlayTitle, OverlayPanel border, ProgressBar fill, GameList `accent_color` and `selection_color`). Change those entries.
- **Change the font**: in the Theme editor set **Default Font** (select the theme resource, Inspector → *Default Font*) to a `.ttf`/`.otf` file in the project. Font sizes are per variation.
- **Add a new text style**: in the Theme editor, *Add type* and create a variation of `Label` (or `PanelContainer`), then pick it on any node under *Theme Overrides → Theme Type Variation*.

The **game list** is a custom-drawn control. In the editor it shows demo rows
("Example Game One…") so you can see your theme changes in `main.tscn` right away.

## 2. The background (`theme/background.tres`)

A `GradientTexture2D`. Edit the gradient colors in the Inspector, or replace the
`Background` node's texture in `main.tscn` with your own image.

## 3. Scenes

Open any file in `scenes/`:

- **header.tscn**: move things around, resize the logo slot (`LogoSlot` custom minimum size), change the placeholder team name and tagline. You can also assign a **texture directly to the `Logo` node** to bake your logo into the launcher. A logo from `launcher_config.json` still takes priority.
- **footer.tscn**: the hints at the bottom are instances of `button_hint.tscn`. Select one and change *Glyph*, *Caption*, *Pill Color*, *Glyph Color* in the Inspector. Duplicate one to add more, delete one to remove it.
- **game_details.tscn**: change the proportions of the preview and the text panel (*Size Flags → Stretch Ratio*).
- **info_overlay.tscn**, **playing_overlay.tscn**: toggle the node's visibility (eye icon) to preview them. Texts such as "Press A or B to close" are plain labels; the dynamic texts (`CONTROLS` heading, the "Now playing" template, the "hold START + BACK" hint) are *exported properties* on the root node.
- **main.tscn**: the overall layout (header, list, details, footer). Select the **Main** node to edit the launcher's messages (hold-to-close text, error toasts, ...) in the Inspector.

Text from `launcher_config.json` (team name, tagline, footer message) replaces the
text in the scenes only when it is not empty.

## 4. Things to keep in mind

- Don't rename nodes marked with a `%` unique-name icon (for example `%Title`, `%GameList`, `%Header`); the scripts look them up by name. You can freely move and restyle them.
- The UI is designed for a **1920x1080** canvas and scales to other resolutions (project settings: stretch mode `canvas_items`, aspect `expand`).
- `config/assets/` and `config/games/` contain a `.gdignore` so the Godot editor doesn't import your game builds and thumbnails.
- After changing the look, **re-export** the launcher; scenes and the theme are baked into the export.
