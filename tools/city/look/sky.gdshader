shader_type sky;
// LOOK PACK, sky half (18 Nov). The sky of tools/city/look/look.gd: a colour run from a hazy horizon to a deep top,
// soft clouds, the sun's glow, at night stars and a moon. Written for a pixel-limited phone:
//  - it is drawn in the place of the old sky, in the same pass (no extra pass), only on pixels no building covers;
//  - per sky pixel: 2 reads of ONE small texture (256 x 256) by day, 3 at night (stars), and a little arithmetic;
//  - no TIME: a sky shader that reads TIME makes the engine redraw its reflection cube map EVERY frame. The clouds
//    move by a global value (ck_sky_drift, set by look.gd), which does not trigger that;
//  - the engine's fog is not applied to the sky (it would paint it flat): the haze at the horizon is `haze` below,
//    and look.gd gives the distance fog the same colour and the same sun glow, so buildings fade INTO this sky.
render_mode disable_fog;

uniform sampler2D noise_tex : filter_linear_mipmap, repeat_enable;      // R cloud shapes, G cloud detail, B stars
uniform vec3 zenith : source_color = vec3(0.16, 0.36, 0.74);
uniform vec3 middle : source_color = vec3(0.42, 0.62, 0.88);
uniform vec3 haze : source_color = vec3(0.80, 0.85, 0.88);              // the horizon: equals the fog colour
uniform vec3 sun_dir = vec3(0.0, 1.0, 0.0);                             // towards the sun (the moon at night)
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
uniform float stars = 0.0;             // 0 by day
global uniform vec2 ck_sky_drift;

void sky() {
	float y = max(EYEDIR.y, 0.0);
	// the colour run: haze at the horizon (and below it), thinning out quickly, then the slow run to the top
	vec3 col = mix(haze, mix(middle, zenith, smoothstep(0.0, 0.8, y)), 1.0 - exp(-y * 6.0));
	float sd = max(dot(EYEDIR, sun_dir), 0.0);
	float sd2 = sd * sd; float sd8 = sd2 * sd2; sd8 *= sd8;
	col += sun_col * (sd8 * sun_scatter);
	float sd64 = sd8 * sd8; sd64 *= sd64; sd64 *= sd64;
	vec3 glow = sun_col * (sd64 * sun_halo + smoothstep(disc_cos, disc_cos + 0.00025, sd) * sun_disc);
	if (EYEDIR.y > 0.0) {
		// clouds on a flat layer; the 0.16 keeps the layer from running to infinity at the horizon
		vec2 uv = EYEDIR.xz / (y + 0.16);
		float shape = texture(noise_tex, uv * cloud_scale + ck_sky_drift).r;
		float detail = texture(noise_tex, uv * cloud_scale * 4.1 + ck_sky_drift * 2.6 + vec2(0.37, 0.11)).g;
		float d = shape * 0.74 + detail * 0.26;
		float edge = 1.0 - cloud_cover;
		float c = smoothstep(edge, edge + 0.24, d) * smoothstep(0.015, 0.2, y) * cloud_alpha;      // melts into the haze
		vec3 cc = mix(cloud_lit, cloud_dark, smoothstep(edge + 0.1, edge + 0.52, d));               // thick middles are darker
		cc += sun_col * (sd8 * sun_scatter * 1.5);
		if (stars > 0.0) {
			col += texture(noise_tex, uv * 1.7).b * stars * smoothstep(0.05, 0.4, y);
		}
		col = mix(col + glow, cc, c);
	} else {
		col += glow;
	}
	COLOR = col;
}
