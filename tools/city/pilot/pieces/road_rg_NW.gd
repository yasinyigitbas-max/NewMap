extends RefCounted
## Ring road kit, stage 2 SITE BUILDER, half NW (17 Nov). Brief: map_dc/coronado/city_kit/ROADKIT_SPEC.md. Yasin, 17 Nov:
## "act like an architect, city planner and exterior designer, no jagged edges".
##
## Half NW = the ring sites with v < -900 or u < -900: 1st St on the bay front, Alameda Blvd along the base fence, the
## north end of Glorietta Blvd (5th St to 3rd St, with the bridge gap), their T-junctions and the ring-owned stubs from
## the lattice. Boundary (agreed in the brief: the ring node nearest to v = -900 / u = -900 ON EACH SIDE of the line
## belongs to NW): east, the 6th St T (657.3, -800) and block b141 are NW, so half SE ends with b140 at that T's tile
## edge; west, the J Ave T (-800, 288.7) and b159 are NW (both built by the core stage), so half SE starts with b131.
##
## The ring library road_rg.gd is used READ-ONLY. Everything it decides (geometry, paint, furniture, wear, heights,
## bus spacing) stays its decision; this file only adds what the sites need beyond it, each with its reason:
##  1. STEM OVERRIDES (the measured reality at two stems, applied to the library's cached ring data before any build):
##     - Amber Ave x 1st St (0, -1600): sites.json calls the stem "res", but the amber family built Amber north of 3rd
##       St as the divided avenue (median 2.5, lanes to 9.1, kerb 11.5, walk to 16; their j_am_3rd measured: its north
##       tile edge 22.5 carries that section) and the brief's rule is "any Amber crossing: signals". The T gets the
##       library's "hs" stem (median nose, Amber lanes, signals, kerb 11.5, walk 16).
##     - 3rd St x Alameda Blvd (-950.9, -1400): sites.json calls the stem "couplet", but the locked industrial sample I
##       turned 3rd St into its truck street: its west leg s_ind (measured) ends at 100 m (u -900) with the truck
##       section (4.2 m lanes, edge lines 4.14-4.26, kerb 6.7, walk 8.7). Only 25 m are left to the ring: an arterial
##       taper there would be a jagged stub of lanes appearing and vanishing. The truck street runs on to the ring and
##       meets it like every truck street (Yasin approved 17 Nov: "Truck streets meet the ring with stop control").
##       Decision for Yasin (in the report): the 3rd St / base gate corner is stop-controlled, not signalised.
##     The overrides change the two T's tiles (em / ep), so the height stations, the buildable ranges of the four
##     blocks beside them (all NW) and the bus-stop spacing are recomputed with the library's own rules. Nodes outside
##     NW keep identical bus flags (checked and printed by prepare()).
##  2. STUB STARTS measured on the lattice junctions the stubs leave (nw/edge.gd scratch tool, 17 Nov):
##       art j_ar_g3 / e3 / c3 / b3 / ad3 north mouths 26.0 (the art family's side-street tile; library SEC 20 / 22),
##       amber j_am_3rd north mouth 22.5, resstd j_rs_* / j_res west mouths 20.0, art j_ar_j4 west / ad3 east 22.0.
##       Sections at those edges match the library stubs (res: kerb 5.7, grass parkway to 7.2, walk 9.2, no centre
##       line; std: the same with a double yellow; ind: double yellow, edge lines 4.14-4.26, kerb 6.7, walk 8.7).
##  3. b036 (Amber, 3rd St -> 1st St): built with the amber family's own leg builder (road_amber.build_leg, called, never
##     edited) and its "res" avenue section, so it matches b037 across j_am_3rd exactly; the plan (lines in phase with
##     the T's dashes, the northbound far-side bus stop the amber family asked this stub to carry, lamps, hydrant,
##     inlets at the low end) is written in amber_res_spec() below.
##  4. b079 (4th St, strip sample M -> Glorietta Blvd): M's own arterial leg s_strip_art runs to 100 m (measured: TWLTL
##     yellow edges 1.65-1.75, bike lines 8.72-8.88, kerb 10.3, palm parkway, walk 14.3). The library stub would start
##     with a lattice-junction pocket and arrows 100 m from M's signal; strip_continuation() continues M's paint phase
##     instead and only shapes the approach to the ring T (pocket, arrows, solid lines, broken bike line).
##  5. NAMES: pieces built here are j_rg_nw_* / s_rg_nw_* (the brief); the core stage's NW examples keep their names.
##     T's get the name through the cached node data; boulevard pieces are saved by the library under s_rg_<bid>_<i>
##     and re-saved here under s_rg_nw_<bid>_<i> (restamp: load, rename, save, delete the library-named file; no
##     instance or transform changes).
##  6. PREVIEW-ONLY review grounds zz_ring_nw_ground_<tag> (never in the game): verges along the ring and along every
##     stem following the stub's own height profile, grass round the lattice junctions at their pads, a deep field
##     1.5 m under the nearest road.

const RG := preload("res://tools/city/pilot/pieces/road_rg.gd")
const AM := preload("res://tools/city/pilot/pieces/road_amber.gd")
const K := preload("res://tools/city/pilot/kit_lib.gd")
const S := preload("res://tools/city/pilot/site.gd")
const W := preload("res://tools/city/pilot/pieces/wear_lib.gd")
const RL := preload("res://tools/city/pilot/pieces/road_lib.gd")
const I := preload("res://tools/city/pilot/pieces/ind_lib.gd")

const SITES := "res://map_dc/coronado/city_kit/review/sites.json"
const PIECES := "res://map_dc/coronado/city_kit/pieces/"
const KH := 0.15

## stem section overrides (node key -> library SEC section); reasons in the header (1)
const STEM := {"0.0,-1600.0": "hs", "-950.9,-1400.0": "ind"}
## stub section overrides (the stub of an overridden stem follows it)
const STUB_SEC := {"b064": "ind"}
## stub starts measured on the lattice junctions (header 2), where they differ from the library's SEC z0
const STUB_Z0 := {"b010": 26.0, "b018": 26.0, "b028": 26.0, "b046": 26.0, "b056": 26.0, "b036": 22.5}

