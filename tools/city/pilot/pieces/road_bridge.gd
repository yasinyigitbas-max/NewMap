extends RefCounted
## Hand-made hero road pieces of the bridge landing (option A, Yasin 17 Nov: "Bridge: A, but make sure that the
## resulting roads arent jagged ... curve smoothly"). HERO_DESIGN.md, zoning/hero_geom.json.
##
## THE GATEWAY CROSSES (this file, build_cross): the ring T's at 4th St (660, -1200) and 3rd St (660, -1400) become
## 4-way signals: the town street keeps the west mouth exactly as the ring T built it (same _tgeom corners, crosswalks,
## stop bars), the east mouth takes the bridge approach (4th St: divided 2 + 2, the island's front door) or the one-way
## off-ramp (3rd St: two lanes in, nothing out). Everything is cut from the ring library's ONE fitted path (road_rg.gd):
## same kerb return fillets, paint cut into the asphalt, s cuts shared, so the crosses meet the locked boulevard pieces
## edge for edge. The east legs use sections RG.SEC "approach" / "ramp" whose mouths fit INSIDE the town street's tile
## (kerb <= 10.3, R 8), so the tile extents (em / ep) and every neighbouring piece stay as they are.
##
## Traffic engineering (the planner's reasons):
##  - Ring: a left-turn pocket for BOTH directions now (the centre lane serves +s before the junction and -s after it),
##    solid lane lines on the approaches, crosswalks across the ring on both sides of the junction.
##  - Approach inbound (from the bridge): inner lane left (south along Glorietta) + through (4th St), outer lane through
##    + right (north); outbound: two lanes up to the bridge. A planted median with a round nose behind the crosswalk.
##  - Off-ramp (3rd St): the ramp's single lane widens to two at the stop bar: left lane left / through (3rd St west),
##    right lane right (north on Glorietta). No outbound side: drivers cannot enter the ramp the wrong way (the mouth's
##    exit half is kerbed off by the narrower ramp mouth).
##  - Signals: a mast arm over each of the four approaches, at its far-right corner (the arm reaches over the lanes):
##    one pole on every corner; street-name signs on the poles; ramps and crosswalks on every leg.
## Wear: queue oil and braking marks at all four stop bars, turning arcs through the box, a duct trench, corner grime.
const K := preload("res://tools/city/pilot/kit_lib.gd")
const S := preload("res://tools/city/pilot/site.gd")
const W := preload("res://tools/city/pilot/pieces/wear_lib.gd")
const RG := preload("res://tools/city/pilot/pieces/road_rg.gd")
const NW := preload("res://tools/city/pilot/pieces/road_rg_NW.gd")

## the east legs: node key -> section; direction from the hero geometry (the leg's last straight, pointing away)
const EAST := {"660.0,-1200.0": "approach", "660.0,-1400.0": "ramp"}

static func east_dir(key: String) -> Vector2:
	var R := RG.ring()
	var nd: Dictionary = R["nodes"][key]
	var d: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(RG.SITES))
	for n: Dictionary in d["nodes"]:
		if RG.nkey(float(n["u"]), float(n["v"])) != key: continue
		for lg: Dictionary in n["legs"]:
			if String(lg["section"]) == "bridge": return Vector2(float(lg["dir"][0]), float(lg["dir"][1])).normalized()
	push_error("road_bridge: no bridge leg at " + key)
	return Vector2(1, 0)

## the corner sidewalk + kerb return of one corner (exactly the ring T's corner code, per stem)
static func _corner(g: K.Ground, ctx: Dictionary, path: RG.Path, o: Vector2, tg: Dictionary, c: Dictionary, sig: float, clips: Array) -> void:
	var zf := func(_x: float, _z: float) -> float: return 0.0
	var wf := func(_x: float, _z: float) -> float: return RG.KH
	var arc: PackedVector2Array = c["arc"]
	var la := PackedVector2Array()
	for q in arc: la.append(RG._L(ctx, q))
	var dd := (la[1] - la[0]).normalized(); var left := Vector2(dd.y, -dd.x)
	g.wall_line("curb", la, zf, wf, signf(left.dot((arc[0] - (c["c"] as Vector2)).normalized())))
	var ns: Vector2 = tg["ns"]; var ds: Vector2 = tg["ds"]
	var j: float = c["j"]; var zt: float = c["z_t"]
	var cc: Vector2 = c["c"]
	var cp := PackedVector2Array()
	for q in la: cp.append(q)
	var psd: float = tg["ps"]; var ks: float = tg["ks"]
	if (c["X"] as Vector2).distance_to(cc) < float(tg["R"]) - 0.3:
		cp.append(RG._L(ctx, o + ns * j * psd + ds * zt))
		cp.append(RG._L(ctx, c["X"]))
		var sX: float = c["s_X"]; var st0: float = c["s_t"]
		var ring_pts := RG._sub(ctx, minf(sX, st0), maxf(sX, st0))
		var rp: Array = []
		for v: float in ring_pts: rp.append(v)
		if sX > st0: rp.reverse()
		for k in range(1, rp.size()): cp.append(RG._L(ctx, path.at(float(rp[k]), sig * RG.PR)))
	else:
		var n3 := arc.size()
		var back: Array = []
		for k in range(n3 - 1, -1, -1):
			var f := float(k) / float(n3 - 1)
			var w := lerpf(RG.PR - RG.KB, psd - ks, f)
			var dv := (arc[k] - cc).normalized()
			back.append(cc + dv * (float(tg["R"]) - w))
		for q: Vector2 in back: cp.append(RG._L(ctx, q))
		clips.append(back)
	g.poly("concrete", cp, wf)

## the mouth's asphalt between the ring kerb and a stem's kerb returns
static func _mouth(g: K.Ground, ctx: Dictionary, path: RG.Path, o: Vector2, tg: Dictionary) -> void:
	var sig: float = tg["sig"]; var ks: float = tg["ks"]; var z_k: float = tg["z_k"]
	var ns: Vector2 = tg["ns"]; var ds: Vector2 = tg["ds"]
	var clo: Dictionary = tg["lo"]; var chi: Dictionary = tg["hi"]
	var mouth := PackedVector2Array()
	for v: float in RG._sub(ctx, float(clo["s_t"]), float(chi["s_t"])): mouth.append(RG._L(ctx, path.at(v, sig * RG.KB)))
	var ahi: PackedVector2Array = chi["arc"]
	for k in range(1, ahi.size()): mouth.append(RG._L(ctx, ahi[k]))
	mouth.append(RG._L(ctx, o + ns * float(chi["j"]) * ks + ds * z_k))
	mouth.append(RG._L(ctx, o + ns * float(clo["j"]) * ks + ds * z_k))
	var alo: PackedVector2Array = clo["arc"]
	for k in range(alo.size() - 1, 0, -1): mouth.append(RG._L(ctx, alo[k]))
	var mclean := PackedVector2Array()
	for q in mouth:
		if mclean.is_empty() or mclean[mclean.size() - 1].distance_to(q) > 1e-4: mclean.append(q)
	if mclean[0].distance_to(mclean[mclean.size() - 1]) < 1e-4: mclean.remove_at(mclean.size() - 1)
	g.poly("asphalt", mclean, func(_x: float, _z: float) -> float: return 0.0)

## a corner position on the walk, r - 1 from the return's centre, rotated rot_deg along it
static func _pole(ctx: Dictionary, tg: Dictionary, c: Dictionary, rot_deg: float) -> Vector3:
	var u: Vector2 = (c["u"] as Vector2).rotated(deg_to_rad(rot_deg))
	var q: Vector2 = (c["c"] as Vector2) + u * (float(tg["R"]) - 1.0)
	var l := RG._L(ctx, q)
	return Vector3(l.x, RG.KH, l.y)

