extends SceneTree
## Piece n_ea_cape (ea fill, the east shore north of v -1460): NORTH BEACH - the park band along the ring and the wide
## beach below it, round the ring's north-east bend.
## The land with no piece between the ring's outer walk (s_rg_nw_b163_1..3, from the u 500 junction's corner at u 516,
## v -1618 round the bend to u 673, v -1460) and the sea, v -1700 .. -1460, out to 25 m past the 0 m line (the sand goes
## on under the water there). Placed at grid [0, 0, 0], yaw 0 (x = u, z = v, y = world height). Run once.
##
## WHY (planner): across the ring lies the hospital campus (n_hp_main / n_hp_transit) and, at the u 500 junction, the
## campus's north road: staff on their breaks, visitors and patients' families, and the town on summer days come over at
## that junction's corner, and from the south along the promenade from the v -1400 junction's crossing. No street has an
## apron here: nobody drives in; they walk and ride (bike racks at the entries, none on the sand). So: by the u 500
## corner the NORTH BEACH COMMONS - a paved forecourt with NORTH BEACH RENTALS (kayaks, paddle boards, bikes; its racks
## out on the sand at the first access) and the NORTH BEACH CAFE with its terrace to the sea; from there the PROMENADE
## runs along the grass side of the dune line, lamps on its land side, benches facing the sea; four boardwalk ACCESSES
## cross the dune onto the sand, a shower at each; on the grass band between the ring and the promenade picnic tables
## with grills (lunch breaks, family days). On the sand: two VOLLEYBALL courts at the quiet west end (the sand there is
## high and dry, far from the water), three LIFEGUARD TOWERS about 140 m apart facing the water with life rings, the
## rip-current signs near the water, families' umbrellas in groups between the towers.
## LAND: 2.0 - 2.1 m at the ring falling to the sea over 60 - 200 m; the ground follows it (n_ea_site.g, 5 cm over the
## land, 0 at the water and under it, eased onto the ring's walk within 12 m); the two buildings stand on level pads at
## the highest ground under them, the field graded up to them at 6 %. Grass > sand along n_ea_site.DUNE.
## No trees here (hand list zoning/trees/ea_cape.json, t_ea_cape).
const PASS := 2
const K := preload("res://tools/city/pilot/kit_lib.gd")
const H := preload("res://tools/city/pilot/pieces/hs_fill_lib.gd")
const S := preload("res://tools/city/pilot/pieces/n_ea_site.gd")
const NAME := "n_ea_cape"

const B := [
	["rent", "commercial/com_surf_shop", 548.0, -1630.0, 180.0],        # NORTH BEACH RENTALS: front (door u 551.3) to the forecourt and the sea
	["cafe", "commercial/com_cafe_seaside", 578.0, -1630.0, 180.0],     # NORTH BEACH CAFE: front (door u 579.8) to its terrace and the sea
]
## the forecourt of both shops (the promenade's west end): from the junction's corner to the cafe's terrace
const PLAZA := [516.0, -1647.0, 596.0, -1637.0]
## the entry path from the u 500 junction's corner (the ring's outer walk ends at u 516) up to the forecourt
const ENTRY := [516.0, -1637.0, 519.5, -1618.3]
## a path from the ring's outer walk (people walking along the ring from the hospital) to the promenade
const RINGPATH := [Vector2(611.0, -1587.0), Vector2(625.0, -1615.5)]
## beach accesses: boardwalk decks from the forecourt / the promenade over the dune onto the sand (centre, yaw)
const DECKS := [
	# A1 at the rentals' door: north from the forecourt (dune at v -1666)
	[548.0, -1649.0, 90.0], [548.0, -1653.0, 90.0], [548.0, -1657.0, 90.0], [548.0, -1661.0, 90.0], [548.0, -1665.0, 90.0],
	# A2 at the cafe's terrace
	[586.0, -1649.0, 90.0], [586.0, -1653.0, 90.0], [586.0, -1657.0, 90.0],
	# A3 from the promenade (its 60 m point) toward the sea (north-east)
	[639.06, -1607.89, 45.0], [641.89, -1610.72, 45.0], [644.71, -1613.55, 45.0], [647.54, -1616.38, 45.0], [650.37, -1619.21, 45.0],
	# A4 from the promenade (its 150 m point) east
	[682.07, -1527.82, 17.0], [685.9, -1528.99, 17.0], [689.72, -1530.16, 17.0], [693.55, -1531.33, 17.0], [697.37, -1532.5, 17.0],
]

