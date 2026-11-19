extends SceneTree
## Makes the places people go: map_dc/coronado/city_kit/traffic/places.bin (home and shop doors, bench seats, bus
## stops, beach and park places, cafe seats, beggars' spots, night corners, gates).
## All the work is C++ (native/src/people_places.cpp, class PeoplePlaces); this script only calls it.
## It reads the layout, the pieces, the interiors' shop list and streets.bin: run it after make_streets.gd.
##   godot --path . --rendering-method mobile --resolution 320x180 -s res://tools/city/traffic/make_places.gd
## A real renderer is needed (the benches' meshes are read to see which way they face).
const OUT := "res://map_dc/coronado/city_kit/traffic/"

func _init() -> void:
	if not ClassDB.class_exists(&"PeoplePlaces"):
		print("PLACES ERROR the native module is not built: run  bash native/build.sh"); quit(1); return
	var p: Object = ClassDB.instantiate(&"PeoplePlaces")
	var rep: PackedStringArray = p.build(OUT + "streets.bin", "res://map_dc/coronado/city_kit/city_grid_layout.json", "res://map_dc/coronado/city_kit/pieces/", "res://map_dc/coronado/city_kit/interiors/assignment_all.json")
	for l in rep: print(l)
	if int(p.count()) == 0: quit(1); return
	p.save(OUT + "places.bin")
	var f := FileAccess.open(OUT + "places_report.txt", FileAccess.WRITE)
	f.store_string("\n".join(rep) + "\n"); f.close()
	print("PLACES saved %d places to %splaces.bin" % [int(p.count()), OUT])
	quit(0)
