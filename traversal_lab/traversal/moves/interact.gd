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
# Sitting (Yasin, 27 Nov: "stand to sit, walk to sit, sitting idle, sit to stand ... sit to type"). The study has no
# section on sitting; of real seats it gives "Bench seat | 0.43 to 0.485 m". The takes (measured): Stand To Sit goes
# 0.45 m back and down to hips at 0.55 m; Sit To Stand comes 0.47 m forward. At a desk he sits down onto the seat
# from its side, turns on it to the desk, and puts his hands to the keys (Type To Sit, played backward); T takes his
# hands off the keys and puts them back. Every figure here is mine or read off the takes.
const SIT := {"down": {"input": "sit_down", "clip": "Stand_To_Sit"}, "idle": {"input": "sit_idle", "clip": "Sitting_Idle"},
		"up": {"input": "sit_up", "clip": "Sit_To_Stand"}, "type": {"input": "sit_type", "clip": "Typing"},
		"hands": {"input": "type_to_sit", "clip": "Type_To_Sit"}}
const SIT_REACH := 2.5          # the act key takes him to a seat whose standing place is within this (m)
const SIT_AT := 0.12            # he is at that place when within this of it (m)
const SIT_WALK_MOST := 6.0      # seconds he is walked toward it before it is given up
const TURN_TIME := 0.8          # seconds for half a turn on the spot before he sits (his standing turn: no steps)
const SWIVEL_TIME := 0.7        # seconds to turn on the seat to the desk, or away from it
const UP_HOLD := 0.25           # seconds the stick is held before it is taken as "get up"
# Stage 23, cars. The study: "`Entering Car` (5.47 s) walks 1.9 m, turns 97 degrees and sits ... `Exiting Car` (5.8 s) is
# the reverse. There is no bonnet slide." (and: "Cars come last because the human data for getting in and out could
# not be sourced, so that stage will rest on clip measurement alone"). The act key by the driver's door: he is walked
# to where the take starts, turned to it, and the take is played: he opens the door, gets in, shuts it, and sits with
# his hands on the wheel until the act key again; then the other take: out, the door shut behind him.
# The door's angle at each time is read off the takes' left hand in the lab, NOT in the study.
const CAR := {"in": {"input": "car_in", "clip": "Entering_Car", "door": [[0.90, 0.0], [1.40, 31.0], [1.70, 48.0], [3.20, 48.0], [3.50, 23.0], [4.10, 0.0]]},
		"out": {"input": "car_out", "clip": "Exiting_Car", "door": [[0.60, 0.0], [1.50, 85.0], [3.90, 85.0], [4.40, 0.0]]}}
const CAR_REACH := 2.5          # NOT in the study, mine: the act key takes him to a car whose take starts within this (m)
# Stage 21, cover: "cover: low and high, enter, peek, exit | low 0.8 to 1.1 m, high above head". The study: "look and
# fire around the side of cover, not over the top; stay 30 to 46 cm or an arm's length off the wall; come out lower
# than expected ...; keep exposure between positions to 3 to 5 seconds"; and of the takes: "in crouch cover the head
# is at 1.28 m, so behind the 0.8 to 1.1 m low cover the head shows by 0.2 m or more. Low cover for these clips needs
# to be about 1.3 m, or the pose lowered".
# The act key facing a wall 0.8 m high or more, within reach: he takes cover against it, his back to it. A wall he
# can be seen over standing (under COVER_HIGH) is low cover, crouched; a higher one is high cover, standing.
# In cover: the stick along the wall side-steps him along it; held on at the wall's end, he looks round it (never
# over it); the act key, or the stick held out from the wall, brings him out.
const COVER := {
	"low": {"in": "Stand_To_Cover", "in_key": "cover_in", "in_back": false, "idle": "cover_idle_low", "idle_clip": "Crouch_Cover_Idle",
			"out": "Cover_To_Stand", "out_key": "cover_out", "peek": "Crouch_Look_Around_Corner", "peek_key": "cover_peek", "peek_to": 1.0,
			"head": 1.33, "head_side": 1.68},
	# (no take of his goes from standing into standing cover: the take out of it is played backward)
	"high": {"in": "Cover_To_Stand_High", "in_key": "cover_out_high", "in_back": true, "idle": "cover_idle", "idle_clip": "Cover_Idle",
			"out": "Cover_To_Stand_High", "out_key": "cover_out_high", "peek": "Standing_Cover_Turn", "peek_key": "cover_peek_high", "peek_to": -1.0,
			"head": 1.66, "head_side": 1.68}}
