extends SceneTree
## The player's moving clips, all from the Quaternius pack (the Animator, 20 Nov; Yasin: "cant we make start walk end
## walk stop ones ourselves?", "just work on quaternius animations", "just make one normal mode"), for each figure:
## characters/rocketbox/clips_step_<male|female>.res, library "step" on CityPed:
##  walk, jog, idle  Walk_Loop, Jog_Fwd_Loop, Idle_Loop with the hands open (the fingers of Idle_Talking_Loop)
##  start            from standing (idle's first frame) into the walk: the weight goes over the right foot, the body tips
##                   a little forward, the left foot steps off; the walk comes in slow and reaches its own pace just as
##                   the clip ends, exactly at the loop's start (the walk takes over at its own first frame, no jump)
##  stop_l / stop_r  from the walk as the left / right foot lands: the walk slows over its last step, the trunk carries on
##                   forward and rocks back, the hips sink a little as the feet come together, ending on idle's first frame
##  turn_l / turn_r / turn180_l / turn180_r   Turn90 / Turn180 on the spot, meta "yaw" (how the body turns), ending on idle
## Each clip carries meta "pace": per 1/30 s, the share of the walk's ground pace the body should move at, measured from
## the clip itself (how fast its lower foot goes back under the body; the player code moves him by it, so the planted
## foot stays put; a curve worked out by hand let the foot slide 0.35 m/s while the blend moved it).
##   godot --headless --path . -s res://tools/people/make_steps.gd
const FPS := 30.0
## the Quaternius Walk_Loop: its left foot lands at 0.0 of the loop (CityPed::stride_of), the right half a loop on; its
## own ground pace (the planted foot's), m/s, the same number as CityPlayer's
const WALK_LAND_L := 0.0
const WALK_V := 0.92
const OPEN_HANDS := "Idle_Talking_Loop"   # (whose fingers are relaxed and open)
## where in the walk the start blends in, after the right foot lands (share of the loop): 0.12 (the left about to
## lift, behind) dragged the left foot back along the ground and the right forward under load (0.31 m/s slide)
const START_AT := 0.25
const IDLE := "Idle_Loop"   # (in clips_ual: the idle the player stands in)
const TRUNK := ["Bip01_Spine", "Bip01_Spine1", "Bip01_Spine2"]
## the figure's frame: which way is forward is measured from the walk itself (the way its planted foot goes back is
## backward), so the trunk tips the right way and the pace has its sign; set in _initialize
var FIG_FWD := Vector3(0, 0, 1)
var FIG_RIGHT := Vector3(1, 0, 0)

var skel: Skeleton3D
var to_fig: Basis        # skeleton space -> the figure's frame (metres, +z forward, +y up)
var bones: Array = []    # bone names
var pelvis := ""
var last_stance := Vector3.ZERO

