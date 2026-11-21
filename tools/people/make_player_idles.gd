extends SceneTree
## PLAYER ONLY. Mixamo upper-body idle takes over the existing step/idle stance.
## Offline bake: preserves the exact base pelvis/root/legs (no runtime IK, physics or foot correction).
## The 4 upper-body takes were extracted from the existing Mixamo->Rocketbox conversion.
## No full Mixamo packs, general action mappings, Hands, camera or locomotion changes are required.
## This tool is a stance rebaker, not an FBX retargeter: the included .res contains the retargeted upper-body source.
## Re-stance the included pre-retargeted Mixamo upper-body takes to step/idle's first pose:
##   godot --headless --path . -s res://tools/people/make_player_idles.gd   -> characters/rocketbox/clips_player_idle_<g>.res
## (Yasin, 21 Nov: the player's idle on foot plays step/idle 4 loops, then one of these, never twice in a row; no UAL,
## no Idle_Transition, no texting.) The pelvis, thighs, calves and feet hold step/idle's first pose (its still-leg fix),
## so the feet stay planted through the variation and both crossfades.
const TAKES := ["Looking_Around_idle", "Looking", "Arm_Stretching", "Neck_Stretching", "Bored"]
## A take not yet in clips_player_idle_<g>.res comes from its own Mixamo conversion (the perf-bugs converter,
## tools/people/make_mixamo.gd / AnimRetarget "mixamo", run on that one FBX: Yasin's Bored.fbx, 21 Nov); once baked it
## is in the library and the tool re-stances it from there like the others.
const EXTRA := {"Bored": "/workspace/share/anim/walk/src/bored_%s.res"}
const DIR := "res://characters/rocketbox/"
const FPS := 30.0
## OPEN HANDS on the base (Yasin, 21 Nov: "can you open the hands of this base idle please?"): step/idle's finger
## tracks (Quaternius, tips folded into the palm) take the relaxed, slightly curled hand of a Mixamo take at rest
## (arms hanging), held: the same fingers the variations start and end with, so the crossfades do not move them.
const HAND_FROM := "Neck_Stretching"
const HAND_AT := 0.0
const HAND_EASE := 0.4
func _open_hands(base: Animation, from: Animation, at: float) -> void:
	var n := 0
	for ti in base.get_track_count():
		if base.track_get_type(ti) != Animation.TYPE_ROTATION_3D: continue
		var path := base.track_get_path(ti)
		var bone := String(path).get_slice(":", 1)
		if not bone.contains("Finger"): continue
		var fi := from.find_track(path, Animation.TYPE_ROTATION_3D)
		if fi < 0: continue
		var q := from.rotation_track_interpolate(fi, at)
		while base.track_get_key_count(ti) > 0: base.track_remove_key(ti, 0)
		base.rotation_track_insert_key(ti, 0.0, q)
		base.rotation_track_insert_key(ti, base.length, q)
		n += 1
	print("PLAYER_IDLE open hands: %d finger tracks of step/idle from %s at %.2f s" % [n, from.resource_name if from.resource_name != "" else HAND_FROM, at])

func _local(a: Animation, path: NodePath, t: float, rest: Transform3D) -> Transform3D:
	var pi := a.find_track(path, Animation.TYPE_POSITION_3D)
	var ri := a.find_track(path, Animation.TYPE_ROTATION_3D)
	var si := a.find_track(path, Animation.TYPE_SCALE_3D)
	var pos := a.position_track_interpolate(pi, t) if pi >= 0 else rest.origin
	var rot := a.rotation_track_interpolate(ri, t) if ri >= 0 else rest.basis.get_rotation_quaternion()
	var scl := a.scale_track_interpolate(si, t) if si >= 0 else rest.basis.get_scale()
	return Transform3D(Basis(rot).scaled(scl), pos)

