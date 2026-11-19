extends SceneTree
## The way into and out of what people do, and a fight (C++: CityCrowd, the brain's A_RISE, the Quaternius pro clips), headless:
##   godot --headless --fixed-fps 60 --path . -s res://tests/people/test_acts.gd
## The real streets over a flat floor, the player beside the people so that they have animated bodies.
##  - somebody sits, then crouches: when the act is over he first gets up WHERE HE IS (the exit clip's length), then walks;
##  - two people fight: both square up, exchange blows for the set time, the last blow hands the one who takes it to his
##    balancing body (a real shove, not a clip), both go their ways afterwards.
##  - one of the two wins (chance, fixed by who they are) and celebrates; the other walks away slowly, hurt.
## `-- --trace` prints the figure of one of the two twice a second. This script only sets things up and reads what the people show.
var crowd: Node3D
var player: Node3D
var t := 0.0
var step := 0
var t0 := 0.0
var fails := 0
var spot := Vector3.ZERO
var dir := Vector3.FORWARD
var a := -1
var b := -1
var c := -1
var g := -1
var seen := {}          # per walker: the acts it showed, in order, with how long and how far it moved in each
var in_body := 0
var phone_walkers := {}
var trace := OS.get_cmdline_user_args().has("--trace")      # the one who takes the last blow, twice a second
var clips := {}        # per walker: the clips its animated body played, in order

func _initialize() -> void:
	if not ClassDB.class_exists(&"CityCrowd") or not ClassDB.class_exists(&"CityPlayer"):
		print("ACTS ERROR the native module is not built: run  bash native/build.sh"); print("RESULT FAIL"); quit(1); return
	crowd = ClassDB.instantiate(&"CityCrowd")
	crowd.set(&"max_people", 300); crowd.set(&"hour", 12.5); crowd.set(&"near_max", 18)      # (18 animated bodies: the people of this test stand among passers-by)
	root.add_child(crowd)
	var cam := Camera3D.new(); cam.position = Vector3(0, 40, -620); cam.rotation_degrees = Vector3(-90, 0, 0); root.add_child(cam); cam.current = true

func _check(ok: bool, what: String) -> void:
	if not ok: fails += 1
	print("ACTS   %s: %s" % ["ok" if ok else "FAIL", what])

func _person(id: int) -> Dictionary:
	for p: Dictionary in crowd.call(&"people_near", spot, 400.0):
		if int(p.id) == id: return p
	return {}

func _watch(delta: float) -> void:
	for id: int in [a, b, c]:
		if id < 0: continue
		var p := _person(id)
		if p.is_empty(): continue
		var l: Array = seen.get(id, [])
		if l.is_empty() or int(l.back()[0]) != int(p.act): l.append([int(p.act), 0.0, p.at, 0.0, int(p.mode)])
		l.back()[1] = float(l.back()[1]) + delta
		l.back()[3] = maxf(float(l.back()[3]), (p.at as Vector3).distance_to(l.back()[2]))
		if int(p.mode) == 7: l.back()[4] = 7
		seen[id] = l
	in_body = maxi(in_body, int(crowd.call(&"stats").in_physical_body))
	for nb: Dictionary in crowd.call(&"near_bodies"):
		if int(nb.walker) in [a, b, c, g]:
			var cl: Array = clips.get(int(nb.walker), [])
			var nm := String(nb.clip).trim_prefix("ual/")
			if cl.is_empty() or cl.back() != nm: cl.append(nm)
			clips[int(nb.walker)] = cl
	for p: Dictionary in crowd.call(&"people_near", spot, 60.0):
		if int(p.act) == 4 and float(p.speed) > 0.6: phone_walkers[int(p.id)] = true

func _seq(id: int) -> String:
	var s := PackedStringArray()
	for e: Array in seen.get(id, []): s.append("%d for %.1f s (moved %.2f m)" % [int(e[0]), float(e[1]), float(e[3])])
	return ", then ".join(s)

func _find(id: int, act: int) -> Array:
	for e: Array in seen.get(id, []):
		if int(e[0]) == act: return e
	return []