func _initialize() -> void:
	var made := 0
	for g in ["male", "female"]:
		var scene: Node = (load("res://characters/rocketbox/hero_%s.scn" % g) as PackedScene).instantiate()
		root.add_child(scene)
		skel = scene.find_children("*", "Skeleton3D", true, false)[0]
		var x := Transform3D(); var nd: Node = skel
		while nd != null and nd != scene.get_parent():
			if nd is Node3D: x = (nd as Node3D).transform * x
			nd = nd.get_parent()
		to_fig = x.basis
		bones.clear()
		for b in skel.get_bone_count(): bones.append(skel.get_bone_name(b))
		pelvis = "Bip01_Pelvis"
		for t in TRUNK: if skel.find_bone(t) < 0: print("STEPS ERROR no bone %s; bones: %s" % [t, str(bones)]); quit(1); return
		# forward: the planted (lower) foot of the walk goes backward under the body
		var w: Animation = (load("res://characters/rocketbox/clips_ual_%s.res" % g) as AnimationLibrary).get_animation("Walk_Loop")
		var fl := skel.find_bone("Bip01_L_Foot"); var fr := skel.find_bone("Bip01_R_Foot")
		var sum := 0.0; var prev := Vector3.INF
		for k in 40:
			var gl := _glob(_mix(_pose(w, k * w.length / 40.0), {}, 0.0))
			var a: Vector3 = to_fig * (gl[fl] as Transform3D).origin; var b: Vector3 = to_fig * (gl[fr] as Transform3D).origin
			var lo := a if a.y <= b.y else b
			if prev != Vector3.INF and absf(lo.z - prev.z) < 0.1: sum += lo.z - prev.z
			prev = lo
		FIG_FWD = Vector3(0, 0, -1.0 if sum > 0.0 else 1.0)
		FIG_RIGHT = Vector3(0, 1, 0).cross(FIG_FWD)   # (the axis that turns up toward forward)
		print("STEPS %s: forward is %s (the planted foot went %+.3f along z over the walk)" % [g, FIG_FWD, sum])
		var ual: AnimationLibrary = load("res://characters/rocketbox/clips_ual_%s.res" % g)
		var idle: Animation = ual.get_animation(IDLE)
		var out := AnimationLibrary.new()
		# ONE MODE: the Quaternius clips with the hands open (Yasin, 20 Nov: "drop rocket box walk, just open the hands of
		# quaternius animations and use them for walk"; "just work on quaternius animations"; "just make one normal mode,
		# lets drop the angry entirely"): the fingers of Idle_Talking_Loop (relaxed, open; the walk, jog and idle hold
		# fists) held on the walk, the jog and the idle; the start, stops and turns are made from those
		var open_src: Animation = ual.get_animation(OPEN_HANDS)
		var gaits := {}
		for c in [["walk", "Walk_Loop"], ["jog", "Jog_Fwd_Loop"], ["idle", IDLE]]:
			var a := _open_hands(ual.get_animation(String(c[1])), open_src)
			out.add_animation(StringName(c[0]), a); gaits[c[0]] = a; made += 1
		var walk: Animation = gaits["walk"]
		var idle_o: Animation = gaits["idle"]
		out.add_animation(&"start", _start(walk, idle_o, WALK_LAND_L, WALK_V))
		out.add_animation(&"stop_l", _stop(walk, idle_o, WALK_LAND_L, WALK_V))
		out.add_animation(&"stop_r", _stop(walk, idle_o, fmod(WALK_LAND_L + 0.5, 1.0), WALK_V))
		made += 3
		# TURNS on the spot: the Quaternius Turn90 / Turn180 are made for a body the game turns (their hips swing out up
		# to 46 degrees and come back to 0, the feet too: there is no turn in them to measure); the body turns along an
		# even curve to the clip's 90 or 180 (meta "yaw"), and the clip ends on the idle
		for tt in [["turn_l", "Turn90_L", 90.0], ["turn_r", "Turn90_R", -90.0], ["turn180_l", "Turn180_L", 180.0], ["turn180_r", "Turn180_R", -180.0]]:
			print("STEPS   %s from %s:" % [tt[0], tt[1]])
			out.add_animation(StringName(tt[0]), _turn(_open_hands(ual.get_animation(String(tt[1])), open_src), idle_o, deg_to_rad(float(tt[2]))))
			made += 1
		var path := "res://characters/rocketbox/clips_step_%s.res" % g
		var err := ResourceSaver.save(out, path)
		print("STEPS %s: %s (%s)" % [g, path, "saved" if err == OK else "ERROR %d" % err])
		for nm in out.get_animation_list():
			var a := out.get_animation(nm)
			print("STEPS   %-12s %.2f s, pace %s" % [nm, a.length, _pace_str(a.get_meta("pace", PackedFloat32Array()))])
		scene.queue_free()
	print("STEPS %d clips made" % made)
	print("STEPS the weight goes over the right foot: %s (figure frame)" % str(last_stance))
	quit(0)

func _pace_str(p: PackedFloat32Array) -> String:
	var s := PackedStringArray()
	for i in range(0, p.size(), 3): s.append("%.2f" % p[i])
	return " ".join(s)

