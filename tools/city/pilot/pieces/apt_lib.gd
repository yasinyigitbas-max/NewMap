extends RefCounted
## Apartment band sample helpers (j_apt, s_apt, a_ne / a_nw / a_se / a_sw, w_apt). The band is the transition between
## the city centre and the houses (CITY_PLAN.md): 2-3 storey walk-ups, courts, Spanish Revival and stucco
## mid-rises, townhouse rows, dingbats raised over carports, a corner store / laundromat / bar on the corners.
## Frame: junction centre; the AVENUE runs along x, the SIDE STREET along z, both the same residential section:
## 1+1 lanes 3.3, parallel parking to the kerb at 5.7, a 1.5 m grass parkway with street trees, 2 m sidewalk,
## property line at 9.2. Each quadrant (u = |x|, v = |z| from the junction) is cut by two alleys (v 54-60 along u,
## u 54-60 along v) into four sub-blocks: A on the corner, B on the avenue, C on the side street, D inside. Parking is
## behind the buildings off the alleys (carports, garages, pads); the street keeps its parallel parking. Flat ground.
const K := preload("res://tools/city/pilot/kit_lib.gd")
const S := preload("res://tools/city/pilot/site.gd")
const W := preload("res://tools/city/pilot/pieces/wear_lib.gd")
const I := preload("res://tools/city/pilot/pieces/ind_lib.gd")
const SL := preload("res://tools/city/pilot/pieces/strip_lib.gd")
const CC := preload("res://tools/city/pilot/pieces/cc_lib.gd")

const LANE := 3.3
const KERB := 5.7
const PKW := 7.2        # parkway 5.7 - 7.2 (grass, street trees), sidewalk 7.2 - 9.2
const PROP := 9.2
const R := 6.0
const J := 20.0
const LEN := 100.0
const AL0 := 54.0       # alleys: 54 - 60 (along u at that v, and along v at that u)
const AL1 := 60.0
const SET := 3.0        # front yards
const FRONT := PROP + SET
const FORE := 2.5       # corner business forecourt

static func q(sx: float, sz: float, u: float, v: float, y := 0.0) -> Vector3:
	return Vector3(sx * u, S.walk_y(0.0) + y, sz * v)

static func rect(sx: float, sz: float, u0: float, v0: float, u1: float, v1: float, mat: String) -> Array:
	return SL.rect(sx, sz, u0, v0, u1, v1, mat)

## world facing direction of a quadrant-local facing: "-v" (toward the avenue), "+v", "-u" (toward the side street), "+u"
static func face_dir(sx: float, sz: float, face: String) -> Vector2:
	match face:
		"-v": return Vector2(0.0, -sz)
		"+v": return Vector2(0.0, sz)
		"-u": return Vector2(-sx, 0.0)
	return Vector2(sx, 0.0)

## Place a kit building centred at (u, v) with its front facing `face`. Returns a record
## {node, w, d, folder, face, u, v} used by dress() and the wires.
static func place(bl: Node3D, sx: float, sz: float, folder: String, u: float, v: float, face: String, label := "", wear := 0.75) -> Dictionary:
	var dir := face_dir(sx, sz, face)
	var yaw := rad_to_deg(atan2(dir.x, dir.y))
	var n := K.building(bl, folder, q(sx, sz, u, v), yaw, label, wear)
	var st := K.building_stats(folder)
	return {"node": n, "w": float(st.footprint_wd[0]), "d": float(st.footprint_wd[1]), "folder": folder, "face": face, "u": u, "v": v}

## A row of buildings whose fronts stand on the line `line` (a v value for faces ±v, a u value for ±u), spread
## evenly between s0 and s1 along the row (equal side yards, at least 1.2 m). Returns the records.
static func row(bl: Node3D, sx: float, sz: float, face: String, line: float, s0: float, s1: float, folders: Array, labels: Array = []) -> Array:
	var widths: Array = []; var total := 0.0
	for f: String in folders:
		var w: float = K.building_stats(f).footprint_wd[0]; widths.append(w); total += w
	var gap := maxf(0.9, (s1 - s0 - total) / float(folders.size() + 1))
	var out: Array = []
	var s := s0 + gap
	var toward := -1.0 if face.begins_with("-") else 1.0      # the front faces toward smaller / larger values
	for k in folders.size():
		var f: String = folders[k]
		var d: float = K.building_stats(f).footprint_wd[1]
		var c_along := s + float(widths[k]) * 0.5
		var c_across := line - toward * d * 0.5
		var lab: String = labels[k] if k < labels.size() else ""
		if face.ends_with("v"): out.append(place(bl, sx, sz, f, c_along, c_across, face, lab))
		else: out.append(place(bl, sx, sz, f, c_across, c_along, face, lab))
		s += float(widths[k]) + gap
	return out

## local point of a building record -> world
static func at(b: Dictionary, lx: float, lz: float, y := 0.0) -> Vector3:
	var p: Vector3 = (b.node as Node3D).transform * Vector3(lx, 0.0, lz)
	return Vector3(p.x, S.walk_y(0.0) + y, p.z)

## Life on and around one apartment building, each thing where it would be:
## front: a concrete walk from every ground door to `walk_to` (the sidewalk or the alley edge), a potted plant beside
##   the door, the coach light over it, the mailbox bank by the first door, low boxwood along the front yard edge
##   (gaps at the walks), a yard tree when the frontage is wide enough;
## walls: window AC units on the side walls (old buildings never got central air), a satellite dish or a TV antenna
##   on the roof edge at the back;
## back (CC.back_of_house, residential): meter bank, gas meter, condensers, the three bin carts; then a patio:
##   grill, table set, chairs, a hose reel, sometimes the golf cart (Coronado) or a propane bottle.
## Balconies (Yasin 17 Nov: the white ones overlapped the apartment rows' own walkway rails and blocked their doors,
## and white read "sore on the eyes" on red brick): never on the apt3 rows - their fronts ARE open-air walkways with
## the rails and doors built in. On the brick walk-ups one stack of black iron balconies (floors 2 and 3) over the
## walk-up's entry bay, where the flats are, centred on the bay so each stands in front of that bay's windows.
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

