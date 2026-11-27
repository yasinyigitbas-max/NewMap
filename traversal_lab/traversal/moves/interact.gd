extends Node
## Moves on things in the world that are not climbed: doors (stage 22), cars (stage 23), and sitting (Yasin, 27 Nov).
## Built as the traversal moves are (the study: "align, play, fit, hand IK, hand back"): the body is carried by the
## take's own travel from a start point set by the thing, the hands are held on it, and it cannot be cancelled.
## Kept apart from traverse.gd so that nothing there changes.

const ClipData := preload("res://traversal/character/clip_data.gd")
const CLIPS := "res://traversal/character/clips/%s.res"
const PALM := 0.08              # the study: "the gripping palm is about 0.08 m further along" than the wrist
const HAND_FADE := 0.15         # NOT in the study: seconds for a hand to come onto, and off, what it holds

# Stage 22, doors. The study: "Passing a push door adds about 2 to 3 s to walking through, a pull door about 4 s";
# "Open Door Outwards takes 4.1 s over 2.21 m ... Opening Door Inwards takes 6.4 s over 1.75 m". Measured in the lab
# on his body: "Outwards" is the PULL side (he draws it to him, steps back and to the side, and goes through);
# "Inwards" is the PUSH side (he pushes it away, goes through, then turns and shuts it behind him).
# Every figure below is read off the takes in the lab, NOT in the study: where the door stands for the take (plane =
# m ahead of where he starts; hinge = m to his right of his line, minus = left), when his hand is on it, and the
# angle the door has reached at those times (so that the leaf goes with his hand).
const DOOR := {
	"pull": {"input": "door_pull", "clip": "Open_Door_Outwards", "plane": 0.70, "hinge": 0.35, "aside": [[1.60, 0.0], [2.60, 0.25], [2.90, 0.25], [3.70, 0.0]], "rate": 1.0, "end": 4.10,
			# (The take was made on a wider door than the study's 0.815 m: his hand comes down 0.68 m from the hinge
			# this door is given, and his own walk through is 0.4 m to the left of that hand. With the hinge 0.06 m to
			# his right, where his walk through the opening is centred, the leaf's free end swept through his knee and
			# shoulders. At 0.35 m his whole body is outside the leaf's sweep; he is then 0.25 m too far left for the
			# opening, and is carried that much toward the hinge as he walks through: `aside`.)
			"hand": 1, "hand_on": 0.50, "hand_off": 1.55, "hand_at": [[0.50, 0.68], [0.90, 0.69], [1.10, 0.74], [1.30, 0.78], [1.50, 0.78]],
			"swing": [[0.70, 0.0], [0.90, 16.0], [1.10, 31.0], [1.30, 41.0], [1.50, 46.0], [1.90, 75.0], [2.30, 95.0]]},
	# (the push take is used as far as he is through, 4.45 s of its 6.37: its turning back to shut the door is left
	# out, the door shuts by itself; and it is played 1.15 times as fast: so it adds 2.8 s to walking the same
	# 1.56 m, inside the study's 2 to 3 s. As it is, whole, it adds 5.2 s.)
	"push": {"input": "door_push", "clip": "Opening_Door_Inwards", "plane": 0.53, "hinge": -0.24, "rate": 1.15, "end": 4.45,
			"hand": 1, "hand_on": 2.45, "hand_off": 3.15, "hand_at": [[2.45, 0.52], [3.15, 0.52]],
			"swing": [[2.45, 0.0], [3.10, 44.0], [3.50, 90.0]]}}
const DOOR_NEAR := 0.25         # NOT in the study, mine: the move begins when he is within this of the take's own start (m)
const DOOR_ASIDE := 0.45        # NOT in the study, mine: and no further than this to either side of its line (m)
const ALIGN_TIME := 0.35        # NOT in the study, mine: seconds over which he is brought onto the take's start

var body: CharacterBody3D
var enabled := true
var plays := 0                  # how many moves have been begun (for the tests)
var last := ""                  # the key of the last one
var _plan := {}
var _along := {}                # clip name -> how far along its own line of travel the take has gone, frame by frame
var _fps := 30.0


func _ready() -> void:
	for key: String in DOOR:
		_load(String(DOOR[key]["clip"]))


func _load(clip: String) -> void:
	var c: Resource = load(CLIPS % clip)
	var hips: PackedVector3Array = c.get(&"hips")
	_fps = float(c.get(&"fps"))
	var net := hips[hips.size() - 1] - hips[0]
	net.y = 0.0
	var dir := net.normalized() if net.length() > 0.02 else Vector3.ZERO
	var t := PackedFloat32Array()
	for f in hips.size():
		var rel := hips[f] - hips[0]
		t.append(Vector3(rel.x, 0.0, rel.z).dot(dir))
	_along[clip] = t


