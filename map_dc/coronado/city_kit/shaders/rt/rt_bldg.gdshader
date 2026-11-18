// Runtime bake (18 Nov): the city kit's weathered building material (bldg_wear) with two additions:
//  - tint and extra wear PER BUILDING (instance uniforms, no extra material, no extra draw): copies of one model
//    read as different buildings. Default 1 / 0 = exactly the bldg_wear look.
//  - the night window glow follows the global ck_night (0 day .. 1 night); the kit's emissive mask was already bound.
// Look pack, buildings (18 Nov, docs/LOOK_BUILDINGS.md): three changes, each behind a global value (0 off = the look
// before, 1 on), no texture read added:
//  - ck_look_contact: the kit's own occlusion (ORM red, already read) also dims direct light a little, and a thin
//    dark line where a wall meets the ground. No second foot or eave gradient: the kit has those baked in.
//  - ck_look_windows: at night every window has its own colour temperature and brightness (hash of the window).
//  - ck_look_glass: by day the glass (found by its roughness in the ORM, already read) reflects a sky gradient,
//    a little different per window. ck_look_sky_top / ck_look_sky_horizon: the day sky's colours.
shader_type spatial;
render_mode cull_back, diffuse_burley, specular_schlick_ggx;
uniform sampler2D albedo_tex : source_color, filter_linear_mipmap_anisotropic, repeat_disable;
uniform sampler2D normal_tex : hint_normal, filter_linear_mipmap, repeat_disable;
uniform sampler2D orm_tex : filter_linear_mipmap, repeat_disable;
uniform sampler2D emission_tex : source_color, filter_linear_mipmap, repeat_disable;
uniform sampler2D grime_tex : source_color, filter_linear_mipmap, repeat_enable;
uniform bool has_normal = true;
uniform bool has_orm = true;
uniform bool has_emission = false;
uniform float emission_energy = 1.0;
uniform float wear : hint_range(0.0, 1.0) = 0.45;
uniform float foot_m = 1.4;
uniform float grime_meters = 2.2;
uniform float streaks = 0.55;
uniform vec3 night_color : source_color = vec3(1.0, 0.78, 0.5);
uniform float night_energy = 1.3;
instance uniform vec3 tint : source_color = vec3(1.0, 1.0, 1.0);
instance uniform float wear_add = 0.0;
instance uniform float lit_seed = 0.0;       // which windows are lit differs per building
uniform float contact_light = 0.6;     // how much of the kit's occlusion also dims direct light
uniform float contact_line = 0.5;      // darkness of the line where a wall meets the ground
uniform float contact_line_m = 0.45;   // its height
uniform float glass_reflect = 0.15;    // sky reflection seen straight on (rises to 1 at a grazing angle)
global uniform float ck_night;
// the tier window (19 Nov, rt_tier.gdshaderinc): this mesh draws while its building's pivot (world) is within
// [ck_win.x, ck_win.y) of the camera; the bake sets near 0-60 m, mid 60-220 m, and node ranges a little wider
#include "rt_tier.gdshaderinc"
instance uniform vec3 ck_pivot = vec3(0.0);
instance uniform vec2 ck_win = vec2(0.0, 1.0e6);
#ifdef CK_TIERS
varying vec2 v_tw;
#endif
global uniform float ck_look_contact;
global uniform float ck_look_windows;
global uniform float ck_look_glass;
global uniform vec4 ck_look_sky_top : source_color;
global uniform vec4 ck_look_sky_horizon : source_color;
global uniform float ck_look_signs;          // look job 6: the kit's painted shop signs glow at night
uniform float sign_glow = 1.1;
global uniform float ck_look_detail;          // look job 3: fine grain on the walls near the camera
global uniform sampler2D ck_look_detail_tex : filter_linear_mipmap, repeat_enable;
uniform float detail_amount = 0.6;
uniform float detail_m = 0.7;           // world size of the detail tile
uniform float detail_near = 4.0;        // full strength up to here, gone by detail_far (metres from the camera)
uniform float detail_far = 12.0;
varying vec3 v_wp;
varying vec3 v_wn;
varying float v_y;
varying vec2 v_win;      // window cell (3 m): the same value over one window, another on the next
varying flat float v_city;      // 1 = the material uses the city atlas (the one with the painted shop signs)
void vertex() {
	float ck_d = distance(MAIN_CAM_INV_VIEW_MATRIX[3].xyz, ck_pivot);
#ifdef CK_TIERS
	float ck_s = CK_FAR_M * ck_cell_ramp(ck_pivot);
	v_tw = ck_weights(ck_d, min(ck_win.x, ck_s), min(ck_win.y, ck_s));
	if (v_tw.x <= 0.0 || v_tw.y <= 0.0) VERTEX = vec3(0.0);
#else
	if (ck_d < ck_win.x || ck_d >= ck_win.y) VERTEX = vec3(0.0);
#endif
	v_wp = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	v_wn = normalize((MODEL_MATRIX * vec4(NORMAL, 0.0)).xyz);
	v_y = VERTEX.y;
	// A window is one quad that shows one window of the atlas. Its place along the wall minus its place in the atlas
	// (at the kit's window scale, about 18 m across the atlas, 16 m down) is nearly the same at all four corners, so
	// a 3 m cell of that value holds whole windows (4 % are still cut, against 40 % for cells of plain position).
	// Glass bands as wide as a tower are cut into bays by it. Each wall face starts at another cell.
	float along = VERTEX.x * NORMAL.z - VERTEX.z * NORMAL.x;
	v_win = vec2(along - UV.x * 18.0, VERTEX.y + UV.y * 16.0) / 3.0 + vec2(floor(dot(NORMAL.xz, vec2(17.0, 43.0)) + 0.5), 0.0);
	// which kit atlas: the city atlas has a lit shopfront where the building atlas has a white door (one fetch of a fixed
	// texel per vertex, not per pixel)
	v_city = has_emission ? step(0.2, texelFetch(emission_tex, ivec2(60, 790), 0).r) : 0.0;
}
// the city atlas' sign boards (assets/coronado_kit/textures/city_layout.json SG_*): the two name rows at the top, the
// shop-name row and the landmark column over the doors, the small boards by the windows; -1 = not a sign, else its id
float sign_id(vec2 px) {
	if (px.y >= 536.0 && px.y <= 660.0) return floor(px.x / 256.0) + (px.y > 598.0 ? 8.0 : 0.0);
	if (px.y >= 1707.0 && px.y <= 1759.0) return 16.0 + floor(px.x / 256.0);
	if (px.x >= 1804.0 && px.y >= 1403.0 && px.y <= 1695.0) return 24.0 + floor((px.y - 1403.0) / 60.0);
	if (px.x >= 1844.0 && px.y >= 1763.0 && px.y <= 1995.0) return 30.0 + floor((px.y - 1763.0) / 60.0);
	return -1.0;
}
vec2 win_hash(vec2 c) {
	return fract(sin(vec2(dot(c, vec2(12.9898, 78.233)), dot(c, vec2(39.3468, 11.135)))) * 43758.5453);
}
void fragment() {
#ifdef CK_TIERS
	CK_DITHER
#endif
	vec4 alb = texture(albedo_tex, UV);
	vec3 orm = has_orm ? texture(orm_tex, UV).rgb : vec3(1.0, 0.8, 0.0);
	vec3 a = abs(v_wn);
	vec2 guv = (a.y >= a.x && a.y >= a.z) ? v_wp.xz : (a.x >= a.z ? v_wp.zy : v_wp.xy);
	vec4 grime = texture(grime_tex, guv / grime_meters);
	float cavity = clamp((1.0 - orm.r) * 1.3, 0.0, 1.0);
	float foot = 1.0 - smoothstep(0.0, foot_m, v_y);
	float film = grime.a * 0.35;
	float wall = 1.0 - smoothstep(0.5, 0.8, a.y);
	vec2 suv = (a.x >= a.z ? vec2(v_wp.z, v_wp.y) : vec2(v_wp.x, v_wp.y)) * vec2(1.0 / 1.6, 1.0 / 19.0);
	float streak = smoothstep(0.35, 0.85, texture(grime_tex, suv).a) * wall * streaks;
	float amount = clamp((cavity * 0.75 + foot * 0.85 + film + streak * 0.6) * clamp(wear + wear_add, 0.0, 1.0), 0.0, 0.9);
	// the tint paints the walls, not the glass or the dark trims: it fades out on dark and on saturated texels
	float lum = dot(alb.rgb, vec3(0.299, 0.587, 0.114));
	float sat = max(alb.r, max(alb.g, alb.b)) - min(alb.r, min(alb.g, alb.b));
	float paint = smoothstep(0.28, 0.55, lum) * (1.0 - smoothstep(0.18, 0.4, sat)) * wall;
	vec3 base = alb.rgb * COLOR.rgb * mix(vec3(1.0), tint, paint);
	vec3 col = mix(base, base * grime.rgb * 1.1, amount * 0.8);
	// close-up detail: walls go soft at arm's length (one atlas texel is ~1-2 cm); a fine tiling grain only near the camera
	if (ck_look_detail > 0.5) {
		float near_f = (1.0 - smoothstep(detail_near, detail_far, distance(CAMERA_POSITION_WORLD, v_wp))) * smoothstep(0.18, 0.3, orm.g);      // not on glass
		if (near_f > 0.01) col *= 1.0 + (texture(ck_look_detail_tex, guv / detail_m).r - 0.5) * 1.6 * detail_amount * near_f;
	}
	// contact: a thin dark line where the wall stands on the ground
	float line = (1.0 - smoothstep(0.0, contact_line_m, v_y)) * wall;
	col *= 1.0 - contact_line * ck_look_contact * line * line;
	ALBEDO = col;
	ROUGHNESS = clamp(mix(orm.g, max(orm.g, 0.85), amount), 0.05, 1.0);
	METALLIC = orm.b * (1.0 - amount);
	AO = orm.r;
	AO_LIGHT_AFFECT = contact_light * ck_look_contact;      // the kit's occlusion (recesses, under eaves and sills) also in sunlight
	if (has_normal) NORMAL_MAP = texture(normal_tex, UV).rgb;
	vec3 emi = vec3(0.0);
	if (ck_look_glass > 0.5 && has_orm) {
		// glass = the smooth, non-metal texels of the ORM (roughness 0.08; nothing else in the kit is under 0.25)
		float glass = (1.0 - smoothstep(0.1, 0.22, orm.g)) * (1.0 - smoothstep(0.1, 0.3, orm.b)) * wall;
		if (glass > 0.01) {
			vec2 hw = win_hash(floor(v_win) + lit_seed);
			vec3 view = normalize(CAMERA_POSITION_WORLD - v_wp);
			// no two panes are quite parallel: each window leans a little, so each shows another part of the sky
			vec3 n = normalize(v_wn + vec3(hw.x - 0.5, hw.y - 0.5, 0.5 - hw.x) * 0.035);
			vec3 r = reflect(-view, n);
			float f = 1.0 - max(dot(n, view), 0.0);
			float f2 = f * f;
			float fres = glass_reflect + (1.0 - glass_reflect) * f2 * f2 * f;
			// what the glass faces: sky above the roofs across the street, their dark fronts below. High windows
			// see over the roofs, low ones do not.
			float up = clamp(r.y, 0.0, 1.0);
			vec3 sky = mix(ck_look_sky_horizon.rgb, ck_look_sky_top.rgb, up * (2.0 - up));
			float open = smoothstep(-0.2, 0.2, r.y * 4.0 + (v_y - 9.0) * 0.06 + (hw.y - 0.5) * 0.5);
			vec3 refl = mix(ck_look_sky_horizon.rgb * vec3(0.2, 0.19, 0.18), sky, open) * mix(0.9, 1.04, hw.x) * (1.0 - 0.94 * ck_night);
			float k = glass * fres;
			ALBEDO = col * (1.0 - k);
			emi = refl * k;
		}
	}
	if (has_emission && ck_night > 0.001) {
		if (ck_look_windows > 0.5) {
			// every window its own lamp: a third stay dark, the rest come on one by one at dusk. One home or office (two
			// windows of a floor) has one kind of light: mostly warm bulbs (2700-3000 K), some neutral (3500 K), one in
			// twelve a cold tube or a television; each window a little brighter or dimmer than its neighbour
			vec2 hw = win_hash(floor(v_win) + lit_seed);
			vec2 hr = win_hash(floor(v_win * vec2(0.5, 1.0)) + lit_seed * 1.7 + 0.31);
			float on = step(0.34, hw.x) * smoothstep(hw.x * 0.6, hw.x * 0.6 + 0.25, ck_night);
			float bright = mix(0.35, 0.85, hr.x) * mix(0.8, 1.1, hw.y);      // under 1: big shopfronts must not burn white
			vec3 lamp = mix(vec3(1.0, 0.56, 0.24), vec3(1.0, 0.7, 0.42), smoothstep(0.0, 0.55, hr.y));      // tungsten .. warm LED
			lamp = mix(lamp, vec3(1.0, 0.8, 0.58), step(0.72, hr.y));                                          // neutral
			lamp = mix(lamp, vec3(0.3, 0.38, 0.52), step(0.92, hr.y));                                        // tube / TV: bluish, dimmer
			emi += texture(emission_tex, UV).r * lamp * (emission_energy * night_energy * on * bright);
		} else {
			// the look before: 3 m x 3 m bays of each wall, one colour
			vec2 bay = floor(vec2(a.x >= a.z ? v_wp.z : v_wp.x, v_wp.y) / 3.0);
			float hsh = fract(sin(dot(bay + lit_seed, vec2(12.9898, 78.233))) * 43758.5453);
			float on = step(0.34, hsh) * smoothstep(hsh * 0.6, hsh * 0.6 + 0.25, ck_night) * mix(0.35, 1.0, fract(hsh * 7.31));
			emi += texture(emission_tex, UV).rgb * night_color * emission_energy * night_energy * on;
		}
	}
	// night signs: the letters (lighter than their board) glow, the board a little; one sign in seven flickers
	if (ck_look_signs > 0.5 && v_city > 0.5 && ck_night > 0.001) {
		float sid = sign_id(UV * 2048.0);
		if (sid >= 0.0) {
			float hs = fract(sin(sid * 12.9898 + lit_seed * 78.233) * 43758.5453);
			float letter = smoothstep(0.42, 0.68, lum);
			float tick = floor(TIME * 7.0 + hs * 50.0);
			float flick = hs > 0.86 ? mix(1.0, 0.2, step(0.86, fract(sin(tick * 91.7 + hs * 13.0) * 43758.5453))) : 1.0;
			emi += alb.rgb * (letter * 1.0 + 0.1) * sign_glow * flick * smoothstep(0.2, 0.6, ck_night);
		}
	}
	EMISSION = emi;
}
