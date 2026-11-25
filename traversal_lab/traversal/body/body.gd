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
const SLOPE_LIMIT_DEG := 28.0   # steeper ground cannot be stood on
# Speeds and how they change come from the movement study (reports/Hybrid character traversal study.md, Part 1
# "Turning, starting, stopping" and Part 3), not from feel. Each line says which finding it follows.
const WALK := 1.4               # comfortable walking is 1.3 to 1.45 m/s
const RUN := 4.5                # running was measured at 2.5 to 4.5 m/s
const START_TIME_WALK := 0.24   # "about 90 % of its speed on the first step" (a step is about 0.55 s), steady by the third
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
const REVERSE_ANGLE_DEG := 135.0  # asked to go nearly the opposite way at a run: "a sudden turn starts with a braking
                                # action like a rapid stop" - brake to REVERSE_SPEED first, then turn round
# Turning on the spot before setting off (Stage 5): "turning 180 degrees on the spot takes about 3 to 4 steps", and
# his turn clips do it without travelling. From rest, a direction more than SPOT_START off his facing is turned to
# first, at the turn rates above; he sets off when within SPOT_END.
const SPOT_START_DEG := 60.0    # NOT in the study: below this he just sets off and curves; a value to tune by eye
const SPOT_END_DEG := 15.0      # NOT in the study
# Stairs are their own movement: "stairs are climbed at about half a second per step: 0.51 s up and 0.47 s down".
# The running figures are his own clips: Running Up Stairs takes 0.30 s a step, Run Down Stairs 0.20 s.
const STEP_TIME_UP := 0.51
const STEP_TIME_DOWN := 0.47
const STEP_TIME_RUN_UP := 0.30
const STEP_TIME_RUN_DOWN := 0.20
const TREAD := 0.28             # a tread is at least 0.28 m (US accessible); used until the stairs have been measured
const REVERSE_SPEED := 2.0      # NOT in the study: the speed he may carry into the turn-round; a value to tune by eye
const RISE_SPEED := 2.4         # how fast the feet follow ground that rises (m/s): 4 cm a tick
const SINK_SPEED := 3.0         # and ground that falls away
const GRAVITY := 9.8
const TERMINAL := 50.0
const TURN_SPEED := 12.0        # radians a second
const JUMP_RISE := 0.45         # an average standing jump raises the body 0.41 to 0.50 m
const JUMP_PUSH_STAND := 0.30   # the push-off of a standing jump takes 0.30 s (the slower dip before it is left out)
const JUMP_PUSH_RUN := 0.10     # from a run the take-off comes off the stride: the Running Jump clip leaves at 0.10 s

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
var stairs := 0                 # +1 going up stairs, -1 going down, 0 not on stairs
var stair_tread := TREAD        # the depth of a step, measured from the last two edges crossed
var stair_edge := Vector3.ZERO  # where the last step edge was crossed
var stair_dir := Vector3.ZERO   # the way along the stairs
var stair_count := 0            # step edges crossed on these stairs
var _ray_y := 0.0
var _ray_ok := false
var _since_edge := 99.0
var spot_total := 0.0           # the on-the-spot turn being made (radians, + = to his left); 0 = none
var spot_left := 0.0            # how much of it is still to turn


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
	if not under.is_empty() and acos(clampf((under["normal"] as Vector3).y, -1.0, 1.0)) <= deg_to_rad(SLOPE_LIMIT_DEG):
		return false
	down = down.normalized()
	var rise := tan(angle) * 0.2
	var feet := Vector3(global_position.x, float(g["y"]), global_position.z)
	var lo := probe(feet + down * 0.2, FLOAT + RADIUS + rise, STEP_DOWN + rise + 0.1)
	var hi := probe(feet - down * 0.2, FLOAT + RADIUS + rise, STEP_DOWN + rise + 0.1)
	if not lo["hit"] or not hi["hit"]:
		return false
	return absf(float(lo["y"]) - (feet.y - rise)) < 0.05 and absf(float(hi["y"]) - (feet.y + rise)) < 0.05


