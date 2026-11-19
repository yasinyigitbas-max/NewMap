extends SceneTree
## Piece n_un_south (university campus, the south row): u -790.8 (J Ave's walk) .. -409.2 (the east street's walk),
## v -510 (the Quad / the side pieces) .. -409.2 (the south street's walk). Grid [0, 4.0, 0], yaw 0.
##
## WHY (planner): where the students live, and the campus's back door.
##  - WEST DORMS (south-west, the campus's low corner): two residence halls (apt_court_white, apt_garden_mint) with
##    their doors on the south street, each on its own level terrace at its front's height; their courtyard behind
##    (grills, tables, washing lines, bike racks); their car park on a drive from J Ave's apron (v -457).
##  - SOUTH LOOP (middle): in at the south street's apron u -657, out at u -543; on its north side the CAMPUS SHUTTLE
##    STOP (two shelters on a platform) and the LIBRARY PLAZA up to the library's back door; inside the loop the South
##    Green; two more halls (apt_spanish_revival) face the loop's legs.
##  - EAST DORMS (south-east): two student apartment blocks (apt_stucco3) on the south street, their car park on a drive
##    from the east street's apron (v -457) and the south street's (u -457).
## LAND (Yasin: "build according to it"): the campus's SW corner: the ground follows the land (n_un_site.g), falling to
## 4.15 at (-790.8, -409.2);
## the drives, stalls and lawns follow it; every building stands on a level pad at its front's height with a retaining
## face round the pad where the field is higher or lower.
const PASS := 2
const K := preload("res://tools/city/pilot/kit_lib.gd")
const Wr := preload("res://tools/city/pilot/pieces/wear_lib.gd")
const H := preload("res://tools/city/pilot/pieces/hs_fill_lib.gd")
const U := preload("res://tools/city/pilot/pieces/n_un_site.gd")

const X0 := -790.8
const X1 := -409.2
const Z0 := -510.0
const Z1 := -409.2
## [label, folder, centre u, centre v, yaw]: residence halls, doors not walk-in
const B := [
	["dorm_w1", "apartments/apt_court_white", -768.0, -420.1, 0.0],        # front on the south street at v -414
	["dorm_w2", "apartments/apt_garden_mint", -720.0, -420.1, 0.0],
	["hall_lw", "apartments/apt_spanish_revival", -671.5, -440.0, 90.0],   # front on the loop's west leg at u -665
	["hall_le", "apartments/apt_spanish_revival", -528.5, -440.0, -90.0],  # front on the loop's east leg at u -535
	["apts_e1", "apartments/apt_stucco3_cream", -490.0, -422.1, 0.0],      # front on the south street at v -414
	["apts_e2", "apartments/apt_stucco3_peach", -430.0, -422.1, 0.0],
]
const WDRIVE := [-461.0, -453.0]        # west dorms' drive from J Ave (v), stalls both sides u -785 .. -737
const LW := [-661.0, -653.0]
const LE := [-547.0, -539.0]
const LX := [-486.0, -478.0]            # the loop's cross road (v)
const EDRIVE := [-461.0, -453.0]        # east dorms' drive from the east street (v), u -505 .. -409.2
const ELEG := [-461.0, -453.0]          # ... and its leg to the south street's apron (u)

