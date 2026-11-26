extends RefCounted
## Stage 7: the measuring routine. It only measures; nothing is played. The study: "Build obstacle detection as a
## separate piece that only measures and draws its result on screen. It should produce one record: obstacle top height
## above the character's ground, the near edge position and wall facing direction, depth (how far the top extends),
## whether the top has room to stand, the far edge and landing ground height if the obstacle is thin, and free width
## on top."
##
## The queries follow the study's list: forward ("A short sphere `cast_motion` from inside the character's own
## capsule, at two or three heights ... Then `get_rest_info` at the touch point for the wall direction"), top, room
## ("An `intersect_shape` test of the standing (or crouching) capsule on top"), landing, ceiling. Every probe is a
## thin sphere, not a ray ("rays slip on shared triangle edges"), starts from a place known to be free ("a cast
## ignores whatever it starts inside") and is reached from the character's own capsule by other casts, and is set a
## millimetre off the capsule's centre line ("Offset every sphere probe by a millimetre").
##
## One departure in method, said here: the study finds the top with a cast straight down "from above the maximum
## climb height ... just beyond the wall face". Under a roof that cast lands on the roof, not on the wall. So the top
## is first found from below, by trying the wall face at rising heights, and only then measured exactly by a short
## cast down onto it.
##
## Call measure() when a move is asked for or he walks into something, not every tick (the study: "run detection
## only when the player asks for a move or walks into something").

const R := 0.03                 # the thin probe sphere (m). NOT in the study beyond "thin"
const R_FWD := 0.05             # the forward probe sphere
const OFF := Vector3(0.001, 0.0, 0.001)     # "Offset every sphere probe by a millimetre"
const REACH := 1.5              # NOT in the study: how far ahead he looks (m)
# Heights of the forward probes above his ground: under the floating capsule for kerbs and steps (the lowest kerb
# is 0.10 m), then knee, hip and chest. The study says "two or three heights"; four are used so that a 0.10 m kerb
# and a rail at chest height are both met. NOT in the study: the heights themselves.
const FWD_HEIGHTS := [0.06, 0.5, 1.0, 1.5]
const CLIMB_MOST := 3.0         # the study: "above 3.0 m | not climbable"
const LOOK_UP := 3.3            # the wall face is tried up to here: "From above the maximum climb height"
const DEPTH_MOST := 4.3         # NOT in the study: the top is followed no further than this (m)
const WIDTH_MOST := 1.6         # NOT in the study: the top's free width is followed this far to each side (m)
const GAP_MOST := 3.0           # NOT in the study: a far side is looked for this far across a gap (m)
const DROP_MOST := 3.5          # NOT in the study: the ground below an edge is looked for this far down (m)
const SAME_TOP := 0.08          # NOT in the study: the top goes on while it stays within this of its height at the edge (m)
# "the vault-or-climb-on split must come from the measured forward reach of the vault clip you choose": no vault
# clip is chosen yet, so until then an obstacle he could not stand on, one shallower than his own capsule, is "thin".
const THIN_UNDER := 0.5         # NOT in the study: twice the capsule's radius (m)
const WALK_SLOPE_DEG := 50.0    # the body's own limit (body.gd SLOPE_LIMIT_DEG): ground he can stand on is not an obstacle
const STEP_DOWN := 0.30         # the body's own: ground this far below the feet is still ground

var body: CharacterBody3D
var _space: PhysicsDirectSpaceState3D
var _shape := SphereShape3D.new()
var _capsule := CapsuleShape3D.new()
var queries := 0                # how many physics queries the last measure() made


func _q(r: float, at: Vector3, motion: Vector3) -> PhysicsShapeQueryParameters3D:
	_shape.radius = r
	var q := PhysicsShapeQueryParameters3D.new()
	q.shape = _shape
	q.exclude = [body.get_rid()]
	q.collision_mask = body.collision_mask
	q.transform = Transform3D(Basis.IDENTITY, at)
	q.motion = motion
	queries += 1
	return q