static func _ss(a: float, b: float, t: float) -> float:
	var u := clampf((t - a) / (b - a), 0.0, 1.0)
	return u * u * (3.0 - 2.0 * u)

static func _bump(c: float, w: float, t: float) -> float:   # (a smooth hump: 1 at c, 0 beyond w either side)
	var u := absf(t - c) / w
	return 0.0 if u >= 1.0 else 0.5 + 0.5 * cos(u * PI)

## A pose of a clip at t: bone name -> [rotation, position or null]
func _pose(a: Animation, t: float) -> Dictionary:
	var p := {}
	var tt := fposmod(t, a.length) if a.loop_mode != Animation.LOOP_NONE else clampf(t, 0.0, a.length)
	for i in a.get_track_count():
		var path := a.track_get_path(i)
		if path.get_subname_count() < 1: continue
		var b := String(path.get_subname(0))
		if not p.has(b): p[b] = [null, null]
		match a.track_get_type(i):
			Animation.TYPE_ROTATION_3D: p[b][0] = a.rotation_track_interpolate(i, tt)
			Animation.TYPE_POSITION_3D: p[b][1] = a.position_track_interpolate(i, tt)
	return p

## a mixed pose: w = 0 all a, 1 all b (rotations slerped, the hips' place lerped); bones neither moves keep the rest
func _mix(a: Dictionary, b: Dictionary, w: float) -> Dictionary:
	var p := {}
	for nm in bones:
		var bi := skel.find_bone(nm)
		var rest := skel.get_bone_rest(bi)
		var ra: Quaternion = a[nm][0] if a.has(nm) and a[nm][0] != null else rest.basis.get_rotation_quaternion()
		var rb: Quaternion = b[nm][0] if b.has(nm) and b[nm][0] != null else rest.basis.get_rotation_quaternion()
		var pa: Vector3 = a[nm][1] if a.has(nm) and a[nm][1] != null else rest.origin
		var pb: Vector3 = b[nm][1] if b.has(nm) and b[nm][1] != null else rest.origin
		p[nm] = [ra.slerp(rb, w), pa.lerp(pb, w)]
	return p

## Every bone's place in skeleton space for a pose, chained from the root (the skeleton node's own world poses do not
## update in a headless run: they stayed at rest, the first bake's feet never moved)
func _glob(p: Dictionary) -> Array:
	var g: Array = []; g.resize(bones.size())
	for b in bones.size(): _glob_one(p, b, g)
	return g

func _glob_one(p: Dictionary, b: int, g: Array) -> Transform3D:
	if g[b] != null: return g[b]
	var rest := skel.get_bone_rest(b)
	var nm: String = bones[b]
	var local := Transform3D(Basis(p[nm][0] as Quaternion).scaled(rest.basis.get_scale()), p[nm][1] as Vector3)
	var par := skel.get_bone_parent(b)
	g[b] = (_glob_one(p, par, g) * local) if par >= 0 else local
	return g[b]

## the trunk tipped forward (+) or back by `pitch` rad about the figure's left-right axis, shared over the three spine
## bones; the hips moved by `off` metres in the figure's frame
func _shape(p: Dictionary, pitch: float, off: Vector3) -> void:
	if absf(pitch) > 0.0001:
		var axis := (to_fig.inverse() * FIG_RIGHT).normalized()
		for nm in TRUNK:
			var g := _glob(p)
			var bi := skel.find_bone(nm)
			var par := skel.get_bone_parent(bi)
			var pg: Basis = (g[par] as Transform3D).basis.orthonormalized() if par >= 0 else Basis()
			var ng := Basis(axis, pitch / TRUNK.size()) * (g[bi] as Transform3D).basis.orthonormalized()
			p[nm][0] = (pg.inverse() * ng).get_rotation_quaternion()
	if off.length() > 0.0001:
		var g := _glob(p)
		var pi := skel.find_bone(pelvis)
		var par := skel.get_bone_parent(pi)
		var pg: Basis = (g[par] as Transform3D).basis if par >= 0 else Basis()
		p[pelvis][1] = (p[pelvis][1] as Vector3) + pg.inverse() * (to_fig.inverse() * off)

