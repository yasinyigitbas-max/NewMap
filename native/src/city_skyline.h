// CitySkyline: the painted ring of San Diego round the horizon - a C++ port of tools/city/look/skyline.gd (the Hospital /
// coordinator session's, 20 Nov; Yasin: "PLACE FLAT CARD ACCURATE VIEWS OF SAN DIEGO TO ALL FOUR SIDES ... ALWAYS DISPLAYED,
// IMMUNE TO THE LOD, EVER VISIBLE"; code work is C++). One mesh, one material, ONE DRAW: a far ring by direction only
// (mountains, Tijuana, the islands, the haze), a near ring at the real distances (downtown, the shipyards, North Island,
// Point Loma: parallax as the camera crosses the island), and the bridge and Coronado Shores as boxes at their places.
// Data: map_dc/coronado/city_kit/skyline/ (skyline.json, skyline_day.png, skyline_lights.png; tools/city/look/
// make_skyline.py). Shader: tools/city/look/skyline.gdshader (drawn at the far end of the depth range). Never culled:
// a 200 km custom AABB, no range, no shadow. CityStream adds one next to the far world (property skyline); the look tints
// it through get_skyline_material().
#pragma once
#include <godot_cpp/classes/mesh_instance3d.hpp>
#include <godot_cpp/classes/shader_material.hpp>

namespace godot {

class CitySkyline : public MeshInstance3D {
	GDCLASS(CitySkyline, MeshInstance3D)
protected:
	static void _bind_methods();
public:
	static Ref<ShaderMaterial> get_skyline_material();
	void build();
	void _exit_tree() override;
	int tris = 0;
	int get_tris() const { return tris; }
};

} // namespace godot
