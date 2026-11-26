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
const ClipData := preload("res://traversal/character/clip_data.gd")    # (nothing under tools/ is in the exported game)
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
# Stage 9, the high step up (the study: "0.30 to 0.50 m | deliberate high step"). No clip for it was in the library
# (the study: "0.30 to 0.50 m, high step | none | **missing**"; Mixamo's nearest steps onto 0.59 m). A Kimodo take of
# 26 Nov, the one of six that is a single step from standing: onto 0.61 m, the right foot up from 0.40 s and on top at
# 0.83 s, the left foot following from 0.80 s and beside it at 1.77 s.
const STEP_UP := {"input": "step_up", "res": "res://traversal/character/clips/KM_Step_Up.res",
		"from": 0.30, "from_moving": 0.45, "exit": 1.95,
		"edge": 0.25}           # NOT in the study: where the take's edge is taken to be (m ahead of where his hips
                                # start): a foot's length in front of his toes, and behind the heel that lands on top
const UP_BAND := [0.30, 0.50]   # the study's band for the high step: more than the first, up to the second (m)
const EARLY := 0.2              # NOT in the study: on the move the step up is begun this many seconds of travel before the
                                # take's own distance from the step
# At a run the same step is taken in stride, with a leap (Yasin, 26 Nov: "there should be one for running too ...
# the running one needs to be smoother, preserving our momentum as much as possible"). Six Kimodo takes ordered for
# it did not do it (they climb stairs, or leap along the flat), so it is the Running Jump clip he already has, "one
# run stride with a leap ... in it" (the study, Part 3): the body goes on at the speed he came in at, over an arc
# that clears the edge and comes down on top, and he runs on. Leaves the ground at 0.10 s of the clip, down at 0.67 s.
const RUN_UP := {"input": "run_jump", "off": 0.10, "land": 0.67, "exit": 0.90}
const RUN_UP_AIR := 0.40        # NOT in the study: seconds in the air of the leap onto the step
const RUN_UP_FACE := 0.75       # NOT in the study: the share of the leap at which he crosses the edge
const RUN_UP_ARC := 0.25        # NOT in the study: how far the arc rises over a straight line to the top (m); at the
                                # edge he is then 3 cm or more over a 0.50 m step
# Stage 10, the vault over a thin obstacle from a run (the study: "0.50 to 1.10 m | vault if thin ... one-hand vault at
# a run"; "The speed vault is one hand down, take-off from one leg, legs kicked sideways over with no foot touching,
# landing in stride"). The clip is Mixamo's Vault 1 Hand, downloaded for him. Measured on him (tests/zz_meas, 26 Nov):
# the left foot takes off at 0.33 s, 1.3 m before the obstacle; the left wrist is on it from 0.45 to 0.72 s, at
# 0.94 m (so an obstacle about 0.88 m high, a palm lower) and 2.30 m along the clip's path, 0.25 m to his left; the
# left foot comes down at 0.90 s, 1.5 m beyond it; it runs at 4.3 m/s; his hips peak at 1.32 m and leave the ground
# at 1.12 m.
const VAULT := {"input": "vault", "res": "res://traversal/character/clips/Vault_1_Hand.res",
		"from": 0.20, "off": 0.33, "hand_on": 0.47, "hand_off": 0.65, "down": 0.90, "exit": 1.13,
		"at": 2.30, "high": 0.88, "hand_side": 0.25, "speed": 4.3, "hips_off": 1.12, "hips_top": 1.32}
const VAULT_BAND := [0.50, 1.10]    # the study's band: more than the first, up to the second (m)
const VAULT_PACE := [0.75, 1.1]     # NOT in the study: the clip is played at between these shares of its own pace, to go at his
const PALM := 0.08                  # the study, Part 3: "the gripping palm is about 0.08 m further along" than the wrist
const HAND_FADE := 0.07             # NOT in the study: seconds over which the hand's hold comes in and goes out
const LAND_LEVEL := 0.10            # NOT in the study: the ground beyond is taken as level with his if within this (m)
const UP_LOOK_RUN := 1.6        # NOT in the study: at a run it is looked for this far ahead (m)
const UP_LOOK := 0.9            # NOT in the study: how far ahead something to step onto is looked for (m)
const RUN_ON_MOST := 0.50       # NOT in the study: running off an edge up to this high he runs on with no landing clip
                                # (the height he also runs up onto in stride: the top of the study's high-step band)
