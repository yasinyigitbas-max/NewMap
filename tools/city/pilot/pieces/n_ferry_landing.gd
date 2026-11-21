extends SceneTree
## Piece n_ferry_landing (hero, 21 Nov; Yasin: "get to work on ferry landing ... make sure they look good"): THE FERRY
## LANDING north of 1st St, u 190 .. 490, from 1st St's bay walk (v -1618.3) to the bay. Placed at grid [0, 0, 0],
## yaw 0: x = u, z = v (north = -v, the bay), y = world height (the game's sea at 0). Run once; every building, module
## and prop below is listed by hand with its reason (no scatter, no fill loops, no seeds).
##
## WHY (planner; ZONING: the ferry landing and the maritime museum lie north of the ring, at the 1st St gap):
##  - FERRY LANDING DRIVE: the signalised T (j_rg_nw_e350_n1600) on the 1st St gap continues north as the landing's
##    only road (same section: 11.4 m carriageway, parkway palms, walks), past the PARK AND RIDE's connector and a
##    coach bay with its shelter, into the DROP-OFF LOOP round a raised palm island (the landing's monument). Taxis wait
##    in their bay at the loop's mouth (the story's taxis block this road).
##  - THE TERMINAL (lmk_ferry_landing): its verandah on the loop's kerb (drop-off at the door), its covered walkway
##    and shelter out the back to the QUAY: a bastion of kit quay modules pushed out into water deep enough for the
##    boats (face v -1770, bed -1.5), the PIER on the terminal's axis (u 343) to its T-head, where the passenger
##    ferry berths alongside (x_street_food's ferry row). A float off the T-head for the HARBOUR PATROL boat; the
##    LANDING STEPS (quay_stair) in the bastion front where a troller ties up; a visiting sloop on the east berth.
##  - PARK AND RIDE (u 236 - 318): 100 stalls in four rows (cars parked by the game on the "stalls" meta), lot lights
##    on its island, its pay station on the walk to the water.
##  - MARITIME MUSEUM (pub_museum, ZONING (380, -1680)): its front on the loop's east walk, its exhibits (buoys, a
##    boat trailer) on the lawn on the bay side, the food kiosks' terrace (street_food.json) over the east revetment.
##  - LANDING GREEN (west): the bandstand, a playground on sand, picnic tables under a sail, all on the promenade
##    along the seawall; beach steps down to the sand.
## LAND (zoning/terrain_grid.npz, ferry_land.gd): 2.1 at 1st St falling to 0.4 at the shore (0 / under water in the
## east cove). The landing is built up: the walk level falls from 2.15 (1st St) to the quay datum 1.5 (sea + 1.5) at
## v -1726, flat from there to the water; eased onto the fill's own heights (measured) within 14 m of the west and
## east edges. Roads 0.15 below the walks with kerbs.
const K := preload("res://tools/city/pilot/kit_lib.gd")
const H := preload("res://tools/city/pilot/pieces/hs_fill_lib.gd")
const I := preload("res://tools/city/pilot/pieces/ind_lib.gd")
const LAND := preload("res://tools/city/pilot/pieces/ferry_land.gd")

const NAME := "n_ferry_landing"
const U0 := 190.0
const U1 := 490.0
const VS := -1618.3          # 1st St's bay walk edge (2.150)
const VSTEM := -1625.5       # the T's stem walks end here (u 340.8 - 359.2)
const WALK := 2.15
const QUAY := 1.5            # coping / pier deck / walk at the water (sea 0 + 1.5)
const BED := -1.5            # wall toe (kit datum: walk - 3.0)
const VF := -1750.0          # land edge: the seawall modules' backs, the revetments' tops
const QF := -1770.0          # the bastion's front face
const TOE := -1758.0         # the revetments' toe (on the bay bed / beach)
const PX := 343.0            # the pier's axis (the terminal's walkway)
const KERB := 0.15
const EASE := 14.0
const STALL_D := 5.5
## the fill's ground along this piece's west (u 190) and east (u 490) edges, measured 21 Nov from OUT/fill/pieces
## (fl_0_m9, fl_2_m9 vertices; the land + 5 cm on the lawn, the land itself on the sand): [v, world height]
const EDGE_W := [[-1620.0, 2.101], [-1622.0, 2.087], [-1624.0, 2.064], [-1626.0, 2.031], [-1628.0, 1.998], [-1630.0, 1.974], [-1632.0, 1.950], [-1634.0, 1.924], [-1636.0, 1.899], [-1638.0, 1.874], [-1640.0, 1.849], [-1642.0, 1.822], [-1644.0, 1.794], [-1646.0, 1.767], [-1648.0, 1.741], [-1650.0, 1.715], [-1652.0, 1.689], [-1654.0, 1.663], [-1656.0, 1.636], [-1658.0, 1.610], [-1660.0, 1.584], [-1662.0, 1.557], [-1664.0, 1.530], [-1666.0, 1.504], [-1668.0, 1.478], [-1670.0, 1.452], [-1672.0, 1.425], [-1674.0, 1.399], [-1676.0, 1.373], [-1678.0, 1.346], [-1680.0, 1.320], [-1682.0, 1.293], [-1684.0, 1.266], [-1686.0, 1.240], [-1688.0, 1.213], [-1690.0, 1.187], [-1692.0, 1.161], [-1694.0, 1.135], [-1696.0, 1.110], [-1698.0, 1.084], [-1700.0, 1.058], [-1702.0, 1.032], [-1704.0, 1.006], [-1706.0, 0.980], [-1708.0, 0.954], [-1710.0, 0.929], [-1712.0, 0.904], [-1714.0, 0.879], [-1716.0, 0.853], [-1718.0, 0.828], [-1720.0, 0.802], [-1722.0, 0.777], [-1724.0, 0.753], [-1726.0, 0.725], [-1728.0, 0.696], [-1730.0, 0.677], [-1732.0, 0.660], [-1734.0, 0.631], [-1736.0, 0.602], [-1738.0, 0.579], [-1740.0, 0.558], [-1742.0, 0.529], [-1744.0, 0.501], [-1746.0, 0.481], [-1748.0, 0.462], [-1750.0, 0.440], [-1752.0, 0.405], [-1754.0, 0.278], [-1756.0, 0.144], [-1758.0, -0.017]]
const EDGE_E := [[-1620.0, 2.121], [-1622.0, 2.107], [-1624.0, 2.083], [-1626.0, 2.043], [-1628.0, 2.003], [-1630.0, 1.975], [-1632.0, 1.947], [-1634.0, 1.908], [-1636.0, 1.870], [-1638.0, 1.843], [-1640.0, 1.814], [-1642.0, 1.782], [-1644.0, 1.751], [-1646.0, 1.721], [-1648.0, 1.692], [-1650.0, 1.661], [-1652.0, 1.630], [-1654.0, 1.600], [-1656.0, 1.569], [-1658.0, 1.542], [-1660.0, 1.515], [-1662.0, 1.484], [-1664.0, 1.452], [-1666.0, 1.424], [-1668.0, 1.395], [-1670.0, 1.364], [-1672.0, 1.333], [-1674.0, 1.305], [-1676.0, 1.278], [-1678.0, 1.249], [-1680.0, 1.220], [-1682.0, 1.194], [-1684.0, 1.167], [-1686.0, 1.139], [-1688.0, 1.111], [-1690.0, 1.083], [-1692.0, 1.056], [-1694.0, 1.030], [-1696.0, 1.005], [-1698.0, 0.978], [-1700.0, 0.952], [-1702.0, 0.927], [-1704.0, 0.903], [-1706.0, 0.875], [-1708.0, 0.849], [-1710.0, 0.825], [-1712.0, 0.801], [-1714.0, 0.776], [-1716.0, 0.750], [-1718.0, 0.728], [-1720.0, 0.709], [-1722.0, 0.686], [-1724.0, 0.662], [-1726.0, 0.639], [-1728.0, 0.615], [-1730.0, 0.597], [-1732.0, 0.579], [-1734.0, 0.555], [-1736.0, 0.532], [-1738.0, 0.514], [-1740.0, 0.497], [-1742.0, 0.470], [-1744.0, 0.443], [-1746.0, 0.420], [-1748.0, 0.385], [-1750.0, 0.248], [-1752.0, 0.105], [-1754.0, -0.057], [-1756.0, -0.217], [-1758.0, -0.377]]

