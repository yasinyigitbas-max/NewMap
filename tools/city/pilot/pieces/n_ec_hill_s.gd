extends SceneTree
## Piece n_ec_hill_s (ec fill, the east shore's park beyond the ring, south half): SHORE HILL PARK's south lawn, from
## the ring's outer walk to u 932, v -250 .. 0. Placed at grid [0, 0, 0], yaw 0 (x = u, z = v, y = world). Run once.
##
## WHY (planner): people cross the ring on foot at the T junction j_rg_se_e647_n200 (v -200) and at the v 0 junction
## j_rg_se_e627_s0 (the corner people reach from the waterfront and Glorietta Point's shops); the ring has no apron on
## this side, so no car comes in (no car park). From each corner a BEACH WALK (A200, A0; 3 m paved, lamps) runs east to
## the promenade (n_ec_dune_s). On the hill's south shoulder a spur from A200 climbs to a small SOUTH LOOKOUT (a level
## terrace, benches and two beach chairs facing the sea). North of A200 a PICNIC LAWN with grills; on the low south flat
## by A0 the PLAYGROUND (play structure, slide, swing on a level bark pad, benches for the parents facing it) and a
## second picnic spot: the families coming from the waterfront stop here. The rest is open lawn.
## LAND: 4.1 at the ring; the hill's south flank 9.5 m at v -250 falling to 2.4 m at v -80 and 1.1 - 2.7 m on the south
## flat; the ground follows it (n_ec_site.g); the lookout and the playground on level pads, the field graded to them.
const PASS := 2
const K := preload("res://tools/city/pilot/kit_lib.gd")
const W := preload("res://tools/city/pilot/pieces/wear_lib.gd")
const H := preload("res://tools/city/pilot/pieces/hs_fill_lib.gd")
const S := preload("res://tools/city/pilot/pieces/n_ec_site.gd")

const Z0 := -250.0
const Z1 := 0.0
const A200 := [640.0, -201.5, 932.0, -198.5]      # the beach walk from the v -200 junction corner
const A0 := [640.0, -9.5, 932.0, -6.5]            # the beach walk from the v 0 junction corner
const SPUR := [889.5, -226.0, 892.5, -201.5]      # up to the south lookout
const LOOK := [882.0, -238.0, 900.0, -226.0]      # the south lookout terrace
const PLAY := [728.0, -60.0, 746.0, -49.0]        # the playground's bark pad

