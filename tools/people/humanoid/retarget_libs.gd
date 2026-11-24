extends SceneTree
## Batch retarget (studio style, like Unreal's IK Retargeter run over animation assets): every finished clip library of
## the movement system (characters/rocketbox/clips_<stem>_male.res, on the old Bip01 figure, with all their hand-made
## meta: pace, foot phases, turn angles, hand-over points) onto HIS skeleton - the Meshy player v3 on Godot's standard
## humanoid skeleton (assets/people/humanoid/player_v3.glb). Same clip names, same meta.
##   godot --headless --path . -s res://tools/people/humanoid/retarget_libs.gd [-- --only=stem,stem]
## -> characters/hero_v3/clips_<stem>.res
## The math, 30 times a second: the turn each old bone has made in the world from its rest is given to his matching bone,
## starting from his bone laid along the old limb (his rest is a T, the old one an A); the hip joints' middle follows the
## old one's, scaled by the two figures' leg lengths, so his feet land where the old feet did relative to the body.
const SRC_FIG := "res://characters/rocketbox/hero_male.scn"
const DST_FIG := "res://assets/people/humanoid/player_v3.glb"
const SRC_DIR := "res://characters/rocketbox/"
const OUT := "res://characters/hero_v3/"
const STEMS := ["", "ual", "step", "mx", "yl", "ms", "player_idle", "player_walk", "player_run", "player_trav", "player_act"]
const FPS := 30.0
## (Yasin, 23 Nov: "shoulders drop way down whenever an animation plays other than the idle" - the walks hold the collarbone
## up to 18 deg below level, the old figure the same; on his broad shoulders it reads as a slump) CLEANED like mocap: his
## collarbone at most this far below level; the upper arm keeps its own direction in the world (only the shoulder line lifts)
const CLAV_MIN_DEG := -5.0
## ... in the standing and moving libraries only: a reach (a vault's hands onto the rail, a climb, a carry) drops the
## collarbone for real - held up, his hands stopped 10-35 cm short of the rail
const CLAV_LIBS := ["player_walk", "player_run", "player_idle", "ms", "yl", "step"]
var clav_on := false

## old bone -> his bone, old bone further along the limb (its rest direction lays his limb along the old one)
const PAIRS := [
	["Bip01_Pelvis", "Hips", ""], ["Bip01_Spine", "Spine", "Bip01_Spine1"], ["Bip01_Spine1", "Chest", "Bip01_Spine2"],
	["Bip01_Spine2", "UpperChest", "Bip01_Neck"], ["Bip01_Neck", "Neck", "Bip01_Head"], ["Bip01_Head", "Head", ""],
]
const SIDE := [["Clavicle", "Shoulder", "UpperArm"], ["UpperArm", "UpperArm", "Forearm"], ["Forearm", "LowerArm", "Hand"],
	["Hand", "Hand", "Finger2"], ["Thigh", "UpperLeg", "Calf"], ["Calf", "LowerLeg", "Foot"], ["Foot", "Foot", ""]]
const FING := [["0", "Thumb"], ["1", "Index"], ["2", "Middle"], ["3", "Ring"], ["4", "Little"]]
const PH := ["Proximal", "Intermediate", "Distal"]
const PH_THUMB := ["Metacarpal", "Proximal", "Distal"]

var ssk: Skeleton3D; var dsk: Skeleton3D
var sx := Transform3D(); var dx := Transform3D()   # each skeleton in its figure
var map := {}     # his bone index -> old bone index
var lay := {}     # his bone index -> Quaternion
var srest_w: Array[Quaternion] = []; var drest_w: Array[Quaternion] = []
var s_th := []; var d_th := []
var k_leg := 1.0
var d_hips := -1
var d_mid_rest := Vector3(); var s_mid_rest := Vector3()
var d_path := ""

func _pairs() -> Array:
	var out := PAIRS.duplicate()
	for s in [["L", "Left"], ["R", "Right"]]:
		for p in SIDE: out.append(["Bip01_%s_%s" % [s[0], p[0]], s[1] + p[1], ("Bip01_%s_%s" % [s[0], p[2]]) if p[2] != "" else ""])
		for f in FING:
			var names: Array = PH_THUMB if f[1] == "Thumb" else PH
			for j in 3:
				var src := "Bip01_%s_Finger%s%s" % [s[0], f[0], "" if j == 0 else str(j)]
				var nxt := ("Bip01_%s_Finger%s%d" % [s[0], f[0], j + 1]) if j < 2 else ""
				out.append([src, s[1] + f[1] + names[j], nxt])
	return out

func _chain(n: Node, top: Node) -> Transform3D:
	var x := Transform3D()
	while n != top: x = (n as Node3D).transform * x; n = n.get_parent()
	return x

