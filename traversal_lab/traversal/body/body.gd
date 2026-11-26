extends CharacterBody3D
## Stage 1: the body alone. A floating capsule: the capsule covers the body from FLOAT above the feet to the top of
## the head, and one short downward probe finds the ground, so kerbs and stair risers pass under the capsule.
## The node's origin is the feet. This script owns where the character is; nothing else may move it.
## (CharacterBody3D under Jolt has no stair stepping and unreliable floor flags, so neither is used here.)

enum State { GROUND, STEEP, UNSUPPORTED, AIR }
const STATE_NAMES := ["on ground", "too steep", "touching, unsupported", "in air"]

const HEIGHT := 1.80            # feet to top of head
const RADIUS := 0.25
const FLOAT := 0.32             # capsule bottom above the feet; anything lower than this is stepped onto
const STEP_DOWN := 0.30         # ground this far below the feet is still "ground" (stairs down, kerbs)
const PROBE_R := 0.15
# Steep ground (26 Nov, Yasin: "we should be able to climb even higher than 35-40 degrees, there are mountain
# climbers and trekkers who do that all the time ... bend or hunch forward, raising the heels off the ground,
# getting assistance by hands"). Sourced notes: research_notes/Hybrid character traversal study/steep_slopes.md.
const SLOPE_WALK_DEG := 20.0    # up to here the ordinary clips serve (the steepest streets are 19 degrees)
const SLOPE_HANDS_DEG := 35.0   # from here up: on hands and feet. NO source gives this angle; it is reasoned from
                                # shoe grip on dry concrete running out at 31 to 40 deg, an ankle that could not bend
                                # past 24 deg, and a 37 deg ski-jump race described as run "on all four"
const SLOPE_LIMIT_DEG := 50.0   # steeper ground cannot be stood on: climbing rubber on granite holds to 44 to 50 deg
# Going uphill, what limits a person is how fast they gain height, whatever the slope:
const CLIMB_WALK := 0.35        # m/s of height: the steady rate in the treadmill study of 9 to 39 deg slopes
                                # (0.70 m/s along a 30 deg belt)
const CLIMB_RUN := 1.0          # m/s of height: a fast run up 30 deg was measured at 2.06 m/s along the slope
                                # (the best racers hold 0.6 m/s for half an hour)
const CLIMB_HANDS_RUN := 0.6    # on hands and feet with run held: the racers' rate; NOT measured for crawling
const DOWN_EASE := 16.0 / 30.0  # "walking down a slope of 30 degrees was done at the same speed as walking up 16"
# Speeds and how they change come from the movement study (reports/Hybrid character traversal study.md, Part 1
# "Turning, starting, stopping" and Part 3), not from feel. Each line says which finding it follows.
const WALK := 1.45              # the study: "Comfortable adult walking is about 1.27 to 1.46 m/s". 1.45, because its
                                # other two walking figures ("115 to 120 steps a minute with a 1.5 to 1.7 m stride") only
                                # fit together with that range at 1.44 to 1.46 m/s (speed = steps a minute x stride / 120)
const RUN := 4.5                # running was measured at 2.5 to 4.5 m/s
const START_TIME_WALK := 0.24   # "A walk reaches about 90 % of its speed on the first step and steady speed in about three":
                                # this time constant gives 90 % in 0.55 s, about when the first step lands
const START_TAIL_WALK := 0.33   # ... and from 90 % on this slower one, so the last tenth comes in during the third step
                                # (the split into two rates is OURS: the study gives the two points, not the curve)
const START_TIME_RUN := 0.60    # NOT in the study (steps to reach a run were not found): a value to tune by eye
const STOP_WALK := 2.3          # m/s2: "a walk stops in under two steps" -> from 1.4 m/s in 0.6 s
const STOP_RUN := 6.2           # m/s2: "5 steps and 2.9 m" from a flat-out run (about 6 m/s)
# Turning (changed 25 Nov after Yasin's play-test: "very very slow to turn"). The first version capped every turn
# at the gentle arc of the Walking / Running Left Turn clips (36 deg a stride = 30 to 46 deg a second). That is how
# people follow a curve, not how they turn a corner: the study's sharp turns are step and spin turns of about
# 75 deg a step, done "within one step of the cue" and "without resetting the walking rhythm".
const TURN_RATE_WALK := 3.14    # rad/s: his Walking Turn 180 clip turns 180 deg in 1.00 s; 75 deg a 0.6 s step = 125 deg/s
const TURN_RATE_RUN := 4.7      # rad/s: his Running Turn 180 clip turns 180 deg in 0.67 s (270 deg/s, the top of the
                                # 137 to 272 deg/s measured; over 300 deg/s is outside the data)
const TURN_SLOW := 0.6          # people slow to turn: 0.96 m/s on a 1 m circle against 1.61 m/s straight
const TURN_SLOW_ANGLE_DEG := 90.0   # the full slow-down applies from a right-angle turn up
# On a curve people slow down: "on a 1 m radius circle people chose 0.96 m/s against 1.61 m/s in a straight line".
# Taken as a limit on the sideways pull he accepts while the way he is asked to go keeps turning: speed x turn rate
# stays under what that walker had, scaled to his own walking speed: (0.96 / 1.61 x WALK)^2 / 1 m. That one circle is
# all the study gives; carrying it to other radii this way is OURS. It is a WALKING figure and is applied to walking
# only: for a day a figure of ours slowed a run on a curve too, down to a walk (Yasin, 26 Nov: "CANT TURN CORNERS
# WHILE RUNNING NOW, IT SWITCHES TO WALKING"). The study gives nothing for a run on a curve, so a run is not slowed.
const CURVE_PULL_WALK := (0.96 / 1.61 * WALK) * (0.96 / 1.61 * WALK) / 1.0    # m/s2
const CURVE_TIME := 0.25        # NOT in the study: seconds over which the stick's turning is averaged
const REVERSE_ANGLE_DEG := 135.0  # asked to go nearly the opposite way at a run: "a sudden turn starts with a braking
                                # action like a rapid stop" - brake to REVERSE_SPEED first, then turn round
