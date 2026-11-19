extends RefCounted
## Apartment band FILL helpers (claude/fill-apartments, 19 Nov). A COPY of the approved sample's apt_lib.gd (and the
## bits of cc_lib / strip_lib it calls), changed only where the fill blocks need it; apt_lib.gd itself is untouched
## (locked pieces were built with it). What is different from apt_lib:
##  - GY: the piece's own ground height (piece-local x, z). apt_lib stands everything on S.walk_y (flat). Block 1 is
##    flat (GY = walk height); blocks 2 and 3 set GY to their terraces before building. Buildings stand on their pad
##    (the record keeps "y"), loose things on the ground under them, a fence panel at the LOWEST ground along it.
##  - alleys at any position (apt_lib's sit at 54-60 only): the fill blocks continue the sample's alleys and add the
##    ones the neighbouring junctions' aprons call for.
##  - the floor is painted over the piece's own outline (any rectangle), cells unmerged (no T-joints), with a 0.3 m
##    skirt round the outside so a residual gap shows a face, not the land.
##  - no fill_open(): the shared yards are placed by hand in each piece script, with their reasons.
## A generator is NOT hidden in here: nothing in this file decides where a building, a yard or a park goes. dress()
## adds the things every apartment door and back wall has (walk, pot, light, intercom, mailbox, meters, bins, AC);
## the piece script decides everything else, line by line.
const K := preload("res://tools/city/pilot/kit_lib.gd")
const S := preload("res://tools/city/pilot/site.gd")
const W := preload("res://tools/city/pilot/pieces/wear_lib.gd")
const I := preload("res://tools/city/pilot/pieces/ind_lib.gd")
const SL := preload("res://tools/city/pilot/pieces/strip_lib.gd")

const PROP := 9.2
const SET := 3.0
const FORE := 2.5
const STALL_W := 2.7
const STALL_D := 5.5

## ground height of the piece at piece-local (x, z); flat walk height unless a piece sets its terraces
static var GY: Callable = S.walk_y

## ---------------------------------------------------------------- land on a slope (blocks 2 and 3)
## SURF: the block's base surface (x, z) -> local y, made by the piece from MEASURED street heights so it equals every
## street walk along the block's edges (and the locked neighbours' level ground). PADS: a level pad under every building
## [x0, z0, x1, z1, h], h = the surface at the middle of the building's front (Yasin's rule: nothing stands on a slope;
## the skill: a pad at the height of the middle of the front, eased into the slope over about 5 m). PRECT: the piece's
## outline; the ease fades out within 3 m of it, so every edge stays exactly on SURF (flush with the street and with the
## neighbouring piece, which computes the same SURF). Between two pads the heights are blended by inverse distance, so
## the ground never jumps; inside a pad it is exactly level.
static var SURF: Callable = S.walk_y
static var PADS: Array = []
static var PRECT := Rect2()
const EASE := 5.0
const EDGE_KEEP := 3.0

static func terrain(x: float, z: float) -> float:
	var s := float(SURF.call(x, z))
	if PADS.is_empty(): return s
	var wmax := 0.0; var num := 0.0; var den := 0.0
	for p: Array in PADS:
		var dx := maxf(maxf(float(p[0]) - x, x - float(p[2])), 0.0); var dz := maxf(maxf(float(p[1]) - z, z - float(p[3])), 0.0)
		var d := sqrt(dx * dx + dz * dz)
		if d >= EASE: continue
		var w := 1.0 - smoothstep(0.0, EASE, d)
		wmax = maxf(wmax, w)
		var iw := 1.0 / (d * d + 1e-6)
		num += float(p[4]) * iw; den += iw
	if wmax <= 0.0: return s
	var de := minf(minf(x - PRECT.position.x, PRECT.end.x - x), minf(z - PRECT.position.y, PRECT.end.y - z))
	var bf := smoothstep(0.0, EDGE_KEEP, de)
	return s + (num / den - s) * wmax * bf

## the piece outline (quadrant u / v) for the edge fade; call before any pad
static func outline(sx: float, sz: float, u0: float, v0: float, u1: float, v1: float) -> void:
	var a := Vector2(sx * u0, sz * v0); var b := Vector2(sx * u1, sz * v1)
	PRECT = Rect2(Vector2(minf(a.x, b.x), minf(a.y, b.y)), (b - a).abs())

## register a level pad for a building that will stand centred at (u, v) facing `face`; returns its height. The pad's
## footprint is painted as a concrete plinth (cut lines at its edges, so the floor is exactly level under the walls).
static func pad_for(paints: Array, sx: float, sz: float, folder: String, u: float, v: float, face: String, at_h := NAN) -> float:
	var st := K.building_stats(folder)
	var w: float = st.footprint_wd[0]; var d: float = st.footprint_wd[1]
	var along_v := face.ends_with("v")
	var hu := (w if along_v else d) * 0.5; var hv := (d if along_v else w) * 0.5
	var toward := -1.0 if face.begins_with("-") else 1.0
	var fu := u + (0.0 if along_v else toward * hu); var fv := v + (toward * hv if along_v else 0.0)
	var h := float(SURF.call(sx * fu, sz * fv)) if is_nan(at_h) else at_h
	var r := rect(sx, sz, u - hu, v - hv, u + hu, v + hv, "concrete")
	PADS.append([r[0], r[1], r[2], r[3], h])
	paints.insert(0, r)
	return h

## a level pad with no building on it (a play yard, a court): same rules
static func pad_rect(paints: Array, sx: float, sz: float, u0: float, v0: float, u1: float, v1: float, h: float, mat := "") -> void:
	var r := rect(sx, sz, u0, v0, u1, v1, mat)
	PADS.append([r[0], r[1], r[2], r[3], h])
	if mat != "": paints.insert(0, r)

static func gy(x: float, z: float) -> float:
	return float(GY.call(x, z))

static func q(sx: float, sz: float, u: float, v: float, y := 0.0) -> Vector3:
	return Vector3(sx * u, gy(sx * u, sz * v) + y, sz * v)

static func rect(sx: float, sz: float, u0: float, v0: float, u1: float, v1: float, mat: String) -> Array:
	return SL.rect(sx, sz, u0, v0, u1, v1, mat)

