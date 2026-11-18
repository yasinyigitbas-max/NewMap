extends RefCounted
## Ring road kit, stage 2 SITE BUILDER, half SE (17 Nov). Brief: map_dc/coronado/city_kit/ROADKIT_SPEC.md. Yasin, 17 Nov:
## "act like an architect, city planner and exterior designer, no jagged edges".
##
## Half SE = every ring-owned site that is not in half NW (NW: v < -900 or u < -900, plus the ring node nearest to the
## dividing line on each side of it): Ocean Blvd from the J Ave T's east tile edge (b131) to the waterfront sample W,
## both W transitions, Glorietta Blvd from the 10th St T on the curve north to the 6th St T's south tile edge (b140),
## their T-junctions and the ring-owned stubs from the lattice (G / E / C / Amber / B Ave south of 11th St, 6th-10th St
## east of Adela, 11th St from B Ave to W). Boundaries (agreed with half NW, written in road_rg_NW.gd too): the J Ave T
## (-800, 288.7) and the 6th St T (657.3, -800) are NW pieces; this half meets them at their tile edges (b131 starts at
## the J Ave T's +s edge, b140 ends at the 6th St T's -s edge). The stub b095 (6th St, Adela -> the 6th St T) is SE.
##
## The ring library road_rg.gd is used READ-ONLY. Everything it decides (geometry, paint, furniture, wear, heights,
## bus rule) stays its decision; this file adds only what the SE sites need beyond it, each with its reason:
##  1. BUS STOP AT B AVE x OCEAN BLVD (the hotel / beach corner). The library's rule ("a stop-controlled T gets stops
##     when the last stop pair is >= 330 m back") never looks ahead, so on Ocean Blvd east of Amber it leaves 667 m
##     without a stop (Amber's signals at s 300 -> the waterfront W at s 968), against Yasin's approved rule (17 Nov:
##     "plus enough stop-controlled T's that stops are never more than ~330 m apart"). B Ave is the hotel and beach
##     corner, the busiest stop on the beach front: it gets far-side stops both ways (250 m after Amber, 418 m before
##     W, the ring's usual ~400 m rhythm elsewhere). Nodes outside SE are untouched (checked: prepare() prints them).
##     This changes the block layouts of b135 and b161 (the library lays a block out once with one random stream), so
##     b161 part 2, which the core stage built as an example, is rebuilt here as s_rg_se_b161_2 from the new layout
##     (its palms / plants must run on from part 1 without a doubled or missing palm at the joint). The core's file
##     s_rg_b161_2.scn is left as it was (restored byte for byte after the library build) and is NOT in this half's
##     table.
##  2. STUB STARTS measured on the lattice junctions they leave (se/edge.gd scratch tool, 17 Nov): every resstd junction
##     j_rs_4r_c / 4r_d / 1l3r_b / 2l2r_opp_a / 2l2r_adj_a / 3l1r_d / 4r_e / t_rrr_a and the locked j_res end at 20.0
##     toward the ring with the res section (kerb 5.7, grass parkway to 7.2, walk to 9.2; the 11th St east leg of
##     j_rs_2l2r_opp_a also carries the std double yellow at 0.1-0.2); j_am_11th's south edge is 17.5 with Amber's hs
##     section (the core's s_rg_b045 joins it; the amber family checked that joint). The library's SEC z0 (20 / 17.5)
##     is right for every SE stub: no override.
##  3. b130 (11th St, B Ave x 11th -> the waterfront W): a lattice block whose far end is the locked sample W, not a
##     ring T, so the library's stub plan cannot place it (W has no T geometry). Built here (b130_plan / _build_b130):
##     the std section (s_apt / s_wfd: double yellow, stall ticks, grass parkway, 2 m walk) from j_rs_2l2r_opp_a's east
##     tile edge (z 20, measured) to W's own west leg end (s_wfd ends at 100 m from W, measured: z 220). ROADKIT_SPEC 6:
##     a block next to a locked sample takes the WHOLE rise in the new leg: 6.0 -> W's pad 1.35 (-4.65 m) on one
##     smoothstep over 200 m, max grade 3.5 %. It is a std collector, so it carries the eastbound far-side bus stop
##     after B Ave (W's own west leg carries the westbound one), lamps every ~42 m, hydrants every ~100 m, inlets at
##     mid-block and at the low end before W, and the bay drive's palms start on its last 70 m (people see the water).
##  4. NAMES: pieces built here are j_rg_se_* / s_rg_se_* (the brief). T's get the name through the cached node data;
##     boulevard pieces are saved by the library under s_rg_<bid>_<i> and re-saved here under s_rg_se_<bid>_<i>
##     (restamp: load, rename, save, delete the library-named file; no instance or transform changes). Where a
##     library-named file existed before (the core's s_rg_b161_2), its bytes are put back afterwards.
##  5. THE W TRANSITIONS are rebuilt here (s_rg_se_b161_w, s_rg_se_b136_w). The core stage built its examples before the
##     waterfront pad changed from 2.0 to 1.35 (ROADKIT_SPEC 6, 17:15): their "rg" meta still reads y 2.0 at W, so they
##     would stand 0.65 m above W's own legs and above Ocean Blvd's new end (b161 now falls 2.65 m to 1.35). The
##     library builds them from today's data (south: flat at 1.35; north: 1.35 at W rising to the 10th St T's 4.0 over
##     90 m, 4.4 %). The core's files stay untouched (restored byte for byte) and are not in this half's table.
##  6. TWO LIBRARY RULES THAT COLLIDE, fixed here (the validator's overlap check found them; road_rg.gd stays as it is):
##     - the promenade's planting strip: the library sows succulents every ~3.5 m and a canary date palm every ~45 m
##       without checking one against the other or against the pier lamps standing at the strip's edge, so an agave
##       grows into a palm trunk or round a lamp post. _fix_prom() (run on the library's cached block layout before a
##       boulevard piece is cut from it, so both pieces of a block see the same result) gives a big agave that touches
##       anything a small one, and leaves a gap (bare mulch) where even that would touch: a gardener plants round a
##       trunk and keeps a lamp's base clear for the maintenance crew.
##     - the residential stubs' kerb inlets: the library puts a flat stub's inlets 3 m either side of mid-block
##       without looking at what is already at the kerb, so one landed on the street-sweeping sign's post (b017) and
##       others in the alley's dropped-kerb apron (b035, b123), where a car's wheels would drop into the grate.
##       _stub_two_lane() here is the library's residential / standard stub copied unchanged except for the inlets: the
##       nearest free kerb spot to the planned one, 2.5 m clear of every sign, lamp and hydrant and of the apron flares.
##  7. MARKED CROSSINGS AT THE BEACH / BUS T's, AND UTILITY CUTS THAT READ AS REPAIRS (road_rg.build_t / build_boulevard are
##     copied below as _t_lib / _boulevard_lib, unchanged except the lines marked SE):
##     - The library marks crossings across the ring only at signals, so at a stop-controlled T a bus rider had to cross
##       four lanes and two bike lanes to the far-side stop with nothing painted, and nobody could reach the beach from
##       the avenues. Ocean Blvd's T's are the beach accesses of every avenue (real Coronado marks them), and the
##       Glorietta T's with bus stops (9th, 7th St) are where riders cross to the golf-side stop. These T's (XING) get a
##       continental crosswalk across the ring on their +s side, the side of the +s far-side stop), ramps both sides, yield-to-pedestrians shark teeth 6 m before it across the -s approach
##       lanes (the +s approach meets it right after the mouth), a pedestrian crossing sign facing each approach, a bin
##       where people wait. The T tile grows on its +s side to hold it (ep), so the blocks after these T's start later
##       and the height stations are recomputed with the library's rule (only SE blocks change).
##     - The library patches its utility cuts with tile 3 (a dark patch) in 0.8 x 4 m pieces: at street level they read
##       as three dark squares in the lane, the "shadows of nothing" the coordinator listed (ROADKIT_SPEC 8). A real
##       trench repair shows its saw-cut outline sealed with black crack sealant and a slightly darker fill:
##       _trench_s / _trench_t / _trench_xz draw exactly that (fill pieces abutting, alpha 0.2; sealant lines 5 cm,
##       in pieces no longer than 3 m so they follow curves and slopes). The duct trench is drawn only at signals (a
##       stop-controlled T has no signal ducts to cut).
##     With these two changes the core stage's examples at SE sites are rebuilt here too (s_rg_se_b131_1/_2, b009,
##     j_rg_se_e0_s340, j_rg_se_e627_s0) so the half has one look; the core's files are untouched and not in the table.
##     Only s_rg_b045 (the Amber stub, no cuts, joint checked by the amber family) stays the core's.
##  8. PREVIEW-ONLY review ground zz_ring_se_ground (never in the game), the approach of road_rg_NW.gd's review ground
##     (copied here, not shared: the halves never touch each other's files): verges along the ring, along every stem
##     FOLLOWING THE STUB'S HEIGHT, along the W transitions (morphing section) and along b130, grass quadrants round
##     the lattice junctions at their pads, the waterfront W's land side at its pad 1.35, and a deep field 1.5 m under
##     the nearest road (ring, stub, b130, W transition).

const RG := preload("res://tools/city/pilot/pieces/road_rg.gd")
const K := preload("res://tools/city/pilot/kit_lib.gd")
const S := preload("res://tools/city/pilot/site.gd")
const W := preload("res://tools/city/pilot/pieces/wear_lib.gd")
const RL := preload("res://tools/city/pilot/pieces/road_lib.gd")
const I := preload("res://tools/city/pilot/pieces/ind_lib.gd")

const SITES := "res://map_dc/coronado/city_kit/review/sites.json"
const PIECES := "res://map_dc/coronado/city_kit/pieces/"
const KH := 0.15

## reason: header (1)
const BUS_ADD := {"250.0,345.0": "B Ave x Ocean Blvd (hotel and beach corner): closes the 667 m gap between Amber's signals and W"}
## the boundary nodes the brief gives to NW (nearest ring node to the dividing line, on each side of it)
const BOUNDARY_NW := ["657.3,-800.0", "-800.0,288.7"]
## built by the core stage (road kit stage 1) at SE sites: served by those pieces, not rebuilt here
const CORE_T := {}
const CORE_S := {"b045": "s_rg_b045"}
## the core's examples that this half REBUILDS (header 1, 5, 7): not in this half's table
const CORE_SUPERSEDED := {"s_rg_b161_2": "s_rg_se_b161_2 (the B Ave bus stop changes b161's layout; sealed utility cuts)",
	"s_rg_b161_w": "s_rg_se_b161_w (built for W's old pad 2.0; W is at 1.35 now)",
	"s_rg_b136_w": "s_rg_se_b136_w (built for W's old pad 2.0; W is at 1.35 now)",
	"s_rg_b131_1": "s_rg_se_b131_1 (sealed utility cut instead of three dark squares)",
	"s_rg_b131_2": "s_rg_se_b131_2 (sealed utility cut; the G Ave T's crossing does not change its range)",
	"s_rg_b009": "s_rg_se_b009 (kerb inlets clear of signs and aprons; sealed water-service cut)",
	"j_rg_e0_s340": "j_rg_se_e0_s340 (the signal duct trench as a sealed cut)",
	"j_rg_e627_s0": "j_rg_se_e627_s0 (no signal duct trench at a stop-controlled T)"}
## T's with a marked crossing across the ring (header 7): Ocean Blvd's beach accesses, Glorietta's bus T's
const XING := {"-600.0,302.0": "G Ave: beach access", "-400.0,315.3": "E Ave: beach access, bus stops", "-200.0,328.0": "C Ave: beach access",
	"250.0,345.0": "B Ave: the hotel's beach access, bus stops", "647.0,-200.0": "9th St: bus stops", "654.7,-600.0": "7th St: bus stops"}
const XING_YIELD := 6.0     # shark teeth this far before the crosswalk (MUTCD: 20-50 ft)
## ring blocks of half SE in loop order (b136 has no boulevard: the core's W transition s_rg_b136_w carries it)
const RING_BLOCKS := ["b131", "b132", "b133", "b134", "b135", "b161", "b137", "b138", "b139", "b140"]
## ring-owned lattice blocks (stubs) of half SE; b130 is built by _build_b130 (header 3)
const STUBS := ["b009", "b017", "b027", "b035", "b045", "b055", "b095", "b101", "b107", "b115", "b123", "b130"]

static var _ready := false

static func is_se(u: float, v: float) -> bool:
	return not (v < -900.0 or u < -900.0 or BOUNDARY_NW.has(RG.nkey(u, v)))