# Turning on the spot before setting off (Stage 5): "turning 180 degrees on the spot takes about 3 to 4 steps", and
# his turn clips do it without travelling. From rest, a direction more than SPOT_START off his facing is turned to
# first, at the turn rates above; he sets off when within SPOT_END.
const SPOT_START_DEG := 60.0    # NOT in the study: below this he just sets off and curves; a value to tune by eye
const SPOT_END_DEG := 15.0      # NOT in the study
# How fast he turns on the spot from standing. The study: "Turning 180 degrees on the spot takes about 3 to 4 steps"
# and "Young adults take 115 to 120 steps a minute": three and a half steps at 117.5 a minute are 1.79 s for the 180
# degrees. (Putting the two figures together is OURS. Until 26 Nov he spun round at the walking turn rate, 180
# degrees in one second, with no steps: Yasin, "THERE WASNT ANY STANDING 180 TURNS".)
const SPOT_RATE := PI / (3.5 * 60.0 / 117.5)    # rad/s. NOT USED since Yasin's word of 26 Nov (see character.gd,
                                                # TURN_BIG_DEG): he turns at the walking turn rate again, with no steps
const RUN_OUT := 2.5            # m/s: the speed he comes out of the plant-and-turn at
# Stairs are their own movement: "stairs are climbed at about half a second per step: 0.51 s up and 0.47 s down".
# The study has nothing on running stairs (its notes: "two-steps-at-a-time mechanics, running on stairs: not
# found"), so the running figures are OURS, set 26 Nov at Yasin's word ("we need to set them ourselves as many
# players will run them"). The Kimodo running clips take 0.33 s a step both ways; these are a little quicker.
const STEP_TIME_UP := 0.51
const STEP_TIME_DOWN := 0.47
const STEP_TIME_RUN_UP := 0.28      # NOT in the study: 1.0 m/s along 0.28 m treads; a value to tune by feel
const STEP_TIME_RUN_DOWN := 0.22    # NOT in the study: 1.3 m/s; a value to tune by feel
# Landings: the study gives the forces (4.4 body weights from 0.45 m, 7.4 from 0.89 m) and that the peak comes 35 to
# 91 ms after contact, but no time to recover. These follow his landing clips and are values to tune by eye.
const LAND_HOLD_SOFT := 0.30    # NOT in the study
const LAND_HOLD_HARD := 0.90    # NOT in the study (Hard Landing has 1.0 s left after the feet touch)
const HARD_DROP := 1.0          # the study: a drop of 1.0 to 2.0 m is "a heavy landing"
const TREAD := 0.28             # a tread is at least 0.28 m (US accessible); used until the stairs have been measured
const REVERSE_SPEED := 2.0      # NOT in the study: the speed he may carry into the turn-round; a value to tune by eye
const RISE_SPEED := 2.4         # how fast the feet follow ground that rises (m/s): 4 cm a tick
const SINK_SPEED := 3.0         # and ground that falls away
const GRAVITY := 9.8
const TERMINAL := 50.0
const TURN_SPEED := 12.0        # radians a second
const JUMP_RISE := 0.45         # an average standing jump raises the body 0.41 to 0.50 m
const JUMP_DIP_STAND := 0.0     # DEPARTS FROM THE STUDY AT YASIN'S WORD. The study: "A natural standing jump spends 0.70 s
                                # dipping and 0.30 s pushing". Built so on 26 Nov; his play-test the same day: "STANDING JUMP
                                # TAKES WAY TOO LONG". The dip is not waited for; the push keeps the study's 0.30 s.
const JUMP_PUSH_STAND := 0.30
const JUMP_RISE_RUN := 0.60     # "a run-up typically 0.10 to 0.20 m more": 0.45 + 0.15
const JUMP_PUSH_RUN := 0.10     # from a run the take-off comes off the stride: the Running Jump clip leaves at 0.10 s

# Stage 6, crouch (Yasin, 26 Nov: "DO THE CROUCH MOVES"). The study: "Build: crouch idle and walk, the smaller
# capsule, the fit test before standing. Pass when: the character passes under the 1.2 m overhang crouched and cannot
# stand up beneath it; standing up in the open is instant; crouch speed is about half walk speed".
# The study: "crouch speed is about half walk speed". Built at exactly half, 0.72 m/s; Yasin, 26 Nov: "crouched
# movement is too slow". Now the top of what the study's figure allows: half of its fastest comfortable walk
# (1.46 m/s), plus the 10 % a single study figure is given (his decision of 26 Nov).
const CROUCH_SPEED := 1.46 * 0.5 * 1.1    # 0.80 m/s
const CROUCH_HEIGHT := 1.15         # feet to the top of the crouched body: under the course's 1.2 m overhang. His
                                    # crouch takes hold the top of the head under this (measured, see character.gd)
const STAND_ROOM := 0.03            # NOT in the study: the standing shape is tried this much thinner than it is, so
                                    # that a wall he is touching does not count as no room to stand

signal jump_started(push_time: float)
signal jumped
signal landed(drop: float)

