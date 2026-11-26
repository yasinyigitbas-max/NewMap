extends Node
## Input for the body, one sample per physics tick. Live from keyboard / gamepad, or replayed from a recorded tape,
## so the same run can be repeated exactly after every change.
## A sample: {mx, mz (stick, -1..1, mz < 0 is forward), yaw (camera heading, radians), run, jump, crouch, act}.

enum Mode { LIVE, RECORD, REPLAY }

var mode: Mode = Mode.LIVE
var tape: Array = []          # recorded samples
var start: Vector3 = Vector3.ZERO   # where the body stood when recording began
var cursor := 0
var live_yaw := 0.0           # set by the camera each frame
signal replay_finished


func _ready() -> void:
	_action(&"tl_left", [KEY_A, KEY_LEFT])
	_action(&"tl_right", [KEY_D, KEY_RIGHT])
	_action(&"tl_fwd", [KEY_W, KEY_UP])
	_action(&"tl_back", [KEY_S, KEY_DOWN])
	_action(&"tl_run", [KEY_SHIFT])
	_action(&"tl_jump", [KEY_SPACE])
	_action(&"tl_crouch", [KEY_C])
	_action(&"tl_act", [KEY_E])
	_axis(&"tl_left", JOY_AXIS_LEFT_X, -1.0)
	_axis(&"tl_right", JOY_AXIS_LEFT_X, 1.0)
	_axis(&"tl_fwd", JOY_AXIS_LEFT_Y, -1.0)
	_axis(&"tl_back", JOY_AXIS_LEFT_Y, 1.0)


func _action(name: StringName, keys: Array) -> void:
	if not InputMap.has_action(name):
		InputMap.add_action(name, 0.2)
	for k: int in keys:
		var ev := InputEventKey.new()
		ev.physical_keycode = k as Key
		InputMap.action_add_event(name, ev)


func _axis(name: StringName, axis: JoyAxis, value: float) -> void:
	var ev := InputEventJoypadMotion.new()
	ev.axis = axis
	ev.axis_value = value
	InputMap.action_add_event(name, ev)


## For the Stage 6 test ("Stage 1 tests pass in crouch"): every sample of a replayed tape is given with crouch held.
var hold_crouch := false


## Called once per physics tick by the body.
func sample() -> Dictionary:
	if mode == Mode.REPLAY:
		if cursor < tape.size():
			cursor += 1
			if hold_crouch:
				var low: Dictionary = (tape[cursor - 1] as Dictionary).duplicate()
				low["crouch"] = true
				return low
			return tape[cursor - 1]
		mode = Mode.LIVE
		replay_finished.emit()
	var v := Input.get_vector(&"tl_left", &"tl_right", &"tl_fwd", &"tl_back")
	var s := {"mx": v.x, "mz": v.y, "yaw": live_yaw, "run": Input.is_action_pressed(&"tl_run"),
			"jump": Input.is_action_pressed(&"tl_jump"), "crouch": Input.is_action_pressed(&"tl_crouch"),
			"act": Input.is_action_pressed(&"tl_act")}
	if mode == Mode.RECORD:
		tape.append(s)
	return s


func record_from(at: Vector3) -> void:
	tape = []
	start = at
	mode = Mode.RECORD


func stop() -> void:
	mode = Mode.LIVE


func replay() -> void:
	cursor = 0
	mode = Mode.REPLAY


func save(path: String) -> bool:
	DirAccess.make_dir_recursive_absolute(path.get_base_dir())
	var f := FileAccess.open(path, FileAccess.WRITE)
	if f == null:
		return false
	f.store_string(JSON.stringify({"start": [start.x, start.y, start.z], "tape": tape}))
	return true


func load_from(path: String) -> bool:
	if not FileAccess.file_exists(path):
		return false
	var d: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
	if typeof(d) != TYPE_DICTIONARY:
		return false
	var st: Array = d.get("start", [0, 0, 0])
	start = Vector3(st[0], st[1], st[2])
	tape = d.get("tape", [])
	return true


## A tape made in code (for tests): segments of [seconds, mx, mz, yaw_degrees, run].
func make(segments: Array, ticks_per_second := 60) -> void:
	tape = []
	for seg: Array in segments:
		for i in int(round(float(seg[0]) * ticks_per_second)):
			tape.append({"mx": float(seg[1]), "mz": float(seg[2]), "yaw": deg_to_rad(float(seg[3])),
					"run": bool(seg[4]), "jump": false, "crouch": false, "act": false})
