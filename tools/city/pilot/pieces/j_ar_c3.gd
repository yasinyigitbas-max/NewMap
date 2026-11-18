extends SceneTree
## Piece j_ar_c3 (art road kit, 17 Nov). 3rd St x C Ave (pad 4): signalised; N res (b028 C Ave), S std (b029 C Ave), E art (b068 3rd St), W art (b067 3rd St).
## Legs rise away from it by N -4, S +6, E +4, W -2 m (kerb inlets where the water comes in). Dress hill.
## Built by road_art.gd (THE PLAN at its top has every rule and its reason). Run once; never when locked.
const R := preload("res://tools/city/pilot/pieces/road_art.gd")
func _init() -> void: _run.call_deferred()
func _run() -> void:
	R.art_junction("j_ar_c3", {"N": "res", "S": "std", "E": "art", "W": "art", "tN": 26.0, "tS": 26.0, "tE": 22.0, "tW": 22.0, "rise": {"N": -4.0, "S": 6.0, "W": -2.0, "E": 4.0}, "dress": "hill", "cond": "worn", "hyd": "ne_sw"})
	quit()
