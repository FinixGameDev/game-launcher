class_name LauncherHeader
extends PanelContainer
## Top bar: logo, team name, tagline, clock and controller status.
## Values in launcher_config.json override the text/logo set in header.tscn.

@onready var _logo: TextureRect = %Logo
@onready var _logo_placeholder: Control = %LogoPlaceholder
@onready var _logo_hint: Label = %LogoHint
@onready var _team_name: Label = %TeamName
@onready var _tagline: Label = %Tagline
@onready var _clock: Label = %Clock
@onready var _status: Label = %ControllerStatus

@export var status_normal_variation := &"StatusLabel"
@export var status_warning_variation := &"StatusLabelWarn"
@export var no_controller_text := "No controller detected"
@export var one_controller_text := "1 controller connected"
@export var many_controllers_text := "%d controllers connected"

var _last_status := ""


func _ready() -> void:
	_tagline.visible = _tagline.text != ""
	_logo_placeholder.visible = _logo.texture == null


func set_team(team_name: String, tagline: String, logo: Texture2D, logo_path: String) -> void:
	if team_name != "":
		_team_name.text = team_name
	if tagline != "":
		_tagline.text = tagline
	_tagline.visible = _tagline.text != ""
	if logo != null:
		_logo.texture = logo
	_logo_placeholder.visible = _logo.texture == null
	if logo_path != "":
		_logo_hint.text = "YOUR LOGO HERE\n%s" % logo_path


func _process(_delta: float) -> void:
	_clock.text = Time.get_time_string_from_system().left(5)
	var n := Input.get_connected_joypads().size()
	var text := no_controller_text
	if n == 1:
		text = one_controller_text
	elif n > 1:
		text = many_controllers_text % n
	if text != _last_status:
		_last_status = text
		_status.text = text
		_status.theme_type_variation = status_warning_variation if n == 0 else status_normal_variation
