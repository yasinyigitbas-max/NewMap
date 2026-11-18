extends RefCounted
## Road kit library (17 Nov, street skeleton + audit fixes). New street / junction pieces are built here, NEVER by
## editing the older sample libraries (apt_lib, ind_lib, ...) that locked pieces were built with.
##
## apt_street(): the standard residential leg (s_apt cross-section: 1+1 lanes, double yellow, parallel parking both
## sides, kerb, 1.5 m parkway, 2 m sidewalk, alley aprons at 54-60, hydrant with red kerb, a bus stop on the departure
## side) from the junction tile (|z| 20) to 100 m along +z, used on all four legs by rotation. The cross-section,
## stalls, aprons, hydrant and bus zone are IDENTICAL for every dress, so any variant replaces s_apt in a layout
## without touching the blocks beside it. Only the dress changes (audit #5: "one street piece dresses four zones"):
##   apt     the apartment band: magnolia / ficus / queen palm parkway, globe lamps staggered, street sweeping signs
##   civ     the civic heart: one formal species (magnolias) in matched pairs, heritage (victorian) lamps opposite each
##           other, pay stations for visitors (2 h civic parking), bins at the crosswalks, no sweeping signs, the
##           city keeps it: fewer cracks, sealed not open
##   grt     the gritty edge: hardy trees in only some of the slots (the rest died and were never replaced), the
##           parkway worn to gravel, cobra lamps, tow-away / no-parking signs at the alley mouth, an abandoned
##           shopping cart from the market, more cracks, patches, gutter litter and sidewalk grime
##   wfd     the bay drive: fan and queen palms, pier lamps (the promenade's), beach parking meters (one per stall
##           pair), sand blown into the gutters and onto the walk, no sweeping signs
## Audit #15 (bus stops: sign, palm, lamp and speed sign within 2.5 m on every leg): the stop gets a concrete boarding
## pad through the parkway at the bus doors (people step off the bus onto it, not onto grass), no tree on the pad,
## the stop sign at the pad's front end where the front door stops, the lamp at the back of the zone, the speed sign
## past the alley (25 m on).
const K := preload("res://tools/city/pilot/kit_lib.gd")
const S := preload("res://tools/city/pilot/site.gd")
const W := preload("res://tools/city/pilot/pieces/wear_lib.gd")
const A := preload("res://tools/city/pilot/pieces/apt_lib.gd")
const I := preload("res://tools/city/pilot/pieces/ind_lib.gd")

const Z0 := 20.0
const Z1 := 100.0
const STALL := 6.5
const BUS0 := 27.0
const BUS1 := 47.0
const PAD0 := 35.0          # bus boarding pad through the parkway (doors open here)
const PAD1 := 42.5
const HYDRANT := 40.0


