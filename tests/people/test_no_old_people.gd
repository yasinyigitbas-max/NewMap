extends SceneTree
## No old people in the game (Yasin, 28 Nov: "there are still npcs from the old version, i need them to be out of the game
## entirely"; "not only the far away crowds, some near people are also old npcs"), a new game in the real city:
##   godot --path . --rendering-method mobile --resolution 640x360 -s res://tests/people/test_no_old_people.gd
## He walks ahead 30 s. Every half second: the far crowd draws nobody (CityCrowd stats "drawn"), no old figure (a CityPed
## whose mesh is drawn) is seen anywhere, and new bodies are seen near him (at least one, at some moment).
var game: Node
var t := 0.0
var t0 := 0.0
var step := 0
var fails := 0
var pl: Node3D
var crowd: Node
var samples := 0
var far_most := 0
var old_most := 0
var old_where := ""
var new_most := 0
var next_t := 0.0

func _check(ok: bool, what: String) -> void:
	if not ok: fails += 1
	print("NOOLD   %s: %s" % ["ok" if ok else "FAIL", what])

func _initialize() -> void:
	var boot := Node.new(); boot.name = "Boot"
	game = ClassDB.instantiate(&"CityGame")
	game.name = "Game"
	game.set(&"saves_dir", "user://noold_test_saves/")
	for f in DirAccess.get_files_at("user://noold_test_saves/"): DirAccess.remove_absolute("user://noold_test_saves/" + f)
	boot.add_child(game); root.add_child(boot); current_scene = boot

func _key(k: Key, down: bool) -> void:
	var e := InputEventKey.new(); e.keycode = k; e.physical_keycode = k; e.pressed = down
	Input.parse_input_event(e)

func _sample() -> void:
	samples += 1
	far_most = maxi(far_most, int((crowd.call(&"stats") as Dictionary).get("drawn", 0)))
	var old := 0
	for p in current_scene.find_children("*", "CityPed", true, false):
		var n := p as Node3D
		if not n.is_visible_in_tree(): continue
		for m in n.find_children("*", "MeshInstance3D", true, false):
			if (m as Node3D).is_visible_in_tree():
				old += 1
				if old_where == "": old_where = "%s at %.0f m" % [str(n.get_path()), n.global_position.distance_to(pl.global_position)]
				break
	old_most = maxi(old_most, old)
	var nb := 0
	for b in current_scene.find_children("*", "TravBody", true, false):
		if (b as Node3D).is_visible_in_tree() and b != pl.call(&"get_traversal_body"): nb += 1
	new_most = maxi(new_most, nb)

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
			for n in current_scene.find_children("*", "CityCrowd", true, false): crowd = n
			_check(pl != null and crowd != null, "the start: player and crowd")
			if pl == null or crowd == null: return _end()
			step = 2; t0 = t
		2:
			if t - t0 < 6.0: return false
			_key(KEY_W, true); step = 3; t0 = t
		3:
			if t >= next_t: _sample(); next_t = t + 0.5
			if t - t0 < 30.0: return false
			_key(KEY_W, false)
			_check(far_most == 0, "the far crowd draws nobody (most %d)" % far_most)
			_check(old_most == 0, "no old figure seen (most %d at once; first: %s)" % [old_most, old_where])
			_check(new_most > 0, "new bodies seen near him (most %d at once, %d samples)" % [new_most, samples])
			return _end()
	return false

func _end() -> bool:
	print("RESULT %s (%d failed)" % ["PASS" if fails == 0 else "FAIL", fails])
	quit(1 if fails > 0 else 0)
	return true
