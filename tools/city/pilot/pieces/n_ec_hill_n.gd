extends SceneTree
## Piece n_ec_hill_n (ec fill, the east shore's park beyond the ring, north half): SHORE HILL PARK on the hill east of
## the ring, from the ring's outer walk to u 932, v -500 .. -250. Placed at grid [0, 0, 0], yaw 0 (x = u, z = v,
## y = world). Run once; never when locked.
##
## WHY (planner): the hill (11 m, the highest ground on this side of the island) is the city's view over the ocean
## beach. People come on foot from the city across the ring at the T junction j_rg_se_e652_n400 (v -400; the ring has
## no apron on this side, so no car comes in: no car park). From that corner the BEACH WALK (A400, 3 m paved) climbs the
## hill's south shoulder to the promenade and the beach in the next piece (n_ec_dune_n). Halfway up a spur leads to
## the SHORE HILL LOOKOUT on the summit (a level paved terrace, benches facing the sea, lamps, a drinking fountain).
## The lawn below the ring, sheltered from the sea wind, is the PICNIC GROVE (tables with grills, one shade sail) for
## families from the apartment band; benches at the walk's start for people waiting for friends; sprinklers keep the
## lawn green. Everything else is open lawn (a park: open lawn in the middle, trees later by hand at the edges).
## LAND: 4.1 at the ring rising to 11.1 at the summit (u 900, v -340), 3 - 4 % slopes: the ground follows it
## (n_ec_site.g), the lookout on a level pad at the highest ground under it with faces round it, the field graded up to
## it at 6 %.
const PASS := 2
const K := preload("res://tools/city/pilot/kit_lib.gd")
const W := preload("res://tools/city/pilot/pieces/wear_lib.gd")
const H := preload("res://tools/city/pilot/pieces/hs_fill_lib.gd")
const S := preload("res://tools/city/pilot/pieces/n_ec_site.gd")

const Z0 := -500.0
const Z1 := -250.0
const A400 := [640.0, -401.5, 932.0, -398.5]      # the beach walk from the junction corner (it goes on in n_ec_dune_n)
const SPUR := [898.5, -398.5, 901.5, -350.0]      # up to the lookout
const LOOK := [888.0, -350.0, 912.0, -334.0]      # the summit terrace

