extends RefCounted
## Block-kit authoring helpers (pilot 16 Nov 2026). Used ONLY by the per-piece authoring scripts in
## tools/city/pilot/pieces/. Those scripts write frozen scene files to map_dc/coronado/city_kit/pieces/; a locked piece
## is never re-written (see map_dc/coronado/city_kit/locked.json), so changing this file cannot change a locked piece.
##
## Frame: piece-local, metres, X east along 10th St, -Z north along Amber Ave, Y up.

const KIT := "res://assets/coronado_kit/"
const MAT_DIR := "res://map_dc/coronado/city_kit/materials/"

## ---------------------------------------------------------------- ground materials (shared by all pieces)
## name -> [albedo texture, tile metres, roughness, tint]
const GROUND := {
	"asphalt": ["res://assets/roads/asphalt026c_color.jpg", 4.0, 0.92, Color(0.82, 0.82, 0.84)],
	"concrete": ["res://assets/roads/concrete034_color.jpg", 2.0, 0.85, Color(0.74, 0.72, 0.69)],
	"curb": ["res://assets/roads/concrete034_color.jpg", 1.0, 0.8, Color(0.66, 0.65, 0.63)],
	"grass": ["res://map_dc/coronado/terrain/textures/grass004/grass_albedo.jpg", 3.0, 0.95, Color(0.85, 0.95, 0.8)],
	"mulch": ["res://map_dc/coronado/terrain/textures/ground037/dry_albedo.jpg", 1.5, 0.98, Color(0.62, 0.5, 0.42)],
	"paving": ["res://map_dc/coronado/terrain/textures/travertine009", 2.0, 0.8, Color(1, 1, 1)],
	"white": ["res://assets/roads/roadlines022a_white_worn.png", 2.0, 0.7, Color(0.95, 0.95, 0.93)],
	"yellow": ["res://assets/roads/roadlines022a_yellow_worn.png", 2.0, 0.7, Color(0.95, 0.78, 0.25)],
	"gravel": ["res://map_dc/coronado/terrain/textures/gravel022/gravel_albedo.jpg", 2.0, 0.95, Color(0.82, 0.8, 0.76)],
	"tactile": ["res://assets/roads/concrete034_color.jpg", 1.0, 0.75, Color(0.92, 0.72, 0.22)],
	"wall": ["res://assets/roads/concrete034_color.jpg", 2.0, 0.9, Color(0.78, 0.76, 0.72)],
	# civic plazas (17 Nov): "paving" (travertine, white) and "concrete" render near white in the sun on big areas;
	# a weathered, darker paving for forecourts and plazas (a new material file: locked pieces keep theirs)
	"plaza": ["res://map_dc/coronado/terrain/textures/travertine009", 2.0, 0.85, Color(0.5, 0.48, 0.45)],
	"sand": ["res://map_dc/coronado/terrain/textures/ground054/sand_albedo.jpg", 3.0, 0.97, Color(0.93, 0.87, 0.74)],     # waterfront beach (17 Nov)
}

static func ground_mat(name: String) -> Material:
	return Ground.ground_mat(name)

static func tile_m(name: String) -> float:
	return float(GROUND[name][1])

