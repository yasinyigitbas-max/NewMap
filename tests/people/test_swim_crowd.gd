extends SceneTree
## People of the beach go for a swim (C++: the brain's swim spots, CityCrowd's sea depth map), headless:
##   godot --headless --fixed-fps 60 --path . -s res://tests/people/test_swim_crowd.gd
## The real streets, places and sea map over a flat floor at the beach's height. Somebody is sent to a place on the
## beach that has a spot in the sea; he lies there a moment, gets up, walks into the water, wades while it is under
## his chest, swims where it is deeper, floats at his spot, and comes back to the pavement. The player stands half way
## so that he has an animated body all the time. This script sets it up and reads where he is and which clip plays.
var crowd: Node3D
var player: Node3D
var t := 0.0
var step := 0
var t0 := 0.0
var fails := 0
var beach := -1
var spot := -1
var b_at := Vector3.ZERO
var s_at := Vector3.ZERO
var who := -1
var clips: Array = []
var waded := false
var swam_y := 9.0
var deepest := 0.0
var modes: Array = []

func _initialize() -> void:
	if not ClassDB.class_exists(&"CityCrowd"):
		print("SWIMC ERROR the native module is not built"); print("RESULT FAIL"); quit(1); return
	crowd = ClassDB.instantiate(&"CityCrowd")
	crowd.set(&"max_people", 150); crowd.set(&"hour", 13.0); crowd.set(&"near_max", 18)
	root.add_child(crowd)
	var cam := Camera3D.new(); cam.position = Vector3(0, 40, -620); cam.rotation_degrees = Vector3(-90, 0, 0); root.add_child(cam); cam.current = true

func _check(ok: bool, what: String) -> void:
	if not ok: fails += 1
	print("SWIMC   %s: %s" % ["ok" if ok else "FAIL", what])

func _person(id: int) -> Dictionary:
	for p: Dictionary in crowd.call(&"people_near", b_at, 300.0):
		if int(p.id) == id: return p
	return {}

func _physics_process(delta: float) -> bool:
	if crowd == null: return true
	t += delta
	if who >= 0:
		var p := _person(who)
		if not p.is_empty():
			if modes.is_empty() or modes.back() != int(p.mode): modes.append(int(p.mode))
			var d: float = crowd.call(&"sea_depth", (p.at as Vector3).x, (p.at as Vector3).z)
			deepest = maxf(deepest, d)
			for nb: Dictionary in crowd.call(&"near_bodies"):
				if int(nb.walker) != who: continue
				var nm := String(nb.clip).trim_prefix("ual/")
				if clips.is_empty() or clips.back() != nm: clips.append(nm)
				# (walking: the Quaternius walk, or since 20 Nov the same with the hands open, its start and stops: "step/...")
				var walking := nm.begins_with("Walk") or nm.begins_with("walk") or nm in ["step/walk", "step/start", "step/stop_l", "step/stop_r", "step/rb_stop_l", "step/rb_stop_r"]   # (the Rocketbox walk again since 21 Nov)
				if d > 0.3 and d < 1.0 and walking and absf((nb.at as Vector3).y + d) < 0.12: waded = true
				if d > 1.3 and nm.begins_with("Swim"): swam_y = (nb.at as Vector3).y
	match step:
		0:
			if t < 2.0: return false
			var n := int(crowd.call(&"stats").places)
			for i in n:
				var info: Dictionary = crowd.call(&"place_info", i)
				if int(info.kind) == 2 and int(crowd.call(&"swim_spot_of", i)) >= 0:
					beach = i; spot = int(crowd.call(&"swim_spot_of", i)); b_at = info.at; s_at = crowd.call(&"place_info", spot).at; break
			if beach < 0: _check(false, "no place on the beach has a spot in the sea (run tools/city/traffic/make_swim.gd)"); step = 9; return false
			var fl := StaticBody3D.new(); var cs := CollisionShape3D.new(); var sh := BoxShape3D.new()
			sh.size = Vector3(600, 2, 600); cs.shape = sh; fl.add_child(cs); fl.position = Vector3(b_at.x, b_at.y - 1.0, b_at.z); root.add_child(fl)
			player = ClassDB.instantiate(&"CityPlayer")
			var along := Vector3(s_at.x - b_at.x, 0, s_at.z - b_at.z).normalized()
			player.position = Vector3((b_at.x + s_at.x) * 0.5, b_at.y + 0.05, (b_at.z + s_at.z) * 0.5) + Vector3(-along.z, 0, along.x) * 7.0      # (half way, 7 m to the side: not in his way)
			root.add_child(player)
			crowd.call(&"set_player", player)
			var pave: Vector3 = crowd.call(&"place_info", beach).pavement
			who = int(crowd.call(&"place_walker", pave, 32768 + 77))      # (one of the half who swim: bit 15 of who he is)
			var ok: bool = crowd.call(&"set_goal", who, beach, 2.0, false)
			_check(ok, "somebody is sent to a place on the beach %.0f m from its pavement; its spot in the sea is %.0f m out, %.1f m of water there" % [pave.distance_to(b_at), Vector2(b_at.x - s_at.x, b_at.z - s_at.z).length(), float(crowd.call(&"sea_depth", s_at.x, s_at.z))])
			step = 1; t0 = t
		1:      # until he has been at his spot and is on the pavement again (or five minutes)
			var p := _person(who)
			var back: bool = not p.is_empty() and int(p.mode) == 0 and modes.has(2) and modes.count(2) >= 1 and modes.size() >= 6
			if not back and t - t0 < 300.0 and not p.is_empty(): return false
			_check(deepest > 1.3 and clips.has("Swim_Fwd_Loop") and clips.has("Swim_Idle_Loop") and swam_y > -0.5 and swam_y < -0.25, "he went into the sea (%.1f m of water at the deepest), swam there at the surface (his body %.2f m under it) and floated at his spot" % [deepest, -swam_y])
			_check(waded, "on the way he waded, his feet on the bottom, where the water was under his chest")
			_check(clips.has("IdleToLay") or clips.has("GroundSit_Enter"), "before that he lay or sat down on the beach and got up again")
			_check(back, "and he is back on the pavement, walking (%.0f s in all; modes %s)" % [t - t0, str(modes)])
			print("SWIMC his body played: %s" % " > ".join(PackedStringArray(clips)))
			step = 9
		9:
			print("RESULT %s" % ("PASS" if fails == 0 else "FAIL (%d)" % fails))
			quit(1 if fails else 0)
			return true
	return false
