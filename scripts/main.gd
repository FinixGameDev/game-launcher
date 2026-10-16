extends Control
## Game Launcher main controller.
## The UI itself lives in main.tscn and scenes/*.tscn, styled by theme/launcher_theme.tres.
## This script handles config, controller input, launching games and coming back.

enum State { BROWSING, INFO, PLAYING, COOLDOWN }

const REPEAT_DELAY := 0.40
const REPEAT_RATE := 0.08
const SESSION_LOG := "user://sessions.csv"

## Texts shown by the launcher. Edit them in the Inspector of the Main node.
@export var hold_close_game_text := "Keep holding to close the game…"
@export var hold_quit_text := "Keep holding to quit the launcher…"
@export var forced_close_text := "%s was closed by the operator combo."
@export var instant_exit_text := "%s closed immediately.\nCheck the executable path and permissions."
@export var launch_failed_text := "Can't start %s\n%s"

@onready var _header: LauncherHeader = %Header
@onready var _list: GameList = %GameList
@onready var _details: GameDetails = %Details
@onready var _footer: LauncherFooter = %Footer
@onready var _toast: Toast = %Toast
@onready var _hold: HoldIndicator = %HoldIndicator
@onready var _info: InfoOverlay = %InfoOverlay
@onready var _playing: PlayingOverlay = %PlayingOverlay

var cfg := LauncherConfig.new()
var runner := GameRunner.new()
var state: State = State.BROWSING

var _hold_dir := 0
var _hold_time := 0.0
var _cooldown := 0.0
var _combo_lock := false
var _combo_held := 0.0
var _window_mode_before_launch: DisplayServer.WindowMode = DisplayServer.WINDOW_MODE_FULLSCREEN


func _ready() -> void:
	_setup_input()
	cfg.load_config()
	_apply_window_settings()

	_header.set_team(cfg.team_name, cfg.team_tagline, cfg.logo_texture, cfg.logo_hint)
	_footer.set_message(cfg.footer_text)

	add_child(runner)
	runner.game_started.connect(_on_game_started)
	runner.game_exited.connect(_on_game_exited)
	runner.launch_failed.connect(_on_launch_failed)

	_list.selection_changed.connect(_on_selection_changed)
	_list.set_items(cfg.games)

	if cfg.load_error != "":
		_toast.show_message(cfg.load_error, 10.0, true)


func _apply_window_settings() -> void:
	if OS.has_feature("editor"):
		return  # keep the editor's game window as-is while developing
	if cfg.fullscreen:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
	else:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
	if cfg.hide_mouse:
		Input.mouse_mode = Input.MOUSE_MODE_HIDDEN


func _on_selection_changed(index: int) -> void:
	var g := _list.current()
	if g == null:
		_details.show_empty()
	else:
		_details.show_game(g)
	_footer.set_counter(index, _list.items.size())


# ──────────────────────────────────────────────────────────────── input map

func _setup_input() -> void:
	_add_action("nav_up", [_key(KEY_UP), _joy_btn(JOY_BUTTON_DPAD_UP), _joy_axis(JOY_AXIS_LEFT_Y, -1.0)])
	_add_action("nav_down", [_key(KEY_DOWN), _joy_btn(JOY_BUTTON_DPAD_DOWN), _joy_axis(JOY_AXIS_LEFT_Y, 1.0)])
	_add_action("nav_page_up", [_key(KEY_LEFT), _key(KEY_PAGEUP), _joy_btn(JOY_BUTTON_DPAD_LEFT),
		_joy_btn(JOY_BUTTON_LEFT_SHOULDER), _joy_axis(JOY_AXIS_LEFT_X, -1.0)])
	_add_action("nav_page_down", [_key(KEY_RIGHT), _key(KEY_PAGEDOWN), _joy_btn(JOY_BUTTON_DPAD_RIGHT),
		_joy_btn(JOY_BUTTON_RIGHT_SHOULDER), _joy_axis(JOY_AXIS_LEFT_X, 1.0)])
	_add_action("nav_accept", [_key(KEY_ENTER), _key(KEY_KP_ENTER), _key(KEY_SPACE), _joy_btn(JOY_BUTTON_A)])
	_add_action("nav_back", [_key(KEY_ESCAPE), _joy_btn(JOY_BUTTON_B)])
	_add_action("nav_info", [_key(KEY_I), _joy_btn(JOY_BUTTON_Y)])
	_add_action("nav_reload", [_key(KEY_F5), _joy_btn(JOY_BUTTON_X)])


func _add_action(action: StringName, events: Array) -> void:
	if InputMap.has_action(action):
		InputMap.erase_action(action)
	InputMap.add_action(action, 0.5)
	for e in events:
		InputMap.action_add_event(action, e)


func _key(code: Key) -> InputEventKey:
	var e := InputEventKey.new()
	e.physical_keycode = code
	return e


func _joy_btn(button: JoyButton) -> InputEventJoypadButton:
	var e := InputEventJoypadButton.new()
	e.device = -1  # any controller
	e.button_index = button
	return e


func _joy_axis(axis: JoyAxis, value: float) -> InputEventJoypadMotion:
	var e := InputEventJoypadMotion.new()
	e.device = -1
	e.axis = axis
	e.axis_value = value
	return e


# ──────────────────────────────────────────────────────────────── input & loop

