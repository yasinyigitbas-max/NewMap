extends SceneTree
## Piece n_ec_beach_s (ec fill, the east shore beyond the ring, south half, u 1200 .. 25 m past the 0 m line, v -250 ..
## 0): SHORE HILL BEACH's south end, the sand down to the water and on under it, and the DOG BEACH. Placed at grid
## [0, 0, 0], yaw 0 (x = u, z = v, y = world). Run once; never when locked.
##
## WHY (planner): the footpaths from the accesses A200 (v -200) and A0 (v -8) cross 300 - 450 m of sand to the water;
## two LIFEGUARD TOWERS face the water (v -170, v -45), each with a life ring stand and a rip-current sign; UMBRELLAS
## (a few furled) where the footpaths reach the water and round the towers, a towel's worn patch beside each; South Beach
## Rentals' (n_ec_dune_s) two KAYAK RACKS above the waterline at v -70 where its kayaks are launched; the DOG BEACH at
## the quiet south-west corner of the sand, off the swimmers' beach: a picket-fenced run with a gate on its land side
## (where the dog owners come from A0), the dog rules sign at the gate, a bin on the fence for the bags, two benches
## inside for the owners. Wet sand darker along the water.
## SHORE: as n_ec_beach_n (the sand follows the land exactly near the water and on under it to 25 m past the 0 m line).
## The south edge v 0 is open: the sand goes on south of v 0 (not filled); a face under the edge.
## LAND: 0.7 - 1.2 m at u 1200, 0.4 - 0.5 m 30 m from the water, then 1 : 8 into the sea.
## AFTER THE SUPERCHECKER PASS (20 Nov, delete when unsure): every mark on the sand (wet sand, the footpaths, the towels'
## patches, the dog run's trodden sand) is OUT (see _wear). One bench inside the dog run was left out before the check
## (it would have stood alone).
const PASS := 2
const K := preload("res://tools/city/pilot/kit_lib.gd")
const W := preload("res://tools/city/pilot/pieces/wear_lib.gd")
const H := preload("res://tools/city/pilot/pieces/hs_fill_lib.gd")
const S := preload("res://tools/city/pilot/pieces/n_ec_site.gd")

const Z0 := -250.0
const Z1 := 0.0
const DOG := [1230.0, -38.0, 1258.0, -14.0]       # the dog run (picket fence round it)
const DOG_GATE := 13.0                            # the gate: 13 m along the west side from its north corner