var tape: Node
var state: State = State.AIR
var hvel := Vector3.ZERO        # horizontal velocity
var vy := 0.0
var ground_y := 0.0
var ground_normal := Vector3.UP
var _probe := SphereShape3D.new()
var _wish := Vector3.ZERO
var _touched := false
var _wall := Vector3.ZERO          # the upright surface being leaned on, if any
var jump_timer := 0.0           # > 0 while pushing off for a jump
var air_time := 0.0
var from_jump := false          # this time in the air began with a jump
var _jump_held := false
var _air_peak := 0.0
var _jump_still := false
var _look: Array[Node3D] = []
var slope_deg := 0.0            # how steep the ground under him is
var grade := 0.0                # its rise per metre the way he is going (+ = uphill)
var face_in := false            # he is coming down very steep ground backwards, facing the slope
var terrain := 0                # 0 = ordinary ground, 1 = steep (leaning walk), 2 = very steep (hands and feet)
var stairs := 0                 # +1 going up stairs, -1 going down, 0 not on stairs
var stair_tread := TREAD        # the depth of a step, measured from the last two edges crossed
var stair_edge := Vector3.ZERO  # where the last step edge was crossed
var stair_dir := Vector3.ZERO   # the way along the stairs
var stair_riser := 0.0           # the height of a step, from the last edge crossed (0 = not yet known)
var stair_count := 0            # step edges crossed on these stairs
var _ray_y := 0.0
var _ray_ok := false
var _since_edge := 99.0
var spot_total := 0.0           # the on-the-spot turn being made (radians, + = to his left); 0 = none
var spot_left := 0.0            # how much of it is still to turn
var spot_run := false           # it is the plant-and-turn out of a run
var spot_walk := false          # it is the turn round made while walking
var land_hold := 0.0            # seconds left of gathering himself after a landing, when the stick is not obeyed
var _wish_yaw := 0.0            # the way he was asked to go last tick
var _wish_turn := 0.0           # how fast the way he is asked to go is turning (rad/s, averaged)
var _wish_on := false
var _stood_y := 0.0             # the height of the ground he last stood squarely on (his middle over it)
var move_path := Callable()     # a traversal move is under way: see begin_move
var move_clip := ""             # the tree input its clip is under, and where in the clip it is (seconds)
var move_clip_t := 0.0
var move_t := 0.0
var move_landed := false        # he has come down in it
var move_free := false          # the clip is shown as it is, with no fitting of the feet (a roll)
var move_landing := "soft"      # what kind of landing the move makes
var move_step: Array = []       # a climbing move: [how far ahead the clip's own edge is, the clip's own height, how much
                                # of it the body has risen] (m), for the feet
var move_hand: Array = []       # a move that puts a hand on something: [0 left / 1 right, where the wrist goes, how much]
var move_soft := 0.0            # 0..1: how much less than the clip he folds on landing
var _wish_was_moving := false
var crouched := false           # he is crouched: the smaller capsule, half walking speed, no run, no jump
var _col: CollisionShape3D
var _fit := CapsuleShape3D.new()


func _ready() -> void:
	motion_mode = CharacterBody3D.MOTION_MODE_FLOATING
	wall_min_slide_angle = 0.0
	max_slides = 6
	var shape := CapsuleShape3D.new()
	shape.radius = RADIUS
	shape.height = HEIGHT - FLOAT
	var col := CollisionShape3D.new()
	col.shape = shape
	col.position.y = FLOAT + (HEIGHT - FLOAT) * 0.5
	add_child(col)
	_col = col
	_fit.radius = RADIUS - STAND_ROOM
	_fit.height = HEIGHT - FLOAT - STAND_ROOM
	# a flat underside: without it a block between FLOAT and waist height meets the capsule's round bottom and
	# is ridden up. With it the block meets an upright side and is a wall.
	var skirt_shape := CylinderShape3D.new()
	skirt_shape.radius = RADIUS - 0.004
	skirt_shape.height = RADIUS + 0.06
	var skirt := CollisionShape3D.new()
	skirt.shape = skirt_shape
	skirt.position.y = FLOAT + skirt_shape.height * 0.5
	add_child(skirt)
	_probe.radius = PROBE_R
	# a plain look for the lab: the capsule, thin legs so the float is visible, a nose
	var mesh := CapsuleMesh.new()
	mesh.radius = RADIUS
	mesh.height = HEIGHT - FLOAT
	var mi := MeshInstance3D.new()
	mi.mesh = mesh
	mi.position.y = col.position.y
	add_child(mi)
	_look.append(mi)
	var leg := MeshInstance3D.new()
	var lm := CylinderMesh.new()
	lm.top_radius = 0.06
	lm.bottom_radius = 0.06
	lm.height = FLOAT + 0.2
	leg.mesh = lm
	leg.position.y = (FLOAT + 0.2) * 0.5
	add_child(leg)
	_look.append(leg)
	var nose := MeshInstance3D.new()
	var nm := BoxMesh.new()
	nm.size = Vector3(0.08, 0.08, 0.3)
	nose.mesh = nm
	nose.position = Vector3(0, 1.6, -0.3)
	add_child(nose)
	_look.append(nose)


## The capsule for standing or for crouching: from FLOAT above the feet to the top of the body, as always.
func _set_crouched(low: bool) -> void:
	crouched = low
	var top := CROUCH_HEIGHT if low else HEIGHT
	(_col.shape as CapsuleShape3D).height = top - FLOAT
	_col.position.y = FLOAT + (top - FLOAT) * 0.5
	if _look.size() > 0:
		((_look[0] as MeshInstance3D).mesh as CapsuleMesh).height = top - FLOAT
		_look[0].position.y = _col.position.y


## The study: "After changing capsule size for crouch, test that the standing capsule fits before standing up."
## An overlap test of the standing shape where it would be ("Is this space free" is `intersect_shape`).
func can_stand() -> bool:
	var q := PhysicsShapeQueryParameters3D.new()
	q.shape = _fit
	q.transform = Transform3D(Basis.IDENTITY, global_position + Vector3.UP * (FLOAT + (HEIGHT - FLOAT) * 0.5))
	q.exclude = [get_rid()]
	q.collision_mask = collision_mask
	return get_world_3d().direct_space_state.intersect_shape(q, 1).is_empty()


