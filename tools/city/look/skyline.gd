extends RefCounted
## THE SKYLINE RING (20 Nov, Yasin: "PLACE FLAT CARD ACCURATE VIEWS OF SAN DIEGO TO ALL FOUR SIDES, WHATEVER IS ACTUALLY
## VISIBLE WHEN LOOKED TOWARD THAT DIRECTION FROM THE ISLAND, FLATCARDS SHOULD BE ALWAYS DISPLAYED, IMMUNE TO THE LOD,
## EVER VISIBLE"). One mesh, one material, ONE DRAW: a 360-degree ring of painted cards round the horizon (no seams:
## the texture wraps), from map_dc/coronado/city_kit/skyline/ (painted by tools/city/look/make_skyline.py from real
## positions and heights, README in review/skyline/). Added by the streamer (city_stream.gd) next to the far world, so
## it is there wherever the city is drawn; the look (look.gd) tints it to the time of day.
## Never culled or faded: a custom AABB of 200 km round the origin (always holds the camera), no visibility range, no
## LOD, no shadow; the shader draws it at the far end of the depth range (skyline.gdshader), so camera.far (900 m)
## never clips it and every object stands in front of it.
## Two rings in the one mesh, far first (drawn in index order, alpha blended):
##   FAR   mountains, mesas, Tijuana, the islands, the sea to the horizon and a haze band: by direction only;
##   NEAR  downtown, the shipyards, North Island, Point Loma: points on a ring r(phi) 2-6.4 km out at their real
##         distance, so they shift as the camera crosses the island (parallax);
##   SOLIDS the bridge and Coronado Shores (0.2-3 km from parts of the island, too near for a card): plain boxes at
##         their true places, seen from the real camera, still drawn at the far end of the depth range.

const DIR := "res://map_dc/coronado/city_kit/skyline/"
const SHADER := "res://tools/city/look/skyline.gdshader"
const SEGS := 360            ## columns of the ring (one a degree)
const FAR_LOW := -40.0       ## the far ring goes on down to here (the sea's colour), for high cameras

static var _mat: ShaderMaterial
static var _meta: Dictionary

static func meta() -> Dictionary:
	if _meta.is_empty(): _meta = JSON.parse_string(FileAccess.get_file_as_string(DIR + "skyline.json"))
	return _meta

static func material() -> ShaderMaterial:
	if _mat == null:
		var m := meta()
		_mat = ShaderMaterial.new(); _mat.shader = load(SHADER)
		_mat.set_shader_parameter(&"day_tex", load(DIR + "skyline_day.png"))
		_mat.set_shader_parameter(&"lights_tex", load(DIR + "skyline_lights.png"))
		var c: Array = m.centre_grid
		_mat.set_shader_parameter(&"centre", Vector2(float(c[0]), float(c[1])))
		_mat.render_priority = Material.RENDER_PRIORITY_MIN      # first of the see-through things: lamp halos stay in front of it
	return _mat

## the near ring's radius (m) at grid azimuth phi (degrees from -Z, clockwise), smooth between the table's points
static func ring_r(phi: float, ring: Array) -> float:
	phi = fposmod(phi, 360.0)
	for i in ring.size() - 1:
		var a: Array = ring[i]; var b: Array = ring[i + 1]
		if phi <= float(b[0]):
			var f := (phi - float(a[0])) / maxf(float(b[0]) - float(a[0]), 0.001); f = f * f * (3.0 - 2.0 * f)
			return lerpf(float(a[1]), float(b[1]), f)
	return float((ring[ring.size() - 1] as Array)[1])

static func build() -> MeshInstance3D:
	var m := meta()
	var nel: Array = m.near_el; var fel: Array = m.far_el; var rows: Array = m.rows; var ring: Array = m.ring
	var H := float(rows[0]) + float(rows[1]); var eye := float(m.eye_m)
	var c: Array = m.centre_grid; var cx := float(c[0]); var cz := float(c[1])
	var V := PackedVector3Array(); var UV := PackedVector2Array(); var K := PackedVector2Array(); var C := PackedColorArray(); var I := PackedInt32Array()
	var half := 0.5 / H
	# FAR: three rows of vertices (top, bottom of the painted part, the sea's colour on down to FAR_LOW)
	var far_rows := [[float(fel[0]), float(rows[0]) / H + half], [float(fel[1]), 1.0 - half], [FAR_LOW, 1.0 - half]]
	for j in SEGS + 1:
		var phi := 360.0 * j / SEGS; var s := sin(deg_to_rad(phi)); var co := cos(deg_to_rad(phi))
		for r: Array in far_rows:
			var e := deg_to_rad(float(r[0]))
			V.append(Vector3(s * cos(e), sin(e), -co * cos(e))); UV.append(Vector2(float(j) / SEGS, float(r[1]))); K.append(Vector2(0, 0)); C.append(Color(1, 1, 1))
	for j in SEGS:
		for k in 2:
			var a := j * 3 + k; var b := (j + 1) * 3 + k
			I.append_array([a, b, a + 1, b, b + 1, a + 1])
	# NEAR: two rows on the ring, heights eye + tan(elevation) x r (the paint is in elevation as seen from the centre)
	var n0 := V.size()
	for j in SEGS + 1:
		var phi := 360.0 * j / SEGS; var s := sin(deg_to_rad(phi)); var co := cos(deg_to_rad(phi)); var rr := ring_r(phi, ring)
		for k in 2:
			var e := float(nel[k]); var v := half if k == 0 else float(rows[0]) / H - half
			V.append(Vector3(cx + s * rr, eye + tan(deg_to_rad(e)) * rr, cz - co * rr)); UV.append(Vector2(float(j) / SEGS, v)); K.append(Vector2(1, 0)); C.append(Color(1, 1, 1))
	for j in SEGS:
		var a := n0 + j * 2; var b := n0 + (j + 1) * 2
		I.append_array([a, b, a + 1, b, b + 1, a + 1])
	# SOLIDS: the bridge and Coronado Shores as boxes at their true places (make_skyline.py says why), drawn last
	for q: Array in m.get("solids", []):
		var col: Array = q[4]; var b0 := V.size()
		for k in 4:
			var p: Array = q[k]
			V.append(Vector3(float(p[0]), float(p[1]), float(p[2]))); UV.append(Vector2.ZERO); K.append(Vector2(2, 0))
			C.append(Color(float(col[0]), float(col[1]), float(col[2]), float(col[3])))
		I.append_array([b0, b0 + 1, b0 + 2, b0, b0 + 2, b0 + 3])
	var arr := []; arr.resize(Mesh.ARRAY_MAX)
	arr[Mesh.ARRAY_VERTEX] = V; arr[Mesh.ARRAY_TEX_UV] = UV; arr[Mesh.ARRAY_TEX_UV2] = K; arr[Mesh.ARRAY_COLOR] = C; arr[Mesh.ARRAY_INDEX] = I
	var am := ArrayMesh.new(); am.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arr)
	var mi := MeshInstance3D.new(); mi.name = "skyline"; mi.mesh = am; mi.material_override = material()
	mi.top_level = true
	mi.custom_aabb = AABB(Vector3(-100000, -100000, -100000), Vector3(200000, 200000, 200000))      # holds every camera: never frustum-culled
	mi.extra_cull_margin = 16384.0
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	mi.gi_mode = GeometryInstance3D.GI_MODE_DISABLED
	mi.ignore_occlusion_culling = true
	mi.visibility_range_begin = 0.0; mi.visibility_range_end = 0.0      # no LOD / range fade
	mi.set_meta(&"tris", I.size() / 3)
	return mi
