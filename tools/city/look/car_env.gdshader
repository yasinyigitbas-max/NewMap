shader_type canvas_item;
// LOOK QUEUE 2, JOB 6: the look's sky map (ck_sky_map) in the layout the game's car shader reads (vehicles/
// car_paint.gdshader, env_pano: a latitude / longitude panorama in each half, day above, night below). The look's map
// is already the current time of day, so both halves get the same picture (and the look sets refl_env = (1, 0)).
// Drawn by look.gd when the sky map changes (128 x 128 pixels, once), never per frame.
global uniform sampler2D ck_sky_map : filter_linear, repeat_enable;
void fragment() {
	COLOR = vec4(textureLod(ck_sky_map, vec2(UV.x, fract(UV.y * 2.0)), 0.0).rgb, 1.0);
}
