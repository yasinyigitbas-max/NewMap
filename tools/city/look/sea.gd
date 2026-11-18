extends RefCounted
## LOOK QUEUE 2, JOB 3: the sea of the test app, in the place of the flat green plane. Built once at start from
## tools/city/look/sea_map.png (tools/city/look/make_sea.py: depth and where the water lies, 8 m a texel):
## one mesh at the sea's 0 m, a 16 m grid where there is water (and 25 m onto the land, under the beach, so the real
## waterline is where the water cuts the beach: the 0 m contour the shore foam piece follows), and a skirt of a few big
## quads out to 8 km for the horizon. The depth rides in each vertex (COLOR.r), so the shader reads no depth texture
## and no depth buffer. One draw, about 33,000 triangles.

const MAP := "res://tools/city/look/sea_map.png"
const META := "res://tools/city/look/sea_map.json"
const SHADER := "res://tools/city/look/sea.gdshader"
const NOISE := "res://tools/city/look/sky_noise.png"
const EVERY := 2          ## texels per grid step (2 x 8 m = 16 m)
const FAR := 8000.0

static var _mat: ShaderMaterial

static func material() -> ShaderMaterial:
	if _mat == null:
		_mat = ShaderMaterial.new(); _mat.shader = load(SHADER); _mat.set_shader_parameter(&"ripple_tex", load(NOISE))
	return _mat

static func build() -> MeshInstance3D:
	var meta: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(META))
	var img := (load(MAP) as Texture2D).get_image()
	if img.is_compressed(): img.decompress()
	var x0 := float(meta.x0); var z0 := float(meta.z0); var step := float(meta.step); var deep := float(meta.deep)
	var W := img.get_width(); var H := img.get_height()
	var nx := (W - 1) / EVERY + 1; var nz := (H - 1) / EVERY + 1
	var V := PackedVector3Array(); var C := PackedColorArray(); var I := PackedInt32Array()
	var idx := PackedInt32Array(); idx.resize(nx * nz); idx.fill(-1)
	var lay := PackedByteArray(); lay.resize(nx * nz)
	for gz in nz:
		for gx in nx:
			lay[gz * nx + gx] = 1 if img.get_pixel(gx * EVERY, gz * EVERY).g > 0.5 else 0
	var vert := func(gx: int, gz: int) -> int:
		var k := gz * nx + gx
		if idx[k] < 0:
			idx[k] = V.size()
			V.append(Vector3(x0 + gx * EVERY * step, 0.0, z0 + gz * EVERY * step))
			C.append(Color(img.get_pixel(gx * EVERY, gz * EVERY).r, 0, 0, 1))
		return idx[k]
	for gz in nz - 1:
		for gx in nx - 1:
			if lay[gz * nx + gx] + lay[gz * nx + gx + 1] + lay[(gz + 1) * nx + gx] + lay[(gz + 1) * nx + gx + 1] == 0: continue
			var a: int = vert.call(gx, gz); var b: int = vert.call(gx + 1, gz); var c: int = vert.call(gx, gz + 1); var d: int = vert.call(gx + 1, gz + 1)
			I.append_array([a, b, c, b, d, c])
	# the skirt: deep water from the frame out to the horizon; not west of the frame between the island's two coasts
	# (the island runs on past the frame there)
	var gx1 := x0 + (nx - 1) * EVERY * step; var gz1 := z0 + (nz - 1) * EVERY * step
	var rects := [[-FAR, -FAR, FAR, z0], [-FAR, gz1, FAR, FAR], [gx1, z0, FAR, gz1],      # north, south, east
		[-FAR, z0, x0, -1600.0], [-FAR, 780.0, x0, gz1]]                                        # west, beyond the island's coasts
	for r: Array in rects:
		var b0 := V.size()
		for p: Vector2 in [Vector2(r[0], r[1]), Vector2(r[2], r[1]), Vector2(r[0], r[3]), Vector2(r[2], r[3])]:
			V.append(Vector3(p.x, 0.0, p.y)); C.append(Color(1, 0, 0, 1))
		I.append_array([b0, b0 + 1, b0 + 2, b0 + 1, b0 + 3, b0 + 2])
	var arr := []; arr.resize(Mesh.ARRAY_MAX)
	arr[Mesh.ARRAY_VERTEX] = V; arr[Mesh.ARRAY_COLOR] = C; arr[Mesh.ARRAY_INDEX] = I
	var n := PackedVector3Array(); n.resize(V.size()); n.fill(Vector3.UP); arr[Mesh.ARRAY_NORMAL] = n
	var am := ArrayMesh.new(); am.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arr)
	var mi := MeshInstance3D.new(); mi.name = "look_sea"; mi.mesh = am; mi.material_override = material()
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	mi.set_meta(&"tris", I.size() / 3); mi.set_meta(&"deep", deep)
	return mi