## ---------------------------------------------------------------- ground mesh builder
## Collects triangles per material; UVs are world metres / tile size (top: x,z; walls: along, y).
class Ground:
	static func ground_mat(name: String) -> Material:
		var path := MAT_DIR + "g_%s.tres" % name
		if ResourceLoader.exists(path): return load(path)
		var g: Array = GROUND[name]
		var m := StandardMaterial3D.new()
		var tp: String = g[0]
		if DirAccess.dir_exists_absolute(tp):     # a folder: take its albedo jpg
			for f in DirAccess.get_files_at(tp):
				if f.ends_with(".jpg") and not f.contains("normal"): tp = tp.path_join(f); break
		var tex: Texture2D = load(tp) if ResourceLoader.exists(tp) else null
		if tex: m.albedo_texture = tex
		m.albedo_color = g[3]
		m.roughness = g[2]
		m.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS_ANISOTROPIC
		DirAccess.make_dir_recursive_absolute(MAT_DIR)
		ResourceSaver.save(m, path)
		return load(path)
	

	var surf := {}   # mat -> [PackedVector3Array verts, PackedVector3Array normals, PackedVector2Array uvs]

	func _s(m: String) -> Array:
		if not surf.has(m): surf[m] = [PackedVector3Array(), PackedVector3Array(), PackedVector2Array()]
		return surf[m]

	## one triangle; vertices are reordered so the face points to the side of `up_hint` (default up)
	func tri(m: String, a: Vector3, b: Vector3, c: Vector3, up_hint := Vector3.UP, wall_uv := false) -> void:
		var n := (b - a).cross(c - a)
		if n.length_squared() < 1e-10: return
		n = n.normalized()
		# Godot: front faces are clockwise as seen from the front, i.e. (b-a)x(c-a) points AWAY from the viewer.
		if n.dot(up_hint) > 0.0:
			var t := b; b = c; c = t; n = -n
		var s := _s(m); var tm := 1.0 / float(GROUND[m][1]) if GROUND.has(m) else 1.0
		var face_n := -n
		for p: Vector3 in [a, b, c]:
			s[0].append(p); s[1].append(face_n)
			if wall_uv:
				var along := p.x * absf(face_n.z) + p.z * absf(face_n.x)
				s[2].append(Vector2(along * tm, -p.y * tm))
			else:
				s[2].append(Vector2(p.x * tm, p.z * tm))

	func quad(m: String, a: Vector3, b: Vector3, c: Vector3, d: Vector3, up_hint := Vector3.UP, wall_uv := false) -> void:
		tri(m, a, b, c, up_hint, wall_uv); tri(m, a, c, d, up_hint, wall_uv)

	## flat-topped rectangle [x0,x1]x[z0,z1], heights from yfn(x, z), split so no cell is longer than `step` m
	func rect(m: String, x0: float, z0: float, x1: float, z1: float, yfn: Callable, step := 4.0) -> void:
		if x1 - x0 < 1e-4 or z1 - z0 < 1e-4: return
		var nx := maxi(1, ceili((x1 - x0) / step)); var nz := maxi(1, ceili((z1 - z0) / step))
		for i in nx:
			for j in nz:
				var xa := lerpf(x0, x1, float(i) / nx); var xb := lerpf(x0, x1, float(i + 1) / nx)
				var za := lerpf(z0, z1, float(j) / nz); var zb := lerpf(z0, z1, float(j + 1) / nz)
				quad(m, Vector3(xa, yfn.call(xa, za), za), Vector3(xb, yfn.call(xb, za), za), Vector3(xb, yfn.call(xb, zb), zb), Vector3(xa, yfn.call(xa, zb), zb))

	## simple polygon (no holes) in x,z; heights from yfn
	func poly(m: String, pts: PackedVector2Array, yfn: Callable) -> void:
		var idx := Geometry2D.triangulate_polygon(pts)
		for k in range(0, idx.size(), 3):
			var p := [pts[idx[k]], pts[idx[k + 1]], pts[idx[k + 2]]]
			tri(m, Vector3(p[0].x, yfn.call(p[0].x, p[0].y), p[0].y), Vector3(p[1].x, yfn.call(p[1].x, p[1].y), p[1].y), Vector3(p[2].x, yfn.call(p[2].x, p[2].y), p[2].y))

	## vertical face along a polyline in x,z: bottom heights ybot(x,z), top heights ytop(x,z); faces toward `out_side`
	## (+1 = left of the walking direction, -1 = right)
	func wall_line(m: String, pts: PackedVector2Array, ybot: Callable, ytop: Callable, out_side: float) -> void:
		for k in pts.size() - 1:
			var a := pts[k]; var b := pts[k + 1]
			var d := (b - a).normalized(); var o := Vector2(d.y, -d.x) * out_side
			var a0 := Vector3(a.x, ybot.call(a.x, a.y), a.y); var a1 := Vector3(a.x, ytop.call(a.x, a.y), a.y)
			var b0 := Vector3(b.x, ybot.call(b.x, b.y), b.y); var b1 := Vector3(b.x, ytop.call(b.x, b.y), b.y)
			if absf(a1.y - a0.y) < 0.002 and absf(b1.y - b0.y) < 0.002: continue
			quad(m, a0, b0, b1, a1, Vector3(o.x, 0, o.y), true)

	func build() -> ArrayMesh:
		var am := ArrayMesh.new()
		for m: String in surf:
			var s: Array = surf[m]
			if s[0].is_empty(): continue
			var arr := []; arr.resize(Mesh.ARRAY_MAX)
			arr[Mesh.ARRAY_VERTEX] = s[0]; arr[Mesh.ARRAY_NORMAL] = s[1]; arr[Mesh.ARRAY_TEX_UV] = s[2]
			var st := SurfaceTool.new(); st.create_from_arrays(arr); st.index(); st.generate_tangents()
			var a2 := st.commit_to_arrays()
			am.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, a2)
			am.surface_set_material(am.get_surface_count() - 1, ground_mat(m))
			am.surface_set_name(am.get_surface_count() - 1, m)
		return am

	func tri_count() -> int:
		var n := 0
		for m: String in surf: n += surf[m][0].size() / 3
		return n

