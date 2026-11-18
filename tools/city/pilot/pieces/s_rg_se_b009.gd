extends SceneTree
## Piece s_rg_se_b009 (ring road kit, stage 2 half SE, 17 Nov): J Ave stub, 11th St -> Ocean Blvd (residential, flat; rebuilt from the core's example: kerb inlets clear of signs and aprons, sealed water-service cut)
## Built by road_rg_SE.gd over road_rg.gd (every rule and its reason is written there). Run once; never when locked.
const SE := preload("res://tools/city/pilot/pieces/road_rg_SE.gd")
func _init() -> void: _run.call_deferred()
func _run() -> void:
	SE.build_stub("b009")
	quit()