const COVER_AIM := {"Stand_To_Cover": 47.0, "Cover_To_Stand_High": 180.0}      # as tools/build_library.gd AIM_DEG turns these takes
const COVER_LOW := 0.80         # the study's lowest cover
const COVER_HIGH := 1.85        # "high above head": he is 1.80 m tall
const COVER_OFF := 0.30         # the study's "stay 30 to 46 cm ... off the wall": his hips this far out from it
const COVER_REACH := 2.0        # NOT in the study, mine: a wall this near in front of him is taken cover against (m)
const COVER_PACE := 1.16        # the side-step takes' own pace on his body (m/s; the study: "1.34 m per loop at 1.18 m/s" on X Bot)
const COVER_SIDE_LEN := 1.1333  # their length (s)
const COVER_DROP_MOST := 0.25   # NOT in the study, mine: the most his hips are brought down to keep his head under the top (m)
const COVER_HEAD_ROOM := 0.03   # NOT in the study, mine: his head is kept this far under the top (m)
const PEEK_AFTER := 0.3         # NOT in the study, mine: seconds the stick is held on at the wall's end before he looks round it
const PEEK_HOLD := 1.0          # NOT in the study, mine: seconds he stays out round the end of high cover (out 1 s, back 1 s: 3 s
                                # of exposure in all, the study's "3 to 5 seconds"; the low take is 3.0 s long by itself)
const ALIGN_TIME := 0.35        # NOT in the study, mine: seconds over which he is brought onto the take's start

var body: CharacterBody3D
var enabled := true
var plays := 0                  # how many moves have been begun (for the tests)
var last := ""                  # the key of the last one
var _plan := {}
var _along := {}                # clip name -> how far along its own line of travel the take has gone, frame by frame
var _fps := 30.0
var _len := {}                  # clip name -> its length (s)
var _yaw := {}                  # clip name -> the take's own turning, frame by frame (radians, + = to his left)
var _dir := {}                  # clip name -> the line the take travels along, in its own frame (x = to his left, z = ahead)
var _to_car: Node3D             # the car he is being walked to
var in_car := false             # he is in a car (for the tests)
var _to_cover := {}              # the cover he is being walked to (a plan), or empty
var in_cover := ""              # "" , "low" or "high": he is in cover (for the tests)
var cover_phase := ""
var _to_seat: Node3D            # the seat he is being walked to
var _walked := 0.0
var seated := false             # he is on a seat (for the tests and the readout)
var sit_phase := ""


func _ready() -> void:
	for key: String in DOOR:
		_load(String(DOOR[key]["clip"]))
	for key: String in SIT:
		_load(String(SIT[key]["clip"]))
	for key: String in CAR:
		_load(String(CAR[key]["clip"]))
	for kind: String in COVER:
		for part: String in ["in", "out", "peek", "idle_clip"]:
			_load(String(COVER[kind][part]))


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
	# (the line in the frame the take is baked in: some cover takes are turned at the bake)
	_dir[clip] = dir.rotated(Vector3.UP, deg_to_rad(float(COVER_AIM[clip]))) if COVER_AIM.has(clip) else dir
	_yaw[clip] = c.get(&"yaw")
	_len[clip] = float(hips.size() - 1) / _fps


func _at(table: PackedFloat32Array, t: float) -> float:
	var x := clampf(t * _fps, 0.0, table.size() - 1.001)
	var i := int(x)
	return lerpf(table[i], table[i + 1], x - i)