static func apt_street(name: String, dress: String) -> void:
	S.hill_on = false
	var root := Node3D.new(); root.name = name
	var g := K.Ground.new(); var props := K.Props.new(); var dec := K.Decals.new(); var rr := W.rng_for(name)
	var ry := S.road_y
	var p: Array = [[-0.2, Z0, -0.1, Z1, "yellow"], [0.1, Z0, 0.2, Z1, "yellow"]]
	var stalls: Array = []
	var crack_n: int = {"apt": 14, "civ": 8, "grt": 24, "wfd": 12}[dress]
	for sx: float in [-1.0, 1.0]:
		var blocked: Array = [[A.AL0 - 1.5, A.AL1 + 1.5], [Z0, 27.0]]          # alley mouth; 7 m clear of the crosswalk
		if sx < 0: blocked.append([BUS0, BUS1])                              # bus zone (departure side, far side of the junction)
		if sx > 0: blocked.append([HYDRANT - 4.5, HYDRANT + 4.5])
		var d := Z0
		var si := 0
		while d + STALL <= Z1:
			var bad := false
			for r: Array in blocked:
				if d + STALL > float(r[0]) and d < float(r[1]): bad = true
			if bad:
				d += 0.5; continue
			for e: float in [d, d + STALL]:
				p.append([minf(sx * A.LANE, sx * (A.LANE + 0.6)), e - 0.05, maxf(sx * A.LANE, sx * (A.LANE + 0.6)), e + 0.05, "white"])
			stalls.append([sx * (A.LANE + 1.2), d + STALL * 0.5, 180.0 if sx > 0 else 0.0])
			W.oil(dec, rr, Vector2(sx * (A.LANE + 1.2), d + STALL * (0.35 if sx > 0 else 0.65)), 0.0, ry, rr.randf_range(0.5, 0.85))
			if dress == "wfd" and si % 2 == 0:       # beach parking: a meter between every second pair of stalls, at the kerb
				props.add("prop_parking_meter", "worn", Vector3(sx * (A.KERB + 0.4), S.walk_y(0.0), d), -90.0 * sx)
			if dress == "civ" and si == 2:            # one pay station per side for the visitors' 2 h parking
				props.add("prop_pay_station", "worn", Vector3(sx * (A.PKW + 0.35), S.walk_y(0.0), d + STALL * 0.5), -90.0 * sx)
			si += 1
			d += STALL
		W.lane_wear(dec, rr, sx * A.LANE * 0.5, Z0, Z1, true, ry)
		W.cracks(dec, rr, minf(sx * 0.3, sx * A.KERB), Z0 + 1.0, maxf(sx * 0.3, sx * A.KERB), Z1 - 1.0, crack_n, ry, 0.45)
		var gz := Z0 + 1.0
		while gz < Z1 - 1.5:   # gutter: grime and the leaves the street trees drop (sand on the bay drive, litter in gritty)
			var gc := Color(0.86, 0.79, 0.64, rr.randf_range(0.45, 0.7)) if dress == "wfd" else Color(1, 1, 1, rr.randf_range(0.45, 0.7) + (0.15 if dress == "grt" else 0.0))
			dec.add(14 if dress != "wfd" else 4 + rr.randi() % 2, Vector2(sx * (A.KERB - 0.3), gz + 1.2), 0.0, 0.55, 2.4, ry, gc)
			gz += rr.randf_range(2.0, 4.0) if dress == "grt" else rr.randf_range(3.0, 6.0)
	K.painted_rect(g, -A.KERB, Z0, A.KERB, Z1, p, ry)
	# ---- parkways, sidewalks, the bus boarding pad
	var ac := (A.AL0 + A.AL1) * 0.5; var aw := A.AL1 - A.AL0
	var pk := "gravel" if dress == "grt" else "grass"
	for sx: float in [-1.0, 1.0]:
		if sx < 0:
			S.sidewalk_strip(g, "z", sx * A.KERB, sx * A.PKW, Z0, PAD0, [], pk)
			S.sidewalk_strip(g, "z", sx * A.KERB, sx * A.PKW, PAD0, PAD1, [], "concrete")
			S.sidewalk_strip(g, "z", sx * A.KERB, sx * A.PKW, PAD1, A.AL0 - 1.0, [], pk)
		else:
			S.sidewalk_strip(g, "z", sx * A.KERB, sx * A.PKW, Z0, A.AL0 - 1.0, [], pk)
		S.sidewalk_strip(g, "z", sx * A.KERB, sx * A.PKW, A.AL0 - 1.0, A.AL1 + 1.0, [[ac, aw]], "concrete", 1.5, 1.0, 0.0)
		S.sidewalk_strip(g, "z", sx * A.KERB, sx * A.PKW, A.AL1 + 1.0, Z1, [], pk)
		g.rect("concrete", minf(sx * A.PKW, sx * A.PROP), Z0, maxf(sx * A.PKW, sx * A.PROP), Z1, S.walk_y)
		_trees(props, dec, rr, sx, dress, ac, aw)
		_lamps(props, sx, dress)
		var wz := Z0 + 0.5
		while wz < Z1 - 1.0:      # sidewalk dirt along the walking line
			var Lw := rr.randf_range(2.0, 5.0)
			var a0: Array = {"apt": [0.3, 0.55], "civ": [0.2, 0.4], "grt": [0.45, 0.75], "wfd": [0.3, 0.5]}[dress]
			dec.add(14, Vector2(sx * rr.randf_range(A.PKW + 0.5, A.PROP - 0.5), wz + Lw * 0.5), 0.0, 1.3, Lw, S.walk_y, Color(1, 1, 1, rr.randf_range(a0[0], a0[1])))
			wz += Lw + rr.randf_range(1.0, 4.0)
		props.add("prop_storm_drain_curb_inlet", "dirty", Vector3(sx * A.KERB, ry.call(0.0), 50.5), -90.0 * sx, false)
		match dress:
			"apt":
				props.add("prop_sign_no_parking", "worn", Vector3(sx * (A.KERB + 0.35), S.walk_y(0.0), 64.0 if sx > 0 else 84.0), -90.0 * sx)   # street sweeping
			"grt":
				# tow-away zone at the alley mouth both sides (trucks and the pound cut in there), one bent sweeping sign
				props.add("prop_sign_no_parking", "rusty", Vector3(sx * (A.KERB + 0.35), S.walk_y(0.0), A.AL0 - 1.4), -90.0 * sx)   # 2 m past the kerb inlet at 50.5
				props.add("prop_sign_no_parking", "rusty", Vector3(sx * (A.KERB + 0.35), S.walk_y(0.0), A.AL1 + 2.6), -90.0 * sx)
	# ---- the bus stop (a stop each way in every area: the leg is used four times)
	props.add("prop_bench_bus_stop", "worn" if dress != "grt" else "dirty", Vector3(-(A.PROP - 0.45), S.walk_y(0.0), 38.5), 90.0)
	I.add(props, "prop_bus_stop_sign", "worn", Vector3(-(A.KERB + 0.45), S.walk_y(0.0), PAD1 - 0.6), 90.0)    # front door stops here
	props.add("prop_trash_receptacle", "dirty", Vector3(-(A.PROP - 0.5), S.walk_y(0.0), 41.6), 0.0)
	W.red_kerb(dec, Vector2(-A.KERB, BUS0), Vector2(-A.KERB, BUS1), Vector2(1.0, 0.0))
	dec.add(14, Vector2(-(A.PKW + 1.0), 38.5), 0.0, 1.8, 4.5, S.walk_y, Color(1, 1, 1, 0.6))
	dec.add(14, Vector2(-(A.KERB + 0.75), (PAD0 + PAD1) * 0.5), 0.0, 1.2, PAD1 - PAD0 - 0.6, S.walk_y, Color(1, 1, 1, 0.55))   # the pad people step onto
	props.add("prop_hydrant_red", "rusty", Vector3(A.KERB + 0.7, S.walk_y(0.0), HYDRANT), -90.0)
	W.red_kerb(dec, Vector2(A.KERB, HYDRANT - 4.5), Vector2(A.KERB, HYDRANT + 4.5), Vector2(-1.0, 0.0))
	# speed sign for the traffic leaving the junction (-x side drives +z), past the alley: 25 m on from the stop
	props.add("prop_sign_speed25", "worn", Vector3(-(A.KERB + 0.35), S.walk_y(0.0), 67.5), 90.0)
	props.add("prop_manhole_cover", "worn", Vector3(-1.6, ry.call(0.0) + 0.002, 46.0), 0.0, false)
	props.add("prop_manhole_cover", "worn", Vector3(1.6, ry.call(0.0) + 0.002, 88.0), 0.0, false)
	dec.add(2, Vector2(1.6, 88.0), 0.0, 2.4, 2.2, ry, Color(1, 1, 1, 0.85))
	dec.add(3, Vector2(0.0, 76.0), 90.0, 1.4, 2.0 * A.KERB, ry, Color(1, 1, 1, 0.85))     # a water service trench, curb to curb
	for sx: float in [-1.0, 1.0]:   # tyres turning into the alley
		dec.add(8, Vector2(sx * 2.4, A.AL0 - 2.0), sx * 35.0, 0.6, 6.0, ry, Color(1, 1, 1, 0.45))
	_extras(props, dec, rr, dress)
	root.set_meta("stalls", stalls)
	var wm := dec.build()
	if wm: root.add_child(wm)
	var mi := MeshInstance3D.new(); mi.name = "ground"; mi.mesh = g.build(); mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF; root.add_child(mi)
	var body := StaticBody3D.new(); body.name = "ground_col"; var cs := CollisionShape3D.new(); cs.shape = mi.mesh.create_trimesh_shape(); body.add_child(cs); root.add_child(body)
	props.build(root, K)
	print("%s (%s): ground tris %d, props %d, stalls %d" % [name, dress, g.tri_count(), props.count(), stalls.size()])
	K.save_piece(root, name)


