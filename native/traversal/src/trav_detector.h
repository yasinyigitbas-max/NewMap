// Detection (the study, stage 7): "one measuring routine". A line-for-line translation of
// traversal_lab/traversal/detect/detector.gd (the script version, the reference): the same names, the same numbers,
// the same order of queries. The reasons for each thing are in the script.
#pragma once

#include <godot_cpp/classes/capsule_shape3d.hpp>
#include <godot_cpp/classes/character_body3d.hpp>
#include <godot_cpp/classes/physics_direct_space_state3d.hpp>
#include <godot_cpp/classes/physics_shape_query_parameters3d.hpp>
#include <godot_cpp/classes/ref_counted.hpp>
#include <godot_cpp/classes/sphere_shape3d.hpp>
#include <godot_cpp/variant/dictionary.hpp>
#include <godot_cpp/variant/vector3.hpp>

namespace godot {

class TravDetector : public RefCounted {
	GDCLASS(TravDetector, RefCounted)

public:
	static constexpr double R = 0.03;
	static constexpr double R_FWD = 0.05;
	static constexpr double REACH = 1.5;
	static constexpr double CLIMB_MOST = 3.0;
	static constexpr double LOOK_UP = 3.3;
	static constexpr double DEPTH_MOST = 4.3;
	static constexpr double WIDTH_MOST = 1.6;
	static constexpr double GAP_MOST = 3.0;
	static constexpr double DROP_MOST = 3.5;
	static constexpr double SAME_TOP = 0.08;
	static constexpr double THIN_UNDER = 0.5;
	static constexpr double WALK_SLOPE_DEG = 50.0;
	static constexpr double STEP_DOWN = 0.30;

private:
	CharacterBody3D *body = nullptr;
	PhysicsDirectSpaceState3D *_space = nullptr;
	Ref<SphereShape3D> _shape;
	Ref<CapsuleShape3D> _capsule;
	int queries = 0;

	Ref<PhysicsShapeQueryParameters3D> _q(double r, const Vector3 &at, const Vector3 &motion);
	double _sweep(const Vector3 &at, const Vector3 &motion, double r = R);
	double _down(const Vector3 &at, double reach);
	double _step_down(const Vector3 &from, const Vector3 &to, double reach);
	Dictionary _wall(const Vector3 &col, double ground, const Vector3 &dir);
	Dictionary _follow(const Vector3 &start, const Vector3 &way, double top_y, double most, double step);
	double _ground_end(const Vector3 &from, const Vector3 &way, double ground, double most, double first, double step = STEP_DOWN);
	Dictionary _edge(const Vector3 &col, double ground, const Vector3 &dir, double gap_most = GAP_MOST, double step = STEP_DOWN, double far_down = STEP_DOWN);

protected:
	static void _bind_methods();

public:
	TravDetector();
	void set_body(CharacterBody3D *b) { body = b; }
	CharacterBody3D *get_body() const { return body; }
	void set_queries(int q) { queries = q; }
	int get_queries() const { return queries; }
	bool _fits(const Vector3 &feet, double tall);
	Dictionary measure(Vector3 dir, double from_y = INFINITY, double gap_most = GAP_MOST);
	Dictionary measure_edge(Vector3 dir, double gap_most = GAP_MOST, double step = STEP_DOWN, double far_down = STEP_DOWN);
};

} // namespace godot
