extends Node3D
## The lab scene: the course, a body, a follow camera, the readout and the input tape.

const Course := preload("res://traversal/course/course.gd")
const Readout := preload("res://traversal/debug/readout.gd")
const Tape := preload("res://traversal/debug/input_tape.gd")
const PlainBody := preload("res://traversal/debug/plain_body.gd")
const Body := preload("res://traversal/body/body.gd")
const Character := preload("res://traversal/character/character.gd")
const CharacterV1 := preload("res://traversal/character/character_v1.gd")       # the code-posed one, kept to compare: -- --v1
const Traverse := preload("res://traversal/moves/traverse.gd")
const Interact := preload("res://traversal/moves/interact.gd")
const DetectView := preload("res://traversal/detect/detect_view.gd")
const TAPE_FILE := "user://tapes/last.json"

var course: Node3D
var body: CharacterBody3D
var character: Node3D
var tape: Node
var readout: CanvasLayer
var detect: Node3D
var traverse: Node
var interact: Node              # doors, cars, sitting (see interact.gd)
var cam: Camera3D
var station := 0
var _yaw := 0.0
var _pitch := -0.25
var _dist := 4.5


func _ready() -> void:
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-50, -30, 0)
	sun.shadow_enabled = true
	add_child(sun)
	var env := WorldEnvironment.new()
	env.environment = Environment.new()
	env.environment.background_mode = Environment.BG_COLOR
	env.environment.background_color = Color(0.55, 0.68, 0.82)
	env.environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.environment.ambient_light_color = Color(0.7, 0.7, 0.75)
	env.environment.ambient_light_energy = 0.6
	add_child(env)
	course = Course.new()
	course.name = "Course"
	add_child(course)
	tape = Tape.new()
	tape.name = "Tape"
	add_child(tape)
	body = make_body()
	body.name = "Body"
	body.set(&"tape", tape)
	add_child(body)
	if body.has_method(&"show_capsule") and not ("--capsule" in OS.get_cmdline_user_args()):
		character = CharacterV1.new() if "--v1" in OS.get_cmdline_user_args() else Character.new()
		# (`-- --native`: the character translated to C++, native/traversal, where its library has been built)
		if "--native" in OS.get_cmdline_user_args() and not ("--v1" in OS.get_cmdline_user_args()) and ClassDB.class_exists(&"TravCharacter"):
			character.free()
			character = ClassDB.instantiate(&"TravCharacter")
		for arg in OS.get_cmdline_user_args():
			if arg.begins_with("--npc="):
				character.free()
				character = (load("res://traversal/npc/npc_character.gd") as GDScript).new()
		character.name = "Character"
		character.set(&"body", body)
		# `-- --npc=npc_01`: the trial NPC body in the player's place (Yasin, 27 Nov: "yes go on, and make it")
		for arg in OS.get_cmdline_user_args():
			if arg.begins_with("--npc="):
				character.set(&"model_path", "res://traversal/npc/%s.scn" % arg.trim_prefix("--npc="))
		body.add_child(character)
		body.call(&"show_capsule", false)
	if body.has_method(&"begin_move"):
		# Stage 8 onward: the traversal moves
		# (before the traversal moves, so that a door he walks at is opened, not taken for a wall)
		interact = Interact.new()
		interact.name = "Interact"
		interact.set(&"body", body)
		body.add_child(interact)
		traverse = Traverse.new()
		traverse.name = "Traverse"
		traverse.set(&"body", body)
		body.add_child(traverse)
	if body.has_method(&"can_stand"):
		# Stage 7: the detection record, measured and drawn (nothing is played from it yet)
		detect = DetectView.new()
		detect.name = "DetectView"
		detect.set(&"body", body)
		add_child(detect)
	cam = Camera3D.new()
	cam.fov = 65.0
	add_child(cam)
	readout = Readout.new()
	readout.set(&"body", body)
	readout.set(&"tape", tape)
	add_child(readout)
	go_to(0)
	if DisplayServer.get_name() != "headless":
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED


## Which body the lab runs. Later stages swap this for the real one.
func make_body() -> CharacterBody3D:
	if "--plain" in OS.get_cmdline_user_args():
		return PlainBody.new()
	# `-- --native`: the body translated to C++ (native/traversal, TravBody), where its library has been built. The
	# script body stays the default until Yasin has play-tested the C++ one (27 Nov: "make all the code c plus plus
	# and make god damn sure nothing ever breaks").
	if "--native" in OS.get_cmdline_user_args() and ClassDB.class_exists(&"TravBody"):
		return ClassDB.instantiate(&"TravBody")
	return Body.new()


func go_to(i: int) -> void:
	var st: Array = (course.get(&"stations") as Array) + (course.get(&"extras") as Array)
	station = posmod(i, st.size())
	var s: Dictionary = st[station]
	place(s["start"])
	body.rotation.y = 0.0
	_yaw = 0.0
	readout.set(&"station_label", "%d / %d   %s" % [station + 1, st.size(), s["label"]])
	readout.call(&"reset_marks")


func place(at: Vector3) -> void:
	if body.has_method(&"place"):
		body.call(&"place", at)
	else:
		body.global_position = at
		body.velocity = Vector3.ZERO


func _unhandled_input(ev: InputEvent) -> void:
	if ev is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		_yaw -= ev.relative.x * 0.004
		_pitch = clampf(_pitch - ev.relative.y * 0.004, -1.2, 0.6)
	elif ev is InputEventKey and ev.pressed and not ev.echo:
		match ev.physical_keycode:
			KEY_BRACKETRIGHT: go_to(station + 1)
			KEY_BRACKETLEFT: go_to(station - 1)
			KEY_R: go_to(station)
			KEY_F5: tape.call(&"record_from", body.global_position)
			KEY_F6: tape.call(&"stop")
			KEY_F7:
				place(tape.get(&"start"))
				readout.call(&"reset_marks")
				tape.call(&"replay")
			KEY_F8: tape.call(&"save", TAPE_FILE)
			KEY_F9: tape.call(&"load_from", TAPE_FILE)
			KEY_ESCAPE:
				Input.mouse_mode = Input.MOUSE_MODE_VISIBLE if Input.mouse_mode == Input.MOUSE_MODE_CAPTURED else Input.MOUSE_MODE_CAPTURED


func _process(_dt: float) -> void:
	tape.set(&"live_yaw", _yaw)
	var target := body.global_position + Vector3(0, 1.4, 0)
	var back := Vector3(0, 0, 1).rotated(Vector3.RIGHT, _pitch).rotated(Vector3.UP, _yaw)
	cam.global_position = target + back * _dist
	cam.look_at(target)
