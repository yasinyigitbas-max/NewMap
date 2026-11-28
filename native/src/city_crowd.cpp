// CityCrowd: see city_crowd.h.
#include "perf_marks.h"
#include "city_crowd.h"

#include "city_ped.h"
#include "hand_grip.h"
#include "city_player.h"
#include "foot_steps.h"
#include "city_ambience.h"
#include "city_traffic.h"
#include "people_bake.h"
#include "ped_inl.h"
#include "traffic_sim.h"

#include <godot_cpp/classes/bone_attachment3d.hpp>
#include <godot_cpp/classes/box_mesh.hpp>
#include <godot_cpp/classes/mesh_instance3d.hpp>
#include <godot_cpp/classes/standard_material3d.hpp>
#include <godot_cpp/classes/array_mesh.hpp>
#include <godot_cpp/classes/camera3d.hpp>
#include <godot_cpp/classes/file_access.hpp>
#include <godot_cpp/classes/image.hpp>
#include <godot_cpp/classes/json.hpp>
#include <godot_cpp/classes/rendering_server.hpp>
#include <godot_cpp/classes/resource_loader.hpp>
#include <godot_cpp/classes/shader.hpp>
#include <godot_cpp/classes/texture2d.hpp>
#include <godot_cpp/classes/texture_layered.hpp>
#include <godot_cpp/classes/time.hpp>
#include <godot_cpp/classes/viewport.hpp>
#include <godot_cpp/classes/world3d.hpp>
#include <godot_cpp/core/class_db.hpp>
#include <godot_cpp/variant/callable.hpp>
#include <godot_cpp/variant/dictionary.hpp>
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
CityCrowd *CityCrowd::the = nullptr;

CityCrowd::~CityCrowd() { if (the == this) the = nullptr; delete crowd; }

float CityCrowd::body_under(const Vector3 &p_at) const {
	float top = -1.0e9f;
	for (const Near &nb : near_pool) if (nb.walker >= 0 && nb.ped) top = std::max(top, nb.ped->top_over(p_at, 0.25f));
	if (player_id) if (CityPlayer *pl = Object::cast_to<CityPlayer>(ObjectDB::get_instance(ObjectID(player_id)))) if (pl->figure()) top = std::max(top, pl->figure()->top_over(p_at, 0.25f));
	return top;
}

int CityCrowd::car_boxes(CityPed *p_ped, int k, const float *q, float p_ground_y) {
	const float hl = q[3], hw = q[4], fx = std::sin(q[2]), fz = std::cos(q[2]);
	const Vector3 v(q[5], 0, q[6]);
	p_ped->set_box(k, Vector3(q[0], p_ground_y + 0.535f, q[1]), Vector3(hw, 0.315f, hl), q[2], v, k + 2);   // (the body: 0.22-0.85 m)
	const float off = -0.175f * hl;   // (the cabin: from 55 % of the way back to 20 % forward, 0.85-1.45 m)
	p_ped->set_box(k + 1, Vector3(q[0] + fx * off, p_ground_y + 1.15f, q[1] + fz * off), Vector3(hw * 0.9f, 0.3f, 0.375f * hl), q[2], v, k + 2);
	return k + 2;
}

// The streets, the places, the bodies' table.
bool CityCrowd::load() {
	ready = false;
	const PackedByteArray sb = FileAccess::get_file_as_bytes(streets_path);
	sg::StreetData d;
	if (sb.size() < 16 || !d.load(sb.ptr(), (size_t)sb.size()) || !crowd->build(d)) { UtilityFunctions::push_error("CityCrowd: no streets (", streets_path, "): run tools/city/traffic/make_streets.gd"); return false; }
	load_sea();
	crowd->cfg.swim = !sea_d.empty();
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
	the = this;
	if (!ready) load();
	if (!ready) { set_process(false); return; }
	if (cells.empty()) cells.assign((size_t)GRID * GRID, 0);
	if (draw_on) make_look();
	if (gfx) { make_near(); make_extras(); }
	crowd->reset(20261120ull);
	for (size_t k = 0; k < crowd->segs.size(); k++) {   // the floor under the pavements and crossings, 2 m strips
		const pc::Seg &S = crowd->segs[k];
		const int m = std::max(1, (int)(S.len / 2.0f));
		int h = 0; float x0, y0, z0, x1, y1, z1, tx, tz;
		crowd->at(S, 0.0f, 0.0f, h, x0, y0, z0, tx, tz);
		for (int q = 1; q <= m; q++) {
			crowd->at(S, S.len * (float)q / (float)m, 0.0f, h, x1, y1, z1, tx, tz);
			way_floor.add(Vector3(x0, y0, z0), Vector3(x1, y1, z1), S.hw + 0.15f);
			x0 = x1; y0 = y1; z0 = z1;
		}
	}
	set_process(true);
}

void CityCrowd::_exit_tree() {
	RenderingServer *rs = RenderingServer::get_singleton();
	if (inst.is_valid()) rs->free_rid(inst);
	if (mm.is_valid()) rs->free_rid(mm);
	inst = RID(); mm = RID(); gfx = false;
	near_pool.clear();
	free_extras();
	way_floor.clear();
}

// ---------------------------------------------------------------- who else there is
void CityCrowd::set_traffic(Object *p_traffic) { traffic_id = p_traffic ? (uint64_t)p_traffic->get_instance_id() : 0; }
void CityCrowd::set_player_car(Object *p_car, double p_half_length, double p_half_width) {
	car_id = p_car ? (uint64_t)p_car->get_instance_id() : 0; has_car_last = false;
	car_hl = (float)p_half_length; car_hw = (float)p_half_width;
}

void CityCrowd::set_player(Object *p_player) {
	player_id = p_player ? (uint64_t)p_player->get_instance_id() : 0; has_last_player = false;
	// the test app's stand-in player gets a body and clothes like the people's (his own, never dissolving)
	CityPlayer *cp = Object::cast_to<CityPlayer>(p_player);
	if (p_player && !has_node("Ambience")) {   // B3: the sound of the place round him
		CityAmbience *am = memnew(CityAmbience); am->set_name("Ambience"); add_child(am); am->set_crowd(this);
	}
	if (cp && cp->figure() && !cp->has_node("FootSteps")) {   // B16: his footsteps, by what he walks on
		FootSteps *fs = memnew(FootSteps); fs->set_name("FootSteps"); cp->add_child(fs); fs->set_figure(cp->figure()); fs->set_own(true);
	}
	if (cp && cp->figure() && gfx && !bodies.empty()) {
		int body = 0;
		for (int k = 0; k < (int)bodies.size(); k++) if (bodies[k].id == cp->get_body_id()) body = k;
		Ref<ShaderMaterial> m = mat_near->duplicate();
		m->set_shader_parameter("person", Vector4(7.0f, 0.0f, 3.0f + 8.0f, 0.2f));
		m->set_shader_parameter("fade_band", Vector2(1.0e5f, 1.0e5f + 1.0f));
		// (with his physical body: it was false, and nothing could knock him over, a car (Yasin, 20 Nov: "i got run over by
		// cars several times", "still passing right thru") nor a beating; the fight's "beaten" froze him standing)
		cp->figure()->become(bodies[body].id, bodies[body].near_mesh, m, true);
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
		// the buses that stand at a stop: the front door, on the kerb's side, opens to the people who wait; a few get off
		tr->set_hour(hour);
		tr->buses_at_stops(bus_buf);
		std::vector<int> here;
		for (size_t k = 0; k + 6 < bus_buf.size(); k += 7) {
			const int pf = (int)bus_buf[k];
			const int place = pf >= 0 && pf < (int)crowd->place_from_file.size() ? crowd->place_from_file[pf] : -1;   // (the traffic names a stop by its number in places.bin)
			if (place < 0) continue;
			here.push_back(place);
			if (std::find(bus_here.begin(), bus_here.end(), place) != bus_here.end()) continue;
			const float bx = bus_buf[k + 1], bz = bus_buf[k + 2], hx = std::sin(bus_buf[k + 3]), hz = std::cos(bus_buf[k + 3]), hl = bus_buf[k + 4], hw = bus_buf[k + 5];
			const uint32_t hsh = ((uint32_t)bus_buf[k + 6] * 2654435761u) ^ ((uint32_t)place * 40503u);
			crowd->bus_at(place, true, bx + hx * (hl - 1.3f) - hz * (hw + 0.45f), bz + hz * (hl - 1.3f) + hx * (hw + 0.45f), (int)((hsh >> 9) % 4u));
			buses_served++;
		}
		for (int place : bus_here) if (std::find(here.begin(), here.end(), place) == here.end()) crowd->bus_at(place, false, 0.0f, 0.0f, 0);
		bus_here = here;
		if (tr->has_clock()) clock = tr->signal_clock();
	} else cars.clear();
	// the car the player drives is a car like the others to them
	Node3D *pcar = car_id ? Object::cast_to<Node3D>(ObjectDB::get_instance(ObjectID(car_id))) : nullptr;
	if (pcar && pcar->is_inside_tree()) {
		const Transform3D ct = pcar->get_global_transform();
		const Vector3 f = ct.basis.get_column(2);
		Vector3 cv;
		if (has_car_last && p_delta > 1.0e-4) cv = (ct.origin - car_last) / (float)p_delta;
		car_last = ct.origin; has_car_last = true;
		const float q[7] = { (float)ct.origin.x, (float)ct.origin.z, (float)std::atan2(f.x, f.z), car_hl, car_hw, (float)cv.x, (float)cv.z };
		cars.insert(cars.end(), q, q + 7);
	} else { car_id = 0; has_car_last = false; }
	crowd->set_cars((int)cars.size() / 7, cars.empty() ? nullptr : cars.data());
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
			// (knocked down, where his body lies: it may be metres from where he was standing)
			float px = crowd->pl_x, pz = crowd->pl_z;
			if (CityPlayer *dp = player_id ? Object::cast_to<CityPlayer>(ObjectDB::get_instance(ObjectID(player_id))) : nullptr)
				if (dp->figure() && dp->figure()->get_mode() != CityPed::MODE_ANIM) { const Vector3 ba = dp->figure()->body_at(); px = ba.x; pz = ba.z; }
			const float b[tc::DYN_STRIDE] = { px, last_player.y, pz, 0.0f, 0.3f, 0.3f, crowd->pl_vx, crowd->pl_vz, (float)tc::DYN_PLAYER, -3.0f, (float)tc::DF_ON_ROAD };
			dyn.insert(dyn.end(), b, b + tc::DYN_STRIDE);
		}
		tr->set_walkers(dyn.data(), (int)dyn.size() / tc::DYN_STRIDE);
	}
	for (const pc::Event &e : crowd->events) if (e.type == pc::E_FIGHT) onlookers(crowd->find(e.id), 5, crowd->cfg.fight_s, true, true);   // a fight: people stop and look, one films it, one calls
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
	if (!uniforms.empty()) {   // (an actor in the clothes of his job: police, medical)
		const int ut = uniform_of(crowd->id[i]);
		if (ut > 0 && ut < 8 && !pool_tag[ut].empty()) { pool = &pool_tag[ut]; role = 0; }
	}
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
		if (crowd->mode[i] == pc::M_STAY && (a == pc::A_SIT || a == pc::A_DRINK)) return 9;
		if (crowd->mode[i] == pc::M_STAY && (a == pc::A_GSIT || a == pc::A_BEG)) return 12;
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
#ifdef TRAV_IN_GAME
		if (trav_people) break;   // (28 Nov, Yasin: the old people "out of the game entirely": no far figure; the near ones are new bodies)
#endif
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
		int pose = pose_of(i);
		const float wd = sea_depth(x, z);   // (in the sea: wading with his feet on the bottom, or lying at the surface: swimming, from afar)
		const float y_sea = wd > 1.15f ? (float)sea_y - 0.30f : (wd > 0.05f ? (float)sea_y - wd : 1.0e9f);
		if (wd > 1.15f) pose = 11;
		if (y_sea < 1.0e8f) r[7] = y_sea;
		r[12] = pr[0]; r[13] = pr[1]; r[14] = pr[2] + POSE_K * (float)pose;
		bool has_body = false;
		for (const Near &nb : near_pool) if (nb.walker == crowd->id[i]) has_body = true;
		r[15] = has_body ? pr[3] : -(pr[3] + 1.0f);   // (below 0: drawn whole at any distance; else it dissolves where the near body takes over)
		n++;
	}
	// THE TRAFFIC'S CYCLISTS: each rider is a far figure in one of the four riding poses (PeopleBake 13-16, by how far
	// the crank has turned), on the traffic's bicycle, leaning with it. Who he is comes from the bicycle's id.
	CityTraffic *trf = traffic_id ? Object::cast_to<CityTraffic>(ObjectDB::get_instance(ObjectID(traffic_id))) : nullptr;
	riders_drawn = 0;
#ifdef TRAV_IN_GAME
	if (trav_people) trf = nullptr;   // (their riders are old figures: with the new people the game has no traffic cyclists, rig.gd)
