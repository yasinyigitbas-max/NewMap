extends "res://tools/city/pilot/pieces/cc_fill_lib.gd"
## West fill helpers (University session, 20 Nov; review/fill_west/PLAN.md). Geometry and placement arithmetic only:
## every piece script decides what goes where. Pieces sit on a layout row (u0, 0, v0): local x = u - u0, z = v - v0,
## heights absolute (the land datum 0).

## the eased ground for a rectangle 0..W x 0..D: `land` everywhere, eased over R m to the measured heights of whatever
## borders each side (EDGE_* tables from OUT/site_hdr.py: [[t, h], ...] along x for N / S, along z for W / E)
static func edged(land: Callable, W: float, D: float, EN: Array, ES: Array, EW: Array, EE: Array, R := 8.0) -> Callable:
	var fn := func(x: float, _z: float) -> float: return prof(EN, x)
	var fs := func(x: float, _z: float) -> float: return prof(ES, x)
	var fw := func(_x: float, z: float) -> float: return prof(EW, z)
	var fe := func(_x: float, z: float) -> float: return prof(EE, z)
	return eased(land, [[Vector2(0, 0), Vector2(W, 0), fn], [Vector2(0, D), Vector2(W, D), fs], [Vector2(0, 0), Vector2(0, D), fw], [Vector2(W, 0), Vector2(W, D), fe]], R)

## a fence run a -> b of `panel` panels (width w) with `post` at every joint and both ends; panels stand at the lowest
## ground along them (-3 cm on a slope); gaps are the caller's (two runs)
func fence(panel: String, post: String, w: float, a: Vector2, b: Vector2, reason: String, cond := "worn") -> void:
	var L2 := a.distance_to(b)
	if L2 < 0.2: return
	var n := maxi(1, int(ceil(L2 / w))); var dir := (b - a).normalized(); var step := L2 / n
	var yaw := rad_to_deg(atan2(dir.x, dir.y)) + 90.0
	# panels flush with both ends (the first starts at a, the last ends at b, the overlap shared between them), so no
	# panel pokes past the run's end (the iron() rule of cc_fill_lib)
	for i in n:
		var m: Vector2 = a + dir * (w * 0.5 + (L2 - w) * float(i) / float(n - 1)) if n > 1 else a.lerp(b, 0.5)
		put(panel, cond, Vector3(m.x, _low(m, dir, w * 0.5), m.y), yaw, reason, false)
	for i in n + 1:
		var pp: Vector2 = a + dir * (step * i)
		put(post, cond, Vector3(pp.x, yf(pp.x, pp.y), pp.y), yaw, "fence post at every joint", false)

func chainlink(a: Vector2, b: Vector2, reason: String) -> void: fence("fence_chainlink_lot", "fence_chainlink_lot_post", 2.0, a, b, reason)
func privacy(a: Vector2, b: Vector2, reason: String) -> void: fence("fence_wood_privacy", "fence_post_privacy", 2.01, a, b, reason)
func picket(a: Vector2, b: Vector2, reason: String) -> void: fence("fence_picket_white", "fence_post_picket", 2.0, a, b, reason, "clean")

## a closed run round a polygon with one gap of width `gap` centred `at` m along the side `side_i` (0 = first side);
## the gate leaf (if given) fills it, its two jambs are the posts of the runs either side
func ring_fence(kind: String, pts: Array, side_i: int, at: float, gap: float, gate: String, reason: String) -> void:
	for i in pts.size():
		var a: Vector2 = pts[i]; var b: Vector2 = pts[(i + 1) % pts.size()]
		if i != side_i:
			call(kind, a, b, reason); continue
		var dir := (b - a).normalized()
		var g0: Vector2 = a + dir * (at - gap * 0.5); var g1: Vector2 = a + dir * (at + gap * 0.5)
		call(kind, a, g0, reason); call(kind, g1, b, reason)
		if gate != "":
			var m := (g0 + g1) * 0.5
			put(gate, "worn", Vector3(m.x, _low(m, dir, gap * 0.5), m.y), rad_to_deg(atan2(dir.x, dir.y)) + 90.0, "the gate in the fence", false)
