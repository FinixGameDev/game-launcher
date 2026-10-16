class_name LauncherFooter
extends PanelContainer
## Bottom bar: button hints (ButtonHint nodes), a message and the "3 / 12" counter.

@onready var _message: Label = %Message
@onready var _counter: Label = %Counter


## Text from launcher_config.json replaces the text set in footer.tscn (if not empty).
func set_message(text: String) -> void:
	if text != "":
		_message.text = text


func set_counter(index: int, total: int) -> void:
	_counter.text = "%d / %d" % [index + 1, total] if total > 0 else ""
