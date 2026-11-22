extends SceneTree
## PLAYER ONLY. The player's idle on foot (Yasin, 21 Nov 23:19: "remove ual idle too and again play the new ones
## alternatively in long loops after a transition and then the other long ones and etc"):
##   godot --headless --path . -s res://tools/people/make_player_idles.gd   -> characters/rocketbox/clips_player_idle_<g>.res
## Library "pidle" (CityPed loads it; CityPlayer plays it):
##   base_*   the LONG LOOPS: his new Mixamo looping idles (Standing Idle, Idle, Idle (1), Orc Idle; gender tags ignored,
##            every take goes to both figures), fitted by the same Mixamo converter as the walks (perf-bugs AnimRetarget,
##            mixamo rig) into tools/people/player_idle_sources/clips_mxidle_<g>.res
##   the FIDGETS: Looking_Around_idle, Looking, Arm_Stretching, Neck_Stretching, Bored, now the whole Mixamo take (before:
##            only the upper body, over step/idle's legs)
## step/idle (the Quaternius / UAL Idle_Loop) is no longer played on foot; it stays in the step library.
## Every take is the mocap as converted, untouched (hips, legs, fingers and all), but for one rigid placement: each take is
## moved along the floor (no turn) so the middle of its feet is where the others have it, so a crossfade does not slide
## them. A new take within DUP_CM of one we have (its feet and head, all through) is the same take: left out.
const DIR := "res://characters/rocketbox/"
const MX_SRC := "/workspace/share/anim/walk/src/clips_mx_%s.res"
const BORED := "/workspace/share/anim/walk/src/bored_%s.res"
const NEW_SRC := "res://tools/people/player_idle_sources/clips_mxidle_%s.res"
## (Yasin, 22 Nov 01:23: "add all these variety to the ones we covered": every plain standing idle of his downloads; the
## Male Locomotion pack's idle and the Action Adventure pack's four standing idles (its "idle (4)" is the crouched cover
## idle, Crouch cover idle.fbx to the byte: not a standing idle), and Idle Transition as a fidget)
const DROP_IDLE := {"male": ["base_aa", "base_aa5", "base_aa3", "base_orc"], "female": ["base_aa", "base_aa5", "base_aa3", "base_orc"]}   # (Yasin, 22 Nov 02:14: they don't fit)
const RUN_SRC := "res://tools/people/player_run_sources/clips_mxrun_%s.res"
const BASES := [["base_standing", "Standing_Idle_mixamo_com", "Standing Idle.fbx"], ["base_idle", "Idle_A_mixamo_com", "Idle.fbx"], ["base_idle1", "Idle_B_mixamo_com", "Idle (1).fbx"], ["base_orc", "Orc_Idle_mixamo_com", "Orc Idle.fbx"],
		["base_loco", "Loco_Idle", "Male Locomotion Pack idle.fbx", "run"], ["base_aa", "AA_Idle_1", "Action Adventure Pack idle.fbx", "run"], ["base_aa2", "AA_Idle_2", "Action Adventure Pack idle (2).fbx", "run"],
		["base_aa3", "AA_Idle_3", "Action Adventure Pack idle (3).fbx", "run"], ["base_aa5", "AA_Idle_5", "Action Adventure Pack idle (5).fbx", "run"]]
const FIDGETS := ["Looking_Around_idle", "Looking", "Arm_Stretching", "Neck_Stretching", "Bored", "Idle_Transition"]
const DUP_CM := 2.0
const FPS := 30.0
var sk: Skeleton3D
var prefix := "Skeleton/Skeleton3D"
var skel_x := Transform3D()

func _bone_path(b: int) -> NodePath: return NodePath(prefix + ":" + sk.get_bone_name(b))
func _globals(a: Animation, t: float) -> Array[Transform3D]:
	var g: Array[Transform3D] = []
	for b in sk.get_bone_count():
		var rest := sk.get_bone_rest(b); var p := _bone_path(b)
		var pi := a.find_track(p, Animation.TYPE_POSITION_3D); var ri := a.find_track(p, Animation.TYPE_ROTATION_3D)
		var l := Transform3D(Basis(a.rotation_track_interpolate(ri, t) if ri >= 0 else rest.basis.get_rotation_quaternion()), a.position_track_interpolate(pi, t) if pi >= 0 else rest.origin)
		var par := sk.get_bone_parent(b)
		g.append(l if par < 0 else g[par] * l)
	return g
