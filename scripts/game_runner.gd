class_name GameRunner
extends Node
## Starts an external game process and reports when it exits.

signal game_started(game: GameEntry)
signal game_exited(game: GameEntry, duration_seconds: float, forced: bool)
signal launch_failed(game: GameEntry, reason: String)

var current: GameEntry = null
var pid := -1

var _start_msec := 0
var _forced := false


func is_running() -> bool:
	return pid > 0


func launch(game: GameEntry) -> bool:
	if is_running():
		return false
	if not game.available:
		launch_failed.emit(game, "Executable not found:\n%s" % game.executable)
		return false

	var exe := game.executable
	var args := PackedStringArray()
	args.append_array(game.args)

	# macOS .app bundles must be started through `open`; -W makes it wait until the app quits.
	if OS.get_name() == "macOS" and exe.to_lower().ends_with(".app"):
		var open_args := PackedStringArray(["-W", "-n", exe, "--args"])
		open_args.append_array(args)
		exe = "/usr/bin/open"
		args = open_args

	var new_pid := OS.create_process(exe, args)
	if new_pid <= 0:
		launch_failed.emit(game, "The OS refused to start:\n%s" % game.executable)
		return false

	pid = new_pid
	current = game
	_forced = false
	_start_msec = Time.get_ticks_msec()
	game_started.emit(game)
	return true


func kill_current() -> void:
	if pid > 0:
		_forced = true
		OS.kill(pid)


func _process(_delta: float) -> void:
	if pid > 0 and not OS.is_process_running(pid):
		var game := current
		var duration := (Time.get_ticks_msec() - _start_msec) / 1000.0
		var forced := _forced
		pid = -1
		current = null
		_forced = false
		game_exited.emit(game, duration, forced)