static func build_cross(key: String) -> void:
	S.hill_on = false
	var R := NW.prepare()
	var path: RG.Path = R["path"]
	var nd: Dictionary = R["nodes"][key]
	var tw: Dictionary = nd["tg"]                 # the town street's T geometry (west mouth), as the ring T had it
	var name: String = nd["piece"]
	var o: Vector2 = nd["o"]
	var s_n: float = nd["s"]; var em: float = nd["em"]; var ep: float = nd["ep"]
	var sa := s_n - em; var sb := s_n + ep
	var esec: String = EAST[key]
	var de := east_dir(key)
	var te := RG._tgeom(path, o, s_n, de, esec, true)    # the east mouth
	# the east mouth must fit inside the town street's tile (else the neighbouring boulevard pieces would overlap)
	assert(float(te["stop_lo"][0]) >= sa - 1e-3 and float(te["stop_hi"][1]) <= sb + 1e-3, "east mouth outside the tile")
	var stems: Array = [tw, te]
	var zero := func(_s: float) -> float: return 0.0
	var ctx := RG._ctx(path, o, zero)
	var root := Node3D.new(); root.name = name
	var g := K.Ground.new(); var props := K.Props.new(); var dec := K.Decals.new(); var rr := W.rng_for(name)
	# the ring crosswalks / stop bars clear BOTH mouths: the outermost of the two
	var xlo: Array = [minf(float(tw["xw_lo"][0]), float(te["xw_lo"][0])), minf(float(tw["xw_lo"][1]), float(te["xw_lo"][1]))]
	var xhi: Array = [maxf(float(tw["xw_hi"][0]), float(te["xw_hi"][0])), maxf(float(tw["xw_hi"][1]), float(te["xw_hi"][1]))]
	var stl: Array = [xlo[0] - RG.STOP_GAP - RG.STOP_W, xlo[0] - RG.STOP_GAP]
	var sth: Array = [xhi[1] + RG.STOP_GAP, xhi[1] + RG.STOP_GAP + RG.STOP_W]
	assert(float(stl[0]) >= sa and float(sth[1]) <= sb, "ring stop bars outside the tile")
	# ================================================== ring carriageway through the box
	var p: Array = []
	for xr: Array in [xlo, xhi]:
		var t := -RG.KB + 0.3
		while t + 0.6 <= RG.KB - 0.3 + 1e-3:
			p.append([t, float(xr[0]), t + 0.6, float(xr[1]), "white"]); t += 1.2
	p.append([0.0, float(stl[0]), RG.KB, float(stl[1]), "white"])          # +s stop bar (t > 0 lanes, pocket included)
	p.append([-RG.KB, float(sth[0]), 0.0, float(sth[1]), "white"])          # -s stop bar
	var apl: float = stl[0]; var aph: float = sth[1]
	# both directions turn left: the centre lane is the +s pocket before the box and the -s pocket after it
	p.append([RG.TL - 0.2, sa, RG.TL - 0.05, apl, "white"]); p.append([-RG.TL + 0.05, sa, -RG.TL + 0.15, apl, "yellow"])
	p.append([-RG.TL + 0.05, aph, -RG.TL + 0.2, sb, "white"]); p.append([RG.TL - 0.15, aph, RG.TL - 0.05, sb, "yellow"])
	p.append([RG.L1 - 0.06, sa, RG.L1 + 0.06, apl, "white"])
	p.append([-RG.L1 - 0.06, aph, -RG.L1 + 0.06, sb, "white"])
	RG._dashes(p, [-RG.L1 - 0.06, -RG.L1 + 0.06], sa, float(xlo[0]), RG.DASH, "white")
	RG._dashes(p, [RG.L1 - 0.06, RG.L1 + 0.06], float(xhi[1]), sb, RG.DASH, "white")
	# bike lines on both sides: the approach toward a mouth is broken (right turners cross it), the departure solid
	for side: float in [-1.0, 1.0]:
		var tb: Array = [minf(side * RG.L2 - 0.08, side * RG.L2 + 0.08), maxf(side * RG.L2 - 0.08, side * RG.L2 + 0.08)]
		if side > 0.0:     # +s traffic drives t > 0 and approaches from the lo side
			var k := sa
			while k + 1.0 <= float(xlo[0]): p.append([tb[0], k, tb[1], k + 1.0, "white"]); k += 2.0
			p.append([tb[0], float(xhi[1]), tb[1], sb, "white"])
		else:
			p.append([tb[0], sa, tb[1], float(xlo[0]), "white"])
			var k2 := float(xhi[1])
			while k2 + 1.0 <= sb: p.append([tb[0], k2, tb[1], k2 + 1.0, "white"]); k2 += 2.0
	RG._reg(ctx, p)
	var ramps_lo: Array = [[(float(xlo[0]) + float(xlo[1])) * 0.5, RG.XW_W]]
	var ramps_hi: Array = [[(float(xhi[0]) + float(xhi[1])) * 0.5, RG.XW_W]]
	for tg: Dictionary in stems:
		var slo: float = tg["lo"]["s_t"]; var shi: float = tg["hi"]["s_t"]
		RG._reg_ramps(ctx, ramps_lo, sa, slo, 1.0); RG._reg_ramps(ctx, ramps_hi, shi, sb, 1.0)
		for e: float in [slo, shi, float(tg["lo"]["s_X"]), float(tg["hi"]["s_X"])]: (ctx["extra"] as Array).append(e)
	RG._finalize(ctx, sa, sb)
	RG._band(g, ctx, -RG.KB, RG.KB, sa, sb, p, "asphalt", 0.0)
	# both sides: corner aprons paved to the tile ends (pole bases, the crossing ramps), walks
	for tg: Dictionary in stems:
		var sig: float = tg["sig"]
		var slo: float = tg["lo"]["s_t"]; var shi: float = tg["hi"]["s_t"]
		RG._strip(g, ctx, sig * RG.KB, sig * RG.PK, sa, slo, ramps_lo, "concrete", 1.8, 1.0)
		RG._strip(g, ctx, sig * RG.KB, sig * RG.PK, shi, sb, ramps_hi, "concrete", 1.8, 1.0)
		RG._plain(g, ctx, sig * RG.PK, sig * RG.PR, sa, slo, "concrete")
		RG._plain(g, ctx, sig * RG.PK, sig * RG.PR, shi, sb, "concrete")
	# ================================================== the two stems
	var clips: Array = []
	var stem_ctx: Array = []
	for tg: Dictionary in stems:
		var sec: String = tg["sec"]
		var sd: Dictionary = RG.SEC[sec]
		var ds: Vector2 = tg["ds"]
		var ks: float = tg["ks"]; var psd: float = tg["ps"]; var pkw: float = sd["pkw"]
		var z_k: float = tg["z_k"]; var z_E: float = tg["z_E"]
		var xw: Array = tg["z_xw"]; var zst: Array = tg["z_stop"]
		var stem := RG.Path.new(); stem.add_line(o, o + ds * 200.0)
		var cst := RG._ctx(stem, o, zero)
		stem_ctx.append(cst)
		var ps: Array = []
		var t := -ks + 0.3
		while t + 0.6 <= ks - 0.3 + 1e-3:
			ps.append([t, float(xw[0]), t + 0.6, float(xw[1]), "white"]); t += 1.2
		var sarrows: Array = []
		var za := float(zst[1]) + 1.4
		match sec:
			"strip", "couplet":     # the town street (as the ring T); at a 4-way it gets a through movement too
				ps.append([-RG.L2, float(zst[0]), RG.TL, float(zst[1]), "white"])
				ps.append([-RG.TL + 0.05, float(zst[1]), -RG.TL + 0.2, z_E, "white"])
				ps.append([RG.TL - 0.15, float(xw[1]), RG.TL - 0.05, z_E, "yellow"])
				ps.append([-RG.L1 - 0.06, float(zst[1]), -RG.L1 + 0.06, z_E, "white"])
				RG._dashes(ps, [RG.L1 - 0.06, RG.L1 + 0.06], float(xw[1]) + 2.0, z_E, RG.DASH, "white")
				for sx: float in [-1.0, 1.0]: ps.append([minf(sx * RG.L2 - 0.08, sx * RG.L2 + 0.08), float(xw[1]) if sx > 0.0 else float(zst[1]), maxf(sx * RG.L2 - 0.08, sx * RG.L2 + 0.08), z_E, "white"])
				if z_E - za > 5.0:
					sarrows.append(RG._arrow("left", 0.0, za + 4.5, za))
					sarrows.append(RG._arrow("through", -(RG.TL + RG.L1) * 0.5, za + 4.5, za))
					sarrows.append(RG._arrow("through_right", -(RG.L1 + RG.L2) * 0.5, za + 4.5, za))
			"approach":     # median 2.0, lanes 2.0 - 5.6 - 9.2, shoulder to the kerb 10.2
				ps.append([-9.2, float(zst[0]), -2.0, float(zst[1]), "white"])
				ps.append([-5.66, float(zst[1]), -5.54, z_E, "white"])           # solid between the inbound lanes
				RG._dashes(ps, [5.54, 5.66], float(xw[1]) + 2.0, z_E, RG.DASH, "white")
				for sx: float in [-1.0, 1.0]: ps.append([minf(sx * 9.2 - 0.08, sx * 9.2 + 0.08), float(xw[1]) if sx > 0.0 else float(zst[1]), maxf(sx * 9.2 - 0.08, sx * 9.2 + 0.08), z_E, "white"])
				var zn := float(xw[1]) + 1.0
				ps.append([-2.0, zn + 2.0, 2.0, z_E, "-"])                      # under the island
				var nose := PackedVector2Array()
				for k in 13: nose.append(Vector2(2.0 * cos(PI * k / 12.0), zn + 2.0 - 2.0 * sin(PI * k / 12.0)))
				sarrows.append({"box": [-2.1, zn - 0.1, 2.1, zn + 2.0], "poly": nose, "c": 0.0, "axis": "x", "fill": ""})
				tg["nose"] = zn
				if z_E - za > 5.0:
					sarrows.append(RG._arrow("left_through", -3.8, za + 4.5, za))
					sarrows.append(RG._arrow("through_right", -7.4, za + 4.5, za))
			"ramp":         # one-way in: two lanes (t < 0 right lane, t > 0 left lane), edge lines at 3.6
				ps.append([-3.6, float(zst[0]), 3.6, float(zst[1]), "white"])
				ps.append([-0.06, float(zst[1]), 0.06, z_E, "white"])
				for sx: float in [-1.0, 1.0]: ps.append([minf(sx * 3.6 - 0.08, sx * 3.6 + 0.08), float(zst[1]), maxf(sx * 3.6 - 0.08, sx * 3.6 + 0.08), z_E, "white"])
				if z_E - za > 5.0:
					sarrows.append(RG._arrow("left_through", 1.8, za + 4.5, za))
					sarrows.append(RG._arrow("right", -1.8, za + 4.5, za))
		RG._reg(cst, ps, sarrows)
		var ramp_st: Array = [[(float(xw[0]) + float(xw[1])) * 0.5, RG.XW_W]]
		RG._reg_ramps(cst, ramp_st, 0.0, z_E, 1.0)
		for e: float in [float(tg["lo"]["z_t"]), float(tg["hi"]["z_t"]), float(tg["lo"]["zX"]), float(tg["hi"]["zX"]), z_k]: (cst["extra"] as Array).append(e)
		RG._finalize(cst, 0.0, z_E)
		RG._band(g, cst, -ks, ks, z_k, z_E, ps, "asphalt", 0.0, sarrows)
		if tg.has("nose"): RG._median(g, cst, float(tg["nose"]), z_E, 2.0, true)
		for c: Dictionary in [tg["lo"], tg["hi"]]:
			var j: float = c["j"]; var zt: float = c["z_t"]
			if pkw > ks + 0.1:
				RG._strip(g, cst, j * ks, j * pkw, zt, z_E, ramp_st, "grass", 1.4, 0.0)
				RG._plain(g, cst, j * pkw, j * psd, zt, z_E, "concrete")
			else:
				RG._strip(g, cst, j * ks, j * psd, zt, z_E, ramp_st, "concrete", 1.8, 1.0)
		_mouth(g, ctx, path, o, tg)
		for c: Dictionary in [tg["lo"], tg["hi"]]: _corner(g, ctx, path, o, tg, c, float(tg["sig"]), clips)
	# ================================================== signals and furniture
	var to_centre := func(v: Vector3) -> float: return RG._yaw(Vector2(-v.x, -v.z))
	var d_pos := path.tangent(sth[0]); var d_neg := path.tangent(stl[1])
	var pos_side: Dictionary = tw if float(tw["sig"]) > 0.0 else te       # the stem on the +t side
	var neg_side: Dictionary = te if pos_side == tw else tw
	# ring +s approach: far-right = the +t stem's hi corner; ring -s approach: far-right = the -t stem's lo corner
	props.add("prop_signal_mast_arm", "worn", _pole(ctx, pos_side, pos_side["hi"], 0.0), RG._yaw(-d_pos))
	props.add("prop_signal_mast_arm", "worn", _pole(ctx, neg_side, neg_side["lo"], 0.0), RG._yaw(d_neg))
	# each stem's approach: far-right = the OTHER stem's corner on the driver's right (j = +1 of the far stem: the
	# far stem's lateral +ns is the right of a driver going out along its ds)
	for k in 2:
		var near_t: Dictionary = stems[k]; var far_t: Dictionary = stems[1 - k]
		if String(near_t["sec"]) == "approach" or String(near_t["sec"]) == "ramp" or String(near_t["sec"]) in ["strip", "couplet"]:
			var cfar: Dictionary = far_t["hi"] if float(far_t["hi"]["j"]) > 0.0 else far_t["lo"]
			props.add("prop_signal_mast_arm", "worn", _pole(ctx, far_t, cfar, 0.0), RG._yaw(-(far_t["ds"] as Vector2)))
	# (at a 4-way every corner already carries one mast arm pole: the far-right corner of one approach is the near-right
	# corner of the next, so no extra posts - the validator found them standing in the arm poles)
	for tg: Dictionary in stems:
		for c: Dictionary in [tg["lo"], tg["hi"]]:
			props.add("prop_sign_street_names", "worn", _pole(ctx, tg, c, 20.0 * float(c["j"])), 45.0 + RG._yaw(tg["ds"] as Vector2))
			props.add("prop_trash_receptacle", "worn", _pole(ctx, tg, c, -34.0 * float(c["j"])), 0.0)      # people wait for the light
		var lc: Dictionary = tg["hi"]
		props.add("prop_lamp_cobra", "worn", _pole(ctx, tg, lc, -24.0 * float(lc["j"])), float(to_centre.call(_pole(ctx, tg, lc, -24.0 * float(lc["j"])))))
	# (the gateway palms stand in the approach's median and verges, never on the corner walks: trees only in grass)
	props.add("prop_newspaper_box_blue" if rr.randf() < 0.5 else "prop_newspaper_box_red", "worn", _pole(ctx, tw, tw["lo"], 40.0 * float(tw["lo"]["j"])), RG._yaw(tw["lo"]["u"] as Vector2))
	props.add("prop_hydrant_red", "worn", _pole(ctx, te, te["hi"], 30.0 * float(te["hi"]["j"])), RG._yaw(te["hi"]["u"] as Vector2))
	for e: Array in [[sa + 1.6, 1.0], [sb - 1.6, -1.0], [sa + 1.6, -1.0], [sb - 1.6, 1.0]]:
		var sv: float = e[0]
		props.add("prop_storm_drain_curb_inlet", "dirty", RG._P(ctx, sv, float(e[1]) * RG.KB, 0.0), RG._yaw(-path.normal(sv) * float(e[1])), false)
	props.add("prop_manhole_cover", "worn", RG._P(ctx, s_n + rr.randf_range(-4.0, 4.0), 3.5, 0.002), 0.0, false)
	# ================================================== wear: a busy gateway
	var yr := func(_x: float, _z: float) -> float: return 0.0
	var yw := func(_x: float, _z: float) -> float: return RG.KH
	for e3: Array in [[float(stl[0]), 1.0], [float(sth[1]), -1.0]]:
		var se: float = e3[0]; var dr: float = e3[1]
		for ln: float in [(RG.TL + RG.L1) * 0.5, (RG.L1 + RG.L2) * 0.5]:
			for wp: float in [-0.8, 0.8]: RG._dec(dec, ctx, 8, se - dr * 3.0, dr * (ln + wp), 0.45, 5.5, yr, Color(1, 1, 1, 0.5))
			W.oil(dec, rr, RG._L(ctx, path.at(se - dr * 2.5, dr * ln)), RG._yaw(path.tangent(se)), yr, 0.7)
	for k in 2:
		var tg: Dictionary = stems[k]; var cst: Dictionary = stem_ctx[k]
		var lane_c := -3.8 if String(tg["sec"]) == "approach" else (-1.8 if String(tg["sec"]) == "ramp" else -(RG.TL + RG.L1) * 0.5)
		for wp: float in [-0.8, 0.8]:
			RG._dec(dec, cst, 8, float(tg["z_stop"][1]) + 3.0, lane_c + wp, 0.45, 5.0, yr, Color(1, 1, 1, 0.45))
		W.oil(dec, rr, RG._L(cst, (cst["path"] as RG.Path).at(float(tg["z_stop"][1]) + 2.5, lane_c)), RG._yaw(tg["ds"] as Vector2), yr, 0.7)
	for k in 7:     # turning arcs through the box
		var sv := rr.randf_range(sa + 8.0, sb - 8.0)
		RG._dec(dec, ctx, 8, sv, rr.randf_range(-7.0, 7.0), 0.6, 8.0, yr, Color(1, 1, 1, 0.36), rr.randf_range(25.0, 65.0) * (1.0 if rr.randf() < 0.5 else -1.0))
	RG._cracks(dec, rr, ctx, -9.0, 9.0, sa + 1.0, sb - 1.0, 14, yr, 0.5)
	for k in 8:     # the signal duct trench right across the box
		RG._dec(dec, ctx, 3, s_n + 2.0, -RG.KB + 1.2 + k * 2.4, 0.7, 2.4, yr, Color(1, 1, 1, 0.55), 90.0)
	for tg: Dictionary in stems:
		for c: Dictionary in [tg["lo"], tg["hi"]]:
			var arc2: PackedVector2Array = c["arc"]
			for k in range(1, arc2.size() - 1, 3):
				var q: Vector2 = arc2[k] + (arc2[k] - (c["c"] as Vector2)).normalized() * 0.3
				dec.add(14, RG._L(ctx, q), RG._yaw(arc2[k + 1] - arc2[k]), 0.5, 2.0, yr, Color(1, 1, 1, 0.55))
			dec.add(14, RG._L(ctx, (c["c"] as Vector2) + (c["u"] as Vector2) * (float(tg["R"]) - 2.6)), rr.randf_range(0, 90), 3.0, 2.2, yw, Color(1, 1, 1, 0.45))
	var site := {"site": key, "kind": "X", "ctl": "signal", "stem": tw["sec"], "east": esec, "pos": [o.x, float(nd["pad"]), o.y], "yaw": 0.0,
		"s": [sa, sb], "z_E": tw["z_E"], "z_E_east": te["z_E"], "bus": nd.get("bus", false)}
	if not clips.is_empty(): site["corner_clip"] = clips
	RG._finish(root, g, props, dec, name, {"rg": site})

