shader_type spatial;
render_mode diffuse_lambert, specular_disabled;
// The far version of every car: one 60-triangle shape for all models (scaled per row to the model's size), all far
// cars of the city in one batch (CityTraffic, native/src/traffic_batches.*). Paint and glass from the small atlas.
// A row's custom data: (-, -, lamps on 0..1, 1 = a parked car: not drawn nearer than parked_cut, where the light model
// takes over, traffic_car.gdshader).
uniform sampler2D atlas : source_color, filter_linear_mipmap;
uniform float parked_cut = 35.0;

// B6 (Yasin 20 Nov: "everything inluding cars and trees snap in lod tiers"): a car crossing from one model to the next is
// drawn by both batches for a few metres, each keeping the pixels of a complementary 4x4 dither (CityTraffic sets the row
// colour's alpha: 1 = whole; f in (0, 1) = keep where the dither is under f; 1 + f = keep where it is not). Parked cars
// cross at parked_cut the same way, by their distance here (PARK_BAND metres).
const float PARK_BAND = 4.0;
varying float v_fade;
varying vec3 v_lp;      // the shape's own point and normal (look uplift: the far car drawn from its shape)
varying vec3 v_ln;
float ck_dither(vec2 p) {
	int x = int(mod(p.x, 4.0)), y = int(mod(p.y, 4.0));
	int i = x + y * 4;
	float m[16] = float[16](0.0, 8.0, 2.0, 10.0, 12.0, 4.0, 14.0, 6.0, 3.0, 11.0, 1.0, 9.0, 15.0, 7.0, 13.0, 5.0);
	return (m[i] + 0.5) / 16.0;
}
void ck_fade_discard(float fa, vec2 frag) {
	if (fa > 0.999 && fa < 1.001) return;
	float d = ck_dither(frag);
	if (fa <= 1.0) { if (d >= fa) discard; }
	else if (d < fa - 1.0) discard;
}

void vertex() {
	v_fade = COLOR.a;
	v_lp = VERTEX; v_ln = NORMAL;
	if (INSTANCE_CUSTOM.w > 0.5) {   // a parked car: this (the far shape) from parked_cut on, fading in over PARK_BAND
		float dc = distance(MAIN_CAM_INV_VIEW_MATRIX[3].xyz, (MODEL_MATRIX * vec4(0.0, 0.0, 0.0, 1.0)).xyz);
		if (dc < parked_cut - 0.5 * PARK_BAND) VERTEX = vec3(0.0);
		else { float f = clamp((parked_cut + 0.5 * PARK_BAND - dc) / PARK_BAND, 0.0, 1.0); v_fade = f >= 1.0 ? 1.0 : (f <= 0.0 ? 1.0 : 1.0 + f); }
	}
}

void fragment() {
	ck_fade_discard(v_fade, FRAGCOORD.xy);
	// (look uplift, 28 Nov; Yasin: the far cars "look terrible") the shape is stern_g's and the picture volt_x's: the two
	// did not line up and every far car came out in white and coloured patches. From parked_cut on a car is its paint, a
	// dark glass band at window height (the shape: 0.32-1.52 m) and a dark sill line, read from the shape itself.
	vec3 n = normalize(v_ln);
	float glass = smoothstep(0.97, 1.03, v_lp.y) * (1.0 - smoothstep(1.37, 1.42, v_lp.y)) * (1.0 - step(0.8, n.y));
	float sill = 1.0 - smoothstep(0.38, 0.5, v_lp.y);
	ALBEDO = mix(COLOR.rgb, vec3(0.035, 0.045, 0.055), glass);
	ALBEDO = mix(ALBEDO, vec3(0.03, 0.03, 0.032), sill * 0.85);
	ROUGHNESS = 0.6;
}
