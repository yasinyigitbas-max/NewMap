extends SceneTree
## RUNTIME BAKE (18 Nov, Yasin: "do the 4 things"; audit docs/AUDIT_PERF_LIFE_18NOV.md).
## Reads the locked pieces and the layout, NEVER writes a piece. Writes game-ready data to city_kit/runtime/:
##   lib/    every model, collision shape and runtime material ONCE (named by a hash of its content)
##   cells/  one scene per 200 m cell of the grid frame: buildings (near, mid), ground, wear marks, props as batches
##           (near tier: merged into one mesh per material per 64 m, the few heavy models instanced; mid tier: merged
##           per cell), collision, the parking stalls. Each prop still switches tier at its own distance (the shaders in
##           city_kit/shaders/rt collapse a prop outside its distance window).
##           Yasin 18 Nov: "keep draw calls as low as possible", triangles second: so batches are big. Finer batches
##           were measured and send fewer triangles but cost draws (near per piece batch: +45 draws, -60k triangles).
##   far/far_world.scn  the far tier of the WHOLE island in a few meshes; always loaded, so a streamed-out piece
##           still shows on the skyline.
##   manifest.json  which pieces (sha256) each cell was baked from: `--check` lists cells that are out of date.
## Run (real renderer: MultiMesh data lives in it), repo root:
##   xvfb-run -a godot --path . --rendering-method mobile --rendering-driver vulkan -s res://tools/city/bake/bake_runtime.gd -- --all
##   ... -- --area=60,-600,520      only the cells whose rectangle is within 520 m of (60, -600); the far world is always whole
##   ... -- --check                 compare the manifest with the pieces, write nothing
##   options: --tint (trial: a paint tint per building from its position)   --out=res://... (another runtime folder)
const ColData := preload("res://tools/city/bake/col_data.gd")
const PIECES := "res://map_dc/coronado/city_kit/pieces/"
const LAYOUT := "res://map_dc/coronado/city_kit/city_grid_layout.json"
const SH := "res://map_dc/coronado/city_kit/shaders/rt/"
const TEX := "res://map_dc/coronado/city_kit/runtime_tex/"      ## texture arrays (tools/city/bake/make_arrays.py)
const VERSION := 6
const CELL := 200.0
const SUB_NEAR := 64.0
const SUB_MID := 200.0
const CHUNK_FAR := 1000.0
const NEAR_END := 60.0       ## near tier: 0 .. 60 m from the prop; mid: 60 .. 220; far world: 220 ..
const MID_END := 220.0
const MERGE_TRIS := 1000     ## near props up to this many triangles are merged per 64 m; heavier ones stay instanced
## Triangle (concave) collision is cut into small pieces. The physics engine builds a triangle shape in one go when the
## shape is loaded, and nothing else can ask the physics server meanwhile: a piece's ground came as ONE shape of 7,000 to
## 25,000 triangles, and the main thread waited 38-48 ms for it on the PC (phone runs of 18 Nov: 76-181 ms frames while
## cells load). With pieces of COL_CHUNK_TRIS the longest wait is one small piece.
const COL_CHUNK_TRIS := 400
const COL_GRID := 16.0        ## first cut: a grid in the shape's own space (so copies of a piece still share their pieces in lib/)
const COL_BODY_TRIS := 1600   ## a static body carries at most this many triangles (and 24 shapes): attaching stays small too
const FAR_MIN_SIZE := 2.5    ## a prop smaller than this in every direction gets no far version (under a pixel)
## Tier hand-over (19 Nov, shaders/rt/rt_tier.gdshaderinc): the shaders cut each tier exactly at its window, and with the
## tier switch on they overlap two tiers over a band of up to BAND_MAX metres. Node ranges are BAND_MAX / 2 wider than
## the windows so the band is drawn (the kit's 2 m hysteresis margins gave the same overlap before: 56-64 m, 218-224 m).
const BAND_MAX := 8.0
## Far ground (19 Nov): every cell's ground as a 200 m patch on this grid, drawn with a top-down picture of the real ground
const FG_GRID := 20.0
const FG_TEXEL := 1.25       ## metres a texel of the far ground's picture
const FG_SUPER := 2          ## the picture is rendered this many times larger and scaled down (thin kerbs and lines)

var out := "res://map_dc/coronado/city_kit/runtime/"
var tint_on := false
var area := []               # [x, z, r] or empty = all
var cells := {}              # Vector2i -> cell record
var far := {}                # [chunk Vector2i, matkey] -> Array of entries
var far_mats := {}           # matkey -> Material
var mesh_keys := {}          # instance id -> key
var lib_mesh := {}           # key (+ "_m") -> Mesh (lib resource)
var lib_shape := {}          # key -> ColData of the cell being written (emptied for every cell)
var split_cache := {}        # concave shape instance id -> Array of [piece of it (ConcavePolygonShape3D), its centre]
var arr_cache := {}          # instance id -> surface arrays
var mats := {}               # signature -> Material
var atlas_img := {}          # texture path -> Image (linear lookups for the far props' flat colours)
var stat := {"props_in": 0, "merged": 0, "instanced": 0, "pass": 0, "far": 0, "far_dropped": 0, "skipped_cell": 0, "buildings": 0, "shapes": 0, "col_split": 0, "col_pieces": 0, "col_piece_max": 0, "trees_out": 0, "tree_cols_out": 0, "wells_filled": 0, "wells_left": 0}
var manifest_cells := {}
var warm := {}               # material path + kind -> a small node that draws it once (lib/warm.scn)
var keep := {}               # every shared material a cell uses (the streamer holds them for its whole life)
var layers := {}             # arrays.json: set name -> [texture path per layer]
var fg_src: Array = []       # every piece ground of the island (whatever --area says): [mesh, world transform, cell]
var fg_node: Node3D = null   # the far ground, made before the far world (it goes into far_world.scn)
var fg_on := true            # --nofarground: bake without it
## TREES OUT (19 Nov, Yasin: "we can turn off the trees entirely from the current builders and place your hand placed
## trees instead"; "can that same bake fill every tree well once they are gone too? with the same material as around
## the well"). --notrees: every tree_* / palm_* batch of every piece is left out of the bake (all tiers, and the trunk's
## collision), except in the hand-placed tree pieces (t_*). The pieces are not touched. A tree well whose tree went is
## paved over: its soil is raised to the rim and drawn in the rim's material, the rim's inner face goes, and the ground
## collision is lifted with it (--keepwells: wells stay open). A well in which a t_* tree stands is not filled.
var no_trees := false
var well_fill := true
var cur_strip := false       # the piece being routed loses its trees
var cur_trees := {}          # its trees, world: Vector2i (0.5 m bucket) -> Array of Vector2 (x, z)
var cur_ground := {}         # its ground meshes with the wells filled: source mesh instance id -> Mesh
var cur_wells: Array = []    # the wells filled in it, world: [centre on the rim plane, radius, slope x, slope z]
var kept_trees := {}         # the hand-placed trees (t_* pieces), world: Vector2i (2 m bucket) -> Array of Vector2
var gap_col := true          # --nogapcol: buildings get only their kit "col" shell (as before 20 Nov)
var gap_cache := {}          # kit folder -> Array of [ConvexPolygonShape3D, Transform3D] (building space)
var fill_cache := {}         # ground mesh key + its trees -> [Mesh, wells in the mesh's own frame]

func _init() -> void: _run.call_deferred()

# ---------------------------------------------------------------- helpers
func _cell_of(p: Vector3) -> Vector2i: return Vector2i(floori(p.x / CELL), floori(p.z / CELL))

func _cell_wanted(c: Vector2i) -> bool:
	if area.is_empty(): return true
	var x0 := c.x * CELL; var z0 := c.y * CELL
	var dx := maxf(maxf(x0 - float(area[0]), float(area[0]) - (x0 + CELL)), 0.0); var dz := maxf(maxf(z0 - float(area[1]), float(area[1]) - (z0 + CELL)), 0.0)
	return sqrt(dx * dx + dz * dz) <= float(area[2])

func _cell(c: Vector2i) -> Dictionary:
	if not cells.has(c): cells[c] = {"bld": [], "ground": [], "wear": [], "misc": [], "merged": {}, "inst": {}, "col": [], "stalls": [], "lights": [], "pieces": {}}
	return cells[c]

func _mesh_key(m: Mesh) -> String:
	var id := m.get_instance_id()
	if mesh_keys.has(id): return mesh_keys[id]
	var k := ""
	if m is ArrayMesh:
		for si in m.get_surface_count():
			var d: Dictionary = RenderingServer.mesh_get_surface(m.get_rid(), si)
			k += "%d:%d:%d:%d:%d;" % [int(d.get("vertex_count", 0)), int(d.get("index_count", 0)), hash(d.get("vertex_data", PackedByteArray())), hash(d.get("attribute_data", PackedByteArray())), hash(d.get("index_data", PackedByteArray()))]
	else: k = m.get_class() + str(m.get_aabb())
	k = k.md5_text().substr(0, 12)
	mesh_keys[id] = k
	return k

## the model once in lib/: bare (its materials stripped, the batch brings the runtime material) or with its materials
func _lib_mesh(m: Mesh, keep_mats := false) -> Mesh:
	var k := _mesh_key(m) + ("_m" if keep_mats else "")
	if lib_mesh.has(k): return lib_mesh[k]
	var path := out + "lib/m_%s.res" % k
	if not ResourceLoader.exists(path):
		var copy: Mesh = m.duplicate()
		if not keep_mats and copy is ArrayMesh:
			for si in copy.get_surface_count(): copy.surface_set_material(si, null)
			if (copy as ArrayMesh).shadow_mesh:
				var sm: ArrayMesh = (copy as ArrayMesh).shadow_mesh.duplicate()
				for si in sm.get_surface_count(): sm.surface_set_material(si, null)
				(copy as ArrayMesh).shadow_mesh = sm
		ResourceSaver.save(copy, path, ResourceSaver.FLAG_COMPRESS)
	lib_mesh[k] = load(path)
	return lib_mesh[k]

## a piece's ground with all its surfaces joined into one (for rt_ground.gdshader), once in lib/; null if it has a
## surface the ground texture array does not cover
func _lib_ground(gm: Mesh) -> Mesh:
	var k := _mesh_key(gm) + "_g1"
	if lib_mesh.has(k): return lib_mesh[k]
	var path := out + "lib/m_%s.res" % k
	if not ResourceLoader.exists(path):
		for si in gm.get_surface_count():
			var sm := gm.surface_get_material(si) as BaseMaterial3D
			if sm == null or _layer("ground", sm.albedo_texture) < 0: lib_mesh[k] = null; return null
		var GV := PackedVector3Array(); var GN := PackedVector3Array(); var GUV := PackedVector2Array(); var GU2 := PackedVector2Array(); var GC := PackedColorArray(); var GI := PackedInt32Array()
		for si in gm.get_surface_count():
			var sm2 := gm.surface_get_material(si) as BaseMaterial3D
			var ga := gm.surface_get_arrays(si); var base := GV.size(); var n := (ga[Mesh.ARRAY_VERTEX] as PackedVector3Array).size()
			GV.append_array(ga[Mesh.ARRAY_VERTEX]); GN.append_array(ga[Mesh.ARRAY_NORMAL]); GUV.append_array(ga[Mesh.ARRAY_TEX_UV])
			var u2 := PackedVector2Array(); u2.resize(n); u2.fill(Vector2(float(_layer("ground", sm2.albedo_texture)), sm2.roughness)); GU2.append_array(u2)
			var col := PackedColorArray(); col.resize(n); col.fill(sm2.albedo_color.srgb_to_linear()); GC.append_array(col)
			for ix: int in (ga[Mesh.ARRAY_INDEX] as PackedInt32Array): GI.append(ix + base)
		var garr := []; garr.resize(Mesh.ARRAY_MAX)
		garr[Mesh.ARRAY_VERTEX] = GV; garr[Mesh.ARRAY_NORMAL] = GN; garr[Mesh.ARRAY_TEX_UV] = GUV; garr[Mesh.ARRAY_TEX_UV2] = GU2; garr[Mesh.ARRAY_COLOR] = GC; garr[Mesh.ARRAY_INDEX] = GI
		var gam := ArrayMesh.new(); gam.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, garr)
		ResourceSaver.save(gam, path, ResourceSaver.FLAG_COMPRESS)
	lib_mesh[k] = load(path)
	return lib_mesh[k]

# ---------------------------------------------------------------- trees out, wells filled (--notrees)
## the trees of a piece instance that the bake leaves out, and its ground with their wells paved over
func _scan_trees(inst: Node3D) -> void:
	cur_trees.clear(); cur_ground.clear(); cur_wells.clear()
	var pts: Array = []
	for mmi: MultiMeshInstance3D in inst.find_children("*_near", "MultiMeshInstance3D", true, false):
		var nm := String(mmi.name)
		if mmi.multimesh == null or not (nm.begins_with("tree_") or nm.begins_with("palm_")): continue
		for i in mmi.multimesh.instance_count:
			var p: Vector3 = (mmi.global_transform * mmi.multimesh.get_instance_transform(i)).origin
			pts.append(p)
			var k := Vector2i(floori(p.x * 2.0), floori(p.z * 2.0))
			if not cur_trees.has(k): cur_trees[k] = []
			(cur_trees[k] as Array).append(Vector2(p.x, p.z))
	stat.trees_out += pts.size()
	if pts.is_empty() or not well_fill: return
	for g: MeshInstance3D in inst.find_children("ground", "MeshInstance3D", true, false):
		if g.mesh == null: continue
		var inv := g.global_transform.affine_inverse()
		var loc: Array = []
		for p2: Vector3 in pts:
			if _kept_tree_at(p2): continue      # a hand-placed tree stands here: its well stays open
			loc.append(inv * p2)
		if loc.is_empty(): continue
		var res: Array = _fill_wells(g.mesh, loc)
		cur_ground[g.mesh.get_instance_id()] = res[0]
		for w: Array in res[1]:
			var gr: Vector3 = g.global_transform.basis * Vector3(float(w[2]), 0.0, float(w[3]))
			cur_wells.append([g.global_transform * (w[0] as Vector3), float(w[1]), gr.x, gr.z])

func _tree_at(p: Vector3) -> bool:
	var k := Vector2i(floori(p.x * 2.0), floori(p.z * 2.0))
	for dx in range(-1, 2):
		for dz in range(-1, 2):
			var kk := k + Vector2i(dx, dz)
			if not cur_trees.has(kk): continue
			for q: Vector2 in cur_trees[kk]:
				if q.distance_squared_to(Vector2(p.x, p.z)) < 0.09: return true
	return false