## the boundary nodes the brief gives to NW (nearest ring node to the dividing line, on each side of it)
const BOUNDARY := ["657.3,-800.0", "-800.0,288.7"]
## built by the core stage (road kit stage 1) in half NW: served by those pieces, not rebuilt here
const CORE_T := {"-800.0,-1600.0": "j_rg_w800_n1600", "660.0,-1000.0": "j_rg_e660_n1000", "-992.5,200.0": "j_rg_w993_s200", "-800.0,288.7": "j_rg_w800_s289"}
const CORE_S := {"b000": "s_rg_b000", "b087": "s_rg_b087", "b158_2": "s_rg_b158_2", "b159_1": "s_rg_b159_1", "b159_2": "s_rg_b159_2"}

static var _ready := false

static func is_nw(u: float, v: float) -> bool:
	return v < -900.0 or u < -900.0 or BOUNDARY.has(RG.nkey(u, v))

## Apply the overrides to the library's cached ring (once per process) and return it. Every build starts here.
static func prepare() -> Dictionary:
	var R := RG.ring()
	if _ready: return R
	var path: RG.Path = R["path"]
	var bus0 := {}
	for k: String in R["nodes"]: bus0[k] = bool(R["nodes"][k].get("bus", false))
	for k: String in STEM:
		var nd: Dictionary = R["nodes"][k]
		var sec: String = STEM[k]
		(nd["stem"] as Dictionary)["sec"] = sec
		var sg: bool = RG.SEC[sec]["signal"]
		nd["ctl"] = "signal" if sg else "stop"
		nd["tg"] = RG._tgeom(path, nd["o"], float(nd["s"]), (nd["stem"] as Dictionary)["dir"], sec, sg)
		nd["em"] = float(nd["tg"]["em"]); nd["ep"] = float(nd["tg"]["ep"])
		print("NW override %s: stem %s, ctl %s, em %.2f ep %.2f z_E %.2f" % [k, sec, nd["ctl"], nd["em"], nd["ep"], float(nd["tg"]["z_E"])])
	# height stations (the library's ring_h reads R.st): level pads on the tiles, smoothstep between the tile edges
	var st: Array = []
	for k: String in R["order"]:
		var nd: Dictionary = R["nodes"][k]
		st.append([float(nd["s"]), float(nd["pad"]), float(nd["em"]), float(nd["ep"])])
	R["st"] = st
	# bus stops with the library's rule: every signalised T, plus stop T's so stops are never more than ~330 m apart
	var ks: Array = R["order"]
	var first := 0
	for i in ks.size():
		if String(R["nodes"][ks[i]]["ctl"]) == "sample": first = i
	var last_s: float = R["nodes"][ks[first]]["s"]
	for j in ks.size():
		var nd: Dictionary = R["nodes"][ks[(first + j) % ks.size()]]
		var s: float = nd["s"]
		var dist := fposmod(s - last_s, path.length)
		var ctl := String(nd["ctl"])
		var bus := ctl == "signal" or ctl == "sample" or (ctl == "stop" and dist >= RG.BUS_SPACING)
		nd["bus"] = bus and ctl != "sample"
		if bus: last_s = s
	for k: String in R["nodes"]:
		var nd: Dictionary = R["nodes"][k]
		if bool(nd["bus"]) != bool(bus0[k]):
			print("NW bus %s: %s -> %s%s" % [k, str(bus0[k]), str(nd["bus"]), "" if is_nw(float(nd["u"]), float(nd["v"])) else "   OUTSIDE NW: CHECK"])
	# buildable ranges and grades of every block (the library's rule)
	for id: String in R["blocks"]:
		var bk: Dictionary = R["blocks"][id]
		var A: Dictionary = R["nodes"][bk["na"]]; var Bn: Dictionary = R["nodes"][bk["nb"]]
		bk["r0"] = float(bk["sa"]) + float(A["ep"]); bk["r1"] = float(bk["sb"]) - float(Bn["em"])
		var span: float = float(bk["r1"]) - float(bk["r0"])
		bk["grade"] = 1.5 * absf(float(bk["rise"])) / maxf(span, 1.0) if span > 1.0 else 0.0
	RG._BL.clear()
	# names: the T's this half builds
	for k: String in R["nodes"]:
		var nd: Dictionary = R["nodes"][k]
		if is_nw(float(nd["u"]), float(nd["v"])) and not CORE_T.has(k) and String(nd["ctl"]) in ["signal", "stop"]:
			nd["piece"] = "j_rg_nw_" + RG.nid(float(nd["u"]), float(nd["v"]))
	_ready = true
	return R

## ------------------------------------------------------------------------------------------------ the half's sites
## T's to build (ring nodes of half NW with a stem, not built by the core, not the bridge)
static func t_keys() -> Array:
	var R := prepare()
	var out: Array = []
	for k: String in R["order"]:
		var nd: Dictionary = R["nodes"][k]
		if is_nw(float(nd["u"]), float(nd["v"])) and not CORE_T.has(k) and String(nd["ctl"]) in ["signal", "stop"]: out.append(k)
	return out

## ring blocks of half NW (b159 is the core's; b160 the bridge ramp is a hero piece)
const RING_BLOCKS := ["b141", "b142", "b143", "b144", "b163", "b145", "b146", "b147", "b148", "b149", "b150", "b162",
	"b151", "b152", "b153", "b154", "b155", "b156", "b157", "b158", "b159"]
## ring-owned lattice blocks (stubs) of half NW
const STUBS := ["b000", "b010", "b018", "b028", "b036", "b046", "b056", "b064", "b071", "b072", "b079", "b080", "b087",
	"b088", "b096", "b102", "b108", "b116", "b124"]

## boulevard parts this half builds: [{name (s_rg_nw_...), lib (library name), bid, i, s0, s1}]
static func boulevard_parts() -> Array:
	prepare()
	var out: Array = []
	for bid: String in RING_BLOCKS:
		for e: Dictionary in RG.block_plan(bid):
			var key := "%s_%d" % [bid, int(e["i"])]
			if CORE_S.has(key): continue
			out.append({"name": "s_rg_nw_" + key, "lib": String(e["name"]), "bid": bid, "i": int(e["i"]), "s0": float(e["s0"]), "s1": float(e["s1"])})
	return out

