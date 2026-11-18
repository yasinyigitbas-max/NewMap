extends SceneTree
## Piece j_ar_b3 (art road kit, 17 Nov). 3rd St x B Ave (pad 2): signalised; N res (b046 B Ave), S res (b047 B Ave), E art (b070 3rd St), W art (b069 3rd St).
## Legs rise away from it by N -2, S +6, E +0, W +6 m (kerb inlets where the water comes in). Dress hill, bus stop corners.
## Built by road_art.gd (THE PLAN at its top has every rule and its reason). Run once; never when locked.
const R := preload("res://tools/city/pilot/pieces/road_art.gd")
func _init() -> void: _run.call_deferred()
func _run() -> void:
	R.art_junction("j_ar_b3", {"N": "res", "S": "res", "E": "art", "W": "art", "tN": 26.0, "tS": 26.0, "tE": 22.0, "tW": 22.0, "rise": {"N": -2.0, "S": 6.0, "W": 6.0, "E": 0.0}, "dress": "hill", "cond": "worn", "hyd": "nw_se", "bus_corners": [[1.0, 1.0], [-1.0, -1.0]]})
	quit()