func _kept_tree_at(p: Vector3) -> bool:
	var k := Vector2i(floori(p.x / 2.0), floori(p.z / 2.0))
	for dx in range(-1, 2):
		for dz in range(-1, 2):
			var kk := k + Vector2i(dx, dz)
			if not kept_trees.has(kk): continue
			for q: Vector2 in kept_trees[kk]:
				if q.distance_squared_to(Vector2(p.x, p.z)) < 0.49: return true
	return false

func _keep_trees(inst: Node3D) -> void:
	for mmi: MultiMeshInstance3D in inst.find_children("*_near", "MultiMeshInstance3D", true, false):
		var nm := String(mmi.name)
		if mmi.multimesh == null or not (nm.begins_with("tree_") or nm.begins_with("palm_")): continue
		for i in mmi.multimesh.instance_count:
			var p: Vector3 = (mmi.global_transform * mmi.multimesh.get_instance_transform(i)).origin
			var k := Vector2i(floori(p.x / 2.0), floori(p.z / 2.0))
			if not kept_trees.has(k): kept_trees[k] = []
			(kept_trees[k] as Array).append(Vector2(p.x, p.z))

func _k3(p: Vector3) -> Vector3i: return Vector3i(roundi(p.x * 1000.0), roundi(p.y * 1000.0), roundi(p.z * 1000.0))

## A piece's ground with the wells of the given trees (the mesh's own frame) paved over. A well = soil ("mulch")
## triangles that all lie within 1 m of a trunk, with the trunk near their middle, whose edge vertices have a hard,
## up-facing vertex right above them (the rim, 2-15 cm up). A trunk in a bed or on grass matches none of that and
## nothing changes there. Returns [mesh, [[centre on the rim plane, radius, slope x, slope z], ...]].
func _fill_wells(gm: Mesh, trees: Array) -> Array:
	if not (gm is ArrayMesh): return [gm, []]
	var hk := PackedInt32Array()
	for t: Vector3 in trees: hk.append(roundi(t.x * 100.0)); hk.append(roundi(t.z * 100.0))
	var key := _mesh_key(gm) + ":" + str(hash(hk))
	if fill_cache.has(key): return fill_cache[key]
	var ns := gm.get_surface_count(); var soil := -1
	for si in ns:
		var sm := gm.surface_get_material(si) as BaseMaterial3D
		if gm.surface_get_name(si) == "mulch" or (sm and sm.albedo_texture and sm.albedo_texture.resource_path.contains("ground037")): soil = si
	if soil < 0: fill_cache[key] = [gm, []]; return fill_cache[key]
	var arrs: Array = []; var idx: Array = []
	for si in ns:
		var a: Array = gm.surface_get_arrays(si); arrs.append(a)
		var ix := PackedInt32Array()
		if a[Mesh.ARRAY_INDEX] != null: ix = a[Mesh.ARRAY_INDEX]
		if ix.is_empty():
			ix.resize((a[Mesh.ARRAY_VERTEX] as PackedVector3Array).size())
			for q in ix.size(): ix[q] = q
		idx.append(ix)
	# the 2 m squares round the trunks: everything else of the mesh is skipped with one lookup
	var near := {}
	for t2: Vector3 in trees:
		for dx in range(-1, 2):
			for dz in range(-1, 2): near[Vector2i(floori(t2.x / 2.0) + dx, floori(t2.z / 2.0) + dz)] = true
	# soil triangles near a trunk, by 2 m square
	var SV: PackedVector3Array = arrs[soil][Mesh.ARRAY_VERTEX]; var SI: PackedInt32Array = idx[soil]
	var sgrid := {}
	for t3 in SI.size() / 3:
		var c3: Vector3 = (SV[SI[t3 * 3]] + SV[SI[t3 * 3 + 1]] + SV[SI[t3 * 3 + 2]]) / 3.0
		var k3 := Vector2i(floori(c3.x / 2.0), floori(c3.z / 2.0))
		if not near.has(k3): continue
		if not sgrid.has(k3): sgrid[k3] = []
		(sgrid[k3] as Array).append(t3)
	if sgrid.is_empty(): fill_cache[key] = [gm, []]; return fill_cache[key]
	# hard, up-facing vertices near a trunk: 2 mm buckets of x, z -> [surface, vertex]
	var hard := {}
	for si in ns:
		if si == soil: continue
		var HV: PackedVector3Array = arrs[si][Mesh.ARRAY_VERTEX]; var HN: PackedVector3Array = arrs[si][Mesh.ARRAY_NORMAL]
		for v in HV.size():
			var hp: Vector3 = HV[v]
			if not near.has(Vector2i(floori(hp.x / 2.0), floori(hp.z / 2.0))) or HN[v].y < 0.7: continue
			var kh := Vector2i(roundi(hp.x * 500.0), roundi(hp.z * 500.0))
			if not hard.has(kh): hard[kh] = []
			(hard[kh] as Array).append([si, v])
	var gone := {}                # soil triangles that become paving
	var add: Array = []           # [dst surface, twin vertex (attributes to copy), [3 positions], [3 uvs], normal]
	var wells: Array = []
	for t4: Vector3 in trees:
		var cand: Array = []; var bed := false
		var kt := Vector2i(floori(t4.x / 2.0), floori(t4.z / 2.0))
		for dx in range(-1, 2):
			for dz in range(-1, 2):
				var kk := kt + Vector2i(dx, dz)
				if not sgrid.has(kk): continue
				for ti: int in sgrid[kk]:
					if gone.has(ti): continue
					var inside := 0
					for e in 3:
						var pv: Vector3 = SV[SI[ti * 3 + e]]
						if Vector2(pv.x - t4.x, pv.z - t4.z).length_squared() <= 1.0: inside += 1
					if inside == 3: cand.append(ti)
					elif inside > 0: bed = true
		if cand.is_empty(): continue                       # the trunk stands in grass, gravel or a big bed
		if bed: stat.wells_left += 1; continue
		# every soil vertex of the patch and the rim vertex above it
		var tw: Array = []; var free: Array = []          # [soil position, surface, vertex] / soil positions without one
		var seen := {}
		for ti2: int in cand:
			for e2 in 3:
				var sp: Vector3 = SV[SI[ti2 * 3 + e2]]
				var ks := _k3(sp)
				if seen.has(ks): continue
				seen[ks] = true
				var best: Array = []; var by := 1.0e9
				var kb := Vector2i(roundi(sp.x * 500.0), roundi(sp.z * 500.0))
				for bx in range(-1, 2):
					for bz in range(-1, 2):
						var kq := kb + Vector2i(bx, bz)
						if not hard.has(kq): continue
						for hv: Array in hard[kq]:
							var q3: Vector3 = (arrs[int(hv[0])][Mesh.ARRAY_VERTEX] as PackedVector3Array)[int(hv[1])]
							if absf(q3.x - sp.x) > 0.002 or absf(q3.z - sp.z) > 0.002: continue
							var up := q3.y - sp.y
							if up > 0.02 and up < 0.15 and up < by: by = up; best = hv
				if best.is_empty(): free.append(sp)
				else: tw.append([sp, int(best[0]), int(best[1])])
		if tw.size() < 3: stat.wells_left += 1; continue
		# the rim plane (least squares over the rim vertices) and the well's centre and radius
		var cen := Vector3.ZERO; var votes := {}
		for w: Array in tw:
			cen += (arrs[int(w[1])][Mesh.ARRAY_VERTEX] as PackedVector3Array)[int(w[2])]
			votes[int(w[1])] = int(votes.get(int(w[1]), 0)) + 1
		cen /= float(tw.size())
		var dst := -1; var dn := 0
		for vs: int in votes:
			if int(votes[vs]) > dn: dn = int(votes[vs]); dst = vs
		var sxx := 0.0; var sxz := 0.0; var szz := 0.0; var sxy := 0.0; var szy := 0.0; var rad := 0.0
		for w2: Array in tw:
			var rp: Vector3 = (arrs[int(w2[1])][Mesh.ARRAY_VERTEX] as PackedVector3Array)[int(w2[2])] - cen
			sxx += rp.x * rp.x; sxz += rp.x * rp.z; szz += rp.z * rp.z; sxy += rp.x * rp.y; szy += rp.z * rp.y
			rad = maxf(rad, Vector2(rp.x, rp.z).length())
		var det := sxx * szz - sxz * sxz
		var gx := 0.0; var gz := 0.0
		if absf(det) > 1.0e-6: gx = (sxy * szz - szy * sxz) / det; gz = (szy * sxx - sxy * sxz) / det
		var ok := Vector2(t4.x - cen.x, t4.z - cen.z).length() < 0.5 and rad < 1.2
		for fp: Vector3 in free:
			if Vector2(fp.x - cen.x, fp.z - cen.z).length() > rad * 0.6: ok = false      # an edge vertex with no rim over it
		# the rim surface's texture mapping over the well (u and v are planes over x, z)
		var DV: PackedVector3Array = arrs[dst][Mesh.ARRAY_VERTEX]
		var DU := PackedVector2Array()
		if arrs[dst][Mesh.ARRAY_TEX_UV] != null: DU = arrs[dst][Mesh.ARRAY_TEX_UV]
		var ucen := Vector2.ZERO; var dcen := Vector3.ZERO; var un := 0; var twin_v := -1
		if not DU.is_empty():
			for w3: Array in tw:
				if int(w3[1]) != dst: continue
				ucen += DU[int(w3[2])]; dcen += DV[int(w3[2])]; un += 1; twin_v = int(w3[2])
		if un < 3: ok = false
		if not ok: stat.wells_left += 1; continue
		ucen /= float(un); dcen /= float(un)
		var uxx := 0.0; var uxz := 0.0; var uzz := 0.0; var uxu := 0.0; var uzu := 0.0; var uxv := 0.0; var uzv := 0.0
		for w5: Array in tw:
			if int(w5[1]) != dst: continue
			var dp: Vector3 = DV[int(w5[2])] - dcen; var du: Vector2 = DU[int(w5[2])] - ucen
			uxx += dp.x * dp.x; uxz += dp.x * dp.z; uzz += dp.z * dp.z
			uxu += dp.x * du.x; uzu += dp.z * du.x; uxv += dp.x * du.y; uzv += dp.z * du.y
		var udet := uxx * uzz - uxz * uxz
		if absf(udet) < 1.0e-6: stat.wells_left += 1; continue
		var ua := Vector2((uxu * uzz - uzu * uxz) / udet, (uzu * uxx - uxu * uxz) / udet)      # d u / d x, d u / d z
		var va := Vector2((uxv * uzz - uzv * uxz) / udet, (uzv * uxx - uxv * uxz) / udet)
		var top := {}                 # soil position -> its rim position
		for w6: Array in tw:
			top[_k3(w6[0] as Vector3)] = (arrs[int(w6[1])][Mesh.ARRAY_VERTEX] as PackedVector3Array)[int(w6[2])]
		var nrm := Vector3(-gx, 1.0, -gz).normalized()
		for ti3: int in cand:
			gone[ti3] = true
			var ps: Array = []; var us: Array = []
			for e3 in 3:
				var s7: Vector3 = SV[SI[ti3 * 3 + e3]]
				var k7 := _k3(s7)
				var np := Vector3(s7.x, cen.y + gx * (s7.x - cen.x) + gz * (s7.z - cen.z), s7.z)
				if top.has(k7): np = top[k7]
				ps.append(np)
				us.append(ucen + Vector2(ua.x * (np.x - dcen.x) + ua.y * (np.z - dcen.z), va.x * (np.x - dcen.x) + va.y * (np.z - dcen.z)))
			add.append([dst, twin_v, ps, us, nrm])
		wells.append([cen, rad, gx, gz])
	if wells.is_empty(): fill_cache[key] = [gm, []]; return fill_cache[key]
	# the soil loses the wells' triangles
	var keep_i := PackedInt32Array()
	for t5 in SI.size() / 3:
		if gone.has(t5): continue
		keep_i.append(SI[t5 * 3]); keep_i.append(SI[t5 * 3 + 1]); keep_i.append(SI[t5 * 3 + 2])
	idx[soil] = keep_i
	# the rim's inner face goes: upright triangles wholly inside a filled well
	var wgrid := {}
	for wi in wells.size():
		var wc: Vector3 = wells[wi][0]
		for dx in range(-1, 2):
			for dz in range(-1, 2):
				var kw := Vector2i(floori(wc.x / 2.0) + dx, floori(wc.z / 2.0) + dz)
				if not wgrid.has(kw): wgrid[kw] = []
				(wgrid[kw] as Array).append(wi)
	for si in ns:
		if si == soil: continue
		var RV: PackedVector3Array = arrs[si][Mesh.ARRAY_VERTEX]; var RI: PackedInt32Array = idx[si]
		var out_i := PackedInt32Array(); var cut := 0
		for t6 in RI.size() / 3:
			var a6: Vector3 = RV[RI[t6 * 3]]; var b6: Vector3 = RV[RI[t6 * 3 + 1]]; var c6: Vector3 = RV[RI[t6 * 3 + 2]]
			var drop := false
			var k6 := Vector2i(floori(a6.x / 2.0), floori(a6.z / 2.0))
			if wgrid.has(k6):
				var n6 := (b6 - a6).cross(c6 - a6)
				if n6.length_squared() > 1.0e-12 and absf(n6.normalized().y) < 0.3:
					for wi2: int in wgrid[k6]:
						var wc2: Vector3 = wells[wi2][0]; var wr := float(wells[wi2][1]) + 0.004
						var all_in := true
						for q6: Vector3 in [a6, b6, c6]:
							if Vector2(q6.x - wc2.x, q6.z - wc2.z).length() > wr or q6.y > wc2.y + 0.1 or q6.y < wc2.y - 0.25: all_in = false
						if all_in: drop = true
			if drop: cut += 1; continue
			out_i.append(RI[t6 * 3]); out_i.append(RI[t6 * 3 + 1]); out_i.append(RI[t6 * 3 + 2])
		if cut > 0: idx[si] = out_i
	# the new paving: added to the rim's surface, every other attribute copied from a rim vertex
	for ad: Array in add:
		var d := int(ad[0]); var tv := int(ad[1]); var da: Array = arrs[d]
		var base := (da[Mesh.ARRAY_VERTEX] as PackedVector3Array).size()
		for e4 in 3:
			for at in Mesh.ARRAY_MAX:
				if da[at] == null or at == Mesh.ARRAY_INDEX: continue
				if at == Mesh.ARRAY_VERTEX:
					var av: PackedVector3Array = da[at]; av.append((ad[2] as Array)[e4]); da[at] = av
				elif at == Mesh.ARRAY_NORMAL:
					var an: PackedVector3Array = da[at]; an.append(ad[4]); da[at] = an
				elif at == Mesh.ARRAY_TEX_UV:
					var au: PackedVector2Array = da[at]; au.append((ad[3] as Array)[e4]); da[at] = au
				elif at == Mesh.ARRAY_TANGENT:
					var atn: PackedFloat32Array = da[at]
					for q7 in 4: atn.append(atn[tv * 4 + q7])
					da[at] = atn
				elif at == Mesh.ARRAY_COLOR:
					var ac: PackedColorArray = da[at]; ac.append(ac[tv]); da[at] = ac
				elif at == Mesh.ARRAY_TEX_UV2:
					var a2: PackedVector2Array = da[at]; a2.append(a2[tv]); da[at] = a2
		var di: PackedInt32Array = idx[d]; di.append(base); di.append(base + 1); di.append(base + 2); idx[d] = di
	var nm := ArrayMesh.new()
	for si in ns:
		if (idx[si] as PackedInt32Array).is_empty(): continue
		var oa: Array = arrs[si]; oa[Mesh.ARRAY_INDEX] = idx[si]
		nm.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, oa)
		nm.surface_set_material(nm.get_surface_count() - 1, gm.surface_get_material(si))
		nm.surface_set_name(nm.get_surface_count() - 1, gm.surface_get_name(si))
	stat.wells_filled += wells.size()
	fill_cache[key] = [nm, wells]
	return fill_cache[key]