## Paint inside a road rectangle: the rectangle is cut along every paint edge into cells, each cell is either paint
## (white / yellow) or asphalt. Paint and asphalt share one plane with no overlap, so nothing can flicker.
## paints: Array of [x0, z0, x1, z1, mat]; mat "-" leaves a hole (something else is built there, e.g. steps)
static func painted_rect(g: Ground, x0: float, z0: float, x1: float, z1: float, paints: Array, yfn: Callable, base := "asphalt", merge := true) -> void:
	var xs := {x0: true, x1: true}; var zs := {z0: true, z1: true}
	var inside: Array = []
	for p: Array in paints:
		var px0 := maxf(p[0], x0); var px1 := minf(p[2], x1); var pz0 := maxf(p[1], z0); var pz1 := minf(p[3], z1)
		if px1 - px0 < 1e-4 or pz1 - pz0 < 1e-4: continue
		inside.append([px0, pz0, px1, pz1, p[4]]); xs[px0] = true; xs[px1] = true; zs[pz0] = true; zs[pz1] = true
	var xa: Array = xs.keys(); xa.sort(); var za: Array = zs.keys(); za.sort()
	# merge runs of same-material cells along z per x column to keep the triangle count low
	for i in xa.size() - 1:
		var cx: float = (xa[i] + xa[i + 1]) * 0.5
		var run_m := ""; var run_z0 := 0.0
		for j in za.size() - 1:
			var cz: float = (za[j] + za[j + 1]) * 0.5
			var m := base
			for p: Array in inside:
				if cx > p[0] and cx < p[2] and cz > p[1] and cz < p[3]: m = p[4]; break
			# merge = false: every cell on its own (all cells share the global grid lines, so no T-joints: hairline
			# cracks showed the ground below where a merged run's long edge met two shorter cells, Yasin 19 Nov)
			if j == 0 or m != run_m or not merge:
				if j > 0 and run_m != "-": g.rect(run_m, xa[i], run_z0, xa[i + 1], za[j], yfn)
				run_m = m; run_z0 = za[j]
		if run_m != "-": g.rect(run_m, xa[i], run_z0, xa[i + 1], za[za.size() - 1], yfn)

## fill the hole a smooth arrow (site.gd arrow2) left in a painted_rect: the arrow polygon in white, the box around it
## in `base`, split along the shaft so each side is a simple polygon (no holes to triangulate)
static func fill_arrow(g: Ground, a: Dictionary, yfn: Callable, base := "asphalt", mat := "white") -> void:
	var bx: Array = a.box; var c: float = a.c
	var halves: Array = []
	if String(a.axis) == "x":
		halves = [[bx[0], bx[1], c, bx[3]], [c, bx[1], bx[2], bx[3]]]
	else:
		halves = [[bx[0], bx[1], bx[2], c], [bx[0], c, bx[2], bx[3]]]
	var arrow: PackedVector2Array = a.poly
	for h: Array in halves:
		var hp := PackedVector2Array([Vector2(h[0], h[1]), Vector2(h[2], h[1]), Vector2(h[2], h[3]), Vector2(h[0], h[3])])
		for r: PackedVector2Array in Geometry2D.clip_polygons(hp, arrow):
			if r.size() >= 3: g.poly(base, r, yfn)
	g.poly(mat, arrow, yfn)

## quarter-circle points from angle a0 to a1 (radians) around c, radius r (x,z)
static func arc(c: Vector2, r: float, a0: float, a1: float, segs := 10) -> PackedVector2Array:
	var out := PackedVector2Array()
	for i in segs + 1:
		var a := lerpf(a0, a1, float(i) / segs)
		out.append(c + Vector2(cos(a), sin(a)) * r)
	return out

## ---------------------------------------------------------------- wear materials (city1: "everything looks brand new")
const PROP_WEAR := "res://map_dc/coronado/city_kit/shaders/prop_wear_fix.gdshader"   # kit shader with the 4.7 compile fix
const BLDG_WEAR := "res://map_dc/coronado/city_kit/shaders/bldg_wear.gdshader"
const GRIME := "res://assets/coronado_kit/atlases/props_grime.png"
## props: clean still carries a light film (0.2), worn 0.55, dirty / rusty 1.0 (kit README: wear is the shader)
const COND_WEAR := {"clean": 0.2, "worn": 0.55, "dirty": 1.0, "rusty": 1.0}

static func _orm_of(m: BaseMaterial3D) -> Texture2D:
	if m.roughness_texture: return m.roughness_texture
	if m.ao_texture: return m.ao_texture
	return null