static func dress(b: Dictionary, paints: Array, props: K.Props, dec: K.Decals, rr: RandomNumberGenerator, sx: float, sz: float, walk_to: float, hedge := true, patio := true) -> void:
	var st := K.building_stats(String(b.folder))
	var w: float = b.w; var d: float = b.d
	var n: Node3D = b.node
	var yaw := rad_to_deg(n.rotation.y)
	var front_v: float = (b.v if String(b.face).ends_with("v") else b.u)
	var toward := -1.0 if String(b.face).begins_with("-") else 1.0
	var line := front_v + toward * d * 0.5                      # front wall (quadrant coordinate)
	var doors: Array = []
	for e: Array in st.get("doors_front", []):
		if String(e[0]) in ["apt_door", "shopdoor", "civic_door"]:
			var dup := false
			for o: float in doors:
				if absf(o - float(e[1])) < 0.6: dup = true
			if not dup: doors.append(float(e[1]))
	if doors.is_empty(): doors.append(0.0)
	# walks: each door's x on the facade -> a strip from the wall to walk_to
	var walk_xs: Array = []
	for lx: float in doors:
		var p := at(b, lx, d * 0.5)
		var along := p.x * sx if String(b.face).ends_with("v") else p.z * sz      # quadrant coordinate along the row
		walk_xs.append(along)
		var a0 := minf(line, walk_to); var a1 := maxf(line, walk_to)
		if String(b.face).ends_with("v"): paints.append(rect(sx, sz, along - 0.7, a0, along + 0.7, a1, "concrete"))
		else: paints.append(rect(sx, sz, a0, along - 0.7, a1, along + 0.7, "concrete"))
		var pot_x := lx + 1.35
		var pot_ok := true
		for e2: Array in st.get("doors_front", []):
			if absf(pot_x - float(e2[1])) < 1.15: pot_ok = false       # never in front of another (or a patio) door
		if pot_ok: I.add(props, "plant_potted_succulent", "normal", at(b, pot_x, d * 0.5 + 0.35), yaw)   # small pot: a 1.4 m leafy pot fills a door step
		I.add(props, ["prop_porch_light_coach", "prop_porch_light_coach_bronze", "prop_porch_light_barn"][rr.randi() % 3], "worn", at(b, lx - 0.9, d * 0.5 + 0.05, 2.25), yaw, false)
		dec.add(14, Vector2(p.x, p.z) + face_dir(sx, sz, String(b.face)) * 1.0, yaw, 1.6, 1.4, S.walk_y, Color(1, 1, 1, 0.45))
		I.add(props, "prop_buzzer_panel", "worn", at(b, lx + 0.8, d * 0.5 + 0.01, 1.15), yaw, false)    # kit batch 2: the intercom by the door
	if not String(b.folder).begins_with("civic/"): I.add(props, "prop_mailbox_wall_brass" if rr.randf() < 0.5 else "prop_mailbox_wall_black", "worn", at(b, float(doors[0]) - 1.6, d * 0.5 + 0.05, 1.3), yaw, false)
	# front yard edge: low boxwood on the yard side of walk_to, broken at every walk
	var along_c: float = b.u if String(b.face).ends_with("v") else b.v
	if hedge:
		var hv := walk_to - toward * 0.45
		var hs := along_c - w * 0.5 + 0.2
		while hs + 2.0 <= along_c + w * 0.5:
			var clear := true
			for wx: float in walk_xs:
				if absf(hs + 1.0 - wx) < 2.0: clear = false
			if clear:
				var hp := q(sx, sz, hs + 1.0, hv) if String(b.face).ends_with("v") else q(sx, sz, hv, hs + 1.0)
				I.add(props, "hedge_boxwood_low_2m", "normal", hp, 0.0 if String(b.face).ends_with("v") else 90.0)
				hs += 2.0
			else:
				hs += 0.5
		if w >= 15.0 and absf(walk_to - line) >= 2.6:
			var tv := (walk_to + line) * 0.5
			var ts := along_c + w * 0.5 - 2.2
			for e3: Array in st.get("doors_front", []):        # slide the tree off any door's line (patio doors too)
				var dpos := at(b, float(e3[1]), d * 0.5)
				var dal := dpos.x * sx if String(b.face).ends_with("v") else dpos.z * sz
				if absf(ts - dal) < 1.6: ts = dal - 1.7 if ts < dal else dal + 1.7
			var tp := q(sx, sz, ts, tv) if String(b.face).ends_with("v") else q(sx, sz, tv, ts)
			I.add(props, ["palm_queen_a", "palm_queen_b", "tree_magnolia_a", "tree_magnolia_b"][rr.randi() % 4], "normal", tp, rr.randf_range(0, 360))
	# side walls: window AC units, roof: dish or antenna (homes only: public buildings have rooftop plant, 17 Nov)
	var h: float = float(st.get("height", 7.0))
	var public := String(b.folder).begins_with("civic/") or String(b.folder).begins_with("public/")
	for side: float in ([] if public else [-1.0, 1.0]):
		if rr.randf() < 0.7:
			I.add(props, "prop_ac_window", "rusty" if rr.randf() < 0.4 else "worn", at(b, side * (w * 0.5 + 0.12), rr.randf_range(-d * 0.3, d * 0.3), 2.4), yaw + side * 90.0, false)
		if h > 7.5 and rr.randf() < 0.6:
			I.add(props, "prop_ac_window", "worn", at(b, side * (w * 0.5 + 0.12), rr.randf_range(-d * 0.3, d * 0.3), 5.4), yaw + side * 90.0, false)
	if not public: I.add(props, "prop_satellite_dish" if rr.randf() < 0.6 else "prop_tv_antenna", "worn", at(b, rr.randf_range(-w * 0.35, w * 0.35), -d * 0.5 + 0.8, h - 0.05), yaw + 180.0, false)
	# kit batch 2 (17 Nov): balconies with their clutter on the walk-ups' upper floors (one bay in two), a clothesline
	# in one back yard of three, the outdoor stair up the side of a dingbat
	var fol := String(b.folder)
	balconies(b, props)
	if patio and rr.randf() < 0.34:
		I.add(props, "prop_clothesline", "worn", at(b, 0.0, -d * 0.5 - 6.4), yaw)    # mid-yard: the shade tree stands in a back corner
	if fol.contains("dingbat"):
		I.add(props, "prop_dingbat_stair", "worn", at(b, -w * 0.5 - 0.6, 0.0), yaw - 90.0, false)
	# back of house + patio
	CC.back_of_house(props, n, String(b.folder), true)
	if patio:
		var px := rr.randf_range(-w * 0.25, w * 0.25)
		I.add(props, "prop_patio_set_4", "worn", at(b, px, -d * 0.5 - 3.4), yaw + rr.randf_range(-20, 20))
		I.add(props, "prop_bbq_kettle" if rr.randf() < 0.5 else "prop_bbq_gas_cart", "worn", at(b, px + 2.6, -d * 0.5 - 2.4), yaw + 180.0)
		I.add(props, "prop_hose_reel_wall", "worn", at(b, -w * 0.5 + 0.8, -d * 0.5 - 0.1, 0.0), yaw + 180.0, false)
		if rr.randf() < 0.5: I.add(props, "prop_adirondack_wood" if rr.randf() < 0.5 else "prop_adirondack_white", "worn", at(b, px - 2.4, -d * 0.5 - 3.0), yaw + 160.0)
		if rr.randf() < 0.35: I.add(props, "prop_propane_cylinder_100lb", "rusty", at(b, w * 0.5 - 0.6, -d * 0.5 - 0.5), 0.0)
	# back yard: one shade tree in a back corner (people sit under it), a path worn into the grass from the back
	# door toward the parking (nobody walks round by the paved way)
	if patio:
		var tx := (w * 0.5 - 2.0) * (1.0 if rr.randf() < 0.5 else -1.0)
		I.add(props, ["tree_ficus_a", "tree_coral_a", "tree_magnolia_b", "tree_jacaranda_b", "tree_ficus_b"][rr.randi() % 5], "normal", at(b, tx, -d * 0.5 - 5.5), rr.randf_range(0, 360))
		var bd := at(b, -tx * 0.4, -d * 0.5 - 1.5)
		var bp2 := at(b, -tx * 0.4, -d * 0.5 - 12.0)
		var mid := (Vector2(bd.x, bd.z) + Vector2(bp2.x, bp2.z)) * 0.5
		dec.add(14, mid, yaw, 1.1, 10.0, S.walk_y, Color(1, 1, 1, 0.55))
		var under := at(b, 0.0, -d * 0.5 - 3.4)   # the patio wears the grass bare
		dec.add(14, Vector2(under.x, under.z), yaw, 3.6, 3.0, S.walk_y, Color(1, 1, 1, 0.5))
	# wear: grime at the foot of the front, dirt where the bins stand
	I.wall_grime(dec, Vector2(at(b, -w * 0.5, d * 0.5 + 0.4).x, at(b, -w * 0.5, d * 0.5 + 0.4).z), Vector2(at(b, w * 0.5, d * 0.5 + 0.4).x, at(b, w * 0.5, d * 0.5 + 0.4).z), rr)
	var bp := at(b, w * 0.5 - 2.3, -d * 0.5 - 0.75)
	dec.add(14, Vector2(bp.x, bp.z), yaw, 3.0, 1.6, S.walk_y, Color(1, 1, 1, 0.6))

