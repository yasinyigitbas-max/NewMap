shader_type spatial;
render_mode diffuse_lambert;
// The traffic's cars (moving and parked), drawn as rows of a few batches by the C++ node CityTraffic
// (native/src/traffic_batches.*). Lean on purpose: ONE texture read a pixel, no reflection map, no damage.
// The car atlas (vehicles/models/Textures) tells the parts apart by its alpha, as in the game's car_paint shader:
//   ~1.0 body paint (takes the row's colour)   ~0.5 glass   ~0.0 lights, trim, tyres (their own colours)
// The lamps are their own batch (traffic_lamps.gdshader): these models do not mark their lamp texels.
// A row: its colour = the paint (linear), its custom data = (-, -, -, 1 = a PARKED car: it is drawn by this batch only nearer than parked_cut; beyond it the far batch
// (traffic_box.gdshader) draws it, cut at the same distance, so the two never show together and never leave a gap).
uniform sampler2D atlas : source_color, filter_linear_mipmap;
uniform float parked_cut = 35.0;

void vertex() {
	// (the main camera's place, also in the shadow passes, as the bake's tier shaders take it)
	if (INSTANCE_CUSTOM.w > 0.5 && distance(MAIN_CAM_INV_VIEW_MATRIX[3].xyz, (MODEL_MATRIX * vec4(0.0, 0.0, 0.0, 1.0)).xyz) >= parked_cut) VERTEX = vec3(0.0);
}

void fragment() {
	vec4 t = texture(atlas, UV);
	float pm = smoothstep(0.75, 0.95, t.a);
	float gm = (1.0 - smoothstep(0.62, 0.75, t.a)) * smoothstep(0.3, 0.42, t.a);
	ALBEDO = t.rgb * mix(vec3(1.0), COLOR.rgb, pm);
	ROUGHNESS = mix(mix(0.6, 0.34, pm), 0.08, gm);
	METALLIC = 0.0;
	SPECULAR = mix(0.4, 0.6, max(pm, gm));
}
