extends Resource
## One clip, baked for the character's own skeleton: a rotation for every bone on every frame, and the hips' path.
## Made by tools/build_clips.gd from a Mixamo FBX. Sampling is a lookup and a blend between two frames.

@export var fps := 30.0
@export var frames := 0
@export var bones: PackedStringArray = []
@export var rot: PackedFloat32Array = []        # frames * bones * 4 (x, y, z, w), local rotations
@export var hips: PackedVector3Array = []       # the hips in model space, travel included
@export var loop := false
@export var travel := Vector3.ZERO              # hips' ground travel from the first frame to the last
@export var speed := 0.0                        # travel / length, on this character
@export var phase_offset := 0.0                 # loops: seconds into the clip at which the left foot is furthest forward
@export var source := ""
@export var yaw: PackedFloat32Array = []        # how far the hips have turned since the first frame (radians, + = to his left)

var length: float:
	get: return float(frames - 1) / fps


## Local rotation of bone `b` (index into `bones`) at time `t`.
func rotation_at(b: int, t: float) -> Quaternion:
	var f := clampf(t * fps, 0.0, float(frames - 1))
	var i := mini(int(f), frames - 2) if frames > 1 else 0
	var k := f - float(i)
	var n := bones.size()
	var a := (i * n + b) * 4
	var c := ((i + 1) * n + b) * 4 if frames > 1 else a
	return Quaternion(rot[a], rot[a + 1], rot[a + 2], rot[a + 3]).slerp(Quaternion(rot[c], rot[c + 1], rot[c + 2], rot[c + 3]), k)


## The hips at time `t`, with the clip's straight-line travel taken out (what is left is bob and sway).
func hips_at(t: float) -> Vector3:
	var f := clampf(t * fps, 0.0, float(frames - 1))
	var i := mini(int(f), frames - 2) if frames > 1 else 0
	var k := f - float(i)
	var p := hips[i].lerp(hips[mini(i + 1, frames - 1)], k)
	var u := f / float(maxi(frames - 1, 1))
	return Vector3(p.x - hips[0].x - travel.x * u, p.y, p.z - hips[0].z - travel.z * u)


## The hips' travel along the ground up to time `t` (model space), for moves that are driven by the clip.
func travel_at(t: float) -> Vector3:
	var f := clampf(t * fps, 0.0, float(frames - 1))
	var i := mini(int(f), frames - 2) if frames > 1 else 0
	var p := hips[i].lerp(hips[mini(i + 1, frames - 1)], f - float(i))
	return Vector3(p.x - hips[0].x, 0.0, p.z - hips[0].z)


func _at(t: float) -> Vector2:
	var f := clampf(t * fps, 0.0, float(frames - 1))
	var i := mini(int(f), frames - 2) if frames > 1 else 0
	return Vector2(float(i), f - float(i))


## How far the hips have turned by time `t` (radians, + = to his left).
func yaw_at(t: float) -> float:
	if yaw.is_empty():
		return 0.0
	var a := _at(t)
	return lerpf(yaw[int(a.x)], yaw[mini(int(a.x) + 1, frames - 1)], a.y)


## Distance covered along the clip's own line of travel by time `t`.
func dist_at(t: float) -> float:
	var total := travel.length()
	if total < 0.02:
		return 0.0
	return travel_at(t).dot(travel / total)


## The first time at which the clip has covered `d` (for playing a clip by distance, not by the clock).
func time_for_dist(d: float) -> float:
	var total := travel.length()
	if total < 0.02 or frames < 2:
		return 0.0
	var dir := travel / total
	var prev := 0.0
	for i in range(1, frames):
		var here := Vector3(hips[i].x - hips[0].x, 0.0, hips[i].z - hips[0].z).dot(dir)
		if here >= d:
			var k := 1.0 if here - prev < 0.00001 else clampf((d - prev) / (here - prev), 0.0, 1.0)
			return (float(i - 1) + k) / fps
		prev = maxf(prev, here)
	return length


## The first time at which the hips have turned `a` radians (same sign as the clip's own turn).
func time_for_yaw(a: float) -> float:
	if yaw.is_empty() or frames < 2:
		return 0.0
	var sgn := signf(yaw[frames - 1])
	var prev := 0.0
	for i in range(1, frames):
		var here := yaw[i] * sgn
		if here >= a * sgn:
			var k := 1.0 if here - prev < 0.00001 else clampf((a * sgn - prev) / (here - prev), 0.0, 1.0)
			return (float(i - 1) + k) / fps
		prev = maxf(prev, here)
	return length


## The hips at time `t` for a clip played by distance: everything along the line of travel is taken out (the body
## covers that), the sideways sway and the height stay.
func hips_matched_at(t: float) -> Vector3:
	var a := _at(t)
	var i := int(a.x)
	var p := hips[i].lerp(hips[mini(i + 1, frames - 1)], a.y)
	var rel := Vector3(p.x - hips[0].x, 0.0, p.z - hips[0].z)
	var total := travel.length()
	if total >= 0.02:
		var dir := travel / total
		rel -= dir * rel.dot(dir)
	return Vector3(rel.x, p.y, rel.z)


## The same clip as seen in a mirror (left and right swapped). `parents` = each bone's parent, `rest` = each bone's
## rotation in the T-pose in model space, `pair` = each bone's opposite number (itself for the spine and head).
func mirrored(parents: PackedInt32Array, rest: Array[Quaternion], pair: PackedInt32Array) -> Resource:
	var m: Resource = duplicate()
	var n := bones.size()
	var out := PackedFloat32Array()
	out.resize(rot.size())
	var g: Array[Quaternion] = []
	g.resize(n)
	var d: Array[Quaternion] = []
	d.resize(n)
	var g2: Array[Quaternion] = []
	g2.resize(n)
	for f in frames:
		for b in n:
			var o := (f * n + b) * 4
			var q := Quaternion(rot[o], rot[o + 1], rot[o + 2], rot[o + 3])
			g[b] = (g[parents[b]] * q) if parents[b] >= 0 else q
			d[b] = g[b] * rest[b].inverse()
		for b in n:
			var t := d[pair[b]]
			g2[b] = Quaternion(t.x, -t.y, -t.z, t.w) * rest[b]
			var l := ((g2[parents[b]].inverse() * g2[b]) if parents[b] >= 0 else g2[b]).normalized()
			var o := (f * n + b) * 4
			out[o] = l.x
			out[o + 1] = l.y
			out[o + 2] = l.z
			out[o + 3] = l.w
	var h := PackedVector3Array()
	for p in hips:
		h.append(Vector3(-p.x, p.y, p.z))
	var y := PackedFloat32Array()
	for a in yaw:
		y.append(-a)
	m.set(&"rot", out)
	m.set(&"hips", h)
	m.set(&"yaw", y)
	m.set(&"travel", Vector3(-travel.x, 0.0, travel.z))
	m.set(&"source", source + " (mirrored)")
	return m


## The share of a climbing clip's whole rise that its hips have made, frame by frame: never going back down.
## (traverse.gd moves the body by the same curve.)
static func rise_of(hips: PackedVector3Array) -> PackedFloat32Array:
	var out := PackedFloat32Array()
	var n := hips.size()
	var whole := hips[n - 1].y - hips[0].y
	var most := 0.0
	for f in n:
		most = maxf(most, clampf((hips[f].y - hips[0].y) / whole, 0.0, 1.0) if absf(whole) > 0.01 else 0.0)
		out.append(most)
	return out