## parking pad off an alley: asphalt, a row of nose-in stalls (cars come in from the alley), oil under them, a wheel
## stop's worth of grime, recorded for the parked-car layer. Along u (rows facing an alley that runs along u) when
## along_u, else along v. edge = the alley edge (v or u), dir = which way the stalls run from it (-1 or +1).
static func pad(paints: Array, stalls: Array, dec: K.Decals, rr: RandomNumberGenerator, sx: float, sz: float, along_u: bool, s0: float, s1: float, edge: float, dir: float) -> void:
	var n := int(floor((s1 - s0) / SL.STALL_W))
	if n < 1: return
	var depth := SL.STALL_D + 0.8
	# (painted_rect: the FIRST matching paint wins, so the stall lines go in before the pad's asphalt)
	if along_u:
		SL.stalls_u(paints, stalls, sx, sz, s0, n, edge + dir * 0.8, dir)
		paints.append(rect(sx, sz, s0, minf(edge, edge + dir * depth), s1, maxf(edge, edge + dir * depth), "asphalt"))
	else:
		SL.stalls_v(paints, stalls, sx, sz, s0, n, edge + dir * 0.8, dir)
		paints.append(rect(sx, sz, minf(edge, edge + dir * depth), s0, maxf(edge, edge + dir * depth), s1, "asphalt"))
	SL.stall_wear(dec, rr, stalls.slice(stalls.size() - n), 0.7)

