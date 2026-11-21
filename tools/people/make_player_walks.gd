extends SceneTree
## PLAYER ONLY. The player's walk on foot (Yasin, 21 Nov: "mirror start and turns if we dont have the alternate foot
## versions and start hooking them up, also place the ual walking into this as the secondary walking loop but again open
## their hands. we should see one of the random starts, random main walks, and random stop walks. again, never the same
## one again"):
##   godot --headless --path . -s res://tools/people/make_player_walks.gd   -> characters/rocketbox/clips_player_walk_<g>.res
## Library "pwalk" (CityPed loads it; CityPlayer picks the clips):
##   start_a / start_b       Mixamo Start_Walking, and it mirrored (the other foot first)
##   walk_mx / walk_ual      Mixamo Walking; the UAL walk loop the player walked on (step/walk, made from ual/Walk_Loop)
##   stop_a / stop_b         Mixamo Stop_Walking, and it mirrored (stopping on the other foot)
##   turn_l / turn_r         Mixamo Walking_Left_Turn, and it mirrored
##   turn180_r / turn180_l   Mixamo Walking_Turn_180 (he turns to his right), and it mirrored
## L_Start_Walking, Stop_Walking_2, L_Stop_Walking and Walking_Turn_180_2 are the same downloads as the clips above (the
## same FBX bytes; under 0.4 degrees apart after the fit), so the other feet come from mirroring. No phone, bag, carry or
## rifle walk. Every clip holds the base idle's open hand (step/idle's fingers, tools/people/make_player_idles.gd).
## The Mixamo clips come from the perf-bugs converter's packs (clips_mx_<g>.res, tools/people/make_mixamo.gd there):
## their travel and turn are taken out of the hips and kept as meta (vz / vx m/s and yaw rad, 30 a second), so the
## body moves by them and the planted foot stays put. Meta added here:
##   ph_in_mx / ph_in_ual   (stops, turns) the share of each loop it is cut in at, and in_at_mx / in_at_ual the moment
##                          of the clip it starts from there (of its first 0.6 s: the nearest feet)
##   ph_out_mx / ph_out_ual (starts, turns) the share of each loop it hands over at, and out_at_mx / out_at_ual the
##                          moment of the clip it does (near done_at: the nearest feet)
##   vz / vx / pace         made again from the planted foot (_vel_from_feet)
##   still_at               (stops) where he is standing still
##   v_out                  (starts) his pace over the half second before done_at, m/s (the start plays at the walk over it)
##   slide_cm               the planted foot's worst drift with the body moved by vz / vx / yaw (checked here)
const DIR := "res://characters/rocketbox/"
const MX_SRC := "/workspace/share/anim/walk/src/clips_mx_%s.res"
const FPS := 30.0

var sk: Skeleton3D
var prefix := "Skeleton/Skeleton3D"
var rest_g: Array[Transform3D] = []
var mirror_of: PackedInt32Array = PackedInt32Array()
var M := Basis()        # the reflection across his middle, in the skeleton's space
var skel_x := Transform3D()   # the skeleton in the figure (metres, turned)

func _bone_path(b: int) -> NodePath: return NodePath(prefix + ":" + sk.get_bone_name(b))

func _locals(a: Animation, t: float) -> Array[Transform3D]:
	var out: Array[Transform3D] = []
	for b in sk.get_bone_count():
		var rest := sk.get_bone_rest(b)
		var p := _bone_path(b)
		var pi := a.find_track(p, Animation.TYPE_POSITION_3D)
		var ri := a.find_track(p, Animation.TYPE_ROTATION_3D)
		var pos: Vector3 = a.position_track_interpolate(pi, t) if pi >= 0 else rest.origin
		var rot: Quaternion = a.rotation_track_interpolate(ri, t) if ri >= 0 else rest.basis.get_rotation_quaternion()
		out.append(Transform3D(Basis(rot), pos))
	return out

func _globals(loc: Array[Transform3D]) -> Array[Transform3D]:
	var g: Array[Transform3D] = []
	for b in sk.get_bone_count():
		var par := sk.get_bone_parent(b)
		g.append(loc[b] if par < 0 else g[par] * loc[b])
	return g