func _physics_process(_dt: float) -> void:
	if body == null or not enabled or bool(body.call(&"in_move")):
		return
	if int(body.get(&"state")) != 0 or bool(body.get(&"crouched")):
		return
	if _to_seat != null:
		_walk_to_seat(_dt)
		return
	if _to_car != null:
		_walk_to_car(_dt)
		return
	if not _to_cover.is_empty():
		_walk_to_cover(_dt)
		return
	if bool(body.get(&"act_now")) and (_try_seat() or _try_car() or _try_cover()):
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


# -------------------------------------------------------------------------------------------------------- sitting

## The way he faces as he sits down onto a seat, and where he stands to do it.
func _seat_side(seat: Node3D) -> Vector3:
	var f: Vector3 = seat.get_meta(&"side") if bool(seat.get_meta(&"desk")) else seat.global_transform.basis.z
	return Vector3(f.x, 0.0, f.z).normalized()


func _seat_stand(seat: Node3D) -> Vector3:
	var back := _at(_along[String(SIT["down"]["clip"])], 99.0)
	return seat.global_position + _seat_side(seat) * back


## The act key: the nearest free seat he can be walked to.
func _try_seat() -> bool:
	var best: Node3D = null
	var best_d := SIT_REACH
	for seat: Node3D in get_tree().get_nodes_in_group(&"tl_seat"):
		var d := body.global_position.distance_to(_seat_stand(seat))
		if d < best_d and absf(seat.global_position.y - body.global_position.y) < 0.1:
			best = seat
			best_d = d
	if best == null:
		return false
	_to_seat = best
	_walked = 0.0
	return true


## "Walk to sit": he is walked to the seat's standing place; any push of the stick gives it up.
func _walk_to_seat(dt: float) -> void:
	_walked += dt
	var stand := _seat_stand(_to_seat)
	var off := stand - body.global_position
	off.y = 0.0
	if (bool(body.get(&"stick_held")) and _walked > 0.2) or _walked > SIT_WALK_MOST:
		body.set(&"auto_on", false)
		_to_seat = null
		return
	if off.length() > SIT_AT:
		body.set(&"auto_on", true)
		body.set(&"auto_to", stand)
		return
	body.set(&"auto_on", false)
	var seat := _to_seat
	_to_seat = null
	var side := _seat_side(seat)
	var face := seat.global_transform.basis.z
	face = Vector3(face.x, 0.0, face.z).normalized()
	var yaw_side := atan2(-side.x, -side.z)
	var turn := absf(wrapf(yaw_side - body.rotation.y, -PI, PI))
	_plan = {"key": "sit", "seat": seat, "at": seat.global_position, "stand": stand, "side": side, "desk": bool(seat.get_meta(&"desk")),
			"from": body.global_position, "yaw0": body.rotation.y, "yaw_side": yaw_side, "yaw_face": atan2(-face.x, -face.z),
			"turn_time": maxf(TURN_TIME * turn / PI, ALIGN_TIME), "phase": "turn", "t0": 0.0, "held": 0.0, "last_t": 0.0}
	plays += 1
	last = "sit"
	seated = true
	body.call(&"begin_move", _sit, String(SIT["down"]["input"]))