## Move a sphere from `at` along `motion`: how far it gets before it touches something, or -1 if it gets all the way.
func _sweep(at: Vector3, motion: Vector3, r := R) -> float:
	if motion.length() < 0.0005:
		return -1.0         # "A zero-length cast returns nothing"
	var f := _space.cast_motion(_q(r, at, motion))
	if f.is_empty() or f[1] >= 1.0:
		return -1.0
	return motion.length() * f[1]


## The surface under `at` (a point in free space), looked for `reach` down: its height, or NAN.
func _down(at: Vector3, reach: float) -> float:
	var d := _sweep(at, Vector3.DOWN * reach)
	return NAN if d < 0.0 else at.y - d - R


## Go from `from` to `to` (both at one height) and look down: the height of the surface there, NAN if there is none
## within `reach`, INF if the way there is shut.
func _step_down(from: Vector3, to: Vector3, reach: float) -> float:
	if _sweep(from, to - from) >= 0.0:
		return INF
	return _down(to, reach)


## Does the body fit with its feet at `feet`? The body's own capsule, a little thinner (see body.gd, STAND_ROOM).
func _fits(feet: Vector3, tall: float) -> bool:
	_space = body.get_world_3d().direct_space_state       # (it is also asked without a measurement before it)
	var fl := float(body.get(&"FLOAT"))
	_capsule.radius = float(body.get(&"RADIUS")) - 0.03
	_capsule.height = maxf(tall - fl - 0.03, 2.0 * _capsule.radius)
	var q := PhysicsShapeQueryParameters3D.new()
	q.shape = _capsule
	q.exclude = [body.get_rid()]
	q.collision_mask = body.collision_mask
	q.transform = Transform3D(Basis.IDENTITY, feet + Vector3.UP * (fl + (tall - fl) * 0.5))
	queries += 1
	return _space.intersect_shape(q, 1).is_empty()


## Measure what is ahead of him the way `dir` points (horizontal). Returns the record; `kind` is "none", "obstacle",
## "gap" or "drop". Heights are above his own ground.
func measure(dir: Vector3, from_y := INF) -> Dictionary:
	queries = 0
	_space = body.get_world_3d().direct_space_state
	dir = Vector3(dir.x, 0.0, dir.z)
	if dir.length() < 0.001:
		return {"kind": "none"}
	dir = dir.normalized()
	var feet := body.global_position
	var col := feet + OFF
	# "above the character's ground": the ground he last stood squarely on. Within a step's length of a kerb the
	# floating body is already rising onto it, and measured from his feet a 0.20 m kerb read as 0.12 m.
	var ground := float(body.get(&"_stood_y")) if int(body.get(&"state")) == 0 else feet.y
	if absf(ground - feet.y) > STEP_DOWN:
		ground = feet.y
	# (`from_y` given = he is in the air from a jump: it is measured as from the ground under him, at that height.
	# Measured from his feet in the air, the ground ahead read as a drop and a wall beyond it was not seen.)
	if from_y != INF:
		feet.y = from_y
		col = feet + OFF
		ground = from_y
	var rec := _wall(col, ground, dir)
	if rec.is_empty():
		rec = _edge(col, ground, dir)
	if rec.is_empty():
		rec = {"kind": "none"}
	rec["queries"] = queries
	return rec


# ------------------------------------------------------------------------------------------------ something that stands up

