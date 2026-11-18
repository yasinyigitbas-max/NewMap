extends SceneTree
## Piece s_apt (apartment band sample): one residential street leg from the junction tile (|z| 20) to 100 m, along +z,
## used on all four legs. Built by road_lib.apt_street (dress "apt"): magnolia / ficus / queen palm parkway, globe lamps,
## street sweeping signs. 17 Nov audit #15: bus boarding pad through the parkway, posts spread (was: sign, palm, lamp
## and speed sign within 2.5 m). The civic, gritty and waterfront samples use their own dresses (s_civ, s_grt, s_wfd)
## on the same cross-section. Run once; never when locked.
const R := preload("res://tools/city/pilot/pieces/road_lib.gd")
func _init() -> void: _run.call_deferred()
func _run() -> void:
	R.apt_street("s_apt", "apt")
	quit()