func _mirror(src: Animation) -> Animation:
	var a := Animation.new(); a.length = src.length; a.loop_mode = src.loop_mode
	var frames := int(ceil(src.length * FPS)) + 1
	var rt := {}; var pt := {}
	for ti in src.get_track_count():
		var bn := String(src.track_get_path(ti)).get_slice(":", 1)
		var b := sk.find_bone(bn)
		if b < 0: continue
		var ty := src.track_get_type(ti)
		if ty == Animation.TYPE_ROTATION_3D: var o := a.add_track(ty); a.track_set_path(o, src.track_get_path(ti)); rt[b] = o
		elif ty == Animation.TYPE_POSITION_3D: var o2 := a.add_track(ty); a.track_set_path(o2, src.track_get_path(ti)); pt[b] = o2
	var Mx := Transform3D(M, Vector3())
	for k in frames:
		var t: float = minf(float(k) / FPS, src.length)
		var g := _globals(_locals(src, t))
		var gm: Array[Transform3D] = []
		for b in sk.get_bone_count():
			var m := mirror_of[b]
			gm.append(Mx * g[m] * rest_g[m].affine_inverse() * Mx * rest_g[b])
		for b in sk.get_bone_count():
			var par := sk.get_bone_parent(b)
			var l: Transform3D = gm[b] if par < 0 else gm[par].affine_inverse() * gm[b]
			if rt.has(b): a.rotation_track_insert_key(rt[b], t, l.basis.orthonormalized().get_rotation_quaternion())
			if pt.has(b): a.position_track_insert_key(pt[b], t, l.origin)
	for key in src.get_meta_list(): a.set_meta(key, src.get_meta(key))
	for key in ["vx", "yaw"]:
		if a.has_meta(key):
			var c: PackedFloat32Array = (a.get_meta(key) as PackedFloat32Array).duplicate()
			for i in c.size(): c[i] = -c[i]
			a.set_meta(key, c)
	if a.has_meta("travel"): var tr: Vector3 = a.get_meta("travel"); a.set_meta("travel", Vector3(-tr.x, tr.y, tr.z))
	if a.has_meta("left_down"): a.set_meta("left_down", fposmod(float(a.get_meta("left_down")) + 0.5, 1.0))
	a.set_meta("mirrored", true)
	return a

## an editable copy (the packs are compressed: their keys cannot be changed), sampled at 30 a second
func _copy(src: Animation) -> Animation:
	var a := Animation.new(); a.length = src.length; a.loop_mode = src.loop_mode
	var frames := int(ceil(src.length * FPS)) + 1
	for ti in src.get_track_count():
		var ty := src.track_get_type(ti)
		if ty not in [Animation.TYPE_POSITION_3D, Animation.TYPE_ROTATION_3D, Animation.TYPE_SCALE_3D]: continue
		var o := a.add_track(ty); a.track_set_path(o, src.track_get_path(ti))
		for k in frames:
			var t: float = minf(float(k) / FPS, src.length)
			if ty == Animation.TYPE_POSITION_3D: a.position_track_insert_key(o, t, src.position_track_interpolate(ti, t))
			elif ty == Animation.TYPE_ROTATION_3D: a.rotation_track_insert_key(o, t, src.rotation_track_interpolate(ti, t))
			else: a.scale_track_insert_key(o, t, src.scale_track_interpolate(ti, t))
	for key in src.get_meta_list(): a.set_meta(key, src.get_meta(key))
	return a

## fingers: held at the base idle's open hand
func _open_hands(a: Animation, idle: Animation) -> int:
	var n := 0
	for ti in a.get_track_count():
		if a.track_get_type(ti) != Animation.TYPE_ROTATION_3D or not String(a.track_get_path(ti)).contains("Finger"): continue
		var hi := idle.find_track(a.track_get_path(ti), Animation.TYPE_ROTATION_3D)
		if hi < 0: continue
		var q := idle.rotation_track_interpolate(hi, 0.0)
		while a.track_get_key_count(ti) > 0: a.track_remove_key(ti, 0)
		a.rotation_track_insert_key(ti, 0.0, q); a.rotation_track_insert_key(ti, a.length, q)
		n += 1
	return n

