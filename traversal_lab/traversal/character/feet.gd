extends RefCounted
## Stage 4, the feet. The clips know nothing of the ground or of how the body really moved, so each tick, for each
## foot: (1) a foot the clip has on the ground is held where it was planted until the clip lifts it (no skating);
## (2) the foot is raised or lowered to the ground actually under it, and tilted to it; (3) the hips come down
## just far enough for the lower foot to reach. The legs are then solved by Godot's TwoBoneIK3D, with the knee
## pointed the way the clip had it, and foot_orient.gd turns the feet back afterwards.
## The report's bar: no foot inside or above its surface by more than about 2 cm, a planted foot drifts under 2 cm.

const FootOrient := preload("res://traversal/character/foot_orient_v1.gd")
const CONTACT := 0.025          # the ball of the foot this close to the clip's floor counts as on the ground (m)
const PLANT_SPEED := 0.45        # NOT in the study: a low foot counts as planted while it moves over the ground slower than
                                # this share of the body's speed (a swinging foot moves at about twice the body's speed)
const PIN_MOST := 0.10          # NOT in the study: a planted foot is let slide once it is this far from where the clip wants it
const PIN_TURN_MOST := 0.70     # radians (40 deg): the same for a planted foot's twist while he turns on the spot
const LET_GO := 0.10            # seconds for a lifted foot to return to the clip's own path
const REACH := 0.45             # how far above or below the body's ground a foot will look for its own ground (m)
const EDGE_REACH := 0.12         # NOT in the study: how far before and behind a moving foot a step edge is felt (m)
const STAND_TIME := 0.07         # NOT in the study: seconds for a foot to settle from "on its way" to "standing"
const FOOT_SPEED := 5.0         # m/s: how fast a foot follows a jump in the ground's height (a stair edge); a swinging
                                # foot on a 19 degree street needs 1 m/s, so slopes are followed exactly
const HIPS_TIME := 0.10         # seconds for the hips to come back up
const HIPS_DOWN := 1.5           # m/s: how fast they may come down when a planted foot cannot reach its ground
                                # (walking up a 19 degree street needs 0.5 m/s)
const TILT_MOST := 0.40         # radians (23 deg): how far the foot tilts to the ground; one measured ankle stopped at 24 deg
const STRAIGHT := 0.997         # the leg is never asked to be longer than this share of its length
const HIPS_MOST := 0.25         # NOT in the study: the most the hips come down for a foot to reach (m)

var skel: Skeleton3D
var body: CharacterBody3D
var hips_i := 0
var thigh := [0, 0]
var shin := [0, 0]
var foot := [0, 0]
var toe := [0, 0]
var foot_goal := [Basis.IDENTITY, Basis.IDENTITY]      # skeleton space, read by foot_orient.gd
var clip_slope := 0.0           # a stair clip climbs its own stairs: their rise per metre forward (0 for flat clips)
var clip_lump := [0.0, 0.0]      # and, per foot, how far the clip's own ground under that foot is off its even slope
var clip_pitch := 0.0           # a clip made on a slope (not stairs) holds its feet tipped to that slope: by this much (rad)
var clip_floor := 0.0           # and how far above the hips' own floor those stairs stand under him
var narrow := 1.0               # the share of the clip's sideways foot spread that is kept (1 = as the clip)
var pinning := true
var grounding := true
var weight := 0.0               # 0 = the clip alone (in the air), 1 = feet fitted
var pelvis := 0.0
var contact := [false, false]
# what the skeleton ended up with after the IK, in world space (for the tests and the readout)
var final_ball := [Vector3.ZERO, Vector3.ZERO]
var final_ankle := [Vector3.ZERO, Vector3.ZERO]
var final_knee := [Vector3.ZERO, Vector3.ZERO]
var final_hip := [Vector3.ZERO, Vector3.ZERO]
var ground_at := [0.0, 0.0]      # the ground height found under each foot
var clip_ball_h := [0.0, 0.0]   # how high the clip itself holds the ball of each foot above its own floor
var knee_side := [0.0, 0.0]      # > 0 = the knee is on the side the clip bent it to

