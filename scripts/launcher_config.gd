class_name LauncherConfig
extends RefCounted
## Loads launcher_config.json and exposes it as typed fields.
##
## Search order for the config file:
##   1. --config=/path/to/file.json  (command line)
##   2. launcher_config.json next to the exported executable
##   3. res://config/launcher_config.json  (when running from the editor)

const CONFIG_NAME := "launcher_config.json"

var config_path := ""
var base_dir := ""
var load_error := ""

var team_name := ""
var team_tagline := ""
var logo_texture: Texture2D = null
var logo_hint := "assets/logo.png"

var fullscreen := true
var hide_mouse := true
var minimize_while_playing := true
var return_cooldown := 1.0
var operator_exit_hold := 3.0
var force_quit_hold := 3.0
var footer_text := ""

var games: Array = []  # Array of GameEntry


func locate() -> String:
	var all_args := OS.get_cmdline_args() + OS.get_cmdline_user_args()
	for arg in all_args:
		if arg.begins_with("--config="):
			return arg.get_slice("=", 1)
	var beside_exe := OS.get_executable_path().get_base_dir().path_join(CONFIG_NAME)
	if FileAccess.file_exists(beside_exe):
		return beside_exe
	return ProjectSettings.globalize_path("res://config/" + CONFIG_NAME)


func load_config() -> bool:
	games.clear()
	load_error = ""

	config_path = locate()
	base_dir = config_path.get_base_dir()

	if not FileAccess.file_exists(config_path):
		load_error = "Config file not found:\n%s" % config_path
		return false

	var json := JSON.new()
	var err := json.parse(FileAccess.get_file_as_string(config_path))
	if err != OK:
		load_error = "Config JSON error (line %d): %s" % [json.get_error_line(), json.get_error_message()]
		return false
	if typeof(json.data) != TYPE_DICTIONARY:
		load_error = "Config root must be a JSON object."
		return false
	var data: Dictionary = json.data

	var team: Dictionary = _dict(data.get("team", {}))
	team_name = str(team.get("name", team_name))
	team_tagline = str(team.get("tagline", ""))
	logo_hint = str(team.get("logo", logo_hint))
	if logo_hint != "":
		var logo_path := logo_hint if logo_hint.is_absolute_path() else base_dir.path_join(logo_hint).simplify_path()
		logo_texture = GameEntry.load_texture(logo_path)

	var launcher: Dictionary = _dict(data.get("launcher", {}))
	fullscreen = bool(launcher.get("fullscreen", fullscreen))
	hide_mouse = bool(launcher.get("hide_mouse_cursor", hide_mouse))
	minimize_while_playing = bool(launcher.get("minimize_while_playing", minimize_while_playing))
	return_cooldown = float(launcher.get("return_cooldown_seconds", return_cooldown))
	operator_exit_hold = float(launcher.get("operator_exit_hold_seconds", operator_exit_hold))
	force_quit_hold = float(launcher.get("force_quit_hold_seconds", force_quit_hold))
	footer_text = str(launcher.get("footer_text", ""))

	var raw_games: Variant = data.get("games", [])
	if raw_games is Array:
		for entry in raw_games:
			if entry is Dictionary and bool(entry.get("enabled", true)):
				games.append(GameEntry.from_dict(entry, base_dir))
	else:
		load_error = "\"games\" must be a list."
		return false
	return true


func _dict(v: Variant) -> Dictionary:
	if v is Dictionary:
		return v
	return {}