## the ground collision under the filled wells of this piece: the soil lifted to the rim plane, the rim's face gone
func _lift_wells(s: ConcavePolygonShape3D, xf: Transform3D) -> ConcavePolygonShape3D:
	var inv := xf.affine_inverse(); var wl: Array = []; var grid := {}
	for w: Array in cur_wells:
		var c: Vector3 = inv * (w[0] as Vector3); var g: Vector3 = inv.basis * Vector3(float(w[2]), 0.0, float(w[3]))
		var r := float(w[1]) + 0.004
		for gx in range(floori((c.x - r) / 2.0), floori((c.x + r) / 2.0) + 1):
			for gz in range(floori((c.z - r) / 2.0), floori((c.z + r) / 2.0) + 1):
				var k := Vector2i(gx, gz)
				if not grid.has(k): grid[k] = []
				(grid[k] as Array).append(wl.size())
		wl.append([c, r * r, g.x, g.z])
	var f := s.get_faces(); var o := PackedVector3Array(); var moved := 0
	for t in f.size() / 3:
		var tri: Array = [f[t * 3], f[t * 3 + 1], f[t * 3 + 2]]; var hit := false
		for e in 3:
			var p: Vector3 = tri[e]
			var kp := Vector2i(floori(p.x / 2.0), floori(p.z / 2.0))
			if not grid.has(kp): continue
			for wi: int in grid[kp]:
				var wc: Vector3 = wl[wi][0]
				var dx := p.x - wc.x; var dz := p.z - wc.z
				if dx * dx + dz * dz > float(wl[wi][1]): continue
				var py := wc.y + float(wl[wi][2]) * dx + float(wl[wi][3]) * dz
				if p.y < py - 0.005 and p.y > py - 0.25: tri[e] = Vector3(p.x, py, p.z); hit = true
		if hit:
			moved += 1
			if ((tri[1] as Vector3) - (tri[0] as Vector3)).cross((tri[2] as Vector3) - (tri[0] as Vector3)).length_squared() < 1.0e-10: continue
		o.append(tri[0]); o.append(tri[1]); o.append(tri[2])
	if moved == 0: return s
	var nsh := ConcavePolygonShape3D.new(); nsh.backface_collision = s.backface_collision; nsh.set_faces(o)
	return nsh

## A concave shape as pieces of at most COL_CHUNK_TRIS triangles: [[shape, centre], ...]. Each piece's triangles are
## stored round its own centre, so the CollisionShape3D that carries it sits where the piece is (the streamer attaches
## the nearest collision first, and bodies are grouped by place).
## `snap` (the ground, given in WORLD space by _body): the centre is a whole metre. A shared corner of two neighbouring
## pieces is then the same float in both (corner - centre and centre + that are exact for whole-metre centres), so the
## seam between them is closed. Before (19 Nov, collision_holes.gd: 70 of the 89 holes) every piece was re-centred on
## its own odd centre in the piece's frame and turned by the piece's yaw: the same corner came out a few hundredths of a
## millimetre apart in two pieces, and a ray straight down onto the seam (a lane's centre line at x = 480.000, a cell
## border) went through between them.
func _split_concave(s: ConcavePolygonShape3D, snap := false) -> Array:
	var id := s.get_instance_id()
	if not snap and split_cache.has(id): return split_cache[id]
	var f := s.get_faces(); var n := f.size() / 3
	var cen := PackedVector3Array(); cen.resize(n)
	for t in n: cen[t] = (f[t * 3] + f[t * 3 + 1] + f[t * 3 + 2]) / 3.0
	var bins := {}
	for t in n:
		var k := Vector2i(floori(cen[t].x / COL_GRID), floori(cen[t].z / COL_GRID)) if n > COL_CHUNK_TRIS else Vector2i.ZERO
		if not bins.has(k): bins[k] = []
		(bins[k] as Array).append(t)      # (plain arrays: a packed array kept in a dictionary is copied when taken out)
	var groups: Array = bins.values()
	var i := 0
	while i < groups.size():      # a grid square still too heavy: halve it across its longer side until it is not
		var g: Array = groups[i]
		if g.size() <= COL_CHUNK_TRIS: i += 1; continue
		var lo := cen[int(g[0])]; var hi := lo
		for t: int in g: lo = lo.min(cen[t]); hi = hi.max(cen[t])
		var ax := 0 if (hi.x - lo.x) >= (hi.z - lo.z) else 2
		var order: Array = []
		for t: int in g: order.append([cen[t][ax], t])
		order.sort_custom(func(a: Array, b: Array) -> bool: return a[0] < b[0])
		var left: Array = []; var right: Array = []; var half := order.size() / 2
		for j in order.size():
			if j < half: left.append(int(order[j][1]))
			else: right.append(int(order[j][1]))
		groups[i] = left; groups.append(right)
	var res: Array = []
	for g2: Array in groups:
		if g2.is_empty(): continue
		var lo2 := f[int(g2[0]) * 3]; var hi2 := lo2
		for t: int in g2:
			for v in 3: lo2 = lo2.min(f[t * 3 + v]); hi2 = hi2.max(f[t * 3 + v])
		var c := (lo2 + hi2) * 0.5
		if snap: c = c.floor()
		var pf := PackedVector3Array(); pf.resize(g2.size() * 3)
		for j in g2.size():
			for v in 3: pf[j * 3 + v] = f[int(g2[j]) * 3 + v] - c
		var ps := ConcavePolygonShape3D.new(); ps.backface_collision = s.backface_collision; ps.set_faces(pf)
		res.append([ps, c]); stat.col_piece_max = maxi(int(stat.col_piece_max), g2.size())
	if n > COL_CHUNK_TRIS: stat.col_split += 1
	stat.col_pieces += res.size()
	if not snap: split_cache[id] = res
	return res

## A shape as plain data (col_data.gd says why it is not a Shape3D), kept INSIDE the cell's own file: one per cell
## however often the cell uses it. Not a file each in lib/: a cell uses about 600 shapes, and 600 small files read one
## after another took 1-3 s a cell (PC, 18 Nov). Returns null for a kind the kit does not use (sphere, capsule ...):
## counted, reported at the end, left out.
func _lib_shape(s: Shape3D) -> Resource:
	var k := ""; var kind := -1; var data := PackedVector3Array()
	if s is ConvexPolygonShape3D: kind = 1; data = (s as ConvexPolygonShape3D).points; k = "cx" + str(hash(data))
	elif s is ConcavePolygonShape3D: kind = 0; data = (s as ConcavePolygonShape3D).get_faces(); k = "cc" + str(hash(data)) + str((s as ConcavePolygonShape3D).backface_collision)
	elif s is BoxShape3D: kind = 2; data = PackedVector3Array([(s as BoxShape3D).size]); k = "bx" + str((s as BoxShape3D).size)
	else:
		if not stat.has("col_unknown"): stat["col_unknown"] = {}
		stat.col_unknown[s.get_class()] = int(stat.col_unknown.get(s.get_class(), 0)) + 1
		return null
	if lib_shape.has(k): return lib_shape[k]
	var cd: Resource = ColData.new(); cd.kind = kind; cd.data = data
	if s is ConcavePolygonShape3D: cd.backface = (s as ConcavePolygonShape3D).backface_collision
	lib_shape[k] = cd; stat["col_shapes"] = int(stat.get("col_shapes", 0)) + 1
	return cd

## A body-to-be: a plain Node3D that carries the body's layer, mask and its shapes as [ColData, Transform3D]. The
## streamer turns it into a StaticBody3D on the main thread.
func _col_marker(nm: String, layer: int, mask: int) -> Node3D:
	var m := Node3D.new(); m.name = nm
	m.set_meta(&"col", []); m.set_meta(&"layer", layer); m.set_meta(&"mask", mask); m.set_meta(&"w", 0)
	return m

func _col_add(m: Node3D, src: Shape3D, xf: Transform3D) -> void:
	var cd := _lib_shape(src)
	if cd == null: return
	(m.get_meta(&"col") as Array).append([cd, xf]); m.set_meta(&"w", int(m.get_meta(&"w")) + int(cd.call(&"weight")))

## What kind of material a mesh is drawn with, as far as the renderer cares: the shader, the textures, the on / off
## and choice settings, and the vertex layout. Colours and strengths do not count.
func _mat_sig(mesh: Mesh, ov: Material) -> String:
	var parts: Array = []
	for si in mesh.get_surface_count():
		var mt: Material = ov if ov else mesh.surface_get_material(si)
		var s := "fmt%d" % (int((mesh as ArrayMesh).surface_get_format(si)) if mesh is ArrayMesh else 0)
		if mt == null: parts.append(s + "none"); continue
		s += mt.get_class()
		for p: Dictionary in mt.get_property_list():
			if not (int(p.usage) & PROPERTY_USAGE_STORAGE): continue
			var v: Variant = mt.get(p.name)
			if v is Texture or v is Shader: s += "|%s=%s" % [p.name, (v as Resource).resource_path]
			elif v is bool or v is int: s += "|%s=%s" % [p.name, str(v)]
		parts.append(s)
	parts.sort()
	return str(hash("#".join(parts)))

## every file `path` needs, and what those need
func _deps(path: String, seen: Dictionary) -> void:
	for d: String in ResourceLoader.get_dependencies(path):
		var p := d.get_slice("::", 2) if d.contains("::") else d
		if p == "" or seen.has(p): continue
		seen[p] = true
		_deps(p, seen)

func _tex_name(t: Texture2D) -> String: return t.resource_path.get_file().get_basename() if t else "none"

func _save_mat(sig: String, m: Material) -> Material:
	var path := out + "lib/mat_%s.tres" % sig
	ResourceSaver.save(m, path)
	mats[sig] = load(path)
	return mats[sig]

func _layer(set_name: String, t: Texture2D) -> int:
	return (layers[set_name] as Array).find(t.resource_path) if t else -1

## ONE runtime prop material per (two-sided, merged / instanced, tier): the atlas page, the wear level and the
## normal / ORM flags ride with each prop, so page and wear no longer split batches
func _mat_prop(src: ShaderMaterial, two: bool, merged: bool, tier: String) -> Material:
	var sig := "prop%s_%s_%s" % ["_2s" if two else "", "merged" if merged else "inst", tier]
	if mats.has(sig): return mats[sig]
	var m := ShaderMaterial.new(); m.shader = load(SH + "rt_prop_%s%s.gdshader" % ["merged" if merged else "inst", "_2s" if two else ""])
	m.set_shader_parameter(&"albedo_arr", load(TEX + "arr_prop_albedo.png")); m.set_shader_parameter(&"normal_arr", load(TEX + "arr_prop_normal.png")); m.set_shader_parameter(&"orm_arr", load(TEX + "arr_prop_orm.png"))
	m.set_shader_parameter(&"grime_tex", src.get_shader_parameter(&"grime_tex"))
	for u: StringName in [&"grime_meters", &"bottom_bias", &"cavity_bias", &"instance_variation", &"normal_depth"]:
		if src.get_shader_parameter(u) != null: m.set_shader_parameter(u, src.get_shader_parameter(u))
	m.set_shader_parameter(&"range_begin", 0.0 if tier == "near" else NEAR_END); m.set_shader_parameter(&"range_end", NEAR_END if tier == "near" else MID_END)
	return _save_mat(sig, m)

## ONE runtime plant / cut-out material per (cut or solid, merged / instanced, tier)
func _mat_fol(src: BaseMaterial3D, merged: bool, tier: String) -> Material:
	var cut := src.transparency == BaseMaterial3D.TRANSPARENCY_ALPHA_SCISSOR
	var sig := "fol_%s_%s_%s" % ["cut" if cut else "solid", "merged" if merged else "inst", tier]
	if mats.has(sig): return mats[sig]
	var m := ShaderMaterial.new(); m.shader = load(SH + "rt_foliage_%s_%s.gdshader" % ["merged" if merged else "inst", "cut" if cut else "solid"])
	m.set_shader_parameter(&"albedo_arr", load(TEX + "arr_fol_albedo.png")); m.set_shader_parameter(&"normal_arr", load(TEX + "arr_fol_normal.png"))
	m.set_shader_parameter(&"roughness", src.roughness); m.set_shader_parameter(&"scissor", src.alpha_scissor_threshold)
	m.set_shader_parameter(&"range_begin", 0.0 if tier == "near" else NEAR_END); m.set_shader_parameter(&"range_end", NEAR_END if tier == "near" else MID_END)
	return _save_mat(sig, m)

## runtime building material from a city-kit bldg_wear material (bw_*)
func _mat_bldg(src: Material) -> Material:
	if not (src is ShaderMaterial) or not String((src as ShaderMaterial).shader.resource_path).ends_with("bldg_wear.gdshader"): return src
	var s := src as ShaderMaterial
	var sig := "bldg_%s_n%d_w%d" % [_tex_name(s.get_shader_parameter(&"albedo_tex")), int(bool(s.get_shader_parameter(&"has_normal"))), int(round(float(s.get_shader_parameter(&"wear")) * 100.0))]
	if mats.has(sig): return mats[sig]
	var m := ShaderMaterial.new(); m.shader = load(SH + "rt_bldg.gdshader")
	for u: StringName in [&"albedo_tex", &"normal_tex", &"orm_tex", &"emission_tex", &"grime_tex", &"has_normal", &"has_orm", &"has_emission", &"emission_energy", &"wear", &"foot_m", &"grime_meters", &"streaks"]:
		if s.get_shader_parameter(u) != null: m.set_shader_parameter(u, s.get_shader_parameter(u))
	return _save_mat(sig, m)

