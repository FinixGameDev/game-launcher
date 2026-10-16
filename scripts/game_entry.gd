class_name GameEntry
extends RefCounted
## One game in the launcher. Built from an entry in launcher_config.json.

var id := ""
var title := "Untitled"
var description := ""
var developer := ""
var players := ""
var genre := ""
var version := ""
var controls := ""
var executable := ""            # Resolved for the current OS
var args: PackedStringArray = PackedStringArray()
var texture: Texture2D = null
var available := false          # Executable found on this machine?


static func from_dict(d: Dictionary, base_dir: String) -> GameEntry:
	var g := GameEntry.new()
	g.title = str(d.get("title", "Untitled"))
	g.id = str(d.get("id", g.title.to_snake_case()))
	g.description = str(d.get("description", ""))
	g.developer = str(d.get("developer", ""))
	g.players = str(d.get("players", ""))
	g.genre = str(d.get("genre", ""))
	g.version = str(d.get("version", ""))
	g.controls = str(d.get("controls", ""))

	var raw_args: Variant = d.get("args", [])
	if raw_args is Array:
		for a in raw_args:
			g.args.append(str(a))

	g.executable = _resolve_executable(d.get("executable", ""), base_dir)
	g.available = _check_available(g.executable)

	var thumb := str(d.get("thumbnail", ""))
	if thumb != "":
		g.texture = load_texture(_resolve_file(thumb, base_dir))
	return g


static func _os_key() -> String:
	match OS.get_name():
		"Windows":
			return "windows"
		"macOS":
			return "macos"
		_:
			return "linux"


static func _resolve_file(path: String, base_dir: String) -> String:
	if path.is_absolute_path():
		return path
	return base_dir.path_join(path).simplify_path()


static func _resolve_executable(value: Variant, base_dir: String) -> String:
	var path := ""
	if value is Dictionary:
		var key := _os_key()
		for k in value.keys():
			if str(k).to_lower() == key:
				path = str(value[k])
	else:
		path = str(value)
	if path.is_empty():
		return ""
	if path.is_absolute_path():
		return path
	# A bare command name (no slashes) is looked up on the system PATH by the OS.
	if not (path.contains("/") or path.contains("\\")):
		return path
	return base_dir.path_join(path).simplify_path()


static func _check_available(exe: String) -> bool:
	if exe.is_empty():
		return false
	if not (exe.contains("/") or exe.contains("\\")):
		return true  # bare command, can't verify
	return FileAccess.file_exists(exe) or DirAccess.dir_exists_absolute(exe)  # dir = macOS .app


static func load_texture(path: String) -> Texture2D:
	if not FileAccess.file_exists(path):
		return null
	var img := Image.load_from_file(path)
	if img == null or img.is_empty():
		return null
	return ImageTexture.create_from_image(img)
