// CitySkyline: see city_skyline.h (the numbers and order of tools/city/look/skyline.gd, line for line).
#include "city_skyline.h"
#include <godot_cpp/classes/array_mesh.hpp>
#include <godot_cpp/classes/file_access.hpp>
#include <godot_cpp/classes/json.hpp>
#include <godot_cpp/classes/resource_loader.hpp>
#include <godot_cpp/classes/shader.hpp>
#include <godot_cpp/core/class_db.hpp>
#include <algorithm>
#include <cmath>

namespace godot {

static const char *SKY_DIR = "res://map_dc/coronado/city_kit/skyline/";
static const int SEGS = 360;           // columns of the ring (one a degree)
static const float FAR_LOW = -40.0f;   // the far ring goes on down to here (the sea's colour), for high cameras
static Ref<ShaderMaterial> *g_sky_mat = nullptr;   // made on first use (no Godot type as a static)
static Dictionary *g_sky_meta = nullptr;

static const Dictionary &sky_meta() {
	if (!g_sky_meta) {
		g_sky_meta = new Dictionary();
		const Variant v = JSON::parse_string(FileAccess::get_file_as_string(String(SKY_DIR) + "skyline.json"));
		if (v.get_type() == Variant::DICTIONARY) *g_sky_meta = v;
	}
	return *g_sky_meta;
}

Ref<ShaderMaterial> CitySkyline::get_skyline_material() {
	if (!g_sky_mat) g_sky_mat = new Ref<ShaderMaterial>();
	if (g_sky_mat->is_null()) {
		ResourceLoader *rl = ResourceLoader::get_singleton();
		const Dictionary &m = sky_meta();
		Ref<ShaderMaterial> mt; mt.instantiate();
		mt->set_shader(rl->load("res://tools/city/look/skyline.gdshader"));
		mt->set_shader_parameter("day_tex", rl->load(String(SKY_DIR) + "skyline_day.png"));
		mt->set_shader_parameter("lights_tex", rl->load(String(SKY_DIR) + "skyline_lights.png"));
		const Array c = m.get("centre_grid", Array());
		if (c.size() >= 2) mt->set_shader_parameter("centre", Vector2((float)(double)c[0], (float)(double)c[1]));
		mt->set_render_priority(Material::RENDER_PRIORITY_MIN);   // first of the see-through things: lamp halos stay in front of it
		*g_sky_mat = mt;
	}
	return *g_sky_mat;
}

// the near ring's radius (m) at grid azimuth phi (degrees from -Z, clockwise), smooth between the table's points
static float ring_r(float phi, const Array &ring) {
	phi = std::fmod(std::fmod(phi, 360.0f) + 360.0f, 360.0f);
	for (int i = 0; i < ring.size() - 1; i++) {
		const Array a = ring[i], b = ring[i + 1];
		if (phi <= (float)(double)b[0]) {
			float f = (phi - (float)(double)a[0]) / std::max((float)(double)b[0] - (float)(double)a[0], 0.001f); f = f * f * (3.0f - 2.0f * f);
			return (float)(double)a[1] + ((float)(double)b[1] - (float)(double)a[1]) * f;
		}
	}
	return ring.size() ? (float)(double)Array(ring[ring.size() - 1])[1] : 4000.0f;
}

void CitySkyline::build() {
	const Dictionary &m = sky_meta();
	if (m.is_empty()) return;
	const Array nel = m["near_el"], fel = m["far_el"], rows = m["rows"], ring = m["ring"], c = m["centre_grid"];
	const float H = (float)(double)rows[0] + (float)(double)rows[1], eye = (float)(double)m["eye_m"];
	const float cx = (float)(double)c[0], cz = (float)(double)c[1];
	PackedVector3Array V; PackedVector2Array UV, K; PackedColorArray C; PackedInt32Array I;
	const float half = 0.5f / H, D2R = 0.017453292f;
	// FAR: three rows of vertices (top, bottom of the painted part, the sea's colour on down to FAR_LOW)
	const float far_rows[3][2] = { { (float)(double)fel[0], (float)(double)rows[0] / H + half }, { (float)(double)fel[1], 1.0f - half }, { FAR_LOW, 1.0f - half } };
	for (int j = 0; j <= SEGS; j++) {
		const float phi = 360.0f * (float)j / (float)SEGS, s = std::sin(phi * D2R), co = std::cos(phi * D2R);
		for (const auto &r : far_rows) {
			const float e = r[0] * D2R;
			V.push_back(Vector3(s * std::cos(e), std::sin(e), -co * std::cos(e))); UV.push_back(Vector2((float)j / (float)SEGS, r[1])); K.push_back(Vector2(0, 0)); C.push_back(Color(1, 1, 1));
		}
	}
	for (int j = 0; j < SEGS; j++)
		for (int k = 0; k < 2; k++) {
			const int a = j * 3 + k, b = (j + 1) * 3 + k;
			I.push_back(a); I.push_back(b); I.push_back(a + 1); I.push_back(b); I.push_back(b + 1); I.push_back(a + 1);
		}
	// NEAR: two rows on the ring, heights eye + tan(elevation) x r (the paint is in elevation as seen from the centre)
	const int n0 = (int)V.size();
	for (int j = 0; j <= SEGS; j++) {
		const float phi = 360.0f * (float)j / (float)SEGS, s = std::sin(phi * D2R), co = std::cos(phi * D2R), rr = ring_r(phi, ring);
		for (int k = 0; k < 2; k++) {
			const float e = (float)(double)nel[k], v = k == 0 ? half : (float)(double)rows[0] / H - half;
			V.push_back(Vector3(cx + s * rr, eye + std::tan(e * D2R) * rr, cz - co * rr)); UV.push_back(Vector2((float)j / (float)SEGS, v)); K.push_back(Vector2(1, 0)); C.push_back(Color(1, 1, 1));
		}
	}
	for (int j = 0; j < SEGS; j++) {
		const int a = n0 + j * 2, b = n0 + (j + 1) * 2;
		I.push_back(a); I.push_back(b); I.push_back(a + 1); I.push_back(b); I.push_back(b + 1); I.push_back(a + 1);
	}
	// SOLIDS: the bridge and Coronado Shores as boxes at their true places (make_skyline.py says why), drawn last
	const Array solids = m.get("solids", Array());
	for (int q = 0; q < solids.size(); q++) {
		const Array sq = solids[q]; const Array col = sq[4]; const int b0 = (int)V.size();
		for (int k = 0; k < 4; k++) {
			const Array p = sq[k];
			V.push_back(Vector3((float)(double)p[0], (float)(double)p[1], (float)(double)p[2])); UV.push_back(Vector2()); K.push_back(Vector2(2, 0));
			C.push_back(Color((float)(double)col[0], (float)(double)col[1], (float)(double)col[2], (float)(double)col[3]));
		}
		I.push_back(b0); I.push_back(b0 + 1); I.push_back(b0 + 2); I.push_back(b0); I.push_back(b0 + 2); I.push_back(b0 + 3);
	}
	Array arr; arr.resize(Mesh::ARRAY_MAX);
	arr[Mesh::ARRAY_VERTEX] = V; arr[Mesh::ARRAY_TEX_UV] = UV; arr[Mesh::ARRAY_TEX_UV2] = K; arr[Mesh::ARRAY_COLOR] = C; arr[Mesh::ARRAY_INDEX] = I;
	Ref<ArrayMesh> am; am.instantiate(); am->add_surface_from_arrays(Mesh::PRIMITIVE_TRIANGLES, arr);
	set_name("skyline"); set_mesh(am); set_material_override(get_skyline_material());
	set_as_top_level(true);
	set_custom_aabb(AABB(Vector3(-100000, -100000, -100000), Vector3(200000, 200000, 200000)));   // holds every camera: never frustum-culled
	set_extra_cull_margin(16384.0f);
	set_cast_shadows_setting(SHADOW_CASTING_SETTING_OFF);
	set_gi_mode(GI_MODE_DISABLED);
	set_ignore_occlusion_culling(true);
	set_visibility_range_begin(0.0f); set_visibility_range_end(0.0f);   // no LOD / range fade
	tris = (int)I.size() / 3; set_meta("tris", tris);
}

void CitySkyline::_exit_tree() {
	if (g_sky_mat) g_sky_mat->unref();   // (the shared material let go with the ring: no leak reported at exit)
	set_material_override(Ref<Material>());
}

void CitySkyline::_bind_methods() {
	ClassDB::bind_method(D_METHOD("build"), &CitySkyline::build);
	ClassDB::bind_method(D_METHOD("get_tris"), &CitySkyline::get_tris);
	ClassDB::bind_static_method("CitySkyline", D_METHOD("get_skyline_material"), &CitySkyline::get_skyline_material);
}

} // namespace godot
