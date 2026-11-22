extends SceneTree
## CityPlayer's outdoor moves (Yasin, 22 Nov): carrying (one hand: a bag, a briefcase; two: a box, a crate) standing,
## walking, jogging, the fast run, starts, stops and turns; the bench (sit down from the front, the side and from
## behind, sit, get up); pick up / put down; bumps (a pole at a walk, a jog, the fast run); a kerb caught at a run; the
## sidestep through a tight gap; the look-at; the lean on a wall. A planted foot's slide (as drawn, after the foot plant)
## is measured all through; for the carry against the same course with empty hands.
##   godot --headless --path . --fixed-fps 60 -s res://tests/people/test_player_moves.gd [-- female] [-- carry bench pick bump trip side look lean]
var player: Node3D
var fails := 0
var female := false
var only := []
var dbg := false
var res := {}

func _check(ok: bool, what: String) -> void:
	if not ok: fails += 1
	print("MOVES  %s: %s" % ["ok" if ok else "FAIL", what])

func _box(at: Vector3, size: Vector3) -> StaticBody3D:
	var b := StaticBody3D.new(); var cs := CollisionShape3D.new(); var sh := BoxShape3D.new(); sh.size = size; cs.shape = sh; b.add_child(cs)
	b.position = at + Vector3(0, size.y * 0.5, 0); root.add_child(b); return b

func _initialize() -> void:
	var a := OS.get_cmdline_user_args()
	female = "female" in a; dbg = "dbg" in a
	for k in ["carry", "bench", "pick", "bump", "trip", "side", "look", "lean"]: if k in a: only.append(k)
	if only.is_empty(): only = ["carry", "bench", "pick", "bump", "trip", "side", "look", "lean"]
	var g := StaticBody3D.new(); var gc := CollisionShape3D.new(); var gs := BoxShape3D.new(); gs.size = Vector3(600, 2, 600); gc.shape = gs; g.add_child(gc); g.position = Vector3(0, -1, 0); root.add_child(g)
	# the bench: its seat 0.42 m up, 1.6 m long, a back; the sitter faces +z (its seat point at x 100, z 0)
	_box(Vector3(100, 0, -0.05), Vector3(1.6, 0.42, 0.45)); _box(Vector3(100, 0.42, -0.3), Vector3(1.6, 0.5, 0.06))
	var seat := Node3D.new(); seat.position = Vector3(100, 0, 0); seat.set_meta("seat_len", 1.6); root.add_child(seat); seat.add_to_group("player_seat")
	# the pick-up: a low stand (0.36 m) and a box on it
	_box(Vector3(120, 0, 0), Vector3(0.5, 0.36, 0.5))
	# the poles (bumps): 0.1 m round, 2.5 m
	for i in 3: _box(Vector3(140 + i * 10, 0, 6), Vector3(0.16, 2.5, 0.16))
	# the kerb: 0.15 m, from z 8 on
	_box(Vector3(180, 0, 18), Vector3(6, 0.15, 20))
	# the gap: two posts 0.52 m apart (inside)
	_box(Vector3(199.64, 0, 6), Vector3(0.2, 2.0, 0.3)); _box(Vector3(200.36, 0, 6), Vector3(0.2, 2.0, 0.3))
	# the look-at point: a sign 1.8 m up, 3 m off the walk
	var lk := Node3D.new(); lk.position = Vector3(223, 1.8, 6); root.add_child(lk); lk.add_to_group("player_look")
	# the wall to lean on: 3 m high
	_box(Vector3(240, 0, 2), Vector3(4, 3, 0.3))
	player = ClassDB.instantiate(&"CityPlayer"); player.position = Vector3(0, 0.05, 0)
	if female: player.set(&"body_id", "F1")
	root.add_child(player)
	_run.call_deferred()

# the planted feet (as drawn): the most a foot slid while planted, by clip
var prev := [Vector3(), Vector3()]; var plant_at := [Vector3(), Vector3()]; var on := [false, false]
var slide_by := {}; var mx_slide := 0.0; var miss_most := 0.0; var gap_least := 9.0
func _clear() -> void:
	slide_by = {}; mx_slide = 0.0; on = [false, false]; prev = [Vector3(), Vector3()]; miss_most = 0.0; gap_least = 9.0

