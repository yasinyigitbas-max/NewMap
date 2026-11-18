extends RefCounted
## Commercial strip GROWTH blocks (m_gr_*, claude/grow-strip, 18 Nov 2026): the variants of the strip sample that fill
## the empty blocks round it (CITY_PLAN.md: samples, zoning map, variants, growth; Yasin: "no two blocks dressed the
## same", "every prop has a reason", "lively, worn, varied", "no jagged edges, smooth heights, no jumps").
## The locked sample (j_strip, s_strip_*, m_*) and its helpers (strip_lib, ind_lib) are only READ here, never edited.
##
## Frame: each block is authored in its junction's frame (x = grid u - junction u, z = grid v - junction v, y = metres
## above the junction pad), placed by a layout row at [junction u, pad, junction v], yaw 0. Its rectangle and ground
## come from strip_grow_ground.json (tools/city/pilot/zoning/strip_grow_ground.py): a smooth surface that meets every
## neighbour's walk / lot edge flush. Buildings stand on LEVEL pads cut into that surface (pad() / bld()), blended back
## over 4 m, so a slope never leaves a building floating or a door under ground. Everything placed here takes its height
## from y(): props, fences, stalls (meta [x, z, yaw, y, grade] for the parked-car layer), wear decals.
const K := preload("res://tools/city/pilot/kit_lib.gd")
const S := preload("res://tools/city/pilot/site.gd")
const W := preload("res://tools/city/pilot/pieces/wear_lib.gd")
const I := preload("res://tools/city/pilot/pieces/ind_lib.gd")
const L := preload("res://tools/city/pilot/pieces/strip_lib.gd")
const GROUND := "res://tools/city/pilot/pieces/strip_grow_ground.json"

const STALL_W := 2.7
const STALL_D := 5.5

var name := ""
var variant := ""
var x0 := 0.0; var z0 := 0.0; var x1 := 0.0; var z1 := 0.0
var nx := 0; var nz := 0; var stx := 1.0; var stz := 1.0
var gy: PackedFloat32Array
var pads: Array = []          # [x0, z0, x1, z1, y, blend]
var root: Node3D; var bl: Node3D
var g := K.Ground.new(); var props := K.Props.new(); var dec := K.Decals.new()
var rr: RandomNumberGenerator
var paints: Array = []; var stalls: Array = []; var arrows: Array = []; var B: Array = []
var shops: Array = []         # [label, kit folder] of every building with shop doors (rooms: interiors/assignment_strip.json)
var yfn: Callable

func _init(piece: String, var_name: String) -> void:
	name = piece; variant = var_name
	S.hill_on = false
	var d: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(GROUND)).blocks[piece]
	x0 = float(d.x0); z0 = float(d.z0); nx = int(d.nx); nz = int(d.nz); stx = float(d.step); stz = float(d.stepz)
	x1 = x0 + (nx - 1) * stx; z1 = z0 + (nz - 1) * stz
	gy = PackedFloat32Array(d.y)
	root = Node3D.new(); root.name = piece
	root.set_meta(&"variant", var_name)
	bl = Node3D.new(); bl.name = "Buildings"; root.add_child(bl)
	rr = W.rng_for(piece)
	yfn = func(x: float, z: float) -> float: return y(x, z)

## ---------------------------------------------------------------- ground
## the solved surface (bilinear), then every building pad with its blend
func field(x: float, z: float) -> float:
	var fx := clampf((x - x0) / stx, 0.0, nx - 1.001); var fz := clampf((z - z0) / stz, 0.0, nz - 1.001)
	var i := int(fx); var j := int(fz); var tx := fx - i; var tz := fz - j
	var a := gy[j * nx + i]; var b := gy[j * nx + i + 1]; var c := gy[(j + 1) * nx + i]; var e := gy[(j + 1) * nx + i + 1]
	return lerpf(lerpf(a, b, tx), lerpf(c, e, tx), tz)

