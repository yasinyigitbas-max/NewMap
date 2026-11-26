extends SkeletonModifier3D
## Stage 4, the feet (the study: "Build: pelvis offset and leg IK from foot probes"). The first of the corrections in
## the study's order: "a pelvis height offset (custom), leg `TwoBoneIK3D`, ...". Each tick it reads the pose the
## AnimationTree has just made and, for each foot:
##   1. a foot the clip has on the ground is held where it came down until the clip lifts it (no skating);
##   2. the foot is raised or lowered to the ground really under it, and tilted to it;
##   3. the hips come down just far enough for a planted foot to reach.
## It moves only the hips. The legs are then solved by Godot's TwoBoneIK3D (the next modifier) toward the targets set
## here, with the knee pointed the way the clip had it, and foot_orient.gd (after that) turns the feet.
## The study's bar: no foot inside or above its surface by more than about 2 cm; a planted foot drifts under 2 cm.

const CONTACT := 0.025          # OURS: the ball of the foot this close to the clip's floor counts as on the ground (m)
const PLANT_SHARE := 0.45       # NOT in the study: a low foot is planted while it moves over the ground slower than this
const PLANT_LEAST := 0.5        # share of the body's speed, or than this (m/s)
const HOLD_SHARE := 1.1         # NOT in the study: once planted it is let go only when it clearly moves off
const HOLD_LEAST := 1.2
const PIN_MOST := 0.10          # NOT in the study: a planted foot is let slide once it is this far from where the clip wants it (m)
const LET_GO := 0.10            # NOT in the study: seconds for a lifted foot to return to the clip's own path
const REACH := 0.45             # how far above or below the body's ground a foot looks for its own ground (m)
const FOOT_SPEED := 5.0         # NOT in the study: m/s a foot follows a jump in the height of its ground (a stair edge)
const HIPS_DOWN := 1.5          # NOT in the study: m/s the hips may come down for a planted foot to reach
const HIPS_TIME := 0.10         # NOT in the study: seconds for the hips to come back up
const HIPS_MOST := 0.25         # NOT in the study: the most the hips come down (m)
const TILT_MOST := 0.35         # radians (20 deg): the foot tilts to the ground this far: the study's ankle "goes from 10
                                # degrees up to 20 degrees down" in walking, and its steepest streets are 19 degrees
const NEAR := 0.10              # OURS: the tilt fades out as the foot rises this far off the ground (m)
const STRAIGHT := 0.995         # the leg is never asked to be longer than this share of its length: the study's
                                # "never let the target be further than the limb's length minus a small margin"
const WEIGHT_TIME := 0.12       # NOT in the study: seconds to fade the fitting in on landing and out on leaving the ground

var body: CharacterBody3D
var target: Array[Node3D] = []      # where each ankle should be: read by the leg IK
var pole: Array[Node3D] = []        # which way each knee points
var goal := [Basis.IDENTITY, Basis.IDENTITY]       # each foot's wanted orientation, skeleton space: read by foot_orient.gd
var weight := 0.0               # 0 = the clip alone (in the air), 1 = feet fitted
var clip_slope := 0.0           # a stair clip stands on its own stairs: their rise per metre forward (0 for a flat clip)
var pinning := true
var grounding := true

var _hips := -1
var _thigh := [-1, -1]
var _shin := [-1, -1]
var _foot := [-1, -1]
var _toe := [-1, -1]
var _leg_len := [0.0, 0.0]
var _toe_rest := 0.0
var _ankle_rest := 0.0
var _planted := [false, false]
var _pin := [Vector3.ZERO, Vector3.ZERO]
var _corr := [Vector3.ZERO, Vector3.ZERO]
var _was := [Vector3.ZERO, Vector3.ZERO]
var _was_ok := false
var _g := [0.0, 0.0]
var _g_ok := false
var _pelvis := 0.0


func bind(sk: Skeleton3D) -> void:
	_hips = sk.find_bone("mixamorig_Hips")
	var side := ["Left", "Right"]
	for f in 2:
		_thigh[f] = sk.find_bone("mixamorig_%sUpLeg" % side[f])
		_shin[f] = sk.find_bone("mixamorig_%sLeg" % side[f])
		_foot[f] = sk.find_bone("mixamorig_%sFoot" % side[f])
		_toe[f] = sk.find_bone("mixamorig_%sToeBase" % side[f])
		_leg_len[f] = sk.get_bone_rest(_shin[f]).origin.length() + sk.get_bone_rest(_foot[f]).origin.length()
	_toe_rest = sk.get_bone_global_rest(_toe[0]).origin.y
	_ankle_rest = sk.get_bone_global_rest(_foot[0]).origin.y


