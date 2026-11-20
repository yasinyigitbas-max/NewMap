extends SceneTree
## Does AnimationPlayer.seek() right after play(clip, blend) cut the blend short? (CityPed::drive hands one walking loop to
## another at the same point of the stride by such a seek; trace_locomotion saw a foot jump 16 cm on that frame.)
##   godot --headless --path . -s res://tools/people/seek_blend.gd
## The figure jogs 1 s, then the walk is played with a 0.3 s blend: once without a seek, once with one. Prints how far the
## right foot moves in each of the 6 frames after the switch.
var scene: Node3D
var sk: Skeleton3D
var ap: AnimationPlayer
var foot := -1

func _run(seek_to: float) -> Array:
	ap.play(&"ual/Jog_Fwd_Loop", 0.0); ap.seek(0.40, true)
	var out := []
	ap.advance(0.0)
	var prev := _foot()
	ap.play(&"ual/Walk_Loop", 0.3)
	if seek_to >= 0.0: ap.seek(seek_to, true)
	for i in 6:
		ap.advance(1.0 / 60.0)
		var p := _foot()
		out.append("%.3f" % ((p - prev).length() * 0.01))
		prev = p
	return out

func _chain(seeks: bool) -> String:   # sprint; 13 frames on the jog (0.3 s blend); 13 frames on the walk: the biggest foot move a frame
	ap.play(&"ual/Sprint_Loop", 0.0); ap.seek(0.30, true); ap.advance(0.0)
	var prev := _foot(); var most := 0.0; var at := 0
	for i in 40:
		if i == 5: ap.play(&"ual/Jog_Fwd_Loop", 0.3); if seeks: ap.seek(0.62, true)
		if i == 18: ap.play(&"ual/Walk_Loop", 0.3); if seeks: ap.seek(0.10, true)
		ap.advance(1.0 / 60.0)
		var p := _foot(); var mv := (p - prev).length() * 0.01; prev = p
		if mv > most: most = mv; at = i
	return "most %.3f m at frame %d (switches at 5 and 18)" % [most, at]

func _foot() -> Vector3:   # (composed from the local poses: no deferred skeleton update in the way)
	var x := Transform3D(); var b := foot
	while b >= 0: x = Transform3D(sk.get_bone_pose_rotation(b), sk.get_bone_pose_position(b)) * x; b = sk.get_bone_parent(b)
	return x.origin

func _initialize() -> void:
	scene = (load("res://characters/rocketbox/hero_male.scn") as PackedScene).instantiate()
	root.add_child(scene)
	sk = scene.find_children("*", "Skeleton3D", true, false)[0]
	foot = sk.find_bone("Bip01_R_Foot")
	ap = AnimationPlayer.new(); scene.add_child(ap); ap.root_node = NodePath("..")
	ap.add_animation_library(&"ual", load("res://characters/rocketbox/clips_ual_male.res"))
	ap.callback_mode_process = AnimationMixer.ANIMATION_CALLBACK_MODE_PROCESS_MANUAL
	print("SEEKBLEND no seek:   right foot per frame (m) ", _run(-1.0))
	print("SEEKBLEND chain sprint > jog > walk, seeks: ", _chain(true))
	print("SEEKBLEND chain sprint > jog > walk, no seeks: ", _chain(false))
	print("SEEKBLEND with seek: right foot per frame (m) ", _run(0.55))
	quit()
