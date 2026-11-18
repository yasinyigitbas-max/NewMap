extends SceneTree
## Terrain vs pieces (preview check, 17 Nov). Loads the assembled city (CITYKIT_LAYOUT_ONLY + EXTRA), the terrain grid
## (terrain_grid.f32 / .json, grid frame) and compares every piece's "ground" mesh with the terrain:
##   edge  = open edges of the piece's ground (welded per piece): terrain should sit 5 cm under the edge
##           POKE d > +0.03 (terrain covers the walk edge), GAP d < -0.30 (the piece edge floats over the ground)
##   inner = 4 points per ground triangle: terrain above the surface = shows through (z-fight / poke)
## Sea cells are skipped (sea walls meet water). Writes zz_terrain_pts.csv (u, v, kind, d) for the picture.
## Input: res://terrain_grid.json + .f32 + terrain_sea.u8 in the preview project root, exported from terrain_grid.npz:
##   python3 -c "import numpy as np,json; b=np.load('map_dc/coronado/city_kit/zoning/terrain_grid.npz'); H=b['heights'].astype('<f4');
##     H.tofile('<pv>/terrain_grid.f32'); b['sea'].astype(np.uint8).tofile('<pv>/terrain_sea.u8'); json.dump({'u0':float(b['u0']),
##     'v0':float(b['v0']),'step':float(b['step']),'nx':H.shape[1],'ny':H.shape[0]},open('<pv>/terrain_grid.json','w'))"
## 17 Nov result (assembled city, 445 pieces): poke 2 (beach, 4 cm), shows-through 0, edge drops > 0.3 m 1,325 of which
## 1,192 are steps inside the pieces (terrace walls, kerbs) and 133 lie in the locked pilot's hill yards (behind houses).
const K := preload("res://tools/city/pilot/kit_lib.gd")
var H := PackedFloat32Array(); var SEA := PackedByteArray()
var u0 := 0.0; var v0 := 0.0; var st := 4.0; var nx := 0; var ny := 0

func _init() -> void: _run.call_deferred()

func th(u: float, v: float) -> float:
	var fx := (u - u0) / st; var fy := (v - v0) / st
	var i := clampi(int(floor(fx)), 0, nx - 2); var j := clampi(int(floor(fy)), 0, ny - 2)
	var tx := clampf(fx - i, 0, 1); var ty := clampf(fy - j, 0, 1)
	var a := H[j * nx + i]; var b := H[j * nx + i + 1]; var c := H[(j + 1) * nx + i]; var d := H[(j + 1) * nx + i + 1]
	return lerpf(lerpf(a, b, tx), lerpf(c, d, tx), ty)

func sea_near(u: float, v: float) -> bool:
	var i := clampi(int(round((u - u0) / st)), 1, nx - 2); var j := clampi(int(round((v - v0) / st)), 1, ny - 2)
	for dj in range(-2, 3):
		for di in range(-2, 3):
			var jj := clampi(j + dj, 0, ny - 1); var ii := clampi(i + di, 0, nx - 1)
			if SEA[jj * nx + ii] != 0: return true
	return false