func y(x: float, z: float) -> float:
	var h := field(x, z)
	for p: Array in pads:
		var dx := maxf(maxf(float(p[0]) - x, x - float(p[2])), 0.0)
		var dz := maxf(maxf(float(p[1]) - z, z - float(p[3])), 0.0)
		var d := sqrt(dx * dx + dz * dz)
		var bw := float(p[5])
		if d <= 0.0: return float(p[4])
		if d < bw:
			var t := d / bw; t = t * t * (3.0 - 2.0 * t)
			# never blend across the block edge: the edge keeps the neighbour's height
			var ed := minf(minf(x - x0, x1 - x), minf(z - z0, z1 - z))
			if ed < 0.6: continue
			h = lerpf(float(p[4]), h, t)
	return h

## a level pad (rect in piece coordinates) at the surface's mean height over it (or `at`), blended back over `blend` m
func pad(ax: float, az: float, bx: float, bz: float, blend := 4.0, at := NAN) -> float:
	var r := [minf(ax, bx), minf(az, bz), maxf(ax, bx), maxf(az, bz)]
	var h := at
	if is_nan(h):
		var s := 0.0; var n := 0
		for i in 5:
			for j in 5:
				s += field(lerpf(r[0], r[2], i / 4.0), lerpf(r[1], r[3], j / 4.0)); n += 1
		h = s / n
	pads.append([r[0], r[1], r[2], r[3], h, blend])
	return h

## ---------------------------------------------------------------- placing
func p3(x: float, z: float, lift := 0.0) -> Vector3: return Vector3(x, y(x, z) + lift, z)

func add(base: String, cond: String, x: float, z: float, yaw := 0.0, collide := true, lift := 0.0) -> void:
	I.add(props, base, cond, p3(x, z, lift), yaw, collide)

## a kit building with its centre at (x, z) turned by yaw (front = +Z turned), on its own level pad (1 m apron round it).
## services: the back-of-house wall kit (meters, gas, AC) on its rear wall at the pad height.
func bld(folder: String, x: float, z: float, yaw: float, label: String, wear := 0.8, services := true, shop := true) -> Array:
	var st := K.building_stats(folder)
	var w: float = st.footprint_wd[0]; var d: float = st.footprint_wd[1]
	var b := Basis(Vector3.UP, deg_to_rad(yaw))
	var hx := absf((b * Vector3(w * 0.5, 0, 0)).x) + absf((b * Vector3(0, 0, d * 0.5)).x)
	var hz := absf((b * Vector3(w * 0.5, 0, 0)).z) + absf((b * Vector3(0, 0, d * 0.5)).z)
	var h := pad(x - hx - 1.2, z - hz - 1.2, x + hx + 1.2, z + hz + 1.2)
	var n := K.building(bl, folder, Vector3(x, h, z), yaw, label, wear)
	n.set_meta(&"label", label)
	if services:
		# a back wall within 2 m of the block edge (a lot fence behind it) gets the compact AC units, tight to the wall
		var back_c: Vector3 = n.transform * Vector3(0, 0, -d * 0.5)
		var tight := minf(minf(back_c.x - x0, x1 - back_c.x), minf(back_c.z - z0, z1 - back_c.z)) < 2.0
		back_of_house(n, folder, w, d, tight)
	B.append([n, w, d, folder])
	if shop and not (st.get("doors_front", []) as Array).is_empty(): shops.append([label, folder])
	return [n, w, d]

## meters, gas meter, AC condensers on the rear wall (cc_lib.back_of_house, at this block's pad height)
func back_of_house(node: Node3D, folder: String, w: float, d: float, compact := false) -> void:
	var yaw := rad_to_deg(node.rotation.y) + 180.0
	var at := func(lx: float, ly: float, lz: float) -> Vector3:
		var p: Vector3 = node.transform * Vector3(lx, 0.0, lz)
		return Vector3(p.x, node.position.y + S.KERB_H + ly, p.z)
	var xa := -w * 0.5 + 1.6
	for k in 3: props.add("prop_meter_electric", "worn", at.call(xa + k * 0.42, 1.05, -d * 0.5 - 0.02), yaw)
	props.add("prop_meter_gas", "rusty", at.call(xa + 1.7, 0.2, -d * 0.5 - 0.02), yaw)
	var n_ac := 1 if w < 14.0 else 2
	for k in n_ac:
		props.add("prop_ac_condenser_compact" if compact else "prop_ac_condenser", "worn", at.call(xa + 3.4 + k * 1.3, 0.0, -d * 0.5 - (0.47 if compact else 0.75)), yaw)

