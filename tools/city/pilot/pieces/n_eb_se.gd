extends SceneTree
## Piece n_eb_se (eb fill, the east shore beyond the ring, south-east): SOUTH BEACH and BAYSHORE PADDLE HIRE.
## u 960 .. the sea, v -650 .. -500; the sand runs on under the water to n_eb_site.SEA_LIM. Placed at grid [0, 0, 0],
## yaw 0 (x = u, z = v, y = world height). Run once; never when locked.
##
## WHY (planner): the widest beach of the shore (sand from u ~1125 - 1185 to the water at ~1395, very flat) at the end of
## the GLORIETTA WALK from the ring's -600 junction (n_eb_sw): the walk reaches the promenade at the SOUTH ACCESS
## (landing, shower, rules sign, bike racks along the walk, bins against the dune fence). Beside it BAYSHORE PADDLE
## HIRE (com_surf_shop): kayaks and boards on racks in its forecourt to the promenade, its service side (bins, the
## condenser) to the lawn. On the sand three VOLLEYBALL courts, the fourth LIFEGUARD TOWER facing the water with its
## life ring, umbrellas and loungers spread over the wide beach. On the lawn: picnic tables with grills, benches in
## pairs facing the sea, lamps along the walk and the promenade, ice plant and agaves on the dune edge.
## LAND: the ground follows it (n_eb_site.g; the 5 cm eased to 0 over the last 10 m to the water, the land itself under
## it). The hire shop on a level pad at the highest ground under it, the lawn graded up to it at 6 %.
const S := preload("res://tools/city/pilot/pieces/n_eb_site.gd")

