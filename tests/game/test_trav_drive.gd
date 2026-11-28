extends SceneTree
## Driving on the traversal body (Yasin, 28 Nov, the phone build: "while the car we are in is driven our character appear
## out of it randomly"; "the textures dont load until we get out of the car when we are in a car and drive away"):
##   godot --path . --rendering-method mobile --resolution 640x360 -s res://tests/game/test_trav_drive.gd
## (with the phone's physics: an override.cfg with [physics] 3d/physics_engine="Jolt Physics" and
##  3d/run_on_separate_thread=true; the file is not kept)
## A new game; he gets into the start car and it drives ahead 12 s. Checks, every frame while seated and driving: his body
## (the traversal body, drawn in the driver figure's pose) is within 2 m of the car; the streamer's focus follows the car
## (within 60 m of it at the end); out again, his body stands by the car, seen.
var game: Node
var t := 0.0
var t0 := 0.0
var step := 0
var fails := 0
var pl: Node3D
var car: Node3D
var st: Node
var body: Node3D
var worst := 0.0
var worst_at := ""
var frames := 0
var seen_out := 0
var start_pos := Vector3()

func _check(ok: bool, what: String) -> void:
	if not ok: fails += 1
	print("DRIVE   %s: %s" % ["ok" if ok else "FAIL", what])

func _initialize() -> void:
	var boot := Node.new(); boot.name = "Boot"
	game = ClassDB.instantiate(&"CityGame")
	game.name = "Game"
	game.set(&"saves_dir", "user://drive_test_saves/")
	for f in DirAccess.get_files_at("user://drive_test_saves/"): DirAccess.remove_absolute("user://drive_test_saves/" + f)
	boot.add_child(game); root.add_child(boot); current_scene = boot

func _key(k: Key, down: bool) -> void:
	var e := InputEventKey.new(); e.keycode = k; e.physical_keycode = k; e.pressed = down
	Input.parse_input_event(e)

func _watch() -> void:      # his body against the car, this frame
	if body == null or not body.visible: return
	frames += 1
	var d := body.global_position.distance_to(car.global_position)
	if d > 2.0: seen_out += 1
	if d > worst:
		worst = d; worst_at = "%.1f s, car at %.1f km/h" % [t - t0, absf(float((car.call(&"get_state") as Dictionary).get("kmh", 0.0)))]

func _process(delta: float) -> bool:
	t += delta
	match step:
		0:
			if t < 1.0: return false
			game.press("menu.new_game"); step = 1; t0 = t
		1:
			if game.get_start_info().is_empty() and t - t0 < 180.0: return false
			for c in current_scene.get_children():
				if c.get_class() == "CityPlayer": pl = c
			for n in current_scene.find_children("*", "CityStream", true, false): st = n
			car = current_scene.get_node_or_null(^"StartCar")
			_check(pl != null and car != null and st != null, "the start: player, car, streamer")
			if pl == null or car == null or st == null: return _end()
			body = pl.call(&"get_traversal_body")
			_check(body != null, "he is on the traversal body")
			step = 2; t0 = t
		2:
			if t - t0 < 6.0 or bool(pl.call(&"is_frozen")): return false
			_check(bool(car.call(&"enter", pl)), "he goes to get into the car"); step = 3; t0 = t
		3:
			if not bool(car.call(&"is_seated")) and t - t0 < 20.0: return false
			_check(bool(car.call(&"is_seated")), "seated in the car")
			start_pos = car.global_position
			_key(KEY_W, true)      # (at the wheel the car reads the keys, as a player drives: W ahead)
			# (measured just before the frame is drawn: what is seen. This script's _process runs before the nodes' own, so
			# there the car has moved this frame and the body, placed in the car's _process, not yet)
			RenderingServer.frame_pre_draw.connect(_watch)
			step = 4; t0 = t
		4:      # ahead, gently, 12 s
			if t - t0 < 12.0: return false
			RenderingServer.frame_pre_draw.disconnect(_watch)
			_key(KEY_W, false); _key(KEY_S, true)
			var moved := car.global_position.distance_to(start_pos)
			_check(moved > 20.0, "the car drove (%.0f m)" % moved)
			_check(frames > 0 and seen_out == 0, "his body stayed with the car: %d of %d frames more than 2 m from it (worst %.1f m at %s)" % [seen_out, frames, worst, worst_at])
			var f: Vector3 = st.call(&"get_focus")
			_check(f.distance_to(car.global_position) < 60.0, "the streamer follows the car (focus %.0f m from it)" % f.distance_to(car.global_position))
			step = 5; t0 = t
		5:
			if absf(float((car.call(&"get_state") as Dictionary).get("kmh", 0.0))) > 2.0 and t - t0 < 8.0: return false
			_key(KEY_S, false)
			car.call(&"leave"); step = 6; t0 = t
		6:
			if (bool(pl.call(&"is_frozen")) or int(car.call(&"get_entry_state")) != 0) and t - t0 < 15.0: return false
			_check(not bool(pl.call(&"is_frozen")), "out of the car, on foot")
			_check(body.visible and body.global_position.distance_to(car.global_position) < 3.5, "his body stands by the car (%.1f m), seen" % body.global_position.distance_to(car.global_position))
			_check(pl.global_position.distance_to(body.global_position) < 0.5, "the player is where his body is (%.2f m)" % pl.global_position.distance_to(body.global_position))
			return _end()
	return false

func _end() -> bool:
	print("RESULT %s (%d failed)" % ["PASS" if fails == 0 else "FAIL", fails])
	quit(1 if fails > 0 else 0)
	return true
