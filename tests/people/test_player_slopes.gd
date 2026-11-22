extends SceneTree
## CityPlayer on slopes (Yasin, 22 Nov: "walk/run up and down hills and ramps, feet planted, no float or sink"): ramps of
## 8, 15, 22 and 30 degrees, each up onto a plateau and down the other side; he walks and jogs over every one. A foot on
## the ground (its ankle near the ground under it, still) is measured as drawn (after the foot plant): its ankle's and
## its ball's height over the ground right under each, against the same on the flat (float +, sink -), and its slide.
## He must stay on his feet (no fall, no jump-down) and get over every ramp.
##   godot --headless --path . --fixed-fps 60 -s res://tests/people/test_player_slopes.gd [-- female] [-- slopes]
var player: Node3D
var fails := 0
var female := false
var dbg := false
const ANG := [8.0, 15.0, 22.0, 30.0]
const L := 8.0        # (each ramp's run, m)
const TOP := 4.0      # (the plateau)
var base_a := 0.0; var base_t := 0.0; var base_n := 0
var res := {}

func _check(ok: bool, what: String) -> void:
	if not ok: fails += 1
	print("SLOPE  %s: %s" % ["ok" if ok else "FAIL", what])

func _wedge(x: float, ang: float) -> void:
	var h := L * tan(deg_to_rad(ang))
	var pts := PackedVector3Array()
	# up ramp from z 0 to L, plateau to L+TOP, down to 2L+TOP; 4 m wide
	for xx in [x - 2.0, x + 2.0]:
		pts.append(Vector3(xx, 0, 0)); pts.append(Vector3(xx, h, L)); pts.append(Vector3(xx, h, L + TOP)); pts.append(Vector3(xx, 0, 2 * L + TOP))
	var b := StaticBody3D.new(); var cs := CollisionShape3D.new(); var sh := ConvexPolygonShape3D.new(); sh.points = pts; cs.shape = sh; b.add_child(cs)
	root.add_child(b)

func _initialize() -> void:
	female = "female" in OS.get_cmdline_user_args(); dbg = "slopes" in OS.get_cmdline_user_args()
	var g := StaticBody3D.new(); var gc := CollisionShape3D.new(); var gs := BoxShape3D.new(); gs.size = Vector3(600, 2, 600); gc.shape = gs; g.add_child(gc); g.position = Vector3(0, -1, 0); root.add_child(g)
	for i in ANG.size(): _wedge(20.0 * (i + 1), ANG[i])
	player = ClassDB.instantiate(&"CityPlayer"); player.position = Vector3(0, 0.05, -10)
	if female: player.set(&"body_id", "F1")
	root.add_child(player)
	_run.call_deferred()

func _ground(p: Vector3) -> float:
	var q := PhysicsRayQueryParameters3D.create(p + Vector3(0, 0.6, 0), p - Vector3(0, 1.0, 0))
	q.exclude = [player.get_rid()]
	var h := player.get_world_3d().direct_space_state.intersect_ray(q)
	return (h.position as Vector3).y if not h.is_empty() else -99.0

var prev := [Vector3(), Vector3()]; var plant_at := [Vector3(), Vector3()]; var on := [false, false]
var mx_float := 0.0; var mx_sink := 0.0; var mx_slide := 0.0; var n_on := 0; var sum_a := 0.0; var sum_t := 0.0
var trav_seen := 0; var air_seen := 0; var pel_jump := 0.0; var pel_prev := Vector3()

func _clear() -> void:
	mx_float = 0.0; mx_sink = 0.0; mx_slide = 0.0; n_on = 0; sum_a = 0.0; sum_t = 0.0; trav_seen = 0; air_seen = 0; pel_jump = 0.0
	on = [false, false]; prev = [Vector3(), Vector3()]; pel_prev = Vector3()