## the clip from frames: pose(t) for t in 0..length at FPS, and its pace curve
func _bake(length: float, pose_at: Callable, v_walk: float, start_pace: float, end_pace: float) -> Animation:
	var a := Animation.new()
	a.length = length; a.step = 1.0 / FPS; a.loop_mode = Animation.LOOP_NONE
	var rot := {}
	for nm in bones:
		var ti := a.add_track(Animation.TYPE_ROTATION_3D); a.track_set_path(ti, NodePath("Skeleton/Skeleton3D:" + nm)); rot[nm] = ti
	var pos := a.add_track(Animation.TYPE_POSITION_3D); a.track_set_path(pos, NodePath("Skeleton/Skeleton3D:" + pelvis))
	var n := int(round(length * FPS))
	var feet := [skel.find_bone("Bip01_L_Foot"), skel.find_bone("Bip01_R_Foot")]
	var fz := [PackedFloat32Array(), PackedFloat32Array()]; var fy := [PackedFloat32Array(), PackedFloat32Array()]
	for k in n + 1:
		var t := minf(k / FPS, length)
		var p: Dictionary = pose_at.call(t)
		for nm in bones: a.rotation_track_insert_key(rot[nm], t, p[nm][0])
		a.position_track_insert_key(pos, t, p[pelvis][1])
		var gl := _glob(p)   # (where its feet are)
		for s in 2:
			var f: Vector3 = to_fig * (gl[feet[s]] as Transform3D).origin
			fz[s].append(f.z); fy[s].append(f.y)
	# the pace: the lower foot's speed backward under the body, over the walk's own ground pace
	if OS.get_cmdline_user_args().has("--debug"): print("STEPS DEBUG Lz ", fz[0].slice(0, 12), " Ly ", fy[0].slice(0, 12), " Rz ", fz[1].slice(0, 12))
	var raw := PackedFloat32Array()
	for k in n + 1:
		var lo := 0 if fy[0][k] <= fy[1][k] else 1
		var k0 := maxi(k - 1, 0); var k1 := mini(k + 1, n)
		var back: float = -(fz[lo][k1] - fz[lo][k0]) * FIG_FWD.z / (float(k1 - k0) / FPS) if k1 > k0 else 0.0
		raw.append(clampf(back / v_walk, 0.0, 1.4))
	# smoothed over 0.3 s (a triangle 9 frames wide: the body does not jerk from foot to foot; the foot plant takes the
	# little left over), and the ends pinned to the clips they meet (the walk's full pace, standing still)
	var pace := PackedFloat32Array()
	for k in n + 1:
		var sw := 0.0; var sv := 0.0
		for j in range(-4, 5):
			var wj := 5.0 - absf(j); sw += wj; sv += wj * raw[clampi(k + j, 0, n)]
		pace.append(sv / sw)
	for k in n + 1:
		var u := clampf((float(n - k) / FPS) / 0.15, 0.0, 1.0)   # (1 until the last 0.15 s, then down to 0 at the end)
		var u0 := clampf((float(k) / FPS) / 0.15, 0.0, 1.0)      # (and from start_pace over the first 0.15 s)
		pace[k] = lerpf(end_pace, lerpf(start_pace, pace[k], u0), u)
	a.set_meta("pace", pace)
	return a

## the walk's own time, w(t) = w0 + integral of rate(t): found by summing in small steps
func _walk_time(rate: Callable, t: float) -> float:
	var s := 0.0; var h := 1.0 / 240.0; var u := 0.0
	while u < t: s += float(rate.call(minf(u + h * 0.5, t))) * minf(h, t - u); u += h
	return s