## shared ShaderMaterial for a kit prop material at a wear level (saved once, reused by every piece)
static func prop_wear_mat(src: Material, wear: float) -> Material:
	if not (src is BaseMaterial3D): return src
	var b: BaseMaterial3D = src
	if b.transparency != BaseMaterial3D.TRANSPARENCY_DISABLED: return src     # foliage / cut-outs keep their own
	# keep the kit's double-sidedness (fences, gates: culling off) or panels vanish when seen from behind
	var two := b.cull_mode == BaseMaterial3D.CULL_DISABLED
	var key := "pw_%s_%d%s.tres" % [b.albedo_texture.resource_path.get_file().get_basename() if b.albedo_texture else "none", int(wear * 100.0), "_2s" if two else ""]
	var path := MAT_DIR + key
	if ResourceLoader.exists(path): return load(path)
	var m := ShaderMaterial.new(); m.shader = load(PROP_WEAR.replace(".gdshader", "_2s.gdshader") if two else PROP_WEAR)
	m.set_shader_parameter(&"albedo_tex", b.albedo_texture)
	m.set_shader_parameter(&"normal_tex", b.normal_texture)
	m.set_shader_parameter(&"orm_tex", _orm_of(b))
	m.set_shader_parameter(&"grime_tex", load(GRIME))
	m.set_shader_parameter(&"wear", wear)
	DirAccess.make_dir_recursive_absolute(MAT_DIR); ResourceSaver.save(m, path)
	return load(path)

## "iron" condition: the clean kit model with its white metalwork turned to weathered black iron (prop_iron.gdshader).
## A new material file of its own: no existing (locked) prop material changes.
static func prop_iron_mat(src: Material, shader := "prop_iron", prefix := "pi_") -> Material:
	if not (src is BaseMaterial3D): return src
	var b: BaseMaterial3D = src
	var path := MAT_DIR + prefix + "%s.tres" % (b.albedo_texture.resource_path.get_file().get_basename() if b.albedo_texture else "none")
	if ResourceLoader.exists(path): return load(path)
	var m := ShaderMaterial.new(); m.shader = load(PROP_WEAR.replace("prop_wear_fix", shader))
	m.set_shader_parameter(&"albedo_tex", b.albedo_texture)
	m.set_shader_parameter(&"normal_tex", b.normal_texture)
	m.set_shader_parameter(&"orm_tex", _orm_of(b))
	m.set_shader_parameter(&"grime_tex", load(GRIME))
	m.set_shader_parameter(&"wear", 0.55)
	DirAccess.make_dir_recursive_absolute(MAT_DIR); ResourceSaver.save(m, path)
	return load(path)

## shared weathered building material (near and mid tiers; the far tier keeps its baked colour-only material)
static func bldg_wear_mat(src: Material, wear: float) -> Material:
	if not (src is BaseMaterial3D): return src
	var b: BaseMaterial3D = src
	var key := "bw_%s_%d.tres" % [b.albedo_texture.resource_path.get_file().get_basename() if b.albedo_texture else "none", int(wear * 100.0)]
	var path := MAT_DIR + key
	if ResourceLoader.exists(path): return load(path)
	var m := ShaderMaterial.new(); m.shader = load(BLDG_WEAR)
	m.set_shader_parameter(&"albedo_tex", b.albedo_texture)
	m.set_shader_parameter(&"has_normal", b.normal_enabled and b.normal_texture != null)
	m.set_shader_parameter(&"normal_tex", b.normal_texture)
	var orm := _orm_of(b)
	m.set_shader_parameter(&"has_orm", orm != null); m.set_shader_parameter(&"orm_tex", orm)
	m.set_shader_parameter(&"has_emission", b.emission_enabled and b.emission_texture != null)
	m.set_shader_parameter(&"emission_tex", b.emission_texture)
	m.set_shader_parameter(&"grime_tex", load(GRIME))
	m.set_shader_parameter(&"wear", wear)
	DirAccess.make_dir_recursive_absolute(MAT_DIR); ResourceSaver.save(m, path)
	return load(path)