func _physics_process(delta: float) -> bool:
	if crowd == null: return true
	t += delta
	_watch(delta)
	match step:
		0:
			if t < 6.0: return false
			for p: Dictionary in crowd.call(&"people_near", Vector3(0, 0, -620), 200.0):
				if int(p.mode) == 0 and int(p.state) == 0 and int(p.party) == 0 and float(p.speed) > 0.9:
					spot = p.at; dir = Vector3(sin(float(p.yaw)), 0, cos(float(p.yaw))); break
			if spot == Vector3.ZERO: _check(false, "no walker on a pavement within 200 m of the centre"); step = 99; return false
			var fl := StaticBody3D.new(); var cs := CollisionShape3D.new(); var sh := BoxShape3D.new()
			sh.size = Vector3(800, 2, 800); cs.shape = sh; fl.add_child(cs); fl.position = Vector3(spot.x, spot.y - 1.0, spot.z); root.add_child(fl)
			player = ClassDB.instantiate(&"CityPlayer")
			player.position = spot + dir * 3.0 + Vector3(-dir.z, 0, dir.x) * 2.2 + Vector3(0, 0.05, 0)
			root.add_child(player)
			crowd.call(&"set_player", player)
			step = 1; t0 = t
		1:      # somebody sits for 3 s, then is left alone
			if t - t0 < 1.0: return false
			var cl: PackedFloat32Array = crowd.call(&"stats").clip_seconds
			print("ACTS clips, seconds into / out of: a seat %.2f / %.2f, the ground %.2f / %.2f, lying %.2f / %.2f, a crouch %.2f / %.2f, a fight %.2f / %.2f; the start %.2f" % [cl[0], cl[1], cl[2], cl[3], cl[4], cl[5], cl[6], cl[7], cl[8], cl[9], cl[10]])
			_check(cl[1] > 0.3 and cl[7] > 0.2 and cl[9] > 0.2 and cl[4] > 0.5, "the pro packs' enter and exit clips are on the figure")
			a = int(crowd.call(&"place_walker", spot + dir * 3.0, 5151))
			g = int(crowd.call(&"place_walker", spot + dir * 4.4, 5252))      # (a woman or a man, whoever: sits on the ground)
			step = 12; t0 = t
		12:     # (a second for their animated bodies to be theirs: somebody set down this instant has none yet)
			if t - t0 < 1.0: return false
			crowd.call(&"set_act", a, 1, 3.0)
			crowd.call(&"set_act", g, 23, 4.0)
			step = 2; t0 = t
		2:
			if t - t0 < 7.0: return false
			var cl: PackedFloat32Array = crowd.call(&"stats").clip_seconds
			var sit := _find(a, 1); var up := _find(a, 22)
			_check(not sit.is_empty() and not up.is_empty() and absf(float(up[1]) - cl[1]) < 0.15 and float(up[3]) < 0.05, "sitting, then getting up where he is for the exit clip's %.2f s, then walking: %s" % [cl[1], _seq(a)])
			var ca: Array = clips.get(a, []); var cg: Array = clips.get(g, [])
			_check(ca.has("Sitting_Enter") and ca.has("Sitting_Exit") and ca.find("Sitting_Enter") < ca.find("Sitting_Exit") and ca.back().begins_with("Walk"), "his body played: %s" % " > ".join(PackedStringArray(ca)))
			_check(cg.has("GroundSit_Enter") and cg.has("GroundSit_Idle_Loop") and cg.has("GroundSit_Exit"), "the one on the ground played: %s" % " > ".join(PackedStringArray(cg)))
			var p := _person(a)
			_check(not p.is_empty() and int(p.act) == 0 and float(p.speed) > 0.5, "and he walks on (%.1f m/s)" % float(p.get("speed", 0.0)))
			seen.erase(a); clips.erase(a)
			crowd.call(&"set_act", a, 7, 2.0)      # a crouch
			step = 3; t0 = t
		3:
			if t - t0 < 5.0: return false
			var cl: PackedFloat32Array = crowd.call(&"stats").clip_seconds
			var up := _find(a, 22)
			var cd: Array = clips.get(a, [])
			_check(cd.has("Crouch_Enter") and cd.has("Crouch_Idle_Loop") and cd.has("Crouch_Exit"), "his body played: %s" % " > ".join(PackedStringArray(cd)))
			_check(not up.is_empty() and absf(float(up[1]) - cl[7]) < 0.15 and float(up[3]) < 0.05, "a crouch, then out of it for %.2f s where he is: %s" % [cl[7], _seq(a)])
			# two people fight
			b = int(crowd.call(&"place_walker", spot + dir * 1.0, 6262)); c = int(crowd.call(&"place_walker", spot + dir * 2.0, 7373))
			step = 13; t0 = t
		13:
			if t - t0 < 1.0: return false
			var pb := _person(b); var pc_ := _person(c)
			var ok: bool = crowd.call(&"fight", b, c)
			_check(ok and not pb.is_empty() and not pc_.is_empty(), "two people set to fight, %.2f m apart" % ((pb.at as Vector3).distance_to(pc_.at) if not pb.is_empty() and not pc_.is_empty() else -1.0))
			in_body = 0
			step = 4; t0 = t
		4:
			if trace and Engine.get_physics_frames() % 30 == 0:
				for n: Dictionary in crowd.call(&"near_bodies"):
					if int(n.walker) == b: print("ACTS   trace %.1f s: figure mode %d at %s clip %s" % [t - t0, int(n.figure_mode), str(n.at), String(n.clip)])
			if t - t0 < 20.0: return false
			var st: Dictionary = crowd.call(&"stats")
			var fb := _find(b, 13); var fc := _find(c, 13)
			_check(not fb.is_empty() and not fc.is_empty() and float(fb[1]) > 4.0, "both fought: %s | %s" % [_seq(b), _seq(c)])
			var cb: Array = clips.get(b, []); var cc: Array = clips.get(c, [])
			var blows := 0; var hits := 0
			for nm: String in cb + cc:
				if nm.begins_with("Punch_") or nm == "Kick" or nm.begins_with("Melee_"): blows += 1
				if nm.begins_with("Hit_") or nm.begins_with("Dodge_"): hits += 1
			_check(cb.has("PunchKick_Enter") and cc.has("PunchKick_Enter") and blows >= 3 and hits >= 2, "their bodies squared up and exchanged %d blows, %d taken or dodged: %s | %s" % [blows, hits, " > ".join(PackedStringArray(cb)), " > ".join(PackedStringArray(cc))])
			var won: Array = cb if cb.has("Celebration") else cc
			var lost: Array = cc if cb.has("Celebration") else cb
			_check(won.has("Celebration") and not lost.has("Celebration") and lost.has("Walk_Hurt_Loop") and not won.has("Walk_Hurt_Loop"), "one of them won and celebrates, the other walks away hurt (nobody dies): the loser's body ended with %s" % " > ".join(PackedStringArray(lost.slice(-5))))
			_check(int(st.fight_blows_landed) >= 1 and in_body >= 1, "the last blow was a real shove: %d landed, %d body handed to its physics (he staggers or falls by himself)" % [int(st.fight_blows_landed), in_body])
			var pb := _person(b); var pc_ := _person(c)
			print("ACTS   (the two afterwards: %s | %s | bodies: %s)" % [str(pb), str(pc_), str(crowd.call(&"near_bodies").filter(func(n: Dictionary) -> bool: return int(n.walker) in [b, c]))])
			_check(not pb.is_empty() and not pc_.is_empty() and int(pb.mode) != 7 and int(pc_.mode) != 7 and int(pb.act) != 13 and int(pc_.act) != 13, "afterwards both are on their feet and done with it (modes %d and %d)" % [int(pb.get("mode", -1)), int(pc_.get("mode", -1))])
			_check(int(st.inside_each_other) == 0 and int(st.bad_numbers) == 0, "nobody inside anybody, no bad number")
			print("ACTS seen walking with a phone within 60 m in this run: %d people (not a check)" % phone_walkers.size())
			step = 99
		99:
			print("RESULT %s" % ("PASS" if fails == 0 else "FAIL (%d)" % fails))
			quit(1 if fails else 0)
			return true
	return false