func _sit(t: float) -> Dictionary:
	var pl := _plan
	var dt := t - float(pl["last_t"])
	pl["last_t"] = t
	var ph := String(pl["phase"])
	var tau := t - float(pl["t0"])
	var at: Vector3 = pl["at"]
	var side: Vector3 = pl["side"]
	var desk: bool = pl["desk"]
	var out := {"done": false, "pos": at, "yaw": float(pl["yaw_face"]) if desk else float(pl["yaw_side"]), "clip": "sit_idle", "clip_t": 0.0, "air": false, "landed": true}
	var next := ""
	# getting up is asked for with the act key, or by holding the stick
	pl["held"] = float(pl["held"]) + dt if bool(body.get(&"stick_held")) else 0.0
	var up_asked := bool(body.get(&"act_now")) or float(pl["held"]) >= UP_HOLD
	match ph:
		"turn":
			var u := smoothstep(0.0, float(pl["turn_time"]), tau)
			out["pos"] = (pl["from"] as Vector3).lerp(pl["stand"], u)
			out["yaw"] = lerp_angle(float(pl["yaw0"]), float(pl["yaw_side"]), u)
			out["clip"] = "sit_down"
			if tau >= float(pl["turn_time"]):
				next = "down"
		"down":
			var clip := String(SIT["down"]["clip"])
			out["pos"] = (pl["stand"] as Vector3) - side * _at(_along[clip], tau)
			out["yaw"] = float(pl["yaw_side"])
			out["clip"] = "sit_down"
			out["clip_t"] = minf(tau, float(_len[clip]))
			if tau >= float(_len[clip]):
				next = "swivel_in" if desk else "idle"
		"idle":
			out["clip_t"] = fposmod(tau, float(_len[String(SIT["idle"]["clip"])]))
			if up_asked and tau > 0.3:
				next = "swivel_out" if desk else "up"
			elif desk and int(body.get(&"phone")) == 1:
				# (at the desk the text key is "hands to the keys", not the phone)
				body.set(&"phone", 0)
				next = "hands_on"
		"swivel_in", "swivel_out":
			var u2 := smoothstep(0.0, SWIVEL_TIME, tau)
			out["yaw"] = lerp_angle(float(pl["yaw_side"]), float(pl["yaw_face"]), u2 if ph == "swivel_in" else 1.0 - u2)
			if tau >= SWIVEL_TIME:
				next = "hands_on" if ph == "swivel_in" else "up"
		"hands_on", "hands_off":
			var hl := float(_len[String(SIT["hands"]["clip"])])
			out["clip"] = "type_to_sit"
			out["clip_t"] = clampf(hl - tau if ph == "hands_on" else tau, 0.0, hl)
			if tau >= hl:
				next = "type" if ph == "hands_on" else ("swivel_out" if bool(pl.get("leaving", false)) else "idle")
		"type":
			out["clip"] = "sit_type"
			out["clip_t"] = fposmod(tau, float(_len[String(SIT["type"]["clip"])]))
			if int(body.get(&"phone")) != 0:
				body.set(&"phone", 0)
				pl["leaving"] = false
				next = "hands_off"
			elif up_asked and tau > 0.3:
				pl["leaving"] = true
				next = "hands_off"
		"up":
			var clip2 := String(SIT["up"]["clip"])
			out["pos"] = at + side * _at(_along[clip2], tau)
			out["yaw"] = float(pl["yaw_side"])
			out["clip"] = "sit_up"
			out["clip_t"] = minf(tau, float(_len[clip2]))
			if tau >= float(_len[clip2]):
				out["done"] = true
				out["exit"] = Vector3.ZERO
				seated = false
	if next != "":
		pl["phase"] = next
		pl["t0"] = t
	sit_phase = String(pl["phase"]) if not bool(out["done"]) else ""
	return out


# ----------------------------------------------------------------------------------------------------------- cars

## Where a take that turns as it travels has got to at `t`: [how far along its own line, how far it has turned].
func _travel(clip: String, t: float) -> Array:
	var yaw: PackedFloat32Array = _yaw[clip]
	var x := clampf(t * _fps, 0.0, yaw.size() - 1.001)
	var i := int(x)
	return [_at(_along[clip], t), lerpf(yaw[i], yaw[i + 1], x - i)]


## The line a take travels along, in the world, for a man who starts it facing `fwd`.
func _line(clip: String, fwd: Vector3) -> Vector3:
	var d: Vector3 = _dir[clip]
	var right := fwd.cross(Vector3.UP).normalized()
	return (fwd * d.z - right * d.x).normalized()


