extends SceneTree
## Holes in the city's collision on the roads and pavements (Yasin, 19 Nov: "so are there holes on the roads?" ...
## "do that now"). Headless:
##   godot --headless --path . -s res://tools/city/audit/collision_holes.gd [-- --area=x0,z0,x1,z1 --step=1.0]
## Every lane and junction path (the traffic's streets) and every pavement and crossing (the crowd's walks) as points a
## metre apart; the city streamed in cell by cell (the game's own streamer), each cell's collision waited for; then a ray
## straight down at every point (from 1.5 m over the drawn surface to 1.5 m under it, the world's layer). A point with no
## ground is a hole; neighbouring ones are one hole. Writes map_dc/coronado/city_kit/review/collision_holes_19nov/
## holes.txt (each hole: where, how big, road or pavement, which cell) and holes.json, and prints the totals.
## The work of finding the points is C++ (CityTraffic.lane_points, CityCrowd.walk_points); this only drives it.
const Stream := preload("res://tools/city/bake/city_stream.gd")
const OUT := "res://map_dc/coronado/city_kit/review/collision_holes_19nov/"
var st: Node
var traffic: Node
var crowd: Node
var cells_todo: Array = []          # [key, centre, points (PackedVector3Array), kinds (PackedByteArray)]
var ci := -1
var t_cell := 0.0
var holes: Array = []               # [x, y, z, kind, cell]
var checked := 0
var no_cell := 0
var t_all := 0.0
var area := Rect2(-5000, -5000, 10000, 10000)
var step := 1.0

func _initialize() -> void:
	for a: String in OS.get_cmdline_user_args():
		if a.begins_with("--area="): var f := a.trim_prefix("--area=").split_floats(","); area = Rect2(f[0], f[1], f[2] - f[0], f[3] - f[1])
		if a.begins_with("--step="): step = float(a.trim_prefix("--step="))
	st = Stream.new(); st.name = "City"; st.show_cells = false; st.col_range = 0.0; st.bodies_per_frame = 60; st.body_tris_per_frame = 60000; st.col_ms_per_frame = 40.0; st.max_cells = 12
	root.add_child(st)
	traffic = ClassDB.instantiate(&"CityTraffic")
	crowd = ClassDB.instantiate(&"CityCrowd")
	if not traffic.load_streets("res://map_dc/coronado/city_kit/traffic/streets.bin"):
		print("HOLES ERROR no streets"); quit(1); return
	root.add_child(crowd)      # (the crowd reads its pavements in _ready)

func _cell_of(p: Vector3) -> Vector2i: return Vector2i(floori(p.x / 200.0), floori(p.z / 200.0))

func _gather() -> void:
	var by: Dictionary = {}
	var pts: Array = [traffic.call(&"lane_points", step), crowd.call(&"walk_points", step)]
	for kind in 2:
		for p: Vector3 in pts[kind]:
			if not area.has_point(Vector2(p.x, p.z)): continue
			var c := _cell_of(p)
			if not by.has(c): by[c] = [PackedVector3Array(), PackedByteArray()]
			by[c][0].append(p); by[c][1].append(kind)
	for c: Vector2i in by:
		var key := "%d_%d" % [c.x, c.y]
		cells_todo.append([key, Vector3(c.x * 200.0 + 100.0, 0, c.y * 200.0 + 100.0), by[c][0], by[c][1]])
	cells_todo.sort_custom(func(a, b): return a[0] < b[0])
	print("HOLES %d points (lanes %d, walks %d) in %d cells of the area" % [(pts[0] as PackedVector3Array).size() + (pts[1] as PackedVector3Array).size(), (pts[0] as PackedVector3Array).size(), (pts[1] as PackedVector3Array).size(), cells_todo.size()])

func _ready_cell(key: String, c: Vector3) -> bool:
	if not st.cells.has(key) or int(st.cells[key].state) != 4: return false      # (4 = IN: the streamer's enum NONE, LOADING, BUILDING, READY, IN)
	return st.is_ready(c) and not st.busy() and (st.get(&"_pending") as Array).size() == 0

