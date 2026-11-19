extends SceneTree
## The BAKED GROUND of the whole city on the terrain grid's own points (4 m), written out for the terrain check
## (tools/city/traffic/ground_vs_terrain.py compares it with zoning/terrain_grid.npz):
##   godot --headless --path . -s res://tools/city/traffic/ground_vs_terrain.gd
## Writes OUT/ground_grid.f32 (height, surface layer per point; NaN = no baked ground there) and OUT/ground_grid.json.
## Needs the bake (map_dc/coronado/city_kit/runtime) and the native module.
func _init() -> void:
	if not ClassDB.class_exists(&"StreetGraph"):
		print("GROUND ERROR the native module is not built"); quit(1); return
	var g: Object = ClassDB.instantiate(&"StreetGraph")
	var n: int = g.load_bake("res://map_dc/coronado/city_kit/runtime/")
	var x0 := -1600.0; var z0 := -1900.0; var x1 := 1700.0; var z1 := 760.0; var step := 4.0
	var a: PackedFloat32Array = g.height_grid(x0, z0, x1, z1, step)
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://OUT"))
	var f := FileAccess.open("res://OUT/ground_grid.f32", FileAccess.WRITE); f.store_buffer(a.to_byte_array()); f.close()
	var j := FileAccess.open("res://OUT/ground_grid.json", FileAccess.WRITE)
	j.store_string(JSON.stringify({"x0": x0, "z0": z0, "step": step, "nx": int(floor((x1 - x0) / step)) + 1, "ny": int(floor((z1 - z0) / step)) + 1, "cells": n})); j.close()
	print("GROUND wrote %d points from %d cells" % [a.size() / 2, n])
	quit()
