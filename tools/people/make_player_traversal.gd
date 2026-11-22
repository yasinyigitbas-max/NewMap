extends "res://tools/people/make_player_walks.gd"
## PLAYER ONLY. Jumps, landings, falls, crouch, cover, vaults and climbs (Yasin, 22 Nov: "add all these variety to the ones
## we covered and do the jumps, and crouches, again no ual"; the falls by height, the losing balance at an edge, the
## bushes and boxes, the cover): every distinct take of his downloads in those families, no UAL / Quaternius clip.
##   godot --headless --path . -s res://tools/people/make_player_traversal.gd   -> characters/rocketbox/clips_player_trav_<g>.res
## Library "ptrav" (CityPed loads it; CityPlayer's traversal, native/src/city_player_traversal.cpp, plays it). Sources:
## his Downloads and his three packs, fitted by the Mixamo converter (perf-bugs AnimRetarget, mixamo rig) into
## tools/people/player_trav_sources/clips_mxtrav_<g>.res. Exact duplicates (same base name and size, the packs +1 byte;
## every pair checked: under 0.1 cm apart all through, tools/people/trav_scan.gd) are left out:
##   Jump (Male Locomotion pack) = Jump; Jumping soft landing = Jumping; AA falling idle = Falling Idle; Falling To Landing
##   (1) (2) = Falling To Landing; AA hard landing = Hard Landing (1); Running Jump (1) = Running Jump; Standing Up (2) =
##   Standing Up (1); Crouch To Stand (2) = Crouch To Stand; Crouch Turn To Stand (1), Crouched Walking (1), Falling From
##   Losing Balance (1) = the take without the number. (The AA pack's crouched sneaking right and its cover sneaks are
##   the other way round from the downloads: distinct, kept.)
## Clip names are the takes' own (spaces to "_", a/b/c for the distinct takes of one name, "_M" mirrored). Every
## one-shot carries its own root motion in its hips (the converter took a jump's travel out into vz / vx: put back here),
## so the game draws it at one place and the feet stay where the mocap puts them. Meta (30 a second where a curve):
##   elev        the lower foot's height over the take's own ground (m), per frame
##   elev0       elev at its first frame (a take that starts on a ledge or in the air)   rise   elev at the end - elev0
##   air_at      leaves the ground (s)   apex_at   highest   land_at   back on the ground   (-1: none)
##   leave_at    (a take that starts up high) the moment it drops off   impact_at   the feet hit the ground under it
##   top_at      (a climb) on the top   face0 / face_end   the hips' facing at the start / end (rad, + to his left)
##   flip        it faces back the way it starts (a cover take made facing -z: drawn turned round)
##   lat         (a sideways loop) +1 it goes to his left, -1 to his right (as drawn)
##   lo0 / lo_end the lower foot's height in the figure at the start / end (m; standing: about 0.10)   hand0   the higher
##               hand's height at the first frame (a take that starts hanging: where the edge is)   key_at   elev's highest
##   hands_low_at / hands_low_x y z  when both hands are lowest, and where (between them; the figure's frame, m)
##   root        true: one-shot with its root motion in the hips   turning: its turn is taken out (meta yaw turns the body)
const SRC := "res://tools/people/player_trav_sources/clips_mxtrav_%s.res"
## [clip, source take, mirrored]
const TAKES := [
	# standing jumps (in place: the whole jump; Jumping Up / Jumping (2): take-offs, the air and a landing follow)
	["Jump_a", "Jump_a", false], ["Jumping_b", "Jumping_b", false], ["Jumping_Up", "Jumping_Up", false], ["Jumping_c", "Jumping_c", false],
	# running jumps
	["Running_Jump_a", "Running_Jump_a", false], ["Jump_b", "Jump_b", false],
	# soft landings / jumping down off a ledge
	["Jumping_a", "Jumping_a", false], ["Jumping_Down_a", "Jumping_Down_a", false], ["Jumping_Down_b", "Jumping_Down_b", false], ["Jumping_Down_c", "Jumping_Down_c", false],
	# hard landings, the messed-up ones and up again, the long fall
	["Hard_Landing_a", "Hard_Landing_a", false], ["Hard_Landing_b", "Hard_Landing_b", false],
	["Falling_Flat_Impact", "Falling_Flat_Impact", false], ["Fall_Flat", "Fall_Flat", false], ["Falling_Down_On_Ass", "Falling_Down_On_Ass", false],
	["Getting_Up", "Getting_Up", false], ["Standing_Up_a", "Standing_Up_a", false], ["Standing_Up_b", "Standing_Up_b", false], ["Fallen_Idle", "Fallen_Idle", false],
	["Falling_Air", "Falling_Air", false], ["Falling_Idle", "Falling_Idle_a", false], ["Falling_To_Landing", "Falling_To_Landing_a", false],
	["Falling_From_Losing_Balance", "Falling_From_Losing_Balance_a", false],
	# crouch
	["Standing_To_Crouched", "Standing_To_Crouched", false], ["Crouch_To_Stand_a", "Crouch_To_Stand_a", false], ["Crouch_To_Stand_b", "Crouch_To_Stand_b", false],
	["Crouched_To_Standing", "Crouched_To_Standing", false], ["Crouch_Turn_To_Stand", "Crouch_Turn_To_Stand_a", false],
	["Crouching_Idle", "Crouching_Idle", false], ["Crouched_Walking", "Crouched_Walking_a", false], ["Sneaking_Forward", "Sneaking_Forward", false],
	["Crouched_Sneaking_Left", "Crouched_Sneaking_Left", false], ["Crouched_Sneaking_Right", "Crouched_Sneaking_Right", false], ["Crouched_Sneaking_Right_aa", "Crouched_Sneaking_Right_aa", false],
	["Crouched_To_Sprinting", "Crouched_To_Sprinting", false],
	# cover
	["Stand_To_Cover_a", "Stand_To_Cover_a", false], ["Stand_To_Cover_b", "Stand_To_Cover_b", false], ["Cover_To_Stand_a", "Cover_To_Stand_a", false], ["Cover_To_Stand_b", "Cover_To_Stand_b", false],
	["Cover_Idle", "Cover_Idle", false], ["Crouch_Cover_Idle", "Crouch_Cover_Idle", false],
	["Crouch_Cover_To_Cover", "Crouch_Cover_To_Cover", false], ["Crouch_Cover_To_Cover_M", "Crouch_Cover_To_Cover", true],
	["Crouch_Cover_Turn", "Crouch_Cover_Turn", false], ["Standing_Cover_Turn", "Standing_Cover_Turn", false],
	["Left_Cover_Sneak_a", "Left_Cover_Sneak_a", false], ["Left_Cover_Sneak_b", "Left_Cover_Sneak_b", false], ["Right_Cover_Sneak_a", "Right_Cover_Sneak_a", false], ["Right_Cover_Sneak_b", "Right_Cover_Sneak_b", false],
	["Sneak_Off_The_Cover", "Sneak_Off_The_Cover", false], ["Crouch_Look_Around_Corner", "Crouch_Look_Around_Corner", false], ["Crouch_Look_Around_Corner_M", "Crouch_Look_Around_Corner", true],
	["Vault_Over_Box_To_Cover", "Vault_Over_Box_To_Cover", false],
	# vault (walking over a thin obstacle), climbs
	["Jumping_Over_Into_Combat", "Jumping_Over_Into_Combat", false],
	["Running_Jump_Climb", "Running_Jump_Climb", false], ["Braced_Hang_To_Crouch", "Braced_Hang_To_Crouch", false], ["Stand_To_Freehang", "Stand_To_Freehang", false],
	["Hanging_Idle", "Hanging_Idle", false], ["Climbing_Single", "Climbing_Single", false], ["Climbing_Double", "Climbing_Double", false], ["Sprint_To_Wall_Climb", "Sprint_To_Wall_Climb", false],
]

