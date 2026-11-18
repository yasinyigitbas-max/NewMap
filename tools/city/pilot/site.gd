extends RefCounted
## Pilot site Amber Ave x 10th St: shared dimensions and the hill (see map_dc/coronado/city_kit/PILOT_DESIGN.md).
## Local frame: origin = junction centre, X east along 10th, -Z north along Amber, Y up.

const KitLib := preload("res://tools/city/pilot/kit_lib.gd")

# Amber Ave (divided) half-section
const A_MED := 2.5        # median half width
const A_LANE := 9.1       # outer edge of the two traffic lanes
## Kerb lines are static vars (not const) so a piece can use another cross-section: the city centre has no parking
## lane, its kerb sits on the lane edge and the sidewalk is 2.4 m wider. A piece that changes them sets them at the
## start of its own script; the defaults are the pilot's (locked pieces were built with these values).
static var A_KERB := 11.5      # kerb line (parking lane 9.1 - 11.5)
const A_BLD := 16.0       # building line downtown
# 10th St half-section
const T_LANE := 3.3
static var T_KERB := 5.7
const T_BLD := 9.7        # downtown building line
const T_PARKWAY := 7.7    # residential: grass parkway 5.7 - 7.7
const T_PROP := 9.2       # residential property line (sidewalk 7.7 - 9.2)
# junction
const R_CORNER := 6.0
const XW_A := [12.5, 15.5]     # crosswalk across Amber, |z| range
const STOP_A := [16.7, 17.3]   # stop bar on Amber approaches, |z|
const XW_T := [18.3, 21.3]     # crosswalk across 10th, |x| range
const STOP_T := [22.5, 23.1]
const J_Z := 17.5              # junction tile reaches |z| <= 17.5 on Amber
const J_X := 23.5              # and |x| <= 23.5 on 10th
const KERB_H := 0.15
# alleys (6 m service lanes behind the downtown shops, parallel to Amber)
const ALLEY_W := [-50.0, -44.0]
const ALLEY_E := [44.0, 50.0]
const RES_X0 := 56.0           # residential lots start east of the east alley
# hill on 10th St east: level to x = 40, smoothstep to +HILL_H at x = 150 (max grade 8 %)
const HILL_X0 := 40.0
const HILL_X1 := 150.0
const HILL_H := 5.9

## pieces of flat clusters (city centre sample) switch the hill off before they build anything
static var hill_on := true

static func hill(x: float) -> float:
	if not hill_on: return 0.0
	var t := clampf((x - HILL_X0) / (HILL_X1 - HILL_X0), 0.0, 1.0)
	return HILL_H * t * t * (3.0 - 2.0 * t)

## street surface height at (x, z): the hill only depends on x
static func road_y(x: float, _z := 0.0) -> float:
	return hill(x)

static func walk_y(x: float, _z := 0.0) -> float:
	return hill(x) + KERB_H