## a pose's feet, for matching: both ankles and both toes' ends in the figure (metres; where the body's origin is is
## where the crossfade puts both clips)
func _legs(a: Animation, t: float) -> PackedVector3Array:
	var g := _globals(_locals(a, t))
	var out := PackedVector3Array()
	for bn in ["Bip01_L_Foot", "Bip01_R_Foot"]:
		var f: Transform3D = g[sk.find_bone(bn)]
		out.append(skel_x * f.origin); out.append(skel_x * (f * Vector3(0, 12.0, 0)))
	return out

## how far apart two poses' feet are: the worst of the four points, cm
func _pose_d(x: PackedVector3Array, y: PackedVector3Array) -> float:
	var s := 0.0
	for i in x.size(): s = maxf(s, (x[i] - y[i]).length())
	return s * 100.0

## INTO AND OUT OF THE IDLE'S STANCE (step/idle stands wide, the left foot 20 cm out and 11 cm on, the right 15 cm out and
## 27 cm back; the Mixamo starts and stops stand with the feet together, 17 cm apart): a crossfade between them would
## slide the feet 30-40 cm. So each start begins in the idle's stance and each stop ends in it: a foot stays where the
## idle has it until it first lifts (start) and goes to where the idle has it in its last swing (stop), the hips move
## over a little at the same time, and the legs reach there (two-bone IK on thigh / calf / foot, the knee bending in its
## own plane). The planted foot never moves on the ground: a foot only changes its place while it is in the air.
func _ik(loc: Array[Transform3D], g: Array[Transform3D], side: String, target: Vector3, foot_q: Quaternion) -> void:
	var th := sk.find_bone("Bip01_%s_Thigh" % side); var ca := sk.find_bone("Bip01_%s_Calf" % side); var fo := sk.find_bone("Bip01_%s_Foot" % side)
	var T := g[th].origin; var K := g[ca].origin; var F := g[fo].origin
	var a := (K - T).length(); var b := (F - K).length()
	var d := clampf((target - T).length(), absf(a - b) + 0.01, a + b - 0.01)
	var n := (K - T).cross(F - K)
	if n.length() < 1e-4: n = g[th].basis.z
	n = n.normalized()
	var want := acos(clampf((a * a + b * b - d * d) / (2.0 * a * b), -1.0, 1.0))   # (the knee's inside angle)
	var have := (T - K).angle_to(F - K)
	var best := Basis(); var bd := INF
	for sgn in [1.0, -1.0]:
		var r := Basis(n, sgn * (have - want))
		var f2 := K + r * (F - K)
		var e := absf((f2 - T).length() - d)
		if e < bd: bd = e; best = r
	# the shin about the knee, then the whole leg about the hip onto the target
	var gc := Transform3D(best * g[ca].basis, K)
	var gf := Transform3D(best * g[fo].basis, K + best * (F - K))
	var q := Quaternion(gf.origin - T, target - T) if (gf.origin - T).length() > 1e-4 and (target - T).length() > 1e-4 else Quaternion()
	var R := Basis(q)
	var gt := Transform3D(R * g[th].basis, T)
	gc = Transform3D(R * gc.basis, T + R * (gc.origin - T))
	gf = Transform3D(Basis(foot_q), T + R * (gf.origin - T))
	var par := sk.get_bone_parent(th)
	loc[th] = g[par].affine_inverse() * gt
	loc[ca] = gt.affine_inverse() * gc
	loc[fo] = gc.affine_inverse() * gf
	g[th] = gt; g[ca] = gc; g[fo] = gf

func _set_key(a: Animation, bone: String, k: int, l: Transform3D, pos: bool) -> void:
	var p := NodePath(prefix + ":" + bone)
	var ri := a.find_track(p, Animation.TYPE_ROTATION_3D)
	if ri >= 0 and k < a.track_get_key_count(ri): a.track_set_key_value(ri, k, l.basis.orthonormalized().get_rotation_quaternion())
	if pos:
		var pi := a.find_track(p, Animation.TYPE_POSITION_3D)
		if pi >= 0 and k < a.track_get_key_count(pi): a.track_set_key_value(pi, k, l.origin)