## ---------------------------------------------------------------- ground wear decals (main branch photo atlas)
## Tiles of map_dc/coronado/streets/street_wear/wear_atlas.png (street_wear_atlas.gd):
##  0 crack_a 1 crack_b 2 sealed_a 3 sealed_b 4 patch_a 5 patch_b 6 oil_a 7 oil_b 8 tyre 9 manhole 10 drain 11 utility
##  12 valve 13 paint 14 grime 15 scuff
const WEAR_ATLAS := "res://map_dc/coronado/streets/street_wear/wear_atlas.png"
class Decals:
	var V := PackedVector3Array(); var N := PackedVector3Array(); var UV := PackedVector2Array(); var C := PackedColorArray()
	var count := 0
	static func uvr(tile: int) -> Rect2:
		var cx := tile % 4; var cy := tile / 4; var ins := 4.0 / 1024.0
		return Rect2(cx / 4.0 + ins, cy / 4.0 + ins, 0.25 - 2.0 * ins, 0.25 - 2.0 * ins)
	## a flat mark lying on the ground: centre c (x, z), size along / across (sx, sz), yaw (deg), heights from yfn
	func add(tile: int, c: Vector2, yaw: float, sx: float, sz: float, yfn: Callable, tint := Color(1, 1, 1, 0.8), lift := 0.012, flip := false) -> void:
		var r := uvr(tile); var b := Basis(Vector3.UP, deg_to_rad(yaw))
		var corners: Array[Vector2] = [Vector2(-sx, -sz), Vector2(sx, -sz), Vector2(sx, sz), Vector2(-sx, sz)]
		var uvs: Array[Vector2] = [Vector2(0, 0), Vector2(1, 0), Vector2(1, 1), Vector2(0, 1)]
		var pts: Array[Vector3] = []
		for k in 4:
			var o := b * Vector3(corners[k].x * 0.5, 0.0, corners[k].y * 0.5)
			var x := c.x + o.x; var z := c.y + o.z
			pts.append(Vector3(x, float(yfn.call(x, z)) + lift, z))
		for tri in [[0, 1, 2], [0, 2, 3]]:     # front face up (tested 16 Nov: the other order was culled, marks invisible)
			for k: int in tri:
				V.append(pts[k]); N.append(Vector3.UP)
				var u: Vector2 = uvs[k]
				if flip: u.x = 1.0 - u.x
				UV.append(r.position + u * r.size); C.append(tint)
		count += 1
	## a vertical mark (kerb paint): quad a0-b0-b1-a1 facing `out`, stretched paint tile
	func add_face(tile: int, a0: Vector3, b0: Vector3, b1: Vector3, a1: Vector3, out: Vector3, tint: Color) -> void:
		var r := uvr(tile)
		var pts: Array[Vector3] = [a0 + out * 0.006, b0 + out * 0.006, b1 + out * 0.006, a1 + out * 0.006]
		var n := (pts[1] - pts[0]).cross(pts[3] - pts[0]).normalized()
		var order := [[0, 2, 1], [0, 3, 2]] if n.dot(out) > 0.0 else [[0, 1, 2], [0, 2, 3]]
		var uvs: Array[Vector2] = [Vector2(0, 1), Vector2(1, 1), Vector2(1, 0), Vector2(0, 0)]
		for tri in order:
			for k: int in tri:
				V.append(pts[k]); N.append(out.normalized()); UV.append(r.position + uvs[k] * r.size); C.append(tint)
		count += 1
	func build() -> MeshInstance3D:
		if V.is_empty(): return null
		var arr := []; arr.resize(Mesh.ARRAY_MAX)
		arr[Mesh.ARRAY_VERTEX] = V; arr[Mesh.ARRAY_NORMAL] = N; arr[Mesh.ARRAY_TEX_UV] = UV; arr[Mesh.ARRAY_COLOR] = C
		var am := ArrayMesh.new(); am.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arr)
		var path := "res://map_dc/coronado/city_kit/materials/wear_decal.tres"
		if not ResourceLoader.exists(path):
			var m := ShaderMaterial.new(); m.shader = load("res://map_dc/coronado/city_kit/shaders/wear_decal.gdshader")
			m.set_shader_parameter(&"atlas", load("res://map_dc/coronado/streets/street_wear/wear_atlas.png"))
			ResourceSaver.save(m, path)
		am.surface_set_material(0, load(path))
		var mi := MeshInstance3D.new(); mi.name = "wear"; mi.mesh = am
		mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		mi.visibility_range_end = 100.0
		return mi

## ---------------------------------------------------------------- kit buildings
static func _first_mesh(n: Node) -> MeshInstance3D:
	if n is MeshInstance3D: return n
	for c in n.get_children():
		var r := _first_mesh(c)
		if r: return r
	return null

static func _tier_file(dir: String, tier: String) -> String:
	for f in DirAccess.get_files_at(dir):
		if f.ends_with("_%s.glb" % tier) or f.ends_with("_%s.scn" % tier): return dir.path_join(f)
	return ""

