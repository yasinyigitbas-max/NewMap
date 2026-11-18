extends RefCounted
## =====================================================================================================================
## road_art.gd - the art family's road kit (17 Nov 2026, road kit groups 2-5): 3rd / 4th St (two-way arterials on the
## strip cross-section) and the Adela Ave strip side street, with their signalised junctions. Brief: map_dc/coronado/
## city_kit/ROADKIT_SPEC.md. Yasin, 17 Nov: "act like an architect, city planner and exterior designer, no jagged edges".
## Prefixes: j_ar_ (junctions), s_ar_ (legs), zz_art_ (preview-only ground). Integration table: review/art_sites.json;
## review rows: review/art.json (art area at grid (u, pad, v) + (3200, 0, -3000)). Never edits a shared helper: it CALLS
## road_lib (strip_z, red_kerb_z, lane_wear_y, RES_MIX, _pick_group), kit_lib, site, wear_lib, ind_lib, strip_lib's
## numbers are repeated here (measured, see below) so a later change to strip_lib can never move these pieces.
##
## ---------------------------------------------------------------------------------------------------------- THE PLAN
## What the family owns (review/sites.json, owner "art"): 11 junctions, 14 blocks (3rd St b065-b070, 4th St b073-b078,
## Adela b057 / b058). Piece list, sites, yaws and heights: review/art_sites.json (written by the planner with every
## piece script; the planner's reasons are copied into each script's header).
##
## 1. Cross-sections, MEASURED on the locked pieces (zz_art/measure.gd, 17 Nov), never assumed:
##    arterial (s_strip_art, leg along x from |x| 22): centre two-way left-turn lane, solid yellow edges at |t| 1.65-1.75
##      and dashed inner lines at 1.32-1.42; lane lines 5.24-5.36 (dashed, solid 15 m before the stop bar); bike lane
##      lines 8.72-8.88; kerb 10.3; fan palm parkway (grass) to 12.3; 2 m sidewalk to the property line 14.3.
##    strip side (s_strip_side, from |z| 26): double yellow 0.1-0.2, lanes 3.3, parking to the kerb at 5.7 (T marks),
##      3 m sidewalk with round tree wells to 8.7.
##    truck street (s_ind, from 22): double yellow, lane edge lines 4.14-4.26, shoulder to the kerb at 6.7, walk to 8.7.
##    residential / standard legs at OUR junctions (resstd family, its assumptions list): start at 26 (j_strip's side
##      street tile edge), kerb 5.7, grass parkway to 7.2, walk to 9.2; res has no centre line, std a double yellow.
## 2. Junctions (j_ar_*): every 3rd / 4th St crossing is SIGNALISED (an arterial crossing), j_strip's geometry: the
##    arterial runs along x (grid u: yaw 0 at every site), tile |x| <= 22 along it, |z| <= 26 along the cross street;
##    8 m kerb returns (14-segment arcs) at every corner - also into the truck street: a semi turning right swings out
##    of the 3.5 m outer lane across the 1.5 m bike lane into the 2.5 m shoulder, an effective radius over 12 m, so the
##    industrial 12 m kerb is not needed and the corner keeps the same crossing distance as the others.
##    - mast arms over the arterial on the far-right corners of its approaches (NW for westbound, SE for eastbound),
##      post heads for the cross street (NE for northbound, SW for southbound), street names on the post corners;
##    - every pole at r - 1 from its kerb return's centre (the centre lies inside the block: 1 m behind the kerb, on the
##      corner walk, never on the asphalt fillet - audit #1 was this sign error);
##    - continental crosswalks on all four mouths, two directional ramps per corner aimed at them, stop bars 1.2 m
##      behind; centre lines into the tile only where the cross street carries one (std, strip, truck);
##    - kerb inlets upstream of the crosswalks on every mouth that drains INTO the junction (a leg rising away: both
##      kerbs; a flat leg: the approach kerb; a leg falling away carries its water off, no inlet), grate to the road;
##    - hydrants on two diagonal corners on the departure kerbs (clear of inlets and ramps), cobra lamps on the two post
##      corners lighting the crosswalks, the corner dress of the district (below).
##    Adela x 5th St (j_ar_ad5) is the one odd junction: the strip spur of 5th St (ring family stub b087, the arterial
##    section from 22) meets Adela's strip side street and two residential streets; it is signalised too (an
##    arterial-section approach) with a mast arm for the 5th St approach only and posts for the three narrow ones.
## 3. Legs (s_ar_*), authored along +z from the junction tile edge, approach traffic on +x (drives -z), departure on -x:
##    - left-turn pocket in the centre lane for the first 30 m of each approach (white edge, two smooth arrows), the
##      two-way left-turn lane beyond it (dashed inner yellows); through / through-right arrows in the approach lanes;
##      smooth polygon arrows cut into the asphalt (site.arrow2 + kit_lib.fill_arrow): one plane, nothing lifted;
##    - dashes on a BLOCK-wide phase (3 m on / 9 m off for lanes, 3 / 6 for the turn lane): the two legs of a block meet
##      at the seam with their dashes continuing, never a half dash, never a jump;
##    - bike lane lines solid, dotted where cars cross them (driveway aprons, the bus zone); a small bike-lane arrow
##      after each junction for each direction;
##    - driveway aprons (dropped kerb, concrete through the palm parkway, the walk stays level) at standard places
##      (45 / 80 / 112-140 m) so the frontage lots line up; moved to 56 / 85 on the side with a bus stop;
##    - far-side bus stops in BOTH directions at the stop junctions (3rd St: E Ave, B Ave; 4th St: G Ave, C Ave, B Ave;
##      ~400 m apart with the strip sample's own stops and the industrial sample's): a 20 m zone with red kerb, a
##      concrete boarding pad through the parkway at the bus doors, the sign at the pad's front end, the bench at the
##      back of the walk facing the street 5 m behind the sign (nothing within 2.5 m of it), a bin, a lamp near;
##    - cobra lamps both sides staggered ~34 m, a hydrant mid-leg with its red kerb, 25 mph signs for departing traffic,
##      kerb inlets at the low end (silt fans where the runoff stops), manholes in the lanes, no utility poles (no wires
##      run along the arterials: power is in the alleys behind the frontage, where the block wire pieces put it);
##    - trees only in the grass parkway, never within 28 m of a junction centre (signal sight lines), never on aprons
##      or the bus pad, the district deciding the mix (Yasin: variety, no copy-paste):
##        grt   (west of E Ave, the gritty edge): fan and queen palms, a quarter of them died and left stumps, rusty
##              lamps, many cracks and patched slabs, litter grime in the gutters, a shopping cart dumped on the walk;
##        hill  (Crown Hill, C Ave to B Ave): road_lib RES_MIX (torrey pines, jacarandas, corals, magnolias, palms in
##              runs, young to mature), sealed cracks, root-lifted slabs, tidier;
##        strip (B Ave to Adela, toward the commercial strip): fan palms with some queens, heavy oil at the aprons.
##    - slopes: a block's rise is ONE smoothstep between the two junction tiles (any block length: 200 or 250 m), each
##      leg carries its half so both meet at the seam with equal height and grade; next to a locked sample (flat at
##      its pad) the whole rise is in our leg (b078 to the strip sample: 22..150 m; b057: 26..100 m). Steepest: 4th St
##      E Ave -> C Ave, 6 m over 156 m = 5.8 % (max grade 1.5 H / span); Yasin's limit 8 %.
##    - 3rd St west of G Ave (b065) becomes the industrial sample's truck street (s_ind, measured): between 50 and 90 m
##      the turn lane closes (its yellows converge smoothly to the double yellow), the outer lanes end into the truck
##      shoulder (the bike lane line becomes the edge line 4.2), the kerb moves 10.3 -> 6.7, the parkway narrows away
##      and the property line moves 14.3 -> 8.7, all on one smoothstep in 0.5 m slices: exact, no step, no jag.
##    Legs from the Amber junctions (amber family, not built yet) start at 23.5 (the pilot's cross-street tile edge
##    that the resstd family also assumed); if the amber family chooses another edge, change z0 in the script, rebuild.
## 4. Adela strip side legs (b057 AD3 -> strip sample, b058 Adela x 5th -> strip sample): s_strip_side's section with
##    recorded stalls (y and grade on the slope), wells with mixed species, pay stations by the hospital end (b057).
## =====================================================================================================================

const K := preload("res://tools/city/pilot/kit_lib.gd")
const S := preload("res://tools/city/pilot/site.gd")
const W := preload("res://tools/city/pilot/pieces/wear_lib.gd")
const I := preload("res://tools/city/pilot/pieces/ind_lib.gd")
const RL := preload("res://tools/city/pilot/pieces/road_lib.gd")

const KH := 0.15
# arterial (measured on s_strip_art)
const TL := 1.8
const L1 := 5.3
const L2 := 8.8
const KA := 10.3
const PKA := 12.3
const PRA := 14.3
const R := 8.0
const POCKET := 30.0
const APR_W := 9.0
# strip side street (measured on s_strip_side)
const LANE_S := 3.3
const KERB_S := 5.7
const PROP_S := 8.7
const SIDE_STALL := 6.7
const APR_S_W := 7.0
# truck street (measured on s_ind)
const KI := 6.7
const PI_ := 8.7
const LI := 4.2
# junction tile
const XW_S := [18.8, 21.8]
const STOP_S := [23.0, 23.6]
## cross-street sections at a junction mouth: kerb, parkway outer edge (= kerb: none), property line, lane, centre line
const MS := {
	"res": [5.7, 7.2, 9.2, 3.3, false],
	"std": [5.7, 7.2, 9.2, 3.3, true],
	"strip": [5.7, 5.7, 8.7, 3.3, true],
	"ind": [6.7, 6.7, 8.7, 4.2, true],
	"art": [10.3, 10.3, 14.3, 8.8, true],     # inside a junction tile the arterial walk is all concrete (sight lines)
}

static func ss(t: float) -> float:
	var u := clampf(t, 0.0, 1.0)
	return u * u * (3.0 - 2.0 * u)

static func _py(prof: Array, z: float) -> float:
	var v := 0.0
	for p: Array in prof: v += float(p[2]) * ss((z - float(p[0])) / (float(p[1]) - float(p[0])))
	return v