## ===================================================================================================== the approach
## The divided approach (zoning/hero_geom.json "approach": 45 m straight off the gateway, a reverse curve of two R 234 m
## arcs, 40 m straight onto the deck), s = 0 at the 4th St node, +s toward the bridge; +t = the right of a +s driver
## (outbound lanes t > 0, inbound t < 0). Section: planted median |t| < 2 (queen palms: the island's welcome), lanes to
## 5.6 / 9.2, 1 m shoulders, kerbs at 10.2, grass verges to 12.2 with cobra lamps, a 2 m walk to 14.2 for the first
## 70 m off the gateway (ending in a small bench overlook: walks never just stop), no walk further out (nobody walks onto
## the bridge: it has no footway). Height: 4.0 m at the gateway pad up to the deck's 6.9 m, smoothstep (max 0.7 %).
## The off-ramp diverges on the inbound side (see DIVERGE): its whole beginning (taper, deceleration lane, painted gore,
## the kerbed nose) is built in the approach's (t, s) frame; the ramp piece takes over at the nose line.
const DECK_Y := 6.9
const APPR_PAD := 4.0
const TAPER := [360.0, 450.0]       # the deceleration lane opens (s 450 -> 360, smoothstep 0 -> 4 m)
const BLEND := [335.0, 358.0]       # the lane drifts from hugging the inbound edge onto the ramp's own line (its arc starts at ~358)
const NOSE_GAP := 1.4               # the raised nose starts where approach kerb and ramp kerb are this far apart
const WALK_LEN := 70.0
const RAMP_PAD := 2.0               # 3rd St node pad

