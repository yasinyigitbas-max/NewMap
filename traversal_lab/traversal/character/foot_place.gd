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
const SAME_STEP := 0.10         # OURS: a foothold foreseen this near the last one foreseen is the same step (m)
const WEIGHT_TIME := 0.12       # NOT in the study: seconds to fade the fitting in on landing and out on leaving the ground

var body: CharacterBody3D
var target: Array[Node3D] = []      # where each ankle should be: read by the leg IK
var pole: Array[Node3D] = []        # which way each knee points
var goal := [Basis.IDENTITY, Basis.IDENTITY]       # each foot's wanted orientation, skeleton space: read by foot_orient.gd
var weight := 0.0               # 0 = the clip alone (in the air), 1 = feet fitted
var clip_slope := 0.0           # a stair clip stands on its own stairs: their rise per metre forward (0 for a flat clip)
# On stairs (set by character.gd, which knows the stride): where the ball of each foot will next come down, so a
# swinging foot can be carried evenly from the step it left to the step it is going to.
var stride_fit := false
var stride_dir := Vector3.ZERO
var land_at: Array[Vector3] = [Vector3.ZERO, Vector3.ZERO]
# A generated take of steep ground does not walk an even slope: the ground it imagines under each footfall is higher
# here and lower there (measured 26 Nov: from 0.24 m under the even slope to 0.23 m over it). For such a take a foot
# counts as down when it is not travelling over the ground, however high the take holds it, and is then put ON the
# ground; it keeps that correction through its swing and eases to the next one where it next comes down.
var by_speed := false
var stand_wide := 0.0           # each foot is set this far out to its own side (m): see character.gd, STAND_WIDE
var hands: SkeletonModifier3D   # hand_place.gd, when it is there: how far the hips must come down for the hands
# A clip that climbs onto something stands on its own step: `step_high` m high, its edge `step_edge` m ahead of him
# now, and `step_rise` m of the climb already made by the body (see build_library.gd, RISE). 0 = a flat clip.
var step_high := 0.0
var step_edge := 0.0
var step_rise := 0.0
var step_real := 0.0            # the height of the real thing he is stepping onto (m)
var base := 0.0                 # a climb: the take's own ground is this far above the body's own level (m): the feet are
                                # fitted to the real ground against THAT, not against where the body is on its way up
const STEP_SOFT := 0.15         # NOT in the study: the clip's own step is taken as a ramp this long at its edge (m), so
                                # that a foot crossing the edge is not thrown by it
var hips_fit := 0.0             # the hips' height put right for a clip made on steeper or shallower ground (m; see character.gd)
# Standing still with a foot over nothing (Yasin, 26 Nov: "standing idle on the walls or beams feet dont stand on the
# wall": the standing take sets his feet 0.28 m apart, wider than a beam or a wall top, and each stood in the air
# beside it). The study: "the careful walk with the feet narrowed and arms raised by IK for beams". A standing foot
# whose outer side has no ground under it is brought sideways onto what he stands on, just inside its edge (on
# something narrower than his shoe, onto its middle); two feet brought onto one line are set one before the other.
var stand_on := 0.0             # 0 to 1: he is standing still on the ground (set by character.gd)
const SHOE_HALF := 0.05         # NOT in the study, mine: half the width of his shoe (m)
const SHOE_EDGE := 0.04         # NOT in the study, mine: this much of it, each side of its middle, is to have ground under it (m)
const SHOE_LONG := 0.27         # NOT in the study, mine: the length of his shoe (m)
const IN_TIME := 0.15           # NOT in the study, mine: seconds for a foot to be brought in, and let back out
var _in := [Vector3.ZERO, Vector3.ZERO]
# Going sideways through a gap between walls (stage 18) his feet point across it, and the side-step take sets them
# up to 0.24 m off his middle line: in a gap of 0.25 to 0.45 m that is in the wall. Each foot is brought across so
# that its ankle and the ball of it are both inside the gap, SHOE_CLEAR off each wall (in a gap too tight for that,
# onto its middle). The study: "build them from clips you have plus procedure".
var gap_fit := 0.0              # 0 to 1: he is going sideways through a gap (set by character.gd)
const SHOE_CLEAR := 0.04        # NOT in the study, mine: the ankle joint and the ball of the foot are kept this far off each wall (m)
var _gap_in := [Vector3.ZERO, Vector3.ZERO]
# On a ledge with a wall behind (the sidle of stage 17) he stands with his heels to the wall: each ankle joint is set
# HEEL_OFF out from the wall, the toes over the edge where the ledge is shorter than his shoe.
var ledge_fit := 0.0            # 0 to 1: he is on such a ledge (set by character.gd)
const BACK_OFF := 0.13          # NOT in the study, mine: and his hip joints no nearer the wall than this (m): his back on it, not in it
var _hips_out := Vector3.ZERO
const HEEL_OFF := 0.07          # NOT in the study, mine: the ankle joint this far out from the wall (m): his heel just clear of it
var pinning := true
var grounding := true

