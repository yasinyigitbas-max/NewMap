## Study v2 9.2 / 9.4 on clips: plays every clip of a clip cache on player_v3 (the clip as retargeted, its root motion,
## no layers) and runs the C++ validator (PoseCheck) on every frame. Flat ground at y = 0. Locomotion clips are judged
## on every rule; traversal clips (no obstacle here) on the joint rules only.
##   godot --headless --path . -s tests/clip_check.gd -- <cache.bin> [clip_prefix] [--log]
extends SceneTree

const JOINT_RULES := ["KNEE_FLEX_MIN", "KNEE_FLEX_MAX", "KNEE_VARUS", "KNEE_TWIST", "ANKLE_DORSI", "ANKLE_PLANTAR",
	"ANKLE_INVERSION", "ANKLE_EVERSION", "FOOT_TWIST", "TOE_BEND", "HIP_FLEX_COUPLED", "HIP_EXT", "HIP_ABD", "HIP_ROTATION",
	"SPINE_LUMBAR", "SPINE_THORACIC", "NECK", "SHOULDER_CONE", "SHOULDER_TWIST", "ELBOW", "FOREARM_TWIST", "WRIST",
	"FINGERS", "JOINT_SPEED", "POSE_DISCONTINUITY", "SELF_INTERSECT", "BONE_LENGTH", "PELVIS_YAW_SPEED"]

func _initialize():
	var a := OS.get_cmdline_user_args()
	var d: Dictionary = FileAccess.open(a[0], FileAccess.READ).get_var()
	var prefix := a[1] if a.size() > 1 and not a[1].begins_with("--") else ""
	var want_log := a.has("--log")
	var body: Node3D = load("res://body/player_v3.glb").instantiate()
	root.add_child(body)
	var sk: Skeleton3D = body.get_node("Armature/Skeleton3D")
	var chk = ClassDB.instantiate("PoseCheck")
	sk.add_child(chk)
	chk.set_active(false)
	await process_frame
	chk.set_flat_ground(true, 0.0)
	var names: Array = d.clips.keys()
	names.sort()
	for nm in names:
		if prefix != "" and not String(nm).begins_with(prefix): continue
		var c: Dictionary = d.clips[nm]
		var kind: String = c.get("kind", "")
		var trav := kind in ["traverse", "gesture"] or String(nm).begins_with("cand_t")
		chk.reset()
		var rot: PackedFloat32Array = c.rot; var hips: PackedFloat32Array = c.hips; var rt: PackedFloat32Array = c.root
		var n: int = c.bones
		var nf: int = c.frames
		var fps: float = c.fps
		var prev := Vector3(rt[0], 0, rt[1])
		for f in nf:
			chk.set_fk_pose(rot, hips, rt, f)
			var p := Vector3(rt[f * 3], 0, rt[f * 3 + 1])
			var v := (p - prev) * fps if f > 0 else Vector3.ZERO
			prev = p
			var spd := v.length()
			var state := 0
			if not trav:
				state = 2 if (kind == "loop") else (1 if kind == "start" else (3 if kind == "stop" else (4 if kind == "pivot" else 0)))
			else:
				state = 5
			chk.set_frame_input(state, spd, v, c.contact_l[f] == 1, c.contact_r[f] == 1, false, false)
			chk.step_manual(1.0 / fps)
		var counts: Dictionary = chk.get_counts()
		var tot := 0; var s := ""
		var keys := counts.keys(); keys.sort()
		for k in keys:
			if trav and not JOINT_RULES.has(k): continue
			tot += counts[k]; s += " %s=%d" % [k, counts[k]]
		print("CLIP %-28s %-6s n=%3d v=%4.2f HARD=%4d%s" % [nm, kind, nf, c.get("speed", 0.0), tot, s])
		if want_log:
			for l in chk.get_log().slice(0, 40): print("    ", l)
	quit()
