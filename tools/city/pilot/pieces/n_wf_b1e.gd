extends SceneTree
## Piece n_wf_b1e (waterfront fill, block 1 EAST: grid u 404 to the ring's corner at u 560.8, with Beach Lane - the
## strip u 470-560.8, v 300-322 between the sample's beach parking (f_nw, locked) and the ring).
## WHO COMES HERE AND WHY: the bottom of Pier St, 50 m from the pier plaza: the Fish House (the seafood place, with a
## deck to eat on), a bait & tackle shop for the people who fish off the pier, the surf shop, and a kayak / SUP hire
## kiosk at the corner by the sample. Behind them the lowest level of the visitor lot, a small playground with picnic
## tables for beach families, the end of the Beach Walk and BEACH LANE: palms, benches, a shower, bike racks and a rental
## stand, the walk the whole block uses to get to the sand (it meets the street corner across from the beach).
## THE GROUND: Pier St falls 2.72 -> 1.50 m, the ring 1.92 -> 1.50, the sample's quadrant f_nw is flat at 1.50. Pads:
##   Fish House with deck 2.25 | bait & tackle 1.67 | surf shop 1.54 | kiosk 1.50
##   lot middle level 3.60 to u 420, ramps on both aisles 3.60 -> 2.30 (8.1 %), lower level 2.30 (a planted wall at its
##   east end, down to the field at 1.5) | holiday flats 2.25 | playground 1.60 | Beach Walk 2.55 -> 1.50
##   cottages 1.85 / 1.68 / 1.55 | Beach Lane: the base field, 1.50 (flat).
## Run: GROUND_ONLY=1 for the ground alone (first check), then without. A draft until Yasin has seen it; never when locked.
const F := preload("res://tools/city/pilot/pieces/wf_fill_lib.gd")

static func ring_v(u: float) -> float: return 330.27 - (u - 259.2) * 0.045497
static func ring_band(u: float) -> float: return ring_v(u) - 2.05

func _init() -> void: _run.call_deferred()
func _run() -> void:
	var b := F.new("n_wf_b1e")
	ground(b)
	if OS.get_environment("GROUND_ONLY") == "1":
		b.finish(true); quit(); return
	life(b)
	polish(b)
	b.finish()
	quit()

func ground(b: F) -> void:
	b.band = 2.0
	# ---- Pier St front
	b.terrace(405.5, 211.2, 441.0, 230.0, 2.25, "wall", 0, "Fish House + deck")
	b.terrace(441.0, 211.2, 453.5, 230.0, 1.67, "wall", 0, "bait & tackle")
	b.terrace(453.5, 211.2, 464.0, 230.0, 1.54, "wall", 0, "surf shop")
	b.terrace(464.0, 211.2, 468.0, 230.0, 1.50, "wall", 0, "kayak hire kiosk")
	# ---- the lot: middle level (from n_wf_b1m) to u 420, lower level beyond
	b.terrace(404.0, 230.0, 420.0, 266.0, 3.60, "wall", 0, "lot middle level")
	b.terrace(420.0, 230.0, 464.0, 266.0, 2.30, "wall", 0, "lot lower level")
	b.terrace(405.5, 266.0, 438.0, 294.0, 2.25, "wall", 0, "holiday flats")
	b.terrace(442.0, 268.0, 466.0, 292.0, 1.60, "wall", 0, "playground + picnic")
	b.terrace(405.5, 298.0, 417.0, ring_band(417.0), 1.85, "wall", 0, "cottage 10")
	b.terrace(417.0, 298.0, 429.0, ring_band(429.0), 1.68, "wall", 0, "cottage 11")
	b.terrace(429.0, 298.0, 441.0, ring_band(441.0), 1.55, "wall", 0, "cottage 12")
	# ---- ramps
	b.ramp(420.0, 235.5, 436.0, 242.5, "u", 3.60, 2.30, true)
	b.ramp(420.0, 253.5, 436.0, 260.5, "u", 3.60, 2.30, true)
	b.ramp(404.0, 294.0, 470.0, 298.0, "u", 2.55, 1.50)                 # the Beach Walk, on into Beach Lane
	# ---- surfaces
	b.paint(404.0, 209.2, 470.0, 211.2, "concrete")
	b.paint(404.0, 266.0, 405.5, 294.0, "grass")
	b.paint(404.0, 211.2, 405.5, 230.0, "mulch")
	b.paint(405.5, 211.2, 470.0, 214.0, "concrete")
	b.paint(431.0, 214.0, 441.0, 228.0, "plaza")                       # Fish House deck
	b.paint(420.0, 230.0, 436.0, 235.5, "mulch"); b.paint(420.0, 242.5, 436.0, 253.5, "mulch")
	b.paint(404.0, 260.5, 466.0, 266.0, "grass")
	b.paint(405.5, 266.0, 442.0, 294.0, "grass")
	b.paint(442.0, 268.0, 466.0, 292.0, "sand")                          # play pad: sand under the play things
	b.paint(404.0, 294.0, 470.0, 298.0, "plaza")
	b.paint(405.5, 298.0, 441.0, 340.0, "grass")
	b.paint(441.0, 298.0, 562.0, 310.5, "plaza")                         # the lane's end and Beach Lane's path (6 m)
	b.paint(538.0, 310.5, 562.0, 340.0, "plaza")                         # the corner where people cross to the beach
	b.paint(441.0, 266.0, 470.0, 298.0, "plaza")                         # round the playground
	b.paint(441.0, 310.5, 538.0, 340.0, "grass")                         # Beach Lane's south verge: palms, ice plant, agave
	b.paint(464.0, 230.0, 470.0, 266.0, "grass")                        # bank below the lot's east wall


