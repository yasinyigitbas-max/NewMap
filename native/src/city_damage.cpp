// CityDamage: see city_damage.h. The thresholds and the reasons for them: docs/damage/BEHAVIOUR.md.
#include "city_damage.h"
#include "city_rooms.h"
#include "el_sfx.h"
#include <godot_cpp/classes/camera3d.hpp>
#include <godot_cpp/classes/collision_object3d.hpp>
#include <godot_cpp/classes/file_access.hpp>
#include <godot_cpp/classes/input.hpp>
#include <godot_cpp/classes/input_event_screen_touch.hpp>
#include <godot_cpp/classes/json.hpp>
#include <godot_cpp/classes/os.hpp>
#include <godot_cpp/classes/physics_direct_space_state3d.hpp>
#include <godot_cpp/classes/physics_ray_query_parameters3d.hpp>
#include <godot_cpp/classes/physics_server3d.hpp>
#include <godot_cpp/classes/physics_shape_query_parameters3d.hpp>
#include <godot_cpp/classes/quad_mesh.hpp>
#include <godot_cpp/classes/resource_loader.hpp>
#include <godot_cpp/classes/scene_tree.hpp>
#include <godot_cpp/classes/shader_material.hpp>
#include <godot_cpp/classes/sphere_shape3d.hpp>
#include <godot_cpp/classes/texture2d.hpp>
#include <godot_cpp/classes/viewport.hpp>
#include <godot_cpp/classes/window.hpp>
#include <godot_cpp/classes/world3d.hpp>
#include <godot_cpp/core/class_db.hpp>
#include <algorithm>
#include <cmath>