## street trees in the parkway (0.75 m off the kerb), every 9.5 m, clear of the alley apron, the hydrant and the bus pad
static func _trees(props: K.Props, dec: K.Decals, rr: RandomNumberGenerator, sx: float, dress: String, ac: float, aw: float) -> void:
	var sets := {
		"apt": ["tree_magnolia_a", "palm_queen_a", "tree_ficus_a", "palm_queen_b", "tree_magnolia_b", "tree_ficus_b"],
		"civ": ["tree_magnolia_a", "tree_magnolia_b"],
		"grt": ["tree_ficus_a", "palm_mexican_fan_c", "tree_ficus_b", "palm_mexican_fan_a"],
		"wfd": ["palm_mexican_fan_a", "palm_queen_a", "palm_mexican_fan_b", "palm_queen_b", "palm_mexican_fan_c"],
	}
	var sp_list: Array = sets[dress]
	var tz := 24.0
	var k := 0
	while tz < Z1 - 2.0:
		var clear := absf(tz - ac) > aw * 0.5 + 2.5 and not (sx > 0 and absf(tz - HYDRANT) < 2.5) \
			and not (sx < 0 and tz > PAD0 - 2.5 and tz < PAD1 + 2.5)
		if clear:
			var keep := true
			if dress == "grt": keep = rr.randf() < 0.45       # the rest died and were never replaced
			if keep:
				# civic: matched pairs (the same species at the same z on both sides); elsewhere staggered
				var idx := k if dress == "civ" else (k + (1 if sx > 0 else 0))
				var sp: String = sp_list[idx % sp_list.size()]
				var yaw := 0.0 if dress == "civ" else tz * 29.0 + sx * 40.0
				props.add(sp, "normal", Vector3(sx * (A.KERB + 0.75), S.walk_y(0.0), tz), yaw)
				if sp.begins_with("tree_") and rr.randf() < (0.4 if dress == "civ" else 0.7):   # roots lift the sidewalk
					dec.add(rr.randi() % 2, Vector2(sx * (A.PKW + 0.7), tz + rr.randf_range(-0.8, 0.8)), rr.randf_range(60, 120), 1.9, 0.9, S.walk_y, Color(0.3, 0.29, 0.28, 0.8))
			elif dress == "grt":
				# where a tree died: a stump hole in the gravel, darker ground
				dec.add(14, Vector2(sx * (A.KERB + 0.75), tz), rr.randf_range(0, 180), 1.2, 1.2, S.walk_y, Color(0.55, 0.5, 0.45, 0.6))
			k += 1
			tz += 9.5
		else:
			tz += 1.0


## street lamps in the parkway: apt globes staggered (the old pattern; the -x one at the back of the bus zone);
## civ victorian pairs opposite each other; grt cobras (one side, the cheap standard); wfd pier lamps staggered
static func _lamps(props: K.Props, sx: float, dress: String) -> void:
	match dress:
		"apt":
			for lz: float in [33.0, 72.0, 95.0]:
				var z := lz + (2.0 if sx > 0 else -2.0)
				if sx < 0 and lz == 33.0: z = BUS0 + 1.5       # lights the waiting end of the stop, clear of the pad
				props.add("prop_lamp_globe", "worn", Vector3(sx * (A.KERB + 0.6), S.walk_y(0.0), z), 0.0)
		"civ":
			for lz: float in [28.5, 66.0, 94.0]:
				props.add("prop_lamp_victorian", "worn", Vector3(sx * (A.KERB + 0.6), S.walk_y(0.0), lz), 90.0)   # as on Amber (amber_seg)
		"grt":
			if sx > 0:
				for lz: float in [31.0, 70.0]:
					props.add("prop_lamp_cobra", "rusty", Vector3(sx * (A.KERB + 0.6), S.walk_y(0.0), lz), -90.0)    # arm over the road
		"wfd":
			for lz: float in [33.0, 72.0, 95.0]:
				var z2 := lz + (2.0 if sx > 0 else -2.0)
				if sx < 0 and lz == 33.0: z2 = BUS0 + 1.5
				props.add("prop_pier_lamp", "worn", Vector3(sx * (A.KERB + 0.6), S.walk_y(0.0), z2), 0.0)


## per-dress extras with their reasons
static func _extras(props: K.Props, dec: K.Decals, rr: RandomNumberGenerator, dress: String) -> void:
	match dress:
		"civ":
			# bins with recycling at the crosswalk end of each walk (people leaving the civic buildings), a newspaper
			# box at the bus stop; the city sealed its cracks (dark sealant lines)
			for sx: float in [-1.0, 1.0]:
				props.add("prop_trash_receptacle", "worn", Vector3(sx * (A.PROP - 0.5), S.walk_y(0.0), 24.5), 0.0)
				props.add("prop_recycling_receptacle", "worn", Vector3(sx * (A.PROP - 0.5), S.walk_y(0.0), 25.4), 0.0)
			props.add("prop_newspaper_box_blue", "worn", Vector3(-(A.PROP - 0.4), S.walk_y(0.0), 44.4), 90.0)
			for k in 6:
				dec.add(0, Vector2(rr.randf_range(-A.LANE, A.LANE), rr.randf_range(Z0 + 4.0, Z1 - 4.0)), rr.randf_range(0, 180), rr.randf_range(1.5, 3.0), 0.5, S.road_y, Color(0.12, 0.12, 0.12, 0.85))
		"grt":
			# an abandoned shopping cart on the walk (from the market up the street), litter grime round the bus stop
			# bin, a dark trench patch never resurfaced (no square dark tiles on their own: they read as shadows of nothing)
			props.add("prop_shopping_cart", "worn", Vector3(A.PROP - 0.7, S.walk_y(0.0), 78.0), 160.0)
			dec.add(14, Vector2(-(A.PROP - 0.5), 41.6), 0.0, 2.2, 2.2, S.walk_y, Color(1, 1, 1, 0.8))
			dec.add(3, Vector2(-1.8, 34.0), 0.0, 1.1, 16.0, S.road_y, Color(1, 1, 1, 0.7))   # a long narrow water-main trench, softer
			for k in 8:     # broken slabs replaced with fresh concrete over the years (tinted grey, never white)
				var px := (1.0 if k % 2 else -1.0) * rr.randf_range(A.PKW + 0.3, A.PROP - 0.3)
				W.pale_patch(dec, rr, Vector2(px, rr.randf_range(Z0 + 3.0, Z1 - 3.0)), rr.randf_range(0, 90), rr.randf_range(1.0, 1.8), rr.randf_range(1.0, 1.8), S.walk_y, 0.7)
		"wfd":
			# sand carried up from the beach on feet and blown onto both walks
			for k in 10:
				dec.add(4 + k % 2, Vector2((1.0 if k % 2 else -1.0) * rr.randf_range(A.PKW + 0.3, A.PROP - 0.3), rr.randf_range(Z0 + 2.0, Z1 - 2.0)), rr.randf_range(0, 180), rr.randf_range(1.2, 2.8), rr.randf_range(0.6, 1.2), S.walk_y, Color(0.86, 0.79, 0.64, 0.55))