## Where the getting-in take starts for a car, and the way he faces there: so that it ends on the car's seat, facing
## the way the car points.
func _car_start(car: Node3D) -> Array:
	var clip := String(CAR["in"]["clip"])
	var ahead := -car.global_transform.basis.z
	ahead = Vector3(ahead.x, 0.0, ahead.z).normalized()
	var whole: Array = _travel(clip, 99.0)
	var fwd := ahead.rotated(Vector3.UP, -float(whole[1]))
	return [car.global_position - _line(clip, fwd) * float(whole[0]), fwd]


func _try_car() -> bool:
	for car: Node3D in get_tree().get_nodes_in_group(&"tl_car"):
		var start: Vector3 = _car_start(car)[0]
		if body.global_position.distance_to(start) < CAR_REACH and absf(start.y - body.global_position.y) < 0.1:
			_to_car = car
			_walked = 0.0
			return true
	return false


func _walk_to_car(dt: float) -> void:
	_walked += dt
	var st: Array = _car_start(_to_car)
	var start: Vector3 = st[0]
	var off := start - body.global_position
	off.y = 0.0
	if (bool(body.get(&"stick_held")) and _walked > 0.2) or _walked > SIT_WALK_MOST:
		body.set(&"auto_on", false)
		_to_car = null
		return
	if off.length() > SIT_AT:
		body.set(&"auto_on", true)
		body.set(&"auto_to", start)
		return
	body.set(&"auto_on", false)
	var car := _to_car
	_to_car = null
	var fwd: Vector3 = st[1]
	var yaw_in := atan2(-fwd.x, -fwd.z)
	var ahead := -car.global_transform.basis.z
	ahead = Vector3(ahead.x, 0.0, ahead.z).normalized()
	var turn := absf(wrapf(yaw_in - body.rotation.y, -PI, PI))
	_plan = {"key": "car", "car": car, "start": start, "fwd": fwd, "ahead": ahead, "from": body.global_position, "yaw0": body.rotation.y,
			"yaw_in": yaw_in, "yaw_seat": atan2(-ahead.x, -ahead.z), "turn_time": maxf(TURN_TIME * turn / PI, ALIGN_TIME), "phase": "turn", "t0": 0.0}
	plays += 1
	last = "car"
	body.call(&"begin_move", _car, String(CAR["in"]["input"]))


func _car(t: float) -> Dictionary:
	var pl := _plan
	var ph := String(pl["phase"])
	var tau := t - float(pl["t0"])
	var car: Node3D = pl["car"]
	var seat := car.global_position
	var c_in := String(CAR["in"]["clip"])
	var c_out := String(CAR["out"]["clip"])
	var out := {"done": false, "pos": seat, "yaw": float(pl["yaw_seat"]), "clip": "car_in", "clip_t": float(_len[c_in]), "air": false, "free": true}
	var next := ""
	match ph:
		"turn":
			var u := smoothstep(0.0, float(pl["turn_time"]), tau)
			out["pos"] = (pl["from"] as Vector3).lerp(pl["start"], u)
			out["yaw"] = lerp_angle(float(pl["yaw0"]), float(pl["yaw_in"]), u)
			out["clip_t"] = 0.0
			out["free"] = false
			out["landed"] = true
			if tau >= float(pl["turn_time"]):
				next = "in"
		"in":
			var tr: Array = _travel(c_in, tau)
			out["pos"] = (pl["start"] as Vector3) + _line(c_in, pl["fwd"]) * float(tr[0])
			out["yaw"] = float(pl["yaw_in"]) + float(tr[1])
			out["clip_t"] = minf(tau, float(_len[c_in]))
			car.set(&"door_deg", _keyed(CAR["in"]["door"], tau))
			car.set(&"held", true)
			if tau >= float(_len[c_in]):
				next = "seated"
				in_car = true
		"seated":
			if bool(body.get(&"act_now")) and tau > 0.3:
				next = "out"
		"out":
			var tr2: Array = _travel(c_out, tau)
			out["pos"] = seat + _line(c_out, pl["ahead"]) * float(tr2[0])
			out["yaw"] = float(pl["yaw_seat"]) + float(tr2[1])
			out["clip"] = "car_out"
			out["clip_t"] = minf(tau, float(_len[c_out]))
			car.set(&"door_deg", _keyed(CAR["out"]["door"], tau))
			car.set(&"held", true)
			in_car = false
			if tau >= float(_len[c_out]):
				out["done"] = true
				out["exit"] = Vector3.ZERO
	if next != "":
		pl["phase"] = next
		pl["t0"] = t
	return out