static var _AP: RG.Path = null
static var _RP: RG.Path = null
static var _tab := {}

static func approach_path() -> RG.Path:
	if _AP != null: return _AP
	# exact, as hero_geom.py laid it out: 45 m straight off the gateway, two tangent arcs of equal radius (a symmetric
	# reverse curve: the inflection is the midpoint of the arcs' ends), 40 m straight onto the deck (fit_polyline
	# cannot fit an S with no straight between its arcs)
	var a1 := Vector2(705.0, -1200.0); var a2 := Vector2(1140.0, -905.0)
	var pm := (a1 + a2) * 0.5
	_AP = RG.Path.new()
	_AP.add_line(Vector2(660.0, -1200.0), a1)
	RG._arc_to(_AP, a1, Vector2(1.0, 0.0), pm)
	RG._arc_to(_AP, pm, _AP.tangent(_AP.length), a2)
	_AP.add_line(a2, Vector2(1180.0, -905.0))
	return _AP

## the ramp's own path: from its point level with approach station 345 (on the plateau) to the 3rd St node
static func ramp_path() -> RG.Path:
	if _RP != null: return _RP
	# exact, through hero_geom's own break points: P1 (beside approach station ~358, 12 m right of a driver coming off
	# the bridge, where the taper ends), the R 225 m arc away to P2, the R 224 m arc back to the 35 m straight onto 3rd
	# St (each arc tangent to the one before: no kinks)
	var p1 := Vector2(947.7503, -1027.894); var p2 := Vector2(918.8714, -1159.6529)
	var h1 := deg_to_rad(-120.0536)
	_RP = RG.Path.new()
	RG._arc_to(_RP, p1, Vector2(cos(h1), sin(h1)), p2)
	# the second arc ends exactly where it becomes tangent to 3rd St's line (v = -1400, heading -u): no kink
	var t2 := _RP.tangent(_RP.length)
	var b := Vector2(695.0, -1400.0)
	for m: Vector2 in [Vector2(-t2.y, t2.x), Vector2(t2.y, -t2.x)]:
		var r := (-1400.0 - p2.y) / (m.y - 1.0)
		if r > 0.0: b = Vector2(p2.x + m.x * r, -1400.0)
	RG._arc_to(_RP, p2, t2, b)
	_RP.add_line(b, Vector2(660.0, -1400.0))
	return _RP

static func appr_len() -> float: return approach_path().length

static func appr_y(s: float, s_start: float) -> float:
	var L := appr_len()
	return APPR_PAD + (DECK_Y - APPR_PAD) * RG._ss(clampf((s - s_start) / (L - s_start), 0.0, 1.0))

## a ramp-frame curve (ramp lateral tr) as a table of approach (s -> t), sampled every 0.5 m of ramp
static func _ramp_curve(tr: float) -> Array:
	if _tab.has(tr): return _tab[tr]
	var ap := approach_path(); var rp := ramp_path()
	var out: Array = []
	var sr := 0.0
	while sr <= 80.0:
		var q := ap.project(rp.at(sr, tr))
		out.append(q)
		sr += 0.5
	out.sort_custom(func(a: Vector2, b: Vector2) -> bool: return a.x < b.x)
	_tab[tr] = out
	return out

