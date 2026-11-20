extends SceneTree
## Audit of every animation clip the game plays (Yasin, 20 Nov: "inspect for every animation in the game, talk, fight,
## walk etc, all of them", "i want them pixel perfect"). Reads the fitted clips (characters/rocketbox/clips_ual_*.res) on
## the game's own skeleton, composes every bone frame by frame at 60 fps (as the figure plays them), and reports per clip:
##  - POP: a frame where a bone jumps: its move in that frame over 4x the median of the frames round it and over 2 cm
##  - SEAM (loops): how far each bone is between the last frame and the first (a loop that does not close pops)
##  - DRIFT (in-place clips: idles, loops): how far the hips wander over the clip
##  - FLOOR: the lowest a foot gets (under 0 = into the ground), the highest the lower foot is (a figure floating)
##   godot --headless --path . -s res://tools/people/clip_audit.gd [-- --female] [--clip=Walk_Loop] [--all]
## Writes OUT/clip_audit.txt (and prints the clips with a finding).
const USED := ["Celebration", "ClimbUp_1m", "ClimbUp_2m", "Counter_Angry", "Counter_Give", "Crouch_Enter", "Crouch_Exit", "Crouch_Fwd_Loop", "Crouch_Idle_Loop", "Dodge_Left", "Dodge_Right", "Driving_Loop", "GroundSit_Ask_Loop", "GroundSit_Enter", "GroundSit_Exit", "GroundSit_Idle_Loop", "GroundSit_Thanks_Loop", "Hit_Chest", "Hit_Head", "Hit_Stomach", "IdleToLay", "Idle_FoldArms_Loop", "Idle_Lantern_Loop", "Idle_LookAround_Loop", "Idle_Loop", "Idle_No_Loop", "Idle_TalkingPhone_Loop", "Idle_Talking_Loop", "Idle_Tired_Loop", "Idle_Torch_Loop", "Interact", "Jog_Fwd_Loop", "Jump_Land", "Jump_Loop", "Jump_Start", "Kick", "LayToIdle", "Melee_Hook", "Melee_Knee", "Melee_Uppercut", "PunchKick_Enter", "PunchKick_Exit", "Punch_Cross", "Punch_Jab", "SafetyVault", "Sitting_Drink_Loop", "Sitting_Enter", "Sitting_Exit", "Sitting_Idle02_Loop", "Sitting_Idle03_Loop", "Sitting_Idle_Loop", "Sitting_Nodding_Loop", "Sitting_Phone_Loop", "Sitting_Talking_Loop", "Sitting_Text_Loop", "Sprint_Enter", "Sprint_Exit", "Sprint_Loop", "StepUp", "Surprise", "Swim_Fwd_Loop", "Swim_Idle_Loop", "Walk_Formal_Loop", "Walk_Hurt_Loop", "Walk_Loop", "Walk_Phone_Loop", "Walk_Talk_Loop", "Walk_Text_Loop"]
const FPS := 60.0

var skel: Skeleton3D
var k := 1.0               # skeleton units -> metres
var skel_in_scene := Transform3D()
var n := 0
var parent: PackedInt32Array
var rest: Array = []
var bname: PackedStringArray

func _pose(a: Animation, tracks: Dictionary, t: float) -> Array:
	var loc: Array = rest.duplicate()
	for b: int in tracks:
		var tr: Array = tracks[b]
		var x: Transform3D = loc[b]
		for ti: int in tr:
			match a.track_get_type(ti):
				Animation.TYPE_POSITION_3D: x.origin = a.position_track_interpolate(ti, t)
				Animation.TYPE_ROTATION_3D: x.basis = Basis(a.rotation_track_interpolate(ti, t)).scaled(x.basis.get_scale())
		loc[b] = x
	var glob: Array = []; glob.resize(n)
	for b in n:
		glob[b] = (glob[parent[b]] as Transform3D) * (loc[b] as Transform3D) if parent[b] >= 0 else loc[b]
	var pts: Array = []; pts.resize(n)
	for b in n: pts[b] = skel_in_scene * (glob[b] as Transform3D).origin
	return pts

