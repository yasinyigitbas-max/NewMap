extends RefCounted
## Waterfront sample helpers (s_wf, f_se, f_sw, f_ne, f_nw, w_wf; 17 Nov). The sample sits on the apartment-band
## grid (locked j_apt + s_apt north / east / west legs); the water is to the SOUTH (+z). Piece-local frame = the
## junction centre, x east, +z south.
## Datum (kit waterfront README): harbour bed at the wall toe, still water 1.5 m above it, quay coping / pier deck
## 3.0 m above it = the street (walk) level here. So BED = walk - 3.0, WATER = walk - 1.5. Floats: pontoon underside
## at BED + 1.20 (deck top BED + 1.95, the gangway landing height). Boats float at BED + 1.5 - WL.
## Water itself is NOT in the pieces: the game draws one sea plane for the whole map. A piece records its water
## rectangles in meta "water" ([x0, z0, x1, z1, y] piece-local); the preview draws water there. Integration note: the
## waterfront's street level must sit 1.5 m above the game's sea level.
const K := preload("res://tools/city/pilot/kit_lib.gd")
const S := preload("res://tools/city/pilot/site.gd")
const W := preload("res://tools/city/pilot/pieces/wear_lib.gd")
const I := preload("res://tools/city/pilot/pieces/ind_lib.gd")
const QZ := 40.0            # quay water face (z)
const BOAT_WL := {"prop_boat_sloop": 1.40, "prop_boat_express": 0.70, "prop_boat_troller": 1.35, "prop_boat_skiff": 0.30}

static func wy() -> float: return S.walk_y(0.0)
static func bed() -> float: return wy() - 3.0
static func water() -> float: return wy() - 1.5
static func deck() -> float: return bed() + 1.95          # float deck top
static func float_y() -> float: return bed() + 1.20       # float model origin (pontoon underside)

## one quay module (6 m along x, water face toward +z at yaw 0) centred at x, its water face on line QZ
static func quay(props: K.Props, kind: String, x: float, z_face := QZ, yaw := 0.0) -> void:
	var off := Basis(Vector3.UP, deg_to_rad(yaw)) * Vector3(0, 0, -1.0)
	I.add(props, "prop_quay_" + kind, "worn", Vector3(x, bed(), z_face) + off, yaw)

## a moored boat: centre (x, z), bow direction yaw (kit bow = +z at yaw 0)
static func boat(props: K.Props, base: String, x: float, z: float, yaw: float) -> void:
	I.add(props, base, "worn", Vector3(x, water() - float(BOAT_WL.get(base, 0.5)), z), yaw)

## sand height of the beach: level with the walk at z0, falling 8 % toward the water and on under it
static func beach_y(z: float, z0: float) -> float:
	return wy() - maxf(0.0, z - z0) * 0.08

## preview water rectangle (piece-local) -> meta "water"
static func water_rect(root: Node3D, x0: float, z0: float, x1: float, z1: float) -> void:
	var w: Array = root.get_meta(&"water", [])
	w.append([x0, z0, x1, z1, water()])
	root.set_meta(&"water", w)

## seaside railing along the quay edge from x0 to x1 (4 m modules end to end, a wall-flange end piece where a run
## stops at a gap), 0.35 m in from the water face, on the coping
static func rail_run(props: K.Props, x0: float, x1: float, z_face := QZ) -> void:
	var n := int(floor((x1 - x0) / 4.09))
	if n < 1: return
	var z := z_face - 0.35
	for k in n: I.add(props, "prop_prom_rail", "worn", Vector3(x0 + 2.045 + k * 4.09, wy(), z), 0.0)
	if (x1 - x0) - n * 4.09 >= 2.05:      # the run ends in a 2 m module bolted to the wall flange
		I.add(props, "prop_prom_rail_wall", "worn", Vector3(x0 + n * 4.09 + 1.02, wy(), z), 0.0)