var _origin := {}
var _leg_len := [0.0, 0.0]
var _ankle_rest := 0.0
var _toe_rest := 0.0
var _target: Array[Node3D] = []
var _pole: Array[Node3D] = []
var _ik: TwoBoneIK3D
var _orient: SkeletonModifier3D
var _pin_on := [false, false]
var _pin := [Vector3.ZERO, Vector3.ZERO]
var _pin_yaw := [0.0, 0.0]
var _corr := [Vector3.ZERO, Vector3.ZERO]
var _twist := [0.0, 0.0]
var _lift := [0.0, 0.0]
var _g := [0.0, 0.0]
var _g_ok := false
var _stand := [1.0, 1.0]         # 0 = a foot on its way, 1 = a foot standing
var _bend := [Vector3.ZERO, Vector3.ZERO]
var _aim := [Vector3.ZERO, Vector3.ZERO]
var _was := [Vector3.ZERO, Vector3.ZERO]
var _was_ok := false


func setup(s: Skeleton3D, b: CharacterBody3D) -> void:
	skel = s
	body = b
	hips_i = skel.find_bone("mixamorig_Hips")
	var side := ["Left", "Right"]
	for f in 2:
		thigh[f] = skel.find_bone("mixamorig_%sUpLeg" % side[f])
		shin[f] = skel.find_bone("mixamorig_%sLeg" % side[f])
		foot[f] = skel.find_bone("mixamorig_%sFoot" % side[f])
		toe[f] = skel.find_bone("mixamorig_%sToeBase" % side[f])
		for i: int in [thigh[f], shin[f], foot[f], toe[f]]:
			_origin[i] = skel.get_bone_rest(i).origin
		_leg_len[f] = (_origin[shin[f]] as Vector3).length() + (_origin[foot[f]] as Vector3).length()
	_ankle_rest = skel.get_bone_global_rest(foot[0]).origin.y
	_toe_rest = skel.get_bone_global_rest(toe[0]).origin.y
	skel.modifier_callback_mode_process = Skeleton3D.MODIFIER_CALLBACK_MODE_PROCESS_PHYSICS
	_ik = TwoBoneIK3D.new()
	_ik.name = "LegIK"
	skel.add_child(_ik)
	_ik.setting_count = 2
	for f in 2:
		var t := Node3D.new()
		t.name = "%sFootTarget" % side[f]
		skel.add_child(t)
		_target.append(t)
		var p := Node3D.new()
		p.name = "%sKneePole" % side[f]
		skel.add_child(p)
		_pole.append(p)
		_ik.set_root_bone(f, thigh[f])
		_ik.set_middle_bone(f, shin[f])
		_ik.set_end_bone(f, foot[f])
		_ik.set_target_node(f, _ik.get_path_to(t))
		_ik.set_pole_node(f, _ik.get_path_to(p))
	_orient = FootOrient.new()
	_orient.name = "FootOrient"
	_orient.set(&"feet", self)
	skel.add_child(_orient)
	skel.skeleton_updated.connect(_after)


