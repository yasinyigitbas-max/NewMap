// PeoplePlaces: the tool that finds the places people go (see ped_places.h), all C++. It reads what the map already
// holds: the layout (which piece stands where), every piece's own props (benches, bus stop signs, picnic tables, beach
// umbrellas, cafe tables) and buildings (houses, flats), the interiors' shop list (every shop door with its kind and
// name) and the walk graph of streets.bin, and ties each place to the pavement one leaves for it.
// Run by tools/city/traffic/make_places.gd after the streets tool. Nothing here runs in the game.
#include "people_places.h"

#include "ped_crowd.h"
#include "street_build.h"

#include <godot_cpp/classes/file_access.hpp>
#include <godot_cpp/classes/json.hpp>
#include <godot_cpp/classes/mesh.hpp>
#include <godot_cpp/classes/mesh_instance3d.hpp>
#include <godot_cpp/classes/multi_mesh.hpp>
#include <godot_cpp/classes/multi_mesh_instance3d.hpp>
#include <godot_cpp/classes/node3d.hpp>
#include <godot_cpp/classes/packed_scene.hpp>
#include <godot_cpp/classes/resource_loader.hpp>
#include <godot_cpp/core/class_db.hpp>
#include <godot_cpp/variant/packed_vector3_array.hpp>
#include <godot_cpp/variant/utility_functions.hpp>

#include <algorithm>
#include <cmath>
#include <map>
#include <string>
#include <vector>

