extends SceneTree
## The player's moves in play, frame by frame (C++: CityPlayer, CityPed, FootPlant; Yasin, 20 Nov: "inspect for every
## animation in the game ... all of them", "i want them pixel perfect"), in a window:
##   godot --path . --rendering-method mobile --resolution 960x540 --fixed-fps 60 -s res://tests/people/trace_locomotion.gd [-- --frames]
## A tour on a flat floor: idle, walk, jog, sprint, stop, a walking turn, crouch-walk, stand, a jump and its landing, idle.
## Every physics frame: the feet and hips as drawn (after the foot plant), the clip, the speed. Per part of the tour:
##  - SLIDE: a planted foot (the lower, within 4 cm of the floor) moving over the ground: its speed (should be ~0)
##  - POP: the hips or a foot jumping in one frame (over 3x the frames round it and over 3 cm), and which clips met there
##  - FLOOR: a foot under the floor (sunk) or the lower foot well over it (floating)
var player: CharacterBody3D
var cam: Camera3D
var t := 0.0
var frames := []
var part := ""
const TOUR := [
	[1.5, "idle", Vector2.ZERO, false, false],
	[3.0, "walk", Vector2(0, 0.55), false, false],
	[3.0, "jog", Vector2(0, 0.9), false, false],
	[3.0, "sprint", Vector2(0, 1.0), true, false],
	[1.5, "stop", Vector2.ZERO, false, false],
	[3.0, "walk turning", Vector2(0.45, 0.4), false, false],
	[0.6, "crouch down", Vector2.ZERO, false, true],
	[2.5, "crouch walk", Vector2(0, 0.7), false, true],
	[1.2, "stand up", Vector2.ZERO, false, false],
	[2.0, "jump", Vector2.ZERO, false, false],
	[1.5, "idle", Vector2.ZERO, false, false],
]
var seg := -1
var seg_t := 0.0

func _initialize() -> void:
	var b := StaticBody3D.new(); var cs := CollisionShape3D.new(); var sh := BoxShape3D.new(); sh.size = Vector3(400, 2, 400); cs.shape = sh; b.add_child(cs)
	var mi := MeshInstance3D.new(); var bm := BoxMesh.new(); bm.size = sh.size; mi.mesh = bm; b.add_child(mi); b.position = Vector3(0, -1, 0); root.add_child(b)
	var sun := DirectionalLight3D.new(); sun.rotation_degrees = Vector3(-50, 35, 0); root.add_child(sun)
	player = ClassDB.instantiate(&"CityPlayer"); player.position = Vector3(0, 0.05, 0); root.add_child(player)
	cam = Camera3D.new(); root.add_child(cam)

func _physics_process(delta: float) -> bool:
	t += delta
	cam.current = true
	cam.look_at_from_position(player.global_position + Vector3(3.5, 1.5, 1.0), player.global_position + Vector3(0, 0.8, 0), Vector3.UP)
	if t < 1.0: return false
	seg_t += delta
	if seg < 0 or seg_t >= float(TOUR[seg][0]):
		seg += 1; seg_t = 0.0
		if seg >= TOUR.size(): _report(); quit(); return true
		var s: Array = TOUR[seg]
		player.call(&"set_move", s[2], s[3])
		player.call(&"set_crouch", s[4])
		if s[1] == "jump": player.call(&"jump")
		part = s[1]
	var f: Dictionary = player.call(&"get_frame_log")
	f["part"] = part
	frames.append(f)
	return false

func _report() -> void:
	var by := {}
	var pops := []
	for i in range(3, frames.size() - 3):
		var f: Dictionary = frames[i]
		if not f.has("foot_l"): continue
		var p: String = f.part
		if not by.has(p): by[p] = {"slide_n": 0, "slide_sum": 0.0, "slide_max": 0.0, "sunk": 0.0, "float": 0.0, "n": 0}
		var B: Dictionary = by[p]
		B.n += 1
		var floor_y := 0.0
		for side in ["foot_l", "foot_r"]:
			var a: Vector3 = f[side]; var pr: Vector3 = frames[i - 1][side]
			var hgt := a.y - floor_y - 0.085   # (the ankle over the sole)
			B.sunk = minf(B.sunk, hgt)
			var lower: bool = (side == "foot_l") == ((f.foot_l as Vector3).y <= (f.foot_r as Vector3).y)
			var nxt: Vector3 = frames[i + 2][side]; var pr2: Vector3 = frames[i - 2][side]
			if lower and hgt < 0.04 and nxt.y - 0.085 < 0.04 and pr2.y - 0.085 < 0.04:   # (mid stance: planted two frames before and after)
				var v := Vector2(a.x - pr.x, a.z - pr.z).length() * 60.0
				B.slide_n += 1; B.slide_sum += v; B.slide_max = maxf(B.slide_max, v)
		B.float = maxf(B.float, minf((f.foot_l as Vector3).y, (f.foot_r as Vector3).y) - floor_y - 0.085)
		# pops: the hips or a foot in one frame, against the frames round it
		for key in ["pelvis_drawn", "foot_l", "foot_r"]:
			var mv := ((f[key] as Vector3) - (frames[i - 1][key] as Vector3)).length()
			var round := []
			for j in [-3, -2, 2, 3]: round.append(((frames[i + j][key] as Vector3) - (frames[i + j - 1][key] as Vector3)).length())
			round.sort()
			var med: float = (round[1] + round[2]) * 0.5
			if mv > 0.03 and mv > med * 3.0: pops.append("F%04d %-12s %-13s %.3f m (round it %.3f) clip %s <- %s" % [i, p, key, mv, med, frames[i].clip, frames[i - 1].clip])
	for p in by:
		var B: Dictionary = by[p]
		print("LOCO %-13s %4d frames | planted foot slides: mean %.2f m/s, worst %.2f m/s (%d planted frames) | deepest into the floor %.3f m | lower foot highest over it %.3f m" % [p, B.n, B.slide_sum / maxf(B.slide_n, 1), B.slide_max, B.slide_n, B.sunk, B.float])
	for l in pops: print("LOCO POP " + l)
	print("LOCO %d pops" % pops.size())
	if OS.get_cmdline_user_args().has("--frames"):
		for i in frames.size():
			var f: Dictionary = frames[i]
			if f.has("foot_l"): print("LOCOF %04d %-12s %-20s sp %.2f L %s R %s hips %s lock %s slide R %s" % [i, f.part, String(f.clip).trim_prefix("ual/"), float(f.speed), str(f.foot_l), str(f.foot_r), str(f.pelvis_drawn), str(f.get("lock", "")), str(f.get("slide_r", ""))])
