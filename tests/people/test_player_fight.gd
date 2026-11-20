extends SceneTree
## The player's fight (C++: CityPlayer's combat, CityCrowd's lock, health and the person's defence; the balancing bodies),
## headless with physics:
##   godot --headless --fixed-fps 60 --path . -s res://tests/people/test_player_fight.gd
## The real streets over a flat floor. A person is set down (held where he stands so that he is in reach), the player a
## metre from him. The player asks for combat (what the swing / F does): he is locked on the nearest person, who does NOT
## fight before he is hit. Then the player punches (what a back tap / J does) and stays in reach: from the first blow
## the person fights (hits back, dodges sideways); one of them is beaten; a beaten person falls as a ragdoll with its
## weight (his hips near the floor, never thrown high), the fight ends.
var crowd: Node3D
var player: CharacterBody3D
var t := 0.0
var t0 := 0.0
var step := 0
var fails := 0
var who := -1
var spot := Vector3.ZERO
var lowest := 9.0
var highest := -9.0
var punch_t := 0.0

func _check(ok: bool, what: String) -> void:
	if not ok: fails += 1
	print("FIGHT   %s: %s" % ["ok" if ok else "FAIL", what])

func _initialize() -> void:
	crowd = ClassDB.instantiate(&"CityCrowd")
	crowd.set(&"max_people", 30); crowd.set(&"hour", 12.5); crowd.set(&"near_max", 6)
	root.add_child(crowd)
	var cam := Camera3D.new(); cam.position = Vector3(0, 30, -600); cam.rotation_degrees = Vector3(-90, 0, 0); root.add_child(cam); cam.current = true

func _person() -> Dictionary:
	for p: Dictionary in crowd.call(&"people_near", spot, 60.0):
		if int(p.id) == who: return p
	return {}

func _physics_process(delta: float) -> bool:
	t += delta
	var fs: Dictionary = crowd.call(&"fight_stats") if crowd else {}
	match step:
		0:
			if t < 2.0: return false
			who = int(crowd.call(&"place_walker", Vector3(0, 0, -600), 4242))
			spot = Vector3(0, 0, -600)
			var p := _person(); spot = p.at
			var fl := StaticBody3D.new(); var cs := CollisionShape3D.new(); var sh := BoxShape3D.new()
			sh.size = Vector3(200, 2, 200); cs.shape = sh; fl.add_child(cs); fl.position = Vector3(spot.x, spot.y - 1.0, spot.z); root.add_child(fl)
			crowd.call(&"hold", who, true, 0.0)
			player = ClassDB.instantiate(&"CityPlayer"); player.position = spot + Vector3(0, 0.05, -1.0); root.add_child(player)
			crowd.call(&"set_player", player)
			var cam := root.get_viewport().get_camera_3d(); cam.current = true; cam.look_at_from_position(spot + Vector3(5, 3, 0), spot, Vector3.UP)
			step = 1; t0 = t
		1:
			if t - t0 < 1.2: return false
			player.call(&"request_combat")
			step = 2; t0 = t
		2:
			if t - t0 < 2.0: return false
			_check(int(fs.walker) == who and bool(player.call(&"get_combat")), "combat: the player is locked on the nearest person (%d)" % int(fs.walker))
			_check(not bool(fs.angry) and int(fs.attacks) == 0, "he does not fight before he is hit")
			step = 3; t0 = t; punch_t = 0.0
		3:      # punches, staying in reach
			var p := _person()
			if not p.is_empty():
				var at: Vector3 = p.at
				for nb: Dictionary in crowd.call(&"near_bodies"):
					if int(nb.walker) == who:
						at = nb.at
						if int(nb.figure_mode) == 1: lowest = minf(lowest, (nb.at as Vector3).y - spot.y); highest = maxf(highest, (nb.at as Vector3).y - spot.y)
				var d := Vector3(at.x - player.global_position.x, 0, at.z - player.global_position.z)
				if d.length() > 1.1: player.global_position += d.normalized() * minf(d.length() - 1.0, 2.0 * delta)
			punch_t += delta
			if OS.get_cmdline_user_args().has("--trace") and int((t - t0) * 4.0) != int((t - t0 - delta) * 4.0):
				var fm := -1
				for nb: Dictionary in crowd.call(&"near_bodies"): if int(nb.walker) == who: fm = int(nb.figure_mode)
				var pp := _person()
				print("FIGHT     t+%.2f body %d mode %s angry %s state %d hp %d" % [t - t0, fm, str(pp.get("mode", -1)), str(fs.angry), int(fs.state), int(fs.npc_health)])
			if punch_t > 1.3: punch_t = 0.0; player.call(&"punch")      # (a beat between blows, as in an exchange)
			if int(fs.npc_beaten) == 0 and int(fs.player_beaten) == 0 and t - t0 < 60.0: return false
			_check(int(fs.landed) >= 1, "the punches land: %d landed, %d missed (dodged or out of reach), %d thrown" % [int(fs.landed), int(fs.missed), int(player.call(&"get_punches"))])
			_check(int(fs.attacks) + int(fs.dodges) >= 1, "once hit he fights back: %d blows at the player (%d landed), %d dodges sideways" % [int(fs.attacks), int(fs.hits_on_player), int(fs.dodges)])
			_check(int(fs.npc_beaten) + int(fs.player_beaten) == 1, "one of them is beaten: %s (%.0f s)" % ["the person" if int(fs.npc_beaten) > 0 else "the player", t - t0])
			_check(not bool(player.call(&"get_combat")), "the fight is over")
			var cst: Dictionary = crowd.call(&"stats")
			_check(int(cst.alarms_player_hit) >= 1, "the street reacts to the player's blows (B31): %d alarm(s); %d ran, %d stared / filmed / called, %d ducked" % [int(cst.alarms_player_hit), int(cst.fled), int(cst.stared), int(cst.ducked)])
			step = 4; t0 = t
		4:      # the beaten person falls with his weight
			for nb: Dictionary in crowd.call(&"near_bodies"):
				if int(nb.walker) == who and int(nb.figure_mode) == 1: lowest = minf(lowest, (nb.at as Vector3).y - spot.y); highest = maxf(highest, (nb.at as Vector3).y - spot.y)
			if t - t0 < 3.0: return false
			if int(fs.npc_beaten) > 0: _check(lowest < 0.5 and highest < 1.6, "he falls to the ground as a ragdoll, not weightlessly: hips at the lowest %.2f m, at the highest %.2f m" % [lowest, highest])
			step = 9
		9:
			print("RESULT %s" % ("PASS" if fails == 0 else "FAIL (%d)" % fails))
			quit(1 if fails else 0)
			return true
	return false