## a world point on a building: local (lx, lz) of its footprint, at its pad height (+ly)
func on_bld(b: Array, lx: float, lz: float, ly := 0.0) -> Vector3:
	var n: Node3D = b[0]
	var p: Vector3 = n.transform * Vector3(lx, 0.0, lz)
	return Vector3(p.x, n.position.y + S.KERB_H + ly, p.z)

func bld_yaw(b: Array, dyaw := 0.0) -> float: return rad_to_deg((b[0] as Node3D).rotation.y) + dyaw

## roof plant on a building's FLAT roof (life_lib's rule): candidate spots on a 3 m grid over the footprint, raycast
## down on the near mesh; a spot counts when it and four points 1.2 m round it hit the same level (normal up), so
## nothing lands on a parapet, a sign or a pitched roof. Items are placed in order, one per spot, at least 3 m apart.
func roof(b: Array, items: Array) -> int:
	var n: Node3D = b[0]
	var near := n.get_node_or_null("near") as MeshInstance3D
	if near == null: return 0
	var tm := near.mesh.generate_triangle_mesh()
	var w: float = b[1]; var d: float = b[2]
	var spots: Array = []
	var lx := -w * 0.5 + 2.0
	while lx <= w * 0.5 - 2.0:
		var lz := -d * 0.5 + 2.0
		while lz <= d * 0.5 - 2.0:
			var h := _roof_hit(tm, near.transform, Vector3(lx, 0, lz))
			if h > 2.4:
				var ok := true
				for o: Vector3 in [Vector3(1.2, 0, 0), Vector3(-1.2, 0, 0), Vector3(0, 0, 1.2), Vector3(0, 0, -1.2)]:
					if absf(_roof_hit(tm, near.transform, Vector3(lx, 0, lz) + o) - h) > 0.01: ok = false
				if ok: spots.append(Vector3(lx, h, lz))
			lz += 3.0
		lx += 3.0
	var placed := 0
	var used: Array = []
	var k := 0
	for s: Vector3 in spots:
		if placed >= items.size(): break
		# spread out: take every other spot, from the middle out
		k += 1
		if k % 2 == 0: continue
		var clear := true
		for u: Vector3 in used:
			if u.distance_to(s) < 3.0: clear = false
		if not clear: continue
		var wp: Vector3 = n.transform * s
		I.add(props, String(items[placed]), "worn" if rr.randf() < 0.7 else "rusty", wp, rad_to_deg(n.rotation.y) + 90.0 * (rr.randi() % 2), false)
		used.append(s); placed += 1
	return placed

func _roof_hit(tm: TriangleMesh, mxf: Transform3D, lp: Vector3) -> float:
	var o := mxf.affine_inverse() * Vector3(lp.x, 60.0, lp.z)
	var dir := (mxf.affine_inverse().basis * Vector3.DOWN).normalized()
	var r: Dictionary = tm.intersect_ray(o, dir)
	if r.is_empty(): return -1.0
	var nrm: Vector3 = (mxf.basis * Vector3(r.normal)).normalized()
	if absf(nrm.y) < 0.97: return -1.0
	return (mxf * Vector3(r.position)).y

## the kit building's front door positions (local x) by kind
func doors(folder: String) -> Array:
	var out: Array = []
	for e: Array in K.building_stats(folder).get("doors_front", []): out.append([String(e[0]), float(e[1])])
	return out

