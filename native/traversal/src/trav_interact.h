// Moves on things in the world that are not climbed: doors (stage 22), cars (stage 23), sitting, cover (stage 21).
// A line-for-line translation of traversal_lab/traversal/moves/interact.gd (the script version, the reference): the
// same names, the same numbers, the same order of work. The reasons for each thing are in the script.
#pragma once

#include <godot_cpp/classes/character_body3d.hpp>
#include <godot_cpp/classes/node.hpp>
#include <godot_cpp/classes/node3d.hpp>
#include <godot_cpp/variant/array.hpp>
#include <godot_cpp/variant/dictionary.hpp>
#include <godot_cpp/variant/packed_float32_array.hpp>
#include <godot_cpp/variant/vector3.hpp>

namespace godot {

class TravInteract : public Node {
	GDCLASS(TravInteract, Node)

public:
#include "trav_interact_consts.inc"

	CharacterBody3D *body = nullptr;
	bool enabled = true;
	int plays = 0;
	String last;
	bool in_car = false;
	String in_cover;
	String cover_phase;
	bool seated = false;
	String sit_phase;

protected:
	Dictionary _plan;
	Dictionary _along;
	double _fps = 30.0;
	Dictionary _len;
	Dictionary _yaw;
	Dictionary _dir;
	Node3D *_to_car = nullptr;
	Dictionary _to_cover;
	Node3D *_to_seat = nullptr;
	double _walked = 0.0;

	double _rot_y() const { return (double)body->get_rotation().y; }
	void _load(const String &clip);
	double _at(const PackedFloat32Array &table, double t);
	double _keyed(const Array &keys, double t);
	bool _try_door(const Vector3 &dir);
	Vector3 _seat_side(Node3D *seat);
	bool _try_seat();
	void _walk_to_seat(double dt);
	Array _travel(const String &clip, double t);
	Vector3 _line(const String &clip, const Vector3 &fwd);
	bool _try_car();
	void _walk_to_car(double dt);
	Dictionary _ray(const Vector3 &from, const Vector3 &to);
	double _cover_wall(const Vector3 &at, const Vector3 &n);
	bool _cover_on(const Vector3 &at, const Vector3 &way, const Vector3 &n);
	bool _try_cover();
	void _walk_to_cover(double dt);
	double _drop_for(double head, double high);

	static void _bind_methods();
	bool _get(const StringName &p_name, Variant &r_ret) const;
	bool _set(const StringName &p_name, const Variant &p_value);

public:
	TravInteract();
	void _ready() override;
	void _physics_process(double dt) override;
	Vector3 _seat_stand(Node3D *seat);
	Array _car_start(Node3D *car);
	// where the body is `t` seconds into each move (handed to the body's begin_move)
	Dictionary _door(double t);
	Dictionary _sit(double t);
	Dictionary _car(double t);
	Dictionary _cover(double t);
};

} // namespace godot