func _mat_far(kind: String) -> String:
	var sig := "far_%s" % kind
	if not mats.has(sig):
		var m := ShaderMaterial.new(); m.shader = load(SH + "rt_far_%s.gdshader" % kind)
		if kind == "cut": m.set_shader_parameter(&"albedo_arr", load(TEX + "arr_fol_albedo.png"))
		else: m.set_shader_parameter(&"albedo_tex", load("res://assets/coronado_kit/textures/far_color.png"))
		m.set_shader_parameter(&"range_begin", MID_END)
		_save_mat(sig, m)
	return sig

func _mat_glow(halo: bool) -> Material:
	var sig := "glow_halo" if halo else "glow_pool"
	if not mats.has(sig):
		var m := ShaderMaterial.new(); m.shader = load(SH + "rt_glow.gdshader"); m.set_shader_parameter(&"billboard", halo); m.set_shader_parameter(&"energy", 1.6 if halo else 0.22)
		_save_mat(sig, m)
	return mats[sig]

func _mat_ground() -> Material:
	if not mats.has("ground"):
		var m := ShaderMaterial.new(); m.shader = load(SH + "rt_ground.gdshader"); m.set_shader_parameter(&"ground_arr", load(TEX + "arr_ground.png"))
		_save_mat("ground", m)
	return mats["ground"]

func _arrays(m: Mesh) -> Array:
	var id := m.get_instance_id()
	if not arr_cache.has(id): arr_cache[id] = m.surface_get_arrays(0)
	return arr_cache[id]

func _tris(m: Mesh) -> int:
	var a := _arrays(m)
	return ((a[Mesh.ARRAY_INDEX] as PackedInt32Array).size() if a[Mesh.ARRAY_INDEX] != null else (a[Mesh.ARRAY_VERTEX] as PackedVector3Array).size()) / 3

func _linear_texel(tex: Texture2D, uv: Vector2) -> Color:
	var p := tex.resource_path
	if not atlas_img.has(p):
		var img: Image = tex.get_image()
		if img.is_compressed(): img.decompress()
		atlas_img[p] = img
	var im: Image = atlas_img[p]
	var c := im.get_pixel(clampi(int(uv.x * im.get_width()), 0, im.get_width() - 1), clampi(int(uv.y * im.get_height()), 0, im.get_height() - 1))
	return c.srgb_to_linear()

# ---------------------------------------------------------------- B16: the ground's surface classes (footsteps)
## Yasin, 20 Nov: "add footsteps to the game based on terrain". From the top-down picture of the island's ground (before
## it is compressed): one byte a GC_TEXEL-metre texel, 0 hard (asphalt, pavement, concrete), 1 grass, 2 sand, 3 dirt.
## far/ground_class.bin (w * h bytes, row z, column x) + far/ground_class.json (x0, z0, texel, w, h); a look at it in
## far/ground_class.png (black hard, green grass, yellow sand, brown dirt). The game (C++ FootSteps) reads both.
const GC_TEXEL := 2.5

func _ground_class(img: Image, x0: float, z0: float, wx: float, wz: float) -> void:
	var w := int(round(wx / GC_TEXEL)); var h := int(round(wz / GC_TEXEL))
	var small := img.duplicate(); small.resize(w, h, Image.INTERPOLATE_BILINEAR)
	var bytes := PackedByteArray(); bytes.resize(w * h)
	var look := Image.create(w, h, false, Image.FORMAT_RGB8)
	var cols := [Color(0.1, 0.1, 0.1), Color(0.2, 0.7, 0.2), Color(0.9, 0.85, 0.4), Color(0.5, 0.33, 0.15)]
	var count := [0, 0, 0, 0]
	for y in h:
		for x in w:
			var c := small.get_pixel(x, y)
			var mx := maxf(c.r, maxf(c.g, c.b)); var mn := minf(c.r, minf(c.g, c.b))
			var sat := 0.0 if mx < 0.001 else (mx - mn) / mx
			var k := 0
			if c.g > c.r * 1.04 and c.g > c.b * 1.08 and sat > 0.12: k = 1                       # green: grass
			elif c.r >= c.g and c.g >= c.b and sat > 0.14 and mx > 0.52: k = 2                  # light warm: sand
			elif c.r >= c.g and c.g >= c.b and sat > 0.2 and mx <= 0.52: k = 3                  # dark warm: dirt, bark
			bytes[y * w + x] = k; count[k] += 1
			look.set_pixel(x, y, cols[k])
	var f := FileAccess.open(out + "far/ground_class.bin", FileAccess.WRITE); f.store_buffer(bytes); f.close()
	var j := FileAccess.open(out + "far/ground_class.json", FileAccess.WRITE)
	j.store_string(JSON.stringify({"x0": x0, "z0": z0, "texel": GC_TEXEL, "w": w, "h": h, "classes": ["hard", "grass", "sand", "dirt"], "count": count})); j.close()
	look.save_png(out + "far/ground_class.png")
	stat["ground_class"] = count

# ---------------------------------------------------------------- B15: collision for what the kit's col shell leaves out
## Yasin, 20 Nov: "stairs around or columns under buildings dont have colliders, add them". A kit building's collision is
## its hand-made "col" shell; measured over the kit (122 of 128 buildings, 1,480 parts): outside stairs, columns under
## overhangs, porch walls, shopfront panels are not in it and the player walks through them. Here, once per kit folder:
## the near model's triangles in its lowest GAP_LOW metres are voxelised (GAP_VOX); voxels within GAP_PAD of the shell or
## inside it (a vertical ray crosses the shell an odd number of times) are dropped; what is left is split into connected
## parts, and each part of at least GAP_MIN voxels becomes a convex shape of its own triangles (a flight of stairs a ramp
## the player walks up, a column a column). Building space: the same frame as the shell's CollisionShape3D.
const GAP_VOX := 0.25
const GAP_LOW := 3.5
const GAP_PAD := 0.3
const GAP_MIN := 6
const KitLib := preload("res://tools/city/pilot/kit_lib.gd")

func _gap_first_mesh(n: Node) -> MeshInstance3D:
	if n is MeshInstance3D and (n as MeshInstance3D).mesh: return n
	for c in n.get_children():
		var m := _gap_first_mesh(c)
		if m: return m
	return null

func _gap_tris(mi: MeshInstance3D) -> PackedVector3Array:
	var out_t := PackedVector3Array()
	for si in mi.mesh.get_surface_count():
		var a := mi.mesh.surface_get_arrays(si)
		var v: PackedVector3Array = a[Mesh.ARRAY_VERTEX]
		var idx: PackedInt32Array = a[Mesh.ARRAY_INDEX]
		if idx.is_empty(): idx = PackedInt32Array(range(v.size()))
		for i in idx: out_t.append(mi.transform * v[i])
	return out_t

func _gap_hulls(kit: String) -> Array:
	if gap_cache.has(kit): return gap_cache[kit]
	var res: Array = []
	gap_cache[kit] = res
	var dir: String = KitLib._bdir(kit)
	var nf: String = KitLib._tier_file(dir, "near"); var cf: String = KitLib._tier_file(dir, "col")
	if nf == "" or cf == "": return res
	var ni: Node = (load(nf) as PackedScene).instantiate(); var ci: Node = (load(cf) as PackedScene).instantiate()
	var nm := _gap_first_mesh(ni); var cm := _gap_first_mesh(ci)
	var nt := _gap_tris(nm) if nm else PackedVector3Array()
	var ct := _gap_tris(cm) if cm else PackedVector3Array()
	ni.free(); ci.free()
	if nt.is_empty() or ct.is_empty(): return res
	var y0 := 1.0e9
	for q in nt: y0 = minf(y0, q.y)
	var pr := int(ceil(GAP_PAD / GAP_VOX))
	var col := {}
	for i in range(0, ct.size(), 3):
		for q in [ct[i], ct[i + 1], ct[i + 2], (ct[i] + ct[i + 1] + ct[i + 2]) / 3.0, (ct[i] + ct[i + 1]) * 0.5, (ct[i + 1] + ct[i + 2]) * 0.5, (ct[i] + ct[i + 2]) * 0.5]:
			var k := Vector3i((q / GAP_VOX).floor())
			for dx in range(-pr, pr + 1):
				for dy in range(-pr, pr + 1):
					for dz in range(-pr, pr + 1): col[k + Vector3i(dx, dy, dz)] = true
	var tri_of := {}      # voxel -> triangle starts that touch it
	for i in range(0, nt.size(), 3):
		for q in [nt[i], nt[i + 1], nt[i + 2], (nt[i] + nt[i + 1] + nt[i + 2]) / 3.0]:
			if q.y > y0 + GAP_LOW: continue
			var k := Vector3i((q / GAP_VOX).floor())
			if col.has(k): continue
			if not tri_of.has(k): tri_of[k] = []
			(tri_of[k] as Array).append(i)
	var keep := {}
	for k: Vector3i in tri_of:
		var o := (Vector3(k) + Vector3(0.5, 0.5, 0.5)) * GAP_VOX
		var hits := 0
		for i in range(0, ct.size(), 3):
			if Geometry3D.ray_intersects_triangle(o, Vector3.UP, ct[i], ct[i + 1], ct[i + 2]) != null: hits += 1
		if hits % 2 == 0: keep[k] = true
	var seen := {}
	for k: Vector3i in keep:
		if seen.has(k): continue
		var st := [k]; seen[k] = true; var vox: Array = []
		while not st.is_empty():
			var q: Vector3i = st.pop_back(); vox.append(q)
			for d in [Vector3i(1, 0, 0), Vector3i(-1, 0, 0), Vector3i(0, 1, 0), Vector3i(0, -1, 0), Vector3i(0, 0, 1), Vector3i(0, 0, -1)]:
				var w: Vector3i = q + d
				if keep.has(w) and not seen.has(w): seen[w] = true; st.append(w)
		if vox.size() < GAP_MIN: continue
		var used := {}; var verts := PackedVector3Array()
		for q: Vector3i in vox:
			for i: int in tri_of[q]:
				if used.has(i): continue
				used[i] = true; verts.append(nt[i]); verts.append(nt[i + 1]); verts.append(nt[i + 2])
		if verts.size() < 12: continue
		var c := Vector3()
		for q in verts: c += q
		c /= float(verts.size())
		var local := PackedVector3Array()
		for q in verts: local.append(q - c)
		var am := ArrayMesh.new(); var arr := []; arr.resize(Mesh.ARRAY_MAX); arr[Mesh.ARRAY_VERTEX] = local
		am.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arr)
		var hull: ConvexPolygonShape3D = am.create_convex_shape(true, true)
		if hull == null or hull.points.size() < 4: continue
		res.append([hull, Transform3D(Basis(), c)])
	stat["gap_kits"] = int(stat.get("gap_kits", 0)) + 1; stat["gap_parts"] = int(stat.get("gap_parts", 0)) + res.size()
	return res

# ---------------------------------------------------------------- pass 1: route every object of every piece
func _walk(n: Node, piece: String, inst_name: String) -> void:
	if n.has_meta(&"kit") and n is Node3D:
		_building(n as Node3D, piece, inst_name); return
	if n is StaticBody3D:
		_body(n as StaticBody3D); return
	if n is MultiMeshInstance3D:
		_props(n as MultiMeshInstance3D); return
	if n is MeshInstance3D and (n as MeshInstance3D).mesh:
		var mi := n as MeshInstance3D
		var c := _cell_of((mi.global_transform * mi.get_aabb()).get_center())
		var gmesh: Mesh = cur_ground.get(mi.mesh.get_instance_id(), mi.mesh)      # --notrees: with its emptied wells paved over
		if String(n.name) == "ground": fg_src.append([gmesh, mi.global_transform, c])      # the far ground covers the whole island
		if not _cell_wanted(c): stat.skipped_cell += 1
		elif String(n.name) == "wear" and mi.material_override == null: _cell(c).wear.append([mi.mesh, mi.global_transform])
		elif String(n.name) == "ground": _cell(c).ground.append([gmesh, mi.global_transform, "%s__ground" % inst_name])
		else: _cell(c).misc.append({"name": "%s__%s" % [inst_name, String(n.name).replace("@", "")], "mesh": mi.mesh, "xf": mi.global_transform, "ov": mi.material_override, "vb": mi.visibility_range_begin, "ve": mi.visibility_range_end, "vbm": mi.visibility_range_begin_margin, "vem": mi.visibility_range_end_margin, "shadow": mi.cast_shadow})
	for ch in n.get_children(): _walk(ch, piece, inst_name)

func _building(b: Node3D, piece: String, inst_name: String) -> void:
	stat.buildings += 1
	var c := _cell_of(b.global_position)
	var rec := {"name": "%s__%s" % [inst_name, b.name], "kit": String(b.get_meta(&"kit")), "piece": piece, "label": String(b.name), "xf": b.global_transform, "tiers": [], "col": []}
	var pivot := b.global_position
	for ch in b.get_children():
		if ch is MeshInstance3D and (ch as MeshInstance3D).mesh:
			var mi := ch as MeshInstance3D
			var mt: Material = mi.get_surface_override_material(0) if mi.get_surface_override_material(0) else mi.mesh.surface_get_material(0)
			if String(mi.name) == "mid": pivot.y = (mi.global_transform * mi.get_aabb()).get_center().y      # (x, z stay the origin: the cell it was routed to)
			if String(mi.name) == "far":
				_far_add(pivot, _mat_far("solid"), mi.mesh, mi.global_transform, pivot, 1.0e9, false, false, null, 0.0)
				continue
			rec.tiers.append({"name": String(mi.name), "mesh": mi.mesh, "lxf": mi.transform, "mat": mt, "vb": mi.visibility_range_begin, "ve": mi.visibility_range_end, "vbm": mi.visibility_range_begin_margin, "vem": mi.visibility_range_end_margin, "shadow": mi.cast_shadow})
		elif ch is StaticBody3D:
			for cs in ch.get_children():
				if not (cs is CollisionShape3D) or (cs as CollisionShape3D).shape == null: continue
				var bsh: Shape3D = (cs as CollisionShape3D).shape
				if bsh is ConcavePolygonShape3D:
					for pc: Array in _split_concave(bsh): rec.col.append([pc[0], (cs as CollisionShape3D).transform * Transform3D(Basis(), pc[1]), (ch as StaticBody3D).collision_layer, (ch as StaticBody3D).collision_mask])
				else: rec.col.append([bsh, (cs as CollisionShape3D).transform, (ch as StaticBody3D).collision_layer, (ch as StaticBody3D).collision_mask])
	if gap_col and not rec.col.is_empty():      # B15: the parts the kit's col shell leaves out (stairs, columns, low walls)
		var lay: int = int(rec.col[0][2]); var msk: int = int(rec.col[0][3])
		for g: Array in _gap_hulls(String(rec.kit)): rec.col.append([g[0], g[1], lay, msk])
	rec["pivot"] = pivot      # the far version's pivot: near and mid measure their distance to the same point (rt_tier)
	if _cell_wanted(c): _cell(c).bld.append(rec)
	else: stat.skipped_cell += 1