## A straight sidewalk strip next to a kerb, with directional kerb ramps.
## along = "z": kerb at x = kerb, sidewalk spans x from kerb to outer, strip runs z from s0 to s1.
## along = "x": kerb at z = kerb, sidewalk spans z from kerb to outer, strip runs x from s0 to s1.
## ramps: Array of [centre s, width]. Ramp run 1.8 m (8.3 %), flares 1.2 m, tactile strip 0.6 m at the bottom.
## Draws the walking surface (concrete / tactile) and the kerb face (curb). mat = surface material.
static func sidewalk_strip(g: KitLib.Ground, along: String, kerb: float, outer: float, s0: float, s1: float, ramps: Array, mat := "concrete", RUN := 1.8, FLARE := 1.2, TACT := 0.6) -> void:
	var depth := absf(outer - kerb); var dir := signf(outer - kerb)
	# split [s0, s1] into flat runs and ramp zones
	var zones: Array = []   # [a, b, ramp or null]
	var cur := s0
	var rs := ramps.duplicate(); rs.sort_custom(func(p: Array, q: Array) -> bool: return p[0] < q[0])
	for r: Array in rs:
		var a: float = r[0] - r[1] * 0.5 - FLARE; var b: float = r[0] + r[1] * 0.5 + FLARE
		a = maxf(a, s0); b = minf(b, s1)
		if a > cur: zones.append([cur, a, null])
		zones.append([a, b, r]); cur = b
	if cur < s1: zones.append([cur, s1, null])
	var pt := func(s: float, t: float, y: float) -> Vector3:
		return Vector3(kerb + dir * t, y, s) if along == "z" else Vector3(s, y, kerb + dir * t)
	for zn: Array in zones:
		var a: float = zn[0]; var b: float = zn[1]
		if zn[2] == null:
			if along == "z": g.rect(mat, minf(kerb, outer), a, maxf(kerb, outer), b, walk_y)
			else: g.rect(mat, a, minf(kerb, outer), b, maxf(kerb, outer), walk_y)
			# kerb face, full height
			var p0 := Vector2(kerb, a) if along == "z" else Vector2(a, kerb)
			var p1 := Vector2(kerb, b) if along == "z" else Vector2(b, kerb)
			g.wall_line("curb", PackedVector2Array([p0, p1]), road_y, walk_y, -dir if along == "z" else dir)
			continue
		var r: Array = zn[2]; var c: float = r[0]; var w: float = r[1]
		var drop := func(s: float, t: float) -> float:
			var ft := clampf(1.0 - t / RUN, 0.0, 1.0)
			var ds := absf(s - c) - w * 0.5
			var fs := 1.0 if ds <= 0.0 else clampf(1.0 - ds / FLARE, 0.0, 1.0)
			return KERB_H * ft * fs
		var ns := maxi(2, ceili((b - a) / 0.3)); var nt := maxi(2, ceili(depth / 0.3))
		for i in ns:
			for j in nt:
				var sa := lerpf(a, b, float(i) / ns); var sb := lerpf(a, b, float(i + 1) / ns)
				var ta := depth * float(j) / nt; var tb := depth * float(j + 1) / nt
				var yv := func(s: float, t: float) -> float:
					var p: Vector3 = pt.call(s, t, 0.0)
					return walk_y(p.x, p.z) - drop.call(s, t)
				var sm := (sa + sb) * 0.5; var tmid := (ta + tb) * 0.5
				var m := mat
				if tmid < TACT and absf(sm - c) < w * 0.5: m = "tactile"
				g.quad(m, pt.call(sa, ta, yv.call(sa, ta)), pt.call(sb, ta, yv.call(sb, ta)), pt.call(sb, tb, yv.call(sb, tb)), pt.call(sa, tb, yv.call(sa, tb)))
		# kerb face with its top lowered by the ramp
		var kp := PackedVector2Array()
		for i in ns + 1:
			var s := lerpf(a, b, float(i) / ns)
			kp.append(Vector2(kerb, s) if along == "z" else Vector2(s, kerb))
		var top := func(x: float, z: float) -> float:
			var s := z if along == "z" else x
			return walk_y(x, z) - drop.call(s, 0.0)
		g.wall_line("curb", kp, road_y, top, -dir if along == "z" else dir)

## A sidewalk strip with tree wells in its furniture zone (16 Nov, Yasin: "trees grow out of the cement"): drawing the
## full strip and then a well on top hides the well's sunken soil under the slab. This leaves the 1.5 m well cells out
## of the strip: per well, the kerb face, the well cell (kerb .. kerb + 1.5) and the rest of the sidewalk beside it.
## wells: Array of centres along the strip (s); the trunk goes at kerb + 0.75 (sign of outer - kerb).
static func sidewalk_with_wells(g: KitLib.Ground, along: String, kerb: float, outer: float, s0: float, s1: float, ramps: Array, wells: Array, mat := "concrete", RUN := 1.8, FLARE := 1.2, TACT := 0.6) -> void:
	var dir := signf(outer - kerb)
	var ws := wells.duplicate(); ws.sort()
	var cur := s0
	for w: float in ws:
		var a := w - 0.75; var b := w + 0.75
		var rs: Array = []
		for r: Array in ramps:
			if float(r[0]) > cur and float(r[0]) < a: rs.append(r)
		if a > cur: sidewalk_strip(g, along, kerb, outer, cur, a, rs, mat, RUN, FLARE, TACT)
		var c := Vector2(kerb + dir * 0.75, w) if along == "z" else Vector2(w, kerb + dir * 0.75)
		tree_well(g, c)
		var k1 := kerb + dir * 1.5
		if along == "z": g.rect(mat, minf(k1, outer), a, maxf(k1, outer), b, walk_y)
		else: g.rect(mat, a, minf(k1, outer), b, maxf(k1, outer), walk_y)
		var p0 := Vector2(kerb, a) if along == "z" else Vector2(a, kerb)
		var p1 := Vector2(kerb, b) if along == "z" else Vector2(b, kerb)
		g.wall_line("curb", PackedVector2Array([p0, p1]), road_y, walk_y, -dir if along == "z" else dir)
		cur = b
	var rs2: Array = []
	for r: Array in ramps:
		if float(r[0]) > cur: rs2.append(r)
	if s1 > cur: sidewalk_strip(g, along, kerb, outer, cur, s1, rs2, mat, RUN, FLARE, TACT)