## ---------------------------------------------------------------- paint, parking
func rect(ax: float, az: float, bx: float, bz: float, mat: String) -> Array:
	return [minf(ax, bx), minf(az, bz), maxf(ax, bx), maxf(az, bz), mat]

## n stalls side by side along x from xs, the aisle edge at z = ze, nose-in toward dir (+1 = larger z)
func stalls_x(xs: float, n: int, ze: float, dir: float, w := STALL_W) -> void:
	var za := ze + dir * STALL_D
	for k in n + 1:
		paints.append(rect(xs + k * w - 0.05, minf(ze, za) + (0.3 if dir < 0 else 0.0), xs + k * w + 0.05, maxf(ze, za) - (0.3 if dir > 0 else 0.0), "white"))
	for k in n:
		var cx := xs + (k + 0.5) * w; var cz := ze + dir * STALL_D * 0.5
		var yaw := 0.0 if dir > 0.0 else 180.0
		stalls.append([cx, cz, yaw, y(cx, cz), _grade(cx, cz, yaw)])

## n stalls side by side along z from zs, the aisle edge at x = xe, nose-in toward dir (+1 = larger x)
func stalls_z(zs: float, n: int, xe: float, dir: float, w := STALL_W) -> void:
	var xa := xe + dir * STALL_D
	for k in n + 1:
		paints.append(rect(minf(xe, xa) + (0.3 if dir < 0 else 0.0), zs + k * w - 0.05, maxf(xe, xa) - (0.3 if dir > 0 else 0.0), zs + k * w + 0.05, "white"))
	for k in n:
		var cz := zs + (k + 0.5) * w; var cx := xe + dir * STALL_D * 0.5
		var yaw := 90.0 if dir > 0.0 else -90.0
		stalls.append([cx, cz, yaw, y(cx, cz), _grade(cx, cz, yaw)])

func _grade(x: float, z: float, yaw: float) -> float:
	var f := Vector2(sin(deg_to_rad(yaw)), cos(deg_to_rad(yaw)))
	return snappedf((y(x + f.x * 2.0, z + f.y * 2.0) - y(x - f.x * 2.0, z - f.y * 2.0)) / 4.0, 0.001)

## wheel stops at the head of every stall (rubber in a newer lot, concrete in an old one), one in five knocked askew
func wheel_stops(kind := "prop_wheel_stop_concrete") -> void:
	var r2 := W.rng_for(name + "_ws")
	for st: Array in stalls:
		var yaw := float(st[2])
		var f := Vector2(sin(deg_to_rad(yaw)), cos(deg_to_rad(yaw)))
		var px := float(st[0]) + f.x * (STALL_D * 0.5 - 0.55); var pz := float(st[1]) + f.y * (STALL_D * 0.5 - 0.55)
		var off := r2.randf() < 0.2
		I.add(props, kind, "dirty" if off else "worn", p3(px, pz, 0.002), yaw + (r2.randf_range(-12, 12) if off else 0.0), false)

## a planted island (grass, or mulch on a dry lot) with palms and low shrubs at the ends
func island(ax: float, az: float, bx: float, bz: float, palms: int, species: Array, mat := "grass", ends := true) -> void:
	paints.append(rect(ax, az, bx, bz, mat))
	var long_x := absf(bx - ax) > absf(bz - az)
	for k in palms:
		var t := (k + 1.0) / (palms + 1.0)
		var px := lerpf(ax, bx, t) if long_x else (ax + bx) * 0.5
		var pz := (az + bz) * 0.5 if long_x else lerpf(az, bz, t)
		add(String(species[rr.randi() % species.size()]), "normal", px, pz, rr.randf_range(0, 360))
	if not ends: return
	var e2: Array = [[minf(ax, bx) + 0.9, (az + bz) * 0.5], [maxf(ax, bx) - 0.9, (az + bz) * 0.5]] if long_x else [[(ax + bx) * 0.5, minf(az, bz) + 0.9], [(ax + bx) * 0.5, maxf(az, bz) - 0.9]]
	for e: Array in e2:
		add(["plant_agave_americana_small", "plant_bird_of_paradise", "plant_iceplant_patch"][rr.randi() % 3], "normal", float(e[0]), float(e[1]), rr.randf_range(0, 360))

