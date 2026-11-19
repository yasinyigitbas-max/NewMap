// brown-humans3: Microsoft Rocketbox (MIT) whole-donor character, single-tint recolour (player / story HeroModels).
// albedo_tex = the donor's untinted atlas (import size_limit 1024); mask_tex: R = skin weight, G = iris, B = hair (soft masks baked offline).
// Recolour (sRGB, as the offline PoC): skin = tint * lum / donor_lm; everything else (the donor's own outfit) as authored.
// cloud-ui (creator bugs, 9 Nov): hair and iris are now normalised by the donor's OWN mean brightness the same way as
// skin (hair = softened tint * (0.35 + 0.65 * lum / donor_hair_lm), iris = softened tint * lum / IRIS_LM). The old hair formula used a
// fixed 0.45, but donor hair averages 0.06-0.10 (F1 0.29), so blonde / red / white all came out near black; the old iris
// divided by the tint's mean and came out neon. The iris mask is tightened so the colour stays off the lids / lashes.
// tints are plain material uniforms (one material per player look): the gl_compatibility renderer used on phones
// rendered instance uniforms as blown-out skin in the xvfb check
shader_type spatial;
render_mode cull_back, depth_draw_opaque;
uniform float light_k = 0.0;   // brown-pr8 A: indoor baked-light scale (IndoorLightK), EMISSION = ALBEDO * light_k
uniform sampler2D albedo_tex : source_color, filter_linear_mipmap, repeat_disable;
uniform sampler2D mask_tex : filter_linear_mipmap, repeat_disable;
uniform vec3 skin_tint = vec3(0.87, 0.67, 0.50);
uniform vec3 hair_tint = vec3(0.33, 0.2, 0.11);
uniform vec3 eye_tint = vec3(0.3, 0.18, 0.08);
uniform float donor_lm = 0.45;
uniform float donor_hair_lm = 0.09;   // mean sRGB brightness of the donor's hair texels (RB.HAIR_LM)
const float IRIS_LM = 0.315;
const float SKIN_DETAIL = 0.55;   // cloud-ui: how much of the donor photo's light / dark detail stays on the skin
const float SKIN_GAIN = 0.92;          // mean iris brightness, the same on every donor (0.30-0.33)
vec3 to_s(vec3 c) { return pow(max(c, vec3(0.0)), vec3(1.0 / 2.2)); }
vec3 to_l(vec3 c) { return pow(max(c, vec3(0.0)), vec3(2.2)); }
vec3 skn(vec3 c) { c = mix(vec3((c.r + c.g + c.b) / 3.0), c, 0.8); return c / max(1.0, max(c.r, max(c.g, c.b))); }   // keep the skin hue when bright donors overshoot
void fragment() {
	vec4 t = texture(albedo_tex, UV);
	vec3 m = texture(mask_tex, UV).rgb;
	vec3 s = to_s(t.rgb);
	float lum = (s.r + s.g + s.b) / 3.0;
	vec3 st = skin_tint, ht = hair_tint, et = eye_tint;   // raw sRGB (no source_color: gl_compatibility handled the hint differently)
	// cloud-ui audit: dark tones (palette luminance < 0.5: brown, dark) rendered far darker than their swatch (dark was
	// near-black, measured 15/255 on a lit face). Lift them toward the lighter tones, keeping the hue; tones >= 0.5 unchanged.
	float sl = (st.r + st.g + st.b) / 3.0;
	if (sl < 0.5) st *= (0.5 - (0.5 - sl) * 0.47) / max(sl, 0.02);
	vec3 o = s;
	// cloud-ui audit (skin tones 4-5 near-black, 0-3 the same flat white): the donor photo's detail (lum / donor_lm, often
	// 1.5-2 on a lit face) multiplied straight into the tint clipped every light tone to white and pushed the dark ones
	// toward black. The detail is softened (power 0.55) and centred, so the chosen tone sets the skin brightness.
	o = mix(o, skn(st * pow(lum / max(donor_lm, 0.05), SKIN_DETAIL) * SKIN_GAIN), m.r);
	float hr = clamp(0.35 + 0.65 * lum / max(donor_hair_lm, 0.03), 0.3, 1.7);   // strand detail kept, contrast softened
	o = mix(o, mix(vec3((ht.r + ht.g + ht.b) / 3.0), ht, 0.6) * hr, m.b);       // creator tints are bright swatches: softened
	vec3 eo = mix(vec3((et.r + et.g + et.b) / 3.0), et, 0.65) * 0.85 * clamp(lum / IRIS_LM, 0.25, 1.6);
	o = mix(o, eo, smoothstep(0.5, 0.9, m.g));
	ALBEDO = to_l(clamp(o, 0.0, 1.0));
	EMISSION = ALBEDO * light_k;
	ALPHA = t.a;
	ALPHA_SCISSOR_THRESHOLD = 0.5;
	ROUGHNESS = mix(0.82, 0.6, m.r);
}
