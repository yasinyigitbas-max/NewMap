extends SceneTree
## Piece s_rg_b158_2 (ring road kit, stage 1 library test at its real site, 17 Nov): Alameda Blvd, block b158 part 2: the base-fence walk widens over 20 m to meet the beach promenade at the 11th St T (taper test).
## Built by road_rg.gd (every rule and its reason is written there). Run once; never when locked.
const RG := preload("res://tools/city/pilot/pieces/road_rg.gd")
func _init() -> void: _run.call_deferred()
func _run() -> void:
	RG.build_boulevard("b158", 2)
	quit()