const ITEMS := [
	# the south lookout: two benches on its sea edge facing the ocean, two beach chairs at its north corner
	["prop_park_bench", "worn", 898.0, -235.4, 95.0], ["prop_park_bench", "worn", 898.0, -232.0, 95.0],
	["prop_adirondack_wood", "worn", 894.0, -236.6, 80.0], ["prop_adirondack_white", "worn", 891.6, -236.6, 100.0],
	["prop_lamp_victorian", "worn", 882.8, -226.8, 0.0],
	# A200: lamps on its north side every ~40 m
	["prop_lamp_victorian", "worn", 690.0, -202.4, 0.0], ["prop_lamp_victorian", "worn", 730.0, -202.4, 0.0],
	["prop_lamp_victorian", "worn", 770.0, -202.4, 0.0], ["prop_lamp_victorian", "worn", 810.0, -202.4, 0.0],
	["prop_lamp_victorian", "worn", 850.0, -202.4, 0.0], ["prop_lamp_victorian", "worn", 920.0, -202.4, 0.0],
	# A0: lamps on its north side
	["prop_lamp_victorian", "worn", 680.0, -10.4, 0.0], ["prop_lamp_victorian", "worn", 720.0, -10.4, 0.0],
	["prop_lamp_victorian", "worn", 760.0, -10.4, 0.0], ["prop_lamp_victorian", "worn", 800.0, -10.4, 0.0],
	["prop_lamp_victorian", "worn", 840.0, -10.4, 0.0], ["prop_lamp_victorian", "worn", 880.0, -10.4, 0.0],
	["prop_lamp_victorian", "worn", 920.0, -10.4, 0.0],
	# the walks' starts by the junction corners: the beach rules facing the people coming in
	["prop_beach_sign_rules", "worn", 672.0, -196.8, -90.0], ["prop_beach_sign_rules", "worn", 660.0, -4.8, -90.0],
	# the picnic lawn north of A200 (the hill's lee): tables with a kettle grill each
	["prop_picnic_table", "worn", 770.0, -226.0, 0.0], ["prop_bbq_kettle", "worn", 773.2, -226.0, 0.0],
	["prop_picnic_table", "worn", 786.0, -218.0, 90.0], ["prop_bbq_kettle", "worn", 786.0, -221.4, 0.0],
	["prop_picnic_table", "worn", 800.0, -232.0, 0.0], ["prop_bbq_kettle", "worn", 803.2, -232.0, 0.0],
	["prop_shade_sail", "worn", 786.0, -218.0, 90.0],
	["prop_drinking_fountain", "worn", 780.0, -204.2, 0.0],
	# the playground on its bark pad: the play structure in the middle, the slide and the swing beside it
	["prop_play_structure", "worn", 737.0, -55.0, 0.0], ["prop_slide", "worn", 741.4, -55.0, 0.0],
	["prop_swing_set", "worn", 732.4, -55.0, 90.0],
	# the parents' benches on the grass south of the pad, facing it (north)
	["prop_park_bench", "worn", 729.0, -46.6, 180.0], ["prop_park_bench", "worn", 732.6, -46.6, 180.0],
	["prop_drinking_fountain", "worn", 748.4, -46.0, 0.0],
	# the south flat's picnic spot by A0, for the families from the waterfront
	["prop_picnic_table", "worn", 772.0, -30.0, 0.0], ["prop_bbq_kettle", "worn", 775.2, -30.0, 0.0],
	["prop_picnic_table", "worn", 790.0, -24.0, 0.0], ["prop_bbq_kettle", "worn", 793.2, -24.0, 0.0],
	# the hill's east brow above the dunes: two benches facing the beach
	["prop_park_bench", "worn", 924.0, -150.0, 100.0], ["prop_park_bench", "worn", 924.0, -146.5, 100.0],
	# lawn sprinklers (no collision)
	["prop_sprinkler_impact", "normal", 720.0, -150.0, 0.0, false], ["prop_sprinkler_impact", "normal", 820.0, -120.0, 0.0, false],
	["prop_sprinkler_impact", "normal", 860.0, -60.0, 0.0, false], ["prop_sprinkler_impact", "normal", 700.0, -100.0, 0.0, false],
	["prop_sprinkler_impact", "normal", 840.0, -170.0, 0.0, false], ["prop_sprinkler_popup", "normal", 760.0, -80.0, 0.0, false],
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
	var root := Node3D.new(); root.name = "n_ec_hill_s"
	var bl := Node3D.new(); bl.name = "Buildings"; root.add_child(bl)
	var g := K.Ground.new(); var props := K.Props.new(); var dec := K.Decals.new()
	var yb := func(x: float, z: float) -> float: return S.g(x, z)
	var ly := S.pad_top(LOOK[0], LOOK[1], LOOK[2], LOOK[3], yb)
	var py := S.pad_top(PLAY[0], PLAY[1], PLAY[2], PLAY[3], yb)
	var yf := H.graded(yb, [[LOOK[0], LOOK[1], LOOK[2], LOOK[3], ly], [PLAY[0], PLAY[1], PLAY[2], PLAY[3], py]])
	var paints: Array = [
		[LOOK[0], LOOK[1], LOOK[2], LOOK[3], "-"],
		[PLAY[0], PLAY[1], PLAY[2], PLAY[3], "-"],
		[A200[0], A200[1], A200[2], A200[3], "plaza"],
		[A0[0], A0[1], A0[2], A0[3], "plaza"],
		[SPUR[0], SPUR[1], SPUR[2], SPUR[3], "plaza"],
		[736.0, -49.0, 738.0, -9.5, "plaza"],         # the playground's walk from A0
	]
	S.rows(g, Z0, Z1, [func(z: float) -> float: return S.ring_u(z), S.U_W], ["grass"], paints, yf)
	H.level_pad(g, "plaza", LOOK[0], LOOK[1], LOOK[2], LOOK[3], ly, yf)
	H.level_pad(g, "mulch", PLAY[0], PLAY[1], PLAY[2], PLAY[3], py, yf)
	# the open south edge (open land goes on south of v 0): a face under it
	H.skirt(g, Vector2(S.ring_u(Z1), Z1), Vector2(S.U_W, Z1), yf, "grass")
	if PASS >= 2: H.polish(props, g, ITEMS)
	if PASS >= 2: H.sc_apply(root, props, dec, SC)
	print("n_ec_hill_s lookout pad %.2f, playground pad %.2f" % [ly, py])
	H.finish(root, g, props, dec, "n_ec_hill_s")
	quit()
