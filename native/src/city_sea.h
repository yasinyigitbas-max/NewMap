// CitySea: the sea of the city kit, a C++ port of tools/city/look/sea.gd (Yasin, 20 Nov: code work is C++). Built once
// from tools/city/look/sea_map.png + .json (make_sea.py: depth and where the water lies, 8 m a texel): one mesh at 0 m,
// a 16 m grid where there is water (and 25 m onto the land, so the waterline is where the water cuts the beach), and a
// skirt of big quads out to 8 km. The depth rides in each vertex (COLOR.r); the shader is tools/city/look/sea.gdshader.
// DRAWN LAST (render priority -127; the land's backstop plane, backstop(), -128): phone, 20 Nov, census at 1.5x on the
// waterfront: the sea and the plane under it cost 13 ms of 46 - full-screen surfaces drawn before the city were shaded
// under every building. Drawn after it, the depth test drops the hidden water before shading.
#pragma once
#include <godot_cpp/classes/mesh_instance3d.hpp>
#include <godot_cpp/classes/shader_material.hpp>

namespace godot {

class CitySea : public MeshInstance3D {
	GDCLASS(CitySea, MeshInstance3D)
protected:
	static void _bind_methods();
public:
	static Ref<ShaderMaterial> get_sea_material();
	static MeshInstance3D *make_backstop(double p_size, double p_y);   // the flat plane under everything (holes show it, not the sky)
	void build();
	void _exit_tree() override;   // the shared material let go with the sea (else the engine reports it leaked at exit)
	int tris = 0;
	int get_tris() const { return tris; }
};

} // namespace godot