func _fit_stance(a: Animation, idle: Animation, at_start: bool) -> String:
	var frames := int(ceil(a.length * FPS)) + 1
	var gi := _globals(_locals(idle, 0.0))
	var pel := sk.find_bone("Bip01_Pelvis")
	var feet := {"L": sk.find_bone("Bip01_L_Foot"), "R": sk.find_bone("Bip01_R_Foot")}
	var ys := {"L": PackedFloat32Array(), "R": PackedFloat32Array()}
	var gs: Array = []
	for k in frames:
		var g := _globals(_locals(a, minf(k / FPS, a.length)))
		gs.append(g)
		for sd in feet: ys[sd].append(g[feet[sd]].origin.y)
	var win := {}   # side -> Vector2(from, to) frames of the swing that changes the foot's place
	var info := ""
	for sd in feet:
		var y: PackedFloat32Array = ys[sd]
		var lo := INF
		for v in y: lo = minf(lo, v)
		var up := 1.5; var dn := 1.0   # (cm over its lowest: lifted / down)
		var fa := -1; var fb := -1
		if at_start:
			for k in frames: if y[k] > y[0] + up: fa = k; break
			if fa >= 0:
				for k in range(fa, frames): if y[k] < lo + dn: fb = k; break
		else:
			for k in range(frames - 1, -1, -1): if y[k] > y[frames - 1] + up: fb = k + 1; break
			if fb >= 0:
				for k in range(fb - 1, -1, -1): if y[k] < lo + dn: fa = k; break
		if fa < 0 or fb < 0 or fb <= fa: fa = 0 if at_start else frames - 8; fb = 8 if at_start else frames - 1   # (a foot that never lifts: over 8 frames)
		win[sd] = Vector2(fa, fb)
		info += " %s %.2f-%.2fs" % [sd, fa / FPS, fb / FPS]
	var e0: int = 0 if at_start else frames - 1
	var g0: Array[Transform3D] = gs[e0]
	var p_from := 0.0; var p_to := 0.0
	if at_start: p_from = 0.0; p_to = maxf(minf(win["L"].y, win["R"].y), 6.0)
	else: p_from = minf(win["L"].x, win["R"].x); p_to = float(frames - 1)
	var off_p := gi[pel].origin - g0[pel].origin
	var q_p := gi[pel].basis.get_rotation_quaternion() * g0[pel].basis.get_rotation_quaternion().inverse()
	for k in frames:
		var t: float = minf(k / FPS, a.length)
		var loc := _locals(a, t)
		var wp := smoothstep(p_from, p_to, float(k))
		var ip := (1.0 - wp) if at_start else wp   # (how much of the idle: all of it at the start's first frame / the stop's last)
		var g := _globals(loc)
		var gpel := Transform3D(Basis(Quaternion().slerp(q_p, ip)) * g[pel].basis, g[pel].origin + off_p * ip)
		var pp := sk.get_bone_parent(pel)
		loc[pel] = gpel if pp < 0 else g[pp].affine_inverse() * gpel
		g = _globals(loc)
		var gm: Array[Transform3D] = gs[k]
		for sd in feet:
			var fb_i: int = feet[sd]
			var w: Vector2 = win[sd]
			var ww := smoothstep(w.x, w.y, float(k))
			var i_f := (1.0 - ww) if at_start else ww
			var off: Vector3 = gi[fb_i].origin - g0[fb_i].origin
			var qo: Quaternion = gi[fb_i].basis.get_rotation_quaternion() * g0[fb_i].basis.get_rotation_quaternion().inverse()
			var target: Vector3 = gm[fb_i].origin + off * i_f
			var fq: Quaternion = Quaternion().slerp(qo, i_f) * gm[fb_i].basis.get_rotation_quaternion()
			_ik(loc, g, sd, target, fq)
		_set_key(a, "Bip01_Pelvis", k, loc[pel], true)
		for sd in ["L", "R"]:
			for part in ["Thigh", "Calf", "Foot"]:
				var bn := "Bip01_%s_%s" % [sd, part]
				_set_key(a, bn, k, loc[sk.find_bone(bn)], false)
	return info