static func _interp(tab: Array, s: float) -> float:
	if s <= (tab[0] as Vector2).x: return (tab[0] as Vector2).y
	for k in range(1, tab.size()):
		var b: Vector2 = tab[k]
		if b.x >= s:
			var a: Vector2 = tab[k - 1]
			return lerpf(a.y, b.y, (s - a.x) / maxf(b.x - a.x, 1e-6))
	return (tab[tab.size() - 1] as Vector2).y

## the diverge's lateral lines at approach station s (all t < 0): lane left edge, lane right edge, outer kerb
static func dv_lines(s: float) -> Dictionary:
	var w := 4.0 * RG._ss(clampf((TAPER[1] - s) / (TAPER[1] - TAPER[0]), 0.0, 1.0))
	var c_t := -(9.2 + w * 0.5)
	var half := w * 0.5
	var c := c_t
	if s < BLEND[1]:
		var cr := _interp(_ramp_curve(0.0), s)
		c = lerpf(c_t, cr, RG._ss(clampf((BLEND[1] - s) / (BLEND[1] - BLEND[0]), 0.0, 1.0)))
	if s < BLEND[0]:
		return {"el": _interp(_ramp_curve(-2.0), s), "er": _interp(_ramp_curve(2.0), s), "E": _interp(_ramp_curve(3.0), s), "kl": _interp(_ramp_curve(-2.6), s)}
	return {"el": c + half, "er": c - half, "E": c - half - 1.0, "kl": c + half + 0.6}

static var _cache := {}

static func nose_s() -> float:
	if _cache.has("nose"): return _cache["nose"]
	var lo := 250.0; var hi := BLEND[0]
	for it in 50:
		var mid := (lo + hi) * 0.5
		var gap := -10.2 - float(dv_lines(mid)["kl"])
		if gap > NOSE_GAP: lo = mid
		else: hi = mid
	_cache["nose"] = (lo + hi) * 0.5
	return _cache["nose"]

## approach parts: [name, s0, s1]; the diverge part holds the nose .. the taper start whole
static func approach_parts() -> Array:
	if _cache.has("aparts"): return _cache["aparts"]
	var R := NW.prepare()
	var te := RG._tgeom(R["path"], R["nodes"]["660.0,-1200.0"]["o"], float(R["nodes"]["660.0,-1200.0"]["s"]), east_dir("660.0,-1200.0"), "approach", true)
	var s0: float = te["z_E"]
	var sn := nose_s()
	var L := appr_len()
	var out: Array = []
	var cuts: Array = []
	var a := s0; var b := sn - 30.0
	var n := maxi(1, ceili((b - a) / 110.0))
	for i in n: cuts.append([lerpf(a, b, float(i) / n), lerpf(a, b, float(i + 1) / n)])
	cuts.append([sn - 30.0, TAPER[1] + 10.0])
	a = TAPER[1] + 10.0; b = L
	n = maxi(1, ceili((b - a) / 110.0))
	for i in n: cuts.append([lerpf(a, b, float(i) / n), lerpf(a, b, float(i + 1) / n)])
	for i in cuts.size(): out.append(["s_br_appr_%d" % (i + 1), float(cuts[i][0]), float(cuts[i][1])])
	_cache["aparts"] = out
	return out

## a (t, s) polygon -> ground triangles through the approach path at height ys(s) + lift
static func _poly_ts(g: K.Ground, ctx: Dictionary, poly: PackedVector2Array, m: String, lift: float) -> void:
	if poly.size() < 3: return
	RG._tri_poly(g, ctx, poly, m, lift)

## the region between two lateral functions fa(s) (inner) and fb(s) (outer), s0..s1, as a (t, s) polygon on the cuts
static func _region(ctx: Dictionary, fa: Callable, fb: Callable, s0: float, s1: float) -> PackedVector2Array:
	var sc := RG._sub(ctx, s0, s1)
	var poly := PackedVector2Array()
	for v: float in sc: poly.append(Vector2(float(fa.call(v)), v))
	for k in range(sc.size() - 1, -1, -1): poly.append(Vector2(float(fb.call(sc[k])), sc[k]))
	return poly

static func _clip_all(base: Array, cutters: Array) -> Array:
	var cur: Array = base
	for c: PackedVector2Array in cutters:
		var nxt: Array = []
		for p: PackedVector2Array in cur:
			for r: PackedVector2Array in Geometry2D.clip_polygons(p, c):
				if not Geometry2D.is_polygon_clockwise(r) or true: nxt.append(r)
		cur = nxt
	return cur

## kerb faces along a (t, s) polyline; each face looks toward (t, s) + face (a (dt, ds) offset), so the side is explicit
static func _kerb_ts(g: K.Ground, ctx: Dictionary, pts: Array, face: Vector2) -> void:
	var path: RG.Path = ctx["path"]; var ys: Callable = ctx["ys"]
	for k in pts.size() - 1:
		var a: Vector2 = pts[k]; var b: Vector2 = pts[k + 1]
		var A := RG._F(ctx, a.y, a.x, float(ys.call(a.y))); var B := RG._F(ctx, b.y, b.x, float(ys.call(b.y)))
		var m := (a + b) * 0.5 + face
		var F := RG._F(ctx, m.y, m.x, 0.0)
		var mid := (A + B) * 0.5
		var d := Vector2(B.x - A.x, B.z - A.z).normalized(); var n := Vector2(-d.y, d.x)
		if n.dot(Vector2(F.x - mid.x, F.z - mid.z)) < 0.0: n = -n
		g.quad("curb", A, B, B + Vector3(0, RG.KH, 0), A + Vector3(0, RG.KH, 0), Vector3(n.x, 0.0, n.y), true)

static func _half_disc(c: Vector2, r: float, toward_s: float, n := 16) -> Array:
	var out: Array = []
	for k in n + 1:
		var a := PI * k / n
		out.append(Vector2(c.x + r * cos(a), c.y + toward_s * r * sin(a)))
	return out

## convex polygon (t, s) clipped to the half plane a*t + b*s + c >= 0 (Sutherland-Hodgman)
static func _clip_hp(poly: PackedVector2Array, a: float, b: float, c: float) -> PackedVector2Array:
	var out := PackedVector2Array()
	var n := poly.size()
	for i in n:
		var p := poly[i]; var q := poly[(i + 1) % n]
		var fp := a * p.x + b * p.y + c; var fq := a * q.x + b * q.y + c
		if fp >= 0.0: out.append(p)
		if (fp >= 0.0) != (fq >= 0.0):
			out.append(p.lerp(q, fp / (fp - fq)))
	return out

static func _area(poly: PackedVector2Array) -> float:
	var a := 0.0
	for i in poly.size():
		var p := poly[i]; var q := poly[(i + 1) % poly.size()]
		a += p.x * q.y - q.x * p.y
	return absf(a) * 0.5

## a (t, s) polygon -> triangles: convex ones by fan (always works), others by triangulation
static func _fill(g: K.Ground, ctx: Dictionary, poly: PackedVector2Array, m: String, lift: float, convex: bool) -> void:
	if poly.size() < 3 or _area(poly) < 1e-5: return
	var ys: Callable = ctx["ys"]
	var V := func(q: Vector2) -> Vector3: return RG._F(ctx, q.y, q.x, float(ys.call(q.y)) + lift)
	if convex:
		for k in range(1, poly.size() - 1):
			g.tri(m, V.call(poly[0]), V.call(poly[k]), V.call(poly[k + 1]))
	else:
		RG._tri_poly(g, ctx, poly, m, lift)