static func _q(t: Transform3D) -> Quaternion: return t.basis.orthonormalized().get_rotation_quaternion()

func _setup() -> void:
	var s: Node3D = (load(SRC_FIG) as PackedScene).instantiate(); var d: Node3D = (load(DST_FIG) as PackedScene).instantiate()
	ssk = s.find_children("*", "Skeleton3D", true, false)[0]; dsk = d.find_children("*", "Skeleton3D", true, false)[0]
	sx = _chain(ssk, s); dx = _chain(dsk, d)
	d_path = str(d.get_path_to(dsk))
	for b in ssk.get_bone_count(): srest_w.append(_q(sx) * _q(ssk.get_bone_global_rest(b)))
	for b in dsk.get_bone_count(): drest_w.append(_q(dx) * _q(dsk.get_bone_global_rest(b)))
	for p in _pairs():
		var sb := ssk.find_bone(p[0]); var db := dsk.find_bone(p[1])
		if sb < 0 or db < 0: print("RETARGET no pair ", p); continue
		map[db] = sb
		lay[db] = Quaternion()
		if p[2] == "": continue
		var sn := ssk.find_bone(p[2])
		var dn := -1
		for q in _pairs(): if q[0] == p[2]: dn = dsk.find_bone(q[1])
		if sn < 0 or dn < 0: continue
		var ds := ((sx * ssk.get_bone_global_rest(sn)).origin - (sx * ssk.get_bone_global_rest(sb)).origin).normalized()
		var dd := ((dx * dsk.get_bone_global_rest(dn)).origin - (dx * dsk.get_bone_global_rest(db)).origin).normalized()
		if ds.dot(dd) > -0.999: lay[db] = Quaternion(dd, ds)
	for nm in ["LeftShoulder", "RightShoulder"]:
		var c := dsk.find_bone(nm); var u := dsk.find_bone(nm.replace("Shoulder", "UpperArm"))
		clav.append(c)
		clav_dir[c] = Basis(drest_w[c]).inverse() * ((dx * dsk.get_bone_global_rest(u)).origin - (dx * dsk.get_bone_global_rest(c)).origin).normalized()
	s_th = [ssk.find_bone("Bip01_L_Thigh"), ssk.find_bone("Bip01_R_Thigh"), ssk.find_bone("Bip01_L_Foot"), ssk.find_bone("Bip01_R_Foot")]
	d_th = [dsk.find_bone("LeftUpperLeg"), dsk.find_bone("RightUpperLeg"), dsk.find_bone("LeftFoot"), dsk.find_bone("RightFoot")]
	d_hips = dsk.find_bone("Hips")
	var sp := func(b): return (sx * ssk.get_bone_global_rest(b)).origin
	var dp := func(b): return (dx * dsk.get_bone_global_rest(b)).origin
	s_mid_rest = (sp.call(s_th[0]) + sp.call(s_th[1])) * 0.5; d_mid_rest = (dp.call(d_th[0]) + dp.call(d_th[1])) * 0.5
	var s_leg: float = (sp.call(s_th[0]) - sp.call(s_th[2])).length(); var d_leg: float = (dp.call(d_th[0]) - dp.call(d_th[2])).length()
	k_leg = d_leg / s_leg
	print("RETARGET pairs %d  leg old %.3f his %.3f  k %.3f  path %s" % [map.size(), s_leg, d_leg, k_leg, d_path])

## the collarbone's world turn lifted so the line to the shoulder joint is at most CLAV_MIN_DEG below level
var clav := []; var clav_dir := {}   # his collarbones; their rest direction (to the shoulder joint) in the bone's own frame
func _lift_clav(db: int, tw: Array[Quaternion], _pw: Quaternion) -> Quaternion:
	var d: Vector3 = (Basis(tw[db]) * clav_dir[db]).normalized()
	var flat := Vector2(d.x, d.z).length()
	var ang := atan2(d.y, flat)
	var lo := deg_to_rad(CLAV_MIN_DEG)
	if ang >= lo or flat < 1e-4: return tw[db]
	var axis := d.cross(Vector3.UP).normalized()
	return (Quaternion(axis, lo - ang) * tw[db]).normalized()

## the old figure's bones in its figure, at time t
func _src_globals(a: Animation, tracks: Dictionary, t: float) -> Array[Transform3D]:
	var g: Array[Transform3D] = []
	for b in ssk.get_bone_count():
		var rest := ssk.get_bone_rest(b)
		var tr: Array = tracks.get(b, [-1, -1])
		var l := Transform3D(Basis(a.rotation_track_interpolate(tr[1], t) if tr[1] >= 0 else rest.basis.get_rotation_quaternion()), a.position_track_interpolate(tr[0], t) if tr[0] >= 0 else rest.origin)
		var par := ssk.get_bone_parent(b)
		g.append(l if par < 0 else g[par] * l)
	return g

