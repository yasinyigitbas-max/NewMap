// CityCrowd: see city_crowd.h.
#include "city_crowd.h"

#include "city_ped.h"
#include "city_player.h"
#include "city_traffic.h"
#include "ped_inl.h"
#include "traffic_sim.h"

#include <godot_cpp/classes/array_mesh.hpp>
#include <godot_cpp/classes/camera3d.hpp>
#include <godot_cpp/classes/file_access.hpp>
#include <godot_cpp/classes/image.hpp>
#include <godot_cpp/classes/json.hpp>
#include <godot_cpp/classes/rendering_server.hpp>
#include <godot_cpp/classes/resource_loader.hpp>
#include <godot_cpp/classes/shader.hpp>
#include <godot_cpp/classes/texture_layered.hpp>
#include <godot_cpp/classes/time.hpp>
#include <godot_cpp/classes/viewport.hpp>
#include <godot_cpp/classes/world3d.hpp>
#include <godot_cpp/core/class_db.hpp>
#include <godot_cpp/variant/callable.hpp>
#include <godot_cpp/variant/packed_vector3_array.hpp>
#include <godot_cpp/variant/utility_functions.hpp>

#include <cstring>

namespace godot {

namespace {

const float STEP_S = 0.05f;
const int GRID = 64;
const float POSE_K = 512.0f;

inline int64_t usec_now() { return (int64_t)Time::get_singleton()->get_ticks_usec(); }
inline float lerp_angle(float a, float b, float t) { return a + pc::wrap_pi(b - a) * t; }

// the people's colours, as the old game had them (npc_people.gd, char_look.gd): sRGB
const float HAIR[8][3] = { { 0.06f, 0.05f, 0.05f }, { 0.1f, 0.07f, 0.05f }, { 0.16f, 0.1f, 0.06f }, { 0.24f, 0.15f, 0.09f }, { 0.33f, 0.2f, 0.11f }, { 0.48f, 0.34f, 0.2f }, { 0.78f, 0.62f, 0.36f }, { 0.45f, 0.18f, 0.08f } };
const float EYES[4][3] = { { 0.3f, 0.18f, 0.08f }, { 0.2f, 0.45f, 0.85f }, { 0.2f, 0.55f, 0.3f }, { 0.55f, 0.42f, 0.2f } };
const float SKINS[4][3] = { { 0.82f, 0.63f, 0.52f }, { 0.80f, 0.58f, 0.44f }, { 0.64f, 0.44f, 0.31f }, { 0.38f, 0.25f, 0.17f } };
const float LIPS[4][3] = { { 0.8f, 0.16f, 0.22f }, { 0.68f, 0.24f, 0.38f }, { 0.84f, 0.5f, 0.5f }, { 0.9f, 0.42f, 0.36f } };
const float SUITS[8][3] = { { 0.1f, 0.13f, 0.24f }, { 0.2f, 0.2f, 0.22f }, { 0.38f, 0.38f, 0.4f }, { 0.3f, 0.22f, 0.16f }, { 0.06f, 0.06f, 0.07f }, { 0.62f, 0.55f, 0.42f }, { 0.15f, 0.22f, 0.18f }, { 0.3f, 0.1f, 0.12f } };
const float TOPS[44][3] = { { 0.95f, 0.95f, 0.93f }, { 0.08f, 0.11f, 0.24f }, { 0.82f, 0.72f, 0.52f }, { 0.45f, 0.3f, 0.6f }, { 0.2f, 0.55f, 0.56f }, { 0.06f, 0.06f, 0.07f }, { 0.72f, 0.16f, 0.14f }, { 0.35f, 0.5f, 0.75f },
	{ 0.55f, 0.6f, 0.35f }, { 0.9f, 0.78f, 0.3f }, { 0.95f, 0.6f, 0.55f }, { 0.42f, 0.42f, 0.44f }, { 0.25f, 0.35f, 0.25f }, { 0.6f, 0.75f, 0.88f }, { 0.85f, 0.45f, 0.2f }, { 0.55f, 0.25f, 0.35f },
	{ 0.88f, 0.86f, 0.8f }, { 0.15f, 0.25f, 0.45f }, { 0.7f, 0.7f, 0.72f }, { 0.3f, 0.2f, 0.15f }, { 0.95f, 0.85f, 0.7f }, { 0.4f, 0.65f, 0.5f }, { 0.8f, 0.3f, 0.5f }, { 0.2f, 0.2f, 0.22f },
	// role colours
	{ 0.25f, 0.6f, 0.62f }, { 0.55f, 0.7f, 0.85f }, { 0.12f, 0.18f, 0.35f }, { 0.3f, 0.55f, 0.4f }, { 0.45f, 0.12f, 0.18f }, { 0.96f, 0.96f, 0.95f }, { 0.85f, 0.95f, 0.15f }, { 1.0f, 0.45f, 0.05f },
	{ 0.94f, 0.94f, 0.91f }, { 0.07f, 0.07f, 0.08f }, { 0.32f, 0.26f, 0.18f }, { 0.3f, 0.3f, 0.2f }, { 0.35f, 0.35f, 0.34f }, { 0.95f, 0.2f, 0.55f }, { 0.8f, 0.05f, 0.1f }, { 0.45f, 0.1f, 0.55f },
	{ 0.85f, 0.65f, 0.2f }, { 0.18f, 0.18f, 0.19f }, { 0.3f, 0.42f, 0.6f }, { 0.62f, 0.55f, 0.4f } };
const float BOTTOMS[30][3] = { { 0.22f, 0.33f, 0.52f }, { 0.35f, 0.45f, 0.62f }, { 0.62f, 0.54f, 0.38f }, { 0.06f, 0.06f, 0.07f }, { 0.7f, 0.35f, 0.15f }, { 0.4f, 0.4f, 0.42f }, { 0.15f, 0.2f, 0.32f }, { 0.85f, 0.83f, 0.78f },
	{ 0.3f, 0.32f, 0.22f }, { 0.5f, 0.4f, 0.3f }, { 0.18f, 0.18f, 0.2f }, { 0.55f, 0.6f, 0.7f }, { 0.6f, 0.2f, 0.18f }, { 0.25f, 0.4f, 0.55f }, { 0.72f, 0.68f, 0.6f }, { 0.1f, 0.12f, 0.2f },
	// role colours
	{ 0.25f, 0.6f, 0.62f }, { 0.55f, 0.7f, 0.85f }, { 0.12f, 0.18f, 0.35f }, { 0.3f, 0.55f, 0.4f }, { 0.45f, 0.12f, 0.18f }, { 0.24f, 0.18f, 0.12f }, { 0.3f, 0.3f, 0.24f }, { 0.06f, 0.06f, 0.07f },
	{ 0.04f, 0.04f, 0.05f }, { 0.75f, 0.05f, 0.1f }, { 0.94f, 0.94f, 0.92f }, { 0.15f, 0.18f, 0.28f }, { 0.55f, 0.48f, 0.35f }, { 0.2f, 0.2f, 0.21f } };

PackedVector3Array table(const float (*c)[3], int n, bool linear) {
	PackedVector3Array a;
	for (int k = 0; k < n; k++) {
		Color col(c[k][0], c[k][1], c[k][2]);
		if (linear) col = col.srgb_to_linear();
		a.push_back(Vector3(col.r, col.g, col.b));
	}
	return a;
}

int tag_of(const String &t, bool police) {
	if (police) return 2;
	if (t == "office") return 1;
	if (t == "medical") return 3;
	if (t == "trade") return 4;
	if (t == "swim") return 5;
	if (t == "navy") return 6;
	if (t == "night") return 7;
	return 0;
}

} // namespace

CityCrowd::CityCrowd() { crowd = new pc::Crowd(); }
CityCrowd::~CityCrowd() { delete crowd; }

// The streets, the places, the bodies' table.
bool CityCrowd::load() {
	ready = false;
	const PackedByteArray sb = FileAccess::get_file_as_bytes(streets_path);
	sg::StreetData d;
	if (sb.size() < 16 || !d.load(sb.ptr(), (size_t)sb.size()) || !crowd->build(d)) { UtilityFunctions::push_error("CityCrowd: no streets (", streets_path, "): run tools/city/traffic/make_streets.gd"); return false; }
	const PackedByteArray pbs = FileAccess::get_file_as_bytes(places_path);
	pc::PlaceData pd;
	if (pbs.size() >= 12 && pd.load(pbs.ptr(), (size_t)pbs.size())) {
		crowd->set_places(pd);
		place_names.clear();
		for (const std::string &nm : pd.names) place_names.push_back(String::utf8(nm.c_str()));
	}
	else UtilityFunctions::push_warning("CityCrowd: no places (", places_path, "): people only walk about. Run tools/city/traffic/make_places.gd");
	ready = true;
	return true;
}

// The far figures' table, the people's material, the batch.
void CityCrowd::make_look() {
	Ref<FileAccess> f = FileAccess::open_compressed(people_dir + String("far_poses.bin"), FileAccess::READ, FileAccess::COMPRESSION_ZSTD);
	if (f.is_null() || f->get_32() != 0x32525046u) { UtilityFunctions::push_error("CityCrowd: no far figures (", people_dir, "far_poses.bin): run tools/city/traffic/make_people.gd"); return; }
	tex_w = (int)f->get_32(); tex_h = (int)f->get_32(); corner_h = (int)f->get_32();
	const int poses = (int)f->get_32(), n = (int)f->get_32();
	corners_max = (int)f->get_32();
	for (int g = 0; g < 2; g++) for (int q = 0; q < 6; q++) gait[g][q] = f->get_float();
	stride[0] = gait[0][0]; stride[1] = gait[1][0];
	if (poses != POSES || n <= 0 || n > 64 || tex_w <= 0 || tex_h <= 0) { UtilityFunctions::push_error("CityCrowd: far_poses.bin is of another make: run make_people.gd again"); return; }
	block_rows = (2 * POSES + 1) * corner_h;
	const Variant mv = JSON::parse_string(FileAccess::get_file_as_string(people_dir + String("rb_meta.json")));
	const Dictionary donors = mv.get_type() == Variant::DICTIONARY ? (Dictionary)((Dictionary)mv).get("donors", Dictionary()) : Dictionary();
	bodies.clear();
	for (int k = 0; k < 2; k++) pool_casual[k].clear();
	for (int k = 0; k < 8; k++) pool_tag[k].clear();
	PackedFloat32Array lms; lms.resize(48); lms.fill(0.45f);
	for (int k = 0; k < n; k++) {
		Body b;
		b.id = f->get_pascal_string(); b.layer = (int)f->get_32(); b.female = (int)f->get_32(); b.corners = (int)f->get_32(); b.height = f->get_float();
		const Dictionary dn = donors.get(b.id, Dictionary());
		b.tag = tag_of(String(dn.get("tag", "")), (bool)dn.get("police", false));
		if (b.layer >= 0 && b.layer < 48) lms[b.layer] = (float)(double)dn.get("lm", 0.45);
		if (b.tag == 0 || b.tag == 1) pool_casual[b.female ? 1 : 0].push_back(k);
		pool_tag[b.tag].push_back(k);
		bodies.push_back(b);
	}
	const PackedByteArray px = f->get_buffer((int64_t)tex_w * tex_h * 8);
	if (px.size() != (int64_t)tex_w * tex_h * 8) { UtilityFunctions::push_error("CityCrowd: far_poses.bin is cut short"); return; }
	{   // where a lying figure lies in its own frame (for the towel under it): body 0, the pose "lying on the back"
		auto unhalf = [](uint16_t h) { const int e = (h >> 10) & 31, m = h & 1023; float f = e == 0 ? std::ldexp((float)m, -24) : std::ldexp((float)(m + 1024), e - 25); return (h & 0x8000) ? -f : f; };
		const uint16_t *hp = (const uint16_t *)px.ptr();
		float lo[2] = { 1e9f, 1e9f }, hi[2] = { -1e9f, -1e9f };
		const int row0 = 2 * 10 * corner_h;
		for (int c = 0; c < bodies[0].corners && c < corner_h * tex_w; c++) {
			const uint16_t *q = hp + ((size_t)row0 * tex_w + c) * 4;
			const float vx = unhalf(q[0]), vz = unhalf(q[2]);
			lo[0] = std::min(lo[0], vx); hi[0] = std::max(hi[0], vx); lo[1] = std::min(lo[1], vz); hi[1] = std::max(hi[1], vz);
		}
		lie_c = Vector3(0.5f * (lo[0] + hi[0]), 0, 0.5f * (lo[1] + hi[1]));
		lie_yaw = (hi[0] - lo[0]) > (hi[1] - lo[1]) ? 1.5707963f : 0.0f;
	}
	Ref<Image> img = Image::create_from_data(tex_w, tex_h, false, Image::FORMAT_RGBAH, px);
	pose_tex = ImageTexture::create_from_image(img);

	// the material: the old game's own, fed as it fed it
	ResourceLoader *rl = ResourceLoader::get_singleton();
	Ref<Shader> sh = rl->load(people_dir + String("rb_person.gdshader"));
	Ref<Resource> alb = rl->load(people_dir + String("tex/rb_npc_albedo.png")), msk = rl->load(people_dir + String("tex/rb_npc_mask.png"));
	if (sh.is_null() || alb.is_null() || msk.is_null()) { UtilityFunctions::push_error("CityCrowd: the people's shader or textures are missing"); return; }
	if (!Object::cast_to<TextureLayered>(alb.ptr())) UtilityFunctions::push_error("CityCrowd: rb_npc_albedo.png is not a texture array (its .import file is missing or wrong): people will be one flat colour");
	PackedFloat32Array packs, dye, tl, bl, face, skb, skh, hlm;
	for (PackedFloat32Array *a : { &packs, &dye, &tl, &bl, &face, &skb, &skh, &hlm }) { a->resize(48); a->fill(0.0f); }
	const Variant ov = JSON::parse_string(FileAccess::get_file_as_string(people_dir + String("tex/rb_npc_outfits.json")));
	if (ov.get_type() == Variant::DICTIONARY) {
		const Dictionary layers = ((Dictionary)ov).get("layers", Dictionary());
		const Array keys = layers.keys();
		for (int k = 0; k < keys.size(); k++) {
			const Dictionary L = layers[keys[k]];
			const int li = std::min(std::max((int)(double)L.get("layer", 0.0), 0), 47);
			packs[li] = (bool)L.get("packed", false) ? 1.0f : 0.0f;
			int tag = 0;
			for (const Body &b : bodies) if (b.id == String(keys[k])) tag = b.tag;
			dye[li] = tag == 2 ? 0.0f : (tag == 1 ? 2.0f : 1.0f);
			tl[li] = (float)(double)L.get("top_lum", 0.5); bl[li] = (float)(double)L.get("bottom_lum", 0.5); face[li] = (float)(double)L.get("face", 0.0);
			skb[li] = (float)(double)L.get("skin_body", 0.0); skh[li] = (float)(double)L.get("skin_head", 0.0); hlm[li] = (float)(double)L.get("hair_lm", 0.0);
		}
	}
	auto feed = [&](Ref<ShaderMaterial> &m, bool far) {
		m.instantiate(); m->set_shader(sh);
		m->set_shader_parameter("use_instance", far);
		m->set_shader_parameter("fade_band", Vector2((float)near_r, (float)(near_r + near_fade)));
		m->set_shader_parameter("hairs", table(HAIR, 8, true)); m->set_shader_parameter("eyes", table(EYES, 4, true)); m->set_shader_parameter("skins", table(SKINS, 4, true));
		m->set_shader_parameter("lms", lms);
		m->set_shader_parameter("packs", packs); m->set_shader_parameter("dye", dye); m->set_shader_parameter("top_lum", tl); m->set_shader_parameter("bot_lum", bl);
		m->set_shader_parameter("face", face); m->set_shader_parameter("skin_body", skb); m->set_shader_parameter("skin_head", skh); m->set_shader_parameter("hair_lm", hlm);
		m->set_shader_parameter("lips", table(LIPS, 4, false)); m->set_shader_parameter("tops", table(TOPS, 44, false)); m->set_shader_parameter("bottoms", table(BOTTOMS, 30, false));
		m->set_shader_parameter("suits", table(SUITS, 8, false));
		m->set_shader_parameter("albedo_arr", alb); m->set_shader_parameter("mask_arr", msk);
	};
	feed(mat_far, true);
	mat_far->set_shader_parameter("use_pose_tex", true); mat_far->set_shader_parameter("far_merged", true);
	mat_far->set_shader_parameter("pose_tex", pose_tex); mat_far->set_shader_parameter("pose_k", POSE_K); mat_far->set_shader_parameter("pose_n", (int)POSES);
	mat_far->set_shader_parameter("block_rows", block_rows); mat_far->set_shader_parameter("corner_h", corner_h);
	feed(mat_near, false);

	// the one mesh of the far crowd: as many corners as the largest body has; where each lies comes from the table
	{
		PackedVector3Array v, nn; PackedVector2Array uv;
		v.resize(corners_max); nn.resize(corners_max); uv.resize(corners_max);
		for (int k = 0; k < corners_max; k++) { v[k] = Vector3(); nn[k] = Vector3(0, 1, 0); uv[k] = Vector2(); }
		Array arr; arr.resize(Mesh::ARRAY_MAX);
		arr[Mesh::ARRAY_VERTEX] = v; arr[Mesh::ARRAY_NORMAL] = nn; arr[Mesh::ARRAY_TEX_UV] = uv;
		Ref<ArrayMesh> am; am.instantiate();
		am->add_surface_from_arrays(Mesh::PRIMITIVE_TRIANGLES, arr);
		am->set_custom_aabb(AABB(Vector3(-1.2f, -0.2f, -1.2f), Vector3(2.4f, 2.4f, 2.4f)));
		far_mesh = am;
	}
	RenderingServer *rs = RenderingServer::get_singleton();
	mm = rs->multimesh_create();
	rs->multimesh_allocate_data(mm, pc::MAX_PEDS, RenderingServer::MULTIMESH_TRANSFORM_3D, false, true);
	rs->multimesh_set_mesh(mm, far_mesh->get_rid());
	rs->multimesh_set_visible_instances(mm, 0);
	inst = rs->instance_create2(mm, get_world_3d()->get_scenario());
	rs->instance_set_custom_aabb(inst, AABB(Vector3(-4000, -200, -4000), Vector3(8000, 600, 8000)));
	rs->instance_geometry_set_material_override(inst, mat_far->get_rid());
	rs->instance_geometry_set_cast_shadows_setting(inst, RenderingServer::SHADOW_CASTING_SETTING_OFF);
	rs->instance_set_visible(inst, false);
	buf.resize((int64_t)pc::MAX_PEDS * ROW);
	buf.fill(0.0f);
	shown = 0;
	gfx = true;
}

void CityCrowd::_ready() {
	if (!ready) load();
	if (!ready) { set_process(false); return; }
	if (cells.empty()) cells.assign((size_t)GRID * GRID, 0);
	if (draw_on) make_look();
	if (gfx) { make_near(); make_extras(); }
	crowd->reset(20261120ull);
	set_process(true);
}

void CityCrowd::_exit_tree() {
	RenderingServer *rs = RenderingServer::get_singleton();
	if (inst.is_valid()) rs->free_rid(inst);
	if (mm.is_valid()) rs->free_rid(mm);
	inst = RID(); mm = RID(); gfx = false;
	near_pool.clear();
	free_extras();
}

// ---------------------------------------------------------------- who else there is
void CityCrowd::set_traffic(Object *p_traffic) { traffic_id = p_traffic ? (uint64_t)p_traffic->get_instance_id() : 0; }
void CityCrowd::set_player(Object *p_player) {
	player_id = p_player ? (uint64_t)p_player->get_instance_id() : 0; has_last_player = false;
	// the test app's stand-in player gets a body and clothes like the people's (his own, never dissolving)
	CityPlayer *cp = Object::cast_to<CityPlayer>(p_player);
	if (cp && cp->figure() && gfx && !bodies.empty()) {
		int body = 0;
		for (int k = 0; k < (int)bodies.size(); k++) if (bodies[k].id == cp->get_body_id()) body = k;
		Ref<ShaderMaterial> m = mat_near->duplicate();
		m->set_shader_parameter("person", Vector4(7.0f, 0.0f, 3.0f + 8.0f, 0.2f));
		m->set_shader_parameter("fade_band", Vector2(1.0e5f, 1.0e5f + 1.0f));
		cp->figure()->become(bodies[body].id, bodies[body].near_mesh, m, false);
	}
}

void CityCrowd::cell_set(const String &p_key, bool p_in) {
	const PackedStringArray p = p_key.split("_");
	if (p.size() != 2) return;
	const int cx = (int)p[0].to_int() + GRID / 2, cz = (int)p[1].to_int() + GRID / 2;
	if (cx < 0 || cz < 0 || cx >= GRID || cz >= GRID) return;
	if (cells.empty()) cells.assign((size_t)GRID * GRID, 0);
	cells[(size_t)cz * GRID + cx] = p_in ? 1 : 0;
	cells_dirty = true;
}
void CityCrowd::_on_cell_in(const String &p_key) { cell_set(p_key, true); }
void CityCrowd::_on_cell_out(const String &p_key) { cell_set(p_key, false); }

void CityCrowd::attach(Object *p_streamer) {
	if (!p_streamer) return;
	streamer_id = (uint64_t)p_streamer->get_instance_id();
	cells_all = false;
	cells.assign((size_t)GRID * GRID, 0);
	p_streamer->connect("cell_in", Callable(this, "_on_cell_in"));
	p_streamer->connect("cell_out", Callable(this, "_on_cell_out"));
	if (p_streamer->has_method("loaded_keys")) {   // (the cells that are in already)
		const Array keys = p_streamer->call("loaded_keys");
		for (int k = 0; k < keys.size(); k++) cell_set(String(keys[k]), true);
	}
	cells_dirty = true;
}

// ---------------------------------------------------------------- the step
void CityCrowd::step_brain(double p_delta) {
	hour += clock_rate * p_delta;
	while (hour >= 24.0) { hour -= 24.0; weekday = (weekday + 1) % 7; }
	crowd->cfg.max_peds = max_people; crowd->cfg.density = (float)density;
	crowd->set_time((float)hour, weekday, 6.5f, 19.0f);
	crowd->set_rain((float)rain);
	if (cells_dirty) { crowd->set_cells(cells_all ? std::vector<uint8_t>() : cells); cells_dirty = false; }
	Viewport *vp = get_viewport();
	Camera3D *cam = vp ? vp->get_camera_3d() : nullptr;
	if (cam) {
		const Transform3D ct = cam->get_global_transform();
		Vector3 fw = -ct.basis.get_column(2); fw.y = 0.0f;
		const float fl = fw.length();
		crowd->set_view(ct.origin.x, ct.origin.z, fl > 0.05f ? fw.x / fl : 0.0f, fl > 0.05f ? fw.z / fl : 0.0f);
	}
	Node3D *pl = player_id ? Object::cast_to<Node3D>(ObjectDB::get_instance(ObjectID(player_id))) : nullptr;
	if (pl && pl->is_inside_tree()) {
		const Vector3 p = pl->get_global_position();
		Vector3 v;
		if (has_last_player && p_delta > 1.0e-4) v = (p - last_player) / (float)p_delta;
		if (v.length_squared() > 400.0f) v = Vector3();
		last_player = p; has_last_player = true;
		crowd->set_player(true, p.x, p.z, v.x, v.z);
	} else { crowd->set_player(false, 0, 0, 0, 0); player_id = 0; }
	CityTraffic *tr = traffic_id ? Object::cast_to<CityTraffic>(ObjectDB::get_instance(ObjectID(traffic_id))) : nullptr;
	double clock = own_clock;
	if (tr && tr->is_inside_tree()) {
		tr->cars_for_people(cars);
		crowd->set_cars((int)cars.size() / 7, cars.data());
		if (tr->has_clock()) clock = tr->signal_clock();
	} else crowd->set_cars(0, nullptr);
	acc += p_delta;
	int steps = 0;
	while (acc >= STEP_S && steps < 3) {
		acc -= STEP_S; steps++;
		crowd->step(STEP_S, clock + (double)steps * STEP_S);
		cnt.steps++; cnt.step_us += crowd->st.step_us; cnt.step_us_worst = std::max(cnt.step_us_worst, crowd->st.step_us);
	}
	if (acc > STEP_S * 3.0) acc = 0.0;   // (the app was held: no catching up)
	own_clock += p_delta;
	if (steps == 0) return;
	// the people the drivers must see: on a road, or waiting at a crossing without signals
	if (tr && tr->is_inside_tree()) {
		dyn.clear();
		const float cx = crowd->cam_x, cz = crowd->cam_z;
		for (int i = 0; i < crowd->hi && dyn.size() < (size_t)120 * tc::DYN_STRIDE; i++) {
			if (!crowd->alive[i] || (crowd->flags[i] & pc::F_HIDDEN)) continue;
			const float dx = crowd->x[i] - cx, dz = crowd->z[i] - cz;
			if (dx * dx + dz * dz > 160.0f * 160.0f) continue;
			const pc::Seg &S = crowd->segs[crowd->seg[i]];
			const bool road = crowd->on_road(i) || crowd->mode[i] == pc::M_DODGE || crowd->mode[i] == pc::M_BODY;
			const bool waits = !road && crowd->mode[i] == pc::M_LINE && S.kind == 1 && S.phase < 0 && crowd->state[i] == pc::ST_WAIT;
			if (!road && !waits) continue;
			const float b[tc::DYN_STRIDE] = { crowd->x[i], crowd->y[i], crowd->z[i], crowd->yaw[i], 0.25f, 0.25f, crowd->hx[i] * crowd->v[i], crowd->hz[i] * crowd->v[i],
				(float)(road ? tc::DYN_PED : tc::DYN_XWALK), (float)(300000 + crowd->id[i]), road ? (float)tc::DF_ON_ROAD : 0.0f };
			dyn.insert(dyn.end(), b, b + tc::DYN_STRIDE);
		}
		if (crowd->has_player) {   // the player on foot: the drivers see him wherever he is
			const float b[tc::DYN_STRIDE] = { crowd->pl_x, last_player.y, crowd->pl_z, 0.0f, 0.3f, 0.3f, crowd->pl_vx, crowd->pl_vz, (float)tc::DYN_PLAYER, -3.0f, (float)tc::DF_ON_ROAD };
			dyn.insert(dyn.end(), b, b + tc::DYN_STRIDE);
		}
		tr->set_walkers(dyn.data(), (int)dyn.size() / tc::DYN_STRIDE);
	}
	for (const pc::Event &e : crowd->events) { emit_signal("crowd_event", (int)e.type, e.id, e.aux, e.f); if (ev_keep.size() < 512) ev_keep.push_back(e); }
	crowd->events.clear();
}

// Who a walker is, for the shader: (top colour + role * 64, bottoms colour + body * 64, hair + 8 * eye, skin tone);
// which body; how tall.
void CityCrowd::person_of(int i, float r[4], int &r_body, float &r_scale) const {
	const uint32_t h = crowd->look[i];
	int role = 0, body = 0;
	const int female = (h >> 3) & 1u;
	const std::vector<int> *pool = &pool_casual[female];
	if (crowd->flags[i] & pc::F_RESIDENT) {
		const int g = crowd->goal[i];
		if (g >= 0 && g < (int)crowd->places.size() && crowd->places[g].kind == pc::PL_NIGHT && !pool_tag[7].empty()) { pool = &pool_tag[7]; role = 5; }
		else role = 2;   // a beggar: his own clothes, dirty
	} else if (crowd->pkind[i] == pc::PK_SAILORS && !pool_tag[6].empty()) { pool = &pool_tag[6]; role = 4; }
	if (pool->empty()) pool = &pool_casual[0];
	if (!pool->empty()) body = (*pool)[(h >> 4) % (uint32_t)pool->size()];
	r_body = body;
	const bool grey = (h >> 27) % 12u == 0u;
	r[0] = (float)((h >> 8) % 24u) + (float)(role * 64);
	r[1] = (float)((h >> 13) % 16u) + (float)(body * 64);
	r[2] = (float)((h >> 17) % 8u) + 8.0f * (float)((h >> 20) % 4u);
	r[3] = (float)((h >> 22) % 997u) / 1000.0f + (grey ? 2.0f : 0.0f);
	const bool child = crowd->pkind[i] == pc::PK_FAMILY && crowd->slot[i] >= 2;
	r_scale = child ? 0.62f + (float)((h >> 5) % 100u) * 0.0012f : 0.95f + (float)((h >> 5) % 100u) * 0.001f;
}

// Which of the 12 poses a walker is in.
int CityCrowd::pose_of(int i) const {
	const int a = crowd->act[i];
	if (crowd->mode[i] == pc::M_STAY || crowd->state[i] == pc::ST_PAUSE) {
		if (a == pc::A_LIE_BACK) return 10;
		if (a == pc::A_LIE_FRONT) return 11;
		if (crowd->mode[i] == pc::M_STAY && (a == pc::A_SIT || a == pc::A_DRINK || a == pc::A_BEG)) return 9;
		return 8;
	}
	if (crowd->v[i] < 0.15f) return 8;
	const float st = stride[(crowd->look[i] >> 3) & 1u];
	return (int)std::floor(std::fmod(crowd->odo[i], st) / st * 8.0f) & 7;
}

// ---------------------------------------------------------------- every frame
void CityCrowd::draw(double p_alpha) {
	if (!gfx) return;
	float *w = buf.ptrw();
	int n = 0;
	const float alpha = (float)p_alpha;
	for (int i = 0; i < crowd->hi && n < pc::MAX_PEDS; i++) {
		if (!crowd->alive[i] || (crowd->flags[i] & pc::F_HIDDEN)) continue;
		const float a = std::min(std::max(((float)(crowd->tick - crowd->tu[i]) + alpha) / (float)std::max((int)crowd->span[i], 1), 0.0f), 1.0f);
		const float x = crowd->px[i] + (crowd->x[i] - crowd->px[i]) * a, y = crowd->py[i] + (crowd->y[i] - crowd->py[i]) * a, z = crowd->pz[i] + (crowd->z[i] - crowd->pz[i]) * a;
		const float yaw = lerp_angle(crowd->pyaw[i], crowd->yaw[i], a);
		float pr[4]; int body; float sc;
		person_of(i, pr, body, sc);
		const float cy = std::cos(yaw) * sc, sy = std::sin(yaw) * sc;
		float *r = w + (size_t)n * ROW;
		r[0] = cy; r[1] = 0.0f; r[2] = sy; r[3] = x;
		r[4] = 0.0f; r[5] = sc; r[6] = 0.0f; r[7] = y;
		r[8] = -sy; r[9] = 0.0f; r[10] = cy; r[11] = z;
		r[12] = pr[0]; r[13] = pr[1]; r[14] = pr[2] + POSE_K * (float)pose_of(i);
		bool has_body = false;
		for (const Near &nb : near_pool) if (nb.walker == crowd->id[i]) has_body = true;
		r[15] = has_body ? pr[3] : -(pr[3] + 1.0f);   // (below 0: drawn whole at any distance; else it dissolves where the near body takes over)
		n++;
	}
	RenderingServer *rs = RenderingServer::get_singleton();
	if (n > 0) rs->multimesh_set_buffer(mm, buf);
	if (n != shown) { rs->multimesh_set_visible_instances(mm, n); rs->instance_set_visible(inst, n > 0); shown = n; }
	cnt.people += n; cnt.most = std::max(cnt.most, n);
}

// The near bodies: a pool of animated figures made once (three men to two women), every body's near mesh held.
void CityCrowd::make_near() {
	ResourceLoader *rl = ResourceLoader::get_singleton();
	for (Body &b : bodies) b.near_mesh = rl->load(people_dir + String("bodies/") + b.id + String(".res"));
	String first[2];
	for (const Body &b : bodies) if (first[b.female ? 1 : 0].is_empty()) first[b.female ? 1 : 0] = b.id;
	const int n = std::min(std::max(near_max, 0), (int)NEAR_MAX);
	for (int k = 0; k < n; k++) {
		Near nb;
		nb.female = (k % 5) >= 3 ? 1 : 0;
		if (first[nb.female].is_empty()) continue;
		nb.ped = memnew(CityPed);
		nb.ped->set_body_id(first[nb.female]);
		nb.ped->set_clip("ual/Idle_Loop");
		add_child(nb.ped);
		nb.ped->set_visible(false);
		nb.look = mat_near->duplicate();
		near_pool.push_back(nb);
	}
}

// What a near body shows for what its walker does: the clip, how fast it runs, or the moment it is held at.
void CityCrowd::clip_of(int i, StringName &r_clip, double &r_speed, double &r_hold) const {
	static const StringName WALK("ual/Walk_Loop"), WALK2("ual/Walk_Formal_Loop"), JOG("ual/Jog_Fwd_Loop"), SPRINT("ual/Sprint_Loop"), IDLE("ual/Idle_Loop"), ARMS("ual/Idle_FoldArms_Loop"),
			SIT("ual/Sitting_Idle_Loop"), SIT_TALK("ual/Sitting_Talking_Loop"), LIE("ual/LayToIdle"), PHONE("ual/Idle_TalkingPhone_Loop"), FILM("ual/Idle_Lantern_Loop"), DUCK("ual/Crouch_Idle_Loop"),
			TALK("ual/Idle_Talking_Loop"), NO("ual/Idle_No_Loop"), PUNCH("ual/Punch_Jab"), PUNCH2("ual/Punch_Cross"), GIVE("ual/Interact"), WAVE("wave"), HUG("hug");
	const int g = (crowd->look[i] >> 3) & 1u, a = crowd->act[i];
	const float v = crowd->v[i];
	r_speed = 1.0; r_hold = -1.0;
	const bool stays = crowd->mode[i] == pc::M_STAY || crowd->mode[i] == pc::M_HELD || crowd->state[i] == pc::ST_PAUSE;
	if (!stays && v > 0.15f) {   // on its way: the walk at the walker's own pace, a jog, a run
		if (v > 2.8f) { r_clip = SPRINT; r_speed = v / (gait[g][4] / gait[g][5]); }
		else if (v > 1.9f) { r_clip = JOG; r_speed = v / (gait[g][2] / gait[g][3]); }
		else { r_clip = ((crowd->look[i] >> 6) & 3u) == 0u ? WALK2 : WALK; r_speed = v / (gait[g][0] / gait[g][1]); }
		r_speed = std::min(std::max(r_speed, 0.4), 2.2);
		if (a == pc::A_WAVE) { r_clip = WAVE; r_speed = 1.0; }
		return;
	}
	switch (a) {
		case pc::A_SIT: case pc::A_BEG: r_clip = SIT; break;
		case pc::A_DRINK: r_clip = SIT_TALK; break;
		case pc::A_LIE_BACK: case pc::A_LIE_FRONT: r_clip = LIE; r_hold = 0.0; break;
		case pc::A_PHONE: case pc::A_CALL: r_clip = PHONE; break;
		case pc::A_FILM: r_clip = FILM; break;
		case pc::A_WINDOW: case pc::A_STARE: case pc::A_SHELTER: r_clip = ARMS; break;
		case pc::A_DUCK: r_clip = DUCK; break;
		case pc::A_CHAT: case pc::A_TALK: r_clip = TALK; break;
		case pc::A_ARGUE: r_clip = NO; break;
		case pc::A_HUG: r_clip = HUG; break;
		case pc::A_FIGHT: r_clip = (crowd->id[i] & 1) ? PUNCH : PUNCH2; break;
		case pc::A_GIVE: case pc::A_DOOR: r_clip = GIVE; break;
		case pc::A_WAVE: r_clip = WAVE; break;
		case pc::A_WAIT: r_clip = ((crowd->look[i] >> 9) & 1u) ? ARMS : IDLE; break;
		default: r_clip = IDLE; break;
	}
}

// Who has a near body this frame, what it shows, and the hand-over to its physical body and back.
void CityCrowd::near_update(double p_delta, double p_alpha) {
	if (near_pool.empty()) return;
	Viewport *vp = get_viewport();
	Camera3D *cam = vp ? vp->get_camera_3d() : nullptr;
	if (!cam) return;
	const Vector3 cp = cam->get_global_transform().origin;
	const float keep2 = (float)((near_r + near_fade + 4.0) * (near_r + near_fade + 4.0)), take2 = (float)((near_r + near_fade) * (near_r + near_fade));
	// who keeps his body, who gives it back
	for (Near &nb : near_pool) {
		nb.push_cd = std::max(0.0f, nb.push_cd - (float)p_delta);
		if (nb.walker < 0) continue;
		const int i = crowd->find(nb.walker);
		const bool busy = nb.ped->get_mode() != CityPed::MODE_ANIM;   // (staggering, down or getting up: it stays this person's)
		bool drop = i < 0;
		if (!drop && !busy) {
			const float dx = crowd->x[i] - cp.x, dz = crowd->z[i] - cp.z;
			drop = dx * dx + dz * dz > keep2 || (crowd->flags[i] & pc::F_HIDDEN);
		}
		if (drop) { if (i >= 0 && nb.in_body) crowd->to_body(nb.walker, false, crowd->x[i], crowd->z[i]); nb.walker = -1; nb.in_body = false; nb.ped->set_visible(false); }
	}
	// the nearest people without one take the free ones (of their own kind)
	for (Near &nb : near_pool) {
		if (nb.walker >= 0) continue;
		int best = -1; float bd = take2;
		for (int i = 0; i < crowd->hi; i++) {
			if (!crowd->alive[i] || (crowd->flags[i] & pc::F_HIDDEN) || (int)((crowd->look[i] >> 3) & 1u) != nb.female || crowd->mode[i] == pc::M_BODY) continue;
			const float dx = crowd->x[i] - cp.x, dz = crowd->z[i] - cp.z, d2 = dx * dx + dz * dz;
			if (d2 >= bd) continue;
			bool has = false;
			for (const Near &o : near_pool) if (o.walker == crowd->id[i]) has = true;
			if (!has) { bd = d2; best = i; }
		}
		if (best < 0) continue;
		float pr[4]; int body; float sc;
		person_of(best, pr, body, sc);
		// (the near figure must be of the walker's kind: a walker whose body is of the other kind keeps its far figure)
		if (bodies[body].female != nb.female) continue;
		nb.walker = crowd->id[best]; nb.in_body = false;
		nb.look->set_shader_parameter("person", Vector4(pr[0], pr[1] - (float)(body * 64), pr[2], pr[3]));
		nb.ped->become(bodies[body].id, bodies[body].near_mesh, nb.look, sc > 0.9f);
		nb.ped->set_visible(true);
	}
	// what each one shows; a car near it; the player walking into it; its physical body
	Node3D *pl = player_id ? Object::cast_to<Node3D>(ObjectDB::get_instance(ObjectID(player_id))) : nullptr;
	int n_near = 0;
	for (Near &nb : near_pool) {
		if (nb.walker < 0) continue;
		const int i = crowd->find(nb.walker);
		if (i < 0) continue;
		n_near++;
		float pr[4]; int body; float sc;
		person_of(i, pr, body, sc);
		if (nb.ped->get_mode() == CityPed::MODE_ANIM) {
			if (nb.in_body) { const Vector3 at = nb.ped->get_global_transform().origin; crowd->to_body(nb.walker, false, at.x, at.z); nb.in_body = false; }   // it is up again: its walker goes on from where it stands
			if (crowd->mode[i] != pc::M_BODY) {
				const float a = std::min(std::max(((float)(crowd->tick - crowd->tu[i]) + (float)p_alpha) / (float)std::max((int)crowd->span[i], 1), 0.0f), 1.0f);
				const Vector3 at(crowd->px[i] + (crowd->x[i] - crowd->px[i]) * a, crowd->py[i] + (crowd->y[i] - crowd->py[i]) * a, crowd->pz[i] + (crowd->z[i] - crowd->pz[i]) * a);
				StringName clip; double speed, hold;
				clip_of(i, clip, speed, hold);
				nb.ped->drive(Transform3D(Basis(Vector3(0, 1, 0), lerp_angle(crowd->pyaw[i], crowd->yaw[i], a)).scaled(Vector3(sc, sc, sc)), at), clip, speed, hold);
			}
			// the cars near it: its body knows them as boxes, and takes over by itself when one reaches it
			int nbx = 0;
			const int nc = (int)cars.size() / 7;
			for (int c = 0; c < nc && nbx < pb::MAX_BOXES; c++) {
				const float *q = &cars[(size_t)c * 7];
				const float dx = q[0] - crowd->x[i], dz = q[1] - crowd->z[i];
				if (dx * dx + dz * dz > 9.0f * 9.0f) continue;
				nbx++;
			}
			int k = 0;
			for (int c = 0; c < nc && k < nbx; c++) {
				const float *q = &cars[(size_t)c * 7];
				const float dx = q[0] - crowd->x[i], dz = q[1] - crowd->z[i];
				if (dx * dx + dz * dz > 9.0f * 9.0f) continue;
				nb.ped->set_box(k++, Vector3(q[0], crowd->y[i] + 0.75f, q[1]), Vector3(q[4], 0.75f, q[3]), q[2], Vector3(q[5], 0, q[6]), nbx);
			}
			if (nbx == 0) nb.ped->set_box(-1, Vector3(), Vector3(), 0.0, Vector3(), 0);
			// the player walks into it: a shove as hard as he comes
			if (pl && nb.push_cd <= 0.0f && sc > 0.9f) {
				const Vector3 pp = pl->get_global_position();
				const float dx = crowd->x[i] - pp.x, dz = crowd->z[i] - pp.z, d2 = dx * dx + dz * dz;
				const float vx = crowd->pl_vx, vz = crowd->pl_vz, sp = std::sqrt(vx * vx + vz * vz);
				if (d2 < 0.62f * 0.62f && sp > 1.2f && dx * vx + dz * vz > 0.0f) {
					nb.ped->push(Vector3(vx, 0, vz) * (35.0f + 18.0f * sp) / sp, Vector3(crowd->x[i], crowd->y[i] + 1.25f, crowd->z[i]));
					nb.push_cd = 1.5f;
				}
			}
		}
		if (nb.ped->get_mode() != CityPed::MODE_ANIM) {   // its body has it: the walker is where the body is
			const Vector3 at = nb.ped->body_at();
			crowd->to_body(nb.walker, true, at.x, at.z);
			nb.in_body = true;
		}
	}
	cnt.near += n_near;
}

void CityCrowd::_process(double p_delta) {
	if (!ready) return;
	const int64_t t0 = usec_now();
	step_brain(p_delta);
	near_update(p_delta, acc / STEP_S);
	draw(acc / STEP_S);
	extras_update(acc / STEP_S);
	crowd->events.clear();
	const double us = (double)(usec_now() - t0);
	cnt.frames++; cnt.main_us += us; cnt.main_us_worst = std::max(cnt.main_us_worst, us);
}

// ---------------------------------------------------------------- the hooks
int CityCrowd::place_walker(const Vector3 &p_at, int p_look) { return crowd->place_walker(p_at.x, p_at.z, (uint32_t)p_look); }
bool CityCrowd::remove_walker(int p_id) { return crowd->remove_walker(p_id); }
bool CityCrowd::set_goal(int p_id, int p_place, double p_stay_s, bool p_enter) { return crowd->set_goal(p_id, p_place, (float)p_stay_s, p_enter); }
bool CityCrowd::set_goal_point(int p_id, const Vector3 &p_at, double p_stay_s) { return crowd->set_goal_point(p_id, p_at.x, p_at.z, (float)p_stay_s); }
bool CityCrowd::stay(int p_id, double p_seconds) { return crowd->stay(p_id, (float)p_seconds); }
bool CityCrowd::set_act(int p_id, int p_act, double p_seconds) { return crowd->set_act(p_id, p_act, (float)p_seconds); }
bool CityCrowd::hold(int p_id, bool p_on, double p_yaw) { return crowd->hold(p_id, p_on, (float)p_yaw); }
bool CityCrowd::hide(int p_id, bool p_on) { return crowd->hide(p_id, p_on); }
void CityCrowd::scare(const Vector3 &p_at, double p_radius, double p_seconds) { crowd->scare(p_at.x, p_at.z, (float)p_radius, (float)p_seconds); }
void CityCrowd::bus_at(int p_place, bool p_on, const Vector3 &p_door, int p_get_off) { crowd->bus_at(p_place, p_on, p_door.x, p_door.z, p_get_off); }
void CityCrowd::bench_off(int p_place, bool p_off) { crowd->bench_off(p_place, p_off); }

int CityCrowd::place_near(const Vector3 &p_at, int p_kind, double p_radius) const {
	int best = -1; float bd = (float)(p_radius * p_radius);
	for (int p = 0; p < (int)crowd->places.size(); p++) {
		const pc::Place &P = crowd->places[p];
		if (P.kind != p_kind) continue;
		const float dx = P.x - p_at.x, dz = P.z - p_at.z, d2 = dx * dx + dz * dz;
		if (d2 < bd) { bd = d2; best = p; }
	}
	return best;
}

Dictionary CityCrowd::place_info(int p_place) const {
	Dictionary d;
	if (p_place < 0 || p_place >= (int)crowd->places.size()) return d;
	const pc::Place &P = crowd->places[p_place];
	d["kind"] = (int)P.kind; d["at"] = Vector3(P.x, P.y, P.z); d["yaw"] = P.yaw; d["pavement"] = Vector3(P.ax, P.y, P.az); d["sub"] = (int)P.sub; d["pose"] = (int)P.pose;
	d["taken_by"] = crowd->occ[p_place]; d["inside"] = (int)crowd->inside[p_place]; d["open"] = crowd->shop_open(p_place);
	return d;
}

Array CityCrowd::people_near(const Vector3 &p_at, double p_radius) const {
	Array out;
	for (int i = 0; i < crowd->hi; i++) {
		if (!crowd->alive[i]) continue;
		const float dx = crowd->x[i] - p_at.x, dz = crowd->z[i] - p_at.z;
		if (dx * dx + dz * dz > (float)(p_radius * p_radius)) continue;
		Dictionary d;
		d["id"] = crowd->id[i]; d["at"] = Vector3(crowd->x[i], crowd->y[i], crowd->z[i]); d["yaw"] = crowd->yaw[i]; d["speed"] = crowd->v[i];
		d["mode"] = (int)crowd->mode[i]; d["act"] = (int)crowd->act[i]; d["state"] = (int)crowd->state[i]; d["party"] = crowd->party[i]; d["goal"] = crowd->goal[i];
		out.push_back(d);
	}
	return out;
}

Array CityCrowd::take_events() {
	Array out;
	for (const pc::Event &e : ev_keep) { Array a; a.push_back((int)e.type); a.push_back(e.id); a.push_back(e.aux); a.push_back(e.f); out.push_back(a); }
	ev_keep.clear();
	return out;
}

Dictionary CityCrowd::stats() const {
	Dictionary d;
	const pc::Stats &s = crowd->st;
	int r[7];
	crowd->audit(own_clock, r);
	d["people"] = crowd->n_alive; d["places"] = (int)crowd->places.size(); d["hour"] = hour; d["weekday"] = weekday;
	d["inside_each_other"] = r[0]; d["beside_pavement"] = r[1]; d["standing_a_minute"] = r[3]; d["bad_numbers"] = r[4];
	d["spawned"] = s.spawned; d["left"] = s.despawned; d["arrivals"] = s.arrivals; d["went_in"] = s.went_in; d["came_out"] = s.came_out; d["sat"] = s.sat; d["crossings"] = s.crossings;
	d["groups"] = s.parties; d["meetings"] = s.meetings; d["dodges"] = s.dodges; d["fled"] = s.fled; d["bumps"] = s.bumps;
	d["bodies"] = (int)bodies.size(); d["drawn"] = shown;
	int nn = 0, nbdy = 0;
	for (const Near &nb : near_pool) { if (nb.walker >= 0) nn++; if (nb.in_body) nbdy++; }
	d["near_bodies"] = nn; d["near_pool"] = (int)near_pool.size(); d["in_physical_body"] = nbdy; d["umbrellas"] = prop_shown[0]; d["towels"] = prop_shown[1];
	d["ducked"] = s.ducks; d["stared"] = s.stared; d["coins"] = s.coins; d["lines_said"] = s.lines_said;
	return d;
}

String CityCrowd::report() {
	const double f = std::max(cnt.frames, 1);
	String s = vformat("people avg %.1f most %d (cap %d, %d places known), hour %.1f | main thread a frame: avg %.3f worst %.3f ms (of it the crowd's step: avg %.3f worst %.3f ms a step, %d steps) | drawn as one batch of far figures; near bodies avg %.1f",
			cnt.people / f, cnt.most, max_people, (int)crowd->places.size(), hour, cnt.main_us / f / 1000.0, cnt.main_us_worst / 1000.0, cnt.step_us / std::max(cnt.steps, 1) / 1000.0, cnt.step_us_worst / 1000.0, cnt.steps, cnt.near / f);
	cnt = Count();
	return s;
}

void CityCrowd::_bind_methods() {
	ClassDB::bind_method(D_METHOD("set_traffic", "traffic"), &CityCrowd::set_traffic);
	ClassDB::bind_method(D_METHOD("attach", "streamer"), &CityCrowd::attach);
	ClassDB::bind_method(D_METHOD("_on_cell_in", "key"), &CityCrowd::_on_cell_in);
	ClassDB::bind_method(D_METHOD("_on_cell_out", "key"), &CityCrowd::_on_cell_out);
	ClassDB::bind_method(D_METHOD("set_player", "player"), &CityCrowd::set_player);
	ClassDB::bind_method(D_METHOD("set_max_people", "n"), &CityCrowd::set_max_people);
	ClassDB::bind_method(D_METHOD("get_max_people"), &CityCrowd::get_max_people);
	ClassDB::bind_method(D_METHOD("set_density", "scale"), &CityCrowd::set_density);
	ClassDB::bind_method(D_METHOD("get_density"), &CityCrowd::get_density);
	ClassDB::bind_method(D_METHOD("set_hour", "hour"), &CityCrowd::set_hour);
	ClassDB::bind_method(D_METHOD("get_hour"), &CityCrowd::get_hour);
	ClassDB::bind_method(D_METHOD("set_clock_rate", "hours_a_second"), &CityCrowd::set_clock_rate);
	ClassDB::bind_method(D_METHOD("get_clock_rate"), &CityCrowd::get_clock_rate);
	ClassDB::bind_method(D_METHOD("set_weekday", "day"), &CityCrowd::set_weekday);
	ClassDB::bind_method(D_METHOD("get_weekday"), &CityCrowd::get_weekday);
	ClassDB::bind_method(D_METHOD("set_rain", "rain"), &CityCrowd::set_rain);
	ClassDB::bind_method(D_METHOD("get_rain"), &CityCrowd::get_rain);
	ClassDB::bind_method(D_METHOD("set_near_max", "n"), &CityCrowd::set_near_max);
	ClassDB::bind_method(D_METHOD("get_near_max"), &CityCrowd::get_near_max);
	ClassDB::bind_method(D_METHOD("set_streets_path", "path"), &CityCrowd::set_streets_path);
	ClassDB::bind_method(D_METHOD("get_streets_path"), &CityCrowd::get_streets_path);
	ClassDB::bind_method(D_METHOD("set_places_path", "path"), &CityCrowd::set_places_path);
	ClassDB::bind_method(D_METHOD("get_places_path"), &CityCrowd::get_places_path);
	ADD_PROPERTY(PropertyInfo(Variant::INT, "max_people"), "set_max_people", "get_max_people");
	ADD_PROPERTY(PropertyInfo(Variant::FLOAT, "density"), "set_density", "get_density");
	ADD_PROPERTY(PropertyInfo(Variant::FLOAT, "hour"), "set_hour", "get_hour");
	ADD_PROPERTY(PropertyInfo(Variant::FLOAT, "clock_rate"), "set_clock_rate", "get_clock_rate");
	ADD_PROPERTY(PropertyInfo(Variant::INT, "weekday"), "set_weekday", "get_weekday");
	ADD_PROPERTY(PropertyInfo(Variant::FLOAT, "rain"), "set_rain", "get_rain");
	ADD_PROPERTY(PropertyInfo(Variant::INT, "near_max"), "set_near_max", "get_near_max");
	ADD_PROPERTY(PropertyInfo(Variant::STRING, "streets_path"), "set_streets_path", "get_streets_path");
	ADD_PROPERTY(PropertyInfo(Variant::STRING, "places_path"), "set_places_path", "get_places_path");
	ClassDB::bind_method(D_METHOD("place_walker", "at", "look"), &CityCrowd::place_walker);
	ClassDB::bind_method(D_METHOD("remove_walker", "id"), &CityCrowd::remove_walker);
	ClassDB::bind_method(D_METHOD("set_goal", "id", "place", "stay_s", "enter"), &CityCrowd::set_goal);
	ClassDB::bind_method(D_METHOD("set_goal_point", "id", "at", "stay_s"), &CityCrowd::set_goal_point);
	ClassDB::bind_method(D_METHOD("stay", "id", "seconds"), &CityCrowd::stay);
	ClassDB::bind_method(D_METHOD("set_act", "id", "act", "seconds"), &CityCrowd::set_act);
	ClassDB::bind_method(D_METHOD("hold", "id", "on", "yaw"), &CityCrowd::hold);
	ClassDB::bind_method(D_METHOD("hide", "id", "on"), &CityCrowd::hide);
	ClassDB::bind_method(D_METHOD("scare", "at", "radius", "seconds"), &CityCrowd::scare);
	ClassDB::bind_method(D_METHOD("bus_at", "place", "on", "door", "get_off"), &CityCrowd::bus_at);
	ClassDB::bind_method(D_METHOD("bench_off", "place", "off"), &CityCrowd::bench_off);
	ClassDB::bind_method(D_METHOD("place_near", "at", "kind", "radius"), &CityCrowd::place_near);
	ClassDB::bind_method(D_METHOD("place_info", "place"), &CityCrowd::place_info);
	ClassDB::bind_method(D_METHOD("people_near", "at", "radius"), &CityCrowd::people_near);
	ClassDB::bind_method(D_METHOD("take_events"), &CityCrowd::take_events);
	ClassDB::bind_method(D_METHOD("stats"), &CityCrowd::stats);
	ClassDB::bind_method(D_METHOD("report"), &CityCrowd::report);
	ADD_SIGNAL(MethodInfo("crowd_event", PropertyInfo(Variant::INT, "type"), PropertyInfo(Variant::INT, "id"), PropertyInfo(Variant::INT, "aux"), PropertyInfo(Variant::FLOAT, "f")));
}

} // namespace godot
