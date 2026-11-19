// brown-humans3: Rocketbox (MIT) crowd / traffic people (NpcPeople). One material for every donor:
// albedo_arr / mask_arr = Texture2DArray, one 512 layer per donor (UV2.x = layer). Same recolour as rb_char.gdshader.
// Per person (near: uniform `person`; far MultiMesh: INSTANCE_CUSTOM): z = hair + 8*eye, w = skin tone 0..1 (+2 = grey hair).
// Far tier: baked poses in pose_tex (pose index in INSTANCE_CUSTOM.z / pose_k), cross-dissolve over fade_band.
// cloud-props "NPC faces + outfit variety" (tools/rocketbox/npc_outfits.py): packs[layer] = 1 -> the layer holds only
// the donor's bottom-row cells (body | head | hair) packed 2 x 2 at 2.3x the old texel density (UVs remapped here, no
// mesh change); mask alpha = garment code (top 1.0, bottoms 0.5). Per person x / y pick a top / bottoms colour (suits:
// one matching colour) that re-dyes those texels with the photo's own luminance (weave, folds, seams kept); every
// 4th person keeps the donor's original outfit. dye[layer]: 0 never (police), 1 casual palettes, 2 suit palette.
shader_type spatial;
render_mode cull_back;
uniform float light_k = 0.0;   // brown-pr8 A: indoor baked-light scale (IndoorLightK), EMISSION = ALBEDO * light_k
uniform bool use_instance = false;
uniform vec2 fade_band = vec2(30.0, 38.0);
uniform vec4 person = vec4(0.0);
uniform bool use_pose_tex = false;
uniform float pose_k = 512.0;
uniform int pose_n = 8;
uniform sampler2D pose_tex : filter_nearest, repeat_disable;
// cloud-props far merge (crowd_layer --farmerge): ONE MultiMesh per gender for every donor. The mesh is pose_corners
// unindexed corners; per donor a block of block_rows rows in pose_tex: per pose positions then normals (corner_h rows
// each), then one UV block (xy = UV, z = texture-array layer). Donor index = INSTANCE_CUSTOM.y / 64 (bottoms index below
// 64). Corners past a donor's own count are stored collapsed (zero-area). Same vertices / normals / UVs as per-donor.
uniform bool far_merged = false;
uniform int block_rows = 0;
uniform int corner_h = 1;
uniform vec3 hairs[8];
uniform vec3 eyes[4];
uniform vec3 skins[4];
uniform float lms[48];
uniform float packs[48];
uniform float skin_body[48];   // sRGB mean skin brightness of the body / head cells (npc_outfits.py; 0 = use lms)
uniform float skin_head[48];
uniform float hair_lm[48];     // mean sRGB brightness of the donor's hair texels (as rb_char donor_hair_lm)
const float IRIS_LM = 0.315;   // mean iris brightness, the same on every donor (rb_char.gdshader)
uniform float dye[48];
uniform float top_lum[48];
uniform float bot_lum[48];
uniform vec3 tops[44];      // sRGB: 24 casual + 20 role colours (NpcPeople.TOPS + ROLE_TOPS)
uniform vec3 bottoms[30];   // sRGB: 16 casual + 14 role colours
uniform vec3 suits[8];      // sRGB
// faces: face[layer] 1 = man (beard tile in the layer's 4th quadrant), 2 = woman (head-cell mask alpha = lips), 0 = none
uniform float face[48];
uniform vec3 lips[4];       // sRGB lipstick tints
uniform sampler2DArray albedo_arr : source_color, filter_linear_mipmap, repeat_disable;
uniform sampler2DArray mask_arr : filter_linear_mipmap, repeat_disable;
// 14 Nov (Samsung S23 / Adreno 740: the nearest, skinned people did not draw). The shader used 12 varyings of its own;
// with the engine's own that was 27 of the 28 the Adreno driver allows, and the skinned pipeline variants, which need
// more, failed to link ("Failed to link shaders", on every engine). The same 12 values now travel in 6 vec4 slots
// (the #defines keep the old names), so nothing in the picture changes.
varying vec4 v_p0;   // skin colour, f (near / far dissolve)
varying vec4 v_p1;   // hair colour, solid
varying vec4 v_p2;   // eye colour, texture layer
varying vec4 v_p3;   // top colour, dye
varying vec4 v_p4;   // bottoms colour, face (man: beard amount 0 / ~0.45 stubble / 0.9 beard; woman: lipstick amount)
varying vec4 v_p5;   // lip colour, hobo (role 2: dirt photo, mask array 4th quadrant R, over clothes + skin)
#define v_skin v_p0.rgb
#define v_f v_p0.a
#define v_hair v_p1.rgb
#define v_solid v_p1.a
#define v_eye v_p2.rgb
#define v_layer v_p2.a
#define v_top v_p3.rgb
#define v_dye v_p3.a
#define v_bot v_p4.rgb
#define v_face v_p4.a
#define v_lip v_p5.rgb
#define v_hobo v_p5.a
// the per-layer table values the fragment stage needs are looked up in the vertex stage and handed over flat: the
// fragment stage indexes no uniform array (the Adreno linker also rejected the engine's light grid for a computed
// index into uniform-block arrays in the fragment stage), and it is 8 fewer table reads per pixel
varying flat vec4 v_la;   // packs, top_lum, bot_lum, lms of this person's layer
varying flat vec4 v_lb;   // skin_body, skin_head, hair_lm, face
vec3 to_s(vec3 c) { return pow(max(c, vec3(0.0)), vec3(1.0 / 2.2)); }
vec3 to_l(vec3 c) { return pow(max(c, vec3(0.0)), vec3(2.2)); }
void vertex() {
	vec4 p = use_instance ? INSTANCE_CUSTOM : person;
	v_solid = 0.0;
	if (p.w < 0.0) { p.w = -p.w - 1.0; v_solid = 1.0; }
	float layer_in = UV2.x;
	if (use_pose_tex && far_merged) {
		int pose = int((p.z + 0.5) / pose_k);
		p.z -= float(pose) * pose_k;
		int di = int(p.y + 0.5) / 64;
		p.y -= float(di * 64);
		int W = textureSize(pose_tex, 0).x;
		ivec2 cv = ivec2(VERTEX_ID % W, VERTEX_ID / W + di * block_rows);
		VERTEX = texelFetch(pose_tex, cv + ivec2(0, 2 * pose * corner_h), 0).xyz;
		NORMAL = texelFetch(pose_tex, cv + ivec2(0, 2 * pose * corner_h + corner_h), 0).xyz;
		vec4 uvl = texelFetch(pose_tex, cv + ivec2(0, 2 * pose_n * corner_h), 0);
		UV = uvl.xy; layer_in = uvl.z;
	} else if (use_pose_tex) {
		int pose = int((p.z + 0.5) / pose_k);
		p.z -= float(pose) * pose_k;
		ivec2 ts = textureSize(pose_tex, 0);
		int h = ts.y / (2 * pose_n);
		ivec2 uv = ivec2(VERTEX_ID % ts.x, VERTEX_ID / ts.x);
		VERTEX = texelFetch(pose_tex, uv + ivec2(0, 2 * pose * h), 0).xyz;
		NORMAL = texelFetch(pose_tex, uv + ivec2(0, 2 * pose * h + h), 0).xyz;
	}
	float dist = length((MODEL_MATRIX * vec4(0.0, 0.0, 0.0, 1.0)).xyz - CAMERA_POSITION_WORLD);
	v_f = smoothstep(fade_band.x, fade_band.y, dist);
	int z = int(p.z + 0.5);
	float sk = fract(p.w);
	v_skin = sk < 0.3333 ? mix(skins[0], skins[1], sk * 3.0) : (sk < 0.6667 ? mix(skins[1], skins[2], sk * 3.0 - 1.0) : mix(skins[2], skins[3], sk * 3.0 - 2.0));
	v_hair = p.w >= 1.5 ? vec3(0.26, 0.26, 0.25) : hairs[z & 7];
	v_eye = eyes[(z >> 3) & 3];
	v_layer = layer_in;
	int li = clamp(int(layer_in + 0.5), 0, 47);
	int px = int(p.x + 0.5); int py = int(p.y + 0.5);
	int role = px / 64; px = px % 64;   // NpcPeople roles: 0 casual 1 uniform 2 hobo 3 night 4 keep 5 night in own wear
	v_la = vec4(packs[li], top_lum[li], bot_lum[li], lms[li]);
	v_lb = vec4(skin_body[li], skin_head[li], hair_lm[li], face[li]);
	float dm = dye[li];
	if (role == 0) {
		v_dye = (dm > 0.5 && (px + 3 * py) % 4 != 0) ? 1.0 : 0.0;
		v_top = dm > 1.5 ? suits[(px + py) % 8] : tops[px % 24];
		v_bot = dm > 1.5 ? v_top : bottoms[py % 16];
	} else {
		v_dye = (dm > 0.5 && role < 4) ? 1.0 : 0.0;
		v_top = tops[min(px, 43)]; v_bot = bottoms[min(py, 29)];
	}
	v_hobo = role == 2 ? 1.0 : 0.0;
	int fr = int(fract(p.w) * 997.0) + 13 * px;
	float fm = face[li];
	v_face = 0.0; v_lip = vec3(0.0);
	if (fm > 0.5 && fm < 1.5) { int r = fr % 10; v_face = role == 2 ? (r < 3 ? 0.45 : 0.9) : (r < 5 ? 0.0 : (r < 8 ? 0.45 : 0.9)); }
	else if (fm > 1.5 && (role == 3 || role == 5)) { v_face = 0.8; v_lip = lips[fr % 2 == 0 ? 0 : 1]; }   // night (dyed / own party wear): red / berry, always
	else if (fm > 1.5 && role != 2 && fr % 10 < 4) { v_face = 0.65; v_lip = lips[(fr / 10) % 4]; }
}
vec3 skn(vec3 c) { c = mix(vec3((c.r + c.g + c.b) / 3.0), c, 0.8); return c / max(1.0, max(c.r, max(c.g, c.b))); }   // keep the skin hue when bright donors overshoot
void fragment() {
	float dn = fract(52.9829189 * fract(dot(FRAGCOORD.xy, vec2(0.06711056, 0.00583715))));
	if (use_instance) { if (v_solid < 0.5 && dn >= v_f) discard; }
	else if (dn < v_f) discard;
	int li = clamp(int(v_layer + 0.5), 0, 47);
	vec2 uv = UV; vec2 gx = dFdx(UV); vec2 gy = dFdy(UV);
	if (v_la.x > 0.5) {   // bottom-row cell k (0 body, 1 head, 2 hair) -> 2 x 2 cell (k % 2, k / 2)
		vec2 c3 = UV * 3.0; float k = clamp(floor(c3.x), 0.0, 2.0);
		uv = (vec2(mod(k, 2.0), floor(k * 0.5)) + clamp(c3 - vec2(k, 2.0), 0.0, 1.0)) * 0.5;
		gx *= 1.5; gy *= 1.5;
	}
	vec3 uvw = vec3(uv, float(li));
	vec4 t = textureGrad(albedo_arr, uvw, gx, gy);
	vec4 m4 = textureGrad(mask_arr, uvw, gx, gy);
	vec3 m = m4.rgb;
	// packed layers, body cell: G = top weight, B = bottoms weight (npc_outfits.py; no iris / hair in that cell)
	bool body_cell = v_la.x > 0.5 && UV.x * 3.0 < 1.0;
	float wt = body_cell ? m4.g : 0.0;
	float wb = body_cell ? m4.b : 0.0;
	if (body_cell) { m.g = 0.0; m.b = 0.0; }
	vec3 s = to_s(t.rgb);
	float lum = (s.r + s.g + s.b) / 3.0;
	if (v_dye > 0.5 && wt + wb > 0.0) {
		// photo detail strength: dark source cloth (black suit) has noisy relative contrast -> keep less of it; folds and
		// shadows carry over (down to 0.4x), highlights only to 1.12x (a lighter hem on the source washed the dye out)
		float rt = mix(1.0, clamp(lum / max(v_la.y, 0.03), 0.4, 1.12), mix(0.35, 0.85, smoothstep(0.06, 0.3, v_la.y)));
		float rb = mix(1.0, clamp(lum / max(v_la.z, 0.03), 0.4, 1.12), mix(0.35, 0.85, smoothstep(0.06, 0.3, v_la.z)));
		// one blend of the two dyes by weight (a top / bottoms seam, or filtering between their codes, gives wt = wb = 0.5:
		// two mixes in a row left 25 % of the undyed colour there = a pale band at the waist)
		vec3 dy = (clamp(v_top * rt, 0.0, 1.0) * wt + clamp(v_bot * rb, 0.0, 1.0) * wb) / max(wt + wb, 1e-3);
		s = mix(s, dy, clamp(wt + wb, 0.0, 1.0));
	}
	vec3 st = to_s(v_skin), ht = to_s(v_hair), et = to_s(v_eye);
	// skin reference per cell: body-texture skin is brighter than face skin on every donor; one reference made the
	// recoloured arms lighter than the face (two skin tones on one person)
	float sref = v_la.w;
	if (v_la.x > 0.5) { sref = UV.x * 3.0 < 1.0 ? v_lb.x : (UV.x * 3.0 < 2.0 ? v_lb.y : sref); }
	else if (v_lb.x > 0.0) { sref = v_lb.x; }
	if (sref <= 0.0) sref = v_la.w;
	vec3 o = mix(s, skn(st * lum / max(sref, 0.05)), m.r);
	// hair / iris as the player's rb_char.gdshader (cloud-ui creator fix): hair normalised by the donor's own hair
	// brightness (the fixed 0.45 made blonde / red / grey near black), iris by IRIS_LM, softened tint, tight mask
	// (the old formula lit the whole eye in neon: "devil eyes")
	float hr = clamp(0.35 + 0.65 * lum / max(v_lb.z > 0.0 ? v_lb.z : 0.09, 0.03), 0.3, 1.7);
	o = mix(o, mix(vec3((ht.r + ht.g + ht.b) / 3.0), ht, 0.6) * hr, m.b);
	vec3 eo = mix(vec3((et.r + et.g + et.b) / 3.0), et, 0.65) * 0.85 * clamp(lum / IRIS_LM, 0.25, 1.6);
	o = mix(o, eo, smoothstep(0.5, 0.9, m.g));
	if (v_face > 0.0 && v_la.x > 0.5 && UV.x * 3.0 >= 1.0 && UV.x * 3.0 < 2.0) {   // head cell only
		if (v_lb.w < 1.5) {
			// beard / stubble: the layer's 4th quadrant (npc_outfits.py beard_tile) = this donor's hair photo (rgb) +
			// beard density (a), aligned with the head cell; tinted with this person's hair colour
			vec2 bl = (clamp(UV * 3.0 - vec2(1.0, 2.0), 0.0, 1.0) + 1.0) * 0.5;
			vec4 bs = textureGrad(albedo_arr, vec3(bl, float(li)), gx, gy);
			float blum = dot(to_s(bs.rgb), vec3(0.3333));
			vec3 bc = clamp(mix(vec3((ht.r + ht.g + ht.b) / 3.0), ht, 0.6) * blum * 2.0 * 0.95, 0.0, 1.0);   // beard: the (softened) scalp hair colour, strands +-
			float cover = bs.a * 0.8;   // a little skin shows through: hair, not a mask
			if (v_face < 0.6) {   // stubble: the strand detail at 3x frequency = short dark bristles, skin shows between
				vec2 sl = (fract(clamp(UV * 3.0 - vec2(1.0, 2.0), 0.0, 1.0) * 3.0) * 0.96 + 0.02 + 1.0) * 0.5;
				float sb = dot(to_s(textureGrad(albedo_arr, vec3(sl, float(li)), gx * 3.0, gy * 3.0).rgb), vec3(0.3333));
				bc = ht * 0.55; cover = smoothstep(0.05, 0.4, bs.a) * 0.6 * smoothstep(0.5, 0.36, sb);
			}
			o = mix(o, bc, cover);
		} else {
			// lips keep their own shading but never go darker than 0.55x the tint (a downward-facing upper lip in shade read
			// as a dark moustache), tint by the lips' own brightness (~0.5)
			o = mix(o, clamp(v_lip * max(lum / 0.5, 0.55), 0.0, 1.0), smoothstep(0.2, 0.7, m4.a) * v_face);
		}
	}
	if (v_hobo > 0.5 && v_la.x > 0.5 && UV.x * 3.0 < 2.0) {
		// homeless: ambientCG SurfaceImperfections dirt + stains photo (npc_outfits.py dirt tile) at the same cell-local
		// spot; clothes drab + grimy, skin a little dirty
		vec2 dl = (clamp(UV * 3.0 - vec2(floor(UV.x * 3.0), 2.0), 0.0, 1.0) * 0.94 + 0.03 + 1.0) * 0.5;
		float dirt = textureGrad(mask_arr, vec3(dl, float(li)), gx, gy).r;
		float l2 = (o.r + o.g + o.b) / 3.0;
		vec3 drab = mix(o, vec3(l2) * vec3(1.05, 0.98, 0.85), 0.45 * (1.0 - m.r));
		o = mix(drab, drab * vec3(0.5, 0.44, 0.36), clamp(dirt * mix(1.1, 0.3, m.r), 0.0, 1.0));
	}
	ALBEDO = to_l(clamp(o, 0.0, 1.0));
	EMISSION = ALBEDO * light_k;
	ALPHA = t.a;
	ALPHA_SCISSOR_THRESHOLD = 0.5;
	ROUGHNESS = mix(0.82, 0.6, m.r);
}
