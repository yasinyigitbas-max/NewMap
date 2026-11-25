## Clip build step (study v2 1.7, 12.4): on the body, per frame, the sole points (from the C++ body model) give the
## clip's floor and its foot contacts. Moves the clip so its floor is y = 0 and replaces the ankle/toe-height contacts
## with sole-point contacts: a foot is down while its lowest sole point is within 1.2 cm of the floor (ground clips) or
## still (traversal clips, whose floor changes) and moving under 0.25 m/s.
extends RefCounted

var body: Node3D
var sk: Skeleton3D
var chk

func setup(host: Node) -> void:
	body = load("res://body/player_v3.glb").instantiate()
	host.add_child(body)
	sk = body.get_node("Armature/Skeleton3D")
	chk = ClassDB.instantiate("PoseCheck")
	sk.add_child(chk)
	chk.set_active(false)

func cleanup() -> void:
	if body: body.queue_free()

func pose(c: Dictionary, f: int) -> void:
	var rot: PackedFloat32Array = c.rot; var hips: PackedFloat32Array = c.hips; var rt: PackedFloat32Array = c.root
	var n: int = c.bones
	for i in n:
		var o := (f * n + i) * 4
		sk.set_bone_pose_rotation(i, Quaternion(rot[o], rot[o + 1], rot[o + 2], rot[o + 3]))
	sk.set_bone_pose_position(0, Vector3(hips[f * 3], hips[f * 3 + 1], hips[f * 3 + 2]))
	body.transform = Transform3D(Basis(Vector3.UP, rt[f * 3 + 2]), Vector3(rt[f * 3], 0, rt[f * 3 + 1]))

## the four sole points of each foot, world, per frame (C++ forward kinematics, no scene update): S[f][side][k]
func soles(c: Dictionary) -> Array:
	var raw: PackedVector3Array = chk.clip_lowest_soles(c.rot, c.hips, c.root, int(c.frames))
	var out := []
	for f in int(c.frames):
		out.append([raw.slice(f * 8, f * 8 + 4), raw.slice(f * 8 + 4, f * 8 + 8)])
	return out

static func _low(pts: PackedVector3Array) -> float:
	var m := 1e9
	for p in pts: m = min(m, p.y)
	return m

## the generator's contact labels (a sidecar <file>.contacts.json next to the source), mirrored with the clip
static func _labels(c: Dictionary) -> Array:
	var sp: String = c.get("src_path", "")
	if sp == "": return []
	var j := sp.get_basename() + ".contacts.json"
	if not FileAccess.file_exists(j): return []
	var d = JSON.parse_string(FileAccess.get_file_as_string(j))
	if typeof(d) != TYPE_DICTIONARY: return []
	var a: int = c.get("src_a", 0)
	var l: Array = d.get("left", []).slice(a); var r: Array = d.get("right", []).slice(a)
	return [r, l] if c.get("mirror", false) else [l, r]

func process(c: Dictionary, traverse: bool) -> void:
	var nf: int = c.frames
	var fps: float = c.fps
	var S := soles(c)
	# the floor per frame: the lowest sole point over a +-0.5 s window, smoothed (Kimodo's running part floats ~2.5 cm
	# above its standing part, so one value per clip is not enough). Traversal clips: the floor they start on.
	var low := PackedFloat32Array(); low.resize(nf)
	for f in nf: low[f] = min(_low(S[f][0]), _low(S[f][1]))
	var fl := PackedFloat32Array(); fl.resize(nf)
	for f in nf:
		if traverse:
			var m := 1e9
			for g in mini(nf, 12): m = min(m, low[g])
			fl[f] = m
		else:
			# a robust low: the 25th percentile (a heel strike sinking 2-3 cm for a frame must not set the floor)
			var w := []
			for g in range(maxi(0, f - 15), mini(nf, f + 16)): w.append(low[g])
			w.sort()
			fl[f] = w[int(w.size() * 0.25)]
	if not traverse:
		var sm := PackedFloat32Array(); sm.resize(nf)
		for f in nf:
			var acc := 0.0; var w := 0.0
			for g in range(maxi(0, f - 10), mini(nf, f + 11)):
				var k := exp(-0.5 * pow((g - f) / 5.0, 2)); acc += fl[g] * k; w += k
			sm[f] = acc / w
		fl = sm
	var hips: PackedFloat32Array = c.hips
	for f in nf: hips[f * 3 + 1] -= fl[f] / 0.01
	c.hips = hips
	var fsum := 0.0
	for f in nf: fsum += fl[f]
	c["floor_fix"] = fsum / nf
	S = soles(c)
	var floor_y := 0.0
	# contacts: the generator's own per-frame labels when it wrote them (Kimodo: heel / toe / toe-end per foot), else
	# from the sole points
	var side_lab := _labels(c)
	for s in 2:
		var con := PackedByteArray(); con.resize(nf)
		if side_lab.size() == 2:
			var lab: Array = side_lab[s]
			for f in nf: con[f] = 1 if lab[mini(f, lab.size() - 1)] else 0
		else:
			for f in nf:
				var a: int = max(f - 1, 0); var b: int = min(f + 1, nf - 1)
				var down := false
				for k in 4:
					var p: Vector3 = S[f][s][k]
					var dv: Vector3 = (S[b][s][k] - S[a][s][k]) / ((b - a) / fps)
					var h: float = p.y - floor_y
					var slow := Vector2(dv.x, dv.z).length() < 0.6
					if not traverse:
						if h < 0.012 and slow: down = true
					elif slow and abs(dv.y) < 0.1: down = true
				con[f] = 1 if down else 0
		# a single-frame flicker is not a step
		for f in range(1, nf - 1):
			if con[f - 1] == con[f + 1] and con[f] != con[f - 1]: con[f] = con[f - 1]
		c["contact_l" if s == 0 else "contact_r"] = con
	c["contacts_from"] = "generator labels" if side_lab.size() == 2 else "sole points"
	var strikes := [[], []]
	for s in 2:
		var con: PackedByteArray = c["contact_l" if s == 0 else "contact_r"]
		for f in range(1, nf):
			if con[f] == 1 and con[f - 1] == 0: strikes[s].append(f)
	c["strikes_l"] = strikes[0]; c["strikes_r"] = strikes[1]