namespace godot {

CityDamage *CityDamage::the = nullptr;

static const char *SURF_NAME[CityDamage::N_SURF] = { "concrete", "brick", "stucco", "asphalt", "stone", "wood", "metal", "glass", "plastic", "fabric", "bark", "foliage", "grass", "dirt", "sand", "water", "flesh", "car_body", "car_glass" };
static const char *KIND_NAME[CityDamage::N_KINDS] = { "bullet", "punch", "kick", "blunt", "car", "fall", "explosion" };
static const char *RUNTIME_FAR = "res://map_dc/coronado/city_kit/runtime/far/";

// the colour of a surface's dust and chips
static Color surf_colour(int s) {
	switch (s) {
		case CityDamage::CONCRETE: return Color(0.72f, 0.72f, 0.70f);
		case CityDamage::BRICK: return Color(0.66f, 0.38f, 0.30f);
		case CityDamage::STUCCO: return Color(0.88f, 0.85f, 0.78f);
		case CityDamage::ASPHALT: return Color(0.36f, 0.36f, 0.37f);
		case CityDamage::STONE: return Color(0.76f, 0.72f, 0.66f);
		case CityDamage::WOOD: return Color(0.78f, 0.62f, 0.42f);
		case CityDamage::METAL: return Color(0.62f, 0.62f, 0.64f);
		case CityDamage::GLASS: case CityDamage::CAR_GLASS: return Color(0.86f, 0.92f, 0.94f);
		case CityDamage::PLASTIC: return Color(0.86f, 0.86f, 0.84f);
		case CityDamage::FABRIC: return Color(0.72f, 0.64f, 0.54f);
		case CityDamage::BARK: return Color(0.36f, 0.27f, 0.19f);
		case CityDamage::FOLIAGE: return Color(0.30f, 0.46f, 0.20f);
		case CityDamage::GRASS: return Color(0.38f, 0.55f, 0.26f);
		case CityDamage::DIRT: return Color(0.46f, 0.36f, 0.26f);
		case CityDamage::SAND: return Color(0.86f, 0.78f, 0.60f);
		case CityDamage::WATER: return Color(0.82f, 0.90f, 0.96f);
		case CityDamage::CAR_BODY: return Color(0.55f, 0.55f, 0.58f);
		default: return Color(0.6f, 0.6f, 0.6f);
	}
}

const char *CityDamage::surface_name(int p_s) { return (p_s >= 0 && p_s < N_SURF) ? SURF_NAME[p_s] : "concrete"; }

int CityDamage::surface_from_name(const String &p_name) {
	const String n = p_name.to_lower().strip_edges();
	for (int s = 0; s < N_SURF; s++) if (n == SURF_NAME[s]) return s;
	return -1;
}

// a kit building's or a prop's name -> what it is made of. Order matters: the first word found wins.
int CityDamage::surface_from_words(const String &p_words, int p_default) {
	const String w = p_words.to_lower();
	struct R { const char *word; int s; };
	static const R RULES[] = {
		// props: living things first (a "tree_planter" is a tree), then glass and the light stuff
		{ "palm", BARK }, { "tree", BARK }, { "trunk", BARK }, { "hedge", FOLIAGE }, { "bush", FOLIAGE }, { "shrub", FOLIAGE }, { "plant_", FOLIAGE }, { "flower", FOLIAGE },
		{ "glass", GLASS }, { "window", GLASS }, { "umbrella", FABRIC }, { "awning", FABRIC }, { "parasol", FABRIC }, { "canopy", FABRIC }, { "tent", FABRIC }, { "cushion", FABRIC },
		{ "cone", PLASTIC }, { "plastic", PLASTIC }, { "cooler", PLASTIC }, { "slide", PLASTIC }, { "kayak", PLASTIC },
		{ "hydrant", METAL }, { "bollard", METAL }, { "lamp", METAL }, { "light", METAL }, { "pole", METAL }, { "post", METAL }, { "sign", METAL }, { "meter", METAL },
		{ "mailbox", METAL }, { "newsbox", METAL }, { "rail", METAL }, { "rack", METAL }, { "grate", METAL }, { "chain", METAL }, { "metal", METAL }, { "steel", METAL },
		{ "iron", METAL }, { "dumpster", METAL }, { "bin", METAL }, { "trash", METAL }, { "can_", METAL }, { "box_elec", METAL }, { "transformer", METAL }, { "hvac", METAL }, { "ac_unit", METAL },
		{ "pump", METAL }, { "signal", METAL }, { "barrier", METAL }, { "guard", METAL }, { "swing", METAL }, { "playground", METAL }, { "shelter", METAL }, { "busstop", METAL }, { "bus_stop", METAL },
		{ "bench", WOOD }, { "picnic", WOOD }, { "pallet", WOOD }, { "crate", WOOD }, { "deck", WOOD }, { "pier", WOOD }, { "dock", WOOD }, { "boardwalk", WOOD }, { "picket", WOOD },
		{ "fence", WOOD }, { "wood", WOOD }, { "cedar", WOOD }, { "siding", WOOD }, { "shingle", WOOD }, { "craftsman", WOOD }, { "cape_", WOOD }, { "colonial", WOOD }, { "beach_", WOOD },
		{ "lifeguard", WOOD }, { "lookout", WOOD }, { "boathouse", WOOD }, { "shed", WOOD }, { "kiosk", WOOD },
		// buildings
		{ "brick", BRICK }, { "courthouse", BRICK }, { "red_spire", BRICK }, { "fire_station", BRICK },
		{ "stone", STONE }, { "rock", STONE }, { "church", STONE }, { "chapel", STONE }, { "mansion", STONE }, { "museum", STONE }, { "library", STONE }, { "city_hall", STONE }, { "bank", STONE },
		{ "stucco", STUCCO }, { "spanish", STUCCO }, { "dingbat", STUCCO }, { "apt_", STUCCO }, { "ranch", STUCCO }, { "mcm", STUCCO }, { "contemporary", STUCCO }, { "motel", STUCCO },
		{ "hotel", STUCCO }, { "orange", STUCCO }, { "arcade", STUCCO }, { "bistro", STUCCO }, { "cafe", STUCCO }, { "bakery", STUCCO }, { "boutique", STUCCO }, { "surf", STUCCO },
		{ "realty", STUCCO }, { "books", STUCCO }, { "bar_", STUCCO }, { "civ_", STUCCO }, { "lmk_", STUCCO }, { "com_", STUCCO }, { "urb_", STUCCO }, { "twr_", CONCRETE },
		{ "ind_", CONCRETE }, { "garage", CONCRETE }, { "parking", CONCRETE }, { "warehouse", METAL }, { "carport", WOOD }, { "carwash", CONCRETE }, { "stadium", CONCRETE },
		{ "planter", CONCRETE }, { "wall", CONCRETE }, { "kerb", CONCRETE }, { "curb", CONCRETE }, { "step", CONCRETE }, { "stair", CONCRETE }, { "block", CONCRETE }, { "concrete", CONCRETE },
	};
	for (const R &r : RULES) if (w.contains(r.word)) return r.s;
	return p_default;
}

CityDamage::CityDamage() { the = this; }
CityDamage::~CityDamage() { if (the == this) the = nullptr; }

void CityDamage::_ready() {
	if (!is_in_group("city_damage")) add_to_group("city_damage");
	the = this;
	const PackedStringArray args = OS::get_singleton()->get_cmdline_user_args();
	for (int i = 0; i < args.size(); i++) {
		if (args[i] == "--testgun") set_testgun(1);
		else if (args[i] == "--testgun=crowd") set_testgun(2);
	}
	make();
	set_process(true);
}

void CityDamage::_exit_tree() {
	if (the == this) the = nullptr;
}

void CityDamage::make() {
	if (made) return;
	made = true;
	ResourceLoader *rl = ResourceLoader::get_singleton();
	marks.assign(MAX_MARKS, Mark());
	// the marks: one quad mesh, one material, one MultiMesh in world space
	{
		Ref<QuadMesh> q; q.instantiate(); q->set_size(Vector2(1, 1));   // (faces +Z)
		mark_mm.instantiate();
		mark_mm->set_transform_format(MultiMesh::TRANSFORM_3D);
		mark_mm->set_use_custom_data(true);
		mark_mm->set_mesh(q);
		mark_mm->set_instance_count(MAX_MARKS);
		mark_mm->set_visible_instance_count(0);
		mark_mmi = memnew(MultiMeshInstance3D);
		mark_mmi->set_name("Marks");
		mark_mmi->set_multimesh(mark_mm);
		mark_mmi->set_cast_shadows_setting(GeometryInstance3D::SHADOW_CASTING_SETTING_OFF);
		Ref<ShaderMaterial> m; m.instantiate();
		if (rl->exists("res://assets/damage/marks.gdshader")) m->set_shader(rl->load("res://assets/damage/marks.gdshader"));
		if (rl->exists("res://assets/damage/marks.png")) m->set_shader_parameter("sheet", rl->load("res://assets/damage/marks.png"));
		m->set_shader_parameter("far", MARK_FAR);
		mark_mmi->set_material_override(m);
		add_child(mark_mmi);
		mark_mmi->set_as_top_level(true);
		mark_mmi->set_global_transform(Transform3D());
		mark_mmi->set_visible(false);
	}
	// the particles
	{
		Ref<QuadMesh> q; q.instantiate(); q->set_size(Vector2(1, 1));
		part_mm.instantiate();
		part_mm->set_transform_format(MultiMesh::TRANSFORM_3D);
		part_mm->set_use_colors(true);
		part_mm->set_use_custom_data(true);
		part_mm->set_mesh(q);
		part_mm->set_instance_count(MAX_PARTS);
		part_mm->set_visible_instance_count(0);
		part_mmi = memnew(MultiMeshInstance3D);
		part_mmi->set_name("Particles");
		part_mmi->set_multimesh(part_mm);
		part_mmi->set_cast_shadows_setting(GeometryInstance3D::SHADOW_CASTING_SETTING_OFF);
		Ref<ShaderMaterial> m; m.instantiate();
		if (rl->exists("res://assets/damage/sprites.gdshader")) m->set_shader(rl->load("res://assets/damage/sprites.gdshader"));
		if (rl->exists("res://assets/damage/sprites.png")) m->set_shader_parameter("sheet", rl->load("res://assets/damage/sprites.png"));
		part_mmi->set_material_override(m);
		add_child(part_mmi);
		part_mmi->set_as_top_level(true);
		part_mmi->set_global_transform(Transform3D());
		part_mmi->set_visible(false);
	}
	parts.reserve(MAX_PARTS);
}

// ---------------------------------------------------------------- the ground's surface map
void CityDamage::load_ground_map() {
	if (gmap_tried) return;
	gmap_tried = true;
	// the damage system's own (the bake writes it beside the footsteps' classes); an older bake: the footsteps' classes
	for (int pass = 0; pass < 2; pass++) {
		const String base = String(RUNTIME_FAR) + (pass == 0 ? "ground_surface" : "ground_class");
		if (!FileAccess::file_exists(base + String(".json"))) continue;
		const Variant v = JSON::parse_string(FileAccess::get_file_as_string(base + String(".json")));
		if (v.get_type() != Variant::DICTIONARY) continue;
		const Dictionary d = v;
		const int w = (int)d.get("w", 0), h = (int)d.get("h", 0);
		const PackedByteArray b = FileAccess::get_file_as_bytes(base + String(".bin"));
		if (w <= 0 || h <= 0 || b.size() != (int64_t)w * h) continue;
		gw = w; gh = h; gx0 = (float)(double)d.get("x0", 0.0); gz0 = (float)(double)d.get("z0", 0.0); gtex = (float)(double)d.get("texel", 2.5);
		gmap.assign(b.ptr(), b.ptr() + b.size());
		gmap_is_surface = pass == 0;
		return;
	}
}

int CityDamage::ground_surface(const Vector3 &p_at, int p_fallback) const {
	if (gmap.empty()) return p_fallback;
	const int x = (int)std::floor((p_at.x - gx0) / gtex), z = (int)std::floor((p_at.z - gz0) / gtex);
	if (x < 0 || z < 0 || x >= gw || z >= gh) return SAND;   // (off the picture: the beach and the sea's edge)
	const int c = gmap[(size_t)z * gw + x];
	if (gmap_is_surface) return c < N_SURF ? c : p_fallback;
	// the footsteps' classes: 0 hard (asphalt, pavement or concrete: the old map cannot tell them apart), 1 grass, 2 sand, 3 dirt
	static const int FROM_CLASS[4] = { CONCRETE, GRASS, SAND, DIRT };
	return c < 4 ? FROM_CLASS[c] : p_fallback;
}

// ---------------------------------------------------------------- what was hit
Dictionary CityDamage::ray(const Vector3 &p_from, const Vector3 &p_to, uint32_t p_mask, Object *p_exclude) const {
	if (!is_inside_tree()) return Dictionary();
	PhysicsDirectSpaceState3D *ss = get_world_3d()->get_direct_space_state();
	if (!ss) return Dictionary();
	TypedArray<RID> ex;
	if (CollisionObject3D *co = Object::cast_to<CollisionObject3D>(p_exclude)) ex.push_back(co->get_rid());
	Ref<PhysicsRayQueryParameters3D> q = PhysicsRayQueryParameters3D::create(p_from, p_to, p_mask, ex);
	q->set_hit_back_faces(false);
	return ss->intersect_ray(q);
}

static Node *opening_of(Node *p_n, bool &r_window) {
	// a room's window pane or door leaf: the collider is "body" under Window_*, or somewhere under DoorLeaf_*
	Node *n = p_n;
	for (int up = 0; up < 4 && n; up++, n = n->get_parent()) {
		const String nm = n->get_name();
		if (nm.begins_with("Window_")) { r_window = true; return n; }
		if (nm.begins_with("DoorLeaf_")) { r_window = false; return n; }
	}
	return nullptr;
}

int CityDamage::surface_id_at(const Dictionary &p_hit) {
	if (p_hit.is_empty()) return -1;
	load_ground_map();
	const Vector3 pos = p_hit.get("position", p_hit.get("point", Vector3()));
	const Vector3 n = p_hit.get("normal", Vector3(0, 1, 0));
	const int shape = (int)p_hit.get("shape", 0);
	Object *col = p_hit.get("collider", Variant());
	if (!col && p_hit.has("collider_id")) col = ObjectDB::get_instance(ObjectID((uint64_t)(int64_t)p_hit["collider_id"]));
	if (!col) {
		// a body made straight on the physics server (CityBreakables' pooled props: bollards, posts, meters, bins)
		return p_hit.has("rid") ? METAL : ground_surface(pos, CONCRETE);
	}
	// 1. said by the thing itself: meta "surface" on the collider, or the bake's per-shape table "surf"
	if (col->has_meta("surface")) { const int s = surface_from_name(col->get_meta("surface")); if (s >= 0) return s; }
	if (col->has_meta("surf")) {
		const Array t = col->get_meta("surf");
		if (shape >= 0 && shape < t.size()) {
			const String sn = t[shape];
			if (!sn.is_empty()) { const int s = surface_from_name(sn); if (s >= 0) return s; }
		}
	}
	CollisionObject3D *co = Object::cast_to<CollisionObject3D>(col);
	const uint32_t layer = co ? co->get_collision_layer() : 0u;
	// 2. cars: the body, or its glass (between the belt line and the roof, on the sides and ends)
	if (col->is_class("CityCar") || (co && co->is_in_group("vehicles")) || (layer & L_CARS)) {
		const Dictionary g = ray(pos + Vector3(0, 0.05f, 0), pos - Vector3(0, 3.0f, 0), L_WORLD, nullptr);
		const float h = g.is_empty() ? 1.0f : pos.y - ((Vector3)g["position"]).y;
		return (h > 0.95f && h < 1.5f && std::fabs(n.y) < 0.85f) ? CAR_GLASS : CAR_BODY;
	}
	// 3. people
	if ((layer & (L_PEOPLE | L_PLAYER)) || col->is_class("CityPed") || col->is_class("CityPlayer") || col->is_class("CharacterBody3D")) return FLESH;
	Node *node = Object::cast_to<Node>(col);
	if (!node) return ground_surface(pos, CONCRETE);
	// 4. a room's window or door
	bool win = false;
	if (Node *op = opening_of(node, win)) {
		if (win) return GLASS;
		if (op->has_meta("surface")) { const int s = surface_from_name(op->get_meta("surface")); if (s >= 0) return s; }
		return surface_from_words(op->get_name(), WOOD);
	}
	const String nm = node->get_name();
	// 5. inside a room: plaster walls, wooden or tiled floors
	if (nm == "room_col") return n.y > 0.7f ? WOOD : STUCCO;
	// 6. a building's shell ("col" under the building's node, named after its kit)
	Node *par = node->get_parent();
	if (nm == "col" && par) {
		if (par->has_meta("surface")) { const int s = surface_from_name(par->get_meta("surface")); if (s >= 0) return s; }
		String words = par->get_name();
		if (par->has_meta("kit")) words += String(" ") + String(par->get_meta("kit"));
		if (n.y > 0.97f) return CONCRETE;      // a flat roof
		if (n.y > 0.6f) return STONE;          // a pitched roof (clay tiles, slate: brittle, chips like stone)
		return surface_from_words(words, STUCCO);
	}
	// 7. the ground and the props of a cell ("col_N"): the ground's trimesh by the map, a prop's hull by its size
	if (co) {
		PhysicsServer3D *ps = PhysicsServer3D::get_singleton();
		const RID rid = co->get_rid();
		if (shape >= 0 && shape < ps->body_get_shape_count(rid)) {
			const RID sh = ps->body_get_shape(rid, shape);
			const PhysicsServer3D::ShapeType st = ps->shape_get_type(sh);
			if (st == PhysicsServer3D::SHAPE_CONCAVE_POLYGON || st == PhysicsServer3D::SHAPE_HEIGHTMAP) return ground_surface(pos, n.y > 0.6f ? CONCRETE : CONCRETE);
			if (st == PhysicsServer3D::SHAPE_CONVEX_POLYGON) {
				const PackedVector3Array pts = ps->shape_get_data(sh);
				AABB ab; for (int k = 0; k < pts.size(); k++) { if (k == 0) ab.position = pts[k]; else ab.expand_to(pts[k]); }
				// thin and tall: a pole, a post, a sign (an older bake gives a tree trunk the same; the new one names it)
				if (ab.size.x < 0.6f && ab.size.z < 0.6f && ab.size.y > 1.2f) return METAL;
				return CONCRETE;
			}
		}
	}
	// 8. anything else: by its own name, else the ground under a floor-like hit, else concrete
	const int by_name = surface_from_words(nm, -1);
	if (by_name >= 0) return by_name;
	return n.y > 0.7f ? ground_surface(pos, CONCRETE) : CONCRETE;
}

String CityDamage::surface_at(const Dictionary &p_ray_hit) {
	const int s = surface_id_at(p_ray_hit);
	return s < 0 ? String() : String(SURF_NAME[s]);
}

// ---------------------------------------------------------------- the contract
Dictionary CityDamage::hit(const Vector3 &p_at, const Vector3 &p_normal, const Vector3 &p_dir, double p_amount, int p_kind, Object *p_source) {
	make();
	const int kind = std::clamp(p_kind, 0, (int)N_KINDS - 1);
	hits_n[kind]++;
	const float amount = (float)std::max(0.0, p_amount);
	Vector3 nrm = p_normal.length_squared() > 1e-6f ? p_normal.normalized() : Vector3(0, 1, 0);
	Vector3 dir = p_dir.length_squared() > 1e-6f ? p_dir.normalized() : -nrm;
	// the thing at the point: a short ray through it along the hit's direction (then against the normal)
	Dictionary rh = ray(p_at - dir * 0.3f, p_at + dir * 0.3f, BULLET_MASK, p_source);
	if (rh.is_empty()) rh = ray(p_at + nrm * 0.3f, p_at - nrm * 0.3f, BULLET_MASK, p_source);
	int surf;
	Object *col = nullptr;
	Vector3 at = p_at;
	if (!rh.is_empty()) {
		surf = surface_id_at(rh);
		col = rh.get("collider", Variant());
		at = rh["position"]; nrm = rh["normal"];
	} else {
		load_ground_map();
		surf = (at.y < SEA_Y + 0.05f && nrm.y > 0.7f) ? WATER : (nrm.y > 0.7f ? ground_surface(at, CONCRETE) : CONCRETE);
	}
	if (surf < 0) surf = CONCRETE;
	surf_n[surf]++; last_surface = surf;
	Dictionary r; r["surface"] = String(SURF_NAME[surf]); r["target_id"] = String(); r["state"] = String("marked"); r["kind"] = String(KIND_NAME[kind]);
	Node *node = Object::cast_to<Node>(col);
	// a room's window or door: its state (intact -> cracked -> broken), saved by CityRooms
	bool win = false;
	if (node && opening_of(node, win)) {
		CityRooms *rooms = nullptr;
		if (SceneTree *tr = get_tree()) rooms = Object::cast_to<CityRooms>(tr->get_first_node_in_group("city_rooms"));
		if (rooms) {
			// how much of the blow reaches the pane or leaf (docs/damage/BEHAVIOUR.md): a bullet passes through glass and
			// leaves a hole (several before it gives way); a fist or a foot loads the whole pane; a car takes it out
			static const float TO_GLASS[N_KINDS] = { 0.5f, 1.0f, 1.0f, 1.2f, 3.0f, 0.5f, 3.0f };
			static const float TO_DOOR[N_KINDS] = { 0.25f, 0.5f, 1.0f, 1.0f, 3.0f, 0.5f, 3.0f };
			const float a = amount * (win ? TO_GLASS[kind] : TO_DOOR[kind]);
			const Dictionary o = rooms->hit_opening(at, a, 0.6, kind == BULLET && win);
			if (!o.is_empty()) {
				openings_hit++;
				const String st = o.get("state", "");
				r["target_id"] = o.get("bid", ""); last_target = r["target_id"];
				r["state"] = st == "broken" ? String("broken") : (st == "intact" || st == "closed" ? String("marked") : String("damaged"));
				if (st == "broken" && (bool)o.get("now", false)) emit_signal("obstacle_changed", AABB(at - Vector3(1.5f, 1.5f, 1.5f), Vector3(3, 3, 3)));
			}
		}
		burst(at, nrm, dir, surf, kind, amount);
		impact_sound(at, surf, kind, amount);
		return r;
	}
	if (node) r["target_id"] = String(node->get_name());
	// a mark: on the static world only (a car, a person, a door or a piece of debris moves and keeps its own damage)
	const bool static_world = !col || (Object::cast_to<CollisionObject3D>(col) && Object::cast_to<CollisionObject3D>(col)->is_class("StaticBody3D"));
	const bool pooled_prop = !col && !rh.is_empty();   // (CityBreakables' pooled props: knocked over later, so no mark)
	if (static_world && !pooled_prop) {
		int tile = -1; float size = 0.22f;
		const bool masonry = surf == CONCRETE || surf == BRICK || surf == STUCCO || surf == STONE || surf == ASPHALT;
		switch (kind) {
			case BULLET:
				switch (surf) {
					case CONCRETE: tile = rnd() < 0.5f ? MARK_CONCRETE : MARK_CONCRETE2; break;
					case BRICK: tile = MARK_BRICK; break;
					case STUCCO: tile = MARK_STUCCO; break;
					case STONE: tile = MARK_STONE; break;
					case ASPHALT: tile = MARK_ASPHALT; size = 0.18f; break;
					case WOOD: tile = MARK_WOOD; break;
					case METAL: tile = MARK_METAL; size = 0.16f; break;
					case PLASTIC: case FABRIC: tile = MARK_PLASTIC; size = 0.16f; break;
					case BARK: tile = MARK_BARK; size = 0.14f; break;
					case GRASS: case DIRT: case SAND: tile = MARK_DIVOT; size = 0.16f; break;
					default: break;
				}
				break;
			case PUNCH: if (masonry || surf == WOOD || surf == METAL || surf == PLASTIC) { tile = MARK_PUNCH; size = 0.14f; } break;
			case KICK: if (masonry || surf == WOOD || surf == METAL || surf == PLASTIC) { tile = MARK_KICK; size = 0.24f; } break;
			case BLUNT: if (masonry || surf == WOOD || surf == METAL) { tile = amount > 30.0f && (surf == STUCCO || surf == CONCRETE || surf == STONE) ? MARK_CHIP_BIG : MARK_PUNCH; size = 0.2f + std::min(amount, 60.0f) * 0.004f; } break;
			case CAR:
				if (surf == BARK) { tile = MARK_BARK; size = 0.3f + std::min(amount, 20.0f) * 0.015f; }
				else if (masonry || surf == WOOD || surf == METAL || surf == PLASTIC) { tile = amount > 9.0f && masonry ? MARK_CHIP_BIG : MARK_SCRAPE; size = 0.5f + std::min(amount, 20.0f) * 0.04f; }
				break;
			case FALL: if (amount > 6.0f && (surf == GRASS || surf == DIRT || surf == SAND)) { tile = MARK_DIVOT; size = 0.5f; } break;
			case EXPLOSION: if (surf != WATER && surf != FOLIAGE && surf != GLASS) { tile = MARK_CHIP_BIG; size = 0.8f + std::min(amount, 100.0f) * 0.01f; } break;
			default: break;
		}
		if (tile >= 0) add_mark(at, nrm, dir, tile, size, col ? (uint64_t)col->get_instance_id() : 0);
		else r["state"] = String("none");
	} else r["state"] = String("none");
	burst(at, nrm, dir, surf, kind, amount);
	impact_sound(at, surf, kind, amount);
	return r;
}

Dictionary CityDamage::strike(const Vector3 &p_from, const Vector3 &p_to, double p_radius, double p_amount, int p_kind, Object *p_source) {
	if (!is_inside_tree()) return Dictionary();
	PhysicsDirectSpaceState3D *ss = get_world_3d()->get_direct_space_state();
	if (!ss) return Dictionary();
	Ref<SphereShape3D> sp; sp.instantiate(); sp->set_radius((float)std::max(0.02, p_radius));
	Ref<PhysicsShapeQueryParameters3D> q; q.instantiate();
	q->set_shape(sp);
	q->set_transform(Transform3D(Basis(), p_from));
	q->set_motion(p_to - p_from);
	q->set_collision_mask(BULLET_MASK & ~(uint32_t)L_DEBRIS);   // (a fist does not stop at a shard on the ground)
	TypedArray<RID> ex;
	if (CollisionObject3D *co = Object::cast_to<CollisionObject3D>(p_source)) ex.push_back(co->get_rid());
	q->set_exclude(ex);
	// already touching at the start (a wall at arm's length): the rest info there; otherwise sweep
	Dictionary rest = ss->get_rest_info(q);
	if (rest.is_empty()) {
		const PackedFloat32Array m = ss->cast_motion(q);
		if (m.size() < 2 || m[1] >= 1.0f) return Dictionary();
		q->set_transform(Transform3D(Basis(), p_from + (p_to - p_from) * m[1]));
		q->set_motion(Vector3());
		rest = ss->get_rest_info(q);
		if (rest.is_empty()) return Dictionary();
	}
	const Vector3 pt = rest["point"], nr = rest["normal"];
	return hit(pt, nr, p_to - p_from, p_amount, p_kind, p_source);
}

Dictionary CityDamage::shoot(const Vector3 &p_from, const Vector3 &p_dir, double p_range, double p_amount, Object *p_source) {
	const Vector3 d = p_dir.normalized();
	const Vector3 to = p_from + d * (float)p_range;
	const Dictionary rh = ray(p_from, to, BULLET_MASK, p_source);
	shots++;
	// the sea (y = 0 off the island) first, if the bullet crosses it before anything solid
	const float hit_t = rh.is_empty() ? (float)p_range : ((Vector3)rh["position"]).distance_to(p_from);
	if (p_from.y > SEA_Y && d.y < -1e-4f) {
		const float t = (SEA_Y - p_from.y) / d.y;
		if (t < hit_t) {
			const Vector3 w = p_from + d * t;
			load_ground_map();
			// over the sea only where the ground under it is below the water (a ray to the ground would tell; the map is cheaper)
			const Dictionary g = ray(w + Vector3(0, 0.01f, 0), w - Vector3(0, 30.0f, 0), L_WORLD, nullptr);
			if (g.is_empty() || ((Vector3)g["position"]).y < SEA_Y - 0.05f) {
				hits_n[BULLET]++; surf_n[WATER]++; last_surface = WATER;
				burst(w, Vector3(0, 1, 0), d, WATER, BULLET, (float)p_amount);
				impact_sound(w, WATER, BULLET, (float)p_amount);
				Dictionary r; r["surface"] = String("water"); r["target_id"] = String("sea"); r["state"] = String("none"); r["kind"] = String("bullet"); r["position"] = w;
				return r;
			}
		}
	}
	if (rh.is_empty()) return Dictionary();
	Dictionary r = hit(rh["position"], rh["normal"], d, p_amount, BULLET, p_source);
	r["position"] = rh["position"];
	return r;
}

// ---------------------------------------------------------------- marks
void CityDamage::add_mark(const Vector3 &p_at, const Vector3 &p_n, const Vector3 &p_dir, int p_tile, float p_size, uint64_t p_target) {
	Vector3 n = p_n.normalized();
	// the quad's own axes: a scrape or a tyre mark lies along the blow; a hole anywhere round its centre
	Vector3 along = p_dir - n * p_dir.dot(n);
	if (p_tile != MARK_SCRAPE && p_tile != MARK_TYRE && p_tile != MARK_KICK) {
		const Vector3 up = std::fabs(n.y) < 0.9f ? Vector3(0, 1, 0) : Vector3(1, 0, 0);
		along = up.cross(n);
		const float a = rnd() * 6.2832f;
		along = along.rotated(n, a);
	} else if (p_tile == MARK_KICK) {
		along = (std::fabs(n.y) < 0.9f ? Vector3(0, 1, 0) : Vector3(1, 0, 0)).cross(n).rotated(n, rnd2() * 0.4f + 1.5708f);
	}
	if (along.length_squared() < 1e-6f) along = (std::fabs(n.y) < 0.9f ? Vector3(0, 1, 0) : Vector3(1, 0, 0)).cross(n);
	along.normalize();
	const Vector3 side = n.cross(along).normalized();
	const float sz = p_size * (0.85f + 0.3f * rnd());
	Mark &m = marks[mark_head];
	m.xf = Transform3D(Basis(along * sz, side * sz, n), p_at + n * MARK_LIFT);   // (columns: x, y, z)
	m.tile = p_tile; m.born = (float)clock; m.target = p_target; m.live = true;
	const int i = mark_head;
	mark_head = (mark_head + 1) % MAX_MARKS;
	mark_count = std::min(mark_count + 1, (int)MAX_MARKS);
	marks_total++;
	mark_mm->set_visible_instance_count(std::max(mark_mm->get_visible_instance_count(), i + 1));
	upload_mark(i);
	refade();
	mark_bounds();
	mark_mmi->set_visible(true);
}

void CityDamage::upload_mark(int p_i) {
	const Mark &m = marks[p_i];
	if (!m.live) { mark_mm->set_instance_transform(p_i, Transform3D(Basis().scaled(Vector3(0, 0, 0)), Vector3(0, -1000, 0))); return; }
	mark_mm->set_instance_transform(p_i, m.xf);
	mark_mm->set_instance_custom_data(p_i, Color((float)m.tile, 1.0f, 0.0f, 0.0f));
}

void CityDamage::refade() {
	// the FADE_MARKS oldest of a full ring fade towards nothing, the oldest most: the next new mark replaces it unseen
	if (mark_count < MAX_MARKS - FADE_MARKS) return;
	const int oldest = mark_count < MAX_MARKS ? 0 : mark_head;
	const int start_rank = MAX_MARKS - mark_count;   // (a ring not yet full: its oldest is not yet the one to go)
	for (int r = 0; r < FADE_MARKS; r++) {
		const int rank = r - start_rank;
		if (rank < 0) continue;
		const int i = (oldest + rank) % MAX_MARKS;
		if (!marks[i].live) continue;
		const float a = (float)(r + 1) / (float)(FADE_MARKS + 1);
		mark_mm->set_instance_custom_data(i, Color((float)marks[i].tile, a, 0.0f, 0.0f));
	}
}

void CityDamage::mark_bounds() {
	AABB ab; bool any = false;
	for (const Mark &m : marks) {
		if (!m.live) continue;
		const AABB b(m.xf.origin - Vector3(1, 1, 1), Vector3(2, 2, 2));
		if (!any) { ab = b; any = true; } else ab = ab.merge(b);
	}
	if (any) mark_mmi->set_custom_aabb(ab);
	mark_mmi->set_visible(any);
}

void CityDamage::clear_marks() {
	for (int i = 0; i < MAX_MARKS; i++) { if (marks[i].live) { marks[i].live = false; upload_mark(i); } }
	mark_head = 0; mark_count = 0;
	if (mark_mm.is_valid()) mark_mm->set_visible_instance_count(0);
	if (mark_mmi) mark_mmi->set_visible(false);
}

Array CityDamage::marks_near(const Vector3 &p_at, double p_radius) const {
	Array out;
	const int oldest = mark_count < MAX_MARKS ? 0 : mark_head;
	for (int r = 0; r < mark_count; r++) {
		const int i = (oldest + r) % MAX_MARKS;
		const Mark &m = marks[i];
		if (!m.live || m.xf.origin.distance_to(p_at) > p_radius) continue;
		Dictionary d; d["at"] = m.xf.origin; d["tile"] = m.tile; d["size"] = m.xf.basis.get_column(0).length();
		d["alpha"] = (float)(double)mark_mm->get_instance_custom_data(i).g;
		d["normal"] = m.xf.basis.get_column(2);
		out.push_back(d);
	}
	return out;
}

// ---------------------------------------------------------------- particles
void CityDamage::spawn(int p_tile, const Vector3 &p_at, const Vector3 &p_v, const Color &p_col, float p_size, float p_life, float p_grav, float p_drag, float p_glow) {
	if ((int)parts.size() >= MAX_PARTS) {   // full: the oldest goes
		int old = 0; for (int k = 1; k < (int)parts.size(); k++) if (parts[k].age / parts[k].life > parts[old].age / parts[old].life) old = k;
		parts[old] = parts.back(); parts.pop_back();
	}
	Part p; p.p = p_at; p.v = p_v; p.col = p_col; p.size = p_size; p.life = std::max(0.05f, p_life); p.grav = p_grav; p.drag = p_drag; p.glow = p_glow; p.tile = p_tile; p.spin = rnd2() * 6.0f;
	parts.push_back(p); parts_total++;
}

void CityDamage::burst(const Vector3 &p_at, const Vector3 &p_n, const Vector3 &p_dir, int s, int k, float p_amount) {
	if (!part_mm.is_valid()) return;
	const Vector3 n = p_n.normalized();
	const Vector3 refl = (p_dir - n * 2.0f * p_dir.dot(n)).normalized();
	const Color c = surf_colour(s);
	const float big = k == CAR || k == EXPLOSION ? 2.0f : (k == BULLET ? 1.0f : 0.6f);
	auto cone = [&](float spread, float speed) { Vector3 v = (n * 0.7f + refl * 0.3f).normalized(); v += Vector3(rnd2(), rnd2(), rnd2()) * spread; return v.normalized() * speed * (0.6f + 0.8f * rnd()); };
	const Vector3 at = p_at + n * 0.03f;
	auto dust = [&](int cnt, float size, float a) { for (int i = 0; i < cnt; i++) spawn(SPR_PUFF, at, cone(0.6f, 0.8f), Color(c.r, c.g, c.b, a), size * (0.7f + 0.6f * rnd()) * big, 0.6f + 0.5f * rnd(), -0.05f, 2.5f); };
	auto chips = [&](int tile, int cnt, float size, float speed, const Color &cc) { for (int i = 0; i < cnt; i++) spawn(tile, at, cone(0.7f, speed), cc, size * (0.6f + 0.8f * rnd()), 0.5f + 0.5f * rnd(), 1.0f, 0.3f); };
	if (s == FLESH) return;   // (no blood: the people's own reactions are theirs; Yasin decides what a person shows)
	switch (s) {
		case CONCRETE: case STUCCO: case STONE: case BRICK: case ASPHALT:
			dust(k == BULLET ? 3 : 2, 0.22f, 0.65f);
			if (k == BULLET || k == CAR || k == EXPLOSION || k == BLUNT) chips(SPR_CHIP, k == BULLET ? 5 : 8, 0.035f, 3.5f, c * 0.9f);
			break;
		case METAL: case CAR_BODY:
			if (k == BULLET || k == CAR || k == EXPLOSION) for (int i = 0; i < (k == BULLET ? 6 : 12); i++) spawn(SPR_SPARK, at, cone(0.9f, 6.0f), Color(1.0f, 0.82f, 0.45f, 1.0f), 0.05f, 0.18f + 0.2f * rnd(), 1.0f, 0.5f, 3.0f);
			else dust(1, 0.12f, 0.3f);
			break;
		case WOOD:
			chips(SPR_SPLINTER, k == BULLET ? 5 : 7, 0.07f, 3.0f, c);
			dust(1, 0.16f, 0.4f);
			break;
		case BARK:
			chips(SPR_SPLINTER, k == CAR ? 10 : 4, 0.07f, 2.5f, Color(0.62f, 0.50f, 0.34f));
			chips(SPR_CHIP, 3, 0.04f, 2.0f, c);
			for (int i = 0; i < (k == CAR ? 14 : 3); i++) spawn(SPR_LEAF, at + Vector3(rnd2() * 1.5f, 2.0f + rnd() * 2.5f, rnd2() * 1.5f), Vector3(rnd2() * 0.6f, -0.3f, rnd2() * 0.6f), Color(0.36f, 0.52f, 0.22f), 0.08f, 2.5f + rnd() * 1.5f, 0.15f, 1.2f);   // (the crown shakes: leaves drop)
			break;
		case FOLIAGE: case GRASS:
			for (int i = 0; i < (s == FOLIAGE ? 8 : 5); i++) spawn(SPR_LEAF, at, cone(1.0f, 1.8f), surf_colour(s) * (0.85f + 0.3f * rnd()), 0.06f, 1.2f + rnd(), 0.25f, 1.5f);
			if (s == GRASS) chips(SPR_CLOD, 3, 0.04f, 2.0f, Color(0.40f, 0.32f, 0.22f));
			break;
		case DIRT: case SAND:
			dust(3, 0.3f, s == SAND ? 0.7f : 0.6f);
			chips(SPR_CLOD, 5, 0.04f, 2.6f, c);
			break;
		case GLASS: case CAR_GLASS:
			chips(SPR_SHARD, k == BULLET ? 6 : 10, 0.05f, 2.5f, Color(0.9f, 0.95f, 1.0f, 0.85f));
			break;
		case WATER:
			for (int i = 0; i < 14; i++) spawn(SPR_DROP, at, Vector3(rnd2() * 0.8f, 2.5f + rnd() * 2.5f, rnd2() * 0.8f), Color(0.85f, 0.92f, 1.0f, 0.8f), 0.06f, 0.9f, 1.0f, 0.2f);
			break;
		case PLASTIC: chips(SPR_CHIP, 4, 0.03f, 3.0f, c); break;
		case FABRIC: dust(2, 0.14f, 0.4f); break;
		default: dust(2, 0.2f, 0.5f); break;
	}
	(void)p_amount;
	part_mmi->set_visible(true); parts_shown = true;
}

void CityDamage::step_parts(double p_dt) {
	if (parts.empty()) {
		if (parts_shown) { part_mm->set_visible_instance_count(0); part_mmi->set_visible(false); parts_shown = false; }
		return;
	}
	const float dt = (float)p_dt;
	Viewport *vp = get_viewport();
	Camera3D *cam = vp ? vp->get_camera_3d() : nullptr;
	const Basis cb = cam ? cam->get_global_transform().basis : Basis();
	const Vector3 cx = cb.get_column(0), cy = cb.get_column(1), cz = cb.get_column(2);
	for (int i = 0; i < (int)parts.size();) {
		Part &p = parts[i];
		p.age += dt;
		if (p.age >= p.life) { parts[i] = parts.back(); parts.pop_back(); continue; }
		p.v.y -= 9.8f * p.grav * dt;
		p.v *= std::max(0.0f, 1.0f - p.drag * dt);
		p.p += p.v * dt;
		i++;
	}
	const int n = (int)parts.size();
	PackedFloat32Array buf; buf.resize((int64_t)MAX_PARTS * 20);
	float *w = buf.ptrw();
	AABB ab;
	for (int i = 0; i < MAX_PARTS; i++) {
		float *q = w + (size_t)i * 20;
		if (i >= n) { for (int k = 0; k < 20; k++) q[k] = 0.0f; continue; }
		const Part &p = parts[i];
		const float t = p.age / p.life;
		float size = p.size * (p.tile == SPR_PUFF ? (1.0f + 1.8f * t) : 1.0f);
		Vector3 ax = cx, ay = cy;
		if (p.tile == SPR_SPARK) {   // a streak along its flight, as seen from the camera
			Vector3 v = p.v - cz * p.v.dot(cz);
			if (v.length_squared() > 1e-4f) { ay = v.normalized(); ax = ay.cross(cz).normalized(); }
			ay *= 1.0f + std::min(p.v.length() * 0.08f, 2.5f);
		} else {
			const float c = std::cos(p.spin * p.age), s = std::sin(p.spin * p.age);
			ax = cx * c + cy * s; ay = cy * c - cx * s;
		}
		ax *= size; ay *= size;
		// a 3 x 4 matrix row by row (basis row, origin), then the colour, then the custom data
		q[0] = ax.x; q[1] = ay.x; q[2] = cz.x; q[3] = p.p.x;
		q[4] = ax.y; q[5] = ay.y; q[6] = cz.y; q[7] = p.p.y;
		q[8] = ax.z; q[9] = ay.z; q[10] = cz.z; q[11] = p.p.z;
		const float fade = p.tile == SPR_PUFF ? (1.0f - t) * (1.0f - t) : (t < 0.7f ? 1.0f : (1.0f - t) / 0.3f);
		q[12] = p.col.r; q[13] = p.col.g; q[14] = p.col.b; q[15] = p.col.a * fade;
		q[16] = (float)p.tile; q[17] = p.glow; q[18] = 0.0f; q[19] = 0.0f;
		const AABB b(p.p - Vector3(size, size, size), Vector3(size, size, size) * 2.0f);
		ab = i == 0 ? b : ab.merge(b);
	}
	part_mm->set_buffer(buf);
	part_mm->set_visible_instance_count(n);
	part_mmi->set_custom_aabb(ab);
}

// ---------------------------------------------------------------- sound
void CityDamage::impact_sound(const Vector3 &p_at, int s, int k, float p_amount) {
	// the recorded sets that fit (el_sfx.h). Missing and wanted: bullet impacts and ricochets, a gunshot, splashes, flesh
	// hits, glass ticks (docs/damage/ASSETS_WANTED.md)
	const char *base = nullptr; int width = 1; float db = -10.0f;
	switch (s) {
		case METAL: case CAR_BODY: base = k == CAR ? "res://audio/sfx/car/metal_scrape_" : "res://audio/sfx/car/hit_pole_"; db = k == BULLET ? -9.0f : -12.0f; break;
		case GLASS: case CAR_GLASS: base = "res://audio/sfx/door/door_glass_close_"; db = -10.0f; break;
		case WOOD: case BARK: base = k == CAR ? "res://audio/sfx/car/hit_fence_" : "res://audio/steps/footstep_land_wood_"; width = k == CAR ? 1 : 3; db = -6.0f; break;
		case PLASTIC: base = "res://audio/sfx/car/hit_bin_"; db = -12.0f; break;
		case GRASS: case FOLIAGE: base = "res://audio/steps/footstep_land_grass_"; width = 3; db = -8.0f; break;
		case DIRT: base = "res://audio/steps/footstep_land_dirt_"; width = 3; db = -6.0f; break;
		case SAND: base = "res://audio/steps/footstep_land_sand_"; width = 3; db = -6.0f; break;
		case WATER: case FLESH: case FABRIC: base = nullptr; break;
		default: base = k == CAR ? "res://audio/sfx/car/car_bump_" : "res://audio/steps/footstep_land_concrete_"; width = k == CAR ? 1 : 3; db = k == CAR ? -6.0f : -4.0f; break;
	}
	if (k == CAR && s != METAL && s != CAR_BODY && s != WOOD && s != BARK) { base = "res://audio/sfx/car/car_bump_"; width = 1; db = -6.0f; }
	if (!base) return;
	db += std::min(p_amount * 0.15f, 6.0f) - 3.0f;
	if (elsfx::play(this, String(base), std::min(db, 0.0f), 0.08f, to_local(p_at), 40.0f, 0, width)) sounds++;
}

// ---------------------------------------------------------------- every frame, and the test gun
void CityDamage::dev_fire() {
	Viewport *vp = get_viewport();
	Camera3D *cam = vp ? vp->get_camera_3d() : nullptr;
	if (!cam) return;
	const Vector2 c = vp->get_visible_rect().size * 0.5f;
	const Vector3 from = cam->project_ray_origin(c), d = cam->project_ray_normal(c);
	// (from the camera: it sits behind the player, so the first metres would hit him; the player's capsule is on layer 2,
	// which bullets do not test - the contract's bullet mask)
	const Dictionary r = shoot(from, d, 250.0, 10.0, nullptr);
	if (testgun >= 2) {
		const TypedArray<Node> cr = get_tree()->get_root()->find_children("*", "CityCrowd", true, false);
		if (cr.size() > 0) {
			Object *o = cr[0];
			o->call("gun_aimed", from, d, 1.5);
			o->call("gunshot", from, true);
		}
	}
	(void)r;
}

void CityDamage::_input(const Ref<InputEvent> &p_event) {
	if (testgun <= 0) return;
	const Ref<InputEventScreenTouch> t = p_event;
	if (t.is_valid() && t->is_pressed() && t->get_index() == 2) dev_fire();   // (a phone: a third finger fires)
}

void CityDamage::_process(double p_delta) {
	clock += p_delta;
	if (testgun > 0) {
		Input *in = Input::get_singleton();
		const bool k = in->is_key_pressed(KEY_G) || in->is_mouse_button_pressed(MOUSE_BUTTON_MIDDLE);
		if (k && !gun_key_was) dev_fire();
		gun_key_was = k;
	}
	step_parts(p_delta);
}

Dictionary CityDamage::get_state() const {
	Dictionary d;
	Dictionary kinds; for (int k = 0; k < N_KINDS; k++) kinds[KIND_NAME[k]] = hits_n[k];
	Dictionary surfs; for (int s = 0; s < N_SURF; s++) if (surf_n[s] > 0) surfs[SURF_NAME[s]] = surf_n[s];
	d["hits"] = kinds; d["surfaces"] = surfs;
	d["marks"] = mark_count; d["marks_total"] = marks_total; d["mark_draws"] = (mark_mmi && mark_mmi->is_visible()) ? 1 : 0;
	d["particles"] = (int)parts.size(); d["particles_total"] = parts_total; d["particle_draws"] = parts.empty() ? 0 : 1;
	d["sounds"] = sounds; d["openings_hit"] = openings_hit; d["shots"] = shots; d["testgun"] = testgun;
	d["last_surface"] = last_surface >= 0 ? String(SURF_NAME[last_surface]) : String(); d["last_target"] = last_target;
	d["ground_map"] = gmap.empty() ? String("none") : (gmap_is_surface ? String("ground_surface") : String("ground_class"));
	return d;
}

void CityDamage::_bind_methods() {
	ClassDB::bind_method(D_METHOD("hit", "at", "normal", "dir", "amount", "kind", "source"), &CityDamage::hit, DEFVAL(Variant()));
	ClassDB::bind_method(D_METHOD("strike", "from", "to", "radius", "amount", "kind", "source"), &CityDamage::strike, DEFVAL(Variant()));
	ClassDB::bind_method(D_METHOD("surface_at", "ray_hit"), &CityDamage::surface_at);
	ClassDB::bind_method(D_METHOD("shoot", "from", "dir", "range", "amount", "source"), &CityDamage::shoot, DEFVAL(250.0), DEFVAL(10.0), DEFVAL(Variant()));
	ClassDB::bind_method(D_METHOD("set_testgun", "mode"), &CityDamage::set_testgun);
	ClassDB::bind_method(D_METHOD("get_testgun"), &CityDamage::get_testgun);
	ClassDB::bind_method(D_METHOD("clear_marks"), &CityDamage::clear_marks);
	ClassDB::bind_method(D_METHOD("marks_near", "at", "radius"), &CityDamage::marks_near);
	ClassDB::bind_method(D_METHOD("get_state"), &CityDamage::get_state);
	ClassDB::bind_static_method("CityDamage", D_METHOD("surface_from_words", "words", "default"), &CityDamage::surface_from_words);
	ADD_PROPERTY(PropertyInfo(Variant::INT, "testgun"), "set_testgun", "get_testgun");
	ADD_SIGNAL(MethodInfo("obstacle_changed", PropertyInfo(Variant::AABB, "box")));
	ADD_SIGNAL(MethodInfo("prop_broken", PropertyInfo(Variant::STRING, "target_id"), PropertyInfo(Variant::VECTOR3, "at"), PropertyInfo(Variant::INT, "kind")));
	BIND_CONSTANT(BULLET); BIND_CONSTANT(PUNCH); BIND_CONSTANT(KICK); BIND_CONSTANT(BLUNT); BIND_CONSTANT(CAR); BIND_CONSTANT(FALL); BIND_CONSTANT(EXPLOSION);
}

} // namespace godot