## Round tree well cut into a sidewalk cell: square cell (half size a) at walk level with a circular opening (radius r)
## down to soil 6 cm below, rim face in kerb concrete. The trunk goes in the centre.
static func tree_well(g: KitLib.Ground, c: Vector2, a := 0.75, r := 0.6) -> void:
	var n := 24
	var wy := walk_y(c.x, c.y); var sy := wy - 0.06
	for k in n:
		var t0 := TAU * k / n; var t1 := TAU * (k + 1) / n
		var d0 := Vector2(cos(t0), sin(t0)); var d1 := Vector2(cos(t1), sin(t1))
		var c0 := c + d0 * r; var c1 := c + d1 * r
		var s0 := c + d0 * (a / maxf(absf(d0.x), absf(d0.y))); var s1 := c + d1 * (a / maxf(absf(d1.x), absf(d1.y)))
		g.quad("concrete", Vector3(c0.x, wy, c0.y), Vector3(c1.x, wy, c1.y), Vector3(s1.x, wy, s1.y), Vector3(s0.x, wy, s0.y))
		g.tri("mulch", Vector3(c.x, sy, c.y), Vector3(c0.x, sy, c0.y), Vector3(c1.x, sy, c1.y))
		var inward := Vector3(-(d0.x + d1.x), 0, -(d0.y + d1.y))
		g.quad("curb", Vector3(c0.x, sy, c0.y), Vector3(c1.x, sy, c1.y), Vector3(c1.x, wy, c1.y), Vector3(c0.x, wy, c0.y), inward, true)

## Sidewalk along Amber (runs in z) with round tree wells in the furniture zone (first 1.5 m from the kerb).
## wells: Array of z centres. Kerb face included. sx = side (-1 west, +1 east).
static func amber_sidewalk(g: KitLib.Ground, sx: float, z0: float, z1: float, wells: Array, outer := A_BLD) -> void:
	var k := sx * A_KERB; var f := sx * (A_KERB + 1.5); var o := sx * outer
	var zs := wells.duplicate(); zs.sort()
	var cur := z0
	for wz: float in zs:
		g.rect("concrete", minf(k, f), cur, maxf(k, f), wz - 0.75, walk_y)
		tree_well(g, Vector2(sx * (A_KERB + 0.75), wz))
		cur = wz + 0.75
	g.rect("concrete", minf(k, f), cur, maxf(k, f), z1, walk_y)
	g.rect("concrete", minf(f, o), z0, maxf(f, o), z1, walk_y)
	g.wall_line("curb", PackedVector2Array([Vector2(k, z0), Vector2(k, z1)]), road_y, walk_y, -sx)