# ---------------- build-time foot lock (study v2 12.4, 10.6): retargeting onto other leg proportions makes a planted
# foot slide (the Kimodo run: 2-3 cm in the source, ~9 cm on player_v3). In each contact window the contact point is
# pinned where it landed (the heel, then the ball once the heel lifts), the leg re-solved with two-bone IK in the
# clip's own knee plane, the foot keeping its orientation; the correction fades in over 2 frames and out over 4.

var _par := PackedInt32Array()
var _rest_pos := PackedVector3Array()   # local rest origins, skeleton units
var _B := {}

func _setup_fk() -> void:
	if _par.size() > 0: return
	var n := sk.get_bone_count()
	_par.resize(n); _rest_pos.resize(n)
	for i in n:
		_par[i] = sk.get_bone_parent(i)
		_rest_pos[i] = sk.get_bone_rest(i).origin
	for nm in ["Hips", "LeftUpLeg", "LeftLeg", "LeftFoot", "RightUpLeg", "RightLeg", "RightFoot"]: _B[nm] = sk.find_bone(nm)

## global (clip-world, metres) rotations and positions of one frame
func _fk(c: Dictionary, f: int) -> Array:
	var n: int = c.bones
	var rot: PackedFloat32Array = c.rot; var hips: PackedFloat32Array = c.hips; var rt: PackedFloat32Array = c.root
	var R := Quaternion(Vector3.UP, rt[f * 3 + 2])
	var T := Vector3(rt[f * 3], 0, rt[f * 3 + 1])
	var gq: Array[Quaternion] = []; gq.resize(n)
	var gp := PackedVector3Array(); gp.resize(n)
	for i in n:
		var o := (f * n + i) * 4
		var q := Quaternion(rot[o], rot[o + 1], rot[o + 2], rot[o + 3])
		if _par[i] < 0:
			gq[i] = R * q
			gp[i] = T + R * (Vector3(hips[f * 3], hips[f * 3 + 1], hips[f * 3 + 2]) * 0.01)
		else:
			gq[i] = gq[_par[i]] * q
			gp[i] = gp[_par[i]] + gq[_par[i]] * (_rest_pos[i] * 0.01)
	return [gq, gp]

func _set_local(c: Dictionary, f: int, i: int, q: Quaternion) -> void:
	var rot: PackedFloat32Array = c.rot
	var o := (f * int(c.bones) + i) * 4
	q = q.normalized()
	rot[o] = q.x; rot[o + 1] = q.y; rot[o + 2] = q.z; rot[o + 3] = q.w
	c.rot = rot