## ------------------------------------------------------------------------------------------------------- builders
static func build_t(key: String) -> void:
	prepare()
	RG.build_t(key)

static func build_boulevard(bid: String, part: int) -> void:
	prepare()
	_clean_layout(bid)
	RG.build_boulevard(bid, part)
	restamp("s_rg_%s_%d" % [bid, part], "s_rg_nw_%s_%d" % [bid, part], {})

## The promenade's planting strip (library block_layout): succulents are set every ~3.5 m without looking at the canary
## palms and pier lamps of the same strip, so some grew into a palm trunk or a lamp base (validator: 18 overlaps on
## 1st St). A gardener plants round a palm (its root plate and the trunk's skirt need ~1.6 m) and keeps a lamp base
## clear for the maintenance crew (~1.8 m): those succulents are taken out of the block's layout before any piece of
## the block is built (the layout is cached per block, so every part sees the same cleaned list).
static func _clean_layout(bid: String) -> void:
	var lay: Dictionary = RG.block_layout(bid)
	if lay.get("nw_clean", false): return
	var keep: Array = []
	var gone := 0
	for pm: Array in lay["plant"]:
		var m := String(pm[2])
		if m.begins_with("palm"):
			keep.append(pm); continue
		var ok := true
		for q: Array in lay["plant"]:
			if String(q[2]).begins_with("palm") and Vector2(float(q[0]) - float(pm[0]), float(q[1]) - float(pm[1])).length() < 1.6: ok = false
		for it: Array in lay["items"]:
			if String(it[0]) in ["prop_pier_lamp", "prop_park_bench", "prop_bike_rack", "prop_trash_receptacle", "prop_drinking_fountain", "prop_beach_sign_rules", "prop_bus_shelter"] \
				and Vector2(float(it[2]) - float(pm[0]), float(it[3]) - float(pm[1])).length() < 1.8: ok = false
		if ok: keep.append(pm)
		else: gone += 1
	lay["plant"] = keep
	if gone > 0: print("NW planting %s: %d succulents kept clear of palms / lamps / bay furniture" % [bid, gone])
	# Kerb inlets: every T puts an inlet just upstream of its ring crossing (road_rg build_t: +1 side at the T's tile
	# start, -1 side at its tile end). A flat block's own every-70 m inlets ignore them, so a second grate could sit a
	# few metres before the T's on the same kerb (seen on 1st St at G Ave): the city builds one inlet per low point,
	# so the block's inlet within 12 m of a T's on the same kerb is left out.
	var R := prepare()
	var bk: Dictionary = R["blocks"][bid]
	var A: Dictionary = R["nodes"][bk["na"]]; var Bn: Dictionary = R["nodes"][bk["nb"]]
	var S0: float = lay["S0"]; var S1: float = lay["S1"]
	var items: Array = []
	var dropped := 0
	for it2: Array in lay["items"]:
		if String(it2[0]) == "prop_storm_drain_curb_inlet":
			var sv: float = it2[2]; var side := signf(float(it2[3]))
			var near_b := String(Bn["ctl"]) in ["signal", "stop"] and side > 0.0 and sv > S1 - 12.0
			var near_a := String(A["ctl"]) in ["signal", "stop"] and side < 0.0 and sv < S0 + 12.0
			if near_a or near_b:
				dropped += 1; continue
		items.append(it2)
	lay["items"] = items
	if dropped > 0: print("NW inlets %s: %d block inlets left out next to a T's own" % [bid, dropped])
	lay["nw_clean"] = true

## load a saved piece, rename it (and merge meta), save it under the new name, delete the old file. Nothing else moves.
static func restamp(old: String, nw: String, meta: Dictionary) -> void:
	var p := PIECES + old + ".scn"
	var ps: PackedScene = ResourceLoader.load(p, "", ResourceLoader.CACHE_MODE_IGNORE)
	var root: Node3D = ps.instantiate()
	root.scene_file_path = ""
	root.name = nw
	for k: String in meta: root.set_meta(k, meta[k])
	K.save_piece(root, nw)
	root.free()
	if old != nw:
		var err := DirAccess.remove_absolute(ProjectSettings.globalize_path(p))
		print("NW restamp %s -> %s (removed the library-named file: %s)" % [old, nw, error_string(err)])

## the stub plan with this half's overrides (section, measured start, name)
static func stub_plan(bid: String) -> Dictionary:
	prepare()
	var pl := RG.stub_plan(bid)      # z1 from the (overridden) T's z_E
	pl["name"] = "s_rg_nw_" + bid
	if STUB_SEC.has(bid): pl["sec"] = STUB_SEC[bid]
	if STUB_Z0.has(bid): pl["z0"] = STUB_Z0[bid]
	return pl

static func build_stub(bid: String) -> void:
	prepare()
	match bid:
		"b036": _build_b036()
		"b079": _build_strip_cont(bid)
		_: _build_stub_generic(bid)

## the library's build_stub with the plan above (same section builders, same reasons: road_rg.gd)
static func _build_stub_generic(bid: String) -> void:
	S.hill_on = false
	var pl := stub_plan(bid)
	var name: String = pl["name"]
	var sec: String = pl["sec"]
	var z0: float = pl["z0"]; var z1: float = pl["z1"]; var Lb: float = pl["len"]
	var H: float = float(pl["pad1"]) - float(pl["pad0"])
	var hz := func(z: float) -> float: return H * RG._ss((z - z0) / maxf(z1 - z0, 1.0))
	var gz := func(z: float) -> float:
		var t := clampf((z - z0) / maxf(z1 - z0, 1.0), 0.0, 1.0)
		return H * 6.0 * t * (1.0 - t) / maxf(z1 - z0, 1.0)
	var yr := func(_x: float, z: float) -> float: return float(hz.call(z))
	var yw := func(_x: float, z: float) -> float: return float(hz.call(z)) + KH
	var root := Node3D.new(); root.name = name
	var g := K.Ground.new(); var props := K.Props.new(); var dec := K.Decals.new(); var rr := W.rng_for(name)
	var stalls: Array = []
	var Lr := Lb - 25.0          # the T's sight triangle: no trees closer to the ring junction than this
	match sec:
		"res", "std":
			RG._stub_two_lane(g, props, dec, rr, sec, z0, z1, Lr, H, hz, gz, yr, yw, stalls)
		"strip", "couplet":
			RG._stub_art(g, props, dec, rr, z0, z1, Lr, H, yr, yw)
		"ind":
			_stub_ind(g, props, dec, rr, z0, z1, H, yr, yw)
		_:
			push_error("NW: no stub builder for section %s" % sec)
	_finish_stub(root, g, props, dec, pl, stalls, {})

