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

#include "res://tools/city/look/sky_common.gdshaderinc"

void sky() {
	COLOR = ck_sky_color(EYEDIR);
}