const RECT := [960.0, -650.0, 1600.0, -500.0]
const B := [
	["hire", "commercial/com_surf_shop", 1138.0, -630.0, 90.0],      # BAYSHORE PADDLE HIRE: door and forecourt to the sea (east)
]
const TERR := []
const PAVE := [
	[960.0, -607.5, 1158.5, -604.5, "plaza"],       # the GLORIETTA WALK (from n_eb_sw) east to the promenade
	[1145.3, -638.0, 1165.5, -622.0, "plaza"],      # the hire shop's forecourt (racks), out to the promenade
	[1156.0, -609.0, 1172.0, -603.0, "plaza"],      # SOUTH ACCESS landing: from the promenade over the dune line onto the sand
]
const FENCES := [
	# dune fences along the dune line either side of the access landing (the bins stand against the south one)
	["fence_weathered_board", "fence_post_privacy", 1169.0, -612.0, 1172.7, -626.0, "worn"],
	["fence_weathered_board", "fence_post_privacy", 1165.5, -600.0, 1160.5, -586.0, "worn"],
]
const ITEMS := [
	# ---- the PADDLE HIRE: surfboard racks and two kayak racks in its forecourt (clear of the door at v -626.7), its
	#      service side behind (bins against the back wall, the condenser)
	["prop_surfboard_rack", "clean", 1148.0, -636.0, 90.0], ["prop_surfboard_rack", "clean", 1149.4, -636.0, 90.0],
	["prop_surfboard_rack", "clean", 1150.8, -636.0, 90.0],
	["prop_kayak_rack", "clean", 1157.0, -634.4, 90.0], ["prop_kayak_rack", "clean", 1157.0, -624.2, 90.0],
	["prop_trash_cart_green", "worn", 1130.0, -632.0, 90.0], ["prop_trash_cart_blue", "worn", 1130.0, -630.6, 90.0],
	["prop_ac_condenser", "worn", 1130.2, -627.6, -90.0],
	# ---- SOUTH ACCESS: shower over the dune line, the rules sign, bike racks along the walk (north of it), bins against
	#      the south dune fence, the access lamp
	["prop_beach_shower", "clean", 1174.0, -606.0, 0.0],
	["prop_beach_sign_rules", "worn", 1171.4, -610.0, -90.0],
	["prop_bike_rack", "worn", 1140.0, -609.6, 0.0], ["prop_bike_rack", "worn", 1146.0, -609.6, 0.0],
	["prop_trash_receptacle", "worn", 1164.0, -597.4, 90.0], ["prop_recycling_receptacle", "worn", 1163.6, -596.2, 90.0],
	# ---- three VOLLEYBALL courts on the open sand (nets parallel to the shore)
	["prop_volleyball_net", "clean", 1250.0, -638.0, -79.0],
	["prop_volleyball_net", "clean", 1254.0, -617.0, -79.0],
	["prop_volleyball_net", "clean", 1270.0, -560.0, -79.0],
	# ---- the FOURTH LIFEGUARD TOWER facing the water, its life ring and the rip-current sign
	["prop_lifeguard_tower", "worn", 1365.0, -575.0, 101.0],
	["prop_lifering_stand", "clean", 1358.0, -567.0, 101.0],
	["prop_beach_sign_rip", "worn", 1356.0, -585.0, 101.0],
	# ---- umbrellas (a few furled) and loungers over the wide beach
	["prop_beach_umbrella", "clean", 1215.0, -570.0, 0.0], ["prop_beach_umbrella", "clean", 1230.0, -590.0, 45.0],
	["prop_beach_umbrella", "clean", 1300.0, -640.0, 90.0], ["prop_beach_umbrella_closed", "clean", 1312.0, -628.0, 0.0],
	["prop_beach_umbrella", "clean", 1320.0, -645.0, 130.0], ["prop_beach_umbrella", "clean", 1335.0, -620.0, 20.0],
	["prop_lounge_chair", "clean", 1333.4, -617.4, 101.0], ["prop_lounge_chair", "clean", 1335.2, -617.0, 101.0],
	["prop_beach_umbrella", "clean", 1290.0, -600.0, 60.0], ["prop_beach_umbrella", "clean", 1305.0, -590.0, 100.0],
	["prop_beach_umbrella", "clean", 1322.0, -602.0, 150.0], ["prop_beach_umbrella_closed", "clean", 1340.0, -592.0, 0.0],
	["prop_beach_umbrella", "clean", 1300.0, -560.0, 10.0], ["prop_beach_umbrella", "clean", 1318.0, -548.0, 70.0],
	["prop_lounge_chair", "clean", 1316.4, -545.4, 101.0], ["prop_lounge_chair", "clean", 1318.2, -545.0, 101.0],
	["prop_beach_umbrella", "clean", 1335.0, -560.0, 110.0], ["prop_beach_umbrella", "clean", 1350.0, -540.0, 40.0],
	["prop_beach_umbrella", "clean", 1290.0, -530.0, 80.0], ["prop_beach_umbrella_closed", "clean", 1310.0, -520.0, 0.0],
	["prop_beach_umbrella", "clean", 1332.0, -516.0, 140.0],
	# ---- the lawn: picnic tables with their grills, benches in pairs facing the sea, lamps (the walk's south side,
	#      the promenade's land side)
	["prop_picnic_table", "worn", 1040.0, -620.0, 0.0], ["prop_bbq_kettle", "worn", 1043.2, -620.0, 0.0],
	["prop_picnic_table", "worn", 1060.0, -560.0, 90.0], ["prop_bbq_kettle", "worn", 1060.0, -556.6, 0.0],
	["prop_picnic_table", "worn", 1090.0, -530.0, 0.0], ["prop_bbq_gas_cart", "worn", 1090.0, -526.0, 0.0],
	["prop_park_bench", "worn", 1120.0, -560.0, 90.0], ["prop_park_bench", "worn", 1120.6, -556.6, 90.0],
	["prop_park_bench", "worn", 1149.4, -594.0, 90.0], ["prop_park_bench", "worn", 1148.8, -590.6, 90.0],
	["prop_lamp_victorian", "worn", 1000.0, -602.8, 0.0], ["prop_lamp_victorian", "worn", 1050.0, -602.8, 0.0],
	["prop_lamp_victorian", "worn", 1100.0, -602.8, 0.0],
	["prop_lamp_victorian", "worn", 1168.5, -640.0, 0.0], ["prop_lamp_victorian", "worn", 1148.2, -580.0, 0.0],
	["prop_lamp_victorian", "worn", 1133.9, -540.0, 0.0], ["prop_lamp_victorian", "worn", 1119.5, -510.0, 0.0],
	["prop_sprinkler_impact", "normal", 1020.0, -580.0, 0.0, false], ["prop_sprinkler_impact", "normal", 1080.0, -640.0, 0.0, false],
	# ---- dune edge: ice plant (ground cover, no collider) and agaves
	["plant_iceplant_patch", "normal", 1181.0, -645.0, 0.0, false], ["plant_iceplant_patch", "normal", 1160.0, -580.0, 50.0, false],
	["plant_iceplant_patch", "normal", 1150.0, -560.0, 20.0, false], ["plant_iceplant_patch", "normal", 1140.0, -530.0, 70.0, false],
	["plant_agave_americana", "normal", 1153.0, -548.0, 0.0],
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
	["Buildings/hire", [2.036573886871338, 1.4999818801879883, 6.879859924316406, 0.16, 2.9999637603759766, 0.16]],
 ],
}

func _init() -> void: _run.call_deferred()
func _run() -> void:
	S.run_piece("n_eb_se", RECT, "", B, TERR, PAVE, FENCES, ITEMS, SC)
	quit()