func _body(body: StaticBody3D) -> void:
	for cs in body.get_children():
		if not (cs is CollisionShape3D) or (cs as CollisionShape3D).shape == null: continue
		var s := cs as CollisionShape3D
		if s.shape is ConcavePolygonShape3D:      # ground trimesh of a whole piece: in small pieces, each to the cell it lies in
			var gsh: ConcavePolygonShape3D = s.shape
			if not cur_wells.is_empty(): gsh = _lift_wells(gsh, s.global_transform)
			# in world space (see _split_concave, snap): the pieces' seams stay closed
			var wsh := ConcavePolygonShape3D.new(); wsh.backface_collision = gsh.backface_collision; wsh.set_faces(s.global_transform * gsh.get_faces())
			for pc: Array in _split_concave(wsh, true):
				var pxf := Transform3D(Basis(), pc[1])
				var c0 := _cell_of(pxf.origin)
				if not _cell_wanted(c0): continue
				_cell(c0).col.append([pc[0], pxf, body.collision_layer, body.collision_mask]); stat.shapes += 1
			continue
		var p := s.global_position
		if cur_strip and _tree_at(p): stat.tree_cols_out += 1; continue      # the trunk of a tree that was left out
		var c := _cell_of(p)
		if not _cell_wanted(c): continue
		_cell(c).col.append([s.shape, s.global_transform, body.collision_layer, body.collision_mask]); stat.shapes += 1

func _props(mmi: MultiMeshInstance3D) -> void:
	var mm := mmi.multimesh
	if mm == null or mm.mesh == null: return
	var nm := String(mmi.name); var tier := nm.get_slice("_", nm.get_slice_count("_") - 1)
	if not (tier in ["near", "mid", "far"]): tier = "near"
	if cur_strip and (nm.begins_with("tree_") or nm.begins_with("palm_")): return      # --notrees
	var mt: Material = mmi.material_override if mmi.material_override else mm.mesh.surface_get_material(0)
	var kind := "pass"; var two := false; var wear := 0.55; var page := -1; var u2y := 0.0; var custom := Color(0, 0, 0, 1)
	var use_mesh: Mesh = mm.mesh
	var wind := nm.begins_with("tree_") or nm.begins_with("palm_") or nm.begins_with("plant_") or nm.begins_with("hedge_")
	var has_n := false
	if mm.mesh.get_surface_count() == 1 and mt is ShaderMaterial and String((mt as ShaderMaterial).shader.resource_path).get_file() in ["prop_wear_fix.gdshader", "prop_wear_fix_2s.gdshader"]:
		var sm := mt as ShaderMaterial
		page = _layer("prop_albedo", sm.get_shader_parameter(&"albedo_tex"))
		if page >= 0:
			kind = "prop"; two = String(sm.shader.resource_path).ends_with("_2s.gdshader"); wear = float(sm.get_shader_parameter(&"wear"))
			has_n = sm.get_shader_parameter(&"normal_tex") != null
			u2y = (1.0 if has_n else 0.0) + (2.0 if sm.get_shader_parameter(&"orm_tex") != null else 0.0) + (4.0 if nm.begins_with("prop_signal_") else 0.0)
			custom = Color(wear, float(page), u2y, 1)
	elif mm.mesh.get_surface_count() == 1 and mt is BaseMaterial3D:
		var bm := mt as BaseMaterial3D
		page = _layer("fol_albedo", bm.albedo_texture)
		if page >= 0:
			kind = "fol"; has_n = bm.normal_enabled and bm.normal_texture != null; wear = 0.0
			u2y = (1.0 if wind else 0.0) + (2.0 if has_n else 0.0)
			custom = Color(float(page), 1.0 if wind else 0.0, 1.0 if has_n else 0.0, 1)
	var tris := _tris(mm.mesh)
	var ab := mm.mesh.get_aabb(); var size := maxf(ab.size.y + ab.position.y, maxf(ab.size.x, ab.size.z))
	# lamps: where the light comes from (model space), its reach and colour -> light anchors + night glow
	var lamp := []
	if tier == "near":
		var top := ab.position.y + ab.size.y
		if nm.begins_with("prop_lamp_cobra"): lamp = [Vector3(ab.get_center().x, top - 0.25, ab.position.z + ab.size.z - 0.35), 16.0, Color(1.0, 0.86, 0.62), 0]
		elif nm.begins_with("prop_lamp_") or nm.begins_with("prop_pier_lamp"): lamp = [Vector3(ab.get_center().x, top - 0.35, ab.get_center().z), 11.0, Color(1.0, 0.82, 0.58), 0]
		elif nm.begins_with("prop_lot_light_pole"): lamp = [Vector3(ab.get_center().x, top - 0.3, ab.get_center().z), 18.0, Color(0.86, 0.93, 1.0), 0]
		elif nm.begins_with("prop_porch_light"): lamp = [ab.get_center(), 5.0, Color(1.0, 0.78, 0.5), 1]
	for i in mm.instance_count:
		stat.props_in += 1
		var xf := mmi.global_transform * mm.get_instance_transform(i)
		if tier == "far":
			if kind == "pass" or (size < FAR_MIN_SIZE and not nm.begins_with("fence_")) or (kind == "fol" and not wind): stat.far_dropped += 1; continue
			if kind == "fol": _far_add(xf.origin, _mat_far("cut" if (mt as BaseMaterial3D).transparency == BaseMaterial3D.TRANSPARENCY_ALPHA_SCISSOR else "solid"), mm.mesh, xf, xf.origin, 1200.0, (mt as BaseMaterial3D).transparency != BaseMaterial3D.TRANSPARENCY_ALPHA_SCISSOR, false, (mt as BaseMaterial3D).albedo_texture, float(page))
			else: _far_add(xf.origin, _mat_far("solid"), mm.mesh, xf, xf.origin, 500.0 if nm.begins_with("fence_") else 700.0, true, two, (mt as ShaderMaterial).get_shader_parameter(&"albedo_tex"), 0.0)
			stat.far += 1
			continue
		var c := _cell_of(xf.origin)
		if not _cell_wanted(c): stat.skipped_cell += 1; continue
		var cell := _cell(c)
		if not lamp.is_empty():
			var hp: Vector3 = xf * (lamp[0] as Vector3)
			cell.lights.append([hp.x, hp.y, hp.z, float(lamp[1]), (lamp[2] as Color).r, (lamp[2] as Color).g, (lamp[2] as Color).b, int(lamp[3]), xf.origin.y])
		var subsz := SUB_NEAR if tier == "near" else SUB_MID
		var sub := Vector2i(floori(xf.origin.x / subsz), floori(xf.origin.z / subsz))
		if kind == "pass":
			var key := [mmi.get_instance_id(), tier, "pass"]
			if not cell.inst.has(key): cell.inst[key] = {"mesh": mm.mesh, "mat": mt, "kind": kind, "xfs": [], "custom": [], "vb": mmi.visibility_range_begin, "ve": mmi.visibility_range_end, "shadow": mmi.cast_shadow, "name": nm}
			cell.inst[key].xfs.append(xf); cell.inst[key].custom.append(custom); stat.pass += 1
		elif tier == "near" and tris > MERGE_TRIS:
			var rm: Material = _mat_prop(mt, two, false, tier) if kind == "prop" else _mat_fol(mt, false, tier)
			var key2 := [sub, tier, _mesh_key(use_mesh), rm.resource_path]
			if not cell.inst.has(key2): cell.inst[key2] = {"mesh": use_mesh, "mat": rm, "kind": kind, "xfs": [], "custom": [], "shadow": mmi.cast_shadow, "name": nm}
			cell.inst[key2].xfs.append(xf); cell.inst[key2].custom.append(custom); stat.instanced += 1
		else:
			var rm2: Material = _mat_prop(mt, two, true, tier) if kind == "prop" else _mat_fol(mt, true, tier)
			var key3 := [sub, tier, rm2.resource_path]
			if not cell.merged.has(key3): cell.merged[key3] = {"mat": rm2, "items": [], "shadow": mmi.cast_shadow, "tangents": false}
			if has_n: cell.merged[key3].tangents = true
			cell.merged[key3].items.append([use_mesh, xf, wear, float(page), u2y]); stat.merged += 1

## one far object: its far mesh into the chunk's bucket for that material
func _far_add(where: Vector3, matkey: String, mesh: Mesh, xf: Transform3D, pivot: Vector3, end: float, flat: bool, two: bool, atlas: Texture2D, page: float) -> void:
	var key := [Vector2i(floori(where.x / CHUNK_FAR), floori(where.z / CHUNK_FAR)), matkey]
	if not far.has(key): far[key] = []
	far[key].append([mesh, xf, pivot, end, flat, two, atlas, page])

# ---------------------------------------------------------------- pass 2: build
## props merged into one mesh: vertices relative to `centre`, CUSTOM0 = (prop origin, wear)
func _merge(items: Array, centre: Vector3, tangents: bool) -> ArrayMesh:
	var V := PackedVector3Array(); var N := PackedVector3Array(); var T := PackedFloat32Array(); var UV := PackedVector2Array(); var C := PackedColorArray(); var CU := PackedByteArray(); var I := PackedInt32Array()
	for it: Array in items:
		var a := _arrays(it[0]); var xf: Transform3D = it[1]
		var v: PackedVector3Array = a[Mesh.ARRAY_VERTEX]; var n := v.size(); var base := V.size()
		var lx := Transform3D(xf.basis, xf.origin - centre); var nb := Transform3D(xf.basis.orthonormalized(), Vector3.ZERO)
		V.append_array(lx * v)
		N.append_array(nb * (a[Mesh.ARRAY_NORMAL] as PackedVector3Array) if a[Mesh.ARRAY_NORMAL] != null else _fill_v3(Vector3.UP, n))
		UV.append_array(a[Mesh.ARRAY_TEX_UV] if a[Mesh.ARRAY_TEX_UV] != null else _fill_v2(n))
		if a[Mesh.ARRAY_COLOR] != null: C.append_array(a[Mesh.ARRAY_COLOR])
		else:
			var w := PackedColorArray(); w.resize(n); w.fill(Color.WHITE); C.append_array(w)
		if tangents:
			if a[Mesh.ARRAY_TANGENT] != null:
				var t: PackedFloat32Array = a[Mesh.ARRAY_TANGENT]; var bb := nb.basis
				for k in n:
					var tv := bb * Vector3(t[k * 4], t[k * 4 + 1], t[k * 4 + 2])
					T.append(tv.x); T.append(tv.y); T.append(tv.z); T.append(t[k * 4 + 3])
			else:
				for k in n: T.append(1.0); T.append(0.0); T.append(0.0); T.append(1.0)
		var o := xf.origin - centre
		# CUSTOM0 as four half floats: the prop's origin, and page * 16 + flags * 2 + wear in one number
		var cu := PackedByteArray(); cu.resize(8)
		cu.encode_half(0, o.x); cu.encode_half(2, o.y); cu.encode_half(4, o.z); cu.encode_half(6, float(it[3]) * 16.0 + float(it[4]) * 2.0 + float(it[2]))
		while cu.size() < n * 8: cu.append_array(cu)
		cu.resize(n * 8); CU.append_array(cu)
		if a[Mesh.ARRAY_INDEX] != null:
			for ix: int in (a[Mesh.ARRAY_INDEX] as PackedInt32Array): I.append(ix + base)
		else:
			for k in n: I.append(base + k)
	var arr := []; arr.resize(Mesh.ARRAY_MAX)
	arr[Mesh.ARRAY_VERTEX] = V; arr[Mesh.ARRAY_NORMAL] = N; arr[Mesh.ARRAY_TEX_UV] = UV; arr[Mesh.ARRAY_COLOR] = C; arr[Mesh.ARRAY_CUSTOM0] = CU; arr[Mesh.ARRAY_INDEX] = I
	if tangents: arr[Mesh.ARRAY_TANGENT] = T
	var am := ArrayMesh.new()
	am.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arr, [], {}, Mesh.ARRAY_CUSTOM_RGBA_HALF << Mesh.ARRAY_FORMAT_CUSTOM0_SHIFT)
	return am

func _fill_v3(v: Vector3, n: int) -> PackedVector3Array:
	var a := PackedVector3Array(); a.resize(n); a.fill(v); return a
func _fill_v2(n: int) -> PackedVector2Array:
	var a := PackedVector2Array(); a.resize(n); return a

func _own(n: Node, o: Node) -> void:
	for ch in n.get_children(): ch.owner = o; _own(ch, o)

func _centre_radius(pts: Array) -> Array:
	var ab := AABB(pts[0], Vector3.ZERO)
	for p: Vector3 in pts: ab = ab.expand(p)
	var c := ab.get_center(); var r := 0.0
	for p: Vector3 in pts: r = maxf(r, c.distance_to(p))
	return [c, r]