var _hips := -1
var _thigh := [-1, -1]
var _shin := [-1, -1]
var _foot := [-1, -1]
var _toe := [-1, -1]
var _leg_len := [0.0, 0.0]
var _front := [1.0, 1.0]
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
var _swing := [0.0, 0.0]        # 0 = the foot goes by the ground under it, 1 = by the line from step to step
var _hold_p := [Vector3.ZERO, Vector3.ZERO]     # where the ball of the foot stands (while planted), and its ground
var _hold_g := [0.0, 0.0]
var _from_p := [Vector3.ZERO, Vector3.ZERO]     # the foothold it last left
var _from_g := [0.0, 0.0]
var _to_p := [Vector3.ZERO, Vector3.ZERO]       # the foothold it is going to
var _to_g := [0.0, 0.0]
var _lump := [0.0, 0.0]         # what the take's own ground is out by under this foot (m)
var _bound := [false, false]    # the swinging foot has a foothold to go to
var _ride := 0.0                # how far the body's own height is off the line through his footholds (m)


func bind(sk: Skeleton3D) -> void:
	_hips = sk.find_bone("mixamorig_Hips")
	var side := ["Left", "Right"]
	for f in 2:
		_thigh[f] = sk.find_bone("mixamorig_%sUpLeg" % side[f])
		_shin[f] = sk.find_bone("mixamorig_%sLeg" % side[f])
		_foot[f] = sk.find_bone("mixamorig_%sFoot" % side[f])
		_toe[f] = sk.find_bone("mixamorig_%sToeBase" % side[f])
		_leg_len[f] = sk.get_bone_rest(_shin[f]).origin.length() + sk.get_bone_rest(_foot[f]).origin.length()
		# which way round the thigh's side-to-side line gives "in front of the knee", from the standing pose
		var side_rest := sk.get_bone_global_rest(_thigh[f]).basis.x.normalized()
		var down_rest := (sk.get_bone_global_rest(_foot[f]).origin - sk.get_bone_global_rest(_thigh[f]).origin).normalized()
		_front[f] = 1.0 if side_rest.cross(down_rest).z > 0.0 else -1.0
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
	if on_ground and body.has_method(&"in_move") and bool(body.call(&"in_move")) and bool(body.get(&"move_landed")):
		# coming down in a traversal move the ground is known beforehand: the feet are on it from the tick he lands
		# (faded in over WEIGHT_TIME, they stood up to 5 cm in the ground for the first tenth of a second)
		weight = 1.0
	var xf := sk.global_transform
	var inv := xf.affine_inverse()
	var feet_y := body.global_position.y + base
	var pace := (body.get(&"hvel") as Vector3).length()
	var let_go := 1.0 - exp(-dt / LET_GO)
	var want_pelvis := 0.0
	var ankle_goal := [Vector3.ZERO, Vector3.ZERO]
	var hip_at := [Vector3.ZERO, Vector3.ZERO]
	var hinge_at := [Vector3.ZERO, Vector3.ZERO]
	var want_in := [Vector3.ZERO, Vector3.ZERO]
	if stand_on > 0.0 and on_ground and grounding:
		want_in = _onto(sk, xf, feet_y)
	for f in 2:
		_in[f] = (_in[f] as Vector3).lerp((want_in[f] as Vector3) * stand_on, 1.0 - exp(-dt / IN_TIME))
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
		hinge_at[f] = hip_t.basis.x.normalized()
		# planted = the clip has the ball of the foot on its own floor, and not travelling over the ground
		# (how high the clip holds the ball of the foot over its OWN ground: a flat floor, or its own stairs)
		# (the clip's own floor under this foot, for a clip that climbs onto a step)
		var own_floor := 0.0
		if step_high != 0.0:
			own_floor = step_high * smoothstep(step_edge - STEP_SOFT, step_edge, ball_t.origin.z) - step_rise
		var ball_h := ball_t.origin.y - clip_slope * ball_t.origin.z - own_floor
		var low: bool = on_ground and (by_speed or ball_h < _toe_rest + CONTACT)
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
		var was_planted: bool = _planted[f]
		_planted[f] = planted
		ball += _corr[f]
		ankle += _corr[f]
		if stand_wide != 0.0:
			var side := xf.basis.x.normalized()
			var out := side * (signf((ankle - xf * sk.get_bone_global_pose(_hips).origin).dot(side)) * stand_wide)
			ball += out
			ankle += out
		ball += _in[f]
		ankle += _in[f]
		if gap_fit > 0.0:
			var n: Vector3 = body.get(&"squeeze_across")
			var half := float(body.get(&"squeeze_w")) * 0.5 - SHOE_CLEAR
			var mid_line: Vector3 = body.get(&"squeeze_mid")
			var ca := (ankle - mid_line).dot(n)
			var cb := (ball - mid_line).dot(n)
			var move := 0.0
			if absf(ca - cb) >= 2.0 * half:
				move = -(ca + cb) * 0.5
			else:
				move = clampf(0.0, -half - minf(ca, cb), half - maxf(ca, cb))
			_gap_in[f] = (_gap_in[f] as Vector3).lerp(n * move, 1.0 - exp(-dt / IN_TIME)) if is_finite(half) else Vector3.ZERO
		elif ledge_fit > 0.0:
			var out_n: Vector3 = body.get(&"ledge_out")
			var from_wall := (ankle - (body.get(&"ledge_wall") as Vector3)).dot(out_n)
			_gap_in[f] = (_gap_in[f] as Vector3).lerp(out_n * (HEEL_OFF - from_wall), 1.0 - exp(-dt / IN_TIME))
		else:
			_gap_in[f] = (_gap_in[f] as Vector3) * exp(-dt / IN_TIME)
		var fit_w := maxf(gap_fit, ledge_fit)
		ball += (_gap_in[f] as Vector3) * (fit_w if fit_w > 0.0 else 1.0)
		ankle += (_gap_in[f] as Vector3) * (fit_w if fit_w > 0.0 else 1.0)
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
		# A foot swinging across stairs passes over step edges, where the ground under it jumps a riser at once:
		# followed, that threw the foot (and the knee) up or down a riser in a tick or two, twice in every swing
		# (measured 26 Nov: 7 to 10 cm in a tick; Yasin: "knees and steps jump"). While it swings, its ground is
		# instead the even line from the foothold it left to the one it is going to; it comes back to the ground
		# really under it as it is planted there, where the two agree.
		var flat_ball := Vector3(ball.x, 0.0, ball.z)
		if planted:
			_hold_p[f] = flat_ball
			_hold_g[f] = _g[f]
		elif stride_fit and on_ground:
			# the foothold it is going to is fixed as it lifts off, and after that only put right by a little: the
			# stride's own count moves on to the step after as this one is due, a moment before the foot is down
			var next := Vector3(land_at[f].x, 0.0, land_at[f].z)
			if was_planted:
				_from_p[f] = _hold_p[f]
				_from_g[f] = _hold_g[f]
				_to_p[f] = next
				_bound[f] = true
			elif _bound[f] and next.distance_to(_to_p[f]) < SAME_STEP:
				_to_p[f] = next
			if _bound[f]:
				var at: Vector3 = _to_p[f]
				var q := PhysicsRayQueryParameters3D.create(Vector3(at.x, feet_y + 2.0 * REACH, at.z), Vector3(at.x, feet_y - 2.0 * REACH, at.z), body.collision_mask, [body.get_rid()])
				var gl := body.get_world_3d().direct_space_state.intersect_ray(q)
				_to_g[f] = (gl["position"] as Vector3).y if not gl.is_empty() else float(_from_g[f])
		if not stride_fit or not on_ground:
			_bound[f] = false
		_swing[f] = move_toward(_swing[f], 1.0 if (_bound[f] and not planted) else 0.0, dt / LET_GO)
		var ground_f: float = _g[f]
		if float(_swing[f]) > 0.0:
			var span: Vector3 = (_to_p[f] as Vector3) - (_from_p[f] as Vector3)
			var u := clampf((flat_ball - (_from_p[f] as Vector3)).dot(span) / maxf(span.length_squared(), 0.0025), 0.0, 1.0)
			ground_f = lerpf(ground_f, lerpf(_from_g[f], _to_g[f], u), _swing[f])
		if by_speed and planted:
			_lump[f] = lerpf(_lump[f], _toe_rest - ball_h, let_go)
		elif not by_speed:
			_lump[f] = lerpf(_lump[f], 0.0, let_go)
		var lift := clampf(ground_f - feet_y, -REACH, REACH) - clip_slope * ball_t.origin.z + float(_lump[f]) - own_floor
		var stepping := step_high != 0.0
		if stepping:
			# In a climbing move both grounds are known: the clip's own step and the real one, crossed at the same
			# point of the foot's path. The foot is fitted from the one to the other by that alone. (Fitted by
			# looking for the ground under it, as everywhere else, the foot was thrown up and down a step's height
			# from tick to tick as it crossed the edge. Yasin, 26 Nov: "stepping onto the edge is jittery".)
			var past := smoothstep(step_edge - STEP_SOFT, step_edge, ball_t.origin.z)
			lift = (step_real - step_high) * (past - step_rise / step_high)
		# tilt the foot to the ground, about the ball of the foot, the more the nearer it is to the ground
		var near := clampf(1.0 - (ball_h + float(_lump[f]) - _toe_rest) / NEAR, 0.0, 1.0)
		var axis := Vector3.UP.cross(normal)
		var tilt := Basis.IDENTITY
		if axis.length() > 0.001 and near > 0.0:
			tilt = Basis(axis.normalized(), minf(Vector3.UP.angle_to(normal), TILT_MOST) * near)
		var ball_goal := ball + Vector3(0.0, lift, 0.0)
		# (nor the ball of the foot: a swinging toe that dips under the clip's own floor is kept on top of the ground)
		if grounding and on_ground and not stepping:
			var gt := _ground(ball_goal, feet_y)
			if not gt.is_empty() and (gt["normal"] as Vector3).y > 0.3:
				var off_t := (ball_goal - (gt["position"] as Vector3)).dot(gt["normal"])
				if off_t < _toe_rest:
					ball_goal.y += (_toe_rest - off_t) / (gt["normal"] as Vector3).y
		ankle_goal[f] = ball_goal + tilt * (ankle - ball)
		# the heel never goes into the ground: a clip that lets its heel sink under its own floor as it lands (the
		# walk and the runs do, by 3 to 5 cm) has the whole foot raised by what the ankle is short of its standing
		# height over the ground under it (the study: "no foot inside or floating above it by more than about 2 cm")
		if grounding and on_ground and not stepping:
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
	# On stairs the hips go by the even line through his footholds, not by the body's own height, which takes each
	# step in a ramp and a rest; and by `hips_fit`. Never higher than a planted foot can reach.
	var off := 0.0
	# (only while both footholds are known: a foot that was in the air as he came onto the stairs has none yet)
	if stride_fit and on_ground and (_planted[0] or _bound[0]) and (_planted[1] or _bound[1]):
		var p := [Vector3.ZERO, Vector3.ZERO]
		var g := [0.0, 0.0]
		for f in 2:
			p[f] = _to_p[f] if (not _planted[f] and _bound[f]) else _hold_p[f]
			g[f] = _to_g[f] if (not _planted[f] and _bound[f]) else _hold_g[f]
		# (measured along the way he is going: the feet stand apart sideways too. The body is often behind both
		# footholds: the line is carried on past them, up to a stride either way)
		var span := ((p[1] as Vector3) - (p[0] as Vector3)).dot(stride_dir)
		var here := Vector3(body.global_position.x, 0.0, body.global_position.z)
		var u := clampf((here - (p[0] as Vector3)).dot(stride_dir) / span, -2.0, 3.0) if absf(span) > 0.05 else 0.5
		off = feet_y - lerpf(g[0], g[1], u)
	_ride += (off - _ride) * (1.0 - exp(-dt / HIPS_TIME))
	var for_hands := float(hands.get(&"hips_down")) if hands else 0.0
	want_pelvis = maxf(minf(want_pelvis, hips_fit - _ride) - for_hands, -HIPS_MOST) if on_ground else 0.0
	if want_pelvis < _pelvis:
		_pelvis = maxf(want_pelvis, _pelvis - HIPS_DOWN * dt)
	else:
		_pelvis += (want_pelvis - _pelvis) * (1.0 - exp(-dt / HIPS_TIME))
	# the pelvis offset: the only bone this modifier moves (the skeleton applies `influence` to it)
	var hips_t := sk.get_bone_global_pose(_hips)
	hips_t.origin.y += _pelvis
	# on a ledge with a wall behind: his hips out from the wall far enough for his back to lie on it
	var want_out := Vector3.ZERO
	if ledge_fit > 0.0:
		var out_n: Vector3 = body.get(&"ledge_out")
		var hips_from := ((xf * hips_t.origin) - (body.get(&"ledge_wall") as Vector3)).dot(out_n)
		want_out = out_n * maxf(BACK_OFF - hips_from, 0.0) * ledge_fit
	_hips_out = _hips_out.lerp(want_out, 1.0 - exp(-dt / IN_TIME))
	hips_t.origin += inv.basis * _hips_out
	sk.set_bone_global_pose(_hips, hips_t)
	for f in 2:
		# a target never further than the leg can reach from where the hip now is
		var hip: Vector3 = (hip_at[f] as Vector3) + Vector3(0.0, _pelvis, 0.0) + _hips_out
		var to: Vector3 = (ankle_goal[f] as Vector3) - hip
		var most: float = float(_leg_len[f]) * STRAIGHT
		if to.length() > most:
			to = to.normalized() * most
		target[f].position = inv * (hip + to)
		# The knee bends about the hinge the clip gives it (the thigh's own side-to-side line), whatever the leg IK
		# does with the foot: the pole stands off the middle of the line from hip to ankle AS IT NOW IS, square to
		# that line and to the hinge, in front of the knee (the study: "place the pole target in front of the
		# knee"). Until 26 Nov the pole was taken from where the clip's knee stood off its own hip-to-ankle line:
		# with the leg nearly straight that is a few millimetres and points anywhere, and the knee swung 12 cm out
		# to the side and snapped back 5 cm in a tick (measured on the stairs; Yasin: "left leg twitch outwards").
		var hip_now: Vector3 = inv * hip
		var ankle_now: Vector3 = target[f].position
		var line := (ankle_now - hip_now).normalized()
		var hinge: Vector3 = hinge_at[f]
		var front := hinge.cross(line) * float(_front[f])
		if front.length() < 0.2:
			# the leg lies along its own hinge (it never should): the knee goes up and forward
			var fwd := sk.get_bone_global_pose(_hips).basis * Vector3(0.0, 0.0, 1.0)
			var lead := (fwd + Vector3.UP).normalized()
			front = lead - line * lead.dot(line)
		pole[f].position = (hip_now + ankle_now) * 0.5 + front.normalized() * 0.6