func _unhandled_input(event: InputEvent) -> void:
	if state == State.INFO:
		if event.is_action_pressed("nav_accept") or event.is_action_pressed("nav_back") or event.is_action_pressed("nav_info"):
			_set_info(false)
		return
	if state != State.BROWSING:
		return

	if event.is_action_pressed("nav_accept"):
		_launch_selected()
	elif event.is_action_pressed("nav_info"):
		_set_info(true)
	elif event.is_action_pressed("nav_page_up"):
		_list.page(-1)
	elif event.is_action_pressed("nav_page_down"):
		_list.page(1)
	elif event.is_action_pressed("nav_reload"):
		get_tree().reload_current_scene()


func _process(delta: float) -> void:
	_update_combo(delta)
	match state:
		State.BROWSING:
			_process_navigation(delta)
		State.COOLDOWN:
			_hold_dir = 0
			_cooldown -= delta
			if _cooldown <= 0.0:
				state = State.BROWSING
		_:
			_hold_dir = 0


func _process_navigation(delta: float) -> void:
	var dir := int(Input.is_action_pressed("nav_down")) - int(Input.is_action_pressed("nav_up"))
	if dir == 0:
		_hold_dir = 0
		return
	if dir != _hold_dir:
		_hold_dir = dir
		_hold_time = REPEAT_RATE - REPEAT_DELAY
		_list.move(dir)
	else:
		_hold_time += delta
		while _hold_time >= REPEAT_RATE:
			_hold_time -= REPEAT_RATE
			_list.move(dir)


func _set_info(show_it: bool) -> void:
	if show_it:
		var g := _list.current()
		if g == null:
			return
		_info.open(g, cfg.force_quit_hold)
		state = State.INFO
	else:
		_info.close()
		state = State.BROWSING


func _pad_combo(buttons: Array) -> bool:
	for pad in Input.get_connected_joypads():
		var all_down := true
		for b in buttons:
			if not Input.is_joy_button_pressed(pad, b):
				all_down = false
				break
		if all_down:
			return true
	return false


## Hold START+BACK to close a running game (best effort, see docs).
## Hold START+BACK+LB+RB (or Ctrl+Q) in the launcher to quit the launcher itself.
func _update_combo(delta: float) -> void:
	var pair := _pad_combo([JOY_BUTTON_START, JOY_BUTTON_BACK])
	var full := _pad_combo([JOY_BUTTON_START, JOY_BUTTON_BACK, JOY_BUTTON_LEFT_SHOULDER, JOY_BUTTON_RIGHT_SHOULDER])
	var keys := Input.is_key_pressed(KEY_CTRL) and Input.is_key_pressed(KEY_Q)

	if not (pair or keys):
		_combo_lock = false
		_combo_held = 0.0
		_hold.hide_progress()
		return
	if _combo_lock:
		return

	var killing := state == State.PLAYING
	var active := pair if killing else (full or keys)
	var needed := cfg.force_quit_hold if killing else cfg.operator_exit_hold
	if state == State.COOLDOWN or not active or needed <= 0.0:
		_combo_held = 0.0
		_hold.hide_progress()
		return

	_combo_held += delta
	if _combo_held > 0.3:
		_hold.show_progress(hold_close_game_text if killing else hold_quit_text, _combo_held / needed)
	if _combo_held >= needed:
		_combo_held = 0.0
		_combo_lock = true
		_hold.hide_progress()
		if killing:
			runner.kill_current()
		else:
			get_tree().quit()


# ──────────────────────────────────────────────────────────────── launching

func _launch_selected() -> void:
	var g := _list.current()
	if g != null:
		runner.launch(g)  # results come back through the runner's signals


func _on_game_started(game: GameEntry) -> void:
	state = State.PLAYING
	_playing.show_for(game)
	_window_mode_before_launch = DisplayServer.window_get_mode()
	if cfg.minimize_while_playing and not OS.has_feature("editor"):
		# Give the game a moment to open its window first, then get out of the way.
		await get_tree().create_timer(0.6).timeout
		if state == State.PLAYING:
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_MINIMIZED)


func _on_game_exited(game: GameEntry, duration: float, forced: bool) -> void:
	_log_session(game, duration, forced)

	if DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_MINIMIZED:
		DisplayServer.window_set_mode(_window_mode_before_launch)
	DisplayServer.window_move_to_foreground()
	DisplayServer.window_request_attention()
	get_window().grab_focus()

	_playing.dismiss()
	state = State.COOLDOWN  # swallow the button press that closed the game
	_cooldown = cfg.return_cooldown
	_combo_lock = true

	if forced:
		_toast.show_message(forced_close_text % game.title, 3.0)
	elif duration < 2.0:
		_toast.show_message(instant_exit_text % game.title, 6.0, true)


func _on_launch_failed(game: GameEntry, reason: String) -> void:
	_toast.show_message(launch_failed_text % [game.title, reason], 6.0, true)


func _log_session(game: GameEntry, duration: float, forced: bool) -> void:
	var is_new := not FileAccess.file_exists(SESSION_LOG)
	var f := FileAccess.open(SESSION_LOG, FileAccess.WRITE if is_new else FileAccess.READ_WRITE)
	if f == null:
		return
	if is_new:
		f.store_csv_line(PackedStringArray(["timestamp", "game_id", "title", "duration_seconds", "force_closed"]))
	else:
		f.seek_end()
	f.store_csv_line(PackedStringArray([
		Time.get_datetime_string_from_system(), game.id, game.title, "%.0f" % duration, str(forced)]))
	f.close()