static func _pg(prof: Array, z: float) -> float:
	var v := 0.0
	for p: Array in prof:
		var d := float(p[1]) - float(p[0]); var t := (z - float(p[0])) / d
		if t > 0.0 and t < 1.0: v += float(p[2]) * 6.0 * t * (1.0 - t) / d
	return v

static func _free(taken: Array, z: float, d: float) -> bool:
	for t: Array in taken:
		if absf(z - float(t[0])) < d + float(t[1]): return false
	return true

## dashes on the BLOCK's phase (s from end a): period / dash length, clipped to [za, zb]; a dash cut only by the seam
## is kept (the other leg draws its other part), anything else cut is dropped (never a half dash at a solid line)
static func _dash(p: Array, xa: float, xb: float, za: float, zb: float, sp: Dictionary, period: float, dash: float, mat := "white", seam := false) -> void:
	var Lb: float = sp.Lb; var fb: bool = sp.from_b
	var s_lo := (Lb - zb) if fb else za; var s_hi := (Lb - za) if fb else zb
	var k := floori(s_lo / period) - 1
	while float(k) * period <= s_hi + period:
		var d0 := float(k) * period; var d1 := d0 + dash
		var z_a := (Lb - d1) if fb else d0; var z_b := (Lb - d0) if fb else d1
		var ca := maxf(z_a, za); var cb := minf(z_b, zb)
		if cb - ca > 0.08:
			var full := cb - ca > dash - 0.01
			var cut_at_seam := seam and absf(cb - zb) < 1e-3 and absf(ca - z_a) < 1e-3
			if full or cut_at_seam: p.append([xa, ca, xb, cb, mat])
		k += 1

## a line broken (1 m on, 1 m off) across the given zones, solid elsewhere
static func _broken_line(p: Array, xa: float, xb: float, za: float, zb: float, breaks: Array, mat := "white") -> void:
	var bs := breaks.duplicate(); bs.sort_custom(func(a: Array, b: Array) -> bool: return float(a[0]) < float(b[0]))
	var cur := za
	for br: Array in bs:
		var b0 := maxf(float(br[0]), za); var b1 := minf(float(br[1]), zb)
		if b1 <= cur: continue
		if b0 > cur: p.append([xa, cur, xb, b0, mat])
		var k := maxf(b0, cur)
		while k + 1.0 <= b1: p.append([xa, k, xb, k + 1.0, mat]); k += 2.0
		cur = b1
	if cur < zb: p.append([xa, cur, xb, zb, mat])

## crack marks no longer than 4 m (a flat decal must follow a curved slope)
static func _cracks(dec: K.Decals, rr: RandomNumberGenerator, x0: float, z0: float, x1: float, z1: float, n: int, yfn: Callable, sealed := 0.4) -> void:
	for i in n:
		var c := Vector2(rr.randf_range(x0, x1), rr.randf_range(z0, z1))
		var tint := Color(0.12, 0.12, 0.12, 0.95) if rr.randf() < sealed else Color(0.28, 0.27, 0.26, 0.9)
		dec.add(0, c, rr.randf_range(0, 360), rr.randf_range(2.4, 4.0), rr.randf_range(1.0, 1.8), yfn, tint, 0.012, rr.randf() < 0.5)

## round tree well on any height function: 1.5 m cell at walk level, a 0.6 m round opening down to soil 6 cm below,
## rim face in kerb concrete (site.gd tree_well only follows the pilot's x-hill)
static func _well(g: K.Ground, c: Vector2, yw: Callable, a := 0.75, r := 0.6) -> void:
	var n := 24
	for k in n:
		var t0 := TAU * k / n; var t1 := TAU * (k + 1) / n
		var d0 := Vector2(cos(t0), sin(t0)); var d1 := Vector2(cos(t1), sin(t1))
		var c0 := c + d0 * r; var c1 := c + d1 * r
		var s0 := c + d0 * (a / maxf(absf(d0.x), absf(d0.y))); var s1 := c + d1 * (a / maxf(absf(d1.x), absf(d1.y)))
		var y0: float = yw.call(c0.x, c0.y); var y1: float = yw.call(c1.x, c1.y)
		var ys0: float = yw.call(s0.x, s0.y); var ys1: float = yw.call(s1.x, s1.y); var yc: float = yw.call(c.x, c.y)
		g.quad("concrete", Vector3(c0.x, y0, c0.y), Vector3(c1.x, y1, c1.y), Vector3(s1.x, ys1, s1.y), Vector3(s0.x, ys0, s0.y))
		g.tri("mulch", Vector3(c.x, yc - 0.06, c.y), Vector3(c0.x, y0 - 0.06, c0.y), Vector3(c1.x, y1 - 0.06, c1.y))
		var inward := Vector3(-(d0.x + d1.x), 0, -(d0.y + d1.y))
		g.quad("curb", Vector3(c0.x, y0 - 0.06, c0.y), Vector3(c1.x, y1 - 0.06, c1.y), Vector3(c1.x, y1, c1.y), Vector3(c0.x, y0, c0.y), inward, true)

static func _finish(root: Node3D, g: K.Ground, props: K.Props, dec: K.Decals, name: String, msg: String) -> void:
	var wm := dec.build()
	if wm: root.add_child(wm)
	var mi := MeshInstance3D.new(); mi.name = "ground"; mi.mesh = g.build(); mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF; root.add_child(mi)
	var body := StaticBody3D.new(); body.name = "ground_col"; var cs := CollisionShape3D.new(); cs.shape = mi.mesh.create_trimesh_shape(); body.add_child(cs); root.add_child(body)
	props.build(root, K)
	print("%s: %s, ground tris %d, props %d" % [name, msg, g.tri_count(), props.count()])
	K.save_piece(root, name)


