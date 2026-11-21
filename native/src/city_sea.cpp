// CitySea: see city_sea.h.
#include "city_sea.h"
#include <godot_cpp/classes/array_mesh.hpp>
#include <godot_cpp/classes/file_access.hpp>
#include <godot_cpp/classes/image.hpp>
#include <godot_cpp/classes/json.hpp>
#include <godot_cpp/classes/plane_mesh.hpp>
#include <godot_cpp/classes/resource_loader.hpp>
#include <godot_cpp/classes/shader.hpp>
#include <godot_cpp/classes/standard_material3d.hpp>
#include <godot_cpp/classes/texture2d.hpp>
#include <godot_cpp/core/class_db.hpp>
#include <vector>

namespace godot {

Ref<ShaderMaterial> *g_sea_mat = nullptr;   // (made on first use: no Godot type as a static, see foot_steps.h)

Ref<ShaderMaterial> CitySea::get_sea_material() {
	if (!g_sea_mat) g_sea_mat = new Ref<ShaderMaterial>();
	if (g_sea_mat->is_null()) {
		ResourceLoader *rl = ResourceLoader::get_singleton();
		Ref<ShaderMaterial> m; m.instantiate();
		m->set_shader(rl->load("res://tools/city/look/sea.gdshader"));
		m->set_shader_parameter("ripple_tex", rl->load("res://tools/city/look/sky_noise.png"));
		m->set_render_priority(-127);   // after the city (see city_sea.h)
		*g_sea_mat = m;
	}
	return *g_sea_mat;
}

MeshInstance3D *CitySea::make_backstop(double p_size, double p_y) {
	MeshInstance3D *gp = memnew(MeshInstance3D);
	Ref<PlaneMesh> pm; pm.instantiate(); pm->set_size(Vector2((float)p_size, (float)p_size)); gp->set_mesh(pm);
	Ref<StandardMaterial3D> gm; gm.instantiate(); gm->set_albedo(Color(0.36f, 0.42f, 0.3f)); gm->set_roughness(1.0f);
	gm->set_render_priority(-128);   // the very last: only the pixels nothing else covers are shaded
	gp->set_material_override(gm); gp->set_position(Vector3(0, (float)p_y, 0)); gp->set_name("backstop");
	gp->set_cast_shadows_setting(GeometryInstance3D::SHADOW_CASTING_SETTING_OFF);
	return gp;
}

void CitySea::build() {
	const Variant mv = JSON::parse_string(FileAccess::get_file_as_string("res://tools/city/look/sea_map.json"));
	if (mv.get_type() != Variant::DICTIONARY) return;
	const Dictionary meta = mv;
	Ref<Texture2D> tex = ResourceLoader::get_singleton()->load("res://tools/city/look/sea_map.png");
	if (tex.is_null()) return;
	Ref<Image> img = tex->get_image();
	if (img.is_null()) return;
	if (img->is_compressed()) img->decompress();
	const float x0 = (float)(double)meta["x0"], z0 = (float)(double)meta["z0"], step = (float)(double)meta["step"];
	const int EVERY = 2; const float FAR = 8000.0f;   // texels per grid step (16 m); the skirt's reach
	const int W = img->get_width(), H = img->get_height(), nx = (W - 1) / EVERY + 1, nz = (H - 1) / EVERY + 1;
	PackedVector3Array V; PackedColorArray C; PackedInt32Array I;
	std::vector<int> idx((size_t)nx * nz, -1); std::vector<uint8_t> lay((size_t)nx * nz, 0);
	for (int gz = 0; gz < nz; gz++) for (int gx = 0; gx < nx; gx++) lay[(size_t)gz * nx + gx] = img->get_pixel(gx * EVERY, gz * EVERY).g > 0.5f ? 1 : 0;
	auto vert = [&](int gx, int gz) -> int {
		const size_t k = (size_t)gz * nx + gx;
		if (idx[k] < 0) {
			idx[k] = (int)V.size();
			V.push_back(Vector3(x0 + (float)(gx * EVERY) * step, 0.0f, z0 + (float)(gz * EVERY) * step));
			C.push_back(Color(img->get_pixel(gx * EVERY, gz * EVERY).r, 0, 0, 1));
		}
		return idx[k];
	};
	for (int gz = 0; gz < nz - 1; gz++)
		for (int gx = 0; gx < nx - 1; gx++) {
			if (lay[(size_t)gz * nx + gx] + lay[(size_t)gz * nx + gx + 1] + lay[(size_t)(gz + 1) * nx + gx] + lay[(size_t)(gz + 1) * nx + gx + 1] == 0) continue;
			const int a = vert(gx, gz), b = vert(gx + 1, gz), c = vert(gx, gz + 1), d = vert(gx + 1, gz + 1);
			I.push_back(a); I.push_back(b); I.push_back(c); I.push_back(b); I.push_back(d); I.push_back(c);
		}
	// the skirt: deep water from the frame to the horizon, on all four sides (21 Nov, the fill: the island's west end is
	// closed by a beach inside the frame, tools/city/fill/fields.py WEST_COAST; before, the land ran on west of the frame
	// between the two coasts and the skirt left that band dry)
	const float gx1 = x0 + (float)((nx - 1) * EVERY) * step, gz1 = z0 + (float)((nz - 1) * EVERY) * step;
	const float rects[4][4] = { { -FAR, -FAR, FAR, z0 }, { -FAR, gz1, FAR, FAR }, { gx1, z0, FAR, gz1 }, { -FAR, z0, x0, gz1 } };
	for (const auto &r : rects) {
		const int b0 = (int)V.size();
		const Vector2 q[4] = { Vector2(r[0], r[1]), Vector2(r[2], r[1]), Vector2(r[0], r[3]), Vector2(r[2], r[3]) };
		for (const Vector2 &p : q) { V.push_back(Vector3(p.x, 0.0f, p.y)); C.push_back(Color(1, 0, 0, 1)); }
		I.push_back(b0); I.push_back(b0 + 1); I.push_back(b0 + 2); I.push_back(b0 + 1); I.push_back(b0 + 3); I.push_back(b0 + 2);
	}
	PackedVector3Array N; N.resize(V.size()); N.fill(Vector3(0, 1, 0));
	Array arr; arr.resize(Mesh::ARRAY_MAX);
	arr[Mesh::ARRAY_VERTEX] = V; arr[Mesh::ARRAY_NORMAL] = N; arr[Mesh::ARRAY_COLOR] = C; arr[Mesh::ARRAY_INDEX] = I;
	Ref<ArrayMesh> am; am.instantiate(); am->add_surface_from_arrays(Mesh::PRIMITIVE_TRIANGLES, arr);
	set_mesh(am); set_material_override(get_sea_material()); set_name("look_sea");
	set_cast_shadows_setting(SHADOW_CASTING_SETTING_OFF);
	tris = (int)I.size() / 3;
	set_meta("tris", tris); set_meta("deep", meta.get("deep", 20.0));
}

void CitySea::_exit_tree() {
	if (g_sea_mat) g_sea_mat->unref();
	set_material_override(Ref<Material>());
}

void CitySea::_bind_methods() {
	ClassDB::bind_method(D_METHOD("build"), &CitySea::build);
	ClassDB::bind_method(D_METHOD("get_tris"), &CitySea::get_tris);
	ClassDB::bind_static_method("CitySea", D_METHOD("get_sea_material"), &CitySea::get_sea_material);
	ClassDB::bind_static_method("CitySea", D_METHOD("make_backstop", "size", "y"), &CitySea::make_backstop);
}

} // namespace godot