## the feet (both ankles, both toes' ends) and the head, in the figure, metres
func _pts(a: Animation, t: float) -> PackedVector3Array:
	var g := _globals(a, t); var out := PackedVector3Array()
	for bn in ["Bip01_L_Foot", "Bip01_R_Foot"]:
		var f: Transform3D = g[sk.find_bone(bn)]
		out.append(skel_x * f.origin); out.append(skel_x * (f * Vector3(0, 12.0, 0)))
	out.append(skel_x * g[sk.find_bone("Bip01_Head")].origin)
	return out
func _d(x: PackedVector3Array, y: PackedVector3Array, n := 5) -> float:
	var s := 0.0
	for i in n: s = maxf(s, (x[i] - y[i]).length())
	return s * 100.0
func _dup_cm(a: Animation, b: Animation) -> float:
	if absf(a.length - b.length) > 0.1: return INF
	var w := 0.0
	for i in 16:
		var t := minf(a.length, b.length) * i / 15.0
		w = maxf(w, _d(_pts(a, t), _pts(b, t)))
	return w
## the way his hips face (from the thighs), degrees about the vertical, figure space, averaged over the take
func _facing(a: Animation) -> float:
	var v := Vector2()
	for i in 11:
		var g := _globals(a, a.length * i / 10.0)
		var l: Vector3 = skel_x * g[sk.find_bone("Bip01_L_Thigh")].origin; var r: Vector3 = skel_x * g[sk.find_bone("Bip01_R_Thigh")].origin
		var f := (l - r).cross(Vector3.UP)
		v += Vector2(f.x, f.z).normalized()
	return rad_to_deg(atan2(v.x, v.y))
func _feet_mid(a: Animation, t: float) -> Vector3:
	var p := _pts(a, t); var m := (p[0] + p[2]) * 0.5; return Vector3(m.x, 0, m.z)
## an editable copy at 30 a second, moved by `shift` (figure space, metres) along the floor
func _copy(src: Animation, shift: Vector3, turn_deg := 0.0) -> Animation:
	var a := Animation.new(); a.length = src.length; a.loop_mode = src.loop_mode
	# (turned about the vertical in the figure, the root only: the take's own motion as recorded, facing another way)
	var rq := (skel_x.basis.inverse() * Basis(Vector3.UP, deg_to_rad(turn_deg)) * skel_x.basis).get_rotation_quaternion()
	var frames := int(ceil(src.length * FPS)) + 1
	var root_name := sk.get_bone_name(0)
	var sh := skel_x.basis.inverse() * shift
	for ti in src.get_track_count():
		var ty := src.track_get_type(ti)
		if ty not in [Animation.TYPE_POSITION_3D, Animation.TYPE_ROTATION_3D, Animation.TYPE_SCALE_3D]: continue
		var o := a.add_track(ty); a.track_set_path(o, src.track_get_path(ti))
		var is_root := String(src.track_get_path(ti)).get_slice(":", 1) == root_name
		for k in frames:
			var t: float = minf(float(k) / FPS, src.length)
			if ty == Animation.TYPE_POSITION_3D: a.position_track_insert_key(o, t, (rq * src.position_track_interpolate(ti, t) + sh) if is_root else src.position_track_interpolate(ti, t))
			elif ty == Animation.TYPE_ROTATION_3D: a.rotation_track_insert_key(o, t, (rq * src.rotation_track_interpolate(ti, t)) if is_root else src.rotation_track_interpolate(ti, t))
			else: a.scale_track_insert_key(o, t, src.scale_track_interpolate(ti, t))
	return a