func _build_cell(c: Vector2i) -> Dictionary:
	lib_shape = {}
	var rec: Dictionary = cells[c]
	var root := Node3D.new(); root.name = "cell_%d_%d" % [c.x, c.y]
	var counts := {"draw_nodes": 0, "tris": 0}
	# ground: the ground of every piece in the cell as ONE mesh, one draw (layer + tint + roughness per vertex; each
	# piece's surfaces are joined once in lib/, see _lib_ground). A ground with a material that is not one of the nine
	# known ground textures keeps its own mesh as built.
	var gn := Node3D.new(); gn.name = "Ground"; root.add_child(gn)
	var gc := Vector3((c.x + 0.5) * CELL, 0, (c.y + 0.5) * CELL)
	var GV := PackedVector3Array(); var GN := PackedVector3Array(); var GUV := PackedVector2Array(); var GU2 := PackedVector2Array(); var GC := PackedColorArray(); var GI := PackedInt32Array()
	for g: Array in rec.ground:
		var gm: Mesh = g[0]; var gx: Transform3D = g[1]; var joined := _lib_ground(gm)
		if joined == null:
			var mi := MeshInstance3D.new(); mi.name = String(g[2]); mi.transform = gx; mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
			mi.mesh = _lib_mesh(gm, true); counts.draw_nodes += gm.get_surface_count(); gn.add_child(mi)
			continue
		var ga := joined.surface_get_arrays(0); var base := GV.size()
		GV.append_array(Transform3D(gx.basis, gx.origin - gc) * (ga[Mesh.ARRAY_VERTEX] as PackedVector3Array))
		GN.append_array(Transform3D(gx.basis.orthonormalized(), Vector3.ZERO) * (ga[Mesh.ARRAY_NORMAL] as PackedVector3Array))
		GUV.append_array(ga[Mesh.ARRAY_TEX_UV]); GU2.append_array(ga[Mesh.ARRAY_TEX_UV2]); GC.append_array(ga[Mesh.ARRAY_COLOR])
		for ix: int in (ga[Mesh.ARRAY_INDEX] as PackedInt32Array): GI.append(ix + base)
	if GV.size() > 0:
		var garr := []; garr.resize(Mesh.ARRAY_MAX)
		garr[Mesh.ARRAY_VERTEX] = GV; garr[Mesh.ARRAY_NORMAL] = GN; garr[Mesh.ARRAY_TEX_UV] = GUV; garr[Mesh.ARRAY_TEX_UV2] = GU2; garr[Mesh.ARRAY_COLOR] = GC; garr[Mesh.ARRAY_INDEX] = GI
		var gam := ArrayMesh.new(); gam.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, garr)
		var gmi := MeshInstance3D.new(); gmi.name = "ground"; gmi.mesh = gam; gmi.position = gc; gmi.material_override = _mat_ground()
		gmi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF; gn.add_child(gmi); counts.draw_nodes += 1
		if not warm.has("ground"):
			var wg := MeshInstance3D.new(); wg.mesh = _lib_ground(rec.ground[0][0]) if _lib_ground(rec.ground[0][0]) else gam; wg.material_override = _mat_ground(); wg.scale = Vector3.ONE * 0.02; warm["ground"] = wg
	# wear marks of every piece in the cell: one mesh (the shader fades each mark by its own distance)
	if not rec.wear.is_empty():
		var V := PackedVector3Array(); var N := PackedVector3Array(); var UV := PackedVector2Array(); var C := PackedColorArray(); var cc := Vector3((c.x + 0.5) * CELL, 0, (c.y + 0.5) * CELL); var wmat: Material = null
		for w: Array in rec.wear:
			var a := (w[0] as Mesh).surface_get_arrays(0); var xf: Transform3D = w[1]; wmat = (w[0] as Mesh).surface_get_material(0)
			var v: PackedVector3Array = Transform3D(xf.basis, xf.origin - cc) * (a[Mesh.ARRAY_VERTEX] as PackedVector3Array)
			var nn: PackedVector3Array = Transform3D(xf.basis.orthonormalized(), Vector3.ZERO) * (a[Mesh.ARRAY_NORMAL] as PackedVector3Array)
			if a[Mesh.ARRAY_INDEX] != null:
				for ix: int in (a[Mesh.ARRAY_INDEX] as PackedInt32Array): V.append(v[ix]); N.append(nn[ix]); UV.append((a[Mesh.ARRAY_TEX_UV] as PackedVector2Array)[ix]); C.append((a[Mesh.ARRAY_COLOR] as PackedColorArray)[ix])
			else: V.append_array(v); N.append_array(nn); UV.append_array(a[Mesh.ARRAY_TEX_UV]); C.append_array(a[Mesh.ARRAY_COLOR])
		var arr := []; arr.resize(Mesh.ARRAY_MAX); arr[Mesh.ARRAY_VERTEX] = V; arr[Mesh.ARRAY_NORMAL] = N; arr[Mesh.ARRAY_TEX_UV] = UV; arr[Mesh.ARRAY_COLOR] = C
		var am := ArrayMesh.new(); am.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arr); am.surface_set_material(0, wmat)
		var wm := MeshInstance3D.new(); wm.name = "wear"; wm.mesh = am; wm.position = cc; wm.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		wm.visibility_range_end = 100.0 + CELL * 0.75; root.add_child(wm); counts.draw_nodes += 1
		if wmat and wmat.resource_path != "": keep[wmat.resource_path] = true
		if not warm.has("wear") and V.size() >= 3:
			var wa := []; wa.resize(Mesh.ARRAY_MAX); wa[Mesh.ARRAY_VERTEX] = V.slice(0, 3); wa[Mesh.ARRAY_NORMAL] = N.slice(0, 3); wa[Mesh.ARRAY_TEX_UV] = UV.slice(0, 3); wa[Mesh.ARRAY_COLOR] = C.slice(0, 3)
			var wam := ArrayMesh.new(); wam.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, wa); wam.surface_set_material(0, wmat)
			var wn := MeshInstance3D.new(); wn.mesh = wam; warm["wear"] = wn
	# buildings: near and mid from lib/, the weathered material with a tint slot per building; far is in the far world
	var bn := Node3D.new(); bn.name = "Buildings"; root.add_child(bn)
	for b: Dictionary in rec.bld:
		var node := Node3D.new(); node.name = String(b.name); node.transform = b.xf
		node.set_meta(&"kit", b.kit); node.set_meta(&"piece", b.piece); node.set_meta(&"label", b.label); bn.add_child(node)
		var seed_v := float(absi(hash(b.name)) % 1000) * 0.137
		for t: Dictionary in b.tiers:
			var mi2 := MeshInstance3D.new(); mi2.name = String(t.name); mi2.mesh = _lib_mesh(t.mesh); mi2.transform = t.lxf
			var bmat := _mat_bldg(t.mat)
			mi2.set_surface_override_material(0, bmat)
			var wk3 := "%s|bldg|%d" % [bmat.resource_path, mi2.mesh.surface_get_format(0)]
			if not warm.has(wk3):
				var wb := MeshInstance3D.new(); wb.mesh = mi2.mesh; wb.set_surface_override_material(0, bmat); wb.scale = Vector3.ONE * 0.05; wb.cast_shadow = t.shadow; warm[wk3] = wb
			# the tier window (the shader cuts exactly there, rt_tier.gdshaderinc) and a node range BAND_MAX / 2 wider
			var win := Vector2(0.0, NEAR_END) if String(t.name) == "near" else (Vector2(NEAR_END, MID_END) if String(t.name) == "mid" else Vector2(0.0, 1.0e6))
			if win.y < 1.0e5:
				mi2.visibility_range_begin = maxf(0.0, win.x - BAND_MAX * 0.5) if win.x > 0.0 else 0.0; mi2.visibility_range_end = win.y + BAND_MAX * 0.5
				mi2.visibility_range_begin_margin = 0.0; mi2.visibility_range_end_margin = 0.0
			else:
				mi2.visibility_range_begin = t.vb; mi2.visibility_range_end = t.ve; mi2.visibility_range_begin_margin = t.vbm; mi2.visibility_range_end_margin = t.vem
			mi2.set_instance_shader_parameter(&"ck_win", win); mi2.set_instance_shader_parameter(&"ck_pivot", b.pivot)
			mi2.visibility_range_fade_mode = GeometryInstance3D.VISIBILITY_RANGE_FADE_DISABLED; mi2.cast_shadow = t.shadow
			# every per-building value is written (an unset one did not read as the shader's default in the first bake)
			var tv := _tint_for(String(b.name), String(b.kit)) if tint_on else [Color(1, 1, 1), 0.0]
			mi2.set_instance_shader_parameter(&"lit_seed", seed_v); mi2.set_instance_shader_parameter(&"tint", tv[0]); mi2.set_instance_shader_parameter(&"wear_add", tv[1])
			node.add_child(mi2); counts.draw_nodes += 1
		if not b.col.is_empty():
			var body := _col_marker("col", int(b.col[0][2]), int(b.col[0][3])); node.add_child(body)
			for cs: Array in b.col: _col_add(body, cs[0], cs[1])
	# props
	var pn := Node3D.new(); pn.name = "Props"; root.add_child(pn)
	var k := 0
	for key: Array in rec.merged:
		var mb: Dictionary = rec.merged[key]
		var pts: Array = []
		for it: Array in mb.items: pts.append((it[1] as Transform3D).origin)
		var cr := _centre_radius(pts)
		var mi3 := MeshInstance3D.new(); mi3.name = "m%d_%s" % [k, key[1]]; k += 1
		mi3.mesh = _merge(mb.items, cr[0], mb.tangents); mi3.position = cr[0]; mi3.material_override = mb.mat
		var wk := "%s|merged|%s" % [(mb.mat as Material).resource_path, str(mb.tangents)]
		if not warm.has(wk):
			var wm2 := MeshInstance3D.new(); wm2.mesh = _merge([mb.items[0]], (mb.items[0][1] as Transform3D).origin, mb.tangents); wm2.material_override = mb.mat; wm2.cast_shadow = mb.shadow; warm[wk] = wm2
		_range(mi3, String(key[1]), float(cr[1])); mi3.cast_shadow = mb.shadow
		pn.add_child(mi3); counts.draw_nodes += 1
	for key2: Array in rec.inst:
		var ib: Dictionary = rec.inst[key2]
		var mm := MultiMesh.new(); mm.transform_format = MultiMesh.TRANSFORM_3D; mm.use_custom_data = ib.kind != "pass"; mm.mesh = _lib_mesh(ib.mesh, ib.kind == "pass" and ib.mat == null)
		mm.instance_count = ib.xfs.size()
		var pts2: Array = []
		for i in ib.xfs.size():
			mm.set_instance_transform(i, ib.xfs[i]); pts2.append((ib.xfs[i] as Transform3D).origin)
			if mm.use_custom_data: mm.set_instance_custom_data(i, ib.custom[i])
		var mmi := MultiMeshInstance3D.new(); mmi.name = "i%d_%s" % [k, String(ib.name)]; k += 1; mmi.multimesh = mm
		if ib.mat:
			mmi.material_override = ib.mat
			if (ib.mat as Material).resource_path != "" and not (ib.mat as Material).resource_path.contains("::"): keep[(ib.mat as Material).resource_path] = true
			var wk2 := "%s|inst|%d" % [(ib.mat as Material).resource_path, mm.mesh.surface_get_format(0)]
			if not warm.has(wk2) and (ib.mat as Material).resource_path != "":
				var wmm := MultiMesh.new(); wmm.transform_format = MultiMesh.TRANSFORM_3D; wmm.use_custom_data = mm.use_custom_data; wmm.mesh = mm.mesh; wmm.instance_count = 1; wmm.set_instance_transform(0, Transform3D.IDENTITY)
				if wmm.use_custom_data: wmm.set_instance_custom_data(0, ib.custom[0])
				var wmi := MultiMeshInstance3D.new(); wmi.multimesh = wmm; wmi.material_override = ib.mat; wmi.cast_shadow = ib.shadow; warm[wk2] = wmi
		if ib.kind == "pass": mmi.visibility_range_begin = ib.vb; mmi.visibility_range_end = ib.ve; mmi.visibility_range_end_margin = 2.0
		else: _range(mmi, String(key2[1]), float(_centre_radius(pts2)[1]))
		mmi.cast_shadow = ib.shadow
		pn.add_child(mmi); counts.draw_nodes += 1
	# everything else a piece draws (foam strips, wires, park ground tiers): as built, model in lib/
	if not rec.misc.is_empty():
		var mn := Node3D.new(); mn.name = "Misc"; root.add_child(mn)
		for m: Dictionary in rec.misc:
			var mi4 := MeshInstance3D.new(); mi4.name = String(m.name); mi4.mesh = _lib_mesh(m.mesh, true); mi4.transform = m.xf
			if m.ov: mi4.material_override = m.ov
			# These keep the materials they were built with. The first of every KIND of material (shader, textures,
			# switches, vertex layout) is drawn in the warm-up and held for good, so the cell that brings the first
			# park ground or the first wire does not load its textures and build its shader in the middle of a drive
			# (phone, 18 Nov: one frame of 60-350 ms at the same place in every run).
			var sig := "misc" + _mat_sig(mi4.mesh, m.ov)
			if not warm.has(sig):
				var wm4 := MeshInstance3D.new(); wm4.mesh = mi4.mesh; wm4.scale = Vector3.ONE * 0.01
				if m.ov: wm4.material_override = m.ov
				warm[sig] = wm4; keep[mi4.mesh.resource_path] = true
				if m.ov and (m.ov as Material).resource_path != "" and not (m.ov as Material).resource_path.contains("::"): keep[(m.ov as Material).resource_path] = true
			mi4.visibility_range_begin = m.vb; mi4.visibility_range_end = m.ve; mi4.visibility_range_begin_margin = m.vbm; mi4.visibility_range_end_margin = m.vem; mi4.cast_shadow = m.shadow
			mn.add_child(mi4); counts.draw_nodes += 1
	# collision of ground and props: one static body per layer / mask pair
	var bodies := {}; var body_tris := {}
	for cs2: Array in rec.col:
		var co: Vector3 = (cs2[1] as Transform3D).origin
		var st2 := (cs2[0] as ConcavePolygonShape3D).get_faces().size() / 3 if cs2[0] is ConcavePolygonShape3D else 0
		# small bodies (a 32 m block, at most 24 shapes): each is quick to attach and to free (136 shapes in one body
		# took 15-25 ms to attach in the cloud test)
		var bk := [cs2[2], cs2[3], floori(co.x / 32.0), floori(co.z / 32.0), 0]
		while bodies.has(bk) and (((bodies[bk] as Node).get_meta(&"col") as Array).size() >= 24 or (st2 > 0 and int(body_tris.get(bodies[bk], 0)) + st2 > COL_BODY_TRIS)): bk[4] += 1
		if not bodies.has(bk):
			var body2 := _col_marker("col_%d" % bodies.size(), int(cs2[2]), int(cs2[3])); body2.position = co; root.add_child(body2); bodies[bk] = body2
		_col_add(bodies[bk], cs2[0], Transform3D(Basis(), -(bodies[bk] as Node3D).position) * (cs2[1] as Transform3D))
		body_tris[bodies[bk]] = int(body_tris.get(bodies[bk], 0)) + st2
	# night: every lamp of the cell as a halo at its head and a pool on the ground (two draws, drawn only at night),
	# and as a light anchor [x, y, z, reach, r, g, b, kind (0 street, 1 porch), ground y] for the real lights
	if not rec.lights.is_empty():
		var quad := QuadMesh.new(); quad.size = Vector2(1, 1)
		for kind_i in 2:
			var gm2 := MultiMesh.new(); gm2.transform_format = MultiMesh.TRANSFORM_3D; gm2.use_custom_data = true; gm2.mesh = quad; gm2.instance_count = rec.lights.size()
			for i in rec.lights.size():
				var L: Array = rec.lights[i]; var reach := float(L[3]); var porch := int(L[7]) == 1
				var t := Transform3D(Basis.IDENTITY.scaled(Vector3.ONE * (0.5 if porch else 1.5)), Vector3(L[0], L[1], L[2])) if kind_i == 0 else Transform3D(Basis(Vector3.RIGHT, -PI * 0.5).scaled(Vector3.ONE * reach * (0.9 if porch else 1.1)), Vector3(L[0], float(L[8]) + 0.04, L[2]))
				gm2.set_instance_transform(i, t); gm2.set_instance_custom_data(i, Color(L[4], L[5], L[6], 1))
			var gl := MultiMeshInstance3D.new(); gl.name = "glow_halo" if kind_i == 0 else "glow_pool"; gl.multimesh = gm2; gl.material_override = _mat_glow(kind_i == 0)
			gl.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF; gl.visibility_range_end = 260.0 + CELL * 0.75
			gl.visible = false      # shown by city_stream.set_night() only at night: no draw by day
			if not warm.has(String(gl.name)):
				var wq := MultiMesh.new(); wq.transform_format = MultiMesh.TRANSFORM_3D; wq.use_custom_data = true; wq.mesh = quad; wq.instance_count = 1; wq.set_instance_transform(0, Transform3D.IDENTITY); wq.set_instance_custom_data(0, Color(1, 1, 1, 1))
				var wgl := MultiMeshInstance3D.new(); wgl.multimesh = wq; wgl.material_override = gl.material_override; warm[String(gl.name)] = wgl
			root.add_child(gl); counts.draw_nodes += 1
	root.set_meta(&"cell", [c.x, c.y]); root.set_meta(&"stalls", rec.stalls); root.set_meta(&"lights", rec.lights); root.set_meta(&"pieces", rec.pieces.values())
	_own(root, root)
	var ps := PackedScene.new(); ps.pack(root)
	var path := out + "cells/cell_%d_%d.scn" % [c.x, c.y]
	var err := ResourceSaver.save(ps, path, ResourceSaver.FLAG_COMPRESS)
	counts["nodes"] = root.find_children("*", "", true, false).size() + 1; counts["err"] = err
	root.free()
	return counts