func _at(table: PackedFloat32Array, t: float) -> float:
	var x := clampf(t * _fps, 0.0, table.size() - 1.001)
	var i := int(x)
	return lerpf(table[i], table[i + 1], x - i)


func _physics_process(_dt: float) -> void:
	if body == null or not enabled or bool(body.call(&"in_move")):
		return
	if int(body.get(&"state")) != 0 or bool(body.get(&"crouched")):
		return
	var wish: Vector3 = body.get(&"stick_wish")
	if wish.length() > 0.05:
		_try_door(wish.normalized())


## A value read off a list of [time, value] at `t`, straight between them, held before the first and after the last.
func _keyed(keys: Array, t: float) -> float:
	var out := float((keys[0] as Array)[1])
	for i in keys.size() - 1:
		var a: Array = keys[i]
		var b: Array = keys[i + 1]
		if t >= float(a[0]):
			out = lerpf(float(a[1]), float(b[1]), clampf((t - float(a[0])) / (float(b[0]) - float(a[0])), 0.0, 1.0))
	return out


# ---------------------------------------------------------------------------------------------------------- doors

func _try_door(dir: Vector3) -> bool:
	for door: Node3D in get_tree().get_nodes_in_group(&"tl_door"):
		if float(door.get(&"open_deg")) > 2.0:
			continue
		var hinge := door.global_position
		var out := door.global_transform.basis.z
		out = Vector3(out.x, 0.0, out.z).normalized()
		var rel := body.global_position - hinge
		if absf(rel.y) > 0.1:
			continue
		var front := rel.dot(out) > 0.0
		var p: Dictionary = DOOR["pull" if front else "push"]
		var into := -out if front else out
		if dir.dot(into) < 0.7:
			continue
		var right := into.cross(Vector3.UP).normalized()
		var start := hinge - right * float(p["hinge"]) - into * (float(p["plane"]) + (float(door.get(&"THICK")) * 0.5))
		start.y = body.global_position.y
		var off := body.global_position - start
		# (ahead of the start by no more than he covers in a tick or two; short of it by DOOR_NEAR)
		if off.dot(into) > 0.10 or off.dot(into) < -DOOR_NEAR or absf(off.dot(right)) > DOOR_ASIDE:
			continue
		var table: PackedFloat32Array = _along[String(p["clip"])]
		var end_t := float(p["end"])
		_plan = {"key": "door_pull" if front else "door_push", "p": p, "door": door, "front": front, "from": body.global_position, "start": start,
				"into": into, "yaw0": body.rotation.y, "yaw": atan2(-into.x, -into.z), "table": table,
				"exit_speed": (_at(table, end_t) - _at(table, end_t - 0.2)) / 0.2 * float(p["rate"])}
		plays += 1
		last = String(_plan["key"])
		body.call(&"begin_move", _door, String(p["input"]))
		return true
	return false


func _door(t: float) -> Dictionary:
	var pl := _plan
	var p: Dictionary = pl["p"]
	var ct := t * float(p["rate"])
	var into: Vector3 = pl["into"]
	var pos := (pl["start"] as Vector3) + into * _at(pl["table"], ct)
	if p.has("aside"):
		pos += into.cross(Vector3.UP).normalized() * _keyed(p["aside"], ct)
	pos = (pl["from"] as Vector3).lerp(pos, smoothstep(0.0, ALIGN_TIME, t))
	# the leaf goes with his hand
	var door: Node3D = pl["door"]
	door.set(&"open_deg", _keyed(p["swing"], ct))
	door.set(&"held", true)
	var hold := clampf(minf((ct - float(p["hand_on"])) / HAND_FADE + 1.0, (float(p["hand_off"]) - ct) / HAND_FADE + 1.0), 0.0, 1.0)
	hold = hold * hold * (3.0 - 2.0 * hold)
	var front: bool = pl["front"]
	var at: Vector3 = (door.call(&"bar_at", _keyed(p["hand_at"], ct), front) as Vector3) + (door.call(&"face", front) as Vector3) * (PALM - 0.03)
	var done := ct >= float(p["end"])
	var out := {"done": done, "pos": pos, "clip_t": ct, "air": false, "landed": true,
			"yaw": lerp_angle(float(pl["yaw0"]), float(pl["yaw"]), smoothstep(0.0, ALIGN_TIME, t)),
			"hand": [[int(p["hand"]), at, hold]]}
	if done:
		out["exit"] = into * float(pl["exit_speed"])
	return out