## ======================================================================== residential road kit (group 1, 17 Nov)
## Residential streets use the s_apt cross-section exactly (1+1 lanes 3.3 m, parking 2.4 m, kerb at 5.7, 1.5 m grass
## parkway, 2 m sidewalk to the property line at 9.2, alley aprons at 54-60), so every junction family fits every leg.
## What makes them residential (and why):
##   - no centre line: a quiet two-way street, cars give way to each other; no stall marks (unmarked kerb parking)
##   - one tree species per street (the street was planted at one time), about one tree per house front (12 m),
##     never within 28 m of the junction (the stop-sign sight triangle), clear of the alley mouth, hydrant and lamps
##   - garages are on the alleys (Coronado's village pattern), so the parkway has no driveway cuts
##   - lamps: one on a corner of every junction, one mid-block per leg (staggered along a block by the rotations)
##   - a hydrant every ~100 m (alternate sides) with 15 ft of red kerb each way
##   - drainage: flat legs get a mid-block kerb inlet; on a slope water runs to the low junction (its inlets are in
##     the junction tile), so the gutter shows streaks running downhill and silt where they end
## Slopes: a block between two junctions rises H metres with a smoothstep across the 160 m between the junction
## tiles; each leg carries its half: up-leg H*ss((z-20)/160) for z 20..100, down-leg the same with -H (seen from the
## upper junction), so the two halves meet at mid-block with the same height and grade. Junctions are level pads.
## Max grade = 1.5 H / 160 (H 8 m -> 7.5 %).

## Street trees must clear 2.5 m over the walk and ~4.5 m over the road (pruned). Measured crown bases (lowest leaf
## > 1 m from the trunk): torrey pine 4.8-5.4, queen palm 4.2-7.3, mexican fan 7.4-12, eucalyptus 7-8 (too big for a
## 1.5 m parkway). Every kit broadleaf (coral 1.7-1.9, magnolia 1.8-1.9, ficus 1.6, jacaranda 2.3) is a YARD tree:
## its crown hangs into walkers and parked cars, so it waits for street-pruned versions (Yasin's asset wish list).
## The mix (Yasin 17 Nov: "trees look copy pasted ... can't we have variety"; low crowns over the road are fine, the
## player sees them from street level anyway): a residential street is planted tree by tree over decades, so species,
## ages and spacing vary. Neighbours often share a species (the same owner or builder planted a run of them), then the
## street changes. Weights favour the classic Coronado street trees; ficus is left out (too big for a 1.5 m parkway).
const RES_MIX := [
	[["tree_jacaranda_a", "tree_jacaranda_b"], 0.22, 0.78, 1.12],     # [models, weight, min scale, max scale]
	[["tree_magnolia_a", "tree_magnolia_b"], 0.17, 0.75, 1.1],
	[["tree_coral_a", "tree_coral_b"], 0.14, 0.75, 1.1],
	[["tree_torrey_pine_a", "tree_torrey_pine_b"], 0.17, 0.8, 1.15],
	[["palm_queen_a", "palm_queen_b"], 0.18, 0.85, 1.12],
	[["palm_mexican_fan_a", "palm_mexican_fan_c"], 0.12, 0.85, 1.1],
]

static func _pick_group(rr: RandomNumberGenerator) -> int:
	var tot := 0.0
	for gp: Array in RES_MIX: tot += float(gp[1])
	var x := rr.randf() * tot
	for i in RES_MIX.size():
		x -= float(RES_MIX[i][1])
		if x <= 0.0: return i
	return RES_MIX.size() - 1

const RES_SPECIES := {
	"torrey": ["tree_torrey_pine_a", "tree_torrey_pine_b"],      # San Diego's native pine: the hill streets
	"queen": ["palm_queen_a", "palm_queen_b"],
	"fan": ["palm_mexican_fan_a", "palm_mexican_fan_c"],
}

static func seg_y(H: float, z: float) -> float:
	var t := clampf((z - Z0) / 160.0, 0.0, 1.0)
	return H * t * t * (3.0 - 2.0 * t)

static func seg_grade(H: float, z: float) -> float:
	var t := clampf((z - Z0) / 160.0, 0.0, 1.0)
	return H * 6.0 * t * (1.0 - t) / 160.0


## sidewalk / parkway strip along z (kerb at x = kerb, out to x = outer, z s0..s1) on any height function: the
## surface, the kerb face, and kerb ramps [centre z, width] (run = strip depth). Same look as site.gd sidewalk_strip,
## which only follows the pilot's x-hill.
static func strip_z(g: K.Ground, kerb: float, outer: float, s0: float, s1: float, ramps: Array, mat: String, yr: Callable, yw: Callable, RUN := 1.5, FLARE := 1.0) -> void:
	var depth := absf(outer - kerb); var dir := signf(outer - kerb)
	var zones: Array = []
	var cur := s0
	var rs := ramps.duplicate(); rs.sort_custom(func(p: Array, q: Array) -> bool: return p[0] < q[0])
	for r: Array in rs:
		var a: float = maxf(float(r[0]) - float(r[1]) * 0.5 - FLARE, s0); var b: float = minf(float(r[0]) + float(r[1]) * 0.5 + FLARE, s1)
		if a > cur: zones.append([cur, a, null])
		zones.append([a, b, r]); cur = b
	if cur < s1: zones.append([cur, s1, null])
	for zn: Array in zones:
		var a2: float = zn[0]; var b2: float = zn[1]
		if zn[2] == null:
			g.rect(mat, minf(kerb, outer), a2, maxf(kerb, outer), b2, yw)
			g.wall_line("curb", _dense_z(kerb, a2, b2), yr, yw, -dir)
			continue
		var r2: Array = zn[2]; var c: float = r2[0]; var w: float = r2[1]
		var drop := func(s: float, t: float) -> float:
			var ft := clampf(1.0 - t / RUN, 0.0, 1.0)
			var ds := absf(s - c) - w * 0.5
			var fs := 1.0 if ds <= 0.0 else clampf(1.0 - ds / FLARE, 0.0, 1.0)
			return S.KERB_H * ft * fs
		var ns := maxi(2, ceili((b2 - a2) / 0.35)); var nt := maxi(2, ceili(depth / 0.35))
		for i in ns:
			for j in nt:
				var sa := lerpf(a2, b2, float(i) / ns); var sb := lerpf(a2, b2, float(i + 1) / ns)
				var ta := depth * float(j) / nt; var tb := depth * float(j + 1) / nt
				var P := func(s: float, t: float) -> Vector3:
					var x := kerb + dir * t
					return Vector3(x, float(yw.call(x, s)) - float(drop.call(s, t)), s)
				g.quad("concrete", P.call(sa, ta), P.call(sb, ta), P.call(sb, tb), P.call(sa, tb))
		var kp := PackedVector2Array()
		for i in ns + 1: kp.append(Vector2(kerb, lerpf(a2, b2, float(i) / ns)))
		var top := func(x: float, z: float) -> float: return float(yw.call(x, z)) - float(drop.call(z, 0.0))
		g.wall_line("curb", kp, yr, top, -dir)

