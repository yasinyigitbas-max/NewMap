extends SceneTree
## The HUD (C++: CityHud, HudArrow, CityGame's objective and health / needs), in a window:
##   godot --path . --rendering-method mobile --resolution 1152x648 -s res://tests/game/test_hud.gd
## A new game in a small world with the player. Checks: the four boxes are the phone button's size in the four corners;
## money and the clock in the top left; the arrow gold to the north with no objective, green to an objective (an
## objective to the camera's right: the arrow turns a quarter right); the arrow box and the phone button open the phone,
## the inventory box the weapons (none), each growing out of its box over several frames, a tick and a vibration each
## touch, closing back; health and needs are hidden (inactive). One picture: OUT/hud.png (the weapons open: OUT/hud_inv.png).
var game: Node
var hud: Node
var t := 0.0
var t0 := 0.0
var step := 0
var fails := 0
var frames := 0
var cam: Camera3D
const DIR := "user://test_hud_saves/"

func _check(ok: bool, what: String) -> void:
	if not ok: fails += 1
	print("HUD     %s: %s" % ["ok" if ok else "FAIL", what])

func _initialize() -> void:
	DirAccess.make_dir_recursive_absolute(DIR)
	for f in DirAccess.get_files_at(DIR): DirAccess.remove_absolute(DIR + f)
	game = ClassDB.instantiate(&"CityGame")
	game.set(&"saves_dir", DIR); game.set(&"world_scene", "res://tests/game/picture_world.tscn"); game.set(&"autosave_s", 0.0)
	game.connect(&"play_started", func(_s: int) -> void:
		var pl := current_scene.get_node_or_null("Player") if current_scene else null
		if pl: game.set_player(pl))
	root.add_child(game)

func _process(delta: float) -> bool:
	t += delta
	match step:
		0:
			if t < 0.5: return false
			game.press("menu.new_game"); step = 1; t0 = t
		1:
			if not game.is_playing() and t - t0 < 30.0: return false
			hud = game.get_hud()
			step = 2; t0 = t
		2:
			if t - t0 < 1.5: return false
			var sz := root.get_visible_rect().size
			var k := minf(sz.x / 1152.0, sz.y / 648.0)
			var names := ["arrow (top right)", "phone (bottom right)", "inventory (bottom left)", "money and clock (top left)"]
			var corners := [Vector2(sz.x - 100 * k, 24 * k), Vector2(sz.x - 100 * k, sz.y - 100 * k), Vector2(24 * k, sz.y - 100 * k), Vector2(24 * k, 24 * k)]
			for w in 4:
				var r: Rect2 = hud.box_rect(w)
				_check(r.size.distance_to(Vector2(76, 76) * k) < 1.0 and r.position.distance_to(corners[w]) < 1.5, "the %s box: %s, the phone button's size" % [names[w], str(r)])
			_check(String(hud.get_money_text()) == "$50" and String(hud.get_time_text()).length() == 5, "money and the clock: %s  %s" % [hud.get_money_text(), hud.get_time_text()])
			_check(not bool(hud.get_arrow_objective()), "no objective: the arrow is gold, to the north (%.0f deg from straight ahead)" % rad_to_deg(float(hud.get_arrow_angle())))
			cam = root.get_viewport().get_camera_3d()
			game.set_objective(cam.global_position + cam.global_basis.x * 60.0)
			_check(not bool(game.get_needs_active()), "health and needs: kept, inactive (their bars hidden)")
			step = 3; t0 = t
		3:
			if t - t0 < 0.3: return false
			var a := float(hud.get_arrow_angle())
			_check(bool(hud.get_arrow_objective()) and absf(a - PI * 0.5) < 0.12, "an objective to the camera's right: the arrow is green and points right (%.0f deg)" % rad_to_deg(a))
			var im := root.get_texture().get_image(); im.save_png("res://OUT/hud.png")
			hud.press(0); frames = 0
			step = 4; t0 = t
		4:      # the phone grows out over several frames
			if float(hud.get_anim()) > 0.0 and float(hud.get_anim()) < 1.0: frames += 1
			if float(hud.get_anim()) < 1.0 and t - t0 < 2.0: return false
			_check(int(hud.get_open()) == 0 and frames >= 5, "the arrow box opens the phone (its map): it grew out over %d frames" % frames)
			hud.press(3); step = 5; t0 = t
		5:
			if int(hud.get_open()) >= 0 and t - t0 < 2.0: return false
			_check(int(hud.get_open()) == -1, "closed back into its box (%.2f s)" % (t - t0))
			hud.press(2); frames = 0; step = 6; t0 = t
		6:
			if float(hud.get_anim()) > 0.0 and float(hud.get_anim()) < 1.0: frames += 1
			if float(hud.get_anim()) < 1.0 and t - t0 < 2.0: return false
			_check(int(hud.get_open()) == 1 and frames >= 5, "the inventory box opens the weapons (none yet), over %d frames" % frames)
			step = 7; t0 = t
		7:
			if t - t0 < 0.3: return false
			var im := root.get_texture().get_image(); im.save_png("res://OUT/hud_inv.png")
			hud.press(3)
			_check(int(hud.get_taps()) == 4, "each touch a tick and a vibration: %d touches" % int(hud.get_taps()))
			hud.press(1); step = 8; t0 = t
		8:
			if float(hud.get_anim()) < 1.0 and t - t0 < 2.0: return false
			_check(int(hud.get_open()) == 0, "the phone button opens the phone")
			# the player's map targets are kept in the save
			var tg := []
			for k in 3: tg.append({"x": 10.0 * k, "z": -5.0 * k, "name": "Room %d" % k})
			game.set_map_targets(tg)
			game.save(); game.set_map_targets([]); game.load_slot(int(game.get_active_slot()))
			_check((game.get_map_targets() as Array).size() == 3 and String((game.get_map_targets() as Array)[2].name) == "Room 2", "the three map targets are kept in the save (saved, cleared, loaded: %d)" % (game.get_map_targets() as Array).size())
			var im := root.get_texture().get_image(); im.save_png("res://OUT/hud_phone.png")
			print("RESULT %s" % ("PASS" if fails == 0 else "FAIL (%d)" % fails))
			quit(1 if fails else 0)
			return true
	return false
