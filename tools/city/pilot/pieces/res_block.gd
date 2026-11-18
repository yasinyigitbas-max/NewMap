extends RefCounted
## Builds the residential lots along 10th St east (one side per piece: r_n / r_s), on the hill.
## Every lot is a level terrace at the street height of its own frontage (nothing stands on a slope). The difference to
## the sloping sidewalk is a low retaining wall along the property line, steps on the front path, a ramped driveway;
## neighbouring terraces meet at a retaining wall on the side lot line.

const K := preload("res://tools/city/pilot/kit_lib.gd")
const S := preload("res://tools/city/pilot/site.gd")
const W := preload("res://tools/city/pilot/pieces/wear_lib.gd")

static func build(name: String, sz: float) -> Node3D:
	var root := Node3D.new(); root.name = name
	var bl := Node3D.new(); bl.name = "Buildings"; root.add_child(bl)
	var g := K.Ground.new(); var props := K.Props.new()
	var dec := K.Decals.new(); var rr := W.rng_for(name)
	var lots: Array = []
	for L: Dictionary in S.LOTS:
		if float(L.side) == sz: lots.append(L)
	lots.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return float(a.x0) < float(b.x0))
	var zp := sz * S.T_PROP                      # property line
	var zf := sz * (S.T_PROP + S.SETBACK)       # house fronts
	var zb := sz * (S.T_PROP + S.LOT_D)         # back line
	var heights: Array = []
	var i := 0
	for L: Dictionary in lots:
		var x0: float = L.x0; var x1 := x0 + S.LOT_W
		var H := S.walk_y(x0 + S.LOT_W * 0.5)
		heights.append(H)
		var st := K.building_stats(String(L.house))
		var w: float = st.footprint_wd[0]; var d: float = st.footprint_wd[1]
		var hx: float = L.hx
		var facing := -sz                          # north side faces +z (south), south side faces -z
		var yaw := 0.0 if facing > 0 else 180.0
		# front door x (main door = first "door*" entry), in world x
		var door_x := hx
		for e: Array in st.get("doors_front", []):
			if String(e[0]).begins_with("door"):
				door_x = hx + float(e[1]) * (1.0 if facing > 0 else -1.0); break
		var drive: float = L.drive
		var has_drive := drive > 0.0
		var gar: String = L.garage
		var gz_front := sz * (S.T_PROP + S.SETBACK + d + 4.0)      # detached garage front, behind the house
		# ---------------------------------------------------------------- ground
		var Hf := func(_x: float, _z: float) -> float: return H
		# 1) front strip (property line to house front): lawn + path (+ driveway slope handled separately)
		var paint: Array = []
		var nst := int(ceil(absf(H - S.walk_y(door_x)) / 0.17)) if absf(H - S.walk_y(door_x)) >= 0.06 else 0
		var zs_end := zp + sz * 0.3 * nst
		if nst > 0: paint.append([door_x - 0.6, minf(zp, zs_end), door_x + 0.6, maxf(zp, zs_end), "-"])
		paint.append([door_x - 0.6, minf(zs_end, zf), door_x + 0.6, maxf(zs_end, zf), "concrete"])
		var cols: Array = [[x0, x1]]
		if has_drive: cols = [[x0, drive - 1.5], [drive + 1.5, x1]]
		for c: Array in cols:
			K.painted_rect(g, c[0], minf(zp, zf), c[1], maxf(zp, zf), paint, Hf, "grass")
		if has_drive:
			# ramped driveway: from the sidewalk height at the property line to the terrace at the house front
			var nseg := 6
			for k in nseg:
				var za := lerpf(zp, zf, float(k) / nseg); var zb2 := lerpf(zp, zf, float(k + 1) / nseg)
				var ya := lerpf(S.walk_y(drive), H, float(k) / nseg); var yb := lerpf(S.walk_y(drive), H, float(k + 1) / nseg)
				g.quad("concrete", Vector3(drive - 1.5, ya, za), Vector3(drive + 1.5, ya, za), Vector3(drive + 1.5, yb, zb2), Vector3(drive - 1.5, yb, zb2))
				# side faces of the ramp where it stands proud of / sinks into the lawn
				for ex: float in [drive - 1.5, drive + 1.5]:
					_wall2(g, Vector2(ex, za), Vector2(ex, zb2), ya, yb, H, H)
		# 2) the rest of the lot (behind the house front): lawn, driveway on to the garage, back patio
		var paint2: Array = []
		if has_drive:
			var dz1 := gz_front if gar != "" else zf
			paint2.append([drive - 1.5, minf(zf, dz1), drive + 1.5, maxf(zf, dz1), "concrete"])
		K.painted_rect(g, x0, minf(zf, zb), x1, maxf(zf, zb), paint2, Hf, "grass")
		# 3) front retaining face along the property line (both ways; the path gets steps, the driveway ramps)
		var gaps: Array = [[door_x - 0.6, door_x + 0.6]]
		if has_drive: gaps.append([drive - 1.5, drive + 1.5])
		var xs := x0
		gaps.sort_custom(func(a: Array, b: Array) -> bool: return a[0] < b[0])
		for gp: Array in gaps:
			_front_wall(g, xs, float(gp[0]), zp, H)
			xs = float(gp[1])
		_front_wall(g, xs, x1, zp, H)
		_steps(g, door_x, zp, sz, S.walk_y(door_x), H)
		# ---------------------------------------------------------------- buildings
		var hz := zf + sz * d * 0.5
		K.building(bl, String(L.house), Vector3(hx, H, hz), yaw)
		if has_drive and gar != "":
			var gst := K.building_stats(gar)
			var gd: float = gst.footprint_wd[1]
			K.building(bl, gar, Vector3(drive, H, gz_front + sz * gd * 0.5), yaw)
		# ---------------------------------------------------------------- props (each with its reason)
		var fy := H
		# fences on the terrace edge: front picket / iron with openings at the path and driveway
		var fence: String = L.fence
		if fence != "":
			var base := "fence_picket_white" if fence == "picket" else "fence_wrought_iron"
			var x := x0 + 0.4
			while x + 2.0 <= x1 - 0.4:
				var mid := x + 1.0
				var blocked := absf(mid - door_x) < 2.2 or (has_drive and absf(mid - drive) < 2.6)
				if not blocked: props.add(base, "worn", Vector3(mid, fy, zp + sz * 0.35), 0.0)
				x += 2.0
		# back-yard privacy fence along the back line, and down the side line behind the house
		var xb := x0
		while xb + 2.0 <= x1 + 1e-3:
			props.add("fence_wood_privacy", "worn", Vector3(xb + 1.0, fy, zb - sz * 0.1), 0.0); xb += 2.0
		var zz := zf + sz * (d + 1.0)
		while absf(zz - zb) > 2.0:
			props.add("fence_wood_privacy", "worn", Vector3(x1 - 0.1, fy, zz + sz * 1.0), 90.0); zz += sz * 2.0
		# mailbox on a post by the path (houses with a front fence) or on the wall beside the door
		if fence != "": props.add("prop_mailbox_post_wood", "worn", Vector3(door_x + 0.95, fy, zp + sz * 0.35), yaw)   # in the fence opening, beside the path
		# three carts (trash, recycling, green waste) beside the garage / driveway, not at the kerb: not collection day
		var cx := hx + (w * 0.5 + 1.2) * (1.0 if i % 2 == 0 else -1.0)
		if has_drive:
			var dside := signf(drive - hx)
			if absf(drive - hx) > w * 0.5: cx = drive + dside * 2.3          # detached garage: beyond the driveway
			else: cx = hx + dside * (w * 0.5 + 0.8)                          # own garage: in the side yard by it
		cx = clampf(cx, x0 + 0.6, x1 - 0.6)
		var cz := zf + sz * (d * 0.6)
		for k2 in 3:
			props.add(["prop_trash_cart_black", "prop_trash_cart_blue", "prop_trash_cart_green"][k2], "worn", Vector3(cx, fy, cz + sz * 0.8 * k2), 90.0 if cx > hx else -90.0)
		# AC condenser on the side of the house opposite the carts
		var acx := hx - (w * 0.5 + 0.7) * signf(cx - hx)
		var ac := Vector3(acx, fy, zf + sz * d * 0.4)
		if acx < x0 + 0.7 or acx > x1 - 0.7:
			ac = Vector3(hx - signf(cx - hx) * 2.0, fy, zf + sz * (d + 0.8))
			props.add("prop_ac_condenser", "worn", ac, yaw + 180.0)   # side yard too tight: behind the house
		else:
			props.add("prop_ac_condenser", "worn", ac, 90.0 if acx > hx else -90.0)
		# front yard planting by the path; bougainvillea against Spanish walls
		props.add("plant_bird_of_paradise", "normal", Vector3(door_x - 1.4, fy, zp + sz * 2.2), 0.0)
		props.add("plant_agave_americana_small", "normal", Vector3(door_x + 1.5, fy, zp + sz * 3.4), 0.0)
		if String(L.house).contains("spanish") or String(L.house).contains("tudor"):
			props.add("plant_bougainvillea_mound", "normal", Vector3(x0 + 1.5, fy, zp + sz * 1.8), 0.0)
		# back yard: shade tree in the back corner, and one thing people do out there
		props.add(["tree_ficus_a", "tree_coral_a", "tree_jacaranda_a", "tree_magnolia_b"][i % 4], "normal", Vector3(x0 + 3.5 if i % 2 == 0 else x1 - 3.5, fy, zb - sz * 4.0), float(i * 61))
		var by := zf + sz * (d + 4.5)
		match i % 4:
			0: props.add("prop_patio_set_4", "worn", Vector3(hx, fy, by), 0.0)
			1: props.add("prop_bbq_kettle", "worn", Vector3(hx - 1.5, fy, by), 0.0); props.add("prop_adirondack_white", "worn", Vector3(hx + 1.2, fy, by), yaw)
			2: props.add("prop_garden_arbor", "worn", Vector3(hx, fy, by + sz * 2.0), 0.0)
			3: props.add("prop_bbq_gas_cart", "worn", Vector3(hx - 1.2, fy, by), yaw); props.add("prop_adirondack_wood", "worn", Vector3(hx + 1.4, fy, by), yaw)
		# ---- lived in
		var Hc := func(_x: float, _z: float) -> float: return H
		if has_drive:
			var car_z := (gz_front - sz * 3.2) if gar != "" else (zf - sz * 3.0)
			W.oil(dec, rr, Vector2(drive, car_z), 0.0, Hc, 0.6)
			dec.add(8, Vector2(drive, (zp + zf) * 0.5), 0.0, 2.4, 5.5, Hc, Color(1, 1, 1, 0.25))
		dec.add(14, Vector2(door_x, zp + sz * (0.3 * nst + 1.2)), 0.0, 1.4, 2.0, Hc, Color(1, 1, 1, 0.4))
		dec.add(14, Vector2(cx, cz + sz * 0.8), 0.0, 1.4, 3.2, Hc, Color(1, 1, 1, 0.55))
		props.add("plant_potted_succulent", "normal", Vector3(door_x - 1.6, fy, zf - sz * 0.5), 0.0)   # by the front steps, clear of the door
		# hose cart next to the AC unit (same side of the house as the water tap), never in a neighbour's lot
		var hose := ac + Vector3(0, 0, sz * 1.6)
		hose.x = clampf(hose.x, x0 + 0.7, x1 - 0.7)
		if absf(hose.x - cx) < 1.2 and absf(hose.z - cz) < 3.0: hose.z = cz + sz * 3.4
		props.add("prop_hose_reel_cart", "worn", hose, 90.0 if hose.x > hx else -90.0)
		var lx0 := x0 + 1.0; var lx1 := x1 - 1.0
		if i % 3 == 1:
			# this owner does not water: dry, patchy front lawn
			for k in 5: dec.add(14, Vector2(rr.randf_range(lx0, lx1), zp + sz * rr.randf_range(1.5, S.SETBACK - 1.0)), rr.randf_range(0, 360), rr.randf_range(1.8, 3.2), rr.randf_range(1.4, 2.4), Hc, Color(0.8, 0.72, 0.46, 0.6))
		else:
			var spx := x0 + 3.0 if absf(door_x - (x0 + 3.0)) > 3.0 else x1 - 3.0
			if has_drive and absf(spx - drive) < 2.5: spx = (x0 + x1) * 0.5
			props.add("prop_sprinkler_impact", "worn", Vector3(spx, fy, zp + sz * 4.6), 0.0, false)
		# one Coronado touch: a golf cart parked in a driveway
		if String(L.house).contains("beach") and has_drive and sz < 0:
			props.add("prop_golf_cart_white", "worn", Vector3(drive, fy, zf + sz * 2.5), yaw)
		i += 1
	# power: an overhead line on poles along the back lot line (rear easement), fed from the alley line; the drops to
	# the houses are drawn by the w_power piece. Cross-arms cross the line (line runs along x: yaw 90).
	for px: float in [63.5, 93.5, 123.5]:
		var pz := sz * (S.T_PROP + S.LOT_D + 0.6)
		props.add("prop_utility_pole_transformer" if px == 93.5 else "prop_utility_pole", "worn", Vector3(px, S.walk_y(px) + 0.15, pz), 90.0)
	var wm := dec.build()
	if wm: root.add_child(wm)
	# side walls between neighbouring terraces, and the ends of the row
	for k in lots.size() - 1:
		var xw: float = float(lots[k].x0) + S.LOT_W
		_wall2(g, Vector2(xw, zp), Vector2(xw, zb), heights[k], heights[k], heights[k + 1], heights[k + 1])
	# strips outside the lots: alley side (x 50..56) and the far end, as sloping lawn at street height
	g.rect("grass", 50.0, minf(zp, zb), float(lots[0].x0), maxf(zp, zb), S.walk_y)
	_wall2(g, Vector2(float(lots[0].x0), zp), Vector2(float(lots[0].x0), zb), S.walk_y(float(lots[0].x0)), S.walk_y(float(lots[0].x0)), heights[0], heights[0])
	var mi := MeshInstance3D.new(); mi.name = "ground"; mi.mesh = g.build()
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF; root.add_child(mi)
	var body := StaticBody3D.new(); body.name = "ground_col"
	var cs := CollisionShape3D.new(); cs.shape = mi.mesh.create_trimesh_shape(); body.add_child(cs); root.add_child(body)
	props.build(root, K)
	print("%s: ground tris %d, props %d, buildings %d" % [name, g.tri_count(), props.count(), bl.get_child_count()])
	return root

