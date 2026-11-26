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
## At a run the same, with the Kimodo take of a man running off a ledge and running on (Yasin, 26 Nov: "only walking
## off an edge works well, running off doesnt").
## NOT BUILT: the study's "plant the last foot about 14 cm back from the edge" for kerbs.

const Detector := preload("res://traversal/detect/detector.gd")
const BAND := [0.30, 1.0]       # the study's band for this move: more than the first, up to the second (m)
# The clip: a Kimodo take of a man stepping off a ledge (the study's Part 3 has no Mixamo clip that steps off and
# lands standing in under 3 s). Measured on the take's own hip path: he begins the step at 1.45 s, his feet leave at
# 2.10 s, he is down at 2.52 s and standing again by 3.30 s; the ledge it steps off is 1.15 m high.
const MOVES := {
	"walk": {"input": "drop_walk", "res": "res://traversal/character/clips/KM_Ledge_Walk_Off.res",
		"from": 1.75, "leaves": 2.10, "down": 2.52, "exit": 3.30, "native": 1.15,
		"edge": 0.46},          # NOT in the study: where the take's edge is taken to be, along its own path (m):
                                # 5 cm behind his hips at the moment his feet leave (the take has no real ledge)
	# The run-off take, measured the same way: he is running by 1.70 s, his feet leave at 1.95 s, he is down at
	# 2.72 s and running on, upright again, by 3.70 s; its ledge is 1.76 m high.
	"run": {"input": "drop_run", "res": "res://traversal/character/clips/KM_Ledge_Run_Off.res",
		"from": 1.70, "leaves": 1.95, "down": 2.72, "exit": 3.70, "native": 1.76,
		"edge": 0.95},
	# Off a higher edge at a run: he lands, rolls forward and comes up running (Yasin, 26 Nov: "we need a hard landing
	# exit animation I think, or roll off after hard landing and continue running"). The study: "From 0.75 m a roll
	# cut the peak from 5.2 to 2.9 body weights", and for going down, "a roll for a running jump". No roll was in
	# the library (the study's "falling to roll" is in a Mixamo pack that was never downloaded for him); this is a
	# Kimodo take of 26 Nov, the one of seven that rolls: off a 1.19 m ledge, feet leave at 1.20 s, down at 1.57 s,
	# over his shoulder and up again by 2.93 s, 3.6 m further on.
	"roll": {"input": "drop_roll", "res": "res://traversal/character/clips/KM_Land_Roll.res",
		"from": 1.12, "leaves": 1.20, "down": 1.57, "exit": 2.93, "native": 1.19,
		"edge": 0.96, "landing": "heavy",
		"free": [1.68, 2.60]}}  # between these moments of the take he is rolling: the feet are not fitted to the ground
const ROLL_MOST := 3.0          # the study: "2.0 to 3.0 m, hang and drop preferred, with a roll for a running jump; above
                                # that, expect damage"
const REST_LEAST := 0.6         # NOT in the study: off the lowest edge he is standing again in this share of the take's time
const RUN_FROM := 2.5           # faster than this, and asked to run, it is the run-off (as character.gd, RUN_FROM)
const LOOK_TIME := 0.3          # NOT in the study: ... or as far as he goes in this many seconds, if that is further
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
var _fwd := {}                  # move -> the take's own travel forward, frame by frame
var _high := {}                 # move -> how far above its landing the take is, as a share of its whole drop
var _fps := 30.0
var _plan: Dictionary = {}


