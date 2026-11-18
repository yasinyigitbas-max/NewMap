// StreetGraph: see street_graph.h
#include "street_graph.h"

#include <godot_cpp/classes/dir_access.hpp>
#include <godot_cpp/classes/file_access.hpp>
#include <godot_cpp/classes/json.hpp>
#include <godot_cpp/classes/mesh.hpp>
#include <godot_cpp/classes/mesh_instance3d.hpp>
#include <godot_cpp/classes/multi_mesh.hpp>
#include <godot_cpp/classes/multi_mesh_instance3d.hpp>
#include <godot_cpp/classes/node.hpp>
#include <godot_cpp/classes/node3d.hpp>
#include <godot_cpp/classes/packed_scene.hpp>
#include <godot_cpp/classes/resource_loader.hpp>
#include <godot_cpp/core/class_db.hpp>
#include <godot_cpp/core/memory.hpp>
#include <godot_cpp/variant/array.hpp>
#include <godot_cpp/variant/color.hpp>
#include <godot_cpp/variant/packed_byte_array.hpp>
#include <godot_cpp/variant/packed_color_array.hpp>
#include <godot_cpp/variant/packed_int32_array.hpp>
#include <godot_cpp/variant/packed_string_array.hpp>
#include <godot_cpp/variant/packed_vector2_array.hpp>
#include <godot_cpp/variant/packed_vector3_array.hpp>
#include <godot_cpp/variant/transform3d.hpp>
#include <godot_cpp/variant/utility_functions.hpp>

#include <cmath>
#include <cstring>

