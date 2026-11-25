## Clip build tool (GDScript: a tool, not runtime). Loads Mixamo FBX at runtime with FBXDocument, retargets each
## clip onto player_v3, extracts root motion, measures contacts / speed / phase, and returns a Dictionary the C++
## runtime reads. Nothing it makes is committed (Mixamo terms): it runs on the player's machine and caches in user://.
## Decisions: DECISIONS.md 1.x and 2.x.
extends RefCounted

const FPS := 30.0

# Mixamo name (prefix stripped) -> player_v3 (Meshy) name. Same humanoid bones, a few different names (study 5.5).
const MIXAMO_TO_BODY := {
	"Hips": "Hips", "Spine": "Spine02", "Spine1": "Spine01", "Spine2": "Spine", "Neck": "neck", "Head": "Head",
	"LeftShoulder": "LeftShoulder", "LeftArm": "LeftArm", "LeftForeArm": "LeftForeArm", "LeftHand": "LeftHand",
	"RightShoulder": "RightShoulder", "RightArm": "RightArm", "RightForeArm": "RightForeArm", "RightHand": "RightHand",
	"LeftUpLeg": "LeftUpLeg", "LeftLeg": "LeftLeg", "LeftFoot": "LeftFoot", "LeftToeBase": "LeftToeBase",
	"RightUpLeg": "RightUpLeg", "RightLeg": "RightLeg", "RightFoot": "RightFoot", "RightToeBase": "RightToeBase",
}
const FINGERS := ["Thumb", "Index", "Middle", "Ring", "Pinky"]

# Limb bones swung so the body's reference pose points like Mixamo's T-pose (DECISIONS 1.2). bone -> child.
# Limbs are swung WHOLE (one rotation per limb, from its root joint to its end joint), never bone by bone: player_v3's
# knee and elbow bones are bent at rest (knee 29° / 16°, elbow ~18°) while the mesh limb is straight, so aligning each
# bone with the source's bone would bend the mesh backward (STATUS #14). group: [from joint, to joint, members...]
const LIMB_SWING := {
	"LeftShoulder": ["LeftShoulder", "LeftArm", ["LeftShoulder"]],
	"RightShoulder": ["RightShoulder", "RightArm", ["RightShoulder"]],
	"LeftArm": ["LeftArm", "LeftHand", ["LeftArm", "LeftForeArm", "LeftHand", "LeftHand*"]],
	"RightArm": ["RightArm", "RightHand", ["RightArm", "RightForeArm", "RightHand", "RightHand*"]],
	"LeftLeg": ["LeftUpLeg", "LeftFoot", ["LeftUpLeg", "LeftLeg"]],
	"RightLeg": ["RightUpLeg", "RightFoot", ["RightUpLeg", "RightLeg"]],
}

var body_skel: Skeleton3D          # player_v3's skeleton (not in a tree)
var body_scale := 0.01             # skeleton units -> metres (Armature node scale)
var bones: PackedStringArray       # body bone names, skeleton order
var parent: PackedInt32Array
var rest_local: Array[Transform3D] = []
var rest_global_m: Array[Transform3D] = []   # body rest, model space, metres
var ref_rot: Array[Quaternion] = []          # reference-pose global rotation per body bone (model space)
var src_for: PackedStringArray     # per body bone: mixamo name it takes, "" = none
var leg_k := 1.0                   # body leg length / clip leg length (DECISIONS 1.3)
var ankle_c := 0.0                 # vertical offset so the ankles stand where the clip's ankles stand
var hips_mid_off := Vector3.ZERO   # hips-local offset to the hip joints' midpoint (body)
var log_lines: PackedStringArray = []

