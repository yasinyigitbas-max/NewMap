extends SceneTree
## The player's fight to watch (C++: CityPlayer's combat, CityCrowd's fight; the balancing bodies), in a window:
##   godot --path . --rendering-method mobile --resolution 1280x720 -s res://tests/people/fight_film.gd [-- --movie]
## A person on a lit ground, the player beside him: combat, a punch every 1.3 s, he fights back, one goes down. The
## camera stays beside the two. Ends a few seconds after the fight.
var crowd: Node3D
var player: CharacterBody3D
var cam: Camera3D
var t := 0.0
var t0 := 0.0
var step := 0
var who := -1
var spot := Vector3.ZERO
var punch_t := 0.0
var label: Label

func _initialize() -> void:
	crowd = ClassDB.instantiate(&"CityCrowd")
	crowd.set(&"max_people", 20); crowd.set(&"hour", 12.5); crowd.set(&"near_max", 6)
	root.add_child(crowd)
	cam = Camera3D.new(); cam.position = Vector3(0, 30, -600); root.add_child(cam); cam.current = true
	var sun := DirectionalLight3D.new(); sun.rotation_degrees = Vector3(-50, 35, 0); sun.shadow_enabled = true; root.add_child(sun)
	var env := WorldEnvironment.new(); env.environment = Environment.new(); env.environment.background_mode = Environment.BG_COLOR
	env.environment.background_color = Color(0.55, 0.7, 0.88); env.environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR; env.environment.ambient_light_color = Color(0.62, 0.62, 0.65)
	root.add_child(env)
	var cl := CanvasLayer.new(); root.add_child(cl)
	label = Label.new(); label.position = Vector2(24, 20); label.add_theme_font_size_override("font_size", 26); cl.add_child(label)

func _person() -> Dictionary:
	for p: Dictionary in crowd.call(&"people_near", spot, 60.0):
		if int(p.id) == who: return p
	return {}

func _physics_process(delta: float) -> bool:
	t += delta
	var fs: Dictionary = crowd.call(&"fight_stats")
	if label: label.text = "fight: you %d / 8   him %d / 4   blows at you %d   his dodges %d" % [int(fs.player_health), int(fs.npc_health), int(fs.attacks), int(fs.dodges)]
	match step:
		0:
			if t < 2.0: return false
			spot = Vector3(0, 0, -600)
			who = int(crowd.call(&"place_walker", spot, 4242))
			var p := _person(); spot = p.at
			var fl := StaticBody3D.new(); var cs := CollisionShape3D.new(); var sh := BoxShape3D.new()
			sh.size = Vector3(200, 2, 200); cs.shape = sh; fl.add_child(cs); fl.position = Vector3(spot.x, spot.y - 1.0, spot.z)
			var mi := MeshInstance3D.new(); var bm := BoxMesh.new(); bm.size = sh.size; mi.mesh = bm
			var m := StandardMaterial3D.new(); m.albedo_color = Color(0.38, 0.38, 0.4); mi.material_override = m; fl.add_child(mi)
			root.add_child(fl)
			crowd.call(&"hold", who, true, 0.0)
			player = ClassDB.instantiate(&"CityPlayer"); player.position = spot + Vector3(0, 0.05, -1.0); root.add_child(player)
			crowd.call(&"set_player", player)
			step = 1; t0 = t
		1:
			cam.current = true
			if t - t0 < 1.5: return false
			player.call(&"request_combat")
			step = 2; t0 = t; punch_t = 0.0
		2:
			cam.current = true
			var p := _person()
			var at: Vector3 = p.at if not p.is_empty() else spot
			var mid := (at + player.global_position) * 0.5
			cam.look_at_from_position(mid + Vector3(3.6, 1.7, 0.6), mid + Vector3(0, 0.9, 0), Vector3.UP)
			if t - t0 < 1.5: return false
			var d := Vector3(at.x - player.global_position.x, 0, at.z - player.global_position.z)
			if d.length() > 1.1 and bool(player.call(&"get_combat")): player.global_position += d.normalized() * minf(d.length() - 1.0, 2.0 * delta)
			punch_t += delta
			if punch_t > 1.3: punch_t = 0.0; player.call(&"punch")
			if int(fs.npc_beaten) + int(fs.player_beaten) > 0: step = 3; t0 = t
			if t - t0 > 60.0: quit(); return true
		3:
			if t - t0 > 6.0: quit(); return true
	return false