func _wall(col: Vector3, ground: float, dir: Vector3) -> Dictionary:
	# 1. Forward: the nearest thing met that he could not simply walk up
	var best := INF
	var n := Vector3.ZERO
	var h0 := 0.0
	for h: float in FWD_HEIGHTS:
		var from := col + Vector3.UP * h
		var d := _sweep(from, dir * REACH, R_FWD)
		if d < 0.0 or d >= best:
			continue
		var q := _q(R_FWD, from + dir * d, Vector3.ZERO)
		q.margin = 0.02
		var info := _space.get_rest_info(q)
		if info.is_empty():
			continue
		var normal: Vector3 = info["normal"]
		if normal.y > cos(deg_to_rad(WALK_SLOPE_DEG)):
			continue        # ground he can walk on
		var flat := Vector3(normal.x, 0.0, normal.z)
		if flat.length() < 0.2:
			continue
		best = d
		n = flat.normalized()
		h0 = h
	if best == INF or n.dot(dir) > -0.2:
		return {}
	var fwd := -n
	# how far the face is from his centre line, straight at it
	var face := (dir * best).dot(fwd) + R_FWD
	if face > REACH:
		return {}
	# 5. Ceiling: how high the space over his own head is free
	var up_from := col + Vector3.UP * 1.0
	var ceil_d := _sweep(up_from, Vector3.UP * (LOOK_UP - 1.0), R_FWD)
	var cap := LOOK_UP if ceil_d < 0.0 else 1.0 + ceil_d - 0.02
	# 2. Top: the face is tried at rising heights until a probe passes over it
	var solid := h0
	var free := -1.0
	var h := h0
	while h < cap:
		h = minf(h + 0.25, cap)
		var d := _sweep(col + Vector3.UP * h, fwd * (face + 0.08))
		if d < 0.0:
			free = h
			break
		solid = h
	var rec := {"kind": "obstacle", "normal": n, "face": face, "from": col, "ground": ground, "ceiling": cap if ceil_d >= 0.0 else INF}
	if free < 0.0:
		# the face goes on up as far as could be tried
		rec["top"] = INF
		rec["blocked"] = ceil_d >= 0.0      # under a ceiling its top cannot be seen at all
		rec["too_high"] = ceil_d < 0.0
		rec["edge"] = col + fwd * face + Vector3.UP * cap
		return rec
	for i in 5:
		var mid := (solid + free) * 0.5
		if _sweep(col + Vector3.UP * mid, fwd * (face + 0.08)) < 0.0:
			free = mid
		else:
			solid = mid
	# ... and measured exactly by a short cast down onto it, just beyond the face
	var over := col + Vector3.UP * free + fwd * (face + 0.06)
	var top_y := _down(over, free + 0.2)
	if is_nan(top_y):
		top_y = ground + free - R
	var top := top_y - ground
	if top < 0.03:
		return {}
	rec["top"] = top
	rec["too_high"] = top > CLIMB_MOST
	var edge := Vector3(col.x, top_y, col.z) + fwd * face
	rec["edge"] = edge
	# headroom over the top: what is free straight above it
	var clear_d := _sweep(over, Vector3.UP * 2.2)
	var clear := (2.2 if clear_d < 0.0 else clear_d + R) + (over.y - top_y)
	rec["clear"] = clear
	var crouch_tall := float(body.get(&"CROUCH_HEIGHT"))
	var tall := float(body.get(&"HEIGHT"))
	rec["blocked"] = clear < crouch_tall
	# the height the top is followed at: over it, under whatever is above it
	var ride := top_y + minf(0.15, clear * 0.5)
	var start := Vector3(over.x, ride, over.z)
	if _sweep(over, start - over) >= 0.0:
		start = over
	# Depth: "Repeat at several distances forward to measure depth and find the far edge"
	var d_res := _follow(start, fwd, top_y, DEPTH_MOST, 0.25)
	var depth: float = float(d_res["len"]) + 0.06
	rec["depth"] = depth
	rec["depth_open"] = bool(d_res["open"])         # followed to DEPTH_MOST and still going
	rec["backed"] = bool(d_res["shut"])             # the top ends at something standing on or behind it
	rec["thin"] = depth < THIN_UNDER
	rec["far_edge"] = edge + fwd * depth
	# 3. Room: does he fit on top, standing or crouched, just inside the edge?
	var rad := float(body.get(&"RADIUS"))
	var on_top := Vector3(col.x, top_y, col.z) + fwd * (face + rad + 0.05)
	rec["stand_at"] = on_top
	rec["stand_room"] = depth >= THIN_UNDER and _fits(on_top, tall)
	rec["crouch_room"] = depth >= THIN_UNDER and (bool(rec["stand_room"]) or _fits(on_top, crouch_tall))
	# 4. Landing: "For a thin obstacle, a downward thin sphere cast beyond the far edge for the landing height"
	if not bool(d_res["open"]) and not bool(d_res["shut"]):
		var end: Vector3 = d_res["end"]
		var beyond := end + fwd * (rad + 0.10)
		var ly := _step_down(end, beyond, (ride - ground) + DROP_MOST)
		if ly != INF and not is_nan(ly):
			rec["landing"] = ly - ground
			rec["land_at"] = Vector3(beyond.x, ly, beyond.z)
			rec["landing_ok"] = _fits(Vector3(beyond.x, ly, beyond.z), tall)
	# Free width on top, to each side of where he would arrive
	var side := fwd.cross(Vector3.UP).normalized()
	var w_from := start + fwd * minf(0.04, depth * 0.3)
	var right := _follow(w_from, side, top_y, WIDTH_MOST, 0.2)
	var left := _follow(w_from, -side, top_y, WIDTH_MOST, 0.2)
	rec["width"] = float(right["len"]) + float(left["len"])
	rec["width_open"] = bool(right["open"]) and bool(left["open"])
	return rec


