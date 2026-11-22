extends SceneTree
## The new movement system's vaults and climbs (native/src/mo_motor_trav.cpp; docs/ANIMATION_PLAN.md step 3; Yasin, 22
## Nov: "hands should hold edges of things when we interact with them like when we vault, character shouldnt jump to
## the sky after initiating climbs"):
##   godot --headless --path . --fixed-fps 60 -s res://tests/people/test_motor_trav.gd [-- --trace]
## Lanes: a thing across his way 3 m ahead, walked or run into. Per lane it prints and checks:
##   move      which clip took it (a vault / a climb happened at all)
##   sky       the hips' highest over the real top, minus the clip's own (cm): 0 = as the mocap did it over its own
##             obstacle; the old code's climbs went 60 cm over (test_step_up: feet 2.20 m up a 1.6 m wall)
##   hand      the worst distance a pinned hand was drawn from its spot on the edge, and its height error (cm)
##   warp      how far the clip was shifted to fit (cm)
##   end       where he stands after: beyond a rail on the ground, on top of a box / wall
##   pop       the biggest change of the hips' rise from one frame to the next (cm a frame; a climb rises fast but
##             smoothly: a jump in it is a pop; under 3 cm: the clips' own take-offs reach 2.5, Climbing_Double at
##             0.8 s as captured)
## What it cannot see: the look (the arms, the spine, the feet on the wall) - Yasin plays it.
var player: CharacterBody3D
var sk: Skeleton3D
var lane := -1
var t := 0.0
var fails := 0
var trace := false
var b_pel := -1
var pel_prev := Vector3(); var have := 0; var pop := 0.0; var dy_prev := 0.0; var pop_at := ""
var started := false; var done_t := -1.0
var seen_states := {}
var b_hand := [-1, -1]
var hand_miss := 0.0; var hand_dy := 0.0
const Z0 := 3.0
# [height, depth, run, what it should be]
const LANES := [
	[0.7, 0.12, false, "vault"], [0.95, 0.12, false, "vault"], [1.2, 0.12, false, "vault"],
	[0.7, 0.12, true, "vault"], [1.0, 0.12, true, "vault"],
	[0.7, 2.0, false, "climb"], [1.0, 2.0, false, "climb"], [1.0, 2.0, true, "climb"],
	[1.4, 2.0, false, "climb"], [1.75, 2.0, false, "climb"], [2.0, 2.0, false, "climb"], [1.8, 2.0, true, "climb"],
]

func _box(size: Vector3, at: Vector3) -> void:
	var b := StaticBody3D.new(); var cs := CollisionShape3D.new(); var sh := BoxShape3D.new(); sh.size = size; cs.shape = sh; b.add_child(cs)
	b.position = at; root.add_child(b)

func _initialize() -> void:
	trace = OS.get_cmdline_user_args().has("--trace")
	_box(Vector3(200, 2, 60), Vector3(40, -1, 10))
	for i in LANES.size():
		var h: float = LANES[i][0]; var d: float = LANES[i][1]
		_box(Vector3(3.0, h, d), Vector3(i * 6.0, h * 0.5, Z0 + d * 0.5))
	player = ClassDB.instantiate(&"CityPlayer"); player.position = Vector3(0, 0.02, 0); root.add_child(player)

func _next() -> void:
	lane += 1
	if lane >= LANES.size(): _finish(); return
	player.global_position = Vector3(lane * 6.0, 0.02, 0.0); player.velocity = Vector3.ZERO
	t = 0.0; started = false; done_t = -1.0; have = 0; pop = 0.0; seen_states = {}; hand_miss = 0.0; hand_dy = 0.0; snap_ok = false
	player.call(&"set_move", Vector2.ZERO, false)

func _process(delta: float) -> bool:
	if not player or not player.is_inside_tree(): return false
	if sk == null:
		var s := player.find_children("*", "Skeleton3D", true, false)
		if s.is_empty(): return false
		sk = s[0]; b_pel = sk.find_bone("Bip01_Pelvis"); b_hand = [sk.find_bone("Bip01_L_Hand"), sk.find_bone("Bip01_R_Hand")]; sk.skeleton_updated.connect(_on_pose)
		_next(); return false
	if lane >= LANES.size(): return true
	t += delta
	var L = LANES[lane]
	if t > 0.6 and not started and done_t < 0.0: player.call(&"set_move", Vector2(0, 1), L[2])
	var ms: Dictionary = player.call(&"get_motor_state")
	var st: String = ms.get("state", "off")
	seen_states[st] = true
	if st == "trav": started = true
	if started and st != "trav" and done_t < 0.0:
		done_t = t; player.call(&"set_move", Vector2.ZERO, false)
	if (done_t > 0.0 and t > done_t + 1.2) or t > 9.0:
		_judge(ms)
		_next()
	return false

