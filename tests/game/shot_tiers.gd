extends SceneTree
## Do the mid tiers of the buildings show in the game? (Yasin, 21 Nov: "im pretty confident that our mid tiers never show
## up in game and instead we are seeing far snap directly into near, skipping middle"):
##   godot --path . --rendering-method mobile --resolution 1280x720 -s res://tests/game/shot_tiers.gd
## A new game; once the start is in, every building's near is tinted green and its mid red (the instance tint the
## building shader multiplies by), the far world stays as it is. Pictures from the player's eye looking four ways, and a
## count of nears and mids in the loaded cells with their distance to the camera, to OUT/tiers_21nov/.
var game: Node
var t := 0.0
var t0 := 0.0
var step := 0
var pl: Node3D
var shot := 0
const OUT := "res://OUT/tiers_21nov/"

func _initialize() -> void:
	var boot := Node.new(); boot.name = "Boot"
	game = ClassDB.instantiate(&"CityGame")
	game.name = "Game"
	game.set(&"saves_dir", "user://tiers_test_saves/")
	for f in DirAccess.get_files_at("user://tiers_test_saves/"): DirAccess.remove_absolute("user://tiers_test_saves/" + f)
	boot.add_child(game); root.add_child(boot); current_scene = boot
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT))

func _tint() -> void:
	var cam := root.get_viewport().get_camera_3d()
	var n := {"near": 0, "mid": 0}
	var d_mid := []
	for mi in current_scene.find_children("*", "MeshInstance3D", true, false):
		var nm := String(mi.name)
		if nm == "near": (mi as MeshInstance3D).set_instance_shader_parameter(&"tint", Color(0.2, 1.0, 0.2)); n.near += 1
		elif nm == "mid":
			(mi as MeshInstance3D).set_instance_shader_parameter(&"tint", Color(1.0, 0.1, 0.1)); n.mid += 1
			if cam: d_mid.append(cam.global_position.distance_to((mi as MeshInstance3D).global_position))
	d_mid.sort()
	# --mode=onlymid: the nears and the far world hidden (only the mids draw); --mode=nomid: the mids hidden
	var mode := ""
	for a in OS.get_cmdline_user_args(): if a.begins_with("--mode="): mode = a.substr(7)
	if mode != "":
		for mi in current_scene.find_children("*", "MeshInstance3D", true, false):
			if mode == "onlymid" and String(mi.name) == "near": mi.visible = false
			if mode == "nomid" and String(mi.name) == "mid": mi.visible = false
		if mode == "onlymid":
			for st in current_scene.find_children("*", "CityStream", true, false):
				for ch in st.get_children(): if ch is Node3D and not String(ch.name).begins_with("cell"): (ch as Node3D).visible = false; print("TIERS   hid %s" % ch.name)
	var in_win := d_mid.filter(func(d: float) -> bool: return d >= 60.0 and d < 220.0).size()
	print("TIERS   loaded: %d nears, %d mids; mids 60-220 m from the camera: %d (nearest %.0f m)" % [n.near, n.mid, in_win, d_mid[0] if d_mid.size() > 0 else -1.0])

func _process(delta: float) -> bool:
	t += delta
	match step:
		0:
			if t < 1.0: return false
			game.press("menu.new_game"); step = 1; t0 = t
		1:
			if game.get_start_info().is_empty() and t - t0 < 180.0: return false
			for c in current_scene.get_children(): if c.get_class() == "CityPlayer": pl = c
			step = 2; t0 = t
		2:
			if t - t0 < 12.0: return false
			_tint(); step = 3; t0 = t
		3:
			if t - t0 < 0.5: return false
			var cam: Camera3D = current_scene.get_node_or_null(^"TierCam")
			if cam == null:
				cam = Camera3D.new(); cam.name = "TierCam"; cam.far = 3000.0; cam.fov = 70.0; current_scene.add_child(cam); cam.make_current()
			if cam and pl:
				cam.global_position = pl.global_position + Vector3(0, 12, 0)
				cam.global_rotation = Vector3(-0.12, shot * PI * 0.5, 0)
			step = 4; t0 = t
		4:
			if t - t0 < 0.6: return false
			root.get_viewport().get_texture().get_image().save_jpg(ProjectSettings.globalize_path(OUT + "look_%s%d.jpg" % [_mode(), shot]), 0.85)
			print("TIERS   picture look_%d.jpg" % shot)
			shot += 1
			if shot >= 4: quit(); return true
			step = 3; t0 = t
	return false

func _mode() -> String:
	for a in OS.get_cmdline_user_args(): if a.begins_with("--mode="): return a.substr(7) + "_"
	return ""