## kinds "left" / "right": a turn-only arrow (shaft, then the arm and head at the far end).
## SMOOTH arrow marking (16 Nov, Yasin: "make the road arrows smooth instead of being jagged"): the arrow is an exact
## polygon. Returns {"box": [x0, z0, x1, z1], "poly": PackedVector2Array, "axis": "x"|"z", "c": float}. The caller
## puts box + "-" FIRST in its painted_rect paints (a hole in the asphalt), then after painted_rect calls
## KitLib.fill_arrow(g, it, yfn): the arrow in white and the asphalt around it fill the hole exactly - one plane,
## nothing lifted, no stair-steps. kind: "through", "left", "left_through", "through_right" (left/right as seen by the
## driver moving from zt to zh along z; moving +z the driver's left is +x). along_x: the arrow runs along x instead
## (cx is then its z; the transposition mirrors it, so callers swap left/right as with arrow()). scale: size factor.
static func arrow2(kind: String, cx: float, zt: float, zh: float, along_x := false, scale := 1.0) -> Dictionary:
	var dz := signf(zh - zt); var L := absf(zh - zt)
	var sw := 0.08 * scale; var hw := 0.45 * scale; var hl := 1.2 * scale
	var poly := PackedVector2Array()
	if kind == "left" or kind == "right":
		poly = PackedVector2Array([Vector2(cx - sw, zt), Vector2(cx + sw, zt), Vector2(cx + sw, zh), Vector2(cx - sw, zh)])
	else:
		var hb := zh - dz * hl
		poly = PackedVector2Array([Vector2(cx - sw, zt), Vector2(cx - sw, hb), Vector2(cx - hw, hb), Vector2(cx, zh), Vector2(cx + hw, hb), Vector2(cx + sw, hb), Vector2(cx + sw, zt)])
	if kind != "through":
		var side := dz if (kind == "left_through" or kind == "left") else -dz
		var wb2 := zh if (kind == "left" or kind == "right") else zt + dz * L * 0.45
		var wb1 := wb2 - dz * 0.16 * scale
		var zc := (wb1 + wb2) * 0.5
		var x1 := cx + side * (0.08 + 0.55) * scale; var tip := x1 + side * 0.75 * scale   # tip 1.38 m off the shaft: stays inside a 3.3 m lane
		var ah := 0.4 * scale
		var arm := PackedVector2Array([Vector2(cx, wb1), Vector2(x1, wb1), Vector2(x1, zc - ah * dz), Vector2(tip, zc), Vector2(x1, zc + ah * dz), Vector2(x1, wb2), Vector2(cx, wb2)])
		var merged := Geometry2D.merge_polygons(poly, arm)
		var best := PackedVector2Array()
		for m: PackedVector2Array in merged:
			if m.size() > best.size(): best = m
		poly = best
	var x0 := INF; var z0 := INF; var x1b := -INF; var z1b := -INF
	for p in poly:
		x0 = minf(x0, p.x); z0 = minf(z0, p.y); x1b = maxf(x1b, p.x); z1b = maxf(z1b, p.y)
	var box := [x0 - 0.15, z0 - 0.15, x1b + 0.15, z1b + 0.15]
	var axis := "x"     # split line through the shaft: x = cx (a vertical line in this frame)
	if along_x:
		var t := PackedVector2Array()
		for p in poly: t.append(Vector2(p.y, p.x))
		poly = t; box = [box[1], box[0], box[3], box[2]]; axis = "z"
	return {"box": box, "poly": poly, "axis": axis, "c": cx}

## Arrow paint made of rectangles only (so it cuts exactly into the asphalt). Lane centre cx, tail at zt, head at zh
## (the arrow points from zt to zh). kind: "through", "left_through", "through_right". left/right are seen by the
## driver moving from zt to zh.
static func arrow(kind: String, cx: float, zt: float, zh: float) -> Array:
	var out: Array = []
	var dz := signf(zh - zt); var L := absf(zh - zt)
	var lo := func(a: float, b: float) -> float: return minf(a, b)
	var hi := func(a: float, b: float) -> float: return maxf(a, b)
	var head := 1.2; var steps := 6
	var shaft_end := zh - dz * head
	out.append([cx - 0.08, lo.call(zt, shaft_end), cx + 0.08, hi.call(zt, shaft_end), "white"])
	for i in steps:
		var w := 0.45 * (1.0 - float(i) / steps)
		var za := shaft_end + dz * head * float(i) / steps; var zb := shaft_end + dz * head * float(i + 1) / steps
		out.append([cx - w, lo.call(za, zb), cx + w, hi.call(za, zb), "white"])
	if kind != "through":
		# driver's left when moving +z is +x; moving -z it is -x
		var side := (dz if kind == "left_through" else -dz)
		var zb2 := zt + dz * L * 0.45; var zb1 := zb2 - dz * 0.16
		var arm := 0.9
		var x0 := cx + side * 0.08; var x1 := cx + side * (0.08 + arm)
		out.append([lo.call(x0, x1), lo.call(zb1, zb2), hi.call(x0, x1), hi.call(zb1, zb2), "white"])
		var zc := (zb1 + zb2) * 0.5
		for i in steps:
			var w2 := 0.4 * (1.0 - float(i) / steps)
			var xa := x1 + side * 0.9 * float(i) / steps; var xb := x1 + side * 0.9 * float(i + 1) / steps
			out.append([lo.call(xa, xb), zc - w2, hi.call(xa, xb), zc + w2, "white"])
	return out