## roads (asphalt, KERB below the walks): [u0, v0, u1, v1, why]
const ROADS := [
	[344.3, -1676.0, 355.7, VSTEM, "Ferry Landing Drive: the T's stem carried on to the loop"],
	[355.7, -1658.0, 358.7, -1638.0, "the coach bay (tour buses, the museum's school parties)"],
	[341.3, -1674.0, 344.3, -1662.0, "the taxi bay at the loop's mouth"],
	[318.0, -1658.5, 344.3, -1651.5, "the park and ride's connector to the drive"],
	[200.0, -1644.0, 318.0, -1626.0, "park and ride: rows A and B"],
	[200.0, -1666.0, 318.0, -1646.0, "park and ride: rows C and D"],
	[200.0, -1646.0, 207.0, -1644.0, "park and ride: west cross aisle past the island"],
	[311.0, -1646.0, 318.0, -1644.0, "park and ride: east cross aisle past the island"],
]
## kerb lines (a face from the walk down to the road): [[u, v], [u, v], ...] polylines, each along a road's edge
const KERBS := [
	[[344.3, VSTEM], [344.3, -1651.5]], [[344.3, -1658.5], [344.3, -1662.0], [341.3, -1662.0], [341.3, -1674.0], [344.3, -1674.0], [344.3, -1676.0]],
	[[355.7, VSTEM], [355.7, -1638.0], [358.7, -1638.0], [358.7, -1658.0], [355.7, -1658.0], [355.7, -1676.0]],
	[[344.3, -1651.5], [318.0, -1651.5], [318.0, -1626.0], [200.0, -1626.0], [200.0, -1666.0], [318.0, -1666.0], [318.0, -1658.5], [344.3, -1658.5]],
	[[207.0, -1644.0], [311.0, -1644.0], [311.0, -1646.0], [207.0, -1646.0], [207.0, -1644.0]],
]
## the drop-off loop: outer kerb and the island (rounded rectangles, concentric: the lane 9 m all round)
## the superchecker's answers (sc.py check n_ferry_landing, 21 Nov): a collision box on each building column that had none
const SC := {"boxes": [
	["Buildings/terminal", [-9.1752, 1.4900, -18.7502, 0.1600, 2.9800, 0.5397]],   # terminal: a 0.1 x 0.5 m column or post of the building has no collision
	["Buildings/terminal", [-5.7653, 0.8919, -11.2503, 0.1600, 1.1802, 0.3999]],   # terminal: a 0.1 x 0.4 m column or post of the building has no collision
	["Buildings/terminal", [-4.8252, 1.4900, -18.7502, 0.1600, 2.9800, 0.5397]],   # terminal: a 0.1 x 0.5 m column or post of the building has no collision
	["Buildings/terminal", [-8.2353, 0.8919, -11.2503, 0.1600, 1.1802, 0.3999]],   # terminal: a 0.1 x 0.4 m column or post of the building has no collision
	["Buildings/terminal", [0.8998, 1.6999, 5.2000, 0.1600, 2.8001, 0.1600]],   # terminal: a 0.1 x 0.1 m column or post of the building has no collision
	["Buildings/bistro", [3.7350, 1.5000, 6.7748, 0.4900, 3.0000, 0.4901]],   # bistro: a 0.4 x 0.5 m column or post of the building has no collision
	["Buildings/bistro", [1.6959, 1.5000, 6.8800, 0.1600, 3.0000, 0.1600]],   # bistro: a 0.1 x 0.1 m column or post of the building has no collision
	["Buildings/cafe", [1.6349, 1.5000, 3.1900, 0.7901, 3.0000, 0.1600]],   # cafe: a 0.8 x 0.1 m column or post of the building has no collision
	["Buildings/cafe", [3.1524, 1.1000, 3.1947, 0.3251, 2.2000, 0.1694]],   # cafe: a 0.3 x 0.1 m column or post of the building has no collision
	["Buildings/icecream", [1.0249, 1.5000, 6.8800, 0.1600, 3.0000, 0.1600]],   # icecream: a 0.1 x 0.1 m column or post of the building has no collision
]}

## the landing plaza's planted beds (mulch, a pair of queen palms each in the trees list, bougainvillea, bird of paradise
## and agave): the two between the loop and the terminal's door, the two on the plaza's sides by the terminal, so the
## plaza reads as a garden forecourt, not a car park of bare paving
const BEDS := [
	[321.0, -1727.0, 336.0, -1719.0], [364.0, -1727.0, 379.0, -1719.0],
	[322.0, -1740.0, 334.0, -1731.0], [366.0, -1740.0, 378.0, -1731.0],
]