static func _dense_z(x: float, a: float, b: float) -> PackedVector2Array:
	var out := PackedVector2Array()
	var n := maxi(1, ceili((b - a) / 4.0))
	for i in n + 1: out.append(Vector2(x, lerpf(a, b, float(i) / n)))
	return out

## red kerb (face + top strip) between z a..b on a kerb at x, on any height function
static func red_kerb_z(dec: K.Decals, x: float, a: float, b: float, road_side: float, yr: Callable, yw: Callable) -> void:
	var n := maxi(1, ceili((b - a) / 2.0))
	for k in n:
		var za := lerpf(a, b, float(k) / n); var zb := lerpf(a, b, float(k + 1) / n)
		var out := Vector3(road_side, 0, 0)
		dec.add_face(13, Vector3(x, yr.call(x, za), za), Vector3(x, yr.call(x, zb), zb), Vector3(x, yw.call(x, zb), zb), Vector3(x, yw.call(x, za), za), out, W.RED)
		dec.add(13, Vector2(x - road_side * 0.075, (za + zb) * 0.5), 0.0, 0.15, zb - za, yw, W.RED, 0.004)

## wheel-path wear along a lane in pieces no longer than 4 m (a longer flat decal would cut into a curved slope)
static func lane_wear_y(dec: K.Decals, rr: RandomNumberGenerator, c: float, s0: float, s1: float, yfn: Callable, a := 0.4) -> void:
	var s := s0 + rr.randf_range(0.0, 3.0)
	while s < s1 - 2.0:
		var L := rr.randf_range(2.5, 4.0)
		for wp: float in [-0.85, 0.85]:
			dec.add(14, Vector2(c + wp, s + L * 0.5), 0.0, 0.7, L, yfn, Color(1, 1, 1, a * rr.randf_range(0.5, 0.8)))
		if rr.randf() < 0.5: dec.add(6, Vector2(c, s + L * 0.5), 0.0, 0.8, L, yfn, Color(1, 1, 1, a * 0.9))
		s += L + rr.randf_range(0.3, 2.5)


