extends Node
## Drop-in helper for Godot prototypes that are started by the Game Launcher.
##
## Setup: copy this file into your game, then add it as an Autoload
## (Project > Project Settings > Globals > Autoload).
##
## Holding ESC, or START + BACK on any controller, for `hold_seconds` quits the
## game. The launcher notices the process ended and comes back automatically.

@export var hold_seconds := 1.5

var _held := 0.0


func _process(delta: float) -> void:
	var combo := Input.is_key_pressed(KEY_ESCAPE)
	for pad in Input.get_connected_joypads():
		if Input.is_joy_button_pressed(pad, JOY_BUTTON_START) and Input.is_joy_button_pressed(pad, JOY_BUTTON_BACK):
			combo = true
	if combo:
		_held += delta
		if _held >= hold_seconds:
			get_tree().quit()
	else:
		_held = 0.0