func setup_body(body_scene: PackedScene) -> void:
	var inst := body_scene.instantiate()
	var arm: Node3D = inst.get_node("Armature")
	body_scale = arm.transform.basis.get_scale().x
	body_skel = arm.get_node("Skeleton3D")
	var n := body_skel.get_bone_count()
	bones.resize(n); parent.resize(n); src_for.resize(n)
	rest_local.resize(n); rest_global_m.resize(n)
	for i in n:
		bones[i] = body_skel.get_bone_name(i)
		parent[i] = body_skel.get_bone_parent(i)
		rest_local[i] = body_skel.get_bone_rest(i)
		var g := body_skel.get_bone_global_rest(i)
		rest_global_m[i] = Transform3D(g.basis.orthonormalized(), g.origin * body_scale)
	for i in n:
		src_for[i] = ""
	for m in MIXAMO_TO_BODY:
		var bi := bones.find(MIXAMO_TO_BODY[m])
		if bi >= 0: src_for[bi] = m
	for side in ["Left", "Right"]:
		for f in FINGERS:
			for j in range(1, 4):
				var bi := bones.find("%sHand%s%d" % [side, f, j])
				if bi >= 0: src_for[bi] = "%sHand%s%d" % [side, f, j]

func bone_idx(name: String) -> int:
	return bones.find(name)

## Source skeleton data from one FBX scene.
class Src:
	var skel: Skeleton3D
	var model: Transform3D        # skeleton -> model (metres)
	var names: PackedStringArray  # prefix-stripped
	var parent: PackedInt32Array
	var rest: Array[Transform3D] = []
	var anim: Animation
	var pos_tr: PackedInt32Array
	var rot_tr: PackedInt32Array

# NVIDIA Kimodo (SOMA 77-joint skeleton) -> Mixamo names, so both sources go through the same retargeter.
# SOMA fingers have a metacarpal joint first (Index1): its Index2-4 are Mixamo's Index1-3.
const SOMA_TO_MIXAMO := {
	"Spine1": "Spine", "Spine2": "Spine1", "Chest": "Spine2", "Neck1": "Neck",
	"LeftLeg": "LeftUpLeg", "LeftShin": "LeftLeg", "LeftToeEnd": "LeftToe_End",
	"RightLeg": "RightUpLeg", "RightShin": "RightLeg", "RightToeEnd": "RightToe_End",
}

func _strip(n: String) -> String:
	var i := n.find("_")
	if n.begins_with("mixamorig") and i > 0: return n.substr(i + 1)
	return n

static func _soma_name(n: String) -> String:
	if SOMA_TO_MIXAMO.has(n): return SOMA_TO_MIXAMO[n]
	for side in ["Left", "Right"]:
		for f in ["Index", "Middle", "Ring", "Pinky"]:
			var b: String = side + "Hand" + f
			if n.begins_with(b) and n.length() == b.length() + 1:
				var k := int(n.substr(b.length()))
				return b + str(k - 1) if k >= 2 else b + "_meta"
	return n

func load_src(path: String) -> Src:
	var doc: GLTFDocument
	var st: GLTFState
	if path.get_extension().to_lower() == "glb":
		# Kimodo: joint nodes without a skin; read them as a skeleton
		doc = GLTFDocument.new(); st = GLTFState.new()
		st.import_as_skeleton_bones = true
	else:
		doc = FBXDocument.new(); st = FBXState.new()
	if doc.append_from_file(path, st) != OK: return null
	var root: Node = doc.generate_scene(st)
	if root == null: return null
	var s := Src.new()
	s.skel = _find(root, "Skeleton3D")
	var ap: AnimationPlayer = _find(root, "AnimationPlayer")
	if s.skel == null or ap == null or ap.get_animation_list().is_empty():
		root.free(); return null
	# "with skin" files carry an empty "Take 001" beside the real take: use the one with the most tracks
	var best: Animation = null
	for an in ap.get_animation_list():
		var a := ap.get_animation(an)
		if best == null or a.get_track_count() > best.get_track_count(): best = a
	s.anim = best.duplicate()
	var m := Transform3D.IDENTITY
	var nd: Node = s.skel
	while nd != null and nd != root:
		if nd is Node3D: m = (nd as Node3D).transform * m
		nd = nd.get_parent()
	s.model = m
	var n := s.skel.get_bone_count()
	s.names.resize(n); s.parent.resize(n); s.pos_tr.resize(n); s.rot_tr.resize(n)
	for i in n:
		s.names[i] = _strip(s.skel.get_bone_name(i))
		if s.skel.find_bone("LeftShin") >= 0: s.names[i] = _soma_name(s.names[i])
		s.parent[i] = s.skel.get_bone_parent(i)
		s.rest.append(s.skel.get_bone_rest(i))
		var p := NodePath(str(root.get_path_to(s.skel)) + ":" + s.skel.get_bone_name(i))
		s.pos_tr[i] = s.anim.find_track(p, Animation.TYPE_POSITION_3D)
		s.rot_tr[i] = s.anim.find_track(p, Animation.TYPE_ROTATION_3D)
	root.free()
	return s