const ITEMS := [
	# the dog run: the dog rules sign by the gate (outside, facing the owners coming from A0), a bin on the fence inside
	# by the gate for the bags, two benches inside on the west side facing the run (east)
	["prop_beach_sign_dog", "worn", 1228.6, -23.0, -90.0],
	["prop_trash_receptacle", "dirty", 1230.6, -27.6, 0.0],
	["prop_park_bench", "worn", 1231.0, -33.0, 90.0], ["prop_park_bench", "worn", 1231.0, -29.4, 90.0],
]
## items placed against the 0 m line: [base, cond, offset from the 0 m line (u, - = landward), v, yaw, collide]
const ALONG := [
	# the lifeguard towers facing the water, a life ring stand and the rip-current sign beside each
	["prop_lifeguard_tower", "worn", -30.0, -170.0, "sea", true],
	["prop_lifering_stand", "worn", -27.0, -165.6, "sea", true], ["prop_beach_sign_rip", "worn", -26.0, -175.0, "sea", true],
	["prop_lifeguard_tower", "worn", -30.0, -45.0, "sea", true],
	["prop_lifering_stand", "worn", -27.0, -40.6, "sea", true], ["prop_beach_sign_rip", "worn", -26.0, -50.0, "sea", true],
	# South Beach Rentals' launching racks above the waterline
	["prop_kayak_rack", "worn", -22.0, -73.0, "sea", true], ["prop_kayak_rack", "worn", -22.0, -67.0, "sea", true],
	# where the footpath from A200 reaches the water (v -200)
	["prop_beach_umbrella", "worn", -36.0, -206.0, 30.0, true], ["prop_beach_umbrella", "worn", -44.0, -194.0, 120.0, true],
	["prop_beach_umbrella", "worn", -30.0, -214.0, 75.0, true], ["prop_beach_umbrella_closed", "worn", -52.0, -222.0, 0.0, true],
	["prop_beach_umbrella", "worn", -40.0, -238.0, 160.0, true],
	# round the north tower
	["prop_beach_umbrella", "worn", -45.0, -182.0, 15.0, true], ["prop_beach_umbrella", "worn", -38.0, -156.0, 100.0, true],
	["prop_beach_umbrella", "worn", -52.0, -160.0, 55.0, true], ["prop_beach_umbrella_closed", "worn", -60.0, -168.0, 0.0, true],
	["prop_beach_umbrella", "worn", -40.0, -140.0, 140.0, true],
	# between the towers
	["prop_beach_umbrella", "worn", -38.0, -120.0, 85.0, true], ["prop_beach_umbrella", "worn", -50.0, -128.0, 20.0, true],
	["prop_beach_umbrella", "worn", -34.0, -96.0, 130.0, true], ["prop_beach_umbrella_closed", "worn", -46.0, -90.0, 0.0, true],
	# round the south tower and where the footpath from A0 reaches the water (v -8)
	["prop_beach_umbrella", "worn", -55.0, -56.0, 40.0, true], ["prop_beach_umbrella", "worn", -42.0, -60.0, 115.0, true],
	["prop_beach_umbrella", "worn", -40.0, -30.0, 65.0, true], ["prop_beach_umbrella", "worn", -48.0, -20.0, 170.0, true],
	["prop_beach_umbrella", "worn", -36.0, -12.0, 5.0, true], ["prop_beach_umbrella_closed", "worn", -60.0, -26.0, 0.0, true],
	["prop_beach_umbrella", "worn", -44.0, -4.0, 95.0, true],
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
	var root := Node3D.new(); root.name = "n_ec_beach_s"
	var g := K.Ground.new(); var props := K.Props.new(); var dec := K.Decals.new()
	var rr := W.rng_for("n_ec_beach_s")
	var yf := func(x: float, z: float) -> float: return S.g(x, z)
	var se := func(z: float) -> float: return S.sea_u(z)
	S.rows(g, Z0, Z1, [S.U_E, se], ["sand"], [[DOG[0], DOG[1], DOG[2], DOG[3], "sand"]], yf, 2.0)
	H.skirt(g, Vector2(S.U_E, Z1), Vector2(S.zero_u(Z1) - 10.0, Z1), yf, "sand")
	if PASS >= 2:
		# the dog run's picket fence, a post at every joint; the gate in the west side
		var nw := Vector2(DOG[0], DOG[1]); var ne := Vector2(DOG[2], DOG[1]); var se2 := Vector2(DOG[2], DOG[3]); var sw := Vector2(DOG[0], DOG[3])
		H.fence(props, "fence_picket_white", "fence_post_picket", nw, ne, yf, 2.0, "worn")
		H.fence(props, "fence_picket_white", "fence_post_picket", ne, se2, yf, 2.0, "worn")
		H.fence(props, "fence_picket_white", "fence_post_picket", se2, sw, yf, 2.0, "worn")
		H.fence(props, "fence_picket_white", "fence_post_picket", nw, sw, yf, 2.0, "worn", [[DOG_GATE, 1.0]])
		H.put(props, "fence_gate_picket", "worn", DOG[0], DOG[1] + DOG_GATE, yf, 90.0)
		var items: Array = ITEMS.duplicate()
		for a: Array in ALONG:
			var v := float(a[3])
			items.append([a[0], a[1], S.zero_u(v) + float(a[2]), v, S.sea_yaw(v) if a[4] is String else float(a[4]), a[5]])
		H.polish(props, g, items)
		_wear(dec, rr, yf)
		H.sc_apply(root, props, dec, SC)
	H.finish(root, g, props, dec, "n_ec_beach_s")
	quit()

## wear: none. SUPERCHECKER PASS (20 Nov, "be much more prone to delete a prop or road mark"): every mark on the sand
## had a finding ("grime mark lies on sand": 480 marks) and is out at the source: the wet sand along the water, the
## footpaths from the accesses to the water, the towels' patches, the dog run's trodden sand. The bubbly sea / sand line is the locked foam strip
## x_shore_foam, lying on the land's 0 m line where this sand meets the sea.
func _wear(dec: K.Decals, rr: RandomNumberGenerator, yf: Callable) -> void:
	pass