func _process(delta: float) -> bool:
	t_all += delta
	if ci == -1:
		if t_all < 1.0: return false
		_gather(); ci = 0; t_cell = 0.0
		if cells_todo.is_empty(): _finish(); return true
	var e: Array = cells_todo[ci]
	st.update_focus(e[1], true)
	t_cell += delta
	var known: bool = st.manifest.get("cells", {}).has(e[0]) if st.manifest.has("cells") else true
	if not known: no_cell += (e[2] as PackedVector3Array).size(); _next(); return false
	if not _ready_cell(e[0], e[1]) and t_cell < 25.0: return false
	var ss := root.get_world_3d().direct_space_state
	var q := PhysicsRayQueryParameters3D.new(); q.collision_mask = 1
	var pts: PackedVector3Array = e[2]; var kinds: PackedByteArray = e[3]
	for i in pts.size():
		var p := pts[i]
		q.from = p + Vector3(0, 1.5, 0); q.to = p - Vector3(0, 1.5, 0)
		if ss.intersect_ray(q).is_empty(): holes.append([p.x, p.y, p.z, kinds[i], e[0]])
		checked += 1
	if ci % 10 == 0: print("HOLES   cell %d / %d (%s): %d points, holes so far %d%s" % [ci + 1, cells_todo.size(), e[0], pts.size(), holes.size(), "" if t_cell < 25.0 else " (timed out waiting for its collision)"])
	_next()
	return false

func _next() -> void:
	ci += 1; t_cell = 0.0
	if ci >= cells_todo.size(): _finish()

func _finish() -> void:
	# neighbouring hole points (within 1.6 m) are one hole
	var n := holes.size()
	var parent := PackedInt32Array(); parent.resize(n)
	for i in n: parent[i] = i
	var grid := {}
	for i in n: var k := Vector2i(floori(holes[i][0] / 2.0), floori(holes[i][2] / 2.0)); if not grid.has(k): grid[k] = []; grid[k].append(i)
	var find := func(i: int) -> int:
		while parent[i] != i: parent[i] = parent[parent[i]]; i = parent[i]
		return i
	for i in n:
		var k := Vector2i(floori(holes[i][0] / 2.0), floori(holes[i][2] / 2.0))
		for dx in range(-1, 2):
			for dz in range(-1, 2):
				for j in grid.get(k + Vector2i(dx, dz), []):
					if j <= i: continue
					if Vector2(holes[i][0] - holes[j][0], holes[i][2] - holes[j][2]).length() < 1.6:
						var a: int = find.call(i); var b: int = find.call(j)
						if a != b: parent[a] = b
	var groups := {}
	for i in n: var r: int = find.call(i); if not groups.has(r): groups[r] = []; groups[r].append(i)
	var list: Array = []
	for r in groups:
		var g: Array = groups[r]
		var lo := Vector2(1e9, 1e9); var hi := Vector2(-1e9, -1e9); var road := 0; var walk := 0; var sy := 0.0
		for i in g:
			var p := Vector2(holes[i][0], holes[i][2]); lo = lo.min(p); hi = hi.max(p); sy += holes[i][1]
			if int(holes[i][3]) == 0: road += 1
			else: walk += 1
		var c := (lo + hi) * 0.5
		list.append({"x": snappedf(c.x, 0.1), "z": snappedf(c.y, 0.1), "y": snappedf(sy / g.size(), 0.01), "size_m": [snappedf(hi.x - lo.x + step, 0.1), snappedf(hi.y - lo.y + step, 0.1)], "points": g.size(), "road_points": road, "pavement_points": walk, "cell": holes[g[0]][4]})
	list.sort_custom(func(a, b): return a.points > b.points)
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT))
	var lines := PackedStringArray()
	lines.append("Holes in the collision on roads and pavements (tools/city/audit/collision_holes.gd), %s" % Time.get_datetime_string_from_system())
	lines.append("points checked %d (a ray down every %.1f m), hole points %d, holes %d; points in cells the manifest does not have: %d" % [checked, step, n, list.size(), no_cell])
	lines.append("biggest first: centre x, z (height) | size m | points (road / pavement) | cell")
	for h: Dictionary in list:
		lines.append("(%.1f, %.1f) y %.2f | %.1f x %.1f m | %d (%d road, %d pavement) | cell %s" % [h.x, h.z, h.y, h.size_m[0], h.size_m[1], h.points, h.road_points, h.pavement_points, h.cell])
	var f := FileAccess.open(OUT + "holes.txt", FileAccess.WRITE); f.store_string("\n".join(lines) + "\n"); f.close()
	var j := FileAccess.open(OUT + "holes.json", FileAccess.WRITE); j.store_string(JSON.stringify(list, "\t")); j.close()
	var road_h := 0; var walk_h := 0
	for h: Dictionary in list:
		if int(h.road_points) > 0: road_h += 1
		if int(h.pavement_points) > 0: walk_h += 1
	print("HOLES done in %.0f s: %d points checked, %d holes (%d touch a road, %d a pavement); the biggest: %s" % [t_all, checked, list.size(), road_h, walk_h, str(list.slice(0, 5))])
	print("HOLES written %sholes.txt" % OUT)
	quit(0)