## Show or hide the plain capsule look (hidden when the character is on the body).
func show_capsule(on: bool) -> void:
	for n in _look:
		n.visible = on


## Ground under a point: a small sphere cast straight down. Returns {hit, y, normal, point}.
## `from_up` is how far above `feet` the cast starts (inside free space), `reach` how far below the feet it looks.
func probe(feet: Vector3, from_up := FLOAT + RADIUS, reach := STEP_DOWN + 0.05) -> Dictionary:
	var space := get_world_3d().direct_space_state
	var q := PhysicsShapeQueryParameters3D.new()
	q.shape = _probe
	q.exclude = [get_rid()]
	q.collision_mask = collision_mask
	var start := feet + Vector3.UP * from_up
	var length := from_up - PROBE_R + reach
	q.transform = Transform3D(Basis.IDENTITY, start)
	q.motion = Vector3.DOWN * length
	var f := space.cast_motion(q)
	if f.is_empty() or f[1] >= 1.0:
		return {"hit": false}
	var y := start.y - length * f[0] - PROBE_R
	q.transform = Transform3D(Basis.IDENTITY, start + Vector3.DOWN * length * f[1])
	q.motion = Vector3.ZERO
	q.margin = 0.02
	var r := space.get_rest_info(q)
	var n: Vector3 = r.get("normal", Vector3.UP)
	if r.has("point"):
		# exact height from the contact itself: the cast's own answer is only good to about a millimetre and
		# changes with the cast length, which made two replays of the same input differ
		y = (r["point"] as Vector3).y + PROBE_R * (n.y - 1.0)
	return {"hit": true, "y": y, "normal": n, "point": r.get("point", Vector3(feet.x, y, feet.z))}


## Too steep to stand on? Only when the ground really is a slope: an edge of a step also gives a tilted normal,
## so two more probes up and down the slope must agree with the plane.
func _is_steep(g: Dictionary) -> bool:
	var n: Vector3 = g["normal"]
	var angle := acos(clampf(n.y, -1.0, 1.0))
	if angle <= deg_to_rad(SLOPE_LIMIT_DEG):
		return false
	var down := Vector3(n.x, 0.0, n.z)
	if down.length() < 0.001:
		return false
	# a stair edge: the surface straight under him is level, whatever the rounded probe says of its edge (stairs of
	# 0.18 / 0.28 m lie along a 33 degree line, and taken a step at a time he would be held on them as "too steep")
	var under := _ray_down(Vector3(global_position.x, float(g["y"]), global_position.z))
	if not under.is_empty():
		return acos(clampf((under["normal"] as Vector3).y, -1.0, 1.0)) > deg_to_rad(SLOPE_LIMIT_DEG)
	down = down.normalized()
	var rise := tan(angle) * 0.2
	var feet := Vector3(global_position.x, float(g["y"]), global_position.z)
	var lo := probe(feet + down * 0.2, FLOAT + RADIUS + rise, STEP_DOWN + rise + 0.1)
	var hi := probe(feet - down * 0.2, FLOAT + RADIUS + rise, STEP_DOWN + rise + 0.1)
	if not lo["hit"] or not hi["hit"]:
		return false
	return absf(float(lo["y"]) - (feet.y - rise)) < 0.05 and absf(float(hi["y"]) - (feet.y + rise)) < 0.05


## A traversal move takes the body over (the study: "Switch the body to traversal mode: gravity off, normal collision
## off, body moved only by the clip's root travel"). `path` is asked every tick, with the seconds since the move
## began, for {pos, yaw, clip_t, air, done, exit}; nothing else moves him until it says done.
func begin_move(path: Callable, clip: String) -> void:
	move_path = path
	move_clip = clip
	move_t = 0.0
	move_landed = false
	land_hold = 0.0
	jump_timer = 0.0
	spot_total = 0.0


func in_move() -> bool:
	return move_path.is_valid()


func _run_move(dt: float) -> void:
	move_t += dt
	var r: Dictionary = move_path.call(move_t)
	var was := global_position
	global_position = r["pos"]
	rotation.y = float(r["yaw"])
	move_clip_t = float(r["clip_t"])
	move_landed = bool(r.get("landed", false))
	move_soft = float(r.get("soft", 0.0))
	move_step = r.get("step", [])
	move_hand = r.get("hand", [])
	move_free = bool(r.get("free", false))
	move_landing = String(r.get("landing", "soft"))
	state = State.AIR if bool(r["air"]) else State.GROUND
	var step := global_position - was
	hvel = Vector3(step.x, 0.0, step.z) / dt
	vy = 0.0
	velocity = Vector3.ZERO
	ground_y = global_position.y
	ground_normal = Vector3.UP
	air_time = 0.0
	from_jump = false
	_air_peak = global_position.y
	if bool(r["done"]):
		# "hand the body back to code-driven movement at the clip's exit speed"
		hvel = r["exit"]
		state = State.GROUND
		_stood_y = global_position.y
		_wish_was_moving = false
		move_path = Callable()
		move_step = []
		move_hand = []


