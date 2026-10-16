class_name GameDetails
extends VBoxContainer
## Right-hand side: preview image plus title / meta line / description.

@export var empty_title := "No games found"
@export_multiline var empty_description := "Add games to launcher_config.json and press X to reload."
@export var not_installed_tag := "NOT INSTALLED"
@export var fade_time := 0.18

@onready var _preview: TextureRect = %Preview
@onready var _preview_hint: Label = %PreviewHint
@onready var _title: Label = %GameTitle
@onready var _meta: Label = %Meta
@onready var _description: Label = %Description

var _fade: Tween


func show_empty() -> void:
	_title.text = empty_title
	_meta.text = ""
	_description.text = empty_description
	_preview.texture = null
	_preview_hint.visible = true


func show_game(g: GameEntry) -> void:
	_title.text = g.title
	var parts := PackedStringArray()
	if g.genre != "":
		parts.append(g.genre)
	if g.players != "":
		parts.append(g.players)
	if g.developer != "":
		parts.append("by " + g.developer)
	if not g.available:
		parts.append(not_installed_tag)
	_meta.text = "  •  ".join(parts)
	_description.text = g.description

	_preview.texture = g.texture
	_preview_hint.visible = g.texture == null
	if g.texture != null and fade_time > 0.0:
		if _fade:
			_fade.kill()
		_preview.modulate.a = 0.0
		_fade = create_tween()
		_fade.tween_property(_preview, "modulate:a", 1.0, fade_time)
	else:
		_preview.modulate.a = 1.0