const ITEMS := [
	# west dorms' courtyard (behind the halls): grills, tables, washing lines, racks; trees in the lawn
	["prop_bbq_kettle", "worn", -775.0, -433.0, 0.0], ["prop_picnic_table", "worn", -768.0, -435.0, 0.0],
	["prop_picnic_table", "worn", -726.0, -436.0, 90.0], ["prop_bbq_gas_cart", "worn", -716.0, -432.0, 180.0],
	["prop_clothesline", "worn", -745.0, -436.0, 0.0], ["prop_adirondack_wood", "worn", -705.0, -437.0, 200.0],
	["prop_adirondack_white", "worn", -702.5, -438.5, 160.0],
	["prop_bike_rack", "worn", -757.0, -428.6, 0.0], ["prop_bike_rack", "worn", -735.0, -428.6, 0.0],
	
	["prop_trash_cart_black", "worn", -779.2, -426.0, 90.0], ["prop_trash_cart_blue", "worn", -779.2, -424.9, 90.0],
	["prop_trash_cart_green", "worn", -706.2, -426.0, -90.0],
	# the south street front of the west dorms: low planting between the door paths, palms at the ends
	
	# the South Loop: shuttle platform's racks and bins; the South Green's trees, benches, picnic tables
	["prop_bike_rack", "worn", -624.0, -493.0, 90.0], ["prop_bike_rack", "worn", -576.0, -493.0, 90.0],
	
	["prop_park_bench", "worn", -615.0, -455.0, 0.0], ["prop_park_bench", "worn", -585.0, -455.0, 0.0],
	["prop_picnic_table", "worn", -635.0, -440.0, 30.0], ["prop_picnic_table", "worn", -565.0, -440.0, 150.0],
	["prop_sprinkler_impact", "normal", -600.0, -445.0, 0.0, false], ["plant_bougainvillea_mound", "normal", -608.0, -418.0, 0.0],
	["prop_garden_arbor", "normal", -600.0, -411.0, 0.0],
	# the library plaza: benches facing the shuttle stop, planters
	["prop_park_bench", "worn", -612.0, -504.0, 180.0], ["prop_park_bench", "worn", -588.0, -504.0, 180.0],
	["plant_potted_leafy", "normal", -596.0, -508.6, 0.0], ["plant_potted_leafy", "normal", -586.0, -508.6, 0.0],
	# the loop halls' fronts: bike racks, bins
	["prop_bike_rack", "worn", -663.4, -452.0, 90.0], ["prop_bike_rack", "worn", -536.6, -452.0, 90.0],
	["prop_trash_cart_black", "worn", -679.0, -452.0, 0.0], ["prop_trash_cart_blue", "worn", -521.0, -452.0, 0.0],
	# east dorms: courtyard behind them, the strip on the east street
	["prop_picnic_table", "worn", -490.0, -437.0, 0.0], ["prop_bbq_kettle", "worn", -482.0, -436.0, 0.0],
	["prop_picnic_table", "worn", -430.0, -437.0, 90.0], ["prop_clothesline", "worn", -440.0, -440.5, 0.0],
	["prop_bike_rack", "worn", -500.0, -432.0, 0.0], ["prop_bike_rack", "worn", -420.0, -432.0, 0.0],
	
]