const ITEMS := [
	# ---- the forecourt: two bike racks along its south edge by the entry (people ride over from the campus), a
	#      drinking fountain and the beach rules where the entry arrives, a bench pair facing the sea at its west end
	["prop_bike_rack", "worn", 525.0, -1638.4, 0.0], ["prop_bike_rack", "worn", 530.0, -1638.4, 0.0],
	["prop_drinking_fountain", "worn", 521.4, -1638.3, 0.0],
	["prop_beach_sign_rules", "worn", 518.0, -1645.6, 0.0],
	["prop_park_bench", "worn", 524.0, -1645.6, 180.0], ["prop_park_bench", "worn", 526.4, -1645.6, 180.0],
	# ---- NORTH BEACH RENTALS: boards on two racks by its front, the kayak racks out on the sand either side of access
	#      A1's foot (kayaks are carried straight down to the water), an ice chest of cold drinks by its door
	["prop_surfboard_rack", "clean", 544.4, -1639.4, 180.0], ["prop_surfboard_rack", "clean", 545.6, -1639.4, 180.0],
	["prop_kayak_rack", "clean", 541.0, -1670.0, 0.0], ["prop_kayak_rack", "clean", 555.0, -1670.0, 0.0],
	["prop_ice_chest", "clean", 555.5, -1639.5, 0.0],
	# ---- NORTH BEACH CAFE: its terrace (tables either side of the door, kept 4 m off it), planters at the terrace's
	#      corners
	["prop_patio_set_4", "worn", 574.6, -1642.8, 0.0], ["prop_patio_set_4", "worn", 584.6, -1642.8, 0.0],
	["plant_potted_leafy", "normal", 572.4, -1639.6, 0.0], ["plant_potted_succulent", "normal", 587.4, -1639.6, 0.0],
	# ---- access feet on the sand: a shower beside each (sand rinsed off before the promenade), the rules at A3 / A4
	["prop_beach_shower", "clean", 551.2, -1668.2, 0.0], ["prop_beach_shower", "clean", 589.2, -1660.2, 0.0],
	["prop_beach_shower", "clean", 650.58, -1622.53, 0.0], ["prop_beach_shower", "clean", 699.12, -1535.34, 0.0],
	["prop_beach_sign_rules", "worn", 639.83, -1605.28, 135.0], ["prop_beach_sign_rules", "worn", 681.53, -1525.15, 107.0],
	# ---- the promenade: lamps on its land side every ~30 m (the walk home after sunset), facing the walk
	["prop_lamp_victorian", "worn", 595.9, -1636.6, 152.0], ["prop_lamp_victorian", "worn", 619.4, -1619.1, 139.0],
	["prop_lamp_victorian", "worn", 639.8, -1597.9, 127.0], ["prop_lamp_victorian", "worn", 656.5, -1573.4, 119.0],
	["prop_lamp_victorian", "worn", 669.2, -1546.6, 112.0], ["prop_lamp_victorian", "worn", 678.7, -1518.4, 107.0],
	["prop_lamp_victorian", "worn", 686.0, -1489.5, 103.0], ["prop_lamp_victorian", "worn", 690.2, -1463.1, 97.0],
	# ---- benches in pairs on its sea side, facing the sea over the dune
	["prop_park_bench", "worn", 610.6, -1633.4, 139.0], ["prop_park_bench", "worn", 612.4, -1631.9, 139.0],
	["prop_park_bench", "worn", 652.2, -1589.7, 127.0], ["prop_park_bench", "worn", 653.6, -1587.9, 127.0],
	["prop_park_bench", "worn", 678.9, -1535.2, 107.0], ["prop_park_bench", "worn", 679.6, -1533.0, 107.0],
	["prop_park_bench", "worn", 692.9, -1480.6, 97.0], ["prop_park_bench", "worn", 693.2, -1478.3, 97.0],
	# ---- the grass band between the ring and the promenade: picnic tables, each with its grill (lunch breaks from the
	#      campus, family days), lawn sprinklers
	["prop_picnic_table", "worn", 603.0, -1616.0, 45.0], ["prop_bbq_kettle", "worn", 605.6, -1613.4, 0.0],
	["prop_picnic_table", "worn", 613.0, -1607.0, 45.0], ["prop_bbq_kettle", "worn", 615.6, -1604.4, 0.0],
	["prop_picnic_table", "worn", 674.0, -1500.0, 15.0], ["prop_bbq_kettle", "worn", 674.6, -1496.6, 0.0],
	["prop_sprinkler_impact", "clean", 598.0, -1608.0, 0.0, false], ["prop_sprinkler_impact", "clean", 645.0, -1575.0, 0.0, false],
	["prop_sprinkler_impact", "clean", 670.0, -1520.0, 0.0, false],
	# ---- the dune line: iceplant and agave holding the sand where the grass ends (clear of the accesses)
	["plant_iceplant_patch", "normal", 537.0, -1665.4, 0.0, false], ["plant_iceplant_patch", "normal", 566.0, -1661.0, 0.0, false],
	["plant_agave_americana_small", "normal", 600.0, -1647.2, 0.0], ["plant_iceplant_patch", "normal", 619.0, -1634.6, 0.0, false],
	["plant_iceplant_patch", "normal", 633.0, -1621.6, 0.0, false], ["plant_iceplant_patch", "normal", 655.0, -1597.4, 0.0, false],
	["plant_agave_americana_small", "normal", 664.5, -1585.6, 0.0], ["plant_iceplant_patch", "normal", 673.6, -1568.0, 0.0, false],
	["plant_iceplant_patch", "normal", 682.6, -1550.0, 0.0, false], ["plant_iceplant_patch", "normal", 693.6, -1508.0, 0.0, false],
	["plant_iceplant_patch", "normal", 698.6, -1488.0, 0.0, false], ["plant_agave_americana_small", "normal", 702.0, -1470.0, 0.0],
	# ---- the sand: two volleyball courts at the dry west end, nets across them (the courts run east - west)
	["prop_volleyball_net", "clean", 562.0, -1686.0, 90.0], ["prop_volleyball_net", "clean", 591.0, -1683.0, 90.0],
	# ---- three lifeguard towers ~140 m apart, 22 m up from the water facing it, a life ring beside each
	["prop_lifeguard_tower", "worn", 630.4, -1655.3, 145.0], ["prop_lifering_stand", "clean", 633.4, -1653.2, 145.0],
	["prop_lifeguard_tower", "worn", 733.6, -1570.1, 131.0], ["prop_lifering_stand", "clean", 735.9, -1567.6, 131.0],
	["prop_lifeguard_tower", "worn", 844.4, -1478.0, 142.0], ["prop_lifering_stand", "clean", 846.8, -1476.2, 142.0],
	# ---- rip-current warnings 10 m up from the water, read from the beach (facing up the sand)
	["prop_beach_sign_rip", "worn", 670.0, -1642.2, -35.0], ["prop_beach_sign_rip", "worn", 804.8, -1525.0, -39.0],
	# ---- families under umbrellas in groups between the towers (open where people sit, one furled), a cooler by some
	["prop_beach_umbrella", "clean", 612.0, -1672.0, 10.0], ["prop_beach_umbrella", "clean", 617.0, -1667.5, 50.0],
	["prop_beach_umbrella_closed", "clean", 621.5, -1675.0, 0.0],
	["prop_beach_umbrella", "clean", 652.0, -1650.0, 20.0], ["prop_beach_umbrella", "clean", 657.5, -1645.5, 80.0],
	["prop_beach_umbrella", "clean", 664.0, -1640.5, 30.0], ["prop_ice_chest", "clean", 659.5, -1651.5, 145.0],
	["prop_beach_umbrella", "clean", 703.0, -1606.0, 15.0], ["prop_beach_umbrella_closed", "clean", 709.0, -1600.0, 0.0],
	["prop_beach_umbrella", "clean", 714.0, -1594.0, 60.0],
	["prop_beach_umbrella", "clean", 762.0, -1546.0, 35.0], ["prop_beach_umbrella", "clean", 768.0, -1540.0, 70.0],
	["prop_ice_chest", "clean", 765.5, -1548.5, 140.0],
	["prop_beach_umbrella", "clean", 812.0, -1505.0, 5.0], ["prop_beach_umbrella", "clean", 818.0, -1499.0, 45.0],
	["prop_beach_umbrella_closed", "clean", 824.0, -1492.0, 0.0],
	["prop_beach_umbrella", "clean", 861.0, -1470.0, 25.0], ["prop_beach_umbrella", "clean", 868.0, -1464.0, 65.0],
]
## buildings' service sides (their backs face the ring): condensers, the bins against the side walls
const SERVICE := [
	["prop_ac_condenser", "worn", 545.0, -1621.7, 0.0], ["prop_ac_condenser", "worn", 576.0, -1621.7, 0.0],
	["prop_trash_receptacle", "dirty", 574.4, -1634.0, 90.0], ["prop_recycling_receptacle", "worn", 574.4, -1632.8, 90.0],
	["prop_trash_receptacle", "dirty", 553.6, -1627.0, -90.0], ["prop_recycling_receptacle", "worn", 553.6, -1628.2, -90.0],
]