func _ground(at: Vector3, feet_y: float) -> Dictionary:
	var q := PhysicsRayQueryParameters3D.create(Vector3(at.x, feet_y + REACH, at.z), Vector3(at.x, feet_y - REACH, at.z), body.collision_mask, [body.get_rid()])
	return body.get_world_3d().direct_space_state.intersect_ray(q)


func _process_modification_with_delta(dt: float) -> void:
	var sk := get_skeleton()
	if sk == null or body == null or _hips < 0 or target.size() < 2:
		return
	var on_ground := int(body.get(&"state")) == 0
	weight = move_toward(weight, 1.0 if on_ground else 0.0, dt / WEIGHT_TIME)
	var xf := sk.global_transform
	var inv := xf.affine_inverse()
	var feet_y := body.global_position.y
	var pace := (body.get(&"hvel") as Vector3).length()
	var let_go := 1.0 - exp(-dt / LET_GO)
	var want_pelvis := 0.0
	var ankle_goal := [Vector3.ZERO, Vector3.ZERO]
	var hip_at := [Vector3.ZERO, Vector3.ZERO]
	var knee_at := [Vector3.ZERO, Vector3.ZERO]
	for f in 2:
		var hip_t := sk.get_bone_global_pose(_thigh[f])
		var knee_t := sk.get_bone_global_pose(_shin[f])
		var ankle_t := sk.get_bone_global_pose(_foot[f])
		var ball_t := sk.get_bone_global_pose(_toe[f])
		var hip: Vector3 = xf * hip_t.origin
		var ankle: Vector3 = xf * ankle_t.origin
		var ball: Vector3 = xf * ball_t.origin
		var basis := (xf.basis * ankle_t.basis).orthonormalized()
		hip_at[f] = hip
		knee_at[f] = knee_t.origin
		# planted = the clip has the ball of the foot on its own floor, and not travelling over the ground
		# (how high the clip holds the ball of the foot over its OWN ground: a flat floor, or its own stairs)
		var ball_h := ball_t.origin.y - clip_slope * ball_t.origin.z
		var low: bool = on_ground and ball_h < _toe_rest + CONTACT
		var over := (Vector2(ball.x - (_was[f] as Vector3).x, ball.z - (_was[f] as Vector3).z).length() / dt) if _was_ok else 0.0
		_was[f] = ball
		var slow := over < (maxf(HOLD_LEAST, pace * HOLD_SHARE) if _planted[f] else maxf(PLANT_LEAST, pace * PLANT_SHARE))
		var planted: bool = low and slow
		# 1. a planted foot stays where it came down
		if planted and pinning:
			var flat := Vector3(ball.x, 0.0, ball.z)
			if not _planted[f]:
				_pin[f] = flat + _corr[f]
			var c: Vector3 = _pin[f] - flat
			if c.length() > PIN_MOST:
				c = c.normalized() * PIN_MOST
				_pin[f] = flat + c
			_corr[f] = c
		else:
			_corr[f] = (_corr[f] as Vector3) * (1.0 - let_go)
		_planted[f] = planted
		ball += _corr[f]
		ankle += _corr[f]
		# 2. the ground under this foot: the same height above it as the clip holds the foot above its own floor
		var want_g := feet_y
		var normal := Vector3.UP
		if grounding and on_ground:
			var gb := _ground(ball, feet_y)
			var ga := _ground(ankle, feet_y)
			if not gb.is_empty():
				want_g = (gb["position"] as Vector3).y
				normal = gb["normal"]
				# a step: level ground at two heights under the one foot. It stands on the higher.
				if not ga.is_empty() and normal.y > 0.98 and (ga["normal"] as Vector3).y > 0.98:
					want_g = maxf(want_g, (ga["position"] as Vector3).y)
			elif not ga.is_empty():
				want_g = (ga["position"] as Vector3).y
				normal = ga["normal"]
		if not _g_ok or not on_ground:
			_g[f] = want_g
		_g[f] = move_toward(_g[f], want_g, FOOT_SPEED * dt)
		var lift := clampf(float(_g[f]) - feet_y, -REACH, REACH) - clip_slope * ball_t.origin.z
		# tilt the foot to the ground, about the ball of the foot, the more the nearer it is to the ground
		var near := clampf(1.0 - (ball_h - _toe_rest) / NEAR, 0.0, 1.0)
		var axis := Vector3.UP.cross(normal)
		var tilt := Basis.IDENTITY
		if axis.length() > 0.001 and near > 0.0:
			tilt = Basis(axis.normalized(), minf(Vector3.UP.angle_to(normal), TILT_MOST) * near)
		var ball_goal := ball + Vector3(0.0, lift, 0.0)
		# (nor the ball of the foot: a swinging toe that dips under the clip's own floor is kept on top of the ground)
		if grounding and on_ground:
			var gt := _ground(ball_goal, feet_y)
			if not gt.is_empty() and (gt["normal"] as Vector3).y > 0.3:
				var off_t := (ball_goal - (gt["position"] as Vector3)).dot(gt["normal"])
				if off_t < _toe_rest:
					ball_goal.y += (_toe_rest - off_t) / (gt["normal"] as Vector3).y
		ankle_goal[f] = ball_goal + tilt * (ankle - ball)
		# the heel never goes into the ground: a clip that lets its heel sink under its own floor as it lands (the
		# walk and the runs do, by 3 to 5 cm) has the whole foot raised by what the ankle is short of its standing
		# height over the ground under it (the study: "no foot inside or floating above it by more than about 2 cm")
		if grounding and on_ground:
			var gh := _ground(ankle_goal[f], feet_y)
			if not gh.is_empty() and (gh["normal"] as Vector3).y > 0.3:
				var off := ((ankle_goal[f] as Vector3) - (gh["position"] as Vector3)).dot(gh["normal"])
				if off < _ankle_rest:
					ankle_goal[f] = (ankle_goal[f] as Vector3) + Vector3(0.0, (_ankle_rest - off) / (gh["normal"] as Vector3).y, 0.0)
		goal[f] = (xf.basis.orthonormalized().inverse() * (tilt * basis)).orthonormalized()
		# 3. can the leg reach it? If not, the hips come down (for a planted foot)
		var flat_gap := Vector2((ankle_goal[f] as Vector3).x - hip.x, (ankle_goal[f] as Vector3).z - hip.z).length()
		var most: float = float(_leg_len[f]) * STRAIGHT
		if planted and flat_gap < most:
			want_pelvis = minf(want_pelvis, sqrt(most * most - flat_gap * flat_gap) - (hip.y - (ankle_goal[f] as Vector3).y))
	_was_ok = true
	_g_ok = true
	want_pelvis = maxf(want_pelvis, -HIPS_MOST) if on_ground else 0.0
	if want_pelvis < _pelvis:
		_pelvis = maxf(want_pelvis, _pelvis - HIPS_DOWN * dt)
	else:
		_pelvis += (want_pelvis - _pelvis) * (1.0 - exp(-dt / HIPS_TIME))
	# the pelvis offset: the only bone this modifier moves (the skeleton applies `influence` to it)
	var hips_t := sk.get_bone_global_pose(_hips)
	hips_t.origin.y += _pelvis
	sk.set_bone_global_pose(_hips, hips_t)
	for f in 2:
		# a target never further than the leg can reach from where the hip now is
		var hip: Vector3 = (hip_at[f] as Vector3) + Vector3(0.0, _pelvis, 0.0)
		var to: Vector3 = (ankle_goal[f] as Vector3) - hip
		var most: float = float(_leg_len[f]) * STRAIGHT
		if to.length() > most:
			to = to.normalized() * most
		target[f].position = inv * (hip + to)
		# The knee keeps the side the clip bent it to, measured against the line from hip to ankle AS IT NOW IS: the
		# pole stands off the middle of that line, square to it (the study: "place the pole target in front of the
		# knee"). Taken against the clip's own line instead, a foot lifted high onto a step bent the knee backwards.
		var hip_s: Vector3 = inv * (hip_at[f] as Vector3)
		var ankle_s := sk.get_bone_global_pose(_foot[f]).origin
		var knee_s: Vector3 = knee_at[f]
		var bend := knee_s - (hip_s + ankle_s) * 0.5
		if bend.length() < 0.01:
			bend = sk.get_bone_global_pose(_thigh[f]).basis * Vector3(0.0, 0.0, 1.0)
		bend = bend.normalized()
		var hip_now: Vector3 = inv * hip
		var ankle_now: Vector3 = target[f].position
		var line := (ankle_now - hip_now).normalized()
		var square := bend - line * bend.dot(line)
		if square.length() < 0.25:
			# the clip's knee direction lies along the new line (a foot far ahead): the knee goes up and forward
			var fwd := sk.get_bone_global_pose(_hips).basis * Vector3(0.0, 0.0, 1.0)
			var lead := (fwd + Vector3.UP).normalized()
			square = lead - line * lead.dot(line)
		pole[f].position = (hip_now + ankle_now) * 0.5 + square.normalized() * 0.6