func _find(n: Node, cls: String) -> Node:
	if n.is_class(cls): return n
	for c in n.get_children():
		var r := _find(c, cls)
		if r != null: return r
	return null

## Source globals (model space, metres) at time t; mirrored if asked (X reflected, Left/Right swapped).
func src_globals(s: Src, t: float, mirror: bool, use_rest := false) -> Dictionary:
	var n := s.names.size()
	var g: Array[Transform3D] = []
	g.resize(n)
	for i in n:
		var l: Transform3D = s.rest[i]
		if not use_rest:
			var p := l.origin
			var q := l.basis.get_rotation_quaternion()
			if s.pos_tr[i] >= 0: p = s.anim.position_track_interpolate(s.pos_tr[i], t)
			if s.rot_tr[i] >= 0: q = s.anim.rotation_track_interpolate(s.rot_tr[i], t)
			l = Transform3D(Basis(q), p)
		g[i] = l if s.parent[i] < 0 else g[s.parent[i]] * l
	var out := {}
	for i in n:
		var w: Transform3D = s.model * g[i]
		w = Transform3D(w.basis.orthonormalized(), w.origin)
		var name := s.names[i]
		if mirror:
			var mb := Basis(Vector3(-1, 0, 0), Vector3(0, 1, 0), Vector3(0, 0, 1))
			w = Transform3D(mb * w.basis * mb, Vector3(-w.origin.x, w.origin.y, w.origin.z))
			if name.begins_with("Left"): name = "Right" + name.substr(4)
			elif name.begins_with("Right"): name = "Left" + name.substr(5)
		out[name] = w
	return out

## Body reference pose and leg scaling, from the clip's rest (Mixamo rests are all the same T-pose).
func setup_reference(s: Src) -> void:
	var sr := src_globals(s, 0.0, false, true)
	var n := bones.size()
	ref_rot.resize(n)
	for i in n:
		ref_rot[i] = rest_global_m[i].basis.get_rotation_quaternion()
	for g in LIMB_SWING:
		var spec: Array = LIMB_SWING[g]
		var a := bone_idx(spec[0]); var b := bone_idx(spec[1])
		if a < 0 or b < 0 or not sr.has(spec[0]) or not sr.has(spec[1]): continue
		var dt := (rest_global_m[b].origin - rest_global_m[a].origin).normalized()
		var ds: Vector3 = (sr[spec[1]].origin - sr[spec[0]].origin).normalized()
		var q := Quaternion(dt, ds)
		for i in n:
			var bn := bones[i]
			for m in spec[2]:
				var hit: bool = (bn == m) if not m.ends_with("*") else (bn.begins_with(m.trim_suffix("*")) and bn != m.trim_suffix("*"))
				if hit: ref_rot[i] = (q * rest_global_m[i].basis.get_rotation_quaternion()).normalized()
	# leg ratio from the straight leg, hip joint -> ankle at rest (the mesh's straight leg; DECISIONS 1.3)
	var lt := 0.0
	var ls := 0.0
	for side in ["Left", "Right"]:
		lt += rest_global_m[bone_idx(side + "UpLeg")].origin.distance_to(rest_global_m[bone_idx(side + "Foot")].origin)
		ls += sr[side + "UpLeg"].origin.distance_to(sr[side + "Foot"].origin)
	leg_k = lt / ls
	var at: float = (rest_global_m[bone_idx("LeftFoot")].origin.y + rest_global_m[bone_idx("RightFoot")].origin.y) * 0.5
	# the clip's ankle height above its own floor (Kimodo's rest has the hips at 0, Mixamo's the toes at 0)
	var floor_y := INF
	for nm in ["LeftToeBase", "RightToeBase", "LeftToe_End", "RightToe_End"]:
		if sr.has(nm): floor_y = min(floor_y, sr[nm].origin.y)
	if floor_y == INF: floor_y = 0.0
	var as_: float = (sr["LeftFoot"].origin.y + sr["RightFoot"].origin.y) * 0.5 - floor_y
	ankle_c = at - leg_k * as_
	var h := bone_idx("Hips")
	var mid := (rest_global_m[bone_idx("LeftUpLeg")].origin + rest_global_m[bone_idx("RightUpLeg")].origin) * 0.5
	hips_mid_off = rest_global_m[h].basis.inverse() * (mid - rest_global_m[h].origin)