func _physics_process(dt: float) -> void:
	var s: Dictionary = tape.call(&"sample") if tape else {}
	if move_path.is_valid():
		# (the stick is read and not obeyed: "cancelling is impossible mid-move")
		_run_move(dt)
		return
	var stick := Vector3(float(s.get("mx", 0.0)), 0.0, float(s.get("mz", 0.0)))
	if stick.length() > 1.0:
		stick = stick.normalized()
	# crouch: held down he crouches (on the ground); let go, he stands as soon as the standing body fits
	var want_low := bool(s.get("crouch", false))
	if want_low and not crouched and state == State.GROUND and jump_timer <= 0.0:
		_set_crouched(true)
	elif crouched and not want_low and can_stand():
		_set_crouched(false)
	_wish = stick.rotated(Vector3.UP, float(s.get("yaw", 0.0))) * (CROUCH_SPEED if crouched else (RUN if bool(s.get("run", false)) else WALK))

	# a way to go that keeps turning (a curve, not a corner) is walked more slowly
	if _wish.length() > 0.05:
		var wy := atan2(_wish.x, _wish.z)
		var step := absf(wrapf(wy - _wish_yaw, -PI, PI)) / dt if _wish_on else 0.0
		# (a corner is one jump of the stick, not a curve: it is left to the turning rule below)
		if step > deg_to_rad(400.0):
			step = 0.0
		_wish_turn += (step - _wish_turn) * (1.0 - exp(-dt / CURVE_TIME))
		_wish_yaw = wy
		_wish_on = true
		if _wish_turn > 0.05 and _wish.length() <= WALK + 0.1:
			_wish = _wish.limit_length(CURVE_PULL_WALK / _wish_turn)
	else:
		_wish_on = false
		_wish_turn = 0.0
	if land_hold > 0.0:
		land_hold -= dt
		_wish = Vector3.ZERO
	_find_stairs(dt)
	if stairs != 0 and _wish.length() > 0.05:
		_wish = _wish.limit_length(_stair_speed(_wish.length() > WALK + 0.1))
	elif state == State.GROUND and _wish.length() > 0.05:
		var running := _wish.length() > WALK + 0.1
		# A gentle downhill carries him along (Yasin, 26 Nov: "going down hill doesn't reward any speed"). Tobler's
		# hiking function, fitted to real walking: speed = 6 e^(-3.5 |slope + 0.05|) km/h, which peaks at 6 km/h on
		# a 2.9 degree descent against 5 km/h on the flat, and is back to flat speed at a 5.7 degree descent.
		if grade < 0.0:
			var gain := exp(-3.5 * absf(grade + 0.05)) / exp(-3.5 * 0.05)
			if gain > 1.0:
				_wish *= gain
		_wish = _wish.limit_length(_slope_speed(running))
	# (Until 26 Nov a slope clip could set his pace here. The study: "It alone decides where the character is ...
	# Animation never pushes it in this mode." Taken out at Yasin's word: "Keep it, body in charge".)
	# The mountaineering sources say "face inwards for steep slopes, but otherwise face out". That was built and
	# Yasin turned it down with the crawl (26 Nov: "we look like a small baby on both up and down"): he comes down
	# facing out, crouched, a hand back on the slope.
	face_in = false

	# jump: a push-off first, then the body leaves the ground
	var jump_now := bool(s.get("jump", false))
	if state == State.GROUND and jump_now and not _jump_held and jump_timer <= 0.0 and not crouched:
		_jump_still = hvel.length() < 2.0
		jump_timer = (JUMP_DIP_STAND + JUMP_PUSH_STAND) if _jump_still else JUMP_PUSH_RUN
		jump_started.emit(jump_timer)
	_jump_held = jump_now
	if jump_timer > 0.0:
		if state != State.GROUND:
			jump_timer = 0.0
		else:
			if _jump_still:
				_wish = Vector3.ZERO
			jump_timer -= dt
			if jump_timer <= 0.0:
				jump_timer = 0.0
				state = State.AIR
				vy = sqrt(2.0 * GRAVITY * (JUMP_RISE if _jump_still else JUMP_RISE_RUN))
				from_jump = true
				air_time = 0.0
				_air_peak = global_position.y
				jumped.emit()

	match state:
		State.GROUND:
			# leaning on a wall: steer along it, so the speed does not flicker between pushing in and sliding
			var wish := _wish
			if _wall != Vector3.ZERO:
				if test_move(global_transform, -_wall * 0.03):
					if wish.dot(_wall) < 0.0:
						wish = wish.slide(_wall)
				else:
					_wall = Vector3.ZERO
			hvel = _steer(hvel, wish, dt)
			_slow_for_rising_ground()
			vy = 0.0
			_move(hvel * dt, true)
		State.STEEP:
			# slide down the slope; the stick cannot hold or climb it, and no speed carries up it
			var n := ground_normal
			var along := (Vector3.DOWN - n * Vector3.DOWN.dot(n)) * GRAVITY
			hvel += Vector3(along.x, 0.0, along.z) * dt
			var uphill := -Vector3(n.x, 0.0, n.z).normalized()
			var up_speed := hvel.dot(uphill)
			if up_speed > 0.0:
				hvel -= uphill * up_speed
			vy = 0.0
			_move(hvel * dt, true)
		_:
			spot_total = 0.0
			# in the air: keep the speed, a little steering, gravity
			hvel += (_wish - hvel) * (1.0 - exp(-dt / 1.5))
			vy = maxf(vy - GRAVITY * dt, -TERMINAL)
			_move(Vector3(hvel.x, vy, hvel.z) * dt, false)
	velocity = Vector3(hvel.x, vy, hvel.z)
	_update_ground(dt)

	if hvel.length() > 0.2 and state == State.GROUND and spot_total == 0.0:
		var want := atan2(hvel.x, hvel.z) if face_in else atan2(-hvel.x, -hvel.z)
		rotation.y = rotate_toward(rotation.y, want, TURN_SPEED * dt)


