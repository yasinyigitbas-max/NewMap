# compose a west-fill piece script: the standard frame (site header, eased ground, pads, floor, buildings, wear) around
# a hand-written design (paints, props). usage: mk.py <spec.py>  (spec defines NAME, U, V, W, D, Y0, DOC, SITES, PAINTS, BODY, HDR)
import sys, runpy
S=runpy.run_path(sys.argv[1])
hdr=open(S['HDR']).read().strip()
sites=',\n\t\t'.join('["%s", Vector2(%.2f, %.2f), "%s", "%s"]'%s for s in S['SITES'])
paints='\n'.join('\tc.paint("%s", %.2f, %.2f, %.2f, %.2f)%s'%(p[0],p[1],p[2],p[3],p[4],('                # '+p[5]) if len(p)>5 else '') for p in S['PAINTS'])
src='''extends SceneTree
%s
## Layout row (%.1f, 0, %.1f): local x = u - (%.1f), z = v - (%.1f), heights absolute. Built by the west fill (University
## session, 20 Nov; review/fill_west/PLAN.md). Ground: the land 8 cm over it, eased over 8 m to the measured height of
## whatever borders each side; buildings on level pads at the highest ground under them (plinth faces downhill).
const L := preload("res://tools/city/pilot/pieces/w_fill_lib.gd")
%s

func _init() -> void: _run.call_deferred()

func _run() -> void:
	var c := L.new("%s", %.2f)
	var W := %.2f; var D := %.2f
	var land := func(x: float, z: float) -> float: return L.land_at(LAND, x, z) + 0.08
	var base := L.edged(land, W, D, EDGE_N, EDGE_S, EDGE_W, EDGE_E, 8.0)
	var SITES := [%s]
	var pads: Array = []
	for st: Array in SITES:
		var r0: Array = L.bld_rect(String(st[0]), st[1], String(st[2]))
		pads.append([maxf(0.0, float(r0[0]) - 0.3), maxf(0.0, float(r0[1]) - 0.3), minf(W, float(r0[2]) + 0.3), minf(D, float(r0[3]) + 0.3)])
	var gl := L.grid_lots(0.0, 0.0, W, D, pads, base)
	c.terrain(gl.lots)
	c.skirt_depth = 0.5
%s
	c.paint("grass", 0.0, 0.0, W, D)
	c.build_floor(L.rect_edges(0.0, 0.0, W, D))
	if c.stage == "ground": c.finish(); quit(); return
	var B := {}
	for k in SITES.size():
		c.y0 = float(gl.pads[k][4])
		B[String(SITES[k][3])] = c.bld(String(SITES[k][0]), SITES[k][1], String(SITES[k][2]), false, String(SITES[k][3]), %.2f)
%s
	for k2: String in B:
		var r: Dictionary = B[k2]
		c.services(r, 2.0, 1 if not String(r.folder).begins_with("apartments/") else 2, String(r.folder).begins_with("apartments/") or String(r.folder).begins_with("houses/"))
		for dr: Array in r.doors:
			var q: Vector3 = dr[1]; var o: Vector3 = dr[2]
			c.grime(Vector2(q.x + o.x * 0.9, q.z + o.z * 0.9), 0.0, 1.6, 1.4, %.2f)
	c.finish()
	quit()
'''%('\n'.join('## '+l for l in S['DOC'].strip().split('\n')), S['U'],S['V'],S['U'],S['V'],hdr,S['NAME'],S['Y0'],S['W'],S['D'],sites,paints,S.get('WEAR',0.7),S['BODY'].rstrip('\n'),S.get('GRIME',0.45))
open('/home/user/NewMap/tools/city/pilot/pieces/%s.gd'%S['NAME'],'w').write(src)
print('wrote',S['NAME'])
