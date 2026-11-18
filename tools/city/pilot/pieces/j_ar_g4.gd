extends SceneTree
## Piece j_ar_g4 (art road kit, 17 Nov). 4th St x G Ave (pad 4): signalised; N res (b011 G Ave), S std (b012 G Ave), E art (b074 4th St), W art (b073 4th St).
## Legs rise away from it by N -2, S +2, E +0, W -2 m (kerb inlets where the water comes in). Dress grt, bus stop corners.
## Built by road_art.gd (THE PLAN at its top has every rule and its reason). Run once; never when locked.
const R := preload("res://tools/city/pilot/pieces/road_art.gd")
func _init() -> void: _run.call_deferred()
func _run() -> void:
	R.art_junction("j_ar_g4", {"N": "res", "S": "std", "E": "art", "W": "art", "tN": 26.0, "tS": 26.0, "tE": 22.0, "tW": 22.0, "rise": {"N": -2.0, "S": 2.0, "W": -2.0, "E": 0.0}, "dress": "grt", "cond": "rusty", "hyd": "ne_sw", "bus_corners": [[1.0, 1.0], [-1.0, -1.0]]})
	quit()