func _frame(measure: bool) -> void:
	await physics_frame
	var f: Dictionary = player.call(&"get_frame_log")
	if int(f.get("trav", 0)) != 0: trav_seen += 1
	if not bool(player.call(&"is_on_floor")): air_seen += 1
	var pel: Vector3 = f.get("pelvis_drawn", Vector3())
	if pel_prev != Vector3(): pel_jump = maxf(pel_jump, (pel - pel_prev).length())
	pel_prev = pel
	var feet := [f.get("foot_l", Vector3()), f.get("foot_r", Vector3())]
	var soles := [f.get("sole_l", PackedVector3Array([Vector3(), Vector3()])), f.get("sole_r", PackedVector3Array([Vector3(), Vector3()]))]
	for k in 2:
		var a: Vector3 = feet[k]; var hl: Vector3 = (soles[k] as PackedVector3Array)[0]; var tl: Vector3 = (soles[k] as PackedVector3Array)[1]
		# (ga: the ankle over the ground under it; gt: the sole's lower end (heel or ball, modelled: the foot bone's ankle,
		#  turned as the foot plant turned it) over the ground under that end)
		var ga := a.y - _ground(a); var gt := minf(hl.y - _ground(hl), tl.y - _ground(tl))
		var v := (a - (prev[k] as Vector3)).length() * 60.0 if prev[k] != Vector3() else 99.0
		prev[k] = a
		var now := ga < 0.13 and v < 0.6
		if now and not on[k]: plant_at[k] = a
		on[k] = now
		if not now or not measure: continue
		n_on += 1; sum_a += ga; sum_t += gt
		var da := ga - base_a; var dt := gt - base_t
		# (the sole's lower end against the ground: a foot "floats" if both its ankle and ball are above their flat heights,
		#  "sinks" if either is under)
		var fl := dt; var sk := dt
		if fl > mx_float: mx_float = fl
		if sk < -mx_sink: mx_sink = -sk
		var s := Vector2(a.x - (plant_at[k] as Vector3).x, a.z - (plant_at[k] as Vector3).z).length()
		if s > mx_slide and s < 1.0: mx_slide = s
		if dbg and (fl > 0.03 or sk < -0.03): print("SLOPE      f%d %s %s ankle %.3f sole %.3f (d %.3f %.3f) at %s drop %.3f" % [Engine.get_physics_frames(), "LR"[k], f.get("clip", ""), ga, gt, da, dt, a, float(f.get("hips_drop", 0.0))])

func _go(tier: int) -> void: player.call(&"set_move_tier", Vector2(0, 1), tier)
func _stop() -> void: player.call(&"set_move_tier", Vector2(), 0)
func _wait(sec: float, measure := true) -> void:
	for i in int(sec * 60.0): await _frame(measure)

func _put(at: Vector3) -> void:
	_stop(); player.global_position = at; player.call(&"set_facing", 0.0)
	await _wait(0.8, false)
	_clear()

func _run() -> void:
	await _wait(0.5, false)
	# THE FLAT: what a planted foot's ankle and ball sit at over the ground (the clips' own)
	for tier in [0, 1]:
		await _put(Vector3(0, 0.05, -40))
		_go(tier); await _wait(4.0)
		_stop(); await _wait(1.5)
		print("SLOPE  flat %s: ankle %.3f sole %.3f over the ground (%d planted frames), slide %.3f, hips %.3f m a frame" % [["walk", "jog"][tier], sum_a / maxf(n_on, 1), sum_t / maxf(n_on, 1), n_on, mx_slide, pel_jump])
		base_a += sum_a / maxf(n_on, 1) * 0.5; base_t += sum_t / maxf(n_on, 1) * 0.5
	for i in ANG.size():
		for tier in [0, 1]:
			var x := 20.0 * (i + 1)
			await _put(Vector3(x, 0.05, -4))
			var h := L * tan(deg_to_rad(ANG[i]))
			_go(tier)
			var up_ok := false; var top_y := -9.0
			for fr in int(((2 * L + TOP + 10) / (1.2 if tier == 0 else 3.0)) * 60.0 + 240):
				await _frame(true)
				var z := player.global_position.z
				if z > L + 1.0 and z < L + TOP - 1.0: top_y = maxf(top_y, player.global_position.y); up_ok = true
				if z > 2 * L + TOP + 4.0: break
			_stop(); await _wait(1.0)
			var what := "%d deg %s" % [int(ANG[i]), ["walk", "jog"][tier]]
			var over := player.global_position.z > 2 * L + TOP + 2.0 and absf(player.global_position.y) < 0.2
			print("SLOPE  %s: float %.3f sink %.3f (feet against the flat), slide %.3f, hips %.3f m a frame, %d planted frames, top y %.2f (want %.2f), trav %d, air %d frames" % [what, mx_float, mx_sink, mx_slide, pel_jump, n_on, top_y, h, trav_seen, air_seen])
			res[what] = [mx_float, mx_sink, mx_slide]
			_check(up_ok and over and absf(top_y - h) < 0.25, "%s: up onto the top and down the other side" % what)
			_check(trav_seen == 0, "%s: no traversal move (no jump-down off the slope)" % what)
			if ANG[i] <= 22.0:
				var lim := 0.05 if ANG[i] <= 15.0 else 0.07   # (22 degrees: a steep street; the sole modelled level-on-the-slope, the clip's own roll not)
				_check(mx_float < lim and mx_sink < lim, "%s: a planted foot neither floats nor sinks over %d cm (%.3f / %.3f)" % [what, int(lim * 100), mx_float, mx_sink])
				_check(mx_slide < 0.15, "%s: a planted foot slides under 0.15 m (%.3f)" % [what, mx_slide])
	print("SLOPE  results: %s" % [res])
	print("SLOPE  %s (%d failed)" % ["ALL OK" if fails == 0 else "FAILED", fails])
	quit(1 if fails > 0 else 0)
