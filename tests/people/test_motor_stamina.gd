extends SceneTree
## Stamina (Yasin, 24 Nov: "idle 2 is after stamina runs out ... it will happen after running for 30 second or jumping 5
## times back to back"): run 31 s -> tired, the idle at the stop is set 2's; rest 11 s -> rested, set 1's idle again;
## 5 jumps back to back -> tired. Also: the walks and runs rotate (set 1's and set 3's takes both play).
##   godot --headless --path . --fixed-fps 60 -s res://tests/people/test_motor_stamina.gd
var player: CharacterBody3D
var t := 0.0; var t_prev := 0.0; var fails := 0
var clips := {}; var phase := 0
func _initialize() -> void:
	var b := StaticBody3D.new(); var cs := CollisionShape3D.new(); var sh := BoxShape3D.new(); sh.size = Vector3(400, 2, 400); cs.shape = sh; b.add_child(cs)
	b.position = Vector3(0, -1, 0); root.add_child(b)
	player = ClassDB.instantiate(&"CityPlayer"); player.position = Vector3(0, 0.05, 0); root.add_child(player)
func _at(w: float) -> bool: return t_prev < w and t >= w
func _check(ok: bool, what: String) -> void:
	if not ok: fails += 1
	print("STAMINA %s: %s" % ["ok  " if ok else "FAIL", what])
func _ms() -> Dictionary: return player.call(&"get_motor_state")
func _process(delta: float) -> bool:
	t_prev = t; t += delta
	var ms := _ms(); clips[String(ms.get("clip", ""))] = true
	# runs in circles (a wide square) so he never leaves the ground
	if _at(1.0): player.call(&"set_move", Vector2(0, 1), true)
	for k in 11: if _at(1.0 + k * 3.0): player.call(&"set_move", [Vector2(0, 1), Vector2(1, 0), Vector2(0, -1), Vector2(-1, 0)][k % 4], true)
	if _at(28.0): _check(not bool(ms.get("tired", false)), "not tired before 30 s of running (%.1f s)" % float(ms.get("run_t", 0)))
	if _at(33.5): _check(bool(ms.get("tired", false)), "tired after 30 s of running (%.1f s)" % float(ms.get("run_t", 0)))
	if _at(33.0): player.call(&"set_move", Vector2.ZERO, false)
	if _at(37.0): _check(String(ms.get("clip", "")).begins_with("ms/S2_Idle"), "the tired idle (set 2's): %s" % ms.get("clip", ""))
	if _at(46.0): _check(not bool(ms.get("tired", false)) and (String(ms.get("clip", "")).begins_with("pidle/") or String(ms.get("clip", "")) == "ms/S3_Idle_Breathing"), "rested after 10 s: the main idle (%s)" % ms.get("clip", ""))
	for k in 5: if _at(48.0 + k * 3.0): player.call(&"jump")   # (each as soon as the last has landed: set 3's takes 2.6 s)
	if _at(63.5): _check(bool(ms.get("tired", false)), "tired after 5 jumps back to back (chain %d)" % int(ms.get("jump_chain", 0)))
	for k in 8:   # (starts from a stand pick a run at random: eight of them)
		if _at(64.0 + k * 4.0): player.call(&"set_move", [Vector2(0, 1), Vector2(0, -1)][k % 2], true)
		if _at(66.0 + k * 4.0): player.call(&"set_move", Vector2.ZERO, false)
	if _at(97.0):
		var s1 := clips.keys().any(func(c): return String(c).begins_with("pwalk/walk") or String(c).begins_with("prun/"))
		var s3 := clips.keys().any(func(c): return String(c).begins_with("ms/S3_Run") or String(c).begins_with("ms/S3_Sprint") or String(c).begins_with("ms/S3_Walk"))
		_check(s1 and s3, "set 1's and set 3's runs both played (%s)" % str(clips.keys().filter(func(c): return String(c).contains("run") or String(c).contains("Run") or String(c).contains("Sprint") or String(c).contains("fast") or String(c).contains("jog"))))
		print("RESULT %s" % ("PASS" if fails == 0 else "FAIL (%d)" % fails)); quit(1 if fails else 0)
	return false
