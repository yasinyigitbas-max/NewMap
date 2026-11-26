extends Node
## Stage 8 onward: the traversal moves. The study: "Each move is built the same way (align, play, fit, hand IK, hand
## back)", and "In a traversal move the roles swap for the length of that move: the clip's root travel, stretched to
## fit the measured obstacle, drives the body, with gravity and normal collision off."
##
## BUILT: Stage 8, stepping off an edge at a walk, for drops of more than 0.30 m and up to 1.0 m (the study, going
## down: "up to 0.30 m, step down in stride; 0.30 to 1.0 m, step or hop off with a soft landing"). Lower edges are
## stepped down in stride by the body as before (Yasin, 26 Nov: "stepping down off a kerb doesnt look that bad now,
## work on bigger edges like knee height and above"). Higher ones are refused here: he falls as before, until the
## hang-and-drop of stage 15.
## NOT BUILT: the study's "plant the last foot about 14 cm back from the edge" for kerbs; at a run he still leaves an
## edge by the body's own fall with the run-off clip.

const Detector := preload("res://traversal/detect/detector.gd")
const BAND := [0.30, 1.0]       # the study's band for this move: more than the first, up to the second (m)
# The clip: a Kimodo take of a man stepping off a ledge (the study's Part 3 has no Mixamo clip that steps off and
# lands standing in under 3 s). Measured on the take's own hip path: he begins the step at 1.45 s, his feet leave at
# 2.10 s, he is down at 2.52 s and standing again by 3.30 s; the ledge it steps off is 1.15 m high.
const STEP_OFF := {"input": "drop_walk", "res": "res://traversal/character/clips/KM_Ledge_Walk_Off.res",
		"from": 1.75, "leaves": 2.10, "down": 2.52, "exit": 3.30,
		"edge": 0.46}           # NOT in the study: where the take's edge is taken to be, along its own path (m):
                                # 5 cm behind his hips at the moment his feet leave (the take has no real ledge)
const LOOK := 0.7               # NOT in the study: the ground this far ahead is looked at every tick; only when it
                                # ends there is the full measurement made
const AGAIN := 6                # ticks between measurements while he comes up to an edge
const MOST_OFF_DEG := 45.0      # NOT in the study: he steps off only when heading this near to straight at the edge
const MEASURED_WITHIN := 0.01   # NOT in the study: a drop is taken as measured to a centimetre (the course's 1.00 m
                                # wall measures 1.0003 m), so the band's edges are held with that much give
const LAND_WITHIN := 0.05       # the landing must be where the record said, within this (m): the stage 7 bar for height

var body: CharacterBody3D
var detector: RefCounted
var record: Dictionary = {}
var refused := ""               # why the last edge met was not taken with the move ("" = it was, or none met)
var plays := 0                  # moves begun (for the tests)
var _tick := 0
var _fwd := PackedFloat32Array()        # the take's own travel forward, frame by frame
var _high := PackedFloat32Array()       # how far above its landing the take is, as a share of its whole drop
var _fps := 30.0
var _plan: Dictionary = {}


func _ready() -> void:
	detector = Detector.new()
	detector.set(&"body", body)
	var c: Resource = load(String(STEP_OFF["res"]))
	var hips: PackedVector3Array = c.get(&"hips")
	_fps = float(c.get(&"fps"))
	var last := hips.size() - 1
	var drop := hips[0].y - hips[last].y
	for f in hips.size():
		_fwd.append(hips[f].z - hips[0].z)
		_high.append(clampf((hips[f].y - hips[last].y) / drop, 0.0, 1.0))


func _at(table: PackedFloat32Array, t: float) -> float:
	var x := clampf(t * _fps, 0.0, table.size() - 1.001)
	var i := int(x)
	return lerpf(table[i], table[i + 1], x - i)


