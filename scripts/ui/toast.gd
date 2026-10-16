class_name Toast
extends PanelContainer
## Small pop-up message. Normal and error looks are theme variations.

@export var normal_variation := &"ToastPanel"
@export var error_variation := &"ToastPanelError"

@onready var _message: Label = %Message

var _tween: Tween


func show_message(text: String, seconds: float = 4.0, is_error: bool = false) -> void:
	_message.text = text
	theme_type_variation = error_variation if is_error else normal_variation
	visible = true
	if _tween:
		_tween.kill()
	_tween = create_tween()
	_tween.tween_interval(seconds)
	_tween.tween_callback(hide)
