extends SceneTree
## Piece n_ec_beach_n (ec fill, the east shore beyond the ring, north half, u 1200 .. 25 m past the 0 m line, v -500 ..
## -250): SHORE HILL BEACH, the sand down to the water and on under it. Placed at grid [0, 0, 0], yaw 0 (x = u, z = v,
## y = world). Run once; never when locked.
##
## WHY (planner): the people who come down the beach walk A400 cross 220 m of sand to the water along a worn footpath;
## the families settle near the water and near the lifeguards: so two LIFEGUARD TOWERS face the water ~120 m apart
## (v -440 and v -320, either side of the bay the shore makes at v -390), each with a life ring stand and a rip-current
## sign beside it; groups of UMBRELLAS (a few furled) round the towers, where the footpath reaches the water and in the
## middle of the bay, a towel's worn patch beside each; a KAYAK RACK above the waterline at the north end for the
## paddlers who launch here. The sand is bare between (a beach); wet sand darker along the water.
## SHORE (SHORE_GUIDE.md): the sand follows the land EXACTLY near the water (n_ec_site.g: the 5 cm lift eased to 0 as
## the land falls from 0.3 m to 0) and goes on under the water to 25 m past the land's 0 m line, so the sea (0 m)
## cuts it on the land's own 0 m line, inside the locked foam strip x_shore_foam. 2 m grid (the curved waterline).
## LAND: 1.3 - 1.8 m at u 1200, 0.5 m 20 m from the water, then 1 : 8 into the sea (-3 m at the piece's sea edge).
## AFTER THE SUPERCHECKER PASS (20 Nov, delete when unsure): every mark on the sand (wet sand, the footpath, the towels'
## patches) is OUT (see _wear): the sand is clean; the foam strip x_shore_foam is the water's edge.
const PASS := 2
const K := preload("res://tools/city/pilot/kit_lib.gd")
const W := preload("res://tools/city/pilot/pieces/wear_lib.gd")
const H := preload("res://tools/city/pilot/pieces/hs_fill_lib.gd")
const S := preload("res://tools/city/pilot/pieces/n_ec_site.gd")

const Z0 := -500.0
const Z1 := -250.0

## items placed against the 0 m line: [base, cond, offset from the 0 m line (u, - = landward), v, yaw ("sea" = facing
## the water, else degrees), collide]
const ALONG := [
	# the lifeguard towers facing the water, a life ring stand and the rip-current sign beside each
	["prop_lifeguard_tower", "worn", -30.0, -440.0, "sea", true],
	["prop_lifering_stand", "worn", -27.0, -435.6, "sea", true], ["prop_beach_sign_rip", "worn", -26.0, -445.0, "sea", true],
	["prop_lifeguard_tower", "worn", -30.0, -320.0, "sea", true],
	["prop_lifering_stand", "worn", -27.0, -315.6, "sea", true], ["prop_beach_sign_rip", "worn", -26.0, -325.0, "sea", true],
	# the kayak rack above the waterline at the north end (paddlers launch here)
	["prop_kayak_rack", "worn", -22.0, -486.0, "sea", true],
	# umbrellas round the north tower (families sit where the lifeguard watches)
	["prop_beach_umbrella", "worn", -45.0, -452.0, 20.0, true], ["prop_beach_umbrella", "worn", -52.0, -446.5, 95.0, true],
	["prop_beach_umbrella", "worn", -40.0, -429.0, 160.0, true], ["prop_beach_umbrella", "worn", -60.0, -458.0, 45.0, true],
	["prop_beach_umbrella_closed", "worn", -38.0, -468.0, 0.0, true], ["prop_beach_umbrella", "worn", -70.0, -424.0, 120.0, true],
	# where the footpath from the access reaches the water (v -400)
	["prop_beach_umbrella", "worn", -35.0, -408.0, 70.0, true], ["prop_beach_umbrella", "worn", -42.0, -393.0, 10.0, true],
	["prop_beach_umbrella", "worn", -55.0, -412.0, 140.0, true], ["prop_beach_umbrella_closed", "worn", -30.0, -386.0, 0.0, true],
	# the middle of the bay
	["prop_beach_umbrella", "worn", -40.0, -365.0, 35.0, true], ["prop_beach_umbrella", "worn", -48.0, -357.0, 115.0, true],
	["prop_beach_umbrella_closed", "worn", -36.0, -347.0, 0.0, true], ["prop_beach_umbrella", "worn", -62.0, -352.0, 75.0, true],
	# round the south tower
	["prop_beach_umbrella", "worn", -44.0, -332.0, 55.0, true], ["prop_beach_umbrella", "worn", -38.0, -308.0, 150.0, true],
	["prop_beach_umbrella", "worn", -50.0, -301.0, 25.0, true], ["prop_beach_umbrella", "worn", -58.0, -324.0, 100.0, true],
	["prop_beach_umbrella_closed", "worn", -35.0, -290.0, 0.0, true], ["prop_beach_umbrella", "worn", -42.0, -270.0, 65.0, true],
	["prop_beach_umbrella", "worn", -48.0, -262.0, 170.0, true],
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
	var root := Node3D.new(); root.name = "n_ec_beach_n"
	var g := K.Ground.new(); var props := K.Props.new(); var dec := K.Decals.new()
	var rr := W.rng_for("n_ec_beach_n")
	var yf := func(x: float, z: float) -> float: return S.g(x, z)
	var se := func(z: float) -> float: return S.sea_u(z)
	S.rows(g, Z0, Z1, [S.U_E, se], ["sand"], [], yf, 2.0)
	H.skirt(g, Vector2(S.U_E, Z0), Vector2(S.zero_u(Z0) - 10.0, Z0), yf, "sand")
	if PASS >= 2:
		var items: Array = []
		for a: Array in ALONG:
			var v := float(a[3])
			items.append([a[0], a[1], S.zero_u(v) + float(a[2]), v, S.sea_yaw(v) if a[4] is String else float(a[4]), a[5]])
		H.polish(props, g, items)
		_wear(dec, rr, yf)
		H.sc_apply(root, props, dec, SC)
	H.finish(root, g, props, dec, "n_ec_beach_n")
	quit()

## wear: none. SUPERCHECKER PASS (20 Nov, "be much more prone to delete a prop or road mark"): every mark on the sand
## had a finding ("grime mark lies on sand": 409 marks) and is out at the source: the wet sand along the water, the
## footpaths from the accesses to the water, the towels' patches. The bubbly sea / sand line is the locked foam strip
## x_shore_foam, lying on the land's 0 m line where this sand meets the sea.
func _wear(dec: K.Decals, rr: RandomNumberGenerator, yf: Callable) -> void:
	pass
