extends SceneTree
## The crowd's people, frame by frame (C++: CityCrowd's near bodies, CityPed; Yasin, 20 Nov: "inspect for every animation
## in the game, talk, fight, walk etc, all of them", "i want them pixel perfect"), in a window:
##   godot --path . --rendering-method mobile --resolution 960x540 --fixed-fps 60 -s res://tests/people/trace_crowd.gd [-- --secs=40 --at=x,z]
## The people round a busy place at noon, their near bodies watched every physics frame: the feet, hips and hands as drawn,
## the clip, the act. Reported per clip and per switch between clips:
##  - POP: a foot, the hips or a hand jumping in one frame (over 3x the frames round it and over 4 cm)
##  - SLIDE: a walker's planted foot moving over the ground (it should stand still)
##  - FLOOR: a foot into the ground or a standing person floating
## With -- --acts: every 6 s the people nearest the camera are asked to do things (sit, phone, crouch, beg, wave, drink,
## call, sit on the ground, lie down, cheer, chat) and two of them to fight: their ways in and out are traced too.
var crowd: Node3D
var cam: Camera3D
var t := 0.0
var secs := 40.0
var at := Vector3(-12, 0, -606)
var hist := {}      # walker -> array of frames
var started := false
var acts := false
var next_acts := 6.0
var fights := 0
const ACTS := [1, 4, 7, 8, 9, 15, 19, 23, 2, 24, 10]
var act_k := 0
var watch := {}   # (the fighters: their frames round each pop are printed)

func _initialize() -> void:
	for a: String in OS.get_cmdline_user_args():
		if a.begins_with("--secs="): secs = float(a.trim_prefix("--secs="))
		if a == "--acts": acts = true
		if a.begins_with("--at="): var f := a.trim_prefix("--at=").split_floats(","); at = Vector3(f[0], 0, f[1])
	crowd = ClassDB.instantiate(&"CityCrowd"); crowd.set(&"max_people", 260); crowd.set(&"hour", 12.5); crowd.set(&"near_max", 18)
	root.add_child(crowd)
	cam = Camera3D.new(); root.add_child(cam); cam.current = true
	cam.look_at_from_position(at + Vector3(0, 9, -12), at, Vector3.UP)
	var sun := DirectionalLight3D.new(); sun.rotation_degrees = Vector3(-50, 35, 0); root.add_child(sun)

func _physics_process(delta: float) -> bool:
	t += delta
	if t < 6.0: return false
	if t > 6.0 + secs:
		var gs := 0.0; var gn := 0; var gm := 0.0; var gl := 0
		for nb: Dictionary in crowd.call(&"near_bodies"):
			if nb.has("gaps"): gs += float(nb.gap_mean) * int(nb.gaps); gn += int(nb.gaps); gm = maxf(gm, float(nb.gap_most)); gl += int(nb.gaps_by_lift)
		print("CROWD PINS let go %d times (%d as the foot lifted): the gap to the clip's foot then mean %.3f m, most %.3f m" % [gn, gl, gs / maxf(gn, 1), gm])
		_report(); quit(); return true
	var fr := int((t - 6.0) * 60.0)
	if acts and t >= next_acts:
		next_acts = t + 6.0
		var near: Array = crowd.call(&"people_near", at, 14.0)
		var free := []
		for p: Dictionary in near: if int(p.get("act", 0)) == 0: free.append(int(p.id))
		if fights < 3 and free.size() >= 2:
			if bool(crowd.call(&"fight", free[0], free[1])): fights += 1; watch[free[0]] = true; watch[free[1]] = true
			free = free.slice(2)
		for id in free.slice(0, 4):
			crowd.call(&"set_act", id, ACTS[act_k % ACTS.size()], 4.0); act_k += 1
	for nb: Dictionary in crowd.call(&"near_bodies"):
		if int(nb.figure_mode) != 0: continue   # (its balancing body: physics, not a clip)
		var w := int(nb.walker)
		if not hist.has(w): hist[w] = []
		(hist[w] as Array).append({"f": fr, "clip": String(nb.clip).trim_prefix("ual/"), "fl": nb.foot_l, "fr": nb.foot_r, "p": nb.pelvis, "hl": nb.hand_l, "hr": nb.hand_r, "v": float(nb.v), "g": float(nb.ground), "act": int(nb.act), "at": nb.get("at", Vector3.ZERO), "yaw": float(nb.get("yaw", 0.0))})
	return false

