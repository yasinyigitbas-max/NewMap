extends SceneTree
## The player on foot in water (C++ class CityPlayer: property water_y), headless:
##   godot --headless --fixed-fps 60 --path . -s res://tests/people/test_swim.gd
## A beach made of one sloping slab (1 in 6) into water whose surface is at y = 0. He walks down it: where the water
## is deeper than his chest he swims at the surface (the Quaternius swimming clip), goes on a while, turns back, and
## where the ground comes up he stands up and walks out. This script sets the slab up and reads where he is.
var player: Node3D
var t := 0.0
var step := 0
var t0 := 0.0
var fails := 0
var swam_m := 0.0
var last := Vector3.ZERO
var y_swim_lo := 9.0
var y_swim_hi := -9.0
var clips := {}

func _initialize() -> void:
	if not ClassDB.class_exists(&"CityPlayer"):
		print("SWIM ERROR the native module is not built"); print("RESULT FAIL"); quit(1); return
	var slab := StaticBody3D.new(); var cs := CollisionShape3D.new(); var sh := BoxShape3D.new()
	sh.size = Vector3(80, 1, 20); cs.shape = sh; slab.add_child(cs)
	slab.rotation.z = -atan(1.0 / 6.0)      # it falls toward +x
	slab.position = Vector3(0, -0.5, 0)        # its top crosses the water's surface near x = 0
	root.add_child(slab)
	player = ClassDB.instantiate(&"CityPlayer")
	player.set(&"water_y", 0.0)
	player.position = Vector3(-6.0, 1.3, 0)
	root.add_child(player)
	last = player.position

func _check(ok: bool, what: String) -> void:
	if not ok: fails += 1
	print("SWIM   %s: %s" % ["ok" if ok else "FAIL", what])

func _go(dir: Vector3, run: bool) -> void:      # (walk that way in the world, whatever the camera looks at)
	var cam: Camera3D = root.get_viewport().get_camera_3d()
	var f := -cam.global_basis.z; f.y = 0; f = f.normalized()
	var r := Vector3(-f.z, 0, f.x)
	player.call(&"set_move", Vector2(dir.dot(r), dir.dot(f)), run)

func _physics_process(delta: float) -> bool:
	if player == null: return true
	t += delta
	var p: Vector3 = player.global_position
	var swimming: bool = player.call(&"is_swimming")
	if swimming:
		swam_m += Vector2(p.x - last.x, p.z - last.z).length()
		if step == 2 and t - t0 > 1.5: y_swim_lo = minf(y_swim_lo, p.y); y_swim_hi = maxf(y_swim_hi, p.y)      # (once he has floated up)
	clips[String(player.call(&"get_clip")).trim_prefix("ual/")] = true
	last = p
	match step:
		0:
			if t < 1.0: return false
			_check(not swimming and absf(p.y - 0.5) < 0.6, "he stands on the beach above the water (%.2f m over it)" % p.y)
			_go(Vector3(1, 0, 0), false); step = 1; t0 = t
		1:      # down the slope into the water, until he swims; then on for six seconds
			if not swimming and t - t0 < 30.0: return false
			_check(swimming and p.x > 5.0, "walking in, he swims from where the water is deeper than his chest (%.1f m out, the ground %.2f m under the surface there)" % [p.x, p.x / 6.0])
			step = 2; t0 = t
		2:
			if t - t0 < 6.0: return false
			_check(swimming and swam_m > 4.0 and y_swim_lo > -0.6 and y_swim_hi < -0.15 and clips.has("Swim_Fwd_Loop"), "he swims on at the surface: %.1f m in 6 s, his body %.2f to %.2f m under it, the swimming clip plays" % [swam_m, -y_swim_hi, -y_swim_lo])
			player.call(&"set_move", Vector2.ZERO, false); step = 3; t0 = t
		3:
			if t - t0 < 2.0: return false
			_check(swimming and float(player.call(&"get_speed")) < 0.2 and String(player.call(&"get_clip")) == "ual/Swim_Idle_Loop", "left alone he floats where he is (%.2f m/s, %s)" % [float(player.call(&"get_speed")), String(player.call(&"get_clip"))])
			_go(Vector3(-1, 0, 0), true); step = 4; t0 = t
		4:      # back to the beach: he stands up where it gets shallow, and walks out
			if (swimming or p.y < 0.3) and t - t0 < 40.0: return false
			_check(not swimming and p.y >= 0.3 and p.x < 0.0, "swimming back, he stands up where the ground comes up and walks out of the water (now %.2f m over it, %s)" % [p.y, String(player.call(&"get_clip"))])
			step = 9
		9:
			print("RESULT %s" % ("PASS" if fails == 0 else "FAIL (%d)" % fails))
			quit(1 if fails else 0)
			return true
	return false