# the skeleton can be posed more than once a frame (a seek, then its own update with the modifiers): the frame's sample
# is its LAST pose, taken when the next frame's first one comes
var pose_frame := -1
var snap_pel := Vector3(); var snap_hand := [Vector3(), Vector3()]; var snap_ok := false
func _on_pose() -> void:
	var f := Engine.get_process_frames()
	if f != pose_frame and snap_ok: _sample()
	pose_frame = f
	snap_pel = sk.global_transform * sk.get_bone_global_pose(b_pel).origin
	for s in 2: snap_hand[s] = sk.global_transform * sk.get_bone_global_pose(b_hand[s]).origin
	snap_ok = true
	if trace and lane == 0 and t > 4.8 and t < 5.15:
		var inn = sk.get_children().filter(func(c): return c.get_class() == "MoInertial")
		var ms2: Dictionary = player.call(&"get_motor_state")
		print("TRACEP f %d t %.3f pel %s fig %s left %.3f st %s clip %s ct %.3f" % [f, t, str(snap_pel), str(sk.global_position), inn[0].get_left() if inn.size() else -1.0, ms2.get("state", ""), ms2.get("clip", ""), float(ms2.get("t", 0.0))])

func _sample() -> void:
	var pel: Vector3 = snap_pel
	# the hands as DRAWN (after the IK), against their pinned spots while fully pinned
	var ms: Dictionary = player.call(&"get_motor_state")
	var hs: Array = ms.get("hands", [])
	if hs.size() == 4:
		for s in 2:
			if float(hs[s * 2 + 1]) > 0.95:
				var hw: Vector3 = snap_hand[s]
				hand_miss = maxf(hand_miss, (hw - hs[s * 2]).length()); hand_dy = maxf(hand_dy, absf(hw.y - hs[s * 2].y))
				if trace: print("TRACEH lane %d t %.3f clip_t %.3f hand %d drawn %s target %s miss %.3f" % [lane, t, float(ms.get("t", 0.0)), s, str(hw), str(hs[s * 2]), (hw - hs[s * 2]).length()])
	# a pop: the hips' vertical speed changing at once (a climb rises fast, smoothly: its rise per frame changes little)
	if have > 1 and absf((pel.y - pel_prev.y) - dy_prev) > pop:
		pop = absf((pel.y - pel_prev.y) - dy_prev)
		var m2: Dictionary = player.call(&"get_motor_state")
		pop_at = "%s %s t %.2f" % [m2.get("state", ""), m2.get("clip", ""), float(m2.get("t", 0.0))]
	if have > 0: dy_prev = pel.y - pel_prev.y
	if trace and lane >= 0 and lane < LANES.size(): print("TRACE lane %d %.3f %s pel %s" % [lane, t, str(player.call(&"get_motor_state").get("state", "")), str(pel)])
	pel_prev = pel; have += 1

func _check(ok: bool, what: String) -> void:
	if not ok: fails += 1
	print("TRAV    %s: %s" % ["ok  " if ok else "FAIL", what])

func _judge(ms: Dictionary) -> void:
	var L = LANES[lane]
	var h: float = L[0]; var d: float = L[1]
	var name := "%s %.2f m %s, %s" % ["rail" if d < 0.5 else ("box" if h < 1.2 else "wall"), h, "running" if L[2] else "walking", L[3]]
	var p := player.global_position
	var end_ok: bool
	if L[3] == "vault": end_ok = p.z > Z0 + d + 0.2 and absf(p.y) < 0.1
	else: end_ok = absf(p.y - h) < 0.1 and p.z > Z0   # (on the top; some clips end at its edge)
	var sky: float = ms.get("hips_over", 0.0); var hm: float = hand_miss; var hdy: float = hand_dy
	print("TRAV    %-34s move %-36s sky %5.1f cm  hand %4.1f / %4.1f cm  warp %4.1f cm  end %s  pop %.1f cm" % [name, ms.get("trav", ""), sky * 100.0, hm * 100.0, hdy * 100.0, float(ms.get("warp", 0.0)) * 100.0, str(p.snapped(Vector3(0.01, 0.01, 0.01))), pop * 100.0])
	print("TRAV    (contact / hand windows %s, hand weight at most %.2f)" % [str(ms.get("win", Vector3())), float(ms.get("wmax", 0.0))])
	_check(started, "%s: a move took it" % name)
	if not started: return
	_check(sky < 0.10, "%s: no sky (hips at most 10 cm over the clip's own: %.1f cm)" % [name, sky * 100.0])
	_check(hm < 0.05 and hdy < 0.03, "%s: hands on the edge (%.1f cm off, %.1f cm in height)" % [name, hm * 100.0, hdy * 100.0])
	_check(end_ok, "%s: ends %s (at %s)" % [name, "beyond it on the ground" if L[3] == "vault" else "standing on the top", str(p.snapped(Vector3(0.01, 0.01, 0.01)))])
	_check(pop < 0.03, "%s: no pop (the hips' rise changed %.1f cm a frame at most, at %s)" % [name, pop * 100.0, pop_at])

func _finish() -> void:
	print("RESULT %s" % ("PASS" if fails == 0 else "FAIL (%d)" % fails))
	quit(1 if fails else 0)
