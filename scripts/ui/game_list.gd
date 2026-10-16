@tool
class_name GameList
extends Control
## EmulationStation-style scrolling game list.
## It is drawn from the "GameList" type in theme/launcher_theme.tres:
##   colors:     font_color, font_selected_color, selection_color, accent_color,
##               separator_color, missing_color
##   constants:  row_height, text_margin
##   font_sizes: font_size, tag_font_size
## In the editor it shows demo rows so you can see theme changes immediately.

signal selection_changed(index: int)

const THEME_TYPE := &"GameList"
const DEMO_ROWS := [
	["Example Game One", true],
	["Example Game Two", true],
	["Example Game Three", false],
	["Example Game Four", true],
]

@export var missing_tag := "NOT INSTALLED"
@export var empty_text := "No games configured"

var items: Array = []  # Array of GameEntry
var selected := 0

var _scroll := 0.0


func _ready() -> void:
	clip_contents = true
	resized.connect(queue_redraw)


func _notification(what: int) -> void:
	if what == NOTIFICATION_THEME_CHANGED:
		queue_redraw()


func set_items(new_items: Array) -> void:
	items = new_items
	selected = 0
	_scroll = _target_scroll()
	queue_redraw()
	selection_changed.emit(selected)


func current() -> GameEntry:
	if items.is_empty():
		return null
	return items[selected]


func move(dir: int) -> void:
	if items.size() < 2:
		return
	selected = posmod(selected + dir, items.size())
	queue_redraw()
	selection_changed.emit(selected)


func page(dir: int) -> void:
	if items.size() < 2:
		return
	var step := maxi(1, int(size.y / _row_h()) - 1)
	var new_sel := clampi(selected + dir * step, 0, items.size() - 1)
	if new_sel != selected:
		selected = new_sel
		queue_redraw()
		selection_changed.emit(selected)


# ── helpers

func _is_demo() -> bool:
	return items.is_empty() and Engine.is_editor_hint()


func _row_count() -> int:
	return DEMO_ROWS.size() if _is_demo() else items.size()


func _selected_index() -> int:
	return 1 if _is_demo() else selected


func _row_h() -> float:
	var h := get_theme_constant(&"row_height", THEME_TYPE)
	return float(h) if h > 0 else 72.0


func _target_scroll() -> float:
	var visible_rows := size.y / _row_h()
	var max_scroll := maxf(0.0, float(_row_count()) - visible_rows)
	return clampf(_selected_index() - (visible_rows - 1.0) / 2.0, 0.0, max_scroll)


func _process(delta: float) -> void:
	var target := _target_scroll()
	if absf(target - _scroll) > 0.002:
		_scroll = lerpf(_scroll, target, 1.0 - exp(-16.0 * delta))
		queue_redraw()
	elif _scroll != target:
		_scroll = target
		queue_redraw()


func _draw() -> void:
	var font := get_theme_font(&"font", THEME_TYPE)
	var fs := maxi(8, get_theme_font_size(&"font_size", THEME_TYPE))
	var tag_fs := maxi(8, get_theme_font_size(&"tag_font_size", THEME_TYPE))
	var margin := float(get_theme_constant(&"text_margin", THEME_TYPE))
	var row_h := _row_h()

	var c_text := get_theme_color(&"font_color", THEME_TYPE)
	var c_sel_text := get_theme_color(&"font_selected_color", THEME_TYPE)
	var c_sel_bg := get_theme_color(&"selection_color", THEME_TYPE)
	var c_accent := get_theme_color(&"accent_color", THEME_TYPE)
	var c_sep := get_theme_color(&"separator_color", THEME_TYPE)
	var c_missing := get_theme_color(&"missing_color", THEME_TYPE)

	var count := _row_count()
	if count == 0:
		var w := font.get_string_size(empty_text, HORIZONTAL_ALIGNMENT_LEFT, -1, 28).x
		draw_string(font, Vector2((size.x - w) / 2.0, size.y / 2.0), empty_text, HORIZONTAL_ALIGNMENT_LEFT, -1, 28, c_text)
		return

	var sel := _selected_index()
	var text_h := font.get_height(fs)
	var ascent := font.get_ascent(fs)

	for i in count:
		var y := (i - _scroll) * row_h
		if y + row_h < 0.0 or y > size.y:
			continue
		var title: String
		var available: bool
		if _is_demo():
			title = DEMO_ROWS[i][0]
			available = DEMO_ROWS[i][1]
		else:
			var g: GameEntry = items[i]
			title = g.title
			available = g.available

		var is_sel := i == sel
		if is_sel:
			draw_rect(Rect2(0, y, size.x, row_h), c_sel_bg)
			draw_rect(Rect2(0, y, 8, row_h), c_accent)
		else:
			draw_line(Vector2(24, y + row_h - 1), Vector2(size.x - 24, y + row_h - 1), c_sep, 1.0)

		var col := c_sel_text if is_sel else c_text
		var avail_w := size.x - margin * 2.0
		if not available:
			col = col.darkened(0.35)
			avail_w -= 150.0
			var tag_y := y + (row_h - font.get_height(tag_fs)) / 2.0 + font.get_ascent(tag_fs)
			draw_string(font, Vector2(0, tag_y), missing_tag, HORIZONTAL_ALIGNMENT_RIGHT, size.x - 28, tag_fs, c_missing)

		var baseline := y + (row_h - text_h) / 2.0 + ascent
		draw_string(font, Vector2(margin, baseline), title, HORIZONTAL_ALIGNMENT_LEFT, avail_w, fs, col)

	# Scrollbar
	var visible_rows := size.y / row_h
	if count > visible_rows:
		var track_h := size.y - 16.0
		var bar_h := maxf(30.0, track_h * visible_rows / count)
		var max_scroll := float(count) - visible_rows
		var bar_y := 8.0 + (track_h - bar_h) * (_scroll / max_scroll)
		draw_rect(Rect2(size.x - 8, bar_y, 4, bar_h), Color(c_accent, 0.7))