## SUPERCHECKER (20 Nov, Yasin via the coordinator: "be MUCH more prone to delete ... any prop or road/ground mark
## with any finding or any doubt is deleted with its reason"): tools/city/super/sc.py check on this piece (area layout
## OUT/fill/ea/area.json); every finding on an item is a deletion here with the checker's reason; a collision box on
## each building column the checker measured. Applied after everything is placed (hs_fill_lib.sc_apply).
const SC := {
 "out": [

 ],
 "turn": [
 ],
 "decals": [

 ],
 "boxes": [
	["Buildings/rent", [2.036573886871338, 1.4999818801879883, 6.879859924316406, 0.16, 2.9999637603759766, 0.16]],
	["Buildings/cafe", [1.0249133110046387, 1.4999818801879883, 6.8799638748168945, 0.16, 2.9999637603759766, 0.16]],
 ],
}

var PY: Array = []

func _init() -> void: _run.call_deferred()

static func bbox(f: String) -> Array:
	var st := K.building_stats(f)
	if st.has("near") and (st.near as Dictionary).has("bbox"): return (st.near as Dictionary).bbox
	var wd: Array = st.footprint_wd
	return [[-float(wd[0]) * 0.5, 0.0, -float(wd[1]) * 0.5], [float(wd[0]) * 0.5, float(st.get("height", 6.0)), float(wd[1]) * 0.5]]