## an alley: asphalt with a concrete centre gutter (v-gutter), cracks and patches, oil, grime along both edges, a
## trench patch; poles every ~28 m on one edge (their positions go into `poles` for the wires); dumpsters and tagged
## CMU walls where the buildings' service sides meet it. along_u: the alley runs along u at v (c0..c1) else along v.
static func alley(paints: Array, props: K.Props, dec: K.Decals, rr: RandomNumberGenerator, sx: float, sz: float, along_u: bool, s0: float, s1: float, poles: Array, pole_side := 0.4) -> void:
	var c := (AL0 + AL1) * 0.5
	if along_u:   # gutter first: the first matching paint wins
		paints.append(rect(sx, sz, s0, c - 0.4, s1, c + 0.4, "concrete"))
		paints.append(rect(sx, sz, s0, AL0, s1, AL1, "asphalt"))
	else:
		paints.append(rect(sx, sz, c - 0.4, s0, c + 0.4, s1, "concrete"))
		paints.append(rect(sx, sz, AL0, s0, AL1, s1, "asphalt"))
	var s := s0 + 6.0
	while s < s1 - 3.0:
		var pp := q(sx, sz, s, AL0 + pole_side) if along_u else q(sx, sz, AL0 + pole_side, s)
		var pyaw := 90.0 if along_u else 0.0      # cross-arm (model X) across the line
		I.add(props, "prop_utility_pole_transformer" if poles.size() % 3 == 1 else "prop_utility_pole", "worn", pp, pyaw)
		poles.append([pp, pyaw, "u" if along_u else "v"])
		s += 28.0
	# wear
	var a := Vector2(sx * s0, sz * AL0) if along_u else Vector2(sx * AL0, sz * s0)
	var b := Vector2(sx * s1, sz * AL1) if along_u else Vector2(sx * AL1, sz * s1)
	W.cracks(dec, rr, minf(a.x, b.x), minf(a.y, b.y), maxf(a.x, b.x), maxf(a.y, b.y), int(absf(s1 - s0) / 4.0), S.walk_y, 0.4)
	var k := s0 + 2.0
	while k < s1 - 3.0:
		var o := Vector2(sx * k, sz * (c + rr.randf_range(-1.6, 1.6))) if along_u else Vector2(sx * (c + rr.randf_range(-1.6, 1.6)), sz * k)
		W.oil(dec, rr, o, 0.0 if not along_u else 90.0, S.walk_y, rr.randf_range(0.5, 0.85))
		for e: float in [AL0 + 0.3, AL1 - 0.3]:
			var gp := Vector2(sx * (k + 1.5), sz * e) if along_u else Vector2(sx * e, sz * (k + 1.5))
			dec.add(14, gp, 90.0 if along_u else 0.0, 0.7, 3.0, S.walk_y, Color(1, 1, 1, rr.randf_range(0.4, 0.65)))
		k += rr.randf_range(5.0, 9.0)
	for t in 2:
		var tp := rr.randf_range(s0 + 5.0, s1 - 5.0)
		var pv := Vector2(sx * tp, sz * c) if along_u else Vector2(sx * c, sz * tp)
		dec.add(2 + t, pv, 90.0 if along_u else 0.0, 2.4, 6.0, S.walk_y, Color(1, 1, 1, 0.9))

## a run of wood privacy fence (rear yard dividers), 2 m panels, a post at every joint
static func privacy(props: K.Props, a: Vector2, b: Vector2, kind := "fence_wood_privacy", post := "fence_post_privacy") -> void:
	var L := a.distance_to(b)
	if L < 0.6: return
	var n := maxi(1, int(ceil(L / 2.0 - 0.02)))
	var yaw := rad_to_deg(atan2(b.x - a.x, b.y - a.y)) + 90.0
	for i in n:
		var m := a.lerp(b, (i + 0.5) / n)
		I.add(props, kind, "worn", Vector3(m.x, S.walk_y(0.0), m.y), yaw)
	for i in n + 1:
		var e := a.lerp(b, float(i) / n)
		I.add(props, post, "worn", Vector3(e.x, S.walk_y(0.0), e.y), yaw)

static func finish(root: Node3D, g: K.Ground, props: K.Props, dec: K.Decals, name: String, stalls: Array, poles: Array) -> void:
	root.set_meta("poles", poles)
	SL.finish(root, g, props, dec, name, stalls)