static func _finish_stub(root: Node3D, g: K.Ground, props: K.Props, dec: K.Decals, pl: Dictionary, stalls: Array, extra: Dictionary) -> void:
	var H: float = float(pl["pad1"]) - float(pl["pad0"])
	var z0: float = pl["z0"]; var z1: float = pl["z1"]
	var site := {"site": pl["bid"], "kind": "stub", "sec": pl["sec"], "pos": [float((pl["o"] as Vector2).x), float(pl["pad0"]), float((pl["o"] as Vector2).y)],
		"yaw": pl["yaw"], "z": [z0, z1], "street": pl["street"], "max_grade": absf(1.5 * H / maxf(z1 - z0, 1.0)), "t_node": pl["t"], "lattice": pl["lattice"]}
	for k: String in extra: site[k] = extra[k]
	RG._finish(root, g, props, dec, String(pl["name"]), {"rg": site, "stalls": stalls})

## ---------------------------------------------------------------------------------------------- b036: Amber 3rd -> 1st
## The amber family's "res" avenue (road_amber.gd header: median with queen palms, edge line, free unmarked kerb
## parking, 2 m grass parkway with RES_MIX trees, sprinklers, carriage steps and mulch frontages, cobras over the four
## lanes, 2.5 m walk). Planned here for this block:
##  - lines: the approach to j_am_3rd (+x, southbound) solid for its last 20 m as b037's, then 3 m dashes in the ring
##    T's own phase (the T paints its departure dashes with the loop-global 12 m cycle along its stem), so a dash
##    crossing the joint is never cut short; the approach to the ring T (-x, northbound) solid for its last 20 m.
##  - the northbound far-side bus stop of 3rd St (the amber family's interface note: this stub carries it): bench and
##    boarding pad, red kerb, the sign at the front door.
##  - heights: the whole 6 m fall from j_am_3rd (pad 8) to the ring (pad 2) on one smoothstep between the two tiles
##    (max grade 1.5 * 6 / span < 6 %); inlets at the low end take the water before the ring T's crossing, one more
##    half-way where the gutter runs fastest.
##  - no street trees in the last 25 m (the signal's sight triangle), cobras staggered, a hydrant mid-block.
static func amber_res_spec() -> Dictionary:
	var pl := stub_plan("b036")
	var z0: float = pl["z0"]; var z1: float = pl["z1"]; var Lb: float = pl["len"]
	var H: float = float(pl["pad1"]) - float(pl["pad0"])
	var app: Array = []
	# T dashes at stem s in [12k, 12k + 3] -> stub z = Lb - s - 3 .. Lb - s
	var k := floori((Lb - z0) / 12.0)
	var solid_end := z0 + 20.0
	while k >= 0:
		var a := Lb - 12.0 * k - 3.0; var b := Lb - 12.0 * k
		if b > z1 + 1e-3:
			if a < z1 - 0.05: app.append([a, z1])      # the dash the T carries on across the joint: its first part
			break
		if b > solid_end + 1e-3:
			if a <= solid_end + 1e-3: solid_end = b      # the first dash runs into the solid line: one line
			else: app.append([a, b])
		k -= 1
	app.push_front([z0, solid_end])
	var dep: Array = []
	var ds := z1 - 20.0
	var e := ds - 9.0
	while e - 3.0 >= z0 + 3.0:
		dep.push_front([e - 3.0, e]); e -= 12.0
	dep.append([ds, z1])
	var palms: Array = []
	var mz := z0 + 8.5
	while mz < z1 - 6.0:
		palms.append(mz); mz += 12.0
	var lamps: Array = []
	var lz := z0 + 5.0; var ls := -1.0
	while lz < z1 - 4.0:
		lamps.append([lz, ls]); lz += 21.0; ls = -ls
	return {"sec": "res", "z0": z0, "z1": z1, "prof": [[z0, z1, H]], "nose": true, "age": "mid",
		"lines": {"app": app, "dep": dep}, "arrows": ["left_through", "through_right"],
		"bus": {"a": z0 + 4.0, "b": z0 + 29.0, "kind": "bench"},
		"palms": palms, "fan": 0.15, "lamps": lamps, "hyd": [(z0 + z1) * 0.5 + 6.0, 1.0], "trees_to": minf(Lb - RG.SIGHT, z1 - 3.0),
		"mulch": 0.18, "carriage": 0.22,
		"inlets": [[z1 - 3.0, 1.0], [z1 - 3.0, -1.0], [(z0 + z1) * 0.5, -1.0]],
		"manholes": [[-7.4, z0 + 30.0], [7.4, z0 + 80.0], [-7.4, z0 + 125.0]],
		"trenches": [[5.8, z0 + 58.0, 6.4]],
		"extras": [
			["prop_sign_speed25", "worn", -1.0, z0 + 46.0, 0.35, "street"],      # the northbound traffic leaving 3rd St, past the stop
			["prop_sign_no_parking", "worn", 1.0, z0 + 52.0, 0.35, "street"],    # street sweeping (weekly), one sign per side
			["prop_sign_no_parking", "worn", -1.0, z0 + 96.0, 0.35, "street"],
		]}