const LOOP := [324.0, -1714.0, 376.0, -1676.0, 14.0]
const ISLE := [333.0, -1705.0, 367.0, -1685.0, 5.0]
## buildings: [label, folder, u, v, yaw, why]
const B := [
	["terminal", "landmarks/lmk_ferry_landing", 350.0, -1739.0, 0.0, "the verandah on the loop's kerb (drop-off at the door), the covered walkway out the back on the pier's axis (u 343)"],
	["museum", "public/pub_museum", 398.0, -1683.0, -90.0, "the maritime museum: its front on the loop's east walk (u 383.6)"],
	# THE MARKETPLACE: a row of small shops on the west promenade, their fronts to the bay (v -1740.5), the walkers
	# from the boat pass their doors and tables; their backs on the green's path
	["bistro", "commercial/com_bistro", 309.6, -1732.3, 180.0, "the fish bistro at the plaza's corner, its tables on the promenade"],
	["cafe", "commercial/com_shallow_cafe", 296.5, -1736.1, 180.0, "coffee for the people waiting for the boat"],
	["surf", "commercial/com_shallow_surf", 284.5, -1736.4, 180.0, "beach and surf rentals by the beach steps' end of the row"],
	["info", "commercial/com_kiosk", 274.0, -1736.6, 180.0, "the landing's visitor kiosk (maps, the museum's tickets)"],
	["books", "commercial/com_shallow_books", 264.5, -1736.3, 180.0, "a book and gift shop"],
	["icecream", "commercial/com_cafe_seaside", 254.5, -1732.3, 180.0, "the ice-cream parlour at the row's west end, by the playground"],
]
## walk-level surfaces (first rect containing a cell's centre wins; "-" = a hole another part fills)
const PAINTS := [
	[344.3, -1676.0, 355.7, VSTEM, "-"], [355.7, -1658.0, 358.7, -1638.0, "-"], [341.3, -1674.0, 344.3, -1662.0, "-"],   # the roads (ROADS)
	[318.0, -1658.5, 344.3, -1651.5, "-"], [200.0, -1644.0, 318.0, -1626.0, "-"], [200.0, -1666.0, 318.0, -1646.0, "-"],
	[200.0, -1646.0, 207.0, -1644.0, "-"], [311.0, -1646.0, 318.0, -1644.0, "-"],
	[340.8, VSTEM, 359.2, VS, "-"],                         # the T junction's stem (j_rg_nw_e350_n1600)
	[324.0, -1714.0, 376.0, -1676.0, "-"],                  # the loop (ring, island, corners drawn below)
	[340.8, -1662.0, 344.3, -1658.5, "concrete"],           # the zebra's landing on the west side (over the parkway)
	[355.7, -1662.0, 358.7, -1658.0, "concrete"],           # ... and on the east side
	[340.8, -1676.0, 342.8, VSTEM, "concrete"],             # the drive's west walk
	[357.2, -1676.0, 359.2, VSTEM, "concrete"],             # the drive's east walk
	[358.7, -1660.0, 363.0, -1636.0, "concrete"],           # the coach stop's platform (the walk set back round the bay)
	[338.8, -1676.0, 341.3, -1660.0, "concrete"],           # the walk set back round the taxi bay
	[318.0, -1660.5, 340.8, -1658.5, "concrete"],           # the walk along the connector, lot to the drive
	[198.0, -1668.0, 320.0, -1666.0, "concrete"],           # the lot's bay-side walk (riders walk off toward the boat)
	[198.0, -1668.0, 200.0, -1626.0, "concrete"],           # the lot's west walk
	[318.0, -1651.5, 320.0, -1626.0, "concrete"],           # the lot's east walk (to 1st St)
	[298.0, -1626.0, 302.0, VS, "concrete"],                # the lot's footpath to 1st St
	[207.0, -1646.0, 311.0, -1644.0, "mulch"],              # the lot's island (lights, palms)
	[318.0, -1750.0, 383.3, -1676.0, "concrete"],           # THE LANDING PLAZA round the loop, the forecourt, the walk to the quay (stone bands: _bands)
	[204.0, -1750.0, 318.0, -1749.0, "concrete"],           # the promenade's edge on the coping
	[383.3, -1750.0, 476.0, -1749.0, "concrete"],           # ... and on the revetment
	[204.0, -1749.0, 318.0, -1740.0, "paving"],             # the west promenade on the seawall, the marketplace's fronts
	[383.3, -1749.0, 476.0, -1733.0, "paving"],             # the kiosks' terrace over the east revetment
	[383.3, -1701.5, 432.0, -1697.75, "concrete"],             # the museum's exhibit walk (bay side)
	[428.0, -1733.0, 432.0, -1701.5, "concrete"],              # ... down to the terrace
	[409.8, -1690.0, 416.0, -1676.0, "concrete"],           # the museum's service yard (bins, condensers)
	[204.0, -1722.0, 318.0, -1719.0, "concrete"],           # the green's path: the beach steps' corner to the plaza
	[244.5, -1742.0, 247.5, -1668.0, "concrete"],           # the green's path: the lot to the promenade
	[255.0, -1711.0, 269.0, -1698.5, "paving"],             # the bandstand's pad
	[210.0, -1704.0, 234.0, -1684.0, "sand"],               # the playground
	[195.0, -1716.0, 211.0, -1698.0, "sand"],               # the beach volleyball court
	[409.8, -1659.0, 486.0, -1656.0, "concrete"],           # the museum garden's cross path (its exhibits along it)
	[363.0, -1652.0, 380.0, -1649.0, "concrete"],           # the coach stop's path to the museum (school parties) ...
	[377.0, -1676.0, 380.0, -1652.0, "concrete"],           # ... down to the museum's forecourt
	[283.0, -1700.0, 297.0, -1688.0, "concrete"],           # the picnic pad
	[428.0, -1697.75, 431.0, VS, "concrete"],               # the museum lawn's path from 1st St
]

## the waterfront: kit quay modules [kind, u, v_face, yaw] (water face on the line; yaw 180 = face to the bay,
## -90 = to the west, 90 = to the east). Uses: "straight" plain, "straight_bollards" where a boat ties up,
## "stair" landing steps, "pier_root" under the pier, "corner_out" the bastion's two outer corners.
const QUAYS := [
	# west seawall under the promenade (face v -1752, u 212 - 302); the beach steps at u 245
	["straight", 215.0, -1752.0, 180.0], ["straight", 221.0, -1752.0, 180.0], ["straight", 227.0, -1752.0, 180.0],
	["straight", 233.0, -1752.0, 180.0], ["straight", 239.0, -1752.0, 180.0], ["stair", 245.0, -1752.0, 180.0],
	["straight", 251.0, -1752.0, 180.0], ["straight", 257.0, -1752.0, 180.0], ["straight", 263.0, -1752.0, 180.0],
	["straight", 269.0, -1752.0, 180.0], ["straight", 275.0, -1752.0, 180.0], ["straight", 281.0, -1752.0, 180.0],
	["straight", 287.0, -1752.0, 180.0], ["straight", 293.0, -1752.0, 180.0], ["straight", 299.0, -1752.0, 180.0],
	# the bastion's west return (face u 302) and east return (face u 384), v -1750 - -1768
	["straight", -1753.0, 302.0, -90.0], ["straight", -1759.0, 302.0, -90.0], ["straight", -1765.0, 302.0, -90.0],
	["straight", -1753.0, 384.0, 90.0], ["straight", -1759.0, 384.0, 90.0], ["straight", -1765.0, 384.0, 90.0],
	# the bastion's front (face v -1770): the troller's berth at the landing steps (u 313 - 325), the pier root,
	# the sloop's berth (u 358 - 364)
	["straight", 307.0, QF, 180.0], ["straight_bollards", 313.0, QF, 180.0], ["stair", 319.0, QF, 180.0],
	["straight_bollards", 325.0, QF, 180.0], ["straight", 331.0, QF, 180.0], ["straight", 337.0, QF, 180.0],
	["pier_root", 343.0, QF, 180.0], ["straight", 349.0, QF, 180.0], ["straight_bollards", 355.0, QF, 180.0],
	["straight_bollards", 361.0, QF, 180.0], ["straight", 367.0, QF, 180.0], ["straight", 373.0, QF, 180.0],
	["straight", 379.0, QF, 180.0],
]
## railing runs on the coping / the revetment top: [[u, v], [u, v]] each, 0.35 m in from the edge, gaps where
## boats tie up, at the steps and at the pier
const RAILS := [
	[[212.3, -1751.65], [241.8, -1751.65]], [[248.2, -1751.65], [301.65, -1751.65]],
	[[302.35, -1751.65], [302.35, -1769.65]], [[302.35, -1769.65], [309.8, -1769.65]],
	[[328.2, -1769.65], [340.6, -1769.65]], [[345.4, -1769.65], [351.8, -1769.65]],
	[[364.2, -1769.65], [383.65, -1769.65]], [[383.65, -1769.65], [383.65, -1750.35]],
	[[384.3, -1749.65], [476.0, -1749.65]],
]