## POLISH (19 Nov, Yasin: "run a polish pass on the whole zone, plenty of relevant props, lots of life"): trees on open
## lawn away from the buildings, shrubs and sprinklers nearer them, benches / picnic tables / garden chairs where people
## sit (gardens, courts, lawns), benches, planters, bins, racks, fountains and paper boxes on the wide paving; each on a
## free spot this piece already had (found by a scratch tool, OUT/py/freespots_hp.py, chosen per kind of place, frozen
## here), standing on the ground as built (hs_fill_lib.polish).
const POLISH := [
	
	
	
	
	
	
	
	["prop_park_bench", "worn", -614.0, -509.8, 180.0],
	["plant_potted_leafy", "normal", -600.0, -509.8, 0.0],
	["prop_trash_receptacle", "worn", -586.0, -509.8, 0.0],
	
	
	
	
	
	
	
	
	
	
	
	["prop_picnic_table", "worn", -648.5, -470.2, 127.7],
	["prop_park_bench", "worn", -617.0, -472.8, 121.0],
	["prop_adirondack_wood", "worn", -584.0, -475.2, -107.4],
	["prop_adirondack_white", "worn", -556.5, -475.2, -111.5],
	
	
	
	
	
	
	["prop_park_bench", "worn", -634.0, -464.8, 93.5],
	["prop_picnic_table", "worn", -620.5, -460.2, 96.6],
	["prop_park_bench", "worn", -605.5, -465.2, 110.9],
	["prop_adirondack_wood", "worn", -594.0, -455.2, -88.1],
	["prop_adirondack_white", "worn", -579.0, -450.2, -71.4],
	["prop_park_bench", "worn", -563.0, -451.2, -138.0],
	["plant_agave_americana", "normal", -536.0, -456.2, 122.0],
	["plant_bougainvillea_mound", "normal", -410.5, -469.2, 183.0],
	["prop_picnic_table", "worn", -775.5, -434.2, -167.0],
	["prop_park_bench", "worn", -751.5, -435.8, 133.6],
	["prop_adirondack_wood", "worn", -732.0, -435.2, -126.5],
	["prop_adirondack_white", "worn", -716.5, -446.8, 202.5],
	
	["prop_park_bench", "worn", -645.5, -442.2, 64.8],
	["prop_picnic_table", "worn", -628.0, -448.2, 85.7],
	["prop_park_bench", "worn", -605.5, -443.8, 93.3],
	["prop_adirondack_wood", "worn", -579.5, -436.8, -71.4],
	["prop_adirondack_white", "worn", -565.5, -433.8, -50.5],
	["prop_bike_rack", "worn", -537.5, -432.8, -90.0],
	["prop_park_bench", "worn", -493.5, -443.2, -200.6],
	["prop_picnic_table", "worn", -470.0, -432.2, 101.8],
	["prop_park_bench", "worn", -445.0, -439.8, -139.7],
	["prop_adirondack_wood", "worn", -423.5, -437.8, 172.5],
	["prop_adirondack_white", "worn", -752.0, -428.8, 148.5],
	["prop_sprinkler_impact", "normal", -735.0, -416.8, 244.0, false],
	
	["prop_park_bench", "worn", -639.5, -429.8, 42.3],
	["prop_picnic_table", "worn", -624.5, -416.2, 48.1],
	["prop_park_bench", "worn", -606.0, -416.8, 70.5],
	["prop_adirondack_wood", "worn", -587.5, -422.8, -58.7],
	["prop_adirondack_white", "worn", -572.0, -422.8, -38.4],
	["prop_park_bench", "worn", -554.5, -417.8, -79.5],
]

