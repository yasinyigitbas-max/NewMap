extends SceneTree
## A new game in the real city (C++: CityGame places the start; the test app is the world), with a renderer:
##   godot --path . --rendering-method mobile --resolution 960x540 -s res://tests/game/test_start.gd
## New game is pressed; the city loads; the player must be set down in the city centre on a pavement, a bicycle just
## ahead of him and a car at the kerb (Yasin: "start the player next to a bike and car in the city center, make sure
## they land on a way rather than in or on a building"). Checks: each stands on the ground with nothing over it (a ray
## from 30 m up meets the ground at its feet, not a roof); the car is on the road, not the pavement; 5 s later none has
## fallen through. One picture: review/game_19nov/start.jpg.
var game: Node
var t := 0.0
var t0 := 0.0
var step := 0
var fails := 0
var info := {}

func _check(ok: bool, what: String) -> void:
	if not ok: fails += 1
	print("START   %s: %s" % ["ok" if ok else "FAIL", what])

func _initialize() -> void:
	var boot := Node.new(); boot.name = "Boot"
	game = ClassDB.instantiate(&"CityGame")
	game.name = "Game"
	game.set(&"saves_dir", "user://start_test_saves/")
	for f in DirAccess.get_files_at("user://start_test_saves/"): DirAccess.remove_absolute("user://start_test_saves/" + f)
	boot.add_child(game); root.add_child(boot); current_scene = boot

func _sky(at: Vector3, skip: Array) -> float:   # the first thing a ray from 30 m up meets
	var q := PhysicsRayQueryParameters3D.create(at + Vector3(0, 30, 0), at - Vector3(0, 5, 0))
	q.exclude = skip
	var h := root.get_world_3d().direct_space_state.intersect_ray(q)
	return (h.position as Vector3).y if not h.is_empty() else -999.0

func _process(delta: float) -> bool:
	t += delta
	match step:
		0:
			if t < 1.0: return false
			game.press("menu.new_game"); step = 1; t0 = t
		1:
			info = game.get_start_info()
			if info.is_empty() and t - t0 < 180.0: return false
			_check(not info.is_empty(), "the city loaded and the start was placed (%.0f s)" % (t - t0))
			if info.is_empty(): step = 9; return false
			step = 2; t0 = t
		2:
			if t - t0 < 5.0: return false
			var w := current_scene
			var pl: Node3D = null; var bike: Node3D = w.get_node_or_null(^"StartBike"); var car: Node3D = w.get_node_or_null(^"StartCar")
			for c in w.get_children(): if c.get_class() == "CityPlayer": pl = c
			var centre: Vector3 = game.get_start_centre()
			_check(pl != null and Vector2(pl.global_position.x - centre.x, pl.global_position.z - centre.z).length() < 400.0, "the player is in the city centre: %s (%.0f m from its middle)" % [str(pl.global_position) if pl else "none", Vector2(pl.global_position.x - centre.x, pl.global_position.z - centre.z).length() if pl else -1.0])
			for pair in [["the player", pl], ["his bicycle", bike], ["the car", car]]:
				var n: Node3D = pair[1]
				if n == null: _check(false, "%s is there" % pair[0]); continue
				var skip := [n.get_rid()] if n is CollisionObject3D else []
				for o in [pl, bike, car]: if o is CollisionObject3D: skip.append(o.get_rid())
				var top := _sky(n.global_position, skip)
				_check(top > -900.0 and absf(top - n.global_position.y) < 0.8, "%s stands on the ground with nothing over it: ground %.2f, it at %.2f" % [pair[0], top, n.global_position.y])
			if OS.get_cmdline_user_args().has("--probe") and pl:
				for dz in range(-8, 9, 2):
					var row := ""
					for dx in range(-8, 9, 2):
						var y := _sky(pl.global_position + Vector3(dx, 0, dz), [])
						row += ("  ----" if y < -900.0 else " %5.2f" % y)
					print("START   probe z%+d:%s" % [dz, row])
			var people: Node = null
			for c in w.get_children(): if c.get_class() == "CityCrowd": people = c
			if car and people:
				var pv: Dictionary = people.call(&"pavement_near", car.global_position, 0.3)
				_check(not bool(pv.ok), "the car is on the road, not on the pavement")
			if pl and bike: _check(pl.global_position.distance_to(bike.global_position) < 3.0, "the bicycle is beside him (%.1f m)" % pl.global_position.distance_to(bike.global_position))
			if pl and car: _check(pl.global_position.distance_to(car.global_position) < 5.0, "the car is beside him (%.1f m)" % pl.global_position.distance_to(car.global_position))
			if pl and bike:
				var cam := Camera3D.new(); w.add_child(cam); cam.current = true
				var f := Vector3(sin(float(info.yaw)), 0, cos(float(info.yaw))); var side: Vector3 = info.road_side
				cam.look_at_from_position(pl.global_position - f * 4.5 - side * 1.5 + Vector3(0, 2.4, 0), bike.global_position + Vector3(0, 0.6, 0), Vector3.UP)
			step = 3; t0 = t
		3:
			if t - t0 < 0.5: return false
			DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://map_dc/coronado/city_kit/review/game_19nov"))
			root.get_viewport().get_texture().get_image().save_jpg(ProjectSettings.globalize_path("res://map_dc/coronado/city_kit/review/game_19nov/start.jpg"), 0.88)
			print("START picture review/game_19nov/start.jpg")
			step = 9
		9:
			print("RESULT %s" % ("PASS" if fails == 0 else "FAIL (%d)" % fails))
			quit(1 if fails else 0)
			return true
	return false