## ---------------------------------------------------------------- the standard quadrant (sub-blocks A, B, C + alleys)
## spec: corner (folder), corner_label, corner_life ("market" | "laundry" | "bar" | "cafe"), a_av, a_side, b_av, b_ding,
## c_side (lists of folders; b_ding = "" for none). Returns a context for the piece script (it adds sub-block D, then
## calls finish). Everything here is what every apartment quadrant has; D is each quadrant's own.
static func block(name: String, sx: float, sz: float, spec: Dictionary) -> Dictionary:
	S.hill_on = false
	var root := Node3D.new(); root.name = name
	var bl := Node3D.new(); bl.name = "Buildings"; root.add_child(bl)
	var ctx := {"root": root, "bl": bl, "g": K.Ground.new(), "props": K.Props.new(), "dec": K.Decals.new(), "rr": W.rng_for(name),
		"paints": [], "stalls": [], "poles": [], "blds": [], "sx": sx, "sz": sz}
	var props: K.Props = ctx.props; var dec: K.Decals = ctx.dec; var rr: RandomNumberGenerator = ctx.rr
	var paints: Array = ctx.paints; var stalls: Array = ctx.stalls; var poles: Array = ctx.poles; var blds: Array = ctx.blds
	# alleys
	alley(paints, props, dec, rr, sx, sz, true, PROP, LEN, poles)
	alley(paints, props, dec, rr, sx, sz, false, PROP, AL0, poles, 0.4)
	alley(paints, props, dec, rr, sx, sz, false, AL1, LEN, poles, 0.4)
	# ---- A: the corner business on the property lines, then the rows
	var cf: String = spec.corner
	var cst := K.building_stats(cf)
	var cw: float = cst.footprint_wd[0]; var cd: float = cst.footprint_wd[1]
	# the corner business stands 2.5 m back behind its own paved forecourt: its tables, bench and racks go there and
	# the public sidewalk stays clear (17 Nov, Yasin: bike racks across the walk)
	var corner := place(bl, sx, sz, cf, PROP + cw * 0.5, PROP + FORE + cd * 0.5, "-v", String(spec.get("corner_label", "")))
	paints.append(rect(sx, sz, PROP, PROP, PROP + cw, PROP + FORE, "concrete"))
	CC.back_of_house(props, corner.node, cf, false)
	_corner_life(corner, String(spec.get("corner_life", "market")), paints, props, dec, rr, sx, sz)
	var a_rows := row(bl, sx, sz, "-v", FRONT, PROP + cw, AL0, spec.a_av)
	var a_side := row(bl, sx, sz, "-u", FRONT, PROP + FORE + cd + 0.8, AL0, spec.a_side)
	var b_rows := row(bl, sx, sz, "-v", FRONT, AL1, LEN, spec.b_av)
	var c_rows := row(bl, sx, sz, "-u", FRONT, AL1, LEN, spec.c_side)
	for b: Dictionary in a_rows + a_side + b_rows + c_rows:
		dress(b, paints, props, dec, rr, sx, sz, PROP)
		blds.append(b)
	blds.append(corner)
	# ---- rear parking off the alleys; rear yard fences between yards and pads (gates at the middle)
	var side_back := FRONT + 12.0
	for b2: Dictionary in a_side: side_back = maxf(side_back, FRONT + float(b2.d))
	pad(paints, stalls, dec, rr, sx, sz, true, side_back + 2.0, AL0 - 0.5, AL0, -1.0)
	var ding: String = spec.get("b_ding", "")
	var b_pad_end := LEN - 0.5
	if ding != "":
		var dst := K.building_stats(ding)
		var dw: float = dst.footprint_wd[0]; var dd: float = dst.footprint_wd[1]
		var du := LEN - 1.5 - dw * 0.5
		var db := place(bl, sx, sz, ding, du, AL0 - 0.4 - dd * 0.5, "+v", "alley_dingbat")
		blds.append(db)
		CC.back_of_house(props, db.node, ding, true)
		I.add(props, "prop_dingbat_stair", "worn", at(db, -dw * 0.5 - 0.6, 0.0), rad_to_deg((db.node as Node3D).rotation.y) - 90.0, false)   # kit batch 2
		SL.stalls_u(paints, stalls, sx, sz, du - dw * 0.5 + 0.6, 4, AL0 - 0.4, -1.0)    # under the dingbat
		I.add(props, "prop_trash_cart_black", "worn", q(sx, sz, du - dw * 0.5 - 0.7, AL0 - 1.0), 0.0)
		I.add(props, "prop_trash_cart_blue", "worn", q(sx, sz, du - dw * 0.5 - 1.5, AL0 - 1.0), 0.0)
		b_pad_end = du - dw * 0.5 - 2.5
	pad(paints, stalls, dec, rr, sx, sz, true, AL1 + 0.5, b_pad_end, AL0, -1.0)
	pad(paints, stalls, dec, rr, sx, sz, false, AL1 + 0.5, LEN - 0.5, AL0, -1.0)
	var fv := AL0 - SL.STALL_D - 0.9
	# ---- rear rows (courtyard plan, 17 Nov: the backs were empty lawns): walk-ups with their backs to the yard fence,
	# facing the street rows across a shared court where the patios and shade trees are
	var rback := fv - 1.6
	var rears: Array = []
	rears.append_array(row(bl, sx, sz, "-v", rback - 12.0, side_back + 5.5, AL0 - 0.5, spec.get("a_rear", [])))   # after the side row's patios
	rears.append_array(row(bl, sx, sz, "-v", rback - 12.0, AL1 + 0.5, b_pad_end, spec.get("b_rear", [])))
	rears.append_array(row(bl, sx, sz, "-u", rback - 12.0, AL1 + 0.5, LEN - 0.5, spec.get("c_rear", [])))
	for rb: Dictionary in rears:
		var toward := -1.0
		var fl: float = (float(rb.v) if String(rb.face).ends_with("v") else float(rb.u)) + toward * float(rb.d) * 0.5
		dress(rb, paints, props, dec, rr, sx, sz, fl - 2.5, false, false)
		blds.append(rb)
	for seg: Array in [[side_back + 2.0, AL0 - 0.5], [AL1 + 0.5, b_pad_end]]:
		var m := (float(seg[0]) + float(seg[1])) * 0.5
		privacy(props, Vector2(sx * float(seg[0]), sz * fv), Vector2(sx * (m - 1.2), sz * fv))
		privacy(props, Vector2(sx * (m + 1.2), sz * fv), Vector2(sx * float(seg[1]), sz * fv))
	privacy(props, Vector2(sx * fv, sz * (AL1 + 0.5)), Vector2(sx * fv, sz * 78.8))
	privacy(props, Vector2(sx * fv, sz * 81.2), Vector2(sx * fv, sz * (LEN - 0.5)))
	return ctx

