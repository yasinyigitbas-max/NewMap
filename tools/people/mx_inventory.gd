extends SceneTree
## The Mixamo clips as fitted (characters/rocketbox/clips_mx_male.res), one line each: length, loop, the travel and turn
## the bake measured, the loops' ground pace and stride phase, the share held in a T. Written to OUT/mx_inventory.tsv.
##   godot --headless --path . -s res://tools/people/mx_inventory.gd
func _initialize() -> void:
	var lib: AnimationLibrary = load("res://characters/rocketbox/clips_mx_male.res")
	var names := Array(lib.get_animation_list()); names.sort()
	var f := FileAccess.open("res://OUT/mx_inventory.tsv", FileAccess.WRITE)
	f.store_line("name\tlen\tloop\ttravel_m\tturn_deg\tground_v\tleft_down\ttpose\tarm_motion")
	for nm in names:
		var a := lib.get_animation(nm)
		var tr: Vector3 = a.get_meta("travel", Vector3())
		var yw: PackedFloat32Array = a.get_meta("yaw", PackedFloat32Array())
		var turn := rad_to_deg(yw[yw.size() - 1]) if yw.size() > 0 else 0.0
		# how much the upper arms move over the clip (a T held still moves 0)
		var mot := 0.0
		for i in a.get_track_count():
			var p := String(a.track_get_path(i))
			if not (p.ends_with("L_UpperArm") or p.ends_with("R_UpperArm")): continue
			var q0: Quaternion = a.rotation_track_interpolate(i, 0.0)
			for k in 10:
				var q: Quaternion = a.rotation_track_interpolate(i, a.length * k / 9.0)
				mot = maxf(mot, q0.angle_to(q))
		f.store_line("%s\t%.2f\t%d\t%.2f\t%.0f\t%.2f\t%.2f\t%.2f\t%.2f" % [nm, a.length, 1 if a.loop_mode != Animation.LOOP_NONE else 0, Vector2(tr.x, tr.z).length(), turn,
			float(a.get_meta("ground_v", 0.0)), float(a.get_meta("left_down", -1.0)), float(a.get_meta("tpose", 0.0)), rad_to_deg(mot)])
	f.close()
	print("INVENTORY %d clips: OUT/mx_inventory.tsv" % names.size())
	quit(0)