## Residential lots on the hill (15 m frontage, x0 = west edge). side -1 = north of 10th (houses face south),
## +1 = south (houses face north). hx = house centre x. drive = driveway centre x (3 m wide) or -1 for none
## (that house parks on the street). garage = detached garage / carport at the back of the driveway, "" if the
## house has its own garage door (the driveway then lines up with that door).
const LOTS := [
	{"side": -1, "x0": 56.0, "house": "houses/craftsman_cedar", "hx": 61.5, "drive": 68.5, "garage": "garages/single_siding_comp", "fence": "picket"},
	{"side": -1, "x0": 71.0, "house": "houses/hipranch_grey", "hx": 78.5, "drive": 74.2, "garage": "", "fence": ""},
	{"side": -1, "x0": 86.0, "house": "houses/beach_blue", "hx": 91.5, "drive": 97.5, "garage": "garages/carport_comp", "fence": "picket"},
	{"side": -1, "x0": 101.0, "house": "houses/mcm_teal", "hx": 108.5, "drive": 112.95, "garage": "", "fence": ""},
	{"side": -1, "x0": 116.0, "house": "houses/spanish_white", "hx": 123.5, "drive": -1.0, "garage": "", "fence": "iron"},
	{"side": -1, "x0": 131.0, "house": "houses/victorian_yellow", "hx": 136.5, "drive": 143.5, "garage": "garages/single_stucco_comp", "fence": "picket"},
	{"side": 1, "x0": 56.0, "house": "houses/ranch_peach", "hx": 61.8, "drive": 69.2, "garage": "garages/single_stucco_comp", "fence": ""},
	{"side": 1, "x0": 71.0, "house": "houses/colonial_large_garage", "hx": 78.5, "drive": 74.3, "garage": "", "fence": "picket"},
	{"side": 1, "x0": 86.0, "house": "houses/craftsman_sage", "hx": 91.2, "drive": 98.0, "garage": "garages/single_stucco_comp", "fence": ""},
	{"side": 1, "x0": 101.0, "house": "houses/hipranch_sand", "hx": 108.5, "drive": 104.7, "garage": "", "fence": ""},
	{"side": 1, "x0": 116.0, "house": "houses/tudor_stucco", "hx": 123.5, "drive": -1.0, "garage": "", "fence": "iron"},
	{"side": 1, "x0": 131.0, "house": "houses/beach_teal", "hx": 136.0, "drive": 143.0, "garage": "garages/carport_clay", "fence": "picket"},
]
const LOT_W := 15.0
const LOT_D := 42.0      # lot depth from the property line
const SETBACK := 6.0     # front yard depth


