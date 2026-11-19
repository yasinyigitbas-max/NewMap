extends SceneTree
## Pictures of the game shell's screens (C++: CityGame, ui_plate), with a renderer:
##   godot --path . --rendering-method mobile --resolution 1152x648 -s res://tests/game/menu_shots.gd
## Saves map_dc/coronado/city_kit/review/game_19nov/menu.jpg, settings.jpg, loading.jpg.
var game: Node
var t := 0.0
var step := 0
const OUT := "res://map_dc/coronado/city_kit/review/game_19nov/"

func _initialize() -> void:
	game = ClassDB.instantiate(&"CityGame")
	game.set(&"saves_dir", "user://shot_saves/")
	var boot := Node.new(); boot.add_child(game); root.add_child(boot)

func _shot(name: String) -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT))
	root.get_viewport().get_texture().get_image().save_jpg(ProjectSettings.globalize_path(OUT + name), 0.88)
	print("MENUSHOT saved %s%s (%s)" % [OUT, name, game.current_screen()])

func _process(delta: float) -> bool:
	t += delta
	if step == 0 and t > 1.0: _shot("menu.jpg"); game.press("menu.settings"); step = 1; t = 0.0
	elif step == 1 and t > 0.5: _shot("settings.jpg"); game.press("settings.back"); game.open_loading(); game.set_loading(0.62, "loading.building"); step = 2; t = 0.0
	elif step == 2 and t > 0.5: _shot("loading.jpg"); quit(0); return true
	return false