## every prop: [base, cond, x, z, yaw(, collide)], each on the built ground
const ITEMS := [
	# the lookout terrace: two pairs of benches on its sea edge facing the ocean (east), a drinking fountain on the
	# back edge, a lamp at each back corner (the walk up is used at dusk)
	["prop_park_bench", "worn", 909.6, -346.4, 90.0], ["prop_park_bench", "worn", 909.6, -343.4, 90.0],
	["prop_park_bench", "worn", 909.6, -340.6, 90.0], ["prop_park_bench", "worn", 909.6, -337.6, 90.0],
	["prop_drinking_fountain", "worn", 889.0, -341.0, 90.0],
	["prop_lamp_victorian", "worn", 888.8, -349.2, 0.0], ["prop_lamp_victorian", "worn", 888.8, -334.8, 0.0],
	# the spur: a lamp halfway up, on the grass beside it
	["prop_lamp_victorian", "worn", 897.6, -374.0, 0.0],
	# the beach walk: lamps on its north side every ~40 m from the junction corner up the hill
	["prop_lamp_victorian", "worn", 690.0, -402.4, 0.0], ["prop_lamp_victorian", "worn", 730.0, -402.4, 0.0],
	["prop_lamp_victorian", "worn", 770.0, -402.4, 0.0], ["prop_lamp_victorian", "worn", 810.0, -402.4, 0.0],
	["prop_lamp_victorian", "worn", 850.0, -402.4, 0.0], ["prop_lamp_victorian", "worn", 920.0, -402.4, 0.0],
	# the walk's start, by the junction corner: two benches on the grass facing the walk (people wait for friends
	# coming across the ring), the beach rules sign facing the people coming in
	["prop_park_bench", "worn", 684.0, -404.6, 0.0], ["prop_park_bench", "worn", 687.6, -404.6, 0.0],
	["prop_beach_sign_rules", "worn", 676.0, -396.8, -90.0],
	# the picnic grove on the lawn below the ring (land 4.4 - 6 m, out of the sea wind): tables with a kettle grill
	# each, one shade sail over the middle table
	["prop_picnic_table", "worn", 742.0, -462.0, 0.0], ["prop_bbq_kettle", "worn", 745.2, -462.0, 0.0],
	["prop_picnic_table", "worn", 760.0, -452.0, 90.0], ["prop_bbq_kettle", "worn", 760.0, -455.4, 0.0],
	["prop_shade_sail", "worn", 760.0, -452.0, 90.0],
	["prop_picnic_table", "worn", 778.0, -466.0, 0.0], ["prop_bbq_kettle", "worn", 781.2, -466.0, 0.0],
	["prop_picnic_table", "worn", 752.0, -476.0, 20.0], ["prop_bbq_kettle", "worn", 755.2, -477.0, 0.0],
	["prop_drinking_fountain", "worn", 768.0, -444.0, 0.0],
	# the north lawn on the hill's flank: a table and grill with the view down to the beach
	["prop_picnic_table", "worn", 880.0, -470.0, 90.0], ["prop_bbq_kettle", "worn", 880.0, -473.4, 0.0],
	# the hill's east brow: two benches facing the beach
	["prop_park_bench", "worn", 920.0, -301.8, 90.0], ["prop_park_bench", "worn", 920.0, -298.3, 90.0],
	# lawn sprinklers (no collision: flush with the grass)
	["prop_sprinkler_impact", "normal", 720.0, -350.0, 0.0, false], ["prop_sprinkler_impact", "normal", 800.0, -300.0, 0.0, false],
	["prop_sprinkler_impact", "normal", 820.0, -460.0, 0.0, false], ["prop_sprinkler_impact", "normal", 860.0, -280.0, 0.0, false],
	["prop_sprinkler_impact", "normal", 760.0, -420.0, 0.0, false], ["prop_sprinkler_impact", "normal", 700.0, -280.0, 0.0, false],
]

## SUPERCHECKER (filled after the checker's pass; see the README review/fill_east/ec.md)
const SC := {
 "out": [
 ],
 "turn": [
 ],
 "decals": [
 ],
 "boxes": [
 ],
}

func _init() -> void: _run.call_deferred()

func _run() -> void:
	var root := Node3D.new(); root.name = "n_ec_hill_n"
	var bl := Node3D.new(); bl.name = "Buildings"; root.add_child(bl)
	var g := K.Ground.new(); var props := K.Props.new(); var dec := K.Decals.new()
	var yb := func(x: float, z: float) -> float: return S.g(x, z)
	var ly := S.pad_top(LOOK[0], LOOK[1], LOOK[2], LOOK[3], yb)
	var yf := H.graded(yb, [[LOOK[0], LOOK[1], LOOK[2], LOOK[3], ly]])
	var paints: Array = [
		[LOOK[0], LOOK[1], LOOK[2], LOOK[3], "-"],
		[A400[0], A400[1], A400[2], A400[3], "plaza"],
		[SPUR[0], SPUR[1], SPUR[2], SPUR[3], "plaza"],
	]
	S.rows(g, Z0, Z1, [func(z: float) -> float: return S.ring_u(z), S.U_W], ["grass"], paints, yf)
	H.level_pad(g, "plaza", LOOK[0], LOOK[1], LOOK[2], LOOK[3], ly, yf)
	# the open north edge (builder eb's ground meets it at the same rule): a face under it so no gap shows meanwhile
	H.skirt(g, Vector2(S.ring_u(Z0), Z0), Vector2(S.U_W, Z0), yf, "grass")
	if PASS >= 2: H.polish(props, g, ITEMS)
	if PASS >= 2: H.sc_apply(root, props, dec, SC)
	print("n_ec_hill_n lookout pad %.2f" % ly)
	H.finish(root, g, props, dec, "n_ec_hill_n")
	quit()