namespace godot {

namespace {

// a node's transform in the cell (the cell root is at the origin of the grid frame)
Transform3D xf_in_cell(Node *p_node, Node *p_root) {
	Transform3D xf;
	for (Node *n = p_node; n != nullptr && n != p_root; n = n->get_parent()) {
		Node3D *n3 = Object::cast_to<Node3D>(n);
		if (n3) xf = n3->get_transform() * xf;
	}
	Node3D *r3 = Object::cast_to<Node3D>(p_root);
	if (r3) xf = r3->get_transform() * xf;
	return xf;
}

float half_to_float(uint16_t h) {
	const uint32_t s = (h >> 15) & 1u, e = (h >> 10) & 0x1Fu, m = h & 0x3FFu;
	uint32_t f;
	if (e == 0) {
		if (m == 0) f = s << 31;
		else {
			uint32_t mm = m, ee = 0;
			while (!(mm & 0x400u)) { mm <<= 1; ee++; }
			f = (s << 31) | ((127 - 15 - ee + 1) << 23) | ((mm & 0x3FFu) << 13);
		}
	} else if (e == 31) f = (s << 31) | 0x7F800000u | (m << 13);
	else f = (s << 31) | ((e + 127 - 15) << 23) | (m << 13);
	float out;
	std::memcpy(&out, &f, 4);
	return out;
}

} // namespace

void StreetGraph::read_cell(Node *p_root, int p_cell) {
	// the stalls the bake carried over from the pieces: [x, y, z, yaw, grade] in the grid frame
	if (p_root->has_meta(StringName("stalls"))) {
		Array st = p_root->get_meta(StringName("stalls"));
		for (int i = 0; i < st.size(); i++) {
			Array s = st[i];
			if (s.size() < 4) continue;
			for (int k = 0; k < 4; k++) stalls.push_back((float)(double)s[k]);
			stalls.push_back(s.size() >= 5 ? (float)(double)s[4] : 0.0f);
			stalls.push_back((float)p_cell);
		}
	}
	// the ground: the bake's joined mesh (surface kind per vertex in UV2.x), and any ground kept as built
	Node *gn = p_root->get_node_or_null(NodePath("Ground"));
	if (gn) {
		for (int ci = 0; ci < gn->get_child_count(); ci++) {
			MeshInstance3D *mi = Object::cast_to<MeshInstance3D>(gn->get_child(ci));
			if (mi == nullptr || mi->get_mesh().is_null()) continue;
			const Transform3D xf = xf_in_cell(mi, p_root);
			Ref<Mesh> mesh = mi->get_mesh();
			const bool joined = String(mi->get_name()) == "ground";
			if (!joined) grounds_other++;
			for (int si = 0; si < mesh->get_surface_count(); si++) {
				Array arr = mesh->surface_get_arrays(si);
				if (arr.size() <= Mesh::ARRAY_INDEX) continue;
				PackedVector3Array v = arr[Mesh::ARRAY_VERTEX];
				PackedInt32Array ix = arr[Mesh::ARRAY_INDEX];
				PackedVector2Array u2;
				if (joined && arr[Mesh::ARRAY_TEX_UV2].get_type() == Variant::PACKED_VECTOR2_ARRAY) u2 = arr[Mesh::ARRAY_TEX_UV2];
				const int nv = (int)v.size();
				const int ni = ix.size() > 0 ? (int)ix.size() : nv;
				for (int t = 0; t + 2 < ni; t += 3) {
					const int i0 = ix.size() > 0 ? ix[t] : t, i1 = ix.size() > 0 ? ix[t + 1] : t + 1, i2 = ix.size() > 0 ? ix[t + 2] : t + 2;
					if (i0 >= nv || i1 >= nv || i2 >= nv) continue;
					const Vector3 a = xf.xform(v[i0]), b = xf.xform(v[i1]), c = xf.xform(v[i2]);
					const float fa[3] = { a.x, a.y, a.z }, fb[3] = { b.x, b.y, b.z }, fc[3] = { c.x, c.y, c.z };
					int layer = sg::G_OTHER;
					if (u2.size() == nv) layer = (int)std::lround(u2[i0].x);
					ground.add(fa, fb, fc, layer);
				}
			}
		}
	}
	// signal heads: the bake flags them per prop (rt_prop.gdshaderinc: flags 4), merged (CUSTOM0) or instanced
	Node *pn = p_root->get_node_or_null(NodePath("Props"));
	if (pn) {
		for (int ci = 0; ci < pn->get_child_count(); ci++) {
			Node *ch = pn->get_child(ci);
			MeshInstance3D *mi = Object::cast_to<MeshInstance3D>(ch);
			if (mi && mi->get_mesh().is_valid()) {
				const Transform3D xf = xf_in_cell(mi, p_root);
				Ref<Mesh> mesh = mi->get_mesh();
				for (int si = 0; si < mesh->get_surface_count(); si++) {
					Array arr = mesh->surface_get_arrays(si);
					if (arr.size() <= Mesh::ARRAY_CUSTOM0) continue;
					const Variant c0 = arr[Mesh::ARRAY_CUSTOM0];
					float lx = 1e9f, lz = 1e9f;
					auto take = [&](float ox, float oy, float oz, float w) {
						const int fl = (int)std::floor(std::fmod(w, 16.0f) / 2.0f);
						if (fl < 4) return;
						if (std::fabs(ox - lx) < 0.05f && std::fabs(oz - lz) < 0.05f) return;   // the same prop's next vertex
						lx = ox; lz = oz;
						const Vector3 p = xf.xform(Vector3(ox, oy, oz));
						for (size_t k = 0; k + 2 < signals.size(); k += 3) {
							if (std::fabs(signals[k] - p.x) < 0.1f && std::fabs(signals[k + 2] - p.z) < 0.1f) return;
						}
						signals.push_back(p.x); signals.push_back(p.y); signals.push_back(p.z);
					};
					if (c0.get_type() == Variant::PACKED_BYTE_ARRAY) {   // half floats, 4 per vertex
						PackedByteArray b = c0;
						const uint8_t *d = b.ptr();
						for (int64_t k = 0; k + 7 < b.size(); k += 8) {
							uint16_t h[4];
							std::memcpy(h, d + k, 8);
							take(half_to_float(h[0]), half_to_float(h[1]), half_to_float(h[2]), half_to_float(h[3]));
						}
					} else if (c0.get_type() == Variant::PACKED_FLOAT32_ARRAY) {
						PackedFloat32Array f = c0;
						for (int64_t k = 0; k + 3 < f.size(); k += 4) take(f[k], f[k + 1], f[k + 2], f[k + 3]);
					}
				}
			}
			MultiMeshInstance3D *mmi = Object::cast_to<MultiMeshInstance3D>(ch);
			if (mmi && mmi->get_multimesh().is_valid() && mmi->get_multimesh()->is_using_custom_data()) {
				const Transform3D xf = xf_in_cell(mmi, p_root);
				Ref<MultiMesh> mm = mmi->get_multimesh();
				for (int i = 0; i < mm->get_instance_count(); i++) {
					const Color cd = mm->get_instance_custom_data(i);
					if (cd.b < 3.5f) continue;
					const Vector3 p = xf.xform(mm->get_instance_transform(i).origin);
					signals.push_back(p.x); signals.push_back(p.y); signals.push_back(p.z);
				}
			}
		}
	}
}

int StreetGraph::load_bake(const String &p_runtime_dir) {
	ground = sg::Ground();
	stalls.clear(); signals.clear(); cell_xz.clear(); cells_read = 0; grounds_other = 0;
	const String dir = p_runtime_dir.path_join("cells");
	PackedStringArray files = DirAccess::get_files_at(dir);
	for (int i = 0; i < files.size(); i++) {
		const String f = files[i];
		if (!f.ends_with(".scn")) continue;
		Ref<PackedScene> ps = ResourceLoader::get_singleton()->load(dir.path_join(f));
		if (ps.is_null()) continue;
		Node *root = ps->instantiate();
		if (root == nullptr) continue;
		read_cell(root, cells_read);
		memdelete(root);
		const PackedStringArray nm = f.get_basename().split("_");   // cell_X_Z
		cell_xz.push_back(nm.size() >= 3 ? (int32_t)nm[1].to_int() : 0); cell_xz.push_back(nm.size() >= 3 ? (int32_t)nm[2].to_int() : 0);
		cells_read++;
	}
	ground.build();
	return cells_read;
}

Dictionary StreetGraph::stats() const {
	Dictionary d;
	d["cells"] = cells_read;
	d["ground_triangles"] = ground.count();
	d["grounds_kept_as_built"] = grounds_other;
	d["stalls"] = (int)(stalls.size() / 6);
	d["signal_heads"] = (int)(signals.size() / 3);
	int per[11] = { 0 };
	for (int i = 0; i < ground.count(); i++) {
		const int l = ground.layer[i];
		per[l >= 0 && l < 10 ? l : 10]++;
	}
	PackedInt32Array pl;
	for (int k = 0; k < 11; k++) pl.push_back(per[k]);
	d["triangles_by_kind"] = pl;
	return d;
}

PackedStringArray StreetGraph::build(const String &p_sites_json) {
	PackedStringArray lines;
	const Variant parsed = JSON::parse_string(FileAccess::get_file_as_string(p_sites_json));
	if (parsed.get_type() != Variant::DICTIONARY) {
		lines.push_back("STREETS ERROR cannot read " + p_sites_json);
		return lines;
	}
	const Dictionary d = parsed;
	builder = sg::Builder();
	builder.ground = &ground;
	builder.stalls = stalls; builder.signals = signals; builder.cell_xz = cell_xz;
	const Array jn = d.get("nodes", Array());
	for (int i = 0; i < jn.size(); i++) {
		const Dictionary n = jn[i];
		sg::SkNode sn;
		sn.x = (double)n.get("u", 0.0); sn.z = (double)n.get("v", 0.0); sn.pad = (double)n.get("pad", 0.0);
		builder.nodes.push_back(sn);
	}
	const Array jb = d.get("blocks", Array());
	for (int i = 0; i < jb.size(); i++) {
		const Dictionary b = jb[i];
		sg::SkBlock sb;
		sb.id = String(b.get("id", "")).utf8().get_data();
		sb.name = String(b.get("name", "")).utf8().get_data();
		sb.section = String(b.get("section", "")).utf8().get_data();
		const Variant pv = b.get("pts", Variant());
		Array pts;
		if (pv.get_type() == Variant::ARRAY && Array(pv).size() >= 2) pts = pv;
		else { pts.push_back(b.get("a", Array())); pts.push_back(b.get("b", Array())); }
		for (int k = 0; k < pts.size(); k++) {
			const Array q = pts[k];
			if (q.size() < 2) continue;
			sb.pts.push_back((double)q[0]); sb.pts.push_back((double)q[1]);
		}
		if (sb.pts.size() >= 4) builder.blocks.push_back(sb);
	}
	builder.build();
	for (const std::string &l : builder.rep.lines) lines.push_back(String::utf8(l.c_str()));
	return lines;
}

PackedFloat32Array StreetGraph::profile(const Vector3 &p_from, const Vector3 &p_to, double p_step) const {
	PackedFloat32Array out;
	const double len = Vector2(p_to.x - p_from.x, p_to.z - p_from.z).length();
	const int n = (int)std::floor(len / (p_step > 0.01 ? p_step : 0.01)) + 1;
	for (int i = 0; i < n; i++) {
		const double u = len > 1e-9 ? (i * p_step) / len : 0.0;
		const float x = (float)(p_from.x + (p_to.x - p_from.x) * u), z = (float)(p_from.z + (p_to.z - p_from.z) * u);
		float y = 0.0f; int l = sg::G_NONE;
		if (!ground.query(x, z, y, l)) { l = sg::G_NONE; y = 0.0f; }
		out.push_back((float)l); out.push_back(y);
	}
	return out;
}

Ref<Image> StreetGraph::layer_image(double p_x0, double p_z0, double p_x1, double p_z1, double p_m_per_px) const {
	const int w = (int)std::ceil((p_x1 - p_x0) / p_m_per_px), h = (int)std::ceil((p_z1 - p_z0) / p_m_per_px);
	Ref<Image> img = Image::create_empty(w > 1 ? w : 1, h > 1 ? h : 1, false, Image::FORMAT_RGB8);
	static const Color COL[11] = { Color(0.23, 0.23, 0.25), Color(0.72, 0.72, 0.70), Color(0.36, 0.55, 0.28), Color(0.62, 0.52, 0.36), Color(0.82, 0.76, 0.62),
		Color(1.0, 1.0, 1.0), Color(1.0, 0.82, 0.1), Color(0.5, 0.48, 0.45), Color(0.9, 0.84, 0.62), Color(0.55, 0.3, 0.55), Color(0.05, 0.08, 0.12) };
	for (int py = 0; py < h; py++) {
		for (int px = 0; px < w; px++) {
			const int l = ground.layer_at((float)(p_x0 + (px + 0.5) * p_m_per_px), (float)(p_z0 + (py + 0.5) * p_m_per_px));
			img->set_pixel(px, py, COL[l >= 0 && l < 10 ? l : 10]);
		}
	}
	return img;
}

namespace {
void line(Ref<Image> img, double ax, double ay, double bx, double by, const Color &c) {
	const int w = img->get_width(), h = img->get_height();
	const int n = (int)std::ceil(std::fmax(std::fabs(bx - ax), std::fabs(by - ay))) + 1;
	for (int i = 0; i <= n; i++) {
		const int x = (int)std::lround(ax + (bx - ax) * i / n), y = (int)std::lround(ay + (by - ay) * i / n);
		if (x >= 0 && y >= 0 && x < w && y < h) img->set_pixel(x, y, c);
	}
}
void dot(Ref<Image> img, double x, double y, int r, const Color &c) {
	const int w = img->get_width(), h = img->get_height();
	for (int dy = -r; dy <= r; dy++) {
		for (int dx = -r; dx <= r; dx++) {
			const int px = (int)std::lround(x) + dx, py = (int)std::lround(y) + dy;
			if (dx * dx + dy * dy <= r * r && px >= 0 && py >= 0 && px < w && py < h) img->set_pixel(px, py, c);
		}
	}
}
} // namespace

Ref<Image> StreetGraph::lanes_image(double p_x0, double p_z0, double p_x1, double p_z1, double p_m_per_px) const {
	Ref<Image> img = layer_image(p_x0, p_z0, p_x1, p_z1, p_m_per_px);
	const sg::StreetData &d = builder.out;
	const double k = 1.0 / p_m_per_px;
	auto X = [&](float x) { return (x - p_x0) * k; };
	auto Y = [&](float z) { return (z - p_z0) * k; };
	const int nl = d.lanes();
	// the paths through the junctions as they are driven: straight on green, left orange, right light blue
	std::vector<float> pp;
	for (int c = 0; c < d.connections(); c++) {
		const int a = d.conns[(size_t)c * sg::StreetData::CONN], b = d.conns[(size_t)c * sg::StreetData::CONN + 1], turn = d.conns[(size_t)c * sg::StreetData::CONN + 2];
		if (a < 0 || b < 0 || a >= nl || b >= nl) continue;
		pp.clear();
		d.path(c, pp);
		const Color col = turn == 0 ? Color(0.2, 1.0, 0.3) : (turn == 1 ? Color(1.0, 0.55, 0.1) : Color(0.3, 0.8, 1.0));
		for (size_t q = 0; q + 5 < pp.size(); q += 3) line(img, X(pp[q]), Y(pp[q + 2]), X(pp[q + 3]), Y(pp[q + 5]), col);
	}
	// pavements yellow-green, crossings magenta
	for (size_t sgi = 0; sgi + 7 < d.walk_seg.size(); sgi += 8) {
		const int p0 = d.walk_seg[sgi + 6], np = d.walk_seg[sgi + 7];
		const Color col = d.walk_seg[sgi + 2] == 1 ? Color(1.0, 0.1, 0.9) : Color(0.75, 1.0, 0.1);
		for (int q = p0; q + 1 < p0 + np; q++) line(img, X(d.walk_pts[q * 3]), Y(d.walk_pts[q * 3 + 2]), X(d.walk_pts[q * 3 + 3]), Y(d.walk_pts[q * 3 + 5]), col);
	}
	for (size_t wn = 0; wn + 1 < d.walk_node.size(); wn += 2) dot(img, X(d.walk_node[wn]), Y(d.walk_node[wn + 1]), p_m_per_px < 0.5 ? 2 : 0, Color(0.75, 1.0, 0.1));
	// stalls: at the kerb light blue, in car parks grey
	for (size_t k = 0; k * 8 + 7 < d.stall_f.size(); k++) {
		dot(img, X(d.stall_f[k * 8]), Y(d.stall_f[k * 8 + 2]), p_m_per_px < 0.5 ? 3 : 0, d.stall_i[k * 4] == 0 ? Color(0.3, 0.9, 1.0) : Color(0.55, 0.55, 0.6));
	}
	for (int i = 0; i < nl; i++) {
		const Color col = d.lane_i[(size_t)i * 12 + 1] == 0 ? Color(1.0, 0.2, 0.2) : Color(0.25, 0.45, 1.0);
		for (int q = d.lane_off[i]; q + 1 < d.lane_off[i + 1]; q++) {
			line(img, X(d.lane_pts[q * 3]), Y(d.lane_pts[q * 3 + 2]), X(d.lane_pts[q * 3 + 3]), Y(d.lane_pts[q * 3 + 5]), col);
		}
		const int e = d.lane_off[i + 1] - 1, ctl = d.lane_i[(size_t)i * 12 + 9];
		// where the lane ends: red = signal, white = stop, grey = free
		dot(img, X(d.lane_pts[e * 3]), Y(d.lane_pts[e * 3 + 2]), p_m_per_px < 0.5 ? 3 : 1, ctl == 2 ? Color(1, 0, 0.6) : (ctl == 1 ? Color(1, 1, 1) : Color(0.6, 0.6, 0.6)));
	}
	return img;
}

bool StreetGraph::save(const String &p_path) const {
	std::vector<uint8_t> bytes;
	builder.out.save(bytes);
	Ref<FileAccess> f = FileAccess::open(p_path, FileAccess::WRITE);
	if (f.is_null()) return false;
	PackedByteArray b;
	b.resize((int64_t)bytes.size());
	std::memcpy(b.ptrw(), bytes.data(), bytes.size());
	f->store_buffer(b);
	return true;
}

PackedFloat32Array StreetGraph::get_stalls() const {
	PackedFloat32Array out;
	out.resize((int64_t)stalls.size());
	if (!stalls.empty()) std::memcpy(out.ptrw(), stalls.data(), stalls.size() * sizeof(float));
	return out;
}

PackedFloat32Array StreetGraph::get_signals() const {
	PackedFloat32Array out;
	out.resize((int64_t)signals.size());
	if (!signals.empty()) std::memcpy(out.ptrw(), signals.data(), signals.size() * sizeof(float));
	return out;
}

void StreetGraph::_bind_methods() {
	ClassDB::bind_method(D_METHOD("load_bake", "runtime_dir"), &StreetGraph::load_bake);
	ClassDB::bind_method(D_METHOD("stats"), &StreetGraph::stats);
	ClassDB::bind_method(D_METHOD("build", "sites_json"), &StreetGraph::build);
	ClassDB::bind_method(D_METHOD("profile", "from", "to", "step"), &StreetGraph::profile);
	ClassDB::bind_method(D_METHOD("layer_image", "x0", "z0", "x1", "z1", "m_per_px"), &StreetGraph::layer_image);
	ClassDB::bind_method(D_METHOD("lanes_image", "x0", "z0", "x1", "z1", "m_per_px"), &StreetGraph::lanes_image);
	ClassDB::bind_method(D_METHOD("save", "path"), &StreetGraph::save);
	ClassDB::bind_method(D_METHOD("get_stalls"), &StreetGraph::get_stalls);
	ClassDB::bind_method(D_METHOD("get_signals"), &StreetGraph::get_signals);
}

} // namespace godot