const K_DOORS := {"houses/beach_white": -1.4, "houses/beach_blue": -1.4, "houses/beach_teal": 1.4}

## ---------------------------------------------------------------- buildings, then props, each with its reason
func life(b: F) -> void:
	# ================= PIER ST FRONT (fronts at v 214, facing Pier St: yaw 180) =================
	# --- the Fish House (doors u 424.1 and 421.9) with the Poke & Taco counter (door 413.9) in one arcade block, and the
	#     Fish House's deck on the east side, 0.3-0.45 m over the walk, where people eat looking down Pier St to the pier
	var fh := b.bld("commercial/com_spanish_arcade_block", 419.0, 221.0, 180.0, "the_fish_house", 0.8, true, true, true)   # front at v 213, back 1 m inside its pad
	for t2: float in [216.6, 221.0, 225.4]:
		b.add("prop_patio_set_4", "worn", 436.0, t2, 0.0)
	b.add("prop_shade_sail", "worn", 436.0, 221.0, 90.0, false)            # the deck's sail over the middle table
	b.add_at("fence_gate_wrought_iron", "worn", 431.65, 214.1, 2.25, 0.0)   # the deck's gate from the forecourt
	b.fence("iron", 432.2, 214.1, 440.8, 214.1, "worn", 2.25)
	b.fence("iron", 440.8, 214.1, 440.8, 227.9, "worn", 2.25)
	b.fence("iron", 440.8, 227.9, 431.3, 227.9, "worn", 2.25)
	b.add("prop_trash_receptacle", "dirty", 409.3, 213.2, 0.0)
	b.add("prop_newspaper_box_red", "worn", 417.6, 212.6, 180.0)          # between the taco door and the Fish House doors
	b.add("plant_potted_leafy", "normal", 429.6, 213.2, 0.0)
	b.roof(fh, ["prop_vent_box", "prop_vent_box", "prop_ac_condenser"])   # two kitchens
	b.enclosure(412.0, 233.0, 0.0)                                       # the kitchens' bins at the top of the middle level
	# --- Pier Bait & Tackle (door u 444.2): ice for the catch at its back corner, a bench where the old boys sit
	var bt := b.bld("commercial/com_shallow_surf", 447.5, 217.5, 180.0, "pier_bait_tackle", 0.85)
	b.add("prop_ice_chest", "worn", 450.2, 222.6, 0.0)                   # behind the shop, on its pad, off the walk
	b.add("prop_park_bench", "worn", 449.6, 212.5, 180.0)                # facing the street, 5 m east of the door
	b.add("prop_trash_receptacle", "dirty", 452.6, 213.2, 0.0)
	# --- Salt Water Surf (door u 462.55): its boards in a rack along the front, parallel to the shopfront
	var sf := b.bld("commercial/com_surf_shop", 459.25, 221.0, 180.0, "salt_water_surf", 0.75, true, true, true)   # compact AC: a hedge stands 1.6 m behind it
	b.add("prop_kayak_rack", "worn", 457.4, 212.6, 0.0)
	b.add("prop_beach_umbrella_closed", "worn", 454.4, 213.0, 0.0)       # beach umbrellas for sale, furled by the door side
	# --- Bay Paddle (kayak and SUP hire), a walk-up kiosk (front kept clear for the queue), its kayaks behind it
	var ki := b.bld("commercial/com_kiosk", 466.0, 218.0, 180.0, "bay_paddle_hire", 0.8, false)
	b.add("prop_kayak_rack", "worn", 466.0, 223.6, 0.0); b.add("prop_kayak_rack", "worn", 466.0, 226.6, 0.0)
	b.add("prop_lifering_stand", "worn", 467.6, 229.0, 0.0)
	# ================= THE LOT: middle level to u 420, ramps, lower level 2.30 =================
	b.stalls_u(404.4, 5, 242.5, 1.0); b.stalls_u(404.4, 5, 253.5, -1.0)
	b.stalls_u(436.4, 10, 235.5, -1.0); b.stalls_u(436.4, 10, 242.5, 1.0); b.stalls_u(436.4, 10, 253.5, -1.0)
	for bu: float in [421.6, 426.0, 430.4, 434.8]:
		b.add("prop_bollard_steel", "worn", bu, 235.75, 0.0); b.add("prop_bollard_steel", "worn", bu, 242.25, 0.0)
		b.add("prop_bollard_steel", "worn", bu, 253.75, 0.0); b.add("prop_bollard_steel", "worn", bu, 260.25, 0.0)
	b.add("tree_coral_a", "normal", 428.0, 248.0, 0.0); b.add("prop_lot_light_pole", "worn", 423.0, 248.0, 0.0)
	b.add("plant_bougainvillea_mound", "normal", 428.0, 232.6, 0.0)
	# its east end: a railing on the wall (0.7 m down to Beach Lane's bank) and a flight of steps out of aisle 2
	# its low edges (0.6-0.8 m down) are guarded by a privet hedge on the lower side, a gap at the steps
	for k in 11: b.add("hedge_privet_2m", "normal", 464.7, 231.0 + k * 2.05, 90.0)
	for k in 2: b.add("hedge_privet_2m", "normal", 464.7, 261.6 + k * 2.05, 90.0)
	for k in 10: b.add("hedge_privet_2m", "normal", 442.3 + k * 2.1, 229.6, 0.0)
	b.stairs(464.0, 254.0, 467.6, 260.0, "u", 2.30, 1.55)
	b.paint(464.0, 254.0, 467.6, 260.0, "concrete")
	b.add("prop_lot_light_pole", "worn", 462.6, 263.0, 180.0)
	for t3: Array in [["palm_queen_b", 412.0], ["tree_magnolia_a", 434.0], ["palm_mexican_fan_c", 452.0]]:
		b.add(String(t3[0]), "normal", float(t3[1]), 263.6, float(t3[1]) * 3.0)
	b.add("prop_pay_station", "worn", 437.0, 261.2, 180.0)               # for the people who come up the steps from the beach
	b.stall_wear(0.65)
	b.yard_wear(436.0, 230.0, 464.0, 260.5, 0.8); b.yard_wear(404.0, 230.0, 420.0, 260.5, 0.8)
	# ================= HOLIDAY FLATS (pad 2.25) =================
	var f1 := b.bld("apartments/apt_court_white", 414.5, 285.5, 0.0, "pier_court_flats", 0.6)
	var f2 := b.bld("houses/beach_blue", 431.0, 286.0, 0.0, "the_little_blue_rental", 0.6, false, false)
	b.back_of_house(f2[0], f2[1], f2[2], true, true)
	for st: Array in [[413.0, 416.0], [428.1, 431.1]]:
		var uu := (float(st[0]) + float(st[1])) * 0.5
		b.stairs(float(st[0]), 292.0, float(st[1]), 294.0, "v", 2.25, b.y(uu, 295.5))
		b.paint(float(st[0]), 290.0, float(st[1]), 294.0, "concrete")
	for hb: Array in [[406.0, 412.6], [416.4, 427.7], [431.5, 437.5]]:
		var n := int((float(hb[1]) - float(hb[0])) / 2.1)
		for k in n: b.add("hedge_boxwood_low_2m", "normal", float(hb[0]) + 1.05 + k * 2.1, 293.4, 0.0)
	b.add("prop_mailbox_post_metal", "worn", 417.6, 291.4, 0.0)
	b.add("prop_picnic_table", "worn", 410.0, 271.0, 90.0); b.add("prop_bbq_kettle", "worn", 413.5, 269.2, 0.0)
	b.add("prop_beach_shower", "worn", 424.6, 279.0, 0.0); b.add("palm_queen_a", "normal", 431.0, 272.0, 0.0)
	for k in 3: b.add(["prop_trash_cart_black", "prop_trash_cart_blue", "prop_trash_cart_green"][k], "worn", 423.6, 282.0 + k * 0.8, 90.0)
	# ================= THE PLAYGROUND for beach families (sand pad 1.60), a hedge round it, its way in from the Beach Walk
	b.add("prop_play_structure", "worn", 452.0, 279.0, 90.0)
	b.add("prop_swing_set", "worn", 460.5, 274.0, 0.0)
	b.add("prop_slide", "worn", 446.5, 274.5, 0.0)
	for t4: Vector2 in [Vector2(447.0, 287.6), Vector2(459.0, 287.6)]:
		b.add("prop_picnic_table", "worn", t4.x, t4.y, 0.0)
		b.add("prop_shade_sail", "worn", t4.x, t4.y, 0.0, false)        # one sail over each table
	b.add("prop_park_bench", "worn", 444.0, 281.0, 90.0)                 # parents watch the play
	b.add("prop_park_bench", "worn", 464.0, 281.0, -90.0)
	b.add("prop_drinking_fountain", "worn", 453.0, 291.0, 180.0)
	b.add("prop_trash_receptacle", "worn", 450.6, 291.2, 0.0)
	for k in 11: b.add("hedge_privet_2m", "normal", 443.0 + k * 2.1, 268.6, 0.0)          # north side (the lot above)
	for k in 10: b.add("hedge_privet_2m", "normal", 442.6, 270.6 + k * 2.0, 90.0)          # west
	for k in 10: b.add("hedge_privet_2m", "normal", 465.4, 270.6 + k * 2.0, 90.0)          # east
	for k in 3: b.add("hedge_privet_2m", "normal", 443.6 + k * 2.1, 291.6, 0.0)            # south, leaving the entrance
	for k in 3: b.add("hedge_privet_2m", "normal", 458.2 + k * 2.1, 291.6, 0.0)
	# ================= THE BEACH WALK's end and BEACH LANE (to the corner across from the beach) =================
	for lu2: float in [425.0, 452.0]: b.add("prop_lamp_globe", "worn", lu2, 294.45, 0.0)
	for k5 in 7: b.add("prop_pier_lamp", "worn", 478.0 + k5 * 12.0, 300.6, 0.0)      # the promenade's lamps lead the way to the sand
	b.paint(470.0, 300.0, 538.0, 304.4, "grass")                          # the north verge along the sample's lot
	for k6 in 7:
		b.add(["palm_mexican_fan_a", "palm_queen_a", "palm_mexican_fan_b", "palm_canary_date_a", "palm_queen_b", "palm_mexican_fan_c", "palm_queen_a"][k6], "normal", 484.0 + k6 * 12.0, 301.1, k6 * 47.0)
	for bx: float in [490.0, 514.0, 538.0]:
		b.add("prop_park_bench", "worn", bx, 305.0, 0.0)                  # at the path's edge, facing the south verge's palms and the ring
		b.add("prop_trash_receptacle", "dirty", bx + 2.0, 305.0, 0.0)
	b.add("prop_bike_rack", "worn", 475.0, 310.0, 0.0); b.add("prop_bike_rack", "worn", 478.6, 310.0, 0.0)   # leave the bikes before the sand (path edge, parallel)
	b.add("prop_beach_shower", "worn", 552.0, 305.0, 0.0)                # rinse off on the way back from the beach
	b.add("prop_drinking_fountain", "worn", 548.5, 304.0, 0.0)
	b.add("prop_beach_sign_rules", "worn", 556.0, 307.5, -60.0)           # facing people coming in from the corner
	b.add("prop_lifering_stand", "worn", 553.6, 309.0, -60.0)
	# the south verge: palms, ice plant and agave (the beach-front planting), nothing on the path
	for k7 in 6: b.add(["palm_queen_a", "palm_mexican_fan_b", "palm_queen_b", "palm_canary_date_b", "palm_mexican_fan_a", "palm_queen_a"][k7], "normal", 448.0 + k7 * 16.0, 315.0, k7 * 61.0)
	for k8 in 6: b.add(["plant_iceplant_patch", "plant_agave_americana", "plant_iceplant_patch", "plant_bougainvillea_mound", "plant_iceplant_patch", "plant_agave_americana_small"][k8], "normal", 456.0 + k8 * 14.0, 313.2, k8 * 40.0)
	b.sand_drift(520.0, 303.5, 560.0, 321.0, 14)                          # sand carried up off the beach
	b.sand_drift(470.0, 304.0, 520.0, 320.0, 6)
	# ================= COTTAGES ON THE RING =================
	var cot: Array = [["houses/beach_blue", 411.25, 312.5, "cottage_tern", 405.5, 417.0, 1.85],
		["houses/beach_teal", 423.0, 312.5, "cottage_heron", 417.0, 429.0, 1.68],
		["houses/beach_white", 435.0, 311.45, "cottage_plover", 429.0, 441.0, 1.55]]
	for c: Array in cot:
		var hb2 := b.bld(String(c[0]), float(c[1]), float(c[2]), 0.0, String(c[3]), 0.55, false, false)
		b.back_of_house(hb2[0], hb2[1], hb2[2], true, true)
		var ua := float(c[4]); var ub := float(c[5]); var h := float(c[6])
		var vf: float = ring_band(ub) - 0.25
		var door_u: float = float(c[1]) + float(K_DOORS[String(c[0])])
		b.fence("picket", ua + 0.3, vf, door_u - 0.7, vf, "worn", h)
		b.fence("picket", door_u + 0.7, vf, ub - 0.3, vf, "worn", h)
		b.add("fence_gate_picket", "worn", door_u, vf, 0.0)
		b.paint(door_u - 0.6, float(c[2]) + float(hb2[2]) * 0.5, door_u + 0.6, vf, "concrete")
		b.at_bld(hb2, "prop_porch_light_coach", "worn", float(K_DOORS[String(c[0])]) + 0.85, float(hb2[2]) * 0.5 + 0.02, 0.0, 2.0, false)
		b.add("prop_mailbox_post_wood", "worn", door_u + 1.1, vf - 0.35, 0.0)
		b.fence("privacy", ub, 298.4, ub, vf, "worn")
		b.fence("picket", ua + 0.3, 298.4, ub - 0.3, 298.4, "worn", h)
	b.fence("privacy", 405.7, 298.4, 405.7, ring_band(417.0) - 0.25, "worn")
	b.add("prop_beach_shower", "worn", 415.6, 304.0, 0.0); b.add("prop_adirondack_wood", "worn", 409.0, 302.0, 170.0)
	b.add("prop_patio_set_4", "worn", 423.0, 302.5, 0.0)
	b.add("prop_bbq_kettle", "worn", 434.0, 301.5, 0.0); b.add("prop_kayak_rack", "worn", 439.6, 304.0, 90.0)
	b.add("palm_queen_b", "normal", 428.0, 304.5, 0.0)
	b.add("plant_iceplant_patch", "normal", 408.0, 318.4, 0.0); b.add("plant_agave_americana_small", "normal", 427.0, 317.8, 0.0)
	b.building_wear()
	b.sand_drift(441.0, 298.0, 470.0, 318.0, 5)