## Speed and heading on the ground, as the study describes them: speed builds over the first steps and is shed at
## a human braking rate; the heading turns at the rate of a step turn and speed is given up in a sharp turn; a
## near-reversal at a run brakes first.
func _steer(v: Vector3, wish: Vector3, dt: float) -> Vector3:
	var speed := v.length()
	var want := wish.length()
	var fast := clampf((maxf(speed, want) - WALK) / (RUN - WALK), 0.0, 1.0)
	var brake := lerpf(STOP_WALK, STOP_RUN, clampf((speed - WALK) / (RUN - WALK), 0.0, 1.0))
	if want < 0.05:
		spot_total = 0.0
		return v.normalized() * maxf(speed - brake * dt, 0.0) if speed > 0.0001 else Vector3.ZERO
	var wdir := wish / want
	var off := wrapf(atan2(-wdir.x, -wdir.z) - rotation.y, -PI, PI)
	if spot_total != 0.0:
		# turning on the spot, or the plant-and-turn that ends a brake from a run: he turns, and what speed he
		# still has is shed
		if absf(off) > deg_to_rad(SPOT_END_DEG):
			var rate := TURN_RATE_RUN if spot_run else lerpf(TURN_RATE_WALK, TURN_RATE_RUN, fast)
			rotation.y += signf(off) * minf(rate * dt, absf(off))
			spot_left = wrapf(atan2(-wdir.x, -wdir.z) - rotation.y, -PI, PI)
			return v.normalized() * maxf(speed - STOP_RUN * dt, 0.0) if speed > 0.0001 else Vector3.ZERO
		spot_total = 0.0
		if spot_run and want > WALK + 0.1:
			# out of the plant-and-turn he is running again, the new way (Yasin, 26 Nov: "dont play start running
			# after 180 running turn, just continue the running animation"): he comes out at the slowest running
			# the study measured ("Runners on a treadmill at 2.5, 3.5 and 4.5 m/s") and builds up from there
			spot_run = false
			return wdir * RUN_OUT
		if spot_walk and want > 0.05:
			# out of the turn made while walking he is walking again, at the pace of a first step (the study: "A
			# walk reaches about 90 % of its speed on the first step")
			return wdir * minf(want, 0.9 * WALK)
		if speed >= 0.3:
			# (he has planted and turned: what is left of the old way's speed ends here. Left in, it turned him back
			# toward the old way for a tick and the turn began again.)
			return Vector3.ZERO
	if speed < 0.3:
		# from rest (or nearly): turn on the spot first if the way to go is far off his facing
		# (not crouched: there is no clip of turning on the spot in a crouch; he sets off and curves round)
		if absf(off) > deg_to_rad(SPOT_START_DEG) and not crouched:
			spot_total = off
			spot_left = off
			spot_run = false
			spot_walk = false
			return Vector3.ZERO
		# set off in the wanted direction
		speed += (want - speed) * (1.0 - exp(-dt / _start_time(speed, want, fast)))
		return wdir * speed
	var dir := v / speed
	var ang := dir.angle_to(wdir)
	if ang > deg_to_rad(REVERSE_ANGLE_DEG):
		# (Until 26 Nov a run was first braked to REVERSE_SPEED and only then turned. Yasin: "make the 180 run turn
		# immediate, without slowing down first, it makes the hard stop move out of place when we slow down first".
		# The speed is shed while he turns.)
		if speed > REVERSE_SPEED and want <= WALK + 0.1:
			return dir * maxf(speed - brake * dt, 0.0)
		if want > WALK + 0.1:
			# asked to run the other way: plant and turn round, as his Running Turn 180 clip does in 0.67 s
			spot_total = off
			spot_left = off
			spot_run = true
			spot_walk = false
			return dir * speed
		# asked to walk the other way while walking: the same turn on the spot as from standing, and on he walks
		# (Yasin, 26 Nov: "play that same turn 180 while walking too"). Until then he walked round in an arc.
		spot_total = off
		spot_left = off
		spot_run = false
		spot_walk = true
		return dir * speed
	var turn := lerpf(TURN_RATE_WALK, TURN_RATE_RUN, fast) * dt
	if ang > 0.0001:
		var axis := dir.cross(wdir)
		axis = Vector3.UP if axis.length() < 0.0001 else axis.normalized()
		dir = dir.rotated(axis, minf(ang, turn)).normalized()
	# the sharper the turn still to make, the more speed is given up for it
	want *= lerpf(1.0, TURN_SLOW, clampf(ang / deg_to_rad(TURN_SLOW_ANGLE_DEG), 0.0, 1.0))
	if want > speed:
		speed += (want - speed) * (1.0 - exp(-dt / _start_time(speed, want, fast)))
	else:
		speed = maxf(speed - brake * dt, want)
	return dir * speed


## The time constant of gaining speed: quick to nine tenths of the speed asked for, slower over the last tenth.
func _start_time(speed: float, want: float, fast: float) -> float:
	var walk_time := START_TIME_WALK if speed < 0.9 * want else START_TAIL_WALK
	return lerpf(walk_time, START_TIME_RUN, fast)


func _ray_down(at: Vector3) -> Dictionary:
	var q := PhysicsRayQueryParameters3D.create(at + Vector3(0.0, 0.6, 0.0), at - Vector3(0.0, 0.8, 0.0), collision_mask, [get_rid()])
	return get_world_3d().direct_space_state.intersect_ray(q)


