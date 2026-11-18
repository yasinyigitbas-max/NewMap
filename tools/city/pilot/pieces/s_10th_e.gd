extends SceneTree
## Piece s_10th_e: 10th St east of Amber (|x| 23.5 - 150): downtown to the alley (x 44..50), then the residential
## street climbing the hill (level to x 40, +5.9 m at x 150, max 8 %). Run once; never when locked.
## Downtown: bookshop (bike rack in front), news kiosk across the street. Residential: grass parkway, one street tree
## per lot in front of each house (clear of the driveway), cobra lamps at lot lines alternating sides, hydrant at
## a lot line, 25 mph sign for drivers leaving downtown, kerb inlets where the hill meets downtown.
const T := preload("res://tools/city/pilot/pieces/tenth_seg.gd")
const K := preload("res://tools/city/pilot/kit_lib.gd")
const S := preload("res://tools/city/pilot/site.gd")
func _init() -> void: _run.call_deferred()
func _run() -> void:
	var extra: Array = [
		["tree_jacaranda_a", "normal", -1.0, 29.0, 0.75, 70.0],
		["tree_jacaranda_b", "normal", 1.0, 30.0, 0.75, 200.0],
		["prop_bike_rack", "worn", -1.0, 37.0, 0.75, 0.0],             # bookshop customers
		["prop_lamp_victorian", "worn", 1.0, 35.0, 0.6, 0.0],
		["prop_newspaper_box_blue", "worn", 1.0, 41.5, 0.75, 180.0],   # by the kiosk
		["prop_trash_receptacle", "worn", -1.0, 42.0, 0.75, 0.0],
		["prop_storm_drain_curb_inlet", "worn", -1.0, 52.0, 0.0, 0.0],   # catch the hill's runoff before downtown
		["prop_storm_drain_curb_inlet", "worn", 1.0, 52.0, 0.0, 180.0],
		["prop_sign_speed25", "worn", 1.0, 54.5, 1.0, -90.0],          # eastbound drivers leaving downtown
		["prop_lamp_cobra", "worn", -1.0, 71.0, 1.0, 0.0],             # arm over the street
		["prop_lamp_cobra", "worn", 1.0, 101.0, 1.0, 180.0],
		["prop_lamp_cobra", "worn", -1.0, 131.0, 1.0, 0.0],
		["prop_hydrant_red", "worn", -1.0, 86.3, 1.0, 180.0],
		["prop_manhole_cover", "worn", -1.0, 72.0, -4.0, 0.0],
		["prop_manhole_cover", "worn", 1.0, 128.0, -4.0, 0.0],
	]
	# one street tree per lot, in the parkway in front of the house, kept 2.5 m from its driveway
	var kinds := ["tree_magnolia_a", "tree_coral_a", "tree_magnolia_b", "tree_coral_b"]
	var i := 0
	for L: Dictionary in S.LOTS:
		var tx := float(L.hx)
		if float(L.drive) > 0.0 and absf(tx - float(L.drive)) < 4.0: tx = float(L.drive) + signf(tx - float(L.drive)) * 4.0
		extra.append([kinds[i % kinds.size()], "normal", float(L.side), tx, 1.0, float(i * 47 % 360)]); i += 1
	var r := T.build("s_10th_e", 1.0, 150.0, 50.0, [44.0, 50.0], {"extra": extra, "wells": [[-1.0, 29.0], [1.0, 30.0]]})   # the two downtown trees stand in wells (16 Nov audit)
	K.save_piece(r, "s_10th_e")
	quit()
