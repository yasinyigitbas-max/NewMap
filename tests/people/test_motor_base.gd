extends SceneTree
## The new movement system's base (native/src/mo_motor.cpp, mo_inertial.cpp, mo_clip.cpp; docs/ANIMATION_PLAN.md):
## locomotion on flat ground, measured on the drawn figure, the same script once with the new motor and once with the
## old code (--old-moves path), so the two can be compared:
##   godot --headless --path . --fixed-fps 60 -s res://tests/people/test_motor_base.gd [-- --only=new|old] [--trace]
## Phases: stand, walk off and stop, run off and stop, walk -> run -> walk, turn on the spot 90 / 180, walk and turn
## back (a pivot), run and turn back. Per phase it prints:
##   slide    the worst distance a planted foot's ankle moved over the ground while the CLIP has that foot down (cm; the
##            new motor reports its clip's own contacts, mo_clip "down"). The old code has no contacts: for it the guess is
##            a heel or ball within 2.5 cm of its lowest moving under 0.5 m/s, which also counts a foot dragged slowly
##            near the ground, so the old numbers are high and only roughly comparable. The mocap's own feet slide a
##            little (the clips' slide_cm is 1.5-4.5).
##   hips_dv  the biggest change of the hips' level speed from one frame to the next (m/s): a pop / a hand-over jerk
##   hips_dy  the biggest rise or fall of the hips in one frame (cm)
##   clips    the clips it played
## What this cannot see: how it LOOKS (Yasin plays it), the arms and the spine (only feet and hips are measured).
var player: CharacterBody3D
var sk: Skeleton3D
var mode := "new"
var modes: Array = []
var t := 0.0
var phase := -1
var phase_t := 0.0
var fails := 0
var trace := false
var results := {}
var b_foot := [-1, -1, -1, -1]   # L ankle, R ankle, L toe, R toe (each a contact point of its own)
var b_pel := -1
# per phase
var slide_most := 0.0; var dv_most := 0.0; var dy_most := 0.0
var plant_at := [null, null, null, null]; var low := [9.0, 9.0, 9.0, 9.0]
var foot_prev := [Vector3(), Vector3(), Vector3(), Vector3()]
var pel_prev := Vector3(); var pel_v_prev := Vector3(); var have_prev := 0
var clips: Array = []
var dv_at := ""
var slide_at := ""
# [name, seconds, move (x right, y ahead), run]
const PHASES := [
	["stand", 2.5, Vector2(0, 0), false],
	["walk off", 4.0, Vector2(0, 1), false],
	["walk stop", 3.0, Vector2(0, 0), false],
	["run off", 4.0, Vector2(0, 1), true],
	["run stop", 3.0, Vector2(0, 0), false],
	["walk", 3.0, Vector2(0, 1), false],
	["walk to run", 3.0, Vector2(0, 1), true],
	["run to walk", 3.0, Vector2(0, 1), false],
	["stop", 3.0, Vector2(0, 0), false],
	["turn 90 right", 2.5, Vector2(1, 0), false],
	["stand again", 2.0, Vector2(0, 0), false],
	["turn back 180", 3.0, Vector2(-1, 0), false],
	["stop 2", 2.5, Vector2(0, 0), false],
	["walk ahead", 3.0, Vector2(0, 1), false],
	["walk turn back", 3.0, Vector2(0, -1), false],
	["stop 3", 2.5, Vector2(0, 0), false],
	["run ahead", 3.0, Vector2(0, 1), true],
	["run turn back", 3.0, Vector2(0, -1), true],
	["stop 4", 3.0, Vector2(0, 0), false],
]

func _initialize() -> void:
	trace = OS.get_cmdline_user_args().has("--trace")
	modes = ["new", "old"]
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--only="): modes = [a.substr(7)]
	var g := StaticBody3D.new(); var cs := CollisionShape3D.new(); var sh := BoxShape3D.new(); sh.size = Vector3(400, 2, 400); cs.shape = sh; g.add_child(cs)
	g.position = Vector3(0, -1, 0); root.add_child(g)
	_spawn(modes[0])