## the converter's rule for a take whose travel it took out into vz / vx (anim_retarget.cpp mx_motion "locomotion")
func _moved_out(src_name: String, a: Animation) -> bool:
	var l := src_name.to_lower()
	if a.loop_mode != Animation.LOOP_NONE: return false
	return l.contains("start") or l.contains("stop") or l.contains("turn") or l.contains("to_run") or l.contains("to_stop") or l.contains("step") or (l.contains("jump") and not l.contains("climb") and not l.contains("hang"))

## the travel put back into the hips: the path from the converter's own pace (vz / vx in the hips' turning frame)
func _put_back(a: Animation) -> void:
	var vz: PackedFloat32Array = a.get_meta("vz"); var vx: PackedFloat32Array = a.get_meta("vx"); var yw: PackedFloat32Array = a.get_meta("yaw")
	var n := vz.size()
	var P := PackedVector3Array(); var p := Vector3()
	for f in n:
		P.append(p)
		var y: float = yw[f] if f < yw.size() else 0.0
		p += (Vector3(sin(y), 0, cos(y)) * vz[f] + Vector3(cos(y), 0, -sin(y)) * vx[f]) / FPS
	var pel := sk.find_bone("Bip01_Pelvis")
	var ti := -1; var bone := -1
	for k in a.get_track_count():
		if a.track_get_type(k) != Animation.TYPE_POSITION_3D: continue
		var b := sk.find_bone(String(a.track_get_path(k)).get_slice(":", 1))
		if b >= 0 and (b == pel or bone < 0 or sk.get_bone_parent(pel) == b): ti = k; bone = b
	if ti < 0: return
	for k in a.track_get_key_count(ti):
		var t := a.track_get_key_time(ti, k)
		var f := clampf(t * FPS, 0.0, n - 1.0); var i := int(f); var j := mini(i + 1, n - 1)
		var d: Vector3 = P[i].lerp(P[j], f - i)
		var par := sk.get_bone_parent(bone)
		var pgl: Transform3D = _globals(_locals(a, t))[par] if par >= 0 else Transform3D()
		var pg: Transform3D = skel_x * pgl
		var dl := pg.basis.inverse() * d
		a.track_set_key_value(ti, k, (a.track_get_key_value(ti, k) as Vector3) + dl)
	a.set_meta("vz_put_back", true)