func _initialize() -> void:
	var female := OS.get_cmdline_user_args().has("--female")
	var only := ""
	var every := OS.get_cmdline_user_args().has("--all")
	for s: String in OS.get_cmdline_user_args(): if s.begins_with("--clip="): only = s.trim_prefix("--clip=")
	var g := "female" if female else "male"
	var scene: Node = (load("res://characters/rocketbox/hero_%s.scn" % g) as PackedScene).instantiate()
	root.add_child(scene)
	skel = scene.find_children("*", "Skeleton3D", true, false)[0]
	# the skeleton inside the figure's scene: its transform down from the scene's root (scale and offset to metres)
	var x := Transform3D(); var nd: Node = skel
	while nd != null and nd != scene.get_parent():
		if nd is Node3D: x = (nd as Node3D).transform * x
		nd = nd.get_parent()
	skel_in_scene = x
	k = x.basis.get_scale().x
	n = skel.get_bone_count()
	parent.resize(n); bname.resize(n)
	for b in n: parent[b] = skel.get_bone_parent(b); rest.append(skel.get_bone_rest(b)); bname[b] = skel.get_bone_name(b)
	# --rb: the Rocketbox library (characters/rocketbox/clips_<g>.res) and its walking loops instead
	var rb := OS.get_cmdline_user_args().has("--rb")
	var lib: AnimationLibrary = load(("res://characters/rocketbox/clips_%s.res" if rb else "res://characters/rocketbox/clips_ual_%s.res") % g)
	var feet := [skel.find_bone("Bip01_L_Foot"), skel.find_bone("Bip01_R_Foot")]
	var pel := skel.find_bone("Bip01_Pelvis")
	var lines := PackedStringArray()
	lines.append("CLIP AUDIT %s figure, skeleton scale %.4f, %d bones, at %d fps" % [g, k, n, int(FPS)])
	var names: Array = (["walk_slow", "walk", "walk_fast", "jog", "run", "sprint"] if rb else USED) if not every else Array(lib.get_animation_list())
	var flagged := 0
	for nm in names:
		if only != "" and nm != only: continue
		if not lib.has_animation(nm): lines.append("%-24s MISSING from the fitted library" % nm); continue
		var a: Animation = lib.get_animation(nm)
		var tracks := {}
		for ti in a.get_track_count():
			var p := a.track_get_path(ti)
			if p.get_subname_count() < 1: continue
			var b := skel.find_bone(p.get_subname(0))
			if b < 0: continue
			if not tracks.has(b): tracks[b] = []
			(tracks[b] as Array).append(ti)
		var len := a.length
		var fr := maxi(2, int(ceil(len * FPS)))
		var P: Array = []
		for f in fr + 1: P.append(_pose(a, tracks, minf(f / FPS, len)))
		if OS.get_cmdline_user_args().has("--track"):   # (every frame: the hips and feet, metres, the figure's frame: +z forward)
			for f in range(0, fr + 1):
				var hp: Vector3 = P[f][pel]; var lf: Vector3 = P[f][feet[0]]; var rf: Vector3 = P[f][feet[1]]
				print("TRACK %s t %.2f hips z %+.3f y %.3f | L z %+.3f y %.3f | R z %+.3f y %.3f" % [nm, f / FPS, hp.z, hp.y, lf.z, lf.y, rf.z, rf.y])
		# per frame, per bone: the move
		var pops := []
		var worst_move := 0.0; var worst_bone := ""
		for f in range(1, fr + 1):
			var mv := 0.0; var mb := 0
			for b in n:
				var d := ((P[f][b] as Vector3) - (P[f - 1][b] as Vector3)).length()
				if d > mv: mv = d; mb = b
			if mv > worst_move: worst_move = mv; worst_bone = bname[mb]
			# the median move of this bone in the frames round it
			var round := []
			for g2 in range(maxi(1, f - 4), mini(fr, f + 4) + 1):
				if g2 != f: round.append(((P[g2][mb] as Vector3) - (P[g2 - 1][mb] as Vector3)).length())
			round.sort()
			var med: float = round[round.size() / 2] if round.size() > 0 else 0.0
			if mv > 0.02 and mv > med * 4.0: pops.append("f%d %s %.3f m (round it %.3f)" % [f, bname[mb], mv, med])
		var is_loop := String(nm).ends_with("_Loop") or rb
		var seam := 0.0; var seam_bone := ""
		if is_loop:
			for b in n:
				var d := ((P[fr][b] as Vector3) - (P[0][b] as Vector3)).length()
				if d > seam: seam = d; seam_bone = bname[b]
		var drift := 0.0
		for f in fr + 1: drift = maxf(drift, Vector2((P[f][pel] as Vector3).x - (P[0][pel] as Vector3).x, (P[f][pel] as Vector3).z - (P[0][pel] as Vector3).z).length())
		var low := 9.0; var high_low := -9.0
		for f in fr + 1:
			var y0: float = (P[f][feet[0]] as Vector3).y; var y1: float = (P[f][feet[1]] as Vector3).y
			low = minf(low, minf(y0, y1)); high_low = maxf(high_low, minf(y0, y1))
		if (rb or String(nm).ends_with("_Loop")) and (String(nm).begins_with("walk") or String(nm).begins_with("jog") or String(nm).begins_with("run") or String(nm).begins_with("sprint") or String(nm).begins_with("Walk") or String(nm).begins_with("Jog") or String(nm).begins_with("Sprint") or String(nm).begins_with("Crouch_Fwd")):
			# the stride: when each foot is lowest (planted), as a share of the loop; and the planted foot's speed back (the
			# clip's own ground speed)
			var fl := 0; var fr2 := 0
			for f2 in fr + 1:
				if (P[f2][feet[0]] as Vector3).y < (P[fl][feet[0]] as Vector3).y: fl = f2
				if (P[f2][feet[1]] as Vector3).y < (P[fr2][feet[1]] as Vector3).y: fr2 = f2
			var spd := []
			for f2 in range(1, fr + 1):
				for fb in feet:
					var y: float = (P[f2][fb] as Vector3).y
					if y < low + 0.015: spd.append(absf((P[f2][fb] as Vector3).z - (P[f2 - 1][fb] as Vector3).z) * FPS)
			spd.sort()
			var zmin := 9.0; var zmax := -9.0
			for f2 in fr + 1: zmin = minf(zmin, (P[f2][feet[0]] as Vector3).z - (P[f2][pel] as Vector3).z); zmax = maxf(zmax, (P[f2][feet[0]] as Vector3).z - (P[f2][pel] as Vector3).z)
			# landing (what CityPed::stride_of holds): the left foot furthest forward of the hips
			var fw := 0
			for f2 in fr + 1:
				if (P[f2][feet[0]] as Vector3).z - (P[f2][pel] as Vector3).z > (P[fw][feet[0]] as Vector3).z - (P[fw][pel] as Vector3).z: fw = f2
			print("LANDING %-20s left foot furthest forward at %.3f of the loop" % [nm, float(fw) / fr])
			print("STRIDE %-20s left foot down at %.3f, right at %.3f of the loop; planted foot back at %.2f m/s (median of %d frames); the foot's reach fore and aft %.3f m: ground speed %.2f m/s (two steps a loop)" % [nm, float(fl) / fr, float(fr2) / fr, spd[spd.size() / 2] if spd.size() > 0 else 0.0, spd.size(), zmax - zmin, 2.0 * (zmax - zmin) / len])
		var finds := PackedStringArray()
		if not pops.is_empty(): finds.append("POP x%d: %s" % [pops.size(), ", ".join(PackedStringArray(pops.slice(0, 3)))])
		if is_loop and seam > 0.01: finds.append("SEAM %.3f m (%s)" % [seam, seam_bone])
		var in_place := is_loop or String(nm).begins_with("Idle") or String(nm).begins_with("Sitting") or String(nm).begins_with("GroundSit")
		if in_place and drift > 0.05 and not String(nm).begins_with("Swim"): finds.append("DRIFT the hips wander %.3f m" % drift)
		lines.append("%-24s %.2f s %3d fr | biggest move %.3f m (%s) | loop seam %s | hips drift %.3f m | lowest foot %.3f m | %s" % [nm, len, fr, worst_move, worst_bone, ("%.3f m" % seam) if is_loop else "-", drift, low, ("OK" if finds.is_empty() else "; ".join(finds))])
		if not finds.is_empty(): flagged += 1
	lines.append("CLIP AUDIT: %d of %d clips with a finding" % [flagged, names.size() if only == "" else 1])
	var f := FileAccess.open("res://OUT/clip_audit%s.txt" % ("_female" if female else ""), FileAccess.WRITE); f.store_string("\n".join(lines)); f.close()
	for l in lines: if not l.ends_with("| OK"): print(l)
	quit()