func _physics_process(_dt: float) -> void:
	if body == null or bool(body.call(&"in_move")):
		return
	_tick += 1
	var v: Vector3 = body.get(&"hvel")
	var wish := (body.get(&"_wish") as Vector3).length()
	var walking := int(body.get(&"state")) == 0 and not bool(body.get(&"crouched")) and v.length() > 0.5 \
			and wish > 0.05 and wish <= float(body.get(&"WALK")) + 0.1 and int(body.get(&"stairs")) == 0 and int(body.get(&"terrain")) == 0
	if not walking:
		record = {}
		return
	var dir := v.normalized()
	# the cheap look: does the ground end a little ahead?
	if record.is_empty():
		var ahead: Dictionary = body.call(&"_ray_down", body.global_position + dir * LOOK)
		if not ahead.is_empty() and (ahead["position"] as Vector3).y > body.global_position.y - float(BAND[0]):
			return
	if record.is_empty() or _tick % AGAIN == 0:
		record = detector.call(&"measure", dir)
		if record["kind"] != "drop":
			refused = "" if record["kind"] == "none" else "not a plain drop (%s)" % record["kind"]
			record = {}
			return
	# is it this move's? "it plays on every course obstacle inside its height band and is refused on every obstacle
	# outside it"
	var drop := float(record.get("drop", INF))
	if drop <= float(BAND[0]) + MEASURED_WITHIN:
		refused = "low enough to step down in stride"
		return
	if drop > float(BAND[1]) + MEASURED_WITHIN:
		refused = "too high for a step off (%.2f m)" % drop
		return
	var m: Vector3 = -(record["normal"] as Vector3)
	if rad_to_deg(dir.angle_to(m)) > MOST_OFF_DEG:
		refused = "not heading at the edge"
		return
	# fit: the take's own path, from where it is taken up, laid from here out over the edge
	var from_t := float(STEP_OFF["from"])
	var edge_at := float(STEP_OFF["edge"])
	var to_edge := edge_at - _at(_fwd, from_t)                  # the take's own distance to its edge at that moment
	var here := (record["edge"] as Vector3 - body.global_position).dot(m)
	if here > to_edge:
		return                                                  # not there yet
	var feet := body.global_position
	var top_y := float(record["ground"])        # the ground he stood on, not his feet, which sink a little at an edge
	var land_y := top_y - drop
	var leave := feet + m * (here + _at(_fwd, float(STEP_OFF["leaves"])) - edge_at)
	var down := leave + m * (_at(_fwd, float(STEP_OFF["down"])) - _at(_fwd, float(STEP_OFF["leaves"])))
	var end := down + m * (_at(_fwd, float(STEP_OFF["exit"])) - _at(_fwd, float(STEP_OFF["down"])))
	# the landing: the ground where he comes down and where he ends must be where the record said, with room for him
	for p: Vector3 in [down, end]:
		var g: Dictionary = body.call(&"probe", Vector3(p.x, land_y, p.z))
		if not bool(g["hit"]) or absf(float(g["y"]) - land_y) > LAND_WITHIN:
			refused = "the ground where he would land is not level with the drop measured"
			return
		if not bool(detector.call(&"_fits", Vector3(p.x, land_y, p.z), float(body.get(&"HEIGHT")))):
			refused = "no room to land"
			return
	refused = ""
	var speed_in := maxf(v.length(), 0.8)
	var n := _fwd.size()
	_plan = {"from": feet, "leave": Vector3(leave.x, top_y, leave.z), "down": Vector3(down.x, land_y, down.z), "end": Vector3(end.x, land_y, end.z),
			"m": m, "yaw0": body.rotation.y, "yaw1": atan2(-m.x, -m.z), "drop": drop,
			# align and step: at the pace he came in at. Air: as long as that drop takes to fall. Then the take's own time.
			"t_step": maxf((leave - feet).dot(m), 0.05) / speed_in, "t_air": sqrt(2.0 * drop / float(body.get(&"GRAVITY"))),
			"t_rest": float(STEP_OFF["exit"]) - float(STEP_OFF["down"]),
			"exit_speed": (_fwd[n - 1] - _fwd[n - 7]) / (6.0 / _fps)}
	plays += 1
	record = {}
	body.call(&"begin_move", _step_off, String(STEP_OFF["input"]))


## Where the body is `t` seconds into the step off (called by the body every tick of the move).
func _step_off(t: float) -> Dictionary:
	var p := _plan
	var m: Vector3 = p["m"]
	var t_step := float(p["t_step"])
	var t_air := float(p["t_air"])
	var t_rest := float(p["t_rest"])
	var out := {"done": false, "yaw": lerp_angle(float(p["yaw0"]), float(p["yaw1"]), clampf(t / maxf(t_step, 0.05), 0.0, 1.0))}
	if t < t_step:
		var u := t / t_step
		out["pos"] = (p["from"] as Vector3).lerp(p["leave"], u)
		out["clip_t"] = lerpf(float(STEP_OFF["from"]), float(STEP_OFF["leaves"]), u)
		out["air"] = false
	elif t < t_step + t_air:
		var u := (t - t_step) / t_air
		var ct := lerpf(float(STEP_OFF["leaves"]), float(STEP_OFF["down"]), u)
		# forward by the take's own travel through its fall; down by the take's own fall, scaled to this drop
		var f0 := _at(_fwd, float(STEP_OFF["leaves"]))
		var f1 := _at(_fwd, float(STEP_OFF["down"]))
		var along := (_at(_fwd, ct) - f0) / maxf(f1 - f0, 0.001)
		var pos := (p["leave"] as Vector3).lerp(p["down"], along)
		var h0 := _at(_high, float(STEP_OFF["leaves"]))
		var h1 := _at(_high, float(STEP_OFF["down"]))
		pos.y = (p["down"] as Vector3).y + float(p["drop"]) * clampf((_at(_high, ct) - h1) / maxf(h0 - h1, 0.001), 0.0, 1.0)
		out["pos"] = pos
		out["clip_t"] = ct
		out["air"] = true
	else:
		var u := clampf((t - t_step - t_air) / t_rest, 0.0, 1.0)
		var ct := lerpf(float(STEP_OFF["down"]), float(STEP_OFF["exit"]), u)
		var f0 := _at(_fwd, float(STEP_OFF["down"]))
		var f1 := _at(_fwd, float(STEP_OFF["exit"]))
		out["pos"] = (p["down"] as Vector3).lerp(p["end"], (_at(_fwd, ct) - f0) / maxf(f1 - f0, 0.001))
		out["clip_t"] = ct
		out["air"] = false
		out["landed"] = true
		if u >= 1.0:
			out["done"] = true
			out["exit"] = m * float(p["exit_speed"])
	return out