func _spawn(m: String) -> void:
	mode = m; have_prev = 0; plant_at = [null, null, null, null]; low = [9.0, 9.0, 9.0, 9.0]; pose_pending = false
	if player: player.queue_free()
	player = ClassDB.instantiate(&"CityPlayer")
	player.call(&"set_motor", mode == "new")
	player.position = Vector3(0, 0.02, 0)
	root.add_child(player)
	sk = null; phase = -1; t = 0.0; phase_t = 0.0

func _reset_phase() -> void:
	slide_most = 0.0; dv_most = 0.0; dy_most = 0.0; clips = []; dv_at = ""; slide_at = ""   # (the hips and feet go on from the last phase: one motion)

func _end_phase() -> void:
	var P = PHASES[phase]
	results["%s|%s" % [mode, P[0]]] = [slide_most, dv_most, dy_most]
	print("MOTOR %s %-16s slide %5.1f cm%s  hips_dv %4.2f m/s%s  hips_dy %4.1f cm  clips %s" % [mode, P[0], slide_most * 100.0, slide_at, dv_most, dv_at, dy_most * 100.0, str(clips)])

func _process(delta: float) -> bool:
	if not player or not player.is_inside_tree(): return false
	if sk == null:
		var s := player.find_children("*", "Skeleton3D", true, false)
		if s.is_empty(): return false
		sk = s[0]; sk.skeleton_updated.connect(_on_pose); print("SKEL scale %s root bones %s" % [str(sk.global_transform.basis.get_scale()), str(range(sk.get_bone_count()).filter(func(b): return sk.get_bone_parent(b) < 0).map(func(b): return sk.get_bone_name(b)))]); b_foot = [sk.find_bone("Bip01_L_Foot"), sk.find_bone("Bip01_R_Foot"), sk.find_bone("Bip01_L_Toe0"), sk.find_bone("Bip01_R_Toe0")]; b_pel = sk.find_bone("Bip01_Pelvis")
		phase = 0; phase_t = 0.0; _reset_phase()
		player.call(&"set_move", PHASES[0][2], PHASES[0][3])
	t += delta; phase_t += delta
	if phase_t >= PHASES[phase][1]:
		_end_phase()
		phase += 1; phase_t = 0.0; _reset_phase()
		if phase >= PHASES.size():
			var i := modes.find(mode)
			if i + 1 < modes.size(): _spawn(modes[i + 1]); return false
			_finish(); return true
		player.call(&"set_move", PHASES[phase][2], PHASES[phase][3])
	return false

# the skeleton can be posed more than once a frame (a clip seeked at once, then its own update): the frame's sample is
# its LAST pose, taken when the next frame's first one comes
var pose_frame := -1
var pose_pending := false
func _on_pose() -> void:
	if phase < 0 or phase >= PHASES.size(): return
	var f := Engine.get_process_frames()
	if f != pose_frame and pose_pending: _measure(1.0 / 60.0)
	pose_frame = f
	_snap()
	pose_pending = true

var snap_feet := [Vector3(), Vector3(), Vector3(), Vector3()]
var snap_pel := Vector3()
func _snap() -> void:
	var g := sk.global_transform
	for s in 4: snap_feet[s] = g * sk.get_bone_global_pose(b_foot[s]).origin
	snap_pel = g * sk.get_bone_global_pose(b_pel).origin

