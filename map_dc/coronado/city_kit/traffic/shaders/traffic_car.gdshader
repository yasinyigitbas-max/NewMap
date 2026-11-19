shader_type spatial;
render_mode diffuse_lambert;
// The traffic's cars (moving and parked), drawn as rows of a few batches by the C++ node CityTraffic
// (native/src/traffic_batches.*). Lean on purpose: no reflection map, no damage (a car that is hit becomes a CityCar,
// which has both: car_paint.gdshader).
// The parts are told apart by the colour texture's alpha, as in the game's car_paint shader:
//   ~1.0 body paint (takes the row's colour)   ~0.5 glass   ~0.0 lights, trim, tyres (their own colours)
// THE NEW CAR TEXTURES (car-tex r3, the assets branch, 19 Nov 2026), one material per model:
//   map_mode 2 (the near model, the 4 nearest cars): UV = ONE shared trim / detail sheet (lamps, grille, plate, tyres,
//     wheels, trim), UV2 = the car's own unwrap with its normal map (panel gaps) and car_orm (R AO, G grime, B the
//     cabin behind the glass); the trim sheet's own normal and orm (R AO, G roughness, B metal).
//   map_mode 1 (the light model to 85 m): UV = the car's own unwrap, its far colour and orm maps (no normal map).
//   map_mode 0: the old atlas (a model without the new maps).
// The lamps are their own batch (traffic_lamps.gdshader).
// A row: its colour = the paint (linear), its custom data = (-, -, -, 1 = a PARKED car: it is drawn by this batch only
// nearer than parked_cut; beyond it the far batch (traffic_box.gdshader) draws it, cut at the same distance, so the two
// never show together and never leave a gap).
uniform sampler2D atlas : source_color, filter_linear_mipmap;
uniform int map_mode = 0;
uniform sampler2D trim_albedo : source_color, filter_linear_mipmap_anisotropic, repeat_enable;
uniform sampler2D trim_normal : hint_normal, filter_linear_mipmap_anisotropic, repeat_enable;
uniform sampler2D trim_orm : hint_default_white, filter_linear_mipmap_anisotropic, repeat_enable;
uniform sampler2D car_normal : hint_normal, filter_linear_mipmap;
uniform sampler2D car_orm : hint_default_white, filter_linear_mipmap;
uniform sampler2D albedo_map : source_color, filter_linear_mipmap;
uniform sampler2D orm_map : hint_default_white, filter_linear_mipmap;
uniform float parked_cut = 35.0;

void vertex() {
	// (the main camera's place, also in the shadow passes, as the bake's tier shaders take it)
	if (INSTANCE_CUSTOM.w > 0.5 && distance(MAIN_CAM_INV_VIEW_MATRIX[3].xyz, (MODEL_MATRIX * vec4(0.0, 0.0, 0.0, 1.0)).xyz) >= parked_cut) VERTEX = vec3(0.0);
}

void fragment() {
	vec4 t = map_mode == 2 ? texture(trim_albedo, UV) : (map_mode == 1 ? texture(albedo_map, UV) : texture(atlas, UV));
	float pm = smoothstep(0.75, 0.95, t.a);
	float gm = (1.0 - smoothstep(0.62, 0.75, t.a)) * smoothstep(0.3, 0.42, t.a);
	ALBEDO = t.rgb * mix(vec3(1.0), COLOR.rgb, pm);
	ROUGHNESS = mix(mix(0.6, 0.34, pm), 0.08, gm);
	METALLIC = 0.0;
	SPECULAR = mix(0.4, 0.6, max(pm, gm));
	float lm = 0.0;
	if (map_mode == 2) {
		vec3 o = texture(trim_orm, UV).rgb;
		vec3 co = texture(car_orm, UV2).rgb;
		ALBEDO = mix(ALBEDO, ALBEDO * vec3(0.62, 0.58, 0.52) + vec3(0.075, 0.065, 0.05), clamp(co.g * 0.9, 0.0, 1.0));   // road film
		ALBEDO += gm * co.b * vec3(0.26, 0.26, 0.27);   // the cabin behind the tinted glass
		ALBEDO *= mix(1.0, co.r, 0.2);
		ROUGHNESS = clamp(o.g + co.g * 0.35, 0.03, 1.0);
		METALLIC = o.b;
		AO = co.r * o.r; AO_LIGHT_AFFECT = 0.55;
		vec2 nxy = (texture(trim_normal, UV).rg * 2.0 - 1.0) + (texture(car_normal, UV2).rg * 2.0 - 1.0);
		NORMAL = normalize(TANGENT * nxy.x + BINORMAL * nxy.y + NORMAL * sqrt(max(1.0 - dot(nxy, nxy), 0.04)));
		lm = smoothstep(0.08, 0.14, t.a) * (1.0 - smoothstep(0.24, 0.30, t.a));   // lamp lenses / gloss trim
	} else if (map_mode == 1) {
		vec3 o = texture(orm_map, UV).rgb;
		ROUGHNESS = o.g; METALLIC = o.b;
		AO = o.r; AO_LIGHT_AFFECT = 0.55;
	}
	// rubber: near-black, not paint, not glass, not a lens: matte (else the sky's reflection turns the tyres white)
	float rub = (1.0 - pm) * (1.0 - lm) * (1.0 - smoothstep(0.05, 0.12, gm)) * (1.0 - smoothstep(0.03, 0.10, max(t.r, max(t.g, t.b))));
	ROUGHNESS = mix(ROUGHNESS, 0.9, rub);
	SPECULAR = mix(SPECULAR, 0.15, rub);
}