## ---------------------------------------------------------------- fences and walls (a post at every joint)
## kinds: chain (lot chain-link), cmu, graffiti (cmu with every 4th panel tagged), stucco, privacy (wood), iron, board
const FENCE := {"chain": ["fence_chainlink_lot", "fence_chainlink_lot_post", 2.0], "cmu": ["fence_cmu_wall", "", 2.03],
	"stucco": ["fence_stucco_wall", "", 2.0], "privacy": ["fence_wood_privacy", "fence_post_privacy", 2.4],
	"iron": ["fence_wrought_iron", "fence_post_wrought_iron", 1.98], "board": ["fence_weathered_board", "fence_post_privacy", 2.4],
	"vinyl": ["fence_vinyl_canal_rail", "fence_post_vinyl", 2.4]}
func fence(kind: String, ax: float, az: float, bx: float, bz: float, cond := "worn", tag_every := 0) -> void:
	var a := Vector2(ax, az); var b := Vector2(bx, bz)
	var Ln := a.distance_to(b)
	if Ln < 0.5: return
	var f: Array = FENCE[kind]
	var pl := float(f[2])
	var e := K.manifest(String(f[0]))
	if e.has("footprint_w"): pl = float(e.footprint_w)
	var n := maxi(1, int(ceil(Ln / pl - 0.02)))
	var yaw := rad_to_deg(atan2(b.x - a.x, b.y - a.y)) + 90.0
	for i in n:
		var m := a.lerp(b, (i + 0.5) / n)
		var base := String(f[0])
		if tag_every > 0 and i % tag_every == tag_every - 1 and kind == "cmu": base = "fence_graffiti_cmu_panel"
		add(base, cond, m.x, m.y, yaw)
	if String(f[1]) != "":
		for i in n + 1:
			var q := a.lerp(b, float(i) / n)
			add(String(f[1]), cond, q.x, q.y, yaw)

## ---------------------------------------------------------------- dressing helpers
## a dumpster enclosure (strip_lib.enclosure, on this ground): CMU on three sides, open toward yaw
func enclosure(x: float, z: float, yaw: float, mess := true) -> void:
	L.enclosure(props, p3(x, z), yaw)
	if mess: L.enclosure_mess(props, rr, p3(x, z), yaw)

## grime at a building's feet and oil / tyre marks at its rollups (ind_lib.bld_wear, on this ground)
func building_wear() -> void:
	for b: Array in B: I.bld_wear(dec, rr, b[0], b[1], b[2], b[3])

## wear over a rect: cracks, patches, oil, grime puddles (ind_lib.yard_wear with this ground)
func yard_wear(ax: float, az: float, bx: float, bz: float, density := 1.0) -> void:
	var area := absf((bx - ax) * (bz - az)); var n := int(area / 35.0 * density)
	var lo := Vector2(minf(ax, bx), minf(az, bz)); var hi := Vector2(maxf(ax, bx), maxf(az, bz))
	W.cracks(dec, rr, lo.x, lo.y, hi.x, hi.y, n, yfn, 0.45)
	var rp := func() -> Vector2: return Vector2(rr.randf_range(lo.x, hi.x), rr.randf_range(lo.y, hi.y))
	for k in int(n * 0.3): dec.add(2 + k % 2, rp.call(), rr.randf_range(0, 180), rr.randf_range(2.5, 6.0), rr.randf_range(1.5, 4.0), yfn, Color(1, 1, 1, 0.9))
	for k in int(n * 0.15): dec.add(4 + k % 2, rp.call(), rr.randf_range(0, 180), rr.randf_range(2.0, 4.0), rr.randf_range(2.0, 4.0), yfn, Color(0.5, 0.49, 0.47, 0.75))
	for k in int(n * 0.5): W.oil(dec, rr, rp.call(), rr.randf_range(0, 180), yfn, rr.randf_range(0.5, 0.9))
	for k in int(n * 0.25): dec.add(14, rp.call(), rr.randf_range(0, 180), rr.randf_range(2.0, 5.0), rr.randf_range(2.0, 5.0), yfn, Color(1, 1, 1, rr.randf_range(0.4, 0.7)))