## SUPERCHECKER (19 Nov, Yasin: "use super checker in your entire zone and weed out the unnecessary parts ... be very
## prone to delete"): tools/city/super/sc.py check on this piece; every finding with no plainly safe place is a
## deletion (its reason on its line), lamps turned back over their road, oil where no car stands out, a collision
## box on each building column with none. Applied after everything is placed (hs_fill_lib.sc_apply).
const SC := {
 "out": [
	["prop_trash_receptacle", -604.0, -494.79999, "bin_open: prop_trash_receptacle stands in the open (17.2 m from a wall, 179.0 m from a fence)"],
	["prop_trash_receptacle", -586.0, -509.79999, "bin_open: prop_trash_receptacle stands in the open (3.0 m from a wall, 182.6 m from a fence)"],
	["prop_trash_cart_black", -779.20001, -426.0, "bin_open: prop_trash_cart_black stands in the open (3.1 m from a wall, 198.2 m from a fence)"],
	["prop_trash_cart_black", -679.0, -452.0, "bin_open: prop_trash_cart_black stands in the open (3.9 m from a wall, 177.5 m from a fence)"],
	["prop_trash_cart_blue", -779.20001, -424.89999, "bin_open: prop_trash_cart_blue stands in the open (2.8 m from a wall, 199.3 m from a fence)"],
	["prop_trash_cart_blue", -521.0, -452.0, "bin_open: prop_trash_cart_blue stands in the open (3.9 m from a wall, 269.4 m from a fence)"],
	["prop_trash_cart_green", -706.20001, -426.0, "bin_open: prop_trash_cart_green stands in the open (3.3 m from a wall, 197.4 m from a fence)"],
	["prop_picnic_table", -768.0, -435.0, "no_reason: prop_picnic_table stands alone: no door within 18 m, no wall within 8 m, nothing to sit wi"],
	["prop_picnic_table", -726.0, -436.0, "no_reason: prop_picnic_table stands alone: no door within 18 m, no wall within 8 m, nothing to sit wi"],
	["prop_picnic_table", -635.0, -440.0, "no_reason: prop_picnic_table stands alone: no door within 18 m, no wall within 8 m, nothing to sit wi"],
	["prop_picnic_table", -565.0, -440.0, "no_reason: prop_picnic_table stands alone: no door within 18 m, no wall within 8 m, nothing to sit wi"],
	["prop_picnic_table", -490.0, -437.0, "no_reason: prop_picnic_table stands alone: no door within 18 m, no wall within 8 m, nothing to sit wi"],
	["prop_picnic_table", -430.0, -437.0, "no_reason: prop_picnic_table stands alone: no door within 18 m, no wall within 8 m, nothing to sit wi"],
	["prop_picnic_table", -648.5, -470.20001, "no_reason: prop_picnic_table stands alone: no door within 18 m, no wall within 8 m, nothing to sit wi"],
	["prop_picnic_table", -620.5, -460.20001, "no_reason: prop_picnic_table stands alone: no door within 18 m, no wall within 8 m, nothing to sit wi"],
	["prop_picnic_table", -628.0, -448.20001, "no_reason: prop_picnic_table stands alone: no door within 18 m, no wall within 8 m, nothing to sit wi"],
	["prop_picnic_table", -470.0, -432.20001, "no_reason: prop_picnic_table stands alone: no door within 18 m, no wall within 8 m, nothing to sit wi"],
	["prop_picnic_table", -624.5, -416.20001, "no_reason: prop_picnic_table stands alone: no door within 18 m, no wall within 8 m, nothing to sit wi"],
	["prop_adirondack_wood", -584.0, -475.20001, "no_reason: prop_adirondack_wood stands alone: no door within 18 m, no wall within 8 m, nothing to sit"],
	["prop_adirondack_wood", -594.0, -455.20001, "no_reason: prop_adirondack_wood stands alone: no door within 18 m, no wall within 8 m, nothing to sit"],
	["prop_adirondack_wood", -732.0, -435.20001, "no_reason: prop_adirondack_wood stands alone: no door within 18 m, no wall within 8 m, nothing to sit"],
	["prop_adirondack_wood", -579.5, -436.79999, "no_reason: prop_adirondack_wood stands alone: no door within 18 m, no wall within 8 m, nothing to sit"],
	["prop_adirondack_wood", -423.5, -437.79999, "no_reason: prop_adirondack_wood stands alone: no door within 18 m, no wall within 8 m, nothing to sit"],
	["prop_adirondack_wood", -587.5, -422.79999, "no_reason: prop_adirondack_wood stands alone: no door within 18 m, no wall within 8 m, nothing to sit"],
	["prop_adirondack_white", -556.5, -475.20001, "no_reason: prop_adirondack_white stands alone: no door within 18 m, no wall within 8 m, nothing to si"],
	["prop_adirondack_white", -579.0, -450.20001, "no_reason: prop_adirondack_white stands alone: no door within 18 m, no wall within 8 m, nothing to si"],
	["prop_adirondack_white", -716.5, -446.79999, "no_reason: prop_adirondack_white stands alone: no door within 18 m, no wall within 8 m, nothing to si"],
	["prop_adirondack_white", -565.5, -433.79999, "no_reason: prop_adirondack_white stands alone: no door within 18 m, no wall within 8 m, nothing to si"],
	["prop_adirondack_white", -572.0, -422.79999, "no_reason: prop_adirondack_white stands alone: no door within 18 m, no wall within 8 m, nothing to si"],
	["prop_park_bench", -615.0, -455.0, "no_reason: prop_park_bench stands alone: no door within 18 m, no wall within 8 m, nothing to sit with"],
	["prop_park_bench", -585.0, -455.0, "no_reason: prop_park_bench stands alone: no door within 18 m, no wall within 8 m, nothing to sit with"],
	["prop_park_bench", -612.0, -504.0, "no_reason: prop_park_bench stands alone: no door within 18 m, no wall within 8 m, nothing to sit with"],
	["prop_park_bench", -588.0, -504.0, "no_reason: prop_park_bench stands alone: no door within 18 m, no wall within 8 m, nothing to sit with"],
	["prop_park_bench", -614.0, -509.79999, "over_edge: prop_park_bench hangs over the edge of its block (2 of its 4 corners)"],
	["prop_park_bench", -617.0, -472.79999, "no_reason: prop_park_bench stands alone: no door within 18 m, no wall within 8 m, nothing to sit with"],
	["prop_park_bench", -634.0, -464.79999, "no_reason: prop_park_bench stands alone: no door within 18 m, no wall within 8 m, nothing to sit with"],
	["prop_park_bench", -605.5, -465.20001, "no_reason: prop_park_bench stands alone: no door within 18 m, no wall within 8 m, nothing to sit with"],
	["prop_park_bench", -563.0, -451.20001, "no_reason: prop_park_bench stands alone: no door within 18 m, no wall within 8 m, nothing to sit with"],
	["prop_park_bench", -751.5, -435.79999, "no_reason: prop_park_bench stands alone: no door within 18 m, no wall within 8 m, nothing to sit with"],
	["prop_park_bench", -645.5, -442.20001, "no_reason: prop_park_bench stands alone: no door within 18 m, no wall within 8 m, nothing to sit with"],
	["prop_park_bench", -605.5, -443.79999, "no_reason: prop_park_bench stands alone: no door within 18 m, no wall within 8 m, nothing to sit with"],
	["prop_park_bench", -493.5, -443.20001, "no_reason: prop_park_bench stands alone: no door within 18 m, no wall within 8 m, nothing to sit with"],
	["prop_park_bench", -445.0, -439.79999, "no_reason: prop_park_bench stands alone: no door within 18 m, no wall within 8 m, nothing to sit with"],
	["prop_park_bench", -639.5, -429.79999, "no_reason: prop_park_bench stands alone: no door within 18 m, no wall within 8 m, nothing to sit with"],
	["prop_park_bench", -606.0, -416.79999, "no_reason: prop_park_bench stands alone: no door within 18 m, no wall within 8 m, nothing to sit with"],
	["prop_park_bench", -554.5, -417.79999, "no_reason: prop_park_bench stands alone: no door within 18 m, no wall within 8 m, nothing to sit with"],
	["plant_bougainvillea_mound", -410.5, -469.20001, "over_edge: plant_bougainvillea_mound hangs over the edge of its block (2 of its 4 corners)"],
	["plant_potted_leafy", -600.0, -509.79999, "over_edge: plant_potted_leafy hangs over the edge of its block (2 of its 4 corners)"],
 ],
 "turn": [
	["prop_lamp_cobra", -651.0, -465.0, 180.0],
	["prop_lamp_cobra", -549.0, -465.0, 180.0],
	["prop_lamp_cobra", -651.0, -425.0, 180.0],
	["prop_lamp_cobra", -549.0, -425.0, 180.0],
 ],
 "decals": [

 ],
 "boxes": [
	["Buildings/dorm_w1", [9.469815254211426, 1.5499759912490845, 5.8649115562438965, 0.3001642608642578, 3.099951982498169, 0.31015304565429686]],
	["Buildings/dorm_w2", [-11.870152950286865, 1.549957036972046, 5.8649115562438965, 0.29997257232666014, 3.099914073944092, 0.31015304565429686]],
	["Buildings/dorm_w2", [-3.600220203399658, 1.6999385803937912, 5.624899864196777, 0.2598400497436523, 2.799950987100601, 0.289943733215332]],
 ],
}