## move the ankle of `side` by `corr` (metres, world) on frame f
func _ik(c: Dictionary, f: int, side: int, corr: Vector3) -> void:
	if corr.length() < 1e-4: return
	var P := _fk(c, f)
	var gq: Array = P[0]; var gp: PackedVector3Array = P[1]
	var sd := "Left" if side == 0 else "Right"
	var iu: int = _B[sd + "UpLeg"]; var il: int = _B[sd + "Leg"]; var ifo: int = _B[sd + "Foot"]
	var hip := gp[iu]; var knee := gp[il]; var ank := gp[ifo]
	var l1 := hip.distance_to(knee); var l2 := knee.distance_to(ank)
	var target := ank + corr
	var to := target - hip
	var d := to.length()
	var reach := (l1 + l2) * 0.999
	d = clamp(d, abs(l1 - l2) + 1e-3, reach)
	var dir := to.normalized()
	# keep the clip's knee plane: the knee's offset from the hip-ankle line
	var kp := (knee - hip) - dir * (knee - hip).dot(dir)
	if kp.length() < 1e-5: kp = (gq[iu] * Vector3(0, 0, 1))
	var nrm := kp.normalized()
	var ca := clampf((l1 * l1 + d * d - l2 * l2) / (2 * l1 * d), -1, 1)
	var new_knee := hip + dir * (l1 * ca) + nrm * (l1 * sqrt(max(0.0, 1 - ca * ca)))
	var new_ank := hip + dir * d
	# rotate thigh and shin inside the knee plane only (the plane's normal stays), so the knee hinge doesn't twist
	var pn := (knee - hip).cross(ank - hip)
	if pn.length() < 1e-6: pn = (gq[iu] as Quaternion) * Vector3(1, 0, 0)
	pn = pn.normalized()
	var q_up: Quaternion = _in_plane(knee - hip, new_knee - hip, pn) * gq[iu]
	var q_lo: Quaternion = _in_plane(ank - knee, new_ank - new_knee, pn) * gq[il]
	var gfoot: Quaternion = gq[ifo]  # the foot keeps its world orientation
	_set_local(c, f, iu, (gq[_par[iu]] as Quaternion).inverse() * q_up)
	_set_local(c, f, il, q_up.inverse() * q_lo)
	_set_local(c, f, ifo, q_lo.inverse() * gfoot)

static func _in_plane(a: Vector3, b: Vector3, n: Vector3) -> Quaternion:
	var ta := a.normalized(); var tb := b.normalized()
	var Ba := Basis(ta, n, ta.cross(n).normalized()).orthonormalized()
	var Bb := Basis(tb, n, tb.cross(n).normalized()).orthonormalized()
	return (Bb * Ba.inverse()).get_rotation_quaternion()

func lock_feet(c: Dictionary, traverse := false) -> void:
	_setup_fk()
	var nf: int = c.frames
	var S := soles(c)
	for side in 2:
		var con: PackedByteArray = c["contact_l" if side == 0 else "contact_r"]
		var corr := []
		corr.resize(nf)
		for f in nf: corr[f] = Vector3.ZERO
		var f := 0
		while f < nf:
			if con[f] == 0: f += 1; continue
			var a := f
			while f < nf and con[f] == 1: f += 1
			var b := f - 1
			# the pivot: the lowest point at landing; when the heel lifts past 1.2 cm, the lower ball
			var piv := 0
			var lo := 1e9
			for k in 4: if S[a][side][k].y < lo: lo = S[a][side][k].y; piv = k
			# the landing slides a little in the clip: pin where the point comes to rest (slowest of the first 4 frames)
			var rest_f := a
			var vmin := 1e9
			for g in range(a, min(a + 4, b) + 1):
				var g0: int = max(g - 1, 0); var g1: int = min(g + 1, nf - 1)
				var v := Vector2(S[g1][side][piv].x - S[g0][side][piv].x, S[g1][side][piv].z - S[g0][side][piv].z).length()
				if v < vmin: vmin = v; rest_f = g
			var anchor: Vector3 = S[rest_f][side][piv]
			var held := Vector3.ZERO
			for g in range(a, b + 1):
				if piv == 0 and S[g][side][0].y > 0.012:
					var nk := 1 if S[g][side][1].y < S[g][side][2].y else 2
					anchor = S[g][side][nk] + held   # keep the correction continuous at the switch
					piv = nk
				var cur: Vector3 = S[g][side][piv]
				var dc := anchor - cur
				var lowest := 1e9
				for k in 4: lowest = min(lowest, S[g][side][k].y)
				dc.y = 0.0 if traverse else -lowest   # ground clips: the foot's lowest point onto the floor
				held = Vector3(dc.x, 0, dc.z)
				corr[g] = dc
			# fade in 2 frames before, out 4 frames after
			for k in range(1, 3):
				if a - k >= 0 and con[a - k] == 0: corr[a - k] = corr[a] * (1.0 - k / 3.0)
			for k in range(1, 5):
				if b + k < nf and con[b + k] == 0: corr[b + k] = corr[b] * (1.0 - k / 5.0)
		for g in nf: _ik(c, g, side, corr[g])