namespace godot {

namespace {

enum { R_BENCH = 0, R_BUS_SIGN = 1, R_PICNIC = 2, R_PATIO = 3, R_BEACH = 4, R_PLAY = 5, R_HOME = 6 };

struct Rec {   // one thing of a piece, in the piece's own frame
	int type = 0;
	Transform3D xf;
	Vector3 front = Vector3(0, 0, 1), along = Vector3(1, 0, 0);   // (benches, tables: in the prop's own frame)
	float half = 0.8f;
	int people = 1;
};

// A bench's or table's shape: its long way, and which side its back is on (the points of its upper part lie there).
void shape_of(const Ref<Mesh> &mesh, Vector3 &r_front, Vector3 &r_along, float &r_half) {
	r_front = Vector3(0, 0, 1); r_along = Vector3(1, 0, 0); r_half = 0.8f;
	if (mesh.is_null() || mesh->get_surface_count() < 1) return;
	const Array arr = mesh->surface_get_arrays(0);
	if (arr.size() <= Mesh::ARRAY_VERTEX) return;
	const PackedVector3Array v = arr[Mesh::ARRAY_VERTEX];
	if (v.size() < 3) return;
	Vector3 lo = v[0], hi = v[0];
	for (int i = 1; i < v.size(); i++) { lo = lo.min(v[i]); hi = hi.max(v[i]); }
	const Vector3 c = (lo + hi) * 0.5f, e = hi - lo;
	const bool long_x = e.x >= e.z;
	r_along = long_x ? Vector3(1, 0, 0) : Vector3(0, 0, 1);
	r_half = 0.5f * (long_x ? e.x : e.z);
	double back = 0.0; int n = 0;
	for (int i = 0; i < v.size(); i++) {
		if (v[i].y < lo.y + 0.62f * e.y) continue;
		back += long_x ? (v[i].z - c.z) : (v[i].x - c.x); n++;
	}
	const float s = (n > 0 && back / n > 0.0) ? -1.0f : 1.0f;   // the front is away from the back
	r_front = long_x ? Vector3(0, 0, s) : Vector3(s, 0, 0);
}

int type_of(const String &kit) {
	if (kit.begins_with("park_bench") || kit.begins_with("bench_bus_stop")) return R_BENCH;
	if (kit.begins_with("bus_stop_sign")) return R_BUS_SIGN;
	if (kit.begins_with("picnic_table")) return R_PICNIC;
	if (kit.begins_with("patio_set")) return R_PATIO;
	if (kit.begins_with("beach_umbrella") || kit.begins_with("lifeguard_tower")) return R_BEACH;
	if (kit.begins_with("play_structure") || kit.begins_with("bandstand")) return R_PLAY;
	return -1;
}

int people_of(const String &kit) {   // how many live behind a building's door; 0 = not a home
	if (kit.begins_with("houses/")) return 1;
	if (kit.begins_with("apartments/")) return 4;
	if (kit.begins_with("ck/ck_apt")) return 6;
	if (kit.begins_with("urban/twr_condo") || kit.begins_with("urban/twr_hotel")) return 12;
	if (kit.contains("motel") || kit.contains("mod_apt_row")) return 4;
	return 0;
}

uint32_t hash2(float x, float z) {
	uint32_t h = (uint32_t)(int32_t)std::lround(x * 10.0f) * 73856093u ^ (uint32_t)(int32_t)std::lround(z * 10.0f) * 19349663u;
	h ^= h >> 15; h *= 2246822519u; h ^= h >> 13;
	return h;
}

} // namespace

PackedStringArray PeoplePlaces::build(const String &p_streets, const String &p_layout, const String &p_pieces_dir, const String &p_rooms) {
	PackedStringArray rep;
	data = pc::PlaceData();
	const PackedByteArray bytes = FileAccess::get_file_as_bytes(p_streets);
	sg::StreetData d;
	if (bytes.size() < 16 || !d.load(bytes.ptr(), (size_t)bytes.size())) { rep.push_back("PLACES ERROR no streets file: run make_streets.gd first"); return rep; }
	pc::Crowd *cw = new pc::Crowd();
	if (!cw->build(d)) { rep.push_back("PLACES ERROR the streets file has no pavements"); delete cw; return rep; }

	int n_kind[pc::PL_KINDS] = { 0 }, no_walk[pc::PL_KINDS] = { 0 };
	// one place, tied to the pavement nearest to (wx, wz) within max_d; (tx, tz) = where the person ends up
	auto add = [&](int kind, float wx, float wz, float max_d, float tx, float ty, float tz, float yaw, int pose, int sub, int name) -> int {
		float u = 0, dist = 0, ax = 0, az = 0, ay = 0;
		const int seg = cw->nearest_walk(wx, wz, max_d, u, dist, ax, az, ay);
		if (seg < 0) { no_walk[kind]++; return -1; }
		pc::Place p;
		p.kind = (uint8_t)kind; p.sub = (uint8_t)std::min(std::max(sub, 0), 255); p.zone = (uint8_t)cw->segs[seg].zone; p.pose = (uint8_t)pose;
		p.x = tx; p.y = ty; p.z = tz; p.yaw = yaw; p.seg = seg; p.u = u; p.ax = ax; p.az = az; p.name = name;
		if (ty < -900.0f) p.y = ay;
		data.places.push_back(p);
		n_kind[kind]++;
		return (int)data.places.size() - 1;
	};

	// ---- the pieces: their props and buildings, each piece read once
	const Variant lv = JSON::parse_string(FileAccess::get_file_as_string(p_layout));
	if (lv.get_type() != Variant::DICTIONARY) { rep.push_back("PLACES ERROR no layout (" + p_layout + ")"); delete cw; return rep; }
	const Array inst = ((Dictionary)lv).get("instances", Array());
	std::map<std::string, std::vector<Rec>> pieces;
	ResourceLoader *rl = ResourceLoader::get_singleton();
	std::vector<Vector3> patios;   // cafe tables are tied to a shop afterwards
	int n_inst = 0, n_missing = 0, benches_back_to_street = 0, benches = 0;
	for (int ii = 0; ii < inst.size(); ii++) {
		const Dictionary in = inst[ii];
		const String piece = in.get("piece", "");
		const std::string key = piece.utf8().get_data();
		auto it = pieces.find(key);
		if (it == pieces.end()) {
			std::vector<Rec> recs;
			const String path = p_pieces_dir + piece + String(".scn");
			if (rl->exists(path)) {
				Ref<PackedScene> ps = rl->load(path);
				Node *root = ps.is_valid() ? ps->instantiate() : nullptr;
				if (root) {
					Node3D *props = Object::cast_to<Node3D>(root->get_node_or_null(NodePath("Props")));
					if (props) {
						for (int c = 0; c < props->get_child_count(); c++) {
							Node3D *ch = Object::cast_to<Node3D>(props->get_child(c));
							if (!ch) continue;
							String nm = ch->get_name();
							if (!nm.ends_with("_near") || !nm.begins_with("prop_")) continue;
							nm = nm.substr(5, nm.length() - 10);
							const int ty = type_of(nm);
							if (ty < 0) continue;
							const Transform3D base = props->get_transform() * ch->get_transform();
							Rec r; r.type = ty;
							MultiMeshInstance3D *mmi = Object::cast_to<MultiMeshInstance3D>(ch);
							MeshInstance3D *mi = Object::cast_to<MeshInstance3D>(ch);
							if (mmi && mmi->get_multimesh().is_valid()) {
								Ref<MultiMesh> mm = mmi->get_multimesh();
								if (ty == R_BENCH || ty == R_PICNIC) shape_of(mm->get_mesh(), r.front, r.along, r.half);
								for (int k = 0; k < mm->get_instance_count(); k++) { r.xf = base * mm->get_instance_transform(k); recs.push_back(r); }
							} else if (mi) {
								if (ty == R_BENCH || ty == R_PICNIC) shape_of(mi->get_mesh(), r.front, r.along, r.half);
								r.xf = base; recs.push_back(r);
							}
						}
					}
					Node3D *bld = Object::cast_to<Node3D>(root->get_node_or_null(NodePath("Buildings")));
					if (bld) {
						for (int c = 0; c < bld->get_child_count(); c++) {
							Node3D *ch = Object::cast_to<Node3D>(bld->get_child(c));
							if (!ch || !ch->has_meta("kit")) continue;
							const int ppl = people_of(String(ch->get_meta("kit")));
							if (ppl <= 0) continue;
							Rec r; r.type = R_HOME; r.people = ppl; r.xf = bld->get_transform() * ch->get_transform();
							recs.push_back(r);
						}
					}
					memdelete(root);
				}
			} else n_missing++;
			it = pieces.emplace(key, recs).first;
		}
		n_inst++;
		const Array pp = in.get("pos", Array());
		if (pp.size() < 3) continue;
		const Transform3D T(Basis(Vector3(0, 1, 0), Math::deg_to_rad((float)(double)in.get("yaw", 0.0))), Vector3((float)(double)pp[0], (float)(double)pp[1], (float)(double)pp[2]));
		for (const Rec &r : it->second) {
			const Transform3D w = T * r.xf;
			const Vector3 o = w.origin;
			const Vector3 front = w.basis.xform(r.front).normalized(), along = w.basis.xform(r.along).normalized();
			switch (r.type) {
				case R_BENCH: {   // one or two seats, facing the bench's front
					const int seats = r.half >= 0.7f ? 2 : 1;
					for (int k = 0; k < seats; k++) {
						const Vector3 s = o + along * (seats == 2 ? (k ? 0.42f : -0.42f) : 0.0f) + front * 0.08f;
						const int pi = add(pc::PL_BENCH, o.x, o.z, 45.0f, s.x, o.y, s.z, std::atan2(front.x, front.z), pc::POSE_SIT, 0, -1);
						if (pi >= 0 && k == 0) {   // (for the report: does it look at the pavement it is reached from, or away?)
							benches++;
							const pc::Place &p = data.places[pi];
							if ((p.ax - o.x) * front.x + (p.az - o.z) * front.z < 0.0f) benches_back_to_street++;
						}
					}
				} break;
				case R_BUS_SIGN: {
					const int pi = add(pc::PL_BUS, o.x, o.z, 12.0f, o.x, o.y, o.z, 0.0f, pc::POSE_STAND, 0, -1);
					if (pi >= 0) {   // the lane the bus stands in: the nearest lane point within 14 m
						pc::Place &p = data.places[pi];
						float best = 14.0f * 14.0f;
						for (int L = 0; L < d.lanes(); L++) {
							float acc = 0.0f;
							for (int q = d.lane_off[L]; q < d.lane_off[L + 1]; q++) {
								const float *a = &d.lane_pts[(size_t)q * 3];
								if (q > d.lane_off[L]) { const float *b = a - 3; acc += std::sqrt((a[0] - b[0]) * (a[0] - b[0]) + (a[2] - b[2]) * (a[2] - b[2])); }
								const float e2 = (a[0] - o.x) * (a[0] - o.x) + (a[2] - o.z) * (a[2] - o.z);
								if (e2 < best) { best = e2; p.lane = L; p.lane_s = acc; p.yaw = std::atan2(a[0] - p.ax, a[2] - p.az); }
							}
						}
					}
				} break;
				case R_PICNIC: {   // a seat on either side, facing the table
					for (int k = 0; k < 2; k++) {
						const Vector3 f = front * (k ? 1.0f : -1.0f);
						const Vector3 s = o + f * 0.75f;
						add(pc::PL_PARK, o.x, o.z, 60.0f, s.x, o.y, s.z, std::atan2(-f.x, -f.z), pc::POSE_SIT, 0, -1);
					}
				} break;
				case R_PATIO: patios.push_back(o); break;
				case R_BEACH: {   // two places on the sand beside it
					for (int k = 0; k < 2; k++) {
						const Vector3 s = o + w.basis.get_column(0).normalized() * (k ? 1.4f : -1.4f);
						add(pc::PL_BEACH, o.x, o.z, 70.0f, s.x, o.y, s.z, std::atan2(w.basis.get_column(2).x, w.basis.get_column(2).z), pc::POSE_LIE, 0, -1);
					}
				} break;
				case R_PLAY: {   // somebody stands and watches
					for (int k = 0; k < 2; k++) {
						const Vector3 s = o + w.basis.get_column(2).normalized() * 4.5f + w.basis.get_column(0).normalized() * (k ? 1.2f : -1.2f);
						add(pc::PL_PARK, o.x, o.z, 60.0f, s.x, o.y, s.z, std::atan2(o.x - s.x, o.z - s.z), pc::POSE_STAND, 1, -1);
					}
				} break;
				case R_HOME: {   // the door: a few steps off the pavement toward the house
					float u = 0, dist = 0, ax = 0, az = 0, ay = 0;
					if (cw->nearest_walk(o.x, o.z, 40.0f, u, dist, ax, az, ay) < 0) { no_walk[pc::PL_HOME]++; break; }
					const float dx = o.x - ax, dz = o.z - az, dl = std::max(std::sqrt(dx * dx + dz * dz), 0.01f);
					const float in_ = std::min(std::max(dl - 2.0f, 0.6f), 5.0f);
					add(pc::PL_HOME, o.x, o.z, 40.0f, ax + dx / dl * in_, -999.0f, az + dz / dl * in_, std::atan2(dx, dz), pc::POSE_STAND, r.people, -1);
				} break;
			}
		}
	}

	// ---- the shops: every door of the interiors' list, with its kind and name
	int n_rooms = 0;
	std::vector<int> food;   // places that serve (their tables get people with a drink)
	const Variant rv = JSON::parse_string(FileAccess::get_file_as_string(p_rooms));
	if (rv.get_type() == Variant::DICTIONARY) {
		const Array rooms = ((Dictionary)rv).get("rooms", Array());
		for (int i = 0; i < rooms.size(); i++) {
			const Dictionary r = rooms[i];
			const Array pp = r.get("pos", Array());
			if (pp.size() < 3) continue;
			n_rooms++;
			const float wx = (float)(double)pp[0], wz = (float)(double)pp[2];
			const String kind = r.get("kind", "");
			int ki = 7;   // (unknown: a store)
			for (int k = 0; k < pc::N_SHOP_KINDS; k++) if (kind == String(pc::SHOP_KINDS[k])) ki = k;
			float u = 0, dist = 0, ax = 0, az = 0, ay = 0;
			const int seg = cw->nearest_walk(wx, wz, 35.0f, u, dist, ax, az, ay);
			if (seg < 0) { no_walk[pc::PL_SHOP]++; continue; }
			const float dx = wx - ax, dz = wz - az, dl = std::max(std::sqrt(dx * dx + dz * dz), 0.01f);
			const float in_ = std::min(std::max(dl - 0.5f, 0.6f), 3.5f);
			data.names.push_back(std::string(String(r.get("name", "")).utf8().get_data()));
			const int name = (int)data.names.size() - 1;
			const int pi = add(pc::PL_SHOP, wx, wz, 35.0f, ax + dx / dl * in_, -999.0f, az + dz / dl * in_, std::atan2(dx, dz), pc::POSE_STAND, ki, name);
			if (pi < 0) continue;
			if (kind == "bar" || kind == "restaurant" || kind == "cafe" || kind == "bakery" || kind == "ice_cream" || kind == "fast_food") food.push_back(pi);
			// a beggar beside about every fifth door of a busy street, on the building's side of the pavement, facing the people
			const pc::Seg &S = cw->segs[seg];
			if ((S.zone == 2 || S.zone == 4) && hash2(wx, wz) % 5u == 0u) {
				const float off = std::max(S.hw - 0.15f, 0.3f);
				add(pc::PL_BEG, ax, az, 3.0f, ax + dx / dl * off + dz / dl * 1.6f, -999.0f, az + dz / dl * off - dx / dl * 1.6f, std::atan2(-dx, -dz), pc::POSE_SIT, 0, -1);
			}
		}
	}
	// cafe tables within 18 m of a place that serves: two seats each, facing each other
	for (const Vector3 &o : patios) {
		int best = -1; float bd = 18.0f * 18.0f;
		for (int pi : food) { const pc::Place &p = data.places[pi]; const float e2 = (p.x - o.x) * (p.x - o.x) + (p.z - o.z) * (p.z - o.z); if (e2 < bd) { bd = e2; best = pi; } }
		if (best < 0) continue;
		for (int k = 0; k < 2; k++) {
			const float sx = o.x + (k ? 0.7f : -0.7f);
			add(pc::PL_CAFE, o.x, o.z, 30.0f, sx, o.y, o.z, k ? -1.5708f : 1.5708f, pc::POSE_SIT, data.places[best].sub, data.places[best].name);
		}
	}
	// ---- the gates (where a pavement ends: the bridge, the map's edge) and the night's corners
	for (int n = 0; n < (int)cw->node_segs.size(); n++) {
		const std::vector<int32_t> &ns = cw->node_segs[n];
		const float nx = cw->node_xz[(size_t)n * 2], nz = cw->node_xz[(size_t)n * 2 + 1];
		if (ns.size() == 1 && cw->segs[ns[0]].kind == 0) add(pc::PL_GATE, nx, nz, 3.0f, nx, -999.0f, nz, 0.0f, pc::POSE_STAND, 0, -1);
		bool lit = false, busy = false;
		for (int k : ns) { const pc::Seg &S = cw->segs[k]; if (S.kind == 1 && S.phase >= 0) lit = true; if (S.kind == 0 && (S.zone == 2 || S.zone == 4)) busy = true; }
		if (lit && busy && hash2(nx, nz) % 4u == 0u) add(pc::PL_NIGHT, nx, nz, 3.0f, nx, -999.0f, nz, 0.0f, pc::POSE_STAND, 0, -1);
	}

	rep.push_back(vformat("PLACES read %d pieces placed (%d different, %d not found), %d shop doors", n_inst, (int)pieces.size(), n_missing, n_rooms));
	static const char *const KN[pc::PL_KINDS] = { "home doors", "shop doors", "beach places", "park places", "gates", "bus stops", "bench seats", "cafe seats", "beggars' spots", "night corners" };
	String line = "PLACES found:";
	int total = 0;
	for (int k = 0; k < pc::PL_KINDS; k++) { line += vformat(" %d %s,", n_kind[k], KN[k]); total += n_kind[k]; }
	rep.push_back(line + vformat(" %d in all", total));
	line = "PLACES left out (no pavement near enough):";
	for (int k = 0; k < pc::PL_KINDS; k++) if (no_walk[k]) line += vformat(" %d %s,", no_walk[k], KN[k]);
	rep.push_back(line);
	int bus_no_lane = 0;
	for (const pc::Place &p : data.places) if (p.kind == pc::PL_BUS && p.lane < 0) bus_no_lane++;
	rep.push_back(vformat("PLACES bus stops with no lane within 14 m: %d", bus_no_lane));
	rep.push_back(vformat("PLACES benches: %d, of which %d turn their back to the pavement they are reached from", benches, benches_back_to_street));
	delete cw;
	return rep;
}

bool PeoplePlaces::save(const String &p_path) {
	std::vector<uint8_t> o;
	data.save(o);
	Ref<FileAccess> f = FileAccess::open(p_path, FileAccess::WRITE);
	if (f.is_null()) return false;
	PackedByteArray b; b.resize((int64_t)o.size());
	std::memcpy(b.ptrw(), o.data(), o.size());
	f->store_buffer(b);
	return true;
}

int PeoplePlaces::count() const { return (int)data.places.size(); }

void PeoplePlaces::_bind_methods() {
	ClassDB::bind_method(D_METHOD("build", "streets_bin", "layout_json", "pieces_dir", "rooms_json"), &PeoplePlaces::build);
	ClassDB::bind_method(D_METHOD("save", "path"), &PeoplePlaces::save);
	ClassDB::bind_method(D_METHOD("count"), &PeoplePlaces::count);
}

} // namespace godot
