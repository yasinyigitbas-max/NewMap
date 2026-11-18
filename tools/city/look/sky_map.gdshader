shader_type canvas_item;
// LOOK JOB 5: the look's sky as a small panorama (latitude / longitude, 128 x 64) for reflections in glass and wet
// ground (tools/city/look/sky_reflect.gdshaderinc). Drawn once into a SubViewport by look.gd when the time of day
// changes, never per frame. Same maths as the sky itself (sky_common.gdshaderinc).
#include "res://tools/city/look/sky_common.gdshaderinc"
uniform vec3 ground_col = vec3(0.08);      // queue 2 job 6: below the horizon the street, dimly lit (cars reflect it)
void fragment() {
	float lon = (UV.x - 0.5) * 6.2831853;
	float lat = (0.5 - UV.y) * 3.1415927;
	vec3 d = vec3(cos(lat) * sin(lon), sin(lat), -cos(lat) * cos(lon));
	vec3 c = ck_sky_color(d);
	c = mix(c, ground_col, smoothstep(0.0, -0.12, d.y));      // the haze at the horizon, the street under it
	COLOR = vec4(c, 1.0);
}