## The diverge zone on the inbound side, cell by cell along the approach's shared s cuts: per cell the lateral lines at
## both ends (inbound edge -9.2 | gore | ramp lane left line | ramp lane | right line | shoulder | kerb E | verge), quads
## between them; the gore gets 45 deg chevrons (0.45 m every 3 m) cut by exact half-plane clipping (convex pieces, no
## slivers), the nose tip's half disc is cut out of the cells it reaches.
static func _diverge(g: K.Ground, ctx: Dictionary, dv0: float, dv1: float, sn: float, tipc: Vector2, tipr: float) -> void:
	var sc: Array = []
	for v: float in RG._sub(ctx, dv0, dv1): sc.append(v)
	if tipr > 0.0:     # fine cuts through the tip's reach
		var k := sn
		while k < sn + tipr + 0.5:
			if k > dv0 and k < dv1: sc.append(k)
			k += 0.25
		sc.sort()
	var tipp := PackedVector2Array()
	if tipr > 0.0:
		for q: Vector2 in _half_disc(tipc, tipr, 1.0, 24): tipp.append(q)
	var lines := func(s: float) -> Array:
		var d: Dictionary = dv_lines(s)
		var el: float = d["el"]; var er: float = d["er"]; var E: float = d["E"]
		var lw := 0.12 if s < TAPER[0] - 1e-3 else 0.0
		return [-9.2, minf(el, -9.2), minf(el, -9.2) - lw, er + 0.12, er, E, E - 2.0]
	for j in sc.size() - 1:
		var sa: float = sc[j]; var sb: float = sc[j + 1]
		if sb - sa < 1e-4: continue
		var la: Array = lines.call(sa); var lb: Array = lines.call(sb)
		var mats := ["gore", "white" if (sa + sb) * 0.5 < TAPER[0] else "asphalt", "asphalt", "white", "asphalt", "verge"]
		for b in 6:
			var quad := PackedVector2Array([Vector2(float(la[b]), sa), Vector2(float(lb[b]), sb), Vector2(float(lb[b + 1]), sb), Vector2(float(la[b + 1]), sa)])
			if _area(quad) < 1e-5: continue
			var m: String = mats[b]
			if m == "verge":
				_fill(g, ctx, quad, "grass", RG.KH, true); continue
			var pieces: Array = []      # [poly, material]
			if m == "gore":
				# chevrons: stripes where (s + t) mod 3 < 0.45 (45 deg, pointing at the arriving traffic)
				var lo := INF; var hi := -INF
				for q: Vector2 in quad: lo = minf(lo, q.y + q.x); hi = maxf(hi, q.y + q.x)
				var c := floorf(lo / 3.0) * 3.0
				var cur := lo
				while cur < hi:
					var st0 := maxf(c, lo); var st1 := minf(c + 0.45, hi)
					var nxt := minf(c + 3.0, hi)
					if st1 > st0 and st0 < hi:
						pieces.append([_clip_hp(_clip_hp(quad, 1.0, 1.0, -st0), -1.0, -1.0, st1), "white"])
					if nxt > st1:
						pieces.append([_clip_hp(_clip_hp(quad, 1.0, 1.0, -maxf(st1, lo)), -1.0, -1.0, nxt), "asphalt"])
					c += 3.0; cur = c
				if (sa + sb) * 0.5 >= TAPER[0]: pieces = [[quad, "asphalt"]]
			else:
				pieces.append([quad, m])
			for pc: Array in pieces:
				var poly: PackedVector2Array = pc[0]
				if poly.size() < 3: continue
				var hit := tipr > 0.0 and sb > sn and sa < sn + tipr and Geometry2D.intersect_polygons(poly, tipp).size() > 0
				if hit:
					for r: PackedVector2Array in Geometry2D.clip_polygons(poly, tipp): _fill(g, ctx, r, String(pc[1]), 0.0, false)
				else:
					_fill(g, ctx, poly, String(pc[1]), 0.0, true)
	# the outer kerb along E (faces the asphalt)
	var ek: Array = []
	for v2: float in sc: ek.append(Vector2(float(dv_lines(v2)["E"]), v2))
	_kerb_ts(g, ctx, ek, Vector2(0.5, 0.0))