## A residential leg (|z| 20..100 along +z). H: the block's rise (0 = flat; this leg carries the first half).
static func res_street(name: String, H: float, species: String) -> void:
	S.hill_on = false
	var root := Node3D.new(); root.name = name
	var g := K.Ground.new(); var props := K.Props.new(); var dec := K.Decals.new(); var rr := W.rng_for(name)
	var yr := func(_x: float, z: float) -> float: return seg_y(H, z)
	var yw := func(_x: float, z: float) -> float: return seg_y(H, z) + S.KERB_H
	var flat := absf(H) < 0.01
	var ac := (A.AL0 + A.AL1) * 0.5; var aw := A.AL1 - A.AL0
	# ---- carriageway: plain asphalt, no paint (tessellated every 4 m so it follows the slope)
	K.painted_rect(g, -A.KERB, Z0, A.KERB, Z1, [], yr)
	# ---- parkway (grass, concrete alley apron), sidewalk
	for sx: float in [-1.0, 1.0]:
		strip_z(g, sx * A.KERB, sx * A.PKW, Z0, A.AL0 - 1.0, [], "grass", yr, yw)
		strip_z(g, sx * A.KERB, sx * A.PKW, A.AL0 - 1.0, A.AL1 + 1.0, [[ac, aw]], "concrete", yr, yw)
		strip_z(g, sx * A.KERB, sx * A.PKW, A.AL1 + 1.0, Z1, [], "grass", yr, yw)
		g.rect("concrete", minf(sx * A.PKW, sx * A.PROP), Z0, maxf(sx * A.PKW, sx * A.PROP), Z1, yw)
	# ---- fixed furniture first (each with its reason), then the trees in the gaps
	var taken := {-1.0: [], 1.0: []}      # z of things in the parkway per side
	var hyd := HYDRANT
	props.add("prop_hydrant_red", "worn", Vector3(A.KERB + 0.7, yw.call(0.0, hyd), hyd), -90.0)
	red_kerb_z(dec, A.KERB, hyd - 4.5, hyd + 4.5, -1.0, yr, yw)
	(taken[1.0] as Array).append(hyd)
	var lz := 78.0        # mid-block lamp, arm over the road (the junction has its own corner lamp)
	props.add("prop_lamp_cobra", "worn", Vector3(A.KERB + 0.6, yw.call(0.0, lz), lz), -90.0)
	(taken[1.0] as Array).append(lz)
	# street sweeping (Coronado sweeps residential streets weekly): one sign per side, past the alley mouth
	for sx: float in [-1.0, 1.0]:
		var sz := 66.0 if sx > 0 else 88.0
		props.add("prop_sign_no_parking", "worn", Vector3(sx * (A.KERB + 0.35), yw.call(0.0, sz), sz), -90.0 * sx)
		(taken[sx] as Array).append(sz)
	if flat:
		for sx: float in [-1.0, 1.0]:
			props.add("prop_storm_drain_curb_inlet", "dirty", Vector3(sx * A.KERB, yr.call(0.0, 50.5), 50.5), -90.0 * sx, false)
			(taken[sx] as Array).append(50.5)
	# trees: an irregular 11-14 m rhythm from 28 m (sight triangle), shifted up to 4 m to clear things, else skipped;
	# "mix" = the planted-over-decades street (RES_MIX), otherwise one species (RES_SPECIES[species])
	var k := 0
	var grp := _pick_group(rr)
	for sx: float in [-1.0, 1.0]:
		var tz := 28.0 + (rr.randf_range(4.0, 8.0) if sx > 0 else rr.randf_range(0.0, 2.0))      # staggered across the street
		while tz < Z1 - 2.0:
			var placed := false
			if species == "mix" and rr.randf() < 0.08:      # a tree that died and was never replaced: an empty, worn patch
				dec.add(14, Vector2(sx * (A.KERB + 0.75), tz), rr.randf_range(0, 180), 1.1, 1.1, yw, Color(0.75, 0.68, 0.55, 0.55))
				tz += rr.randf_range(11.0, 14.0)
				continue
			for shift: float in [0.0, 1.0, 2.0, 3.0, 4.0]:
				var z := tz + shift
				if z > Z1 - 2.0: break
				var ok := not (z > A.AL0 - 3.5 and z < A.AL1 + 3.5)
				for o: float in taken[sx]:
					if absf(z - o) < 3.0: ok = false
				if ok:
					var model := ""; var scl := 1.0
					if species == "mix":
						if rr.randf() < 0.45: grp = _pick_group(rr)     # else the run continues with the same species
						var gp: Array = RES_MIX[grp]
						model = String((gp[0] as Array)[rr.randi() % (gp[0] as Array).size()])
						scl = rr.randf_range(float(gp[2]), float(gp[3]))
					else:
						var sp: Array = RES_SPECIES[species]
						model = String(sp[k % sp.size()])
					props.add(model, "normal", Vector3(sx * (A.KERB + 0.75), float(yw.call(0.0, z)) - 0.06, z), rr.randf_range(0.0, 360.0), true, scl)
					k += 1
					(taken[sx] as Array).append(z)
					# roots lift the sidewalk beside most trees: a crack, and slabs the city replaced (tinted grey)
					if rr.randf() < 0.65: dec.add(rr.randi() % 2, Vector2(sx * (A.PKW + 0.8), z + rr.randf_range(-0.8, 0.8)), rr.randf_range(60, 120), 1.9, 0.9, yw, Color(0.3, 0.29, 0.28, 0.8))
					if rr.randf() < 0.35: W.pale_patch(dec, rr, Vector2(sx * (A.PKW + 1.0), z + rr.randf_range(-1.0, 1.0)), 0.0, 1.9, 1.6, yw, 0.6)
					placed = true
					break
			tz += rr.randf_range(11.0, 14.0)
	# ---- parking: unmarked kerb parking, recorded for the parked-car layer [x, z, yaw, y, grade along z]
	var stalls: Array = []
	for sx: float in [-1.0, 1.0]:
		var blocked: Array = [[A.AL0 - 1.5, A.AL1 + 1.5], [Z0, 27.0]]       # alley mouth; 20 ft clear of the crosswalk
		if sx > 0: blocked.append([hyd - 4.5, hyd + 4.5])
		var d := Z0
		while d + STALL <= Z1:
			var bad := false
			for r: Array in blocked:
				if d + STALL > float(r[0]) and d < float(r[1]): bad = true
			if bad:
				d += 0.5; continue
			var cz := d + STALL * 0.5; var cx := sx * (A.LANE + 1.2)
			var yaw := 180.0 if sx > 0 else 0.0
			stalls.append([cx, cz, yaw, float(yr.call(cx, cz)), seg_grade(H, cz)])     # y and the grade along the piece's z (cars tilt with the street)
			if rr.randf() < 0.6: W.oil(dec, rr, Vector2(cx, cz + (1.2 if sx > 0 else -1.2)), 0.0, yr, rr.randf_range(0.35, 0.7))   # overnight drips under the engine
			d += STALL
	root.set_meta("stalls", stalls)
	# ---- road wear
	for sx: float in [-1.0, 1.0]:
		lane_wear_y(dec, rr, sx * A.LANE * 0.5, Z0, Z1, yr, 0.35)
		W.cracks(dec, rr, minf(sx * 0.3, sx * A.KERB), Z0 + 1.0, maxf(sx * 0.3, sx * A.KERB), Z1 - 1.0, 9, yr, 0.5)
		# gutter: leaves from the street trees, grime; on a slope long streaks running downhill
		var gz := Z0 + 1.0
		while gz < Z1 - 1.5:
			var L := rr.randf_range(1.5, 2.6) if flat else rr.randf_range(2.8, 3.8)
			dec.add(14, Vector2(sx * (A.KERB - 0.28), gz + L * 0.5), 0.0, 0.5, L, yr, Color(0.95, 0.9, 0.82, rr.randf_range(0.45, 0.7)))
			gz += L + (rr.randf_range(2.0, 5.0) if flat else rr.randf_range(0.4, 1.5))
		if not flat:
			# silt fan where the runoff stops: the low end of the leg (the junction for an up-leg, mid-block for a down-leg)
			var low := Z0 + 2.5 if H > 0 else Z1 - 2.5
			dec.add(4 + rr.randi() % 2, Vector2(sx * (A.KERB - 0.6), low), 0.0, 1.2, 3.0, yr, Color(0.62, 0.57, 0.48, 0.6))
	# utility cuts: house water services patched across half the road, a sewer manhole with its old trench patch
	for q: Array in [[-1.0, 37.0], [1.0, 71.0], [-1.0, 93.0]]:
		var qx := float(q[0]) * A.KERB * 0.5
		dec.add(3, Vector2(qx, float(q[1])), 90.0, 1.0, A.KERB - 0.4, yr, Color(1, 1, 1, 0.7))
	props.add("prop_manhole_cover", "worn", Vector3(-1.6, float(yr.call(0.0, 46.0)) + 0.002, 46.0), 0.0, false)
	dec.add(2, Vector2(-1.6, 46.0), 0.0, 2.2, 2.0, yr, Color(1, 1, 1, 0.75))
	for sx: float in [-1.0, 1.0]:      # tyres cutting into the alley, dirt carried across the sidewalk
		dec.add(8, Vector2(sx * 2.4, A.AL0 - 2.0), sx * 35.0, 0.6, 4.0, yr, Color(1, 1, 1, 0.4))
		dec.add(14, Vector2(sx * (A.PKW + 1.0), ac), 0.0, 2.0, aw, yw, Color(1, 1, 1, 0.5))
		var wz := Z0 + 0.5
		while wz < Z1 - 1.0:      # the walking line: light dirt (quiet street)
			var Lw := rr.randf_range(2.0, 4.0)
			dec.add(14, Vector2(sx * rr.randf_range(A.PKW + 0.6, A.PROP - 0.6), wz + Lw * 0.5), 0.0, 1.1, Lw, yw, Color(1, 1, 1, rr.randf_range(0.2, 0.4)))
			wz += Lw + rr.randf_range(2.0, 6.0)
	var wm := dec.build()
	if wm: root.add_child(wm)
	var mi := MeshInstance3D.new(); mi.name = "ground"; mi.mesh = g.build(); mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF; root.add_child(mi)
	var body := StaticBody3D.new(); body.name = "ground_col"; var cs := CollisionShape3D.new(); cs.shape = mi.mesh.create_trimesh_shape(); body.add_child(cs); root.add_child(body)
	props.build(root, K)
	print("%s (res %s, H %.1f, max grade %.1f %%): ground tris %d, props %d, stalls %d" % [name, species, H, absf(seg_grade(H, 100.0)) * 100.0, g.tri_count(), props.count(), stalls.size()])
	K.save_piece(root, name)