const ROLL_JUMP_MORE := 0.7     # a jump off an edge falls from the top of the jump: the body's own running jump rises
                                # 0.60 m (body.gd, JUMP_RISE_RUN), so that much more fall is still rolled out of
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
var enabled := true             # false = no move is begun (the tests of the body alone, and of detection alone)
var refused := ""               # why the last edge met was not taken with the move ("" = it was, or none met)
var plays := 0                  # moves begun (for the tests)
var _tick := 0
var _fwd := {}                  # move -> the take's own travel forward, frame by frame
var _high := {}                 # move -> how far above its landing the take is, as a share of its whole drop
var _fps := 30.0
var _plan: Dictionary = {}
var _up_fwd := PackedFloat32Array()
var _up_rise := PackedFloat32Array()
var _up_high := 0.0             # the height the step-up take climbs
var _up_record: Dictionary = {}
var _v_fwd := PackedFloat32Array()
var _v_hips := PackedFloat32Array()


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
	var up: Resource = load(String(STEP_UP["res"]))
	var up_hips: PackedVector3Array = up.get(&"hips")
	for f in up_hips.size():
		_up_fwd.append(up_hips[f].z - up_hips[0].z)
	_up_rise = ClipData.rise_of(up_hips)
	_up_high = up_hips[up_hips.size() - 1].y - up_hips[0].y
	body.connect(&"landed", _on_landed)
	var vc: Resource = load(String(VAULT["res"]))
	var v_hips: PackedVector3Array = vc.get(&"hips")
	for f in v_hips.size():
		_v_fwd.append(v_hips[f].z - v_hips[0].z)
		_v_hips.append(v_hips[f].y)


## Coming down from a jump or a fall at speed, from high enough: the roll, from its landing on, if there is the room
## for it (Yasin, 26 Nov: "roll off worked only on running off the edge ... it should work when we jump off too, but
## again with the available space to execute logic").
func _on_landed(drop: float) -> void:
	if not enabled or bool(body.call(&"in_move")) or bool(body.get(&"crouched")):
		return
	var v: Vector3 = body.get(&"hvel")
	if drop <= float(BAND[1]) + MEASURED_WITHIN or drop > ROLL_MOST + ROLL_JUMP_MORE or v.length() < RUN_FROM:
		return
	var mv: Dictionary = MOVES["roll"]
	var fwd: PackedFloat32Array = _fwd["roll"]
	var dir := v.normalized()
	var feet := body.global_position
	var travel := _at(fwd, float(mv["exit"])) - _at(fwd, float(mv["down"]))
	for share: float in [0.0, 0.5, 1.0]:
		var p := feet + dir * (travel * share)
		var g: Dictionary = body.call(&"probe", Vector3(p.x, feet.y, p.z))
		if not bool(g["hit"]) or absf(float(g["y"]) - feet.y) > LAND_WITHIN or not bool(detector.call(&"_fits", Vector3(p.x, feet.y, p.z), float(body.get(&"HEIGHT")))):
			refused = "no room to roll out of the landing"
			return
	refused = ""
	_plan = {"key": "roll_only", "from": feet, "end": feet + dir * travel, "m": dir, "yaw": atan2(-dir.x, -dir.z),
			"exit_speed": (_at(fwd, float(mv["exit"])) - _at(fwd, float(mv["exit"]) - 0.2)) / 0.2}
	plays += 1
	body.call(&"begin_move", _roll_only, String(mv["input"]))


func _roll_only(t: float) -> Dictionary:
	var mv: Dictionary = MOVES["roll"]
	var fwd: PackedFloat32Array = _fwd["roll"]
	var p := _plan
	var u := clampf(t / (float(mv["exit"]) - float(mv["down"])), 0.0, 1.0)
	var ct := lerpf(float(mv["down"]), float(mv["exit"]), u)
	var f0 := _at(fwd, float(mv["down"]))
	var f1 := _at(fwd, float(mv["exit"]))
	var free: Array = mv["free"]
	var out := {"done": u >= 1.0, "pos": (p["from"] as Vector3).lerp(p["end"], (_at(fwd, ct) - f0) / maxf(f1 - f0, 0.001)), "yaw": float(p["yaw"]),
			"clip_t": ct, "air": false, "landed": true, "landing": "heavy", "free": ct >= float(free[0]) and ct <= float(free[1])}
	if u >= 1.0:
		out["exit"] = (p["m"] as Vector3) * float(p["exit_speed"])
	return out


