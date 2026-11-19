extends SceneTree
## The spots in the sea where the people of the beach swim, added to the places that are there already
## (traffic/places.bin), from the sea's own depth map. The work is C++ (class PeoplePlaces, add_swim); this only calls it.
## make_places.gd does the same at its end: run THIS when only the sea map changed, or to add the spots without
## reading the whole baked city again:
##   godot --headless --path . -s res://tools/city/traffic/make_swim.gd
const OUT := "res://map_dc/coronado/city_kit/traffic/"

func _init() -> void:
	if not ClassDB.class_exists(&"PeoplePlaces"):
		print("PLACES ERROR the native module is not built: run  bash native/build.sh"); quit(1); return
	var p: Object = ClassDB.instantiate(&"PeoplePlaces")
	var rep: PackedStringArray = p.add_swim(OUT + "places.bin", "res://tools/city/look/sea_map.png", "res://tools/city/look/sea_map.json")
	for l in rep: print(l)
	if int(p.count()) == 0: quit(1); return
	p.save(OUT + "places.bin")
	var f := FileAccess.open(OUT + "places_report.txt", FileAccess.READ_WRITE)
	if f:
		var keep := PackedStringArray()
		for l: String in f.get_as_text().split("\n", false):
			if not l.begins_with("PLACES swim"): keep.append(l)
		keep.append_array(rep)
		f.resize(0); f.seek(0); f.store_string("\n".join(keep) + "\n"); f.close()
	print("PLACES saved %d places to %splaces.bin" % [int(p.count()), OUT])
	quit(0)