static func face_dir(sx: float, sz: float, face: String) -> Vector2:
	match face:
		"-v": return Vector2(0.0, -sz)
		"+v": return Vector2(0.0, sz)
		"-u": return Vector2(-sx, 0.0)
	return Vector2(sx, 0.0)

## one prop on the ground under it (loose things follow the ground)
static func put(props: K.Props, base: String, cond: String, sx: float, sz: float, u: float, v: float, yaw := 0.0, collide := true) -> void:
	I.add(props, base, cond, q(sx, sz, u, v), yaw, collide)

## a kit building centred at (u, v), front facing `face`, standing on its pad at height `pad` (NAN = the ground at its
## centre). Record {node, w, d, folder, face, u, v, y}.
static func place(bl: Node3D, sx: float, sz: float, folder: String, u: float, v: float, face: String, label := "", wear := 0.75, pad := NAN) -> Dictionary:
	var dir := face_dir(sx, sz, face)
	var yaw := rad_to_deg(atan2(dir.x, dir.y))
	var y := gy(sx * u, sz * v) if is_nan(pad) else pad
	var n := K.building(bl, folder, Vector3(sx * u, y, sz * v), yaw, label, wear)
	var st := K.building_stats(folder)
	return {"node": n, "w": float(st.footprint_wd[0]), "d": float(st.footprint_wd[1]), "folder": folder, "face": face, "u": u, "v": v, "y": y}

## building-local point -> piece point, at the building's pad height + y
static func at(b: Dictionary, lx: float, lz: float, y := 0.0) -> Vector3:
	var p: Vector3 = (b.node as Node3D).transform * Vector3(lx, 0.0, lz)
	return Vector3(p.x, float(b.y) + y, p.z)

## building-local point -> piece point on the GROUND there (yard things behind or beside a building)
static func atg(b: Dictionary, lx: float, lz: float, y := 0.0) -> Vector3:
	var p: Vector3 = (b.node as Node3D).transform * Vector3(lx, 0.0, lz)
	return Vector3(p.x, gy(p.x, p.z) + y, p.z)

## the door x positions (building-local) of a building's front, de-duplicated
static func doors_of(folder: String, kinds := ["apt_door", "shopdoor", "civic_door", "door", "door_spanish", "door_craftsman", "door_modern"]) -> Array:
	var out: Array = []
	for e: Array in K.building_stats(folder).get("doors_front", []):
		if String(e[0]) in kinds:
			var dup := false
			for o: float in out:
				if absf(o - float(e[1])) < 0.6: dup = true
			if not dup: out.append(float(e[1]))
	return out

## ---------------------------------------------------------------- wall items (Yasin: "prop in the glass", "prop
## sitting on a window", "prop overlaps on the wall"): every meter, light, mailbox, intercom, hose reel goes through
## here. The openings are the measured ones check_life.gd uses (interiors/room_contracts.json): the item slides along
## its wall to the nearest place where it is clear of every window and door (15 cm margin, at its own height), and
## inside the wall's ends; if no place within 3 m serves, it is LEFT OUT (returns false). facade: front / back /
## left / right of the building; x: along that wall in the model frame (front / back: model x, sides: model z).
static var _rc := {}
static func openings(folder: String) -> Array:
	if _rc.is_empty():        # the same measured openings check_life.gd reads (shops, apartments, and the houses)
		for f: String in ["room_contracts.json", "room_contracts_res.json"]:
			var pth := "res://map_dc/coronado/city_kit/interiors/" + f
			if FileAccess.file_exists(pth): _rc.merge((JSON.parse_string(FileAccess.get_file_as_string(pth)) as Dictionary).get("models", {}))
	return (_rc.get(folder, {}) as Dictionary).get("openings", [])

static func wall_x(b: Dictionary, facade: String, x: float, y: float, hw: float, h: float) -> float:
	var ops := openings(String(b.folder))
	var half: float = (float(b.w) if facade in ["front", "back"] else float(b.d)) * 0.5
	for k in 31:
		var c := x + (0.2 * ((k + 1) / 2) * (1.0 if k % 2 == 1 else -1.0) if k > 0 else 0.0)
		if absf(c) > half - hw - 0.12: continue
		var ok := true
		for o: Dictionary in ops:
			if String(o.facade) != facade: continue
			if c - hw < float(o.along) + float(o.w) * 0.5 + 0.15 and c + hw > float(o.along) - float(o.w) * 0.5 - 0.15 and y < float(o.y1) + 0.1 and y + h > float(o.y0) - 0.1:
				ok = false; break
		if ok: return c
	return NAN

static func wall(props: K.Props, b: Dictionary, base: String, cond: String, facade: String, x: float, y: float, off := 0.04, hw := -1.0) -> bool:
	var e := K.manifest(base)
	var half_w := float(e.get("footprint_w", 0.4)) * 0.5 if hw < 0.0 else hw
	var c := wall_x(b, facade, x, y, half_w, float(e.get("height", 0.4)))
	if is_nan(c): return false
	var w: float = b.w; var d: float = b.d
	var yaw := rad_to_deg((b.node as Node3D).rotation.y)
	match facade:
		"front": I.add(props, base, cond, at(b, c, d * 0.5 + off, y), yaw, false)
		"back": I.add(props, base, cond, at(b, c, -d * 0.5 - off, y), yaw + 180.0, false)
		"right": I.add(props, base, cond, at(b, w * 0.5 + off, c, y), yaw + 90.0, false)
		_: I.add(props, base, cond, at(b, -w * 0.5 - off, c, y), yaw - 90.0, false)
	return true

## black iron balconies on the brick walk-ups' entry bay (apt_lib.balconies, unchanged)
static func balconies(b: Dictionary, props: K.Props) -> void:
	var fol := String(b.folder)
	if not fol.contains("brk3_"): return
	var w: float = b.w; var d: float = b.d
	var yaw := rad_to_deg((b.node as Node3D).rotation.y)
	for e: Array in K.building_stats(fol).get("doors_front", []):
		if String(e[0]) != "apt_door": continue
		var bx := -w * 0.5 + 3.0 + 6.0 * clampf(floor((float(e[1]) + w * 0.5) / 6.0), 0.0, round(w / 6.0) - 1.0)
		for fy: float in [3.3, 6.3]: I.add(props, "prop_balcony_clutter", "iron", at(b, bx, d * 0.5 + 0.02, fy), yaw, false)
		break

