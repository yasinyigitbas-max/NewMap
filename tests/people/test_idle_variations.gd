extends SceneTree
## The player's idle variations (Yasin, 21 Nov): standing on foot, step/idle plays 4 full loops, then ONE pidle/* take
## (Looking_Around_idle, Looking, Arm_Stretching, Neck_Stretching), then the base again; never two takes back to back, never
## the same take twice running; a move or a car cancels it at once; he never travels and his feet stay planted.
##   godot --headless --path . --fixed-fps 60 -s res://tests/people/test_idle_variations.gd
var player: CharacterBody3D
var sk: Skeleton3D
var lf := -1; var rf := -1
var n := 0; var fails := 0
var seq: Array = []; var base_starts: Array = []
var last_clip := ""; var t := 0.0; var phase := 0
var foot0 := []; var foot_most := 0.0; var pos0 := Vector3(); var pos_most := 0.0
var cancel_t := -1.0
const TAKES := ["pidle/Looking_Around_idle", "pidle/Looking", "pidle/Arm_Stretching", "pidle/Neck_Stretching"]

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
			if c in TAKES: seq.append(c)
			elif c == "step/idle": base_starts.append(t)
			last_clip = c
		if seq.size() >= 5 and c == "step/idle" and t > 4.0:
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
		_check(seq.size() >= 5, "%d takes came while he stood (%s)" % [seq.size(), ", ".join(seq)])
		var rep := 0
		for i in range(1, seq.size()): if seq[i] == seq[i - 1]: rep += 1
		_check(rep == 0, "no take twice running")
		var gaps := []
		for i in range(1, base_starts.size()): gaps.append(snappedf(base_starts[i] - base_starts[i - 1], 0.01))
		print("IDLEV   base starts at ", base_starts, " gaps ", gaps)
		_check(foot_most < 0.01, "feet planted through the takes and blends: most %.4f m" % foot_most)
		_check(pos_most < 0.01, "the body never travels: most %.4f m" % pos_most)
		print("IDLEV RESULT %s" % ("PASS" if fails == 0 else "FAIL (%d)" % fails))
		quit(0 if fails == 0 else 1); return true
	if t > 200.0: print("IDLEV RESULT FAIL (timeout, phase %d)" % phase); quit(1); return true
	return false