static func fp(b: Array) -> Array:
	var x := bbox(String(b[1])); var cu: float = b[2]; var cv: float = b[3]; var yaw: float = b[4]
	if absf(yaw) < 1.0: return [cu + float(x[0][0]), cv + float(x[0][2]), cu + float(x[1][0]), cv + float(x[1][2])]
	if absf(yaw - 180.0) < 1.0: return [cu - float(x[1][0]), cv - float(x[1][2]), cu - float(x[0][0]), cv - float(x[0][2])]
	if absf(yaw - 90.0) < 1.0: return [cu + float(x[0][2]), cv - float(x[1][0]), cu + float(x[1][2]), cv - float(x[0][0])]
	return [cu - float(x[1][2]), cv + float(x[0][0]), cu - float(x[0][2]), cv + float(x[1][0])]

func _run() -> void:
	var root := Node3D.new(); root.name = NAME
	var bl := Node3D.new(); bl.name = "Buildings"; root.add_child(bl)
	var g := K.Ground.new(); var props := K.Props.new(); var dec := K.Decals.new()
	var yb := func(x: float, z: float) -> float: return S.g(x, z)
	var pe: Array = []
	for b: Array in B:
		PY.append(H.pad_height(fp(b), float(b[4]), yb)); pe.append(H.pad_entry(fp(b), float(PY[PY.size() - 1])))
	var yf := H.graded(yb, pe)
	var regions: Array = []
	for b: Array in B:
		var r: Array = H.pad_rect(fp(b)); regions.append([S.rectp(r[0], r[1], r[2], r[3]), "-"])
	regions.append([S.rectp(PLAZA[0], PLAZA[1], PLAZA[2], PLAZA[3]), "plaza"])
	regions.append([S.rectp(ENTRY[0], ENTRY[1], ENTRY[2], ENTRY[3]), "plaza"])
	regions.append([S.strip(S.PROM, S.PROM_W), "plaza"])
	regions.append([S.strip(RINGPATH, 2.5), "plaza"])
	S.fill(g, S.outline("cape"), regions, S.grass_poly(), yf)
	for i in B.size(): H.pad_at(g, fp(B[i]), float(PY[i]), yf)
	# the free edges (v -1700: the shore goes on north; u 516: the land north of the u 500 junction): a skirt, so a
	# neighbour built later at the land's height never looks under this one's 5 cm
	H.skirt(g, Vector2(516.0, -1700.0), Vector2(648.0, -1700.0), yf, "sand")
	H.skirt(g, Vector2(516.0, -1700.0), Vector2(516.0, -1668.0), yf, "sand")
	H.skirt(g, Vector2(516.0, -1668.0), Vector2(516.0, -1647.0), yf, "grass")
	if PASS >= 2:
		for i in B.size():
			var b: Array = B[i]
			K.building(bl, String(b[1]), Vector3(b[2], float(PY[i]), b[3]), float(b[4]), String(b[0]))
		for d: Array in DECKS: S.deck(props, yf, float(d[0]), float(d[1]), float(d[2]))
		for it: Array in ITEMS + SERVICE:
			S.put(props, yf, String(it[0]), String(it[1]), float(it[2]), float(it[3]), float(it[4]), bool(it[5]) if it.size() > 5 else true)
		H.sc_apply(root, props, dec, SC)
	print("%s: dune holes %d" % [NAME, S.holes_seen])
	H.finish(root, g, props, dec, NAME)
	quit()