## Row variants (city3, 16 Nov): same lot lines and driveway positions as LOTS (so one street piece fits every
## variant), different houses / garages / fences. B and C east of Amber (hill), WA and WB west of Amber (flat; x0 is the
## lot's west edge, drives mirrored). Picked once by a small script (widest kit house without its own garage that fits
## beside the driveway, no repeat in a row or with the row it faces); frozen here.
const LOTS_B := [
	{"side": -1, "x0": 56.0, "house": "houses/ranch_pink", "hx": 61.55, "drive": 68.5, "garage": "garages/carport_comp", "fence": ""},
	{"side": -1, "x0": 71.0, "house": "houses/spanish_small", "hx": 80.8, "drive": 74.2, "garage": "garages/single_siding_comp", "fence": "iron"},
	{"side": -1, "x0": 86.0, "house": "houses/narrow_2sty_siding", "hx": 91.05, "drive": 97.5, "garage": "garages/double_stucco_comp", "fence": ""},
	{"side": -1, "x0": 101.0, "house": "houses/beach_teal", "hx": 106.28, "drive": 112.95, "garage": "garages/carport_clay", "fence": "picket"},
	{"side": -1, "x0": 116.0, "house": "houses/tudor_stucco", "hx": 123.5, "drive": -1, "garage": "", "fence": ""},
	{"side": -1, "x0": 131.0, "house": "houses/beach_white", "hx": 136.55, "drive": 143.5, "garage": "garages/single_stucco_clay", "fence": "picket"},
	{"side": 1, "x0": 56.0, "house": "houses/craftsman_olive", "hx": 61.9, "drive": 69.2, "garage": "garages/carport_comp", "fence": ""},
	{"side": 1, "x0": 71.0, "house": "houses/beach_blue", "hx": 80.85, "drive": 74.3, "garage": "garages/single_siding_comp", "fence": "iron"},
	{"side": 1, "x0": 86.0, "house": "houses/narrow_2sty_stucco_clay", "hx": 91.3, "drive": 98.0, "garage": "garages/double_stucco_comp", "fence": ""},
	{"side": 1, "x0": 101.0, "house": "houses/narrow_cottage_siding", "hx": 111.05, "drive": 104.7, "garage": "garages/carport_clay", "fence": "picket"},
	{"side": 1, "x0": 116.0, "house": "houses/spanish_white", "hx": 123.5, "drive": -1, "garage": "", "fence": ""},
	{"side": 1, "x0": 131.0, "house": "houses/narrow_cottage_stucco_clay", "hx": 136.3, "drive": 143.0, "garage": "garages/single_stucco_clay", "fence": "picket"},
]

const LOTS_C := [
	{"side": -1, "x0": 56.0, "house": "houses/spanish_small", "hx": 61.55, "drive": 68.5, "garage": "garages/double_stucco_comp", "fence": ""},
	{"side": -1, "x0": 71.0, "house": "houses/beach_teal", "hx": 80.8, "drive": 74.2, "garage": "garages/carport_clay", "fence": "picket"},
	{"side": -1, "x0": 86.0, "house": "houses/narrow_2sty_stucco_clay", "hx": 91.05, "drive": 97.5, "garage": "garages/single_stucco_flat", "fence": ""},
	{"side": -1, "x0": 101.0, "house": "houses/narrow_2sty_siding", "hx": 106.28, "drive": 112.95, "garage": "garages/single_stucco_clay", "fence": "picket"},
	{"side": -1, "x0": 116.0, "house": "houses/tudor_brick", "hx": 123.5, "drive": -1, "garage": "", "fence": ""},
	{"side": -1, "x0": 131.0, "house": "houses/cape_grey", "hx": 136.55, "drive": 143.5, "garage": "garages/single_siding_comp", "fence": "iron"},
	{"side": 1, "x0": 56.0, "house": "houses/contemporary_white", "hx": 61.9, "drive": 69.2, "garage": "garages/double_stucco_comp", "fence": ""},
	{"side": 1, "x0": 71.0, "house": "houses/narrow_cottage_siding", "hx": 80.85, "drive": 74.3, "garage": "garages/carport_clay", "fence": "picket"},
	{"side": 1, "x0": 86.0, "house": "houses/narrow_cottage_stucco_clay", "hx": 91.3, "drive": 98.0, "garage": "garages/single_stucco_flat", "fence": ""},
	{"side": 1, "x0": 101.0, "house": "houses/beach_blue", "hx": 111.05, "drive": 104.7, "garage": "garages/single_stucco_clay", "fence": "picket"},
	{"side": 1, "x0": 116.0, "house": "houses/colonial_blue", "hx": 123.5, "drive": -1, "garage": "", "fence": ""},
	{"side": 1, "x0": 131.0, "house": "houses/beach_white", "hx": 136.3, "drive": 143.0, "garage": "garages/single_siding_comp", "fence": "iron"},
]

