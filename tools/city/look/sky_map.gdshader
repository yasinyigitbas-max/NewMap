shader_type canvas_item;
// LOOK JOB 5: the look's sky as a small panorama (latitude / longitude, 128 x 64) for reflections in glass and wet
// ground (tools/city/look/sky_reflect.gdshaderinc). Drawn once into a SubViewport by look.gd when the time of day
// changes, never per frame. Same maths as the sky itself (sky_common.gdshaderinc).
#include "res://tools/city/look/sky_common.gdshaderinc"
void fragment() {
	float lon = (UV.x - 0.5) * 6.2831853;
	float lat = (0.5 - UV.y) * 3.1415927;
	vec3 d = vec3(cos(lat) * sin(lon), sin(lat), -cos(lat) * cos(lon));
	COLOR = vec4(ck_sky_color(d), 1.0);
}