## Apply this half's additions to the library's cached ring (once per process) and return it. Every build starts here.
static func prepare() -> Dictionary:
	var R := RG.ring()
	if _ready: return R
	for k: String in BUS_ADD:
		var nd: Dictionary = R["nodes"][k]
		if not is_se(float(nd["u"]), float(nd["v"])): push_error("SE: bus addition outside SE: " + k)
		print("SE bus %s: %s -> true (%s)" % [k, str(nd.get("bus", false)), BUS_ADD[k]])
		nd["bus"] = true
	# the marked crossings (header 7): on the T's +s side, the tile grows to hold the crosswalk and the yield line
	var path: RG.Path = R["path"]
	for k: String in XING:
		var nd: Dictionary = R["nodes"][k]
		var tg: Dictionary = nd["tg"]
		var s_n: float = nd["s"]
		var x0: float = float(tg["hi"]["s_t"]) + RG.XW_GAP
		tg["xing"] = [x0, x0 + RG.XW_W]
		tg["yield"] = x0 + RG.XW_W + XING_YIELD
		var ep := ceilf((float(tg["yield"]) + 0.9 + 1.5 - s_n) * 2.0) / 2.0
		print("SE crossing %s (%s): crosswalk %.2f..%.2f, ep %.2f -> %.2f" % [k, XING[k], x0, x0 + RG.XW_W, float(nd["ep"]), ep])
		tg["ep"] = ep; nd["ep"] = ep
	# height stations and buildable ranges with the library's rules (level pads, smoothstep between the tile edges)
	var st: Array = []
	for k: String in R["order"]:
		var nd: Dictionary = R["nodes"][k]
		st.append([float(nd["s"]), float(nd["pad"]), float(nd["em"]), float(nd["ep"])])
	R["st"] = st
	for id: String in R["blocks"]:
		var bk: Dictionary = R["blocks"][id]
		var A: Dictionary = R["nodes"][bk["na"]]; var Bn: Dictionary = R["nodes"][bk["nb"]]
		bk["r0"] = float(bk["sa"]) + float(A["ep"]); bk["r1"] = float(bk["sb"]) - float(Bn["em"])
		var span: float = float(bk["r1"]) - float(bk["r0"])
		bk["grade"] = 1.5 * absf(float(bk["rise"])) / maxf(span, 1.0) if span > 1.0 else 0.0
	RG._BL.clear()       # block layouts are recomputed with the stop and the new ranges
	for k: String in R["nodes"]:
		var nd: Dictionary = R["nodes"][k]
		if is_se(float(nd["u"]), float(nd["v"])) and not CORE_T.has(k) and String(nd["ctl"]) in ["signal", "stop"]:
			nd["piece"] = "j_rg_se_" + RG.nid(float(nd["u"]), float(nd["v"]))
	_ready = true
	return R

## ------------------------------------------------------------------------------------------------ the half's sites
## T's to build (ring nodes of half SE with a stem, not built by the core, not the bridge / W)
static func t_keys() -> Array:
	var R := prepare()
	var out: Array = []
	for k: String in R["order"]:
		var nd: Dictionary = R["nodes"][k]
		if is_se(float(nd["u"]), float(nd["v"])) and not CORE_T.has(k) and String(nd["ctl"]) in ["signal", "stop"]: out.append(k)
	return out

## boulevard parts this half builds: [{name (s_rg_se_...), lib (library name), bid, i, s0, s1}]
static func boulevard_parts() -> Array:
	prepare()
	var out: Array = []
	for bid: String in RING_BLOCKS:
		for e: Dictionary in RG.block_plan(bid):
			var key := "%s_%d" % [bid, int(e["i"])]
			if CORE_S.has(key): continue
			out.append({"name": "s_rg_se_" + key, "lib": String(e["name"]), "bid": bid, "i": int(e["i"]), "s0": float(e["s0"]), "s1": float(e["s1"])})
	return out

## ------------------------------------------------------------------------------------------------------- builders
static func build_t(key: String) -> void:
	prepare()
	_t_lib(key)

static func build_boulevard(bid: String, part: int) -> void:
	prepare()
	_fix_prom(bid)
	_boulevard_lib(bid, part)     # saves s_rg_se_<bid>_<part> (the library's own file name is never written)

## a W transition ("S" -> s_rg_se_b161_w, "N" -> s_rg_se_b136_w) from today's data (header 5)
static func build_w(side: String) -> void:
	prepare()
	var lib: String = RG.w_plan(side)["name"]
	var p := PIECES + lib + ".scn"
	var keep := PackedByteArray()
	if FileAccess.file_exists(p): keep = FileAccess.get_file_as_bytes(p)
	RG.build_w_transition(side)
	restamp(lib, lib.replace("s_rg_", "s_rg_se_"), {})
	if keep.size() > 0:
		var f := FileAccess.open(p, FileAccess.WRITE); f.store_buffer(keep); f.close()
		print("SE kept the core's %s (restored, %d bytes)" % [lib, keep.size()])

## load a saved piece, rename it (and merge meta), save it under the new name, delete the old file. Nothing else moves.
## (the same steps as road_rg_NW.restamp; copied, the halves share no file)
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
		print("SE restamp %s -> %s (removed the library-named file: %s)" % [old, nw, error_string(err)])

## the stub plan with this half's name (the library's plan is right for every SE stub but b130: header 2, 3)
static func stub_plan(bid: String) -> Dictionary:
	prepare()
	if bid == "b130": return b130_plan()
	var pl := RG.stub_plan(bid)
	pl["name"] = "s_rg_se_" + bid
	return pl

static func build_stub(bid: String) -> void:
	prepare()
	if bid == "b130": _build_b130()
	else: _build_stub_generic(bid)

## the library's build_stub with this half's name (same section builders, same reasons: road_rg.gd)
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
			_stub_two_lane(g, props, dec, rr, sec, z0, z1, Lr, H, hz, gz, yr, yw, stalls)
		"strip", "couplet":
			RG._stub_art(g, props, dec, rr, z0, z1, Lr, H, yr, yw)
		"ind":
			RG._stub_ind(g, props, dec, rr, z0, z1, H, yr, yw)
		"hs":
			RG._stub_hs(g, props, dec, rr, z0, z1, Lr, H, hz, gz, yr, yw, stalls)
		_:
			push_error("SE: no stub builder for section %s" % sec)
	_finish_stub(root, g, props, dec, pl, stalls, {})

static func _finish_stub(root: Node3D, g: K.Ground, props: K.Props, dec: K.Decals, pl: Dictionary, stalls: Array, extra: Dictionary) -> void:
	var H: float = float(pl["pad1"]) - float(pl["pad0"])
	var z0: float = pl["z0"]; var z1: float = pl["z1"]
	var site := {"site": pl["bid"], "kind": "stub", "sec": pl["sec"], "pos": [float((pl["o"] as Vector2).x), float(pl["pad0"]), float((pl["o"] as Vector2).y)],
		"yaw": pl["yaw"], "z": [z0, z1], "street": pl["street"], "max_grade": absf(1.5 * H / maxf(z1 - z0, 1.0)), "t_node": pl["t"], "lattice": pl["lattice"],
		"built_by": "half SE (road_rg_SE.gd over road_rg.gd)"}
	for k: String in extra: site[k] = extra[k]
	RG._finish(root, g, props, dec, String(pl["name"]), {"rg": site, "stalls": stalls})

## ------------------------------------------------------------------------------------------- header (6): fixes
## footprint radius of a kit model (half the diagonal of its manifest footprint; tree / palm trunks 0.3 as the validator)
static func _rad(base: String) -> float:
	if base.begins_with("palm_") or base.begins_with("tree_"): return 0.3
	if base.begins_with("prop_lamp_cobra"): return 0.25
	var e := K.manifest(base)
	return 0.5 * Vector2(float(e.get("footprint_w", 0.5)), float(e.get("footprint_d", 0.5))).length()

## the promenade planting strip: no succulent into a palm trunk, a lamp post or a bay's furniture (header 6)
static func _fix_prom(bid: String) -> void:
	var lay := RG.block_layout(bid)
	if lay.has("se_fixed"): return
	var path: RG.Path = RG.ring()["path"]
	var fixed: Array = []        # [pos, radius] of everything already standing
	for e: Array in lay["items"]:
		fixed.append([path.at(float(e[2]), float(e[3])), _rad(String(e[0]))])
	for pm: Array in lay["plant"]:
		if String(pm[2]).begins_with("palm"): fixed.append([path.at(float(pm[0]), float(pm[1])), 0.3])
	var out: Array = []
	var n_small := 0; var n_drop := 0
	for pm: Array in lay["plant"]:
		var m := String(pm[2])
		if m.begins_with("palm"):
			out.append(pm); continue
		var q := path.at(float(pm[0]), float(pm[1]))
		var tries: Array = [m]
		if m != "plant_agave_americana_small": tries.append("plant_agave_americana_small")
		var put := ""
		for cand: String in tries:
			var r := _rad(cand) * float(pm[3]) * 0.95
			var ok := true
			for f: Array in fixed:
				if q.distance_to(f[0] as Vector2) < r + float(f[1]): ok = false; break
			if ok: put = cand; break
		if put == "":
			n_drop += 1; continue
		if put != m: n_small += 1
		out.append([pm[0], pm[1], put, pm[3]])
		fixed.append([q, _rad(put) * float(pm[3]) * 0.95])
	lay["plant"] = out
	lay["se_fixed"] = true
	if n_small + n_drop > 0: print("SE prom %s: %d plants made small, %d left out (a palm, a lamp or bay furniture there)" % [bid, n_small, n_drop])