## meters, gas, condensers and (homes) the three bin carts at the back wall (cc_lib.back_of_house on the pad height)
static func back_of_house(props: K.Props, b: Dictionary, residential := false) -> void:
	var w: float = b.w; var d: float = b.d
	var yaw := rad_to_deg((b.node as Node3D).rotation.y) + 180.0
	var x0 := -w * 0.5 + 1.6
	# the meter bank as one 1.1 m item (three meters side by side), then the gas meter beside it
	var mx := wall_x(b, "back", x0 + 0.42, 1.05, 0.55, float(K.manifest("prop_meter_electric").get("height", 0.6)))
	if not is_nan(mx):
		for k in 3: props.add("prop_meter_electric", "worn", at(b, mx - 0.42 + k * 0.42, -d * 0.5 - 0.02, 1.05), yaw)
		wall(props, b, "prop_meter_gas", "rusty", "back", mx + 1.3, 0.2, 0.02)
	var n_ac := 1 if w < 14.0 else 2
	if w < 10.0:     # a small house: the condenser goes beside its side wall, the back wall is the bins' and the meters'
		props.add("prop_ac_condenser_compact", "worn", at(b, -w * 0.5 - 0.7, -d * 0.5 + 1.4), yaw - 90.0)
	else:
		for k in n_ac: props.add("prop_ac_condenser", "worn", at(b, x0 + 3.4 + k * 1.3, -d * 0.5 - 0.75), yaw)
	if residential:
		for k in 3: props.add(["prop_trash_cart_black", "prop_trash_cart_blue", "prop_trash_cart_green"][k], "worn", at(b, w * 0.5 - 1.5 - k * 0.8, -d * 0.5 - 0.75), yaw)

## Life on one apartment building (apt_lib.dress, same rules): a walk from each front door to `walk_to`, pot, coach
## light, intercom, mailbox bank; low boxwood along the front yard (gaps at the walks) and a front tree when there is
## room; window ACs on the side walls, a dish or antenna at the back of the roof; back of house; a patio when `patio`.
## Differences: heights from the pad / ground; `ac_sides` lets a piece leave out the AC on a wall that faces a
## neighbour 1-2 m away (nobody hangs a unit into a gap); returns the walk centres (along the row) so the piece script
## keeps its own props off them.
static func dress(b: Dictionary, paints: Array, props: K.Props, dec: K.Decals, rr: RandomNumberGenerator, sx: float, sz: float, walk_to: float, hedge := true, patio := true, ac_sides := [-1.0, 1.0]) -> Array:
	var st := K.building_stats(String(b.folder))
	var w: float = b.w; var d: float = b.d
	var n: Node3D = b.node
	var yaw := rad_to_deg(n.rotation.y)
	var along_v := String(b.face).ends_with("v")
	var front_c: float = (b.v if along_v else b.u)
	var toward := -1.0 if String(b.face).begins_with("-") else 1.0
	var line := front_c + toward * d * 0.5
	var doors := doors_of(String(b.folder))
	if doors.is_empty(): doors.append(0.0)
	var walk_xs: Array = []
	for lx: float in doors:
		var p := at(b, lx, d * 0.5)
		var along := p.x * sx if along_v else p.z * sz
		walk_xs.append(along)
		var a0 := minf(line, walk_to); var a1 := maxf(line, walk_to)
		if absf(a1 - a0) > 0.05:
			if along_v: paints.append(rect(sx, sz, along - 0.7, a0, along + 0.7, a1, "concrete"))
			else: paints.append(rect(sx, sz, a0, along - 0.7, a1, along + 0.7, "concrete"))
		var pot_x := lx + 1.35
		var pot_ok := true
		for e2: Array in st.get("doors_front", []):
			if absf(pot_x - float(e2[1])) < 1.15: pot_ok = false
		if pot_ok: I.add(props, "plant_potted_succulent", "normal", at(b, pot_x, d * 0.5 + 0.35), yaw)
		wall(props, b, ["prop_porch_light_coach", "prop_porch_light_coach_bronze", "prop_porch_light_barn"][rr.randi() % 3], "worn", "front", lx - 0.9, 2.25, 0.05)
		dec.add(14, Vector2(p.x, p.z) + face_dir(sx, sz, String(b.face)) * 1.0, yaw, 1.6, 1.4, GY, Color(1, 1, 1, 0.45))
		wall(props, b, "prop_buzzer_panel", "worn", "front", lx + 0.8, 1.15, 0.01)
	if not String(b.folder).begins_with("civic/"): wall(props, b, "prop_mailbox_wall_brass" if rr.randf() < 0.5 else "prop_mailbox_wall_black", "worn", "front", float(doors[0]) - 1.6, 1.3, 0.05)
	var along_c: float = b.u if along_v else b.v
	if hedge:
		var hv := walk_to - toward * 0.45
		var hs := along_c - w * 0.5 + 0.2
		while hs + 2.0 <= along_c + w * 0.5:
			var clear := true
			for wx: float in walk_xs:
				if absf(hs + 1.0 - wx) < 2.0: clear = false
			if clear:
				var hp := q(sx, sz, hs + 1.0, hv) if along_v else q(sx, sz, hv, hs + 1.0)
				I.add(props, "hedge_boxwood_low_2m", "normal", hp, 0.0 if along_v else 90.0)
				hs += 2.0
			else:
				hs += 0.5
		if w >= 15.0 and absf(walk_to - line) >= 2.6:
			var tv := (walk_to + line) * 0.5
			var ts := along_c + w * 0.5 - 2.2
			for e3: Array in st.get("doors_front", []):
				var dpos := at(b, float(e3[1]), d * 0.5)
				var dal := dpos.x * sx if along_v else dpos.z * sz
				if absf(ts - dal) < 1.6: ts = dal - 1.7 if ts < dal else dal + 1.7
			var tp := q(sx, sz, ts, tv) if along_v else q(sx, sz, tv, ts)
			I.add(props, ["palm_queen_a", "palm_queen_b", "tree_magnolia_a", "tree_magnolia_b"][rr.randi() % 4], "normal", tp, rr.randf_range(0, 360))
	var h: float = float(st.get("height", 7.0))
	var public := String(b.folder).begins_with("civic/") or String(b.folder).begins_with("public/") or String(b.folder).begins_with("commercial/")
	for side: float in ([] if public else ac_sides):
		if rr.randf() < 0.7:
			I.add(props, "prop_ac_window", "rusty" if rr.randf() < 0.4 else "worn", at(b, side * (w * 0.5 + 0.12), rr.randf_range(-d * 0.3, d * 0.3), 2.4), yaw + side * 90.0, false)
		if h > 7.5 and rr.randf() < 0.6:
			I.add(props, "prop_ac_window", "worn", at(b, side * (w * 0.5 + 0.12), rr.randf_range(-d * 0.3, d * 0.3), 5.4), yaw + side * 90.0, false)
	if not public: I.add(props, "prop_satellite_dish" if rr.randf() < 0.6 else "prop_tv_antenna", "worn", at(b, rr.randf_range(-w * 0.35, w * 0.35), -d * 0.5 + 0.8, h - 0.05), yaw + 180.0, false)
	if String(b.folder).contains("dingbat"):
		I.add(props, "prop_dingbat_stair", "worn", at(b, -w * 0.5 - 0.6, 0.0), yaw - 90.0, false)
	back_of_house(props, b, not public)
	if patio:
		var px := rr.randf_range(-w * 0.25, w * 0.25)
		I.add(props, "prop_patio_set_4", "worn", atg(b, px, -d * 0.5 - 3.4), yaw + rr.randf_range(-20, 20))
		I.add(props, "prop_bbq_kettle" if rr.randf() < 0.5 else "prop_bbq_gas_cart", "worn", atg(b, px + 2.6, -d * 0.5 - 2.4), yaw + 180.0)
		wall(props, b, "prop_hose_reel_wall", "worn", "back", -w * 0.5 + 0.9, 0.0, 0.1)
		var under := atg(b, px, -d * 0.5 - 3.4)
		dec.add(14, Vector2(under.x, under.z), yaw, 3.6, 3.0, GY, Color(1, 1, 1, 0.5))
	var g0 := at(b, -w * 0.5, d * 0.5 + 0.4); var g1 := at(b, w * 0.5, d * 0.5 + 0.4)
	grime(dec, Vector2(g0.x, g0.z), Vector2(g1.x, g1.z), rr)
	var bp := at(b, w * 0.5 - 2.3, -d * 0.5 - 0.75)
	dec.add(14, Vector2(bp.x, bp.z), yaw, 3.0, 1.6, GY, Color(1, 1, 1, 0.6))
	return walk_xs

