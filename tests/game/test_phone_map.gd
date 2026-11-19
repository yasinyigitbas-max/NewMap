extends SceneTree
## The phone's map in the real city (C++: HudMap in CityHud; CityTraffic / CityCrowd map_lines, map_rooms, route), in a window:
##   godot --path . --rendering-method mobile --resolution 1152x648 -s res://tests/game/test_phone_map.gd [-- --at=x,z]
## The streets, traffic and crowd round a place; the player on foot there; the HUD (without the shell). The map opens
## out of the arrow box: the roads, pavements and crossings of the new layout drawn, the enterable rooms marked (Yasin:
## "make sure all the enterable rooms appear in it and be routable to, actually up to 3 targets should be routable and
## kept"); four rooms tapped: three kept as targets (the first dropped), each with its way. One picture: OUT/phone_map.png.
var traffic: Node3D
var crowd: Node3D
var player: CharacterBody3D
var hud: CanvasLayer
var map: Control
var at := Vector3(-600, 0, -1000)
var t := 0.0
var t0 := 0.0
var step := 0
var fails := 0
var picked := []

func _check(ok: bool, what: String) -> void:
	if not ok: fails += 1
	print("MAP     %s: %s" % ["ok" if ok else "FAIL", what])

func _initialize() -> void:
	for a: String in OS.get_cmdline_user_args():
		if a.begins_with("--at="):
			var f := a.trim_prefix("--at=").split_floats(","); at = Vector3(f[0], 0, f[1])
	RenderingServer.global_shader_parameter_add(&"refl_env", RenderingServer.GLOBAL_VAR_TYPE_VEC2, Vector2(1.0, 0.0))
	traffic = ClassDB.instantiate(&"CityTraffic"); traffic.set(&"max_cars", 30); root.add_child(traffic)
	crowd = ClassDB.instantiate(&"CityCrowd"); crowd.set(&"max_people", 30); root.add_child(crowd)
	crowd.call(&"set_traffic", traffic)
	var g := StaticBody3D.new(); var cs := CollisionShape3D.new(); var sh := BoxShape3D.new(); sh.size = Vector3(400, 2, 400); cs.shape = sh; g.add_child(cs); g.position = at + Vector3(0, 5.0, 0); root.add_child(g)
	player = ClassDB.instantiate(&"CityPlayer"); player.position = at + Vector3(0, 6.2, 0); root.add_child(player)
	crowd.call(&"set_player", player)
	hud = ClassDB.instantiate(&"CityHud"); root.add_child(hud)
	hud.call(&"set_player", player); hud.call(&"set_world", crowd, traffic)

func _process(_delta: float) -> bool:
	t += _delta
	match step:
		0:
			if t < 8.0: return false
			hud.call(&"press", 0)   # the arrow box: the map
			step = 1; t0 = t
		1:
			if float(hud.call(&"get_anim")) < 1.0 and t - t0 < 2.0: return false
			map = hud.call(&"get_map")
			step = 2; t0 = t
		2:
			if t - t0 < 0.5: return false
			_check(int(map.call(&"get_road_lines")) > 1000 and int(map.call(&"get_walk_lines")) > 1000, "the new streets on the map: %d road lines, %d pavement lines" % [int(map.call(&"get_road_lines")), int(map.call(&"get_walk_lines"))])
			_check(int(map.call(&"get_rooms")) > 50, "the enterable rooms marked: %d" % int(map.call(&"get_rooms")))
			# four rooms on screen nearest the middle, tapped in turn
			var mid: Vector2 = map.size * 0.5
			var cand := []
			for i in int(map.call(&"get_rooms")):
				var q: Vector2 = map.call(&"room_screen", i)
				if q.x > 30 and q.y > 30 and q.x < map.size.x - 30 and q.y < map.size.y - 30: cand.append([q.distance_to(mid), i, q])
			cand.sort_custom(func(a, b): return a[0] < b[0])
			_check(cand.size() >= 4, "%d rooms on the open map" % cand.size())
			var used := []
			for c in cand:
				var far := true
				for u in used: if (u as Vector2).distance_to(c[2]) < 40.0: far = false
				if far: used.append(c[2])
				if used.size() == 4: break
			for q in used: map.call(&"tap", q)
			picked = used
			step = 3; t0 = t
		3:
			if t - t0 < 0.6: return false
			_check(int(map.call(&"get_target_count")) == 3, "four rooms tapped: three kept as targets (the oldest dropped): %d" % int(map.call(&"get_target_count")))
			var routed := 0
			for k in 3: if int(map.call(&"get_target_route_points", k)) >= 2: routed += 1
			_check(routed == 3, "each target has its way: %d of 3 routed (%d, %d, %d points)" % [routed, int(map.call(&"get_target_route_points", 0)), int(map.call(&"get_target_route_points", 1)), int(map.call(&"get_target_route_points", 2))])
			var im := root.get_texture().get_image(); im.save_png("res://OUT/phone_map.png")
			map.call(&"tap", picked[3])
			step = 4; t0 = t
		4:
			if t - t0 < 0.3: return false
			_check(int(map.call(&"get_target_count")) == 2, "a target tapped again is dropped: %d left" % int(map.call(&"get_target_count")))
			print("RESULT %s" % ("PASS" if fails == 0 else "FAIL (%d)" % fails))
			quit(1 if fails else 0)
			return true
	return false
