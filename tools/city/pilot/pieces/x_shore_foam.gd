extends SceneTree
## x_shore_foam (17 Nov, Yasin: "all the shores should have the bubbles of waterfront"): the waterfront's foam strip
## (shaders/shore_foam.gdshader, as in f_sw) along every beach of the island. Geometry from
## map_dc/coronado/city_kit/zoning/shore_foam.json (tools/city/pilot/zoning/shore_foam.py: the terrain's 0 m water line,
## grid frame). One MeshInstance per ~120 m chunk (one draw, culled at 220 m like f_sw), no props, no colliders.
## Placed at [0, 0, 0] in the grid frame (city_grid_layout.json). Rebuild after terrain.py + shore_foam.py.
const K := preload("res://tools/city/pilot/kit_lib.gd")

func _init() -> void: _run.call_deferred()

func _run() -> void:
	var root := Node3D.new(); root.name = "x_shore_foam"
	var j: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://map_dc/coronado/city_kit/zoning/shore_foam.json"))
	var rows_v: Array = j.rows_v
	var mat := ShaderMaterial.new(); mat.shader = load("res://map_dc/coronado/city_kit/shaders/shore_foam.gdshader")
	var nt := NoiseTexture2D.new(); nt.width = 256; nt.height = 256; nt.seamless = true; nt.generate_mipmaps = true
	var fn := FastNoiseLite.new(); fn.noise_type = FastNoiseLite.TYPE_CELLULAR; fn.frequency = 0.06
	fn.cellular_return_type = FastNoiseLite.RETURN_DISTANCE; nt.noise = fn
	mat.set_shader_parameter("foam_noise", nt)
	mat.set_shader_parameter("shore_v", float(j.shore_v))
	var ci := 0; var ntri := 0
	for c: Dictionary in j.chunks:
		var n := int(c.n); var nr := int(c.rows); var v: Array = c.v; var ux: Array = c.ux
		var st := SurfaceTool.new(); st.begin(Mesh.PRIMITIVE_TRIANGLES)
		var pt := func(i: int, k: int) -> Array:
			var o := (i * nr + k) * 3
			return [Vector3(float(v[o]), float(v[o + 1]), float(v[o + 2])), Vector2(float(ux[i]), float(rows_v[k]))]
		for i in n - 1:
			for k in nr - 1:
				var q: Array = [pt.call(i, k), pt.call(i + 1, k), pt.call(i + 1, k + 1), pt.call(i, k + 1)]
				for m: int in [0, 1, 2, 0, 2, 3]:
					st.set_normal(Vector3.UP); st.set_uv(q[m][1]); st.add_vertex(q[m][0])
				ntri += 2
		var mi := MeshInstance3D.new(); mi.name = "foam_%d" % ci; mi.mesh = st.commit()
		mi.material_override = mat
		mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		mi.visibility_range_end = 220.0
		root.add_child(mi); ci += 1
	print("x_shore_foam chunks=%d tris=%d" % [ci, ntri])
	K.save_piece(root, "x_shore_foam")
	quit()