func _start(walk: Animation, idle: Animation, land_l: float, v: float) -> Animation:
	var L := walk.length
	var w0 := fposmod(land_l + 0.5 + START_AT, 1.0) * L   # (the right foot under the body, the left passing it: both where standing has them)
	var dist := L - w0 if L - w0 > 0.05 else 2.0 * L - w0   # (to the loop's end: its first frame again)
	var rate := func(t: float) -> float: return 0.35 + 0.65 * _ss(0.15, 0.7, t)
	# the length at which the walk has covered dist
	var D := 0.0
	while _walk_time(rate, D) < dist: D += 1.0 / 240.0
	var idle0 := _pose(idle, 0.0)
	var blend := func(t: float) -> float: return _ss(0.08, 0.5, t)
	var stance := _stance_side(_mix(idle0, idle0, 0.0))
	var pose_at := func(t: float) -> Dictionary:
		var p := _mix(idle0, _pose(walk, w0 + _walk_time(rate, t)), blend.call(t))
		# the weight over the right foot before the left lifts, then back to the walk's own sway; the trunk tips
		# forward (the body starts to fall into the first step), then settles into the walk
		var shift := stance * 0.03 * _bump(0.18, 0.2, t)
		_shape(p, 0.06 * _bump(0.3, 0.3, t), Vector3(shift.x, -0.012 * _bump(0.18, 0.2, t), shift.z))
		return p
	return _bake(D, pose_at, v, 0.0, 1.0)

func _stop(walk: Animation, idle: Animation, land: float, v: float) -> Animation:
	var L := walk.length
	var w0 := land * L
	var D := 1.0
	var rate := func(t: float) -> float: return 1.0 - 0.75 * _ss(0.0, 0.55, t)
	var blend := func(t: float) -> float: return _ss(0.1, 0.8, t)
	var idle0 := _pose(idle, 0.0)
	var pose_at := func(t: float) -> Dictionary:
		var p := _mix(_pose(walk, w0 + _walk_time(rate, t)), idle0, float(blend.call(t)))
		# momentum: the trunk carries on forward, then rocks back a little and settles; the hips sink as the feet meet
		var pitch := 0.07 * _bump(0.38, 0.32, t) - 0.025 * _bump(0.75, 0.2, t)
		_shape(p, pitch, Vector3(0, -0.035 * _bump(0.5, 0.3, t), 0))
		return p
	return _bake(D, pose_at, v, 1.0, 0.0)

## standing: the way from the hips to the right foot, sideways only, in the figure's frame (unit)
func _stance_side(p: Dictionary) -> Vector3:
	var gl := _glob(p)
	var f := to_fig * (gl[skel.find_bone("Bip01_R_Foot")] as Transform3D).origin
	var h := to_fig * (gl[skel.find_bone(pelvis)] as Transform3D).origin
	var d := Vector3(f.x - h.x, 0, 0)
	last_stance = d.normalized() if d.length() > 0.001 else Vector3(-1, 0, 0)
	return last_stance