func _report() -> void:
	var by := {}
	var sw := {}
	var pops := []
	var people := 0
	for w in hist:
		var H: Array = hist[w]
		if H.size() < 12: continue
		people += 1
		for i in range(3, H.size() - 3):
			var f: Dictionary = H[i]
			if int(H[i - 3].f) != int(f.f) - 3 or int(H[i + 3].f) != int(f.f) + 3: continue   # (only runs of frames in a row)
			var c: String = f.clip
			if not by.has(c): by[c] = {"n": 0, "slide_n": 0, "slide": 0.0, "slide_max": 0.0, "sunk": 0.0, "float": 0.0, "pops": 0}
			var B: Dictionary = by[c]
			B.n += 1
			for key in ["fl", "fr"]:
				var hgt: float = (f[key] as Vector3).y - float(f.g) - 0.075
				B.sunk = minf(B.sunk, hgt)
				var lower: bool = (key == "fl") == ((f.fl as Vector3).y <= (f.fr as Vector3).y)
				# planted: within 1.5 cm of its own lowest over the 25 frames round it, and so two frames before and after
				var lo := 99.0
				for j in range(maxi(0, i - 12), mini(H.size(), i + 13)): lo = minf(lo, (H[j][key] as Vector3).y)
				if lower and (f[key] as Vector3).y - lo < 0.015 and (H[i - 2][key] as Vector3).y - lo < 0.015 and (H[i + 2][key] as Vector3).y - lo < 0.015:
					var v := Vector2((f[key] as Vector3).x - (H[i - 1][key] as Vector3).x, (f[key] as Vector3).z - (H[i - 1][key] as Vector3).z).length() * 60.0
					B.slide_n += 1; B.slide += v; B.slide_max = maxf(B.slide_max, v)
			if not c.begins_with("Sitting") and not c.begins_with("GroundSit") and not c.contains("Lay"):
				B.float = maxf(B.float, minf((f.fl as Vector3).y, (f.fr as Vector3).y) - float(f.g) - 0.075)
			for key in ["p", "fl", "fr", "hl", "hr"]:
				var mv := ((f[key] as Vector3) - (H[i - 1][key] as Vector3)).length()
				var round := []
				for j in [-3, -2, 2, 3]: round.append(((H[i + j][key] as Vector3) - (H[i + j - 1][key] as Vector3)).length())
				round.sort()
				var med: float = (round[1] + round[2]) * 0.5
				if mv > 0.04 and mv > med * 3.0:
					B.pops += 1
					var pair := "%s <- %s" % [c, String(H[i - 1].clip)]
					sw[pair] = int(sw.get(pair, 0)) + 1
					if watch.has(w) and pops.size() < 12:
						for j in range(i - 3, i + 3): print("FIGHTF walker %d frame %d %-16s at %s hips %s L %s R %s" % [w, int(H[j].f), String(H[j].clip), str(H[j].at), str(H[j].p), str(H[j].fl), str(H[j].fr)])
					if pops.size() < 40: pops.append("walker %d frame %d %-4s %.3f m (round it %.3f) %s" % [w, int(f.f), key, mv, med, pair])
	print("CROWD %d people traced near the camera for %.0f s" % [people, secs])
	for a2: String in OS.get_cmdline_user_args():
		if a2.begins_with("--walker="):
			var ww := int(a2.trim_prefix("--walker="))
			if hist.has(ww):
				for f in hist[ww]: print("CROWDF %d %-18s v %.2f L %s R %s hips %s ground %.2f" % [int(f.f), f.clip, float(f.v), str(f.fl), str(f.fr), str(f.p), float(f.g)])
	for c in by:
		var B: Dictionary = by[c]
		print("CROWD %-26s %5d frames | pops %3d | planted foot slides mean %.2f m/s worst %.2f (%d) | foot into the ground %.3f m | lower foot over it %.3f m" % [c, B.n, B.pops, B.slide / maxf(B.slide_n, 1), B.slide_max, B.slide_n, B.sunk, B.float])
	for pair in sw: print("CROWD SWITCH %-50s %d pops" % [pair, sw[pair]])
	for l in pops: print("CROWD POP " + l)