## road_rg._stub_two_lane copied unchanged except the kerb inlets (header 6): the residential / standard stub (the s_apt
## cross-section, road_lib's residential dress generalised to any length and rise)
static func _stub_two_lane(g: K.Ground, props: K.Props, dec: K.Decals, rr: RandomNumberGenerator, sec: String, z0: float, z1: float, Lr: float, H: float, hz: Callable, gz: Callable, yr: Callable, yw: Callable, stalls: Array) -> void:
	var KBs := 5.7; var PKs := 7.2; var PRs := 9.2; var LN := 3.3
	var AL0 := 54.0; var AL1 := 60.0
	var alley := z1 - AL1 >= 12.0 and AL0 > z0 + 8.0      # the block's alley meets the street only where it fits
	var flat := absf(H) < 0.01
	var hside := 1.0 if rr.randf() < 0.5 else -1.0
	var hyd := z0 + 20.0
	# kerb parking, recorded for the parked-car layer [x, z, yaw, y, grade]: 7 m clear of the lattice crosswalk, 5 m short
	# of the ring tile (its stop bar and crosswalk are just beyond), clear of the hydrant and the alley mouth
	var marks: Array = []
	for sx: float in [-1.0, 1.0]:
		var blocked: Array = [[z0, z0 + 7.0], [z1 - 5.0, z1]]
		if alley: blocked.append([AL0 - 1.5, AL1 + 1.5])
		if sx == hside: blocked.append([hyd - 4.5, hyd + 4.5])
		var d := z0
		while d + 6.5 <= z1:
			var bad := false
			for r: Array in blocked:
				if d + 6.5 > float(r[0]) and d < float(r[1]): bad = true
			if bad:
				d += 0.5; continue
			var cz := d + 3.25; var cx := sx * (LN + 1.2)
			stalls.append([cx, cz, 180.0 if sx > 0.0 else 0.0, float(hz.call(cz)), float(gz.call(cz))])
			for e: float in [d, d + 6.5]: marks.append([minf(sx * LN, sx * (LN + 0.6)), e - 0.05, maxf(sx * LN, sx * (LN + 0.6)), e + 0.05, "white"])
			if rr.randf() < 0.6: W.oil(dec, rr, Vector2(cx, cz + (1.2 if sx > 0.0 else -1.2)), 0.0, yr, rr.randf_range(0.35, 0.7))
			d += 6.5
	# carriageway: residential = unmarked (a quiet street, cars give way to each other), standard = double yellow and
	# stall T-marks (a collector: busier, marked)
	var p: Array = []
	if sec == "std":
		p.append_array(marks)
		p.append([-0.2, z0, -0.1, z1, "yellow"]); p.append([0.1, z0, 0.2, z1, "yellow"])
	K.painted_rect(g, -KBs, z0, KBs, z1, p, yr)
	for sx: float in [-1.0, 1.0]:
		if alley:
			RL.strip_z(g, sx * KBs, sx * PKs, z0, AL0 - 1.0, [], "grass", yr, yw)
			RL.strip_z(g, sx * KBs, sx * PKs, AL0 - 1.0, AL1 + 1.0, [[(AL0 + AL1) * 0.5, AL1 - AL0]], "concrete", yr, yw)
			RL.strip_z(g, sx * KBs, sx * PKs, AL1 + 1.0, z1, [], "grass", yr, yw)
		else:
			RL.strip_z(g, sx * KBs, sx * PKs, z0, z1, [], "grass", yr, yw)
		g.rect("concrete", minf(sx * PKs, sx * PRs), z0, maxf(sx * PKs, sx * PRs), z1, yw)
	var taken := {-1.0: [], 1.0: []}
	# a hydrant every ~100 m (the block's one sits 20 m in), red kerb 4.5 m each way
	props.add("prop_hydrant_red", "worn", Vector3(hside * (KBs + 0.7), float(yw.call(0.0, hyd)), hyd), -90.0 * hside)
	RL.red_kerb_z(dec, hside * KBs, hyd - 4.5, hyd + 4.5, -hside, yr, yw)
	(taken[hside] as Array).append(hyd)
	# a cobra mid-way (the junctions have their own corner lamps), arm over the road
	var lz := clampf((z0 + z1) * 0.5 + 6.0, z0 + 6.0, z1 - 6.0)
	props.add("prop_lamp_cobra", "worn", Vector3(-hside * (KBs + 0.6), float(yw.call(0.0, lz)), lz), 90.0 * hside)
	(taken[-hside] as Array).append(lz)
	# street sweeping (weekly), one sign per side past the junction
	for sx: float in [-1.0, 1.0]:
		var sz := clampf(z0 + (14.0 if sx > 0.0 else 26.0), z0 + 3.0, z1 - 3.0)
		props.add("prop_sign_no_parking", "worn", Vector3(sx * (KBs + 0.35), float(yw.call(0.0, sz)), sz), -90.0 * sx)
		(taken[sx] as Array).append(sz)
	# drainage: a flat stub drains to a mid-block inlet each side; on a slope the water runs down to the stub's low end,
	# where an inlet each side takes it before the junction (the junction tiles keep their own crossings dry).
	# SE FIX (header 6): the nearest free kerb spot to the planned one: 2.5 m clear of every post in the parkway (the
	# grate is 2.8 m long) and of the alley apron with its flares (a dropped kerb has no inlet: wheels cross there)
	for sx: float in [-1.0, 1.0]:
		var want := (z0 + z1) * 0.5 + sx * 3.0 if flat else (z0 + 2.5 if H > 0.0 else z1 - 2.5)
		var iz := want
		for k in 41:
			var c := want + (0.5 * ceilf(k / 2.0)) * (1.0 if k % 2 == 1 else -1.0)
			if c < z0 + 1.6 or c > z1 - 1.6: continue
			var ok := not (alley and c > AL0 - 1.0 - 1.0 - 1.5 and c < AL1 + 1.0 + 1.0 + 1.5)
			for o2: float in taken[sx]:
				if absf(c - o2) < 2.5: ok = false
			if ok: iz = c; break
		props.add("prop_storm_drain_curb_inlet", "dirty", Vector3(sx * KBs, float(yr.call(0.0, iz)), iz), -90.0 * sx, false)
		(taken[sx] as Array).append(iz)
	# trees: RES_MIX (planted over decades: runs of one species, mixed ages), 11-14 m rhythm, from 28 m off the lattice
	# junction (its sight triangle) to 25 m short of the ring junction (the stop sign's), clear of things in the parkway
	var grp := RL._pick_group(rr)
	for sx: float in [-1.0, 1.0]:
		var tz := maxf(z0 + 8.0, 28.0) + (rr.randf_range(3.0, 7.0) if sx > 0.0 else rr.randf_range(0.0, 2.0))
		while tz < minf(z1 - 2.0, Lr):
			if rr.randf() < 0.08:
				dec.add(14, Vector2(sx * (KBs + 0.75), tz), rr.randf_range(0, 180), 1.1, 1.1, yw, Color(0.75, 0.68, 0.55, 0.55))
				tz += rr.randf_range(11.0, 14.0); continue
			for shift: float in [0.0, 1.0, 2.0, 3.0, 4.0]:
				var z := tz + shift
				if z > minf(z1 - 2.0, Lr): break
				var ok := not (alley and z > AL0 - 3.5 and z < AL1 + 3.5)
				for o2: float in taken[sx]:
					if absf(z - o2) < 3.0: ok = false
				if ok:
					if rr.randf() < 0.45: grp = RL._pick_group(rr)
					var gp: Array = RL.RES_MIX[grp]
					var model := String((gp[0] as Array)[rr.randi() % (gp[0] as Array).size()])
					props.add(model, "normal", Vector3(sx * (KBs + 0.75), float(yw.call(0.0, z)) - 0.06, z), rr.randf_range(0.0, 360.0), true, rr.randf_range(float(gp[2]), float(gp[3])))
					(taken[sx] as Array).append(z)
					if rr.randf() < 0.6: dec.add(rr.randi() % 2, Vector2(sx * (PKs + 0.8), z + rr.randf_range(-0.8, 0.8)), rr.randf_range(60, 120), 1.9, 0.9, yw, Color(0.3, 0.29, 0.28, 0.8))
					if rr.randf() < 0.3: W.pale_patch(dec, rr, Vector2(sx * (PKs + 1.0), z + rr.randf_range(-1.0, 1.0)), 0.0, 1.9, 1.6, yw, 0.6)
					break
			tz += rr.randf_range(11.0, 14.0)
	# wear: wheel paths, cracks, gutter leaves (streaks downhill on a slope), utility cuts, the walking line
	for sx: float in [-1.0, 1.0]:
		RL.lane_wear_y(dec, rr, sx * LN * 0.5, z0, z1, yr, 0.35)
		W.cracks(dec, rr, minf(sx * 0.3, sx * KBs), z0 + 1.0, maxf(sx * 0.3, sx * KBs), z1 - 1.0, maxi(3, int((z1 - z0) / 9.0)), yr, 0.5)
		var gzz := z0 + 1.0
		while gzz < z1 - 1.5:
			var L := rr.randf_range(1.5, 2.6) if flat else rr.randf_range(2.8, 3.8)
			dec.add(14, Vector2(sx * (KBs - 0.28), gzz + L * 0.5), 0.0, 0.5, L, yr, Color(0.95, 0.9, 0.82, rr.randf_range(0.45, 0.7)))
			gzz += L + (rr.randf_range(2.0, 5.0) if flat else rr.randf_range(0.4, 1.5))
		var wz := z0 + 0.5
		while wz < z1 - 1.0:
			var Lw := rr.randf_range(2.0, 4.0)
			dec.add(14, Vector2(sx * rr.randf_range(PKs + 0.6, PRs - 0.6), wz + Lw * 0.5), 0.0, 1.1, Lw, yw, Color(1, 1, 1, rr.randf_range(0.2, 0.4)))
			wz += Lw + rr.randf_range(2.0, 6.0)
	var qz := rr.randf_range(z0 + 6.0, z1 - 6.0)
	_trench_xz(dec, Vector2((1.0 if rr.randf() < 0.5 else -1.0) * KBs * 0.5, qz), true, 1.0, KBs - 0.4, yr)   # a house's water service (SE: a sealed cut)
	var mz := clampf(z0 + 26.0, z0 + 3.0, z1 - 3.0)
	props.add("prop_manhole_cover", "worn", Vector3(-1.6, float(yr.call(0.0, mz)) + 0.002, mz), 0.0, false)
	dec.add(2, Vector2(-1.6, mz), 0.0, 2.2, 2.0, yr, Color(1, 1, 1, 0.75))

## ---------------------------------------------------------------------------------------- b130: 11th St B Ave -> W
## header (3). Frame: +z from the B Ave x 11th junction (250, 200) east toward W (570, 200), yaw 90; -x drives +z
## (eastbound, toward W), +x drives -z (westbound, toward B Ave).
const B130_Z0 := 20.0        # j_rs_2l2r_opp_a's east tile edge (measured)
const B130_WLEG := 100.0     # W's own west leg (s_wfd) ends 100 m from W (measured)

static func b130_plan() -> Dictionary:
	var R := RG.ring()
	var d: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(SITES))
	var b: Dictionary = {}
	var nodes := {}
	for x: Dictionary in d["blocks"]:
		if String(x["id"]) == "b130": b = x
	for n: Dictionary in d["nodes"]: nodes[RG.nkey(float(n["u"]), float(n["v"]))] = n
	var ka := RG.nkey(float(b["a"][0]), float(b["a"][1])); var kb := RG.nkey(float(b["b"][0]), float(b["b"][1]))
	var kw := ka if R["nodes"].has(ka) else kb          # W (a ring node: the sample)
	var kl := kb if kw == ka else ka
	var L: Dictionary = nodes[kl]
	var lp := Vector2(float(L["u"]), float(L["v"]))
	var wp := Vector2(float(R["nodes"][kw]["u"]), float(R["nodes"][kw]["v"]))
	var ds := (wp - lp).normalized()
	var length := lp.distance_to(wp)
	return {"name": "s_rg_se_b130", "bid": "b130", "sec": String(b["section"]), "lattice": kl, "t": kw, "o": lp, "ds": ds, "len": length,
		"z0": B130_Z0, "z1": length - B130_WLEG, "pad0": float(L["pad"]), "pad1": float(R["nodes"][kw]["pad"]), "yaw": RG._yaw(ds), "street": String(b["name"])}