## ===================================================================================================== arterial legs
## art_leg(name, sp): one 3rd / 4th St leg along +z. sp:
##   z0, z1   start (junction tile edge: 22 ours, 23.5 Amber) and end (seam: mid-block; or a sample leg's end)
##   prof     [[p0, p1, h], ...] height profile in this leg's z (relative to the start junction's pad)
##   end      "seam" (the block's other leg), "strip_art" (the strip sample's s_strip_art at its x 100), "ind" (taper to
##            the industrial sample's s_ind)
##   Lb, from_b   the block's length and whether this leg starts at its end b (dash phase)
##   bus      a far-side stop for the departing traffic (-x side) right after the junction
##   apr      {-1.0: [...], 1.0: [...]} driveway apron centres per side
##   dress    "grt" | "hill" | "strip";  hyd: side of the hydrant (+1 / -1)
static func art_leg(name: String, sp: Dictionary) -> void:
	S.hill_on = false
	var root := Node3D.new(); root.name = name
	var g := K.Ground.new(); var props := K.Props.new(); var dec := K.Decals.new(); var rr := W.rng_for(name)
	var z0: float = sp.z0; var z1: float = sp.z1; var prof: Array = sp.prof
	var endk: String = sp.end; var dress: String = sp.dress
	var bus: bool = sp.get("bus", false)
	var yr := func(_x: float, z: float) -> float: return _py(prof, z)
	var yw := func(_x: float, z: float) -> float: return _py(prof, z) + KH
	var seam := endk == "seam"
	var taper := endk == "ind"
	var TA := 50.0; var TB := 90.0                       # the truck-street transition (b065 only)
	var zc := TA if taper else z1                        # end of the full arterial section
	var zp := minf(z0 + POCKET, zc)                      # left-turn pocket for the approach (+x) traffic
	var apr: Dictionary = sp.apr
	# ---- bus zone (departure side -x): 20 m from 2 m past the tile, boarding pad at the doors
	var bz0 := z0 + 2.0; var bz1 := z0 + 22.0
	var pad0 := bz1 - 9.5; var pad1 := bz1 - 0.6
	# ================================================================ carriageway paint (full arterial section)
	var p: Array = []; var arrows: Array = []
	p.append([-1.75, z0, -1.65, zc, "yellow"])                                  # departure edge of the centre lane: solid
	p.append([1.6, z0, 1.75, zp, "white"])                                      # the pocket's lane line (approach side)
	if zc > zp: p.append([1.65, zp, 1.75, zc, "yellow"])
	if zc - zp > 8.0:                                                           # two-way left-turn lane: dashed inner yellows
		_dash(p, -1.42, -1.32, zp + 6.0, zc, sp, 9.0, 3.0, "yellow", seam)
		_dash(p, 1.32, 1.42, zp + 6.0, zc, sp, 9.0, 3.0, "yellow", seam)
	# pocket arrows: the approach drives -z; its driver's left is -x (arrow2 "left" with zh < zt puts the arm on -x)
	for k: float in [6.0, 18.0]:
		if z0 + k + 4.5 < zp - 1.0: arrows.append(S.arrow2("left", 0.0, z0 + k + 4.5, z0 + k))
	arrows.append(S.arrow2("through", (TL + L1) * 0.5, z0 + 10.5, z0 + 6.0))
	arrows.append(S.arrow2("through_right", (L1 + L2) * 0.5, z0 + 10.5, z0 + 6.0))
	# bike lane arrows (MUTCD bike-lane arrow, small): departure after the bus zone / the tile, approach before the lane line goes solid
	var bka := (bz1 + 4.0) if bus else (z0 + 8.0)
	arrows.append(S.arrow2("through", -(L2 + KA) * 0.5, bka, bka + 2.6, false, 0.55))
	if z0 + 24.0 < zc - 3.0: arrows.append(S.arrow2("through", (L2 + KA) * 0.5, z0 + 24.0, z0 + 21.4, false, 0.55))
	# lane lines: approach solid for the last 15 m, dashed beyond; departure dashed from 6 m out
	p.append([L1 - 0.06, z0, L1 + 0.06, minf(z0 + 15.0, zc), "white"])
	_dash(p, L1 - 0.06, L1 + 0.06, z0 + 18.0, zc, sp, 12.0, 3.0, "white", seam)
	_dash(p, -L1 - 0.06, -L1 + 0.06, z0 + 6.0, zc, sp, 12.0, 3.0, "white", seam)
	# bike lane lines: dotted where cars cross them (aprons) and where the bus pulls in
	for sx: float in [-1.0, 1.0]:
		var brk: Array = []
		for a: float in apr[sx]:
			if a + APR_W * 0.5 < zc: brk.append([a - APR_W * 0.5 - 1.0, a + APR_W * 0.5 + 1.0])
		if bus and sx < 0.0: brk.append([bz0 - 3.0, bz1 + 1.0])
		_broken_line(p, minf(sx * (L2 - 0.08), sx * (L2 + 0.08)), maxf(sx * (L2 - 0.08), sx * (L2 + 0.08)), z0, zc, brk)
	for a2: Dictionary in arrows: p.insert(0, (a2.box as Array) + ["-"])
	K.painted_rect(g, -KA, z0, KA, zc, p, yr)
	for a2: Dictionary in arrows: K.fill_arrow(g, a2, yr)
	# ================================================================ parkway, aprons, bus pad, sidewalk
	for sx: float in [-1.0, 1.0]:
		var cuts: Array = []          # [a, b, kind]
		for a: float in apr[sx]:
			if a + APR_W * 0.5 + 1.5 < zc: cuts.append([a - APR_W * 0.5 - 1.5, a + APR_W * 0.5 + 1.5, "apron", a])
		if bus and sx < 0.0: cuts.append([pad0, pad1, "pad", 0.0])
		cuts.sort_custom(func(a: Array, b: Array) -> bool: return float(a[0]) < float(b[0]))
		var cur := z0
		for c: Array in cuts:
			if float(c[0]) > cur: RL.strip_z(g, sx * KA, sx * PKA, cur, float(c[0]), [], "grass", yr, yw)
			if String(c[2]) == "apron":
				RL.strip_z(g, sx * KA, sx * PKA, float(c[0]), float(c[1]), [[float(c[3]), APR_W]], "concrete", yr, yw, 2.0, 1.5)
			else:
				RL.strip_z(g, sx * KA, sx * PKA, float(c[0]), float(c[1]), [], "concrete", yr, yw)
			cur = float(c[1])
		if cur < zc: RL.strip_z(g, sx * KA, sx * PKA, cur, zc, [], "grass", yr, yw)
		g.rect("concrete", minf(sx * PKA, sx * PRA), z0, maxf(sx * PKA, sx * PRA), zc, yw)
	if taper:
		_taper_ind(g, TA, TB, yr, yw)
		K.painted_rect(g, -KI, TB, KI, z1, [[-0.2, TB, -0.1, z1, "yellow"], [0.1, TB, 0.2, z1, "yellow"], [-LI - 0.06, TB, -LI + 0.06, z1, "white"], [LI - 0.06, TB, LI + 0.06, z1, "white"]], yr)
		for sx: float in [-1.0, 1.0]: RL.strip_z(g, sx * KI, sx * PI_, TB, z1, [], "concrete", yr, yw)
	# ================================================================ furniture (each with its reason)
	var taken := {-1.0: [], 1.0: []}
	for sx: float in [-1.0, 1.0]:
		for a: float in apr[sx]: (taken[sx] as Array).append([a, APR_W * 0.5 + 1.5])
	var lampc := "rusty" if dress == "grt" else ("worn" if dress == "hill" else ("rusty" if rr.randf() < 0.4 else "worn"))
	if bus:
		# far-side stop: the bus stops after the light; the pad is where the doors open; the sign at the pad's front end
		# (the front door stops there); the bench at the back of the walk facing the street, 5 m behind the sign; a bin
		var fr := bz1
		I.add(props, "prop_bus_stop_sign", "worn", Vector3(-(KA + 0.45), float(yw.call(0.0, fr - 0.4)), fr - 0.4), 90.0)
		props.add("prop_bench_bus_stop", "dirty" if dress == "grt" else "worn", Vector3(-(PRA - 0.45), float(yw.call(0.0, fr - 5.6)), fr - 5.6), 90.0)
		props.add("prop_trash_receptacle", "dirty", Vector3(-(PRA - 0.45), float(yw.call(0.0, fr - 8.9)), fr - 8.9), 0.0)
		if dress == "strip": I.add(props, "prop_newspaper_box_red", "worn", Vector3(-(PRA - 0.4), float(yw.call(0.0, fr - 10.0)), fr - 10.0), 90.0)   # commuters' paper
		if dress == "hill": props.add("prop_recycling_receptacle", "worn", Vector3(-(PRA - 0.45), float(yw.call(0.0, fr - 9.8)), fr - 9.8), 0.0)
		RL.red_kerb_z(dec, -KA, bz0, bz1, 1.0, yr, yw)
		dec.add(14, Vector2(-(PRA - 1.0), fr - 5.6), 0.0, 1.6, 4.0, yw, Color(1, 1, 1, 0.6))           # where people stand and wait
		dec.add(14, Vector2(-(KA + 1.0), (pad0 + pad1) * 0.5), 0.0, 1.4, 3.8, yw, Color(1, 1, 1, 0.5))   # the pad people step onto
		for k in 3: W.oil(dec, rr, Vector2(-(L2 + 0.6), fr - rr.randf_range(2.0, 12.0)), 0.0, yr, 0.8)  # the bus idles at the kerb
		(taken[-1.0] as Array).append([(pad0 + pad1) * 0.5, (pad1 - pad0) * 0.5 + 1.5])
		(taken[-1.0] as Array).append([fr - 0.4, 2.5])
		# a lamp at the back of the zone (people wait there after dark), 3 m before the pad
		props.add("prop_lamp_cobra", lampc, Vector3(-(KA + 0.9), float(yw.call(0.0, pad0 - 3.0)), pad0 - 3.0), 90.0)
		(taken[-1.0] as Array).append([pad0 - 3.0, 3.0])
	# hydrant mid-leg on one side with its red kerb (15 ft each way), clear of aprons
	var hs: float = sp.get("hyd", 1.0)
	var hz := (z0 + minf(zc, z1)) * 0.5 + 3.0
	for tr in 40:
		if _free(taken[hs], hz, 6.0): break
		hz += 1.0 if tr % 2 == 0 else -float(tr + 1)
	if _free(taken[hs], hz, 6.0) and hz < zc - 6.0:
		props.add("prop_hydrant_red", "rusty" if dress == "grt" else "worn", Vector3(hs * (KA + 0.7), float(yw.call(0.0, hz)), hz), -90.0 * hs)
		RL.red_kerb_z(dec, hs * KA, hz - 4.5, hz + 4.5, -hs, yr, yw)
		(taken[hs] as Array).append([hz, 4.5])
	# cobra lamps over the road, both sides, staggered ~34 m (the junction lights its own crosswalks)
	for sx: float in [-1.0, 1.0]:
		var lz := z0 + (8.0 if sx < 0.0 else 25.0)
		if bus and sx < 0.0: lz = pad0 - 3.0 + 34.0
		while lz < z1 - 3.0:
			var put := -1.0
			for sh: float in [0.0, 2.0, -2.0, 4.0, -4.0, 6.0]:
				if lz + sh < z1 - 3.0 and lz + sh > z0 + 4.0 and _free(taken[sx], lz + sh, 1.5): put = lz + sh; break
			if put > 0.0:
				var lx := KA + 0.9
				if taper and put > TA: lx = _kx(put, TA, TB) + 0.9
				props.add("prop_lamp_cobra", lampc, Vector3(sx * lx, float(yw.call(0.0, put)), put), -90.0 * sx)
				(taken[sx] as Array).append([put, 3.0])
				lz = put + 34.0
			else:
				lz += 6.0
	# kerb inlets (drainage decides, so they go before the signs): one per side mid-leg, a catch basin intercepting the
	# gutter flow before it reaches the next crosswalk (the junction catches what runs down to it with its own inlets
	# just upstream of its crosswalks, so a rising leg needs none at its foot). Never on an apron or the bus pad.
	var Hl := _py(prof, z1)
	for sx: float in [-1.0, 1.0]:
		var iz0 := 0.0
		iz0 = (z0 + zc) * 0.5 + sx * 7.0
		var iz := -1.0
		for sh: float in [0.0, 2.0, -2.0, 4.0, -4.0, 6.0, -6.0, 8.0, -8.0, 10.0, -10.0, 12.0, -12.0]:
			var q := iz0 + sh
			if q > z0 + 1.6 and q < zc - 1.6 and _free(taken[sx], q, 1.6): iz = q; break
		if iz < 0.0: continue
		props.add("prop_storm_drain_curb_inlet", "dirty", Vector3(sx * KA, float(yr.call(0.0, iz)), iz), -90.0 * sx, false)
		(taken[sx] as Array).append([iz, 1.4])
		if absf(Hl) > 0.01:      # silt fan where the runoff slows at the grate
			dec.add(4 + rr.randi() % 2, Vector2(sx * (KA - 0.6), iz + (1.8 if Hl > 0.0 else -1.8)), 0.0, 1.1, 2.6, yr, Color(0.62, 0.57, 0.48, 0.6))   # uphill side of the grate
	# 25 mph for the traffic leaving the junction (Coronado posts 25 on its arterials), past the bus zone / pocket end
	var spz := (bz1 + 12.0) if bus else (z0 + 30.0)
	var sp_ok := false
	for tr in 40:
		if _free(taken[-1.0], spz, 2.0): sp_ok = true; break
		spz += 1.0
	# (17 Nov review) only where it is really free: an exhausted search used to drop it on a driveway apron's ramp
	if sp_ok and spz < zc - 2.0:
		props.add("prop_sign_speed25", "dirty" if dress == "grt" else "worn", Vector3(-(KA + 0.4), float(yw.call(0.0, spz)), spz), 90.0)
		(taken[-1.0] as Array).append([spz, 1.5])
	# no stopping on the arterial (the bike lane is the kerb lane): one sign per side mid-leg
	for sx: float in [-1.0, 1.0]:
		var nz := lerpf(z0, zc, 0.62 if sx > 0 else 0.78)
		for tr in 20:
			if _free(taken[sx], nz, 2.0): break
			nz += 1.3
		if nz < zc - 2.0:
			props.add("prop_sign_no_parking", "dirty" if dress == "grt" else "worn", Vector3(sx * (KA + 0.4), float(yw.call(0.0, nz)), nz), -90.0 * sx)
			(taken[sx] as Array).append([nz, 1.5])
	# manholes in the lanes (sewer under the inner lanes), with their old trench patches
	var mz := z0 + rr.randf_range(14.0, 30.0)
	while mz < zc - 4.0:
		var mx := (-3.5 if rr.randf() < 0.5 else 3.5)
		props.add("prop_manhole_cover", "rusty" if dress == "grt" else "worn", Vector3(mx, float(yr.call(0.0, mz)) + 0.002, mz), rr.randf_range(0, 90), false)
		if rr.randf() < 0.7: dec.add(2, Vector2(mx, mz), 0.0, 2.2, 2.2, yr, Color(1, 1, 1, 0.75))
		mz += rr.randf_range(45.0, 70.0)
	# trees in the parkway
	_trees(props, dec, rr, sp, taken, zc, yw)
	# district life
	_leg_extras(props, dec, rr, sp, taken, zc, yr, yw)
	# ================================================================ wear
	for lc: float in [-(L1 + L2) * 0.5, -(TL + L1) * 0.5, (TL + L1) * 0.5, (L1 + L2) * 0.5]:
		RL.lane_wear_y(dec, rr, lc, z0, zc, yr, 0.42)
	for k in 6: W.oil(dec, rr, Vector2(rr.randf_range(-0.8, 0.8), rr.randf_range(z0 + 2.0, zp - 2.0)), 0.0, yr, 0.8)   # the left-turn queue
	for lc: float in [(TL + L1) * 0.5, (L1 + L2) * 0.5]:                      # braking into the stop bar
		for wp: float in [-0.8, 0.8]: dec.add(8, Vector2(lc + wp, z0 + 3.0), 0.0, 0.45, 5.0, yr, Color(1, 1, 1, 0.45))
		W.oil(dec, rr, Vector2(lc, z0 + 2.5), 0.0, yr, 0.6)
	var ncr: int = {"grt": 26, "hill": 12, "strip": 18}[dress]
	_cracks(dec, rr, -L2, z0 + 1.0, L2, zc - 1.0, ncr, yr, 0.25 if dress == "grt" else (0.6 if dress == "hill" else 0.4))
	var tz := rr.randf_range(z0 + 20.0, zc - 10.0)                                # a utility trench across, patched
	dec.add(3, Vector2(0.0, tz), 90.0, 1.0, 2.0 * L2, yr, Color(1, 1, 1, 0.6))
	for sx: float in [-1.0, 1.0]:
		var gz := z0 + 0.5
		while gz < zc - 2.0:      # gutter: grime, leaves and palm litter, the grit bikes ride through
			var Lg := rr.randf_range(1.8, 3.6)
			dec.add(14, Vector2(sx * (KA - 0.3), gz + Lg * 0.5), 0.0, 0.55, Lg, yr, Color(0.95, 0.9, 0.82, rr.randf_range(0.4, 0.7) + (0.15 if dress == "grt" else 0.0)))
			gz += Lg + rr.randf_range(1.0, 5.0 if dress != "grt" else 2.5)
		for k in (6 if dress == "grt" else 3):
			dec.add(4 + rr.randi() % 2, Vector2(sx * rr.randf_range(L2 + 0.3, KA - 0.4), rr.randf_range(z0 + 3.0, zc - 3.0)), rr.randf_range(0, 180), rr.randf_range(0.6, 1.2), rr.randf_range(0.8, 2.0), yr, Color(0.55, 0.53, 0.5, 0.5))
		for a: float in apr[sx]:      # cars swing in and out of the lots: tyre arcs, oil, dirt carried over the walk
			if a + APR_W * 0.5 > zc: continue
			dec.add(8, Vector2(sx * (L2 - 1.4), a - 3.0), 25.0 * sx, 0.6, 3.8, yr, Color(1, 1, 1, 0.5))
			dec.add(8, Vector2(sx * (L2 - 1.4), a + 3.0), -25.0 * sx, 0.6, 3.8, yr, Color(1, 1, 1, 0.5))
			W.oil(dec, rr, Vector2(sx * (KA + 1.0), a), 0.0, yw, 0.75 if dress == "strip" else 0.55)
			dec.add(14, Vector2(sx * (PKA + 1.0), a), 0.0, 2.0, APR_W - 1.0, yw, Color(1, 1, 1, 0.55))
		var wz := z0 + 0.5
		while wz < zc - 1.0:      # the walking line: dust blown off the lots
			var Lw := rr.randf_range(2.0, 3.8)
			dec.add(14, Vector2(sx * rr.randf_range(PKA + 0.5, PRA - 0.5), wz + Lw * 0.5), 0.0, 1.2, Lw, yw, Color(1, 1, 1, rr.randf_range(0.25, 0.5)))
			wz += Lw + rr.randf_range(1.5, 5.0)
	if taper: _taper_wear(dec, rr, TA, TB, z1, yr, yw)
	root.set_meta("stalls", [])
	var gmax := 0.0
	var zz := z0
	while zz <= z1: gmax = maxf(gmax, absf(_pg(prof, zz))); zz += 1.0
	_finish(root, g, props, dec, name, "arterial %s, %s, z %.1f..%.1f, rise %.2f, max grade %.1f %%" % [dress, endk, z0, z1, Hl, gmax * 100.0])