## THE BODY'S MOVE FROM THE PLANTED FOOT (the converter took vz / vx from the hips: a planted foot still slid 4-6 cm in
## the starts and stops): each frame the foot lower on the ground is the planted one, and the body moves (and keeps
## the clip's turn) so that it stays where it is in the world; vz / vx are made again from that, m/s, 30 a second.
func _vel_from_feet(a: Animation) -> void:
	var frames := int(ceil(a.length * FPS)) + 1
	var fb := [sk.find_bone("Bip01_L_Foot"), sk.find_bone("Bip01_R_Foot")]
	var pts: Array = []
	for k in frames:
		var g := _globals(_locals(a, minf(k / FPS, a.length)))
		pts.append([skel_x * g[fb[0]].origin, skel_x * g[fb[1]].origin])
	var vz := PackedFloat32Array(); var vx := PackedFloat32Array()
	var side := 0 if pts[0][0].y <= pts[0][1].y else 1
	for k in frames:
		var k2 := mini(k + 1, frames - 1)
		if k2 == k: vz.append(vz[k - 1] if k > 0 else 0.0); vx.append(vx[k - 1] if k > 0 else 0.0); continue
		var o := 1 - side
		if pts[k][o].y < pts[k][side].y - 0.004: side = o   # (the other foot is now the lower one: 4 mm, no flicker)
		var dy := _curve(a, "yaw", k2 / FPS) - _curve(a, "yaw", k / FPS)
		var p0: Vector3 = pts[k][side]; var p1: Vector3 = pts[k2][side]
		var d := p0 - Basis(Vector3.UP, dy) * p1
		vz.append(d.z * FPS); vx.append(d.x * FPS)
	# (a light smoothing: a switch of feet is not a jolt)
	var sz := vz.duplicate(); var sx := vx.duplicate()
	for k in range(1, frames - 1):
		sz[k] = (vz[k - 1] + 2.0 * vz[k] + vz[k + 1]) / 4.0; sx[k] = (vx[k - 1] + 2.0 * vx[k] + vx[k + 1]) / 4.0
	a.set_meta("vz", sz); a.set_meta("vx", sx); a.set_meta("pace", sz)

## the hand-over to a loop: the moment of the clip (from done_at - 0.6 s on, a turn's from 0.2 s before: it turns till then) and the share of the loop whose feet are
## nearest (half a cm better to hand over earlier)
func _hand_over(a: Animation, loop: Animation, done: float, early: float) -> Vector3:
	var best := Vector3(done, 0, INF)
	var t0 := maxf(done - early, 0.3)
	var k := 0
	while t0 + k / 30.0 <= minf(done + 0.2, a.length - 0.05):
		var t := t0 + k / 30.0
		var pin := _phase_in(loop, _legs(a, t))
		if pin.y < best.z - 0.5: best = Vector3(t, pin.x, pin.y)
		k += 1
	return best

## the share of loop L whose feet are nearest pose P (and how far, cm)
func _phase_in(loop: Animation, p: PackedVector3Array) -> Vector2:
	var best := 0.0; var bd := INF
	for i in 120:
		var u := float(i) / 120.0
		var d := _pose_d(_legs(loop, u * loop.length), p)
		if d < bd: bd = d; best = u
	return Vector2(best, bd)

func _curve(a: Animation, key: String, t: float) -> float:
	if not a.has_meta(key): return 0.0
	var c: PackedFloat32Array = a.get_meta(key)
	if c.is_empty(): return 0.0
	var f := clampf(t * 30.0, 0.0, c.size() - 1.0); var i := int(f); var j := mini(i + 1, c.size() - 1)
	return lerpf(c[i], c[j], f - i)

