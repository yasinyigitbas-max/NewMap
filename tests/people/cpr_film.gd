extends SceneTree
## CPR (the Animator, 21 Nov; Yasin: "paramedic should do cpr and rceiving npc shoud lay flat and everything"): somebody
## near the player is knocked down hard (he stays down); the CPR starts (what the paramedics' kneeling does,
## CityCrowd.set_cpr): his body hands over to Receiving_Cpr laid where it lies; treated, he gets up from his back and goes
## his way. In a window, every 3rd frame saved:
##   godot --path . --rendering-method mobile --resolution 800x600 --fixed-fps 60 -s res://tests/people/cpr_film.gd -- --out=OUT/cpr_film
var out := "OUT/cpr_film"
var crowd: Node3D
var player: CharacterBody3D
var cam: Camera3D
var t := 0.0
var t0 := 0.0
var step := 0
var victim := -1
var at := Vector3(-600, 0, -1000)
var seen := []
var fails := 0
var n := 0
var shot := 0

func _check(ok: bool, what: String) -> void:
	if not ok: fails += 1
	print("CPR   %s: %s" % ["ok" if ok else "FAIL", what])

func _initialize() -> void:
	for a: String in OS.get_cmdline_user_args():
		if a.begins_with("--out="): out = a.trim_prefix("--out=")
	DirAccess.make_dir_recursive_absolute(out)
	crowd = ClassDB.instantiate(&"CityCrowd"); crowd.set(&"max_people", 60); crowd.set(&"hour", 12.5); root.add_child(crowd)
	var sun := DirectionalLight3D.new(); sun.rotation_degrees = Vector3(-50, 30, 0); root.add_child(sun)
	cam = Camera3D.new(); root.add_child(cam); cam.current = true

func _victim() -> Dictionary:
	for nb: Dictionary in crowd.call(&"near_bodies"):
		if int(nb.walker) == victim: return nb
	return {}

func _physics_process(delta: float) -> bool:
	t += delta; n += 1
	var v := _victim()
	if not v.is_empty():
		var c: Vector3 = v.at
		cam.current = true
		cam.look_at_from_position(c + Vector3(1.4, 3.2, 1.0), c + Vector3(0, 0.2, 0), Vector3.UP)   # (from above beside him: the player stands close)
		var cl := String(v.clip)
		if seen.is_empty() or seen[-1] != cl: seen.append(cl)
		if n % 3 == 0: root.get_texture().get_image().save_png("%s/f_%04d.png" % [out, shot]); shot += 1
	match step:
		0:
			if t < 6.0: return false
			var pv: Dictionary = crowd.call(&"pavement_near", at, 300.0)
			if not bool(pv.get("ok", false)): _check(false, "no pavement"); return _end()
			var g := StaticBody3D.new(); var cs := CollisionShape3D.new(); var sh := BoxShape3D.new(); sh.size = Vector3(600, 2, 600); cs.shape = sh; g.add_child(cs)
			g.position = Vector3(pv.at.x, pv.at.y - 1.0, pv.at.z); root.add_child(g)
			var fm := MeshInstance3D.new(); var bm := BoxMesh.new(); bm.size = sh.size; fm.mesh = bm; var mm := StandardMaterial3D.new(); mm.albedo_color = Color(0.55, 0.55, 0.57); fm.material_override = mm; g.add_child(fm)
			player = ClassDB.instantiate(&"CityPlayer"); root.add_child(player); player.global_position = pv.at + Vector3(0, 0.1, 0)
			crowd.call(&"set_player", player)
			step = 1; t0 = t
		1:
			for nb: Dictionary in crowd.call(&"near_bodies"):
				if int(nb.walker) >= 0 and bool(crowd.call(&"knock_down_walker", int(nb.walker))): victim = int(nb.walker); break
			if victim < 0:
				if t - t0 > 20.0: _check(false, "nobody to knock down"); return _end()
				return false
			step = 2; t0 = t
		2:
			if t - t0 < 4.0: return false
			_check(bool(crowd.call(&"is_down", victim)), "knocked down hard, he stays down")
			crowd.call(&"set_cpr", victim, true)
			step = 3; t0 = t
		3:
			if t - t0 < 8.0: return false
			_check(seen.has("x/cpr_take"), "he lies flat taking the CPR (x/cpr_take) %s" % str(seen))
			crowd.call(&"treat", victim)
			step = 4; t0 = t
		4:
			if t - t0 < 8.0: return false
			_check(seen.has("x/up_from_back"), "treated, he gets up from his back (x/up_from_back) %s" % str(seen))
			_check(not bool(crowd.call(&"is_down", victim)), "up and on his way")
			print("FILM %d frames: %s" % [shot, out])
			return _end()
	return false

func _end() -> bool:
	print("RESULT %s" % ("PASS" if fails == 0 else "FAIL (%d)" % fails))
	quit(1 if fails else 0); return true