const LOTS_WA := [
	{"side": -1, "x0": -71.0, "house": "houses/beach_teal", "hx": -61.55, "drive": -68.5, "garage": "garages/single_siding_comp", "fence": "iron"},
	{"side": -1, "x0": -86.0, "house": "houses/narrow_2sty_stucco_clay", "hx": -80.8, "drive": -74.2, "garage": "garages/double_stucco_comp", "fence": ""},
	{"side": -1, "x0": -101.0, "house": "houses/spanish_small", "hx": -91.05, "drive": -97.5, "garage": "garages/carport_clay", "fence": "picket"},
	{"side": -1, "x0": -116.0, "house": "houses/beach_white", "hx": -106.28, "drive": -112.95, "garage": "garages/single_stucco_flat", "fence": ""},
	{"side": -1, "x0": -131.0, "house": "houses/colonial_blue", "hx": -123.5, "drive": -1.0, "garage": "", "fence": "picket"},
	{"side": -1, "x0": -146.0, "house": "houses/narrow_2sty_siding", "hx": -136.55, "drive": -143.5, "garage": "garages/carport_comp", "fence": ""},
	{"side": 1, "x0": -71.0, "house": "houses/cape_white", "hx": -61.9, "drive": -69.2, "garage": "garages/single_siding_comp", "fence": "iron"},
	{"side": 1, "x0": -86.0, "house": "houses/beach_blue", "hx": -80.85, "drive": -74.3, "garage": "garages/double_stucco_comp", "fence": ""},
	{"side": 1, "x0": -101.0, "house": "houses/narrow_cottage_siding", "hx": -91.3, "drive": -98.0, "garage": "garages/carport_clay", "fence": "picket"},
	{"side": 1, "x0": -116.0, "house": "houses/narrow_cottage_stucco_clay", "hx": -111.05, "drive": -104.7, "garage": "garages/single_stucco_flat", "fence": ""},
	{"side": 1, "x0": -131.0, "house": "houses/spanish_pink", "hx": -123.5, "drive": -1.0, "garage": "", "fence": "picket"},
	{"side": 1, "x0": -146.0, "house": "houses/beach_blue", "hx": -136.3, "drive": -143.0, "garage": "garages/carport_comp", "fence": ""},
]

const LOTS_WB := [
	{"side": -1, "x0": -71.0, "house": "houses/ranch_pink", "hx": -61.55, "drive": -68.5, "garage": "garages/single_stucco_flat", "fence": ""},
	{"side": -1, "x0": -86.0, "house": "houses/spanish_small", "hx": -80.8, "drive": -74.2, "garage": "garages/single_stucco_clay", "fence": "picket"},
	{"side": -1, "x0": -101.0, "house": "houses/narrow_2sty_siding", "hx": -91.05, "drive": -97.5, "garage": "garages/carport_comp", "fence": ""},
	{"side": -1, "x0": -116.0, "house": "houses/beach_teal", "hx": -106.28, "drive": -112.95, "garage": "garages/single_siding_comp", "fence": "iron"},
	{"side": -1, "x0": -131.0, "house": "houses/tudor_stucco", "hx": -123.5, "drive": -1.0, "garage": "", "fence": ""},
	{"side": -1, "x0": -146.0, "house": "houses/beach_white", "hx": -136.55, "drive": -143.5, "garage": "garages/carport_clay", "fence": "picket"},
	{"side": 1, "x0": -71.0, "house": "houses/craftsman_sage", "hx": -61.9, "drive": -69.2, "garage": "garages/single_stucco_flat", "fence": ""},
	{"side": 1, "x0": -86.0, "house": "houses/narrow_2sty_stucco_clay", "hx": -80.85, "drive": -74.3, "garage": "garages/single_stucco_clay", "fence": "picket"},
	{"side": 1, "x0": -101.0, "house": "houses/narrow_cottage_stucco_clay", "hx": -91.3, "drive": -98.0, "garage": "garages/carport_comp", "fence": ""},
	{"side": 1, "x0": -116.0, "house": "houses/beach_blue", "hx": -111.05, "drive": -104.7, "garage": "garages/single_siding_comp", "fence": "iron"},
	{"side": 1, "x0": -131.0, "house": "houses/tudor_brick", "hx": -123.5, "drive": -1.0, "garage": "", "fence": ""},
	{"side": 1, "x0": -146.0, "house": "houses/narrow_cottage_siding", "hx": -136.3, "drive": -143.0, "garage": "garages/carport_clay", "fence": "picket"},
]