static func _build_b036() -> void:
	var pl := stub_plan("b036")
	var spec := amber_res_spec()
	AM.build_leg(String(pl["name"]), spec)
	var H: float = float(pl["pad1"]) - float(pl["pad0"])
	var site := {"site": "b036", "kind": "stub", "sec": "amber_res", "pos": [float((pl["o"] as Vector2).x), float(pl["pad0"]), float((pl["o"] as Vector2).y)],
		"yaw": pl["yaw"], "z": [float(pl["z0"]), float(pl["z1"])], "street": pl["street"], "t_node": pl["t"], "lattice": pl["lattice"],
		"max_grade": absf(1.5 * H / maxf(float(pl["z1"]) - float(pl["z0"]), 1.0)), "built_by": "road_amber.build_leg (amber family's res avenue, called read-only)"}
	restamp(String(pl["name"]), String(pl["name"]), {"rg": site})

## ------------------------------------------------------------------------------- b079: M's arterial on to the ring T
## Section exactly as s_strip_art (strip_lib: TL 1.8, L1 5.3, L2 8.8, kerb 10.3, palm parkway 12.3, walk 14.3). Frame:
## +z from M's junction toward the ring, -x drives +z (eastbound, toward the T), +x drives -z (westbound, toward M).
## Paint continues M's own phases where they run out at 100 (TWLTL inner dashes every 9 m, eastbound lane line every
## 12 m), then the approach to the T: the centre lane becomes the left-turn pocket (its edge toward the eastbound lanes
## turns white), the eastbound lane line goes solid for the last 20 m, smooth arrows (left in the pocket and the inner
## lane, right in the outer lane: no through movement at a T), the bike line broken where right turners cross it.
## The westbound lane line runs its dashes evenly from M's last dash to the one the T's paint carries across the joint.
static func _build_strip_cont(bid: String) -> void:
	S.hill_on = false
	var pl := stub_plan(bid)
	var name: String = pl["name"]
	var z0: float = pl["z0"]; var z1: float = pl["z1"]; var Lb: float = pl["len"]
	var H: float = float(pl["pad1"]) - float(pl["pad0"])
	var yr := func(_x: float, z: float) -> float: return H * RG._ss((z - z0) / maxf(z1 - z0, 1.0))
	var yw := func(x: float, z: float) -> float: return float(yr.call(x, z)) + KH
	var root := Node3D.new(); root.name = name
	var g := K.Ground.new(); var props := K.Props.new(); var dec := K.Decals.new(); var rr := W.rng_for(name)
	var TL := RG.TL; var L1 := RG.L1; var L2 := RG.L2; var KB := RG.KB; var PK := RG.PK; var PR := RG.PR
	var p: Array = []; var arrows: Array = []
	var zp := z1 - 22.0          # the pocket starts here (it runs on through the T tile to the stop bar)
	# centre lane: north edge yellow throughout; south edge yellow to the pocket, then white (the pocket's lane edge)
	p.append([TL - 0.15, z0, TL - 0.05, z1, "yellow"])
	p.append([-TL + 0.05, z0, -TL + 0.15, zp, "yellow"]); p.append([-TL + 0.05, zp, -TL + 0.2, z1, "white"])
	# TWLTL inner dashes: M's phase (58 + 9k from M's junction), up to 6 m before the pocket
	var d := 58.0
	while d + 3.0 <= zp - 6.0 + 1e-3:
		if d >= z0 - 1e-3:
			p.append([TL - 0.42, d, TL - 0.32, d + 3.0, "yellow"]); p.append([-TL + 0.32, d, -TL + 0.42, d + 3.0, "yellow"])
		d += 9.0
	# eastbound lane line (-x): M's departure phase (28 + 12k), solid for the last 20 m
	var sol := z1 - 20.0
	d = 28.0
	while d < sol:
		if d >= z0 - 1e-3:
			if d + 3.0 > sol: sol = d
			else: p.append([-L1 - 0.06, d, -L1 + 0.06, d + 3.0, "white"])
		d += 12.0
	p.append([-L1 - 0.06, sol, -L1 + 0.06, z1, "white"])
	# westbound lane line (+x): from M's last dash (91-94) to the dash the T carries across the joint (T stem s 24-27)
	var t_dash := Lb - 27.0
	var m_end := 94.0
	var n := 3
	var gap := (t_dash - m_end - 3.0 * n) / float(n + 1)
	for i in n:
		var a := m_end + gap * (i + 1) + 3.0 * i
		p.append([L1 - 0.06, a, L1 + 0.06, a + 3.0, "white"])
	if t_dash < z1: p.append([L1 - 0.06, t_dash, L1 + 0.06, z1, "white"])
	# bike lines: westbound solid; eastbound broken (1 m on, 1 m off) over the last 30 m where right turners cross it
	p.append([L2 - 0.08, z0, L2 + 0.08, z1, "white"])
	p.append([-L2 - 0.08, z0, -L2 + 0.08, z1 - 30.0, "white"])
	var kk := z1 - 30.0
	while kk + 1.0 <= z1 + 1e-3:
		p.append([-L2 - 0.08, kk, -L2 + 0.08, kk + 1.0, "white"]); kk += 2.0
	# arrows (site frame: a driver moving +z has his left on +x)
	arrows.append(S.arrow2("left", 0.0, z1 - 10.5, z1 - 6.0))
	arrows.append(S.arrow2("left", -(TL + L1) * 0.5, z1 - 10.5, z1 - 6.0))
	arrows.append(S.arrow2("right", -(L1 + L2) * 0.5, z1 - 10.5, z1 - 6.0))
	for a2: Dictionary in arrows: p.insert(0, (a2["box"] as Array) + ["-"])
	K.painted_rect(g, -KB, z0, KB, z1, p, yr)
	for a3: Dictionary in arrows: K.fill_arrow(g, a3, yr)
	# kerbs, palm parkways, walks (as M's)
	for sx: float in [-1.0, 1.0]:
		RL.strip_z(g, sx * KB, sx * PK, z0, z1, [], "grass", yr, yw)
		g.rect("concrete", minf(sx * PK, sx * PR), z0, maxf(sx * PK, sx * PR), z1, yw)
	# furniture, each with its reason
	var taken := {-1.0: [], 1.0: []}
	# cobras over the road in M's 34 m rhythm (M: south 36 / 70, north 54 / 88)
	for e: Array in [[-1.0, 104.0], [1.0, 122.0]]:
		var sx2: float = e[0]; var lz: float = e[1]
		if lz < z1 - 2.0:
			props.add("prop_lamp_cobra", "rusty", Vector3(sx2 * (KB + 0.9), float(yw.call(0.0, lz)), lz), -90.0 * sx2); (taken[sx2] as Array).append([lz, 3.0])
	# a hydrant for the lots on the north side, red kerb 4.5 m each way
	var hz := z0 + 17.0
	props.add("prop_hydrant_red", "rusty", Vector3(KB + 0.7, float(yw.call(0.0, hz)), hz), -90.0)
	RL.red_kerb_z(dec, KB, hz - 4.5, hz + 4.5, -1.0, yr, yw); (taken[1.0] as Array).append([hz, 3.0])
	# bike lanes: no parking, a sign each side facing the road
	for e2: Array in [[-1.0, z0 + 8.0], [1.0, z0 + 27.0]]:
		var sx3: float = e2[0]; var sz: float = e2[1]
		props.add("prop_sign_no_parking", "worn", Vector3(sx3 * (KB + 0.35), float(yw.call(0.0, sz)), sz), -90.0 * sx3); (taken[sx3] as Array).append([sz, 1.0])
	# flat: an inlet each side mid-way (the ring T keeps its own crossings dry)
	for e3: Array in [[-1.0, z0 + 13.0], [1.0, z0 + 30.0]]:
		var sx4: float = e3[0]; var iz: float = e3[1]
		props.add("prop_storm_drain_curb_inlet", "dirty", Vector3(sx4 * KB, float(yr.call(0.0, iz)), iz), -90.0 * sx4, false); (taken[sx4] as Array).append([iz, 3.0])
	props.add("prop_manhole_cover", "worn", Vector3(-3.5, float(yr.call(0.0, z0 + 15.0)) + 0.002, z0 + 15.0), 0.0, false)
	dec.add(2, Vector2(-3.5, z0 + 15.0), 0.0, 2.2, 2.2, yr, Color(1, 1, 1, 0.75))
	# Mexican fan palms (the strip's signature, as M's parkway), ~11 m, outside the T's sight triangle (28 m)
	for sx5: float in [-1.0, 1.0]:
		var z := z0 + (3.0 if sx5 > 0.0 else 7.0)
		while z < minf(z1 - 2.0, Lb - RG.SIGHT):
			if RG._free(taken[sx5], z, 2.2):
				var m: String = ["palm_mexican_fan_a", "palm_mexican_fan_b", "palm_mexican_fan_c"][rr.randi() % 3]
				props.add(m, "normal", Vector3(sx5 * (KB + 1.0), float(yw.call(0.0, z)) - 0.06, z), rr.randf_range(0, 360), true, rr.randf_range(0.82, 1.15))
				z += rr.randf_range(10.0, 12.5)
			else:
				z += 1.0
	# wear: four lanes of wheel paths, the left-turn queue (oil), braking marks at the T approach, cracks, gutter grit,
	# dust on the walks blown off the strip's lots
	for lc: float in [-(L1 + L2) * 0.5, -(TL + L1) * 0.5, (TL + L1) * 0.5, (L1 + L2) * 0.5]: RL.lane_wear_y(dec, rr, lc, z0, z1, yr, 0.42)
	for k in 4: W.oil(dec, rr, Vector2(rr.randf_range(-1.0, 1.0), rr.randf_range(zp + 1.0, z1 - 2.0)), 0.0, yr, 0.8)
	for lc2: float in [-(TL + L1) * 0.5, -(L1 + L2) * 0.5]:
		for wp: float in [-0.8, 0.8]: dec.add(8, Vector2(lc2 + wp, z1 - 3.5), 0.0, 0.45, 6.0, yr, Color(1, 1, 1, 0.45))
	for sx6: float in [-1.0, 1.0]:
		W.cracks(dec, rr, minf(sx6 * 2.0, sx6 * 9.5), z0 + 1.0, maxf(sx6 * 2.0, sx6 * 9.5), z1 - 1.0, 5, yr, 0.5)
		var gz := z0 + 1.0
		while gz < z1 - 1.5:
			var L := rr.randf_range(1.6, 2.8)
			dec.add(14, Vector2(sx6 * (KB - 0.3), gz + L * 0.5), 0.0, 0.55, L, yr, Color(0.95, 0.9, 0.82, rr.randf_range(0.4, 0.62)))
			gz += L + rr.randf_range(2.0, 5.0)
		var wz := z0 + 0.5
		while wz < z1 - 1.0:
			var Lw := rr.randf_range(2.0, 5.0)
			dec.add(14, Vector2(sx6 * (PK + 1.0), wz + Lw * 0.5), 0.0, 1.4, Lw, yw, Color(1, 1, 1, rr.randf_range(0.3, 0.5)))
			wz += Lw + rr.randf_range(2.0, 6.0)
	dec.add(3, Vector2(-(TL + L1) * 0.5, z0 + 21.0), 0.0, 1.2, 8.0, yr, Color(1, 1, 1, 0.7))      # a gas service trench along the lane
	_finish_stub(root, g, props, dec, pl, [], {"continues": "s_strip_art (strip sample M, east leg, ends at 100)"})