## Where the leg joints are in the clip's own pose (skeleton space): hips, then thigh, shin, foot, toe of each side.
func _legs(rot: Array[Quaternion], hips: Vector3) -> Array:
	var h := Transform3D(Basis(rot[hips_i]), hips)
	var out := []
	for f in 2:
		var a := h * Transform3D(Basis(rot[thigh[f]]), _origin[thigh[f]])
		var b := a * Transform3D(Basis(rot[shin[f]]), _origin[shin[f]])
		var c := b * Transform3D(Basis(rot[foot[f]]), _origin[foot[f]])
		var d := c * Transform3D(Basis(rot[toe[f]]), _origin[toe[f]])
		# His feet land far apart sideways (Yasin, 26 Nov: "legs are too spread apart"; measured 0.32 m between
		# the ankles at a walk, where people were measured at 0.08 to 0.10 m). It comes from his T-pose, whose legs
		# splay, and every clip inherits it. The feet are brought in toward the line under the hips.
		if narrow != 1.0:
			var pull := (c.origin.x - hips.x) * (narrow - 1.0)
			c.origin.x += pull
			d.origin.x += pull
		# a stair clip puts its feet on its own stairs; take those stairs out, so its feet are on a flat floor like
		# any other clip's and the real steps under him are what they are fitted to
		if clip_slope != 0.0 or clip_floor != 0.0 or clip_lump[f] != 0.0:
			# (the whole foot moves as one, by what its ball needs)
			# a foot that the clip holds tipped to its own slope is laid level first, about the ankle: everything
			# after this (the ground under it, the tilt to the real slope, the heel coming up) takes a level foot
			if clip_pitch != 0.0:
				var level := Basis(Vector3(1.0, 0.0, 0.0), clip_pitch)
				d.origin = c.origin + level * (d.origin - c.origin)
				d.basis = level * d.basis
				c.basis = level * c.basis
			var off := clip_slope * (d.origin.z - hips.z) + clip_floor + float(clip_lump[f])
			c.origin.y -= off
			d.origin.y -= off
		out.append([a, b, c, d])
	return out


func _ground(at: Vector3, feet_y: float) -> Dictionary:
	var q := PhysicsRayQueryParameters3D.create(Vector3(at.x, feet_y + REACH, at.z), Vector3(at.x, feet_y - REACH, at.z), body.collision_mask, [body.get_rid()])
	return body.get_world_3d().direct_space_state.intersect_ray(q)


