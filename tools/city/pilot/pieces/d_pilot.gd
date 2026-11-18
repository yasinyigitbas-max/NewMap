extends SceneTree
## Piece d_pilot (overlay on the pilot: houses on the hill + the high street, Yasin 17 Nov: "elevate the props ... to
## the other zones average, about 1500"). Reads the locked pilot pieces and adds what their buildings lack - roof plant
## on the flat commercial roofs, service sides, house downspouts / numbers / hose reels, pots at shop doors, bike racks
## (life_lib.gd says why each one is there). The locked pieces are not touched. Run once; never when locked.
const LL := preload("res://tools/city/pilot/pieces/life_lib.gd")
func _init() -> void: _run.call_deferred()
func _run() -> void:
	var L = LL.new("d_pilot")
	L.load_sample([0, 0, 0])
	L.roofs(3.0); L.services(); L.houses(); L.shopfronts(false); L.golf_carts(); L.window_acs(); L.solar()
	L.save("d_pilot")
	quit()
