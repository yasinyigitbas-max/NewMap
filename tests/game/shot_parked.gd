extends SceneTree
## A parked car close up, as the player sees it (Yasin, 21 Nov: "all of the cars parked cars have the same problem"):
##   godot --path . --rendering-method mobile --resolution 1280x590 -s res://tests/game/shot_parked.gd [-- --at=102,340]
## New game; the player is put where the S23's save stood (parked cars along the kerb); the parked cars within 30 m become
## the pool's real cars (CityCar, the ones you can take); pictures of the nearest from 4 m and 9 m, and the same car's
## materials, to OUT/tiers_21nov/parked_*.jpg.
var game: Node
var t := 0.0
var step := 0
var t0 := 0.0
var car: Node3D
var cam: Camera3D
var k := 0
var pl: Node3D
var at := Vector2(102, 340)
func _initialize() -> void:
	for a in OS.get_cmdline_user_args(): if a.begins_with("--at="): var p := a.substr(5).split(","); at = Vector2(float(p[0]), float(p[1]))
	var boot := Node.new(); boot.name = "Boot"
	game = ClassDB.instantiate(&"CityGame"); game.name = "Game"; game.set(&"saves_dir", "user://park_test_saves/")
	for f in DirAccess.get_files_at("user://park_test_saves/"): DirAccess.remove_absolute("user://park_test_saves/" + f)
	boot.add_child(game); root.add_child(boot); current_scene = boot
func _process(d: float) -> bool:
	t += d
	if step == 0 and t > 1.0: game.press("menu.new_game"); step = 1; t0 = t
	elif step == 1 and not game.get_start_info().is_empty(): step = 2; t0 = t
	elif step == 2 and t - t0 > 8.0:
		for c in current_scene.get_children(): if c.get_class() == "CityPlayer": pl = c
		pl.global_position = Vector3(at.x, 30.0, at.y); step = 3; t0 = t
	elif step == 3 and t - t0 > 12.0:
		for i in 4:
			pass
		root.get_viewport().get_texture().get_image().save_jpg(ProjectSettings.globalize_path("res://OUT/tiers_21nov/parked_game_cam.jpg"), 0.9)
		cam = Camera3D.new(); current_scene.add_child(cam); cam.make_current(); step = 4; t0 = t
	elif step == 4:
		cam.global_position = pl.global_position + Vector3(0, 1.8, 0)
		cam.rotation = Vector3(-0.15, k * PI * 0.5, 0)
		if t - t0 > 1.0:
			root.get_viewport().get_texture().get_image().save_jpg(ProjectSettings.globalize_path("res://OUT/tiers_21nov/parked_%d.jpg" % k), 0.9)
			k += 1; t0 = t
			if k >= 4: quit(); return true
	return false
