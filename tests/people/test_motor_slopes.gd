extends SceneTree
## The new movement system on slopes, stairs and kerbs (docs/ANIMATION_PLAN.md step 4; Yasin, 22 Nov: "slope or tight
## area walk"): each lane a thing across his way, walked and run over, up and down the far side.
##   godot --headless --path . --fixed-fps 60 -s res://tests/people/test_motor_slopes.gd [-- --trace]
## Per lane it prints and checks:
##   over      he gets up and down the far side, the new system had him all the way (no old code, no vault / climb)
##   float     a planted foot (the clip's own contact, as drawn after the IK) higher over the ground right under its
##   sink      ankle than on the flat (+), or lower (-); cm
##   slide     a planted foot moving over the ground while planted; cm
##   pop       the biggest change of the hips' rise from one frame to the next (a stair lifts the body 17 cm at once:
##             the hips must not); cm
##   drop      the most the hips were lowered for a lower foot; cm
## What it cannot see: the knees, the lean, the look on a slope - Yasin plays it.
var player: CharacterBody3D
var sk: Skeleton3D
var b_pel := -1; var b_ft := [-1, -1]
var fails := 0
var trace := false
const LEN := 6.0   # a ramp's run
const TOP := 3.0
# [kind, size, run]
const LANES := [
	["flat", 0.0, false], ["flat", 0.0, true],
	["ramp", 8.0, false], ["ramp", 8.0, true], ["ramp", 15.0, false], ["ramp", 15.0, true],
	["ramp", 22.0, false], ["ramp", 22.0, true], ["ramp", 30.0, false],
	["stairs", 0.17, false], ["stairs", 0.17, true], ["stairs", 0.12, false],
	["kerb", 0.15, false], ["kerb", 0.15, true],
]
var lane := -1; var t := 0.0
var base := [0.0, 0.0]; var base_n := [0, 0]   # the flat's planted ankle height, walking / running (the jog's contact is lower)
var end_z := 0.0; var top_h := 0.0
var s_float := 0.0; var s_sink := 0.0; var s_slide := 0.0; var s_pop := 0.0; var s_drop := 0.0; var s_off := 0; var s_trav := 0
var top_seen := -9.0
var plant := [null, null]
var pel_prev := Vector3(); var dy_prev := 0.0; var have := 0

func _box(size: Vector3, at: Vector3) -> void:
	var b := StaticBody3D.new(); var cs := CollisionShape3D.new(); var sh := BoxShape3D.new(); sh.size = size; cs.shape = sh; b.add_child(cs)
	b.position = at; root.add_child(b)

func _ramp(x: float, ang: float) -> void:
	var h := LEN * tan(deg_to_rad(ang))
	var pts := PackedVector3Array()
	for xx in [x - 1.5, x + 1.5]:
		for p in [Vector3(xx, 0, 2.0), Vector3(xx, h, 2.0 + LEN), Vector3(xx, h, 2.0 + LEN + TOP), Vector3(xx, 0, 2.0 + 2 * LEN + TOP)]: pts.append(p)
	var b := StaticBody3D.new(); var cs := CollisionShape3D.new(); var sh := ConvexPolygonShape3D.new(); sh.points = pts; cs.shape = sh; b.add_child(cs)
	root.add_child(b)

func _stairs(x: float, rise: float) -> void:
	var tread := 0.28; var n := 8
	for i in n:   # up
		_box(Vector3(3.0, rise * (i + 1), tread), Vector3(x, rise * (i + 1) * 0.5, 2.0 + tread * (i + 0.5)))
	var top := rise * n
	_box(Vector3(3.0, top, 2.0), Vector3(x, top * 0.5, 2.0 + tread * n + 1.0))
	for i in n:   # down
		var hh := rise * (n - i)
		_box(Vector3(3.0, hh, tread), Vector3(x, hh * 0.5, 2.0 + tread * n + 2.0 + tread * (i + 0.5)))

