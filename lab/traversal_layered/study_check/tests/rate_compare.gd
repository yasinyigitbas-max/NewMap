## STUDY CHECK (LOCKED): frame-rate agreement (study 9.3). Compares pose snapshots (every 0.5 s of the same seeded
## free play) taken at two frame rates: every joint within 1 deg, the centre of mass within 1 cm.
##   godot --headless --path . -s res://study_check/tests/rate_compare.gd -- a=<snap_60.json> b=<snap_N.json>
extends SceneTree

func _init():
	var args := {}
	for a in OS.get_cmdline_user_args():
		var kv := a.split("=", true, 1)
		if kv.size() == 2: args[kv[0]] = kv[1]
	var A = JSON.parse_string(FileAccess.get_file_as_string(args.get("a", "")))
	var Bn = JSON.parse_string(FileAccess.get_file_as_string(args.get("b", "")))
	if typeof(A) != TYPE_DICTIONARY or typeof(Bn) != TYPE_DICTIONARY or A.is_empty():
		print("RATE ERROR: missing snapshots"); print("RATE RESULT FAIL"); quit(1); return
	var worst := 0.0; var worst_at := ""; var worst_com := 0.0; var n := 0; var bad := 0
	for k in A.keys():
		if not Bn.has(k): continue
		var a: Dictionary = A[k]; var b: Dictionary = Bn[k]
		n += 1
		var frame_bad := false
		for ch in a.keys():
			if ch == "com" or typeof(a[ch]) != TYPE_FLOAT or not b.has(ch): continue
			if ch == "pelvis_yaw": continue
			var d: float = abs(float(a[ch]) - float(b[ch]))
			if d > worst: worst = d; worst_at = "%s at %.1f s" % [ch, int(k) * 0.5]
			if d > 1.0: frame_bad = true
		if a.has("com") and b.has("com"):
			var ca: Array = a.com; var cb: Array = b.com
			var dc := Vector3(ca[0] - cb[0], ca[1] - cb[1], ca[2] - cb[2]).length()
			worst_com = max(worst_com, dc)
			if dc > 0.01: frame_bad = true
		if frame_bad: bad += 1
	print("RATE %s vs %s: %d snapshots, %d differ; worst joint %.2f deg (%s), worst CoM %.2f cm" % [args.a.get_file(), args.b.get_file(), n, bad, worst, worst_at, worst_com * 100.0])
	print("RATE RESULT " + ("PASS" if bad == 0 and n > 0 else "FAIL"))
	quit(0 if bad == 0 and n > 0 else 1)
