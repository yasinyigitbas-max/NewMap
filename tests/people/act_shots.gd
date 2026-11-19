extends SceneTree
## Four pictures of people doing things with the pro clips (C++ CityCrowd), in a window that closes by itself:
##   godot --path . --resolution 1280x720 -s res://tests/people/act_shots.gd
## A row of five on a plain floor, seen by the player: one sits down on a seat, one on the ground, a beggar, two who
## fight. -> OUT/acts_1.png .. acts_4.png (0.7 s, 1.9 s, 3.6 s and 5.4 s after they began).
var crowd: Node3D
var player: Node3D
var t := 0.0
var step := 0
var spot := Vector3.ZERO
var dir := Vector3.FORWARD
const WHEN := [0.8, 3.2, 5.0, 7.6]

func _initialize() -> void:
	crowd = ClassDB.instantiate(&"CityCrowd")
	crowd.set(&"max_people", 200); crowd.set(&"hour", 12.5); crowd.set(&"near_max", 18)
	root.add_child(crowd)
	var sun := DirectionalLight3D.new(); sun.rotation_degrees = Vector3(-50, 30, 0); root.add_child(sun)
	var we := WorldEnvironment.new(); var env := Environment.new(); env.background_mode = Environment.BG_COLOR; env.background_color = Color(0.55, 0.68, 0.82)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR; env.ambient_light_color = Color(0.7, 0.72, 0.78); env.ambient_light_energy = 0.8; we.environment = env; root.add_child(we)
	var cam := Camera3D.new(); cam.position = Vector3(0, 40, -620); cam.rotation_degrees = Vector3(-90, 0, 0); root.add_child(cam); cam.current = true

func _process(delta: float) -> bool:
	t += delta
	if step == 0:
		if t < 6.0: return false
		for p: Dictionary in crowd.call(&"people_near", Vector3(0, 0, -620), 200.0):
			if int(p.mode) == 0 and int(p.state) == 0 and int(p.party) == 0 and float(p.speed) > 0.9:
				spot = p.at; dir = Vector3(sin(float(p.yaw)), 0, cos(float(p.yaw))); break
		var fl := StaticBody3D.new(); var cs := CollisionShape3D.new(); var sh := BoxShape3D.new()
		sh.size = Vector3(800, 2, 800); cs.shape = sh; fl.add_child(cs)
		var mi := MeshInstance3D.new(); var bm := BoxMesh.new(); bm.size = sh.size; mi.mesh = bm; fl.add_child(mi)
		fl.position = Vector3(spot.x, spot.y - 1.0, spot.z); root.add_child(fl)
		var side := Vector3(-dir.z, 0, dir.x)
		player = ClassDB.instantiate(&"CityPlayer")
		player.position = spot + dir * 3.2 + side * 3.6 + Vector3(0, 0.05, 0)
		player.rotation.y = atan2(side.x, side.z) - PI      # (the camera behind him looks at the row)
		root.add_child(player)
		crowd.call(&"set_player", player)
		step = 1; t = 0.0
	elif step == 1:
		if t < 1.5: return false
		var ids := []
		for k in 5: ids.append(int(crowd.call(&"place_walker", spot + dir * (0.4 + 1.4 * k), 4100 + 37 * k)))
		crowd.call(&"set_act", ids[0], 1, 30.0)      # on a seat
		crowd.call(&"set_act", ids[1], 23, 30.0)     # on the ground
		crowd.call(&"set_act", ids[2], 8, 30.0)      # a beggar
		print("SHOT fight: %s" % str(crowd.call(&"fight", ids[3], ids[4])))
		step = 2; t = 0.0
	elif step >= 2 and step < 2 + WHEN.size():
		if t < float(WHEN[step - 2]): return false
		root.get_texture().get_image().save_png("res://OUT/acts_%d.png" % (step - 1))
		step += 1
	else:
		print("SHOT done")
		quit(0)
		return true
	return false
