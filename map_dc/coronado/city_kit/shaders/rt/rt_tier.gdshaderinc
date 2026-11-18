// Tier hand-over (19 Nov; Yasin: "it snaps from near to far directly and everythings appereance change suddenly as we
// get near"). Shared by every baked shader that has a tier: rt_bldg (near / mid buildings), rt_prop and rt_foliage
// (near / mid props and plants) and rt_far (the far world).
//
// A tier is drawn over a distance window [b, e) from the camera to the object's own pivot. Outside it the object
// collapses to a point in the vertex shader (no pixel cost). Two switches, both off in the baked materials:
//
//  CK_TIERS (a compile switch: city_stream.gd set_tiers() swaps every held material to a copy of its shader with this
//  defined, before the warm-up, so with it off the city draws exactly as before and pays nothing for it):
//   - FAR TO MID BY DISTANCE, not by cell. ck_cells_loaded holds, per 200 m cell, 0 = not in, 1 = in, and in between
//     for a cell that is arriving (city_stream.gd arrive_s). An arriving cell's switch to far starts at the camera and
//     sweeps out to 220 m (S = 220 m x ramp), so its objects take over from their far versions nearest first and not
//     all in the arrival frame.
//   - FADES: ck_tier_band (m) wide overlaps at each switch (60 m and 220 m), drawn OPAQUE with a screen-door dither:
//     the two tiers share the pixels of the band by one fixed noise per screen pixel (the inner tier keeps the pixels
//     with noise < w, the outer one the rest), so there is never a hole and never a pixel drawn twice. No blending.
//     Per pixel: 1 branch on a per-object value; inside a band also 5 ALU for the noise and a discard. The real cost
//     is that a shader that can discard loses the GPU's early hidden-surface removal (Mali: forward pixel kill) for
//     every pixel it draws: measured on the phone, see docs/RUNTIME_BAKE.md "The tiers".
//  ck_tier_band = 0 with CK_TIERS on: hard cuts, the sweep stays.
// The bake makes node visibility ranges CK_BAND_MAX / 2 wider than the windows, so a band up to CK_BAND_MAX is drawn.
global uniform sampler2D ck_cells_loaded;
global uniform float ck_tier_band;
const float CK_FAR_M = 220.0;
const float CK_BAND_MAX = 8.0;

// the cell of a world position: 0 not in, 0..1 arriving, 1 in (cells outside the 64 x 64 map count as in)
float ck_cell_ramp(vec3 wp) {
	ivec2 c = ivec2(int(floor(wp.x / 200.0)) + 32, int(floor(wp.z / 200.0)) + 32);
	if (c.x < 0 || c.y < 0 || c.x >= 64 || c.y >= 64) return 1.0;
	return texelFetch(ck_cells_loaded, c, 0).r;
}

// How much of an object at distance d a tier [b, e) draws: 1 inside, 0 outside, a ramp over the band at each end.
// Returns (begin weight, end weight); the object is drawn where noise >= 1 - x and noise < y.
vec2 ck_weights(float d, float b, float e) {
	float band = clamp(ck_tier_band, 0.0, CK_BAND_MAX);
	float h = band * 0.5; float inv = 1.0 / max(band, 1.0e-4);
	if (e - b < 0.01) return vec2(0.0);
	float wb = b <= 0.0 ? 1.0 : clamp((d - (b - h)) * inv, 0.0, 1.0);
	float we = clamp(((e + h) - d) * inv, 0.0, 1.0);
	return vec2(wb, we);
}

// one fixed noise value per screen pixel, 0..1 (interleaved gradient noise)
float ck_noise(vec2 fc) {
	return fract(52.9829189 * fract(dot(fc, vec2(0.06711056, 0.00583715))));
}

// the fragment side: drop the pixels this tier does not own (only while an object is inside a band). The shader
// declares `varying vec2 v_tw;` (the weights from its vertex shader).
#define CK_DITHER if (v_tw.x < 0.999 || v_tw.y < 0.999) { float ck_n = ck_noise(FRAGCOORD.xy); if (ck_n < 1.0 - v_tw.x || ck_n >= v_tw.y) discard; }