func _frame() -> void:
	await physics_frame
	var f: Dictionary = player.call(&"get_frame_log")
	var m: Dictionary = player.call(&"get_moves")
	if dbg and Engine.get_physics_frames() % 20 == 0: print("MOVES    f%d %s act %d trav %d carry %s w %.2f miss %.3f %.3f fit %.2f gap %.2f up %s pel %.2f to %s wp %d go %s at %s" % [Engine.get_physics_frames(), f.get("clip", ""), int(m.get("act", 0)), int(f.get("trav", 0)), m.get("carry", ""), float(m.get("carry_w", 0.0)), float(m.get("miss_l", 0.0)), float(m.get("miss_r", 0.0)), float(m.get("fit", 1.0)), float(m.get("chest_gap", 0.0)), m.get("up_clip", ""), (f.get("pelvis", Vector3()) as Vector3).y, m.get("go_to", Vector3()), int(m.get("go_wp", 0)), m.get("go_p", Vector3()), player.global_position])
	if String(m.get("carry", "")) != "" and float(m.get("carry_w", 0.0)) > 0.95:
		miss_most = maxf(miss_most, maxf(float(m.get("miss_l", 0.0)), float(m.get("miss_r", 0.0))))
		if bool(m.get("two", false)): gap_least = minf(gap_least, float(m.get("chest_gap", 9.0)))
	if not bool(f.get("plant_on", false)): on = [false, false]; prev = [Vector3(), Vector3()]; return
	var feet := [f.get("foot_l", Vector3()), f.get("foot_r", Vector3())]
	for k in 2:
		var a: Vector3 = feet[k]
		var v := (a - (prev[k] as Vector3)).length() * 60.0 if prev[k] != Vector3() else 99.0
		prev[k] = a
		var g := a.y - _ground(a)
		var now := g < 0.14 and v < 0.6
		if now and not on[k]: plant_at[k] = a
		on[k] = now
		if not now: continue
		var s := Vector2(a.x - (plant_at[k] as Vector3).x, a.z - (plant_at[k] as Vector3).z).length()
		if s < 1.0:
			var c := String(f.get("clip", ""))
			slide_by[c] = maxf(float(slide_by.get(c, 0.0)), s)
			mx_slide = maxf(mx_slide, s)

func _ground(p: Vector3) -> float:
	var q := PhysicsRayQueryParameters3D.create(p + Vector3(0, 0.6, 0), p - Vector3(0, 1.0, 0))
	q.exclude = [player.get_rid()]
	var h := player.get_world_3d().direct_space_state.intersect_ray(q)
	return (h.position as Vector3).y if not h.is_empty() else -99.0

func _go(dir: Vector2, tier: int) -> void: player.call(&"set_move_tier", dir, tier)
func _stop() -> void: player.call(&"set_move_tier", Vector2(), 0)
func _wait(sec: float) -> void:
	for i in int(sec * 60.0): await _frame()
func _put(at: Vector3, face := 0.0) -> void:
	_stop(); player.global_position = at; player.call(&"set_facing", face)
	for i in 50: await physics_frame
	_clear()
func _mv() -> Dictionary: return player.call(&"get_moves")
func _worst(d: Dictionary) -> String:
	var k := ""; var w := -1.0
	for c in d: if float(d[c]) > w: w = float(d[c]); k = c
	return "%.3f (%s)" % [w, k]

# the course of a carry: stand, walk, stop, jog, fast run, stop, a turn at a walk and at a jog
func _carry_course(x: float) -> void:
	await _put(Vector3(x, 0.05, 0))
	await _wait(1.5)
	_go(Vector2(0, 1), 0); await _wait(4.0)
	_stop(); await _wait(2.0)
	_go(Vector2(0, 1), 1); await _wait(4.0)
	_go(Vector2(0, 1), 2); await _wait(3.0)
	_stop(); await _wait(2.5)
	_go(Vector2(1, 0), 0); await _wait(3.0)
	_go(Vector2(0, -1), 1); await _wait(3.0)
	_stop(); await _wait(2.0)