static func _build_b130() -> void:
	S.hill_on = false
	var pl := b130_plan()
	var name: String = pl["name"]
	var z0: float = pl["z0"]; var z1: float = pl["z1"]
	var H: float = float(pl["pad1"]) - float(pl["pad0"])
	var span := z1 - z0
	var hz := func(z: float) -> float: return H * RG._ss((z - z0) / span)
	var gz := func(z: float) -> float:
		var t := clampf((z - z0) / span, 0.0, 1.0)
		return H * 6.0 * t * (1.0 - t) / span
	var yr := func(_x: float, z: float) -> float: return float(hz.call(z))
	var yw := func(_x: float, z: float) -> float: return float(hz.call(z)) + KH
	var root := Node3D.new(); root.name = name
	var g := K.Ground.new(); var props := K.Props.new(); var dec := K.Decals.new(); var rr := W.rng_for(name)
	# the s_apt / s_wfd cross-section (W's leg continues it exactly)
	var KBs := 5.7; var PKs := 7.2; var PRs := 9.2; var LN := 3.3
	var AL0 := 54.0; var AL1 := 60.0                 # the B Ave block's alley meets 11th St here (resstd's alley line)
	var ac := (AL0 + AL1) * 0.5; var aw := AL1 - AL0
	# eastbound bus stop: far side of B Ave for the traffic leaving it (-x side drives +z), road_lib's s_apt stop design
	# (audit #15): a 20 m zone 7 m clear of the crosswalk, red kerb, a concrete boarding pad through the parkway where
	# the doors open, the sign at the pad's front end, the bench at the back of the walk facing the street, a bin
	var BUS0 := z0 + 7.0; var BUS1 := z0 + 27.0; var PAD0 := z0 + 15.0; var PAD1 := z0 + 22.5
	# hydrants every ~100 m on alternating sides (15 ft of red kerb each way: nobody parks in front of them)
	var hyds: Array = [[1.0, z0 + 52.0], [-1.0, z0 + 128.0], [1.0, z1 - 14.0]]
	var taken := {-1.0: [], 1.0: []}       # z of things in each parkway
	# ---- kerb parking, recorded for the parked-car layer [x, z, yaw, y, grade]: 7 m clear of B Ave's crosswalk, clear of
	# the alley mouth, the bus zone and the hydrants; at W's end it runs on into W's own stalls
	var stalls: Array = []
	var marks: Array = []
	for sx: float in [-1.0, 1.0]:
		var blocked: Array = [[z0, z0 + 7.0], [AL0 - 1.5, AL1 + 1.5]]
		if sx < 0.0: blocked.append([BUS0, BUS1])
		for h: Array in hyds:
			if float(h[0]) == sx: blocked.append([float(h[1]) - 4.5, float(h[1]) + 4.5])
		var d := z0
		while d + RL.STALL <= z1 + 1e-3:
			var bad := false
			for r: Array in blocked:
				if d + RL.STALL > float(r[0]) and d < float(r[1]): bad = true
			if bad:
				d += 0.5; continue
			var cz := d + RL.STALL * 0.5; var cx := sx * (LN + 1.2)
			stalls.append([cx, cz, 180.0 if sx > 0.0 else 0.0, float(hz.call(cz)), float(gz.call(cz))])
			for e: float in [d, d + RL.STALL]:
				if e < z1 - 0.06: marks.append([minf(sx * LN, sx * (LN + 0.6)), e - 0.05, maxf(sx * LN, sx * (LN + 0.6)), e + 0.05, "white"])
			if rr.randf() < 0.6: W.oil(dec, rr, Vector2(cx, cz + (1.2 if sx > 0.0 else -1.2)), 0.0, yr, rr.randf_range(0.35, 0.7))   # overnight drips
			d += RL.STALL
	# ---- carriageway: a collector, marked (double yellow, stall ticks), tessellated every 4 m so it follows the slope
	var p: Array = []
	p.append_array(marks)
	p.append([-0.2, z0, -0.1, z1, "yellow"]); p.append([0.1, z0, 0.2, z1, "yellow"])
	K.painted_rect(g, -KBs, z0, KBs, z1, p, yr)
	# ---- parkways (grass; concrete at the alley apron and the bus boarding pad), walks
	for sx: float in [-1.0, 1.0]:
		var cuts: Array = [[AL0 - 1.0, AL1 + 1.0, "apron"]]
		if sx < 0.0: cuts.append([PAD0, PAD1, "pad"])
		cuts.sort_custom(func(a: Array, b: Array) -> bool: return float(a[0]) < float(b[0]))
		var cur := z0
		for c: Array in cuts:
			if float(c[0]) > cur: RL.strip_z(g, sx * KBs, sx * PKs, cur, float(c[0]), [], "grass", yr, yw)
			if String(c[2]) == "apron": RL.strip_z(g, sx * KBs, sx * PKs, float(c[0]), float(c[1]), [[ac, aw]], "concrete", yr, yw)
			else: RL.strip_z(g, sx * KBs, sx * PKs, float(c[0]), float(c[1]), [], "concrete", yr, yw)
			cur = float(c[1])
		RL.strip_z(g, sx * KBs, sx * PKs, cur, z1, [], "grass", yr, yw)
		g.rect("concrete", minf(sx * PKs, sx * PRs), z0, maxf(sx * PKs, sx * PRs), z1, yw)
	# ---- the bus stop (eastbound)
	RL.red_kerb_z(dec, -KBs, BUS0, BUS1, 1.0, yr, yw)
	I.add(props, "prop_bus_stop_sign", "worn", Vector3(-(KBs + 0.45), float(yw.call(0.0, PAD1 - 0.6)), PAD1 - 0.6), 90.0)   # the front door stops here
	props.add("prop_bench_bus_stop", "worn", Vector3(-(PRs - 0.45), float(yw.call(0.0, (PAD0 + PAD1) * 0.5 - 2.0)), (PAD0 + PAD1) * 0.5 - 2.0), 90.0)   # faces the street
	props.add("prop_trash_receptacle", "dirty", Vector3(-(PRs - 0.5), float(yw.call(0.0, PAD1 + 0.4)), PAD1 + 0.4), 0.0)
	(taken[-1.0] as Array).append_array([PAD0 - 1.0, (PAD0 + PAD1) * 0.5, PAD1 + 1.0])
	dec.add(14, Vector2(-(PKs + 1.0), (PAD0 + PAD1) * 0.5 - 2.0), 0.0, 1.8, 4.5, yw, Color(1, 1, 1, 0.6))              # people wait here
	dec.add(14, Vector2(-(KBs + 0.75), (PAD0 + PAD1) * 0.5), 0.0, 1.2, PAD1 - PAD0 - 0.6, yw, Color(1, 1, 1, 0.55))   # the pad people step onto
	for k in 3: W.oil(dec, rr, Vector2(-(LN + 1.2), rr.randf_range(BUS0 + 3.0, BUS1 - 2.0)), 0.0, yr, 0.75)             # buses idle here
	# ---- lamps: cobras over the road every ~42 m, staggered (one lights the waiting end of the stop)
	var lamps: Array = [[-1.0, BUS0 + 1.5], [1.0, z0 + 50.0], [-1.0, z0 + 92.0], [1.0, z0 + 134.0], [-1.0, z0 + 176.0]]
	for e: Array in lamps:
		var sx: float = e[0]; var lz: float = e[1]
		props.add("prop_lamp_cobra", "worn", Vector3(sx * (KBs + 0.6), float(yw.call(0.0, lz)), lz), -90.0 * sx)     # arm over the road
		(taken[sx] as Array).append(lz)
	for h: Array in hyds:
		var sx: float = h[0]; var hzz: float = h[1]
		props.add("prop_hydrant_red", "worn" if sx > 0.0 else "rusty", Vector3(sx * (KBs + 0.7), float(yw.call(0.0, hzz)), hzz), -90.0 * sx)
		RL.red_kerb_z(dec, sx * KBs, hzz - 4.5, hzz + 4.5, -sx, yr, yw)
		(taken[sx] as Array).append(hzz)
	# speed limit for the eastbound traffic leaving B Ave, past the stop; street sweeping (weekly), one sign per side
	props.add("prop_sign_speed25", "worn", Vector3(-(KBs + 0.35), float(yw.call(0.0, z0 + 47.5)), z0 + 47.5), 90.0); (taken[-1.0] as Array).append(z0 + 47.5)
	for e2: Array in [[1.0, z0 + 26.0], [-1.0, z0 + 110.0]]:
		var sx2: float = e2[0]; var sz: float = e2[1]
		props.add("prop_sign_no_parking", "worn", Vector3(sx2 * (KBs + 0.35), float(yw.call(0.0, sz)), sz), -90.0 * sx2); (taken[sx2] as Array).append(sz)
	# drainage: the street falls 4.65 m toward the bay; a 200 m gutter needs an inlet half-way and one at the low end
	# before W's leg (W's tile keeps its own crossing dry)
	for sx: float in [-1.0, 1.0]:
		for iz: float in [z0 + 102.0 + sx * 2.0, z1 - 2.5]:
			props.add("prop_storm_drain_curb_inlet", "dirty", Vector3(sx * KBs, float(yr.call(0.0, iz)), iz), -90.0 * sx, false)
			(taken[sx] as Array).append(iz)
	# ---- street trees: RES_MIX (planted over decades: runs of one species, mixed ages) from 28 m (B Ave's sight
	# triangle); over the last 70 m before W the bay drive's palms take over (fan and queen, as W's own leg)
	var grp := RL._pick_group(rr)
	var palm_from := z1 - 70.0
	for sx: float in [-1.0, 1.0]:
		var tz := maxf(z0 + 8.0, 28.0) + (rr.randf_range(3.0, 7.0) if sx > 0.0 else rr.randf_range(0.0, 2.0))
		while tz < z1 - 3.0:
			if tz < palm_from and rr.randf() < 0.08:
				dec.add(14, Vector2(sx * (KBs + 0.75), tz), rr.randf_range(0, 180), 1.1, 1.1, yw, Color(0.75, 0.68, 0.55, 0.55))   # a tree that died, never replaced
				tz += rr.randf_range(11.0, 14.0); continue
			for shift: float in [0.0, 1.0, 2.0, 3.0, 4.0]:
				var z := tz + shift
				if z > z1 - 3.0: break
				var ok := not (z > AL0 - 3.5 and z < AL1 + 3.5)
				for o2: float in taken[sx]:
					if absf(z - o2) < 3.0: ok = false
				if ok:
					var model := ""; var scl := 1.0
					if z >= palm_from:
						model = (["palm_mexican_fan_a", "palm_mexican_fan_b", "palm_mexican_fan_c"] if rr.randf() < 0.55 else ["palm_queen_a", "palm_queen_b"])[rr.randi() % 2]
						scl = rr.randf_range(0.82, 1.12)
					else:
						if rr.randf() < 0.45: grp = RL._pick_group(rr)
						var gp: Array = RL.RES_MIX[grp]
						model = String((gp[0] as Array)[rr.randi() % (gp[0] as Array).size()])
						scl = rr.randf_range(float(gp[2]), float(gp[3]))
					props.add(model, "normal", Vector3(sx * (KBs + 0.75), float(yw.call(0.0, z)) - 0.06, z), rr.randf_range(0.0, 360.0), true, scl)
					(taken[sx] as Array).append(z)
					if model.begins_with("tree_"):     # roots lift the sidewalk: a crack, a slab the city replaced (grey)
						if rr.randf() < 0.6: dec.add(rr.randi() % 2, Vector2(sx * (PKs + 0.8), z + rr.randf_range(-0.8, 0.8)), rr.randf_range(60, 120), 1.9, 0.9, yw, Color(0.3, 0.29, 0.28, 0.8))
						if rr.randf() < 0.3: W.pale_patch(dec, rr, Vector2(sx * (PKs + 1.0), z + rr.randf_range(-1.0, 1.0)), 0.0, 1.9, 1.6, yw, 0.6)
					break
			tz += rr.randf_range(11.0, 14.0)
	# ---- wear: wheel paths, cracks, gutter streaks running downhill, silt at the low end, utility cuts, the walking line
	for sx: float in [-1.0, 1.0]:
		RL.lane_wear_y(dec, rr, sx * LN * 0.5, z0, z1, yr, 0.38)
		W.cracks(dec, rr, minf(sx * 0.3, sx * KBs), z0 + 1.0, maxf(sx * 0.3, sx * KBs), z1 - 1.0, maxi(4, int(span / 9.0)), yr, 0.5)
		var gzz := z0 + 1.0
		while gzz < z1 - 1.5:
			var L := rr.randf_range(2.8, 3.8)
			dec.add(14, Vector2(sx * (KBs - 0.28), gzz + L * 0.5), 0.0, 0.5, L, yr, Color(0.95, 0.9, 0.82, rr.randf_range(0.45, 0.7)))
			gzz += L + rr.randf_range(0.6, 2.0)
		dec.add(4 + rr.randi() % 2, Vector2(sx * (KBs - 0.6), z1 - 4.5), 0.0, 1.2, 3.0, yr, Color(0.62, 0.57, 0.48, 0.6))   # silt where the runoff stops
		var wz := z0 + 0.5
		while wz < z1 - 1.0:
			var Lw := rr.randf_range(2.0, 4.0)
			dec.add(14, Vector2(sx * rr.randf_range(PKs + 0.6, PRs - 0.6), wz + Lw * 0.5), 0.0, 1.1, Lw, yw, Color(1, 1, 1, rr.randf_range(0.22, 0.42)))
			wz += Lw + rr.randf_range(2.0, 6.0)
		dec.add(8, Vector2(sx * 2.4, AL0 - 2.0), sx * 35.0, 0.6, 4.0, yr, Color(1, 1, 1, 0.4))           # tyres cutting into the alley
		dec.add(14, Vector2(sx * (PKs + 1.0), ac), 0.0, 2.0, aw, yw, Color(1, 1, 1, 0.5))                # dirt carried across the walk
	for q: Array in [[-1.0, z0 + 37.0], [1.0, z0 + 81.0], [-1.0, z0 + 143.0], [1.0, z0 + 171.0]]:       # house water services, patched
		_trench_xz(dec, Vector2(float(q[0]) * KBs * 0.5, float(q[1])), true, 1.0, KBs - 0.4, yr)
	for mz: float in [z0 + 26.0, z0 + 100.0, z0 + 174.0]:      # the sewer under the road, a manhole every ~75 m
		props.add("prop_manhole_cover", "worn", Vector3(-1.6, float(yr.call(0.0, mz)) + 0.002, mz), 0.0, false)
		if rr.randf() < 0.7: dec.add(2, Vector2(-1.6, mz), 0.0, 2.2, 2.0, yr, Color(1, 1, 1, 0.75))
	_finish_stub(root, g, props, dec, pl, stalls, {"continues": "s_wfd (waterfront sample W, west leg, ends at 100 m from W)", "bus": "eastbound far side of B Ave"})

