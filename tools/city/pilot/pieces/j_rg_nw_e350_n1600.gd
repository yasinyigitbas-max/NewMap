extends SceneTree
## Piece j_rg_nw_e350_n1600 (hero: the ferry landing's gate on 1st St, 21 Nov; Yasin: "get to work on ferry landing").
## The 45 m ring gap left in 1st St (block b145, between s_rg_nw_b145_2 and _3, road_rg.gd FERRY) becomes a SIGNALISED
## T: Ferry Landing Drive leaves the ring north (bay side) into the landing's drop-off loop and lot (h_ferry_landing).
## WHY a signal (planner): the ferry's walkers cross 1st St here between the ferry plaza (n_fn_east, south, bollarded:
## people only) and the terminal; a boat unloads 100+ people and 40 cars at once; ferry_plan.png "signalised T +
## crosswalk". The continental crosswalks across the ring land on the plaza (u 320 - 382).
## HOW: the ring node does not exist in sites.json (the gap was left for a hand-made piece), so this script adds ONE
## node to the library's cached ring (in memory only, nothing else changes): at the gap's centre, stem due north,
## the residential section (two lanes, 11.4 m kerb to kerb, R 8 returns), signal control; the tile is widened to the
## gap's exact ends (s +- 22.5 m) so it meets both boulevard pieces flush. Every rule of the T itself is the library's
## (road_rg.gd build_t), as for every other ring T. Run once; never when locked.
const NW := preload("res://tools/city/pilot/pieces/road_rg_NW.gd")
const RG := preload("res://tools/city/pilot/pieces/road_rg.gd")
func _init() -> void: _run.call_deferred()
func _run() -> void:
	var R: Dictionary = NW.prepare()
	var path: RG.Path = R["path"]
	var fg := RG.ferry_gap_s()
	var s_n := (float(fg[0]) + float(fg[1])) * 0.5
	var o: Vector2 = path.point(s_n)
	var ds := Vector2(0.0, -1.0)
	var key := "ferry"
	var nd := {"key": key, "u": o.x, "v": o.y, "pad": RG.ring_h(s_n), "kind": "T", "owner": "ring", "legs": [],
		"stem": {"dir": ds, "sec": "res", "block": "ferry", "name": "Ferry Landing Dr"}, "o": o, "s": s_n,
		"piece": "j_rg_nw_e350_n1600", "outer": RG.PROM, "ctl": "signal", "bus": false}
	var tg: Dictionary = RG._tgeom(path, o, s_n, ds, "res", true)
	nd["tg"] = tg
	nd["em"] = s_n - float(fg[0]); nd["ep"] = float(fg[1]) - s_n
	print("FERRY T o=%s pad=%.3f s=%.2f em(lib)=%.2f ep(lib)=%.2f -> %.2f / %.2f z_E=%.2f sig=%.0f" % [str(o), float(nd["pad"]), s_n, float(tg["em"]), float(tg["ep"]), float(nd["em"]), float(nd["ep"]), float(tg["z_E"]), float(tg["sig"])])
	R["nodes"][key] = nd
	RG.build_t(key)
	quit()