func _initialize() -> void:
	for gender in ["male", "female"]:
		var scene: Node = (load(DIR + "hero_%s.scn" % gender) as PackedScene).instantiate()
		sk = scene.find_children("*", "Skeleton3D", true, false)[0]
		skel_x = Transform3D(); var n: Node = sk
		while n != scene: skel_x = (n as Node3D).transform * skel_x; n = n.get_parent()
		print("PLAYER_IDLE root bone %s (parent %d)" % [sk.get_bone_name(0), sk.get_bone_parent(0)])
		var mx: AnimationLibrary = load(MX_SRC % gender)
		var nw: AnimationLibrary = load(NEW_SRC % gender)
		var bored: AnimationLibrary = load(BORED % gender)
		var src_of := {}; var takes := {}; var order := []
		for f in FIDGETS:
			takes[f] = bored.get_animation(&"Bored") if f == "Bored" else mx.get_animation(f); src_of[f] = "mx/" + f; order.append(f)
		var rn: AnimationLibrary = load(RUN_SRC % gender)
		for b in BASES:
			var lib: AnimationLibrary = rn if b.size() > 3 else nw
			if not lib.has_animation(b[1]): print("PLAYER_IDLE %s %s MISSING" % [gender, b[1]]); continue
			var a: Animation = lib.get_animation(b[1])
			var near := INF; var near_n := ""
			for other in mx.get_animation_list():
				var dd := _dup_cm(a, mx.get_animation(other))
				if dd < near: near = dd; near_n = other
			for k in takes:
				var dd := _dup_cm(a, takes[k])
				if dd < near: near = dd; near_n = k
			# Filename+size inventory decides duplicates, never pose similarity.
			takes[b[0]] = a; src_of[b[0]] = "mx/" + b[2]; order.append(b[0])
			print("PLAYER_IDLE %s %s -> %s %.2fs (nearest take of its length: %s %.0f cm)" % [gender, b[2], b[0], a.length, near_n, near])
		var out := AnimationLibrary.new()
		var nb := 0
		for name in order:
			var src: Animation = takes[name]
			# (a pack idle recorded facing round the other way, the Action Adventure idle (5) at -155 degrees, is turned to face
			# as base_idle does: crossfaded as it was, he spun round on the spot. A bladed stance, 40 degrees off, stays.)
			var turn := 0.0
			if takes.has("base_idle") and name != "base_idle":
				var dd := wrapf(_facing(takes["base_idle"]) - _facing(src), -180.0, 180.0)
				if absf(dd) > 90.0: turn = dd
			if turn != 0.0: src = _copy(src, Vector3(), turn); print("PLAYER_IDLE %s %s turned %.0f degrees to face as base_idle" % [gender, name, turn])
			var mid := Vector3()
			for i in 11: mid += _feet_mid(src, src.length * i / 10.0) / 11.0
			var a := _copy(src, -mid)
			var base := String(name).begins_with("base_")
			a.loop_mode = Animation.LOOP_LINEAR if base else Animation.LOOP_NONE
			a.set_meta("source", src_of[name]); a.set_meta("kind", "base" if base else "fidget"); a.set_meta("placed_cm", mid * 100.0)
			if base: nb += 1
			var p0 := _pts(a, 0.0); var p1 := _pts(a, a.length)
			var fm := 0.0
			for i in int(a.length * FPS):
				var q := _pts(a, i / FPS)
				for j in [0, 2]: fm = maxf(fm, Vector2(q[j].x - p0[j].x, q[j].z - p0[j].z).length() * 100.0)
			a.set_meta("feet_move_cm", fm)
			a.set_meta("facing_deg", _facing(a))
			print("PLAYER_IDLE %s %s facing %.0f deg" % [gender, name, _facing(a)])
			print("PLAYER_IDLE %s %s %.2fs %s moved %.1f cm; end to start %.1f cm; its own feet move up to %.1f cm; feet L %s R %s" % [gender, name, a.length, "LOOP" if base else "once", mid.length() * 100.0, _d(p0, p1), fm, p0[0] * 100.0, p0[2] * 100.0])
			out.add_animation(name, a)
		var worst := 0.0
		for b in order:
			if not String(b).begins_with("base_"): continue
			for f in FIDGETS:
				var fa: Animation = out.get_animation(f); var ba: Animation = out.get_animation(b)
				worst = maxf(worst, maxf(_d(_pts(ba, 0.0), _pts(fa, 0.0), 4), _d(_pts(fa, fa.length), _pts(ba, 0.0), 4)))
		print("PLAYER_IDLE %s %d long loops, %d fidgets; feet apart at a crossfade, worst %.1f cm" % [gender, nb, FIDGETS.size(), worst])
		scene.free()
		# (Yasin, 22 Nov 02:14, after playing the build: "they dont fit": out of this figure's library, so out of its pools)
		for rm in DROP_IDLE.get(gender, []):
			if out.has_animation(rm): out.remove_animation(rm); print("PLAYER_IDLE %s %s REMOVED (Yasin, 22 Nov 02:14)" % [gender, rm])
		var err := ResourceSaver.save(out, DIR + "clips_player_idle_%s.res" % gender)
		print("PLAYER_IDLE saved %s %s" % [gender, "ok" if err == OK else "ERROR %d" % err])
	quit(0)