## Follow a top surface from `start` (a free point just over it) the way `way` points, for as long as it stays at
## the height `top_y`. Returns {len, open (still going at `most`), shut (ended at something in the way), end}.
func _follow(start: Vector3, way: Vector3, top_y: float, most: float, step: float) -> Dictionary:
	var reach := (start.y - top_y) + 0.12
	var good := 0.0
	var at := start
	var s := 0.0
	while s < most:
		var next_s := minf(s + step, most)
		var y := _step_down(at, start + way * next_s, reach)
		if y == INF:
			# something stands in the way: the top ends where the probe was stopped
			var d := _sweep(at, start + way * next_s - at)
			return {"len": s + maxf(d, 0.0) + R, "open": false, "shut": true, "end": at + way * maxf(d, 0.0)}
		if is_nan(y) or absf(y - top_y) > SAME_TOP:
			# the edge is between here and the last good place
			var lo := good
			var hi := next_s
			for i in 6:
				var mid := (lo + hi) * 0.5
				var ym := _step_down(start + way * lo, start + way * mid, reach)
				if ym == INF or is_nan(ym) or absf(ym - top_y) > SAME_TOP:
					hi = mid
				else:
					lo = mid
			return {"len": lo, "open": false, "shut": false, "end": start + way * hi}
		good = next_s
		at = start + way * next_s
		s = next_s
	return {"len": most, "open": true, "shut": false, "end": at}


# ------------------------------------------------------------------------------------------------ ground that ends

## Where the ground under a line ahead of him stops: the distance along `way` from `from` (a free point over the
## ground), or -1 if it goes on to `most`, or -2 if the way is shut.
func _ground_end(from: Vector3, way: Vector3, ground: float, most: float, first: float) -> float:
	var reach := (from.y - ground) + STEP_DOWN + 0.02
	var good := 0.0
	var s := first
	var at := from
	while true:
		var y := _step_down(at, from + way * s, reach)
		if y == INF:
			return -2.0
		if is_nan(y):
			var lo := good
			var hi := s
			for i in 6:
				var mid := (lo + hi) * 0.5
				var ym := _step_down(from + way * lo, from + way * mid, reach)
				if ym == INF or is_nan(ym):
					hi = mid
				else:
					lo = mid
			return lo
		good = s
		at = from + way * s
		if s >= most:
			return -1.0
		s = minf(s + 0.1, most)
	return -1.0


