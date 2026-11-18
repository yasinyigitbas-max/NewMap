extends SceneTree
## Piece j_ar_ad5 (art road kit, 17 Nov). 5th St x Adela Ave (pad 4): signalised; N strip (b058 Adela Ave), S res (b059 Adela Ave), E art (b087 5th St), W res (b086 5th St).
## Legs rise away from it by N +0, S +2, E +0, W +2 m (kerb inlets where the water comes in). Dress strip.
## Only the 5th St approach (ring stub b087, arterial section from 22 m) is wide: the one mast arm (NW) serves it; posts for the rest.
## Built by road_art.gd (THE PLAN at its top has every rule and its reason). Run once; never when locked.
const R := preload("res://tools/city/pilot/pieces/road_art.gd")
func _init() -> void: _run.call_deferred()
func _run() -> void:
	R.art_junction("j_ar_ad5", {"N": "strip", "S": "res", "E": "art", "W": "res", "tN": 26.0, "tS": 26.0, "tE": 22.0, "tW": 26.0, "rise": {"N": 0.0, "S": 2.0, "W": 2.0, "E": 0.0}, "dress": "strip", "cond": "worn", "hyd": "ne_sw"})
	quit()