## the kerb's x in the truck-street transition
static func _kx(z: float, ta: float, tb: float) -> float:
	return lerpf(KA, KI, ss((z - ta) / (tb - ta)))

## 3rd St west of G Ave: the arterial becomes the truck street between ta and tb, all in 0.5 m slices on one smoothstep:
## kerb 10.3 -> 6.7, parkway 2 -> 0 m, property line 14.3 -> 8.7, bike lane line 8.8 -> the truck edge line 4.2, the
## turn lane's yellows 1.7 -> the double yellow 0.15; lane lines end at ta (the outer lanes merge into the shoulder)
static func _taper_ind(g: K.Ground, ta: float, tb: float, yr: Callable, yw: Callable) -> void:
	var n := ceili((tb - ta) / 0.5)
	var kerbs := {-1.0: PackedVector2Array(), 1.0: PackedVector2Array()}
	for i in n:
		var za := lerpf(ta, tb, float(i) / n); var zb := lerpf(ta, tb, float(i + 1) / n)
		var t0 := ss(float(i) / n); var t1 := ss(float(i + 1) / n)
		var ya: float = yr.call(0.0, za); var yb: float = yr.call(0.0, zb)
		# band edges across the road at a slice end (t): [x, material to the right of x]
		var bands := func(t: float) -> Array:
			var k := lerpf(KA, KI, t); var e := lerpf(L2, LI, t); var eh := lerpf(0.08, 0.06, t); var c := lerpf(1.7, 0.15, t)
			return [[-k, "asphalt"], [-e - eh, "white"], [-e + eh, "asphalt"], [-c - 0.05, "yellow"], [-c + 0.05, "asphalt"],
				[c - 0.05, "yellow"], [c + 0.05, "asphalt"], [e - eh, "white"], [e + eh, "asphalt"], [k, ""]]
		var A: Array = bands.call(t0); var B: Array = bands.call(t1)
		for j in A.size() - 1:
			var m: String = A[j][1]
			g.quad(m, Vector3(float(A[j][0]), ya, za), Vector3(float(A[j + 1][0]), ya, za), Vector3(float(B[j + 1][0]), yb, zb), Vector3(float(B[j][0]), yb, zb))
		for sx: float in [-1.0, 1.0]:
			var ka := lerpf(KA, KI, t0); var kb := lerpf(KA, KI, t1)
			var pa := ka + 2.0 * (1.0 - t0); var pb := kb + 2.0 * (1.0 - t1)
			var ra := lerpf(PRA, PI_, t0); var rb := lerpf(PRA, PI_, t1)
			if pa - ka > 0.02 or pb - kb > 0.02:
				g.quad("grass", Vector3(sx * ka, ya + KH, za), Vector3(sx * pa, ya + KH, za), Vector3(sx * pb, yb + KH, zb), Vector3(sx * kb, yb + KH, zb))
			g.quad("concrete", Vector3(sx * pa, ya + KH, za), Vector3(sx * ra, ya + KH, za), Vector3(sx * rb, yb + KH, zb), Vector3(sx * pb, yb + KH, zb))
			var kp: PackedVector2Array = kerbs[sx]
			if i == 0: kp.append(Vector2(sx * ka, za))
			kp.append(Vector2(sx * kb, zb))
			kerbs[sx] = kp
	g.wall_line("curb", kerbs[-1.0], yr, yw, 1.0)
	g.wall_line("curb", kerbs[1.0], yr, yw, -1.0)

static func _taper_wear(dec: K.Decals, rr: RandomNumberGenerator, ta: float, tb: float, z1: float, yr: Callable, yw: Callable) -> void:
	# trucks: the wheel paths pull in toward the truck lanes, oil on the shoulder where they wait for the yard gates
	var z := ta + 1.0
	while z < z1 - 2.0:
		var t := ss((z - ta) / (tb - ta))
		for sx: float in [-1.0, 1.0]:
			var c := sx * lerpf((TL + L1) * 0.5 + 1.0, LI * 0.5, t)
			for wp: float in [-0.85, 0.85]: dec.add(14, Vector2(c + wp, z + 1.5), 0.0, 0.7, 3.0, yr, Color(1, 1, 1, 0.3))
			if rr.randf() < 0.35: W.oil(dec, rr, Vector2(sx * lerpf(L2 - 1.0, LI + 1.2, t), z + 1.5), 0.0, yr, 0.8)
			if rr.randf() < 0.5:
				var kx := lerpf(KA, KI, t)
				dec.add(14, Vector2(sx * (kx - 0.3), z + 1.5), 0.0, 0.55, 2.6, yr, Color(1, 1, 1, 0.65))
		z += 3.2
	_cracks(dec, rr, -LI, ta + 1.0, LI, z1 - 1.0, 10, yr, 0.2)
	dec.add(2, Vector2(2.0, (ta + tb) * 0.5 + 6.0), 0.0, 2.6, 5.0, yr, Color(1, 1, 1, 0.85))   # a patched pothole truck wheels opened