func _at(table: PackedFloat32Array, t: float) -> float:
	var x := clampf(t * _fps, 0.0, table.size() - 1.001)
	var i := int(x)
	return lerpf(table[i], table[i + 1], x - i)


func _physics_process(_dt: float) -> void:
	if body == null or not enabled or bool(body.call(&"in_move")):
		return
	_tick += 1
	var v: Vector3 = body.get(&"hvel")
	var wish := (body.get(&"_wish") as Vector3).length()
	if _try_step_up(v, body.get(&"_wish")):
		return
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
	# Running off a low edge he simply runs on (Yasin, 26 Nov: "only running off a low edge plays timid short steps
	# before the run continues, just continue running animation in that case"): the run itself is shown all the way,
	# the body is carried down as before, and he is handed back as he touches down, at the speed he came in at.
	var run_on := key == "run" and drop <= RUN_ON_MOST + MEASURED_WITHIN
	if run_on:
		_plan["end"] = _plan["down"]
		_plan["exit_speed"] = speed_in
		_plan["run_on"] = true
	# A softer landing off a lower edge (Yasin, 26 Nov: "Make a softer landing for edges lower than 1 meter"): he
	# folds by the share this drop is of the take's own (the study gives the landing forces by height, "4.4 body
	# weights from 0.45 m and 7.4 from 0.89 m", and no fold depth; taking the fold as in step with the height is
	# OURS), and is up again sooner by the same share.
	var share := 1.0 if key == "roll" else clampf(drop / float(mv["native"]), 0.0, 1.0)
	_plan["soft"] = 1.0 - share
	_plan["t_rest"] = float(_plan["t_rest"]) * lerpf(REST_LEAST, 1.0, share)
	plays += 1
	record = {}
	body.call(&"begin_move", _step_off, "ground" if run_on else String(mv["input"]))


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
	elif bool(p.get("run_on", false)):
		out["pos"] = p["down"]
		out["clip_t"] = 0.0
		out["air"] = false
		out["done"] = true
		out["exit"] = m * float(p["exit_speed"])
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


# ------------------------------------------------------------------------------------------------ stage 9: the high step up