## building folder: kit buildings ("industrial/ind_factory"), kit modular examples ("modular/examples/mod_wh_shed") or
## city-kit merged assemblies ("ck/mod_wh_dist", made by tools/city/pilot/modular/merge_modular.gd)
const CK_BLD := "res://map_dc/coronado/city_kit/buildings/"
static func _bdir(folder: String) -> String:
	if folder.begins_with("ck/"): return CK_BLD + folder.substr(3)
	return KIT + ("" if folder.begins_with("modular/") else "buildings/") + folder

## A kit building: near 0-60 m (shadows on), mid 60-220, far 220-1500, plus collision boxes.
## folder = e.g. "commercial/com_bakery". pos = front-centre of footprint at ground? No: kit origin is the footprint
## centre at ground; front (doors) face +Z. rot_deg turns +Z toward the street.
static func building(parent: Node3D, folder: String, pos: Vector3, rot_deg: float, label := "", wear := 0.65) -> Node3D:
	var dir := _bdir(folder)
	var root := Node3D.new(); root.name = label if label != "" else folder.get_file()
	root.set_meta(&"kit", folder)      # the validator finds the stats by this, whatever the node is called
	root.position = pos; root.rotation_degrees.y = rot_deg
	parent.add_child(root)
	var ranges := {"near": [0.0, 62.0], "mid": [58.0, 222.0], "far": [218.0, 1500.0]}
	for tier: String in ranges:
		var f := _tier_file(dir, tier)
		if f == "": continue
		var ps: PackedScene = load(f)
		var inst := ps.instantiate()
		var src := _first_mesh(inst)
		if src:
			var mi := MeshInstance3D.new(); mi.name = tier; mi.mesh = src.mesh
			mi.transform = src.transform
			mi.visibility_range_begin = ranges[tier][0]; mi.visibility_range_end = ranges[tier][1]
			mi.visibility_range_begin_margin = 2.0 if tier != "near" else 0.0
			mi.visibility_range_end_margin = 2.0
			mi.visibility_range_fade_mode = GeometryInstance3D.VISIBILITY_RANGE_FADE_DISABLED
			mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON if tier == "near" else GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
			if tier != "far" and src.mesh.get_surface_count() > 0:
				for si in src.mesh.get_surface_count():
					mi.set_surface_override_material(si, bldg_wear_mat(src.mesh.surface_get_material(si), wear))
			root.add_child(mi)
		inst.free()
	var cf := _tier_file(dir, "col")
	if cf != "":
		var inst2: Node = (load(cf) as PackedScene).instantiate()
		var cm := _first_mesh(inst2)
		if cm and cm.mesh:
			var body := StaticBody3D.new(); body.name = "col"
			var cs := CollisionShape3D.new(); cs.shape = cm.mesh.create_trimesh_shape(); cs.transform = cm.transform
			body.add_child(cs); root.add_child(body)
		inst2.free()
	return root

static func building_stats(folder: String) -> Dictionary:
	var p := _bdir(folder) + "/stats.json"
	var v: Variant = JSON.parse_string(FileAccess.get_file_as_string(p))
	return v if typeof(v) == TYPE_DICTIONARY else {}

## ---------------------------------------------------------------- props (MultiMesh per type and tier)
static var _manifest := {}

static func manifest(base: String) -> Dictionary:
	if _manifest.is_empty():
		for f in ["props/manifest_city.json", "props/manifest_construction.json", "props/manifest_fences.json", "props/manifest_house.json", "props/manifest_park.json", "props/manifest_street.json", "props/manifest_yard.json", "props/manifest_wfquay.json", "props/manifest_wfpier.json", "props/manifest_wfgang.json", "props/manifest_wfmarina.json", "props/manifest_b2a.json", "props/manifest_b2b.json", "props/manifest_wfboats.json", "props/manifest_wfprom.json", "props/manifest_wfsmall.json", "props/manifest_inshared.json", "props/manifest_infood.json", "props/manifest_ingrocery.json", "props/manifest_inclothing.json", "props/manifest_insalon.json", "props/manifest_ingift.json", "props/manifest_inoffice.json", "props/manifest_inservices.json", "props/manifest_insport.json", "props/manifest_invenue.json", "foliage/manifest_foliage.json"]:
			var v: Variant = JSON.parse_string(FileAccess.get_file_as_string(KIT + f))
			var items: Array = v if v is Array else (v as Dictionary).values()
			for e: Dictionary in items: _manifest[String(e.file_base)] = e
	return _manifest.get(base, {})

