extends SceneTree
## Piece n_eb_ne (eb fill, the east shore beyond the ring, north-east): BRIDGE BEACH (north of the bridge approach)
## and THE BLUFF (south of it). u 960 (and, north-east of the bridge, from the off-ramp's edge) .. the sea, v -1100 ..
## -800; the sand runs on under the water to n_eb_site.SEA_LIM. Placed at grid [0, 0, 0], yaw 0 (x = u, z = v,
## y = world height). Run once; never when locked.
##
## WHY (planner): the bridge approach (s_br_appr_3 .. 6) cuts this stretch in two.
##  BRIDGE BEACH, between the off-ramp, the approach and the sea: reached along the PROMENADE from the north (ea's
##  stretch) and from the bluff round the approach's end. The land falls from 5.5 at the ramp to the water; grass above
##  2.5 m, sand below (n_eb_site.DUNE). People: families on the sand, dog walkers (a DOG BEACH at its north end, between
##  two dune fences, with its signs and bag bins), cyclists on the promenade. A SNACK SHACK (com_kiosk, a walk-up
##  counter: "Bridge Beach Snack Shack") on the grass by the promenade, its tables beside it; a beach access with a
##  shower; the north LIFEGUARD TOWER facing the water, a life ring and the rip sign by it; umbrellas where people sit;
##  a volleyball net; picnic tables with grills on the grass toward the ramp; benches facing the sea; lamps on the
##  promenade.
##  THE BLUFF south of the approach: the high ground (6.0 - 6.9) over a narrow beach. The MEADOW WALK from the ring
##  (n_eb_nw) reaches the promenade here; a path climbs to the BLUFF OVERLOOK (a level paved terrace with a rail,
##  benches facing the sea); a beach access (shower, racks, bins against its dune fence); the second LIFEGUARD TOWER;
##  umbrellas on the narrow beach. Under the approach's end (u > 1180, v -930 .. -885), where a deck would go on, only
##  the promenade passes: no props.
## LAND: the ground follows it (n_eb_site.g: 5 cm over it, eased onto the bridge's edges within 12 m, the 5 cm eased to 0
## over the last 10 m to the water, the land itself under the water, so the sea meets the sand where the foam lies).
## The kiosk stands on a level pad at the highest ground under it, the overlook level, both graded round at 6 %.
const S := preload("res://tools/city/pilot/pieces/n_eb_site.gd")