func _initialize() -> void:
	trace = OS.get_cmdline_user_args().has("--trace")
	_box(Vector3(400, 2, 80), Vector3(60, -1, 10))
	for i in LANES.size():
		var L = LANES[i]; var x := i * 6.0
		match L[0]:
			"ramp": _ramp(x, L[1])
			"stairs": _stairs(x, L[1])
			"kerb": _box(Vector3(3.0, L[1], 3.0), Vector3(x, L[1] * 0.5, 2.0 + 1.5))   # (up a kerb, 3 m along its top, down)
	player = ClassDB.instantiate(&"CityPlayer"); player.position = Vector3(0, 0.02, -2); root.add_child(player)

func _ground(p: Vector3) -> float:
	var q := PhysicsRayQueryParameters3D.create(p + Vector3(0, 0.5, 0), p - Vector3(0, 0.8, 0))
	q.exclude = [player.get_rid()]
	var h := player.get_world_3d().direct_space_state.intersect_ray(q)
	return (h.position as Vector3).y if not h.is_empty() else -99.0

func _next() -> void:
	lane += 1
	if lane >= LANES.size(): _finish(); return
	var L = LANES[lane]
	player.global_position = Vector3(lane * 6.0, 0.02, -1.0); player.velocity = Vector3.ZERO
	player.call(&"set_move", Vector2.ZERO, false)
	t = 0.0; s_float = 0.0; s_sink = 0.0; s_slide = 0.0; s_pop = 0.0; s_drop = 0.0; s_off = 0; s_trav = 0; top_seen = -9.0
	plant = [null, null]; have = 0
	match L[0]:
		"flat": end_z = 14.0; top_h = 0.0
		"ramp": end_z = 2.0 + 2 * LEN + TOP + 1.5; top_h = LEN * tan(deg_to_rad(L[1]))
		"stairs": end_z = 2.0 + 0.28 * 16 + 2.0 + 1.5; top_h = L[1] * 8
		"kerb": end_z = 2.0 + 3.0 + 1.5; top_h = L[1]

func _process(delta: float) -> bool:
	if not player or not player.is_inside_tree(): return false
	if sk == null:
		var s := player.find_children("*", "Skeleton3D", true, false)
		if s.is_empty(): return false
		sk = s[0]; b_pel = sk.find_bone("Bip01_Pelvis"); b_ft = [sk.find_bone("Bip01_L_Foot"), sk.find_bone("Bip01_R_Foot")]
		sk.skeleton_updated.connect(_on_pose)
		_next(); return false
	if lane >= LANES.size(): return true
	t += delta
	var L = LANES[lane]
	if t > 0.5: player.call(&"set_move", Vector2(0, 1), L[2])
	var p := player.global_position
	if L[0] != "flat" and p.z > 2.5 and p.z < end_z - 2.0: top_seen = maxf(top_seen, p.y)
	if p.z > end_z or t > 24.0:
		player.call(&"set_move", Vector2.ZERO, false)
		_judge(); _next()
	return false

var pose_frame := -1; var snap_ok := false
var snap_pel := Vector3(); var snap_ft := [Vector3(), Vector3()]; var snap_ms := {}
func _on_pose() -> void:
	var f := Engine.get_process_frames()
	if f != pose_frame and snap_ok: _sample()
	pose_frame = f
	snap_pel = sk.global_transform * sk.get_bone_global_pose(b_pel).origin
	for s in 2: snap_ft[s] = sk.global_transform * sk.get_bone_global_pose(b_ft[s]).origin
	snap_ms = player.call(&"get_motor_state")
	snap_ok = true

