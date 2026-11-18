extends SceneTree
## Pieces s_cc_amber_n / s_cc_amber_s (city centre): Amber Ave legs with the city-centre cross-section - no parking lane,
## kerb on the lane edge, 6.9 m sidewalks in front of the tall blocks (Yasin 16 Nov: "widen the sidewalks in the city
## center"). Parking is in garages here. A wide sidewalk gets a real furniture zone along the kerb: street trees in
## wells every 12 m, lamps between them, benches facing the shops, bike racks, newspaper boxes at the corners, a mail
## box; the bus stops in the kerb lane (a far-side stop on the north leg). Street furniture only (reuse rule).
## Builds both legs. Run once; never when locked.
const Seg := preload("res://tools/city/pilot/pieces/amber_seg.gd")
const K := preload("res://tools/city/pilot/kit_lib.gd")
const S := preload("res://tools/city/pilot/site.gd")
func _init() -> void: _run.call_deferred()
func _run() -> void:
	S.hill_on = false
	S.A_KERB = S.A_LANE; S.T_KERB = S.T_LANE
	for leg: Array in [["s_cc_amber_n", -1.0], ["s_cc_amber_s", 1.0]]:
		var sz: float = leg[1]
		var extra: Array = []
		for side: float in [-1.0, 1.0]:
			# [base, cond, side, |z|, offset from kerb, yaw]; benches sit in the furniture zone facing the street (people watch the city, not a wall)
			extra.append(["prop_newspaper_box_red", "worn", side, 21.5, 0.75, 90.0 * side])
			extra.append(["prop_newspaper_box_blue", "worn", side, 22.2, 0.75, 90.0 * side])
			extra.append(["prop_park_bench", "worn", side, 33.5, 1.0, -90.0 * side])
			extra.append(["prop_park_bench", "worn", side, 69.5, 1.0, -90.0 * side])
			extra.append(["prop_bike_rack", "worn", side, 45.0, 0.75, 90.0])   # parallel to the kerb
			extra.append(["prop_bike_rack", "worn", side, 81.0, 0.75, 90.0])
		extra.append(["prop_usps_collection_box", "worn", -1.0, 62.0, 0.8, 90.0])
		var r := Seg.build(String(leg[0]), sz, {
			"no_parking": true,
			"bus": true, "bus_at": 52.0 if sz < 0.0 else 38.0,   # a stop each way (17 Nov): northbound north leg, southbound south leg
			"trees": [27.5, 39.5, 51.5, 63.5, 75.5, 87.5],
			"lamps": [33.5 - 2.5, 45.5 + 2.0, 57.5, 69.5 + 2.5, 81.5 + 2.5],
			"extra": extra})
		K.save_piece(r, String(leg[0]))
	quit()