## the lawns' things: [base, cond, u, v, yaw(, collide)] each with its reason
const LAWN := [
	# the green's paths lit at night (globe lamps on the grass beside them)
	["prop_lamp_globe", "worn", 208.0, -1723.0, 0.0], ["prop_lamp_globe", "worn", 230.0, -1723.0, 0.0],
	["prop_lamp_globe", "worn", 274.0, -1723.0, 0.0], ["prop_lamp_globe", "worn", 296.0, -1723.0, 0.0],
	["prop_lamp_globe", "worn", 243.6, -1682.0, 0.0], ["prop_lamp_globe", "worn", 243.6, -1704.0, 0.0],
	# the beach volleyball court (sand) and its spectators' chairs on the lawn beside it
	["prop_volleyball_net", "clean", 203.0, -1707.0, 0.0],
	["prop_adirondack_white", "worn", 214.0, -1709.5, -90.0], ["prop_adirondack_white", "worn", 214.0, -1706.5, -90.0],
	# chairs on the west lawn's bay end, looking at the water over the promenade
	["prop_adirondack_wood", "worn", 197.0, -1733.0, 180.0], ["prop_adirondack_wood", "worn", 200.0, -1733.6, 180.0], ["prop_adirondack_wood", "worn", 203.0, -1733.0, 180.0],
	# a drinking fountain between the playground and the volleyball court
	["prop_drinking_fountain", "worn", 213.0, -1700.0, 0.0],
	# the green's lawn north of the lot: benches in pairs along the lot's walk, looking at the green
	["prop_park_bench", "worn", 222.0, -1669.4, 180.0], ["prop_park_bench", "worn", 224.5, -1669.4, 180.0],
	["prop_park_bench", "worn", 280.0, -1669.4, 180.0], ["prop_park_bench", "worn", 282.5, -1669.4, 180.0],
	# the museum garden's cross path: lamps, a buoy, chairs and a picnic spot on its lawn
	["prop_lamp_globe", "worn", 445.0, -1655.0, 0.0], ["prop_lamp_globe", "worn", 470.0, -1655.0, 0.0], ["prop_lamp_globe", "worn", 418.0, -1655.0, 0.0],
	["prop_buoy_nun", "clean", 440.0, -1662.5, 15.0], ["prop_buoy_can", "clean", 462.0, -1662.5, -30.0],
	["prop_picnic_table", "worn", 470.0, -1682.0, 0.0], ["prop_picnic_table", "worn", 474.4, -1682.0, 0.0], ["prop_bbq_kettle", "worn", 472.2, -1678.6, 0.0],
	["prop_adirondack_white", "worn", 450.0, -1724.0, 180.0], ["prop_adirondack_white", "worn", 453.0, -1724.6, 180.0], ["prop_adirondack_white", "worn", 456.0, -1724.0, 180.0],
	["prop_park_bench", "worn", 440.0, -1640.0, 90.0], ["prop_park_bench", "worn", 440.0, -1637.5, 90.0],
	# the coach stop's path to the museum: its lamps, a bench pair halfway for the teachers counting heads
	["prop_lamp_globe", "worn", 370.0, -1653.6, 0.0], ["prop_lamp_globe", "worn", 381.4, -1664.0, 0.0],
	["prop_park_bench", "worn", 372.5, -1647.6, 0.0], ["prop_park_bench", "worn", 375.0, -1647.6, 0.0],
	# the lawns' impact sprinkler heads (the green, the museum lawn and garden are watered: each head in the middle of
	# an open stretch of lawn, read off the empty-lawn report)
	["prop_sprinkler_impact", "normal", 305.0, -1705.0, 0.0, false], ["prop_sprinkler_impact", "normal", 395.0, -1645.0, 0.0, false], ["prop_sprinkler_impact", "normal", 435.0, -1685.0, 0.0, false], ["prop_sprinkler_impact", "normal", 445.0, -1705.0, 0.0, false],
	["prop_sprinkler_impact", "normal", 465.0, -1715.0, 0.0, false], ["prop_sprinkler_impact", "normal", 195.0, -1685.0, 0.0, false], ["prop_sprinkler_impact", "normal", 235.0, -1715.0, 0.0, false], ["prop_sprinkler_impact", "normal", 265.0, -1675.0, 0.0, false],
	["prop_sprinkler_impact", "normal", 275.0, -1715.0, 0.0, false], ["prop_sprinkler_impact", "normal", 405.0, -1665.0, 0.0, false], ["prop_sprinkler_impact", "normal", 455.0, -1675.0, 0.0, false], ["prop_sprinkler_impact", "normal", 455.0, -1645.0, 0.0, false],
	["prop_sprinkler_impact", "normal", 475.0, -1635.0, 0.0, false], ["prop_sprinkler_impact", "normal", 475.0, -1695.0, 0.0, false], ["prop_sprinkler_impact", "normal", 485.0, -1665.0, 0.0, false], ["prop_sprinkler_impact", "normal", 485.0, -1725.0, 0.0, false],
	["prop_sprinkler_impact", "normal", 395.0, -1725.0, 0.0, false],
]

func _init() -> void: _run.call_deferred()

## ---------------------------------------------------------------- heights (world)
static func base(v: float) -> float:
	if v >= -1626.0: return WALK
	if v <= -1726.0: return QUAY
	return lerpf(QUAY, WALK, (v + 1726.0) / 100.0)
static func tbl(t: Array, v: float) -> float:
	if v >= float(t[0][0]): return float(t[0][1])
	for k in range(1, t.size()):
		if v >= float(t[k][0]):
			var a: Array = t[k - 1]; var b: Array = t[k]
			return lerpf(float(a[1]), float(b[1]), (v - float(a[0])) / (float(b[0]) - float(a[0])))
	return float(t[t.size() - 1][1])
## the walk level: base, eased onto the fill's measured edge heights within EASE of the west and east edges
static func yw(u: float, v: float) -> float:
	var dw := u - U0; var de := U1 - u
	var b := base(v)
	if minf(dw, de) >= EASE: return b
	var e := tbl(EDGE_W, v) if dw < de else tbl(EDGE_E, v)
	return lerpf(e, b, smoothstep(0.0, EASE, maxf(0.0, minf(dw, de))))
static func yroad(u: float, v: float) -> float: return yw(u, v) - KERB
## the revetments (u 190 - 212 west, 384 - 490 east): straight down from the walk's edge (v -1750) to the bay bed at
## the toe (v -1758, the land there); at the piece's own west / east edge the fill's measured heights
static func yrip(u: float, v: float) -> float:
	var t := clampf((VF - v) / (VF - TOE), 0.0, 1.0)
	var y := lerpf(yw(u, VF), LAND.at(u, TOE), t)
	var d := minf(u - U0, U1 - u)
	if d < EASE:      # toward the piece's edge the fill's own heights below the top (the top edge stays the walk's)
		var e := tbl(EDGE_W, v) if u - U0 < U1 - u else tbl(EDGE_E, v)
		y = lerpf(y, e, (1.0 - smoothstep(0.0, EASE, maxf(0.0, d))) * t)
	return y