# ---------------------------------------------------------------------------------------------------------- cover

func _ray(from: Vector3, to: Vector3) -> Dictionary:
	return body.get_world_3d().direct_space_state.intersect_ray(PhysicsRayQueryParameters3D.create(from, to, body.collision_mask, [body.get_rid()]))


## Is there a wall to take cover against behind the spot `at` (a point on the ground, COVER_OFF out from it), whose
## outward facing is `n`? Returns its height above the ground there, or 0.
func _cover_wall(at: Vector3, n: Vector3) -> float:
	var hit := _ray(at + Vector3(0.0, 0.5, 0.0), at + Vector3(0.0, 0.5, 0.0) - n * (COVER_OFF + 0.25))
	if hit.is_empty() or (hit["normal"] as Vector3).dot(n) < 0.9:
		return 0.0
	var inside: Vector3 = (hit["position"] as Vector3) - n * 0.05
	var top := _ray(Vector3(inside.x, at.y + 3.5, inside.z), Vector3(inside.x, at.y + 0.3, inside.z))
	return ((top["position"] as Vector3).y - at.y) if not top.is_empty() else 3.5


## May he side-step on from `at` the way `way` (a unit vector along the wall)? The wall goes on COVER_END further than
## a step from here, and nothing stands in his way.
const COVER_END := 0.22         # NOT in the study, mine: he stops with his hips this far inside the end of the wall (m)
func _cover_on(at: Vector3, way: Vector3, n: Vector3) -> bool:
	return _cover_wall(at + way * (COVER_END + 0.03), n) >= COVER_LOW - 0.02 \
			and _ray(at + Vector3(0.0, 0.6, 0.0), at + Vector3(0.0, 0.6, 0.0) + way * 0.5).is_empty()


## The act key, facing a wall: where he would be in cover against it, and what kind of cover it is.
func _try_cover() -> bool:
	var face := -body.global_transform.basis.z
	face = Vector3(face.x, 0.0, face.z).normalized()
	var feet := body.global_position
	var hit := _ray(feet + Vector3(0.0, 0.5, 0.0), feet + Vector3(0.0, 0.5, 0.0) + face * COVER_REACH)
	if hit.is_empty():
		return false
	var n: Vector3 = hit["normal"]
	n = Vector3(n.x, 0.0, n.z)
	if n.length() < 0.9 or n.normalized().dot(face) > -0.7:
		return false
	n = n.normalized()
	var at := Vector3((hit["position"] as Vector3).x, feet.y, (hit["position"] as Vector3).z) + n * COVER_OFF
	var high := _cover_wall(at, n)
	if high < COVER_LOW - 0.02:
		return false
	var kind := "high" if high >= COVER_HIGH else "low"
	var c: Dictionary = COVER[kind]
	var clip := String(c["in"])
	# where the take into cover starts, and the way his body is turned there (the take's own frame: see AIM_DEG)
	var yaw_n := atan2(-n.x, -n.z)
	var whole: Array = _travel(clip, 99.0)
	var start: Vector3
	var yaw_start: float
	if bool(c["in_back"]):
		# (the take out of cover, backward: it starts where that take ends)
		start = at + _line(clip, n) * float(whole[0])
		yaw_start = yaw_n + float(whole[1])
	else:
		yaw_start = yaw_n - float(whole[1])
		var fwd0 := Vector3(-sin(yaw_start), 0.0, -cos(yaw_start))
		start = at - _line(clip, fwd0) * float(whole[0])
	if _ray(start + Vector3(0.0, 1.0, 0.0), start + Vector3(0.0, -0.3, 0.0)).is_empty():
		return false
	_to_cover = {"key": "cover", "kind": kind, "c": c, "at": at, "n": n, "high": high, "yaw_n": yaw_n, "start": start, "yaw_start": yaw_start}
	_walked = 0.0
	return true


