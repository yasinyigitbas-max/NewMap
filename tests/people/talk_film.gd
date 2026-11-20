extends SceneTree
## A film of a talk (the Animator, 20 Nov; Yasin: "starting chat with npc doesnt play any animation as far as i can see"):
## the player stands near a man with his back half to him, starts a talk (he turns to the man and says hello), picks a
## line and says it (typed: his body talks), the man answers, they part with a nod. Side view, 25 fps.
##   godot --path . --rendering-method mobile --resolution 640x480 --fixed-fps 50 -s res://tests/people/talk_film.gd -- --out=OUT/talk_film
## Writes <out>/f_<frame>.png.
var out := "OUT/talk_film"
var crowd: Node3D
var player: Node3D
var talk: Node
var cam: Camera3D
var t := 0.0
var step := 0
var who := -1
var spot := Vector3.ZERO
var n := 0
var shot := 0

func _initialize() -> void:
	for a: String in OS.get_cmdline_user_args():
		if a.begins_with("--out="): out = a.trim_prefix("--out=")
	DirAccess.make_dir_recursive_absolute(out)
	crowd = ClassDB.instantiate(&"CityCrowd")
	crowd.set(&"max_people", 300); crowd.set(&"hour", 14.25)
	root.add_child(crowd)
	var sun := DirectionalLight3D.new(); sun.rotation_degrees = Vector3(-50, 30, 0); sun.shadow_enabled = true; root.add_child(sun)
	var we := WorldEnvironment.new(); var env := Environment.new(); env.background_mode = Environment.BG_COLOR; env.background_color = Color(0.55, 0.68, 0.82)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR; env.ambient_light_color = Color(0.7, 0.72, 0.78); env.ambient_light_energy = 0.8; we.environment = env; root.add_child(we)
	cam = Camera3D.new(); cam.position = Vector3(0, 40, -620); cam.rotation_degrees = Vector3(-90, 0, 0); cam.fov = 45.0; root.add_child(cam); cam.current = true

func _physics_process(delta: float) -> bool:
	t += delta; n += 1
	if step >= 1:
		var mid: Vector3 = (player.global_position + spot) * 0.5
		cam.look_at_from_position(mid + Vector3(-0.6, 1.5, 4.2), mid + Vector3(0, 1.0, 0), Vector3.UP)
		if n % 2 == 0: root.get_texture().get_image().save_png("%s/f_%03d.png" % [out, shot]); shot += 1
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
			player = ClassDB.instantiate(&"CityPlayer"); player.position = spot + Vector3(1.6, 0.05, 0.3); root.add_child(player)
			crowd.call(&"set_player", player)
			talk = ClassDB.instantiate(&"CityTalk"); root.add_child(talk)
			talk.call(&"set_crowd", crowd); talk.call(&"set_player", player)
			talk.call(&"set_force", 0.0, 1.0, 1.0, 1.0, "T5")
			step = 1; t = 0.0
		1:
			if t < 1.2: return false
			print("FILM begin: %s" % String(talk.call(&"begin", who)))
			step = 2; t = 0.0
		2:
			if t < 3.5: return false
			var opts: Array = talk.call(&"get_options")
			if opts.size() > 0:
				talk.call(&"choose", 0)
				talk.call(&"say_typed", String((opts[0] as Dictionary).get("en", "")))
			step = 3; t = 0.0
		3:
			if t < 4.5: return false
			talk.call(&"end", "bye")
			step = 4; t = 0.0
		4:
			if t < 2.5: return false
			print("FILM %d frames saved: %s" % [shot, out])
			quit(0); return true
	return false
