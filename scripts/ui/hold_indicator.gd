class_name HoldIndicator
extends PanelContainer
## "Keep holding…" progress bar for the hold-to-close / hold-to-quit combos.

@onready var _label: Label = %Message
@onready var _bar: ProgressBar = %Bar


func show_progress(text: String, ratio: float) -> void:
	_label.text = text
	_bar.value = clampf(ratio, 0.0, 1.0) * 100.0
	visible = true


func hide_progress() -> void:
	visible = false