## vertical face along a-b between two surfaces (heights ya0/yb0 on one side, ya1/yb1 on the other), visible both ways
static func _wall2(g: K.Ground, a: Vector2, b: Vector2, ya0: float, yb0: float, ya1: float, yb1: float) -> void:
	if absf(ya0 - ya1) < 0.01 and absf(yb0 - yb1) < 0.01: return
	var A0 := Vector3(a.x, minf(ya0, ya1), a.y); var A1 := Vector3(a.x, maxf(ya0, ya1), a.y)
	var B0 := Vector3(b.x, minf(yb0, yb1), b.y); var B1 := Vector3(b.x, maxf(yb0, yb1), b.y)
	var n := Vector3(b.y - a.y, 0.0, -(b.x - a.x))
	g.quad("wall", A0, B0, B1, A1, n, true)
	g.quad("wall", A0, B0, B1, A1, -n, true)

## front retaining face along the property line from x a to b: sidewalk (sloping) vs terrace (level H)
static func _front_wall(g: K.Ground, a: float, b: float, z: float, H: float) -> void:
	if b - a < 0.05: return
	var n := maxi(1, int(ceil((b - a) / 2.0)))
	for k in n:
		var xa := lerpf(a, b, float(k) / n); var xb := lerpf(a, b, float(k + 1) / n)
		_wall2(g, Vector2(xa, z), Vector2(xb, z), S.walk_y(xa), S.walk_y(xb), H, H)

## steps on the front path where the terrace is above (or below) the sidewalk: 0.3 m treads, risers <= 0.17 m
static func _steps(g: K.Ground, x: float, zp: float, sz: float, y0: float, H: float) -> void:
	var dh := H - y0
	if absf(dh) < 0.06:
		_wall2(g, Vector2(x - 0.6, zp), Vector2(x + 0.6, zp), y0, y0, H, H)
		return
	var n := int(ceil(absf(dh) / 0.17))
	for k in n:
		var ya := y0 + dh * float(k) / n; var yb := y0 + dh * float(k + 1) / n
		var za := zp + sz * 0.3 * k; var zb := zp + sz * 0.3 * (k + 1)
		g.quad("concrete", Vector3(x - 0.6, yb, za), Vector3(x + 0.6, yb, za), Vector3(x + 0.6, yb, zb), Vector3(x - 0.6, yb, zb))
		_wall2(g, Vector2(x - 0.6, za), Vector2(x + 0.6, za), ya, ya, yb, yb)
		# cheek walls between the tread and the level lawn either side
		for ex: float in [x - 0.6, x + 0.6]:
			_wall2(g, Vector2(ex, za), Vector2(ex, zb), yb, yb, H, H)
