extends SceneTree
## The player's idle (Yasin, 21 Nov 23:19): standing on foot, a long Mixamo base loop (pidle/base_*) plays 15-30 s, then ONE
## fidget (Looking_Around_idle, Looking, Arm_Stretching, Neck_Stretching, Bored), then a DIFFERENT base; never the same base or
## fidget twice running; step/idle (UAL) never plays; a move or a car cancels it at once; he never travels.
##   godot --headless --path . --fixed-fps 60 -s res://tests/people/test_idle_variations.gd
var player: CharacterBody3D
var sk: Skeleton3D
var lf := -1; var rf := -1
var n := 0; var fails := 0
var seq: Array = []; var base_starts: Array = []
var last_clip := ""; var t := 0.0; var phase := 0
var foot0 := []; var foot_most := 0.0; var pos0 := Vector3(); var pos_most := 0.0
var cancel_t := -1.0
var bases: Array = []; var all_seq: Array = []; var seg_t := 0.0; var seg_c := ""; var spans: Array = []; var ual_seen := 0
var seg_f0 := []; var hold_most := 0.0
const TAKES := ["pidle/Looking_Around_idle", "pidle/Looking", "pidle/Arm_Stretching", "pidle/Neck_Stretching", "pidle/Bored", "pidle/Idle_Transition"]   # (22 Nov 01:23: + Idle Transition)

func _check(ok: bool, what: String) -> void:
	if not ok: fails += 1
	print("IDLEV   %s: %s" % ["ok" if ok else "FAIL", what])

func _initialize() -> void:
	var b := StaticBody3D.new(); var cs := CollisionShape3D.new(); var sh := BoxShape3D.new(); sh.size = Vector3(40, 2, 40); cs.shape = sh; b.add_child(cs)
	b.position = Vector3(0, -1, 0); root.add_child(b)
	player = ClassDB.instantiate(&"CityPlayer"); player.position = Vector3(0, 0.05, 0); root.add_child(player)

func _feet() -> Array:
	return [(sk.global_transform * sk.get_bone_global_pose(lf)).origin, (sk.global_transform * sk.get_bone_global_pose(rf)).origin]

func _process(dt: float) -> bool:
	n += 1; t += dt
	if n == 5:
		sk = player.find_children("*", "Skeleton3D", true, false)[0]
		lf = sk.find_bone("Bip01_L_Foot"); rf = sk.find_bone("Bip01_R_Foot")
	if n < 5: return false
	var c := String(player.call(&"get_clip"))
	if phase == 0:
		if t > 2.0 and foot0.is_empty(): foot0 = _feet(); pos0 = player.global_position
		if not foot0.is_empty():
			var f := _feet()
			foot_most = max(foot_most, max(Vector2(f[0].x - foot0[0].x, f[0].z - foot0[0].z).length(), Vector2(f[1].x - foot0[1].x, f[1].z - foot0[1].z).length()))
			pos_most = max(pos_most, player.global_position.distance_to(pos0))
		if c != last_clip:
			print("IDLEV   t=%.2f %s" % [t, c])
			if last_clip.begins_with("pidle/base_"): spans.append(t - seg_t)
			if c in TAKES: seq.append(c); all_seq.append(c)
			elif c.begins_with("pidle/base_"): bases.append(c); all_seq.append(c); base_starts.append(t)
			elif c == "step/idle" or c.begins_with("ual/Idle"): ual_seen += 1
			last_clip = c; seg_t = t; seg_f0 = []
		if t - seg_t > 1.0 and c.begins_with("pidle/"):
			if seg_f0.is_empty(): seg_f0 = _feet()
			var g := _feet()
			hold_most = max(hold_most, max(Vector2(g[0].x - seg_f0[0].x, g[0].z - seg_f0[0].z).length(), Vector2(g[1].x - seg_f0[1].x, g[1].z - seg_f0[1].z).length()))
		if seq.size() >= 6 and c.begins_with("pidle/base_") and t > 4.0:
			phase = 1; t = 0.0
	elif phase == 1:
		if c in TAKES and cancel_t < 0.0:
			player.call(&"set_move", Vector2(0, 1), false); cancel_t = t
		elif cancel_t >= 0.0:
			if c in TAKES and t - cancel_t > 0.05: _check(false, "a move cancels the take (still %s after %.2f s)" % [c, t - cancel_t]); phase = 2; t = 0.0
			elif not (c in TAKES): _check(true, "a move cancels the take at once (%.3f s: %s)" % [t - cancel_t, c]); phase = 2; t = 0.0
		if t > 40.0: _check(false, "no take came for the move check"); phase = 2; t = 0.0
	elif phase == 2:
		player.call(&"set_move", Vector2(0, 0), false)
		if t > 1.0: phase = 3; t = 0.0
	elif phase == 3:
		if c in TAKES:
			player.call(&"set_frozen", true); phase = 4; t = 0.0
		if t > 40.0: _check(false, "no take came for the car check"); phase = 5
	elif phase == 4:
		var d: Dictionary = player.call(&"get_frame_log")
		if t > 0.05:
			_check(int(d.get("idle_take", 9)) == -1, "entering a car (frozen) cancels the take (idle_take %s)" % d.get("idle_take"))
			phase = 5
	if phase == 5:
		print("IDLEV   sequence: ", ", ".join(all_seq.map(func(x): return String(x).trim_prefix("pidle/"))))
		_check(seq.size() >= 6, "%d fidgets came while he stood" % seq.size())
		var rep := 0
		for i in range(1, seq.size()): if seq[i] == seq[i - 1]: rep += 1
		_check(rep == 0, "no fidget twice running")
		var brep := 0
		for i in range(1, bases.size()): if bases[i] == bases[i - 1]: brep += 1
		_check(brep == 0, "no base loop twice running (%d bases)" % bases.size())
		var alt := true
		for i in range(1, all_seq.size()): if String(all_seq[i]).begins_with("pidle/base_") == String(all_seq[i - 1]).begins_with("pidle/base_"): alt = false
		_check(alt, "base, fidget, base, fidget ... alternate")
		var sp_ok := true
		for x in spans: if x < 14.5 or x > 30.5: sp_ok = false
		_check(sp_ok and spans.size() >= 5, "each base plays 15-30 s: %s" % str(spans.map(func(x): return snappedf(x, 0.1))))
		var kinds := {}
		for x in bases: kinds[x] = true
		_check(kinds.size() >= 3, "%d different bases came" % kinds.size())
		_check(ual_seen == 0, "the UAL / step idle never plays (%d)" % ual_seen)
		print("IDLEV   feet: most %.3f m from where they stood at the start (crossfades between stances included); most %.3f m within one take after its blend" % [foot_most, hold_most])
		# (Idle Transition steps 18 cm and the Action Adventure idle (3) 20 cm by themselves, 22 Nov; Bored 9.8 cm)
		_check(hold_most < 0.22, "within a take the feet move no more than the mocap does (Action Adventure idle (3) shifts a foot 20 cm by itself): %.3f m" % hold_most)
		_check(pos_most < 0.01, "the body never travels: most %.4f m" % pos_most)
		print("IDLEV RESULT %s" % ("PASS" if fails == 0 else "FAIL (%d)" % fails))
		quit(0 if fails == 0 else 1); return true
	if t > 320.0: print("IDLEV RESULT FAIL (timeout, phase %d)" % phase); quit(1); return true
	return false