static func build_approach(part: int) -> void:
	S.hill_on = false
	var parts := approach_parts()
	var pl: Array = parts[part - 1]
	var name: String = pl[0]; var s0: float = pl[1]; var s1: float = pl[2]
	var ap := approach_path()
	var s_start: float = parts[0][1]
	var o := ap.point(s0); var oy := appr_y(s0, s_start)
	var ys := func(s: float) -> float: return appr_y(s, s_start) - oy
	var ctx := RG._ctx(ap, o, ys)
	var root := Node3D.new(); root.name = name
	var g := K.Ground.new(); var props := K.Props.new(); var dec := K.Decals.new(); var rr := W.rng_for(name)
	var L := appr_len()
	var sn := nose_s()
	var dv0 := maxf(s0, sn); var dv1 := minf(s1, TAPER[1])
	var has_dv := dv1 > dv0 + 0.01
	var med_end := L - 30.0
	var wend := s_start + WALK_LEN
	var isl0 := sn - 25.0
	# ---------------------------------------------------------------- paint (main carriageway)
	var p: Array = []
	RG._dashes(p, [5.54, 5.66], s0, s1, RG.DASH, "white")
	RG._dashes(p, [-5.66, -5.54], s0, s1, RG.DASH, "white")
	p.append([9.12, s0, 9.28, s1, "white"])
	if s0 < med_end:
		p.append([2.05, s0, 2.17, minf(s1, med_end), "yellow"]); p.append([-2.17, s0, -2.05, minf(s1, med_end), "yellow"])
	var dot0 := maxf(dv0, TAPER[0]) if has_dv else 0.0
	if has_dv:
		if s0 < dot0: p.append([-9.2, s0, -9.12, dot0, "white"])
		var k := dot0
		while k + 1.0 <= dv1: p.append([-9.2, k, -9.12, k + 1.0, "white"]); k += 3.0
		if s1 > dv1: p.append([-9.2, dv1, -9.12, s1, "white"])
	else:
		p.append([-9.2, s0, -9.12, s1, "white"])
	var arrows: Array = []
	var nose_here := med_end > s0 and med_end < s1 - 2.0
	if nose_here:
		var nz := PackedVector2Array()
		for q: Vector2 in _half_disc(Vector2(0.0, med_end), 2.0, 1.0): nz.append(q)
		arrows.append({"box": [-2.0, med_end, 2.0, med_end + 2.0], "poly": nz, "c": 0.0, "axis": "x", "fill": ""})
	RG._reg(ctx, p, arrows)
	for e: float in [dv0, dv1, TAPER[0], BLEND[0], BLEND[1], wend, wend - 3.0, isl0, sn, med_end]:
		(ctx["extra"] as Array).append(e)
	RG._finalize(ctx, s0, s1)
	# ---------------------------------------------------------------- carriageway + median
	var me := clampf(med_end, s0, s1)
	RG._band(g, ctx, -9.2, -2.0, s0, s1, p, "asphalt", 0.0)
	RG._band(g, ctx, 2.0, 10.2, s0, s1, p, "asphalt", 0.0)
	if me < s1: RG._band(g, ctx, -2.0, 2.0, me, s1, p, "asphalt", 0.0, arrows)
	if me > s0:
		RG._strip(g, ctx, 2.0, 0.0, s0, me, [], "grass", 1.5, 1.0, true, false)
		RG._strip(g, ctx, -2.0, 0.0, s0, me, [], "grass", 1.5, 1.0, true, false)
	if nose_here:     # the median's round nose: raised grass, kerb all round
		var hd := _half_disc(Vector2(0.0, med_end), 2.0, 1.0)
		var nzp := PackedVector2Array()
		for q: Vector2 in hd: nzp.append(q)
		_poly_ts(g, ctx, nzp, "grass", RG.KH)
		_kerb_ts(g, ctx, hd, Vector2(0.0, 0.5))
	# ---------------------------------------------------------------- outbound side: kerb, verge, walk near the gateway
	RG._strip(g, ctx, 10.2, 12.2, s0, s1, [], "grass", 1.5, 1.0, true, false)
	if s0 < wend: RG._plain(g, ctx, 12.2, 14.2, s0, minf(s1, wend), "concrete")
	# ---------------------------------------------------------------- inbound side outside the diverge
	var segs: Array = []
	if has_dv:
		if s0 < dv0: segs.append([s0, dv0])
		if s1 > dv1: segs.append([dv1, s1])
	else:
		segs.append([s0, s1])
	for sg: Array in segs:
		var a0: float = sg[0]; var a1: float = sg[1]
		RG._band(g, ctx, -10.2, -9.2, a0, a1, p, "asphalt", 0.0)
		# the verge, except along the nose island (the island takes that ground)
		var vsegs: Array = [[a0, a1]]
		if isl0 < a1 and sn > a0: vsegs = [[a0, maxf(a0, isl0)]]
		for vs: Array in vsegs:
			if float(vs[1]) > float(vs[0]) + 0.01:
				RG._strip(g, ctx, -10.2, -12.2, float(vs[0]), float(vs[1]), [], "grass", 1.5, 1.0, true, false)
		if a0 < wend: RG._plain(g, ctx, -12.2, -14.2, a0, minf(a1, wend), "concrete")
	# the walks end in a rounded cap, a bench pad beside it facing back over the park (walks never just stop)
	if s0 < wend and s1 >= wend:
		for side: float in [-1.0, 1.0]:
			var cap := _half_disc(Vector2(side * 13.2, wend), 1.0, 1.0)
			var cp := PackedVector2Array()
			for q: Vector2 in cap: cp.append(q)
			_poly_ts(g, ctx, cp, "concrete", RG.KH)
			var pad := PackedVector2Array([Vector2(side * 14.2, wend - 3.0), Vector2(side * 16.4, wend - 3.0), Vector2(side * 16.4, wend), Vector2(side * 14.2, wend)])
			_poly_ts(g, ctx, pad, "concrete", RG.KH)
			props.add("prop_park_bench", "worn", RG._P(ctx, wend - 1.5, side * 15.6), RG._yaw(ap.normal(wend) * side))
			props.add("prop_trash_receptacle", "dirty", RG._P(ctx, wend - 0.4, side * 14.7), 0.0)
	# ---------------------------------------------------------------- the diverge (inbound side, t < 0)
	var tipc := Vector2.ZERO; var tipr := 0.0
	if sn >= s0 and sn <= s1:
		var kl: float = dv_lines(sn)["kl"]
		tipc = Vector2((-10.2 + kl) * 0.5, sn); tipr = (-10.2 - kl) * 0.5
	if has_dv:
		_diverge(g, ctx, dv0, dv1, sn, tipc, tipr)
	if tipr > 0.0:
		# the raised nose: the tip + 25 m of island between the approach kerb (-10.2) and the ramp's kerb
		var sc2 := RG._sub(ctx, maxf(s0, isl0), sn)
		var side_a: Array = []; var side_b: Array = []
		for v2: float in sc2:
			side_a.append(Vector2(-10.2, v2)); side_b.append(Vector2(float(dv_lines(v2)["kl"]), v2))
		var arc := _half_disc(tipc, tipr, 1.0)
		var isl := PackedVector2Array()
		for q: Vector2 in side_a: isl.append(q)
		for k8 in range(1, arc.size() - 1): isl.append(arc[k8])
		for k9 in range(side_b.size() - 1, -1, -1): isl.append(side_b[k9])
		_poly_ts(g, ctx, isl, "grass", RG.KH)
		_kerb_ts(g, ctx, side_a, Vector2(0.5, 0.0))
		var arc_faces: Array = []
		for q2: Vector2 in arc: arc_faces.append(q2)
		for k13 in arc_faces.size() - 1:
			var a: Vector2 = arc_faces[k13]; var b: Vector2 = arc_faces[k13 + 1]
			var mid := (a + b) * 0.5
			_kerb_ts(g, ctx, [a, b], (mid - tipc).normalized() * 0.5)
		_kerb_ts(g, ctx, side_b, Vector2(-0.5, 0.0))
		props.add("prop_bollard_concrete", "worn", RG._P(ctx, sn - 0.8, tipc.x), 0.0)
	# ---------------------------------------------------------------- furniture
	var sp := ceilf(s0 / 16.0) * 16.0
	while sp < minf(s1, med_end - 4.0):
		if sp > s_start + 6.0:
			props.add("palm_queen_a" if int(sp / 16.0) % 3 != 1 else "palm_mexican_fan_a", "normal", RG._P(ctx, sp, 0.0), rr.randf_range(0, 360), true, rr.randf_range(0.85, 1.1))
		sp += 16.0
	var sl := ceilf(s0 / 40.0) * 40.0
	while sl < s1:
		props.add("prop_lamp_cobra", "worn", RG._P(ctx, sl, 11.0), RG._yaw(-ap.normal(sl)))
		var sl2 := sl + 20.0
		if sl2 < s1:
			var tin := -11.0
			if has_dv and sl2 >= dv0 and sl2 <= dv1: tin = float(dv_lines(sl2)["E"]) - 0.8
			elif sl2 >= isl0 and sl2 <= sn: tin = (-10.2 + float(dv_lines(sl2)["kl"])) * 0.5
			props.add("prop_lamp_cobra", "worn", RG._P(ctx, sl2, tin), RG._yaw(ap.normal(sl2)))
		sl += 40.0
	if L - 60.0 > s0 and L - 60.0 < s1:
		props.add("prop_sign_speed", "worn", RG._P(ctx, L - 60.0, -11.0), RG._yaw(ap.tangent(L - 60.0)))
	# ---------------------------------------------------------------- wear
	var yrr: Array = RG._yfns(ctx)
	for ln: float in [3.8, 7.4, -3.8, -7.4]: RG._lane_wear(dec, rr, ctx, ln, s0, s1, yrr[0], 0.35)
	RG._cracks(dec, rr, ctx, -9.0, 9.0, s0 + 1.0, s1 - 1.0, int((s1 - s0) / 12.0), yrr[0], 0.5)
	var site := {"site": "bridge approach", "kind": "hero", "pos": [o.x, appr_y(s0, s_start), o.y], "yaw": 0.0, "s": [s0, s1]}
	RG._finish(root, g, props, dec, name, {"rg": site})

## ======================================================================================================= the off-ramp
## The one-way off-ramp from the nose to 3rd St (ramp_path(): R 222 / 220 m arcs, then 40 m straight onto the ring),
## +s_r toward the ring, +t_r = the driver's right (the outer side). One 4 m lane with a 0.6 m left / 1.0 m right
## shoulder, widening smoothly over the last 70 m to the two 3.6 m lanes the 3rd St mouth has (kerbs at 4.5): the
## right-turn lane opens on the right; centre line solid for the last 30 m. Its start is the approach's nose line (a
## slanted cut in the ramp's frame: each lateral line starts where it crosses the approach normal at the nose station).
## Left kerb: the approach's nose island carries it for the island's 25 m, then the ramp's own kerb + verge. Height: the
## approach's height at the nose, held level for 12 m (the slanted start meets the approach exactly), smoothstep down to
## 3rd St's 2.0 m pad. Grass verges, cobra lamps on the outer verge every 40 m, a 25 mph sign after the nose; the 3rd St
## mouth's walks carry on 15 m along the ramp and end in rounded caps (park paths join them later).
const WIDEN := 70.0
const RAMP_PARTS := 110.0

static func ramp_start_s(tr: float) -> float:
	var key := "rs%.4f" % tr
	if _cache.has(key): return _cache[key]
	var ap := approach_path(); var rp := ramp_path()
	var sn := nose_s()
	var lo := 0.0; var hi := 200.0
	for it in 60:
		var mid := (lo + hi) * 0.5
		if ap.project(rp.at(mid, tr)).x > sn: lo = mid
		else: hi = mid
	_cache[key] = (lo + hi) * 0.5
	return _cache[key]

static func ramp_end_s() -> float:
	if _cache.has("rend"): return _cache["rend"]
	var R := NW.prepare()
	var nd: Dictionary = R["nodes"]["660.0,-1400.0"]
	var te := RG._tgeom(R["path"], nd["o"], float(nd["s"]), east_dir("660.0,-1400.0"), "ramp", true)
	_cache["rend"] = ramp_path().length - float(te["z_E"])
	return _cache["rend"]

static func ramp_parts() -> Array:
	if _cache.has("rparts"): return _cache["rparts"]
	var a := ramp_start_s(-2.6); var b := ramp_end_s()
	var n := maxi(1, ceili((b - a) / RAMP_PARTS))
	var out: Array = []
	for i in n: out.append(["s_br_ramp_%d" % (i + 1), lerpf(a, b, float(i) / n), lerpf(a, b, float(i + 1) / n)])
	_cache["rparts"] = out
	return out

