shader_type spatial;
render_mode diffuse_lambert, specular_disabled;
// The far version of every car: one 60-triangle shape for all models (scaled per row to the model's size), all far
// cars of the city in one batch (CityTraffic, native/src/traffic_batches.*). Paint and glass from the small atlas.
// A row's custom data: (-, -, lamps on 0..1, 1 = a parked car: not drawn nearer than parked_cut, where the light model
// takes over, traffic_car.gdshader).
uniform sampler2D atlas : source_color, filter_linear_mipmap;
uniform float parked_cut = 35.0;

void vertex() {
	if (INSTANCE_CUSTOM.w > 0.5 && distance(MAIN_CAM_INV_VIEW_MATRIX[3].xyz, (MODEL_MATRIX * vec4(0.0, 0.0, 0.0, 1.0)).xyz) < parked_cut) VERTEX = vec3(0.0);
}

void fragment() {
	vec4 t = texture(atlas, UV);
	float pm = smoothstep(0.75, 0.95, t.a);
	float gm = (1.0 - smoothstep(0.62, 0.75, t.a)) * smoothstep(0.3, 0.42, t.a);
	ALBEDO = mix(t.rgb * mix(vec3(1.0), COLOR.rgb, pm), vec3(0.035, 0.045, 0.055), gm);   // (glass: dark from afar, as the model's reads)
	ROUGHNESS = 0.6;
}
