extends SceneTree
## Pictures of the fill (21 Nov). The RAW pieces of the layout near the cameras (OUT/fill/piece_bounds.json: every
## piece whose ground is within --radius of the cameras' centre, plus the overlays with no ground: trees, wires), the
## fill pieces with FILL=1, the look (its sky, light, haze and the C++ sea) at --hour. No streamer, no bake.
##   xvfb-run -a godot --path . --rendering-method mobile --rendering-driver vulkan -s res://tools/city/fill/fill_shots.gd --
##       --out=/abs/dir --radius=450 --cams=name:x,y,z:tx,ty,tz;...     (env FILL=1|0)
const K := preload("res://tools/city/pilot/kit_lib.gd")
const Look := preload("res://tools/city/look/look.gd")
var out := "/tmp/fill_shots"
var cams: Array = []
var radius := 450.0
var hour := 10.5
var size := Vector2i(1600, 900)

func _init() -> void: _run.call_deferred()

func _v(s: String) -> Vector3:
	var p := s.split(","); return Vector3(float(p[0]), float(p[1]), float(p[2]))

func _run() -> void:
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--out="): out = a.trim_prefix("--out=")
		elif a.begins_with("--radius="): radius = float(a.trim_prefix("--radius="))
		elif a.begins_with("--hour="): hour = float(a.trim_prefix("--hour="))
		elif a.begins_with("--cams="):
			for c in a.trim_prefix("--cams=").split(";", false):
				var p := c.split(":"); cams.append([p[0], _v(p[1]), _v(p[2])] + ([float(p[3])] if p.size() > 3 else []))
	DirAccess.make_dir_recursive_absolute(out)
	root.size = size
	var ctr := Vector2.ZERO
	for c: Array in cams: ctr += Vector2((c[1] as Vector3).x, (c[1] as Vector3).z) * 0.5 + Vector2((c[2] as Vector3).x, (c[2] as Vector3).z) * 0.5
	ctr /= maxf(cams.size(), 1)
	var bounds: Array = JSON.parse_string(FileAccess.get_file_as_string("res://OUT/fill/piece_bounds.json"))
	var lay: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://map_dc/coronado/city_kit/city_grid_layout.json"))
	var world := Node3D.new(); world.name = "World"; root.add_child(world)
	var n := 0
	var rows: Array = lay.instances
	for i in rows.size():
		if i >= bounds.size(): continue      # (the fill's own rows: FILL=1 below)
		var r: Dictionary = rows[i]; var b: Array = bounds[i]
		if b[1] != null:
			var dx := maxf(maxf(float(b[1]) - ctr.x, ctr.x - float(b[3])), 0.0); var dz := maxf(maxf(float(b[2]) - ctr.y, ctr.y - float(b[4])), 0.0)
			if Vector2(dx, dz).length() > radius: continue
		elif OS.get_environment("OVERLAYS") == "0": continue
		_place(world, r); n += 1
	var nf := 0
	if OS.get_environment("FILL") == "1":
		var idx: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://OUT/fill/pieces/index.json"))
		for name: String in idx.pieces:
			var m: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://OUT/fill/pieces/%s.json" % name))
			var c := Vector2((float(m.cell[0]) + 0.5) * 200.0, (float(m.cell[1]) + 0.5) * 200.0)
			if c.distance_to(ctr) > radius + 150.0: continue
			if not ResourceLoader.exists("res://map_dc/coronado/city_kit/pieces/%s.scn" % name): continue
			_place(world, {"piece": name}); nf += 1
	var look := Look.new(); look.sea = true; look.cycle = 0.0
	root.add_child(look)
	look.set_hour(hour) if look.has_method("set_hour") else null
	# the backstop under everything, as in the game (rig.gd)
	world.add_child(ClassDB.class_call_static(&"CitySea", &"make_backstop", 6000.0, -2.0))
	for w: Node in world.find_children("*pond_*", "GeometryInstance3D", true, false):
		(w as GeometryInstance3D).material_override = ClassDB.class_call_static(&"CitySea", &"get_sea_material")
	print("FILLSHOTS pieces %d fill %d centre %s" % [n, nf, str(ctr)])
	var cam := Camera3D.new(); cam.far = 6000.0; cam.near = 0.1; root.add_child(cam)
	for c: Array in cams:
		cam.fov = float(c[3]) if c.size() > 3 else 62.0
		cam.position = c[1]; cam.look_at(c[2], Vector3.UP)
		for f in 14: await process_frame
		var img := root.get_texture().get_image()
		img.save_jpg(out.path_join(String(c[0]) + ".jpg"), 0.9)
		print("FILLSHOTS shot ", c[0])
	quit()

func _place(world: Node3D, r: Dictionary) -> void:
	var path := "res://map_dc/coronado/city_kit/pieces/%s.scn" % String(r.piece)
	if not ResourceLoader.exists(path): return
	var inst: Node3D = (load(path) as PackedScene).instantiate()
	var p: Array = r.get("pos", [0, 0, 0])
	inst.position = Vector3(float(p[0]), float(p[1]), float(p[2])); inst.rotation_degrees.y = float(r.get("yaw", 0))
	world.add_child(inst)