## trees in the parkway (0.9-1.1 m off the kerb): from 28 m (signal sight lines), an irregular 10-13 m rhythm, never on
## an apron, the bus pad or within ~2.5 m of a post; the district picks the species (see THE PLAN)
static func _trees(props: K.Props, dec: K.Decals, rr: RandomNumberGenerator, sp: Dictionary, taken: Dictionary, zc: float, yw: Callable) -> void:
	var dress: String = sp.dress; var z0: float = sp.z0; var z1: float = sp.z1
	var zend := minf(zc - 2.5, z1 - (4.0 if String(sp.end) == "seam" else 3.0))
	if String(sp.end) == "ind": zend = minf(zend, 46.0)
	var pools := {
		"grt": [[["palm_mexican_fan_a", "palm_mexican_fan_b", "palm_mexican_fan_c"], 0.7, 0.8, 1.15], [["palm_queen_a", "palm_queen_b"], 0.3, 0.85, 1.1]],
		"strip": [[["palm_mexican_fan_a", "palm_mexican_fan_b", "palm_mexican_fan_c"], 0.75, 0.82, 1.15], [["palm_queen_a", "palm_queen_b"], 0.25, 0.85, 1.12]],
	}
	var died: float = {"grt": 0.15, "hill": 0.06, "strip": 0.05}[dress]
	for sx: float in [-1.0, 1.0]:
		var z := maxf(28.0, z0 + 6.0) + (rr.randf_range(1.0, 5.0) if sx > 0.0 else rr.randf_range(0.0, 2.0))
		var grp := -1
		while z < zend:
			var ok := false
			for sh: float in [0.0, 1.0, 2.0, 3.0]:
				if z + sh < zend and _free(taken[sx], z + sh, 1.0): z += sh; ok = true; break
			if not ok:
				z += 1.0; continue
			if rr.randf() < died:      # a tree that died: the stump's patch of dead grass, never replanted
				dec.add(14, Vector2(sx * (KA + 1.0), z), rr.randf_range(0, 180), 1.2, 1.2, yw, Color(0.72, 0.64, 0.5, 0.6))
				z += rr.randf_range(9.0, 12.0); continue
			var model := ""; var scl := 1.0
			if dress == "hill":
				if grp < 0 or rr.randf() < 0.45: grp = RL._pick_group(rr)      # else the run of one species goes on
				var gp: Array = RL.RES_MIX[grp]
				model = String((gp[0] as Array)[rr.randi() % (gp[0] as Array).size()]); scl = rr.randf_range(float(gp[2]), float(gp[3]))
			else:
				var pool: Array = pools[dress]
				if grp < 0 or rr.randf() < 0.35: grp = 0 if rr.randf() < float(pool[0][1]) else 1
				var gp2: Array = pool[grp]
				model = String((gp2[0] as Array)[rr.randi() % (gp2[0] as Array).size()]); scl = rr.randf_range(float(gp2[2]), float(gp2[3]))
			var tx := sx * (KA + rr.randf_range(0.9, 1.1))
			props.add(model, "normal", Vector3(tx, float(yw.call(tx, z)) - 0.06, z), rr.randf_range(0.0, 360.0), true, scl)
			(taken[sx] as Array).append([z, 0.6])
			if model.begins_with("tree_") and rr.randf() < 0.55:      # roots lift the walk: a crack, or a slab the city replaced
				if rr.randf() < 0.6: dec.add(rr.randi() % 2, Vector2(sx * (PKA + 0.6), z + rr.randf_range(-0.8, 0.8)), rr.randf_range(60, 120), 1.6, 0.8, yw, Color(0.3, 0.29, 0.28, 0.8))
				else: W.pale_patch(dec, rr, Vector2(sx * (PKA + 1.0), z + rr.randf_range(-1.0, 1.0)), 0.0, 1.9, 1.6, yw, 0.6)
			z += rr.randf_range(9.0, 12.0) if dress != "hill" else rr.randf_range(10.0, 13.0)

## district life on a leg, every item with its reason
static func _leg_extras(props: K.Props, dec: K.Decals, rr: RandomNumberGenerator, sp: Dictionary, taken: Dictionary, zc: float, yr: Callable, yw: Callable) -> void:
	var dress: String = sp.dress; var z0: float = sp.z0
	match dress:
		"grt":
			# a shopping cart pushed up from the market and left at the back of the walk; slabs replaced over the years
			# (tinted grey); litter grime where people wait at the light
			var cz := lerpf(z0, zc, rr.randf_range(0.4, 0.8)); var csx := 1.0 if rr.randf() < 0.5 else -1.0
			if _free(taken[csx], cz, 2.0): I.add(props, "prop_shopping_cart", "worn", Vector3(csx * (PRA - 0.6), float(yw.call(0.0, cz)), cz), rr.randf_range(140, 220))
			for k in 7:
				var px := (1.0 if k % 2 else -1.0) * rr.randf_range(PKA + 0.4, PRA - 0.4)
				W.pale_patch(dec, rr, Vector2(px, rr.randf_range(z0 + 3.0, zc - 3.0)), rr.randf_range(0, 90), rr.randf_range(1.0, 1.7), rr.randf_range(1.0, 1.7), yw, 0.7)
			dec.add(14, Vector2(-(PRA - 1.0), z0 + 2.0), 0.0, 2.0, 3.0, yw, Color(1, 1, 1, 0.75))
			dec.add(3, Vector2(-(L1 + L2) * 0.5, lerpf(z0, zc, 0.55)), 0.0, 1.0, 12.0, yr, Color(1, 1, 1, 0.65))   # a long gas-main trench, never resurfaced
		"hill":
			# the city seals its cracks up here (black lines)
			for k in 5: dec.add(0, Vector2(rr.randf_range(-L2, L2), rr.randf_range(z0 + 4.0, zc - 4.0)), rr.randf_range(0, 180), rr.randf_range(1.5, 3.0), 0.5, yr, Color(0.12, 0.12, 0.12, 0.85))
			# Crown Hill's older residents walk to the bus and the shops: a bench at the back of the walk where the climb
			# starts (still nearly level there, 10-16 m out), facing the street, with a bin; the slab under it worn
			if absf(_py(sp.prof, sp.z1)) > 1.5:
				var bsx := -float(sp.get("hyd", 1.0))
				for tr in 8:
					var bzz := z0 + 10.0 + tr * 1.0
					if _free(taken[bsx], bzz, 2.2) and _free(taken[bsx], bzz + 1.4, 1.0):
						props.add("prop_bench_bus_stop", "worn", Vector3(bsx * (PRA - 0.45), float(yw.call(0.0, bzz)), bzz), -90.0 * bsx)
						props.add("prop_trash_receptacle", "worn", Vector3(bsx * (PRA - 0.45), float(yw.call(0.0, bzz + 1.6)), bzz + 1.6), 0.0)
						dec.add(14, Vector2(bsx * (PRA - 1.2), bzz + 0.5), 0.0, 1.4, 3.0, yw, Color(1, 1, 1, 0.5))
						(taken[bsx] as Array).append([bzz + 0.6, 2.0])
						break
		"strip":
			# drivers wait in the bike lane to turn into the lots: oil and tyre dirt along the kerb before each apron
			var apr: Dictionary = sp.apr
			for sx: float in [-1.0, 1.0]:
				for a: float in apr[sx]:
					if a + APR_W * 0.5 < zc: W.oil(dec, rr, Vector2(sx * ((L2 + KA) * 0.5), a - APR_W * 0.5 - 2.0), 0.0, yr, 0.6)