#endif
	if (trf && trf->is_inside_tree()) {
		const std::vector<float> &bk = trf->bikes_drawn();
		if (gfx) {   // the nearest ones as real riders (city_crowd_riders.cpp); they are left out here
			Viewport *rv = get_viewport();
			Camera3D *rc = rv ? rv->get_camera_3d() : nullptr;
			if (rc) near_riders(bk, rc->get_global_position(), trf);
		}
		for (size_t k = 0; k + CityTraffic::BIKE_STRIDE - 1 < bk.size() && n < pc::MAX_PEDS; k += CityTraffic::BIKE_STRIDE) {
			if (std::find(rider_ids.begin(), rider_ids.end(), (int)bk[k + 6]) != rider_ids.end()) continue;
			const uint32_t h = (uint32_t)bk[k + 6] * 2654435761u ^ 0x5bd1e995u;
			const int female = (h >> 3) % 3u == 0u ? 1 : 0;   // (a third of them women)
			const std::vector<int> *pool = &pool_casual[female];
			if (pool->empty()) pool = &pool_casual[0];
			if (pool->empty()) break;
			const int body = (*pool)[(h >> 4) % (uint32_t)pool->size()];
			const float sc = 0.96f + (float)((h >> 5) % 100u) * 0.0009f;
			const Basis b = Basis(Vector3(0, 1, 0), bk[k + 3]) * Basis(Vector3(0, 0, 1), bk[k + 4]) * Basis().scaled(Vector3(sc, sc, sc));
			float *r = w + (size_t)n * ROW;
			r[0] = b.rows[0].x; r[1] = b.rows[0].y; r[2] = b.rows[0].z; r[3] = bk[k];
			r[4] = b.rows[1].x; r[5] = b.rows[1].y; r[6] = b.rows[1].z; r[7] = bk[k + 1];
			r[8] = b.rows[2].x; r[9] = b.rows[2].y; r[10] = b.rows[2].z; r[11] = bk[k + 2];
			const float turns = bk[k + 5] - std::floor(bk[k + 5]);
			const int pose = PeopleBake::RIDE0 + ((int)(turns * (float)PeopleBake::RIDE_N) % PeopleBake::RIDE_N);
			r[12] = (float)((h >> 8) % 24u);
			r[13] = (float)((h >> 13) % 16u) + (float)(body * 64);
			r[14] = (float)((h >> 17) % 8u) + 8.0f * (float)((h >> 20) % 4u) + POSE_K * (float)pose;
			r[15] = -((float)((h >> 22) % 997u) / 1000.0f + 1.0f);
			n++; riders_drawn++;
		}
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
// The nearest passers-by stop and look at what happens where walker `p_row` is; with `p_film` the first of them holds
// his phone up at it.
void CityCrowd::alarm(const Vector3 &p_at, float p_radius, float p_seconds, int p_kind) {
	for (size_t k = 0; k < alarms_recent.size();) {
		if (own_clock - alarms_recent[k].t > 3.0) { alarms_recent[k] = alarms_recent.back(); alarms_recent.pop_back(); continue; }
		if (alarms_recent[k].at.distance_squared_to(p_at) < 6.0f * 6.0f) return;
		k++;
	}
	alarms_recent.push_back(Alarm{ p_at, own_clock });
	crowd->scare(p_at.x, p_at.z, p_radius, p_seconds);
	if (p_kind >= 0 && p_kind < 8) alarms[p_kind]++;
	emit_signal("crowd_event", 18, -1, p_kind, 0.0);
}

void CityCrowd::onlookers(int p_row, int p_most, float p_seconds, bool p_film, bool p_call) {
	if (p_row < 0) return;
	int n = 0;
	for (int j = 0; j < crowd->hi && n < p_most; j++) {
		if (j == p_row || !crowd->alive[j] || crowd->mode[j] != pc::M_LINE || crowd->state[j] != pc::ST_WALK || crowd->act[j] != pc::A_NONE || crowd->party[j] != 0) continue;
		const float dx = crowd->x[p_row] - crowd->x[j], dz = crowd->z[p_row] - crowd->z[j], d2 = dx * dx + dz * dz;
		if (d2 > 81.0f || d2 < 2.25f) continue;
		const int a = (p_film && n == 0) ? pc::A_FILM : ((p_call && n == 1) ? pc::A_CALL : pc::A_STARE);
		if (!crowd->set_act(crowd->id[j], a, p_seconds)) continue;
		crowd->flags[j] |= pc::F_FACE; crowd->face_yaw[j] = std::atan2(dx, dz);
		n++;
	}
}

bool CityCrowd::carries(int i) const { return crowd->carry[i] || ((crowd->look[i] >> 20) & 7u) == 0u; }
int CityCrowd::carry_kind(int i) const { return crowd->carry[i] ? 0 : (int)((crowd->look[i] >> 23) % 3u); }

// The clips' lengths, once the first figure is made: how long the way into and out of an act is. The brain is told
// how long getting up takes (so a walker stands up where he sat, and walks only then), and how long blows last.
void CityCrowd::clip_lengths() {
	if (lens_ok || near_pool.empty() || !near_pool[0].ped) return;
	const CityPed *p = near_pool[0].ped;
	if (p->clip_len("ual/Idle_Loop") <= 0.0) return;   // (not made yet)
	lens_ok = true;
	l_sit_in = p->clip_len("ual/Sitting_Enter"); l_sit_out = p->clip_len("ual/Sitting_Exit");
	l_gsit_in = p->clip_len("ual/GroundSit_Enter"); l_gsit_out = p->clip_len("ual/GroundSit_Exit");
	l_lie_in = p->clip_len("ual/IdleToLay"); l_lie_out = p->clip_len("ual/LayToIdle");
	l_duck_in = p->clip_len("ual/Crouch_Enter"); l_duck_out = p->clip_len("ual/Crouch_Exit");
	l_fight_in = p->clip_len("ual/PunchKick_Enter"); l_fight_out = p->clip_len("ual/PunchKick_Exit");
	l_surprise = p->clip_len("ual/Surprise");
	l_cheer = std::min(p->clip_len("ual/Celebration"), 2.6);
	pc::Config &c = crowd->cfg;
	c.rise_s[pc::A_SIT] = c.rise_s[pc::A_DRINK] = (float)l_sit_out;
	c.rise_s[pc::A_GSIT] = (float)l_gsit_out;
	c.rise_s[pc::A_LIE_BACK] = c.rise_s[pc::A_LIE_FRONT] = (float)l_lie_out;
	c.rise_s[pc::A_DUCK] = (float)l_duck_out;
	c.rise_s[pc::A_FIGHT] = (float)l_fight_out;
	if (l_fight_in > 0.0) c.fight_s = 6.5f;
	c.cheer_s = (float)l_cheer;
	c.hurt_s = 45.0f;
}

// What a near body shows: the clip of what its walker does. `p_t`: how long it has shown this act (the way INTO an
// act, sitting down, crouching, squaring up, is played once, then the act's own clip). r_hold: -1 it runs, -2 once
// and held on its last frame, >= 0 held at that moment. r_token: a new number starts the same clip again.
void CityCrowd::clip_of(int i, float p_t, float p_v, StringName &r_clip, double &r_speed, double &r_hold, int &r_token) const {
	static const StringName WALK("ual/Walk_Loop"), WALK2("ual/Walk_Formal_Loop"), JOG("ual/Jog_Fwd_Loop"), SPRINT("ual/Sprint_Loop"), IDLE("ual/Idle_Loop"), ARMS("ual/Idle_FoldArms_Loop"),
			LOOK("ual/Idle_LookAround_Loop"), SIT_TALK("ual/Sitting_Talking_Loop"), LIE("ual/LayToIdle"), LIE_IN("ual/IdleToLay"), PHONE("ual/Idle_TalkingPhone_Loop"), FILM("ual/Idle_Lantern_Loop"),
			DUCK("ual/Crouch_Idle_Loop"), DUCK_IN("ual/Crouch_Enter"), DUCK_OUT("ual/Crouch_Exit"), TALK("ual/Idle_Talking_Loop"), NO("ual/Idle_No_Loop"), GIVE("ual/Interact"), WAVE("wave"), HUG("hug"),
			SIT_IN("ual/Sitting_Enter"), SIT_OUT("ual/Sitting_Exit"), GSIT("ual/GroundSit_Idle_Loop"), GSIT_IN("ual/GroundSit_Enter"), GSIT_OUT("ual/GroundSit_Exit"), SURPRISE("ual/Surprise"),
			FIGHT_IN("ual/PunchKick_Enter"), FIGHT_OUT("ual/PunchKick_Exit"), DODGE_L("ual/Dodge_Left"), DODGE_R("ual/Dodge_Right"), HIT_HEAD("ual/Hit_Head"), HIT_CHEST("ual/Hit_Chest"),
			HIT_BELLY("ual/Hit_Stomach"), TEXT("ual/Idle_Lantern_Loop"), FILM2("ual/Idle_Torch_Loop"), ANGRY("ual/Counter_Angry"), GIVE_COIN("ual/Counter_Give"), TIRED("ual/Idle_Tired_Loop"),
			WALK_TALK("ual/Walk_Talk_Loop"), WALK_PHONE("ual/Walk_Phone_Loop"), WALK_TEXT("ual/Walk_Text_Loop"), SIT_PHONE("ual/Sitting_Phone_Loop"), SIT_TEXT("ual/Sitting_Text_Loop"),
			SIT_DRINK("ual/Sitting_Drink_Loop"), GSIT_ASK("ual/GroundSit_Ask_Loop"), GSIT_THANKS("ual/GroundSit_Thanks_Loop"), WALK_HURT("ual/Walk_Hurt_Loop"), CHEER("ual/Celebration");
	static const StringName SITS[6] = { StringName("ual/Sitting_Idle_Loop"), StringName("ual/Sitting_Idle02_Loop"), StringName("ual/Sitting_Idle03_Loop"), StringName("ual/Sitting_Nodding_Loop"), SIT_PHONE, SIT_TEXT };
	static const StringName BLOWS[6] = { StringName("ual/Punch_Jab"), StringName("ual/Punch_Cross"), StringName("ual/Kick"), StringName("ual/Melee_Hook"), StringName("ual/Melee_Uppercut"), StringName("ual/Melee_Knee") };
	const uint32_t lk = crowd->look[i];
	const int g = (lk >> 3) & 1u, a = crowd->act[i];
	const float v = p_v;   // (his pace, smoothed over a moment: somebody held up for a step does not flick to standing and back)
	r_speed = 1.0; r_hold = -1.0; r_token = 0;
	if (crowd->mode[i] == pc::M_DODGE) {   // the jump out of a car's way: to the side it goes
		const float hx = std::sin(crowd->yaw[i]), hz = std::cos(crowd->yaw[i]);
		r_clip = ((crowd->x[i] - crowd->px[i]) * hz - (crowd->z[i] - crowd->pz[i]) * hx) > 0.0f ? DODGE_L : DODGE_R;
		r_hold = -2.0;
		return;
	}
	const bool stays = crowd->mode[i] == pc::M_STAY || crowd->mode[i] == pc::M_HELD || crowd->state[i] == pc::ST_PAUSE;
	if (!stays && v > 0.15f) {   // on its way: the walk at the walker's own pace, a jog, a run
		// each clip's own ground speed, measured on the figures (tools/people/clip_audit.gd STRIDE: man, woman): the bake's
		// walk round (1.4 m in 1.3 s) was 18 % fast, and every walker's planted foot slid 0.2 m/s (tests/people/trace_crowd.gd)
		static const float WALK_V[2] = { 0.91f, 0.94f }, JOG_V[2] = { 2.40f, 2.49f }, SPRINT_V[2] = { 3.16f, 3.28f };
		const int gk = g ? 1 : 0;
		if (v > 2.8f) { r_clip = SPRINT; r_speed = v / SPRINT_V[gk]; }
		else if (v > 1.9f) { r_clip = JOG; r_speed = v / JOG_V[gk]; }
		else { r_clip = ((lk >> 6) & 3u) == 0u ? WALK2 : WALK; r_speed = v / WALK_V[gk]; }
		// at a walk the hands are free: a phone at the ear or in the hand, a word to the one beside him (in a group
		// one of them talks for four seconds, then the next, then nobody for a while)
		if (v <= 1.9f) {
			bool talks = a == pc::A_TALK;
			if (!talks && crowd->party[i] != 0 && crowd->pkind[i] != pc::PK_JOGGER && crowd->psize[i] > 1)
				talks = ((int)(own_clock * 0.3) + crowd->party[i]) % std::max((int)crowd->psize[i], 1) == (int)crowd->slot[i];   // (Yasin, 21 Nov: "make most of them walk and talk if in groups": somebody always talking, in turn)
			if (a == pc::A_PHONE || a == pc::A_CALL) r_clip = ((lk >> 13) & 1u) ? WALK_TEXT : WALK_PHONE;
			else if (talks) r_clip = WALK_TALK;
			if (carries(i) && a != pc::A_PHONE && a != pc::A_CALL && !talks) { static const StringName C3[3] = { StringName("x/carry_bag"), StringName("x/carry_box"), StringName("x/carry_case") }; r_clip = C3[carry_kind(i)]; }   // (a bag, a box, a briefcase: Mixamo, 21 Nov)
			if (crowd->hurt_t[i] > 0.0f) r_clip = WALK_HURT;   // he lost a fight: slowly away, his hands at his face
		}
		r_speed = std::min(std::max(r_speed, 0.4), 2.2);
		// (a wave in passing: the standing wave clip on a walker made his whole figure skate, 0.94 m/s: tests/people/trace_crowd.gd
		// --acts. Walking, he walks on; stopped, he waves)
		if (a == pc::A_WAVE && v < 0.3f) { r_clip = WAVE; r_speed = 1.0; }
		return;
	}
	// first the way into the act, once; then the act
	auto seq = [&](const StringName &p_in, double p_in_len, const StringName &p_loop) {
		if (p_t < (float)p_in_len) { r_clip = p_in; r_hold = -2.0; } else r_clip = p_loop;
	};
	switch (a) {
		case pc::A_SIT: {
			// (from his seat: the seated gesture of his line)
			StringName st = SIT_TALK;
			static const char *const GS[13] = { nullptr, "x/gs_yes", "x/gs_no", nullptr, "x/gs_talk", "x/gs_ask", "x/gs_talk", "x/gs_point", "x/gs_angry", "x/gs_talk", "x/gs_ask", "x/gs_no", "x/gs_cheer" };
			const int gk = gesture_now(crowd->id[i]);
			if (gk > 0 && gk < 13 && GS[gk]) st = StringName(GS[gk]);
			// (Yasin, 21 Nov: "some of them should speak on benches") sitting with his party: they talk, in turn
			static const StringName SIT_CHAT("x/sit_chat");
			const bool party_sit = crowd->party[i] != 0 && crowd->psize[i] > 1;
			seq(SIT_IN, l_sit_in, speaking(crowd->id[i]) ? st : (party_sit ? SIT_CHAT : SITS[(lk >> 12) % 6u]));
		} break;   // (talking to the player from his seat: the seated talk)
		case pc::A_DRINK: seq(SIT_IN, l_sit_in, ((int)(p_t / 5.0f) % 3 == 1) ? SIT_DRINK : SIT_TALK); break;   // a word, a sip, a word
		case pc::A_GSIT: seq(GSIT_IN, l_gsit_in, GSIT); break;
		case pc::A_BEG: {   // a beggar: his hand out to whoever comes by, a nod to the one who gives
			r_clip = GSIT;
			for (int j = 0; j < crowd->hi; j++) {
				if (j == i || !crowd->alive[j]) continue;
				const float dx = crowd->x[j] - crowd->x[i], dz = crowd->z[j] - crowd->z[i], d2 = dx * dx + dz * dz;
				if (d2 > 25.0f) continue;
				if (crowd->act[j] == pc::A_GIVE && d2 < 9.0f) { r_clip = GSIT_THANKS; break; }
				r_clip = GSIT_ASK;
			}
			if (r_clip == GSIT && has_last_player) { const float dx = last_player.x - crowd->x[i], dz = last_player.z - crowd->z[i]; if (dx * dx + dz * dz < 25.0f) r_clip = GSIT_ASK; }
		} break;
		case pc::A_LIE_BACK: case pc::A_LIE_FRONT:
			if (p_t < (float)l_lie_in) { r_clip = LIE_IN; r_hold = -2.0; } else { r_clip = LIE; r_hold = 0.0; }
			break;
		case pc::A_PHONE: { static const StringName ANGRY_CALL("x/phone_angry"); r_clip = ((lk >> 13) & 1u) ? TEXT : ((((lk >> 24) % 5u) == 0u) ? ANGRY_CALL : PHONE); } break;   // in the hand, or at the ear (one caller in five arguing)
		case pc::A_CALL: { static const StringName ANGRY_CALL("x/phone_angry"); r_clip = (((lk >> 24) % 5u) == 0u) ? ANGRY_CALL : PHONE; } break;
		case pc::A_FILM: r_clip = FILM2; break;
		case pc::A_WINDOW: r_clip = LOOK; break;
		case pc::A_SHELTER: r_clip = ARMS; break;
		case pc::A_STARE: seq(SURPRISE, l_surprise, ((lk >> 9) & 1u) ? ARMS : LOOK); break;
		case pc::A_DUCK: seq(DUCK_IN, l_duck_in, DUCK); break;
		case pc::A_CHAT: case pc::A_TALK: {   // (talking to the player: the gesture of his line)
			r_clip = TALK;
			static const char *const GK[13] = { nullptr, "ual/Yes", "ual/Idle_No_Loop", nullptr, "x/g_wave", "x/g_ask", "x/g_thanks", "x/g_point", "x/g_angry", "x/g_secret", "x/g_unsure", "x/g_sorry", "x/g_cheer" };
			const int gk = gesture_now(crowd->id[i]);
			if (gk > 0 && gk < 13 && GK[gk]) { r_clip = StringName(GK[gk]); r_hold = -2.0; r_token = 8900 + gk; }
		} break;
		case pc::A_NOD: { static const StringName YES("ual/Yes"); r_clip = YES; r_hold = -2.0; } break;   // (the Animator, 20 Nov: talks had no nod)
		case pc::A_NO: r_clip = NO; break;   // (and no refusal: he walked on with a caption)
		case pc::A_ARGUE: r_clip = ((lk >> 5) & 1u) ? NO : ANGRY; break;
		case pc::A_HUG: r_clip = HUG; break;
		case pc::A_GIVE: r_clip = GIVE_COIN; r_hold = -2.0; break;
		case pc::A_DOOR: r_clip = GIVE; break;
		case pc::A_WAVE: r_clip = WAVE; break;
		case pc::A_WAIT: { const uint32_t w = (lk >> 9) % 3u; r_clip = w == 0u ? IDLE : (w == 1u ? ARMS : LOOK); } break;
		case pc::A_RISE:   // the way out of what it did, once
			switch (crowd->rise_from[i]) {
				case pc::A_SIT: case pc::A_DRINK: r_clip = SIT_OUT; break;
				case pc::A_GSIT: r_clip = GSIT_OUT; break;
				case pc::A_LIE_BACK: case pc::A_LIE_FRONT: r_clip = LIE; break;
				case pc::A_DUCK: r_clip = DUCK_OUT; break;
				case pc::A_FIGHT: r_clip = FIGHT_OUT; break;
				default: r_clip = IDLE; break;
			}
			if (r_clip != IDLE) r_hold = -2.0;
			break;
		case pc::A_CHEER: r_clip = CHEER; r_hold = -2.0; break;
		case pc::A_FIGHT: {
			// Blows: both square up; then a blow every 0.95 s, the two taking turns; the other takes it on the head, the
			// chest or the belly a moment later, or gets out of its way. The beats are counted from the END, so that the
			// last blow is always the winner's (the brain's fwin): that one is a real shove (near_update). Both bodies
			// work it out from the same numbers (the time the fight has left, the two ids), so they agree without a word.
			const float left = std::max(crowd->pause_t[i], 0.0f);
			if (crowd->cfg.fight_s - left < (float)l_fight_in) { r_clip = FIGHT_IN; r_hold = -2.0; break; }
			const float beat = 0.95f;
			const int k = (int)(left / beat), me = crowd->id[i], other = crowd->mate[i];
			const float into = beat - (left - (float)k * beat);
			const bool mine = ((k & 1) == 0) == (crowd->fwin[i] != 0);
			const uint32_t h = pc::hash32((uint32_t)(std::min(me, other) * 7919 + std::max(me, other)) * 31u + (uint32_t)k);
			const int blow = (int)(h % 6u);
			if (mine) { r_clip = BLOWS[blow]; r_hold = -2.0; r_token = k + 1; break; }
			if (into < 0.22f) { static const StringName STANCE("x/fight_stance"); r_clip = STANCE; r_hold = -1.0; break; }   // his stance (Mixamo's, a loop), until the blow lands
			if (k > 0 && ((h >> 8) & 3u) == 0u) r_clip = ((h >> 10) & 1u) ? DODGE_L : DODGE_R;
			else r_clip = (blow == 2 || blow == 5) ? HIT_BELLY : (((h >> 11) & 1u) ? HIT_HEAD : HIT_CHEST);
			r_hold = -2.0; r_token = k + 1001;
		} break;
		default:   // standing: at a kerb for the lights a look round, folded arms; a jogger gets his breath
			// (Yasin, 21 Nov: "i want a living city") waiting, each his own way: a look round, folded arms, the phone at his ear
			// or in his hand, a cigarette, shifting about and stretching; carrying, he holds it
			if (crowd->state[i] == pc::ST_WAIT) {
				static const StringName W_BORED("x/wait_bored"), W_SMOKE("x/wait_smoke");
				const StringName W8[8] = { IDLE, ARMS, LOOK, PHONE, TEXT, W_SMOKE, W_BORED, LOOK };
				r_clip = (crowd->party[i] != 0 && crowd->pkind[i] == pc::PK_JOGGER) ? TIRED : W8[(lk >> 9) % 8u];
				// (Yasin, 21 Nov: "some of them should sell items") one waiter in eight is a street seller: calling out, offering, counting
				if (crowd->party[i] == 0 && ((lk >> 27) & 7u) == 0u) { static const StringName SELL("x/seller"); r_clip = SELL; }
			} else r_clip = IDLE;
			if (carries(i) && carry_kind(i) > 0) { static const StringName CI[3] = { StringName(), StringName("x/carry_box_idle"), StringName("x/carry_case_idle") }; r_clip = CI[carry_kind(i)]; }
			if (crowd->hurt_t[i] > 0.0f) { static const StringName NURSE("ual/Bandage_Loop"); r_clip = NURSE; }   // (hurt and standing: he sees to it)
			break;
	}
}

// Who has a near body this frame, what it shows, and the hand-over to its physical body and back.
void CityCrowd::near_update(double p_delta, double p_alpha) {
	if (near_pool.empty()) return;
	clip_lengths();
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
	// A body goes to whoever is nearer. With every body taken, somebody who comes out of a door beside the camera would
	// stay a far figure while a body is held 30 m away (seen 20 Nov: five people set down beside the player stood as far
	// figures). So: when somebody without a body is clearly nearer than the farthest who has one, that one gives his up.
	for (int kind = 0; kind < 2; kind++) {
		int far_k = -1; float far_d = -1.0f; bool free_one = false;
		for (int k = 0; k < (int)near_pool.size(); k++) {
			const Near &nb = near_pool[k];
			if (nb.female != kind) continue;
			if (nb.walker < 0) { free_one = true; continue; }
			if (nb.in_body || nb.ped->get_mode() != CityPed::MODE_ANIM) continue;
			const int i = crowd->find(nb.walker);
			if (i < 0) continue;
			const float dx = crowd->x[i] - cp.x, dz = crowd->z[i] - cp.z, d2 = dx * dx + dz * dz;
			if (d2 > far_d) { far_d = d2; far_k = k; }
		}
		if (free_one || far_k < 0) continue;
		float near_d = far_d;
		for (int i = 0; i < crowd->hi; i++) {
			if (!crowd->alive[i] || (crowd->flags[i] & pc::F_HIDDEN) || (int)((crowd->look[i] >> 3) & 1u) != kind || crowd->mode[i] == pc::M_BODY) continue;
			const float dx = crowd->x[i] - cp.x, dz = crowd->z[i] - cp.z, d2 = dx * dx + dz * dz;
			if (d2 >= near_d) continue;
			bool has = false;
			for (const Near &o : near_pool) if (o.walker == crowd->id[i]) has = true;
			if (has) continue;
			{ float pq[4]; int bq; float sq; person_of(i, pq, bq, sq); if (bodies[bq].female != kind) continue; }
			near_d = d2;
		}
		if (std::sqrt(near_d) + 3.0f < std::sqrt(far_d)) { near_pool[far_k].walker = -1; near_pool[far_k].ped->set_visible(false); }
	}
	auto give = [&](Near &nb, int best) {
		float pr[4]; int body; float sc;
		person_of(best, pr, body, sc);
		nb.walker = crowd->id[best]; nb.in_body = false; nb.has_last = false; nb.has_y = false; nb.v_s = crowd->v[best]; nb.ped->set_stay_down(false);
		nb.why = 0; nb.after_kind = 0; nb.after_t = 0.0f;
		nb.v_s = crowd->v[best];
		nb.act = crowd->act[best]; nb.act_t = 99.0f;
		nb.look->set_shader_parameter("person", Vector4(pr[0], pr[1] - (float)(body * 64), pr[2], pr[3]));
		nb.ped->become(bodies[body].id, bodies[body].near_mesh, nb.look, sc > 0.9f);
		nb.ped->set_visible(true);
#ifdef TRAV_IN_GAME
		if (trav_people) nb.ped->set_drawn(false);   // (the new body takes his place at the next physics step: city_crowd_trav.cpp)
#endif
	};
	// a cyclist who came off gets a body before anybody: a free one of his kind, else the farthest that is only walking
	for (size_t q = 0; q < thrown.size();) {
		Thrown &th = thrown[q];
		th.t += (float)p_delta;
		const int i = crowd->find(th.walker);
		bool has = false;
		for (const Near &o : near_pool) if (o.walker == th.walker) has = true;
		if (i < 0 || (!has && th.t > 1.5f)) {   // gone, or no body could be his: he walks to the pavement from there
			if (i >= 0) { crowd->to_body(th.walker, true, crowd->x[i], crowd->z[i]); crowd->to_body(th.walker, false, crowd->x[i], crowd->z[i]); }
			thrown.erase(thrown.begin() + (long)q); continue;
		}
		if (!has) {
			float pq[4]; int bq; float sq; person_of(i, pq, bq, sq);
			const int kind = bodies[bq].female;
			int pick = -1; float far_d = -1.0f;
			for (int k = 0; k < (int)near_pool.size(); k++) {
				const Near &nb = near_pool[k];
				if (nb.female != kind) continue;
				if (nb.walker < 0) { pick = k; break; }
				if (nb.in_body || nb.ped->get_mode() != CityPed::MODE_ANIM) continue;
				const int j = crowd->find(nb.walker);
				if (j < 0) { pick = k; break; }
				const float dx = crowd->x[j] - cp.x, dz = crowd->z[j] - cp.z;
				if (dx * dx + dz * dz > far_d) { far_d = dx * dx + dz * dz; pick = k; }
			}
			if (pick >= 0) { if (near_pool[pick].walker >= 0) near_pool[pick].ped->set_visible(false); give(near_pool[pick], i); riders_bodied++; }
		}
		q++;
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
			if (has) continue;
			// (the near figure must be of the walker's kind: a walker whose body is of the other kind keeps its far figure.
			// Asked HERE, not after the nearest is chosen: such a walker beside the camera took the free body's choice every
			// frame and was refused every frame, and nobody farther off ever got it.)
			{ float pq[4]; int bq; float sq; person_of(i, pq, bq, sq); if (bodies[bq].female != nb.female) continue; }
			bd = d2; best = i;
		}
		if (best < 0) continue;
		float pr[4]; int body; float sc;
		person_of(best, pr, body, sc);
		nb.walker = crowd->id[best]; nb.in_body = false; nb.has_last = false; nb.has_y = false; nb.v_s = crowd->v[best]; nb.ped->set_stay_down(false);
		nb.why = 0; nb.after_kind = 0; nb.after_t = 0.0f;
		nb.v_s = crowd->v[best];
		nb.act = crowd->act[best]; nb.act_t = 99.0f;   // (whatever it is doing, it is doing it already)
		nb.look->set_shader_parameter("person", Vector4(pr[0], pr[1] - (float)(body * 64), pr[2], pr[3]));
		nb.ped->become(bodies[body].id, bodies[body].near_mesh, nb.look, sc > 0.9f);
		nb.ped->set_visible(true);
	}
	// the cars near a body: it knows them as boxes, takes over by itself when one reaches it, and is pushed and knocked
	// over by them while its balancing body has it. (Fed in BOTH states: fed only while animated, the car's box stood
	// still from the moment of the take-over, and a car at 25 km/h moved a man 0.4 m and left him standing: seen 20 Nov
	// in tests/people/test_car_hits.gd.)
	auto feed_boxes = [&](Near &nb, int i) {
		int k = 0;
		const int nc = (int)cars.size() / 7;
		for (int c = 0; c < nc && k + 2 <= pb::MAX_BOXES; c++) {
			const float *q = &cars[(size_t)c * 7];
			const float dx = q[0] - crowd->x[i], dz = q[1] - crowd->z[i];
			if (dx * dx + dz * dz > 9.0f * 9.0f) continue;
			k = car_boxes(nb.ped, k, q, crowd->y[i]);
		}
		if (k == 0) nb.ped->set_box(-1, Vector3(), Vector3(), 0.0, Vector3(), 0);
	};
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
		// CPR (Yasin, 21 Nov: "paramedic should do cpr and rceiving npc shoud lay flat and everything"): a medic has knelt by
		// him: his body hands over to Receiving_Cpr laid where it lies; treated, he gets up from his back (Getting_Up), and
		// only then is he up again (his walker goes on from there)
		{
			bool cpr_on = false, treated = false;
			for (const Down &d : downs) if (d.walker == nb.walker) { cpr_on = d.cpr; treated = d.treated; }
			static const StringName CPR("x/cpr_take"), UP("x/up_from_back");
			if (nb.cpr == 0 && cpr_on && nb.in_body && nb.ped->get_mode() == CityPed::MODE_BODY && nb.ped->lie_as(CPR)) { nb.cpr = 1; nb.cpr_t = 0.0f; nb.cpr_xf = nb.ped->get_global_transform(); n_cpr++; }
			if (nb.cpr == 1) {
				if (!cpr_on || treated) { nb.cpr = 2; nb.cpr_t = 0.0f; }
				else { nb.ped->drive(nb.cpr_xf, CPR, 1.0, -1.0, 0); continue; }
			}
			if (nb.cpr == 2) {
				nb.cpr_t += (float)p_delta;
				if (nb.cpr_t < (float)nb.ped->clip_len(UP)) { nb.ped->drive(nb.cpr_xf, UP, 1.0, -2.0, 8801); continue; }
				nb.cpr = 0; nb.ped->set_stay_down(false);
			}
		}
		if (nb.ped->get_mode() == CityPed::MODE_ANIM) {
			if (nb.in_body) {   // it is up again
				const Vector3 at = nb.ped->get_global_transform().origin;
				// THE PLAYER SHOVED HIM: before he goes his way he turns to the player. The first time he tells him off (one
				// in four only stares at him); shoved again within two minutes, half of them square up and hit back, the rest
				// tell him off for longer. People near by stop and look. (The signal crowd_event says so: 16 = shoved, aux = how
				// often; 17 = he hits the player. The talk makes him refuse to speak for a day.)
				if (nb.why == 1 && pl && nb.after_t <= 0.0f && nb.after_kind == 0) {
					const uint32_t lk = crowd->look[i];
					int cnt = 1; bool known = false;
					for (Shove &sh : shoves) if (sh.look == lk) { known = true; sh.n = own_clock - sh.t < 120.0 ? sh.n + 1 : 1; sh.t = own_clock; cnt = sh.n; }
					if (!known) { Shove sh; sh.look = lk; sh.t = own_clock; sh.n = 1; if (shoves.size() >= 32) shoves.erase(shoves.begin()); shoves.push_back(sh); }
					nb.after_kind = cnt >= 2 ? (((lk >> 17) & 1u) ? 2 : 1) : (((lk >> 18) & 3u) == 0u ? 3 : 1);
					nb.after_len = nb.after_kind == 2 ? (float)(l_fight_in + 0.9 + l_fight_out) : (nb.after_kind == 3 ? 2.0f : (cnt >= 2 ? 4.2f : 2.8f));
					nb.after_t = nb.after_len; nb.after_hit = false;
					n_shoved++;
					if (nb.after_kind == 2) n_hit_back++; else if (nb.after_kind == 1) n_told_off++;
					emit_signal("crowd_event", 16, nb.walker, cnt, 0.0);
					onlookers(i, 3, 2.5f, false);
				}
				if (nb.after_t > 0.0f) {
					static const StringName ANGRY("ual/Counter_Angry"), NO("ual/Idle_No_Loop"), ARMS("ual/Idle_FoldArms_Loop"), F_IN("ual/PunchKick_Enter"), F_OUT("ual/PunchKick_Exit"), CROSS("ual/Punch_Cross");
					nb.after_t -= (float)p_delta;
					const Vector3 pp = pl ? pl->get_global_position() : at;
					const float e = nb.after_len - nb.after_t;
					StringName clip = ((crowd->look[i] >> 5) & 1u) ? NO : ANGRY; double hold = -1.0; int token = 0;
					if (nb.after_kind == 3) clip = ARMS;
					else if (nb.after_kind == 2) {
						hold = -2.0;
						if (e < (float)l_fight_in) clip = F_IN;
						else if (e < (float)l_fight_in + 0.9f) {
							clip = CROSS; token = 7;
							if (!nb.after_hit && e > (float)l_fight_in + 0.3f) {   // the blow lands, if the player is still there
								nb.after_hit = true;
								Vector3 d(pp.x - at.x, 0, pp.z - at.z);
								if (pl && d.length() < 1.7f && d.length() > 0.05f) {
									if (pl->has_method("knock")) pl->call("knock", d.normalized() * 4.5f);
									emit_signal("crowd_event", 17, nb.walker, 0, 0.0);
								}
							}
						} else clip = F_OUT;
					}
					const float yaw_to = std::atan2(pp.x - at.x, pp.z - at.z);
					const float yaw_now = nb.ped->get_global_transform().basis.get_euler().y;
					const float turn = std::min(std::max((float)Math::wrapf(yaw_to - yaw_now, -Math_PI, Math_PI), -6.0f * (float)p_delta), 6.0f * (float)p_delta);
					nb.ped->drive(Transform3D(Basis(Vector3(0, 1, 0), yaw_now + turn).scaled(Vector3(sc, sc, sc)), at), clip, 1.0, hold, token);
				}
				if (nb.after_t <= 0.0f) { crowd->to_body(nb.walker, false, at.x, at.z); nb.in_body = false; nb.why = 0; nb.after_kind = 0; }   // its walker goes on from where it stands
			}
			if (crowd->mode[i] != pc::M_BODY) {
				const float a = std::min(std::max(((float)(crowd->tick - crowd->tu[i]) + (float)p_alpha) / (float)std::max((int)crowd->span[i], 1), 0.0f), 1.0f);
				Vector3 at(crowd->px[i] + (crowd->x[i] - crowd->px[i]) * a, crowd->py[i] + (crowd->y[i] - crowd->py[i]) * a, crowd->pz[i] + (crowd->z[i] - crowd->pz[i]) * a);
				// two who fight close in to arm's reach (0.8 m): people who meet stand a pavement's width apart, and blows
				// thrown from there hit the air (Yasin, 20 Nov: "fighters take blows too far away"). Only the bodies step in,
				// over half a second, and step back as it ends.
				{
					const int ac = crowd->act[i];
					const bool fighting = ac == pc::A_FIGHT, after = ac == pc::A_CHEER || (ac == pc::A_RISE && crowd->rise_from[i] == pc::A_FIGHT);
					const int j = (fighting || after) && crowd->mate[i] != 0 ? crowd->find(crowd->mate[i]) : -1;
					if (j >= 0) {
						Vector3 d(crowd->x[j] - crowd->x[i], 0, crowd->z[j] - crowd->z[i]);
						const float dist = d.length();
						float w = 1.0f;
						if (fighting) w = std::min((crowd->cfg.fight_s - crowd->pause_t[i]) / 1.0f, 1.0f);   // (over a second: two steps in)
						else if (ac == pc::A_CHEER) w = std::min(crowd->pause_t[i] / 0.5f, 1.0f);
						else w = crowd->cfg.rise_s[pc::A_FIGHT] > 0.0f ? crowd->rise_t[i] / crowd->cfg.rise_s[pc::A_FIGHT] : 0.0f;
						if (dist > 0.8f && dist < 4.0f) at += d / dist * (std::min((dist - 0.8f) * 0.5f, 1.2f) * std::min(std::max(w, 0.0f), 1.0f));
					}
				}
				// (a kerb: the walker's height steps 12-15 cm between two of the crowd's ticks, and the whole figure went up 5 cm a
				// frame. The figure eases up after it (about 0.1 s) while its foot plant puts the leading foot on the kerb's top;
				// Yasin: "kerbs shouldnt require step up animation, but if you can make it truly seamless its okay")
				if (!nb.has_y || std::fabs(at.y - nb.y_s) > 0.4f) { nb.y_s = at.y; nb.has_y = true; }
				else { nb.y_s += (at.y - nb.y_s) * (1.0f - std::exp(-(float)p_delta / 0.09f)); at.y = nb.y_s; }
				StringName clip; double speed, hold; int token;
				const int act_now = crowd->act[i] | (crowd->mode[i] == pc::M_DODGE ? 256 : 0);
				if (nb.act != act_now) { nb.act = act_now; nb.act_t = 0.0f; } else nb.act_t += (float)p_delta;
				// the clip's pace from how fast the figure really moves (smoothed over about 0.15 s), not the walker's planned speed:
				// on a curve, weaving or slowing they differ, and the planted feet slid (tests/people/trace_crowd.gd)
				{
					float v_real = crowd->v[i];
					if (nb.has_last && p_delta > 1e-4) v_real = Vector2(at.x - nb.last_at.x, at.z - nb.last_at.z).length() / (float)p_delta;
					if (v_real > 6.0f) v_real = crowd->v[i];   // (a jump of the row: not a pace)
					nb.last_at = at; nb.has_last = true;
					nb.v_s += (v_real - nb.v_s) * std::min((float)p_delta * 7.0f, 1.0f);
				}
				clip_of(i, nb.act_t, nb.v_s, clip, speed, hold, token);
				// MOVING WHILE A STANDING CLIP PLAYS: he walks there. (Fighters closing in glided 1.2 m in half a second on
				// their guard clip, a wave in passing, sitting down while still going: the feet skated 0.5-0.9 m/s,
				// tests/people/trace_crowd.gd --acts.) Once he stands, the act's clip from where it was.
				{
					double ld; int ns;
					nb.stepping = nb.v_s > (nb.stepping ? 0.15f : 0.3f);   // (on above 0.3 m/s, off under 0.15: no flicker between the two)
		if (nb.stepping && !CityPed::stride_of(clip, ld, ns) && crowd->mode[i] != pc::M_DODGE) {
						static const StringName STEP_W("ual/Walk_Loop"), STEP_J("ual/Jog_Fwd_Loop");
						if (nb.v_s > 1.9f) { clip = STEP_J; speed = nb.v_s / (nb.female ? 2.49 : 2.40); }
						else { clip = STEP_W; speed = std::max((double)nb.v_s / (nb.female ? 0.94 : 0.91), 0.4); }
						hold = -1.0; token = 0;
						nb.act_t = 0.0f;   // (the act's way in starts when he stands)
					}
				}
				// THE PLAYER'S MOVEMENTS FOR EVERYBODY (the Animator, 20 Nov; Yasin: "give the new movements to npcs too";
				// "just open the hands of quaternius animations and use them for walk"): the walk, jog and idle with the
				// hands open, and the walk stop (make_steps.gd) when he comes to a stand. (A fight keeps its fists: the
				// clips below override this.)
				{
					static const StringName UW("ual/Walk_Loop"), UJ("ual/Jog_Fwd_Loop"), UI("ual/Idle_Loop"), OW("ual/Walk_Loop"), OJ("ual/Jog_Fwd_Loop"), OI("ual/Idle_Loop"),
							OSL("step/rb_stop_l"), OSR("step/rb_stop_r");   // (the Rocketbox walk and run again: Yasin, 21 Nov)
					if (nb.st_walker != nb.walker) { nb.st_walker = nb.walker; nb.st_mode = 0; nb.st_moving = nb.v_s > 0.3f; }
					const bool plain = hold < 0.0 && token == 0 && (clip == UW || clip == UI);
					const bool moving = nb.v_s > (nb.st_moving ? 0.15f : 0.3f);
					if (nb.ped->clip_len(OW) > 0.0 && plain) {
						// (no start for them: the crowd's brain moves them at its own pace from the first frame, not the clip's,
						// and its planted foot slid 1.24 m/s, tests/people/trace_crowd.gd; the stop stands still: 0.00)
						if (!moving && nb.st_moving && nb.st_mode == 0 && (nb.ped->current_clip() == OW || nb.ped->current_clip() == UW)) {
							// on the foot nearer its landing (the walk's left lands at 0 of its loop, the right at 0.5)
							const double len = nb.ped->clip_len(nb.ped->current_clip());
							double ph = len > 0.0 ? nb.ped->clip_pos() / len : 0.0;
							{ double ld = 0.0; int ns = 1; if (nb.ped->stride_now(ld, ns)) ph -= ld; }   // (where this take's left foot lands)
							ph -= std::floor(ph);
							nb.st_mode = 2; nb.st_t = 0.0f; nb.st_clip = (ph > 0.25 && ph < 0.75) ? OSR : OSL;
						}
						if (nb.st_mode == 2 && moving) nb.st_mode = 0;   // (changed his mind)
						if (nb.st_mode != 0) {
							nb.st_t += (float)p_delta;
							if (nb.st_t >= (float)nb.ped->clip_len(nb.st_clip)) nb.st_mode = 0;
							else { clip = nb.st_clip; speed = 1.0; hold = -2.0; token = 9100 + nb.st_mode; }
						}
					} else if (!plain) nb.st_mode = 0;
					nb.st_moving = moving;
					// (since 21 Nov the takes play Mixamo's: city_ped_takes.cpp) a moving loop plays at the walker's pace over its own
					// measured pace (meta ground_v), so the planted foot stays put whatever take this person has
					if (hold < 0.0 && token == 0 && nb.v_s > 0.15f) { const double gv = nb.ped->ground_v(clip, -1.0); if (gv > 0.2) speed = std::min(std::max((double)nb.v_s / gv, 0.4), 2.2); }
				}
				if (pf.walker == nb.walker && pf.angry) {   // fighting the player: his guard, a blow, a dodge, a step in
					static const StringName GUARD("ual/PunchKick_Enter"), JAB("ual/Punch_Jab"), CROSS("ual/Punch_Cross"), DL("ual/Dodge_Left"), DR("ual/Dodge_Right"), STEP("ual/Walk_Loop");
					speed = 1.0; token = 0;
					static const StringName HIT_H("ual/Hit_Head"), HIT_C("ual/Hit_Chest");
					if (pf.st == 1) { clip = (pf.attacks & 1) ? CROSS : JAB; hold = -2.0; token = pf.attacks + 1; }
					else if (pf.st == 4) { clip = (pf.landed & 1) ? HIT_H : HIT_C; hold = -2.0; token = 2000 + pf.landed; }
					else if (pf.st == 2) { clip = pf.dodge_dir > 0 ? DL : DR; hold = -2.0; token = 1000 + pf.dodges; }
					else if (pf.st == 3) { static const StringName FSTEP("x/fight_step"); clip = FSTEP; hold = -1.0; }   // (the fight's own step in)
					else if (pf.in_t < (float)l_fight_in) { clip = GUARD; hold = -2.0; token = 6000; }   // (into his guard: played through)
					else { static const StringName STANCE("x/fight_stance"), TAUNT("x/fight_taunt"); clip = (((int)(own_clock * 0.2) + nb.walker) % 5 == 0) ? TAUNT : STANCE; hold = -1.0; }   // (his stance, a taunt now and then: Mixamo, 21 Nov)
				}
				for (const Rager &r : ragers) {   // out of his car (getting up from the seat), then yelling, arms going
					if (r.walker != nb.walker) continue;
					static const StringName EXIT("x/car_out"), ANGRY("ual/Counter_Angry");   // (out of his car: Mixamo's Exiting_Car, 21 Nov)
					speed = 1.0;
					static const StringName RUN("ual/Sprint_Loop"), RUN_IN("ual/Sprint_Enter"), RUN_OUT("ual/Sprint_Exit");
					if (r.t < 2.4f) { clip = EXIT; hold = -2.0; token = 7001; }
					else if (r.chase && r.arrive_t >= 0.0f) { clip = RUN_OUT; hold = -2.0; token = 7003; }
					else if (r.chase && r.chase_t < 0.5f) { clip = RUN_IN; hold = -2.0; token = 7002; }
					else if (r.chase) { clip = RUN; hold = -1.0; token = 0; }
					else { clip = ANGRY; hold = -1.0; token = 0; }
				}
				if (const Actor *ac = actor_of(nb.walker)) actor_clip(*ac, clip, speed, hold, token);   // (the game's: city_crowd_actors.cpp)
				// in the sea: wading while the water is under the chest (his feet on the bottom), then swimming at the
				// surface (the same two numbers as the player's)
				{
					const float wd = sea_depth(at.x, at.z);
					if (wd > 1.15f) {
						static const StringName SWIM("ual/Swim_Fwd_Loop"), FLOAT("ual/Swim_Idle_Loop");
						at.y = (float)sea_y - 0.38f;
						clip = nb.v_s > 0.2f ? SWIM : FLOAT; speed = nb.v_s > 0.2f ? std::min(std::max(nb.v_s / 1.0f, 0.6f), 1.6f) : 1.0; hold = -1.0; token = 0;
					} else if (wd > 0.05f) at.y = (float)sea_y - wd;
				}
				{   // (a person's size scales his stride: a walking clip's pace divided by it, or a big walker's feet slid)
					double ld; int ns;
					if (CityPed::stride_of(clip, ld, ns)) speed /= std::max((double)sc, 0.5);
				}
				nb.ped->drive(Transform3D(Basis(Vector3(0, 1, 0), lerp_angle(crowd->pyaw[i], crowd->yaw[i], a)).scaled(Vector3(sc, sc, sc)), at), clip, speed, hold, token);
				{   // the phone he films with: a dark slab, 7 x 14.5 x 0.9 cm, in his raised left hand (the filming clip holds it up)
					const bool rec = crowd->act[i] == pc::A_FILM;
					if (rec && !nb.phone) {
						if (Skeleton3D *sk = nb.ped->skeleton()) {
							const float k = std::max((float)sk->get_global_transform().basis.get_scale().x / std::max(sc, 0.5f), 1e-4f);   // (the skeleton's units: centimetres)
							BoneAttachment3D *ba = memnew(BoneAttachment3D); ba->set_bone_name("Bip01_L_Hand"); sk->add_child(ba);
							MeshInstance3D *m = memnew(MeshInstance3D);
							Ref<BoxMesh> bm; bm.instantiate(); bm->set_size(Vector3(0.009f, 0.07f, 0.145f) / k);   // (upright, its face toward him: thin along the hand, tall up its side)
							Ref<StandardMaterial3D> mat; mat.instantiate(); mat->set_albedo(Color(0.05f, 0.05f, 0.06f)); mat->set_roughness(0.35f); mat->set_metallic(0.3f);
							m->set_mesh(bm); m->set_material_override(mat); m->set_cast_shadows_setting(GeometryInstance3D::SHADOW_CASTING_SETTING_OFF);
							nb.phone_base = Vector3(0.09f, -0.02f, 0.0f) / k;   // (along the hand, past the palm: held in the fingers)
							m->set_position(nb.phone_base);
							ba->add_child(m); nb.phone = m; nb.phone_k = k;
							m->set_as_top_level(true);   // (placed in the world each frame: upright, not turned with the hand)
						}
					}
					if (nb.phone) nb.phone->set_visible(rec && nb.ped->get_mode() == CityPed::MODE_ANIM);
					// HOW HE HOLDS IT (Yasin, 20 Nov: "push it 10 cms to left on that photo and 3 cms up", "actually 5cms left",
					// "not the bone the phone", "pull it 3 cms back into the hand. fingers should cover it and it shouldnt clip and
					// it should stand straight"): placed in the world each frame, not by the hand's bone: upright whatever way the hand
					// is turned, its face toward him; its lower part in the fist's grip (where the clip's torch handle was), so the
					// fingers close round it and not through it; on the front photo (taken from his front-left) 7 cm left and 3 cm
					// back ("pull 3 more cms back and 5 more cms left"): 7.56 cm toward his right, 0.82 cm forward,
					// and 3 cm up
					if (nb.phone && nb.phone->is_visible()) {
						if (Node3D *ba = Object::cast_to<Node3D>(nb.phone->get_parent())) {
							const Basis fb = nb.ped->get_global_transform().basis.orthonormalized();
							Vector3 fwd = fb.get_column(2); fwd.y = 0.0f; fwd = fwd.length() > 0.01f ? fwd.normalized() : Vector3(0, 0, 1);
							const Vector3 up(0, 1, 0), left = up.cross(fwd);
							const Vector3 grip = ba->get_global_transform().xform(nb.phone_base);   // (the fist's grip)
							const Vector3 at = grip + fb.xform(Vector3(-0.0756f, 0.03f, 0.0082f)) + up * (0.145f * 0.5f - 0.045f);   // (4.5 cm of it in the fist)
							nb.phone->set_global_transform(Transform3D(Basis(fwd, left, up).scaled(Vector3(nb.phone_k, nb.phone_k, nb.phone_k)), at));
						}
					}
				}
				{   // THE PHONE OF A CALL OR A TEXT (Yasin, 21 Nov: "bring phones to npcs too"): the same dark slab, in the hand nearer his
					// head for a call, in the hand held in front of his chest for a text, laid along the fingers
					const int ac = crowd->act[i];
					const int pm = ac == pc::A_CALL ? 1 : (ac == pc::A_PHONE ? (((crowd->look[i] >> 13) & 1u) ? 2 : 1) : 0);
					if (pm && !nb.phone2) {
						MeshInstance3D *m = memnew(MeshInstance3D);
						Ref<BoxMesh> bm; bm.instantiate(); bm->set_size(Vector3(0.009f, 0.07f, 0.145f));
						Ref<StandardMaterial3D> mat; mat.instantiate(); mat->set_albedo(Color(0.05f, 0.05f, 0.06f)); mat->set_roughness(0.35f); mat->set_metallic(0.3f);
						m->set_mesh(bm); m->set_material_override(mat); m->set_cast_shadows_setting(GeometryInstance3D::SHADOW_CASTING_SETTING_OFF);
						nb.ped->add_child(m); m->set_as_top_level(true); nb.phone2 = m;
					}
					if (nb.phone2) {
						bool show = pm != 0 && nb.ped->get_mode() == CityPed::MODE_ANIM;
						Skeleton3D *sk = nb.ped->skeleton();
						if (show && sk) {
							const int hl = sk->find_bone("Bip01_L_Hand"), hr = sk->find_bone("Bip01_R_Hand"), hd = sk->find_bone("Bip01_Head"), ch = sk->find_bone("Bip01_Spine2");
							if (hl >= 0 && hr >= 0 && hd >= 0 && ch >= 0) {
								const Transform3D sg = sk->get_global_transform();
								const Transform3D L = sg * sk->get_bone_global_pose(hl), R = sg * sk->get_bone_global_pose(hr);
								const Vector3 head = sg.xform(sk->get_bone_global_pose(hd).origin), chest = sg.xform(sk->get_bone_global_pose(ch).origin);
								Vector3 fwd = nb.ped->get_global_transform().basis.get_column(2); fwd.y = 0.0f; fwd = fwd.length() > 0.01f ? fwd.normalized() : Vector3(0, 0, 1);
								const Vector3 front = chest + fwd * 0.3f - Vector3(0, 0.1f, 0);
								const bool use_l = pm == 1 ? L.origin.distance_to(head) < R.origin.distance_to(head) : L.origin.distance_to(front) < R.origin.distance_to(front);
								const Transform3D H = use_l ? L : R;
								const Basis hb = H.basis.orthonormalized();
								const Vector3 along = hb.get_column(0).normalized(), side = hb.get_column(2).normalized();
								const Vector3 zc = along, yc = side, xc = yc.cross(zc).normalized();
								nb.phone2->set_global_transform(Transform3D(Basis(xc, yc, zc), H.origin + along * 0.075f));
							} else show = false;
						}
						nb.phone2->set_visible(show);
					}
				}
				// the feet on the real ground, planted ones pinned where they land (Yasin, 20 Nov: "i want them pixel perfect":
				// tests/people/trace_crowd.gd found walkers' planted feet sliding 0.24-0.36 m/s and feet 23 cm over the ground
				// or 3 cm in it where the crowd's path height and the ground differ); off while seated, on the ground, lying or
				// swimming, and while the figure fades in
				if (Skeleton3D *psk = nb.ped->skeleton()) {
					if (!nb.plant) { nb.plant = memnew(FootPlant); psk->add_child(nb.plant); }
					if (nb.plant_walker != nb.walker) { nb.plant->reset(); nb.plant_walker = nb.walker; }
					const String cn = String(clip);
					const bool on = sc > 0.9f && !cn.begins_with("ual/Sitting") && !cn.begins_with("ual/GroundSit") && !cn.contains("Lay") && !cn.begins_with("ual/Swim");
					nb.plant->set_active(false); nb.plant->set_influence(0.0f); (void)on;   /* (no foot plant: Mixamo's clips as they are, Yasin 21 Nov) */
					const float fy = lerp_angle(crowd->pyaw[i], crowd->yaw[i], a);
					nb.plant->fwd = Vector3(std::sin(fy), 0.0f, std::cos(fy));
				}
				// the last blow of a fight is a real one: the one who takes it is handed to his balancing body, which
				// staggers back or goes down, and gets up by itself (pushes and falls are never a clip)
				if (crowd->act[i] == pc::A_FIGHT && sc > 0.9f && nb.push_cd <= 0.0f && crowd->fwin[i] == 0 && crowd->pause_t[i] < 0.70f && crowd->pause_t[i] > 0.2f && l_fight_in > 0.0) {
					const int j = crowd->find(crowd->mate[i]);
					if (j >= 0) {
						Vector3 d(crowd->x[i] - crowd->x[j], 0, crowd->z[i] - crowd->z[j]);
						if (d.length() > 0.05f && d.length() < 2.5f) { nb.ped->push(d.normalized() * 80.0f, Vector3(crowd->x[i], crowd->y[i] + 1.25f, crowd->z[i])); nb.push_cd = 4.0f; nb.why = 2; fight_falls++; const Vector3 fat(crowd->x[i], crowd->y[i], crowd->z[i]); alarm(fat, 16.0f, 8.0f, 4); incident(fat, 4, false, nb.walker, 1); helpers_for(nb.walker, fat); }
					}
				}
			}
			feed_boxes(nb, i);
			for (size_t q = 0; q < thrown.size(); q++) {   // a cyclist who came off: the blow throws him (his balancing body from here on)
				if (thrown[q].walker != nb.walker) continue;
				nb.ped->launch(thrown[q].vel, thrown[q].imp, thrown[q].at + Vector3(0, 0.95f, 0));
				nb.push_cd = 2.5f; nb.why = 3; nb.after_kind = 0; nb.after_t = 0.0f;
				thrown.erase(thrown.begin() + (long)q);
				break;
			}
			// the player walks into it: a shove as hard as he comes
			if (pl && nb.push_cd <= 0.0f && sc > 0.9f) {
				const Vector3 pp = pl->get_global_position();
				const float dx = crowd->x[i] - pp.x, dz = crowd->z[i] - pp.z, d2 = dx * dx + dz * dz;
				const float vx = crowd->pl_vx, vz = crowd->pl_vz, sp = std::sqrt(vx * vx + vz * vz);
				if (d2 < 0.62f * 0.62f && sp > 1.2f && dx * vx + dz * vz > 0.0f) {
					nb.ped->push(Vector3(vx, 0, vz) * (35.0f + 18.0f * sp) / sp, Vector3(crowd->x[i], crowd->y[i] + 1.25f, crowd->z[i]));
					nb.push_cd = 1.5f; nb.why = 1; nb.after_kind = 0; nb.after_t = 0.0f;
				}
			}
		}
		if (nb.ped->get_mode() != CityPed::MODE_ANIM) {   // its body has it: the walker is where the body is
			if (nb.ped->get_mode() == CityPed::MODE_BODY) feed_boxes(nb, i);
			const Vector3 at = nb.ped->body_at();
			// its body took over by itself (no shove, fight or fall of ours set a why): a car reached it. Hit by a car going
			// faster than a walk, the street reacts.
			if (!nb.in_body && nb.why == 0) {
				float fast = 0.0f;
				const int nc = (int)cars.size() / 7;
				for (int c = 0; c < nc; c++) {
					const float *q = &cars[(size_t)c * 7];
					const float dx = q[0] - at.x, dz = q[1] - at.z;
					if (dx * dx + dz * dz > 6.0f * 6.0f) continue;
					fast = std::max(fast, std::sqrt(q[5] * q[5] + q[6] * q[6]));
				}
				nb.why = 5;
				if (fast > 2.5f) {
					cars_hit_people++; alarm(at, 30.0f, 12.0f, 2);
					// whose car: the player's if his is the one by him
					bool mine = false;
					if (Node3D *pc_n = car_id ? Object::cast_to<Node3D>(ObjectDB::get_instance(ObjectID(car_id))) : nullptr) mine = pc_n->get_global_position().distance_to(at) < 5.0f;
					// a hard knock (faster than 8 m/s, about 30 km/h) and he stays down until a medic has been
					const bool hard = fast > 8.0f;
					if (hard) stay_down(nb.walker, true);
					incident(at, 2, mine, nb.walker, hard ? 2 : 1);
					if (!is_actor(nb.walker)) helpers_for(nb.walker, at);
				}
			}
			crowd->to_body(nb.walker, true, at.x, at.z);
			nb.in_body = true;
		}
	}
	cnt.near += n_near;
}