func _init() -> void: _run.call_deferred()

static func bbox(f: String) -> Array: return (K.building_stats(f).near as Dictionary).bbox
static func fp(b: Array) -> Array:
	var x := bbox(String(b[1])); var cu: float = b[2]; var cv: float = b[3]; var yaw: float = b[4]
	if absf(yaw) < 1.0: return [cu + float(x[0][0]), cv + float(x[0][2]), cu + float(x[1][0]), cv + float(x[1][2])]
	if absf(yaw - 90.0) < 1.0: return [cu + float(x[0][2]), cv - float(x[1][0]), cu + float(x[1][2]), cv - float(x[0][0])]
	return [cu - float(x[1][2]), cv + float(x[0][0]), cu - float(x[0][2]), cv + float(x[1][0])]
## a building's pad height (local): the ground at the middle of its front
static func pad_y(b: Array) -> float:
	return H.pad_height(fp(b), float(b[4]), func(x: float, z: float) -> float: return U.y(x, z), 0.5)

func _run() -> void:
	var root := Node3D.new(); root.name = "n_un_south"
	var bl := Node3D.new(); bl.name = "Buildings"; root.add_child(bl)
	var g := K.Ground.new(); var props := K.Props.new(); var dec := K.Decals.new()
	var rr := Wr.rng_for("n_un_south")
	# patches with their stall lines: the west dorms' drive, the east dorms' drive
	var wl: Array = []; var el: Array = []
	var x := -785.0
	while x <= -737.0 + 0.01: wl.append([x - 0.05, -466.5, x + 0.05, -461.0, "white"]); wl.append([x - 0.05, -453.0, x + 0.05, -447.5, "white"]); x += 2.7
	for seg: Array in [[-505.0, -462.0], [-452.0, -415.0]]:
		x = float(seg[0])
		while x <= float(seg[1]) + 0.01: el.append([x - 0.05, -466.5, x + 0.05, -461.0, "white"]); el.append([x - 0.05, -453.0, x + 0.05, -447.5, "white"]); x += 2.7
	var regions := [[X0, -466.5, -735.0, -447.5, "asphalt", wl], [-505.0, -466.5, X1, -447.5, "asphalt", el]]
	var pads: Array = []
	for b: Array in B:
		var f := fp(b); pads.append([f[0] - 0.5, f[1] - 0.5, f[2] + 0.5, f[3] + 0.5, pad_y(b)])
	# the graded aprons also rise to the Quad's library pad (across the piece line, so both pieces agree there) and fall
	# back onto the plain ground within 4 m of the south and side walks (so the walks' seam stays exact)
	var yb := func(x: float, z: float) -> float: return U.y(x, z)
	var lib := [-612.45, -532.0, -587.28, -510.55]
	var gp: Array = pads.duplicate(); gp.append(H.pad_entry(lib, H.pad_height(lib, 180.0, yb)))
	var gr := H.graded(yb, gp)
	var yf := func(x: float, z: float) -> float: return lerpf(float(yb.call(x, z)), float(gr.call(x, z)), smoothstep(0.0, 4.0, U.edge_d(x, z)))
	var main: Array = []
	for r: Array in regions: main.append([r[0], r[1], r[2], r[3], "-"])
	for p: Array in pads: main.append([p[0], p[1], p[2], p[3], "-"])
	main.append_array([
		[ELEG[0], -447.5, ELEG[1], Z1, "asphalt"],                     # the east dorms' leg to the south apron
		[LW[0], LX[0], LW[1], Z1, "asphalt"], [LE[0], LX[0], LE[1], Z1, "asphalt"], [LW[0], LX[0], LE[1], LX[1], "asphalt"],
		[-620.0, -490.0, -580.0, LX[0], "asphalt"],                    # the shuttle's lay-by
		[-622.0, -496.0, -578.0, -490.0, "plaza"],                     # the platform
		[-620.0, Z0, -580.0, -496.0, "plaza"],                         # the library plaza (back door u -591)
		[-603.0, LX[1], -597.0, -413.0, "plaza"],                      # the South Green's walk to the street
		[-665.0, -449.45, -661.0, -430.28, "plaza"], [-539.0, -449.72, -535.0, -430.55, "plaza"],   # the loop halls' front walks
		[X0, -414.0, -697.0, -412.0, "plaza"],                         # the west dorms' front walk
		[-505.0, -414.0, X1, -412.0, "plaza"],                         # the east dorms' front walk
	])
	for r: Array in regions: H.paint(g, r[0], r[1], r[2], r[3], r[5], String(r[4]), yf)
	H.paint(g, X0, Z0, X1, Z1, main, "grass", yf)
	# the pads: level at the front's height, faces to the field round them
	for p: Array in pads:
		H.level_pad(g, "concrete", p[0], p[1], p[2], p[3], float(p[4]), yf)
	if PASS >= 2: _build(bl, props, dec, rr, yf)
	if PASS >= 2: H.polish(props, g, ITEMS)
	if PASS >= 2: H.polish(props, g, POLISH)
	if PASS >= 2: H.sc_apply(root, props, dec, SC)
	H.finish(root, g, props, dec, "n_un_south")
	quit()