## footprint [u0, v0, u1, v1] of one row of B (yaw 0 / 180 / -90); the terminal's pad under its hall and verandah
## only (its covered walkway and shelter stand on the apron)
static func _fp(b: Array) -> Array:
	var bb: Array = (K.building_stats(String(b[1])).near as Dictionary).bbox
	var cu: float = b[2]; var cv: float = b[3]; var yaw: float = b[4]
	var f: Array
	if absf(yaw) < 1.0: f = [cu + float(bb[0][0]), cv + float(bb[0][2]), cu + float(bb[1][0]), cv + float(bb[1][2])]
	elif absf(yaw - 180.0) < 1.0: f = [cu - float(bb[1][0]), cv - float(bb[1][2]), cu - float(bb[0][0]), cv - float(bb[0][2])]
	else: f = [cu - float(bb[1][2]), cv + float(bb[0][0]), cu - float(bb[0][2]), cv + float(bb[1][0])]   # yaw -90
	if String(b[0]) == "terminal": f = [f[0], -1744.5, f[2], f[3]]
	return f

## the landing plaza's and the quay apron's paving: light stone bands 0.5 m wide every 6 m both ways, on the pier's
## axis (u 343) and the quay face (v -1770), over the concrete (paint rects, first in the list)
static func _bands(u0: float, v0: float, u1: float, v1: float) -> Array:
	var out: Array = []
	var k := ceili((u0 - PX) / 6.0)
	while PX + 6.0 * k < u1:
		var u := PX + 6.0 * k
		if u - 0.25 > u0 and u + 0.25 < u1: out.append([u - 0.25, v0, u + 0.25, v1, "paving"])
		k += 1
	k = ceili((v0 - QF) / 6.0)
	while QF + 6.0 * k < v1:
		var v := QF + 6.0 * k
		if v - 0.25 > v0 and v + 0.25 < v1: out.append([u0, v - 0.25, u1, v + 0.25, "paving"])
		k += 1
	return out

## rounded rectangle [u0, v0, u1, v1, R] as a closed point list (clockwise from the north-west straight's start),
## n segments a corner: the loop's kerb and the island share the same angles (concentric)
static func rrect(r: Array, n := 6) -> PackedVector2Array:
	var u0: float = r[0]; var v0: float = r[1]; var u1: float = r[2]; var v1: float = r[3]; var R: float = r[4]
	var cs := [[u0 + R, v0 + R, 180.0], [u1 - R, v0 + R, 270.0], [u1 - R, v1 - R, 0.0], [u0 + R, v1 - R, 90.0]]
	var out := PackedVector2Array()
	for c: Array in cs:
		for k in n + 1:
			var a := deg_to_rad(float(c[2]) + 90.0 * k / n)
			out.append(Vector2(float(c[0]) + R * cos(a), float(c[1]) + R * sin(a)))
	return out

## one prop on the ground already built at (u, v)
var g: K.Ground
var props: K.Props
func P(base_: String, cond: String, u: float, v: float, yaw := 0.0, collide := true) -> void:
	var y := H.top_at(g, u, v)
	if y == -INF:
		print("WARN no ground under %s at %.1f %.1f" % [base_, u, v]); return
	I.add(props, base_, cond, Vector3(u, y, v), yaw, collide)
func PY(base_: String, cond: String, u: float, y: float, v: float, yaw := 0.0, collide := true) -> void:
	I.add(props, base_, cond, Vector3(u, y, v), yaw, collide)

## a railing from a to b: 4.09 m modules end to end, a 2 m wall-flange module where the run's rest allows
func rail(a: Vector2, b: Vector2, y: float) -> void:
	var L := a.distance_to(b); var d := (b - a).normalized()
	var n := int(floor(L / 4.09))
	var yaw := rad_to_deg(atan2(d.x, d.y)) + 90.0
	for k in n:
		var m := a + d * (2.045 + 4.09 * k)
		I.add(props, "prop_prom_rail", "clean", Vector3(m.x, y, m.y), yaw)
	if L - n * 4.09 >= 2.05:
		var m2 := a + d * (n * 4.09 + 1.02)
		I.add(props, "prop_prom_rail_wall", "clean", Vector3(m2.x, y, m2.y), yaw)

func _run() -> void:
	var root := Node3D.new(); root.name = NAME
	var bl := Node3D.new(); bl.name = "Buildings"; root.add_child(bl)
	g = K.Ground.new(); props = K.Props.new(); var dec := K.Decals.new()
	var fw := func(u: float, v: float) -> float: return yw(u, v)
	var fr := func(u: float, v: float) -> float: return yroad(u, v)
	var fq := func(_u: float, _v: float) -> float: return QUAY
	var fx := func(u: float, v: float) -> float: return yrip(u, v)
	# ---- the walk level (grass where nothing else is listed)
	# (the buildings' pads first, then the holes, then the stone bands, then the surfaces; the field on a 4 m grid:
	#  its edges still meet the fill's 2 m vertices on the same straight lines)
	var paints: Array = []
	for bd: Array in B: paints.append(H.pad_rect(_fp(bd)))
	for pr: Array in PAINTS: if String(pr[4]) == "-": paints.append(pr)
	for bd: Array in BEDS: paints.append([bd[0], bd[1], bd[2], bd[3], "mulch"])
	paints.append_array(_bands(318.0, -1750.0, 383.3, -1676.0))
	for pr: Array in PAINTS: if String(pr[4]) != "-": paints.append(pr)
	H.paint(g, U0, VF, U1, VS, paints, "grass", fw, 4.0)
	# ---- the roads, with their markings and the lot's stalls
	var stalls: Array = []
	var rpaint: Array = []
	rpaint.append([349.92, -1663.0, 350.08, VSTEM, "yellow"])                    # the drive's centre line
	for k in 11: rpaint.append([344.8 + k, -1661.6, 345.3 + k, -1658.9, "white"])  # the zebra over the drive: the lot's walk to the coach stop
	for k in 6: rpaint.append([336.3, -1658.0 + k * 1.1, 340.3, -1657.5 + k * 1.1, "white"])   # the zebra over the connector (the drive's west walk)
	# the four rows of 38 stalls (2.7 m) between the cross aisles (u 207 - 309.6): [aisle edge, nose direction]
	for row: Array in [[-1631.5, 1.0], [-1638.5, -1.0], [-1651.5, 1.0], [-1658.5, -1.0]]:
		var ve: float = row[0]; var dir: float = row[1]; var va := ve + dir * STALL_D
		for k in 39:
			var u := 207.0 + 2.7 * k
			rpaint.append([u - 0.05, minf(ve, va) + (0.3 if dir < 0 else 0.0), u + 0.05, maxf(ve, va) - (0.3 if dir > 0 else 0.0), "white"])
		for k in 38:
			var cu := 207.0 + 2.7 * k + 1.35; var cv := ve + dir * STALL_D * 0.5
			var yaw := 0.0 if dir > 0.0 else 180.0
			var gr := snappedf((yroad(cu, cv + dir * 2.0) - yroad(cu, cv - dir * 2.0)) / 4.0, 0.001)
			stalls.append([cu, cv, yaw, yroad(cu, cv), gr])
	for r: Array in ROADS:
		var sub: Array = []
		for p: Array in rpaint:
			if float(p[0]) >= float(r[0]) - 0.01 and float(p[2]) <= float(r[2]) + 0.01 and float(p[1]) >= float(r[1]) - 0.01 and float(p[3]) <= float(r[3]) + 0.01: sub.append(p)
		H.paint(g, r[0], r[1], r[2], r[3], sub, "asphalt", fr)
	for kl: Array in KERBS:
		for k in kl.size() - 1:
			H.step_face(g, Vector2(kl[k][0], kl[k][1]), Vector2(kl[k + 1][0], kl[k + 1][1]), fw, fr, "curb", 1.0)
	# ---- the drop-off loop: the ring (lane between the kerb and the island), the island (raised lawn), the plaza's
	#      four corners outside the kerb's arcs; kerb faces round both (open at the drive's mouth)
	var ro := rrect(LOOP); var ri := rrect(ISLE)
	for k in ro.size():
		var k2 := (k + 1) % ro.size()
		var a := ro[k]; var b := ro[k2]; var c := ri[k2]; var d := ri[k]
		if a.distance_to(b) < 0.01: continue
		g.quad("asphalt", Vector3(a.x, yroad(a.x, a.y), a.y), Vector3(b.x, yroad(b.x, b.y), b.y), Vector3(c.x, yroad(c.x, c.y), c.y), Vector3(d.x, yroad(d.x, d.y), d.y))
	g.poly("grass", ri, fw)
	for k in ri.size():
		H.step_face(g, ri[k], ri[(k + 1) % ri.size()], fw, fr, "curb", 1.0)
	for k in ro.size():
		var a := ro[k]; var b := ro[(k + 1) % ro.size()]
		if absf(a.y - LOOP[3]) > 0.01 or absf(b.y - LOOP[3]) > 0.01:     # not the north straight (v -1676, the drive's mouth)
			H.step_face(g, a, b, fw, fr, "curb", 1.0)
		else:                                                          # the north straight: open at the drive
			var lo := minf(a.x, b.x); var hi := maxf(a.x, b.x)
			if lo < 344.3: H.step_face(g, Vector2(lo, a.y), Vector2(344.3, a.y), fw, fr, "curb", 1.0)
			if hi > 355.7: H.step_face(g, Vector2(355.7, a.y), Vector2(hi, a.y), fw, fr, "curb", 1.0)
	var n := 7
	for ci in 4:
		var corner: Vector2 = [Vector2(324.0, -1714.0), Vector2(376.0, -1714.0), Vector2(376.0, -1676.0), Vector2(324.0, -1676.0)][ci]
		var pts := PackedVector2Array([corner])
		for k in n: pts.append(ro[ci * n + k])
		g.poly("plaza", pts, fw)
	# ---- the quay apron on the bastion and the revetments
	H.paint(g, 304.0, -1768.0, 382.0, VF, _bands(304.0, -1768.0, 382.0, VF), "concrete", fq)
	H.paint(g, U0, TOE, 212.0, VF, [], "ferry_riprap", fx)
	H.paint(g, 384.0, TOE, U1, VF, [], "ferry_riprap", fx)
	# the west seawall's end (u 212): a face from the promenade's edge down the revetment beside it
	H.step_face(g, Vector2(212.0, VF), Vector2(212.0, -1752.0), fw, fx, "wall", 0.5)
	# ---- buildings on their pads
	for b: Array in B:
		var cu: float = b[2]; var cv: float = b[3]; var yaw: float = b[4]
		var f := _fp(b)
		var y := H.pad_height(f, yaw, fw)
		H.level_pad(g, "concrete", float(f[0]) - 0.3, float(f[1]) - 0.3, float(f[2]) + 0.3, float(f[3]) + 0.3, y, fw)
		K.building(bl, String(b[1]), Vector3(cu, y, cv), yaw, String(b[0]))
		print("building %s pad %.3f footprint %s" % [b[0], y, str(f)])
	_waterfront()
	_dress()
	H.sc_apply(root, props, dec, SC)
	_empty_report(paints)
	root.set_meta(&"stalls", stalls)
	H.finish(root, g, props, dec, NAME)
	quit()

