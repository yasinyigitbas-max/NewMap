extends SceneTree
## Piece n_sc_south (sc fill: the empty scraps inside the ring, 20 Nov; Yasin: "just fill the tiny spaces empty in the ring
## road", "fill them meaningfully without touching anything that already exists"). Placed at grid [0, 0, 0], yaw 0
## (x = u, y = world height, z = v). Run once.
## FIVE SLIVERS along the south ring (n_sc_site.gd R12 / R6 / R9 / R8 / R10): between the beach-side houses' straight back
## edges (north, v 240 / 256 / 275 / 288 / 302) and the ring road's inner walk (south, palms in wells), each a wedge from
## 0 m to 11-18 m wide, closed at its east end by a cross street.
## WHY (planner): the houses' back yards face the ring boulevard. A strip this narrow with no access is a planted buffer:
## lawn, a privet hedge 0.8 m off the houses' back edge where the strip is at least 4 m wide (screening the yards from
## the boulevard and its lights), bougainvillea mounds in the wide parts, agaves in the narrow ones, sprinklers.
## No seats or paths: nobody should linger behind people's back fences, and the ring's own walk carries the walkers.
## LAND: 2.0 .. 4.2; the ground follows it and meets the houses' and the ring's edges at their exact heights.
const K := preload("res://tools/city/pilot/kit_lib.gd")
const H := preload("res://tools/city/pilot/pieces/hs_fill_lib.gd")
const S := preload("res://tools/city/pilot/pieces/n_sc_site.gd")

## SUPERCHECKER deletions (sc.py check, 20 Nov; Yasin: "be much more prone to delete a prop"): every item with a finding is out, with the reason
const SC := {"out": [
	]}

func _init() -> void: _run.call_deferred()

## [region, u0, u1, house edge v, ring table, hedge from u (strip >= 4 m), wide from u (>= 8 m)]
const STRIPS := [
	["r12", -964.8, -930.0, 240.0, "R12_RING", -959.0, -949.0],
	["r6", -928.2, -809.2, 256.0, "R6_RING", -917.0, -907.0],
	["r9", -788.5, -609.2, 275.0, "R9_RING", -730.0, -670.0],
	["r8", -590.8, -409.2, 288.0, "R8_RING", -535.0, -475.0],
	["r10", -383.5, -209.2, 302.0, "R10_RING", -325.0, -261.0],
]

func _run() -> void:
	var root := Node3D.new(); root.name = "n_sc_south"
	var g := K.Ground.new(); var props := K.Props.new(); var dec := K.Decals.new()
	for s: Array in STRIPS:
		var r: String = s[0]; var hv: float = s[3]
		var yf := func(x: float, z: float) -> float: return S.g(r, x, z)
		var ring: Array = S.REG[r][0]      # the region's first edge table is its ring edge
		H.paint_band(g, float(s[1]), float(s[2]), func(_x: float) -> float: return hv, S.f(ring, 0), [], "grass", yf)
		var P := func(base: String, cond: String, x: float, z: float, yaw := 0.0, collide := true) -> void: H.put(props, base, cond, x, z, yf, yaw, collide)
		# the hedge: 2 m privet segments end to end, 0.8 m off the houses' back edge, from where the strip is 4 m wide to
		# 1 m short of the cross street
		var u := float(s[5]) + 1.0
		while u + 1.0 <= float(s[2]) - 1.0:
			P.call("hedge_privet_2m", "normal", u, hv + 0.8, 90.0); u += 2.0
		# planting between hedge and ring walk: agaves where 4-8 m, bougainvillea every 15 m where 8 m or more
		var ringv := S.f(ring, 0)
		var a := float(s[5]) + 6.0
		while a < float(s[6]):
			P.call("plant_agave_americana_small", "normal", a, (hv + 1.6 + float(ringv.call(a))) * 0.5); a += 12.0
		var b := float(s[6]) + 6.0
		while b < float(s[2]) - 4.0:
			P.call("plant_bougainvillea_mound", "normal", b, (hv + 1.6 + float(ringv.call(b))) * 0.5); b += 15.0
		var k := float(s[6]) + 12.0
		while k < float(s[2]) - 4.0:
			P.call("prop_sprinkler_popup", "normal", k, hv + 3.0, 0.0, false); k += 40.0
	H.sc_apply(root, props, dec, SC)
	H.finish(root, g, props, dec, "n_sc_south")
	quit()
