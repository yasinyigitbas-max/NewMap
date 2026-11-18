extends SceneTree
## What a baked cell pulls in besides its own file (read-only): shaders, materials, textures and meshes, and which of
## them the streamer does NOT already hold from the start (manifest "keep", the far world, the warm-up scene). Anything
## in that last list is loaded and, for a shader, COMPILED the first time a cell with it arrives: on the phone one
## 60-350 ms frame at the same place in every run (18 Nov, cells -1_-3 / -1_-4).
##   godot --headless --path . -s res://tools/city/audit/cell_deps.gd -- -1_-3 -1_-4
const RT := "res://map_dc/coronado/city_kit/runtime/"

func _deps(path: String, seen: Dictionary) -> void:
	for d: String in ResourceLoader.get_dependencies(path):
		var p := d.get_slice("::", 2) if d.contains("::") else d
		if p == "" or seen.has(p): continue
		seen[p] = true
		_deps(p, seen)

func _init() -> void:
	var keys: PackedStringArray = OS.get_cmdline_user_args()
	if keys.is_empty(): keys = ["-1_-3", "-1_-4"]
	var man: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(RT + "manifest.json"))
	var held := {}
	for p: String in man.get("keep", []): held[p] = true; _deps(p, held)
	for p2: String in [RT + "far/far_world.scn", RT + "lib/warm.scn"]:
		if ResourceLoader.exists(p2): held[p2] = true; _deps(p2, held)
	print("DEPS held from the start: %d files (keep %d)" % [held.size(), (man.get("keep", []) as Array).size()])
	for k in keys:
		var seen := {}
		_deps(RT + "cells/cell_%s.scn" % k, seen)
		var by := {}; var new_by := {}; var new_list: Array = []
		for p3: String in seen:
			var ext := p3.get_extension()
			var kind := "shader" if ext in ["gdshader", "gdshaderinc"] else ("material" if ext == "tres" or p3.contains("/mat_") else ("texture" if ext in ["png", "jpg", "webp", "ctex"] else ("mesh/other res" if ext == "res" else ext)))
			by[kind] = int(by.get(kind, 0)) + 1
			if not held.has(p3):
				new_by[kind] = int(new_by.get(kind, 0)) + 1
				if kind in ["shader", "material", "texture", "gd"]: new_list.append(p3.trim_prefix("res://"))
		print("DEPS cell %s: %d files %s | not held from the start: %s" % [k, seen.size(), str(by), str(new_by)])
		new_list.sort()
		for p4: String in new_list: print("DEPS   not held: " + p4)
	quit()