## node-level range of a batch: wide enough for every prop in it (each prop then cuts itself exactly in the shader)
func _range(g: GeometryInstance3D, tier: String, r: float) -> void:
	var b := 0.0 if tier == "near" else NEAR_END; var e := NEAR_END if tier == "near" else MID_END
	g.visibility_range_begin = maxf(0.0, b - r - 1.0 - BAND_MAX * 0.5); g.visibility_range_end = e + r + 1.0 + BAND_MAX * 0.5
	g.visibility_range_fade_mode = GeometryInstance3D.VISIBILITY_RANGE_FADE_DISABLED

## trial (--tint): a paint tint and a little more or less wear per building, fixed by its name (so it never changes)
func _tint_for(name: String, kit: String) -> Array:
	var h := absi(hash(name))
	var pal := [Color(1, 1, 1), Color(1.0, 0.94, 0.84), Color(0.93, 0.97, 1.0), Color(1.0, 0.9, 0.86), Color(0.9, 0.96, 0.9), Color(0.98, 0.96, 0.78), Color(0.86, 0.9, 0.96), Color(1.0, 0.86, 0.74), Color(0.84, 0.86, 0.84)]
	var col: Color = pal[h % pal.size()]
	return [col, float((h / 97) % 100) / 100.0 * 0.3 - 0.12]

func _build_far() -> Dictionary:
	var root := Node3D.new(); root.name = "FarWorld"
	var n := 0; var tris := 0
	for key: Array in far:
		var ch: Vector2i = key[0]; var cc := Vector3((ch.x + 0.5) * CHUNK_FAR, 0, (ch.y + 0.5) * CHUNK_FAR)
		var V := PackedVector3Array(); var N := PackedVector3Array(); var UV := PackedVector2Array(); var UV2 := PackedVector2Array(); var C := PackedColorArray(); var CU := PackedFloat32Array()
		for e: Array in far[key]:
			var a := _arrays(e[0]); var xf: Transform3D = e[1]; var flat: bool = e[4]; var two: bool = e[5]
			var v: PackedVector3Array = Transform3D(xf.basis, xf.origin - cc) * (a[Mesh.ARRAY_VERTEX] as PackedVector3Array)
			var nn: PackedVector3Array = Transform3D(xf.basis.orthonormalized(), Vector3.ZERO) * (a[Mesh.ARRAY_NORMAL] as PackedVector3Array) if a[Mesh.ARRAY_NORMAL] != null else _fill_v3(Vector3.UP, v.size())
			var uv: PackedVector2Array = a[Mesh.ARRAY_TEX_UV] if a[Mesh.ARRAY_TEX_UV] != null else _fill_v2(v.size())
			var col: Variant = a[Mesh.ARRAY_COLOR]
			var idx: PackedInt32Array = a[Mesh.ARRAY_INDEX] if a[Mesh.ARRAY_INDEX] != null else PackedInt32Array(range(v.size()))
			var pv: Vector3 = (e[2] as Vector3) - cc
			var hc := _cell_of(e[2]); var code := float((hc.x + 32) + (hc.y + 32) * 64)      # its cell, for rt_far's "is my cell in?"
			var order: Array = [[0, 1, 2]] if not two else [[0, 1, 2], [0, 2, 1]]
			for t in range(0, idx.size(), 3):
				var fc := Color.WHITE
				if flat and e[6] != null:      # a far prop: one flat colour per triangle, read from its atlas (no texture at 220 m and beyond)
					var cuv := (uv[idx[t]] + uv[idx[t + 1]] + uv[idx[t + 2]]) / 3.0
					fc = _linear_texel(e[6], cuv) * 0.9
					if col != null:
						var vc: Color = (col as PackedColorArray)[idx[t]]; var mc := maxf(maxf(vc.r, vc.g), maxf(vc.b, 0.04)); var k := lerpf(1.0, mc, 0.5) / mc
						fc = Color(fc.r * vc.r * k, fc.g * vc.g * k, fc.b * vc.b * k)
				for o: Array in order:
					for j: int in o:
						var ix := idx[t + j]
						V.append(v[ix]); N.append(nn[ix] if o[1] == 1 else -nn[ix]); UV.append(uv[ix]); UV2.append(Vector2((1.0 if flat else 0.0) + 2.0 * float(e[7]), code)); C.append(fc)
						CU.append(pv.x); CU.append(pv.y); CU.append(pv.z); CU.append(float(e[3]))
		var arr := []; arr.resize(Mesh.ARRAY_MAX)
		arr[Mesh.ARRAY_VERTEX] = V; arr[Mesh.ARRAY_NORMAL] = N; arr[Mesh.ARRAY_TEX_UV] = UV; arr[Mesh.ARRAY_TEX_UV2] = UV2; arr[Mesh.ARRAY_COLOR] = C; arr[Mesh.ARRAY_CUSTOM0] = CU
		var am := ArrayMesh.new(); am.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arr, [], {}, Mesh.ARRAY_CUSTOM_RGBA_FLOAT << Mesh.ARRAY_FORMAT_CUSTOM0_SHIFT)
		var mi := MeshInstance3D.new(); mi.name = "far_%d_%d_%s" % [ch.x, ch.y, String(key[1]).trim_prefix("far_")]; mi.mesh = am; mi.position = cc
		mi.material_override = mats[key[1]]; mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		root.add_child(mi); n += 1; tris += V.size() / 3
		if not warm.has(String(key[1])) and V.size() >= 3:
			var fa := []; fa.resize(Mesh.ARRAY_MAX); fa[Mesh.ARRAY_VERTEX] = PackedVector3Array([Vector3(0, 0, 0), Vector3(0.2, 0, 0), Vector3(0, 0.2, 0)]); fa[Mesh.ARRAY_NORMAL] = N.slice(0, 3); fa[Mesh.ARRAY_TEX_UV] = UV.slice(0, 3)
			fa[Mesh.ARRAY_TEX_UV2] = PackedVector2Array([Vector2(0, 0), Vector2(0, 0), Vector2(0, 0)]); fa[Mesh.ARRAY_COLOR] = C.slice(0, 3); fa[Mesh.ARRAY_CUSTOM0] = PackedFloat32Array([0, 0, 0, 1e9, 0, 0, 0, 1e9, 0, 0, 0, 1e9])
			var fam := ArrayMesh.new(); fam.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, fa, [], {}, Mesh.ARRAY_CUSTOM_RGBA_FLOAT << Mesh.ARRAY_FORMAT_CUSTOM0_SHIFT)
			var fn := MeshInstance3D.new(); fn.mesh = fam; fn.material_override = mats[key[1]]; warm[String(key[1])] = fn
	if fg_node: root.add_child(fg_node); n += 1; tris += int(fg_node.get_meta(&"tris", 0))
	_own(root, root)
	var ps := PackedScene.new(); ps.pack(root)
	ResourceSaver.save(ps, out + "far/far_world.scn", ResourceSaver.FLAG_COMPRESS)
	root.free()
	return {"meshes": n, "tris": tris}

## FAR GROUND (19 Nov). The ground of every cell as one mesh of the far world: per cell a 200 m patch on a FG_GRID grid
## that follows the real ground's heights (sampled from its triangles on one grid for the whole island, so neighbouring
## patches meet without cracks), drawn with ONE top-down picture of the real ground (rendered here with the real ground
## materials, unlit, FG_SUPER times larger and scaled down, mipmaps, VRAM-compressed). rt_far_ground.gdshader collapses
## a patch in the frame its cell is in. Places a piece does not cover show the rig's plane colour.
func _build_far_ground() -> Dictionary:
	if fg_src.is_empty(): return {"cells": 0}
	var t0 := Time.get_ticks_msec()
	var used := {}
	for g: Array in fg_src: used[g[2]] = true
	var c_lo := Vector2i(1 << 20, 1 << 20); var c_hi := -c_lo
	for c: Vector2i in used: c_lo = Vector2i(mini(c_lo.x, c.x), mini(c_lo.y, c.y)); c_hi = Vector2i(maxi(c_hi.x, c.x), maxi(c_hi.y, c.y))
	var x0 := c_lo.x * CELL; var z0 := c_lo.y * CELL; var wx := (c_hi.x - c_lo.x + 1) * CELL; var wz := (c_hi.y - c_lo.y + 1) * CELL
	# heights: the highest ground triangle over each grid point
	var gn := Vector2i(int(wx / FG_GRID) + 1, int(wz / FG_GRID) + 1)
	var hy := PackedFloat32Array(); hy.resize(gn.x * gn.y); hy.fill(-1.0e9)
	var ntri := 0
	for g: Array in fg_src:
		var gm: Mesh = g[0]; var xf: Transform3D = g[1]
		for si in gm.get_surface_count():
			var a := gm.surface_get_arrays(si)
			var v: PackedVector3Array = xf * (a[Mesh.ARRAY_VERTEX] as PackedVector3Array)
			var idx: PackedInt32Array = a[Mesh.ARRAY_INDEX] if a[Mesh.ARRAY_INDEX] != null else PackedInt32Array(range(v.size()))
			for t in range(0, idx.size() - 2, 3):
				var p0 := v[idx[t]]; var p1 := v[idx[t + 1]]; var p2 := v[idx[t + 2]]; ntri += 1
				var ix0 := ceili((minf(p0.x, minf(p1.x, p2.x)) - x0) / FG_GRID); var ix1 := floori((maxf(p0.x, maxf(p1.x, p2.x)) - x0) / FG_GRID)
				var iz0 := ceili((minf(p0.z, minf(p1.z, p2.z)) - z0) / FG_GRID); var iz1 := floori((maxf(p0.z, maxf(p1.z, p2.z)) - z0) / FG_GRID)
				if ix1 < ix0 or iz1 < iz0: continue
				var den := (p1.z - p2.z) * (p0.x - p2.x) + (p2.x - p1.x) * (p0.z - p2.z)
				if absf(den) < 1.0e-6: continue
				for iz in range(maxi(iz0, 0), mini(iz1, gn.y - 1) + 1):
					for ix in range(maxi(ix0, 0), mini(ix1, gn.x - 1) + 1):
						var px := x0 + ix * FG_GRID; var pz := z0 + iz * FG_GRID
						var l0 := ((p1.z - p2.z) * (px - p2.x) + (p2.x - p1.x) * (pz - p2.z)) / den
						var l1 := ((p2.z - p0.z) * (px - p2.x) + (p0.x - p2.x) * (pz - p2.z)) / den
						var l2 := 1.0 - l0 - l1
						if l0 < -1.0e-4 or l1 < -1.0e-4 or l2 < -1.0e-4: continue
						var y := l0 * p0.y + l1 * p1.y + l2 * p2.y
						var gi := iz * gn.x + ix
						if y > hy[gi]: hy[gi] = y
	# grid points no ground lies over: the mean of their known neighbours, spread outwards (0 where nothing is known)
	for it in 64:
		var changed := false; var nh := hy.duplicate()
		for iz in gn.y:
			for ix in gn.x:
				if hy[iz * gn.x + ix] > -1.0e8: continue
				var sm := 0.0; var cnt := 0
				for o: Vector2i in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
					var q := Vector2i(ix, iz) + o
					if q.x < 0 or q.y < 0 or q.x >= gn.x or q.y >= gn.y: continue
					var hv := hy[q.y * gn.x + q.x]
					if hv > -1.0e8: sm += hv; cnt += 1
				if cnt > 0: nh[iz * gn.x + ix] = sm / cnt; changed = true
		hy = nh
		if not changed: break
	for i in hy.size():
		if hy[i] < -1.0e8: hy[i] = 0.0
	# the picture: the real ground of every piece, seen from straight above, unlit
	var px_w := int(round(wx / FG_TEXEL)); var px_h := int(round(wz / FG_TEXEL))
	var vp := SubViewport.new(); vp.size = Vector2i(px_w * FG_SUPER, px_h * FG_SUPER); vp.own_world_3d = true; vp.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	root.add_child(vp)
	var env := Environment.new(); env.background_mode = Environment.BG_COLOR; env.background_color = Color(0.36, 0.42, 0.3)      # the rig's ground plane
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR; env.ambient_light_color = Color.WHITE; env.ambient_light_energy = 1.0
	env.reflected_light_source = Environment.REFLECTION_SOURCE_DISABLED; env.tonemap_mode = Environment.TONE_MAPPER_LINEAR
	var we := WorldEnvironment.new(); we.environment = env; vp.add_child(we)
	var cam := Camera3D.new(); cam.projection = Camera3D.PROJECTION_ORTHOGONAL; cam.keep_aspect = Camera3D.KEEP_HEIGHT; cam.size = wz
	cam.position = Vector3(x0 + wx * 0.5, 400.0, z0 + wz * 0.5); cam.rotation_degrees = Vector3(-90, 0, 0); cam.near = 1.0; cam.far = 900.0; vp.add_child(cam); cam.current = true
	var gsh := Shader.new(); gsh.code = (load(SH + "rt_ground.gdshader") as Shader).code.replace("render_mode cull_back;", "render_mode cull_back, unshaded;")
	var gmat := ShaderMaterial.new(); gmat.shader = gsh; gmat.set_shader_parameter(&"ground_arr", load(TEX + "arr_ground.png"))
	var unlit := {}
	for g2: Array in fg_src:
		var mi := MeshInstance3D.new(); mi.transform = g2[1]; mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		var joined := _lib_ground(g2[0])
		if joined: mi.mesh = joined; mi.material_override = gmat
		else:
			mi.mesh = g2[0]
			for si in (g2[0] as Mesh).get_surface_count():
				var sm2: Material = (g2[0] as Mesh).surface_get_material(si)
				if sm2 is BaseMaterial3D:
					if not unlit.has(sm2): unlit[sm2] = sm2.duplicate(); (unlit[sm2] as BaseMaterial3D).shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
					mi.set_surface_override_material(si, unlit[sm2])
		vp.add_child(mi)
	for i in 4: await process_frame
	await RenderingServer.frame_post_draw
	var img := vp.get_texture().get_image()
	vp.queue_free()
	if img == null or img.is_empty(): print("BAKE far ground: the top-down render gave no picture"); return {"cells": 0}
	img.convert(Image.FORMAT_RGB8)
	img.resize(px_w, px_h, Image.INTERPOLATE_LANCZOS)
	var dbg := img.duplicate(); dbg.resize(px_w / 4, px_h / 4, Image.INTERPOLATE_LANCZOS); dbg.save_png(out + "far/far_ground_small.png")      # a look at it (not used by the game)
	_ground_class(img, x0, z0, wx, wz)      # B16: what the ground is made of, for the footsteps
	img.generate_mipmaps()
	var tex: Texture2D = null
	var cimg := img.duplicate()
	if cimg.compress(Image.COMPRESS_ETC2, Image.COMPRESS_SOURCE_SRGB) == OK:
		tex = ImageTexture.create_from_image(cimg)      # the compressed image is what is stored (a PC without ETC2 converts it when it loads; the phone uses it as is)
	else:
		print("BAKE far ground: ETC2 compression not available here, the picture is stored uncompressed")
		tex = ImageTexture.create_from_image(img)
	ResourceSaver.save(tex, out + "far/far_ground_top.res", ResourceSaver.FLAG_COMPRESS)
	tex = load(out + "far/far_ground_top.res")
	# the patches: one mesh for the island, one draw
	var cc := Vector3(x0 + wx * 0.5, 0.0, z0 + wz * 0.5)
	var V := PackedVector3Array(); var N := PackedVector3Array(); var UV := PackedVector2Array(); var UV2 := PackedVector2Array(); var I := PackedInt32Array()
	var per := int(CELL / FG_GRID)
	for c2: Vector2i in used:
		var code := float((c2.x + 32) + (c2.y + 32) * 64); var base := V.size()
		var gx0 := int((c2.x * CELL - x0) / FG_GRID); var gz0 := int((c2.y * CELL - z0) / FG_GRID)
		for j in per + 1:
			for i in per + 1:
				var gx := gx0 + i; var gz := gz0 + j
				var y := hy[gz * gn.x + gx]
				var wpos := Vector3(x0 + gx * FG_GRID, y, z0 + gz * FG_GRID)
				var hl := hy[gz * gn.x + maxi(gx - 1, 0)]; var hr := hy[gz * gn.x + mini(gx + 1, gn.x - 1)]
				var hd := hy[maxi(gz - 1, 0) * gn.x + gx]; var hu := hy[mini(gz + 1, gn.y - 1) * gn.x + gx]
				V.append(wpos - cc); N.append(Vector3(hl - hr, 2.0 * FG_GRID, hd - hu).normalized())
				UV.append(Vector2((wpos.x - x0) / wx, (wpos.z - z0) / wz)); UV2.append(Vector2(0.0, code))
		for j2 in per:
			for i2 in per:
				var a0 := base + j2 * (per + 1) + i2; var a1 := a0 + 1; var a2 := a0 + per + 1; var a3 := a2 + 1
				I.append_array(PackedInt32Array([a0, a1, a2, a1, a3, a2]))
	var arr := []; arr.resize(Mesh.ARRAY_MAX)
	arr[Mesh.ARRAY_VERTEX] = V; arr[Mesh.ARRAY_NORMAL] = N; arr[Mesh.ARRAY_TEX_UV] = UV; arr[Mesh.ARRAY_TEX_UV2] = UV2; arr[Mesh.ARRAY_INDEX] = I
	var am := ArrayMesh.new(); am.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arr)
	if not mats.has("far_ground"):
		var fm := ShaderMaterial.new(); fm.shader = load(SH + "rt_far_ground.gdshader"); fm.set_shader_parameter(&"ground_top", tex)
		_save_mat("far_ground", fm)
	var mi2 := MeshInstance3D.new(); mi2.name = "far_ground"; mi2.mesh = am; mi2.position = cc; mi2.material_override = mats["far_ground"]
	mi2.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF; mi2.set_meta(&"tris", I.size() / 3)
	fg_node = mi2
	if not warm.has("far_ground"):
		var wfa := []; wfa.resize(Mesh.ARRAY_MAX); wfa[Mesh.ARRAY_VERTEX] = V.slice(0, 3); wfa[Mesh.ARRAY_NORMAL] = N.slice(0, 3); wfa[Mesh.ARRAY_TEX_UV] = UV.slice(0, 3)
		wfa[Mesh.ARRAY_TEX_UV2] = PackedVector2Array([Vector2.ZERO, Vector2.ZERO, Vector2.ZERO])
		var wfm := ArrayMesh.new(); wfm.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, wfa)
		var wfn := MeshInstance3D.new(); wfn.mesh = wfm; wfn.material_override = mats["far_ground"]; warm["far_ground"] = wfn
	return {"cells": used.size(), "tris": I.size() / 3, "verts": V.size(), "picture": "%dx%d" % [px_w, px_h], "compressed": cimg.is_compressed(), "tex_kb": FileAccess.get_file_as_bytes(out + "far/far_ground_top.res").size() / 1024, "ground_tris_sampled": ntri, "ms": Time.get_ticks_msec() - t0}

