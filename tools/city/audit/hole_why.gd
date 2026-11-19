extends SceneTree
## Why is there a hole? (19 Nov, the collision-holes job: "for each hole, find WHY before fixing"). Reads only.
##   godot --headless --path . -s res://tools/city/audit/hole_why.gd -- [--holes=res://.../holes.json] [--out=res://OUT/hole_why.json]
## For every hole of collision_holes.gd it puts the RAW pieces of the layout that reach the spot (the locked .scn files,
## not the bake) into an empty world, at their layout place, and casts the same ray down (1.5 m over to 1.5 m under the
## drawn surface). Then:
##   raw hit, mask 1          the pieces are whole there: the hole is made by the BAKE (or the streamer)
##   raw hit only on another layer   the ground is there but on a layer the world's ray (mask 1) does not see
##   no raw hit                the PIECES leave the hole: for each piece near it, the nearest ground triangle (its
##                             distance across, its height) says what is missing (a gap between two pieces, a corner ...)
## Also printed: how far the spot is from the nearest 200 m cell border.
const LAYOUT := "res://map_dc/coronado/city_kit/city_grid_layout.json"
const PIECES := "res://map_dc/coronado/city_kit/pieces/"
var holes_path := "res://map_dc/coronado/city_kit/review/collision_holes_19nov/holes.json"
var out_path := "res://OUT/hole_why.json"
var rows: Array = []
var piece_box := {}      # piece -> AABB of its collision in the piece's own frame (null = none)
var holder: Node3D

func _init() -> void: _run.call_deferred()

func _col_aabb(n: Node, xf: Transform3D, acc: Array) -> void:
	if n is CollisionShape3D and (n as CollisionShape3D).shape:
		var s := (n as CollisionShape3D).shape; var b: AABB
		if s is ConcavePolygonShape3D:
			var f := (s as ConcavePolygonShape3D).get_faces()
			if f.is_empty(): return
			b = AABB(f[0], Vector3.ZERO)
			for v in f: b = b.expand(v)
		else: b = s.get_debug_mesh().get_aabb()
		var wb: AABB = (xf * (n as Node3D).transform) * b
		acc[0] = wb if acc[0] == null else (acc[0] as AABB).merge(wb)
		return
	var nx := xf
	if n is Node3D: nx = xf * (n as Node3D).transform
	for c in n.get_children(): _col_aabb(c, nx, acc)

func _box(piece: String) -> Variant:
	if piece_box.has(piece): return piece_box[piece]
	var acc: Array = [null]
	var p := PIECES + piece + ".scn"
	if ResourceLoader.exists(p):
		var inst: Node = (load(p) as PackedScene).instantiate()
		for c in inst.get_children(): _col_aabb(c, Transform3D.IDENTITY, acc)
		inst.free()
	piece_box[piece] = acc[0]
	return acc[0]

func _xf(r: Dictionary) -> Transform3D:
	var p: Array = r.get("pos", [0, 0, 0])
	return Transform3D(Basis(Vector3.UP, deg_to_rad(float(r.get("yaw", 0)))), Vector3(float(p[0]), float(p[1]), float(p[2])))

## the nearest ground triangle of a concave shape to (x, z) seen from above: [distance across, height there or at the
## nearest point, the triangle's corners]
func _nearest_tri(f: PackedVector3Array, xf: Transform3D, q: Vector2) -> Array:
	var best := [1.0e9, 0.0]
	for t in f.size() / 3:
		var a := xf * f[t * 3]; var b := xf * f[t * 3 + 1]; var c := xf * f[t * 3 + 2]
		var n := (b - a).cross(c - a)
		if n.length_squared() < 1.0e-12 or absf(n.normalized().y) < 0.5: continue      # walls and kerb faces: not ground
		var A := Vector2(a.x, a.z); var B := Vector2(b.x, b.z); var C := Vector2(c.x, c.z)
		var d := 0.0
		if not Geometry2D.point_is_inside_triangle(q, A, B, C):
			d = minf(q.distance_to(Geometry2D.get_closest_point_to_segment(q, A, B)), minf(q.distance_to(Geometry2D.get_closest_point_to_segment(q, B, C)), q.distance_to(Geometry2D.get_closest_point_to_segment(q, C, A))))
		if d < float(best[0]): best = [d, (a.y + b.y + c.y) / 3.0, [a, b, c]]
	return best