static func ramp_y(sr: float) -> float:
	var parts := ramp_parts()
	var a: float = float(parts[0][1]) + 12.0; var b := ramp_end_s()
	var y0 := appr_y(nose_s(), float(approach_parts()[0][1]))
	return y0 + (RAMP_PAD - y0) * RG._ss(clampf((sr - a) / (b - a), 0.0, 1.0))

## lateral lines of the ramp at s_r: [left kerb, left lane edge, right lane edge, right kerb]
static func ramp_lines(sr: float) -> Array:
	var e := ramp_end_s()
	var f := RG._ss(clampf((sr - (e - WIDEN)) / WIDEN, 0.0, 1.0))
	var ll := lerpf(-2.0, -3.6, f); var rl := lerpf(2.0, 3.6, f)
	return [ll - lerpf(0.6, 0.9, f), ll, rl, rl + lerpf(1.0, 0.9, f)]

static func build_ramp(part: int) -> void:
	S.hill_on = false
	var parts := ramp_parts()
	var pl: Array = parts[part - 1]
	var name: String = pl[0]; var s0: float = pl[1]; var s1: float = pl[2]
	var rp := ramp_path(); var ap := approach_path()
	var o := rp.point(s0); var oy := ramp_y(s0)
	var ys := func(s: float) -> float: return ramp_y(s) - oy
	var ctx := RG._ctx(rp, o, ys)
	var root := Node3D.new(); root.name = name
	var g := K.Ground.new(); var props := K.Props.new(); var dec := K.Decals.new(); var rr := W.rng_for(name)
	var e := ramp_end_s()
	var sn := nose_s()
	var first := part == 1
	# where the approach's nose island stops carrying the left kerb (its end, approach station sn - 25)
	var lo := 0.0; var hi := 300.0
	for it in 60:
		var mid := (lo + hi) * 0.5
		if ap.project(rp.at(mid, -2.6)).x > sn - 25.0: lo = mid
		else: hi = mid
	var s_isl := (lo + hi) * 0.5
	var s_cl := e - 30.0                                          # centre line from here (solid)
	var s_walk := e - 15.0
	for x: float in [s_isl, s_cl, s_walk, e - WIDEN]: (ctx["extra"] as Array).append(x)
	RG._finalize(ctx, s0, s1)
	var sc: Array = []
	for v: float in RG._sub(ctx, s0, s1): sc.append(v)
	# per lateral line its own start on the nose line (slanted) in the first part
	var line_t := func(sr: float) -> Array:
		var L: Array = ramp_lines(sr)
		var lk: float = L[0]; var le: float = L[1]; var re: float = L[2]; var rk: float = L[3]
		var cl := sr >= s_cl
		return [lk, le, le + 0.12, (-0.06 if cl else 0.0), (0.06 if cl else 0.0), re - 0.12, re, rk]
	var mats := ["asphalt", "white", "asphalt", "white", "asphalt", "white", "asphalt"]
	for j in sc.size() - 1:
		var sa: float = sc[j]; var sb: float = sc[j + 1]
		var ta: Array = line_t.call(sa); var tb: Array = line_t.call(sb)
		for b in 7:
			var a0 := sa; var a1 := sa
			if first and j == 0:      # the slanted start: each line starts on the approach's nose line
				a0 = maxf(sa, ramp_start_s(float(ta[b]))); a1 = maxf(sa, ramp_start_s(float(ta[b + 1])))
			var quad := PackedVector2Array([Vector2(float(ta[b]), a0), Vector2(float(tb[b]), sb), Vector2(float(tb[b + 1]), sb), Vector2(float(ta[b + 1]), a1)])
			_fill(g, ctx, quad, String(mats[b]), 0.0, true)
	# kerbs + verges: right side the whole way; left side after the island
	var rk_pts: Array = []; var lk_pts: Array = []
	for v2: float in sc:
		var L2: Array = ramp_lines(v2)
		var s_r := v2
		if first and v2 == float(sc[0]): s_r = ramp_start_s(float(L2[3]))
		rk_pts.append(Vector2(float(L2[3]), s_r))
		if v2 >= s_isl: lk_pts.append(Vector2(float(L2[0]), v2))
	_kerb_ts(g, ctx, rk_pts, Vector2(-0.5, 0.0))
	if lk_pts.size() > 1: _kerb_ts(g, ctx, lk_pts, Vector2(0.5, 0.0))
	for j2 in sc.size() - 1:
		var sa2: float = sc[j2]; var sb2: float = sc[j2 + 1]
		var La: Array = ramp_lines(sa2); var Lb: Array = ramp_lines(sb2)
		var ra0 := sa2
		if first and j2 == 0: ra0 = ramp_start_s(float(La[3]))
		var vr := PackedVector2Array([Vector2(float(La[3]), ra0), Vector2(float(Lb[3]), sb2), Vector2(float(Lb[3]) + 1.5, sb2), Vector2(float(La[3]) + 1.5, maxf(ra0, ramp_start_s(float(La[3]) + 1.5)) if first and j2 == 0 else sa2)])
		_fill(g, ctx, vr, "grass", RG.KH, true)
		if sa2 >= s_isl - 1e-3:
			var vl := PackedVector2Array([Vector2(float(La[0]) - 1.5, sa2), Vector2(float(Lb[0]) - 1.5, sb2), Vector2(float(Lb[0]), sb2), Vector2(float(La[0]), sa2)])
			_fill(g, ctx, vl, "grass", RG.KH, true)
		# the 3rd St walks carry on 15 m along the ramp (verge to 6.0, walk 6.0 - 8.0 as the mouth has them)
		if sb2 > s_walk:
			var w0 := maxf(sa2, s_walk)
			for side: float in [-1.0, 1.0]:
				var ki := 4.5 * side
				var kp := PackedVector2Array([Vector2(side * 6.0, w0), Vector2(side * 6.0, sb2), Vector2(side * 8.0, sb2), Vector2(side * 8.0, w0)])
				_fill(g, ctx, kp, "concrete", RG.KH, true)
				var gp := PackedVector2Array([Vector2(float(La[3 if side > 0 else 0]) + side * 1.5, w0), Vector2(float(Lb[3 if side > 0 else 0]) + side * 1.5, sb2), Vector2(side * 6.0, sb2), Vector2(side * 6.0, w0)])
				_fill(g, ctx, gp, "grass", RG.KH, true)
	if s0 <= s_walk and s1 > s_walk:
		for side2: float in [-1.0, 1.0]:
			var cap := _half_disc(Vector2(side2 * 7.0, s_walk), 1.0, -1.0)
			var cp := PackedVector2Array()
			for q: Vector2 in cap: cp.append(q)
			_fill(g, ctx, cp, "concrete", RG.KH, false)
	# furniture
	var sl := ceilf(s0 / 40.0) * 40.0
	while sl < s1:
		if sl > float(parts[0][1]) + 10.0:
			var L3: Array = ramp_lines(sl)
			props.add("prop_lamp_cobra", "worn", RG._P(ctx, sl, float(L3[3]) + 0.8), RG._yaw(-rp.normal(sl)))
		sl += 40.0
	var s_sign := float(parts[0][1]) + 25.0
	if s_sign >= s0 and s_sign < s1:
		props.add("prop_sign_speed", "worn", RG._P(ctx, s_sign, float(ramp_lines(s_sign)[3]) + 0.8), RG._yaw(-rp.tangent(s_sign)))
	# wear
	var yrr: Array = RG._yfns(ctx)
	RG._lane_wear(dec, rr, ctx, 0.0, maxf(s0, float(parts[0][1]) + 2.0), minf(s1, e - WIDEN), yrr[0], 0.35)
	RG._cracks(dec, rr, ctx, -1.8, 1.8, s0 + 2.0, s1 - 1.0, int((s1 - s0) / 15.0), yrr[0], 0.5)
	var site := {"site": "bridge off-ramp", "kind": "hero", "pos": [o.x, ramp_y(s0), o.y], "yaw": 0.0, "s": [s0, s1]}
	RG._finish(root, g, props, dec, name, {"rg": site})