## Work out where each foot goes this tick. `rot` and `hips` are the clip's pose; `on_ground` = the body is standing
## on something. Returns how far the hips must come down (0 or less).
func solve(rot: Array[Quaternion], hips: Vector3, dt: float, on_ground: bool) -> float:
	var s := skel.global_transform
	var feet_y := body.global_position.y
	var legs := _legs(rot, hips)
	weight = move_toward(weight, 1.0 if on_ground else 0.0, dt / 0.12)
	var let_go := 1.0 - exp(-dt / LET_GO)
	var want_pelvis := 0.0
	var goal_pos := [Vector3.ZERO, Vector3.ZERO]
	for f in 2:
		var ankle: Vector3 = s * (legs[f][2] as Transform3D).origin
		var ball: Vector3 = s * (legs[f][3] as Transform3D).origin
		var basis: Basis = (s.basis * (legs[f][2] as Transform3D).basis).orthonormalized()
		clip_ball_h[f] = (legs[f][3] as Transform3D).origin.y
		# planted = low, and not travelling over the ground (the clip's own foot, before anything is corrected)
		var low: bool = on_ground and (legs[f][3] as Transform3D).origin.y < _toe_rest + CONTACT
		var over_ground := (Vector2(ball.x - (_was[f] as Vector3).x, ball.z - (_was[f] as Vector3).z).length() / dt) if _was_ok else 0.0
		_was[f] = ball
		var pace := (body.get(&"hvel") as Vector3).length()
		# (a planted foot is let go only when it clearly moves off: a generated clip's standing foot can creep)
		var slow := over_ground < (maxf(1.2, pace * 1.1) if contact[f] else maxf(0.5, pace * PLANT_SPEED))
		contact[f] = low and slow
		# (1) a planted foot stays where it was planted
		if contact[f] and pinning:
			var flat := Vector3(ball.x, 0.0, ball.z)
			if not _pin_on[f]:
				_pin_on[f] = true
				_pin[f] = flat + _corr[f]
				_pin_yaw[f] = body.rotation.y + _twist[f]
			var c: Vector3 = _pin[f] - flat
			if c.length() > PIN_MOST:
				c = c.normalized() * PIN_MOST
				_pin[f] = flat + c
			_corr[f] = c
			var tw := wrapf(_pin_yaw[f] - body.rotation.y, -PI, PI)
			if absf(tw) > PIN_TURN_MOST:
				tw = signf(tw) * PIN_TURN_MOST
				_pin_yaw[f] = body.rotation.y + tw
			_twist[f] = tw
		else:
			_pin_on[f] = false
			_corr[f] = (_corr[f] as Vector3) * (1.0 - let_go)
			_twist[f] *= 1.0 - let_go
		var turn := Basis(Vector3.UP, _twist[f])
		ball += _corr[f]
		ankle = ball + turn * (ankle - (ball - _corr[f]))
		basis = turn * basis
		# (2) the ground under this foot
		# the height of the ground under the foot is followed in the world, not against the body: a foot standing
		# on a step must not be dragged up as the body rises to the next one
		var want_g := feet_y
		var normal := Vector3.UP
		if grounding and on_ground:
			var ga := _ground(ankle, feet_y)
			var gb := _ground(ball, feet_y)
			if not ga.is_empty():
				want_g = (ga["position"] as Vector3).y
				normal = ga["normal"]
				# on a slope the tilt of the foot puts the ball on the ground; only ground under the ball that is
				# higher than the slope (the next stair) lifts the whole foot
				if not gb.is_empty() and normal.y > 0.3:
					var along := -(normal.x * (ball.x - ankle.x) + normal.z * (ball.z - ankle.z)) / normal.y
					var on_plane := want_g + along
					want_g += maxf((gb["position"] as Vector3).y - on_plane, 0.0)
					# the ankle only bends so far (TILT_MOST; one measured ankle stopped at 24 degrees): on ground
					# steeper than that, facing up it, the heel comes off and he stands on the ball of the foot
					var reach := Vector2(ball.x - ankle.x, ball.z - ankle.z).length() * tan(TILT_MOST)
					if along > reach:
						want_g += along - reach
			elif not gb.is_empty():
				want_g = (gb["position"] as Vector3).y
			ground_at[f] = want_g
			# A foot in the air passing a step edge would have its ground jump a whole step under it and be
			# snapped there (Yasin, 26 Nov: stairs "very jittery"; measured: feet and knees jolting at 300 to
			# 500 m/s2 on stairs against under 60 on the flat). So a moving foot goes by the ground averaged over
			# a hand's width before and behind it along its way, which turns an edge into a short rise; a planted
			# foot goes by the ground it stands on. Between the two it eases.
			var way := Vector3((body.get(&"hvel") as Vector3).x, 0.0, (body.get(&"hvel") as Vector3).z)
			if way.length() > 0.05:
				way = way.normalized()
				var smooth := want_g
				var back := _ground(ankle - way * EDGE_REACH, feet_y)
				var fore := _ground(ankle + way * EDGE_REACH, feet_y)
				if not back.is_empty() and not fore.is_empty() and (back["normal"] as Vector3).y > 0.98 and (fore["normal"] as Vector3).y > 0.98:
					var y0 := (back["position"] as Vector3).y
					var y1 := (fore["position"] as Vector3).y
					if absf(y1 - y0) > 0.04:
						# a step edge lies between: find where (halving the gap five times, to 6 mm), and let the
						# height run from one level to the other across the whole width
						var lo := -EDGE_REACH
						var hi := EDGE_REACH
						for i in 5:
							var mid := (lo + hi) * 0.5
							var r := _ground(ankle + way * mid, feet_y)
							if not r.is_empty() and absf((r["position"] as Vector3).y - y0) < absf((r["position"] as Vector3).y - y1):
								lo = mid
							else:
								hi = mid
						var edge := (lo + hi) * 0.5          # where the edge is, against the foot (- = behind)
						var share := clampf((EDGE_REACH - edge) / (2.0 * EDGE_REACH), 0.0, 1.0)
						smooth = lerpf(y0, y1, share * share * (3.0 - 2.0 * share))
				_stand[f] = move_toward(_stand[f], 1.0 if contact[f] else 0.0, dt / STAND_TIME)
				var k: float = _stand[f] * _stand[f] * (3.0 - 2.0 * _stand[f])
				want_g = lerpf(smooth, want_g, k)
		if not _g_ok or not on_ground:
			_g[f] = want_g
		_g[f] = move_toward(_g[f], want_g, FOOT_SPEED * dt)
		_lift[f] = clampf(_g[f] - feet_y, -REACH, REACH)
		ankle.y += _lift[f]
		# tilt the foot to the ground, the more the nearer it is to the ground
		var near := clampf(1.0 - ((legs[f][3] as Transform3D).origin.y - _toe_rest) / 0.10, 0.0, 1.0)
		var tilt_axis := Vector3.UP.cross(normal)
		if tilt_axis.length() > 0.001 and near > 0.0:
			var angle := minf(Vector3.UP.angle_to(normal), TILT_MOST) * near
			basis = Basis(tilt_axis.normalized(), angle) * basis
		goal_pos[f] = ankle
		foot_goal[f] = (s.basis.orthonormalized().inverse() * basis).orthonormalized()
		# (3) can the leg reach it? If not the hips come down
		var hip: Vector3 = s * (legs[f][0] as Transform3D).origin
		var flat_gap := Vector2(ankle.x - hip.x, ankle.z - hip.z).length()
		# (on stairs a little more bend is kept: a leg at full stretch throws its knee about for the smallest
		# change in reach, which showed as knees jolting on the way down)
		var most: float = _leg_len[f] * (STRAIGHT if clip_slope == 0.0 else 0.965)
		# (on stairs the foot coming down counts too, so the hips go down with it and not in a jerk when it lands)
		if flat_gap < most and (contact[f] or clip_slope != 0.0):
			want_pelvis = minf(want_pelvis, sqrt(most * most - flat_gap * flat_gap) - (hip.y - ankle.y))
		# the knee keeps the side the clip bent it to
		var mid: Vector3 = ((legs[f][0] as Transform3D).origin + (legs[f][2] as Transform3D).origin) * 0.5
		var bend: Vector3 = (legs[f][1] as Transform3D).origin - mid
		if bend.length() < 0.01:
			bend = (legs[f][0] as Transform3D).basis * Vector3(0.0, 0.0, 1.0)
		# the way the knee points is eased from tick to tick (in the skeleton's own space): on a nearly straight leg
		# the clip's knee direction swings about, and the knee with it
		var aim := bend.normalized()
		_aim[f] = aim if (_aim[f] as Vector3) == Vector3.ZERO else (_aim[f] as Vector3).lerp(aim, 1.0 - exp(-dt / 0.06)).normalized()
		_bend[f] = (s.basis * (_aim[f] as Vector3)).normalized()
		_pole[f].position = (legs[f][1] as Transform3D).origin + (_aim[f] as Vector3) * 0.6
	_was_ok = true
	_g_ok = true
	want_pelvis = maxf(want_pelvis, -HIPS_MOST) if on_ground else 0.0
	if want_pelvis < pelvis and clip_slope != 0.0:
		# on stairs the hips ease down to each step rather than follow the foot's reach to the centimetre
		pelvis += (want_pelvis - pelvis) * (1.0 - exp(-dt / 0.07))
	elif want_pelvis < pelvis:
		pelvis = maxf(want_pelvis, pelvis - HIPS_DOWN * dt)
	else:
		pelvis += (want_pelvis - pelvis) * (1.0 - exp(-dt / HIPS_TIME))
	var inv := s.affine_inverse()
	for f in 2:
		_target[f].position = inv * (goal_pos[f] as Vector3)
		_pole[f].position.y += pelvis
	_ik.influence = weight
	_orient.influence = weight
	return pelvis * weight


## After the skeleton has been solved: note where the feet really are.
func _after() -> void:
	var s := skel.global_transform
	for f in 2:
		final_ball[f] = s * skel.get_bone_global_pose(toe[f]).origin
		final_ankle[f] = s * skel.get_bone_global_pose(foot[f]).origin
		final_knee[f] = s * skel.get_bone_global_pose(shin[f]).origin
		final_hip[f] = s * skel.get_bone_global_pose(thigh[f]).origin
		var mid: Vector3 = (final_hip[f] + final_ankle[f]) * 0.5
		knee_side[f] = ((final_knee[f] as Vector3) - mid).dot(_bend[f])
