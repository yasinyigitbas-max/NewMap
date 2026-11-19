extends SceneTree
## Makes the streets as traffic and people use them: map_dc/coronado/city_kit/traffic/streets.bin
## (lanes, stop lines, the paths through the junctions, pavements, crossings, parking stalls).
## All the work is C++ (native/src/street_*.cpp, class StreetGraph); this script only calls it and saves the pictures.
## It reads the BAKED city (city_kit/runtime) and the locked skeleton (review/sites.json): run it after every bake.
##   godot --path . --rendering-method mobile --resolution 320x180 -s res://tools/city/traffic/make_streets.gd [-- --nopics]
## A real renderer is needed (the cells' meshes are read back). Needs the native module (bash native/build.sh).
## Prints "STREETS ..." lines; the whole report goes to city_kit/traffic/streets_report.txt. The CHECK lines must all
## say 0 where they say "must be 0": no lane, no path through a junction and no pavement line may leave its surface.
const OUT := "res://map_dc/coronado/city_kit/traffic/"
const PICS := "res://map_dc/coronado/city_kit/review/traffic/"
## check pictures: name, x0, z0, x1, z1, metres a pixel
const VIEWS := [["city", -1100.0, -1700.0, 1300.0, 420.0, 2.0],
	["junction_stop_residential", -860.0, -1060.0, -740.0, -940.0, 0.125], ["junction_signals_arterial", 440.0, -1260.0, 560.0, -1140.0, 0.125],
	["junction_signals_amber_8th", -50.0, -850.0, 50.0, -750.0, 0.1], ["junction_centre_amber_7th", -40.0, -640.0, 40.0, -560.0, 0.1],
	["junction_t_on_the_ring", -860.0, 230.0, -740.0, 350.0, 0.125], ["junction_truck_streets", -860.0, -1460.0, -740.0, -1340.0, 0.125],
	["waterfront_curve", 440.0, 140.0, 700.0, 420.0, 0.3], ["street_widens_3rd_st", -700.0, -1430.0, -620.0, -1370.0, 0.1],
	["bridge_and_ramp", 640.0, -1420.0, 1200.0, -880.0, 0.6], ["hole_in_1st_st", 300.0, -1660.0, 460.0, -1540.0, 0.2]]

func _init() -> void:
	if not ClassDB.class_exists(&"StreetGraph"):
		print("STREETS ERROR the native module is not built: run  bash native/build.sh"); quit(1); return
	var g: Object = ClassDB.instantiate(&"StreetGraph")
	var t0 := Time.get_ticks_msec()
	var cells: int = g.load_bake("res://map_dc/coronado/city_kit/runtime/")
	if cells == 0:
		print("STREETS ERROR no baked city (map_dc/coronado/city_kit/runtime): bake first"); quit(1); return
	var st: Dictionary = g.stats()
	print("STREETS read %d baked cells in %.0f s: %d ground triangles, %d stalls, %d signal heads" % [cells, (Time.get_ticks_msec() - t0) / 1000.0, int(st.ground_triangles), int(st.stalls), int(st.signal_heads)])
	var rep: PackedStringArray = g.build("res://map_dc/coronado/city_kit/review/sites.json")
	DirAccess.make_dir_recursive_absolute(OUT)
	var head := "# streets report, made by tools/city/traffic/make_streets.gd from the bake with layout_sha %s (%d cells)\n" % [_bake_sha(), cells]
	var f := FileAccess.open(OUT + "streets_report.txt", FileAccess.WRITE); f.store_string(head + "\n".join(rep) + "\n"); f.close()
	for l: String in rep:
		if l.begins_with("TOTAL") or l.begins_with("CHECK") or l.begins_with("HOLE") or l.begins_with("CORNER") or l.begins_with("LANES NOT") or l.begins_with("PATH") or l.begins_with("PAVEMENT LINE") or l.begins_with("STREETS ERROR"):
			print("STREETS " + l)
	if not g.save(OUT + "streets.bin"):
		print("STREETS ERROR could not write streets.bin"); quit(1); return
	print("STREETS wrote %sstreets.bin (%d bytes)" % [OUT, FileAccess.get_file_as_bytes(OUT + "streets.bin").size()])
	if not ("--nopics" in OS.get_cmdline_user_args()):
		DirAccess.make_dir_recursive_absolute(PICS)
		if not FileAccess.file_exists(PICS + ".gdignore"):
			var gi := FileAccess.open(PICS + ".gdignore", FileAccess.WRITE); gi.close()
		for v: Array in VIEWS:
			(g.lanes_image(float(v[1]), float(v[2]), float(v[3]), float(v[4]), float(v[5])) as Image).save_png(PICS + String(v[0]) + ".png")
		print("STREETS pictures: %d in %s" % [VIEWS.size(), PICS])
	print("STREETS done")
	quit()

func _bake_sha() -> String:
	var m: Variant = JSON.parse_string(FileAccess.get_file_as_string("res://map_dc/coronado/city_kit/runtime/manifest.json"))
	return String((m as Dictionary).get("layout_sha", "?")).left(12) if m is Dictionary else "?"
