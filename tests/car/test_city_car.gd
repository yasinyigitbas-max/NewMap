extends SceneTree
## The drivable car (C++ class CityCar: native/src/city_car.*, veh_dyn.*) on the engine's physics, headless:
##   godot --headless --fixed-fps 60 --path . -s res://tests/car/test_city_car.gd [-- --model=2 --feel=0]
## This script only builds a flat ground and a wall, presses the pedals at the start of each part and prints what the
## car reports; every force is worked out in C++. Parts: stand still, 0-100 km/h, 100-0, drive into a wall at about
## 65 km/h (must stop at it, stay on its wheels' side of the ground, no wild numbers), back away in reverse.
## It prints the console test's numbers for the same car beside its own (native/tests/run_veh_test.sh): they must agree.
const NAMES := ["stern_e", "volt_s", "stern_g", "volt_x", "sakura_t", "sakura", "van", "fiamma_r", "fiamma_gt", "taxi", "bus_city", "bus_mini"]
var car: Node3D
var t := 0.0
var phase := 0
var t0 := 0.0
var p0 := Vector3.ZERO
var wall_z := 0.0
var r := {}
var model := 2
var feel := 0
var fails := 0

func _initialize() -> void:
	for a: String in OS.get_cmdline_user_args():
		if a.begins_with("--model="): model = int(a.trim_prefix("--model="))
		if a.begins_with("--feel="): feel = int(a.trim_prefix("--feel="))
	if not ClassDB.class_exists(&"CityCar"):
		print("CAR ERROR the native module is not built: run  bash native/build.sh"); print("RESULT FAIL"); quit(1); return
	_box(Vector3(0, -1, 1500), Vector3(400, 2, 4000))
	car = ClassDB.instantiate(&"CityCar")
	car.set(&"model", model); car.set(&"feel", feel)
	car.position = Vector3(0, 0.03, 0)
	root.add_child(car)
	print("CAR engine test: %s, feel %s, physics engine '%s', %d physics steps a second" % [NAMES[model], "IV" if feel == 0 else "V", String(ProjectSettings.get_setting_with_override("physics/3d/physics_engine")), Engine.physics_ticks_per_second])

func _box(at: Vector3, size: Vector3) -> void:
	var b := StaticBody3D.new(); var cs := CollisionShape3D.new(); var sh := BoxShape3D.new()
	sh.size = size; cs.shape = sh; b.add_child(cs); b.position = at; root.add_child(b)

func _check(ok: bool, what: String) -> void:
	if not ok: fails += 1
	print("CAR   %s: %s" % ["ok" if ok else "FAIL", what])

func _physics_process(delta: float) -> bool:
	if car == null: return true
	t += delta
	var s: Dictionary = car.call(&"get_state")
	var p: Vector3 = car.global_position
	match phase:
		0:
			car.call(&"set_controls", 0.0, 1.0, 0.0, 0.0, false)
			if t > 3.0:
				print("CAR   the model's own wheels: wheelbase %.2f m, track %.2f m, wheel radius %.2f m, %d kg" % [float(s.wheelbase), float(s.track), float(s.wheel_r), int(s.mass)])
				_check(absf(p.y) < 0.03 and absf(float(s.speed)) < 0.02 and int(s.wheels_on_ground) == 4, "stands still on its four wheels (height %.3f m, speed %.3f m/s, wheels on the ground %d)" % [p.y, float(s.speed), int(s.wheels_on_ground)])
				phase = 1; t0 = t; p0 = p
		1:
			car.call(&"set_controls", 1.0, 0.0, 0.0, 0.0, false)
			if float(s.kmh) >= 100.0 or t - t0 > 60.0:
				r.t100 = t - t0
				_check(float(s.kmh) >= 100.0 and absf(p.x) < 1.5, "0-100 km/h in %.1f s over %.0f m, %.2f m off its straight line, gear %d at %d revs" % [r.t100, p.z - p0.z, p.x, int(s.gear), int(s.rpm)])
				phase = 2; t0 = t; p0 = p
		2:
			car.call(&"set_controls", 0.0, 1.0, 0.0, 0.0, false)
			if absf(float(s.speed)) < 0.3 or t - t0 > 30.0:
				r.brake_m = p.z - p0.z
				_check(r.brake_m > 28.0 and r.brake_m < (95.0 if model >= 10 else 62.0), "100-0 in %.1f m, %.1f s" % [r.brake_m, t - t0])
				phase = 3; t0 = t; p0 = p
				wall_z = p.z + 95.0
				_box(Vector3(0, 3, wall_z + 1.0), Vector3(60, 6, 2))
				r.vmax = 0.0
		3:
			car.call(&"set_controls", 1.0 if float(s.kmh) < 66.0 else 0.2, 0.0, 0.0, 0.0, false)
			r.vmax = maxf(r.vmax, float(s.kmh))
			if float(s.hardest_knock_g) > 2.5 or t - t0 > 40.0:
				phase = 4; t0 = t
		4:
			car.call(&"set_controls", 0.0, 1.0, 0.0, 0.0, false)
			if t - t0 > 2.5:
				var up: Vector3 = car.global_transform.basis.y
				var fine: bool = is_finite(p.x) and is_finite(p.y) and is_finite(p.z)
				_check(fine and p.z < wall_z and p.y > -0.3 and p.y < 1.5 and absf(float(s.speed)) < 3.0 and up.y > 0.7,
					"into a wall at %.0f km/h: a knock of %.0f g, it stands %.1f m before the wall, %.2f m above the ground, upright %.2f, speed %.1f m/s" % [float(r.vmax), float(s.hardest_knock_g), wall_z - p.z, p.y, up.y, float(s.speed)])
				phase = 5; t0 = t; p0 = p
		5:
			car.call(&"set_controls", 0.7, 0.0, 0.0, 0.0, true)
			if t - t0 > 3.5:
				_check(p0.z - p.z > 2.0 and float(s.speed) < -0.5, "backs away in reverse: %.1f m in 3.5 s" % (p0.z - p.z))
				print("RESULT %s" % ("PASS" if fails == 0 else "FAIL (%d)" % fails))
				quit(0 if fails == 0 else 1)
				return true
	return false