static func prop_file(base: String, cond: String, tier: String) -> String:
	var e := manifest(base)
	var batch := String(e.get("batch", ""))
	var dir := KIT + ("foliage/" if batch == "foliage" else ("fences/" if batch == "fences" else "props/%s/" % batch))
	var f := dir + "%s_%s_%s.glb" % [base, cond, tier]
	if ResourceLoader.exists(f): return f
	# newer batches (waterfront, streetside) keep their files in sub-folders not named after the batch: search props/
	var name := "%s_%s_%s.glb" % [base, cond, tier]
	if _prop_index.is_empty(): _index_props(KIT + "props/")
	if _prop_index.has(name): return _prop_index[name]
	# clean-only batches: worn / dirty / rusty are the clean model with the wear shader (kit README), see Props.build
	var cf := "%s_clean_%s.glb" % [base, tier]
	if cond != "clean" and _prop_index.has(cf): return _prop_index[cf]
	return ""

static var _prop_index := {}
static func _index_props(dir: String) -> void:
	for f in DirAccess.get_files_at(dir):
		if f.ends_with(".glb"): _prop_index[f] = dir + f
	for d in DirAccess.get_directories_at(dir): _index_props(dir + d + "/")

class Props:
	var items := {}    # "base|cond" -> Array[Transform3D]
	var col_items: Array = []   # [base, cond, Transform3D]

	## place one prop: base = manifest file_base (e.g. "prop_hydrant_red"), yaw degrees (front = +Z turned by yaw).
	## scale (17 Nov, trees of different ages): uniform size factor for the drawn instance; the collider keeps the
	## unscaled shape (physics dislikes scaled shapes; a trunk a few cm thinner or thicker does not matter).
	func add(base: String, cond: String, pos: Vector3, yaw_deg := 0.0, collide := true, scale := 1.0) -> void:
		var k := base + "|" + cond
		if not items.has(k): items[k] = []
		var b := Basis(Vector3.UP, deg_to_rad(yaw_deg))
		var t := Transform3D(b.scaled(Vector3.ONE * scale) if scale != 1.0 else b, pos)
		items[k].append(t)
		if collide: col_items.append([base, cond, Transform3D(b, pos)])

	func count() -> int:
		var n := 0
		for k in items: n += items[k].size()
		return n

	func build(parent: Node3D, kit: Script) -> void:
		var root := Node3D.new(); root.name = "Props"; parent.add_child(root)
		var ranges := {"near": [0.0, 62.0], "mid": [58.0, 222.0], "far": [218.0, 1500.0]}
		for k: String in items:
			var base := k.get_slice("|", 0); var cond := k.get_slice("|", 1)
			var e: Dictionary = kit.manifest(base)
			var tiers: Dictionary = e.get("tiers", {"near": 0})
			var small := not tiers.has("mid")
			for tier: String in ["near", "mid", "far"]:
				if not tiers.has(tier): continue
				var f: String = kit.prop_file(base, cond, tier)
				if f == "":
					if tier == "near": push_warning("kit: no file for %s %s %s" % [base, cond, tier]); print("MISSING PROP %s %s" % [base, cond])
					continue
				var inst: Node = (load(f) as PackedScene).instantiate()
				var src: MeshInstance3D = kit._first_mesh(inst)
				if src == null: inst.free(); continue
				var mm := MultiMesh.new(); mm.transform_format = MultiMesh.TRANSFORM_3D; mm.mesh = src.mesh
				var ts: Array = items[k]; mm.instance_count = ts.size()
				for i in ts.size(): mm.set_instance_transform(i, ts[i] * src.transform)
				var mmi := MultiMeshInstance3D.new(); mmi.name = "%s_%s_%s" % [base, cond, tier]; mmi.multimesh = mm
				if src.mesh.get_surface_count() == 1 and cond == "iron":     # white kit metalwork painted black (balconies)
					mmi.material_override = kit.prop_iron_mat(src.mesh.surface_get_material(0))
				elif src.mesh.get_surface_count() == 1 and cond == "glass":   # bus shelter panes: light glass, worn (17 Nov)
					mmi.material_override = kit.prop_iron_mat(src.mesh.surface_get_material(0), "prop_glass", "pg_")
				elif src.mesh.get_surface_count() == 1 and cond == "net":    # tennis nets: two-sided see-through mesh + white tape
					mmi.material_override = kit.prop_iron_mat(src.mesh.surface_get_material(0), "prop_net", "pn_")
				elif src.mesh.get_surface_count() == 1 and kit.COND_WEAR.has(cond):
					var wm: Material = kit.prop_wear_mat(src.mesh.surface_get_material(0), kit.COND_WEAR[cond])
					if wm != src.mesh.surface_get_material(0): mmi.material_override = wm
				var r: Array = ranges[tier]
				mmi.visibility_range_begin = r[0]; mmi.visibility_range_end = 60.0 if small else r[1]
				mmi.visibility_range_end_margin = 2.0
				mmi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON if tier == "near" else GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
				root.add_child(mmi)
				inst.free()
		# collision: one shared shape per prop type, one CollisionShape3D per placed prop
		var body := StaticBody3D.new(); body.name = "PropCol"; root.add_child(body)
		var shapes := {}
		for c: Array in col_items:
			var base2: String = c[0]
			if not shapes.has(base2):
				var cf: String = kit.KIT + ""   # col file sits next to the near file: <base>_col.glb
				var nf: String = kit.prop_file(base2, c[1], "near")
				var colf := nf.get_base_dir().path_join(base2 + "_col.glb")
				shapes[base2] = null
				if ResourceLoader.exists(colf):
					var inst3: Node = (load(colf) as PackedScene).instantiate()
					var cm: MeshInstance3D = kit._first_mesh(inst3)
					if cm and cm.mesh: shapes[base2] = [cm.mesh.create_convex_shape(true, true), cm.transform]
					inst3.free()
			if shapes[base2] == null: continue
			var cs := CollisionShape3D.new(); cs.shape = shapes[base2][0]; cs.transform = (c[2] as Transform3D) * (shapes[base2][1] as Transform3D)
			body.add_child(cs)