## ===================================================================================================== strip side legs
## side_leg(name, sp): an Adela Ave strip side street leg along +z (s_strip_side's section). sp:
##   z0, z1, prof          as art_leg
##   apr                   apron centres (both sides; the strip's lots line up with them)
##   wells                 {-1.0: [...], 1.0: [...]} tree well centres; trees: species list (mixed)
##   hyd                   [side, z]; pay: pay stations (metered: the hospital's visitors)
static func side_leg(name: String, sp: Dictionary) -> void:
	S.hill_on = false
	var root := Node3D.new(); root.name = name
	var g := K.Ground.new(); var props := K.Props.new(); var dec := K.Decals.new(); var rr := W.rng_for(name)
	var z0: float = sp.z0; var z1: float = sp.z1; var prof: Array = sp.prof
	var yr := func(_x: float, z: float) -> float: return _py(prof, z)
	var yw := func(_x: float, z: float) -> float: return _py(prof, z) + KH
	var apr: Array = sp.apr; var wells: Dictionary = sp.wells; var trees: Array = sp.trees
	var hyd: Array = sp.hyd; var hs: float = hyd[0]; var hz: float = hyd[1]
	var p: Array = [[-0.2, z0, -0.1, z1, "yellow"], [0.1, z0, 0.2, z1, "yellow"]]
	var stalls: Array = []
	for sx: float in [-1.0, 1.0]:
		# stalls from 4 m past the tile (7 m from the crosswalk), clear of the aprons (1.5 m) and the hydrant (4.5 m)
		var blocked: Array = []
		for a: float in apr: blocked.append([a - APR_S_W * 0.5 - 1.5, a + APR_S_W * 0.5 + 1.5])
		if sx == hs: blocked.append([hz - 4.5, hz + 4.5])
		var d := z0 + 4.0
		while d + SIDE_STALL <= z1 - 0.5:
			var bad := false
			for r: Array in blocked:
				if d + SIDE_STALL > float(r[0]) and d < float(r[1]): bad = true
			if bad:
				d += 0.5; continue
			for e: float in [d, d + SIDE_STALL]:
				p.append([minf(sx * LANE_S, sx * (LANE_S + 1.8)), e - 0.05, maxf(sx * LANE_S, sx * (LANE_S + 1.8)), e + 0.05, "white"])
			var cz := d + SIDE_STALL * 0.5; var cx := sx * (LANE_S + 1.2)
			stalls.append([cx, cz, 180.0 if sx > 0 else 0.0, _py(prof, cz), _pg(prof, cz)])
			if rr.randf() < 0.75: W.oil(dec, rr, Vector2(cx, cz + (1.3 if sx > 0 else -1.3)), 0.0, yr, 0.75)
			d += SIDE_STALL
	K.painted_rect(g, -KERB_S, z0, KERB_S, z1, p, yr)
	root.set_meta("stalls", stalls)
	# ---- sidewalks with the apron ramps and round wells (on the slope: our own well, site.gd's follows only x)
	for sx: float in [-1.0, 1.0]:
		var ws: Array = (wells[sx] as Array).duplicate(); ws.sort()
		var cur := z0
		for w: float in ws:
			var rs: Array = []
			for a: float in apr:
				if a > cur and a < w - 0.75: rs.append([a, APR_S_W])
			RL.strip_z(g, sx * KERB_S, sx * PROP_S, cur, w - 0.75, rs, "concrete", yr, yw, 1.5, 1.2)
			_well(g, Vector2(sx * (KERB_S + 0.75), w), yw)
			g.rect("concrete", minf(sx * (KERB_S + 1.5), sx * PROP_S), w - 0.75, maxf(sx * (KERB_S + 1.5), sx * PROP_S), w + 0.75, yw)
			g.wall_line("curb", PackedVector2Array([Vector2(sx * KERB_S, w - 0.75), Vector2(sx * KERB_S, w + 0.75)]), yr, yw, -sx)
			cur = w + 0.75
		var rs2: Array = []
		for a: float in apr:
			if a > cur: rs2.append([a, APR_S_W])
		RL.strip_z(g, sx * KERB_S, sx * PROP_S, cur, z1, rs2, "concrete", yr, yw, 1.5, 1.2)
		# trees in the wells: the side street was planted lot by lot (mixed species, young to mature)
		var k := 0
		for w: float in ws:
			var sp_name: String = trees[(k + (1 if sx > 0 else 0) + rr.randi() % 2) % trees.size()]
			props.add(sp_name, "normal", Vector3(sx * (KERB_S + 0.75), float(yw.call(0.0, w)) - 0.06, w), rr.randf_range(0, 360), true, rr.randf_range(0.82, 1.12))
			if rr.randf() < 0.5: dec.add(rr.randi() % 2, Vector2(sx * (KERB_S + 1.9), w + rr.randf_range(-0.6, 0.6)), rr.randf_range(60, 120), 1.6, 0.8, yw, Color(0.3, 0.29, 0.28, 0.75))
			k += 1
		# cobra lamp, a bin by the corner for the shoppers walking to the arterial, a kerb inlet, the walking line's dirt
		var lz: float = sp.lamps[0] if sx < 0 else sp.lamps[1]
		props.add("prop_lamp_cobra", "worn", Vector3(sx * (KERB_S + 0.6), float(yw.call(0.0, lz)), lz), -90.0 * sx)
		props.add("prop_trash_receptacle", "worn", Vector3(sx * (PROP_S - 0.5), float(yw.call(0.0, z0 + 4.5)), z0 + 4.5), 0.0)
		var H := _py(prof, z1)
		var iz := (z0 + 2.5) if H > 0.01 else ((z1 - 26.0) if absf(H) < 0.01 else (z1 - 8.0))
		props.add("prop_storm_drain_curb_inlet", "dirty", Vector3(sx * KERB_S, float(yr.call(0.0, iz)), iz), -90.0 * sx, false)
		var wz := z0 + 0.5
		while wz < z1 - 1.0:
			var Lw := rr.randf_range(2.0, 3.8)
			dec.add(14, Vector2(sx * (KERB_S + rr.randf_range(1.8, 2.4)), wz + Lw * 0.5), 0.0, 1.3, Lw, yw, Color(1, 1, 1, rr.randf_range(0.3, 0.5)))
			wz += Lw + rr.randf_range(1.0, 5.0)
		var gz := z0 + 1.0
		while gz < z1 - 2.0:
			var Lg := rr.randf_range(1.8, 3.4)
			dec.add(14, Vector2(sx * (KERB_S - 0.3), gz + Lg * 0.5), 0.0, 0.5, Lg, yr, Color(1, 1, 1, rr.randf_range(0.4, 0.6)))
			gz += Lg + rr.randf_range(2.0, 6.0)
		for a: float in apr:      # cars crossing the walk into the lots
			dec.add(14, Vector2(sx * (KERB_S + 1.5), a), 0.0, 2.6, APR_S_W - 1.0, yw, Color(1, 1, 1, 0.5))
			W.oil(dec, rr, Vector2(sx * (KERB_S + 0.8), a), 0.0, yw, 0.5)
		RL.lane_wear_y(dec, rr, sx * LANE_S * 0.5, z0, z1, yr, 0.38)
	# the hydrant and its red kerb, no-parking at the corner end (the delivery trucks' loading space)
	props.add("prop_hydrant_red", "worn", Vector3(hs * (KERB_S + 0.8), float(yw.call(0.0, hz)), hz), -90.0 * hs)
	RL.red_kerb_z(dec, hs * KERB_S, hz - 4.5, hz + 4.5, -hs, yr, yw)
	props.add("prop_sign_no_parking", "worn", Vector3(-hs * (KERB_S + 0.4), float(yw.call(0.0, z0 + 4.6)), z0 + 4.6), 90.0 * hs)   # the sweeping-day sign where the stalls begin, clear of the corner inlet
	if sp.get("pay", false):
		# metered parking near the hospital: one pay station per side, at a stall line, on the walk behind the kerb
		for sx: float in [-1.0, 1.0]:
			var pz: float = sp.pay_z[0] if sx < 0 else sp.pay_z[1]
			props.add("prop_pay_station", "worn", Vector3(sx * (KERB_S + 1.9), float(yw.call(0.0, pz)), pz), -90.0 * sx)
	_cracks(dec, rr, -KERB_S + 0.3, z0 + 1.0, KERB_S - 0.3, z1 - 1.0, 12, yr, 0.4)
	props.add("prop_manhole_cover", "worn", Vector3(-1.6, float(yr.call(0.0, (z0 + z1) * 0.5)) + 0.002, (z0 + z1) * 0.5), 0.0, false)
	dec.add(2, Vector2(1.6, z0 + 28.0), 0.0, 2.2, 2.0, yr, Color(1, 1, 1, 0.8))
	var gmax := 0.0
	var zz := z0
	while zz <= z1: gmax = maxf(gmax, absf(_pg(prof, zz))); zz += 1.0
	_finish(root, g, props, dec, name, "strip side, z %.1f..%.1f, rise %.2f, max grade %.1f %%, stalls %d" % [z0, z1, _py(prof, z1), gmax * 100.0, stalls.size()])


