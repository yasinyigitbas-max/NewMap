extends SceneTree
## Touch driving of the drivable car (20 Nov, Yasin: "Make the car drivable on touchscreen"; C++: CityCar::_input).
##   godot --headless --fixed-fps 60 --path . -s res://tests/car/test_touch_car.gd
## Flat ground, a player car, and screen touches handed to the engine as a phone would: a thumb on GAS (right quarter),
## a thumb on the left half sliding left (steer left), then BRAKE (inner right quarter), then a stop. Checks the car
## speeds up, turns the way the thumb slid, and slows down again. Prints RESULT PASS / FAIL.
var car: Node3D
var t := 0.0
var phase := 0
var fails := 0
var yaw0 := 0.0
var kmh_peak := 0.0
var sz := Vector2.ZERO

func _initialize() -> void:
	if not ClassDB.class_exists(&"CityCar"):
		print("TOUCH ERROR the native module is not built: run  bash native/build.sh"); print("RESULT FAIL"); quit(1); return
	var b := StaticBody3D.new(); var cs := CollisionShape3D.new(); var sh := BoxShape3D.new()
	sh.size = Vector3(800, 2, 800); cs.shape = sh; b.add_child(cs); b.position = Vector3(0, -1, 0); root.add_child(b)
	car = ClassDB.instantiate(&"CityCar")
	car.set(&"model", 2); car.set(&"player", true)
	car.position = Vector3(0, 0.03, 0)
	root.add_child(car)
	sz = root.get_visible_rect().size
	print("TOUCH screen %dx%d" % [int(sz.x), int(sz.y)])

func _touch(idx: int, at: Vector2, down: bool) -> void:
	var e := InputEventScreenTouch.new(); e.index = idx; e.position = at; e.pressed = down
	Input.parse_input_event(e)

func _drag(idx: int, at: Vector2) -> void:
	var e := InputEventScreenDrag.new(); e.index = idx; e.position = at
	Input.parse_input_event(e)

func _check(ok: bool, what: String) -> void:
	if not ok: fails += 1
	print("TOUCH   %s: %s" % ["ok" if ok else "FAIL", what])

func _physics_process(delta: float) -> bool:
	if car == null: return true
	t += delta
	var s: Dictionary = car.call(&"get_state")
	var kmh := absf(float(s.kmh))
	match phase:
		0:
			if t > 1.5:
				_touch(1, Vector2(sz.x * 0.9, sz.y * 0.8), true)      # GAS
				phase = 1; t = 0.0
		1:
			if t > 4.0:
				_check(kmh > 25.0, "gas held 4 s: %.0f km/h" % kmh)
				yaw0 = (car as Node3D).global_rotation.y
				_touch(0, Vector2(sz.x * 0.25, sz.y * 0.8), true)     # a thumb on the left half ...
				_drag(0, Vector2(sz.x * 0.25 - sz.x * 0.12, sz.y * 0.8))  # ... slid left
				phase = 2; t = 0.0
		2:
			if t > 1.5:
				var dy := wrapf((car as Node3D).global_rotation.y - yaw0, -PI, PI)
				_check(dy > 0.15, "thumb slid left 1.5 s: the car turned %.0f degrees (+ = left)" % rad_to_deg(dy))
				_touch(0, Vector2(sz.x * 0.13, sz.y * 0.8), false)
				_touch(1, Vector2(sz.x * 0.9, sz.y * 0.8), false)
				kmh_peak = kmh
				_touch(2, Vector2(sz.x * 0.6, sz.y * 0.8), true)      # BRAKE
				phase = 3; t = 0.0
		3:
			if t > 2.5:
				_check(kmh < kmh_peak * 0.5, "brake held 2.5 s: %.0f -> %.0f km/h" % [kmh_peak, kmh])
				_touch(2, Vector2(sz.x * 0.6, sz.y * 0.8), false)
				print("RESULT %s" % ("PASS" if fails == 0 else "FAIL"))
				quit(0 if fails == 0 else 1)
	return false