## ===================================================================================== PREVIEW-ONLY review ground
## zz_ring_se_ground in GRID coordinates (row pos [0, 0, -8000]); never placed in the game. Approach copied from
## road_rg_NW.build_review_ground (header 5) and extended for the W transitions, b130 and W's land side.
## spec: {"ring": [[s0, s1], ...], "stems": [node keys], "w": ["S", "N"], "b130": true, "rects": [[u0, v0, u1, v1, y]],
##        "boxes": [[u0, v0, u1, v1], ...]}
static func build_review_ground(name: String, spec: Dictionary) -> void:
	var R := prepare()
	var path: RG.Path = R["path"]
	var g := K.Ground.new()
	var root := Node3D.new(); root.name = name
	var inl: float = R["inland"]; var out := -inl
	var W_ := 45.0
	var ys := func(s: float) -> float: return RG.ring_h(s) - 0.02
	var stems: Array = spec.get("stems", [])
	for rs: Array in spec["ring"]:
		var r0: float = rs[0]; var r1: float = rs[1]
		var ctx := RG._ctx(path, Vector2.ZERO, ys)
		var skip: Array = []
		for k: String in stems:
			var tg: Dictionary = R["nodes"][k]["tg"]
			var a := float(tg["lo"]["s_X"]); var b := float(tg["hi"]["s_X"])
			# the stem's corners in this range's unwrapped s
			var ref := (r0 + r1) * 0.5
			a = RG._near(a, ref, path.length); b = RG._near(b, ref, path.length)
			if b < r0 or a > r1: continue
			skip.append([a, b]); (ctx["extra"] as Array).append_array([a, b])
		RG._finalize(ctx, r0, r1)
		var bo: float = RG.PR
		for bid: String in R["blocks"]:
			var bk: Dictionary = R["blocks"][bid]
			var sa := RG._near(float(bk["sa"]), (r0 + r1) * 0.5, path.length)
			var sb := sa + (float(bk["sb"]) - float(bk["sa"]))
			if sb > r0 and sa < r1: bo = maxf(bo, float(bk["outer"]))
		RG._band(g, ctx, minf(out * bo, out * (bo + W_)), maxf(out * bo, out * (bo + W_)), r0, r1, [], "grass", KH)
		var cur := r0
		skip.sort_custom(func(a: Array, b: Array) -> bool: return float(a[0]) < float(b[0]))
		for sk: Array in skip:
			if float(sk[0]) > cur: RG._band(g, ctx, minf(inl * RG.PR, inl * (RG.PR + W_)), maxf(inl * RG.PR, inl * (RG.PR + W_)), cur, float(sk[0]), [], "grass", KH)
			cur = maxf(cur, float(sk[1]))
		if cur < r1: RG._band(g, ctx, minf(inl * RG.PR, inl * (RG.PR + W_)), maxf(inl * RG.PR, inl * (RG.PR + W_)), cur, r1, [], "grass", KH)
	# stems: the stub's own profile (stub frame z from the lattice node; T frame s from the ring node: z = Lb - s)
	var roads: Array = []      # straight roads for the deep field: [start, dir, length, z0, z1, pad0, pad1]
	var lattice: Array = []    # [key, point, pad]
	for k: String in stems:
		var nd: Dictionary = R["nodes"][k]
		var tg: Dictionary = nd["tg"]
		var bid := String(nd["stem"]["block"])
		var pl := RG.stub_plan(bid)
		var Lb: float = pl["len"]; var z0: float = pl["z0"]; var z1: float = pl["z1"]
		var p0: float = pl["pad0"]; var p1: float = pl["pad1"]
		var hstem := func(sv: float) -> float:
			var z := Lb - sv
			return p0 + (p1 - p0) * RG._ss((z - z0) / maxf(z1 - z0, 1.0))
		var ds: Vector2 = tg["ds"]; var o: Vector2 = nd["o"]
		var psd: float = float(tg["ps"])
		roads.append([pl["o"], -ds, Lb, z0, z1, p0, p1])
		lattice.append([String(pl["lattice"]), pl["o"], p0])
		var stem := RG.Path.new(); stem.add_line(o, o + ds * 400.0)
		var c2 := RG._ctx(stem, Vector2.ZERO, func(sv: float) -> float: return float(hstem.call(sv)) - 0.03)
		var zmax := Lb - 45.0      # up to the lattice node's grass quadrants (45 m round it)
		RG._finalize(c2, 0.0, zmax)
		for c: Dictionary in [tg["lo"], tg["hi"]]:
			var j: float = c["j"]
			var zz := float(c["zX"])
			if zmax > zz + 1.0:
				RG._band(g, c2, minf(j * psd, j * (psd + 20.0)), maxf(j * psd, j * (psd + 20.0)), zz, zmax, [], "grass", KH)
	# b130: verges from the lattice quadrant (45 m) to W's land side, following its profile
	if bool(spec.get("b130", false)):
		var pl := b130_plan()
		var Lb: float = pl["len"]; var z0: float = pl["z0"]; var z1: float = pl["z1"]
		var p0: float = pl["pad0"]; var p1: float = pl["pad1"]
		roads.append([pl["o"], pl["ds"], z1 + 100.0, z0, z1, p0, p1])
		lattice.append([String(pl["lattice"]), pl["o"], p0])
		var line := RG.Path.new(); line.add_line(pl["o"], (pl["o"] as Vector2) + (pl["ds"] as Vector2) * Lb)
		var c3 := RG._ctx(line, Vector2.ZERO, func(z: float) -> float: return p0 + (p1 - p0) * RG._ss((z - z0) / maxf(z1 - z0, 1.0)) - 0.03)
		RG._finalize(c3, 45.0, z1)
		for j: float in [-1.0, 1.0]:
			RG._band(g, c3, minf(j * 9.2, j * 29.2), maxf(j * 9.2, j * 29.2), 45.0, z1, [], "grass", KH)
	# the lattice junctions' surroundings: four grass quadrants at the pad, outside the widest corridor
	var done := {}
	for e: Array in lattice:
		if done.has(e[0]): continue
		done[e[0]] = true
		var lp: Vector2 = e[1]
		var cw := _lattice_corridor(String(e[0]))
		var yq := float(e[2]) + KH - 0.04
		var yfq := func(_x: float, _z: float) -> float: return yq
		for qx: Array in [[-45.0, -cw], [cw, 45.0]]:
			for qz: Array in [[-45.0, -cw], [cw, 45.0]]:
				g.rect("grass", lp.x + float(qx[0]), lp.y + float(qz[0]), lp.x + float(qx[1]), lp.y + float(qz[1]), yfq, 8.0)
	# W transitions: verges along their (morphing) section, 1 cm lower than the ring's (the library's approach)
	var wpaths: Array = []     # [path, h(s)]
	for sd: String in spec.get("w", []):
		var wpl := RG.w_plan(sd)
		var tw: Dictionary = wpl["tw"]
		var wp: RG.Path = tw["path"]
		var Lw := wp.length
		var fr: bool = tw["from_ring"]
		var hJ := RG.w_join_h(sd); var hW: float = wpl["pad_w"]
		var h0 := hJ if fr else hW; var h1 := hW if fr else hJ
		var wy := func(sv: float) -> float: return h0 + (h1 - h0) * RG._ss(sv / Lw) - 0.03
		wpaths.append([wp, func(sv: float) -> float: return h0 + (h1 - h0) * RG._ss(sv / Lw)])
		var cw2 := RG._ctx(wp, Vector2.ZERO, wy)
		cw2["tmap"] = func(sv: float, tv: float) -> float: return RG._morph(tv, RG._ss(sv / Lw) if fr else RG._ss(1.0 - sv / Lw), signf(tv) == out)
		RG._finalize(cw2, 0.0, Lw)
		RG._band(g, cw2, minf(inl * RG.PR, inl * (RG.PR + W_)), maxf(inl * RG.PR, inl * (RG.PR + W_)), 0.0, Lw, [], "grass", KH)
		RG._band(g, cw2, minf(out * RG.PROM, out * (RG.PROM + W_)), maxf(out * RG.PROM, out * (RG.PROM + W_)), 0.0, Lw, [], "grass", KH)
	for rq: Array in spec.get("rects", []):
		var ry2: float = rq[4]
		g.rect("grass", float(rq[0]), float(rq[1]), float(rq[2]), float(rq[3]), func(_x: float, _z: float) -> float: return ry2, 8.0)
	# deep field: 1.5 m under the nearest road (the ring, a stub, b130, a W transition)
	var deep := func(x: float, z: float) -> float:
		var q := Vector2(x, z)
		var pr := path.project(q)
		var best := absf(pr.y); var h := RG.ring_h(pr.x)
		for sb: Array in roads:
			var a: Vector2 = sb[0]; var dd: Vector2 = sb[1]
			var zl := clampf((q - a).dot(dd), 0.0, float(sb[2]))
			var dist := (q - (a + dd * zl)).length()
			if dist < best:
				best = dist
				h = float(sb[5]) + (float(sb[6]) - float(sb[5])) * RG._ss((zl - float(sb[3])) / maxf(float(sb[4]) - float(sb[3]), 1.0))
		for wq: Array in wpaths:
			var wp2: RG.Path = wq[0]
			var pw := wp2.project(q)
			if pw.x > 0.01 and pw.x < wp2.length - 0.01 and absf(pw.y) < best:
				best = absf(pw.y); h = float((wq[1] as Callable).call(pw.x))
		return h - 1.5
	for bx: Array in spec["boxes"]:
		g.rect("grass", float(bx[0]), float(bx[1]), float(bx[2]), float(bx[3]), deep, 10.0)
	var mi := MeshInstance3D.new(); mi.name = "ground"; mi.mesh = g.build(); mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF; root.add_child(mi)
	print("%s: ground tris %d" % [name, g.tri_count()])
	K.save_piece(root, name)

## half width of the widest street corridor at a lattice node (property lines of its legs' sections). resstd's "hs"
## (the side street off the high street) has its walk to 9.7; Amber's own legs reach 16.
static func _lattice_corridor(key: String) -> float:
	var d: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(SITES))
	var wmax := 9.2
	for n: Dictionary in d["nodes"]:
		if RG.nkey(float(n["u"]), float(n["v"])) != key: continue
		for lg: Dictionary in n["legs"]:
			var w: float = {"res": 9.2, "std": 9.2, "ind": 8.7, "couplet": 14.3, "strip": 14.3, "hs": 9.7, "cc": 9.7, "ring": 18.3}.get(String(lg["section"]), 9.2)
			if String(lg["name"]).begins_with("Amber"): w = 16.0
			wmax = maxf(wmax, w)
	return wmax + 0.5

## ===================================================================================== header (7): utility cuts
## A utility cut patched with fresh asphalt: the fill a little darker in abutting pieces (alpha 0.2: never a dark
## square on its own), the saw-cut joints sealed with black crack sealant along both edges and across both ends (5 cm,
## pieces no longer than 3 m so they follow curves and slopes): it reads as a repair, never as a shadow of nothing.
const SEAL := Color(0.07, 0.07, 0.07, 0.85)
const CUT_FILL := Color(1, 1, 1, 0.2)

## a cut along the ring (ctx path) from s sa to sb at lateral t, w wide
static func _trench_s(dec: K.Decals, ctx: Dictionary, sa: float, sb: float, t: float, w: float, yr: Callable) -> void:
	var L := sb - sa
	var n := maxi(1, ceili(L / 3.0))
	for k in n:
		var a := sa + L * k / n; var b := sa + L * (k + 1) / n
		RG._dec(dec, ctx, 3, (a + b) * 0.5, t, w, b - a, yr, CUT_FILL)
		for e: float in [-1.0, 1.0]:
			RG._dec(dec, ctx, 13, (a + b) * 0.5, t + e * w * 0.5, 0.05, b - a + 0.02, yr, SEAL)
	for e2: float in [sa, sb]:
		RG._dec(dec, ctx, 13, e2, t, 0.05, w + 0.05, yr, SEAL, 90.0)

## a cut across the ring at s from lateral ta to tb, w wide (along s)
static func _trench_t(dec: K.Decals, ctx: Dictionary, s: float, ta: float, tb: float, w: float, yr: Callable) -> void:
	var t0 := minf(ta, tb); var t1 := maxf(ta, tb)
	var L := t1 - t0
	var n := maxi(1, ceili(L / 3.0))
	for k in n:
		var a := t0 + L * k / n; var b := t0 + L * (k + 1) / n
		RG._dec(dec, ctx, 3, s, (a + b) * 0.5, b - a, w, yr, CUT_FILL)
		for e: float in [-1.0, 1.0]:
			RG._dec(dec, ctx, 13, s + e * w * 0.5, (a + b) * 0.5, b - a + 0.02, 0.05, yr, SEAL)
	for e2: float in [t0, t1]:
		RG._dec(dec, ctx, 13, s, e2, 0.05, w + 0.05, yr, SEAL)

## a cut in a straight leg's own frame (x across, z along): centre c, along_x = the cut runs across the street
static func _trench_xz(dec: K.Decals, c: Vector2, along_x: bool, w: float, L: float, yr: Callable) -> void:
	var dirv := Vector2(1, 0) if along_x else Vector2(0, 1)
	var nrm := Vector2(-dirv.y, dirv.x)
	var yaw := 90.0 if along_x else 0.0
	var n := maxi(1, ceili(L / 3.0))
	for k in n:
		var a := -L * 0.5 + L * k / n; var b := -L * 0.5 + L * (k + 1) / n
		var m := c + dirv * (a + b) * 0.5
		dec.add(3, m, yaw, w, b - a, yr, CUT_FILL)
		for e: float in [-1.0, 1.0]:
			dec.add(13, m + nrm * e * w * 0.5, yaw, 0.05, b - a + 0.02, yr, SEAL)
	for e2: float in [-1.0, 1.0]:
		dec.add(13, c + dirv * e2 * L * 0.5, yaw + 90.0, 0.05, w + 0.05, yr, SEAL)

