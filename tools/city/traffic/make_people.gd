extends SceneTree
## Poses the far figures of the crowd: characters/rocketbox/far_poses.bin (every body in 12 poses, one table).
## All the work is C++ (native/src/people_bake.cpp, class PeopleBake); this script only calls it.
## Run it when a body, the skeleton or a clip of characters/rocketbox changes (not after a bake of the map):
##   godot --path . --rendering-method mobile --resolution 320x180 -s res://tools/city/traffic/make_people.gd
## A real renderer is needed (the bodies' meshes are read).
const DIR := "res://characters/rocketbox/"

func _initialize() -> void:
	if not ClassDB.class_exists(&"PeopleBake"):
		print("PEOPLE ERROR the native module is not built: run  bash native/build.sh"); quit(1); return
	var b: Object = ClassDB.instantiate(&"PeopleBake")
	var rep: PackedStringArray = b.bake(root, DIR, DIR + "far_poses.bin")
	for l in rep: print(l)
	quit(0 if int(b.count()) > 0 else 1)
