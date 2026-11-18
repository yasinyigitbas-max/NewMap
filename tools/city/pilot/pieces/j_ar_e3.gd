extends SceneTree
## Piece j_ar_e3 (art road kit, 17 Nov). 3rd St x E Ave (pad 2): signalised; N res (b018 E Ave), S std (b019 E Ave), E art (b067 3rd St), W art (b066 3rd St).
## Legs rise away from it by N -2, S +2, E +2, W +0 m (kerb inlets where the water comes in). Dress grt, bus stop corners.
## Built by road_art.gd (THE PLAN at its top has every rule and its reason). Run once; never when locked.
const R := preload("res://tools/city/pilot/pieces/road_art.gd")
func _init() -> void: _run.call_deferred()
func _run() -> void:
	R.art_junction("j_ar_e3", {"N": "res", "S": "std", "E": "art", "W": "art", "tN": 26.0, "tS": 26.0, "tE": 22.0, "tW": 22.0, "rise": {"N": -2.0, "S": 2.0, "W": 0.0, "E": 2.0}, "dress": "grt", "cond": "rusty", "hyd": "nw_se", "bus_corners": [[1.0, 1.0], [-1.0, -1.0]]})
	quit()