## the feet in the world with the body moved by the clip's own vz / vx / yaw (a loop: by ground_v): the worst drift of a
## foot while it is down (its ankle within 1 cm of its lowest), cm
func _slide(a: Animation, upto: float) -> float:
	var pos := Vector3(); var yaw := 0.0
	var feet := [sk.find_bone("Bip01_L_Foot"), sk.find_bone("Bip01_R_Foot")]
	var w: Array = [[], []]
	var n := int(upto * 60.0)
	for k in n + 1:
		var t := float(k) / 60.0
		var body := Transform3D(Basis(Vector3.UP, yaw), pos)
		var g := _globals(_locals(a, t))
		for s in 2: w[s].append(body * skel_x * g[feet[s]].origin)
		var vz := float(a.get_meta("ground_v")) if a.has_meta("ground_v") else _curve(a, "vz", t)
		var vx := 0.0 if a.has_meta("ground_v") else _curve(a, "vx", t)
		var y1 := _curve(a, "yaw", t + 1.0 / 60.0)
		var fwd := Vector3(sin(yaw), 0, cos(yaw)); var side := Vector3(cos(yaw), 0, -sin(yaw))
		pos += (fwd * vz + side * vx) / 60.0
		yaw = y1
	var worst := 0.0
	for s in 2:
		var lo := INF
		for p: Vector3 in w[s]: lo = minf(lo, p.y)
		var anchor := Vector3(); var down := false
		for p: Vector3 in w[s]:
			if p.y < lo + 0.01:
				if not down: anchor = p; down = true
				else: worst = maxf(worst, Vector2(p.x - anchor.x, p.z - anchor.z).length())
			else: down = false
	return worst * 100.0