func _ready() -> void:
	detector = Detector.new()
	detector.set(&"body", body)
	for key: String in MOVES:
		var c: Resource = load(String(MOVES[key]["res"]))
		var hips: PackedVector3Array = c.get(&"hips")
		_fps = float(c.get(&"fps"))
		var last := hips.size() - 1
		var drop := hips[0].y - hips[last].y
		var fwd := PackedFloat32Array()
		var high := PackedFloat32Array()
		for f in hips.size():
			fwd.append(hips[f].z - hips[0].z)
			high.append(clampf((hips[f].y - hips[last].y) / drop, 0.0, 1.0))
		_fwd[key] = fwd
		_high[key] = high


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
			and wish > 0.05 and int(body.get(&"stairs")) == 0 and int(body.get(&"terrain")) == 0
	var key := "run" if (wish > float(body.get(&"WALK")) + 0.1 and v.length() > RUN_FROM) else "walk"
	var mv: Dictionary = MOVES[key]
	var fwd: PackedFloat32Array = _fwd[key]
	if not walking:
		record = {}
		return
	var dir := v.normalized()
	# the cheap look: does the ground end a little ahead?
	if record.is_empty():
		var ahead: Dictionary = body.call(&"_ray_down", body.global_position + dir * maxf(LOOK, v.length() * LOOK_TIME))
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
		if key != "run" or drop > ROLL_MOST + MEASURED_WITHIN:
			refused = "too high for a step off (%.2f m)" % drop
			return
		key = "roll"
		mv = MOVES[key]
		fwd = _fwd[key]
	var m: Vector3 = -(record["normal"] as Vector3)
	if rad_to_deg(dir.angle_to(m)) > MOST_OFF_DEG:
		refused = "not heading at the edge"
		return
	# fit: the take's own path, from where it is taken up, laid from here out over the edge
	var from_t := float(mv["from"])
	var edge_at := float(mv["edge"])
	var to_edge := edge_at - _at(fwd, from_t)                  # the take's own distance to its edge at that moment
	var here := (record["edge"] as Vector3 - body.global_position).dot(m)
	if here > to_edge:
		return                                                  # not there yet
	var feet := body.global_position
	var top_y := float(record["ground"])        # the ground he stood on, not his feet, which sink a little at an edge
	var land_y := top_y - drop
	var speed_in := maxf(v.length(), 0.8)
	var t_air := sqrt(2.0 * drop / float(body.get(&"GRAVITY")))
	var t_rest := float(mv["exit"]) - float(mv["down"])
	var n := fwd.size()
	var exit_speed := (_at(fwd, float(mv["exit"])) - _at(fwd, float(mv["exit"]) - 0.2)) / 0.2
	var leave := feet + m * (here + _at(fwd, float(mv["leaves"])) - edge_at)
	# Through the air he goes on at the pace he came in at, for as long as the drop takes; the take's own travel
	# there belongs to its own, higher ledge. On the ground again he covers what the take does, at the take's pace
	# (walking), or goes from his own pace to the take's (running on).
	var down := leave + m * (speed_in * t_air if key != "walk" else _at(fwd, float(mv["down"])) - _at(fwd, float(mv["leaves"])))
	var end := down + m * ((speed_in + exit_speed) * 0.5 * t_rest if key == "run" else _at(fwd, float(mv["exit"])) - _at(fwd, float(mv["down"])))
	# the landing: the ground where he comes down and where he ends must be where the record said, with room for him
	for p: Vector3 in [down, down.lerp(end, 0.5), end]:
		var g: Dictionary = body.call(&"probe", Vector3(p.x, land_y, p.z))
		if not bool(g["hit"]) or absf(float(g["y"]) - land_y) > LAND_WITHIN:
			refused = "the ground where he would land is not level with the drop measured"
			return
		if not bool(detector.call(&"_fits", Vector3(p.x, land_y, p.z), float(body.get(&"HEIGHT")))):
			refused = "no room to land"
			return
	refused = ""
	_plan = {"key": key, "from": feet, "leave": Vector3(leave.x, top_y, leave.z), "down": Vector3(down.x, land_y, down.z), "end": Vector3(end.x, land_y, end.z),
			"m": m, "yaw0": body.rotation.y, "yaw1": atan2(-m.x, -m.z), "drop": drop,
			# align and step: at the pace he came in at. Air: as long as that drop takes to fall. Then the take's own time.
			"t_step": maxf((leave - feet).dot(m), 0.05) / speed_in, "t_air": t_air, "t_rest": t_rest, "exit_speed": exit_speed}
	# A softer landing off a lower edge (Yasin, 26 Nov: "Make a softer landing for edges lower than 1 meter"): he
	# folds by the share this drop is of the take's own (the study gives the landing forces by height, "4.4 body
	# weights from 0.45 m and 7.4 from 0.89 m", and no fold depth; taking the fold as in step with the height is
	# OURS), and is up again sooner by the same share.
	var share := 1.0 if key == "roll" else clampf(drop / float(mv["native"]), 0.0, 1.0)
	_plan["soft"] = 1.0 - share
	_plan["t_rest"] = float(_plan["t_rest"]) * lerpf(REST_LEAST, 1.0, share)
	plays += 1
	record = {}
	body.call(&"begin_move", _step_off, String(mv["input"]))


## Where the body is `t` seconds into the step off (called by the body every tick of the move).
func _step_off(t: float) -> Dictionary:
	var p := _plan
	var mv: Dictionary = MOVES[p["key"]]
	var fwd: PackedFloat32Array = _fwd[p["key"]]
	var high: PackedFloat32Array = _high[p["key"]]
	var m: Vector3 = p["m"]
	var t_step := float(p["t_step"])
	var t_air := float(p["t_air"])
	var t_rest := float(p["t_rest"])
	var out := {"done": false, "yaw": lerp_angle(float(p["yaw0"]), float(p["yaw1"]), clampf(t / maxf(t_step, 0.05), 0.0, 1.0))}
	if t < t_step:
		var u := t / t_step
		out["pos"] = (p["from"] as Vector3).lerp(p["leave"], u)
		out["clip_t"] = lerpf(float(mv["from"]), float(mv["leaves"]), u)
		out["air"] = false
	elif t < t_step + t_air:
		var u := (t - t_step) / t_air
		var ct := lerpf(float(mv["leaves"]), float(mv["down"]), u)
		# forward by the take's own travel through its fall; down by the take's own fall, scaled to this drop
		var f0 := _at(fwd, float(mv["leaves"]))
		var f1 := _at(fwd, float(mv["down"]))
		var along := (_at(fwd, ct) - f0) / maxf(f1 - f0, 0.001)
		var pos := (p["leave"] as Vector3).lerp(p["down"], along)
		var h0 := _at(high, float(mv["leaves"]))
		var h1 := _at(high, float(mv["down"]))
		pos.y = (p["down"] as Vector3).y + float(p["drop"]) * clampf((_at(high, ct) - h1) / maxf(h0 - h1, 0.001), 0.0, 1.0)
		out["pos"] = pos
		out["clip_t"] = ct
		out["air"] = true
		out["soft"] = float(p["soft"]) * u
	else:
		var u := clampf((t - t_step - t_air) / t_rest, 0.0, 1.0)
		var ct := lerpf(float(mv["down"]), float(mv["exit"]), u)
		var f0 := _at(fwd, float(mv["down"]))
		var f1 := _at(fwd, float(mv["exit"]))
		out["pos"] = (p["down"] as Vector3).lerp(p["end"], (_at(fwd, ct) - f0) / maxf(f1 - f0, 0.001))
		out["clip_t"] = ct
		out["air"] = false
		out["landed"] = true
		var free: Array = mv.get("free", [])
		out["free"] = free.size() == 2 and ct >= float(free[0]) and ct <= float(free[1])
		out["landing"] = String(mv.get("landing", "soft"))
		out["soft"] = float(p["soft"])
		if u >= 1.0:
			out["done"] = true
			out["exit"] = m * float(p["exit_speed"])
	return out
