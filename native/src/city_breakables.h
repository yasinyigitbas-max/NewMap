// CityBreakables: small street props that cars knock over (B9, Yasin 20 Nov: "small props should be breakable"; the old
// game's rule, world_fx/breakables.gd: only cars break them - never the player on foot or people).
//  - WHAT: the bake keeps the near copies of a few kinds (bus-stop and beach signs, cones, mailbox posts, steel and iron
//    bollards, bins, newsboxes, parking meters: bake_runtime.gd BRK_KINDS) whole, in nodes named brk_<kind> per cell,
//    with their colliders on the node (meta "brk_cols") instead of in the cell's bodies.
//  - STANDING: drawn by those nodes; the ones within POOL_R of the camera get colliders from a pool of POOL static bodies
//    (the player cannot walk through a bollard; the rest have none: nothing else touches them).
//  - KNOCKED: a car (the player's - the group "vehicles" - or the traffic's, CityTraffic::cars_near) faster than
//    BREAK_SPEED within reach of one: the standing copy is hidden (its instance scaled to nothing), its collider let go,
//    and a physical copy (one of DEBRIS rigid bodies) is thrown the way the car goes, tipping over its foot.
//  - PUT BACK, never in sight: after RESET_S, once neither its spot nor its debris is in the camera's view.
// Made by CityStream (a child of it); follows its cells (cell_in / cell_out).
#pragma once
#include <godot_cpp/classes/node3d.hpp>
#include <godot_cpp/templates/hash_map.hpp>
#include <vector>

namespace godot {

class MultiMeshInstance3D;
class RigidBody3D;
class MeshInstance3D;
class CollisionShape3D;
class CityStream;

class CityBreakables : public Node3D {
	GDCLASS(CityBreakables, Node3D)
	static constexpr int POOL = 32, DEBRIS = 12;
	static constexpr float POOL_R = 30.0f, BREAK_SPEED = 3.0f, RESET_S = 6.0f;
	struct Item {
		uint64_t mmi = 0; int idx = 0; String cell; Transform3D home; Vector3 at; float radius = 0.3f, height = 1.0f, mass = 15.0f;
		PackedVector3Array pts; Transform3D col_xf; bool has_col = false;
		bool broken = false; float down_t = 0.0f; int debris = -1; int pool = -1;
	};
	std::vector<Item> items;
	HashMap<String, std::vector<int>> by_cell;
	std::vector<int> free_slots;
	std::vector<String> arriving;   // cells that came in, not yet looked at
	RID pool_body[POOL]; int pool_item[POOL] = {};
	HashMap<int64_t, RID> shape_cache;      // hash of a collider's points -> its convex shape
	struct Debris { RigidBody3D *body = nullptr; MeshInstance3D *mi = nullptr; CollisionShape3D *cs = nullptr; int item = -1; float t = 0.0f; };
	Debris debris[DEBRIS];
	uint64_t stream_id = 0, traffic_id = 0;
	bool made = false; int frame = 0; int broken_n = 0; int traffic_look = -1000;      // (the frame the traffic was last looked for)
	void make();
	void add_cell(const String &p_key);
	void drop_cell(const String &p_key);
	void knock(int i, const Vector3 &p_vel);
	void put_back(int i);
	RID shape_for(const PackedVector3Array &p_pts);
	void pool_update(const Vector3 &p_cam);
	void hits(const Vector3 &p_cam);
	void set_instance(Item &it, bool p_shown);
protected:
	static void _bind_methods();
public:
	CityBreakables() { for (int k = 0; k < POOL; k++) pool_item[k] = -1; }
	void set_stream(Object *p_stream);
	void _on_cell_in(const String &p_key) { arriving.push_back(p_key); }   // (taken in a frame later, one a frame: the cell's own arrival frame is the streamer's)
	void _on_cell_out(const String &p_key) { drop_cell(p_key); }
	Dictionary get_state() const;
	void _process(double p_delta) override;
	void _exit_tree() override;
};

} // namespace godot