## Something of 0.30 to 0.50 m ahead, with room to stand on it: step up onto it. Asked for by going at it, at a walk,
## at a run, or from standing against it (the body is stopped by anything over 0.30 m).
func _try_step_up(v: Vector3, wish: Vector3) -> bool:
	if int(body.get(&"state")) != 0 or bool(body.get(&"crouched")) or wish.length() < 0.05 \
			or int(body.get(&"stairs")) != 0 or int(body.get(&"terrain")) != 0:
		_up_record = {}
		return false
	var dir := wish.normalized()
	# the cheap look: is anything in the way just above what he steps over by himself?
	if _up_record.is_empty():
		var from := body.global_position + Vector3.UP * (float(UP_BAND[0]) + 0.03)
		var q := PhysicsRayQueryParameters3D.create(from, from + dir * (UP_LOOK_RUN if v.length() > RUN_FROM else UP_LOOK), body.collision_mask, [body.get_rid()])
		if body.get_world_3d().direct_space_state.intersect_ray(q).is_empty():
			return false
	# (at a run it is measured every tick once something is seen: he covers 7 cm a tick, and a move has to be begun
	# within a few tenths of a metre of its place)
	if _up_record.is_empty() or _tick % (1 if v.length() > RUN_FROM else AGAIN) == 0:
		_up_record = detector.call(&"measure", dir)
		if _up_record["kind"] != "obstacle":
			_up_record = {}
			return false
	var rec := _up_record
	var top := float(rec["top"])
	if _try_vault(v, wish, rec):
		return true
	if top <= float(UP_BAND[0]) + MEASURED_WITHIN:
		return false                                            # the body walks onto it by itself
	if top > float(UP_BAND[1]) + MEASURED_WITHIN:
		refused = "too high for a step up (%.2f m)" % top
		return false
	if bool(rec["blocked"]) or not bool(rec["stand_room"]):
		refused = "no room to stand on top"
		return false
	var m: Vector3 = -(rec["normal"] as Vector3)
	if rad_to_deg(dir.angle_to(m)) > MOST_OFF_DEG:
		refused = "not heading at it"
		return false
	if _try_run_up(v, wish, rec, m, top):
		return true
	if not refused.is_empty():
		return false
	# Come at on the move, the take is taken up with its stepping foot already lifting, and of the take and its mirror
	# image the one whose stepping foot is the foot he has forward; and it is begun before he is stopped against the
	# step. (Begun from its standing start once he had walked into the step, the foot he had forward was already past
	# the step's face: Yasin, 26 Nov, "stepping onto the edge is jittery".)
	var moving := v.length() > 0.5
	var from_t := float(STEP_UP["from_moving"]) if moving else float(STEP_UP["from"])
	var exit_t := float(STEP_UP["exit"])
	var native := float(STEP_UP["edge"]) - _at(_up_fwd, from_t)      # the take's own distance from the face as it begins
	var here := (rec["edge"] as Vector3 - body.global_position).dot(m)
	if here > native + 0.02 + (v.length() * EARLY if moving else 0.0):
		return false                                            # not there yet
	var mirror := false
	var ch := body.get_node_or_null(^"Character")
	if moving and ch != null and ch.has_method(&"_lead_now"):
		mirror = float(ch.call(&"_lead_now")) > 0.0             # the take steps with the right foot; his left is forward
	# fit: he ends as far in from the edge as the take does; the take's travel is stretched to that
	var inward := _at(_up_fwd, exit_t) - float(STEP_UP["edge"])
	if float(rec["depth"]) < inward + float(body.get(&"RADIUS")):
		refused = "the top is not deep enough to step onto"
		return false
	var feet := body.global_position
	var ground := float(rec["ground"])
	var end := feet + m * (here + inward)
	end.y = ground + top
	if not bool(detector.call(&"_fits", end, float(body.get(&"HEIGHT")))):
		refused = "no room where he would end"
		return false
	refused = ""
	_plan = {"key": "up", "from": Vector3(feet.x, ground, feet.z), "end": end, "m": m, "yaw0": body.rotation.y, "yaw1": atan2(-m.x, -m.z),
			"top": top, "here": here, "from_t": from_t, "stretch": (here + inward) / maxf(_at(_up_fwd, exit_t) - _at(_up_fwd, from_t), 0.01),
			"exit_speed": maxf((_at(_up_fwd, exit_t) - _at(_up_fwd, exit_t - 0.2)) / 0.2, 0.0)}
	plays += 1
	_up_record = {}
	record = {}
	body.call(&"begin_move", _step_up, String(STEP_UP["input"]) + ("_m" if mirror else ""))
	return true


## Where the body is `t` seconds into the step up: forward by the take's own travel (stretched to the distance
## measured), up by the take's own rise (scaled to the height measured).
func _step_up(t: float) -> Dictionary:
	var p := _plan
	var m: Vector3 = p["m"]
	var from_t := float(p["from_t"])
	var exit_t := float(STEP_UP["exit"])
	var ct := minf(from_t + t, exit_t)
	var gone := _at(_up_fwd, ct) - _at(_up_fwd, from_t)
	var rise := _at(_up_rise, ct)
	var pos := (p["from"] as Vector3) + m * (gone * float(p["stretch"]))
	pos.y = (p["from"] as Vector3).y + float(p["top"]) * rise
	var out := {"done": ct >= exit_t, "pos": pos, "clip_t": ct, "air": false,
			"yaw": lerp_angle(float(p["yaw0"]), float(p["yaw1"]), clampf(t / 0.2, 0.0, 1.0)),
			# for the feet: the take's own step, as it stands ahead of him at this moment
			"step": [float(STEP_UP["edge"]) - _at(_up_fwd, ct), _up_high, _up_high * rise, float(p["top"])]}
	if ct >= exit_t:
		out["pos"] = p["end"]
		out["exit"] = m * float(p["exit_speed"])
	return out


