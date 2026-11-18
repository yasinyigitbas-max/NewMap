extends SceneTree
## Piece c_sw (city centre sample, SW corner). Brick corner block, then the shopping mall filling the block to the
## alley (its loading docks open on the alley, never on Amber), the bank, a news kiosk. On 10th: a service row
## (dry cleaner, key cutter, laundry) faces the side street. Behind the bank: a small office row on the alley.
## Run once; never when locked.
const C := preload("res://tools/city/pilot/pieces/cc_lib.gd")
const B := preload("res://tools/city/pilot/pieces/block_lib.gd")
const K := preload("res://tools/city/pilot/kit_lib.gd")
const S := preload("res://tools/city/pilot/site.gd")
func _init() -> void: _run.call_deferred()
func _run() -> void:
	S.hill_on = false
	var root := Node3D.new(); root.name = "c_sw"
	var bl := Node3D.new(); bl.name = "Buildings"; root.add_child(bl)
	B.begin("c_sw"); var g := K.Ground.new(); var props := K.Props.new()
	C.floor(g, -1.0, 1.0, [])
	var z := S.T_BLD
	var placed: Array = []
	for f: String in ["urban/urb_brick_corner", "urban/urb_mall", "commercial/com_bank", "commercial/com_kiosk"]:
		var r := B.on_amber(bl, f, -1.0, -S.A_BLD, z); placed.append(r); z += float(r[1])
	K.building(bl, "ck/ck_svc_cinema_fast", Vector3(-38.0, S.walk_y(0.0), S.T_BLD + 6.0), 180.0)    # faces 10th
	K.building(bl, "modular/examples/mod_svc_row", Vector3(-38.0, S.walk_y(0.0), 82.7), -90.0)             # faces the alley
	# mall loading on the alley: rolloff, dumpsters, pallets of recycling, a k-rail protecting the dock corner
	props.add("prop_dumpster_rolloff_20yd", "worn", Vector3(-46.5, S.walk_y(0.0), 40.0), 0.0)
	props.add("prop_dumpster_3yd_green", "worn", Vector3(-46.5, S.walk_y(0.0), 50.0), -90.0)
	props.add("prop_dumpster_3yd_blue", "worn", Vector3(-46.5, S.walk_y(0.0), 53.0), -90.0)
	props.add("prop_transformer_substation", "worn", Vector3(-40.0, S.walk_y(0.0), 92.0), -90.0)
	props.add("prop_pay_station", "worn", Vector3(-31.0, S.walk_y(0.0), 92.0), 0.0)
	# bank: planters at the door, a bike rack; kiosk sells papers: news boxes
	var names := ["urban/urb_brick_corner", "urban/urb_mall", "commercial/com_bank", "commercial/com_kiosk"]
	for k in placed.size():
		B.door_pots(props, placed[k][0], names[k])
		if k == 2: C.back_of_house(props, placed[k][0], names[k])   # corner and mall backs touch other buildings / the alley
	props.add("prop_newspaper_box_red", "worn", Vector3(-S.A_BLD - 0.5, S.walk_y(0.0), z + 0.8), 90.0)
	props.add("prop_newspaper_box_blue", "worn", Vector3(-S.A_BLD - 0.5, S.walk_y(0.0), z + 1.4), 90.0)
	B.finish(root, g, props, "c_sw")
	quit()