## A turn on the spot for a body the game turns: the clip as it is (its hips swing and come back), its turn measured
## from the feet: while the lower foot is planted, how much it pivots about the up axis in the clip is how much the
## body must turn the other way for it to stay put on the ground; summed, smoothed and scaled to `total` (rad, + left
## as the player's yaw). The clip is cut 0.35 s after the turn is 97 % done and blends from 0.25 s before it into
## the idle's first frame, so standing (and the walk start) begins where it expects. Meta "yaw", "done_at".
func _turn(src: Animation, idle: Animation, total: float) -> Animation:
	var fb := [skel.find_bone("Bip01_L_Foot"), skel.find_bone("Bip01_R_Foot")]
	var n := int(round(src.length * FPS))
	var tf := to_fig.orthonormalized()
	# the foot's own forward: of its bone's axes (either sign), the one that points most forward (+z) and least up in the
	# first frame (the skeleton has no toe bones: a heading from the toe read 0 degrees all through)
	var axis := [Vector3.ZERO, Vector3.ZERO]
	var gl0 := _glob(_mix(_pose(src, 0.0), {}, 0.0))
	for s in 2:
		var bb: Basis = (gl0[fb[s]] as Transform3D).basis.orthonormalized()
		var best := -9.0
		for ax in [Vector3(1, 0, 0), Vector3(-1, 0, 0), Vector3(0, 1, 0), Vector3(0, -1, 0), Vector3(0, 0, 1), Vector3(0, 0, -1)]:
			var w: Vector3 = tf * (bb * ax)
			var score := w.z - absf(w.y) * 0.5
			if score > best: best = score; axis[s] = ax
	var head := [PackedFloat32Array(), PackedFloat32Array()]; var fy := [PackedFloat32Array(), PackedFloat32Array()]
	for k in n + 1:
		var gl := _glob(_mix(_pose(src, minf(k / FPS, src.length)), {}, 0.0))
		for s in 2:
			var tr: Transform3D = gl[fb[s]]
			var f: Vector3 = to_fig * tr.origin
			var w: Vector3 = tf * (tr.basis.orthonormalized() * (axis[s] as Vector3))
			head[s].append(atan2(w.x, w.z)); fy[s].append(f.y)
	var low := minf(_minf(fy[0]), _minf(fy[1]))
	var raw := PackedFloat32Array(); raw.append(0.0)
	for k in range(1, n + 1):
		var lo := 0 if fy[0][k] <= fy[1][k] else 1
		var d := 0.0
		if fy[lo][k] < low + 0.03 and fy[lo][k - 1] < low + 0.03:
			d = -wrapf(head[lo][k] - head[lo][k - 1], -PI, PI)   # (the foot pivots one way in the clip: the body turns the other)
		raw.append(raw[k - 1] + d)
	var yaw := PackedFloat32Array()
	var scale := total / raw[n] if absf(raw[n]) > 0.2 and signf(raw[n]) == signf(total) else 0.0
	for k in n + 1:
		var sv := 0.0; var sw := 0.0
		for j in range(-3, 4):
			var wj := 4.0 - absf(j); sw += wj; sv += wj * raw[clampi(k + j, 0, n)]
		yaw.append(sv / sw * scale if scale != 0.0 else total * _ss(0.15, 0.85, float(k) / n))
	yaw[0] = 0.0; yaw[n] = total
	var done := 0
	for k in n + 1:
		if absf(yaw[k]) >= absf(total) * 0.97: done = k; break
	var cut := minf(src.length, done / FPS + 0.35)
	var idle0 := _pose(idle, 0.0)
	var pose_at := func(t: float) -> Dictionary:
		return _mix(_mix(_pose(src, t), {}, 0.0), idle0, _ss(done / FPS - 0.25, cut, t))
	var a := _bake(cut, pose_at, 1.0, 0.0, 0.0)
	a.set_meta("yaw", yaw)
	a.set_meta("done_at", done / FPS)
	print("STEPS     %.2f s (cut from %.2f): the feet turn it %+.0f degrees (scaled to %+.0f%s), 97 %% at %.2f s" % [cut, src.length, rad_to_deg(raw[n]), rad_to_deg(total), "" if scale != 0.0 else ": NOT from the feet, an even curve", done / FPS])
	return a

## a clip with the hands open: its finger tracks replaced by the fingers of `hands` (its first frame, held)
func _open_hands(src: Animation, hands: Animation) -> Animation:
	var a: Animation = src.duplicate(true)
	var hp := _pose(hands, 0.0)
	for i in a.get_track_count():
		if a.track_get_type(i) != Animation.TYPE_ROTATION_3D: continue
		var bn := String(a.track_get_path(i).get_subname(0))
		if not bn.contains("Finger") or not hp.has(bn) or hp[bn][0] == null: continue
		while a.track_get_key_count(i) > 0: a.track_remove_key(i, 0)
		a.rotation_track_insert_key(i, 0.0, hp[bn][0])
	return a

func _minf(p: PackedFloat32Array) -> float:
	var m := INF
	for v in p: m = minf(m, v)
	return m

func _half(y: PackedFloat32Array) -> float:
	for k in y.size(): if absf(y[k]) >= absf(y[y.size() - 1]) * 0.5: return float(k)
	return 0.0
