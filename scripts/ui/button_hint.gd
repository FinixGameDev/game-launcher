@tool
class_name ButtonHint
extends HBoxContainer
## A round "button glyph + caption" hint, e.g. (A) Play. Edit the properties
## in the Inspector; the look comes from the HintPill / HintGlyph / HintLabel
## theme variations.

@export var glyph := "A":
	set(v):
		glyph = v
		_apply()
@export var caption := "Play":
	set(v):
		caption = v
		_apply()
@export var pill_color := Color("#3fae5a"):
	set(v):
		pill_color = v
		_apply()
@export var glyph_color := Color.WHITE:
	set(v):
		glyph_color = v
		_apply()

@onready var _pill: PanelContainer = %Pill
@onready var _glyph: Label = %Glyph
@onready var _caption: Label = %Caption


func _ready() -> void:
	_apply()


func _notification(what: int) -> void:
	if what == NOTIFICATION_THEME_CHANGED:
		_apply()


func _apply() -> void:
	if not is_node_ready():
		return
	_glyph.text = glyph
	_glyph.add_theme_color_override(&"font_color", glyph_color)
	_caption.text = caption
	_pill.remove_theme_stylebox_override(&"panel")
	var sb := _pill.get_theme_stylebox(&"panel")
	if sb is StyleBoxFlat:
		var copy: StyleBoxFlat = sb.duplicate()
		copy.bg_color = pill_color
		_pill.add_theme_stylebox_override(&"panel", copy)
