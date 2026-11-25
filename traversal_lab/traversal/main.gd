extends Node3D
## The lab scene: the course, a body, a follow camera, the readout and the input tape.

const Course := preload("res://traversal/course/course.gd")
const Readout := preload("res://traversal/debug/readout.gd")
const Tape := preload("res://traversal/debug/input_tape.gd")
const PlainBody := preload("res://traversal/debug/plain_body.gd")
const TAPE_FILE := "user://tapes/last.json"

var course: Node3D
var body: CharacterBody3D
var tape: Node
var readout: CanvasLayer
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
	return PlainBody.new()


func go_to(i: int) -> void:
	var st: Array = course.get(&"stations")
	station = posmod(i, st.size())
	var s: Dictionary = st[station]
	body.global_position = s["start"]
	body.velocity = Vector3.ZERO
	body.rotation.y = 0.0
	_yaw = 0.0
	readout.set(&"station_label", "%d / %d   %s" % [station + 1, st.size(), s["label"]])
	readout.call(&"reset_marks")


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
				body.global_position = tape.get(&"start")
				body.velocity = Vector3.ZERO
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