func _build(bl: Node3D, props: K.Props, dec: K.Decals, rr: RandomNumberGenerator, yf: Callable) -> void:
	var P := func(base: String, cond: String, x: float, z: float, yaw := 0.0, collide := true) -> void: H.put(props, base, cond, x, z, yf, yaw, collide)
	for b: Array in B: K.building(bl, String(b[1]), Vector3(b[2], pad_y(b), b[3]), float(b[4]), String(b[0]))
	# ---- the dorms' drives: wheel stops at every stall, a lot light each, stop signs at the mouths
	var x := -785.0 + 1.35
	while x < -737.0:
		P.call("prop_wheel_stop_concrete", "worn", x, -465.9, 0.0); P.call("prop_wheel_stop_concrete", "worn", x, -448.1, 0.0); x += 2.7
	for seg: Array in [[-505.0, -462.0], [-452.0, -415.0]]:
		x = float(seg[0]) + 1.35
		while x < float(seg[1]):
			P.call("prop_wheel_stop_concrete", "worn", x, -465.9, 0.0); P.call("prop_wheel_stop_concrete", "worn", x, -448.1, 0.0); x += 2.7
	P.call("prop_lot_light_pole", "worn", -760.0, -468.4, 0.0)
	P.call("prop_lot_light_pole", "worn", -485.0, -468.4, 0.0)
	P.call("prop_sign_stop", "worn", -788.6, -451.6, 90.0)
	P.call("prop_sign_stop", "worn", -411.4, -451.6, -90.0)
	P.call("prop_sign_stop", "worn", -451.6, -411.4, 180.0)
	P.call("prop_dumpster_3yd_green", "worn", -733.6, -470.0, 90.0)
	P.call("prop_dumpster_3yd_green", "worn", -507.0, -470.0, 90.0)
	for xx: float in [-770.0, -748.0]: Wr.oil(dec, rr, Vector2(xx, -463.7), 0.0, yf, 0.5)
	for xx: float in [-490.0, -437.0]: Wr.oil(dec, rr, Vector2(xx, -450.2), 0.0, yf, 0.5)
	# ---- the shuttle stop: two shelters facing the lay-by, the stop sign at the front bay, a bench between, lamps
	P.call("prop_bus_shelter", "worn", -611.0, -492.6, 0.0)
	P.call("prop_bus_shelter", "worn", -589.0, -492.6, 0.0)
	P.call("prop_bus_stop_sign", "worn", -582.0, -490.6, 0.0)
	P.call("prop_bench_bus_stop", "worn", -600.0, -492.8, 0.0)
	P.call("prop_trash_receptacle", "worn", -604.0, -494.8, 0.0)
	P.call("prop_lamp_victorian", "worn", -621.0, -497.0, 0.0)
	P.call("prop_lamp_victorian", "worn", -579.0, -497.0, 0.0)
	Wr.lane_wear(dec, rr, -482.0, LW[0], LE[1], false, yf)
	# ---- the loop: one-way: the exit's stop sign, lamps on the green's edge
	P.call("prop_sign_stop", "worn", -537.0, -411.4, 180.0)
	for z: float in [-465.0, -425.0]:
		P.call("prop_lamp_cobra", "worn", -651.0, z, 90.0); P.call("prop_lamp_cobra", "worn", -549.0, z, -90.0)