## road_rg.build_boulevard copied (header 8), changes marked SE: the piece name, the trench patch
static func _boulevard_lib(bid: String, part: int) -> void:
	S.hill_on = false
	var R := RG.ring()
	var path: RG.Path = R["path"]
	var pl: Dictionary = RG.block_plan(bid)[part - 1]
	var name: String = "s_rg_se_%s_%d" % [bid, part]      # SE: this half's name
	var s0: float = pl["s0"]; var s1: float = pl["s1"]
	var bk: Dictionary = R["blocks"][bid]
	var lay := RG.block_layout(bid)
	var inl: float = R["inland"]; var out := -inl
	var o := path.point(s0); var oy := RG.ring_h(s0)
	var ys := func(s: float) -> float: return RG.ring_h(s) - oy
	var ctx := RG._ctx(path, o, ys)
	var root := Node3D.new(); root.name = name
	var g := K.Ground.new(); var props := K.Props.new(); var dec := K.Decals.new(); var rr := W.rng_for(name)
	var prom: bool = lay["prom"]
	var ow: float = bk["outer"]
	# ---- what lies in this piece
	var paints: Array = []
	for q: Array in lay["paint"]:
		if float(q[3]) > s0 and float(q[1]) < s1: paints.append(q)
	var arrows: Array = []
	for a: Dictionary in lay["arrows"]:
		if float(a["box"][1]) >= s0 - 1e-3 and float(a["box"][3]) <= s1 + 1e-3: arrows.append(a)
	RG._reg(ctx, paints, arrows)
	# parkway on each side: grass, concrete boarding pads at bus stops
	var pk_cuts := {-1.0: [], 1.0: []}
	for pd: Array in lay["pads"]:
		if float(pd[2]) > s0 and float(pd[1]) < s1:
			(pk_cuts[float(pd[0])] as Array).append([maxf(float(pd[1]), s0), minf(float(pd[2]), s1)])
			(ctx["extra"] as Array).append(float(pd[1])); (ctx["extra"] as Array).append(float(pd[2]))
	var bays: Array = []
	for b: Array in lay["bays"]:
		if float(b[1]) > s0 and float(b[0]) < s1:
			bays.append([maxf(float(b[0]), s0), minf(float(b[1]), s1)])
			(ctx["extra"] as Array).append(float(b[0])); (ctx["extra"] as Array).append(float(b[1]))
	for e: float in [s0, s1]:      # a smooth taper needs short cells (2 m) over its 20 m
		for k in 11: (ctx["extra"] as Array).append(e + (2.0 * k if e == s0 else -2.0 * k))
	RG._finalize(ctx, s0, s1)
	# ---- carriageway (paint cut into the asphalt), kerbs, parkways, walks
	RG._band(g, ctx, -RG.KB, RG.KB, s0, s1, paints, "asphalt", 0.0, arrows)
	for side: float in [-1.0, 1.0]:
		var cur := s0
		var segs: Array = (pk_cuts[side] as Array).duplicate()
		segs.sort_custom(func(x: Array, y: Array) -> bool: return float(x[0]) < float(y[0]))
		for sg: Array in segs:
			if float(sg[0]) > cur: RG._strip(g, ctx, side * RG.KB, side * RG.PK, cur, float(sg[0]), [], "grass")
			RG._strip(g, ctx, side * RG.KB, side * RG.PK, float(sg[0]), float(sg[1]), [], "concrete")
			cur = float(sg[1])
		if cur < s1: RG._strip(g, ctx, side * RG.KB, side * RG.PK, cur, s1, [], "grass")
		if side == out and prom:
			RG._plain(g, ctx, side * RG.PK, side * RG.PW, s0, s1, "plaza")
			var c2 := s0
			for b: Array in bays:
				if float(b[0]) > c2: RG._plain(g, ctx, side * RG.PW, side * RG.PROM, c2, float(b[0]), "mulch", KH - 0.04)
				RG._plain(g, ctx, side * RG.PW, side * RG.PROM, float(b[0]), float(b[1]), "plaza")
				c2 = float(b[1])
			if c2 < s1: RG._plain(g, ctx, side * RG.PW, side * RG.PROM, c2, s1, "mulch", KH - 0.04)
			# the planting strip sits 4 cm below the walk: a low edging face along both its edges (no gap)
			RG._edge_faces(g, ctx, side, s0, s1, bays)
			# where the promenade ends at a W transition, the strip's end face too (the transition's walk is level)
			for e3: Array in [[s0, String(R["nodes"][bk["na"]]["ctl"]), 1.0], [s1, String(R["nodes"][bk["nb"]]["ctl"]), -1.0]]:
				if String(e3[1]) != "sample" or not RG._free_bays(bays, float(e3[0]), 0.01): continue
				var se3: float = e3[0]
				var y3: float = float(ys.call(se3)) + KH
				var tg3 := path.tangent(se3) * float(e3[2])
				g.quad("curb", RG._F(ctx, se3, side * RG.PW, y3 - 0.04), RG._F(ctx, se3, side * RG.PROM, y3 - 0.04), RG._F(ctx, se3, side * RG.PROM, y3), RG._F(ctx, se3, side * RG.PW, y3), Vector3(-tg3.x, 0, -tg3.y), true)
		elif side == out:
			# a plain walk (golf course / base fence side); where it meets a junction whose far side is a promenade
			# (the next block faces the water), the walk widens to it over 20 m (smoothstep) so the property line
			# never steps
			var wA: float = float(R["nodes"][bk["na"]]["outer"]) if absf(s0 - float(bk["r0"])) < 0.01 else ow
			var wB: float = float(R["nodes"][bk["nb"]]["outer"]) if absf(s1 - float(bk["r1"])) < 0.01 else ow
			var wfn := func(sv: float) -> float:
				var w := ow
				if wA > ow + 0.01: w = maxf(w, ow + (wA - ow) * (1.0 - RG._ss((sv - s0) / 20.0)))
				if wB > ow + 0.01: w = maxf(w, ow + (wB - ow) * (1.0 - RG._ss((s1 - sv) / 20.0)))
				return w
			RG._plain_var(g, ctx, side, RG.PK, wfn, s0, s1, "concrete")
		else:
			RG._plain(g, ctx, side * RG.PK, side * RG.PR, s0, s1, "concrete")
	# ---- props
	var yy := RG._yfns(ctx)
	var yr: Callable = yy[0]; var yw: Callable = yy[1]
	for e: Array in lay["items"]:
		var s: float = e[2]
		if s < s0 or s >= s1: continue
		var t: float = e[3]
		var lift := KH
		if String(e[0]) in ["prop_storm_drain_curb_inlet", "prop_manhole_cover"]: lift = 0.0 if String(e[0]).contains("inlet") else 0.002
		props.add(String(e[0]), String(e[1]), RG._P(ctx, s, t, lift), RG._face(path, s, t, e[4]), bool(e[5]), float(e[6]))
	for pm: Array in lay["palms"]:
		var s: float = pm[0]
		if s < s0 or s >= s1: continue
		if String(pm[2]) == "":
			RG._dec(dec, ctx, 14, s, float(pm[1]), 1.2, 1.2, yw, Color(0.75, 0.68, 0.55, 0.55), rr.randf_range(0, 90))
			continue
		props.add(String(pm[2]), "normal", RG._P(ctx, s, float(pm[1]), KH - 0.06), rr.randf_range(0.0, 360.0), true, float(pm[3]))
	for pm: Array in lay["plant"]:
		var s: float = pm[0]
		if s < s0 or s >= s1: continue
		props.add(String(pm[2]), "normal", RG._P(ctx, s, float(pm[1]), KH - 0.04), rr.randf_range(0.0, 360.0), String(pm[2]).begins_with("palm"), float(pm[3]))
	for rk: Array in lay["red"]:
		var a := maxf(float(rk[1]), s0); var b := minf(float(rk[2]), s1)
		if b - a > 0.2: RG._red_kerb(dec, ctx, float(rk[0]) * RG.KB, a, b, float(rk[0]))
	# ---- wear (where the thing that makes it happens)
	for side: float in [-1.0, 1.0]:
		RG._lane_wear(dec, rr, ctx, side * (RG.TL + RG.L1) * 0.5, s0, s1, yr, 0.4)
		RG._lane_wear(dec, rr, ctx, side * (RG.L1 + RG.L2) * 0.5, s0, s1, yr, 0.45)
		RG._cracks(dec, rr, ctx, side * 2.0, side * 9.5, s0 + 1.0, s1 - 1.0, int((s1 - s0) / 9.0), yr, 0.55)   # the city seals its boulevards
		# gutter: grit and palm litter in the bike lane edge; on the coast side sand blown into it
		var gz := s0 + 1.0
		while gz < s1 - 1.5:
			var L := rr.randf_range(1.6, 2.8)
			var sandy: bool = side == out and String(lay["coast"]) in ["beach", "bay"]
			RG._dec(dec, ctx, 14, gz + L * 0.5, side * (RG.KB - 0.3), 0.55, L, yr, Color(0.9, 0.82, 0.62, rr.randf_range(0.55, 0.8)) if sandy else Color(0.95, 0.9, 0.82, rr.randf_range(0.4, 0.62)))
			gz += L + rr.randf_range(1.5, 4.5)
		# the walking line: dirt where people walk (the promenade more, the plain walks less)
		var wz := s0 + 0.5
		var t_walk := side * (RG.PK + 1.0) if not (side == out and prom) else side * rr.randf_range(RG.PK + 1.0, RG.PW - 1.0)
		while wz < s1 - 1.0:
			var Lw := rr.randf_range(2.0, 4.0)
			var pa := rr.randf_range(0.1, 0.2) if (side == out and prom) else rr.randf_range(0.22, 0.42)     # light paving shows dirt darker
			RG._dec(dec, ctx, 14, wz + Lw * 0.5, t_walk, 1.2, Lw, yw, Color(1, 1, 1, pa))
			wz += Lw + rr.randf_range(2.0, 6.0)
	if prom:
		for k in int((s1 - s0) / 7.0):     # sand carried up from the beach on feet: soft drifts along the walk (no squares)
			RG._dec(dec, ctx, 14, rr.randf_range(s0 + 2.0, s1 - 2.0), out * rr.randf_range(RG.PK + 0.6, RG.PW - 0.6), rr.randf_range(0.9, 1.6), rr.randf_range(2.0, 3.6), yw, Color(0.88, 0.8, 0.6, rr.randf_range(0.12, 0.22)), rr.randf_range(-12, 12))     # faint: the grime tile reads as stains on light paving
	# utility cuts: a trench patched across half the road, dark patches round some manholes
	if s1 - s0 > 30.0:      # a service trench cut along the inner lane and patched: a long narrow strip in 4 m pieces
		var tz := rr.randf_range(s0 + 4.0, s1 - 16.0)
		var tl := (RG.TL + RG.L1) * 0.5 * (1.0 if rr.randf() < 0.5 else -1.0) + rr.randf_range(-0.6, 0.6)
		_trench_s(dec, ctx, tz, tz + rr.randf_range(9.0, 15.0), tl, 0.8, yr)      # SE: a sealed cut, not three dark squares
	for e: Array in lay["items"]:
		if String(e[0]) == "prop_manhole_cover" and float(e[2]) >= s0 and float(e[2]) < s1 and rr.randf() < 0.6:
			RG._dec(dec, ctx, 2, float(e[2]), float(e[3]), 2.2, 2.2, yr, Color(1, 1, 1, 0.75))
	# bus zones: the bus idles there (oil), people stand on the pad and step through the parkway (worn grass)
	for z: Dictionary in lay["bus"]:
		var fr: float = z["front"]; var dr: float = z["dir"]; var side: float = z["side"]
		if fr < s0 - 20.0 or fr > s1 + 20.0: continue
		for k in 4:
			var s := fr - dr * rr.randf_range(2.0, 11.0)
			if s > s0 + 1.0 and s < s1 - 1.0: W.oil(dec, rr, RG._L(ctx, path.at(s, side * (RG.L2 + 0.4))), RG._yaw(path.tangent(s)), yr, 0.8)
		var pm := fr - dr * 5.0
		if pm > s0 + 3.0 and pm < s1 - 3.0: RG._dec(dec, ctx, 14, pm, side * (RG.KB + 1.0), 1.6, 7.0, yw, Color(1, 1, 1, 0.55))
	# braking marks before a sgnl: in the last 14 m of the approach lanes
	for e2: Array in [[R["nodes"][bk["nb"]], 1.0], [R["nodes"][bk["na"]], -1.0]]:
		var nd: Dictionary = e2[0]; var dr2: float = e2[1]
		if String(nd["ctl"]) != "signal": continue
		var se: float = lay["S1"] if dr2 > 0.0 else lay["S0"]
		if (dr2 > 0.0 and absf(s1 - se) > 0.01) or (dr2 < 0.0 and absf(s0 - se) > 0.01): continue
		for lane: float in [(RG.TL + RG.L1) * 0.5, (RG.L1 + RG.L2) * 0.5]:
			for wp: float in [-0.8, 0.8]:
				var sm := se - dr2 * 6.0
				RG._dec(dec, ctx, 8, sm, dr2 * (lane + wp), 0.45, 6.0, yr, Color(1, 1, 1, 0.45))
			W.oil(dec, rr, RG._L(ctx, path.at(se - dr2 * 3.0, dr2 * lane)), RG._yaw(path.tangent(se)), yr, 0.7)
	var site := {"site": bid, "part": part, "kind": "boulevard", "pos": [o.x, oy, o.y], "yaw": 0.0, "s": [s0, s1],
		"block": bk["name"], "coast": bk["coast"], "scheme": lay["scheme"]}
	RG._finish(root, g, props, dec, name, {"rg": site})

