extends SceneTree
## Piece c_nw (city centre sample, NW corner). Amber frontage, a continuous street wall: the office tower on the corner
## (the junction is the address everyone gives), the department store, a 3-storey brick row, a corner cafe.
## Behind: an apartment row faces the alley (people live over the service lane, as in old centres); a loading court
## behind the store with its dumpsters and the substation box that feeds the block (wires run underground here).
## On 10th: a news kiosk next to the tower's flank. Run once; never when locked.
const C := preload("res://tools/city/pilot/pieces/cc_lib.gd")
const B := preload("res://tools/city/pilot/pieces/block_lib.gd")
const K := preload("res://tools/city/pilot/kit_lib.gd")
const S := preload("res://tools/city/pilot/site.gd")
func _init() -> void: _run.call_deferred()
func _run() -> void:
	S.hill_on = false
	var root := Node3D.new(); root.name = "c_nw"
	var bl := Node3D.new(); bl.name = "Buildings"; root.add_child(bl)
	B.begin("c_nw"); var g := K.Ground.new(); var props := K.Props.new()
	C.floor(g, -1.0, -1.0, [])
	var z := -S.T_BLD
	var parts := ["urban/twr_office", "urban/urb_dept_store", "urban/urb_brick_row", "commercial/com_cafe_seaside"]
	var placed: Array = []
	for f: String in parts:
		var r := B.on_amber(bl, f, -1.0, -S.A_BLD, z); placed.append([r, z, f]); z -= float(r[1])
	for p: Array in placed: B.door_pots(props, p[0][0], String(p[2]))   # planters dress every shop and lobby door
	for p: Array in placed: C.back_of_house(props, p[0][0], String(p[2]), String(p[2]).contains("brick_row"))
	# apartments over the alley behind the brick row (back of the brick row is at x -30)
	var apt := K.building(bl, "modular/examples/mod_apt_row", Vector3(-38.0, S.walk_y(0.0), -78.7), -90.0)
	B.on_tenth(bl, "commercial/com_kiosk", 1.0, -S.T_BLD, -40.0)
	# loading court behind the tower and the store: dumpsters, compactor-size rolloff, recycling, the substation
	props.add("prop_dumpster_3yd_green", "worn", Vector3(-43.1, S.walk_y(0.0), -40.0), -90.0)
	props.add("prop_dumpster_3yd_blue", "worn", Vector3(-43.1, S.walk_y(0.0), -43.0), -90.0)
	props.add("prop_dumpster_rolloff_20yd", "worn", Vector3(-42.0, S.walk_y(0.0), -55.0), 0.0)
	# block wall screening the loading court from the alley: tagged, as such walls always are
	for k in 3: props.add("fence_graffiti_cmu_panel", "worn", Vector3(-43.7, S.walk_y(0.0), -46.0 - k * 2.0), 90.0)
	props.add("prop_transformer_substation", "worn", Vector3(-40.0, S.walk_y(0.0), -24.0), -90.0)
	props.add("prop_bollard_steel", "worn", Vector3(-43.6, S.walk_y(0.0), -22.0), 0.0)
	props.add("prop_bollard_steel", "worn", Vector3(-43.6, S.walk_y(0.0), -26.0), 0.0)
	props.add("prop_ac_condenser", "worn", Vector3(-37.5, S.walk_y(0.0), -30.0), -90.0)
	props.add("prop_ac_condenser", "worn", Vector3(-37.5, S.walk_y(0.0), -31.4), -90.0)
	props.add("prop_trash_cart_black", "worn", Vector3(-43.2, S.walk_y(0.0), -67.6), -90.0)   # apartment bins by their door side
	props.add("prop_trash_cart_blue", "worn", Vector3(-43.2, S.walk_y(0.0), -68.5), -90.0)
	props.add("prop_newspaper_box_red", "worn", Vector3(-36.6, S.walk_y(0.0), -9.1), 0.0)     # by the kiosk
	B.finish(root, g, props, "c_nw")
	quit()