## ========================================================================================================== junctions
## art_junction(name, jp): a signalised junction, arterial (or the E-W street) along x, the cross street along z. jp:
##   N, S, E, W   mouth sections (MS keys); tN, tS, tE, tW tile extents (22 arterial, 26 cross streets)
##   xw, stop     |x| ranges of the crosswalks across the E-W street and its stop bars
##   rise         {"N": h, ...} how much each leg rises away from this junction (drainage)
##   hyd          "ne_sw" | "nw_se" (the diagonal pair of hydrants); dress; cond (signal hardware condition)
static func art_junction(name: String, jp: Dictionary) -> void:
	S.hill_on = false
	var root := Node3D.new(); root.name = name
	var g := K.Ground.new(); var props := K.Props.new(); var dec := K.Decals.new(); var rr := W.rng_for(name)
	var ry := S.road_y; var wy := S.walk_y
	var dress: String = jp.dress; var cond: String = jp.cond
	var xw: Array = jp.get("xw", [14.2, 17.2]); var stp: Array = jp.get("stop", [18.4, 19.0])
	var sec := {"N": String(jp.N), "S": String(jp.S), "E": String(jp.E), "W": String(jp.W)}
	var tile := {"N": float(jp.get("tN", 26.0)), "S": float(jp.get("tS", 26.0)), "E": float(jp.get("tE", 22.0)), "W": float(jp.get("tW", 22.0))}
	var rise: Dictionary = jp.rise
	var ew := func(sx: float) -> String: return "E" if sx > 0.0 else "W"
	var ns := func(sz: float) -> String: return "S" if sz > 0.0 else "N"
	var m := func(key: String, i: int) -> float: return float((MS[sec[key]] as Array)[i])
	# ---- E-W carriageway (both halves) with the crosswalks across it and the stop bars of its approaches
	for sx: float in [-1.0, 1.0]:
		var ke: String = ew.call(sx); var k: float = m.call(ke, 0); var te: float = tile[ke]
		var pa: Array = []
		var z := -k + 0.3
		while z + 0.6 <= k - 0.3 + 1e-3:
			pa.append([minf(sx * float(xw[0]), sx * float(xw[1])), z, maxf(sx * float(xw[0]), sx * float(xw[1])), z + 0.6, "white"]); z += 1.2
		var ext := TL if sec[ke] == "art" else 0.0      # the arterial's stop bar also closes its left-turn pocket
		var reach: float = k if sec[ke] == "art" else float(m.call(ke, 3))     # kerb to centre (bike lane incl.), or the travel lane only
		if sx > 0.0: pa.append([float(stp[0]), -reach, float(stp[1]), ext, "white"])      # westbound (arrives from +x, north half)
		else: pa.append([-float(stp[1]), -ext, -float(stp[0]), reach, "white"])          # eastbound (arrives from -x, south half)
		K.painted_rect(g, minf(0.0, sx * te), -k, maxf(0.0, sx * te), k, pa, ry)
	# ---- cross-street mouths (each half between the centre line and its kerb, from the E-W kerb to the tile edge)
	for sz: float in [-1.0, 1.0]:
		var kn: String = ns.call(sz); var kc: float = m.call(kn, 0); var lane: float = m.call(kn, 3); var tz: float = tile[kn]
		var cl: bool = (MS[sec[kn]] as Array)[4]
		var ps: Array = []
		var x := -kc + 0.3
		while x + 0.6 <= kc - 0.3 + 1e-3:
			ps.append([x, minf(sz * float(XW_S[0]), sz * float(XW_S[1])), x + 0.6, maxf(sz * float(XW_S[0]), sz * float(XW_S[1])), "white"]); x += 1.2
		if sz < 0: ps.append([-lane, -float(STOP_S[1]), 0.0, -float(STOP_S[0]), "white"])      # southbound drives on x < 0
		else: ps.append([0.0, float(STOP_S[0]), lane, float(STOP_S[1]), "white"])
		if cl:
			ps.append([-0.2, minf(sz * float(STOP_S[1]), sz * tz), -0.1, maxf(sz * float(STOP_S[1]), sz * tz), "yellow"])
			ps.append([0.1, minf(sz * float(STOP_S[1]), sz * tz), 0.2, maxf(sz * float(STOP_S[1]), sz * tz), "yellow"])
		for sx: float in [-1.0, 1.0]:
			var ke2: String = ew.call(sx); var kk: float = m.call(ke2, 0)
			K.painted_rect(g, minf(0.0, sx * kc), minf(sz * kk, sz * tz), maxf(0.0, sx * kc), maxf(sz * kk, sz * tz), ps, ry)
	# ---- corners: fillet, kerb return, corner walk, the two walk strips with their ramps
	var poles := {}
	for sx: float in [-1.0, 1.0]:
		for sz: float in [-1.0, 1.0]:
			var ke: String = ew.call(sx); var kn: String = ns.call(sz)
			var kew: float = m.call(ke, 0); var pew: float = m.call(ke, 2); var pkew: float = m.call(ke, 1)
			var kns: float = m.call(kn, 0); var pns: float = m.call(kn, 2); var pkns: float = m.call(kn, 1)
			var c := Vector2(sx * (kns + R), sz * (kew + R))
			var a0 := atan2(0.0, -sx); var a1 := atan2(-sz, 0.0)
			if a1 - a0 > PI: a1 -= TAU
			if a0 - a1 > PI: a1 += TAU
			var arc := K.arc(c, R, a0, a1, 14)
			var fil := arc.duplicate(); fil.append(Vector2(sx * kns, sz * kew)); g.poly("asphalt", fil, ry)
			var d := (arc[1] - arc[0]).normalized(); var left := Vector2(d.y, -d.x)
			g.wall_line("curb", arc, ry, wy, signf(left.dot((arc[0] - c).normalized())))
			var patch := arc.duplicate()
			patch.append(Vector2(sx * (kns + R), sz * pew)); patch.append(Vector2(sx * pns, sz * pew)); patch.append(Vector2(sx * pns, sz * (kew + R)))
			g.poly("concrete", patch, wy)
			var xc := (float(xw[0]) + float(xw[1])) * 0.5; var zc := (float(XW_S[0]) + float(XW_S[1])) * 0.5
			# E-W walk strip (x from the arc's end to the tile edge); a parkway only on a residential E-W mouth
			var xa := sx * (kns + R); var xb := sx * float(tile[ke])
			if pkew > kew + 0.01:
				_pkw_ramp(g, "x", sz * kew, sz * pkew, xa, xb, sx * xc)
				g.rect("concrete", minf(xa, xb), minf(sz * pkew, sz * pew), maxf(xa, xb), maxf(sz * pkew, sz * pew), wy)
			else:
				S.sidewalk_strip(g, "x", sz * kew, sz * pew, minf(xa, xb), maxf(xa, xb), [[sx * xc, 3.0]])
			# cross-street walk strip
			var za := sz * (kew + R); var zb := sz * float(tile[kn])
			if pkns > kns + 0.01:
				_pkw_ramp(g, "z", sx * kns, sx * pkns, za, zb, sz * zc)
				g.rect("concrete", minf(sx * pkns, sx * pns), minf(za, zb), maxf(sx * pkns, sx * pns), maxf(za, zb), wy)
			else:
				S.sidewalk_strip(g, "z", sx * kns, sx * pns, minf(za, zb), maxf(za, zb), [[sz * zc, 3.0]])
			# people wait at the ramps; gutter grime round the return; a root / settlement crack in the corner slab
			dec.add(14, Vector2(sx * xc, sz * (kew + 1.9)), 0.0, 3.2, 2.2, wy, Color(1, 1, 1, 0.5))
			dec.add(14, Vector2(sx * (kns + 1.6), sz * zc), 90.0, 3.2, 2.0, wy, Color(1, 1, 1, 0.5))
			for kk in range(1, arc.size() - 1, 3):
				var pp: Vector2 = arc[kk] + (arc[kk] - c).normalized() * 0.3
				dec.add(14, pp, rad_to_deg(atan2((arc[kk] - c).x, (arc[kk] - c).y)) + 90.0, 0.5, 2.0, ry, Color(0.95, 0.9, 0.82, 0.55))
			dec.add(0, c + Vector2(-sx, -sz).normalized() * (R - 2.4), rr.randf_range(0, 180), 1.6, 0.8, wy, Color(0.3, 0.29, 0.28, 0.75))
			# tyre scuffs on the kerb return where turning trucks and buses clip it (worst on the truck street)
			var mid := c + Vector2(cos((a0 + a1) * 0.5), sin((a0 + a1) * 0.5)) * (R + 1.6)
			dec.add(8, mid, rad_to_deg((a0 + a1) * 0.5) + 90.0, 0.6, 6.0, ry, Color(1, 1, 1, 0.6 if (sec[kn] == "ind") else 0.35))
			# the corner pole: r - 1 from the kerb return's centre, on the corner walk (never the asphalt fillet)
			var pp2 := c + Vector2(-sx, -sz).normalized() * (R - 1.0)
			poles[Vector2(sx, sz)] = Vector3(pp2.x, wy.call(0.0), pp2.y)
	# ---- signals: mast arms over a wide approach, posts for the narrow ones; the heads face the arriving traffic
	# NW serves the westbound approach (from E), SE the eastbound (from W), NE the northbound (from S), SW the southbound
	var mast_nw: bool = sec["E"] == "art"; var mast_se: bool = sec["W"] == "art"
	props.add("prop_signal_mast_arm" if mast_nw else "prop_signal_post", cond, poles[Vector2(-1, -1)], 90.0)
	props.add("prop_signal_mast_arm" if mast_se else "prop_signal_post", cond, poles[Vector2(1, 1)], -90.0)
	props.add("prop_signal_post", cond, poles[Vector2(1, -1)], 0.0)
	props.add("prop_signal_post", cond, poles[Vector2(-1, 1)], 180.0)
	for kv: Vector2 in [Vector2(1, -1), Vector2(-1, 1)]:
		var ns2: Vector3 = poles[kv] + Vector3(kv.x * 1.3, 0.0, 0.0)
		props.add("prop_sign_street_names", "dirty" if dress == "grt" else "worn", ns2, 45.0)
	# ---- cobra lamps on the post corners' E-W walk, lighting the crosswalks and the stop bars
	for kv: Vector2 in [Vector2(1, -1), Vector2(-1, 1)]:
		var ke3: String = ew.call(kv.x); var kk3: float = m.call(ke3, 0)
		props.add("prop_lamp_cobra", "rusty" if dress == "grt" else "worn", Vector3(kv.x * 20.8, wy.call(0.0), kv.y * (kk3 + 1.0)), 90.0 + 90.0 * kv.y)     # arm (+Z) over the road
	# ---- kerb inlets: a mouth whose leg rises away drains INTO the junction (both kerbs), a flat one at its approach kerb
	for key: String in ["N", "S", "E", "W"]:
		var h: float = rise.get(key, 0.0)
		if h < -0.01: continue
		var kerbs: Array = []
		if key == "E" or key == "W":
			var sx2 := 1.0 if key == "E" else -1.0; var kk4: float = m.call(key, 0)
			var app := -1.0 if key == "E" else 1.0       # westbound arrives on z < 0, eastbound on z > 0
			kerbs = [app] if h < 0.01 else [-1.0, 1.0]
			for szk: float in kerbs:
				props.add("prop_storm_drain_curb_inlet", "dirty", Vector3(sx2 * 20.6, ry.call(0.0), szk * kk4), 0.0 if szk < 0.0 else 180.0, false)
				dec.add(14, Vector2(sx2 * 20.6, szk * (kk4 - 0.7)), 90.0, 1.0, 2.6, ry, Color(1, 1, 1, 0.6))
		else:
			var sz2 := -1.0 if key == "N" else 1.0; var kk5: float = m.call(key, 0)
			var app2 := -1.0 if key == "N" else 1.0       # southbound arrives on x < 0, northbound on x > 0
			kerbs = [app2] if h < 0.01 else [-1.0, 1.0]
			for sxk: float in kerbs:
				props.add("prop_storm_drain_curb_inlet", "dirty", Vector3(sxk * kk5, ry.call(0.0), sz2 * 23.4), 90.0 if sxk < 0.0 else -90.0, false)
				dec.add(14, Vector2(sxk * (kk5 - 0.7), sz2 * 23.4), 0.0, 1.0, 2.6, ry, Color(1, 1, 1, 0.6))
	# ---- hydrants on two diagonal corners, at the departure kerbs (clear of the inlets and the ramps)
	var hyd: String = jp.hyd
	var hpts: Array = []
	if hyd == "ne_sw":
		var on: float = 1.0 if float(m.call("N", 1)) > float(m.call("N", 0)) + 0.01 else 0.7
		var os: float = 1.0 if float(m.call("S", 1)) > float(m.call("S", 0)) + 0.01 else 0.7
		hpts = [[Vector3(float(m.call("N", 0)) + on, wy.call(0.0), -25.2), -90.0], [Vector3(-(float(m.call("S", 0)) + os), wy.call(0.0), 25.2), 90.0]]
	else:
		hpts = [[Vector3(21.0, wy.call(0.0), m.call("E", 0) + 1.0), 180.0], [Vector3(-21.0, wy.call(0.0), -(m.call("W", 0) + 1.0)), 0.0]]
	for hp: Array in hpts: props.add("prop_hydrant_red", "rusty" if dress == "grt" else "worn", hp[0], float(hp[1]))
	# ---- the district's corner life
	_corner_extras(props, dec, rr, jp, m)
	# ---- wear: queues at the arterial stop bars (braking marks, oil), left turners sweeping the box, a trench patch
	for sx: float in [-1.0, 1.0]:
		var ke6: String = ew.call(sx)
		if sec[ke6] != "art": continue
		var lanes := [(TL + L1) * 0.5, (L1 + L2) * 0.5, 0.0]
		for lc: float in lanes:
			var zl := -lc if sx > 0.0 else lc        # westbound on z < 0, eastbound on z > 0
			for wp: float in [-0.8, 0.8]: dec.add(8, Vector2(sx * 20.7, zl + wp), 90.0, 0.45, 2.4, ry, Color(1, 1, 1, 0.5))
			W.oil(dec, rr, Vector2(sx * 20.6, zl), 90.0, ry, 0.7)
	for k in 4: dec.add(8, Vector2(rr.randf_range(-6, 6), rr.randf_range(-5, 5)), rr.randf_range(20, 70), 0.6, 4.0, ry, Color(1, 1, 1, 0.38))
	dec.add(3, Vector2(rr.randf_range(-4.0, 4.0), 0.0), 0.0, 0.9, 2.0 * minf(m.call("E", 0), m.call("W", 0)) - 0.4, ry, Color(1, 1, 1, 0.55))   # a duct crossing, patched
	_cracks(dec, rr, -12.0, -minf(m.call("E", 0), m.call("W", 0)) + 0.5, 12.0, minf(m.call("E", 0), m.call("W", 0)) - 0.5, {"grt": 22, "hill": 10, "strip": 16}[dress], ry, 0.45)
	props.add("prop_manhole_cover", "rusty" if dress == "grt" else "worn", Vector3(rr.randf_range(-6.0, 6.0), ry.call(0.0) + 0.002, rr.randf_range(-3.0, 3.0)), 0.0, false)
	_finish(root, g, props, dec, name, "junction %s/%s/%s/%s %s" % [sec["N"], sec["E"], sec["S"], sec["W"], dress])