## The residential all-way stop (level pad, |x|,|z| <= 20 to the property lines), j_apt's geometry with the
## residential dress: plain two-line crosswalks (a quiet corner: no continental bars), stop bars and stop signs on
## every approach, no centre lines, street names on two corners, one cobra lamp on the NE corner sidewalk (r - 1 from
## the kerb return's centre: on the walk, never on the asphalt), kerb inlets upstream of every crosswalk (the low
## point of each approach), no trees on the corners (the drivers' sight triangle).
static func res_junction(name: String) -> void:
	S.hill_on = false
	var root := Node3D.new(); root.name = name
	var g := K.Ground.new(); var props := K.Props.new(); var dec := K.Decals.new(); var rr := W.rng_for(name)
	var ry := S.road_y
	var J := A.J; var KB := A.KERB
	var XW: Array = [12.6, 15.6]; var STOP: Array = [16.6, 17.1]
	var pa: Array = []
	for sx: float in [-1.0, 1.0]:      # crosswalk lines across the east / west mouths
		for e: float in [XW[0], XW[1] - 0.3]:
			pa.append([minf(sx * e, sx * (e + 0.3)), -KB + 0.15, maxf(sx * e, sx * (e + 0.3)), KB - 0.15, "white"])
	pa.append([STOP[0], -A.LANE, STOP[1], 0.0, "white"])
	pa.append([-STOP[1], 0.0, -STOP[0], A.LANE, "white"])
	K.painted_rect(g, -J, -KB, J, KB, pa, ry)
	for sz: float in [-1.0, 1.0]:
		var ps: Array = []
		for e2: float in [XW[0], XW[1] - 0.3]:
			ps.append([-KB + 0.15, minf(sz * e2, sz * (e2 + 0.3)), KB - 0.15, maxf(sz * e2, sz * (e2 + 0.3)), "white"])
		if sz < 0: ps.append([-A.LANE, -STOP[1], 0.0, -STOP[0], "white"])
		else: ps.append([0.0, STOP[0], A.LANE, STOP[1], "white"])
		K.painted_rect(g, -KB, minf(sz * KB, sz * J), KB, maxf(sz * KB, sz * J), ps, ry)
	var xc: float = (float(XW[0]) + float(XW[1])) * 0.5
	for sx: float in [-1.0, 1.0]:
		for sz: float in [-1.0, 1.0]:
			var c := Vector2(sx * (KB + A.R), sz * (KB + A.R))
			var a0 := atan2(0.0, -sx); var a1 := atan2(-sz, 0.0)
			if a1 - a0 > PI: a1 -= TAU
			if a0 - a1 > PI: a1 += TAU
			var arc := K.arc(c, A.R, a0, a1, 12)
			var fil := arc.duplicate(); fil.append(Vector2(sx * KB, sz * KB)); g.poly("asphalt", fil, ry)
			var dd := (arc[1] - arc[0]).normalized(); var left := Vector2(dd.y, -dd.x)
			g.wall_line("curb", arc, ry, S.walk_y, signf(left.dot((arc[0] - c).normalized())))
			var patch := arc.duplicate()
			patch.append(Vector2(sx * (KB + A.R), sz * A.PROP)); patch.append(Vector2(sx * A.PROP, sz * A.PROP)); patch.append(Vector2(sx * A.PROP, sz * (KB + A.R)))
			g.poly("concrete", patch, S.walk_y)
			var t := KB + A.R
			_pkw_ramp(g, "x", sz * KB, sz * A.PKW, sx * t, sx * J, sx * xc)
			g.rect("concrete", minf(sx * t, sx * J), minf(sz * A.PKW, sz * A.PROP), maxf(sx * t, sx * J), maxf(sz * A.PKW, sz * A.PROP), S.walk_y)
			_pkw_ramp(g, "z", sx * KB, sx * A.PKW, sz * t, sz * J, sz * xc)
			g.rect("concrete", minf(sx * A.PKW, sx * A.PROP), minf(sz * t, sz * J), maxf(sx * A.PKW, sx * A.PROP), maxf(sz * t, sz * J), S.walk_y)
			dec.add(14, Vector2(sx * xc, sz * (KB + 1.6)), 0.0, 3.0, 2.0, S.walk_y, Color(1, 1, 1, 0.35))
			dec.add(14, Vector2(sx * (KB + 1.6), sz * xc), 90.0, 3.0, 2.0, S.walk_y, Color(1, 1, 1, 0.35))
			# leaves blown into the corner gutter
			var gm := c + Vector2(-sx, -sz).normalized() * (A.R + 0.3)
			dec.add(14, gm, 45.0, 2.4, 0.6, ry, Color(0.95, 0.9, 0.82, 0.6))
			if sx > 0 and sz < 0:      # the corner lamp (NE), arm reaching over the crossing
				var lp := c + Vector2(-sx, -sz).normalized() * (A.R - 1.0)
				props.add("prop_lamp_cobra", "worn", Vector3(lp.x, S.walk_y(0.0), lp.y), -45.0)
	props.add("prop_sign_stop", "worn", Vector3(-(KB + 0.6), S.walk_y(0.0), -(STOP[1] + 0.3)), 180.0)
	props.add("prop_sign_stop", "worn", Vector3(KB + 0.6, S.walk_y(0.0), STOP[1] + 0.3), 0.0)
	props.add("prop_sign_stop", "worn", Vector3(STOP[1] + 0.3, S.walk_y(0.0), -(KB + 0.6)), 90.0)
	props.add("prop_sign_stop", "worn", Vector3(-(STOP[1] + 0.3), S.walk_y(0.0), KB + 0.6), -90.0)
	props.add("prop_sign_street_names", "worn", Vector3(KB + 2.4, S.walk_y(0.0), KB + 2.4), 45.0)
	props.add("prop_sign_street_names", "worn", Vector3(-(KB + 2.4), S.walk_y(0.0), -(KB + 2.4)), 45.0)
	for e: Array in [[19.4, -KB, 180.0], [-19.4, KB, 0.0], [KB, 19.4, -90.0], [-KB, -19.4, 90.0]]:
		props.add("prop_storm_drain_curb_inlet", "dirty", Vector3(float(e[0]), ry.call(0.0), float(e[1])), float(e[2]), false)
	props.add("prop_manhole_cover", "worn", Vector3(-1.8, ry.call(0.0) + 0.002, 1.8), 0.0, false)
	for q: Array in [[18.5, -A.LANE * 0.5, 90.0], [-18.5, A.LANE * 0.5, 90.0], [A.LANE * 0.5, 18.5, 0.0], [-A.LANE * 0.5, -18.5, 0.0]]:
		for wp: float in [-0.8, 0.8]:
			var o := Vector2(wp, 0.0) if float(q[2]) == 0.0 else Vector2(0.0, wp)
			dec.add(8, Vector2(float(q[0]), float(q[1])) + o, float(q[2]), 0.45, 3.0, ry, Color(1, 1, 1, 0.3))
		if rr.randf() < 0.7: W.oil(dec, rr, Vector2(float(q[0]), float(q[1])), float(q[2]), ry, 0.5)
	W.cracks(dec, rr, -KB, -KB, KB, KB, 8, ry, 0.5)
	var wm := dec.build()
	if wm: root.add_child(wm)
	var mi := MeshInstance3D.new(); mi.name = "ground"; mi.mesh = g.build(); mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF; root.add_child(mi)
	var body := StaticBody3D.new(); body.name = "ground_col"; var cs := CollisionShape3D.new(); cs.shape = mi.mesh.create_trimesh_shape(); body.add_child(cs); root.add_child(body)
	props.build(root, K)
	print("%s: ground tris %d, props %d" % [name, g.tri_count(), props.count()])
	K.save_piece(root, name)