## the corner business's own life, on its sidewalk and at its back door
static func _corner_life(b: Dictionary, kind: String, paints: Array, props: K.Props, dec: K.Decals, rr: RandomNumberGenerator, sx: float, sz: float) -> void:
	var w: float = b.w; var d: float = b.d
	var yaw := rad_to_deg((b.node as Node3D).rotation.y)
	var cdoors: Array = []
	for e: Array in K.building_stats(String(b.folder)).get("doors_front", []): cdoors.append(float(e[1]))
	# a sidewalk prop never stands in front of a door: slide it along the facade until it is clear (1.4 m)
	var front := func(lx: float, out: float) -> Vector3:
		var x := lx
		for it in 8:
			var hit := false
			for dx: float in cdoors:
				if absf(x - dx) < 1.9: hit = true; x = dx + (1.95 if lx >= dx else -1.95)
			if not hit: break
		return at(b, x, d * 0.5 + out)
	match kind:
		"market":   # papers, the ice-chest corner (missing prop: propane cage stands in), a bin, a pay phone's spot
			I.add(props, "prop_newspaper_box_red", "worn", front.call(-w * 0.5 + 0.8, 0.6), yaw)
			I.add(props, "prop_newspaper_box_blue", "worn", front.call(-w * 0.5 + 1.6, 0.6), yaw)
			I.add(props, "prop_trash_receptacle", "dirty", front.call(w * 0.5 - 0.8, 0.6), yaw)
			var cage: Vector3 = front.call(w * 0.5 - 2.0, 0.4)
			var along := (b.node as Node3D).transform.basis.x.normalized()
			for k in 4: I.add(props, "prop_propane_cylinder_100lb", "rusty", cage - along * (k * 0.45), yaw)
		"laundry":   # people wait outside: a bench, a bin, a bike rack
			I.add(props, "prop_park_bench", "worn", front.call(-2.0, 0.6), yaw)
			I.add(props, "prop_trash_receptacle", "dirty", front.call(1.0, 0.5), yaw)
			I.add(props, "prop_bike_rack", "rusty", front.call(w * 0.5 - 1.6, 1.9), yaw)      # parallel to the front
		"bar":   # smokers' corner: a bin, a planter used as an ashtray, a bike rack
			I.add(props, "prop_trash_receptacle", "dirty", front.call(w * 0.5 - 0.7, 1.0), yaw)
			I.add(props, "plant_potted_succulent", "normal", front.call(-w * 0.5 + 0.6, 0.45), yaw)
			I.add(props, "prop_bike_rack", "rusty", front.call(-w * 0.5 + 1.8, 1.9), yaw)
		"cafe":   # two tables out front, pots, a bike rack
			I.add(props, "prop_patio_set_4", "worn", front.call(-w * 0.5 + 1.7, 1.25), yaw)
			I.add(props, "prop_patio_set_4", "worn", front.call(w * 0.5 - 1.7, 1.25), yaw)
			I.add(props, "prop_bike_rack", "worn", front.call(0.0, 2.1), yaw)
	var back := at(b, 0.0, -d * 0.5 - 2.2)
	I.add(props, "prop_dumpster_3yd_green", "rusty", back, yaw)
	dec.add(14, Vector2(back.x, back.z), yaw, 3.0, 2.0, S.walk_y, Color(1, 1, 1, 0.7))
	var f0 := at(b, 0.0, d * 0.5 + 1.0)
	dec.add(14, Vector2(f0.x, f0.z), yaw, 4.0, 1.6, S.walk_y, Color(1, 1, 1, 0.55))

static func done(ctx: Dictionary, name: String) -> void:
	fill_open(ctx)
	# kit batch 2 (17 Nov): wheel stops on the open pads only (under a dingbat the cars nose up to the stair wall)
	var pads: Array = []
	for st: Array in ctx.stalls:
		var under := false
		for b: Dictionary in ctx.blds:
			var lp: Vector3 = (b.node as Node3D).transform.affine_inverse() * Vector3(float(st[0]), 0.0, float(st[1]))
			if absf(lp.x) < float(b.w) * 0.5 + 0.5 and absf(lp.z) < float(b.d) * 0.5 + 3.5: under = true
		if not under: pads.append(st)
	SL.wheel_stops(ctx.props, ctx.rr, pads)
	# no tree hugging a fence: drop a tree whose trunk stands within 0.9 m of a fence panel line
	var fence_pts: Array = []
	for k: String in (ctx.props as K.Props).items:
		if not k.begins_with("fence_"): continue
		for t: Transform3D in ctx.props.items[k]:
			for f: float in [-1.0, -0.5, 0.0, 0.5, 1.0]:
				var fp := t.origin + t.basis.x.normalized() * f
				fence_pts.append(Vector2(fp.x, fp.z))
	for k2: String in (ctx.props as K.Props).items.keys():
		if not (k2.begins_with("tree_") or k2.begins_with("palm_")): continue
		var keep: Array = []
		for t2: Transform3D in ctx.props.items[k2]:
			var ok := true
			for fp2: Vector2 in fence_pts:
				if fp2.distance_to(Vector2(t2.origin.x, t2.origin.z)) < 0.9: ok = false; break
			if ok: keep.append(t2)
		ctx.props.items[k2] = keep
	var g: K.Ground = ctx.g
	var sx: float = ctx.sx; var sz: float = ctx.sz
	var a := Vector2(sx * PROP, sz * PROP); var b := Vector2(sx * LEN, sz * LEN)
	K.painted_rect(g, minf(a.x, b.x), minf(a.y, b.y), maxf(a.x, b.x), maxf(a.y, b.y), ctx.paints, S.walk_y, "grass")
	var arr: Array = ctx.get("arrows", [])
	for a4: Dictionary in arr: K.fill_arrow(g, a4, S.walk_y)
	finish(ctx.root, g, ctx.props, ctx.dec, name, ctx.stalls, ctx.poles)