## oil under the stalls used most, polished wheel paths in the aisles
func stall_wear(share := 0.6) -> void:
	for s: Array in stalls:
		if rr.randf() < share: W.oil(dec, rr, Vector2(float(s[0]), float(s[1])), float(s[2]), yfn, rr.randf_range(0.5, 0.9))

func tyre_path(ax: float, az: float, bx: float, bz: float) -> void:
	var a := Vector2(ax, az); var b := Vector2(bx, bz)
	var Ln := a.distance_to(b); var dir := (b - a) / maxf(Ln, 0.01); var side := Vector2(-dir.y, dir.x)
	var yaw := rad_to_deg(atan2(dir.x, dir.y)); var s := 0.0
	while s < Ln:
		var seg := minf(6.0, Ln - s)
		for o: float in [-0.9, 0.9]:
			dec.add(8, a + dir * (s + seg * 0.5) + side * o, yaw + rr.randf_range(-4, 4), 0.6, seg, yfn, Color(1, 1, 1, rr.randf_range(0.35, 0.55)))
		s += seg
	W.oil(dec, rr, b, yaw, yfn, 0.85)

## smooth direction arrow (site.arrow2) along z at x, tail z0 -> head z1, cut into the lot (one plane)
func arrow_z(x: float, za: float, zb: float, scale := 0.75) -> void:
	var a := S.arrow2("through", x, za, zb, false, scale); arrows.append(a); paints.insert(0, (a.box as Array) + ["-"])

func arrow_x(z: float, xa: float, xb: float, scale := 0.75) -> void:
	var a := S.arrow2("through", z, xa, xb, true, scale); arrows.append(a); paints.insert(0, (a.box as Array) + ["-"])

## ---------------------------------------------------------------- polish (Yasin 18 Nov: "run a polish pass on your part, lots
## of props ... think like an interior and exterior designer, customer and city planner, use fitting props for your zone")
## half the longest side of a prop's footprint (manifest)
func half(base: String) -> float:
	var e := K.manifest(base)
	return maxf(float(e.get("footprint_w", 0.6)), float(e.get("footprint_d", 0.6))) * 0.5

## is (x, z) clear for a prop of half-length r: of every prop placed so far (each by its own size), every building
## (and 1.75 m + r round each of its doors), every stall and the block's edge?
func free_at(x: float, z: float, r := 0.9) -> bool:
	if x < x0 + 0.6 or x > x1 - 0.6 or z < z0 + 0.6 or z > z1 - 0.6: return false
	for k: String in props.items:
		var hk := half(k.get_slice("|", 0))
		if hk > 6.0: continue                               # long runs (fences, rails) are checked by the validator
		for t: Transform3D in props.items[k]:
			if absf(t.origin.x - x) < r + hk + 0.15 and absf(t.origin.z - z) < r + hk + 0.15: return false
	for st: Array in stalls:
		if absf(float(st[0]) - x) < 1.9 and absf(float(st[1]) - z) < 3.3: return false
	for b: Array in B:
		var n: Node3D = b[0]; var w: float = b[1]; var d: float = b[2]
		var lp: Vector3 = n.transform.affine_inverse() * Vector3(x, n.position.y, z)
		if absf(lp.x) < w * 0.5 + 0.3 and absf(lp.z) < d * 0.5 + 0.3: return false
		for e: Array in K.building_stats(String(b[3])).get("doors_front", []):
			if Vector2(lp.x - float(e[1]), lp.z - d * 0.5).length() < 1.75 + r: return false
	return true

