// LOOK PACK: the sky's colour for a direction, shared by the sky (sky.gdshader) and the small sky map for
// reflections (sky_map.gdshader, look job 5), so both always agree. Uniforms are set by look.gd on both materials.
uniform sampler2D noise_tex : filter_linear_mipmap, repeat_enable;      // R cloud shapes, G cloud detail, B stars
uniform vec3 zenith : source_color = vec3(0.16, 0.36, 0.74);
uniform vec3 middle : source_color = vec3(0.42, 0.62, 0.88);
uniform vec3 haze : source_color = vec3(0.80, 0.85, 0.88);              // the horizon: equals the fog colour
uniform vec3 sun_dir = vec3(0.0, 1.0, 0.0);                             // towards the sun (under the horizon at night)
uniform vec3 sun_col : source_color = vec3(1.0, 0.94, 0.82);
uniform float sun_scatter = 0.25;      // the wide glow round the sun: the fog's own formula (light energy x fog_sun_scatter)
uniform float sun_halo = 0.5;          // the tight glow
uniform float sun_disc = 6.0;          // the disc itself
uniform float disc_cos = 0.9994;       // cosine of the disc's radius
uniform vec3 cloud_lit : source_color = vec3(1.0, 0.98, 0.95);
uniform vec3 cloud_dark : source_color = vec3(0.62, 0.68, 0.78);
uniform float cloud_cover = 0.5;      // 0 none .. 1 overcast
uniform float cloud_alpha = 0.9;
uniform float cloud_scale = 0.2;     // texture repeats per unit of the cloud layer: bigger = smaller clouds
uniform float stars = 0.0;             // 0 by day; rises with the dusk
// look queue 2, job 2: the sun's glare, the moon
uniform float sun_glare = 0.35;        // a soft wide glare round the disc (no bloom pass: it is drawn into the sky)
uniform vec3 moon_dir = vec3(0.0, 0.64, -0.77);
uniform float moon_amount = 0.0;       // 0 by day .. 1 at night
uniform vec3 moon_col : source_color = vec3(0.86, 0.89, 0.97);
global uniform vec2 ck_sky_drift;

vec3 ck_sky_color(vec3 dir) {
	float y = max(dir.y, 0.0);
	// the colour run: haze at the horizon (and below it), thinning out quickly, then the slow run to the top
	vec3 col = mix(haze, mix(middle, zenith, smoothstep(0.0, 0.8, y)), 1.0 - exp(-y * 6.0));
	float sd = max(dot(dir, sun_dir), 0.0);
	float sd2 = sd * sd; float sd8 = sd2 * sd2; sd8 *= sd8;
	col += sun_col * (sd8 * sun_scatter);
	float sd64 = sd8 * sd8; sd64 *= sd64; sd64 *= sd64;
	float up = smoothstep(-0.06, 0.03, sun_dir.y);      // the disc and its glare sink behind the horizon
	float x = 1.0 - sd;                                  // ~ half the squared angle from the sun
	vec3 glow = sun_col * up * (sd64 * sun_halo + exp(-x * 1800.0) * sun_glare + smoothstep(disc_cos, disc_cos + 0.00025, sd) * sun_disc);
	// the moon: a disc of about 1.2 degrees, mottled by the noise texture (read only on its own pixels), a faint halo
	if (moon_amount > 0.001) {
		float md = dot(dir, moon_dir);
		float mx = 1.0 - md;
		glow += moon_col * moon_amount * exp(-mx * 700.0) * 0.12;
		if (md > 0.9998) {
			vec3 side = normalize(cross(moon_dir, vec3(0.0, 1.0, 0.0))); vec3 upm = cross(side, moon_dir);
			vec2 muv = vec2(dot(dir - moon_dir, side), dot(dir - moon_dir, upm)) * 45.0;
			float mott = texture(noise_tex, muv + vec2(0.31, 0.77)).g;
			glow += moon_col * moon_amount * smoothstep(0.99979, 0.99984, md) * (1.6 + mott * 0.9);
		}
	}
	if (dir.y > 0.0) {
		// clouds on a flat layer; the 0.16 keeps the layer from running to infinity at the horizon
		vec2 uv = dir.xz / (y + 0.16);
		float shape = texture(noise_tex, uv * cloud_scale + ck_sky_drift).r;
		float detail = texture(noise_tex, uv * cloud_scale * 4.1 + ck_sky_drift * 2.6 + vec2(0.37, 0.11)).g;
		float d = shape * 0.74 + detail * 0.26;
		float edge = 1.0 - cloud_cover;
		float c = smoothstep(edge, edge + 0.24, d) * smoothstep(0.015, 0.2, y) * cloud_alpha;      // melts into the haze
		vec3 cc = mix(cloud_lit, cloud_dark, smoothstep(edge + 0.1, edge + 0.52, d));               // thick middles are darker
		cc += sun_col * (sd8 * sun_scatter * 1.5);
		if (stars > 0.001) {      // thin near the horizon (haze), none round the moon
			float st = texture(noise_tex, uv * 1.7).b;
			col += st * st * 1.6 * stars * smoothstep(0.05, 0.45, y) * (1.0 - moon_amount * exp(-(1.0 - dot(dir, moon_dir)) * 60.0));
		}
		col = mix(col + glow, cc, c);
	} else {
		col += glow;
	}
	return col;
}