## How far each standing foot must be brought sideways (and, two feet on one line, along) to stand on what he
## stands on: see `stand_on`. Zero for a foot that has ground under it as it is.
func _onto(sk: Skeleton3D, xf: Transform3D, feet_y: float) -> Array:
	var out := [Vector3.ZERO, Vector3.ZERO]
	var side := body.global_transform.basis.x
	side = Vector3(side.x, 0.0, side.z).normalized()
	var fwd := -body.global_transform.basis.z
	fwd = Vector3(fwd.x, 0.0, fwd.z).normalized()
	var centre := body.global_position
	var mid := [Vector3.ZERO, Vector3.ZERO]
	var any := false
	for f in 2:
		var ankle: Vector3 = xf * sk.get_bone_global_pose(_foot[f]).origin
		var ball: Vector3 = xf * sk.get_bone_global_pose(_toe[f]).origin
		mid[f] = (ankle + ball) * 0.5 + (_corr[f] as Vector3)     # (where it is held, if it is held where it came down)
		if stand_wide != 0.0:
			# (as it will be set out to its own side: see `stand_wide`)
			var sk_side := xf.basis.x.normalized()
			mid[f] = (mid[f] as Vector3) + sk_side * (signf((ankle - xf * sk.get_bone_global_pose(_hips).origin).dot(sk_side)) * stand_wide)
		# its outer side: SHOE_EDGE out from its middle, away from the middle of him
		var lat := ((mid[f] as Vector3) - centre).dot(side)
		var o := side * (signf(lat) if lat != 0.0 else 1.0)
		var outer: Vector3 = (mid[f] as Vector3) + o * SHOE_EDGE
		if not _ground(outer, feet_y).is_empty():
			continue
		var s := 0.01
		var found := false
		while s <= absf(lat) + 0.15 + SHOE_EDGE:
			if not _ground(outer - o * s, feet_y).is_empty():
				found = true
				break
			s += 0.01
		if not found:
			continue
		# how far what he stands on goes on from its edge: on something narrower than his shoe the foot is set on its middle
		var run := 0.0
		while run < 2.0 * SHOE_EDGE and not _ground(outer - o * (s + run + 0.01), feet_y).is_empty():
			run += 0.01
		out[f] = -o * ((s + 0.01) if run >= 2.0 * SHOE_EDGE else (s + run * 0.5 - SHOE_EDGE))
		any = true
	if any:
		var a: Vector3 = (mid[0] as Vector3) + (out[0] as Vector3)
		var b: Vector3 = (mid[1] as Vector3) + (out[1] as Vector3)
		var apart := absf((a - b).dot(side))
		var along := (a - b).dot(fwd)
		var short := SHOE_LONG - absf(along)
		if apart < 2.0 * SHOE_HALF and short > 0.0:
			var push := fwd * ((1.0 if along >= 0.0 else -1.0) * short * 0.5 * (1.0 - apart / (2.0 * SHOE_HALF)))
			if not _ground(a + push, feet_y).is_empty() and not _ground(b - push, feet_y).is_empty():
				out[0] = (out[0] as Vector3) + push
				out[1] = (out[1] as Vector3) - push
	return out