## a parkway strip inside a junction tile (flat): grass, with concrete from the corner to the end of the crosswalk ramp
static func _pkw_ramp(g: K.Ground, along: String, kerb: float, pkw: float, a: float, b: float, c: float) -> void:
	var lo := minf(a, b); var hi := maxf(a, b)
	var r0 := c - 1.5; var r1 := c + 1.5
	if c < 0.0:     # the corner end is hi (nearer the centre): concrete from hi down to the ramp's far end
		S.sidewalk_strip(g, along, kerb, pkw, maxf(lo, r0), hi, [[c, 3.0]], "concrete", 1.4, 0.0, 0.6)
		if r0 > lo: S.sidewalk_strip(g, along, kerb, pkw, lo, r0, [], "grass")
	else:
		S.sidewalk_strip(g, along, kerb, pkw, lo, minf(hi, r1), [[c, 3.0]], "concrete", 1.4, 0.0, 0.6)
		if hi > r1: S.sidewalk_strip(g, along, kerb, pkw, r1, hi, [], "grass")

## corner life by district: spots on the back of the cross-street walks and the arterial walks, clear of poles, lamps,
## hydrants and ramps (measured spots, see THE PLAN)
static func _corner_extras(props: K.Props, dec: K.Decals, rr: RandomNumberGenerator, jp: Dictionary, m: Callable) -> void:
	var dress: String = jp.dress
	var wy := S.walk_y
	var nsw := func(sx: float, sz: float, dz := 0.0) -> Vector3:     # back of the cross-street walk, near the tile edge
		var key := "S" if sz > 0.0 else "N"
		return Vector3(sx * (float(m.call(key, 2)) - 0.45), wy.call(0.0), sz * (24.4 + dz))
	var eww := func(sx: float, sz: float, dx := 0.0) -> Vector3:     # back of the E-W walk, past the stop bar
		var key := "E" if sx > 0.0 else "W"
		return Vector3(sx * (19.6 + dx), wy.call(0.0), sz * (float(m.call(key, 2)) - 0.45))
	var bus_corners: Array = jp.get("bus_corners", [])
	for bc: Array in bus_corners:      # riders walking to the far-side stop: a bin on the corner they cross to
		props.add("prop_trash_receptacle", "dirty" if dress == "grt" else "worn", eww.call(float(bc[0]), float(bc[1]), 2.0), 0.0)
	# which corner gets what is the junction's own (seeded): same-type junctions never repeat one another
	var c1 := Vector2(1.0 if rr.randf() < 0.5 else -1.0, 1.0 if rr.randf() < 0.5 else -1.0)
	var c2 := -c1
	var mast := Vector2(-1.0, -1.0) if rr.randf() < 0.5 else Vector2(1.0, 1.0)
	var post := Vector2(1.0, -1.0) if rr.randf() < 0.5 else Vector2(-1.0, 1.0)
	match dress:
		"grt":
			# a rusty news box nobody refills, and a shopping cart left at the corner on the walk home from the market
			I.add(props, "prop_newspaper_box_red", "rusty", nsw.call(c1.x, c1.y), -90.0 * c1.x)
			I.add(props, "prop_shopping_cart", "worn", nsw.call(c2.x, c2.y, 0.4), rr.randf_range(60, 120))
			for k in 4:       # litter and dark grime where people wait for the light
				dec.add(14, Vector2((1.0 if k % 2 else -1.0) * rr.randf_range(9.0, 12.0), (1.0 if k < 2 else -1.0) * rr.randf_range(11.0, 13.5)), rr.randf_range(0, 180), 2.0, 2.0, wy, Color(1, 1, 1, 0.75))
		"hill":
			props.add("prop_usps_collection_box", "worn", nsw.call(c1.x, c1.y), 90.0 * -c1.x)     # mail for the hill's houses, where the carrier stops
			props.add("prop_recycling_receptacle", "worn", eww.call(post.x, post.y, 2.2), 0.0)
		"strip":
			I.add(props, "prop_newspaper_box_blue", "worn", eww.call(mast.x, mast.y, 0.0), 0.0)    # commuters waiting for the light
			I.add(props, "prop_newspaper_box_red", "worn", eww.call(mast.x, mast.y, 0.75), 0.0)
			props.add("prop_trash_receptacle", "worn", nsw.call(c1.x, c1.y), 0.0)
			props.add("prop_recycling_receptacle", "worn", nsw.call(c1.x, c1.y, -0.8), 0.0)


## =============================================================================================== review ground (preview)
## PREVIEW ONLY (never placed in the game): grass under the art review area so shots never look into a void. Heights:
## a Coons patch per lattice cell through the street centre lines (each block's own profile, from review/art.json
## "ground"); the grass is cut away exactly where a piece of the review stands (its right-of-way rectangles), 3 cm
## under the walk elsewhere. Review frame: grid (u, y, v) + (3200, 0, -3000).
static func review_ground(name: String) -> void:
	var root := Node3D.new(); root.name = name
	var g := K.Ground.new()
	var d: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://map_dc/coronado/city_kit/review/art.json"))
	var gd: Dictionary = d.ground
	var O := Vector2(float(gd.origin[0]), float(gd.origin[1]))
	var segs: Array = gd.segs           # [ua, va, ub, vb, pad_a, prof [[p0, p1, h]]]
	var holes: Array = []               # right-of-way polygons (grid frame)
	for h: Array in gd.holes:
		var pts := PackedVector2Array()
		for q: Array in h: pts.append(Vector2(float(q[0]), float(q[1])))
		holes.append(pts)
	var U: Array = gd.U; var V: Array = gd.V
	var on_street := func(p: Vector2) -> int:
		for k in segs.size():
			var sg: Array = segs[k]
			var a := Vector2(float(sg[0]), float(sg[1])); var c := Vector2(float(sg[2]), float(sg[3]))
			if absf(a.x - c.x) < 0.5 and absf(p.x - a.x) < 0.5 and p.y >= minf(a.y, c.y) - 0.5 and p.y <= maxf(a.y, c.y) + 0.5: return k
			if absf(a.y - c.y) < 0.5 and absf(p.y - a.y) < 0.5 and p.x >= minf(a.x, c.x) - 0.5 and p.x <= maxf(a.x, c.x) + 0.5: return k
		return -1
	var street_y := func(k: int, p: Vector2) -> float:
		var sg: Array = segs[k]
		var s := (p - Vector2(float(sg[0]), float(sg[1]))).length()
		return float(sg[4]) + _py(sg[5], s)
	var pads: Array = gd.pads           # [u, v, pad]
	var point_y := func(p: Vector2) -> float:
		var k: int = on_street.call(p)
		if k >= 0: return float(street_y.call(k, p))
		var best := 4.0; var bd := 1e9
		for q: Array in pads:
			var dd := Vector2(float(q[0]), float(q[1])).distance_to(p)
			if dd < bd: bd = dd; best = float(q[2])
		return best
	var side_y := func(p: Vector2, q: Vector2, t: Vector2) -> float:
		var k: int = on_street.call((p + q) * 0.5)
		if k >= 0: return float(street_y.call(k, t))
		var f := (t - p).length() / maxf(p.distance_to(q), 0.01)
		return lerpf(float(point_y.call(p)), float(point_y.call(q)), ss(f))
	for i in U.size() - 1:
		for j in V.size() - 1:
			var u0: float = U[i]; var u1: float = U[i + 1]; var v0: float = V[j]; var v1: float = V[j + 1]
			var P00 := Vector2(u0, v0); var P10 := Vector2(u1, v0); var P01 := Vector2(u0, v1); var P11 := Vector2(u1, v1)
			var c00: float = point_y.call(P00); var c10: float = point_y.call(P10); var c01: float = point_y.call(P01); var c11: float = point_y.call(P11)
			var yf := func(u: float, v: float) -> float:
				var a := (u - u0) / (u1 - u0); var b := (v - v0) / (v1 - v0)
				var y := (1.0 - b) * float(side_y.call(P00, P10, Vector2(u, v0))) + b * float(side_y.call(P01, P11, Vector2(u, v1))) \
					+ (1.0 - a) * float(side_y.call(P00, P01, Vector2(u0, v))) + a * float(side_y.call(P10, P11, Vector2(u1, v))) \
					- ((1.0 - a) * (1.0 - b) * c00 + a * (1.0 - b) * c10 + (1.0 - a) * b * c01 + a * b * c11)
				return y + KH - 0.08
			var nu := maxi(1, ceili((u1 - u0) / 4.0)); var nv := maxi(1, ceili((v1 - v0) / 4.0))
			for a2 in nu:
				for b2 in nv:
					var ua := lerpf(u0, u1, float(a2) / nu); var ub := lerpf(u0, u1, float(a2 + 1) / nu)
					var va := lerpf(v0, v1, float(b2) / nv); var vb := lerpf(v0, v1, float(b2 + 1) / nv)
					var pieces: Array = [PackedVector2Array([Vector2(ua, va), Vector2(ub, va), Vector2(ub, vb), Vector2(ua, vb)])]
					var qr := Rect2(Vector2(ua, va), Vector2(ub - ua, vb - va))
					for h2: PackedVector2Array in holes:
						var hb := Rect2(h2[0], Vector2.ZERO)
						for hp in h2: hb = hb.expand(hp)
						if not hb.intersects(qr): continue
						var nxt: Array = []
						for pc: PackedVector2Array in pieces:
							for r2: PackedVector2Array in Geometry2D.clip_polygons(pc, h2):
								if not Geometry2D.is_polygon_clockwise(r2) or r2.size() < 3: nxt.append(r2)
						pieces = nxt
					for pc2: PackedVector2Array in pieces:
						var idx := Geometry2D.triangulate_polygon(pc2)
						for t in range(0, idx.size(), 3):
							var A := pc2[idx[t]]; var B := pc2[idx[t + 1]]; var C := pc2[idx[t + 2]]
							g.tri("grass", Vector3(A.x + O.x, yf.call(A.x, A.y), A.y + O.y), Vector3(B.x + O.x, yf.call(B.x, B.y), B.y + O.y), Vector3(C.x + O.x, yf.call(C.x, C.y), C.y + O.y))
	var mi := MeshInstance3D.new(); mi.name = "ground"; mi.mesh = g.build(); mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF; root.add_child(mi)
	print("%s: ground tris %d" % [name, g.tri_count()])
	K.save_piece(root, name)