func _run() -> void:
	var m: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://terrain_grid.json"))
	u0 = m.u0; v0 = m.v0; st = m.step; nx = int(m.nx); ny = int(m.ny)
	H = FileAccess.get_file_as_bytes("res://terrain_grid.f32").to_float32_array()
	SEA = FileAccess.get_file_as_bytes("res://terrain_sea.u8")
	var world := Node3D.new(); root.add_child(world)
	var pcs := K.place_layout(world)
	var csv := FileAccess.open("res://zz_terrain_pts.csv", FileAccess.WRITE)
	var tot := {"edge": 0, "poke": 0, "gap": 0, "inner": 0, "show": 0}
	var per := {}
	for pc: Node3D in pcs:
		var g := pc.get_node_or_null("ground") as MeshInstance3D
		if g == null or g.mesh == null: continue
		var xf := g.global_transform
		var ecount := {}; var tris: Array[PackedVector3Array] = []
		for si in g.mesh.get_surface_count():
			var arr := g.mesh.surface_get_arrays(si)
			var vs: PackedVector3Array = arr[Mesh.ARRAY_VERTEX]; var ix: PackedInt32Array = arr[Mesh.ARRAY_INDEX]
			var wv := PackedVector3Array(); wv.resize(vs.size())
			for k in vs.size(): wv[k] = xf * vs[k]
			var nt := ix.size() / 3 if ix.size() > 0 else vs.size() / 3
			for t in nt:
				var a := wv[ix[3 * t] if ix.size() > 0 else 3 * t]; var b := wv[ix[3 * t + 1] if ix.size() > 0 else 3 * t + 1]; var c := wv[ix[3 * t + 2] if ix.size() > 0 else 3 * t + 2]
				var nrm := (b - a).cross(c - a)
				if nrm.length() < 1e-6 or absf(nrm.normalized().y) < 0.5: continue     # vertical kerb faces: not ground
				tris.append(PackedVector3Array([a, b, c]))
				for e in [[a, b], [b, c], [c, a]]:
					var k1 := Vector3i(roundi(e[0].x * 50), roundi(e[0].y * 20), roundi(e[0].z * 50)); var k2 := Vector3i(roundi(e[1].x * 50), roundi(e[1].y * 20), roundi(e[1].z * 50))
					var key := [k1, k2] if (k1.x < k2.x or (k1.x == k2.x and k1.z < k2.z)) else [k2, k1]
					var ks := str(key)
					if ecount.has(ks): ecount[ks][0] += 1
					else: ecount[ks] = [1, e[0], e[1]]
		var name := String(pc.get_meta(&"piece"))
		var r := {"poke": 0, "gap": 0, "show": 0, "maxpoke": 0.0, "maxgap": 0.0}
		# open edges (used once) are the piece's outline ... but kerb tops sit over kerb faces we skipped: an edge whose
		# other side is a vertical face shows as open too; those are inner steps of the piece, the terrain is not there
		for ks: String in ecount:
			var e: Array = ecount[ks]
			if e[0] != 1: continue
			var a: Vector3 = e[1]; var b: Vector3 = e[2]
			var L := Vector2(b.x - a.x, b.z - a.z).length()
			var n := maxi(1, int(L / 1.0))
			for s in n:
				var p := a.lerp(b, (s + 0.5) / n)
				if sea_near(p.x, p.z): continue
				# is this edge an outline? the ground just outside it must not belong to this piece: probe 0.3 m both sides
				var d := th(p.x, p.z) - p.y
				tot.edge += 1
				if d > 0.03:
					r.poke += 1; tot.poke += 1; r.maxpoke = maxf(r.maxpoke, d); csv.store_line("%.1f,%.1f,poke,%.2f,%s" % [p.x, p.z, d, name])
				elif d < -0.30:
					r.gap += 1; tot.gap += 1; r.maxgap = minf(r.maxgap, d); csv.store_line("%.1f,%.1f,gap,%.2f,%s" % [p.x, p.z, d, name])
		for t: PackedVector3Array in tris:
			for w: Vector3 in [Vector3(1, 1, 1) / 3.0, Vector3(0.6, 0.2, 0.2), Vector3(0.2, 0.6, 0.2), Vector3(0.2, 0.2, 0.6)]:
				var p := t[0] * w.x + t[1] * w.y + t[2] * w.z
				if sea_near(p.x, p.z): continue
				tot.inner += 1
				var d := th(p.x, p.z) - p.y
				if d > 0.0:
					r.show += 1; tot.show += 1; csv.store_line("%.1f,%.1f,show,%.2f,%s" % [p.x, p.z, d, name])
		if r.poke + r.gap + r.show > 0: per[name + "@" + str(pc.position.round())] = r
	csv.close()
	print("TERRAIN_CHK edge samples %d: poke %d, gap %d; inner %d: shows through %d" % [tot.edge, tot.poke, tot.gap, tot.inner, tot.show])
	var keys := per.keys(); keys.sort_custom(func(x, y): return per[x].poke + per[x].gap + per[x].show > per[y].poke + per[y].gap + per[y].show)
	for k in keys.slice(0, 60): print("TERRAIN_PIECE %s %s" % [k, per[k]])
	quit()