func _clip(a: Animation) -> Animation:
	var tracks := {}
	for k in a.get_track_count():
		var p := a.track_get_path(k)
		if p.get_subname_count() < 1: continue
		var b := ssk.find_bone(p.get_subname(0))
		if b < 0: continue
		if not tracks.has(b): tracks[b] = [-1, -1]
		if a.track_get_type(k) == Animation.TYPE_POSITION_3D: tracks[b][0] = k
		elif a.track_get_type(k) == Animation.TYPE_ROTATION_3D: tracks[b][1] = k
	var o := Animation.new(); o.length = a.length; o.loop_mode = a.loop_mode
	for m in a.get_meta_list(): o.set_meta(m, a.get_meta(m))
	var n := dsk.get_bone_count()
	var tr := {}
	for db in map: tr[db] = o.add_track(Animation.TYPE_ROTATION_3D); o.track_set_path(tr[db], NodePath(d_path + ":" + dsk.get_bone_name(db)))
	var tp := o.add_track(Animation.TYPE_POSITION_3D); o.track_set_path(tp, NodePath(d_path + ":Hips"))
	var frames := maxi(int(ceil(a.length * FPS)), 1)
	var dxq := _q(dx); var dxi := dx.affine_inverse()
	var tw: Array[Quaternion] = []; tw.resize(n)
	for f in frames + 1:
		var t := minf(a.length, f / FPS)
		var g := _src_globals(a, tracks, t)
		for db in n:
			var par := dsk.get_bone_parent(db)
			var pw: Quaternion = tw[par] if par >= 0 else dxq
			if map.has(db):
				var sb: int = map[db]
				var turned := (_q(sx) * _q(g[sb])) * srest_w[sb].inverse()
				tw[db] = (turned * lay[db] * drest_w[db]).normalized()
				if clav_on and db in clav: tw[db] = _lift_clav(db, tw, pw)
				o.rotation_track_insert_key(tr[db], t, (pw.inverse() * tw[db]).normalized())
			else:
				tw[db] = (pw * dsk.get_bone_rest(db).basis.get_rotation_quaternion()).normalized()
		# the hip joints' middle follows the old one's (scaled by the legs); his Hips bone placed from it
		var s_mid := ((sx * g[s_th[0]]).origin + (sx * g[s_th[1]]).origin) * 0.5
		var want := d_mid_rest + (s_mid - s_mid_rest) * k_leg
		var hips_w := Basis(tw[d_hips])
		var off := (dx * dsk.get_bone_global_rest(d_th[0])).origin + (dx * dsk.get_bone_global_rest(d_th[1])).origin
		off = off * 0.5 - (dx * dsk.get_bone_global_rest(d_hips)).origin
		var hips_pos := want - hips_w * (Basis(drest_w[d_hips]).inverse() * off)
		var par_h := dsk.get_bone_parent(d_hips)
		var loc := dxi * hips_pos
		if par_h >= 0: loc = dsk.get_bone_global_rest(par_h).affine_inverse() * loc
		o.position_track_insert_key(tp, t, loc)
	return o

func _init() -> void:
	var only := []
	for a in OS.get_cmdline_user_args(): if a.begins_with("--only="): only = a.substr(7).split(",")
	_setup()
	DirAccess.make_dir_recursive_absolute(OUT)
	for stem in STEMS:
		if not only.is_empty() and not only.has(stem if stem != "" else "base"): continue
		var src: String = SRC_DIR + "clips_" + (stem + "_" if stem != "" else "") + "male.res"
		var lib: AnimationLibrary = load(src)
		if lib == null: print("RETARGET missing ", src); continue
		clav_on = CLAV_LIBS.has(stem)
		var out := AnimationLibrary.new()
		var t0 := Time.get_ticks_msec()
		for nm in lib.get_animation_list():
			var o := _clip(lib.get_animation(nm))
			# (NOT compressed by default: Animation.compress() put a 64 cm kick into his Running_Jump_Climb - a foot planted on
			# the box thrown up and back; COMPRESS=1 for a size test - check the clips after)
			if OS.get_environment("COMPRESS") != "": o.compress()
			out.add_animation(nm, o)
		var dst: String = OUT + "clips_" + (stem if stem != "" else "base") + ".res"
		print("RETARGET %s: %d clips in %.1f s -> %s %s" % [src.get_file(), out.get_animation_list().size(), (Time.get_ticks_msec() - t0) / 1000.0, dst, ResourceSaver.save(out, dst, ResourceSaver.FLAG_COMPRESS) == OK])
	quit()
