shader_type spatial;
render_mode diffuse_lambert;   // cloud-perf-lighting: Lambert diffuse (cheaper than Burley per light per pixel; A/B shots show no visible change), GGX specular kept
// red-cars-sports: shared car material. Atlas alpha encodes the area type:
//   ~1.0 = body paint (takes the per-instance tint: MultiMesh COLOR * paint), glossy clear coat
//   ~0.5 = glass (dark, very smooth, strong reflections so windows read as glass from the side too)
//   ~0.0 = lights, trim, tyres (own colours)
// t172: steering-rim verts merged into the body while the player is inside. car-tex r3: the rim is marked UV2.x = 2
// (was 1: UV2 > 0.5 also hit real UV2 data, e.g. the baked wheels -> the white-tyre bug), the merged cabin UV2.x = -1
// (cabin keeps the old atlas on UV); everything else keeps its real UV2 (the per-car maps in map_mode 2).
//       (CUSTOM0 is NOT available in this Compatibility spatial path).
uniform sampler2D atlas : source_color, filter_nearest_mipmap;
// car-tex (Yasin 19 Nov: hand-made photo textures + normal map + AO): a car with its own baked cell sets use_maps = true
// and gets albedo_map (RGB colour, A = the same paint / glass mask as the atlas alpha), normal_map (tangent space,
// OpenGL +Y, baked from the high model) and orm_map (R = AO, G = roughness, B = metallic). Cars without them keep the
// old atlas path unchanged (use_maps = false): same shader, same per-instance tint.
uniform bool use_maps = false;
// car-tex round 2 (hybrid): map_mode 2 = small parts (lamps, grille, trim, mouldings, plate, glass, tyres, wheels) sample
// ONE shared trim / detail sheet on UV (trim_albedo: RGB + A area mask, 0.18 = lamp lens / gloss trim; trim_normal;
// trim_orm R AO G rough B metal), and the painted body adds the car's own low-res maps on UV2: car_normal (panel gaps)
// and car_orm (R = AO incl. gap cavities, G = grime, B = cabin brightness behind the glass). UV2 keeps its flags on
// top: > 1.5 steering rim, < -0.5 merged cabin (car.gd _ensure_uv2_mark); the unwrap itself stays inside 0..1.
uniform int map_mode = 0;
uniform sampler2D trim_albedo : source_color, filter_linear_mipmap_anisotropic, repeat_enable;
uniform sampler2D trim_normal : hint_normal, filter_linear_mipmap_anisotropic, repeat_enable;
uniform sampler2D trim_orm : hint_default_white, filter_linear_mipmap_anisotropic, repeat_enable;
uniform sampler2D car_normal : hint_normal, filter_linear_mipmap;
uniform sampler2D car_orm : hint_default_white, filter_linear_mipmap;
uniform float grime_strength = 1.0;
const float ENV_LENS = 0.35;     // lamp lenses / gloss black trim: clear, untinted reflection
uniform sampler2D albedo_map : source_color, filter_linear_mipmap_anisotropic;
uniform sampler2D normal_map : hint_normal, filter_linear_mipmap_anisotropic;
uniform sampler2D orm_map : hint_default_white, filter_linear_mipmap_anisotropic;
uniform float normal_strength = 1.0;
uniform float ao_strength = 1.0;
uniform vec4 paint : source_color = vec4(1.0);
uniform float steer_angle = 0.0;
uniform vec3 steer_center = vec3(0.0);
uniform vec3 steer_axis = vec3(0.0, 0.0, 1.0);
// fix3p car damage (vehicles/car_damage.gd): up to 8 dents in mesh space. dent_p = (centre, radius m),
// dent_d = (push direction * depth m, 0). dent_n = 0 on undamaged cars: the loop is skipped.
// the driver's door (CityCar: Yasin, 20 Nov: "CARS DOORS SHOULD OPEN"): the body's part inside door_lo..door_hi swings
// about a vertical hinge at its front edge (door_hinge: x, z), out by door_open x door_max (rad)
uniform float door_open = 0.0;
uniform float door_max = 1.15;
uniform vec3 door_lo = vec3(0.0);
uniform vec3 door_hi = vec3(0.0);
uniform vec2 door_hinge = vec2(0.0);
uniform int dent_n = 0;
uniform vec4 dent_p[8];
uniform vec4 dent_d[8];
// streetD (Yasin: "damaged cars didn't look damaged much" -> "much more realistic"): the damage is drawn PER PIXEL from
// the dent list, so it shows on low-poly bodies too (a 0.8 m dent only moved 2-5 vertices before). Photo detail, CC0
// ambientCG (tools/vehicles/car_damage_tex.py): damage_detail RG = crumpled metal normal (Foil001), B = scratches
// (Scratches001/003), A = paint chips (PaintedMetal004); glass_cracks = a photographed crack web (Asphalt021). Mapped in
// metres on the body's dominant axis (mesh space). Undamaged cars (dent_n = 0) skip all of it.
uniform sampler2D damage_detail : hint_default_black, filter_linear_mipmap, repeat_enable;
uniform sampler2D glass_cracks : hint_default_black, filter_linear_mipmap, repeat_enable;
// streetR (GTA IV look 2: "car paint + windows reflect sky / street"; Yasin: photo textures; phone: no screen-space
// reflections): a photographed street panorama (vehicles/tex/car_env.jpg, tools/vehicles/car_reflection_env.py: Poly
// Haven CC0 wide_street_01 by day, cobblestone_street_night by night, equirect rows) sampled by the reflected view
// direction: clear-coat reflection on the paint (Fresnel, blurred by roughness: dents / scratches go dull), strong on
// glass. refl_env (global, Weather): x = daylight 0..1 (SunSky.day_k), y = cloud cover (overcast: greyer, flatter).
// No env texture (old baked material) = black = no reflection. 2 texture reads per paint / glass pixel.
uniform sampler2D env_pano : source_color, hint_default_black, filter_linear_mipmap, repeat_disable;
global uniform vec2 refl_env;
const float ENV_PAINT = 0.8;     // clear coat strength (checked offline: horizon + trees read, colour stays)
const float ENV_GLASS = 0.35;    // tinted car glass: dark with the street in it, not a mirror (B17, 20 Nov: at 0.65 the windows read pale and see-through)
vec3 env_at(vec3 dw, float lod) {
	float u = atan(dw.x, -dw.z) * 0.15915494 + 0.5;
	float v = clamp(acos(clamp(dw.y, -1.0, 1.0)) * 0.31830989, 0.004, 0.996) * 0.5;   // each panorama = one half
	vec3 d = textureLod(env_pano, vec2(u, v), lod).rgb;
	d = mix(d, vec3(dot(d, vec3(0.3, 0.59, 0.11))) * 0.8, clamp(refl_env.y, 0.0, 1.0));      // overcast: grey, flatter
	vec3 n = textureLod(env_pano, vec2(u, v + 0.5), lod).rgb * 0.45;   // night: lamp-lit street, dimmer
	return mix(n, d, clamp(refl_env.x, 0.0, 1.0));
}
// THE CABIN BEHIND THE GLASS (Yasin, 27 Nov: "we don't have a real cabin ... make it look like it exists with some parallax
// effect"): interior mapping. A glass pixel follows the view ray into the cabin box (cabin_lo .. cabin_hi, the body's mesh
// frame) to where it leaves the box, and shows the cabin picture there: cabin_cube = six 90-degree views from the box
// centre, packed 3 x 2 (+X -X +Y / -Y +Z -Z; tools/vehicles_doors/cabin_cube.py renders it). The picture shifts with the
// camera as a real cabin would. cabin_xf takes this mesh's frame to the body's (identity on the body; a door's own
// hinge transform on a door, kept up to date by CityCar as it swings). Off (cabin_on = false): the old tinted glass.
uniform bool cabin_on = false;
uniform vec3 cabin_lo = vec3(-0.7, 0.35, -1.0);
uniform vec3 cabin_hi = vec3(0.7, 1.2, 0.3);
uniform mat4 cabin_xf = mat4(1.0);
uniform sampler2D cabin_cube : source_color, filter_linear, repeat_disable;
uniform float cabin_tint = 0.62;   // how much of the cabin the tinted glass lets through
varying vec3 v_cp;                 // this pixel, cabin frame
varying vec3 v_cc;                 // the camera, cabin frame
vec3 cabin_face(vec3 d) {
	vec3 a = abs(d);
	vec3 f; vec3 u; float i;
	if (a.x >= a.y && a.x >= a.z) { f = vec3(sign(d.x), 0.0, 0.0); u = vec3(0.0, 1.0, 0.0); i = d.x > 0.0 ? 0.0 : 1.0; }
	else if (a.y >= a.z) { f = vec3(0.0, sign(d.y), 0.0); u = vec3(0.0, 0.0, -sign(d.y)); i = d.y > 0.0 ? 2.0 : 3.0; }
	else { f = vec3(0.0, 0.0, sign(d.z)); u = vec3(0.0, 1.0, 0.0); i = d.z > 0.0 ? 4.0 : 5.0; }
	vec3 r = cross(f, u);
	float df = dot(d, f);
	vec2 st = clamp(vec2(dot(d, r), dot(d, u)) / df, -0.995, 0.995);
	vec2 fuv = vec2(st.x + 1.0, 1.0 - st.y) * 0.5;
	return texture(cabin_cube, (vec2(mod(i, 3.0), floor(i / 3.0)) + fuv) / vec2(3.0, 2.0)).rgb;
}
vec3 cabin_at(vec3 p, vec3 cam) {
	vec3 d = normalize(p - cam);
	vec3 dd = mix(d, vec3(1e-5), vec3(equal(d, vec3(0.0))));
	vec3 t1 = (cabin_lo - p) / dd, t2 = (cabin_hi - p) / dd;
	vec3 tn = min(t1, t2), tf = max(t1, t2);
	float t_far = min(min(tf.x, tf.y), tf.z);
	float t_near = max(max(tn.x, tn.y), tn.z);
	if (t_far < max(t_near, 0.0)) return vec3(0.015);   // (the ray misses the cabin: dark)
	vec3 h = p + d * t_far;
	return cabin_face(normalize(h - (cabin_lo + cabin_hi) * 0.5));
}
const float DMG_TILE = 0.45;     // m per repeat of the crumple / scratch / chip photos
const float CRACK_TILE = 0.55;   // m per repeat of the crack web
varying vec3 v_mp;               // mesh-space position before the dent (stable texture space)
varying vec3 v_mn;               // mesh-space normal
void vertex() {
	v_mp = VERTEX; v_mn = NORMAL;
	for (int i = 0; i < dent_n; i++) {
		vec3 q = VERTEX - dent_p[i].xyz;
		float f = 1.0 - smoothstep(0.0, dent_p[i].w, length(q));
		if (f > 0.0) {
			// the shape: pushed in (uneven depth = folds); the look comes per pixel in fragment()
			float wob = 0.75 + 0.25 * sin(dot(VERTEX, vec3(23.0, 17.0, 29.0)) + float(i) * 1.7);
			VERTEX += dent_d[i].xyz * f * f * wob;
		}
	}
	if (door_open > 0.001 && UV2.x <= 1.5 && all(greaterThanEqual(VERTEX, door_lo)) && all(lessThanEqual(VERTEX, door_hi))) {
		float a = -door_open * door_max;   // (its back edge swings out, to +x)
		float c = cos(a), s = sin(a);
		vec2 p = VERTEX.xz - door_hinge;
		VERTEX.xz = door_hinge + vec2(p.x * c + p.y * s, -p.x * s + p.y * c);
		NORMAL.xz = vec2(NORMAL.x * c + NORMAL.z * s, -NORMAL.x * s + NORMAL.z * c);
	}
	if (UV2.x > 1.5) {
		vec3 ax = normalize(steer_axis);
		float c = cos(steer_angle);
		float s = sin(steer_angle);
		vec3 p = VERTEX - steer_center;
		VERTEX = steer_center + p * c + cross(ax, p) * s + ax * dot(ax, p) * (1.0 - c);
		NORMAL = NORMAL * c + cross(ax, NORMAL) * s + ax * dot(ax, NORMAL) * (1.0 - c);
	}
	if (cabin_on) {
		v_cp = (cabin_xf * vec4(VERTEX, 1.0)).xyz;
		v_cc = (cabin_xf * (inverse(MODEL_MATRIX) * vec4(CAMERA_POSITION_WORLD, 1.0))).xyz;
	}
}
void fragment() {
	float lm = 0.0;
	if (UV2.x > 1.5) {
		ALBEDO = COLOR.rgb;
		ROUGHNESS = 0.75;
		METALLIC = 0.0;
		SPECULAR = 0.4;
	} else {
		bool cab = UV2.x < -0.5;                 // merged cabin: old atlas on UV
		bool m2 = map_mode == 2 && !cab;
		bool m1 = (use_maps || map_mode == 1) && !cab;
		vec4 t = m2 ? texture(trim_albedo, UV) : (m1 ? texture(albedo_map, UV) : texture(atlas, UV));
		float pm = smoothstep(0.75, 0.95, t.a);
		float gm = (1.0 - smoothstep(0.62, 0.75, t.a)) * smoothstep(0.3, 0.42, t.a);
		ALBEDO = t.rgb * mix(vec3(1.0), COLOR.rgb * paint.rgb, pm);
		ROUGHNESS = mix(mix(0.55, 0.32, pm), 0.04, gm);
		vec3 orm = vec3(1.0, ROUGHNESS, 0.0);
		lm = m2 ? smoothstep(0.08, 0.14, t.a) * (1.0 - smoothstep(0.24, 0.30, t.a)) : 0.0;
		if (m2) {
			orm = texture(trim_orm, UV).rgb;
			vec3 co = texture(car_orm, UV2).rgb;
			float g = co.g * grime_strength;
			// road film: darker, warmer, duller; heavier on the paint than on the black trim
			ALBEDO = mix(ALBEDO, ALBEDO * vec3(0.62, 0.58, 0.52) + vec3(0.075, 0.065, 0.05), clamp(g * 0.9, 0.0, 1.0));
			ALBEDO = mix(ALBEDO, ALBEDO * 0.45, gm);   // B17 (20 Nov): tinted glass is dark; at 0.14 + the cabin's 0.26 the windows read pale and see-through
			if (cabin_on && gm > 0.01) {
				ALBEDO = mix(ALBEDO, cabin_at(v_cp, v_cc) * cabin_tint, gm);   // the cabin, seen through the tinted glass (parallax)
			} else {
				ALBEDO += gm * co.b * vec3(0.07, 0.07, 0.075);   // the cabin behind the tinted glass, a hint of it
			}
			float aoc = co.r * orm.r;
			ALBEDO *= mix(1.0, co.r, 0.2 * ao_strength);                     // gap cavities read as lines, not only in shade
			ROUGHNESS = clamp(orm.g + g * 0.35 + (co.b - 0.5) * 0.22 * pm * (1.0 - gm), 0.03, 1.0);   // B on paint: clear-coat roughness variation
			AO = mix(1.0, aoc, ao_strength);
			AO_LIGHT_AFFECT = 0.55 * ao_strength;
			// one tangent frame per triangle (convert2.gd): sheet-UV frame on lamp / grille / plate / wheel / tread
			// triangles, UV2 frame on the flat-cell triangles (paint, glass, trim). At most one of the two maps has relief
			// on any triangle, so both are added in the same frame (no screen-derivative frame: it stair-stepped on edges).
			vec2 txy = texture(trim_normal, UV).rg * 2.0 - 1.0;
			vec2 cxy = texture(car_normal, UV2).rg * 2.0 - 1.0;
			vec2 nxy = (txy + cxy) * normal_strength;
			NORMAL = normalize(TANGENT * nxy.x + BINORMAL * nxy.y + NORMAL * sqrt(max(1.0 - dot(nxy, nxy), 0.04)));
		} else if (m1) {
			orm = texture(orm_map, UV).rgb;
			ROUGHNESS = orm.g;
			AO = mix(1.0, orm.r, ao_strength);
			AO_LIGHT_AFFECT = 0.55 * ao_strength;   // baked AO also darkens sun light a little (gaps, arches, under the sills)
			vec2 nxy = texture(normal_map, UV).rg * 2.0 - 1.0;          // RG only: works with 2-channel (RGTC / ASTC) normal maps
			vec3 nm = vec3(nxy * normal_strength, sqrt(max(1.0 - dot(nxy, nxy), 0.0)));
			NORMAL = normalize(TANGENT * nm.x + BINORMAL * nm.y + NORMAL * nm.z);   // the reflections below see it too
		}
		float bare = 0.0;
		if (dent_n > 0) {
			// texture space: the body's dominant axis in mesh space, metres
			vec3 an = abs(v_mn);
			vec2 pp = v_mp.xy; vec3 ta = vec3(1.0, 0.0, 0.0); vec3 tb = vec3(0.0, 1.0, 0.0);
			if (an.x > an.y && an.x > an.z) { pp = v_mp.zy; ta = vec3(0.0, 0.0, 1.0); tb = vec3(0.0, 1.0, 0.0); }
			else if (an.y > an.z) { pp = v_mp.xz; ta = vec3(1.0, 0.0, 0.0); tb = vec3(0.0, 0.0, 1.0); }
			vec4 dd = texture(damage_detail, pp / DMG_TILE);
			float brk = texture(damage_detail, pp / DMG_TILE * 0.31 + vec2(0.37, 0.71)).a;   // coarse breakup of the edge
			float dmg = 0.0; float core = 0.0; vec3 bowl = vec3(0.0);
			for (int i = 0; i < dent_n; i++) {
				vec3 q = v_mp - dent_p[i].xyz;
				float d = length(q) / max(dent_p[i].w, 0.05);
				float st = clamp(length(dent_d[i].xyz) * 6.0, 0.0, 1.0);
				float e = d + (brk - 0.5) * 0.5 + (dd.r - 0.5) * 0.25;   // a ragged outline from the photos, not a circle
				dmg = max(dmg, (1.0 - smoothstep(0.2, 1.05, e)) * st);     // the whole hit area: dulled, scuffed paint
				core = max(core, (1.0 - smoothstep(0.0, 0.55, e)) * st);   // where it touched: crumpled, scraped, chipped
				// the dent's bowl: the skin slopes down towards its centre, strongest on its wall
				vec3 qt = q - v_mn * dot(q, v_mn);
				bowl -= normalize(qt + vec3(1e-5)) * smoothstep(0.05, 0.45, d) * (1.0 - smoothstep(0.55, 1.05, d)) * st * 1.2;
			}
			if (dmg > 0.003) {
				vec2 cn = dd.rg * 2.0 - 1.0;
				vec3 pert = bowl + (ta * cn.x + tb * cn.y) * (core * 1.2 + dmg * 0.2);   // creases at the contact point
				NORMAL = normalize(NORMAL + (VIEW_MATRIX * (MODEL_MATRIX * vec4(pert, 0.0))).xyz);
				// paint: dulled + dirty over the hit, scratches through the clear coat at the contact, chips to bare steel
				float chips = texture(damage_detail, pp / (DMG_TILE * 1.9) + vec2(0.13, 0.57)).a;   // bigger, irregular flakes
				float chip = smoothstep(0.5, 0.85, max(dd.a * 0.8, chips)) * smoothstep(0.35, 0.9, core);
				float scr = dd.b * (dmg * 0.35 + core * 0.75);
				ALBEDO = mix(ALBEDO, ALBEDO * vec3(0.66, 0.64, 0.6), dmg * pm * 0.55);
				ALBEDO = mix(ALBEDO, vec3(0.56, 0.57, 0.58), clamp(max(chip, scr * 0.85), 0.0, 1.0) * pm);
				ROUGHNESS = mix(ROUGHNESS, 0.72, dmg * pm);
				ROUGHNESS = mix(ROUGHNESS, 0.36, max(chip, scr * 0.8) * pm);
				bare = max(chip, scr * 0.6) * pm;
				// glass: a web of cracks spreading from the impact, milky at the centre
				float ck = texture(glass_cracks, pp / CRACK_TILE).r * smoothstep(0.25, 0.75, core * 1.3 + dmg * 0.1);   // hard hits only
				ALBEDO = mix(ALBEDO, vec3(0.8, 0.82, 0.84), gm * ck);
				ALBEDO = mix(ALBEDO, vec3(0.38, 0.4, 0.43), gm * core * 0.5);
				ROUGHNESS = mix(ROUGHNESS, 0.55, gm * max(ck, core * 0.6));
				gm *= 1.0 - core * 0.6;
			}
		}
		METALLIC = max(max(0.35 * gm, bare * 0.85), (m1 || m2) ? orm.b : 0.0);
		SPECULAR = mix(0.6, 0.5, gm);   // (glass: F0 0.04, real glass; it was 0.08)
		// white-tyres fix: tyres / black trim are ~0.005 albedo; at roughness 0.55 + specular 0.6 the sky reflection
		// is all you see and they read white. Near-black non-paint, non-glass texels = rubber: matte, low specular.
		float rub = (1.0 - pm) * (1.0 - lm) * (1.0 - smoothstep(0.05, 0.12, gm)) * (1.0 - smoothstep(0.03, 0.10, max(t.r, max(t.g, t.b))));
		ROUGHNESS = mix(ROUGHNESS, m2 ? max(ROUGHNESS, 0.6) : 0.92, rub);
		SPECULAR = mix(SPECULAR, 0.15, rub);
		ALBEDO = mix(ALBEDO, max(ALBEDO, vec3(0.025)), rub);
		// streetR: the street reflected in the clear coat and the glass (photo panorama; see env_at)
		float refl = pm * (1.0 - rub) * ENV_PAINT + gm * ENV_GLASS + lm * ENV_LENS;
		float mref = (m1 || m2) ? orm.b * (1.0 - pm) : 0.0;   // chrome / rims / lamp reflectors mirror the street, tinted by their colour
		refl = max(refl, mref);
		if (refl > 0.01) {
			float nv = clamp(dot(NORMAL, VIEW), 0.0, 1.0);
			float fres = 0.04 + 0.96 * pow(1.0 - nv, 5.0);
			vec3 rw = (INV_VIEW_MATRIX * vec4(reflect(-VIEW, NORMAL), 0.0)).xyz;
			float gloss = 1.0 - clamp(ROUGHNESS, 0.0, 1.0);
			vec3 env = env_at(normalize(rw), ROUGHNESS * 7.0);
			// paint: a clear coat over the colour (Fresnel, ~0.25 face-on); glass: dark, mostly the reflection
			float k = mix(0.25, 1.0, fres) * gloss * gloss;
			k *= 1.0 - gm * 0.3;   // (glass reflects less at grazing angles than the clear coat: no milky side windows)
			EMISSION = env * refl * k * mix(vec3(1.0), ALBEDO * 1.6, mref);
			ALBEDO *= 1.0 - gm * 0.35 * k;   // what the glass reflects it does not show behind it
		}
	}
}
