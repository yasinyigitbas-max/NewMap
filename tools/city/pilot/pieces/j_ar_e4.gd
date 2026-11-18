extends SceneTree
## Piece j_ar_e4 (art road kit, 17 Nov). 4th St x E Ave (pad 4): signalised; N std (b019 E Ave), S std (b020 E Ave), E art (b075 4th St), W art (b074 4th St).
## Legs rise away from it by N -2, S +2, E +6, W +0 m (kerb inlets where the water comes in). Dress grt.
## Built by road_art.gd (THE PLAN at its top has every rule and its reason). Run once; never when locked.
const R := preload("res://tools/city/pilot/pieces/road_art.gd")
func _init() -> void: _run.call_deferred()
func _run() -> void:
	R.art_junction("j_ar_e4", {"N": "std", "S": "std", "E": "art", "W": "art", "tN": 26.0, "tS": 26.0, "tE": 22.0, "tW": 22.0, "rise": {"N": -2.0, "S": 2.0, "W": 0.0, "E": 6.0}, "dress": "grt", "cond": "rusty", "hyd": "nw_se"})
	quit()
