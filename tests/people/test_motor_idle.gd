extends SceneTree
## The idle's rhythm (Yasin, 24 Nov: "main idle should have 2 loops before a gesture, like bored, stretch neck or arms,
## look around, after the gesture idle plays 2 more loops and again another gesture and repeat, gestures should be
## random too"): standing 75 s - the idle (pidle/base_idle) at least two of its loops (2 x 8.3 s, less its entry) between
## gestures, never the same gesture twice running, more than one kind.
##   godot --headless --path . --fixed-fps 60 -s res://tests/people/test_motor_idle.gd
var player: CharacterBody3D
var t := 0.0; var fails := 0
var seq := []; var seg_t := 0.0; var last := ""
func _initialize() -> void:
	var b := StaticBody3D.new(); var cs := CollisionShape3D.new(); var sh := BoxShape3D.new(); sh.size = Vector3(40, 2, 40); cs.shape = sh; b.add_child(cs)
	b.position = Vector3(0, -1, 0); root.add_child(b)
	player = ClassDB.instantiate(&"CityPlayer"); player.position = Vector3(0, 0.05, 0); root.add_child(player)
func _check(ok: bool, what: String) -> void:
	if not ok: fails += 1
	print("IDLE    %s: %s" % ["ok  " if ok else "FAIL", what])
func _process(delta: float) -> bool:
	t += delta
	var c := String((player.call(&"get_motor_state") as Dictionary).get("clip", ""))
	if c != last:
		if last != "": seq.append([last, seg_t])
		last = c; seg_t = 0.0
	seg_t += delta
	if t >= 75.0:
		seq.append([last, seg_t])
		print("IDLE    sequence: %s" % str(seq.map(func(e): return "%s %.1f" % [e[0], e[1]])))
		var gestures := seq.filter(func(e): return not String(e[0]).begins_with("pidle/base"))
		var kinds := {}; for g in gestures: kinds[g[0]] = true
		_check(gestures.size() >= 2, "gestures between the idle (%d)" % gestures.size())
		_check(kinds.size() >= 2, "more than one kind (%s)" % str(kinds.keys()))
		var ok_gap := true; var ok_rep := true; var prev := ""
		for i in seq.size():
			var e = seq[i]
			if String(e[0]).begins_with("pidle/base") and i > 0 and i < seq.size() - 1 and e[1] < 2.0 * 8.33 - 4.0: ok_gap = false
			if not String(e[0]).begins_with("pidle/base"):
				if e[0] == prev: ok_rep = false
				prev = e[0]
		_check(ok_gap, "about two idle loops between gestures")
		_check(ok_rep, "never the same gesture twice running")
		print("RESULT %s" % ("PASS" if fails == 0 else "FAIL (%d)" % fails)); quit(1 if fails else 0)
	return false
