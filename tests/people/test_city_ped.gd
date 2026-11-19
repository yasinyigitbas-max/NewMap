extends SceneTree
## One person with a real body (C++ class CityPed: native/src/city_ped.*, ped_body.*) on the engine, headless:
##   godot --headless --fixed-fps 60 --path . -s res://tests/people/test_city_ped.gd [-- --body=M1]
## This script only makes a floor and the person, pushes it at the start of each part, moves a box (a car) and prints
## what the person reports. Parts: it stands in its idle animation (50 bones, a person's height, feet on the floor);
## a shove of 60 N s (the body takes over where the bones were: no jump; it staggers, stays up, and the animation
## takes over again at its old height); a charge of 420 N s (it goes down, lies still, gets up, stands again); a car
## at 30 km/h (down, still, up again). It checks numbers; how it LOOKS needs a picture or the game.
var ped: Node3D
var t := 0.0
var phase := 0
var t0 := 0.0
var fails := 0
var h0 := 0.0
var steps_most := 0
var lean_most := 0.0
var low_head := 9.0
var car_z := 0.0
var bad_bones := false
var body_id := "M1"
var seen := {}

func _initialize() -> void:
	for a: String in OS.get_cmdline_user_args():
		if a.begins_with("--body="): body_id = a.trim_prefix("--body=")
	if not ClassDB.class_exists(&"CityPed"):
		print("PED ERROR the native module is not built: run  bash native/build.sh"); print("RESULT FAIL"); quit(1); return
	var b := StaticBody3D.new(); var cs := CollisionShape3D.new(); var sh := BoxShape3D.new()
	sh.size = Vector3(400, 2, 400); cs.shape = sh; b.add_child(cs); b.position = Vector3(0, -1, 0); root.add_child(b)
	ped = ClassDB.instantiate(&"CityPed")
	ped.set(&"body_id", body_id)
	root.add_child(ped)
	print("PED engine test: body %s" % body_id)

func _check(ok: bool, what: String) -> void:
	if not ok: fails += 1
	print("PED   %s: %s" % ["ok" if ok else "FAIL", what])

func _physics_process(delta: float) -> bool:
	if ped == null: return true
	t += delta
	var s: Dictionary = ped.call(&"get_state")
	if not bool(s.get("bones_fine", false)): bad_bones = true
	steps_most = maxi(steps_most, int(s.steps)); lean_most = maxf(lean_most, float(s.lean_deg))
	var head: Vector3 = s.get("head", Vector3.ZERO)
	low_head = minf(low_head, head.y)
	seen[int(s.mode) * 10 + int(s.state)] = true
	match phase:
		0:
			if t > 1.0:
				h0 = head.y
				var fl: Vector3 = s.foot_l; var fr: Vector3 = s.foot_r
				_check(int(s.bones) == 50 and int(s.mode) == 0 and h0 > 1.4 and h0 < 1.85 and fl.y > -0.02 and fl.y < 0.2 and absf(fl.x - fr.x) > 0.1,
					"stands in its animation: 50 bones, head joint %.2f m up, feet %.2f and %.2f m up, %.2f m apart" % [h0, fl.y, fr.y, absf(fl.x - fr.x)])
				ped.call(&"push", Vector3(0, 0, 60), ped.global_position + Vector3(0, 1.3, 0))
				phase = 1; t0 = t; steps_most = 0; lean_most = 0.0
		1:
			if t - t0 > 0.02 and not seen.has(-1):
				seen[-1] = true
				_check(float(s.jump_at_takeover) < 0.02, "the body takes over where the bones were: the most a bone of the trunk, head or arms moved is %.3f m" % float(s.jump_at_takeover))
			if (int(s.mode) == 0 and t - t0 > 1.5) or t - t0 > 9.0:
				phase = 2; t0 = t
		2:
			if t - t0 > 1.0:
				_check(int(s.mode) == 0 and int(s.falls) == 0 and absf(head.y - h0) < 0.12,
					"a shove of 60 N s from behind: %d steps, leaned %.0f degrees at most, did not fall, moved %.2f m; the animation took over again, head joint at %.2f m (was %.2f)" % [steps_most, lean_most, ped.global_position.length(), head.y, h0])
				ped.call(&"push", Vector3(0, 0, 420), ped.global_position + Vector3(0, 1.3, 0))
				phase = 3; t0 = t; low_head = 9.0
		3:
			if (int(s.mode) == 0 and t - t0 > 2.0) or t - t0 > 18.0:
				phase = 4; t0 = t
		4:
			if t - t0 > 1.0:
				_check(int(s.mode) == 0 and int(s.falls) == 1 and int(s.getups) == 1 and low_head < 0.5 and absf(head.y - h0) < 0.15,
					"a charge of 420 N s: went down (head joint as low as %.2f m), lay still, got up %d time, stands again with its head joint at %.2f m; fastest part %.1f m/s" % [low_head, int(s.getups), head.y, float(s.fastest_part)])
				car_z = ped.global_position.z - 8.0
				phase = 5; t0 = t; low_head = 9.0
		5:
			# a car, 30 km/h, along +z through where the person stands, braking after it
			var cv := 8.3 if car_z < ped.global_position.z + 6.0 or t - t0 < 1.0 else 0.0
			if t - t0 < 4.0: car_z += cv * delta
			ped.call(&"set_box", 0, Vector3(ped.global_position.x if t - t0 < 0.05 else float(seen.get(-2, 0.0)), 0.85, car_z), Vector3(0.95, 0.65, 2.3), 0.0, Vector3(0, 0, cv if t - t0 < 4.0 else 0.0), 1)
			if not seen.has(-2): seen[-2] = ped.global_position.x
			if (int(s.mode) == 0 and int(s.getups) == 2 and t - t0 > 3.0) or t - t0 > 22.0:
				ped.call(&"set_box", 0, Vector3(0, -50, 0), Vector3(0.1, 0.1, 0.1), 0.0, Vector3.ZERO, 0)
				phase = 6; t0 = t
		6:
			if t - t0 > 1.0:
				_check(int(s.mode) == 0 and int(s.falls) == 2 and int(s.getups) == 2 and low_head < 0.6 and absf(head.y - h0) < 0.15,
					"a car at 30 km/h: knocked down (head joint as low as %.2f m), got up again (%d falls, %d times up), head joint at %.2f m" % [low_head, int(s.falls), int(s.getups), head.y])
				_check(not bad_bones, "no bone ever had a wild number")
				print("RESULT %s" % ("PASS" if fails == 0 else "FAIL (%d)" % fails))
				quit(0 if fails == 0 else 1)
				return true
	return false