func _walk_to_cover(dt: float) -> void:
	_walked += dt
	var start: Vector3 = _to_cover["start"]
	var off := start - body.global_position
	off.y = 0.0
	if (bool(body.get(&"stick_held")) and _walked > 0.2) or _walked > SIT_WALK_MOST:
		body.set(&"auto_on", false)
		_to_cover = {}
		return
	if off.length() > SIT_AT:
		body.set(&"auto_on", true)
		body.set(&"auto_to", start)
		return
	body.set(&"auto_on", false)
	_plan = _to_cover
	_to_cover = {}
	var turn := absf(wrapf(float(_plan["yaw_start"]) - body.rotation.y, -PI, PI))
	_plan.merge({"from": body.global_position, "yaw0": body.rotation.y, "turn_time": maxf(TURN_TIME * turn / PI, ALIGN_TIME), "phase": "turn", "t0": 0.0,
			"last_t": 0.0, "pos": _plan["at"], "side_t": 0.0, "pushed": 0.0, "away": 0.0, "peek_side": 1.0})
	plays += 1
	last = "cover_" + String(_plan["kind"])
	body.call(&"begin_move", _cover, String(_plan["c"]["in_key"]))


## How far his hips are brought down so that a head `head` m up is under the top of a wall `high` m high.
func _drop_for(head: float, high: float) -> float:
	return clampf(head - (high - COVER_HEAD_ROOM), 0.0, COVER_DROP_MOST)


