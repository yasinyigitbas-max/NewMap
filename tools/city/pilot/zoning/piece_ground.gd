extends SceneTree
## Rasterise the "ground" mesh of every placed piece (assembled city, grid frame) into a 1 m grid: per cell the LOWEST
## ground surface (point-sampled at the cell centre and at every triangle vertex). Output piece_ground.f32 (NaN = no
## piece) + piece_ground.json. terrain.py reads it: the terrain is fitted to the pieces as built, not to the plan.
## Run in the preview project (real renderer: mesh arrays), then pack it for terrain.py:
##   CITYKIT_LAYOUT_ONLY=1 CITYKIT_LAYOUT_EXTRA=res://map_dc/coronado/city_kit/city_grid_layout.json xvfb-run -a godot --path <pv>
##     --rendering-method mobile --rendering-driver vulkan -s res://tools/city/pilot/zoning/piece_ground.gd
##   python3 -c "import numpy as np,json; m=json.load(open('<pv>/piece_ground.json')); g=np.fromfile('<pv>/piece_ground.f32','<f4')
##     .reshape(m['ny'],m['nx']); np.savez_compressed('map_dc/coronado/city_kit/zoning/piece_ground.npz',u0=m['u0'],v0=m['v0'],step=1.0,ground=g)"
## Rerun it (then terrain.py, bake_game_terrain.py) whenever a placed piece's ground changes or pieces are added.
const K := preload("res://tools/city/pilot/kit_lib.gd")
const U0 := -1600.0; const V0 := -1900.0; const NX := 2900; const NY := 2660      # the terrain box (terrain.py U0..U1)

func _init() -> void: _run.call_deferred()

func _run() -> void:
	var g := PackedFloat32Array(); g.resize(NX * NY); g.fill(INF)
	var world := Node3D.new(); root.add_child(world)
	var pcs := K.place_layout(world)
	var ntri := 0
	for pc: Node3D in pcs:
		var gm := pc.get_node_or_null("ground") as MeshInstance3D
		if gm == null or gm.mesh == null: continue
		var xf := gm.global_transform
		for si in gm.mesh.get_surface_count():
			var arr := gm.mesh.surface_get_arrays(si)
			var vs: PackedVector3Array = arr[Mesh.ARRAY_VERTEX]; var ix: PackedInt32Array = arr[Mesh.ARRAY_INDEX]
			var wv := PackedVector3Array(); wv.resize(vs.size())
			for k in vs.size(): wv[k] = xf * vs[k]
			var nt := ix.size() / 3 if ix.size() > 0 else vs.size() / 3
			for t in nt:
				var a := wv[ix[3 * t] if ix.size() > 0 else 3 * t]; var b := wv[ix[3 * t + 1] if ix.size() > 0 else 3 * t + 1]; var c := wv[ix[3 * t + 2] if ix.size() > 0 else 3 * t + 2]
				var nrm := (b - a).cross(c - a)
				if nrm.length() < 1e-6 or absf(nrm.normalized().y) < 0.5: continue
				ntri += 1
				for p: Vector3 in [a, b, c]:
					var i := int(floor(p.x - U0)); var j := int(floor(p.z - V0))
					if i >= 0 and i < NX and j >= 0 and j < NY: g[j * NX + i] = minf(g[j * NX + i], p.y)
				var i0 := maxi(0, int(floor(minf(a.x, minf(b.x, c.x)) - U0))); var i1 := mini(NX - 1, int(floor(maxf(a.x, maxf(b.x, c.x)) - U0)))
				var j0 := maxi(0, int(floor(minf(a.z, minf(b.z, c.z)) - V0))); var j1 := mini(NY - 1, int(floor(maxf(a.z, maxf(b.z, c.z)) - V0)))
				var d := (b.x - a.x) * (c.z - a.z) - (c.x - a.x) * (b.z - a.z)
				if absf(d) < 1e-9: continue
				for j in range(j0, j1 + 1):
					var pz := V0 + j + 0.5
					for i in range(i0, i1 + 1):
						var px := U0 + i + 0.5
						var l1 := ((b.x - px) * (c.z - pz) - (c.x - px) * (b.z - pz)) / d
						var l2 := ((c.x - px) * (a.z - pz) - (a.x - px) * (c.z - pz)) / d
						var l3 := 1.0 - l1 - l2
						if l1 < -1e-4 or l2 < -1e-4 or l3 < -1e-4: continue
						var y := a.y * l1 + b.y * l2 + c.y * l3
						if y < g[j * NX + i]: g[j * NX + i] = y
	var n := 0
	for k in g.size():
		if g[k] == INF: g[k] = NAN
		else: n += 1
	var f := FileAccess.open("res://piece_ground.f32", FileAccess.WRITE); f.store_buffer(g.to_byte_array()); f.close()
	var m := FileAccess.open("res://piece_ground.json", FileAccess.WRITE)
	m.store_string(JSON.stringify({"u0": U0, "v0": V0, "step": 1.0, "nx": NX, "ny": NY})); m.close()
	print("RASTER pieces=%d tris=%d cells=%d" % [pcs.size(), ntri, n])
	quit()