func _ground_near(n: Node, xf: Transform3D, q: Vector2, out: Array, piece: String, layer: int) -> void:
	if n is StaticBody3D: layer = (n as StaticBody3D).collision_layer
	if n is CollisionShape3D and (n as CollisionShape3D).shape is ConcavePolygonShape3D:
		var r := _nearest_tri(((n as CollisionShape3D).shape as ConcavePolygonShape3D).get_faces(), xf * (n as Node3D).transform, q)
		if float(r[0]) < 6.0: out.append({"piece": piece, "node": str(n.get_path()), "layer": layer, "gap_m": snappedf(float(r[0]), 0.001), "y": snappedf(float(r[1]), 0.01), "tri": str(r[2]) if r.size() > 2 else ""})
		return
	var nx := xf
	if n is Node3D: nx = xf * (n as Node3D).transform
	for c in n.get_children(): _ground_near(c, nx, q, out, piece, layer)

func _run() -> void:
	for a: String in OS.get_cmdline_user_args():
		if a.begins_with("--holes="): holes_path = a.trim_prefix("--holes=")
		if a.begins_with("--out="): out_path = a.trim_prefix("--out=")
	rows = (JSON.parse_string(FileAccess.get_file_as_string(LAYOUT)) as Dictionary).instances
	var holes: Array = JSON.parse_string(FileAccess.get_file_as_string(holes_path))
	holder = Node3D.new(); root.add_child(holder)
	var res: Array = []
	for h: Dictionary in holes:
		var q := Vector2(float(h.x), float(h.z)); var y := float(h.y)
		var near: Array = []
		for r: Dictionary in rows:
			var bx: Variant = _box(String(r.piece))
			if bx == null: continue
			var wb: AABB = _xf(r) * (bx as AABB)
			if q.x >= wb.position.x - 3.0 and q.x <= wb.end.x + 3.0 and q.y >= wb.position.z - 3.0 and q.y <= wb.end.z + 3.0: near.append(r)
		var insts: Array = []
		for r2: Dictionary in near:
			var inst: Node3D = (load(PIECES + String(r2.piece) + ".scn") as PackedScene).instantiate()
			inst.transform = _xf(r2); holder.add_child(inst); insts.append([String(r2.piece), inst])
		await physics_frame; await physics_frame
		var ss := root.get_world_3d().direct_space_state
		var qr := PhysicsRayQueryParameters3D.new(); qr.from = Vector3(q.x, y + 1.5, q.y); qr.to = Vector3(q.x, y - 1.5, q.y)
		qr.collision_mask = 1; var hit1 := ss.intersect_ray(qr)
		qr.collision_mask = 0xFFFFFFFF; var hit_all := ss.intersect_ray(qr)
		var who := ""
		if not hit_all.is_empty():
			var co: Node = hit_all.collider
			for e: Array in insts:
				if (e[1] as Node).is_ancestor_of(co): who = String(e[0])
		var ground: Array = []
		for e2: Array in insts: _ground_near(e2[1], Transform3D.IDENTITY, q, ground, String(e2[0]), 1)
		ground.sort_custom(func(a, b): return float(a.gap_m) < float(b.gap_m))
		var bd := minf(absf(q.x - roundf(q.x / 200.0) * 200.0), absf(q.y - roundf(q.y / 200.0) * 200.0))
		var verdict := "bake" if not hit1.is_empty() else ("layer" if not hit_all.is_empty() else "piece")
		var o := {"x": h.x, "z": h.z, "y": h.y, "cell": h.cell, "road": int(h.road_points) > 0, "border_m": snappedf(bd, 0.01), "verdict": verdict,
			"raw_hit_y": snappedf(float((hit_all.position as Vector3).y), 0.01) if not hit_all.is_empty() else null, "raw_hit_piece": who,
			"pieces": near.map(func(r3): return String(r3.piece)), "ground_near": ground.slice(0, 6)}
		res.append(o)
		print("WHY (%.1f, %.1f) y %.2f %s border %.2f -> %s %s | nearest ground: %s" % [q.x, q.y, y, "road" if o.road else "pavement", bd, verdict, who, str(ground.slice(0, 3).map(func(g): return "%s gap %.3f y %.2f" % [g.piece, g.gap_m, g.y]))])
		for e3: Array in insts: (e3[1] as Node).queue_free()
		await process_frame
	var f := FileAccess.open(out_path, FileAccess.WRITE); f.store_string(JSON.stringify(res, "\t")); f.close()
	var cnt := {}
	for o2: Dictionary in res: cnt[o2.verdict] = int(cnt.get(o2.verdict, 0)) + 1
	print("WHY done: %d holes, %s; written %s" % [res.size(), str(cnt), out_path])
	quit(0)