func _sample() -> void:
	if lane < 0 or lane >= LANES.size() or t < 0.6: return
	var ms: Dictionary = snap_ms
	var st: String = ms.get("state", "off")
	if st == "off":
		s_off += 1
		if trace: print("TRACEOFF lane %d t %.3f floor %s y %.3f ground %.3f v %s clip %s" % [lane, t, str(player.is_on_floor()), player.global_position.y, _ground(player.global_position), str(player.velocity), str(player.call(&"get_clip"))])
	if st == "trav": s_trav += 1
	s_drop = maxf(s_drop, float(ms.get("drop", 0.0)))
	var flat: bool = LANES[lane][0] == "flat"
	for s in 2:
		var down: bool = st != "off" and bool(ms.get(["down_l", "down_r"][s], false)) and not bool(ms.get(["step_l", "step_r"][s], false))
		var a: Vector3 = snap_ft[s]
		if not down: plant[s] = null; continue
		var over := a.y - _ground(a)
		var g: int = 1 if LANES[lane][2] else 0
		if flat:
			base[g] += over; base_n[g] += 1
		elif base_n[g] > 0:
			var d: float = over - base[g] / base_n[g]
			s_float = maxf(s_float, d); s_sink = maxf(s_sink, -d)
			if trace and absf(d) > 0.03: print("TRACEF lane %d t %.2f %s foot %d over %.3f (flat %.3f) at %s %s" % [lane, t, ms.get("clip", ""), s, over, base[g] / base_n[g], str(a), st])
		if plant[s] == null: plant[s] = a
		s_slide = maxf(s_slide, Vector2(a.x - plant[s].x, a.z - plant[s].z).length())
	var pel: Vector3 = snap_pel
	if have > 1: s_pop = maxf(s_pop, absf((pel.y - pel_prev.y) - dy_prev))
	if have > 0: dy_prev = pel.y - pel_prev.y
	if trace: print("TRACE lane %d t %.3f %s %s pel %s drop %.3f draw %.3f body %.3f" % [lane, t, st, ms.get("clip", ""), str(pel), float(ms.get("drop", 0.0)), float(ms.get("draw_y", 0.0)), player.global_position.y])
	pel_prev = pel; have += 1

func _check(ok: bool, what: String) -> void:
	if not ok: fails += 1
	print("SLOPES  %s: %s" % ["ok  " if ok else "FAIL", what])

func _judge() -> void:
	var L = LANES[lane]
	var name := "%s %s %s" % [L[0], ("%d deg" % int(L[1])) if L[0] == "ramp" else ("%.2f m" % L[1]) if L[0] != "flat" else "", "running" if L[2] else "walking"]
	var p := player.global_position
	print("SLOPES  %-26s over %s (at %s, top %.2f / %.2f)  float %4.1f sink %4.1f slide %4.1f pop %4.1f drop %4.1f cm  old code %d trav %d frames" % [name, str(p.z > end_z - 0.1), str(p.snapped(Vector3.ONE * 0.01)), top_seen, top_h, s_float * 100, s_sink * 100, s_slide * 100, s_pop * 100, s_drop * 100, s_off, s_trav])
	if L[0] == "flat":
		var g: int = 1 if L[2] else 0
		print("SLOPES  (flat: a planted ankle %.3f m over the ground)" % [base[g] / maxf(base_n[g], 1)])
		return
	_check(p.z > end_z - 0.1 and absf(p.y) < 0.1 and top_seen > top_h - 0.1, "%s: up and down the far side" % name)
	_check(s_off == 0 and s_trav == 0, "%s: the new system had him all the way (old code %d, trav %d frames)" % [name, s_off, s_trav])
	var lim := 0.03 if (L[0] != "ramp" or L[1] <= 15.0) else 0.05
	if L[0] == "ramp" and L[1] > 25.0: lim = 0.08
	_check(s_float < lim and s_sink < lim, "%s: planted feet on the ground (float %.1f, sink %.1f < %d cm)" % [name, s_float * 100, s_sink * 100, int(lim * 100)])
	_check(s_slide < 0.03, "%s: planted feet do not slide (%.1f < 3 cm)" % [name, s_slide * 100])
	_check(s_pop < 0.03, "%s: no hip pop (%.1f < 3 cm)" % [name, s_pop * 100])

func _finish() -> void:
	print("RESULT %s" % ("PASS" if fails == 0 else "FAIL (%d)" % fails))
	quit(1 if fails else 0)