## the life at every shop door: what its customers use there, on the walk in front of the facade between the doors,
## facing the street; bike racks lie parallel to the shopfront. Kinds cycle per building so no two fronts match.
const DOOR_KIT := [["prop_trash_receptacle", "prop_recycling_receptacle"], ["prop_newspaper_box_red", "prop_newspaper_box_blue"],
	["plant_potted_succulent", "plant_potted_leafy"], ["prop_bike_rack"], ["prop_trash_receptacle", "prop_newspaper_box_blue"]]
func door_life() -> int:
	var placed := 0
	for bi in B.size():
		var b: Array = B[bi]
		var n: Node3D = b[0]; var w: float = b[1]; var d: float = b[2]
		var ds: Array = K.building_stats(String(b[3])).get("doors_front", [])
		var yaw := rad_to_deg(n.rotation.y)
		var k := bi
		for e: Array in ds:
			if String(e[0]) == "rollup": continue
			for off: float in [2.6, -2.6, 4.0, -4.0]:
				var group: Array = DOOR_KIT[k % DOOR_KIT.size()]
				var lx := float(e[1]) + off
				if absf(lx) > w * 0.5 - 0.4: continue
				var wp: Vector3 = n.transform * Vector3(lx, 0, d * 0.5 + 1.05)
				if not free_at(wp.x, wp.z, half(String(group[0]))): continue
				var cursor := lx
				for gi in group.size():
					var base := String(group[gi])
					if gi > 0: cursor += signf(off) * (half(String(group[gi - 1])) + half(base) + 0.3)
					var gp: Vector3 = n.transform * Vector3(cursor, 0, d * 0.5 + 1.05)
					if absf(cursor) > w * 0.5 - 0.3 or not free_at(gp.x, gp.z, half(base)): break
					add(base, "normal" if base.begins_with("plant_") else "worn", gp.x, gp.z, yaw)
					placed += 1
				k += 1
				break
	return placed

## a utility pole line along a block's back lot line (power reaches the shops from the rear, as in the sample); a
## transformer pole every third. The wires piece draws the lines.
func pole_line(ax: float, az: float, bx: float, bz: float, every := 34.0) -> void:
	var a := Vector2(ax, az); var bb := Vector2(bx, bz)
	var n := maxi(1, int(a.distance_to(bb) / every))
	var yaw := rad_to_deg(atan2(bb.x - a.x, bb.y - a.y))
	for i in n + 1:
		var q := a.lerp(bb, float(i) / n)
		if free_at(q.x, q.y, 1.0): add("prop_utility_pole_transformer" if i % 3 == 1 else "prop_utility_pole", "worn", q.x, q.y, yaw)

## red fire-lane kerb paint along a shop walk's lot edge (a, b), road side `side` (unit x / z)
func fire_lane(ax: float, az: float, bx: float, bz: float, side: Vector2) -> void:
	W.red_kerb(dec, Vector2(ax, az), Vector2(bx, bz), side)

## ---------------------------------------------------------------- finish
## floor over the whole rectangle (asphalt base, paints cut in), arrows, wear, props, meta, save
func finish(stops := "prop_wheel_stop_concrete") -> void:
	root.set_meta(&"stalls", stalls)
	var sl: Array = []
	for s in shops: sl.append(s[0])
	root.set_meta(&"shops", sl)
	wheel_stops(stops)
	K.painted_rect(g, x0, z0, x1, z1, paints, yfn)
	for a: Dictionary in arrows: K.fill_arrow(g, a, yfn)
	var wm := dec.build()
	if wm: root.add_child(wm)
	var mi := MeshInstance3D.new(); mi.name = "ground"; mi.mesh = g.build()
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF; root.add_child(mi)
	var body := StaticBody3D.new(); body.name = "ground_col"
	var cs := CollisionShape3D.new(); cs.shape = mi.mesh.create_trimesh_shape(); body.add_child(cs); root.add_child(body)
	props.build(root, K)
	print("%s (%s): ground tris %d, props %d, buildings %d, stalls %d, shops %d" % [name, variant, g.tri_count(), props.count(), bl.get_child_count(), stalls.size(), shops.size()])
	K.save_piece(root, name)
