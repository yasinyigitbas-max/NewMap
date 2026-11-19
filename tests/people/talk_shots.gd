extends SceneTree
## Two pictures of the talk on the screen (C++ class CityTalk), in a window that closes by itself:
##   godot --path . --resolution 1280x720 -s res://tests/people/talk_shots.gd
## -> OUT/talk_1.png (the greeting and the three lines), OUT/talk_2.png (the "say it" box). Plain floor, no city.
var crowd: Node3D
var player: Node3D
var talk: Node
var t := 0.0
var step := 0
var who := -1
var spot := Vector3.ZERO

func _initialize() -> void:
	crowd = ClassDB.instantiate(&"CityCrowd")
	crowd.set(&"max_people", 300); crowd.set(&"hour", 14.25)
	root.add_child(crowd)
	var sun := DirectionalLight3D.new(); sun.rotation_degrees = Vector3(-50, 30, 0); root.add_child(sun)
	var we := WorldEnvironment.new(); var env := Environment.new(); env.background_mode = Environment.BG_COLOR; env.background_color = Color(0.55, 0.68, 0.82)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR; env.ambient_light_color = Color(0.7, 0.72, 0.78); env.ambient_light_energy = 0.8; we.environment = env; root.add_child(we)
	var cam := Camera3D.new(); cam.position = Vector3(0, 40, -620); cam.rotation_degrees = Vector3(-90, 0, 0); root.add_child(cam); cam.current = true

func _process(delta: float) -> bool:
	t += delta
	match step:
		0:
			if t < 6.0: return false
			for p: Dictionary in crowd.call(&"people_near", Vector3(0, 0, -620), 200.0):
				if int(p.mode) == 0 and int(p.state) == 0 and int(p.party) == 0: spot = p.at; break
			var fl := StaticBody3D.new(); var cs := CollisionShape3D.new(); var sh := BoxShape3D.new()
			sh.size = Vector3(800, 2, 800); cs.shape = sh; fl.add_child(cs)
			var mi := MeshInstance3D.new(); var bm := BoxMesh.new(); bm.size = sh.size; mi.mesh = bm; fl.add_child(mi)
			fl.position = Vector3(spot.x, spot.y - 1.0, spot.z); root.add_child(fl)
			who = int(crowd.call(&"place_walker", spot, 4242)); crowd.call(&"stay", who, 600.0)
			player = ClassDB.instantiate(&"CityPlayer"); player.position = spot + Vector3(1.5, 0.05, 0.4); root.add_child(player)
			crowd.call(&"set_player", player)
			talk = ClassDB.instantiate(&"CityTalk"); root.add_child(talk)
			talk.call(&"set_crowd", crowd); talk.call(&"set_player", player)
			talk.call(&"set_force", 0.0, 1.0, 1.0, 1.0, "T5")
			step = 1; t = 0.0
		1:
			if t < 1.5: return false
			print("SHOT begin: %s" % String(talk.call(&"begin", who)))
			step = 2; t = 0.0
		2:
			if t < 1.0: return false
			root.get_texture().get_image().save_png("res://OUT/talk_1.png")
			talk.call(&"choose", 0)
			step = 3; t = 0.0
		3:
			if t < 0.6: return false
			root.get_texture().get_image().save_png("res://OUT/talk_2.png")
			print("SHOT done")
			quit(0)
			return true
	return false