## The step up at a run: a leap in stride. True once it is begun; false with `refused` empty = not this move's, or
## not yet; false with `refused` set = it is waiting for its take-off point.
func _try_run_up(v: Vector3, wish: Vector3, rec: Dictionary, m: Vector3, top: float) -> bool:
	refused = ""
	var speed := v.length()
	if wish.length() <= float(body.get(&"WALK")) + 0.1 or speed <= RUN_FROM:
		return false
	var here := (rec["edge"] as Vector3 - body.global_position).dot(m)
	var take_off := speed * RUN_UP_AIR * RUN_UP_FACE            # how far before the edge he leaves the ground
	var beyond := speed * RUN_UP_AIR * (1.0 - RUN_UP_FACE)      # ... and how far past it he comes down
	var out_run := speed * (float(RUN_UP["exit"]) - float(RUN_UP["land"]))
	if float(rec["depth"]) < beyond + out_run + float(body.get(&"RADIUS")):
		return false                                            # not the room on top to run on: the walking step up
	if here < take_off - 0.15:
		return false                                            # too near already for the leap: the walking step up
	if here > take_off:
		refused = "coming up to the leap"
		return false
	var feet := body.global_position
	var ground := float(rec["ground"])
	var land := feet + m * (here + beyond)
	land.y = ground + top
	var end := land + m * out_run
	for p: Vector3 in [land, end]:
		if not bool(detector.call(&"_fits", p, float(body.get(&"HEIGHT")))):
			return false
	_plan = {"key": "run_up", "from": Vector3(feet.x, ground, feet.z), "land": land, "end": end, "m": m, "yaw0": body.rotation.y, "yaw1": atan2(-m.x, -m.z),
			"top": top, "speed": speed, "exit_speed": speed}
	plays += 1
	_up_record = {}
	record = {}
	body.call(&"begin_move", _run_up, String(RUN_UP["input"]))
	return true


func _run_up(t: float) -> Dictionary:
	var p := _plan
	var m: Vector3 = p["m"]
	var out := {"done": false, "yaw": lerp_angle(float(p["yaw0"]), float(p["yaw1"]), clampf(t / 0.15, 0.0, 1.0))}
	if t < RUN_UP_AIR:
		var u := t / RUN_UP_AIR
		var pos := (p["from"] as Vector3).lerp(p["land"], u)
		pos.y = (p["from"] as Vector3).y + float(p["top"]) * u + 4.0 * RUN_UP_ARC * u * (1.0 - u)
		out["pos"] = pos
		out["clip_t"] = lerpf(float(RUN_UP["off"]), float(RUN_UP["land"]), u)
		out["air"] = true
	else:
		var rest := float(RUN_UP["exit"]) - float(RUN_UP["land"])
		var u := clampf((t - RUN_UP_AIR) / rest, 0.0, 1.0)
		out["pos"] = (p["land"] as Vector3).lerp(p["end"], u)
		out["clip_t"] = lerpf(float(RUN_UP["land"]), float(RUN_UP["exit"]), u)
		out["air"] = false
		if u >= 1.0:
			out["done"] = true
			out["exit"] = m * float(p["exit_speed"])
	return out


# ------------------------------------------------------------------------------------------------ stage 10: the vault