## road_rg.build_t copied (header 8), changes marked SE: the marked crossing at the T's with a beach / bus crossing,
## the duct trench only where there are signals (and drawn as a sealed cut)
static func _t_lib(key: String) -> void:
	S.hill_on = false
	var R := RG.ring()
	var path: RG.Path = R["path"]
	var nd: Dictionary = R["nodes"][key]
	var tg: Dictionary = nd["tg"]
	var name: String = nd["piece"]
	var o: Vector2 = nd["o"]
	var s_n: float = nd["s"]; var em: float = nd["em"]; var ep: float = nd["ep"]
	var sa := s_n - em; var sb := s_n + ep
	var sig: float = tg["sig"]
	var sec: String = tg["sec"]
	var sd: Dictionary = RG.SEC[sec]
	var ks: float = tg["ks"]; var psd: float = tg["ps"]; var pkw: float = sd["pkw"]
	var sgnl: bool = tg["signal"]
	var clo: Dictionary = tg["lo"]; var chi: Dictionary = tg["hi"]
	var slo: float = clo["s_t"]; var shi: float = chi["s_t"]
	var ds: Vector2 = tg["ds"]; var ns: Vector2 = tg["ns"]
	var z_k: float = tg["z_k"]; var z_E: float = tg["z_E"]
	var xw: Array = tg["z_xw"]; var zst: Array = tg["z_stop"]
	var zero := func(_s: float) -> float: return 0.0
	var ctx := RG._ctx(path, o, zero)
	var stem := RG.Path.new(); stem.add_line(o, o + ds * 200.0)
	var cst := RG._ctx(stem, o, zero)
	var root := Node3D.new(); root.name = name
	var g := K.Ground.new(); var props := K.Props.new(); var dec := K.Decals.new(); var rr := W.rng_for(name)
	var inl: float = R["inland"]; var out := -inl
	var ow: float = nd["outer"]
	var bkA: Dictionary = {}; var bkB: Dictionary = {}
	for bid: String in R["blocks"]:
		if R["blocks"][bid]["nb"] == key: bkA = R["blocks"][bid]
		if R["blocks"][bid]["na"] == key: bkB = R["blocks"][bid]
	var prom := ow > RG.PR + 0.1
	# ================================================== ring carriageway through the tile
	var p: Array = []
	var xlo: Array = tg.get("xw_lo", []); var xhi: Array = tg.get("xw_hi", [])
	if sgnl:
		for xr: Array in [xlo, xhi]:     # continental crosswalks across the ring, bars along the traffic
			var t := -RG.KB + 0.3
			while t + 0.6 <= RG.KB - 0.3 + 1e-3:
				p.append([t, float(xr[0]), t + 0.6, float(xr[1]), "white"]); t += 1.2
		var stl: Array = tg["stop_lo"]; var sth: Array = tg["stop_hi"]
		# +s approach (arrives from the lo side, drives t > 0; its pocket is the centre lane when the stem is on its left)
		p.append([-RG.TL if sig < 0.0 else RG.TL, float(stl[0]), RG.KB, float(stl[1]), "white"])
		p.append([-RG.KB, float(sth[0]), RG.TL if sig > 0.0 else -RG.TL, float(sth[1]), "white"])
	# SE: the marked crossing across the ring on the T's +s side (header 8): continental bars, the lane lines stop at it,
	# shark teeth (yield to pedestrians) across the -s approach lanes 6 m before it
	var xg: Array = tg.get("xing", [])
	var teeth: Array = []
	if not xg.is_empty():
		var bars: Array = []
		var tb := -RG.KB + 0.3
		while tb + 0.6 <= RG.KB - 0.3 + 1e-3:
			bars.append([tb, float(xg[0]), tb + 0.6, float(xg[1]), "white"]); tb += 1.2
		bars.append([-RG.KB, float(xg[0]), RG.KB, float(xg[1]), "asphalt"])
		var yl: float = tg["yield"]
		for ln: Array in [[-RG.L2, -RG.L1], [-RG.L1, -RG.TL]]:
			var a0: float = ln[0]; var a1: float = ln[1]
			var n := int(floor((a1 - a0 - 0.5 + 0.45) / 1.05))
			var c0 := (a0 + a1) * 0.5 - (n - 1) * 1.05 * 0.5
			for i in n:
				var c := c0 + i * 1.05
				var tri := PackedVector2Array([Vector2(c - 0.3, yl), Vector2(c + 0.3, yl), Vector2(c, yl + 0.9)])     # apex toward the arriving -s driver
				teeth.append({"box": [c - 0.36, yl - 0.05, c + 0.36, yl + 0.95], "poly": tri, "c": c, "axis": "x", "fill": "white"})
		p.append_array(bars)
	# end of the approach paint: the stop bars (sgnl) or the mouth (stop control)
	var apl: float = float(tg["stop_lo"][0]) if sgnl else slo
	var aph: float = float(tg["stop_hi"][1]) if sgnl else shi
	# centre lane: the pocket / flush median carries on from the boulevard to the stop bar or the mouth
	var pk_p := sig < 0.0    # +s turns left into the stem
	var pk_n := sig > 0.0    # -s turns left into the stem
	p.append([RG.TL - 0.2, sa, RG.TL - 0.05, apl, "white"] if pk_p else [RG.TL - 0.15, sa, RG.TL - 0.05, apl, "yellow"])
	p.append([-RG.TL + 0.05, sa, -RG.TL + 0.15, apl, "yellow"])
	p.append([-RG.TL + 0.05, aph, -RG.TL + 0.2, sb, "white"] if pk_n else [-RG.TL + 0.05, aph, -RG.TL + 0.15, sb, "yellow"])
	p.append([RG.TL - 0.15, aph, RG.TL - 0.05, sb, "yellow"])
	# lane lines: solid on the sgnl approaches; at a stop-controlled T the ring's dashes run straight through
	if sgnl:
		p.append([RG.L1 - 0.06, sa, RG.L1 + 0.06, apl, "white"])
		p.append([-RG.L1 - 0.06, aph, -RG.L1 + 0.06, sb, "white"])
		RG._dashes(p, [-RG.L1 - 0.06, -RG.L1 + 0.06], sa, float(xlo[0]), RG.DASH, "white")      # departure side of the lo half
		RG._dashes(p, [RG.L1 - 0.06, RG.L1 + 0.06], float(xhi[1]), sb, RG.DASH, "white")
	else:
		RG._dashes(p, [RG.L1 - 0.06, RG.L1 + 0.06], sa, sb, RG.DASH, "white")
		RG._dashes(p, [-RG.L1 - 0.06, -RG.L1 + 0.06], sa, sb, RG.DASH, "white")
	# bike lines: the far side runs through (no turns cross it); the stem side breaks where turning cars cross it
	var far := -sig
	var tf: Array = [minf(far * RG.L2 - 0.08, far * RG.L2 + 0.08), maxf(far * RG.L2 - 0.08, far * RG.L2 + 0.08)]
	if sgnl:
		p.append([tf[0], sa, tf[1], float(xlo[0]), "white"]); p.append([tf[0], float(xlo[1]), tf[1], float(xhi[0]), "white"]); p.append([tf[0], float(xhi[1]), tf[1], sb, "white"])
	else:
		p.append([tf[0], sa, tf[1], sb, "white"])
	var tn: Array = [minf(sig * RG.L2 - 0.08, sig * RG.L2 + 0.08), maxf(sig * RG.L2 - 0.08, sig * RG.L2 + 0.08)]
	var near_end_lo: float = float(xlo[0]) if sgnl else slo
	var near_beg_hi: float = float(xhi[1]) if sgnl else shi
	# the approach toward the mouth on the stem side (right turners cross the bike lane): broken; the departure: solid
	var appr_lo := sig > 0.0     # +s traffic (t > 0) approaches the mouth from the lo side when the stem is on t > 0
	if appr_lo:
		var k := sa
		while k + 1.0 <= near_end_lo: p.append([tn[0], k, tn[1], k + 1.0, "white"]); k += 2.0
		p.append([tn[0], near_beg_hi, tn[1], sb, "white"])
	else:
		p.append([tn[0], sa, tn[1], near_end_lo, "white"])
		var k2 := near_beg_hi
		while k2 + 1.0 <= sb: p.append([tn[0], k2, tn[1], k2 + 1.0, "white"]); k2 += 2.0
	if not xg.is_empty():     # SE: the crossing first (first match wins)
		var front: Array = []
		for q: Array in p:
			if (String(q[4]) == "white" or String(q[4]) == "asphalt") and absf(float(q[1]) - float(xg[0])) < 1e-6 and absf(float(q[3]) - float(xg[1])) < 1e-6: front.append(q)
		for q: Array in front: p.erase(q)
		front.append_array(p); p = front
	RG._reg(ctx, p, teeth)
	# ================================================== strips: ramps where the ring crosswalks land
	var ramps_lo: Array = []; var ramps_hi: Array = []; var ramps_far: Array = []
	if sgnl:
		ramps_lo.append([(float(xlo[0]) + float(xlo[1])) * 0.5, RG.XW_W])
		ramps_hi.append([(float(xhi[0]) + float(xhi[1])) * 0.5, RG.XW_W])
		ramps_far = [ramps_lo[0], ramps_hi[0]]
	if not xg.is_empty():     # SE: the crossing lands on ramps both sides
		ramps_hi.append([(float(xg[0]) + float(xg[1])) * 0.5, RG.XW_W])
		ramps_far.append([(float(xg[0]) + float(xg[1])) * 0.5, RG.XW_W])
	RG._reg_ramps(ctx, ramps_lo, sa, slo, 1.0); RG._reg_ramps(ctx, ramps_hi, shi, sb, 1.0); RG._reg_ramps(ctx, ramps_far, sa, sb, 1.0)
	for e: float in [slo, shi, float(clo["s_X"]), float(chi["s_X"])]: (ctx["extra"] as Array).append(e)
	var s_pave := sb          # SE: the stem side's paved parkway (where people wait) ends past the crossing's ramp
	if not xg.is_empty():
		s_pave = minf(float(xg[1]) + 2.0, sb); (ctx["extra"] as Array).append(s_pave)
	RG._finalize(ctx, sa, sb)
	RG._band(g, ctx, -RG.KB, RG.KB, sa, sb, p, "asphalt", 0.0, teeth)
	# stem side: parkway paved (the corner aprons where people wait), walk; far side: parkway paved at a sgnl (pole
	# bases, ramps), grass at a stop T; then the walk or the promenade (paved right through: the crossings land there)
	RG._strip(g, ctx, sig * RG.KB, sig * RG.PK, sa, slo, ramps_lo, "concrete", 1.8, 1.0)
	RG._strip(g, ctx, sig * RG.KB, sig * RG.PK, shi, s_pave, ramps_hi, "concrete", 1.8, 1.0)
	if s_pave < sb - 1e-3: RG._strip(g, ctx, sig * RG.KB, sig * RG.PK, s_pave, sb, [], "grass")     # SE: then the grass parkway again
	RG._plain(g, ctx, sig * RG.PK, sig * RG.PR, sa, slo, "concrete")
	RG._plain(g, ctx, sig * RG.PK, sig * RG.PR, shi, sb, "concrete")
	RG._strip(g, ctx, far * RG.KB, far * RG.PK, sa, sb, ramps_far, "concrete" if sgnl else "grass", 1.8, 1.0)
	if prom and far == out:
		RG._plain(g, ctx, far * RG.PK, far * RG.PW, sa, sb, "plaza")
		RG._plain(g, ctx, far * RG.PW, far * RG.PROM, sa, sb, "plaza")
	else:
		RG._plain(g, ctx, far * RG.PK, far * (ow if far == out else RG.PR), sa, sb, "concrete")
	# ================================================== stem: carriageway from the mouth to z_E, crosswalk, stop bar
	var ps: Array = []
	var t := -ks + 0.3
	while t + 0.6 <= ks - 0.3 + 1e-3:
		ps.append([t, float(xw[0]), t + 0.6, float(xw[1]), "white"]); t += 1.2
	var lane: float = sd["lane"]
	var sarrows: Array = []
	# the approach drives toward the ring (-z) on the stem's t < 0 side
	match sec:
		"res":
			ps.append([-lane, float(zst[0]), 0.0, float(zst[1]), "white"])
		"std", "ind":
			ps.append([-lane, float(zst[0]), 0.0, float(zst[1]), "white"])
			ps.append([-0.2, float(xw[1]), -0.1, z_E, "yellow"]); ps.append([0.1, float(xw[1]), 0.2, z_E, "yellow"])
			if sec == "ind":
				ps.append([-4.26, float(xw[1]), -4.14, z_E, "white"]); ps.append([4.14, float(xw[1]), 4.26, z_E, "white"])
		"hs":
			# Amber: median 2.5, lanes to 9.1 (line at 5.8), parking lane to the kerb (no parking at the junction)
			ps.append([-9.1, float(zst[0]), -2.5, float(zst[1]), "white"])
			ps.append([-5.86, float(zst[1]), -5.74, z_E, "white"])
			RG._dashes(ps, [5.74, 5.86], float(xw[1]) + 2.0, z_E, RG.DASH, "white")
			ps.append([-9.18, float(zst[1]), -9.06, z_E, "white"]); ps.append([9.06, float(xw[1]), 9.18, z_E, "white"])
			var zn := float(xw[1]) + 1.0
			ps.append([-2.5, zn + 2.5, 2.5, z_E, "-"])                  # under the island
			var nose := PackedVector2Array()
			for k in 13: nose.append(Vector2(2.5 * cos(PI * k / 12.0), zn + 2.5 - 2.5 * sin(PI * k / 12.0)))
			sarrows.append({"box": [-2.6, zn - 0.1, 2.6, zn + 2.5], "poly": nose, "c": 0.0, "axis": "x", "fill": ""})
			tg["hs_nose"] = zn
		"strip", "couplet":
			ps.append([-RG.L2, float(zst[0]), RG.TL, float(zst[1]), "white"])
			ps.append([-RG.TL + 0.05, float(zst[1]), -RG.TL + 0.2, z_E, "white"])          # the left-turn lane's edge
			ps.append([RG.TL - 0.15, float(xw[1]), RG.TL - 0.05, z_E, "yellow"])
			ps.append([-RG.L1 - 0.06, float(zst[1]), -RG.L1 + 0.06, z_E, "white"])
			RG._dashes(ps, [RG.L1 - 0.06, RG.L1 + 0.06], float(xw[1]) + 2.0, z_E, RG.DASH, "white")
			for sx: float in [-1.0, 1.0]: ps.append([minf(sx * RG.L2 - 0.08, sx * RG.L2 + 0.08), float(xw[1]) if sx > 0.0 else float(zst[1]), maxf(sx * RG.L2 - 0.08, sx * RG.L2 + 0.08), z_E, "white"])
			# lanes at a T: no through movement. Centre lane and inner lane turn left, the outer lane turns right
			var za := float(zst[1]) + 1.4
			if z_E - za > 5.0:
				sarrows.append(RG._arrow("left", 0.0, za + 4.5, za))
				sarrows.append(RG._arrow("left", -(RG.TL + RG.L1) * 0.5, za + 4.5, za))
				sarrows.append(RG._arrow("right", -(RG.L1 + RG.L2) * 0.5, za + 4.5, za))
	RG._reg(cst, ps, sarrows)
	var ramp_st: Array = [[(float(xw[0]) + float(xw[1])) * 0.5, RG.XW_W]]
	RG._reg_ramps(cst, ramp_st, 0.0, z_E, 1.0)
	for e: float in [float(clo["z_t"]), float(chi["z_t"]), float(clo["zX"]), float(chi["zX"]), z_k]: (cst["extra"] as Array).append(e)
	RG._finalize(cst, 0.0, z_E)
	RG._band(g, cst, -ks, ks, z_k, z_E, ps, "asphalt", 0.0, sarrows)
	if tg.has("hs_nose"): RG._median(g, cst, float(tg["hs_nose"]), z_E, 2.5, true)
	# stem strips from each kerb return's tangent point to z_E: parkway (if the section has one) + walk, ramps at the
	# crosswalk; corner j sits at stem lateral j (stem t = j * ks)
	for c: Dictionary in [clo, chi]:
		var j: float = c["j"]; var zt: float = c["z_t"]
		if pkw > ks + 0.1:
			RG._strip(g, cst, j * ks, j * pkw, zt, z_E, ramp_st, "grass" if sec in ["res", "std"] else ("grass" if sec in ["strip", "couplet"] else "concrete"), 1.4, 0.0)
			RG._plain(g, cst, j * pkw, j * psd, zt, z_E, "concrete")
		else:
			RG._strip(g, cst, j * ks, j * psd, zt, z_E, ramp_st, "concrete", 1.8, 1.0)
	# ================================================== the mouth (kerb returns, asphalt fillets) and the corners
	var mouth := PackedVector2Array()
	for v: float in RG._sub(ctx, slo, shi): mouth.append(RG._L(ctx, path.at(v, sig * RG.KB)))
	var ahi: PackedVector2Array = chi["arc"]
	for k in range(1, ahi.size()): mouth.append(RG._L(ctx, ahi[k]))
	var jh: float = chi["j"]; var jl: float = clo["j"]
	mouth.append(RG._L(ctx, o + ns * jh * ks + ds * z_k))
	mouth.append(RG._L(ctx, o + ns * jl * ks + ds * z_k))
	var alo: PackedVector2Array = clo["arc"]
	for k in range(alo.size() - 1, 0, -1): mouth.append(RG._L(ctx, alo[k]))
	var mclean := PackedVector2Array()
	for q in mouth:
		if mclean.is_empty() or mclean[mclean.size() - 1].distance_to(q) > 1e-4: mclean.append(q)
	if mclean[0].distance_to(mclean[mclean.size() - 1]) < 1e-4: mclean.remove_at(mclean.size() - 1)
	var zf := func(_x: float, _z: float) -> float: return 0.0
	var wf := func(_x: float, _z: float) -> float: return KH
	g.poly("asphalt", mclean, zf)
	var clips: Array = []
	for c: Dictionary in [clo, chi]:
		var arc: PackedVector2Array = c["arc"]
		var la := PackedVector2Array()
		for q in arc: la.append(RG._L(ctx, q))
		var dd := (la[1] - la[0]).normalized(); var left := Vector2(dd.y, -dd.x)
		g.wall_line("curb", la, zf, wf, signf(left.dot((arc[0] - (c["c"] as Vector2)).normalized())))
		# corner sidewalk: the return, the stem walk's end, the property corner X, the ring walk's end. When the return
		# is big for the walks (a 12 m truck return round 2 m walks) the property corner X falls outside the return's
		# circle: then the walk follows the return at its own widths (4 m on the ring side blending to the stem's) and
		# the lot corner behind it is clipped (meta "corner_clip" for the block builders)
		var j: float = c["j"]; var zt: float = c["z_t"]
		var cc: Vector2 = c["c"]
		var cp := PackedVector2Array()
		for q in la: cp.append(q)
		if (c["X"] as Vector2).distance_to(cc) < float(tg["R"]) - 0.3:
			cp.append(RG._L(ctx, o + ns * j * psd + ds * zt))
			cp.append(RG._L(ctx, c["X"]))
			var sX: float = c["s_X"]; var st0: float = c["s_t"]
			var ring_pts := RG._sub(ctx, minf(sX, st0), maxf(sX, st0))
			var rp: Array = []
			for v: float in ring_pts: rp.append(v)
			if sX > st0: rp.reverse()      # walk from X along the ring property line back to the tangent's s
			for k in range(1, rp.size()): cp.append(RG._L(ctx, path.at(float(rp[k]), sig * RG.PR)))
		else:
			var arc3: PackedVector2Array = c["arc"]
			var n3 := arc3.size()
			var back: Array = []
			for k in range(n3 - 1, -1, -1):     # from the stem end back to the ring end, the walk's width blending
				var f := float(k) / float(n3 - 1)
				var w := lerpf(RG.PR - RG.KB, psd - ks, f)
				var dv := (arc3[k] - cc).normalized()
				back.append(cc + dv * (float(tg["R"]) - w))
			for q: Vector2 in back: cp.append(RG._L(ctx, q))
			clips.append(back)
		g.poly("concrete", cp, wf)
	# ================================================== furniture
	var yr := func(_x: float, _z: float) -> float: return 0.0
	var yw := func(_x: float, _z: float) -> float: return KH
	var pole := func(c: Dictionary, rot_deg: float) -> Vector3:
		var u: Vector2 = (c["u"] as Vector2).rotated(deg_to_rad(rot_deg))
		var q: Vector2 = (c["c"] as Vector2) + u * (float(tg["R"]) - 1.0)     # r - 1 from the return's centre: on the walk
		var l := RG._L(ctx, q)
		return Vector3(l.x, KH, l.y)
	var to_centre := func(v: Vector3) -> float: return RG._yaw(Vector2(-v.x, -v.z))
	var corner_of_side := {}       # which corner lies on the hi side (+s) / lo side
	if sgnl:
		# mast arms over the ring for both approaches, on the far-right of each (a stem corner, or the far side just
		# past the crosswalk where there is no corner); arm model: along -X, heads face +Z
		var dp := path.tangent(s_n)
		var d_pos := path.tangent(shi); var d_neg := path.tangent(slo)
		var hi_free := true; var lo_free := true
		if sig > 0.0:
			props.add("prop_signal_mast_arm", "worn", pole.call(chi, 0.0), RG._yaw(-d_pos)); hi_free = false
		else:
			var sp := float(xhi[1]) + 2.6     # 1.6 m past the ramp's flare
			props.add("prop_signal_mast_arm", "worn", RG._P(ctx, sp, RG.KB + 1.0), RG._yaw(-path.tangent(sp)))
		if sig < 0.0:
			props.add("prop_signal_mast_arm", "worn", pole.call(clo, 0.0), RG._yaw(d_neg)); lo_free = false
		else:
			var sn := float(xlo[0]) - 2.6
			props.add("prop_signal_mast_arm", "worn", RG._P(ctx, sn, -(RG.KB + 1.0)), RG._yaw(path.tangent(sn)))
		# the stem approach: heads on a post at the free corner and across the ring (far side, on the stem's line)
		var cfree: Dictionary = clo if lo_free else chi
		props.add("prop_signal_post", "worn", pole.call(cfree, 0.0), RG._yaw(ds))
		var sfar := RG._near(path.project(o).x, s_n, path.length)
		props.add("prop_signal_post", "worn", RG._P(ctx, sfar, far * (RG.KB + 1.0)), RG._yaw(ds))
		# street names hang beside the poles on both corners; a cobra on the free corner lights the crossing
		for c: Dictionary in [clo, chi]:
			props.add("prop_sign_street_names", "worn", pole.call(c, 20.0 * float(c["j"])), 45.0 + RG._yaw(ds))
		props.add("prop_lamp_cobra", "worn", pole.call(cfree, -24.0 * float(cfree["j"])), float(to_centre.call(pole.call(cfree, -24.0 * float(cfree["j"])))))
		# people wait for the light at the corners: a bin each
		for c: Dictionary in [clo, chi]:
			props.add("prop_trash_receptacle", "worn", pole.call(c, -34.0 * float(c["j"])), 0.0)
		props.add("prop_newspaper_box_blue" if rr.randf() < 0.5 else "prop_newspaper_box_red", "worn", pole.call(cfree, 40.0 * float(cfree["j"])), RG._yaw(cfree["u"] as Vector2))
	else:
		# stop control on the stem only: the sign on the approach's right (stem t < 0 side), at the stop bar
		var sp2 := RG._P(cst, float(zst[1]) + 0.4, -(ks + 0.6))
		props.add("prop_sign_stop", "worn", sp2, RG._yaw(ds))
		props.add("prop_sign_street_names", "worn", pole.call(chi, 0.0), 45.0 + RG._yaw(ds))
		props.add("prop_lamp_cobra", "worn", pole.call(clo, 0.0), float(to_centre.call(pole.call(clo, 0.0))))
	if not xg.is_empty():
		# SE: pedestrian crossing signs where each approach's drivers see them (on their right, just before the bars,
		# facing them), and a bin at the corner where people wait to cross to the beach / the bus stop
		var s_m := float(xg[1]) + 1.2; var s_p := float(xg[0]) - 1.2
		props.add("prop_sign_ped_crossing", "worn", RG._P(ctx, s_m, -(RG.KB + 0.6)), RG._yaw(path.tangent(s_m)))
		props.add("prop_sign_ped_crossing", "worn", RG._P(ctx, s_p, RG.KB + 0.6), RG._yaw(-path.tangent(s_p)))
		props.add("prop_trash_receptacle", "worn", pole.call(chi, -34.0 * float(chi["j"])), 0.0)
		dec.add(14, RG._L(ctx, path.at((float(xg[0]) + float(xg[1])) * 0.5, sig * (RG.PK + 0.8))), RG._yaw(path.tangent(s_n)), 3.2, 2.0, yw, Color(1, 1, 1, 0.4))   # feet wait here
	# a hydrant on one corner, 1 m behind the kerb, clear of the ramps
	props.add("prop_hydrant_red", "worn", pole.call(chi, 30.0 * float(chi["j"])), RG._yaw(chi["u"] as Vector2))     # outlets face the street
	# kerb inlets upstream of the ring crossings (the stem's gutter drains in its own stub, at the stub's low end)
	var ring_in: Array = [[sa + 1.6, 1.0], [sb - 1.6, -1.0]]
	for e: Array in ring_in:
		var sv: float = e[0]
		props.add("prop_storm_drain_curb_inlet", "dirty", RG._P(ctx, sv, float(e[1]) * RG.KB, 0.0), RG._yaw(-path.normal(sv) * float(e[1])), false)
	props.add("prop_manhole_cover", "worn", RG._P(ctx, s_n + rr.randf_range(-4.0, 4.0), -sig * 3.5, 0.002), 0.0, false)
	# ================================================== wear: a busy junction
	# braking marks and oil where the queues stop, turning arcs through the mouth, cracks, a duct trench, corner grime
	if sgnl:
		for e3: Array in [[float(tg["stop_lo"][0]), 1.0], [float(tg["stop_hi"][1]), -1.0]]:
			var se: float = e3[0]; var dr: float = e3[1]
			for ln: float in [(RG.TL + RG.L1) * 0.5, (RG.L1 + RG.L2) * 0.5]:
				for wp: float in [-0.8, 0.8]: RG._dec(dec, ctx, 8, se - dr * 3.0, dr * (ln + wp), 0.45, 5.5, yr, Color(1, 1, 1, 0.5))
				W.oil(dec, rr, RG._L(ctx, path.at(se - dr * 2.5, dr * ln)), RG._yaw(path.tangent(se)), yr, 0.7)
	for wp: float in [-0.8, 0.8]:
		RG._dec(dec, cst, 8, float(zst[1]) + 3.0, -lane * 0.5 + wp, 0.45, 5.0, yr, Color(1, 1, 1, 0.45))
	W.oil(dec, rr, RG._L(cst, stem.at(float(zst[1]) + 2.5, -lane * 0.5)), RG._yaw(ds), yr, 0.7)
	for k in 5:     # turning arcs: left turners sweep through the middle of the mouth
		var sv := rr.randf_range(slo + 2.0, shi - 2.0)
		RG._dec(dec, ctx, 8, sv, sig * rr.randf_range(1.0, 7.0), 0.6, 8.0, yr, Color(1, 1, 1, 0.38), rr.randf_range(25.0, 65.0) * (1.0 if rr.randf() < 0.5 else -1.0))
	RG._cracks(dec, rr, ctx, -9.0, 9.0, sa + 1.0, sb - 1.0, 12, yr, 0.5)
	if sgnl:     # the signal duct trench across the far half (cut to the far pole); SE: only at signals, a sealed cut
		_trench_t(dec, ctx, s_n + 2.0, -sig * 0.6, -sig * 9.6, 0.7, yr)
	for c: Dictionary in [clo, chi]:
		var arc2: PackedVector2Array = c["arc"]
		for k in range(1, arc2.size() - 1, 3):
			var q: Vector2 = arc2[k] + (arc2[k] - (c["c"] as Vector2)).normalized() * 0.3
			var lq := RG._L(ctx, q)
			dec.add(14, lq, RG._yaw(arc2[k + 1] - arc2[k]), 0.5, 2.0, yr, Color(1, 1, 1, 0.55))
		var wq := RG._L(ctx, (c["c"] as Vector2) + (c["u"] as Vector2) * (float(tg["R"]) - 2.6))
		dec.add(14, wq, rr.randf_range(0, 90), 3.0, 2.2, yw, Color(1, 1, 1, 0.45))     # people wait here
	var site := {"site": key, "kind": "T", "ctl": nd["ctl"], "stem": tg["sec"], "pos": [o.x, float(nd["pad"]), o.y], "yaw": 0.0,
		"s": [sa, sb], "z_E": z_E, "bus": nd.get("bus", false), "xing": not xg.is_empty()}
	if not clips.is_empty(): site["corner_clip"] = clips      # grid points: the back of the corner walk, lots keep behind it
	RG._finish(root, g, props, dec, name, {"rg": site})