## grime along the foot of a wall (ind_lib.wall_grime on this piece's ground)
static func grime(dec: K.Decals, a: Vector2, b: Vector2, rr: RandomNumberGenerator) -> void:
	var L := a.distance_to(b); var dir := (b - a) / maxf(L, 0.01)
	var yaw := rad_to_deg(atan2(dir.x, dir.y))
	var s := 1.0
	while s < L - 1.0:
		var seg := minf(rr.randf_range(3.0, 6.0), L - s)
		dec.add(14, a + dir * (s + seg * 0.5), yaw, 1.4, seg, GY, Color(1, 1, 1, rr.randf_range(0.45, 0.7)))
		s += seg + rr.randf_range(0.5, 2.5)

## nose-in stalls off an alley (apt_lib.pad): along u (the alley runs along u) or along v; edge = the alley edge,
## dir = which way the stalls go from it. Oil under the stalls used most. Returns the new stall records.
static func pad(paints: Array, stalls: Array, dec: K.Decals, rr: RandomNumberGenerator, sx: float, sz: float, along_u: bool, s0: float, s1: float, edge: float, dir: float, paint_pad := true) -> Array:
	var n := int(floor((s1 - s0) / STALL_W))
	if n < 1: return []
	var depth := STALL_D + 0.8
	var first := stalls.size()
	if along_u:
		SL.stalls_u(paints, stalls, sx, sz, s0, n, edge + dir * 0.8, dir)
		if paint_pad: paints.append(rect(sx, sz, s0, minf(edge, edge + dir * depth), s1, maxf(edge, edge + dir * depth), "asphalt"))
	else:
		SL.stalls_v(paints, stalls, sx, sz, s0, n, edge + dir * 0.8, dir)
		if paint_pad: paints.append(rect(sx, sz, minf(edge, edge + dir * depth), s0, maxf(edge, edge + dir * depth), s1, "asphalt"))
	var new := stalls.slice(first)
	for s: Array in new:
		s.append(gy(float(s[0]), float(s[1])))
		if rr.randf() < 0.7: W.oil(dec, rr, Vector2(float(s[0]), float(s[1])), float(s[2]), GY, rr.randf_range(0.5, 0.9))
	return new

