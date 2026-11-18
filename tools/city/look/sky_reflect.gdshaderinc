// LOOK JOB 5 (18 Nov, sky session): sky reflections from the look's small sky map, for the building session's glass
// and for wet ground. A snippet to #include in a spatial shader; nothing here is used by the city's shaders yet.
//
// ck_sky_map: the look's sky as a 128 x 64 panorama (look.gd renders it when the time of day changes; linear colour).
// ck_wet:     0 dry .. 1 just after rain (a mood, set by the look: rig --wet=0..1).
// In the game, add both to project.godot [shader_globals] (the test app adds them at run time):
//   ck_sky_map={ "type": "sampler2D", "value": "" }      ck_wet={ "type": "float", "value": 0.0 }
//
// Why a map of our own instead of the engine's sky reflection: the engine's reflection is ONE cube-map read in EVERY
// pixel of every lit material (rough walls and asphalt included, where it is nearly invisible). With the look's
// `--reflect=0` that read is gone everywhere, and only glass (and wet ground, when it rains) reads this map: one
// texture read of a 32 KB texture, plus a Fresnel term, on those pixels only.
//
// USE (fragment(), after ALBEDO / ROUGHNESS are set):
//   glass:  EMISSION += ck_sky_reflect(NORMAL, VIEW, INV_VIEW_MATRIX, 0.04, glass_mask);
//           (glass_mask 0..1: the building shader's own glass mask; 0.04 is glass's reflectance at normal view)
//   ground: ck_wet_ground(ALBEDO, ROUGHNESS, EMISSION, NORMAL, VIEW, INV_VIEW_MATRIX, puddle);
//           (puddle 0..1: where water lies, e.g. a noise or the ground texture's own darkness; 1 = everywhere)
// Per pixel: glass 1 texture read + about 15 arithmetic steps; wet ground the same, only while ck_wet > 0.
global uniform sampler2D ck_sky_map : filter_linear, repeat_enable;
global uniform float ck_wet;

vec3 ck_sky_map_read(vec3 world_dir) {
	vec2 uv = vec2(atan(world_dir.x, -world_dir.z) * 0.15915494 + 0.5, 0.5 - asin(clamp(world_dir.y, -1.0, 1.0)) * 0.31830989);
	return textureLod(ck_sky_map, uv, 0.0).rgb;
}

// the sky seen in a surface, weighted by Fresnel (Schlick); add it to EMISSION (it is light, not colour)
vec3 ck_sky_reflect(vec3 normal_view, vec3 view_view, mat4 inv_view, float f0, float amount) {
	vec3 n = normalize((inv_view * vec4(normal_view, 0.0)).xyz);
	vec3 v = normalize((inv_view * vec4(view_view, 0.0)).xyz);      // towards the camera
	vec3 r = reflect(-v, n);
	r.y = max(r.y, 0.02);                                              // below the horizon: the haze, not the map's bottom
	float c = 1.0 - max(dot(n, v), 0.0);
	float fres = f0 + (1.0 - f0) * c * c * c * c * c;
	return ck_sky_map_read(r) * fres * amount;
}

// wet ground: darker, smoother, and the sky in the puddles
void ck_wet_ground(inout vec3 albedo, inout float roughness, inout vec3 emission, vec3 normal_view, vec3 view_view, mat4 inv_view, float puddle) {
	float w = ck_wet * puddle;
	if (w <= 0.001) return;
	albedo *= mix(1.0, 0.55, ck_wet);                                  // all of it darker when wet
	roughness = mix(roughness, 0.12, w);
	vec3 flat_n = transpose(mat3(inv_view)) * vec3(0.0, 1.0, 0.0);      // still water is flat (world up, in view space)
	vec3 n = normalize(mix(normal_view, flat_n, w));
	emission += ck_sky_reflect(n, view_view, inv_view, 0.12, w * 1.3);      // more than water's real 2 %: a game's wet road (GTA 4's rain)
}
