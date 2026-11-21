shader_type spatial;
// front_bake.gd: the near's albedo x vertex colour (tints / baked AO), unlit, like the kit's bldg_wear base colour
render_mode unshaded, cull_back;
uniform sampler2D albedo_tex : source_color, filter_linear_mipmap_anisotropic;
void fragment() { ALBEDO = texture(albedo_tex, UV).rgb * COLOR.rgb; }
