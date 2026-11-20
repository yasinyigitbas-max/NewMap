extends SceneTree
## Piece n_eb_me (eb fill, the east shore beyond the ring, middle): MIDDLE BEACH and the BAYSHORE BEACH CAFE.
## u 960 .. the sea, v -800 .. -650; the sand runs on under the water to n_eb_site.SEA_LIM. Placed at grid [0, 0, 0],
## yaw 0 (x = u, z = v, y = world height). Run once; never when locked.
##
## WHY (planner): the beach widens here (sand from u ~1205 to the water at 1310 - 1370) and the land behind it is a
## broad lawn falling from 4.9 to 2.5. The middle of the beach park is where people stay longest: the BAYSHORE BEACH
## CAFE (com_cafe_seaside) stands on the lawn by the promenade, its door and terrace to the sea (tables under sails),
## its service side (bins, the condenser) to the lawn behind; a beach access north of it (landing, shower, rules sign,
## bins against the dune fence, a bike rack); two VOLLEYBALL courts on the open sand; the third LIFEGUARD TOWER with
## its life ring; umbrellas and loungers where families sit. On the lawn: picnic tables with grills, benches facing the
## sea, lamps along the promenade, ice plant on the dune edge. People come along the promenade from the Meadow Walk
## (n_eb_ne) and the Glorietta Walk (n_eb_se); no car comes in (no apron on the ring's east side).
## LAND: the ground follows it (n_eb_site.g; the 5 cm eased to 0 over the last 10 m to the water, the land itself under
## it). The cafe on a level pad at the highest ground under it, the lawn graded up to it at 6 %.
const S := preload("res://tools/city/pilot/pieces/n_eb_site.gd")

