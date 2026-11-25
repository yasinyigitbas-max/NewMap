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
