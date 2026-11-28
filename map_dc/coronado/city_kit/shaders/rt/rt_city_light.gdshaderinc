// CITY LIGHT (look uplift, 28 Nov; Yasin: "we need a break thru at graphics"). Light the engine does not have on the
// phone, read from two maps baked for the whole island (tools/city/look/city_light_bake.gd + make_city_light.py):
//  - SKY: how much sky a point sees (a street between tall blocks, a wall's foot, a yard behind a fence see less), at
//    four heights above the ground; it darkens the AMBIENT light only (AO): the shade gets depth, the sunlit stays.
//    1 texture read (+1 for the ground height) per pixel.
//  - FAR SHADOW: past the engine's sun shadow (it fades out at 30-50 m) the city casts none; here the height map is
//    marched towards the sun, 5 reads, only for pixels past 35 m. Sunlit faces in it are darkened towards the shade.
// Off when ck_city_light is 0 (the maps are not loaded: an old bake, or switched off): one uniform test, nothing read.
global uniform float ck_city_light;            // 0 off .. 1 full
global uniform sampler2D ck_city_ao : filter_linear_mipmap, repeat_disable;
global uniform sampler2D ck_city_hg : filter_linear, repeat_disable;
global uniform vec4 ck_city_rect;              // x0, z0, 1/width, 1/depth (metres)
global uniform vec4 ck_city_sun;               // xyz towards the sun (or moon), w = how strong the far shadow is (0 at night)
global uniform vec3 ck_city_bounce;            // the sunlit ground's light thrown back up onto walls (look.gd: sun x ground colour)

vec2 ck_cl_uv(vec2 xz) { return (xz - ck_city_rect.xy) * ck_city_rect.zw; }

// x: the ambient factor (1 = all sky), y: the far-shadow factor (1 = in the sun), z: metres above the ground
vec3 ck_city_light_at(vec3 wp, vec3 wn, vec3 cam) {
	vec3 q = wp + vec3(wn.x, 0.0, wn.z) * 1.5;      // a wall reads the air in front of it
	vec2 uv = ck_cl_uv(q.xz);
	vec2 hg = texture(ck_city_hg, uv).rg;
	vec4 a = texture(ck_city_ao, uv);
	float up = q.y - hg.y;
	float v = up < 5.0 ? mix(a.r, a.g, clamp((up - 0.5) / 4.5, 0.0, 1.0))
		: (up < 14.0 ? mix(a.g, a.b, (up - 5.0) / 9.0) : mix(a.b, a.a, clamp((up - 14.0) / 21.0, 0.0, 1.0)));
	v = mix(v, 1.0, clamp(wn.y, 0.0, 1.0) * 0.35);      // a roof or the ground sees more of the open sky than a wall
	float sky = pow(clamp(v, 0.0, 1.0), 1.0 + 3.0 * ck_city_light);
	float sh = 1.0;
	float d = distance(cam, wp);
	float f = smoothstep(35.0, 55.0, d) * ck_city_sun.w;
	if (f > 0.0 && dot(wn, ck_city_sun.xyz) > 0.0) {
		vec3 o = wp + wn * 1.2;
		float t = 3.0;
		for (int i = 0; i < 5; i++) {
			vec3 s = o + ck_city_sun.xyz * t;
			float h = texture(ck_city_hg, ck_cl_uv(s.xz)).r;
			sh = min(sh, clamp((s.y - h) * 0.5 + 0.5, 0.0, 1.0));
			t *= 2.2;
		}
		sh = mix(1.0, sh, f);
	}
	return vec3(mix(1.0, sky, min(ck_city_light, 1.0)), sh, up);
}

// a sunlit face in the far shadow: towards its shade (the engine's light is not reachable from here)
float ck_city_shade(float sh, vec3 wn) {
	return 1.0 - (1.0 - sh) * clamp(dot(wn, ck_city_sun.xyz) * 2.5, 0.0, 1.0) * 0.55;
}

// BOUNCE: the sunlit street lights the walls round it from below, warm, strongest near the ground (a shaded wall in
// a real street is never the flat grey of the ambient light). Added as emission: no texture read.
vec3 ck_city_bounce_at(vec3 wn, float up) {
	float side = (1.0 - abs(wn.y)) + clamp(-wn.y, 0.0, 1.0);
	return ck_city_bounce * side * exp(-max(up, 0.0) / 9.0) * min(ck_city_light, 1.0);
}