## ---------------------------------------------------------------- the quay, the pier, the berths, the boats
func _waterfront() -> void:
	for q: Array in QUAYS:
		var kind: String = q[0]; var yaw: float = q[3]
		var pos: Vector3
		if absf(yaw) > 45.0 and absf(yaw) < 135.0: pos = Vector3(float(q[2]) + (1.0 if yaw < 0.0 else -1.0), BED, float(q[1]))   # returns: [kind, v, u_face, yaw]
		else: pos = Vector3(float(q[1]), BED, float(q[2]) + 1.0)
		I.add(props, "prop_quay_" + kind, "clean", pos, yaw)
	# the bastion's outer corners (2 m square, under the coping's corner)
	I.add(props, "prop_quay_corner_out", "clean", Vector3(303.0, BED, -1769.0), 180.0)
	I.add(props, "prop_quay_corner_out", "clean", Vector3(383.0, BED, -1769.0), 90.0)
	for r: Array in RAILS: rail(Vector2(r[0][0], r[0][1]), Vector2(r[1][0], r[1][1]), QUAY if r[0][1] < VF + 0.1 else yw(r[0][0], r[0][1]))
	# the pier on the terminal's axis: four straights and the T-head (kit snap: root + 4, 10, 16, 22; T-head + 28)
	for k in 4: I.add(props, "prop_pier_straight", "clean", Vector3(PX, BED, QF - 3.0 - 6.0 * k), 180.0)
	var tz := QF - 27.0
	I.add(props, "prop_pier_thead", "clean", Vector3(PX, BED, tz), 180.0)
	# its lamps (the landing lit at night), lifering stands
	for vl: float in [QF - 6.0, QF - 18.0]:
		for s: float in [-1.0, 1.0]: I.add(props, "prop_pier_lamp", "clean", Vector3(PX + s * 1.85, QUAY, vl), 0.0)
	for c: Vector2 in [Vector2(PX - 5.7, tz + 2.6), Vector2(PX + 5.7, tz + 2.6), Vector2(PX - 5.7, tz - 3.0), Vector2(PX + 5.7, tz - 3.0)]:
		I.add(props, "prop_pier_lamp", "clean", Vector3(c.x, QUAY, c.y), 0.0)
	I.add(props, "prop_lifering_stand", "worn", Vector3(PX - 1.8, QUAY, QF - 12.0), 90.0)
	I.add(props, "prop_lifering_stand", "worn", Vector3(PX - 5.6, QUAY, tz - 0.2), 90.0)
	# (the benches and the bin at the head's far rail were taken out: superchecker off_ground / overlap, a pier deck is
	#  a kit prop, not ground)
	# the harbour patrol's float off the T-head's east side: gangway down to it, its piles, a power pedestal; the
	# patrol boat (express cruiser) on its bay side, a skiff on the other
	I.add(props, "prop_gangway", "clean", Vector3(PX + 11.0, BED + 1.95, tz + 0.5), 90.0)
	I.add(props, "prop_marina_float", "clean", Vector3(PX + 19.6, BED + 1.2, tz + 0.5), 180.0)
	for px: float in [16.2, 23.0]: I.add(props, "prop_marina_pile", "clean", Vector3(PX + px, BED, tz + 0.5), 0.0)
	I.add(props, "prop_marina_pedestal", "clean", Vector3(PX + 21.5, BED + 1.95, tz + 0.9), 180.0)
	_boat("prop_boat_express", PX + 19.6, tz + 3.6, 90.0)      # HARBOUR PATROL at the end of the landing
	_boat("prop_boat_skiff", PX + 19.6, tz - 2.0, -90.0)
	# the troller tied up alongside the landing steps (bollard modules either side), the visiting sloop on the east berth
	_boat("prop_boat_troller", 319.0, QF - 2.35, 90.0)
	_boat("prop_boat_sloop", 358.0, QF - 2.1, -90.0)