## ======================================================================================== truck street stub
## A copy of road_rg._stub_ind (read-only there) with one change, the hydrant's place (see below). Every other rule and
## its reason as in road_rg.gd: 4.2 m lanes, double yellow, shoulders to 6.7 (trucks pull over), 2 m walk, 10 m aprons
## every 35 m (the plots' gates), no street trees, cobras on one side, no-parking signs at the aprons, heavy wear.
static func _stub_ind(g: K.Ground, props: K.Props, dec: K.Decals, rr: RandomNumberGenerator, z0: float, z1: float, H: float, yr: Callable, yw: Callable) -> void:
	var LN := 4.2; var KBi := 6.7; var PRi := 8.7; var AW := 10.0
	var aprons: Array = []
	var a := z0 + 18.0
	while a + AW * 0.5 < z1 - 14.0:
		aprons.append(a); a += 35.0
	var p: Array = [[-0.2, z0, -0.1, z1, "yellow"], [0.1, z0, 0.2, z1, "yellow"]]
	for sx: float in [-1.0, 1.0]:
		var cur := z0
		for ap: float in aprons:
			p.append([sx * LN - 0.06, cur, sx * LN + 0.06, ap - AW * 0.5, "white"]); cur = ap + AW * 0.5
		p.append([sx * LN - 0.06, cur, sx * LN + 0.06, z1, "white"])
	for i in p.size():
		var q: Array = p[i]
		p[i] = [minf(float(q[0]), float(q[2])), q[1], maxf(float(q[0]), float(q[2])), q[3], q[4]]
	K.painted_rect(g, -KBi, z0, KBi, z1, p, yr)
	var ramps: Array = []
	for ap: float in aprons: ramps.append([ap, AW])
	for sx: float in [-1.0, 1.0]:
		RL.strip_z(g, sx * KBi, sx * PRi, z0, z1, ramps, "concrete", yr, yw, 2.0, 1.5)
		for ap: float in aprons:
			props.add("prop_sign_no_parking", "dirty", Vector3(sx * (KBi + 0.5), float(yw.call(0.0, ap - AW * 0.5 - 1.0)), ap - AW * 0.5 - 1.0), -90.0 * sx)
			W.pale_patch(dec, rr, Vector2(sx * (LN + 1.3), ap), 0.0, 2.6, AW - 1.0, yr, 0.7)
			dec.add(8, Vector2(sx * 3.2, ap + 4.0), sx * 30.0, 0.7, 6.0, yr, Color(1, 1, 1, 0.55))
			dec.add(8, Vector2(sx * 3.2, ap - 4.0), -sx * 30.0, 0.7, 6.0, yr, Color(1, 1, 1, 0.55))
		RL.lane_wear_y(dec, rr, sx * LN * 0.5, z0, z1, yr, 0.5)
		for k in maxi(2, int((z1 - z0) / 15.0)): W.oil(dec, rr, Vector2(sx * (LN + 1.25), rr.randf_range(z0 + 3.0, z1 - 3.0)), 0.0, yr, 0.85)
		W.cracks(dec, rr, minf(sx * 0.3, sx * KBi), z0 + 1.0, maxf(sx * 0.3, sx * KBi), z1 - 1.0, maxi(4, int((z1 - z0) / 7.0)), yr, 0.3)
		var wz := z0 + 0.5
		while wz < z1 - 1.0:
			var Lw := rr.randf_range(2.0, 5.0)
			dec.add(14, Vector2(sx * rr.randf_range(KBi + 0.5, PRi - 0.5), wz + Lw * 0.5), 0.0, 1.1, Lw, yw, Color(1, 1, 1, rr.randf_range(0.35, 0.6)))
			wz += Lw + rr.randf_range(1.0, 4.0)
	var lz := z0 + 10.0
	while lz < z1 - 3.0:
		var ok := true
		for ap: float in aprons:
			if absf(lz - ap) < AW * 0.5 + 1.5: ok = false
		if ok: props.add("prop_lamp_cobra", "rusty", Vector3(KBi + 0.9, float(yw.call(0.0, lz)), lz), -90.0)
		lz += 40.0 if ok else 3.0
	# the hydrant: mid-way between the first two plot gates (the plots' fire service), or mid-stub; never next to the
	# lattice junction's own corner hydrant (NW change from road_rg: there it stood 6 m from the corner one)
	var hz2 := (z0 + z1) * 0.5 - 6.0     # beside the mid-stub inlets (a flat stub drains there), not on them
	if aprons.size() >= 2: hz2 = (float(aprons[0]) + float(aprons[1])) * 0.5
	hz2 = clampf(hz2, z0 + 3.0, z1 - 3.0)
	props.add("prop_hydrant_red", "rusty", Vector3(-(KBi + 0.6), float(yw.call(0.0, hz2)), hz2), 90.0)
	RL.red_kerb_z(dec, -KBi, hz2 - 4.5, hz2 + 4.5, 1.0, yr, yw)
	var low := (z0 + z1) * 0.5 if absf(H) < 0.01 else (z0 + 2.5 if H > 0.0 else z1 - 2.5)
	for sx: float in [-1.0, 1.0]: props.add("prop_storm_drain_curb_inlet", "dirty", Vector3(sx * KBi, float(yr.call(0.0, low)), low), -90.0 * sx, false)
	var mz := z0 + 20.0
	props.add("prop_manhole_cover", "worn", Vector3(-2.0, float(yr.call(0.0, mz)) + 0.002, mz), 0.0, false)
	dec.add(3, Vector2(-2.1, mz + 6.0), 0.0, 1.0, 12.0, yr, Color(1, 1, 1, 0.7))      # the sewer trench, patched


