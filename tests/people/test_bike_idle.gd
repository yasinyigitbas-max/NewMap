extends SceneTree
## Standing still on the bicycle (C++: CityBike's foot_down, BikeReach; Yasin, 20 Nov: "bike riders need idle on the bike
## animation with one leg down and seamlessly transition into riding again after movement is detected"), in a window:
##   godot --path . --rendering-method mobile --resolution 960x540 --fixed-fps 60 -s res://tests/people/test_bike_idle.gd
## He gets on, rides 3 s, brakes to a stop and lets go: the left foot comes down to the ground, the bike tips onto it.
## Then he pedals again: the foot goes back to its pedal and the bike rolls. Checks: standing, the left foot on the ground
## (within 4 cm of its spot) and the bike tipped 4-9 degrees; pedalling, the foot back on the pedal within 0.35 s, the bike
## rolling; the left foot never jumps more than 4 cm in a frame on the way down or up. Pictures OUT/bike_idle_*.png.
var player: Node3D
var bike: RigidBody3D
var cam: Camera3D
var t := 0.0
var t0 := 0.0
var step := 0
var fails := 0
var prev_foot := Vector3.INF
var jump_most := 0.0
var t_up := -1.0

func _check(ok: bool, what: String) -> void:
	if not ok: fails += 1
	print("BIKEIDLE   %s: %s" % ["ok" if ok else "FAIL", what])

func _initialize() -> void:
	var fl := StaticBody3D.new(); var cs := CollisionShape3D.new(); var sh := BoxShape3D.new()
	sh.size = Vector3(400, 2, 400); cs.shape = sh; fl.add_child(cs); fl.position = Vector3(0, -1, 0)
	var mi := MeshInstance3D.new(); var bm := BoxMesh.new(); bm.size = sh.size; mi.mesh = bm; fl.add_child(mi); root.add_child(fl)
	var sun := DirectionalLight3D.new(); sun.rotation_degrees = Vector3(-45, 30, 0); root.add_child(sun)
	player = ClassDB.instantiate(&"CityPlayer"); player.position = Vector3(-0.9, 0.05, 0); root.add_child(player)
	bike = ClassDB.instantiate(&"CityBike"); bike.position = Vector3(0, 0.02, 0); root.add_child(bike)
	bike.call(&"set_rider_player", player)
	cam = Camera3D.new(); root.add_child(cam)

func _foot(s: Dictionary) -> Vector3:
	return bike.global_transform * (s.foot_on_bike as Vector3) if s.has("foot_on_bike") else Vector3.INF

func _physics_process(delta: float) -> bool:
	t += delta
	cam.current = true
	var b := bike.global_position
	var f: Vector3 = bike.global_basis.z; f.y = 0; f = f.normalized()
	var l := Vector3.UP.cross(f)
	cam.look_at_from_position(b + l * 2.6 + f * 1.4 + Vector3(0, 1.3, 0), b + Vector3(0, 0.7, 0), Vector3.UP)   # (from his left: the foot that comes down)
	var s: Dictionary = bike.call(&"get_state")
	var fw := _foot(s)
	if prev_foot != Vector3.INF and fw != Vector3.INF and (step == 3 or step == 5): jump_most = maxf(jump_most, (fw - prev_foot).length() - absf(float(s.speed)) * delta)
	prev_foot = fw
	match step:
		0:
			if t < 1.0: return false
			_check(bool(bike.call(&"get_on")), "he gets on"); step = 1; t0 = t
		1:
			if String(s.state) != "riding": return false
			bike.call(&"set_controls", 1.0, 0.0, 0.0, 0.0); step = 2; t0 = t
		2:
			if t - t0 < 3.0: return false
			bike.call(&"set_controls", 0.0, 1.0, 0.0, 0.0); step = 3; t0 = t
		3:
			if t - t0 < 1.0 and absf(float(s.speed)) > 0.05: return false
			if t - t0 < 3.0: return false
			bike.call(&"set_controls", 0.0, 0.0, 0.0, 0.0)
			root.get_texture().get_image().save_png("res://OUT/bike_idle_standing.png")
			var miss: Vector2 = (s.foot_miss as Vector2) * 0.01   # (the skeleton's centimetres)
			var tilt := rad_to_deg(asin(clampf(-bike.global_basis.x.y, -1, 1)))
			_check(float(s.foot_down) > 0.99, "standing still, the foot is down (%.2f)" % float(s.foot_down))
			_check(miss.x < 0.04 and absf(fw.y - 0.085) < 0.04, "the left foot on the ground: %.3f m from its spot, the ankle %.3f m over the floor" % [miss.x, fw.y])
			_check(tilt > 4.0 and tilt < 9.0, "the bike tipped onto it %.1f degrees" % tilt)
			bike.call(&"set_controls", 1.0, 0.0, 0.0, 0.0); step = 5; t0 = t
		5:
			if t_up < 0.0 and float(s.foot_down) < 0.01: t_up = t - t0
			if t - t0 > 0.12 and t - t0 < 0.14: root.get_texture().get_image().save_png("res://OUT/bike_idle_pushing_off.png")
			if t - t0 < 1.5: return false
			root.get_texture().get_image().save_png("res://OUT/bike_idle_riding.png")
			var miss2: Vector2 = (s.foot_miss as Vector2) * 0.01
			_check(t_up >= 0.0 and t_up < 0.35, "pedalling: the foot back on its pedal after %.2f s" % t_up)
			_check(float(s.speed) > 1.5 and miss2.x < 0.04, "rolling again at %.1f m/s, the foot on the pedal (%.3f m off)" % [float(s.speed), miss2.x])
			_check(jump_most < 0.04, "the left foot never jumped: at most %.3f m in a frame" % jump_most)
			print("RESULT %s" % ("PASS" if fails == 0 else "FAIL (%d)" % fails))
			quit(1 if fails else 0); return true
	return false