func _edge(col: Vector3, ground: float, dir: Vector3) -> Dictionary:
	var from := col + Vector3.UP * 0.4
	var end := _ground_end(from, dir, ground, REACH, 0.1)
	if end < 0.0:
		return {}
	# which way the edge runs: the same search a little to each side
	var side := dir.cross(Vector3.UP).normalized()
	var m := dir
	var a := INF
	var b := INF
	if _sweep(from, side * 0.2) < 0.0 and _sweep(from, -side * 0.2) < 0.0:
		a = _ground_end(from + side * 0.2, dir, ground, REACH + 0.5, 0.1)
		b = _ground_end(from - side * 0.2, dir, ground, REACH + 0.5, 0.1)
	if a != INF and a >= 0.0 and b >= 0.0:
		var along := ((from + side * 0.2 + dir * a) - (from - side * 0.2 + dir * b)).normalized()
		m = along.cross(Vector3.UP).normalized()
		if m.dot(dir) < 0.0:
			m = -m
	var edge := Vector3(col.x, ground, col.z) + dir * end
	var rec := {"kind": "drop", "normal": -m, "edge": edge, "face": (dir * end).dot(m), "from": col, "ground": ground, "top": 0.0}
	# how far down the ground is, just beyond the edge
	var out := from + dir * end + m * 0.12
	if _sweep(from, out - from) >= 0.0:
		return rec
	var by := _down(out, 0.4 + DROP_MOST)
	rec["drop"] = INF if is_nan(by) else ground - by
	# the far side: the first ground at about his own level, looked for straight across
	var reach := 0.4 + STEP_DOWN + 0.02
	var s := 0.1
	var at := out
	var last_open := 0.0
	while s <= GAP_MOST:
		var y := _step_down(at, out + m * s, reach)
		if y == INF:
			# a wall across the gap: the far side stands higher than he can step
			var d := _sweep(at, out + m * s - at)
			rec["kind"] = "gap"
			rec["gap"] = 0.12 + (s - 0.1 if s > 0.1 else 0.0) + maxf(d, 0.0) + R
			rec["far_wall"] = true
			break
		if not is_nan(y):
			var lo := last_open
			var hi := s
			for i in 6:
				var mid := (lo + hi) * 0.5
				var ym := _step_down(out + m * lo, out + m * mid, reach)
				if ym == INF or is_nan(ym):
					lo = mid
				else:
					hi = mid
			rec["kind"] = "gap"
			rec["gap"] = 0.12 + hi
			rec["far_wall"] = false
			rec["landing"] = y - ground
			var rad := float(body.get(&"RADIUS"))
			var land := edge + m * (0.12 + hi + rad + 0.10)
			land.y = y
			rec["land_at"] = land
			rec["landing_ok"] = _fits(land, float(body.get(&"HEIGHT")))
			rec["far_edge"] = Vector3(edge.x, y, edge.z) + m * (0.12 + hi)
			break
		last_open = s
		at = out + m * s
		s += 0.1
	if rec["kind"] == "drop" and rec.has("drop") and rec["drop"] != INF:
		var land := edge + m * (float(body.get(&"RADIUS")) + 0.10)
		land.y = ground - float(rec["drop"])
		rec["land_at"] = land
		rec["landing"] = -float(rec["drop"])
		rec["landing_ok"] = _fits(land, float(body.get(&"HEIGHT")))
	return rec


## One line of plain words for the screen.
static func words(rec: Dictionary) -> String:
	match String(rec.get("kind", "none")):
		"obstacle":
			if rec["top"] == INF:
				return "obstacle: too high to climb" if bool(rec.get("too_high", false)) else "obstacle: BLOCKED, the ceiling hides its top"
			var t := "obstacle: top %.2f m, depth %s%.2f m (%s)" % [float(rec["top"]), ">" if bool(rec["depth_open"]) else "", float(rec["depth"]), "thin" if bool(rec["thin"]) else "deep"]
			t += ", width %s%.2f m" % [">" if bool(rec["width_open"]) else "", float(rec["width"])]
			if bool(rec["blocked"]):
				t += ", BLOCKED: %.2f m of headroom" % float(rec["clear"])
			elif bool(rec["too_high"]):
				t += ", too high to climb"
			else:
				t += ", room to stand" if bool(rec["stand_room"]) else (", room to crouch" if bool(rec["crouch_room"]) else ", no room on top")
			if rec.has("landing"):
				t += ", lands %.2f m%s" % [float(rec["landing"]), "" if bool(rec["landing_ok"]) else " (no room)"]
			return t
		"gap":
			return "gap: %.2f m across, %s deep, far side %s" % [float(rec["gap"]), ("%.2f m" % float(rec["drop"])) if rec.get("drop", INF) != INF else "bottomless",
					"is a wall" if bool(rec["far_wall"]) else ("%+.2f m%s" % [float(rec["landing"]), "" if bool(rec["landing_ok"]) else " (no room)"])]
		"drop":
			return "drop: %s down" % (("%.2f m" % float(rec["drop"])) if rec.get("drop", INF) != INF else "more than %.1f m" % DROP_MOST)
	return "nothing ahead"