func _initialize() -> void:
	for gender in ["male", "female"]:
		var scene: Node = (load(DIR + "hero_%s.scn" % gender) as PackedScene).instantiate()
		sk = scene.find_children("*", "Skeleton3D", true, false)[0]
		skel_x = Transform3D()
		var n: Node = sk
		while n != scene: skel_x = (n as Node3D).transform * skel_x; n = n.get_parent()
		rest_g.clear()
		for b in sk.get_bone_count():
			var par := sk.get_bone_parent(b)
			rest_g.append(sk.get_bone_rest(b) if par < 0 else rest_g[par] * sk.get_bone_rest(b))
		mirror_of.resize(sk.get_bone_count())
		for b in sk.get_bone_count():
			var bn := sk.get_bone_name(b)
			var other := bn.replace("_L_", "_#_").replace("_R_", "_L_").replace("_#_", "_R_")
			if bn.ends_with(" L"): other = bn.trim_suffix(" L") + " R"
			mirror_of[b] = sk.find_bone(other) if sk.find_bone(other) >= 0 else b
		var lat := (rest_g[sk.find_bone("Bip01_L_Thigh")].origin - rest_g[sk.find_bone("Bip01_R_Thigh")].origin).normalized()
		M = Basis(Vector3(1 - 2 * lat.x * lat.x, -2 * lat.x * lat.y, -2 * lat.x * lat.z), Vector3(-2 * lat.y * lat.x, 1 - 2 * lat.y * lat.y, -2 * lat.y * lat.z), Vector3(-2 * lat.z * lat.x, -2 * lat.z * lat.y, 1 - 2 * lat.z * lat.z))
		var asym := 0.0
		for b in sk.get_bone_count(): asym = maxf(asym, (M * rest_g[mirror_of[b]].origin - rest_g[b].origin).length())
		print("PLAYER_WALK %s lateral %s, rest asymmetry %.2f cm" % [gender, lat, asym])
		var mx: AnimationLibrary = load(MX_SRC % gender)
		var steps: AnimationLibrary = load(DIR + "clips_step_%s.res" % gender)
		var idle: Animation = steps.get_animation(&"idle")
		var clips := {}
		clips["walk_mx"] = _copy(mx.get_animation(&"Walking"))
		var ual := _copy(steps.get_animation(&"walk")); ual.set_meta("ground_v", 0.92); ual.set_meta("left_down", 0.0); ual.set_meta("source", "step/walk (ual/Walk_Loop)")
		clips["walk_ual"] = ual
		clips["start_a"] = _copy(mx.get_animation(&"Start_Walking")); clips["start_b"] = _mirror(mx.get_animation(&"Start_Walking"))
		clips["stop_a"] = _copy(mx.get_animation(&"Stop_Walking")); clips["stop_b"] = _mirror(mx.get_animation(&"Stop_Walking"))
		clips["turn_l"] = _copy(mx.get_animation(&"Walking_Left_Turn")); clips["turn_r"] = _mirror(mx.get_animation(&"Walking_Left_Turn"))
		clips["turn180_r"] = _copy(mx.get_animation(&"Walking_Turn_180")); clips["turn180_l"] = _mirror(mx.get_animation(&"Walking_Turn_180"))
		var src_of := {"walk_mx": "Walking", "start_a": "Start_Walking", "start_b": "Start_Walking (mirrored)", "stop_a": "Stop_Walking", "stop_b": "Stop_Walking (mirrored)", "turn_l": "Walking_Left_Turn", "turn_r": "Walking_Left_Turn (mirrored)", "turn180_r": "Walking_Turn_180", "turn180_l": "Walking_Turn_180 (mirrored)"}
		var out := AnimationLibrary.new()
		var loops := {"mx": clips["walk_mx"], "ual": clips["walk_ual"]}
		for name in ["start_a", "start_b", "walk_mx", "walk_ual", "stop_a", "stop_b", "turn_l", "turn_r", "turn180_l", "turn180_r"]:
			var a: Animation = clips[name]
			var nh := _open_hands(a, idle)
			if src_of.has(name): a.set_meta("source", "mx/" + src_of[name])
			var info := ""
			if not name.begins_with("walk"):
				var done := float(a.get_meta("done_at", a.length))
				if name.begins_with("stop"):
					var still := a.length
					for i in range(int(a.length * 30.0), -1, -1):
						var t := i / 30.0
						if absf(_curve(a, "vz", t)) > 0.05 or absf(_curve(a, "vx", t)) > 0.05: break
						still = t
					a.set_meta("still_at", still); a.set_meta("done_at", a.length); done = a.length
					info += " still_at %.2f" % still
				if name.begins_with("start") or name.begins_with("stop"): info += " idle stance:" + _fit_stance(a, idle, name.begins_with("start"))
				_vel_from_feet(a)
				if name.begins_with("start"):
					var vs := 0.0
					for i in 16: vs += _curve(a, "vz", done - 0.5 + i / 30.0) / 16.0
					a.set_meta("v_out", vs); info += " v_out %.2f m/s" % vs
					info += " from idle %.0f cm" % _pose_d(_legs(a, 0.0), _legs(idle, 0.0))
				if name.begins_with("stop"): info += " into idle %.0f cm" % _pose_d(_legs(a, a.length), _legs(idle, 0.0))
				for lk in loops:
					if name.begins_with("start"): continue   # (a start comes out of the idle)
					# the cut in: the moment of the clip (its first 0.6 s) and the share of the loop whose feet are nearest
					var best := Vector3(0, 0, INF)
					for i in 19:
						var pin := _phase_in(loops[lk], _legs(a, i / 30.0))
						if pin.y < best.z - 0.5: best = Vector3(i / 30.0, pin.x, pin.y)   # (half a cm better to cut in later)
					a.set_meta("ph_in_" + lk, best.y); a.set_meta("in_at_" + lk, best.x)
					info += " in_%s %.2f at %.2fs (%.0f cm)" % [lk, best.y, best.x, best.z]
				for lk in loops:
					if not name.begins_with("stop"):
						var ho := _hand_over(a, loops[lk], done, 0.6 if name.begins_with("start") else 0.2)
						a.set_meta("ph_out_" + lk, ho.y); a.set_meta("out_at_" + lk, ho.x)
						info += " out_%s %.2f at %.2fs (%.0f cm)" % [lk, ho.y, ho.x, ho.z]
			var sl := _slide(a, float(a.get_meta("done_at", a.length)) if not name.begins_with("walk") else a.length)
			a.set_meta("slide_cm", sl)
			out.add_animation(name, a)
			print("PLAYER_WALK %s %s %.2fs loop=%d hands %d slide %.1f cm%s" % [gender, name, a.length, a.loop_mode, nh, sl, info])
		scene.free()
		var err := ResourceSaver.save(out, DIR + "clips_player_walk_%s.res" % gender)
		print("PLAYER_WALK saved %s %s" % [gender, "ok" if err == OK else "ERROR %d" % err])
	quit(0)
