extends SceneTree
## Piece j_ar_c4 (art road kit, 17 Nov). 4th St x C Ave (pad 10): signalised; N std (b029 C Ave), S std (b030 C Ave), E art (b076 4th St), W art (b075 4th St).
## Legs rise away from it by N -6, S -2, E +4, W -6 m (kerb inlets where the water comes in). Dress hill, bus stop corners.
## Built by road_art.gd (THE PLAN at its top has every rule and its reason). Run once; never when locked.
const R := preload("res://tools/city/pilot/pieces/road_art.gd")
func _init() -> void: _run.call_deferred()
func _run() -> void:
	R.art_junction("j_ar_c4", {"N": "std", "S": "std", "E": "art", "W": "art", "tN": 26.0, "tS": 26.0, "tE": 22.0, "tW": 22.0, "rise": {"N": -6.0, "S": -2.0, "W": -6.0, "E": 4.0}, "dress": "hill", "cond": "clean", "hyd": "ne_sw", "bus_corners": [[1.0, 1.0], [-1.0, -1.0]]})
	quit()