func _initialize() -> void:
	_build(TAKES, SRC, "clips_player_trav_%s.res", "PLAYER_TRAV")
	quit(0)

## (also make_player_actions.gd: the same fit for another set of takes)
func _build(takes: Array, src_path: String, out_path: String, tag: String) -> void:
	for gender in ["male", "female"]:
		var scene: Node = (load(DIR + "hero_%s.scn" % gender) as PackedScene).instantiate()
		sk = scene.find_children("*", "Skeleton3D", true, false)[0]
		skel_x = Transform3D()
		var nd: Node = sk
		while nd != scene: skel_x = (nd as Node3D).transform * skel_x; nd = nd.get_parent()
		rest_g.clear()
		for b in sk.get_bone_count():
			var par := sk.get_bone_parent(b)
			rest_g.append(sk.get_bone_rest(b) if par < 0 else rest_g[par] * sk.get_bone_rest(b))
		mirror_of.resize(sk.get_bone_count())
		for b in sk.get_bone_count():
			var bn := sk.get_bone_name(b)
			var other := bn.replace("_L_", "_#_").replace("_R_", "_L_").replace("_#_", "_R_")
			mirror_of[b] = sk.find_bone(other) if sk.find_bone(other) >= 0 else b
		var lat := (rest_g[sk.find_bone("Bip01_L_Thigh")].origin - rest_g[sk.find_bone("Bip01_R_Thigh")].origin).normalized()
		M = Basis(Vector3(1 - 2 * lat.x * lat.x, -2 * lat.x * lat.y, -2 * lat.x * lat.z), Vector3(-2 * lat.y * lat.x, 1 - 2 * lat.y * lat.y, -2 * lat.y * lat.z), Vector3(-2 * lat.z * lat.x, -2 * lat.z * lat.y, 1 - 2 * lat.z * lat.z))
		var src: AnimationLibrary = load(src_path % gender)
		var out := AnimationLibrary.new()
		var lf := sk.find_bone("Bip01_L_Foot"); var rf := sk.find_bone("Bip01_R_Foot"); var lt := sk.find_bone("Bip01_L_Thigh"); var rt := sk.find_bone("Bip01_R_Thigh"); var lh := sk.find_bone("Bip01_L_Hand"); var rh := sk.find_bone("Bip01_R_Hand")
		for T in takes:
			var a := _copy(src.get_animation(T[1]))
			var loop := a.loop_mode != Animation.LOOP_NONE
			var turning := String(T[1]).to_lower().contains("turn") and a.has_meta("yaw") and absf((a.get_meta("yaw") as PackedFloat32Array)[-1]) > 0.35
			if not loop and not turning and _moved_out(T[1], a): _put_back(a)
			if T[2]: a = _mirror(a)
			a.set_meta("source", "mx/" + String(T[1]) + (" (mirrored)" if T[2] else ""))
			a.set_meta("root", not loop); a.set_meta("turning", turning)
			# the feet, the hips' facing, frame by frame
			var n := int(round(a.length * FPS)) + 1
			var lo := PackedFloat32Array(); var face := PackedFloat32Array(); var hand0 := 0.0
			var hl_y := 1e9; var hl_at := 0.0; var hl_p := Vector3()   # (the hands' lowest, both: the put down's moment)
			for f in n:
				var g := _globals(_locals(a, minf(f / FPS, a.length)))
				if f == 0: hand0 = maxf((skel_x * g[lh].origin).y, (skel_x * g[rh].origin).y)
				lo.append(minf((skel_x * g[lf].origin).y, (skel_x * g[rf].origin).y))
				var hm: Vector3 = (skel_x * g[lh].origin + skel_x * g[rh].origin) * 0.5
				if hm.y < hl_y: hl_y = hm.y; hl_at = f / FPS; hl_p = hm
				var th: Vector3 = skel_x * g[lt].origin - skel_x * g[rt].origin
				var fw := -Vector3.UP.cross(th)
				face.append(atan2(fw.x, fw.z))
			var ground: float = Array(lo).min()
			var elev := PackedFloat32Array()
			for f in n: elev.append(lo[f] - ground)
			a.set_meta("elev", elev)
			var e0 := elev[0]; var e1 := elev[n - 1]
			a.set_meta("elev0", e0); a.set_meta("rise", e1 - e0)
			a.set_meta("hands_low_at", hl_at); a.set_meta("hands_low_x", hl_p.x); a.set_meta("hands_low_y", hl_p.y); a.set_meta("hands_low_z", hl_p.z)   # (the figure's frame, m)
			a.set_meta("lo0", lo[0]); a.set_meta("lo_end", lo[n - 1]); a.set_meta("hand0", hand0)
			var apex := 0
			for f in n: if elev[f] > elev[apex]: apex = f
			a.set_meta("key_at", apex / FPS)
			var air := -1.0; var land := -1.0; var ap := -1.0
			if e0 < 0.06 and elev[apex] > 0.15:
				ap = apex / FPS
				for f in apex + 1: if elev[f] > 0.10: air = f / FPS; break
				for f in range(apex, n): if elev[f] < e1 + 0.05: land = f / FPS; break
			a.set_meta("air_at", air); a.set_meta("apex_at", ap); a.set_meta("land_at", land)
			var leave := -1.0; var impact := -1.0
			if e0 > 0.3:
				var lf0 := -1
				for f in n: if elev[f] < e0 - 0.12: lf0 = f; break
				if lf0 >= 0:
					leave = lf0 / FPS
					for f in range(lf0, n): if elev[f] < e1 + 0.05: impact = f / FPS; break
			a.set_meta("leave_at", leave); a.set_meta("impact_at", impact)
			var top := -1.0
			if e1 - e0 > 0.3:
				for f in n: if elev[f] >= e1 - 0.06: top = f / FPS; break
			a.set_meta("top_at", top)
			a.set_meta("face0", face[0]); a.set_meta("face_end", face[n - 1]); a.set_meta("face", face)
			a.set_meta("flip", absf(face[0]) > PI * 0.5)
			if loop:
				var tr: Vector3 = a.get_meta("travel", Vector3())
				var lx := tr.x * (-1.0 if absf(face[0]) > PI * 0.5 else 1.0)
				a.set_meta("lat", 0 if absf(tr.x) < 0.3 else (1 if lx > 0.0 else -1))
			out.add_animation(T[0], a)
			print(tag + " %s %-28s <- %-34s %.2fs %s elev0 %.2f rise %+.2f air %.2f apex %.2f land %.2f leave %.2f impact %.2f top %.2f face %.0f->%.0f%s%s%s" % [gender, T[0], a.get_meta("source"), a.length, "loop" if loop else "once", e0, e1 - e0, air, ap, land, leave, impact, top, rad_to_deg(face[0]), rad_to_deg(face[n - 1]), " flip" if a.get_meta("flip") else "", " lat %d" % int(a.get_meta("lat")) if loop else "", " turning" if turning else (" root+travel" if a.has_meta("vz_put_back") else "")])
		scene.free()
		var err := ResourceSaver.save(out, DIR + out_path % gender, ResourceSaver.FLAG_COMPRESS)
		print(tag + " saved %s %s (%d clips)" % [gender, "ok" if err == OK else "ERROR %d" % err, out.get_animation_list().size()])