const RECT := [900.0, -1100.0, 1600.0, -800.0]
const B := [
	["kiosk", "commercial/com_kiosk", 1050.0, -1032.0, 90.0],    # BRIDGE BEACH SNACK SHACK: its counter window faces the promenade (east)
]
const TERR := [
	[1150.0, -882.0, 1172.0, -866.0],                             # BLUFF OVERLOOK: level paved terrace on the high ground
]
const PAVE := [
	[1053.3, -1036.5, 1063.0, -1027.5, "plaza"],    # the snack shack's forecourt, out to the promenade
	[1052.0, -1049.0, 1062.0, -1043.0, "plaza"],    # NORTH ACCESS landing: from the promenade over the dune line onto the sand
	[960.0, -807.5, 1214.5, -804.5, "plaza"],       # the MEADOW WALK (from n_eb_nw) east to the promenade
	[1158.5, -866.0, 1161.5, -807.5, "plaza"],      # the path up to the Bluff Overlook
	[1219.0, -829.0, 1233.0, -823.0, "plaza"],      # BLUFF ACCESS landing: from the promenade over the dune line
]
const FENCES := [
	# the DOG BEACH (v -1094 .. -1068): a dune fence each side, from the dune line down the sand, stopping short of the water
	["fence_weathered_board", "fence_post_privacy", 1021.0, -1094.0, 1066.0, -1094.0, "worn"],
	["fence_weathered_board", "fence_post_privacy", 1037.0, -1068.0, 1086.0, -1068.0, "worn"],
	# the bluff access: dune fences along the dune line north and south of its landing (the bins stand against the north one)
	["fence_weathered_board", "fence_post_privacy", 1230.0, -831.0, 1231.0, -845.0, "worn"],
	["fence_weathered_board", "fence_post_privacy", 1229.5, -821.0, 1227.0, -810.0, "worn"],
	# the overlook's rail on its sea edge
	["fence_vinyl_canal_rail", "fence_post_vinyl", 1171.6, -881.6, 1171.6, -866.4, "worn"],
]
const ITEMS := [
	# ================= BRIDGE BEACH
	# ---- the DOG BEACH: its signs at the top of each fence (facing the promenade), a bag bin against each fence
	["prop_beach_sign_dog", "worn", 1022.6, -1093.4, -135.0], ["prop_beach_sign_dog", "worn", 1038.6, -1068.6, -135.0],
	["prop_trash_receptacle", "worn", 1030.0, -1093.2, 0.0], ["prop_trash_receptacle", "worn", 1046.0, -1068.8, 0.0],
	# ---- the SNACK SHACK: bins against its north wall, its tables on the grass beside it (one under a sail)
	["prop_trash_receptacle", "worn", 1050.2, -1035.0, 0.0], ["prop_recycling_receptacle", "worn", 1051.4, -1035.0, 0.0],
	["prop_picnic_table", "worn", 1038.0, -1040.0, 0.0], ["prop_shade_sail", "worn", 1038.0, -1040.0, 0.0],
	["prop_picnic_table", "worn", 1046.0, -1022.0, 90.0],
	# ---- NORTH ACCESS: the shower just over the dune line, the beach rules where the landing meets the sand, a bike
	#      rack beside the promenade (along it)
	["prop_beach_shower", "clean", 1064.6, -1046.0, 0.0],
	["prop_beach_sign_rules", "worn", 1061.4, -1049.6, -135.0],
	["prop_bike_rack", "worn", 1034.0, -1050.0, 36.0],
	# ---- the NORTH LIFEGUARD TOWER facing the water (north-east), its life ring and the rip-current sign
	["prop_lifeguard_tower", "worn", 1104.0, -1046.0, 135.0],
	["prop_lifering_stand", "clean", 1098.0, -1051.0, 135.0],
	["prop_beach_sign_rip", "worn", 1094.0, -1056.0, 135.0],
	# ---- umbrellas where families sit (open; a few furled), between the dog beach and the approach
	["prop_beach_umbrella", "clean", 1058.0, -1060.0, 0.0], ["prop_beach_umbrella", "clean", 1068.0, -1054.0, 40.0],
	["prop_beach_umbrella_closed", "clean", 1078.0, -1060.0, 0.0], ["prop_beach_umbrella", "clean", 1084.0, -1040.0, 80.0],
	["prop_beach_umbrella", "clean", 1094.0, -1030.0, 120.0], ["prop_beach_umbrella", "clean", 1088.0, -1022.0, 10.0],
	["prop_beach_umbrella_closed", "clean", 1106.0, -1024.0, 0.0], ["prop_beach_umbrella", "clean", 1150.0, -996.0, 60.0],
	["prop_beach_umbrella", "clean", 1160.0, -988.0, 100.0], ["prop_beach_umbrella_closed", "clean", 1150.0, -982.0, 0.0],
	# ---- the VOLLEYBALL net on the open sand south of the tower (parallel to the shore, the court running to the water)
	["prop_volleyball_net", "clean", 1128.0, -1010.0, 135.0],
	# ---- the grass toward the ramp: picnic tables with their grills, a pair of benches facing the sea by the
	#      promenade, lamps along the promenade (its land side)
	["prop_picnic_table", "worn", 975.0, -1080.0, 0.0], ["prop_bbq_kettle", "worn", 978.2, -1080.0, 0.0],
	["prop_picnic_table", "worn", 990.0, -1066.0, 30.0], ["prop_bbq_kettle", "worn", 993.0, -1063.6, 0.0],
	["prop_park_bench", "worn", 1020.0, -1062.0, 135.0], ["prop_park_bench", "worn", 1022.4, -1059.6, 135.0],
	["prop_lamp_victorian", "worn", 1011.5, -1090.0, 0.0], ["prop_lamp_victorian", "worn", 1030.1, -1060.0, 0.0],
	["prop_lamp_victorian", "worn", 1074.3, -1020.0, 0.0], ["prop_lamp_victorian", "worn", 1105.4, -1000.0, 0.0],
	["prop_lamp_victorian", "worn", 1147.7, -975.0, 0.0], ["prop_lamp_victorian", "worn", 1182.8, -950.0, 0.0],
	# ---- dune edge: ice plant holding the sand just over the grass's edge (ground cover, walked over: no collider), agaves
	["plant_iceplant_patch", "normal", 1028.0, -1086.0, 0.0, false], ["plant_iceplant_patch", "normal", 1080.0, -1014.0, 30.0, false],
	["plant_iceplant_patch", "normal", 1136.0, -992.0, 60.0, false], ["plant_agave_americana", "normal", 1147.0, -986.0, 0.0],
	# ================= THE BLUFF
	# ---- the BLUFF OVERLOOK: benches facing the sea 3 m short of the rail, bins against the rail, a lamp, a fountain
	["prop_park_bench", "worn", 1168.4, -876.0, 90.0], ["prop_park_bench", "worn", 1168.4, -872.6, 90.0],
	["prop_trash_receptacle", "worn", 1170.9, -868.4, 90.0], ["prop_recycling_receptacle", "worn", 1170.9, -869.6, 90.0],
	["prop_lamp_victorian", "worn", 1151.4, -880.6, 0.0], ["prop_drinking_fountain", "worn", 1152.0, -867.4, 0.0],
	# ---- the bluff's grass: picnic tables with grills, lamps along the Meadow Walk (north side) and the promenade
	["prop_picnic_table", "worn", 1080.0, -850.0, 0.0], ["prop_bbq_kettle", "worn", 1083.2, -850.0, 0.0],
	["prop_picnic_table", "worn", 1095.0, -838.0, 90.0], ["prop_bbq_kettle", "worn", 1095.0, -841.4, 0.0],
	["prop_lamp_victorian", "worn", 1000.0, -808.6, 0.0], ["prop_lamp_victorian", "worn", 1050.0, -808.6, 0.0],
	["prop_lamp_victorian", "worn", 1100.0, -808.6, 0.0], ["prop_lamp_victorian", "worn", 1195.0, -808.6, 0.0],
	["prop_lamp_victorian", "worn", 1215.9, -880.0, 0.0], ["prop_lamp_victorian", "worn", 1218.7, -850.0, 0.0],
	# ---- BLUFF ACCESS: shower over the dune line, the rules sign, a bike rack along the promenade, bins against the
	#      north dune fence
	["prop_beach_shower", "clean", 1235.4, -826.0, 0.0],
	["prop_beach_sign_rules", "worn", 1232.4, -829.6, -90.0],
	["prop_bike_rack", "worn", 1215.2, -834.0, 90.0],
	["prop_trash_receptacle", "worn", 1229.6, -835.0, 90.0], ["prop_recycling_receptacle", "worn", 1229.7, -836.2, 90.0],
	# ---- the SECOND LIFEGUARD TOWER and its life ring, facing the water
	["prop_lifeguard_tower", "worn", 1262.0, -852.0, 105.0],
	["prop_lifering_stand", "clean", 1256.0, -845.0, 105.0],
	# ---- umbrellas on the narrow beach under the bluff
	["prop_beach_umbrella", "clean", 1242.0, -878.0, 20.0], ["prop_beach_umbrella", "clean", 1246.0, -862.0, 70.0],
	["prop_beach_umbrella_closed", "clean", 1256.0, -868.0, 0.0], ["prop_beach_umbrella", "clean", 1248.0, -836.0, 110.0],
	["prop_beach_umbrella", "clean", 1264.0, -830.0, 150.0], ["prop_beach_umbrella", "clean", 1252.0, -814.0, 30.0],
	["prop_beach_umbrella", "clean", 1268.0, -818.0, 90.0], ["prop_beach_umbrella_closed", "clean", 1284.0, -808.0, 0.0],
	# ---- dune edge planting on the bluff
	["plant_iceplant_patch", "normal", 1226.0, -880.0, 0.0, false], ["plant_iceplant_patch", "normal", 1228.0, -852.0, 45.0, false],
	["plant_agave_americana_small", "normal", 1226.4, -862.0, 0.0],
]
## SUPERCHECKER (20 Nov, Yasin via the coordinator: "be MUCH more prone to delete ... any prop or road/ground mark
## with any finding or any doubt is deleted with its reason"): tools/city/super/sc.py check on this piece (area layout
## OUT/fill/eb/area.json); every finding on an item is a deletion here with the checker's reason; a collision box on
## each building column the checker measured. Applied after everything is placed (hs_fill_lib.sc_apply).
const SC := {
 "out": [
	["prop_trash_receptacle", 1050.200, -1035.000, "opening: prop_trash_receptacle stands in front of a shop window of kiosk"],
	["prop_recycling_receptacle", 1051.400, -1035.000, "opening: prop_recycling_receptacle stands in front of a shop window of kiosk"],
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
	S.run_piece("n_eb_ne", RECT, "ncut_or_east", B, TERR, PAVE, FENCES, ITEMS, SC)
	quit()
