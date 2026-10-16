class_name InfoOverlay
extends Panel
## "Y" screen: controls and details for the selected game.
## Toggle its visibility (eye icon) in the editor to preview the layout.

@export var controls_heading := "CONTROLS"
@export_multiline var no_controls_text := "No control info provided for this game."
@export_multiline var leave_hint := "To leave a game, use its own quit option, or hold START + BACK for %d seconds."

@onready var _title: Label = %Title
@onready var _body: Label = %Body


func open(game: GameEntry, force_quit_seconds: float) -> void:
	_title.text = game.title
	var blocks := PackedStringArray()
	if game.controls != "":
		blocks.append("%s\n%s" % [controls_heading, game.controls])
	else:
		blocks.append(no_controls_text)
	var meta := PackedStringArray()
	if game.players != "":
		meta.append("Players: " + game.players)
	if game.version != "":
		meta.append("Build: " + game.version)
	if game.developer != "":
		meta.append("By: " + game.developer)
	if not meta.is_empty():
		blocks.append("  |  ".join(meta))
	if force_quit_seconds > 0.0 and leave_hint != "":
		blocks.append(leave_hint % int(force_quit_seconds))
	_body.text = "\n\n".join(blocks)
	visible = true


func close() -> void:
	visible = false