# ---------------------------------------------------------------- main
func _rows() -> Array: return (JSON.parse_string(FileAccess.get_file_as_string(LAYOUT)) as Dictionary).instances

func _check() -> void:
	var mp := out + "manifest.json"
	if not FileAccess.file_exists(mp): print("BAKE_CHECK no manifest: nothing baked"); quit(1); return
	var man: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(mp))
	var sha := {}; var stale := {}
	for ck: String in man.cells:
		for p: Array in man.cells[ck].pieces:
			if not sha.has(p[0]): sha[p[0]] = FileAccess.get_sha256(PIECES + String(p[0]) + ".scn")
			if sha[p[0]] != String(p[1]): stale[ck] = String(p[0])
	if String(man.layout_sha) != FileAccess.get_sha256(LAYOUT): print("BAKE_CHECK the layout changed since the bake")
	for ck: String in stale: print("BAKE_CHECK stale cell %s (piece %s changed)" % [ck, stale[ck]])
	print("BAKE_CHECK %d cells, %d stale" % [man.cells.size(), stale.size()])
	quit(1 if stale.size() > 0 else 0)

func _run() -> void:
	var all := false; var check := false
	for a in OS.get_cmdline_user_args():
		if a == "--all": all = true
		if a == "--check": check = true
		if a == "--tint": tint_on = true
		if a == "--nofarground": fg_on = false
		if a == "--notrees": no_trees = true
		if a == "--keepwells": well_fill = false
		if a == "--nogapcol": gap_col = false
		if a.begins_with("--out="): out = a.trim_prefix("--out=")
		if a.begins_with("--area="):
			var f := a.trim_prefix("--area=").split_floats(","); area = [f[0], f[1], f[2]]
	if check: _check(); return
	if not all and area.is_empty(): print("BAKE needs --all or --area=x,z,r"); quit(2); return
	for d in ["lib", "cells", "far"]: DirAccess.make_dir_recursive_absolute(out + d)
	layers = JSON.parse_string(FileAccess.get_file_as_string(TEX + "arrays.json"))
	var t0 := Time.get_ticks_msec()
	var holder := Node3D.new(); root.add_child(holder)
	var sha := {}; var k := 0
	if no_trees:      # the hand-placed trees first: a well one of them stands in is not filled
		for r0: Dictionary in _rows():
			var pc0 := String(r0.piece)
			if not pc0.begins_with("t_") or not ResourceLoader.exists(PIECES + pc0 + ".scn"): continue
			var i0: Node3D = (load(PIECES + pc0 + ".scn") as PackedScene).instantiate()
			var p0: Array = r0.get("pos", [0, 0, 0]); i0.position = Vector3(float(p0[0]), float(p0[1]), float(p0[2])); i0.rotation_degrees.y = float(r0.get("yaw", 0))
			holder.add_child(i0); _keep_trees(i0); holder.remove_child(i0); i0.free()
	for r: Dictionary in _rows():
		var piece := String(r.piece); var path := PIECES + piece + ".scn"
		if not ResourceLoader.exists(path): continue
		var inst: Node3D = (load(path) as PackedScene).instantiate()
		var p: Array = r.get("pos", [0, 0, 0]); inst.position = Vector3(float(p[0]), float(p[1]), float(p[2])); inst.rotation_degrees.y = float(r.get("yaw", 0))
		holder.add_child(inst)
		var inst_name := "%s_%d" % [piece, k]; k += 1
		if not sha.has(piece): sha[piece] = FileAccess.get_sha256(path)
		var before := cells.size()
		var touched := {}
		for c0: Vector2i in cells: touched[c0] = _count(cells[c0])
		cur_strip = no_trees and not piece.begins_with("t_")
		cur_trees.clear(); cur_ground.clear(); cur_wells.clear()
		if cur_strip: _scan_trees(inst)
		_walk(inst, piece, inst_name)
		for c1: Vector2i in cells:
			if not touched.has(c1) or touched[c1] != _count(cells[c1]): cells[c1].pieces[inst_name] = [piece, sha[piece], p, float(r.get("yaw", 0))]
		# the parking stalls a piece records, in grid-frame coordinates: [x, y, z, yaw, grade]
		if inst.has_meta(&"stalls"):
			for s: Array in inst.get_meta(&"stalls"):
				var wp := inst.global_transform * Vector3(float(s[0]), float(s[3]) if s.size() >= 5 else 0.0, float(s[1]))
				var cs := _cell_of(wp)
				if _cell_wanted(cs): _cell(cs).stalls.append([wp.x, wp.y, wp.z, float(s[2]) + float(r.get("yaw", 0)), float(s[4]) if s.size() >= 5 else 0.0])
		holder.remove_child(inst); inst.free(); arr_cache.clear()
		if before == -1: pass
	print("BAKE routed %d pieces in %d ms: %s" % [k, Time.get_ticks_msec() - t0, str(stat)])
	var routed: int = stat.merged + stat.instanced + stat.pass + stat.far + stat.far_dropped + stat.skipped_cell
	print("BAKE check props in=%d routed=%d %s" % [stat.props_in, routed, "OK" if routed >= stat.props_in else "MISMATCH"])
	if no_trees: print("BAKE trees out: %d trees and palms left out (%d trunk colliders), %d wells paved over, %d wells left open (odd shape or a bed)" % [int(stat.trees_out), int(stat.tree_cols_out), int(stat.wells_filled), int(stat.wells_left)])
	# pass 2 needs the meshes again: reload pieces lazily through the cached PackedScenes (the Mesh objects are kept alive by the records)
	var tot := {"draw_nodes": 0, "nodes": 0}
	for c: Vector2i in cells:
		var cnt := _build_cell(c)
		tot.draw_nodes += cnt.draw_nodes; tot.nodes += cnt.nodes
		manifest_cells["%d_%d" % [c.x, c.y]] = {"pieces": cells[c].pieces.values(), "draw_nodes": cnt.draw_nodes, "nodes": cnt.nodes}
		arr_cache.clear()
		print("BAKE cell %d_%d draw nodes=%d nodes=%d %s" % [c.x, c.y, cnt.draw_nodes, cnt.nodes, error_string(cnt.err)])
	if fg_on:
		var fgs: Dictionary = await _build_far_ground()
		print("BAKE far ground: %s" % str(fgs))
	var fw := _build_far()
	print("BAKE far world: %d meshes, %d triangles" % [fw.meshes, fw.tris])
	# lib/warm.scn: one small draw of every material and vertex format the bake made, for city_stream.warm_up()
	var wroot := Node3D.new(); wroot.name = "Warm"; var wi := 0
	for wk: String in warm:
		var wnode: Node3D = warm[wk]; wnode.name = "w%d" % wi; wnode.position = Vector3((wi % 8) * 0.6 - 2.1, (wi / 8) * 0.6 - 1.2, 0); wi += 1
		wroot.add_child(wnode)
	_own(wroot, wroot)
	var wps := PackedScene.new(); wps.pack(wroot); ResourceSaver.save(wps, out + "lib/warm.scn", ResourceSaver.FLAG_COMPRESS); wroot.free()
	for mk: String in mats: keep[(mats[mk] as Material).resource_path] = true
	# The net under all of the above: any texture, shader or material file a cell needs that is not already held from
	# the start is added to the list the streamer holds. Printed, so new content that brings a new kind shows up here.
	var held := {}
	for kp: String in keep: held[kp] = true; _deps(kp, held)
	for hp: String in [out + "far/far_world.scn", out + "lib/warm.scn"]:
		if ResourceLoader.exists(hp): held[hp] = true; _deps(hp, held)
	var late := {}
	for ck: Vector2i in cells:
		var seen := {}
		_deps(out + "cells/cell_%d_%d.scn" % [ck.x, ck.y], seen)
		for sp: String in seen:
			if not held.has(sp) and sp.get_extension() in ["png", "jpg", "webp", "gdshader", "gdshaderinc", "tres", "gd"]: late[sp] = true
	for lp: String in late: keep[lp] = true
	print("BAKE check first use: %d texture / shader / material files the cells need were not held from the start, now on the keep list: %s" % [late.size(), str(late.keys()).substr(0, 600)])
	var man := {"version": VERSION, "keep": keep.keys(), "warm": wi, "layout_sha": FileAccess.get_sha256(LAYOUT), "area": area, "tint": tint_on, "no_trees": no_trees, "wells_filled": well_fill and no_trees, "cells": manifest_cells, "far": fw, "stat": stat, "cell_m": CELL}
	var f := FileAccess.open(out + "manifest.json", FileAccess.WRITE); f.store_string(JSON.stringify(man, " ")); f.close()
	print("BAKE collision: %d triangle shapes cut into pieces, %d pieces in all, largest %d triangles; shape kinds left out: %s" % [int(stat.col_split), int(stat.col_pieces), int(stat.col_piece_max), str(stat.get("col_unknown", {}))])
	print("BAKE_DONE cells=%d draw nodes=%d nodes=%d lib meshes=%d shapes=%d materials=%d in %d ms" % [cells.size(), tot.draw_nodes, tot.nodes, lib_mesh.size(), int(stat.get("col_shapes", 0)), mats.size(), Time.get_ticks_msec() - t0])
	quit()

func _count(c: Dictionary) -> int:
	var n: int = c.bld.size() + c.ground.size() + c.wear.size() + c.misc.size() + c.col.size()
	for k: Array in c.merged: n += c.merged[k].items.size()
	for k2: Array in c.inst: n += c.inst[k2].xfs.size()
	return n