void CityCrowd::_process(double p_delta) {
	pm::Scope _pm(pm::CROWD);   // (the slow-frame marks, perf_marks.h)
	if (!ready) return;
	const int64_t t0 = usec_now();
	step_brain(p_delta);
	actors_update(p_delta);
	if (Viewport *wv = get_viewport()) if (Camera3D *wc = wv->get_camera_3d()) if (get_world_3d().is_valid()) way_floor.update(wc->get_global_position(), get_world_3d()->get_space());
	{   // the traffic's cyclists who came off this frame: the rider is one of ours now, on the road where he fell
		CityTraffic *trf = traffic_id ? Object::cast_to<CityTraffic>(ObjectDB::get_instance(ObjectID(traffic_id))) : nullptr;
		if (trf && trf->is_inside_tree()) {
			const std::vector<float> &dn = trf->bikes_down_now();
			for (size_t k = 0; k + 8 < dn.size(); k += 9) {
				const uint32_t h = (uint32_t)dn[k + 7] * 2654435761u ^ 0x5bd1e995u;   // (who rode it: as the rider was drawn)
				const uint32_t female = (h >> 3) % 3u == 0u ? 1u : 0u;
				const uint32_t look = (h & ~8u) | (female << 3);
				const int w = crowd->place_held_at(dn[k], dn[k + 2], look, dn[k + 3]);
				if (w < 0) continue;
				const Vector3 f(std::sin(dn[k + 3]), 0.0f, std::cos(dn[k + 3]));
				const Vector3 bv = f * dn[k + 4], cv(dn[k + 5], 0.0f, dn[k + 6]);
				// the whole body leaves at the speed the blow gives it (his own and most of the car's), a small push at the hips
				// turns him over the bonnet's way (no kick upward: one part pushed with the whole body's momentum flew up)
				Vector3 vel = bv + (cv - bv) * 0.75f; vel.y = 0.0f;
				if (vel.length() > 9.0f) vel = vel.normalized() * 9.0f;
				// a car that comes into him fast scoops him up: his legs are taken, he goes onto the bonnet and over (the
				// same as the player thrown off his bicycle into a car: Yasin, "somersaulting to the other side of the car");
				// the car itself is a box to his body, so a slow knock only pushes him over
				const float rel = (cv - bv).length();
				if (rel > 4.0f) vel.y = std::min(0.35f * rel, 3.5f);
				const Vector3 imp = rel > 0.1f ? (cv - bv) / rel * (rel > 4.0f ? 70.0f : 40.0f) : Vector3();
				thrown.push_back(Thrown{ w, vel, imp, Vector3(dn[k], dn[k + 1], dn[k + 2]), 0.0f });
				riders_thrown++;
				alarm(Vector3(dn[k], dn[k + 1], dn[k + 2]), 30.0f, 10.0f, 3);
				if (rel > 6.0f) stay_down(w, true);   // (a hard one: he lies until a medic has been)
				incident(Vector3(dn[k], dn[k + 1], dn[k + 2]), 3, false, w, rel > 6.0f ? 2 : 1);
				helpers_for(w, Vector3(dn[k], dn[k + 1], dn[k + 2]));
			}
			// the drivers who got out of hit cars
			std::vector<CityTraffic::RageOut> ro;
			trf->take_rage(ro);
			std::vector<std::pair<uint32_t, int>> by_serial;
			for (const CityTraffic::RageOut &r : ro) {
				const uint32_t h = r.serial * 2246822519u ^ 0x27d4eb2fu;
				const int w = crowd->place_held_at(r.x, r.z, h & ~8u, r.yaw);
				if (w < 0) continue;
				by_serial.push_back({ r.serial, w });
				if (r.foe == -5) { driver_robbed(w); continue; }   // (his car was taken: he runs, city_crowd_actors.cpp)
				rages++;
				int foe = r.foe == -1 ? -1 : -3;
				if (r.foe >= 0) for (const auto &b : by_serial) if (b.first == r.foe_serial) foe = b.second;
				ragers.push_back(Rager{ w, 0.0f, foe });
			}
		}
	}
	rage_update(p_delta);
	player_fight(p_delta);
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

PackedVector2Array CityCrowd::map_lines(int p_kind) const {
	PackedVector2Array out;
	for (size_t k = 0; k < crowd->segs.size(); k++) {
		const pc::Seg &S = crowd->segs[k];
		if (S.kind != p_kind) continue;
		const int m = std::max(1, (int)(S.len / 6.0f));
		int h = 0; float x, y, z, tx, tz, px = 0, pz = 0;
		for (int q = 0; q <= m; q++) {
			crowd->at(S, S.len * (float)q / (float)m, 0.0f, h, x, y, z, tx, tz);
			if (q > 0) { out.push_back(Vector2(px, pz)); out.push_back(Vector2(x, z)); }
			px = x; pz = z;
		}
	}
	return out;
}

// The player's house on the in-game map / phone map. sub = 100 so HudMap can draw a
// Home pin instead of a shop letter. Path and fields: map_dc/coronado/city_kit/player_home.json.
static const int MAP_HOME_SUB = 100;
static const char *const PLAYER_HOME_JSON = "res://map_dc/coronado/city_kit/player_home.json";

static bool player_home_xz(float &x, float &z, String &name) {
	if (!FileAccess::file_exists(PLAYER_HOME_JSON)) return false;
	const Variant v = JSON::parse_string(FileAccess::get_file_as_string(PLAYER_HOME_JSON));
	if (v.get_type() != Variant::DICTIONARY) return false;
	const Dictionary d = v;
	if (!d.has("x") || !d.has("z")) return false;
	x = (float)(double)d["x"];
	z = (float)(double)d["z"];
	name = d.get("name", "Home");
	return true;
}

PackedVector3Array CityCrowd::map_rooms() const {
	PackedVector3Array out;
	for (const pc::Place &pl : crowd->places) if (pl.kind == pc::PL_SHOP) out.push_back(Vector3(pl.x, pl.z, (float)pl.sub));
	float hx = 0.0f, hz = 0.0f; String hn;
	if (player_home_xz(hx, hz, hn)) out.push_back(Vector3(hx, hz, (float)MAP_HOME_SUB));
	return out;
}

String CityCrowd::room_name(int p_i) const {
	int k = 0;
	for (const pc::Place &pl : crowd->places) {
		if (pl.kind != pc::PL_SHOP) continue;
		if (k++ != p_i) continue;
		if (pl.name >= 0 && pl.name < (int)crowd->place_names.size()) return String::utf8(crowd->place_names[pl.name].c_str());
		return String(pl.sub < pc::N_SHOP_KINDS ? pc::SHOP_KINDS[pl.sub] : "shop").capitalize();
	}
	if (p_i == k) {
		float hx = 0.0f, hz = 0.0f; String hn;
		if (player_home_xz(hx, hz, hn)) return hn.is_empty() ? String("Home") : hn;
	}
	return String();
}

PackedVector3Array CityCrowd::walk_points(double p_step) const {
	PackedVector3Array out;
	const float step = std::max((float)p_step, 0.25f);
	for (size_t k = 0; k < crowd->segs.size(); k++) {
		const pc::Seg &S = crowd->segs[k];
		const int m = std::max(1, (int)(S.len / step));
		int h = 0; float x, y, z, tx, tz;
		for (int q = 0; q <= m; q++) { crowd->at(S, S.len * (float)q / (float)m, 0.0f, h, x, y, z, tx, tz); out.push_back(Vector3(x, y, z)); }
	}
	return out;
}

Dictionary CityCrowd::walk_points_across(double p_step, double p_across, double p_margin) const {
	PackedVector3Array out; PackedByteArray kinds;
	const float step = std::max((float)p_step, 0.25f), across = std::max((float)p_across, 0.1f);
	for (size_t k = 0; k < crowd->segs.size(); k++) {
		const pc::Seg &S = crowd->segs[k];
		const float half = std::max(S.hw - (float)p_margin, 0.0f);
		const int m = std::max(1, (int)(S.len / step)), na = std::max(1, (int)std::ceil(2.0f * half / across));
		int h = 0; float x, y, z, tx, tz;
		for (int q = 0; q <= m; q++)
			for (int a = 0; a <= na; a++) {
				crowd->at(S, S.len * (float)q / (float)m, -half + 2.0f * half * (float)a / (float)na, h, x, y, z, tx, tz);
				out.push_back(Vector3(x, y, z)); kinds.push_back((uint8_t)(S.kind == 1 ? 1 : 0));
			}
	}
	Dictionary d; d["points"] = out; d["kinds"] = kinds;
	return d;
}

Dictionary CityCrowd::pavement_near(const Vector3 &p_at, double p_max_d) const {
	Dictionary d; d["ok"] = false;
	float su = 0, dd = 0, ax = 0, az = 0, ay = 0;
	const int k = crowd->nearest_walk(p_at.x, p_at.z, (float)p_max_d, su, dd, ax, az, ay);
	if (k < 0) return d;
	int h = 0; float x, y, z, tx, tz;
	crowd->at(crowd->segs[k], su, 0.0f, h, x, y, z, tx, tz);
	d["ok"] = true; d["at"] = Vector3(x, y, z); d["yaw"] = std::atan2(tx, tz);
	d["half_width"] = crowd->segs[k].hw;
	d["side"] = Vector3(tz, 0, -tx);   // (left of the way it runs; which side the road is on is the caller's to try)
	return d;
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

// The sea's depth map (the test app's own: 8 m a texel, red = depth / deep, green = there is water). The sea's surface
// is at sea_y. Without the map nobody swims.
void CityCrowd::load_sea() {
	sea_d.clear();
	const String meta_path = sea_path.get_basename() + String(".json");
	if (sea_path.is_empty() || !FileAccess::file_exists(meta_path)) return;
	const Variant mv = JSON::parse_string(FileAccess::get_file_as_string(meta_path));
	if (mv.get_type() != Variant::DICTIONARY) return;
	Ref<Image> img;
	if (ResourceLoader::get_singleton()->exists(sea_path)) { Ref<Texture2D> t = ResourceLoader::get_singleton()->load(sea_path); if (t.is_valid()) img = t->get_image(); }
	if (img.is_null() && FileAccess::file_exists(sea_path)) img = Image::load_from_file(sea_path);
	if (img.is_null() || img->is_empty()) return;
	if (img->is_compressed()) img->decompress();
	const Dictionary meta = mv;
	sea_x0 = meta.get("x0", 0.0); sea_z0 = meta.get("z0", 0.0); sea_step = meta.get("step", 8.0);
	const float deep = meta.get("deep", 20.0);
	sea_w = img->get_width(); sea_h = img->get_height();
	sea_d.resize((size_t)sea_w * sea_h);
	for (int z = 0; z < sea_h; z++) for (int x = 0; x < sea_w; x++) {
		const Color c = img->get_pixel(x, z);
		sea_d[(size_t)z * sea_w + x] = c.g > 0.5f ? c.r * deep : 0.0f;
	}
}

float CityCrowd::sea_depth(float p_x, float p_z) const {
	if (sea_d.empty()) return 0.0f;
	const float fx = (p_x - sea_x0) / sea_step, fz = (p_z - sea_z0) / sea_step;
	const int ix = (int)std::floor(fx), iz = (int)std::floor(fz);
	if (ix < 0 || iz < 0 || ix >= sea_w - 1 || iz >= sea_h - 1) return 0.0f;
	const float ax = fx - (float)ix, az = fz - (float)iz;
	const float *q = &sea_d[(size_t)iz * sea_w + ix];
	return (q[0] * (1.0f - ax) + q[1] * ax) * (1.0f - az) + (q[sea_w] * (1.0f - ax) + q[sea_w + 1] * ax) * az;
}

Array CityCrowd::near_bodies() const {
	Array out;
	for (const Near &nb : near_pool) {
		if (nb.walker < 0) continue;
		Dictionary d;
		d["walker"] = nb.walker; d["woman"] = nb.female != 0; d["clip"] = String(nb.ped->current_clip()); d["in_physical_body"] = nb.in_body; d["shown_s"] = nb.act_t; d["figure_mode"] = (int)nb.ped->get_mode(); d["body_id"] = nb.ped->get_body(); d["at"] = nb.ped->body_at(); d["body"] = nb.ped->get_state();
		const bool planted = nb.plant && nb.plant->is_active();   // (as drawn: after the foot plant, read inside it)
		d["foot_l"] = planted ? nb.plant->foot_w[0] : nb.ped->bone_world("Bip01_L_Foot"); d["foot_r"] = planted ? nb.plant->foot_w[1] : nb.ped->bone_world("Bip01_R_Foot");
		d["pelvis"] = planted ? nb.plant->pelvis_w : nb.ped->bone_world("Bip01_Pelvis"); d["planted"] = planted;
		if (nb.plant) { d["gap_mean"] = nb.plant->gap_n ? nb.plant->gap_sum / nb.plant->gap_n : 0.0f; d["gap_most"] = nb.plant->gap_most; d["gaps"] = nb.plant->gap_n; d["gaps_by_lift"] = nb.plant->gap_by_lift; }
		d["hand_l"] = nb.ped->bone_world("Bip01_L_Hand"); d["hand_r"] = nb.ped->bone_world("Bip01_R_Hand"); d["v"] = nb.v_s;
		{ const int i = crowd->find(nb.walker); d["act"] = i >= 0 ? (int)crowd->act[i] : -1; d["mode"] = i >= 0 ? (int)crowd->mode[i] : -1; d["ground"] = i >= 0 ? crowd->y[i] : 0.0f; }
		out.push_back(d);
	}
	return out;
}

void CityCrowd::end_fight(bool p_release) {
	if (pf.walker >= 0 && p_release) {
		const int i = crowd->find(pf.walker);
		if (i >= 0 && crowd->mode[i] == pc::M_HELD) { crowd->to_body(pf.walker, true, crowd->x[i], crowd->z[i]); crowd->to_body(pf.walker, false, crowd->x[i], crowd->z[i]); }   // (he walks back to the pavement)
	}
	CityPlayer *pl = player_id ? Object::cast_to<CityPlayer>(ObjectDB::get_instance(ObjectID(player_id))) : nullptr;
	if (pl) pl->set_combat(false, Vector3());
	pf.walker = -1; pf.angry = false; pf.st = 0; pf.punch_in = -1.0f;
}

void CityCrowd::player_fight(double p_delta) {
	CityPlayer *pl = player_id ? Object::cast_to<CityPlayer>(ObjectDB::get_instance(ObjectID(player_id))) : nullptr;
	if (!pl || !pl->is_inside_tree()) { if (pf.walker >= 0) end_fight(true); return; }
	const float dt = (float)p_delta;
	CityPed *pfig = pl->figure();
	car_hit_cd = std::max(car_hit_cd - dt, 0.0f);
	if (pfig) {   // the cars near him, as the people feel them (his body rolls on a bonnet and slides off it)
		const Vector3 me = pfig->body_at();
		int k = 0;
		const int nc = (int)cars.size() / 7;
		for (int c = 0; c < nc && k + 2 <= pb::MAX_BOXES; c++) {
			const float *q = &cars[(size_t)c * 7];
			const float dx = q[0] - me.x, dz = q[1] - me.z;
			if (dx * dx + dz * dz > 81.0f) continue;
			k = car_boxes(pfig, k, q, pl->get_global_position().y);
		}
		if (k == 0) pfig->set_box(-1, Vector3(), Vector3(), 0.0, Vector3(), 0);
	}
	if (pf.player_down) {   // beaten (or run over): he lies until his body has him up again
		// (and not before he has been down: his figure goes over to its balancing body a frame after knock_down, and that
		// frame it was still animated, so a car's hit let him go at once and he stood where he was: car_hit_cd)
		if (pfig && pfig->get_mode() == CityPed::MODE_ANIM && car_hit_cd <= 0.0f) { pf.player_down = false; pl->set_frozen(false); }
		pl->take_combat_request();
		return;
	}
	// RUN OVER (Yasin, 20 Nov: "i got run over by cars several times while playing"; nothing showed it): a car that
	// reaches the player on foot at speed knocks him down (his balancing body, as when he is beaten; he gets up and
	// has his body back); a slow one bumps him (the hit clip and a push)
	if (pfig && pl->is_visible_in_tree() && car_hit_cd <= 0.0f && pfig->get_mode() == CityPed::MODE_ANIM) {
		const Vector3 me = pl->get_global_position();
		const int nc = (int)cars.size() / 7;
		for (int c = 0; c < nc; c++) {
			const float *q = &cars[(size_t)c * 7];
			const float dx = me.x - q[0], dz = me.z - q[1];
			if (dx * dx + dz * dz > 36.0f) continue;
			const float hx = std::sin(q[2]), hz = std::cos(q[2]);
			const float along = dx * hx + dz * hz, across = dx * hz - dz * hx;
			if (std::fabs(along) > q[3] + 0.3f || std::fabs(across) > q[4] + 0.3f) continue;
			const Vector3 cv(q[5], 0.0f, q[6]);
			const float sp = cv.length();
			if (sp < 0.8f) continue;
			const Vector3 dir = cv / sp;
			if (sp > 2.5f) {   // knocked down and thrown with the car's speed
				// (his legs swept at the knees, only a little speed of his own: the car's bonnet does the rest, he goes up onto
				// it and is carried, and slides off; launched at the car's speed he flew on ahead of it)
				pfig->knock_down(dir * std::min(sp * 0.3f, 4.0f) + Vector3(0, 0.6f, 0), dir * std::min(sp * 9.0f, 90.0f), me + Vector3(0, 0.45f, 0));
				pf.player_down = true; pl->set_frozen(true);
				if (pf.walker >= 0) end_fight(true);
			} else { pl->take_hit(); pl->knock(dir * (sp + 1.0f)); }
			cars_hit_player++; car_hit_cd = 1.5f; car_hit_v = sp;
			break;
		}
	}
	const Vector3 pp = pl->get_global_position();
	if (pl->take_combat_request()) {
		if (pf.walker >= 0) { end_fight(true); return; }   // (asked again: he lets it go)
		int best = -1; float bd = 10.0f * 10.0f;
		for (int i = 0; i < crowd->hi; i++) {
			if (!crowd->alive[i] || (crowd->flags[i] & pc::F_HIDDEN) || (crowd->mode[i] != pc::M_LINE && crowd->mode[i] != pc::M_STAY && crowd->mode[i] != pc::M_HELD) || crowd->act[i] == pc::A_FIGHT) continue;
			if (crowd->pkind[i] == pc::PK_FAMILY && crowd->slot[i] >= 2) continue;   // (never a child)
			const float dx = crowd->x[i] - pp.x, dz = crowd->z[i] - pp.z, d2 = dx * dx + dz * dz;
			if (d2 < bd) { bd = d2; best = i; }
		}
		if (best < 0) {   // nobody near: he still takes his guard, facing ahead (B20: Yasin could not get into combat to try it); asked again, he drops it
			if (pl->get_combat()) pl->set_combat(false, Vector3());
			else { const float yaw = (float)(double)pl->get_view()[0]; pl->set_combat(true, pp + Vector3(std::sin(yaw), 0.0f, std::cos(yaw)) * 3.0f); }
			return;
		}
		const int keep = pf.locks + 1;
		pf = PFight(); pf.locks = keep;
		pf.walker = crowd->id[best];
		pl->set_combat(true, Vector3(crowd->x[best], crowd->y[best], crowd->z[best]));
	}
	if (pf.walker < 0) return;
	const int i = crowd->find(pf.walker);
	if (i < 0) { end_fight(false); return; }
	Near *nb = nullptr;
	for (Near &n : near_pool) if (n.walker == pf.walker) nb = &n;
	Vector3 at(crowd->x[i], crowd->y[i], crowd->z[i]);
	if (nb && nb->ped->get_mode() != CityPed::MODE_ANIM) at = nb->ped->body_at();
	Vector3 to = at - pp; to.y = 0.0f;
	const float dist = to.length();
	if (dist > 25.0f) { end_fight(true); return; }
	pl->set_combat(true, at);
	const Vector3 dir = dist > 0.01f ? to / dist : Vector3(0, 0, 1);
	// his punch lands a quarter of a second in, if the other is in reach before him and not getting out of the way
	if (const int side = pl->take_punch()) {
		pf.punch_in = 0.25f; (void)side;
		// once he fights, he may see it coming and step aside (it misses)
		if (pf.angry && pf.st == 0 && (!nb || nb->ped->get_mode() == CityPed::MODE_ANIM) && UtilityFunctions::randf() < 0.35) {
			pf.st = 2; pf.st_t = 0.0f; pf.dodges++; pf.dodge_dir = UtilityFunctions::randf() < 0.5 ? 1 : -1;
		}
	}
	if (pf.punch_in >= 0.0f) {
		pf.punch_in -= dt;
		if (pf.punch_in < 0.0f) {
			const float fy = pl->get_global_rotation().y;
			const Vector3 face(std::sin(fy), 0.0f, std::cos(fy));
			const bool in_reach = dist < 1.35f && (pfig ? true : face.dot(dir) > 0.6f) && pf.st != 2;
			// (28 Nov night: made in the next physics step, CityCrowd::_physics_process: the damage system's sweep needs the world)
			strike_due = true; strike_a = pp + Vector3(0, 1.35f, 0); strike_b = strike_a + face * 0.85f; strike_by = pl->get_instance_id();   // TEMP(damage B, 25 Nov): melee test until the traversal lab's strike() arrives - remove then (WORLD_CONTRACT.md 6)
			if (in_reach) {
				pf.landed++; pf.hp--;
				if (!pf.angry) { pf.angry = true; pf.ai_t = 0.5f; pf.st = 0; }   // (from the first blow he fights)
				// a blow staggers him (a push at the head, light); the last one drops him as a whole body with its weight: the
				// body leaves backwards at 2.8 m/s and a small push at the head tips it over (Yasin: "let them fall to ground
				// ragdolling, but not weightlessly"; one part pushed with the whole body's momentum flies like a kite)
				// an ordinary blow: he takes it on his feet (the hit clips, as in the crowd's own fights) and stays in the fight;
				// the last one drops him as a whole body with its weight (the balancing body, falling: it does not catch itself)
				if (pf.hp <= 0) { if (nb) { nb->ped->knock_down(dir * 2.8f, dir * 45.0f, at + Vector3(0, 1.55f, 0)); nb->push_cd = 1.0f; nb->why = 4; } }
				// the street sees the player hit him: a blow, and harder when he goes down (the same spot within 3 s is one alarm,
				// so the knock-down after a blow makes nobody new react; the fight itself goes on)
				else { pf.st = 4; pf.st_t = 0.0f; pf.ai_t = 0.25f; }
				alarm(at, pf.hp <= 0 ? 30.0f : 22.0f, pf.hp <= 0 ? 12.0f : 8.0f, 1);
				incident(at, 1, true, pf.walker, pf.hp <= 0 ? 1 : 0);
				// a brave man near by may come to the victim's aid (the old games: "men may step in"): one in four first blows
				if (pf.landed == 1) {
					for (int j = 0; j < crowd->hi; j++) {
						if (!crowd->alive[j] || crowd->id[j] == pf.walker || crowd->mode[j] != pc::M_LINE || crowd->party[j] != 0 || (crowd->flags[j] & (pc::F_SCRIPT | pc::F_HIDDEN))) continue;
						if (((crowd->look[j] >> 3) & 1u) != 0u || (crowd->look[j] >> 24) % 4u != 0u) continue;   // (a man, one in four)
						const float bx = crowd->x[j] - at.x, bz = crowd->z[j] - at.z;
						if (bx * bx + bz * bz > 14.0f * 14.0f || is_actor(crowd->id[j])) continue;
						if (!crowd->hold(crowd->id[j], true, std::atan2(pp.x - crowd->x[j], pp.z - crowd->z[j]))) continue;
						Rager rg{ crowd->id[j], 1.2f, -1 }; ragers.push_back(rg); rages++; steps_in++;
						break;
					}
				}
				if (pf.hp <= 0) helpers_for(pf.walker, at);
				if (pf.hp <= 0) { pf.npc_beaten++; crowd->hurt_t[i] = 40.0f; end_fight(false); return; }   // (down by his body; he gets up and walks off hurt)
			} else pf.missed++;
		}
	}
	if (!pf.angry) return;   // (until he is hit he goes on with his day)
	if (crowd->mode[i] == pc::M_LINE || crowd->mode[i] == pc::M_STAY) crowd->hold(pf.walker, true, std::atan2(-dir.x, -dir.z));
	else crowd->face_yaw[i] = std::atan2(-dir.x, -dir.z);
	if (nb && nb->ped->get_mode() != CityPed::MODE_ANIM) { pf.ai_t = std::min(pf.ai_t, 0.3f); return; }   // (staggering from a blow: nothing else; then he answers at once)
	pf.st_t += dt; pf.ai_t -= dt; pf.in_t += dt;
	if (pf.st == 1) {   // his blow lands at 0.32 s if the player is in reach
		if (!pf.hit_done && pf.st_t > 0.32f) {
			pf.hit_done = true;
			if (dist < 1.45f) {
				pf.hits_on_player++; pf.php--;
				if (pf.php <= 0) { if (pfig) pfig->knock_down(-dir * 2.8f, -dir * 45.0f, pp + Vector3(0, 1.55f, 0)); }
				else pl->take_hit();   // (on his feet: the hit clip)
				if (pf.php <= 0) {   // the player is beaten: down, still, until his body has him up; the other walks off
					pf.player_beaten++; pf.player_down = true; pl->set_frozen(true);
					end_fight(true);
					return;
				}
			}
		}
		if (pf.st_t > 0.65f) { pf.st = 0; pf.st_t = 0.0f; }
	} else if (pf.st == 4) {   // taking a blow
		if (pf.st_t > 0.45f) { pf.st = 0; pf.st_t = 0.0f; }
	} else if (pf.st == 2) {   // a step to the side, out of the way
		if (crowd->mode[i] == pc::M_HELD) {
			const Vector3 side(dir.z * (float)pf.dodge_dir, 0.0f, -dir.x * (float)pf.dodge_dir);
			crowd->shift_held(i, crowd->x[i] + side.x * 1.8f * dt, crowd->z[i] + side.z * 1.8f * dt);
		}
		if (pf.st_t > 0.55f) { pf.st = 0; pf.st_t = 0.0f; }
	} else if (pf.st == 3) {   // in to reach
		if (crowd->mode[i] == pc::M_HELD) crowd->shift_held(i, crowd->x[i] - dir.x * 1.3f * dt, crowd->z[i] - dir.z * 1.3f * dt);
		if (dist < 1.15f || pf.st_t > 2.0f) { pf.st = 0; pf.st_t = 0.0f; }
	} else if (pf.ai_t <= 0.0f) {   // his guard: what next
		const float r = (float)(UtilityFunctions::randf());
		pf.st_t = 0.0f; pf.hit_done = false;
		if (dist > 1.5f) pf.st = 3;
		else if (r < 0.55f) { pf.st = 1; pf.attacks++; }
		else if (r < 0.85f) { pf.st = 2; pf.dodges++; pf.dodge_dir = UtilityFunctions::randf() < 0.5 ? 1 : -1; }
		pf.ai_t = 0.7f + (float)UtilityFunctions::randf() * 0.8f;
	}
}

void CityCrowd::rage_update(double p_delta) {
	if (ragers.empty()) return;
	CityPlayer *pl = player_id ? Object::cast_to<CityPlayer>(ObjectDB::get_instance(ObjectID(player_id))) : nullptr;
	Camera3D *cam = get_viewport() ? get_viewport()->get_camera_3d() : nullptr;
	const float T_YELL = 3.4f;
	for (size_t k = 0; k < ragers.size();) {
		Rager &r = ragers[k];
		r.t += (float)p_delta;
		const int i = crowd->find(r.walker);
		if (i < 0 || r.t > 60.0f) {   // gone, or a minute without the one he wants: he calms down and walks off
			if (i >= 0) crowd->hold(r.walker, false, 0.0f);
			ragers.erase(ragers.begin() + k); continue;
		}
		const Vector3 at(crowd->x[i], crowd->y[i], crowd->z[i]);
		Vector3 to;
		bool has = false;
		if (r.foe == -1 && pl && pl->is_inside_tree()) { to = pl->get_global_position(); has = true; }
		else if (r.foe >= 0) { const int j = crowd->find(r.foe); if (j >= 0) { to = Vector3(crowd->x[j], crowd->y[j], crowd->z[j]); has = true; } }
		if (has) crowd->hold(r.walker, true, std::atan2(to.x - at.x, to.z - at.z));   // (locked on the one who hit him from the first moment: Yasin, "they should lock into us or their aggressor as soon as the crash happens")
		if (r.t < T_YELL) { k++; continue; }
		if (r.foe == -1) {
			const bool on_foot = pl && pl->is_visible_in_tree() && !pl->is_frozen();
			Vector3 d = to - at; d.y = 0.0f;
			const float dist = d.length();
			if (!on_foot) {   // in his car: he yells by it; a hit and run (driven 60 m off) and he gives up after a while
				r.chase = false;
				r.away_t = dist > 60.0f ? r.away_t + (float)p_delta : 0.0f; r.dist = dist;
				if (r.away_t > 4.0f) { crowd->hold(r.walker, false, 0.0f); rage_given_up++; ragers.erase(ragers.begin() + k); continue; }
				k++; continue;
			}
			// on foot: he runs after him (seen on screen or within 40 m); the fight starts when he reaches him
			const bool seen = cam && cam->is_position_in_frustum(at + Vector3(0, 1.0f, 0));
			if (!r.chase && (seen || dist < 40.0f)) { r.chase = true; r.chase_t = 0.0f; rage_chases++; }
			if (r.chase) r.chase_t += (float)p_delta;
			if (r.chase && r.arrive_t < 0.0f && dist < 2.2f) r.arrive_t = 0.0f;   // reached him: the run's end (Sprint_Exit)
			if (r.arrive_t >= 0.0f) r.arrive_t += (float)p_delta;
			if (r.chase && r.arrive_t < 0.0f && dist > 1.6f && crowd->mode[i] == pc::M_HELD) {
				// (into the run: slower while Sprint_Enter plays)
				const float sp = r.chase_t < 0.5f ? 1.5f + 6.0f * r.chase_t : 4.6f;
				const float step = std::min(sp * (float)p_delta, dist - 1.4f);
				crowd->shift_held(i, crowd->x[i] + d.x / dist * step, crowd->z[i] + d.z / dist * step);
			}
			if (r.arrive_t > 0.45f && pf.walker < 0) {   // (Yasin: "whenever there is an aggressor in the screen, we should get into the combat mode")
				const int keep = pf.locks + 1;
				pf = PFight(); pf.locks = keep;
				pf.walker = r.walker; pf.angry = true; pf.ai_t = 0.3f;
				pl->set_combat(true, at);
				rage_fights++;
				ragers.erase(ragers.begin() + k); continue;
			}
			if (r.chase && dist > 80.0f) { crowd->hold(r.walker, false, 0.0f); rage_given_up++; ragers.erase(ragers.begin() + k); continue; }   // (he got away)
			k++; continue;
		}
		if (r.foe >= 0) {   // the other driver: the two come to blows
			if (crowd->fight(r.walker, r.foe)) {
				rage_npc_fights++;
				for (size_t q = 0; q < ragers.size(); q++) if (ragers[q].walker == r.foe) { ragers.erase(ragers.begin() + q); if (q < k) k--; break; }
				ragers.erase(ragers.begin() + k); continue;
			}
		}
		if (r.foe == -3 && r.t > 8.0f) { ragers.erase(ragers.begin() + k); continue; }   // (the one who hit: his part is over)
		k++;
	}
}

Dictionary CityCrowd::fight_stats() const {
	Dictionary d;
	d["walker"] = pf.walker; d["npc_health"] = pf.hp; d["player_health"] = pf.php; d["angry"] = pf.angry; d["state"] = pf.st;
	d["landed"] = pf.landed; d["missed"] = pf.missed; d["attacks"] = pf.attacks; d["hits_on_player"] = pf.hits_on_player; d["dodges"] = pf.dodges;
	d["npc_beaten"] = pf.npc_beaten; d["player_beaten"] = pf.player_beaten; d["locks"] = pf.locks; d["player_down"] = pf.player_down;
	d["rages"] = rages; d["rage_fights"] = rage_fights; d["rage_npc_fights"] = rage_npc_fights; d["rage_chases"] = rage_chases; d["rage_given_up"] = rage_given_up;
	Array rg; for (const Rager &r : ragers) { Dictionary e; e["walker"] = r.walker; e["t"] = r.t; e["foe"] = r.foe; e["chase"] = r.chase; e["dist"] = r.dist; e["away_t"] = r.away_t; rg.push_back(e); }
	d["ragers"] = rg;
	return d;
}

Dictionary CityCrowd::stats() const {
	Dictionary d;
	{ int on = 0; for (int k = 0; k < CAPSULES; k++) on += cap_on[k] ? 1 : 0; d["capsules_on"] = on; d["capsule_steps"] = cap_steps; d["extras"] = extras; d["has_player"] = crowd->has_player; }
	const pc::Stats &s = crowd->st;
	int r[7];
	crowd->audit(own_clock, r);
	d["people"] = crowd->n_alive; d["places"] = (int)crowd->places.size(); d["hour"] = hour; d["weekday"] = weekday;
	d["riders"] = riders_drawn; d["riders_near"] = riders_near; d["riders_miss"] = riders_miss; d["riders_miss_hand"] = riders_miss_hand; d["riders_limbs"] = riders_limbs; d["riders_thrown"] = riders_thrown; d["riders_given_a_body"] = riders_bodied;
	d["inside_each_other"] = r[0]; d["beside_pavement"] = r[1]; d["standing_a_minute"] = r[3]; d["bad_numbers"] = r[4];
	d["spawned"] = s.spawned; d["left"] = s.despawned; d["arrivals"] = s.arrivals; d["went_in"] = s.went_in; d["came_out"] = s.came_out; d["sat"] = s.sat; d["crossings"] = s.crossings;
	d["groups"] = s.parties; d["meetings"] = s.meetings; d["dodges"] = s.dodges; d["fled"] = s.fled; d["bumps"] = s.bumps;
	d["bodies"] = (int)bodies.size(); d["drawn"] = shown;
	int nn = 0, nbdy = 0;
	for (const Near &nb : near_pool) { if (nb.walker >= 0) nn++; if (nb.in_body) nbdy++; }
	d["near_bodies"] = nn; d["near_pool"] = (int)near_pool.size(); d["in_physical_body"] = nbdy; d["umbrellas"] = prop_shown[0]; d["towels"] = prop_shown[1];
	d["alarms_player_hit"] = alarms[1]; d["alarms_car_hit"] = alarms[2]; d["alarms_bike_down"] = alarms[3]; d["alarms_npc_fight"] = alarms[4]; d["cars_hit_people"] = cars_hit_people;
	d["helpers_sent"] = helpers_sent; d["helpers_knelt"] = helpers_knelt; d["steps_in"] = steps_in; d["actors"] = (int)actors.size(); d["downs"] = (int)downs.size();
	d["cowering"] = cowering; d["shots_heard"] = shots_heard; d["drivers_robbed"] = drivers_robbed; d["alarms_shot"] = alarms[5]; d["alarms_mugging"] = alarms[6]; d["alarms_car_taken"] = alarms[7];
	d["cars_hit_player"] = cars_hit_player; d["car_hit_v"] = car_hit_v; d["player_down_now"] = pf.player_down;
	d["ducked"] = s.ducks; d["stared"] = s.stared; d["coins"] = s.coins; d["lines_said"] = s.lines_said;
	{ PackedFloat32Array cl; const double ls[11] = { l_sit_in, l_sit_out, l_gsit_in, l_gsit_out, l_lie_in, l_lie_out, l_duck_in, l_duck_out, l_fight_in, l_fight_out, l_surprise }; for (double l : ls) cl.push_back((float)l); d["clip_seconds"] = cl; }   // into and out of: a seat, the ground, lying, a crouch, a fight; the start
	d["shoved_by_player"] = n_shoved; d["told_him_off"] = n_told_off; d["hit_back"] = n_hit_back;
	d["fights"] = s.fights; d["fight_blows_landed"] = fight_falls;
	d["bus_waits"] = s.bus_waits; d["boarded"] = s.boarded; d["alighted"] = s.alighted; d["buses_served"] = buses_served;
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
	ClassDB::bind_method(D_METHOD("actor_take", "walker", "role"), &CityCrowd::actor_take);
	ClassDB::bind_method(D_METHOD("actor_place", "at", "tag", "yaw", "role"), &CityCrowd::actor_place);
	ClassDB::bind_method(D_METHOD("actor_go", "walker", "to", "speed", "near"), &CityCrowd::actor_go);
	ClassDB::bind_method(D_METHOD("actor_follow", "walker", "target", "speed", "near"), &CityCrowd::actor_follow);
	ClassDB::bind_method(D_METHOD("actor_stand", "walker", "yaw", "clip", "hold", "token"), &CityCrowd::actor_stand);
	ClassDB::bind_method(D_METHOD("actor_arrived", "walker"), &CityCrowd::actor_arrived);
	ClassDB::bind_method(D_METHOD("is_actor", "walker"), &CityCrowd::is_actor);
	ClassDB::bind_method(D_METHOD("actor_role", "walker"), &CityCrowd::actor_role);
	ClassDB::bind_method(D_METHOD("actor_release", "walker"), &CityCrowd::actor_release);
	ClassDB::bind_method(D_METHOD("actor_free", "walker"), &CityCrowd::actor_free);
	ClassDB::bind_method(D_METHOD("actor_seat", "walker", "floor_y", "yaw", "clip"), &CityCrowd::actor_seat);
	ClassDB::bind_method(D_METHOD("talkable_actor", "walker"), &CityCrowd::talkable_actor);
	ClassDB::bind_method(D_METHOD("talk_hold", "walker", "on", "yaw"), &CityCrowd::talk_hold);
	ClassDB::bind_method(D_METHOD("walker_at", "walker"), &CityCrowd::walker_at);
	ClassDB::bind_method(D_METHOD("walker_alive", "walker"), &CityCrowd::walker_alive);
	ClassDB::bind_method(D_METHOD("is_down", "walker"), &CityCrowd::is_down);
	ClassDB::bind_method(D_METHOD("treat", "walker"), &CityCrowd::treat);
	ClassDB::bind_method(D_METHOD("set_cpr", "walker", "on"), &CityCrowd::set_cpr);
	ClassDB::bind_method(D_METHOD("downs_list"), &CityCrowd::downs_list);
	ClassDB::bind_method(D_METHOD("take_incidents"), &CityCrowd::take_incidents);
	ClassDB::bind_method(D_METHOD("gun_aimed", "from", "dir", "seconds"), &CityCrowd::gun_aimed);
	ClassDB::bind_method(D_METHOD("gunshot", "at", "by_player"), &CityCrowd::gunshot);
	ClassDB::bind_method(D_METHOD("knock_down_walker", "walker"), &CityCrowd::knock_down_walker);
	ClassDB::bind_method(D_METHOD("set_traffic", "traffic"), &CityCrowd::set_traffic);
	ClassDB::bind_method(D_METHOD("attach", "streamer"), &CityCrowd::attach);
	ClassDB::bind_method(D_METHOD("_on_cell_in", "key"), &CityCrowd::_on_cell_in);
	ClassDB::bind_method(D_METHOD("_on_cell_out", "key"), &CityCrowd::_on_cell_out);
	ClassDB::bind_method(D_METHOD("set_player", "player"), &CityCrowd::set_player);
	ClassDB::bind_method(D_METHOD("set_player_car", "car", "half_length", "half_width"), &CityCrowd::set_player_car);
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
#ifdef TRAV_IN_GAME
	ClassDB::bind_method(D_METHOD("set_trav_people", "on"), &CityCrowd::set_trav_people);
	ClassDB::bind_method(D_METHOD("get_trav_people"), &CityCrowd::get_trav_people);
#endif
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
	ClassDB::bind_method(D_METHOD("pavement_near", "at", "max_d"), &CityCrowd::pavement_near);
	ClassDB::bind_method(D_METHOD("walk_points", "step"), &CityCrowd::walk_points);
	ClassDB::bind_method(D_METHOD("walk_points_across", "step", "across", "margin"), &CityCrowd::walk_points_across);
	ClassDB::bind_method(D_METHOD("fight_stats"), &CityCrowd::fight_stats);
	ClassDB::bind_method(D_METHOD("map_lines", "kind"), &CityCrowd::map_lines);
	ClassDB::bind_method(D_METHOD("map_rooms"), &CityCrowd::map_rooms);
	ClassDB::bind_method(D_METHOD("room_name", "i"), &CityCrowd::room_name);
	ClassDB::bind_method(D_METHOD("remove_walker", "id"), &CityCrowd::remove_walker);
	ClassDB::bind_method(D_METHOD("set_goal", "id", "place", "stay_s", "enter"), &CityCrowd::set_goal);
	ClassDB::bind_method(D_METHOD("set_goal_point", "id", "at", "stay_s"), &CityCrowd::set_goal_point);
	ClassDB::bind_method(D_METHOD("stay", "id", "seconds"), &CityCrowd::stay);
	ClassDB::bind_method(D_METHOD("set_act", "id", "act", "seconds"), &CityCrowd::set_act);
	ClassDB::bind_method(D_METHOD("hold", "id", "on", "yaw"), &CityCrowd::hold);
	ClassDB::bind_method(D_METHOD("hide", "id", "on"), &CityCrowd::hide);
	ClassDB::bind_method(D_METHOD("to_body", "id", "on", "at"), &CityCrowd::to_body);
	ClassDB::bind_method(D_METHOD("scare", "at", "radius", "seconds"), &CityCrowd::scare);
	ClassDB::bind_method(D_METHOD("bus_at", "place", "on", "door", "get_off"), &CityCrowd::bus_at);
	ClassDB::bind_method(D_METHOD("bench_off", "place", "off"), &CityCrowd::bench_off);
	ClassDB::bind_method(D_METHOD("place_near", "at", "kind", "radius"), &CityCrowd::place_near);
	ClassDB::bind_method(D_METHOD("place_info", "place"), &CityCrowd::place_info);
	ClassDB::bind_method(D_METHOD("fight", "a", "b"), &CityCrowd::fight);
	ClassDB::bind_method(D_METHOD("near_bodies"), &CityCrowd::near_bodies);
	ClassDB::bind_method(D_METHOD("sea_depth", "x", "z"), &CityCrowd::sea_depth);
	ClassDB::bind_method(D_METHOD("place_from_file", "number_in_places_bin"), &CityCrowd::place_from_file);
	ClassDB::bind_method(D_METHOD("swim_spot_of", "beach_place"), &CityCrowd::swim_spot_of);
	ClassDB::bind_method(D_METHOD("set_sea_path", "path"), &CityCrowd::set_sea_path);
	ClassDB::bind_method(D_METHOD("get_sea_path"), &CityCrowd::get_sea_path);
	ClassDB::bind_method(D_METHOD("set_sea_y", "y"), &CityCrowd::set_sea_y);
	ClassDB::bind_method(D_METHOD("get_sea_y"), &CityCrowd::get_sea_y);
	ADD_PROPERTY(PropertyInfo(Variant::STRING, "sea_path"), "set_sea_path", "get_sea_path");
	ADD_PROPERTY(PropertyInfo(Variant::FLOAT, "sea_y"), "set_sea_y", "get_sea_y");
	ClassDB::bind_method(D_METHOD("people_near", "at", "radius"), &CityCrowd::people_near);
	ClassDB::bind_method(D_METHOD("take_events"), &CityCrowd::take_events);
	ClassDB::bind_method(D_METHOD("stats"), &CityCrowd::stats);
	ClassDB::bind_method(D_METHOD("report"), &CityCrowd::report);
	ADD_SIGNAL(MethodInfo("crowd_event", PropertyInfo(Variant::INT, "type"), PropertyInfo(Variant::INT, "id"), PropertyInfo(Variant::INT, "aux"), PropertyInfo(Variant::FLOAT, "f")));
}

} // namespace godot