## An alley 6 m wide from `a0` to a0 + 6 (a v value when along_u, else a u value), running s0..s1: asphalt with a
## concrete centre gutter, cracks, a trench patch, oil down the middle, grime along both edges. Utility poles on the
## edge at the places the piece script lists (`pole_s`, along the alley; `pole_at` = across, e.g. a0 - 0.7 = just
## outside the a0 edge), each on its own 1.4 m gravel pad (Yasin: "utility poles are on asphalt" - never on the
## asphalt, never on a stall); a transformer where the script says (`tx` = indices). Their places go into `poles`.
## Nothing else: dumpsters and walls are the piece's own decision.
static func alley(paints: Array, props: K.Props, dec: K.Decals, rr: RandomNumberGenerator, sx: float, sz: float, along_u: bool, a0: float, s0: float, s1: float, poles: Array, pole_s: Array = [], pole_at := NAN, tx: Array = []) -> void:
	var a1 := a0 + 6.0; var c := a0 + 3.0
	if along_u:
		paints.append(rect(sx, sz, s0, c - 0.4, s1, c + 0.4, "concrete"))
		paints.append(rect(sx, sz, s0, a0, s1, a1, "asphalt"))
	else:
		paints.append(rect(sx, sz, c - 0.4, s0, c + 0.4, s1, "concrete"))
		paints.append(rect(sx, sz, a0, s0, a1, s1, "asphalt"))
	var pa_c0 := a0 - 0.7 if is_nan(pole_at) else pole_at
	for k in pole_s.size():
		var s := float(pole_s[k][0]) if pole_s[k] is Array else float(pole_s[k])
		var pa_c := pa_c0 if not (pole_s[k] is Array) else float(pole_s[k][1])
		var pp := q(sx, sz, s, pa_c) if along_u else q(sx, sz, pa_c, s)
		var pyaw := 90.0 if along_u else 0.0
		I.add(props, "prop_utility_pole_transformer" if k in tx else "prop_utility_pole", "worn", pp, pyaw)
		poles.append([pp, pyaw, "u" if along_u else "v"])
		paints.insert(0, rect(sx, sz, s - 0.7, pa_c - 0.7, s + 0.7, pa_c + 0.7, "gravel") if along_u else rect(sx, sz, pa_c - 0.7, s - 0.7, pa_c + 0.7, s + 0.7, "gravel"))
	var pa := Vector2(sx * s0, sz * a0) if along_u else Vector2(sx * a0, sz * s0)
	var pb := Vector2(sx * s1, sz * a1) if along_u else Vector2(sx * a1, sz * s1)
	W.cracks(dec, rr, minf(pa.x, pb.x), minf(pa.y, pb.y), maxf(pa.x, pb.x), maxf(pa.y, pb.y), int(absf(s1 - s0) / 4.0), GY, 0.4)
	var k := s0 + 2.0
	while k < s1 - 3.0:
		var o := Vector2(sx * k, sz * (c + rr.randf_range(-1.6, 1.6))) if along_u else Vector2(sx * (c + rr.randf_range(-1.6, 1.6)), sz * k)
		W.oil(dec, rr, o, 0.0 if not along_u else 90.0, GY, rr.randf_range(0.5, 0.85))
		for e: float in [a0 + 0.3, a1 - 0.3]:
			var gp := Vector2(sx * (k + 1.5), sz * e) if along_u else Vector2(sx * e, sz * (k + 1.5))
			dec.add(14, gp, 90.0 if along_u else 0.0, 0.7, 3.0, GY, Color(1, 1, 1, rr.randf_range(0.4, 0.65)))
		k += rr.randf_range(5.0, 9.0)
	for t in 2:
		var tp := rr.randf_range(s0 + 5.0, s1 - 5.0)
		var pv := Vector2(sx * tp, sz * c) if along_u else Vector2(sx * c, sz * tp)
		dec.add(2 + t, pv, 90.0 if along_u else 0.0, 2.4, 6.0, GY, Color(1, 1, 1, 0.9))

## A fence run a -> b (piece x, z), panels never stretched (a short last run gets one shortened panel by overlap: the
## panels are spread evenly with the ends flush), a post at EVERY joint, each panel at the lowest ground along it.
static func fence(props: K.Props, a: Vector2, b: Vector2, kind := "fence_wood_privacy", post := "fence_post_privacy", panel := 2.0, cond := "worn") -> void:
	var L := a.distance_to(b)
	if L < 0.3: return
	var n := maxi(1, int(ceil(L / panel - 0.02)))
	var yaw := rad_to_deg(atan2(b.x - a.x, b.y - a.y)) + 90.0
	var shrink := minf(1.0, (L / n) / panel)      # never stretched: a run that is not whole panels gets shorter panels
	for i in n:
		var e0 := a.lerp(b, float(i) / n); var e1 := a.lerp(b, float(i + 1) / n)
		var m := (e0 + e1) * 0.5
		var y := minf(gy(e0.x, e0.y), gy(e1.x, e1.y)) - (0.03 if absf(gy(e0.x, e0.y) - gy(e1.x, e1.y)) > 0.01 else 0.0)
		add_scaled(props, kind, cond, Vector3(m.x, y, m.y), yaw, shrink)
	for i in n + 1:
		var e := a.lerp(b, float(i) / n)
		I.add(props, post, cond, Vector3(e.x, gy(e.x, e.y), e.y), yaw)

## one prop shortened along its own x (a fence panel cut to fit); the collider stays full size
static func add_scaled(props: K.Props, base: String, cond: String, pos: Vector3, yaw: float, sxl: float) -> void:
	if sxl >= 0.999:
		I.add(props, base, cond, pos, yaw); return
	var conds: Array = K.manifest(base).get("conds", [])
	var c := cond
	if not conds.is_empty() and not (c in conds): c = String(conds[0])
	if conds == ["clean"]: c = cond
	var k := base + "|" + c
	if not props.items.has(k): props.items[k] = []
	var bs := Basis(Vector3.UP, deg_to_rad(yaw)) * Basis.from_scale(Vector3(sxl, 1.0, 1.0))
	props.items[k].append(Transform3D(bs, pos))
	props.col_items.append([base, c, Transform3D(Basis(Vector3.UP, deg_to_rad(yaw)), pos)])   # unscaled: a collider poking into the wall it meets is harmless, a scaled one is not supported

## the same in quadrant coordinates (u, v)
static func fence_uv(props: K.Props, sx: float, sz: float, u0: float, v0: float, u1: float, v1: float, kind := "fence_wood_privacy", post := "fence_post_privacy", panel := 2.0) -> void:
	fence(props, Vector2(sx * u0, sz * v0), Vector2(sx * u1, sz * v1), kind, post, panel)

## a run with ONE gate leaf in it at `g` (distance from the start), the gate's own posts carried by the two runs
static func fence_gate(props: K.Props, sx: float, sz: float, u0: float, v0: float, u1: float, v1: float, g: float, kind := "fence_wood_privacy", post := "fence_post_privacy", gate := "fence_gate_privacy", panel := 2.0) -> void:
	var a := Vector2(u0, v0); var b := Vector2(u1, v1)
	var dirv := (b - a).normalized()
	var g0 := a + dirv * (g - 0.6); var g1 := a + dirv * (g + 0.6)
	fence_uv(props, sx, sz, a.x, a.y, g0.x, g0.y, kind, post, panel)
	fence_uv(props, sx, sz, g1.x, g1.y, b.x, b.y, kind, post, panel)
	var gm := a + dirv * g
	var gw := Vector2(sx * gm.x, sz * gm.y); var dw := Vector2(sx * dirv.x, sz * dirv.y)
	I.add(props, gate, "worn", Vector3(gw.x, gy(gw.x, gw.y), gw.y), rad_to_deg(atan2(dw.x, dw.y)) + 90.0)