## ---------------------------------------------------------------- shared yards (17 Nov, Yasin: swings and slides in
## the open green, "have them all logically placed"). Each thing goes where it would be used:
##  kids' corner - in the shared COURT between a sub-block's street row and its rear row (windows on both sides look
##    onto it, away from the alleys and the street), one per court, at the court's most open point; the bench faces the
##    swing (a parent watches), the bin stands by the bench.
##  sitting spot - just behind a building (tenants step out of the back door), picnic table, grill, two chairs, under
##    a shade tree; one per sub-block.
##  garden patch - along a building's side wall (people plant along their house), a bark bed with succulents,
##    bird-of-paradise and bougainvillea, a hose cart; one per sub-block.
## Nothing within 5 m of an alley, a parking pad or the street side, nothing on a walk, 3 m clear of every prop.
static func fill_open(ctx: Dictionary) -> void:
	var sx: float = ctx.sx; var sz: float = ctx.sz
	var props: K.Props = ctx.props; var rr: RandomNumberGenerator = ctx.rr; var dec: K.Decals = ctx.dec
	var paints: Array = ctx.paints
	var taken: Array = []
	for k: String in props.items:
		for t: Transform3D in props.items[k]:
			taken.append([Vector2(t.origin.x, t.origin.z), 1.2])
			if k.begins_with("fence_") or k.begins_with("prop_clothesline") or k.begins_with("prop_dingbat_stair"):    # lines, not points: the whole length is taken
				var half := 2.6 if k.begins_with("prop_clothesline") else 1.0     # the clothesline is 5.2 m post to post
				for f: float in [-1.0, -0.5, 0.0, 0.5, 1.0]:
					var fp := t.origin + t.basis.x.normalized() * f * half
					taken.append([Vector2(fp.x, fp.z), 1.0 if half > 1.5 else 0.6])
	var boxes: Array = []     # [inverse transform, half w, half d, record]
	for b: Dictionary in ctx.blds:
		boxes.append([(b.node as Node3D).transform.affine_inverse(), float(b.w) * 0.5, float(b.d) * 0.5, b])
		for e: Array in K.building_stats(String(b.folder)).get("doors_front", []):     # door steps stay free
			var dp: Vector3 = (b.node as Node3D).transform * Vector3(float(e[1]), 0.0, float(b.d) * 0.5 + 1.0)
			taken.append([Vector2(dp.x, dp.z), 1.4])
	# distance from p to a building footprint (0 inside), and which side of it (local) p is on
	var bdist := func(bx: Array, p: Vector2) -> Vector3:
		var lp: Vector3 = (bx[0] as Transform3D) * Vector3(p.x, 0.0, p.y)
		var dx := maxf(absf(lp.x) - float(bx[1]), 0.0); var dz := maxf(absf(lp.z) - float(bx[2]), 0.0)
		return Vector3(Vector2(dx, dz).length(), lp.x, lp.z)
	var clear := func(p: Vector2, r: float) -> bool:
		var u := p.x * sx; var v := p.y * sz
		if u < PROP + 5.0 or v < PROP + 5.0 or u > LEN - 3.0 or v > LEN - 3.0: return false
		if (u > AL0 - SL.STALL_D - 5.0 and u < AL1 + 5.0) or (v > AL0 - SL.STALL_D - 5.0 and v < AL1 + 5.0): return false   # alleys + pads
		for bx: Array in boxes:
			if (bdist.call(bx, p) as Vector3).x < r * 0.6 + 1.0: return false
		for pr: Array in paints:
			if String(pr[4]) == "grass": continue
			if p.x > float(pr[0]) - r * 0.6 and p.x < float(pr[2]) + r * 0.6 and p.y > float(pr[1]) - r * 0.6 and p.y < float(pr[3]) + r * 0.6: return false
		for tk: Array in taken:
			if (tk[0] as Vector2).distance_to(p) < r + float(tk[1]): return false
		return true
	# sub-blocks A (corner), B (avenue), C (side street); D is each piece's own
	var subs := {"A": [PROP, PROP, AL0, AL0], "B": [AL1, PROP, LEN, AL0], "C": [PROP, AL1, AL0, LEN]}
	var placed := 0
	for key: String in subs:
		var r0: Array = subs[key]
		# candidates on a 1.5 m grid, with their context
		var best_play := Vector2.INF; var bp_score := -1.0
		var best_sit := Vector2.INF; var bs_score := 1e9; var sit_yaw := 0.0
		var best_gard := Vector2.INF; var bg_score := 1e9; var gard_yaw := 0.0
		var u := float(r0[0]) + 2.0
		while u < float(r0[2]) - 2.0:
			var v := float(r0[1]) + 2.0
			while v < float(r0[3]) - 2.0:
				var p := Vector2(sx * u, sz * v)
				# nearest building, and the two nearest on opposite sides (a court lies between them)
				var near := 1e9; var near_bx: Array = []
				var sides := {}
				for bx: Array in boxes:
					var d3: Vector3 = bdist.call(bx, p)
					if d3.x < near: near = d3.x; near_bx = bx
					if d3.x < 14.0:
						var b: Dictionary = bx[3]
						var c := Vector2(float(b.u), float(b.v))
						var dirv := Vector2(u, v) - c
						var keyd := ("v" if absf(dirv.y) > absf(dirv.x) else "u") + ("+" if (dirv.y if absf(dirv.y) > absf(dirv.x) else dirv.x) > 0.0 else "-")
						sides[keyd] = true
				var court := (sides.has("v+") and sides.has("v-")) or (sides.has("u+") and sides.has("u-"))
				if court and clear.call(p, 3.4):
					var open := minf(near, 10.0)
					if open > bp_score: bp_score = open; best_play = p
				if not near_bx.is_empty():
					var d3b: Vector3 = bdist.call(near_bx, p)
					var hb := float(near_bx[1]); var hd := float(near_bx[2])
					var b2: Dictionary = near_bx[3]
					var yb := rad_to_deg((b2.node as Node3D).rotation.y)
					# behind the building (local z < -half depth), 3-6 m off its back wall
					if d3b.z < -hd and absf(d3b.y) < hb and d3b.x > 3.0 and d3b.x < 6.0 and clear.call(p, 2.8):
						if absf(d3b.y) < bs_score: bs_score = absf(d3b.y); best_sit = p; sit_yaw = yb
					# beside it (local |x| > half width), 1.5-3 m off the side wall, mid-depth
					if absf(d3b.y) > hb and absf(d3b.z) < hd * 0.6 and d3b.x > 1.8 and d3b.x < 3.2 and clear.call(p, 3.0):
						if absf(d3b.z) < bg_score: bg_score = absf(d3b.z); best_gard = p; gard_yaw = yb + 90.0
				v += 1.5
			u += 1.5
		# every item of a cluster is checked on its own before it goes in (a cluster may come out smaller)
		var put := func(base: String, pos: Vector3, yaw: float, r: float) -> bool:
			var p2 := Vector2(pos.x, pos.z)
			if not clear.call(p2, r): return false
			I.add(props, base, "worn" if not base.begins_with("tree_") and not base.begins_with("plant_") else "normal", pos, yaw)
			taken.append([p2, r])
			return true
		var variant := rr.randi() % 3
		if best_play != Vector2.INF:
			var c0 := Vector3(best_play.x, S.walk_y(0.0), best_play.y)
			var items: Array = [[["prop_swing_set", 0.0, 0.0], ["prop_slide", 3.2, 0.0]], [["prop_play_structure", 0.0, 0.0]], [["prop_swing_set", 0.0, 0.0], ["prop_slide", -3.2, 0.0]]][variant]
			var any := false
			for it: Array in items:
				var em: Dictionary = K.manifest(String(it[0]))       # clearance from the item's real footprint (play structure ~5 m)
				var rad := maxf(1.6, Vector2(float(em.get("footprint_w", 2.0)), float(em.get("footprint_d", 2.0))).length() * 0.5)   # any yaw
				if put.call(String(it[0]), c0 + Vector3(float(it[1]), 0, float(it[2])), rr.randf_range(0, 180), rad): any = true
			if any:
				dec.add(14, best_play, 0.0, 4.0, 3.2, S.walk_y, Color(1, 1, 1, 0.55))     # bare grass under the play
				for side: float in [1.0, -1.0]:      # the parent's bench on whichever side is free, facing the play
					var bpos := c0 + Vector3(0, 0, side * 3.6 * sz)
					if put.call("prop_park_bench", bpos, rad_to_deg(atan2(c0.x - bpos.x, c0.z - bpos.z)), 1.1):
						put.call("prop_trash_receptacle", bpos + Vector3(1.7, 0, 0), 0.0, 0.5)
						break
				placed += 1
		if best_sit != Vector2.INF:
			var c3 := Vector3(best_sit.x, S.walk_y(0.0), best_sit.y)
			var bb := Basis(Vector3.UP, deg_to_rad(sit_yaw))
			var sets: Array = [
				[["prop_picnic_table", 0.0, 0.0, 0.0, 1.3], ["prop_bbq_kettle", 2.3, 0.8, 0.0, 0.5], ["prop_adirondack_wood", -2.3, 0.6, 200.0, 0.6]],
				[["prop_patio_set_4", 0.0, 0.0, 0.0, 1.2], ["prop_garden_arbor", 0.0, -2.2, 0.0, 1.0], ["prop_bbq_gas_cart", 2.4, 0.6, 180.0, 0.6], ["prop_propane_cylinder_100lb", 3.2, 1.4, 0.0, 0.3]],
				[["prop_adirondack_white", -1.2, 0.8, 150.0, 0.6], ["prop_adirondack_wood", 1.2, 0.8, 210.0, 0.6], ["prop_adirondack_white", -1.2, -0.8, 30.0, 0.6], ["prop_adirondack_wood", 1.2, -0.8, -30.0, 0.6], ["prop_bbq_kettle", 2.6, 0.0, 0.0, 0.5]]][variant]
			var got := 0
			for it2: Array in sets:
				var es: Dictionary = K.manifest(String(it2[0]))
				var rs := maxf(float(it2[4]), Vector2(float(es.get("footprint_w", 1.0)), float(es.get("footprint_d", 1.0))).length() * 0.45)
				if put.call(String(it2[0]), c3 + bb * Vector3(float(it2[1]), 0, float(it2[2])), sit_yaw + float(it2[3]), rs): got += 1
			if got > 0:
				put.call(["tree_coral_b", "tree_ficus_b", "tree_jacaranda_a"][placed % 3], c3 + bb * Vector3(0.9, 0, -3.0), rr.randf_range(0, 360), 0.8)
				dec.add(14, best_sit, sit_yaw, 3.4, 3.0, S.walk_y, Color(1, 1, 1, 0.45))
				placed += 1
		if best_gard != Vector2.INF and clear.call(best_gard, 3.0):
			var g3 := Vector3(best_gard.x, S.walk_y(0.0), best_gard.y)
			var gb := Basis(Vector3.UP, deg_to_rad(gard_yaw))
			var e0 := g3 + gb * Vector3(-2.7, 0, -0.9); var e1 := g3 + gb * Vector3(2.7, 0, 0.9)
			paints.insert(0, [minf(e0.x, e1.x), minf(e0.z, e1.z), maxf(e0.x, e1.x), maxf(e0.z, e1.z), "mulch"])
			var plants: Array = [["plant_agave_americana_small", "plant_bird_of_paradise", "plant_bougainvillea_mound"], ["plant_bird_of_paradise", "plant_agave_americana", "plant_bird_of_paradise"], ["plant_bougainvillea_mound", "plant_agave_americana_small", "plant_bougainvillea_mound"]][variant]
			for k2 in 3: put.call(String(plants[k2]), g3 + gb * Vector3(-1.75 + k2 * 1.75, 0, 0), k2 * 60.0, 0.75)
			put.call("prop_hose_reel_cart", g3 + gb * Vector3(3.3, 0, 1.4), gard_yaw, 0.5)
			placed += 1
		# a lawn sprinkler somewhere open
		var sp := Vector2(sx * ((float(r0[0]) + float(r0[2])) * 0.5 + rr.randf_range(-6, 6)), sz * ((float(r0[1]) + float(r0[3])) * 0.5 + rr.randf_range(-6, 6)))
		put.call("prop_sprinkler_popup", Vector3(sp.x, S.walk_y(0.0), sp.y), 0.0, 0.4)
	print("shared yard clusters: %d" % placed)
