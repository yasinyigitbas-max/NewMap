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
var seated_t := 0.0
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
				if pl.get_traversal_body() is CollisionObject3D: skip.append(pl.get_traversal_body().get_rid())      # (28 Nov: on the traversal body the ray met his own capsule's top)
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
			step = 4; t0 = t
		4:      # THE USE BUTTON (Yasin: "make the use button as big as phone and map boxes, vibrates and makes sound when used")
			var hud: Node = game.get_hud()
			var w := current_scene
			var pl: Node3D = null
			for c in w.get_children(): if c.get_class() == "CityPlayer": pl = c
			var bike: Node3D = w.get_node_or_null(^"StartBike"); var car: Node3D = w.get_node_or_null(^"StartCar")
			if t - t0 < 0.5: return false
			var sz := root.get_visible_rect().size; var k := minf(sz.x / 1152.0, sz.y / 648.0)
			var r: Rect2 = hud.box_rect(4)
			_check(r.size.distance_to(Vector2(76, 76) * k) < 1.0, "the Use button is the phone button's size, under the arrow box: %s" % str(r))
			_check(int(hud.get_use_kind()) == 3, "by his bicycle the Use button offers GET ON (%d)" % int(hud.get_use_kind()))
			var taps0 := int(hud.get_taps())
			hud.press_use()
			_check(int(hud.get_taps()) == taps0 + 1 and int(hud.get_open()) == -1, "a tap: a tick and a vibration, and nothing opens")
			step = 5; t0 = t
		5:
			var hud: Node = game.get_hud(); var bike: Node3D = current_scene.get_node_or_null(^"StartBike")
			if t - t0 < 2.5: return false
			_check(int(bike.get_ride_state()) == 2 and int(hud.get_use_kind()) == 4, "he got on and rides (the button now says GET OFF)")
			# (Yasin: "bike doesnt move", "our character becomes a grey person"): the pedal held 3 s; a picture of the rider
			var kw := InputEventKey.new(); kw.keycode = KEY_W; kw.physical_keycode = KEY_W; kw.pressed = true; Input.parse_input_event(kw)
			step = 51; t0 = t
		51:
			var bike: Node3D = current_scene.get_node_or_null(^"StartBike")
			if t - t0 < 3.0: return false
			var sp := float((bike.get_state() as Dictionary).speed)
			var cam := Camera3D.new(); current_scene.add_child(cam); cam.current = true
			cam.look_at_from_position(bike.global_position + bike.global_basis.x * 3.0 + Vector3(0, 1.4, 0), bike.global_position + Vector3(0, 0.9, 0), Vector3.UP)
			_check(sp > 2.0, "pedalling 3 s, the bicycle goes: %.1f m/s" % sp)
			if sp <= 2.0: print("START     the bicycle's state: %s" % str(bike.get_state()))
			var kw := InputEventKey.new(); kw.keycode = KEY_W; kw.physical_keycode = KEY_W; kw.pressed = false; Input.parse_input_event(kw)
			step = 52; t0 = t
		52:
			var hud: Node = game.get_hud(); var bike: Node3D = current_scene.get_node_or_null(^"StartBike")
			if t - t0 < 0.3: return false
			root.get_viewport().get_texture().get_image().save_png("res://OUT/start_bike_rider.png")
			if float((bike.get_state() as Dictionary).speed) > 1.0 and t - t0 < 6.0: return false   # (stopped before getting off)
			hud.press_use()
			step = 6; t0 = t
		6:
			var hud: Node = game.get_hud(); var bike: Node3D = current_scene.get_node_or_null(^"StartBike"); var car: Node3D = current_scene.get_node_or_null(^"StartCar")
			if t - t0 < 2.5: return false
			var pl: Node3D = null
			for c in current_scene.get_children(): if c.get_class() == "CityPlayer": pl = c
			_check(int(bike.get_ride_state()) == 0 and pl.visible, "off again, on foot")
			# to the car's door
			var side := car.global_basis.x.normalized()
			pl.stand_at(car.global_position + side * 1.6 + Vector3(0, 0.15, 0), float(pl.get_view()[0]))      # (stand_at: on the traversal body the node alone does not move him, 28 Nov)
			step = 7; t0 = t
		7:
			var hud: Node = game.get_hud(); var car: Node3D = current_scene.get_node_or_null(^"StartCar")
			if t - t0 < 0.6: return false
			_check(int(hud.get_use_kind()) == 1, "at the car's door the Use button offers GET IN (%d)" % int(hud.get_use_kind()))
			hud.press_use()
			step = 8; t0 = t
		8:
			var hud: Node = game.get_hud(); var car: Node3D = current_scene.get_node_or_null(^"StartCar")
			if t - t0 < 0.6 or (not bool(car.call(&"is_seated")) and t - t0 < 20.0): seated_t = t; return false
			if t - seated_t < 0.5: return false   # (he walks to the door, opens it, sits in, closes it)
			var pl: Node3D = null
			for c in current_scene.get_children(): if c.get_class() == "CityPlayer": pl = c
			print("START   (car: entry state %d, seated %s, wheel his %s; player visible %s; use kind %d; %.1f s)" % [int(car.call(&"get_entry_state")), str(car.call(&"is_seated")), str(car.get(&"player")), str(pl.visible), int(hud.get_use_kind()), t - t0])
			_check(bool(car.get(&"player")) and not pl.visible and int(hud.get_use_kind()) == 2, "in the car: the wheel is his, the button says GET OUT")
			hud.press_use()
			step = 10; t0 = t
		10:
			var hud: Node = game.get_hud(); var car: Node3D = current_scene.get_node_or_null(^"StartCar")
			if t - t0 < 0.6 or (int(car.call(&"get_entry_state")) != 0 and t - t0 < 15.0): return false   # (the door opens, he gets out, it closes)
			var pl: Node3D = null
			for c in current_scene.get_children(): if c.get_class() == "CityPlayer": pl = c
			_check(not bool(car.get(&"player")) and pl.visible and pl.global_position.distance_to(car.global_position) < 3.0, "out again beside the car (%.1f m), on foot; %d uses" % [pl.global_position.distance_to(car.global_position), int(hud.get_uses())])
			step = 9
		9:
			print("RESULT %s" % ("PASS" if fails == 0 else "FAIL (%d)" % fails))
			quit(1 if fails else 0)
			return true
	return false