## A thin obstacle of 0.50 to 1.10 m, come at at a run, with level, free ground beyond it: vault it.
func _try_vault(v: Vector3, wish: Vector3, rec: Dictionary) -> bool:
	var top := float(rec["top"])
	# (a thin obstacle of just 0.50 m is vaulted too: there is no standing on it, so it cannot be stepped up onto)
	if top == INF or top < float(VAULT_BAND[0]) - MEASURED_WITHIN or top > float(VAULT_BAND[1]) + MEASURED_WITHIN:
		return false
	if not bool(rec["thin"]) or bool(rec["blocked"]):
		return false                                            # deep: to be climbed onto (stage 11), not vaulted
	var speed := v.length()
	if wish.length() <= float(body.get(&"WALK")) + 0.1 or speed <= RUN_FROM:
		refused = "a thin obstacle, but not at a run (the step vault is stage 11)"
		return false
	var m: Vector3 = -(rec["normal"] as Vector3)
	if rad_to_deg(v.normalized().angle_to(m)) > MOST_OFF_DEG:
		refused = "not heading at it"
		return false
	if not rec.has("landing") or absf(float(rec["landing"])) > LAND_LEVEL or not bool(rec.get("landing_ok", false)):
		refused = "the ground beyond it is not level with his, or has no room"
		return false
	# fit: the clip's own path, laid so that where its hand comes down is the middle of the obstacle's top
	var depth := float(rec["depth"])
	var to_mid := (rec["edge"] as Vector3 - body.global_position).dot(m) + depth * 0.5
	var start := float(VAULT["at"]) - _at(_v_fwd, float(VAULT["from"]))       # the clip's own distance to it as it is taken up
	if to_mid > start:
		refused = "coming up to the vault"
		return false
	if to_mid < start - 0.45:
		refused = "too near already to vault it"
		return false
	var feet := body.global_position
	var ground := float(rec["ground"])
	var mid := feet + m * to_mid
	mid.y = ground
	var land := mid + m * (_at(_v_fwd, float(VAULT["down"])) - float(VAULT["at"]))
	var end := mid + m * (_at(_v_fwd, float(VAULT["exit"])) - float(VAULT["at"]))
	for p: Vector3 in [land, end]:
		var g: Dictionary = body.call(&"probe", p)
		if not bool(g["hit"]) or absf(float(g["y"]) - ground) > LAND_LEVEL or not bool(detector.call(&"_fits", Vector3(p.x, float(g["y"]), p.z), float(body.get(&"HEIGHT")))):
			refused = "no level, free ground to land on"
			return false
	refused = ""
	var pace := clampf(speed / float(VAULT["speed"]), float(VAULT_PACE[0]), float(VAULT_PACE[1]))
	var left := Vector3.UP.cross(m).normalized()
	_plan = {"key": "vault", "from": Vector3(feet.x, ground, feet.z), "mid": mid, "end": Vector3(end.x, ground, end.z), "m": m,
			"yaw0": body.rotation.y, "yaw1": atan2(-m.x, -m.z), "top": top, "pace": pace, "to_mid": to_mid,
			# the hand: on the middle of the top, as far to his left as the clip has it, the wrist a palm over it
			"hand_at": Vector3(mid.x, ground + top + PALM, mid.z) + left * float(VAULT["hand_side"]),
			"exit_speed": float(VAULT["speed"]) * pace}
	plays += 1
	_up_record = {}
	record = {}
	body.call(&"begin_move", _vault, String(VAULT["input"]))
	return true


## Where the body is `t` seconds into the vault. Forward by the clip's own travel, set so that its hand comes down
## on the obstacle. Up or down by how much higher or lower the obstacle is than the clip's own, by the share of the
## clip's own rise over its take-off height that it has made (none on the ground, all of it at the top).
func _vault(t: float) -> Dictionary:
	var p := _plan
	var m: Vector3 = p["m"]
	var from_t := float(VAULT["from"])
	var exit_t := float(VAULT["exit"])
	var ct := minf(from_t + t * float(p["pace"]), exit_t)
	# (before its hand is down the clip's travel is fitted to the distance he really had to go; after, it is its own)
	var z := _at(_v_fwd, ct) - float(VAULT["at"])
	var before := float(VAULT["at"]) - _at(_v_fwd, from_t)
	if z < 0.0:
		z *= float(p["to_mid"]) / before
	var pos := (p["mid"] as Vector3) + m * z
	var air := ct >= float(VAULT["off"]) and ct < float(VAULT["down"])
	# (all of it for as long as the hand is down, coming in from take-off and going out to landing: fitted by the
	# clip's own rise alone he was still too high over a low obstacle when the hand came down, and the wrist was up
	# to 11 cm short of it. His arm is 17 % shorter than the clip's body's, so the hand is held for the middle 0.18 s
	# of the clip's 0.27 s: outside that his arm cannot reach the place.)
	var over := 0.0
	if air:
		over = minf(smoothstep(float(VAULT["off"]), float(VAULT["hand_on"]), ct), 1.0 - smoothstep(float(VAULT["hand_off"]), float(VAULT["down"]), ct))
	pos.y += (float(p["top"]) - float(VAULT["high"])) * over
	var hold := clampf(minf((ct - float(VAULT["hand_on"])) / HAND_FADE + 1.0, (float(VAULT["hand_off"]) - ct) / HAND_FADE + 1.0), 0.0, 1.0)
	var out := {"done": ct >= exit_t, "pos": pos, "clip_t": ct, "air": air, "free": true,
			"yaw": lerp_angle(float(p["yaw0"]), float(p["yaw1"]), clampf(t / 0.15, 0.0, 1.0)),
			"hand": [0, p["hand_at"], hold]}
	if ct >= exit_t:
		out["pos"] = p["end"]
		out["exit"] = m * float(p["exit_speed"])
	return out