func _run() -> void:
	for i in 30: await physics_frame
	# (the view: forward is +z at the start; the tests steer in its frame)
	if "carry" in only:
		await _carry_course(0.0)
		var base := slide_by.duplicate(); var base_mx := mx_slide
		print("MOVES  carry: empty hands, planted feet slide at most %s" % _worst(base))
		for prop in (["box_moving"] if dbg else ["bag_paper_kraft", "briefcase_leather", "backpack_daypack", "box_moving", "crate_wine", "box_long"]):
			player.call(&"set_carry", prop)
			await _carry_course(20.0)
			var m := _mv()
			var two := bool(m.get("two", false))
			print("MOVES  carry %s (%s): slide at most %s; the palms off the grips at most %.3f m; the prop clear of the chest by %.2f m; take %s" % [prop, "two hands" if two else "one hand", _worst(slide_by), miss_most, gap_least, m.get("up_clip", "")])
			res["carry " + prop] = [mx_slide, miss_most]
			_check(String(m.get("carry", "")) == prop, "carry %s: still in his hands at the end" % prop)
			_check(mx_slide <= base_mx + 0.03, "carry %s: the feet slide no more than with empty hands (%.3f vs %.3f)" % [prop, mx_slide, base_mx])
			_check(miss_most < (0.04 if two else 0.02), "carry %s: the hands on the grips (%.3f m)" % [prop, miss_most])
			if two: _check(gap_least >= 0.085, "carry %s: the prop clear of his chest (%.2f m from the spine; the chest is about 0.09 deep there)" % [prop, gap_least])
		player.call(&"set_carry", "")
	if "bench" in only:
		var starts := [[Vector3(100.3, 0.05, 2.2), PI], [Vector3(102.4, 0.05, 0.4), -PI * 0.5], [Vector3(99.4, 0.05, -2.0), 0.0]]
		var names := ["front", "side", "behind"]
		for i in 3:
			await _put(starts[i][0], starts[i][1])
			var n0 := int(_mv().get("sit", 0))
			player.call(&"interact_move")
			var sat := false; var t := 0.0; var hips := Vector3(); var n_p0 := int(_mv().get("go_pause", 0))
			while t < 22.0:
				await _frame(); t += 1.0 / 60.0
				if int(_mv().get("act", 0)) == 3: sat = true; break
			var down_slide := mx_slide
			await _wait(2.0)
			var f: Dictionary = player.call(&"get_frame_log"); hips = f.get("pelvis", Vector3())
			var seat: Vector3 = _mv().get("seat", Vector3())
			var go_miss := float(_mv().get("go_miss", 0.0))
			_clear()
			player.call(&"interact_move")
			t = 0.0
			while t < 6.0:
				await _frame(); t += 1.0 / 60.0
				if int(_mv().get("act", 0)) == 0 and int(player.call(&"get_trav").get("mode", 0)) == 0: break
			await _wait(1.0)
			var up_slide := mx_slide
			var hd := Vector2(hips.x - seat.x, hips.z - seat.z).length()
			print("MOVES  bench from the %s: sat %s in %.1f s, the walk there left %.2f m to ease in; the hips %.2f m from the seat point, %.2f m up; slide sitting down %.3f, getting up %.3f; worst %s" % [names[i], sat, t, go_miss, hd, hips.y, down_slide, up_slide, _worst(slide_by)])
			res["bench " + names[i]] = [go_miss, hd, hips.y, down_slide, up_slide]
			_check(sat and int(_mv().get("sit", 0)) == n0 + 1, "bench from the %s: sits down" % names[i])
			_check(hd < 0.12 and absf(hips.y - 0.49) < 0.06, "bench from the %s: on the seat (%.2f m off, hips %.2f m up)" % [names[i], hd, hips.y])
			_check(down_slide < 0.15 and up_slide < 0.15, "bench from the %s: a planted foot slides under 0.15 m (%.3f / %.3f)" % [names[i], down_slide, up_slide])
			_check(int(_mv().get("stand", 0)) >= i + 1 and player.global_position.y < 0.2, "bench from the %s: gets up again" % names[i])
	if "pick" in only:
		for k in 2:
			var box: Node3D = (load("res://map_dc/coronado/city_kit/carry/scenes/box_ship_small.scn") as PackedScene).instantiate()
			root.add_child(box); box.global_position = Vector3(120, 0.36, 0); box.set_meta("carry", "box_ship_small"); box.add_to_group("player_pickup")
			await _put(Vector3(120.0 + [0.2, -1.8][k], 0.05, [-2.0, 1.2][k]), [0.0, PI * 0.7][k])
			player.call(&"interact_move")
			var t := 0.0
			while t < 14.0:
				await _frame(); t += 1.0 / 60.0
				if String(_mv().get("carry", "")) != "" and int(_mv().get("act", 0)) == 0: break
			var got := String(_mv().get("carry", "")) == "box_ship_small"
			var gm := float(_mv().get("go_miss", 0.0)); var ps := mx_slide
			_go(Vector2(0, 1), 0); await _wait(2.5); _stop(); await _wait(1.5)
			_clear()
			player.call(&"interact_move")
			t = 0.0
			while t < 12.0:
				await _frame(); t += 1.0 / 60.0
				if String(_mv().get("carry", "")) == "" and int(_mv().get("act", 0)) == 0: break
			await _wait(0.6)
			var on_ground := absf(box.global_position.y - 0.0) < 0.05
			print("MOVES  pick up %d: got it %s (the walk there left %.2f m), slide %.3f; put down: down %s at y %.2f, slide %.3f" % [k, got, gm, ps, String(_mv().get("carry", "")) == "", box.global_position.y, mx_slide])
			_check(got, "pick up %d: the box in his hands" % k)
			_check(String(_mv().get("carry", "")) == "" and on_ground, "put down %d: the box on the ground (y %.2f)" % [k, box.global_position.y])
			_check(ps < 0.15 and mx_slide < 0.15, "pick up / put down %d: a planted foot slides under 0.15 m (%.3f / %.3f)" % [k, ps, mx_slide])
			box.queue_free()
	if "bump" in only:
		for k in 3:
			var x := 140.0 + k * 10
			await _put(Vector3(x, 0.05, 1.0))
			var n0 := int(_mv().get("bump", 0))
			_go(Vector2(0, 1), k)   # (toward +z: the view's forward at the start)
			var t := 0.0; var hit := ""
			while t < 8.0:
				await _frame(); t += 1.0 / 60.0
				if int(_mv().get("bump", 0)) > n0 and hit == "": hit = String(_mv().get("last", "")); _stop()
				if hit != "" and int(_mv().get("act", 0)) == 0 and int(player.call(&"get_trav").get("mode", 0)) == 0: break
			await _wait(0.5)
			print("MOVES  bump at tier %d: %s, back on his feet %s, slide %s" % [k, hit, int(player.call(&"get_trav").get("mode", 0)) == 0, _worst(slide_by)])
			_check(hit != "", "bump at tier %d: the pole stops him (a bump move)" % k)
			_check(int(player.call(&"get_trav").get("mode", 0)) == 0 and player.global_position.y < 0.3, "bump at tier %d: on his feet again" % k)
	if "trip" in only:
		player.call(&"set_trip_chance", 1.0)
		for k in [1, 2]:
			await _put(Vector3(180, 0.05, 2.0))
			var n0 := int(_mv().get("trip", 0))
			_go(Vector2(0, 1), k)
			var t := 0.0; var what := ""
			while t < 8.0:
				await _frame(); t += 1.0 / 60.0
				if int(_mv().get("trip", 0)) > n0 and what == "": what = String(_mv().get("last", ""))
				if what != "" and int(_mv().get("act", 0)) == 0 and int(player.call(&"get_trav").get("mode", 0)) == 0: break
			_stop(); await _wait(1.0)
			print("MOVES  kerb at tier %d: %s; on the kerb at y %.2f; slide %s" % [k, what, player.global_position.y, _worst(slide_by)])
			_check(what != "", "kerb at tier %d: caught (a stumble or a trip)" % k)
			_check(absf(player.global_position.y - 0.15) < 0.1, "kerb at tier %d: up on it after (y %.2f)" % [k, player.global_position.y])
		player.call(&"set_trip_chance", 0.15)
	if "side" in only:
		await _put(Vector3(200, 0.05, 3.5))
		var n0 := int(_mv().get("side", 0))
		_go(Vector2(0, 1), 0)
		var t := 0.0
		while t < 8.0 and player.global_position.z < 9.0:
			await _frame(); t += 1.0 / 60.0
		_stop(); await _wait(1.0)
		print("MOVES  gap 0.52 m: sidestep %d, through to z %.2f in %.1f s, slide %s" % [int(_mv().get("side", 0)) - n0, player.global_position.z, t, _worst(slide_by)])
		_check(int(_mv().get("side", 0)) > n0, "gap: the sidestep")
		_check(player.global_position.z > 8.0, "gap: through it")
		_check(mx_slide < 0.15, "gap: a planted foot slides under 0.15 m (%.3f)" % mx_slide)
	if "look" in only:
		await _put(Vector3(220, 0.05, 0.0))
		_go(Vector2(0, 1), 0)
		var most := 0.0; var yw := 0.0
		for i in 360:
			await _frame()
			var m := _mv()
			if float(m.get("look_w", 0.0)) > most: most = float(m.get("look_w", 0.0)); yw = float(m.get("look_yaw", 0.0))
		_stop()
		print("MOVES  look-at: weight %.2f, head turned %.0f degrees" % [most, rad_to_deg(yw)])
		_check(most > 0.8 and absf(yw) > 0.25, "look-at: the head turns to the sign")
	if "lean" in only:
		await _put(Vector3(240, 0.05, 1.4), PI)
		player.call(&"interact_move")
		await _wait(3.0)
		var tr: Dictionary = player.call(&"get_trav")
		var leaned := int(tr.get("mode", 0)) == 3
		print("MOVES  lean: %s (%s)" % [leaned, _mv().get("last", "")])
		_check(leaned and int(_mv().get("lean", 0)) >= 1, "lean: his back to the wall")
		player.call(&"interact_move")
		await _wait(3.0)
		_check(int(player.call(&"get_trav").get("mode", 0)) == 0, "lean: off the wall again")
	print("MOVES  results: %s" % [res])
	print("MOVES  %s (%d failed)" % ["ALL OK" if fails == 0 else "FAILED", fails])
	quit(1 if fails > 0 else 0)