## (a check, places nothing) the lawn cells (2 m) with nothing within 12 m, as the superchecker's empty_area counts
## them, printed in 10 m clusters so the dressing can be read against them
func _empty_report(paints: Array) -> void:
	var pts: Array = []
	for k: String in props.items:
		for t: Transform3D in props.items[k]: pts.append(Vector2(t.origin.x, t.origin.z))
	for b: Array in B: pts.append(Vector2(b[2], b[3]))
	var cl := {}; var n := 0
	var u := U0 + 1.0
	while u < U1:
		var v := VS - 1.0
		while v > VF:
			var m := "grass"
			for pr: Array in paints:
				if u > float(pr[0]) and u < float(pr[2]) and v > float(pr[1]) and v < float(pr[3]): m = String(pr[4]); break
			if m == "grass":
				var near := false
				for q: Vector2 in pts:
					if absf(q.x - u) < 12.0 and absf(q.y - v) < 12.0 and q.distance_to(Vector2(u, v)) < 12.0: near = true; break
				if not near:
					n += 1; var key := Vector2i(int(floor(u / 10.0)) * 10, int(floor(v / 10.0)) * 10)
					cl[key] = int(cl.get(key, 0)) + 1
			v -= 2.0
		u += 2.0
	print("EMPTY lawn %d m2 (cells %d); 10 m squares: %s" % [n * 4, n, str(cl.keys())])

func _boat(base_: String, u: float, v: float, yaw: float) -> void:
	const WL := {"prop_boat_sloop": 1.40, "prop_boat_express": 0.70, "prop_boat_troller": 1.35, "prop_boat_skiff": 0.30}
	I.add(props, base_, "clean", Vector3(u, 0.0 - float(WL[base_]), v), yaw)

