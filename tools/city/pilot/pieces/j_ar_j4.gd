extends SceneTree
## Piece j_ar_j4 (art road kit, 17 Nov). 4th St x J Ave (pad 2): signalised; N res (b001 J Ave), S std (b002 J Ave), E art (b073 4th St), W art (b072 4th St).
## Legs rise away from it by N +0, S +2, E +2, W +0 m (kerb inlets where the water comes in). Dress grt.
## Built by road_art.gd (THE PLAN at its top has every rule and its reason). Run once; never when locked.
const R := preload("res://tools/city/pilot/pieces/road_art.gd")
func _init() -> void: _run.call_deferred()
func _run() -> void:
	R.art_junction("j_ar_j4", {"N": "res", "S": "std", "E": "art", "W": "art", "tN": 26.0, "tS": 26.0, "tE": 22.0, "tW": 22.0, "rise": {"N": 0.0, "S": 2.0, "W": 0.0, "E": 2.0}, "dress": "grt", "cond": "rusty", "hyd": "nw_se"})
	quit()