## ---------------------------------------------------------------- layout: piece instances in the shared frame
const LAYOUT := "res://map_dc/coronado/city_kit/city_layout.json"

## Adds every instance of city_layout.json under `parent` (all pieces at the origin if there is no layout).
## skip: piece names to leave out. Returns the instance nodes.
static func place_layout(parent: Node3D, skip: Array = []) -> Array:
	var out: Array = []
	var dir := "res://map_dc/coronado/city_kit/pieces/"
	var rows: Array = []
	if FileAccess.file_exists(LAYOUT):
		var v: Variant = JSON.parse_string(FileAccess.get_file_as_string(LAYOUT))
		if v is Dictionary: rows = (v as Dictionary).get("instances", [])
	else:
		for f in DirAccess.get_files_at(dir):
			if f.ends_with(".scn"): rows.append({"piece": f.get_basename(), "pos": [0, 0, 0], "yaw": 0})
	# (17 Nov, road kit fleet) review rows from other files, so agents never edit the shared layout:
	# CITYKIT_LAYOUT_EXTRA = comma-separated res:// json files ({"instances": [...]}) appended to the layout;
	# CITYKIT_LAYOUT_ONLY = 1 skips the main layout rows (check / shoot a review area on its own)
	if OS.get_environment("CITYKIT_LAYOUT_ONLY") == "1": rows = []
	for xf: String in OS.get_environment("CITYKIT_LAYOUT_EXTRA").split(",", false):
		var xv: Variant = JSON.parse_string(FileAccess.get_file_as_string(xf.strip_edges()))
		if xv is Dictionary: rows.append_array((xv as Dictionary).get("instances", []))
		else: push_warning("layout: extra file unreadable " + xf)
	for r: Dictionary in rows:
		var name := String(r.piece)
		if name in skip: continue
		var path := dir + name + ".scn"
		if not ResourceLoader.exists(path): push_warning("layout: no piece " + name); continue
		var n: Node3D = (load(path) as PackedScene).instantiate()
		var p: Array = r.get("pos", [0, 0, 0])
		n.position = Vector3(float(p[0]), float(p[1]), float(p[2])); n.rotation_degrees.y = float(r.get("yaw", 0))
		n.name = "%s_%d" % [name, out.size()]     # (Godot replaces "@" in node names)
		n.set_meta(&"piece", name)
		parent.add_child(n); out.append(n)
	return out

## ---------------------------------------------------------------- save a piece
## Every node gets owner = root so the packed scene keeps it. Writes .scn (binary) and returns the path.
static func save_piece(root: Node3D, name: String) -> String:
	_own(root, root)
	var ps := PackedScene.new(); ps.pack(root)
	var dir := "res://map_dc/coronado/city_kit/pieces/"
	DirAccess.make_dir_recursive_absolute(dir)
	var path := dir + name + ".scn"
	var err := ResourceSaver.save(ps, path, ResourceSaver.FLAG_COMPRESS)
	print("PIECE %s saved (%s) nodes=%d" % [path, error_string(err), _count(root)])
	return path

static func _own(n: Node, owner: Node) -> void:
	for c in n.get_children():
		c.owner = owner; _own(c, owner)

static func _count(n: Node) -> int:
	var k := 1
	for c in n.get_children(): k += _count(c)
	return k
