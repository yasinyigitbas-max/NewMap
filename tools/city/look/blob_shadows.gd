extends RefCounted
## LOOK JOB 4 (18 Nov): soft blob shadows under the trees of a loaded cell, for the ground beyond the sun shadow.
## Without touching the bake: when a cell comes in, its plants are found in what it already holds
##  - instanced plants (MultiMesh with an rt_foliage_inst_* material): each instance's position, its mesh's size;
##  - merged plants (mesh with an rt_foliage_merged_* material): CUSTOM0.xyz of every vertex is its plant's foot
##    (bake_runtime.gd _merge), so the vertices grouped by foot give each plant's height and crown radius;
## and one MultiMesh of blobs (tools/city/look/blob.gdshader) is added to the cell. Stiff cut-outs (fences, chain-link)
## and plants under 1.2 m radius or 2.5 m height (shrubs, hedges) get none.
## READING THE MESHES COSTS CPU (tens of ms a cell in the cloud): fine for pictures, NOT for a phone drive, so the rig
## has it off by default (--blobs=1 turns it on). The bake should record the trees instead: docs/look_patches/blob_shadows.md.

const SHADER := "res://tools/city/look/blob.gdshader"
static var _mat: ShaderMaterial

static func material() -> ShaderMaterial:
	if _mat == null:
		_mat = ShaderMaterial.new(); _mat.shader = load(SHADER)
	return _mat

## [foot, height, radius] of every tree of a cell
static func find_trees(cell: Node) -> Array:
	var trees := {}      # rounded foot -> [foot, height, radius]
	for g: Node in cell.find_children("*", "GeometryInstance3D", true, false):
		var gi := g as GeometryInstance3D
		var sm := gi.material_override as ShaderMaterial
		if sm == null or sm.shader == null: continue
		var sp := sm.shader.resource_path
		if not sp.contains("rt_foliage_"): continue
		if gi is MultiMeshInstance3D:
			var mm := (gi as MultiMeshInstance3D).multimesh
			if mm == null or mm.mesh == null: continue
			var ab := mm.mesh.get_aabb()
			for i in mm.instance_count:
				if mm.use_custom_data and mm.get_instance_custom_data(i).g < 0.5: continue      # wind 0: a stiff cut-out
				var xf := gi.global_transform * mm.get_instance_transform(i)
				var s := xf.basis.get_scale()
				_keep(trees, xf.origin, (ab.position.y + ab.size.y) * s.y, maxf(ab.size.x * s.x, ab.size.z * s.z) * 0.5)
		elif gi is MeshInstance3D:
			var mesh := (gi as MeshInstance3D).mesh
			if mesh == null: continue
			for si in mesh.get_surface_count():
				var arr := mesh.surface_get_arrays(si)
				var V: PackedVector3Array = arr[Mesh.ARRAY_VERTEX]; var CU: PackedByteArray = arr[Mesh.ARRAY_CUSTOM0]
				if V.is_empty() or CU.size() < V.size() * 8: continue
				var per := {}      # foot (mesh space, rounded) -> [foot, max height, max radius]
				for k in range(0, V.size(), 3):      # every third vertex is plenty for a size
					var o := Vector3(CU.decode_half(k * 8), CU.decode_half(k * 8 + 2), CU.decode_half(k * 8 + 4))
					var key := Vector3i(roundi(o.x * 4.0), roundi(o.y * 4.0), roundi(o.z * 4.0))
					if not per.has(key):
						var w := CU.decode_half(k * 8 + 6); var page := floorf(w / 16.0)
						var wind := int(floorf((w - page * 16.0) / 2.0 + 0.5)) % 2
						per[key] = [o, 0.0, 0.0, wind]
					var e: Array = per[key]; var dv := V[k] - o
					e[1] = maxf(e[1], dv.y); e[2] = maxf(e[2], Vector2(dv.x, dv.z).length())
				for e2: Array in per.values():
					if int(e2[3]) == 0: continue
					_keep(trees, gi.global_transform * (e2[0] as Vector3), e2[1], e2[2])
	var out: Array = []
	for t: Array in trees.values():
		if float(t[1]) >= 2.5 and float(t[2]) >= 1.2: out.append(t)
	return out

static func _keep(trees: Dictionary, foot: Vector3, h: float, r: float) -> void:
	var key := Vector2i(roundi(foot.x), roundi(foot.z))      # near and mid tier of the same plant: one blob
	if trees.has(key):
		var e: Array = trees[key]; e[1] = maxf(e[1], h); e[2] = maxf(e[2], r)
	else: trees[key] = [foot, h, r]

## one MultiMesh of blobs for the cell (null if it has no trees)
static func build(cell: Node) -> MultiMeshInstance3D:
	var trees := find_trees(cell)
	if trees.is_empty(): return null
	var quad := QuadMesh.new(); quad.size = Vector2(1, 1)
	var mm := MultiMesh.new(); mm.transform_format = MultiMesh.TRANSFORM_3D; mm.use_custom_data = true; mm.mesh = quad
	mm.instance_count = trees.size()
	var lo := Vector3(1e9, 1e9, 1e9); var hi := -lo
	for i in trees.size():
		var t: Array = trees[i]; var f: Vector3 = t[0]
		mm.set_instance_transform(i, Transform3D(Basis(), f)); mm.set_instance_custom_data(i, Color(t[1], t[2], 0, 0))
		lo = lo.min(f); hi = hi.max(f)
	var mi := MultiMeshInstance3D.new(); mi.name = "look_blobs"; mi.multimesh = mm; mi.material_override = material()
	mi.top_level = true; mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	mi.custom_aabb = AABB(lo - Vector3(40, 5, 40), hi - lo + Vector3(80, 10, 80))      # the blobs are moved in the shader
	return mi
