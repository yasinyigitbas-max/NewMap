extends SceneTree
## Piece n_sc_west (sc fill: the empty scraps inside the ring, 20 Nov; Yasin: "just fill the tiny spaces empty in the ring
## road", "fill them meaningfully without touching anything that already exists"). Placed at grid [0, 0, 0], yaw 0
## (x = u, y = world height, z = v). Run once.
## RIDGE CORNER GARDEN (R2): the wedge between the ring road's inner walk (west, bending) and the Ridge Garden Nursery's
## fence (east, u -938), from where the ring touches the nursery (v -1150, 0 m wide) to the -1000 street's north walk
## (v -1009.2, 38 m wide). Edges and heights measured on the current city (n_sc_site.gd R2).
## WHY (planner): people walk the ring's inner walk and the -1000 street past the nursery; this corner is too narrow
## for a building and has no car access. So a small public garden at the corner, the nursery's neighbour: a lawn, a path
## in from the -1000 street's walk to a seating court (two benches facing each other, a picnic table by the street for
## the nursery's customers and passers-by), bougainvillea and agaves along the nursery fence (a planted screen), a bin
## and a lamp at the entrance, sprinklers. The narrow north tip is just lawn and agaves.
## LAND: falls from 4.1 at the street to 2.2 at the tip; the ground follows it, meeting each edge at its exact height.
const K := preload("res://tools/city/pilot/kit_lib.gd")
const H := preload("res://tools/city/pilot/pieces/hs_fill_lib.gd")
const S := preload("res://tools/city/pilot/pieces/n_sc_site.gd")

## SUPERCHECKER deletions (sc.py check, 20 Nov; Yasin: "be much more prone to delete a prop"): every item with a finding is out, with the reason
const SC := {"out": [
	["prop_trash_receptacle", -947.0, -1055.2, "superchecker bin_open: prop_trash_receptacle stands in the open (118.8 m from a wall, 10.5 m from a fence)"],
	["prop_trash_receptacle", -944.8, -1011.6, "superchecker bin_open: prop_trash_receptacle stands in the open (161.2 m from a wall, 8.6 m from a fence)"],
	["prop_park_bench", -951.8, -1052.0, "superchecker no_reason: prop_park_bench stands alone: no door within 18 m, no wall within 8 m, nothing to sit with"],
	["prop_park_bench", -942.2, -1052.0, "superchecker no_reason: prop_park_bench stands alone: no door within 18 m, no wall within 8 m, nothing to sit with"],
	["prop_picnic_table", -942.0, -1022.0, "superchecker no_reason: prop_picnic_table stands alone: no door within 18 m, no wall within 8 m, nothing to sit with"]
]}

func _init() -> void: _run.call_deferred()

func _run() -> void:
	var root := Node3D.new(); root.name = "n_sc_west"
	var g := K.Ground.new(); var props := K.Props.new(); var dec := K.Decals.new()
	var yf := func(x: float, z: float) -> float: return S.g("r2", x, z)
	var paints := [
		[-948.0, -1048.0, -946.0, -1009.2, "plaza"],       # the path in from the -1000 street's walk
		[-953.0, -1056.0, -941.0, -1048.0, "plaza"],       # the seating court
	]
	S.paint_rows(g, -1150.0, -1009.2, S.f(S.R2_RING, 1), S.f(S.R2_NURS, 1), paints, "grass", yf)
	var P := func(base: String, cond: String, x: float, z: float, yaw := 0.0, collide := true) -> void: H.put(props, base, cond, x, z, yf, yaw, collide)
	# the seating court: two benches facing each other across it (east-west), a bin between
	P.call("prop_park_bench", "worn", -951.8, -1052.0, 90.0); P.call("prop_park_bench", "worn", -942.2, -1052.0, -90.0)
	P.call("prop_trash_receptacle", "worn", -947.0, -1055.2)
	# the entrance at the -1000 street: a lamp and a bin beside the path, the picnic table on the lawn east of it
	P.call("prop_lamp_globe", "worn", -949.2, -1012.0); P.call("prop_trash_receptacle", "worn", -944.8, -1011.6)
	P.call("prop_picnic_table", "worn", -942.0, -1022.0, 90.0)
	# the planted screen along the nursery fence: bougainvillea mounds where the wedge is wide, agaves at the narrow end
	for z: float in [-1100.0, -1088.0, -1076.0, -1064.0, -1040.0, -1030.0]: P.call("plant_bougainvillea_mound", "normal", -940.0, z)
	for z: float in [-1124.0, -1114.0]: P.call("plant_agave_americana_small", "normal", -939.8, z)
	P.call("plant_bird_of_paradise", "normal", -955.0, -1030.0); P.call("plant_bird_of_paradise", "normal", -960.0, -1018.0)
	P.call("prop_sprinkler_impact", "normal", -955.0, -1040.0, 0.0, false); P.call("prop_sprinkler_impact", "normal", -945.0, -1080.0, 0.0, false)
	H.sc_apply(root, props, dec, SC)
	H.finish(root, g, props, dec, "n_sc_west")
	quit()