## a CMU dumpster enclosure open toward `yaw` (strip_lib.enclosure on this ground): trash + recycling inside
static func enclosure(props: K.Props, p: Vector3, yaw: float, kinds := ["prop_dumpster_3yd_green", "prop_dumpster_3yd_blue"]) -> void:
	var b := Basis(Vector3.UP, deg_to_rad(yaw))
	for lx: float in [-2.03, 0.0, 2.03]:
		I.add(props, "fence_cmu_wall", "worn", p + b * Vector3(lx, 0, -1.6), yaw)
	for side: float in [-1.0, 1.0]:
		I.add(props, "fence_cmu_wall", "worn", p + b * Vector3(side * 3.15, 0, -0.55), yaw + 90.0)
		I.add(props, "fence_cmu_wall", "worn", p + b * Vector3(side * 3.15, 0, 1.45), yaw + 90.0)
	I.add(props, String(kinds[0]), "rusty", p + b * Vector3(-1.2, 0, 0.0), yaw)
	I.add(props, String(kinds[1]), "rusty", p + b * Vector3(1.2, 0, 0.0), yaw)

## wheel stops at the head of stalls (strip_lib.wheel_stops on this ground); none under a dingbat or in a carport
static func wheel_stops(props: K.Props, rr: RandomNumberGenerator, stalls: Array, kind := "prop_wheel_stop_concrete") -> void:
	for st: Array in stalls:
		var yaw := float(st[2])
		var fwd := Vector3(sin(deg_to_rad(yaw)), 0.0, cos(deg_to_rad(yaw)))
		var p := Vector3(float(st[0]), 0.0, float(st[1])) + fwd * (STALL_D * 0.5 - 0.55)
		p.y = gy(p.x, p.z) + 0.002
		var off := rr.randf() < 0.2
		I.add(props, kind, "dirty" if off else "worn", p, yaw + (rr.randf_range(-12, 12) if off else 0.0), false)

## start a piece: hill off (the band is flat in the sample's frame; terraces come through GY)
static func begin(name: String, sx: float, sz: float) -> Dictionary:
	S.hill_on = false
	GY = S.walk_y
	SURF = S.walk_y; PADS = []; PRECT = Rect2()
	var root := Node3D.new(); root.name = name
	var bl := Node3D.new(); bl.name = "Buildings"; root.add_child(bl)
	var pk := Node3D.new(); pk.name = "Parks"; root.add_child(pk)
	return {"root": root, "bl": bl, "pk": pk, "g": K.Ground.new(), "props": K.Props.new(), "dec": K.Decals.new(), "rr": W.rng_for(name),
		"paints": [], "stalls": [], "stops": [], "poles": [], "blds": [], "sx": sx, "sz": sz, "name": name}

## Finish: no tree within 0.9 m of a fence panel (kept from apt_lib.done, counted and printed), wheel stops on the
## stalls listed in ctx.stops, the floor over [u0, v0, u1, v1] (cells unmerged), a 0.3 m skirt round its outside
## edge, then save. `walls`: extra retaining faces [[x0, z0, x1, z1, y_low, y_high]] the piece script asks for.
static func finish(ctx: Dictionary, u0: float, v0: float, u1: float, v1: float, base := "grass") -> void:
	var props: K.Props = ctx.props
	var fence_pts: Array = []
	for k: String in props.items:
		if not k.begins_with("fence_"): continue
		for t: Transform3D in props.items[k]:
			for f: float in [-1.0, -0.5, 0.0, 0.5, 1.0]:
				var fp := t.origin + t.basis.x.normalized() * f
				fence_pts.append(Vector2(fp.x, fp.z))
	var dropped := 0
	for k2: String in props.items.keys():
		if not (k2.begins_with("tree_") or k2.begins_with("palm_")): continue
		var keep: Array = []
		for t2: Transform3D in props.items[k2]:
			var ok := true
			for fp2: Vector2 in fence_pts:
				if fp2.distance_to(Vector2(t2.origin.x, t2.origin.z)) < 0.9: ok = false; break
			if ok: keep.append(t2)
			else: dropped += 1
		props.items[k2] = keep
	wheel_stops(props, ctx.rr, ctx.stops)
	var sx: float = ctx.sx; var sz: float = ctx.sz
	var a := Vector2(sx * u0, sz * v0); var b := Vector2(sx * u1, sz * v1)
	var x0 := minf(a.x, b.x); var x1 := maxf(a.x, b.x); var z0 := minf(a.y, b.y); var z1 := maxf(a.y, b.y)
	var g: K.Ground = ctx.g
	K.painted_rect(g, x0, z0, x1, z1, ctx.paints, GY, base, false)
	# skirt: a face 0.3 m down all round the outside edge, in the walls' concrete (hidden under a flush neighbour)
	var down := func(x: float, z: float) -> float: return gy(x, z) - 0.3
	for e: Array in [[Vector2(x0, z0), Vector2(x1, z0)], [Vector2(x1, z0), Vector2(x1, z1)], [Vector2(x1, z1), Vector2(x0, z1)], [Vector2(x0, z1), Vector2(x0, z0)]]:
		var pa: Vector2 = e[0]; var pb: Vector2 = e[1]
		var pts := PackedVector2Array()
		var n := maxi(1, ceili(pa.distance_to(pb) / 4.0))
		for i in n + 1: pts.append(pa.lerp(pb, float(i) / n))
		g.wall_line("wall", pts, down, GY, 1.0)
	for wl: Array in ctx.get("walls", []):
		var wp := PackedVector2Array([Vector2(float(wl[0]), float(wl[1])), Vector2(float(wl[2]), float(wl[3]))])
		var lo := float(wl[4]); var hi := float(wl[5])
		g.wall_line("wall", wp, func(_x: float, _z: float) -> float: return lo, func(_x: float, _z: float) -> float: return hi, float(wl[6]) if wl.size() > 6 else 1.0)
	var root: Node3D = ctx.root
	root.set_meta("poles", ctx.poles)
	root.set_meta("stalls", ctx.stalls)
	var wm := (ctx.dec as K.Decals).build()
	if wm: root.add_child(wm)
	var mi := MeshInstance3D.new(); mi.name = "ground"; mi.mesh = g.build()
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF; root.add_child(mi)
	var body := StaticBody3D.new(); body.name = "ground_col"
	var cs := CollisionShape3D.new(); cs.shape = mi.mesh.create_trimesh_shape(); body.add_child(cs); root.add_child(body)
	props.build(root, K)
	print("PIECE %s: ground tris %d, props %d, buildings %d, stalls %d, trees dropped by fences %d" % [ctx.name, g.tri_count(), props.count(), (ctx.bl as Node3D).get_child_count(), (ctx.stalls as Array).size(), dropped])
	K.save_piece(root, String(ctx.name))

