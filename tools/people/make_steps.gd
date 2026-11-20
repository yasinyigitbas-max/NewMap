extends SceneTree
## Walk START and STOP clips, made from the clips we have (the Animator, 20 Nov; Yasin: "cant we make start walk end walk
## stop ones ourselves?"). For each gait set (casual = the Rocketbox walk_fast, angry = the Quaternius Walk_Loop) and
## each figure: characters/rocketbox/clips_step_<male|female>.res, library "step" on CityPed:
##  <set>_start   from standing (ual/Idle_Loop at 0) into the walk: the weight goes over the right foot, the body tips a
##                little forward, the left foot steps off; the walk comes in slow and reaches its own pace just as the clip
##                ends, exactly at the loop's start (so the walk takes over at its own first frame, no jump)
##  <set>_stop_l  from the walk at the moment the left foot lands: the walk slows over its last step, the body's
##  <set>_stop_r  momentum carries the trunk forward and back, the hips sink a little as the feet come together, and it
##                ends exactly on ual/Idle_Loop's first frame (the idle takes over with no jump). _r: from the right foot
## Each clip carries meta "pace": per 1/30 s, the share of the walk's ground pace the body should move at, measured from
## the clip itself (how fast its lower foot goes back under the body; the player code moves him by it, so the planted
## foot stays put; a curve worked out by hand let the foot slide 0.35 m/s while the blend moved it).
##   godot --headless --path . -s res://tools/people/make_steps.gd
const FPS := 30.0
## [prefix, library file stem, walk clip, left foot landing (share of loop), the walk's own ground pace m/s (the planted
## foot's, clip_audit.gd; the same numbers as CityPlayer's)]; the right foot lands half a loop away
const SETS := [["rb", "clips_%s", "walk_fast", 0.800, 1.35], ["ual", "clips_ual_%s", "Walk_Loop", 0.0, 0.92]]
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
		# forward: the planted (lower) foot of the Rocketbox walk goes backward under the body
		var w: Animation = (load("res://characters/rocketbox/clips_%s.res" % g) as AnimationLibrary).get_animation("walk")
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
		for s in SETS:
			var lib: AnimationLibrary = load("res://characters/rocketbox/%s.res" % (String(s[1]) % g))
			var walk: Animation = lib.get_animation(String(s[2]))
			var land_l: float = s[3]
			var v: float = s[4]
			out.add_animation(StringName("%s_start" % s[0]), _start(walk, idle, land_l, v))
			out.add_animation(StringName("%s_stop_l" % s[0]), _stop(walk, idle, land_l, v))
			out.add_animation(StringName("%s_stop_r" % s[0]), _stop(walk, idle, fmod(land_l + 0.5, 1.0), v))
			made += 3
		var path := "res://characters/rocketbox/clips_step_%s.res" % g
		var err := ResourceSaver.save(out, path)
		print("STEPS %s: %s (%s)" % [g, path, "saved" if err == OK else "ERROR %d" % err])
		for nm in out.get_animation_list():
			var a := out.get_animation(nm)
			print("STEPS   %-12s %.2f s, pace %s" % [nm, a.length, _pace_str(a.get_meta("pace"))])
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
	var w0 := fposmod(land_l + 0.5 + 0.12, 1.0) * L      # (the right foot just down, the left about to lift)
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
