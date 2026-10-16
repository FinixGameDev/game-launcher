class_name PlayingOverlay
extends Panel
## Full-screen cover shown while a game is running.

@export_multiline var message := "Now playing\n%s\n\nClose the game to return to the launcher"

@onready var _label: Label = %Message


func show_for(game: GameEntry) -> void:
	_label.text = message % game.title
	visible = true


func dismiss() -> void:
	visible = false
