extends SceneTree
## Piece d_cc (overlay on the city-centre sample, Yasin 17 Nov: "elevate the props ... about 1500"). Reads the locked
## c_* blocks and their streets and adds the roof plant every big downtown roof carries, missing service sides, pots
## at shop doors, cafe tables out on the 6-7 m walks, bike racks along the shopfronts (life_lib.gd). The locked pieces
## are not touched. Run once; never when locked.
const LL := preload("res://tools/city/pilot/pieces/life_lib.gd")
func _init() -> void: _run.call_deferred()
func _run() -> void:
	var L = LL.new("d_cc")
	L.load_sample([0, 0, 400])
	L.roof_terraces(); L.roofs(2.2); L.services(); L.houses(); L.shopfronts(true); L.golf_carts(); L.window_acs(); L.solar()
	L.save("d_cc")
	quit()