## Is he on stairs? Three rays (under him, 0.35 m and 0.70 m ahead) on level surfaces at heights that step the same
## way twice. A kerb is one step, not stairs; a ramp is not level. Step edges are noted as he crosses them.
func _find_stairs(dt: float) -> void:
	var speed := hvel.length()
	var dir := hvel / speed if speed > 0.2 else (_wish.normalized() if _wish.length() > 0.05 else Vector3.ZERO)
	var here := _ray_down(global_position)
	if state == State.GROUND and not here.is_empty() and absf((here["position"] as Vector3).y - ground_y) < 0.05:
		_stood_y = (here["position"] as Vector3).y
	if state != State.GROUND or here.is_empty() or dir == Vector3.ZERO:
		stairs = 0
		_ray_ok = false
		if state != State.GROUND or here.is_empty():
			terrain = 0
			slope_deg = 0.0
		return
	var y := (here["position"] as Vector3).y
	_read_slope(here["normal"], dir)
	_since_edge += speed * dt
	if _ray_ok and absf(y - _ray_y) > 0.06 and (here["normal"] as Vector3).y > 0.98:
		if _since_edge > 0.15 and _since_edge < 0.45 and stairs != 0:
			stair_tread = _since_edge
		_since_edge = 0.0
		stair_edge = global_position
		stair_count += 1
		stair_riser = absf(y - _ray_y)
	_ray_y = y
	_ray_ok = true
	var a := _ray_down(global_position + dir * 0.35)
	var b := _ray_down(global_position + dir * 0.70)
	var way := 0
	if not a.is_empty() and not b.is_empty() and (a["normal"] as Vector3).y > 0.98 and (b["normal"] as Vector3).y > 0.98:
		var d1 := (a["position"] as Vector3).y - y
		var d2 := (b["position"] as Vector3).y - (a["position"] as Vector3).y
		if d1 > 0.08 and d2 > 0.08:
			way = 1
		elif d1 < -0.08 and d2 < -0.08:
			way = -1
		if way != 0 and stairs != way:
			# a first guess at the height of a step, until an edge has been crossed
			stair_riser = absf(d1) if absf(d1) < 0.3 else absf(d1) * 0.5
	if way != 0:
		if stairs != way:
			stair_tread = TREAD
			stair_count = 0
			# where the first edge is: look ahead in small steps, once
			stair_edge = global_position
			var last_y := y
			for i in range(1, 26):
				var r := _ray_down(global_position + dir * (i * 0.02))
				if not r.is_empty() and absf((r["position"] as Vector3).y - last_y) > 0.06:
					stair_edge = global_position + dir * (i * 0.02 - TREAD)
					break
			_since_edge = (global_position - stair_edge).dot(dir)
		stairs = way
		stair_dir = dir
	elif stairs != 0:
		# the stairs have ended when the ground ahead is level with the ground he is on (he has crossed the last
		# edge), or when no edge has come for more than a step. (Waiting a whole step after the top, as it did at
		# first, had him still climbing on the landing: Yasin, 26 Nov.)
		var level_ahead := not a.is_empty() and absf((a["position"] as Vector3).y - y) < 0.03
		if (level_ahead and _since_edge > 0.06) or _since_edge > stair_tread * 1.3:
			stairs = 0


## How steep the ground straight under him is, and which way of going that calls for. (A ray, not the rounded
## probe: the probe reads the edge of a stair as a slope.)
func _read_slope(n: Vector3, dir: Vector3) -> void:
	slope_deg = rad_to_deg(acos(clampf(n.y, -1.0, 1.0)))
	grade = -(n.x * dir.x + n.z * dir.z) / maxf(n.y, 0.01)
	# a degree of slack each way, so he does not flicker between two ways of going on the boundary
	var up_one := 1.0 if terrain < 1 else -1.0
	var up_two := 1.0 if terrain < 2 else -1.0
	terrain = 2 if slope_deg > SLOPE_HANDS_DEG + up_two else (1 if slope_deg > SLOPE_WALK_DEG + up_one else 0)


## The most he asks of himself on sloping ground (m/s along the level): his rate of climb over the slope's rise.
## Downhill a slope counts as one about half as steep.
func _slope_speed(run: bool) -> float:
	var hands := terrain == 2
	var angle := atan(absf(grade))
	if grade < 0.0:
		angle *= DOWN_EASE
	if angle < 0.02:
		return 1000.0
	return (CLIMB_WALK if not run else (CLIMB_HANDS_RUN if hands else CLIMB_RUN)) / tan(angle)


## The most he asks of himself on stairs: one step in the study's step time.
func _stair_speed(run: bool) -> float:
	if stairs > 0:
		return stair_tread / (STEP_TIME_RUN_UP if run else STEP_TIME_UP)
	return stair_tread / (STEP_TIME_RUN_DOWN if run else STEP_TIME_DOWN)


## How far he would still travel if the stick were let go now (the braking above, run forward).
func stop_distance() -> float:
	var speed := hvel.length()
	var d := 0.0
	var dt := 1.0 / float(Engine.physics_ticks_per_second)
	for i in 600:
		if speed <= 0.0:
			break
		speed = maxf(speed - lerpf(STOP_WALK, STOP_RUN, clampf((speed - WALK) / (RUN - WALK), 0.0, 1.0)) * dt, 0.0)
		d += speed * dt
	return d


## Move and slide, done here and not with move_and_slide(): in floating mode that keeps the full speed along a
## wall whatever the angle, and leaves the velocity unchanged. Here both the motion and the velocity lose exactly
## the part that points into the wall. `flat` = on the ground: only the upright part of a surface counts.
func _move(motion: Vector3, flat: bool) -> void:
	_touched = false
	for i in 4:
		if motion.length() < 0.00001:
			break
		var c := move_and_collide(motion)
		if c == null:
			break
		_touched = true
		var n := c.get_normal()
		if flat:
			n = Vector3(n.x, 0.0, n.z)
			if n.length() < 0.2:
				break
			n = n.normalized()
			_wall = n
		motion = c.get_remainder().slide(n)
		if flat:
			motion.y = 0.0
		var v := Vector3(hvel.x, vy, hvel.z)
		if v.dot(n) < 0.0:
			v = v.slide(n)
		hvel = Vector3(v.x, 0.0, v.z)
		if not flat:
			vy = v.y