## ===================================================================================== PREVIEW-ONLY review ground
## zz_ring_nw_ground_<tag> in GRID coordinates (row pos [0, 0, -8000]); never placed in the game.
## spec: {"ring": [s0, s1], "stems": [node keys], "boxes": [[u0, v0, u1, v1], ...], "no_quads": [lattice keys another
## ground already covers]}
##  - the ring's verges as the library's (coast side one 45 m verge, inland verges between the stem corners), at the
##    walk height minus 2 cm (the library's review ground does the same)
##  - every stem's verges from its corner X to the lattice junction, FOLLOWING THE STUB'S HEIGHT (the library's ground
##    keeps them at the T pad, which leaves a rising stub floating), 1 cm lower than the ring's
##  - grass quadrants round each stem's lattice junction at its pad (outside the junction's widest street corridor)
##  - a deep field 1.5 m under the nearest road (ring or stub)
static func build_review_ground(name: String, spec: Dictionary) -> void:
	var R := prepare()
	var path: RG.Path = R["path"]
	var g := K.Ground.new()
	var root := Node3D.new(); root.name = name
	var rs: Array = spec["ring"]
	var r0: float = rs[0]; var r1: float = rs[1]
	var inl: float = R["inland"]; var out := -inl
	var W_ := 45.0
	var ys := func(s: float) -> float: return RG.ring_h(s) - 0.02
	var ctx := RG._ctx(path, Vector2.ZERO, ys)
	var skip: Array = []
	for k: String in spec.get("stems", []):
		var tg: Dictionary = R["nodes"][k]["tg"]
		skip.append([float(tg["lo"]["s_X"]), float(tg["hi"]["s_X"])])
		(ctx["extra"] as Array).append_array([float(tg["lo"]["s_X"]), float(tg["hi"]["s_X"])])
	RG._finalize(ctx, r0, r1)
	var bo: float = RG.PR
	for bid: String in R["blocks"]:
		var bk: Dictionary = R["blocks"][bid]
		if float(bk["sb"]) > r0 and float(bk["sa"]) < r1: bo = maxf(bo, float(bk["outer"]))
	RG._band(g, ctx, minf(out * bo, out * (bo + W_)), maxf(out * bo, out * (bo + W_)), r0, r1, [], "grass", KH)
	var cur := r0
	skip.sort_custom(func(a: Array, b: Array) -> bool: return float(a[0]) < float(b[0]))
	for sk: Array in skip:
		if float(sk[0]) > cur: RG._band(g, ctx, minf(inl * RG.PR, inl * (RG.PR + W_)), maxf(inl * RG.PR, inl * (RG.PR + W_)), cur, float(sk[0]), [], "grass", KH)
		cur = maxf(cur, float(sk[1]))
	if cur < r1: RG._band(g, ctx, minf(inl * RG.PR, inl * (RG.PR + W_)), maxf(inl * RG.PR, inl * (RG.PR + W_)), cur, r1, [], "grass", KH)
	# stems: the stub's profile (stub frame z from the lattice node; T frame s from the ring node: z = Lb - s)
	var stubs: Array = []      # [lattice pt, dir to T, Lb, z0, z1, pad0, pad1, prop half width]
	for k: String in spec.get("stems", []):
		var nd: Dictionary = R["nodes"][k]
		var tg: Dictionary = nd["tg"]
		var bid := String(nd["stem"]["block"])
		var pl := stub_plan(bid)
		var Lb: float = pl["len"]; var z0: float = pl["z0"]; var z1: float = pl["z1"]
		var p0: float = pl["pad0"]; var p1: float = pl["pad1"]
		var hstem := func(sv: float) -> float:
			var z := Lb - sv
			return p0 + (p1 - p0) * RG._ss((z - z0) / maxf(z1 - z0, 1.0))
		var ds: Vector2 = tg["ds"]; var o: Vector2 = nd["o"]
		var psd: float = maxf(float(tg["ps"]), 16.0 if bid == "b036" else float(tg["ps"]))
		stubs.append([pl["o"], -ds, Lb, z0, z1, p0, p1, psd])
		var stem := RG.Path.new(); stem.add_line(o, o + ds * 400.0)
		var c2 := RG._ctx(stem, Vector2.ZERO, func(sv: float) -> float: return float(hstem.call(sv)) - 0.03)
		var zmax := Lb - 45.0      # up to the lattice node's grass quadrants (45 m round it)
		c2["extra"] = []
		RG._finalize(c2, 0.0, zmax)
		for c: Dictionary in [tg["lo"], tg["hi"]]:
			var j: float = c["j"]
			var zz := float(c["zX"])
			if zmax > zz + 1.0:
				RG._band(g, c2, minf(j * psd, j * (psd + 20.0)), maxf(j * psd, j * (psd + 20.0)), zz, zmax, [], "grass", KH)
		# the lattice junction's surroundings: four grass quadrants at its pad, outside its widest corridor
		var lp: Vector2 = pl["o"]
		if (spec.get("no_quads", []) as Array).has(String(pl["lattice"])): continue
		var cw := _lattice_corridor(String(pl["lattice"]))
		var yq := p0 + KH - 0.04
		var yfq := func(_x: float, _z: float) -> float: return yq
		for qx: Array in [[-45.0, -cw], [cw, 45.0]]:
			for qz: Array in [[-45.0, -cw], [cw, 45.0]]:
				g.rect("grass", lp.x + float(qx[0]), lp.y + float(qz[0]), lp.x + float(qx[1]), lp.y + float(qz[1]), yfq, 8.0)
	# deep field: 1.5 m under the nearest road (the ring or a stub)
	var deep := func(x: float, z: float) -> float:
		var q := Vector2(x, z)
		var pr := path.project(q)
		var best := absf(pr.y); var h := RG.ring_h(pr.x)
		for sb: Array in stubs:
			var a: Vector2 = sb[0]; var dd: Vector2 = sb[1]
			var Lb2: float = sb[2]
			var zl := clampf((q - a).dot(dd), 0.0, Lb2)
			var dist := (q - (a + dd * zl)).length()
			if dist < best:
				best = dist
				h = float(sb[5]) + (float(sb[6]) - float(sb[5])) * RG._ss((zl - float(sb[3])) / maxf(float(sb[4]) - float(sb[3]), 1.0))
		return h - 1.5
	for bx: Array in spec["boxes"]:
		g.rect("grass", float(bx[0]), float(bx[1]), float(bx[2]), float(bx[3]), deep, 10.0)
	var mi := MeshInstance3D.new(); mi.name = "ground"; mi.mesh = g.build(); mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF; root.add_child(mi)
	print("%s: ground tris %d" % [name, g.tri_count()])
	K.save_piece(root, name)

## half width of the widest street corridor at a lattice node (property lines of its legs' sections)
static func _lattice_corridor(key: String) -> float:
	var d: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(SITES))
	var wmax := 9.2
	for n: Dictionary in d["nodes"]:
		if RG.nkey(float(n["u"]), float(n["v"])) != key: continue
		for lg: Dictionary in n["legs"]:
			var w: float = {"res": 9.2, "std": 9.2, "ind": 8.7, "couplet": 14.3, "strip": 14.3, "hs": 16.0, "cc": 16.0, "ring": 18.3}.get(String(lg["section"]), 9.2)
			if String(lg["name"]).begins_with("Amber"): w = 16.0
			wmax = maxf(wmax, w)
	return wmax + 0.5
