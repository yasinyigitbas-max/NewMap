extends SceneTree
## Piece j_ar_ad3 (art road kit, 17 Nov). 3rd St x Adela Ave (pad 2): signalised; N std (b056 Adela Ave), S strip (b057 Adela Ave), E art (b071 3rd St), W art (b070 3rd St).
## Legs rise away from it by N -2, S +2, E +0, W +0 m (kerb inlets where the water comes in). Dress strip.
## Built by road_art.gd (THE PLAN at its top has every rule and its reason). Run once; never when locked.
const R := preload("res://tools/city/pilot/pieces/road_art.gd")
func _init() -> void: _run.call_deferred()
func _run() -> void:
	R.art_junction("j_ar_ad3", {"N": "std", "S": "strip", "E": "art", "W": "art", "tN": 26.0, "tS": 26.0, "tE": 22.0, "tW": 22.0, "rise": {"N": -2.0, "S": 2.0, "W": 0.0, "E": 0.0}, "dress": "strip", "cond": "worn", "hyd": "ne_sw"})
	quit()