## ================================================================ POLISH PASS (Yasin 19 Nov, after the lock: "run a polish
## pass in all your quarters, both indoors and outdoors ... plenty of props"). Everything here only ADDS: it runs at the end
## of a piece script with its own random sequence, so every prop, building and ground cell already there stays identical
## (proved per piece with diff_piece.gd). Every added prop is tested on its own spot first and LEFT OUT if the spot is not
## free: clear of buildings (0.3 m), of door steps (1.6 m), of every prop already there (half their diagonals), on grass /
## bark / gravel (never a walk, a stall, an alley or a road), 0.6 m inside the piece.
static var _rad := {}
static func _radius(base: String) -> float:
	if not _rad.has(base):
		var e := K.manifest(base)
		_rad[base] = clampf(Vector2(float(e.get("footprint_w", 0.6)), float(e.get("footprint_d", 0.6))).length() * 0.5, 0.25, 3.0)
	return float(_rad[base])

static func _surface(paints: Array, p: Vector2) -> String:
	for pr: Array in paints:
		if p.x >= float(pr[0]) and p.x <= float(pr[2]) and p.y >= float(pr[1]) and p.y <= float(pr[3]): return String(pr[4])
	return "grass"

static func free_at(ctx: Dictionary, p: Vector2, r: float, allowed: Array, rect: Rect2) -> bool:
	if p.x < rect.position.x + 0.6 + r or p.x > rect.end.x - 0.6 - r or p.y < rect.position.y + 0.6 + r or p.y > rect.end.y - 0.6 - r: return false
	if not (_surface(ctx.paints, p) in allowed): return false
	for b: Dictionary in ctx.blds:
		var lp: Vector3 = (b.node as Node3D).transform.affine_inverse() * Vector3(p.x, 0.0, p.y)
		if absf(lp.x) < float(b.w) * 0.5 + r + 0.3 and absf(lp.z) < float(b.d) * 0.5 + r + 0.3: return false
		for dx: float in doors_of(String(b.folder)):
			if Vector2(lp.x - dx, lp.z - (float(b.d) * 0.5 + 0.9)).length() < 1.6 + r: return false
	var props: K.Props = ctx.props
	for k: String in props.items:
		var base := k.get_slice("|", 0)
		var mount := String(K.manifest(base).get("mount", "ground"))
		if mount != "ground": continue
		var rb := _radius(base) if not base.begins_with("fence") else 0.15
		for t: Transform3D in props.items[k]:
			if t.origin.y - gy(t.origin.x, t.origin.z) > 1.2: continue
			if base.begins_with("fence") and not base.contains("post"):
				# a panel is a line: test the distance to its segment
				var ax := t.basis.x.normalized() * 1.0
				var a2 := Vector2(t.origin.x - ax.x, t.origin.z - ax.z); var b2 := Vector2(t.origin.x + ax.x, t.origin.z + ax.z)
				var tt := clampf((p - a2).dot(b2 - a2) / maxf((b2 - a2).length_squared(), 1e-6), 0.0, 1.0)
				if p.distance_to(a2.lerp(b2, tt)) < r + 0.25: return false
				continue
			if Vector2(t.origin.x, t.origin.z).distance_to(p) < r + rb: return false
	return true

## one prop at (u, v) if its spot is free; true when placed
static func polish_put(ctx: Dictionary, base: String, cond: String, u: float, v: float, yaw: float, rect: Rect2, allowed := ["grass", "mulch", "gravel"]) -> bool:
	var sx: float = ctx.sx; var sz: float = ctx.sz
	var p := Vector2(sx * u, sz * v)
	if not free_at(ctx, p, _radius(base), allowed, rect): return false
	I.add(ctx.props, base, cond, Vector3(p.x, gy(p.x, p.y), p.y), yaw)
	return true

