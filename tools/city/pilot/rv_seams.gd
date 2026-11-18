extends SceneTree
## Seam check for the residential quadrants (18 Nov, zone growth; Yasin: "no jagged edges; smooth heights, no jumps").
## Every r_q_* quadrant's ground must meet its neighbours with no step where the surfaces are meant to be continuous:
##   mouth   each alley mouth (alley centre line at the property line): the quadrant's alley vs the street leg's apron
##   mid     each alley at mid-block (u or v = 100): this quadrant's alley vs the neighbouring quadrant's
##   walk    the corner lots' side yards along the side street are retaining walls by design (not checked)
## Heights from raycasts on the pieces' ground collision only (props and buildings removed). Prints one line per step
## over 3 cm (points 10 cm apart), then "SEAMS n problems (m checked)". Real renderer not needed (collision only), run headless:
##   CITYKIT_LAYOUT_ONLY=1 CITYKIT_LAYOUT_EXTRA=res://map_dc/coronado/city_kit/city_grid_layout.json godot --headless --path . -s res://tools/city/pilot/rv_seams.gd
const K := preload("res://tools/city/pilot/kit_lib.gd")
func _init() -> void: _run.call_deferred()
func _run() -> void:
	var world := Node3D.new(); root.add_child(world)
	var quads: Array = []
	for n: Node3D in K.place_layout(world):
		for c: Node in n.find_children("*", "StaticBody3D", true, false):
			if c.name != "ground_col": c.get_parent().remove_child(c); c.free()
		if String(n.get_meta(&"piece", "")).begins_with("r_q_"): quads.append(n)
	for i in 4: await physics_frame
	var space := (world.get_world_3d() as World3D).direct_space_state
	var bad := 0; var n_ck := 0; var edges := 0
	var hy := func(x: float, z: float) -> float:
		var q := PhysicsRayQueryParameters3D.create(Vector3(x, 80.0, z), Vector3(x, -20.0, z))
		var h := space.intersect_ray(q)
		return float(h.position.y) if not h.is_empty() else -INF
	for n: Node3D in quads:
		var site: Dictionary = n.get_meta(&"site")
		var sx := float(site.sx); var sz := float(site.sz)
		var o := n.position
		var P := func(u: float, v: float) -> Vector2: return Vector2(o.x + sx * u, o.z + sz * v)
		var hu := float(site.get("Lu", 200.0)) * 0.5; var hv := float(site.get("Lv", 200.0)) * 0.5
		var checks: Array = []
		for c: float in [55.0, 57.0, 59.0]:
			checks.append(["mouth u-alley", P.call(9.25, c), P.call(9.15, c)])      # the alley along u starts at the side street
			checks.append(["mouth v-alley", P.call(c, 9.25), P.call(c, 9.15)])
			checks.append(["mid u-alley", P.call(hu - 0.05, c), P.call(hu + 0.05, c)])
			checks.append(["mid v-alley", P.call(c, hv - 0.05), P.call(c, hv + 0.05)])
		for ck: Array in checks:
			var a: Vector2 = ck[1]; var b: Vector2 = ck[2]
			var ya: float = hy.call(a.x, a.y); var yb: float = hy.call(b.x, b.y)
			if ya == -INF or yb == -INF:
				edges += 1; continue        # the zone's edge: the next quadrant is another zone's (or not built)
			n_ck += 1
			if absf(ya - yb) > 0.03:
				print("SEAM step %s %s at (%.1f, %.1f): %.3f vs %.3f (%.2f m)" % [n.get_meta(&"piece"), ck[0], b.x, b.y, ya, yb, ya - yb]); bad += 1
	print("SEAMS %d problems (%d checked, %d points at the zone's edge with nothing beyond)" % [bad, n_ck, edges])
	quit()