## Retarget one frame. Returns body globals (model space, metres) as {rot: Array[Quaternion], hips: Vector3}.
func retarget_frame(sg: Dictionary, sr: Dictionary) -> Array:
	var n := bones.size()
	var grot: Array[Quaternion] = []
	grot.resize(n)
	for i in n:
		var m := src_for[i]
		if m != "" and sg.has(m):
			var d: Quaternion = sg[m].basis.get_rotation_quaternion() * sr[m].basis.get_rotation_quaternion().inverse()
			grot[i] = (d * ref_rot[i]).normalized()
		else:
			var pq := Quaternion.IDENTITY if parent[i] < 0 else grot[parent[i]]
			grot[i] = (pq * rest_local[i].basis.get_rotation_quaternion()).normalized()
	var smid: Vector3 = (sg["LeftUpLeg"].origin + sg["RightUpLeg"].origin) * 0.5
	var p := Vector3(leg_k * smid.x, leg_k * smid.y + ankle_c, leg_k * smid.z)
	var hips := p - grot[bone_idx("Hips")] * hips_mid_off
	return [grot, hips]

## FK of the body from global rotations + hips position: global positions (model space, metres).
func fk_positions(grot: Array, hips: Vector3) -> PackedVector3Array:
	var n := bones.size()
	var pos := PackedVector3Array()
	pos.resize(n)
	for i in n:
		if parent[i] < 0: pos[i] = hips
		else: pos[i] = pos[parent[i]] + grot[parent[i]] * (rest_local[i].origin * body_scale)
	return pos

static func _gauss_smooth(v: PackedFloat32Array, sigma_frames: float, cyclic: bool) -> PackedFloat32Array:
	var n := v.size()
	var out := PackedFloat32Array(); out.resize(n)
	var r := int(ceil(sigma_frames * 3.0))
	for i in n:
		var acc := 0.0; var wsum := 0.0
		for k in range(-r, r + 1):
			var j := i + k
			var val := 0.0
			if cyclic:
				# linear trend kept: unwrap by the cycle's displacement
				var cyc := n - 1
				var wraps := floori(float(j) / cyc)
				var jj := j - wraps * cyc
				val = v[jj] + wraps * (v[cyc] - v[0])
			else:
				val = v[clampi(j, 0, n - 1)]
				if j < 0: val += (v[0] - v[min(1, n - 1)]) * -j * 0.0  # hold the ends
			var w := exp(-0.5 * k * k / (sigma_frames * sigma_frames))
			acc += w * val; wsum += w
		out[i] = acc / wsum
	return out