## the things every lived-in building gains in the polish pass (the same kind of rule as dress()): downspouts at the
## back corners of the taller ones, the house numbers by the first door, on homes a vine on a blank side wall or a
## second dish, grime along the back wall's foot. Every wall item through wall(): clear of the measured windows and
## doors or left out.
static func polish_building(ctx: Dictionary, b: Dictionary, rr: RandomNumberGenerator, rect := Rect2()) -> void:
	var props: K.Props = ctx.props
	var w: float = b.w; var d: float = b.d
	var fol := String(b.folder)
	var h := float(K.building_stats(fol).get("height", 6.0))
	var home := not (fol.begins_with("commercial/") or fol.begins_with("civic/") or fol.begins_with("garages/") or fol.begins_with("public/"))
	if fol.begins_with("garages/"): return
	if h > 4.5:
		for sd: float in [-1.0, 1.0]: wall(props, b, "prop_downspout_3m", "worn", "back", sd * (w * 0.5 - 0.35), 0.0, 0.02)
	var ds := doors_of(fol)
	if home and not ds.is_empty(): wall(props, b, "prop_house_numbers_wood" if rr.randf() < 0.5 else "prop_house_numbers_tile", "worn", "front", float(ds[0]) + 1.25, 1.85, 0.02)
	if home:
		var side := "left" if rr.randf() < 0.5 else "right"
		if rr.randf() < 0.55: wall(props, b, "plant_bougainvillea_wall", "normal", side, rr.randf_range(-d * 0.2, d * 0.2), 0.0, 0.05)
		elif h > 5.0: wall(props, b, "prop_satellite_dish_round", "worn", side, rr.randf_range(-d * 0.3, d * 0.3), minf(h - 1.2, 5.6), 0.05)
	var g0 := at(b, -w * 0.5, -d * 0.5 - 0.35); var g1 := at(b, w * 0.5, -d * 0.5 - 0.35)
	grime(ctx.dec, Vector2(g0.x, g0.z), Vector2(g1.x, g1.z), rr)
	if not home or rect.size == Vector2.ZERO: return
	# the second layer (Yasin: "plenty of props"): what tenants add round a home, each only where its spot is free
	var yaw := rad_to_deg((b.node as Node3D).rotation.y)
	var sx: float = ctx.sx; var sz: float = ctx.sz
	var put_local := func(base: String, lx: float, lz: float, ywo: float) -> void:
		var p := at(b, lx, lz)
		polish_put(ctx, base, "normal" if (base.begins_with("plant_") or base.begins_with("hedge_") or base.begins_with("tree_")) else ("dirty" if rr.randf() < 0.3 else "worn"), p.x * sx, p.z * sz, yaw + ywo, rect)
	# plants at the front corners (people plant beside their windows), two kinds per home
	var pl := ["plant_bird_of_paradise", "plant_agave_americana_small", "plant_bougainvillea_mound", "plant_potted_leafy"]
	for sd: float in [-1.0, 1.0]: put_local.call(String(pl[rr.randi() % pl.size()]), sd * (w * 0.5 - 0.7), d * 0.5 + 1.0, rr.randf_range(0, 360))
	# a privet hedge down one side yard: privacy from the next building's windows
	var hs := -1.0 if rr.randf() < 0.5 else 1.0
	put_local.call("hedge_privet_2m", hs * (w * 0.5 + 1.0), rr.randf_range(-d * 0.25, d * 0.25), 90.0)
	# a residents' bike rack in a walk-up's front yard, along the facade (never across a walk: the spot test keeps it off)
	if fol.contains("apt3") or fol.contains("stucco3") or fol.contains("garden_") or fol.contains("court_white"):
		put_local.call("prop_bike_rack", w * 0.5 - 2.6, d * 0.5 + 1.9, 0.0)
	# the back yard: one more thing a household leaves out
	var bk := ["prop_adirondack_wood", "prop_bbq_gas_cart", "plant_potted_leafy", "prop_patio_set_4", "prop_hose_reel_cart", "prop_propane_cylinder_100lb"]
	put_local.call(String(bk[rr.randi() % bk.size()]), rr.randf_range(-w * 0.35, w * 0.35), -d * 0.5 - rr.randf_range(4.5, 7.0), rr.randf_range(0, 360))
	put_local.call(String(bk[rr.randi() % bk.size()]), rr.randf_range(-w * 0.35, w * 0.35), -d * 0.5 - rr.randf_range(1.6, 2.4), rr.randf_range(0, 360))

## a hand-chosen yard spot gets a cluster of a kind, turned to `yaw` (each item tested on its own spot):
##   sit (a family's patio corner), lounge (chairs under an arbor), garden (a bark bed with plants), tools (hose, gas,
##   sprinkler), bins (the carts against a fence), play (a bark pad with a swing or slide and the parent's bench),
##   shade (a tree with a bench under it), wash (a clothesline), cart (the Coronado golf cart parked by a back gate)
static func polish_spot(ctx: Dictionary, kind: String, u: float, v: float, yaw: float, rr: RandomNumberGenerator, rect: Rect2) -> int:
	var sx: float = ctx.sx; var sz: float = ctx.sz
	var bs := Basis(Vector3.UP, deg_to_rad(yaw))
	var items: Array = []
	match kind:
		"sit": items = [["prop_patio_set_4", 0.0, 0.0, 0.0], ["prop_bbq_kettle", 2.0, 0.6, 0.0], ["prop_adirondack_wood", -2.0, 0.4, 160.0], ["plant_potted_leafy", 1.8, -1.4, 0.0]]
		"lounge": items = [["prop_garden_arbor", 0.0, -0.9, 0.0], ["prop_adirondack_white", -0.7, 0.4, 170.0], ["prop_adirondack_wood", 0.7, 0.4, 190.0], ["plant_potted_succulent", 1.6, -0.6, 0.0]]
		"garden": items = [["plant_bird_of_paradise", -1.2, 0.0, 30.0], ["plant_agave_americana_small", 0.0, 0.0, 80.0], ["plant_bougainvillea_mound", 1.2, 0.0, 140.0]]
		"tools": items = [["prop_hose_reel_cart", 0.0, 0.0, 0.0], ["prop_propane_cylinder_100lb", 0.8, 0.0, 0.0], ["prop_sprinkler_popup", -1.6, 1.0, 0.0]]
		"bins": items = [["prop_trash_cart_black", 0.0, 0.0, 0.0], ["prop_trash_cart_blue", 0.8, 0.0, 0.0], ["prop_trash_cart_green", 1.6, 0.0, 0.0], ["prop_recycling_receptacle", 2.5, 0.0, 0.0]]
		"play": items = [["prop_swing_set", 0.0, 0.0, 0.0], ["prop_park_bench", 0.0, 3.0, 180.0]]
		"shade": items = [["tree_magnolia_a", 0.0, 0.0, 30.0], ["prop_park_bench", 0.0, 1.8, 180.0]]
		"wash": items = [["prop_clothesline", 0.0, 0.0, 0.0]]
		"cart": items = [["prop_golf_cart_white" if rr.randf() < 0.5 else "prop_golf_cart_blue", 0.0, 0.0, 0.0]]
	if kind == "garden" or kind == "play":
		var c := Vector2(sx * u, sz * v)
		if not free_at(ctx, c, 2.0, ["grass"], rect): return 0
		var hw := 2.0 if kind == "garden" else 3.0; var hd := 0.8 if kind == "garden" else 2.2
		var corners := [bs * Vector3(-hw, 0, -hd), bs * Vector3(hw, 0, hd)]
		(ctx.paints as Array).insert(0, [c.x + minf((corners[0] as Vector3).x, (corners[1] as Vector3).x), c.y + minf((corners[0] as Vector3).z, (corners[1] as Vector3).z), c.x + maxf((corners[0] as Vector3).x, (corners[1] as Vector3).x), c.y + maxf((corners[0] as Vector3).z, (corners[1] as Vector3).z), "mulch"])
	var n := 0
	for it: Array in items:
		var o := bs * Vector3(float(it[1]), 0.0, float(it[2]))
		var base := String(it[0])
		var cond := "normal" if (base.begins_with("plant_") or base.begins_with("tree_")) else ("dirty" if rr.randf() < 0.3 else "worn")
		if polish_put(ctx, base, cond, u + o.x * sx, v + o.z * sz, yaw + float(it[3]), rect, ["grass", "mulch", "gravel"]): n += 1
	return n