## parkway strip in a junction tile (flat): grass, with a concrete ramp across it at the crosswalk (as j_apt)
static func _pkw_ramp(g: K.Ground, along: String, kerb: float, pkw: float, a: float, b: float, c: float) -> void:
	var lo := minf(a, b); var hi := maxf(a, b)
	var r0 := c - 1.5; var r1 := c + 1.5
	if r0 > lo: S.sidewalk_strip(g, along, kerb, pkw, lo, r0, [], "grass")
	S.sidewalk_strip(g, along, kerb, pkw, maxf(lo, r0), minf(hi, r1), [[c, 3.0]], "concrete", 1.4, 0.0, 0.6)
	if hi > r1: S.sidewalk_strip(g, along, kerb, pkw, r1, hi, [], "grass")


## PREVIEW ONLY: grass ground under the review street (two junctions 200 m apart along z, the second H higher), cut
## out under the street corridors (|x| <= 9.2 around x 0, |z| <= 9.2 at both junctions). Never placed in the game.
static func review_ground(name: String, H: float) -> void:
	var root := Node3D.new(); root.name = name
	var g := K.Ground.new()
	var yb := func(_x: float, z: float) -> float:
		var t := clampf((z - Z0) / 160.0, 0.0, 1.0)
		return H * t * t * (3.0 - 2.0 * t) + S.KERB_H - 0.02
	for xr: Array in [[-230.0, -A.PROP], [A.PROP, 230.0]]:
		for zr: Array in [[-230.0, -A.PROP], [A.PROP, 200.0 - A.PROP], [200.0 + A.PROP, 430.0]]:
			g.rect("grass", float(xr[0]), float(zr[0]), float(xr[1]), float(zr[1]), yb, 8.0)
	# the cross streets' corridors at both junctions stay open too: (|z| <= 9.2 is already open between the rects)
	var mi := MeshInstance3D.new(); mi.name = "ground"; mi.mesh = g.build(); mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF; root.add_child(mi)
	print("%s: ground tris %d" % [name, g.tri_count()])
	K.save_piece(root, name)


## PREVIEW ONLY: grass ground under a review chain of junctions every 200 m along z (pad heights hs[i] at z = 200 i),
## each block rising with the kit's smoothstep between the junction tiles; cut out under every street corridor.
static func review_ground_chain(name: String, hs: Array) -> void:
	var root := Node3D.new(); root.name = name
	var g := K.Ground.new()
	var n := hs.size()
	var yb := func(_x: float, z: float) -> float:
		var i := clampi(int(floor(z / 200.0)), 0, n - 2)
		var t := clampf((z - 200.0 * i - Z0) / 160.0, 0.0, 1.0)
		return float(hs[i]) + (float(hs[i + 1]) - float(hs[i])) * t * t * (3.0 - 2.0 * t) + S.KERB_H - 0.02
	for xr: Array in [[-230.0, -A.PROP], [A.PROP, 230.0]]:
		var zs: Array = [-230.0]
		for i in n:
			zs.append(200.0 * i - A.PROP); zs.append(200.0 * i + A.PROP)
		zs.append(200.0 * (n - 1) + 230.0)
		for k in range(0, zs.size(), 2):
			g.rect("grass", float(xr[0]), float(zs[k]), float(xr[1]), float(zs[k + 1]), yb, 8.0)
	var mi := MeshInstance3D.new(); mi.name = "ground"; mi.mesh = g.build(); mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF; root.add_child(mi)
	print("%s: ground tris %d" % [name, g.tri_count()])
	K.save_piece(root, name)
