extends RefCounted
## Persistent state of breakable doors and windows (22 Nov, built-in interiors pilot). One dictionary for the whole game,
## keyed by the node's stable id (meta "bid": "<building>|<node name>"), saved to user://breakables.json on every change
## so a broken window stays broken across streaming (the room is freed beyond CityRooms.SLEEP_M and comes back) and
## across sessions. The game's save system can take over by reading / writing `states` directly.
const PATH := "user://breakables.json"
static var states := {}
static var _loaded := false

static func _load() -> void:
	if _loaded: return
	_loaded = true
	if FileAccess.file_exists(PATH):
		var v: Variant = JSON.parse_string(FileAccess.get_file_as_string(PATH))
		if v is Dictionary: states = v

static func get_state(id: String, default := {}) -> Dictionary:
	_load()
	return (states.get(id, default) as Dictionary).duplicate()

static func set_state(id: String, st: Dictionary) -> void:
	_load()
	states[id] = st
	var f := FileAccess.open(PATH, FileAccess.WRITE)
	if f: f.store_string(JSON.stringify(states))

static func clear_all() -> void:
	states = {}; _loaded = true
	if FileAccess.file_exists(PATH): DirAccess.remove_absolute(ProjectSettings.globalize_path(PATH))