## The feet can only follow ground that rises at RISE_SPEED or falls at SINK_SPEED. On steep stairs that is slower
## than a run, so slow down to what the feet can follow, as a person does.
func _slow_for_rising_ground() -> void:
	var speed := hvel.length()
	if speed < 0.3:
		return
	var dir := hvel / speed
	var g := probe(global_position + dir * 0.3, FLOAT + RADIUS + 0.3, STEP_DOWN + 0.05)
	if not g["hit"]:
		return
	var rise := float(g["y"]) - maxf(ground_y, global_position.y)
	var cap := 1000.0
	if rise > 0.02 and rise <= FLOAT:
		cap = RISE_SPEED * 0.9 / (rise / 0.3)
	elif rise < -0.02:
		# the same going down: stairs and kerbs, not a ledge (the probe would not have reached)
		cap = SINK_SPEED * 0.9 / (-rise / 0.3)
	if speed > cap:
		hvel = dir * cap


func _update_ground(dt: float) -> void:
	var feet := global_position
	if state == State.GROUND or state == State.STEEP:
		var g := probe(feet)
		if not g["hit"] or float(g["y"]) - feet.y > FLOAT - 0.005:
			if not g["hit"]:
				state = State.AIR
				vy = 0.0
				from_jump = false
				air_time = 0.0
				# The drop is measured from the ledge he stood on, not from where the rounded probe had let him
				# sink to as it rolled over the edge (a 1.10 m ledge used to count as under 1.0 m, and so as a
				# soft landing; the study: "1.0 to 2.0 m, a heavy landing").
				_air_peak = _stood_y if (_stood_y > feet.y and _stood_y - feet.y < STEP_DOWN) else feet.y
			return
		ground_y = float(g["y"])
		ground_normal = g["normal"]
		state = State.STEEP if _is_steep(g) else State.GROUND
		var err := ground_y - feet.y
		if stairs < 0:
			# Going down stairs his height goes down the even line of the flight: by the end of a tread he is as
			# low as the next one, so there is no drop as he crosses the edge. (Until 26 Nov it went by one ray
			# 0.22 m ahead of him. Over the last few centimetres of a tread that ray already sees the step after
			# the next, two risers down, which was refused as a ledge: he was drawn back UP about 5 cm at every
			# step. Measured tick by tick, 26 Nov; Yasin: "looks like systems are fighting over control".)
			var ahead := _ray_down(feet + stair_dir * stair_tread)
			if not ahead.is_empty():
				var drop := ground_y - (ahead["position"] as Vector3).y
				if drop > 0.02 and drop < 0.3:
					err = ground_y - drop * clampf(_since_edge / stair_tread, 0.0, 1.0) - feet.y
		var up := RISE_SPEED
		var down := SINK_SPEED
		if stairs != 0 and stair_riser > 0.0:
			# on stairs his height follows the flight, not each step: a little faster than the flight rises under
			# him at his pace, so a step's height is spread over the whole step instead of taken in a hop (Yasin,
			# 26 Nov: stairs at a walk were "very jittery")
			var follow := maxf(hvel.length() * stair_riser / stair_tread * 1.5, 0.25)
			up = minf(up, follow)
			down = minf(down, follow)
		var dy := minf(err, up * dt) if err > 0.0 else maxf(err, -down * dt)
		if absf(dy) > 0.00001:
			move_and_collide(Vector3(0.0, dy, 0.0))
	else:
		air_time += dt
		_air_peak = maxf(_air_peak, feet.y)
		var fall := maxf(0.02, -vy * dt + 0.01)
		var g := probe(feet, FLOAT + RADIUS, fall)
		if g["hit"] and vy <= 0.0 and feet.y - float(g["y"]) <= fall and float(g["y"]) - feet.y <= FLOAT - 0.005:
			ground_y = float(g["y"])
			ground_normal = g["normal"]
			move_and_collide(Vector3(0.0, ground_y - feet.y, 0.0))
			vy = 0.0
			state = State.STEEP if _is_steep(g) else State.GROUND
			var drop := _air_peak - ground_y
			# after a real drop he gathers himself before moving off (a jump on the level is run out of)
			if not (from_jump and drop < 0.9):
				land_hold = LAND_HOLD_HARD if drop >= HARD_DROP else (LAND_HOLD_SOFT if drop > STEP_DOWN else 0.0)   # the study: "up to 0.30 m, step down in stride"
			landed.emit(drop)
			from_jump = false
		else:
			state = State.UNSUPPORTED if _touched else State.AIR


## While he is in the air: how long until he lands on the ground now under him, and how far he will have dropped by
## then. Empty if there is no ground within reach. For the character, so that the legs can be brought down to meet
## the ground (the study: "Start the landing fold on the contact frame").
func landing_ahead() -> Dictionary:
	var q := PhysicsRayQueryParameters3D.create(global_position + Vector3(0.0, 0.3, 0.0), global_position - Vector3(0.0, 6.0, 0.0), collision_mask, [get_rid()])
	var hit := get_world_3d().direct_space_state.intersect_ray(q)
	if hit.is_empty():
		return {}
	var y := (hit["position"] as Vector3).y
	var d := maxf(global_position.y - y, 0.0)
	var down := -vy
	return {"time": (-down + sqrt(maxf(down * down + 2.0 * GRAVITY * d, 0.0))) / GRAVITY, "drop": _air_peak - y}


func get_readout() -> Dictionary:
	return {"state": STATE_NAMES[state], "speed": hvel.length(), "height": global_position.y,
			"note": "ground %.3f m   slope %.0f deg" % [ground_y, rad_to_deg(acos(clampf(ground_normal.y, -1.0, 1.0)))]}


## Put the body somewhere by hand (teleport, test set-up).
func place(at: Vector3) -> void:
	global_position = at
	hvel = Vector3.ZERO
	vy = 0.0
	velocity = Vector3.ZERO
	jump_timer = 0.0
	from_jump = false
	air_time = 0.0
	_air_peak = at.y
	_stood_y = at.y
	state = State.AIR