func _initialize() -> void:
	for gender in ["male", "female"]:
		var steps: AnimationLibrary = load(DIR + "clips_step_%s.res" % gender)
		var base: Animation = steps.get_animation(&"idle")
		var mx: AnimationLibrary = load(DIR + "clips_player_idle_%s.res" % gender)
		_open_hands(base, mx.get_animation(HAND_FROM), HAND_AT)
		var serr := ResourceSaver.save(steps, DIR + "clips_step_%s.res" % gender)
		if serr != OK: print("PLAYER_IDLE ERROR save steps %d" % serr)
		var scene: Node = (load(DIR + "hero_%s.scn" % gender) as PackedScene).instantiate()
		var sk: Skeleton3D = scene.find_children("*", "Skeleton3D", true, false)[0]
		var out := AnimationLibrary.new()
		for name in TAKES:
			var src: Animation = mx.get_animation(name) if mx.has_animation(name) else (load(EXTRA[name] % gender) as AnimationLibrary).get_animation(name)
			var a := Animation.new(); a.length = src.length; a.loop_mode = Animation.LOOP_NONE
			var frames := int(ceil(src.length * FPS)) + 1
			var prefix := String(src.track_get_path(0)).get_slice(":", 0)
			for ti in src.get_track_count():
				var path := src.track_get_path(ti); var type := src.track_get_type(ti)
				if type not in [Animation.TYPE_POSITION_3D, Animation.TYPE_ROTATION_3D, Animation.TYPE_SCALE_3D]: continue
				var bone := String(path).get_slice(":", 1)
				# the thighs hang off Bip01_Spine in this rig: they are re-solved below, so the whole leg holds base's pose
				if bone.contains("Thigh"): continue
				var lower := bone.is_empty() or bone == "Bip01_Pelvis" or bone.contains("Calf") or bone.contains("Foot") or bone.contains("Toe")
				var bi := base.find_track(path, type)
				if lower and bi < 0: continue   # (a track base lacks: the rest pose, the same in both)
				var oi := a.add_track(type); a.track_set_path(oi, path)
				var samples := 1 if lower else frames
				for k in samples:
					var t: float = minf(float(k) / FPS, src.length)
					var anim: Animation = base if lower else src
					var idx: int = bi if lower else ti
					var sample_t: float = 0.0 if lower else t
					var v: Variant
					if type == Animation.TYPE_POSITION_3D: v = anim.position_track_interpolate(idx, sample_t)
					elif type == Animation.TYPE_ROTATION_3D: v = anim.rotation_track_interpolate(idx, sample_t)
					else: v = anim.scale_track_interpolate(idx, sample_t)
					a.track_insert_key(oi, t, v)
			# thigh = inverse(spine now) * spine in base * thigh in base: the hip joint and the leg exactly where step/idle has them
			var spi := sk.find_bone("Bip01_Spine")
			var sp_path := NodePath(prefix + ":Bip01_Spine")
			var sp_base := _local(base, sp_path, 0.0, sk.get_bone_rest(spi))
			for side in ["L", "R"]:
				var bn := "Bip01_%s_Thigh" % side
				var th_path := NodePath(prefix + ":" + bn)
				var th_base := _local(base, th_path, 0.0, sk.get_bone_rest(sk.find_bone(bn)))
				var want := sp_base * th_base
				var pt := a.add_track(Animation.TYPE_POSITION_3D); a.track_set_path(pt, th_path)
				var rt := a.add_track(Animation.TYPE_ROTATION_3D); a.track_set_path(rt, th_path)
				for k in frames:
					var t: float = minf(float(k) / FPS, src.length)
					var th := _local(src, sp_path, t, sk.get_bone_rest(spi)).affine_inverse() * want
					a.position_track_insert_key(pt, t, th.origin)
					a.rotation_track_insert_key(rt, t, th.basis.get_rotation_quaternion())
			# the hands at the crossfades: the fingers ease from the base's open hand over the first 0.4 s and back to it over
			# the last 0.4 s (the 0.4 s blends in and out), so no finger moves while the clips mix
			for ti in a.get_track_count():
				if a.track_get_type(ti) != Animation.TYPE_ROTATION_3D or not String(a.track_get_path(ti)).contains("Finger"): continue
				var hb := base.find_track(a.track_get_path(ti), Animation.TYPE_ROTATION_3D)
				if hb < 0: continue
				var hq := base.rotation_track_interpolate(hb, 0.0)
				for k in a.track_get_key_count(ti):
					var kt := a.track_get_key_time(ti, k)
					var w := smoothstep(0.0, 1.0, clampf(minf(kt, a.length - kt) / HAND_EASE, 0.0, 1.0))
					a.track_set_key_value(ti, k, hq.slerp(a.track_get_key_value(ti, k), w))
			a.set_meta("source", "mx/" + name); a.set_meta("stance", "step/idle")
			out.add_animation(name, a)
			print("PLAYER_IDLE %s %s %.3fs %d tracks" % [gender, name, a.length, a.get_track_count()])
		scene.free()
		var err := ResourceSaver.save(out, DIR + "clips_player_idle_%s.res" % gender)
		if err != OK: print("PLAYER_IDLE ERROR save %d" % err)
	quit(0)
