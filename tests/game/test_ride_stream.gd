extends SceneTree
## B37 (Yasin, 20 Nov: "for some reason when we get into cars and bike, the world reloads, all of the texturs reload from far
## to near then the map returns to normal"):
##   godot --path . --rendering-method mobile --resolution 640x360 -s res://tests/game/test_ride_stream.gd
## A new game (the start: his bicycle and a car beside him). He gets into the car, then out, then onto the bicycle. Checks:
## no cell is taken away by the streamer in the 4 s after each (stats "out" unchanged), and the active camera's first
## position after getting in is near the vehicle (within 20 m), not at the world's origin.
var game: Node
var t := 0.0
var t0 := 0.0
var step := 0
var fails := 0
var pl: Node3D
var car: Node3D
var bike: Node3D
var st: Node
var out0 := 0
var cam_far := 0.0

func _check(ok: bool, what: String) -> void:
	if not ok: fails += 1
	print("RIDE    %s: %s" % ["ok" if ok else "FAIL", what])

func _initialize() -> void:
	var boot := Node.new(); boot.name = "Boot"
	game = ClassDB.instantiate(&"CityGame")
	game.name = "Game"
	game.set(&"saves_dir", "user://ride_test_saves/")
	for f in DirAccess.get_files_at("user://ride_test_saves/"): DirAccess.remove_absolute("user://ride_test_saves/" + f)
	boot.add_child(game); root.add_child(boot); current_scene = boot

func _cam_off(v: Node3D) -> float:
	var c := root.get_viewport().get_camera_3d()
	return c.global_position.distance_to(v.global_position) if c else 999.0

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
				if c.get_class() == "CityStream": st = c
			car = current_scene.get_node_or_null(^"StartCar"); bike = current_scene.get_node_or_null(^"StartBike")
			if st == null: for n in current_scene.find_children("*", "CityStream", true, false): st = n
			_check(pl != null and car != null and bike != null and st != null, "the start: player, car, bicycle, streamer")
			if pl == null or car == null or bike == null or st == null: return _end()
			step = 2; t0 = t
		2:      # settle (the start's own loading), then into the car
			if t - t0 < 6.0 or bool(pl.call(&"is_frozen")): return false
			out0 = int(st.stats.get("out", 0))
			_check(bool(car.call(&"enter", pl)), "he goes to get into the car"); step = 3; t0 = t; cam_far = 0.0
		3:
			cam_far = maxf(cam_far, _cam_off(car)) if bool(car.call(&"is_seated")) else cam_far
			if not bool(car.call(&"is_seated")) and t - t0 < 15.0: return false
			if bool(car.call(&"is_seated")) and t - t0 < 15.0 and t0 > -1.0:
				t0 = -100.0 + t      # (seated: watch 4 s more)
			if t - t0 < 104.0 and bool(car.call(&"is_seated")): return false
			_check(bool(car.call(&"is_seated")), "seated in the car (entry state %d, player %.1f m from the car)" % [int(car.call(&"get_entry_state")), pl.global_position.distance_to(car.global_position)])
			_check(int(st.stats.get("out", 0)) == out0, "no cell taken away while getting in and sitting (out %d -> %d)" % [out0, int(st.stats.get("out", 0))])
			_check(cam_far < 20.0, "the car's camera stayed near the car (farthest %.1f m)" % cam_far)
			car.call(&"leave"); step = 4; t0 = t
		4:
			if t - t0 < 5.0: return false
			# to the bicycle (it needs him within 2.5 m)
			pl.global_position = bike.global_position + bike.global_basis.x * 0.9
			out0 = int(st.stats.get("out", 0)); cam_far = 0.0
			step = 5; t0 = t
		5:
			if t - t0 < 0.5: return false
			_check(bool(bike.call(&"get_on")), "he gets on the bicycle"); step = 6; t0 = t
		6:
			cam_far = maxf(cam_far, _cam_off(bike))
			if t - t0 < 5.0: return false
			_check(int(st.stats.get("out", 0)) == out0, "no cell taken away while getting on the bicycle (out %d -> %d)" % [out0, int(st.stats.get("out", 0))])
			_check(cam_far < 20.0, "the camera stayed near the bicycle (farthest %.1f m)" % cam_far)
			return _end()
	return false

func _end() -> bool:
	print("RESULT %s (%d failed)" % ["PASS" if fails == 0 else "FAIL", fails])
	quit(1 if fails > 0 else 0)
	return true