func _measure(dt: float) -> void:
	var clip: String = player.call(&"get_clip")
	var flags = null   # the clip's own foot contacts (new motor): [L down, R down]
	if mode == "new":
		var ms: Dictionary = player.call(&"get_motor_state")
		if ms.get("on", false): flags = [ms["down_l"], ms["down_r"]]
		if ms.get("on", false): clip = "%s:%s" % [ms["state"], ms["clip"]]
		if trace and ms.get("on", false): print("TRACEP %s %.3f %s dl %s dr %s pl %.3f pr %.3f yaw %.2f" % [PHASES[phase][0], phase_t, clip, str(ms["down_l"]), str(ms["down_r"]), ms["pull_l"], ms["pull_r"], ms["yaw"]])
		if trace and ms.get("on", false): print("TRACEI sw %d jump %.3f live %s t %.3f" % [ms["i_switches"], ms["i_jump"], str(ms["i_live"]), ms["t"]])
	if clips.is_empty() or clips[-1] != clip: clips.append(clip)
	for s in 4:
		var p: Vector3 = snap_feet[s]
		low[s] = minf(low[s], p.y)
		var v: Vector3 = (p - foot_prev[s]) / maxf(dt, 1e-4) if have_prev > 0 else Vector3()
		var down: bool
		if flags != null:   # the clip says which foot is down: its ankle is the contact (no toe guess)
			down = s < 2 and bool(flags[s]) and have_prev > 0 and p.y - player.global_position.y < 0.15   # (and on the ground as drawn: a hand-over can hold a foot up while the clip has it down)
		else:
			down = p.y < low[s] + 0.025 and Vector2(v.x, v.z).length() < 0.5 and have_prev > 0
		if down:
			if plant_at[s] == null: plant_at[s] = p
			var dd: float = Vector2(p.x - plant_at[s].x, p.z - plant_at[s].z).length()
			if trace and s < 2: print("TRACEF %s %.3f %s s%d p %s plant %s dd %.3f" % [PHASES[phase][0], phase_t, clip, s, str(p), str(plant_at[s]), dd])
			if dd > slide_most: slide_most = dd; slide_at = " (%s foot at %.2f s, %s)" % [["L heel", "R heel", "L toe", "R toe"][s], phase_t, clip]
		else:
			plant_at[s] = null
		foot_prev[s] = p
	var pel: Vector3 = snap_pel
	if have_prev > 0:
		var v := (pel - pel_prev) / maxf(dt, 1e-4)
		if have_prev > 1:
			var dv := Vector2(v.x - pel_v_prev.x, v.z - pel_v_prev.z).length()
			if dv > dv_most: dv_most = dv; dv_at = " (at %.2f s, %s)" % [phase_t, clip]
		dy_most = maxf(dy_most, absf(pel.y - pel_prev.y))
		pel_v_prev = v
		if trace: print("TRACE %s %s %.3f %s pel %s v %s sp %.2f" % [mode, PHASES[phase][0], phase_t, clip, str(pel), str(Vector2(v.x, v.z)), player.call(&"get_speed")])
	pel_prev = pel; have_prev += 1

func _finish() -> void:
	# the new motor against its targets (step 2 of the plan: the base; the foot lock comes in step 4)
	if modes.has("new"):
		for P in PHASES:
			var r = results.get("new|%s" % P[0])
			if r == null: continue
			var ok: bool = r[1] < 1.2 and r[2] < 0.03
			if not ok: fails += 1
			print("CHECK %s new %-16s hips_dv %.2f < 1.2 m/s, hips_dy %.1f < 3 cm" % ["ok  " if ok else "FAIL", P[0], r[1], r[2] * 100.0])
	if modes.has("new") and modes.has("old"):
		var sn := 0.0; var so := 0.0; var dn := 0.0; var do_ := 0.0
		for P in PHASES:
			var a = results.get("new|%s" % P[0]); var b = results.get("old|%s" % P[0])
			if a == null or b == null: continue
			sn = maxf(sn, a[0]); so = maxf(so, b[0]); dn = maxf(dn, a[1]); do_ = maxf(do_, b[1])
		print("COMPARE worst slide new %.1f cm / old %.1f cm; worst hips_dv new %.2f / old %.2f m/s" % [sn * 100.0, so * 100.0, dn, do_])
	print("RESULT %s" % ("PASS" if fails == 0 else "FAIL (%d)" % fails))
	quit(1 if fails else 0)