const RECT := [960.0, -800.0, 1600.0, -650.0]
const B := [
	["cafe", "commercial/com_cafe_seaside", 1178.0, -722.0, 90.0],   # BAYSHORE BEACH CAFE: door and terrace to the sea (east)
]
const TERR := []
const PAVE := [
	[1185.3, -731.0, 1196.5, -712.0, "plaza"],      # the cafe's terrace, out to the promenade
	[1201.0, -748.0, 1214.0, -742.0, "plaza"],      # MIDDLE ACCESS landing: from the promenade over the dune line onto the sand
]
const FENCES := [
	# dune fences along the dune line either side of the access landing (the bins stand against the north one)
	["fence_weathered_board", "fence_post_privacy", 1210.6, -750.0, 1214.5, -764.0, "worn"],
	["fence_weathered_board", "fence_post_privacy", 1207.7, -740.0, 1206.9, -733.0, "worn"],
]
const ITEMS := [
	# ---- the CAFE: tables on its terrace (each under a sail), its service side on the lawn behind (bins against the
	#      back wall, the condenser), a bike rack by the promenade
	["prop_patio_set_4", "worn", 1190.0, -727.4, 0.0], ["prop_shade_sail", "worn", 1190.0, -727.4, 0.0],
	["prop_patio_set_4", "worn", 1190.0, -714.6, 0.0], ["prop_shade_sail", "worn", 1190.0, -714.6, 0.0],
	["prop_patio_set_4", "worn", 1194.0, -727.4, 0.0],
	["prop_trash_cart_green", "worn", 1170.0, -724.0, 90.0], ["prop_trash_cart_blue", "worn", 1170.0, -722.6, 90.0],
	["prop_ac_condenser", "worn", 1170.2, -719.4, -90.0],
	["prop_bike_rack", "worn", 1194.6, -737.0, 90.0],
	# ---- MIDDLE ACCESS: shower over the dune line, the rules sign, bins against the north dune fence
	["prop_beach_shower", "clean", 1216.4, -745.0, 0.0],
	["prop_beach_sign_rules", "worn", 1213.0, -749.6, -90.0],
	["prop_trash_receptacle", "worn", 1210.6, -753.2, 90.0], ["prop_recycling_receptacle", "worn", 1210.9, -754.4, 90.0],
	# ---- two VOLLEYBALL courts on the open sand (nets parallel to the shore, courts running to the water)
	["prop_volleyball_net", "clean", 1255.0, -788.0, -67.0],
	["prop_volleyball_net", "clean", 1263.0, -767.0, -67.0],
	# ---- the THIRD LIFEGUARD TOWER facing the water, its life ring
	["prop_lifeguard_tower", "worn", 1325.0, -705.0, 113.0],
	["prop_lifering_stand", "clean", 1318.0, -697.0, 113.0],
	# ---- umbrellas (a few furled) and loungers where families sit, from the cafe's beach down toward the water
	["prop_beach_umbrella", "clean", 1235.0, -715.0, 0.0], ["prop_beach_umbrella", "clean", 1240.0, -700.0, 50.0],
	["prop_beach_umbrella", "clean", 1280.0, -740.0, 90.0], ["prop_beach_umbrella", "clean", 1290.0, -750.0, 20.0],
	["prop_beach_umbrella_closed", "clean", 1300.0, -735.0, 0.0], ["prop_beach_umbrella", "clean", 1296.0, -722.0, 140.0],
	["prop_lounge_chair", "clean", 1294.4, -719.4, 113.0], ["prop_lounge_chair", "clean", 1296.2, -718.8, 113.0],
	["prop_beach_umbrella", "clean", 1308.0, -716.0, 60.0], ["prop_beach_umbrella", "clean", 1284.0, -708.0, 30.0],
	["prop_beach_umbrella", "clean", 1300.0, -690.0, 110.0], ["prop_beach_umbrella", "clean", 1315.0, -680.0, 0.0],
	["prop_lounge_chair", "clean", 1313.2, -677.4, 113.0], ["prop_lounge_chair", "clean", 1315.0, -676.8, 113.0],
	["prop_beach_umbrella", "clean", 1290.0, -672.0, 70.0], ["prop_beach_umbrella_closed", "clean", 1325.0, -668.0, 0.0],
	["prop_beach_umbrella", "clean", 1270.0, -690.0, 160.0],
	# ---- the lawn: picnic tables with their grills, benches in pairs facing the sea, lamps along the promenade (land side)
	["prop_picnic_table", "worn", 1090.0, -760.0, 0.0], ["prop_bbq_kettle", "worn", 1093.2, -760.0, 0.0],
	["prop_picnic_table", "worn", 1105.0, -748.0, 90.0], ["prop_bbq_kettle", "worn", 1105.0, -744.6, 0.0],
	["prop_picnic_table", "worn", 1040.0, -700.0, 0.0], ["prop_bbq_gas_cart", "worn", 1040.0, -696.0, 0.0],
	["prop_park_bench", "worn", 1190.6, -772.0, 90.0], ["prop_park_bench", "worn", 1191.0, -768.6, 90.0],
	["prop_park_bench", "worn", 1178.6, -692.0, 90.0], ["prop_park_bench", "worn", 1179.4, -688.6, 90.0],
	["prop_lamp_victorian", "worn", 1209.1, -790.0, 0.0], ["prop_lamp_victorian", "worn", 1202.3, -760.0, 0.0],
	["prop_lamp_victorian", "worn", 1189.5, -700.0, 0.0], ["prop_lamp_victorian", "worn", 1179.9, -670.0, 0.0],
	["prop_sprinkler_impact", "normal", 1080.0, -720.0, 0.0, false], ["prop_sprinkler_impact", "normal", 1140.0, -680.0, 0.0, false],
	# ---- dune edge: ice plant (ground cover, no collider) and agaves
	["plant_iceplant_patch", "normal", 1217.0, -792.0, 0.0, false], ["plant_iceplant_patch", "normal", 1219.5, -777.0, 40.0, false],
	["plant_iceplant_patch", "normal", 1199.0, -690.0, 80.0, false], ["plant_iceplant_patch", "normal", 1190.0, -666.0, 10.0, false],
	["plant_agave_americana", "normal", 1203.0, -705.0, 0.0],
]
## SUPERCHECKER (20 Nov, Yasin via the coordinator: "be MUCH more prone to delete ... any prop or road/ground mark
## with any finding or any doubt is deleted with its reason"): tools/city/super/sc.py check on this piece (area layout
## OUT/fill/eb/area.json); every finding on an item is a deletion here with the checker's reason; a collision box on
## each building column the checker measured. Applied after everything is placed (hs_fill_lib.sc_apply).
const SC := {
 "out": [

 ],
 "turn": [
 ],
 "decals": [

 ],
 "boxes": [
	["Buildings/cafe", [1.0249133110046387, 1.4999818801879883, 6.8799638748168945, 0.16, 2.9999637603759766, 0.16]],
 ],
}

func _init() -> void: _run.call_deferred()
func _run() -> void:
	S.run_piece("n_eb_me", RECT, "", B, TERR, PAVE, FENCES, ITEMS, SC)
	quit()