func _physics_process(dt: float) -> void:
	var s: Dictionary = tape.call(&"sample") if tape else {}
	var stick := Vector3(float(s.get("mx", 0.0)), 0.0, float(s.get("mz", 0.0)))
	if stick.length() > 1.0:
		stick = stick.normalized()
	_wish = stick.rotated(Vector3.UP, float(s.get("yaw", 0.0))) * (RUN if bool(s.get("run", false)) else WALK)

	_find_stairs(dt)
	if stairs != 0 and _wish.length() > 0.05:
		_wish = _wish.limit_length(_stair_speed(_wish.length() > WALK + 0.1))

	# jump: a push-off first, then the body leaves the ground
	var jump_now := bool(s.get("jump", false))
	if state == State.GROUND and jump_now and not _jump_held and jump_timer <= 0.0:
		_jump_still = hvel.length() < 2.0
		jump_timer = JUMP_PUSH_STAND if _jump_still else JUMP_PUSH_RUN
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
				vy = sqrt(2.0 * GRAVITY * JUMP_RISE)
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

	if hvel.length() > 0.2 and state == State.GROUND:
		var want := atan2(-hvel.x, -hvel.z)
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
	if speed < 0.3:
		# from rest (or nearly): turn on the spot first if the way to go is far off his facing
		var off := wrapf(atan2(-wdir.x, -wdir.z) - rotation.y, -PI, PI)
		if spot_total == 0.0 and absf(off) > deg_to_rad(SPOT_START_DEG):
			spot_total = off
		if spot_total != 0.0:
			if absf(off) > deg_to_rad(SPOT_END_DEG):
				rotation.y += signf(off) * minf(lerpf(TURN_RATE_WALK, TURN_RATE_RUN, fast) * dt, absf(off))
				spot_left = wrapf(atan2(-wdir.x, -wdir.z) - rotation.y, -PI, PI)
				return Vector3.ZERO
			spot_total = 0.0
		# from rest (or nearly): set off in the wanted direction
		speed += (want - speed) * (1.0 - exp(-dt / lerpf(START_TIME_WALK, START_TIME_RUN, fast)))
		return wdir * speed
	var dir := v / speed
	var ang := dir.angle_to(wdir)
	if ang > deg_to_rad(REVERSE_ANGLE_DEG) and speed > REVERSE_SPEED:
		return dir * maxf(speed - brake * dt, 0.0)
	var turn := lerpf(TURN_RATE_WALK, TURN_RATE_RUN, fast) * dt
	if ang > 0.0001:
		var axis := dir.cross(wdir)
		axis = Vector3.UP if axis.length() < 0.0001 else axis.normalized()
		dir = dir.rotated(axis, minf(ang, turn)).normalized()
	# the sharper the turn still to make, the more speed is given up for it
	want *= lerpf(1.0, TURN_SLOW, clampf(ang / deg_to_rad(TURN_SLOW_ANGLE_DEG), 0.0, 1.0))
	if want > speed:
		speed += (want - speed) * (1.0 - exp(-dt / lerpf(START_TIME_WALK, START_TIME_RUN, fast)))
	else:
		speed = maxf(speed - brake * dt, want)
	return dir * speed


func _ray_down(at: Vector3) -> Dictionary:
	var q := PhysicsRayQueryParameters3D.create(at + Vector3(0.0, 0.6, 0.0), at - Vector3(0.0, 0.8, 0.0), collision_mask, [get_rid()])
	return get_world_3d().direct_space_state.intersect_ray(q)


## Is he on stairs? Three rays (under him, 0.35 m and 0.70 m ahead) on level surfaces at heights that step the same
## way twice. A kerb is one step, not stairs; a ramp is not level. Step edges are noted as he crosses them.
func _find_stairs(dt: float) -> void:
	var speed := hvel.length()
	var dir := hvel / speed if speed > 0.2 else (_wish.normalized() if _wish.length() > 0.05 else Vector3.ZERO)
	var here := _ray_down(global_position)
	if state != State.GROUND or here.is_empty() or dir == Vector3.ZERO:
		stairs = 0
		_ray_ok = false
		return
	var y := (here["position"] as Vector3).y
	_since_edge += speed * dt
	if _ray_ok and absf(y - _ray_y) > 0.06 and (here["normal"] as Vector3).y > 0.98:
		if _since_edge > 0.15 and _since_edge < 0.45 and stairs != 0:
			stair_tread = _since_edge
		_since_edge = 0.0
		stair_edge = global_position
		stair_count += 1
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
	elif stairs != 0 and _since_edge > stair_tread * 1.3:
		stairs = 0       # no edge for more than a step: the stairs have ended


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
				_air_peak = feet.y
			return
		ground_y = float(g["y"])
		ground_normal = g["normal"]
		state = State.STEEP if _is_steep(g) else State.GROUND
		var err := ground_y - feet.y
		var dy := minf(err, RISE_SPEED * dt) if err > 0.0 else maxf(err, -SINK_SPEED * dt)
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
			landed.emit(_air_peak - ground_y)
			from_jump = false
		else:
			state = State.UNSUPPORTED if _touched else State.AIR


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
	state = State.AIR