## Build one clip. spec: {file, name, mirror, loop}. Returns the clip Dictionary or {} on failure.
func build_clip(path: String, spec: Dictionary) -> Dictionary:
	var s := load_src(path)
	if s == null:
		log_lines.append("FAIL load " + path); return {}
	var mirror: bool = spec.get("mirror", false)
	setup_reference(s)  # per file: "with skin" files carry another skeleton
	var sr := src_globals(s, 0.0, mirror, true)
	var nf_full := int(round(s.anim.length * FPS)) + 1
	var fa: int = clampi(int(spec.get("a", 0)), 0, nf_full - 1)
	var fb: int = int(spec.get("b", -1))
	if fb < 0 or fb >= nf_full: fb = nf_full - 1
	var nf := fb - fa + 1   # a cut: frames fa..fb of the source (30 fps)
	var n := bones.size()
	var H := bone_idx("Hips")
	var frames_rot: Array = []
	var frames_hips: PackedVector3Array = []
	var yaw := PackedFloat32Array(); yaw.resize(nf)
	var rx := PackedFloat32Array(); rx.resize(nf)
	var rz := PackedFloat32Array(); rz.resize(nf)
	var fwd_local := rest_global_m[H].basis.get_rotation_quaternion().inverse() * Vector3(0, 0, 1)
	var prev_yaw := 0.0
	for f in nf:
		var t: float = min((f + fa) / FPS, s.anim.length)
		var sg := src_globals(s, t, mirror)
		var rt := retarget_frame(sg, sr)
		frames_rot.append(rt[0]); frames_hips.append(rt[1])
		var fw: Vector3 = rt[0][H] * fwd_local
		var y := atan2(fw.x, fw.z)
		if f > 0: y = prev_yaw + wrapf(y - prev_yaw, -PI, PI)
		prev_yaw = y
		yaw[f] = y; rx[f] = rt[1].x; rz[f] = rt[1].z
	var loop: bool = spec.get("loop", false)
	# root = smoothed hips ground track and heading (study 5.3); loops keep their linear trend (cyclic smoothing)
	var sig := FPS * 0.2
	var syaw := _gauss_smooth(yaw, sig, loop)
	var hx := _gauss_smooth(rx, sig, loop)
	var hz := _gauss_smooth(rz, sig, loop)
	# keep the forward progress sharp (braking and pushing stay where they are), smooth only the sideways sway:
	# the heavy path gives the direction, a light (0.05 s) smoothing gives the progress along it
	var lx := _gauss_smooth(rx, FPS * 0.05, loop)
	var lz := _gauss_smooth(rz, FPS * 0.05, loop)
	var sx := PackedFloat32Array(); sx.resize(nf)
	var sz := PackedFloat32Array(); sz.resize(nf)
	for f in nf:
		var a: int = max(f - 1, 0); var b: int = min(f + 1, nf - 1)
		var tg := Vector2(hx[b] - hx[a], hz[b] - hz[a])
		var pt := Vector2(hx[f], hz[f])
		if tg.length() > 1e-4:
			tg = tg.normalized()
			pt += tg * tg.dot(Vector2(lx[f], lz[f]) - pt)
		sx[f] = pt.x; sz[f] = pt.y
	if spec.get("root_lock_yaw", false):
		for f in nf: syaw[f] = 0.0
	var rot := PackedFloat32Array(); rot.resize(nf * n * 4)
	var hipsp := PackedFloat32Array(); hipsp.resize(nf * 3)
	var root := PackedFloat32Array(); root.resize(nf * 3)
	var lankle := PackedVector3Array(); var rankle := PackedVector3Array()
	var ltoe := PackedVector3Array(); var rtoe := PackedVector3Array()
	var LF := bone_idx("LeftFoot"); var RF := bone_idx("RightFoot")
	var LT := bone_idx("LeftToeBase"); var RT := bone_idx("RightToeBase")
	for f in nf:
		var grot: Array = frames_rot[f]
		var ry := Quaternion(Vector3.UP, syaw[f])
		var rinv := ry.inverse()
		var rp := Vector3(sx[f], 0, sz[f])
		root[f * 3] = sx[f]; root[f * 3 + 1] = sz[f]; root[f * 3 + 2] = syaw[f]
		var hp: Vector3 = rinv * (frames_hips[f] - rp)
		hipsp[f * 3] = hp.x / body_scale; hipsp[f * 3 + 1] = hp.y / body_scale; hipsp[f * 3 + 2] = hp.z / body_scale
		for i in n:
			var q: Quaternion
			if parent[i] < 0: q = rinv * grot[i]
			else: q = grot[parent[i]].inverse() * grot[i]
			q = q.normalized()
			var o := (f * n + i) * 4
			rot[o] = q.x; rot[o + 1] = q.y; rot[o + 2] = q.z; rot[o + 3] = q.w
		var pos := fk_positions(grot, frames_hips[f])
		lankle.append(pos[LF]); rankle.append(pos[RF]); ltoe.append(pos[LT]); rtoe.append(pos[RT])
	var clip := {
		"name": spec.name, "file": path.get_file(), "src_path": path, "src_a": fa, "mirror": mirror, "loop": loop, "fps": FPS, "frames": nf,
		"bones": n, "rot": rot, "hips": hipsp, "root": root,
	}
	_measure(clip, lankle, rankle, ltoe, rtoe)
	return clip