## ---------------------------------------------------------------- dressing: what people use, each with its reason
func _dress() -> void:
	# ---- the drive: Victorian lamps on both walks (the landing's lamps), the coach stop's shelter and sign, a
	#      (no hydrant: superchecker hydrant_nowhere, no building wall near)
	for v: float in [-1634.0, -1652.0, -1670.0]: P("prop_lamp_victorian", "worn", 341.6, v, 0.0)
	for v: float in [-1630.0, -1664.0]: P("prop_lamp_victorian", "worn", 358.4, v, 0.0)
	P("prop_bus_shelter", "worn", 361.6, -1648.0, -90.0)
	P("prop_bus_stop_sign", "worn", 359.3, -1640.5, -90.0)
	# ---- the park and ride: lot lights on the island, wheel stops at every stall's head, the pay station on the
	#      walk the riders take to the boat, hedges screening the cars from 1st St
	for u: float in [220.0, 243.0, 266.0, 289.0]: P("prop_lot_light_pole", "worn", u, -1645.0, 0.0)
	for row: Array in [[-1631.5, 1.0], [-1638.5, -1.0], [-1651.5, 1.0], [-1658.5, -1.0]]:
		for k in 38:
			P("prop_wheel_stop_concrete", "worn", 207.0 + 2.7 * k + 1.35, float(row[0]) + float(row[1]) * (STALL_D - 0.55), 0.0, false)
	P("prop_pay_station", "worn", 250.5, -1667.4, 180.0)
	H.hedge(props, Vector2(200.0, -1623.5), Vector2(297.0, -1623.5), func(u: float, v: float) -> float: return yw(u, v))
	H.hedge(props, Vector2(303.0, -1623.5), Vector2(318.0, -1623.5), func(u: float, v: float) -> float: return yw(u, v))
	# the lot's west and east sides screened too, and the museum lawn's 1st St edge (a gap at its path, u 428 - 431)
	H.hedge(props, Vector2(196.5, -1626.0), Vector2(196.5, -1666.0), func(u: float, v: float) -> float: return yw(u, v))
	H.hedge(props, Vector2(321.5, -1628.0), Vector2(321.5, -1650.0), func(u: float, v: float) -> float: return yw(u, v))
	H.hedge(props, Vector2(362.0, -1623.5), Vector2(427.0, -1623.5), func(u: float, v: float) -> float: return yw(u, v))
	H.hedge(props, Vector2(432.0, -1623.5), Vector2(486.0, -1623.5), func(u: float, v: float) -> float: return yw(u, v))
	# ---- the loop's island: the landing's monument in the middle, bird of paradise and agave round it
	P("prop_obelisk_monument", "worn", 350.0, -1695.0, 0.0)
	for c: Array in [[344.0, -1691.0], [356.0, -1699.0]]: P("plant_bird_of_paradise", "normal", c[0], c[1], 0.0)
	for c: Array in [[356.0, -1690.5], [344.0, -1699.5]]: P("plant_agave_americana", "normal", c[0], c[1], 0.0)
	for c: Array in [[337.5, -1695.0], [362.5, -1695.0]]: P("plant_bougainvillea_mound", "normal", c[0], c[1], 0.0)
	# ---- the landing plaza and forecourt: lamps round the loop, planters at the terminal's door, the terminal's bins
	#      against its side walls, racks along its east side, paper boxes at the door
	for c: Array in [[320.5, -1680.0], [320.5, -1710.0], [379.5, -1710.0], [332.0, -1718.0], [368.0, -1718.0], [320.5, -1735.0], [379.5, -1735.0]]:
		P("prop_lamp_victorian", "worn", c[0], c[1], 0.0)
	for u: float in [345.0, 355.0]: P("plant_potted_leafy", "normal", u, -1728.6, 0.0)
	# the plaza's beds: low boxwood along their walk sides, the shrubs inside (the palms are in the trees list); a bench
	# on the walk side of each bed (its back to the planting), iron bollards along the loop's south kerb (the drop-off:
	# cars never reach the plaza)
	for bd: Array in BEDS:
		var u0: float = bd[0]; var v0: float = bd[1]; var u1: float = bd[2]; var v1: float = bd[3]
		H.hedge(props, Vector2(u0 + 1.0, v1 - 0.5), Vector2(u1 - 1.0, v1 - 0.5), func(u: float, v: float) -> float: return yw(u, v))
		H.hedge(props, Vector2(u0 + 1.0, v0 + 0.5), Vector2(u1 - 1.0, v0 + 0.5), func(u: float, v: float) -> float: return yw(u, v))
		var cu := (u0 + u1) * 0.5; var cv := (v0 + v1) * 0.5
		P("plant_bougainvillea_mound", "normal", cu, cv, 0.0)
		P("plant_bird_of_paradise", "normal", u0 + 2.0, cv + 1.2, 0.0); P("plant_bird_of_paradise", "normal", u1 - 2.0, cv - 1.2, 0.0)
		P("plant_agave_americana", "normal", u0 + 2.2, cv - 1.6, 0.0); P("plant_agave_americana_small", "normal", u1 - 2.2, cv + 1.6, 0.0)
	for c: Array in [[328.5, -1718.2, 0.0], [371.5, -1718.2, 0.0], [328.0, -1741.0, 180.0], [372.0, -1741.0, 180.0]]:
		for du: float in [-1.25, 1.25]: P("prop_park_bench", "worn", c[0] + du, c[1], c[2])     # in pairs
	for k in 9: P("prop_bollard_iron", "worn", 338.0 + 3.0 * k, -1714.8, 0.0)
	for u: float in [339.8, 342.3, 357.7, 360.2]: P("prop_park_bench", "worn", u, -1727.6, 0.0)      # facing the loop: waiting for a taxi
	for v: float in [-1679.5, -1686.5]: P("plant_potted_leafy", "normal", 382.4, v, 0.0)            # the museum's door
	P("prop_trash_receptacle", "worn", 339.4, -1736.0, 0.0)
	P("prop_recycling_receptacle", "worn", 360.6, -1736.0, 0.0)
	P("prop_bike_rack", "worn", 363.2, -1740.5, 90.0)
	P("prop_newspaper_box_blue", "worn", 358.4, -1728.4, 180.0)
	# ---- the quay apron: Victorian lamps along the bastion, benches in pairs facing the bay, lifering stands at the
	#      rail, the dock box at the troller's berth
	for u: float in [309.0, 333.0, 353.0, 377.0]: P("prop_lamp_victorian", "worn", u, -1766.6, 0.0)
	for u: float in [329.5, 332.0, 366.0, 368.5]: P("prop_park_bench", "worn", u, -1766.0, 180.0)
	for c: Array in [[311.5, -1767.7], [322.6, -1767.7], [371.5, -1767.7], [304.6, -1760.0]]: P("prop_lifering_stand", "worn", c[0], c[1], 180.0 if c[1] < -1765.0 else -90.0)
	P("prop_dock_box", "clean", 316.0, -1767.2, 180.0)
	# ---- the west promenade: lamps, bench pairs facing the bay, lifering stands, the beach steps' kayak rack and shower
	for u: float in [218.0, 248.0, 279.0, 302.0]: P("prop_lamp_victorian", "worn", u, -1749.3, 0.0)
	for u: float in [224.0, 226.5, 263.0, 265.5, 289.0, 291.5]: P("prop_park_bench", "worn", u, -1748.6, 180.0)
	# ---- the marketplace's fronts: the bistro's and the cafe's tables on the promenade, the ice-cream parlour's,
	#      planters at the doors, a bike rack along the row
	for c: Array in [[305.0, -1744.6], [310.5, -1744.2], [315.6, -1744.8], [291.5, -1744.2], [299.5, -1744.2], [251.0, -1744.2], [259.5, -1744.6]]:
		P("prop_patio_set_4", "worn", c[0], c[1], 0.0)
	for u: float in [279.2, 289.8, 269.0]: P("plant_potted_leafy", "normal", u, -1741.0, 0.0)
	P("prop_bike_rack", "worn", 241.5, -1741.2, 0.0)
	# ---- the green's and the museum garden's lawns: path lamps, the volleyball court, chairs and tables in groups,
	#      the lawns' sprinkler heads (each spot read against the empty-lawn report)
	for c: Array in LAWN: P(String(c[0]), String(c[1]), c[2], c[3], c[4], c.size() < 6 or bool(c[5]))
	# ---- the beach below the seawall (the fill's sand): umbrellas of the day's beach-goers
	for c: Array in [[276.0, -1756.0], [284.5, -1757.0], [293.0, -1756.5]]: PY("prop_beach_umbrella", "clean", c[0], LAND.at(c[0], c[1]), c[1], 0.0)
	for u: float in [230.5, 276.5, 297.0]: P("prop_lifering_stand", "worn", u, -1749.6, 180.0)
	P("prop_kayak_rack", "clean", 236.0, -1745.0, 0.0)
	P("prop_beach_shower", "clean", 238.6, -1748.6, 0.0)
	P("prop_beach_sign_rules", "worn", 249.5, -1749.6, 180.0)
	# ---- the bandstand on the green (concerts on summer evenings), benches in pairs facing it
	P("prop_bandstand", "worn", 262.0, -1705.0, 0.0)
	for u: float in [256.5, 259.0, 265.0, 267.5]: P("prop_park_bench", "worn", u, -1696.6, 180.0)
	# ---- the playground on its sand (families waiting for a boat), benches for the parents facing it
	P("prop_play_structure", "worn", 222.0, -1694.0, 0.0)
	P("prop_swing_set", "worn", 218.5, -1690.6, 90.0)
	P("prop_slide", "worn", 224.8, -1696.6, 0.0)
	for v: float in [-1690.0, -1692.5]: P("prop_park_bench", "worn", 230.0, v, -90.0)
	# ---- the picnic pad: two tables under a shade sail, the kettle barbecue beside them
	P("prop_picnic_table", "worn", 290.0, -1694.0, 0.0)    # under the sail
	P("prop_picnic_table", "worn", 294.6, -1694.0, 0.0)    # its neighbour in the sun
	P("prop_shade_sail", "worn", 290.0, -1694.0, 0.0, false)
	P("prop_bbq_kettle", "worn", 292.4, -1690.6, 0.0)
	# ---- the museum: its exhibits on the bay lawn (three buoys, a boat trailer), benches looking at them, the service
	#      yard's dumpster and condensers against its back wall, lamps on its walks
	P("prop_buoy_nun", "clean", 404.0, -1708.0, 30.0)
	P("prop_buoy_can", "clean", 410.0, -1708.0, -20.0)
	P("prop_buoy_mooring", "clean", 416.0, -1708.5, 0.0)
	P("prop_boat_trailer", "clean", 421.5, -1716.0, 90.0)
	for u: float in [405.5, 408.0]: P("prop_park_bench", "worn", u, -1703.0, 0.0)
	P("prop_dumpster_3yd_blue", "worn", 411.2, -1688.0, 90.0)
	for v: float in [-1682.0, -1679.0]: P("prop_ac_condenser", "worn", 410.6, v, 90.0)
	for c: Array in [[395.0, -1700.0], [420.0, -1700.0], [430.0, -1718.0], [429.5, -1660.0], [429.5, -1640.0]]:
		P("prop_lamp_victorian", "worn", c[0], c[1], 0.0)
	# ---- the kiosks' terrace (the kiosks themselves: x_street_food): tables in front of them, bench pairs facing
	#      the bay, lamps, lifering stands at the rail
	for c: Array in [[400.5, -1742.0], [404.5, -1743.5], [408.5, -1742.0], [446.5, -1742.0], [451.0, -1743.0]]:
		P("prop_patio_set_4", "worn", c[0], c[1], 0.0)
	for c: Array in [[423.0, -1747.5], [425.5, -1747.5], [462.0, -1747.5], [464.5, -1747.5]]: P("prop_park_bench", "worn", c[0], c[1], 180.0)
	for u: float in [392.0, 416.0, 438.0, 470.0]: P("prop_lamp_victorian", "worn", u, -1735.0, 0.0)
	for u: float in [419.0, 457.0]: P("prop_lifering_stand", "worn", u, -1749.6, 180.0)
	# ---- the revetments' toe: boulders fallen to the foot and lying on the slope (each spot looked at)
	for c: Array in [[388.0, -1757.0], [393.5, -1756.2], [399.0, -1756.6], [405.0, -1755.8], [411.0, -1757.1], [418.5, -1756.5],
			[426.0, -1756.5], [433.0, -1755.9], [440.5, -1757.0], [447.0, -1756.4], [455.0, -1757.2], [462.0, -1756.0],
			[470.0, -1757.0], [478.0, -1756.3], [195.0, -1756.6], [201.0, -1756.4], [207.0, -1756.0]]:
		P("prop_riprap_boulder", "worn", c[0], c[1], fmod(c[0] * 37.0, 360.0))
	for c: Array in [[396.0, -1753.5], [414.0, -1753.0], [437.0, -1753.6], [459.0, -1753.2], [198.0, -1753.4]]:
		P("prop_riprap_pile", "worn", c[0], c[1], fmod(c[0] * 53.0, 360.0))