func _cover(t: float) -> Dictionary:
	var pl := _plan
	var c: Dictionary = pl["c"]
	var dt := t - float(pl["last_t"])
	pl["last_t"] = t
	var ph := String(pl["phase"])
	var tau := t - float(pl["t0"])
	var n: Vector3 = pl["n"]
	var left := Vector3.UP.cross(n).normalized()            # his own left as he stands with his back to the wall
	var at: Vector3 = pl["pos"]
	var yaw_n := float(pl["yaw_n"])
	var kind := String(pl["kind"])
	var out := {"done": false, "pos": at, "yaw": yaw_n, "clip": String(c["idle"]), "clip_t": 0.0, "air": false, "landed": true}
	var next := ""
	var drop := 0.0
	# the stick, in the wall's own frame: along it to his left (+) or right (-), and out from it
	var stick: Vector3 = body.get(&"stick_dir")
	var along := stick.dot(left)
	var outward := stick.dot(n)
	pl["away"] = float(pl["away"]) + dt if outward > 0.6 else 0.0
	var out_asked := bool(body.get(&"act_now")) or float(pl["away"]) >= UP_HOLD
	match ph:
		"turn":
			var u := smoothstep(0.0, float(pl["turn_time"]), tau)
			out["pos"] = (pl["from"] as Vector3).lerp(pl["start"], u)
			out["yaw"] = lerp_angle(float(pl["yaw0"]), float(pl["yaw_start"]), u)
			out["clip"] = String(c["in_key"])
			out["clip_t"] = float(_len[String(c["in"])]) if bool(c["in_back"]) else 0.0
			if tau >= float(pl["turn_time"]):
				next = "in"
		"in":
			var clip := String(c["in"])
			var l := float(_len[clip])
			var ct := clampf(l - tau if bool(c["in_back"]) else tau, 0.0, l)
			var tr: Array = _travel(clip, ct)
			if bool(c["in_back"]):
				out["pos"] = (pl["at"] as Vector3) + _line(clip, n) * float(tr[0])
				out["yaw"] = yaw_n + float(tr[1])
			else:
				var fwd0 := Vector3(-sin(float(pl["yaw_start"])), 0.0, -cos(float(pl["yaw_start"])))
				out["pos"] = (pl["start"] as Vector3) + _line(clip, fwd0) * float(tr[0])
				out["yaw"] = float(pl["yaw_start"]) + float(tr[1])
			out["clip"] = String(c["in_key"])
			out["clip_t"] = ct
			drop = _drop_for(float(c["head"]), float(pl["high"])) * smoothstep(0.0, l, tau)
			if tau >= l:
				next = "idle"
				in_cover = kind
		"idle":
			out["clip_t"] = fposmod(tau, float(_len[String(c["idle_clip"])]))
			drop = _drop_for(float(c["head"]), float(pl["high"]))
			if out_asked and tau > 0.3:
				next = "out"
			elif absf(along) > 0.5:
				var way := signf(along)
				if _cover_on(at, left * way, n):
					pl["side"] = way
					pl["pushed"] = 0.0
					next = "side"
				else:
					# at the wall's end: held on, he looks round it
					pl["pushed"] = float(pl["pushed"]) + dt
					if float(pl["pushed"]) >= PEEK_AFTER and _cover_wall(at + left * (way * 0.6), n) < COVER_LOW - 0.02:
						pl["peek_side"] = way
						next = "peek"
			else:
				pl["pushed"] = 0.0
		"side":
			var way2 := float(pl["side"])
			pl["side_t"] = fposmod(float(pl["side_t"]) + dt, COVER_SIDE_LEN)
			out["clip"] = "cover_left" if way2 > 0.0 else "cover_right"
			out["clip_t"] = float(pl["side_t"])
			drop = _drop_for(float(c["head_side"]), float(pl["high"])) if kind == "low" else 0.0
			var step := left * (way2 * COVER_PACE * dt)
			var on := signf(along) == way2 and absf(along) > 0.5
			if on and _cover_on(at, left * way2, n):
				at += step
				pl["pos"] = at
				out["pos"] = at
				pl["high"] = _cover_wall(at, n)
			else:
				next = "idle"
		"peek":
			# round the end of the wall on the side the stick was held: the low take looks to his left, the high one
			# steps out to his right; their mirrors do the other
			var clip2 := String(c["peek"])
			var l2 := float(_len[clip2])
			var mirrored := signf(float(pl["peek_side"])) != float(c["peek_to"])
			out["clip"] = String(c["peek_key"]) + ("_m" if mirrored else "")
			drop = _drop_for(float(c["head"]), float(pl["high"]))
			if kind == "low":
				out["clip_t"] = minf(tau, l2)
				if tau >= l2:
					next = "idle"
			else:
				# out, a hold, and back the way he came
				var ct2 := clampf(tau, 0.0, l2) if tau < l2 + PEEK_HOLD else clampf(2.0 * l2 + PEEK_HOLD - tau, 0.0, l2)
				var tr2: Array = _travel(clip2, ct2)
				var m := -1.0 if mirrored else 1.0
				var d2: Vector3 = _dir[clip2]
				out["pos"] = at + (n * d2.z - left * (-d2.x) * m).normalized() * float(tr2[0]) if float(tr2[0]) > 0.0 else at
				out["yaw"] = yaw_n + float(tr2[1]) * m
				out["clip_t"] = ct2
				if tau >= 2.0 * l2 + PEEK_HOLD:
					next = "idle"
		"out":
			var clip3 := String(c["out"])
			var l3 := float(_len[clip3])
			var tr3: Array = _travel(clip3, minf(tau, l3))
			out["pos"] = at + _line(clip3, n) * float(tr3[0])
			out["yaw"] = yaw_n + float(tr3[1])
			out["clip"] = String(c["out_key"])
			out["clip_t"] = minf(tau, l3)
			drop = _drop_for(float(c["head"]), float(pl["high"])) * (1.0 - smoothstep(0.0, l3 * 0.5, tau))
			in_cover = ""
			if tau >= l3:
				out["done"] = true
				out["exit"] = Vector3.ZERO
	body.set(&"cover_drop", drop)
	if next != "":
		pl["phase"] = next
		pl["t0"] = t
	cover_phase = String(pl["phase"]) if not bool(out["done"]) else ""
	return out