## Contacts, speed, phase (DECISIONS 2.1). Foot down = ankle and toe near their standing heights and slow.
func _measure(clip: Dictionary, la: PackedVector3Array, ra: PackedVector3Array, lt: PackedVector3Array, rt: PackedVector3Array) -> void:
	var nf: int = clip.frames
	var a_rest := rest_global_m[bone_idx("LeftFoot")].origin.y
	var t_rest := rest_global_m[bone_idx("LeftToeBase")].origin.y
	var contact := [PackedByteArray(), PackedByteArray()]
	var heights := [PackedFloat32Array(), PackedFloat32Array()]
	for side in 2:
		var A: PackedVector3Array = la if side == 0 else ra
		var T: PackedVector3Array = lt if side == 0 else rt
		contact[side].resize(nf)
		for f in nf:
			var f0: int = max(f - 1, 0); var f1: int = min(f + 1, nf - 1)
			var dt := (f1 - f0) / FPS
			var va := Vector2(A[f1].x - A[f0].x, A[f1].z - A[f0].z).length() / dt
			var vt := Vector2(T[f1].x - T[f0].x, T[f1].z - T[f0].z).length() / dt
			var heel_down := A[f].y < a_rest + 0.035 and va < 0.45
			var toe_down := T[f].y < t_rest + 0.025 and vt < 0.45
			contact[side][f] = 1 if (heel_down or toe_down) else 0
			heights[side].append(min(A[f].y - a_rest, T[f].y - t_rest))
	clip["contact_l"] = contact[0]; clip["contact_r"] = contact[1]
	clip["foot_h_l"] = heights[0]; clip["foot_h_r"] = heights[1]
	var root: PackedFloat32Array = clip.root
	var dx := root[(nf - 1) * 3] - root[0]; var dz := root[(nf - 1) * 3 + 1] - root[1]
	var dur := (nf - 1) / FPS
	clip["dist"] = Vector2(dx, dz).length()
	clip["speed"] = clip.dist / dur if dur > 0 else 0.0
	clip["turn"] = root[(nf - 1) * 3 + 2] - root[2]
	# strikes: frames where a contact starts
	var strikes := [[], []]
	for side in 2:
		for f in range(1, nf):
			if contact[side][f] == 1 and contact[side][f - 1] == 0: strikes[side].append(f)
	clip["strikes_l"] = strikes[0]; clip["strikes_r"] = strikes[1]
	clip["leg_k"] = leg_k

static func summary(c: Dictionary) -> String:
	var cl := ""; var cr := ""
	var nf: int = c.frames
	for f in nf:
		cl += "L" if c.contact_l[f] else "."
		cr += "R" if c.contact_r[f] else "."
	return "%-34s %s n=%3d dist=%5.2f v=%4.2f turn=%6.1f strikesL=%s strikesR=%s\n    %s\n    %s" % [
		c.name, "M" if c.mirror else " ", nf, c.dist, c.speed, rad_to_deg(c.turn), str(c.strikes_l), str(c.strikes_r), cl, cr]
