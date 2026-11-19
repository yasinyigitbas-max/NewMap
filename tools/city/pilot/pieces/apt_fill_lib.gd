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
static func doors_of(folder: String, kinds := ["apt_door", "shopdoor", "civic_door"]) -> Array:
	var out: Array = []
	for e: Array in K.building_stats(folder).get("doors_front", []):
		if String(e[0]) in kinds:
			var dup := false
			for o: float in out:
				if absf(o - float(e[1])) < 0.6: dup = true
			if not dup: out.append(float(e[1]))
	return out

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
	for k in 3: props.add("prop_meter_electric", "worn", at(b, x0 + k * 0.42, -d * 0.5 - 0.02, 1.05), yaw)
	props.add("prop_meter_gas", "rusty", at(b, x0 + 1.7, -d * 0.5 - 0.02, 0.2), yaw)
	var n_ac := 1 if w < 14.0 else 2
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
		I.add(props, ["prop_porch_light_coach", "prop_porch_light_coach_bronze", "prop_porch_light_barn"][rr.randi() % 3], "worn", at(b, lx - 0.9, d * 0.5 + 0.05, 2.25), yaw, false)
		dec.add(14, Vector2(p.x, p.z) + face_dir(sx, sz, String(b.face)) * 1.0, yaw, 1.6, 1.4, GY, Color(1, 1, 1, 0.45))
		I.add(props, "prop_buzzer_panel", "worn", at(b, lx + 0.8, d * 0.5 + 0.01, 1.15), yaw, false)
	if not String(b.folder).begins_with("civic/"): I.add(props, "prop_mailbox_wall_brass" if rr.randf() < 0.5 else "prop_mailbox_wall_black", "worn", at(b, float(doors[0]) - 1.6, d * 0.5 + 0.05, 1.3), yaw, false)
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
	balconies(b, props)
	if String(b.folder).contains("dingbat"):
		I.add(props, "prop_dingbat_stair", "worn", at(b, -w * 0.5 - 0.6, 0.0), yaw - 90.0, false)
	back_of_house(props, b, not public)
	if patio:
		var px := rr.randf_range(-w * 0.25, w * 0.25)
		I.add(props, "prop_patio_set_4", "worn", atg(b, px, -d * 0.5 - 3.4), yaw + rr.randf_range(-20, 20))
		I.add(props, "prop_bbq_kettle" if rr.randf() < 0.5 else "prop_bbq_gas_cart", "worn", atg(b, px + 2.6, -d * 0.5 - 2.4), yaw + 180.0)
		I.add(props, "prop_hose_reel_wall", "worn", at(b, -w * 0.5 + 0.8, -d * 0.5 - 0.1), yaw + 180.0, false)
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
	if L < 0.6: return
	var n := maxi(1, int(ceil(L / panel - 0.02)))
	var yaw := rad_to_deg(atan2(b.x - a.x, b.y - a.y)) + 90.0
	for i in n:
		var e0 := a.lerp(b, float(i) / n); var e1 := a.lerp(b, float(i + 1) / n)
		var m := (e0 + e1) * 0.5
		var y := minf(gy(e0.x, e0.y), gy(e1.x, e1.y)) - (0.03 if absf(gy(e0.x, e0.y) - gy(e1.x, e1.y)) > 0.01 else 0.0)
		I.add(props, kind, cond, Vector3(m.x, y, m.y), yaw)
	for i in n + 1:
		var e := a.lerp(b, float(i) / n)
		I.add(props, post, cond, Vector3(e.x, gy(e.x, e.y), e.y), yaw)

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