## ---------------------------------------------------------------- POLISH PASS (Yasin 19 Nov: "run a polish pass in all your
## quarters, both indoors and outdoors ... plenty of props and life"). Every spot below is chosen by hand with its reason;
## try_add() only refuses a spot that turns out taken (counted and printed), it decides nothing.
func polish(b: F) -> void:
	var T := func(base: String, cond: String, pts: Array, yaw := 0.0, surf: Array = []) -> void:
		for p: Vector2 in pts: b.try_add(base, cond, p.x, p.y, yaw, surf)
	# Pier St: plants, a bench for the Fish House's queue, a bin and papers at the bait shop, umbrellas for sale
	T.call("plant_potted_leafy", "normal", [Vector2(406.2, 213.0), Vector2(442.0, 213.0)])
	T.call("prop_park_bench", "worn", [Vector2(411.6, 212.6)], 180.0)                    # waiting for a table, facing the street
	T.call("prop_newspaper_box_blue", "worn", [Vector2(453.0, 212.4)], 180.0)
	T.call("prop_beach_umbrella_closed", "worn", [Vector2(455.6, 213.2), Vector2(463.6, 213.2)])
	# the kitchens' backs: gas bottles, the fish delivery's cart, bins
	T.call("prop_propane_cylinder_100lb", "rusty", [Vector2(426.0, 230.6)])
	T.call("prop_hose_reel_cart", "worn", [Vector2(445.0, 228.0)], 180.0)                # hosing the bait shop's yard
	T.call("prop_ice_chest", "worn", [Vector2(462.6, 229.2)])                             # the surf shop's cold drinks for the board renters
	# the lowest lot: drains and turning arcs
	for d: Vector2 in [Vector2(448.0, 239.0), Vector2(448.0, 257.0), Vector2(410.0, 257.0)]:
		b.add("prop_storm_drain_grate", "dirty", d.x, d.y, 0.0, false, 0.002)
	for c: Vector2 in [Vector2(462.0, 239.0), Vector2(462.0, 257.0)]: b.mark(15, c, 30.0, 3.0, 2.0, Color(1, 1, 1, 0.45))
	T.call("plant_bird_of_paradise", "normal", [Vector2(422.0, 251.4), Vector2(434.0, 233.6)])
	T.call("plant_agave_americana_small", "normal", [Vector2(420.0, 262.6), Vector2(444.0, 262.6), Vector2(460.0, 262.6)])
	# the flats and the little rental: chairs, a barbecue, flowers at the paths
	T.call("prop_adirondack_wood", "worn", [Vector2(418.0, 270.0), Vector2(420.0, 270.0)], 160.0)
	T.call("prop_beach_umbrella_closed", "worn", [Vector2(435.0, 279.6)])
	T.call("plant_bird_of_paradise", "normal", [Vector2(411.6, 291.6), Vector2(417.4, 291.6), Vector2(426.8, 291.6), Vector2(432.2, 291.6)])
	# the playground: a third bench, a bin by the swings, buckets-and-spades sand round the play things
	T.call("prop_park_bench", "worn", [Vector2(454.0, 270.6)], 180.0)
	T.call("prop_trash_receptacle", "worn", [Vector2(463.6, 288.0)])
	b.sand_drift(442.0, 268.0, 466.0, 292.0, 5)
	# Beach Lane: more palms' company - planting on the verges, a second shower by the bikes, bins
	T.call("plant_iceplant_patch", "normal", [Vector2(484.0, 302.6), Vector2(508.0, 302.6), Vector2(532.0, 302.6)])
	T.call("plant_agave_americana_small", "normal", [Vector2(496.0, 302.8), Vector2(520.0, 302.8)])
	T.call("plant_bird_of_paradise", "normal", [Vector2(463.0, 312.4), Vector2(478.0, 313.0), Vector2(506.0, 313.4), Vector2(526.0, 314.4)])
	T.call("prop_beach_shower", "worn", [Vector2(482.6, 309.6)])
	T.call("prop_trash_receptacle", "dirty", [Vector2(546.0, 304.6), Vector2(470.6, 304.6)])
	T.call("prop_kayak_rack", "worn", [Vector2(544.0, 314.8)])                            # the rental stand's boards by the corner
	T.call("prop_beach_umbrella_closed", "worn", [Vector2(540.6, 316.0), Vector2(541.4, 316.6)])
	# the cottages' gardens
	T.call("prop_adirondack_white", "worn", [Vector2(412.0, 302.0), Vector2(437.0, 302.4)], 180.0)
	T.call("prop_hose_reel_cart", "worn", [Vector2(426.0, 307.0)], 90.0)
	T.call("plant_bougainvillea_mound", "normal", [Vector2(416.0, 318.4), Vector2(437.0, 317.4)])
	b.sand_drift(441.0, 294.0, 470.0, 310.0, 6); b.sand_drift(453.5, 211.2, 468.0, 214.0, 3)
	b.polish_report()
