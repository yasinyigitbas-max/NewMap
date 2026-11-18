// LOOK JOB 4 (18 Nov, sky session): soft shadows under trees BEYOND the sun shadow (50 m in the game), so far trees
// no longer stand on unshaded ground. One MultiMesh of flat quads per cell (tools/city/look/blob_shadows.gd).
// INSTANCE_CUSTOM: r = crown height over the foot (m), g = crown radius (m).
// The blob is moved away from the sun by the crown's height (a shadow falls where the crown's shadow would),
// darkens what is under it (multiply blend), fades in where the real sun shadow fades out, fades out with the haze.
// Per pixel: a few arithmetic steps, one exp(), no texture read, a multiply blend. The quads nearer than fade_begin
// are collapsed in the vertex shader (no pixels); the rest are small (they are far).
shader_type spatial;
render_mode unshaded, blend_mul, depth_draw_never, cull_disabled, shadows_disabled, fog_disabled;
uniform vec3 sun_dir = vec3(0.0, 1.0, 0.0);      // towards the sun (look.gd)
uniform float strength = 0.45;                    // darkest point: 1 - strength (look.gd, per time of day)
uniform float fade_begin = 38.0;                  // the sun shadow fades out from 40 m (the engine's fade starts at 0.8 of 50 m)
uniform float fade_full = 52.0;
uniform float fade_end = 230.0;                   // the loaded cells end at about 220 m
uniform float haze = 0.0017;
uniform float lift = 0.2;                         // over kerbs and pavements, as the lamp pools
varying float v_a;
void vertex() {
	float h = INSTANCE_CUSTOM.r; float rad = INSTANCE_CUSTOM.g;
	vec3 foot = MODEL_MATRIX[3].xyz;
	float d = distance(foot, INV_VIEW_MATRIX[3].xyz);
	v_a = strength * smoothstep(fade_begin, fade_full, d) * (1.0 - smoothstep(fade_end - 40.0, fade_end, d)) * exp(-d * haze);
	vec2 hz = sun_dir.xz / max(sun_dir.y, 0.25);       // a low sun throws it further, up to 4 x the height
	vec2 off = -hz * h * 0.55;                         // the crown's middle, not its top
	float stretch = 1.0 + min(length(hz), 2.0) * 0.35;
	vec2 dir = length(hz) > 0.01 ? normalize(hz) : vec2(1.0, 0.0);
	vec2 q = VERTEX.xy * rad * 2.2;                    // the quad is 1 x 1 in its XY plane; laid flat below
	vec2 along = dir * dot(q, dir) * stretch; vec2 across = q - dir * dot(q, dir);
	vec2 w = along + across;
	if (v_a < 0.002) { VERTEX = vec3(0.0); }
	else {
		vec3 world = vec3(foot.x + off.x + w.x, foot.y + lift, foot.z + off.y + w.y);
		VERTEX = world - foot;      // the instance has no rotation or scale (blob_shadows.gd)
	}
}
void fragment() {
	float r = length(UV - vec2(0.5)) * 2.0;
	float a = v_a * (1.0 - smoothstep(0.25, 1.0, r));
	ALBEDO = vec3(1.0 - a);
}
