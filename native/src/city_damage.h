// CityDamage: the one damage node of the world (damage option B, Yasin 25 Nov 2026: "damage applicable to every prop in
// the game, big trees included, bullet holes when they are shot, and when they are damaged in any way ... every surface,
// building walls and roads or pedestrian ways included"). The contract it keeps: docs/damage/WORLD_CONTRACT.md.
//  - EVERY SOURCE of harm calls hit() (a point, its normal, the direction, how much, what kind, who) or strike() (a melee
//    sweep: the fist's or foot's path in its contact frame; it finds the first thing touched and calls hit()). Nothing
//    else talks to props, windows or doors.
//  - SURFACE: surface_at(ray hit) names what was hit (the contract's 19 surfaces): cars and people by their body, room
//    windows and doors by their node, buildings by their kit, props by the bake's per-shape table (meta "surf"), the
//    ground by the bake's top-down surface map (far/ground_surface.bin) or, with an older bake, the footsteps' classes.
//  - MARKS: pooled quads in ONE MultiMesh (one draw while any is on screen, none otherwise), MAX_MARKS at once, the
//    oldest fading out; multiplied onto the surface (assets/damage/marks.png), so they are right by day and by night.
//    Not Decal nodes: the Mobile renderer draws at most 8 decals on a mesh and the bake merges near props into one mesh
//    per material per 64 m. Marks go on the static world only (a moving car or person keeps its own damage).
//  - PARTICLES: one more MultiMesh of MAX_PARTS camera-facing sprites (assets/damage/sprites.png) moved here on the CPU:
//    dust, chips, sparks, splinters, leaves, glass, drops, clods, by surface and kind. One draw while any flies.
//  - SOUND: the recorded sets (el_sfx.h) by surface and kind; what is missing is listed in docs/damage/ASSETS_WANTED.md.
//  - WINDOWS AND DOORS: hits on a room's pane or leaf go to CityRooms::hit_opening (intact -> cracked -> broken, saved
//    with the rooms' breakables); a bullet leaves a hole in the pane (up to 8 a pane), the crack star comes when it cracks.
//  - TEST GUN (dev only): user arg --testgun; the G key or the middle mouse button fires from the camera's centre. Guns do
//    not exist yet; the crowd's gun_aimed / gunshot hooks are called only with --testgun=crowd.
// It never moves, animates or freezes the player or people: it only reports (signals) and changes the world.
#pragma once
#include <godot_cpp/classes/node3d.hpp>
#include <godot_cpp/classes/multi_mesh.hpp>
#include <godot_cpp/classes/multi_mesh_instance3d.hpp>
#include <godot_cpp/classes/input_event.hpp>
#include <godot_cpp/variant/dictionary.hpp>
#include <cstdint>
#include <vector>

namespace godot {

class CityDamage : public Node3D {
	GDCLASS(CityDamage, Node3D)
public:
	// the contract's kinds (a source passes the number; the names are constants on the class too)
	enum Kind { BULLET = 0, PUNCH, KICK, BLUNT, CAR, FALL, EXPLOSION, N_KINDS };
	// the contract's surfaces, in its order
	enum Surface { CONCRETE = 0, BRICK, STUCCO, ASPHALT, STONE, WOOD, METAL, GLASS, PLASTIC, FABRIC, BARK, FOLIAGE, GRASS, DIRT, SAND, WATER, FLESH, CAR_BODY, CAR_GLASS, N_SURF };
	// the contract's collision layers (bits)
	enum Layer : uint32_t { L_WORLD = 1, L_PLAYER = 2, L_BREAKABLE = 4, L_OPENING = 8, L_CARS = 16, L_PEOPLE = 32, L_DEBRIS = 64, L_DAMAGE = 128 };
	static constexpr uint32_t BULLET_MASK = L_WORLD | L_BREAKABLE | L_OPENING | L_CARS | L_PEOPLE | L_DEBRIS;
	static constexpr int MAX_MARKS = 256, FADE_MARKS = 32, MAX_PARTS = 192;
	static constexpr float MARK_LIFT = 0.012f, MARK_FAR = 70.0f, SEA_Y = 0.0f;
	static CityDamage *the;   // the world's one (the last made); nullptr when none
	static const char *surface_name(int p_s);
	static int surface_from_name(const String &p_name);
	static int surface_from_words(const String &p_words, int p_default);   // a kit or prop name -> a surface

	// the mark sheet's tiles (tools/damage/make_mark_sheet.py) and the sprite sheet's
	enum { MARK_CONCRETE = 0, MARK_BRICK, MARK_STUCCO, MARK_STONE, MARK_WOOD, MARK_METAL, MARK_ASPHALT, MARK_PLASTIC, MARK_BARK, MARK_DIVOT, MARK_PUNCH, MARK_KICK, MARK_SCRAPE, MARK_TYRE, MARK_CHIP_BIG, MARK_CONCRETE2 };
	enum { SPR_PUFF = 0, SPR_CHIP, SPR_SPARK, SPR_SPLINTER, SPR_LEAF, SPR_SHARD, SPR_DROP, SPR_CLOD };

private:
	struct Mark { Transform3D xf; int tile = 0; float alpha = 1.0f, born = 0.0f; uint64_t target = 0; bool live = false; };
	std::vector<Mark> marks;
	int mark_head = 0, mark_count = 0, marks_total = 0;
	struct Part { Vector3 p, v; float life = 0.0f, age = 0.0f, size = 0.1f, spin = 0.0f, grav = 1.0f, drag = 0.0f, glow = 0.0f; Color col; int tile = 0; };
	std::vector<Part> parts;
	int parts_total = 0;
	MultiMeshInstance3D *mark_mmi = nullptr, *part_mmi = nullptr;
	Ref<MultiMesh> mark_mm, part_mm;
	bool made = false, parts_shown = false;
	double clock = 0.0;
	uint32_t rng = 0x2545F491u;
	// the ground's surface map (far/ground_surface.bin: one byte a texel, a Surface number) or the footsteps' classes
	std::vector<uint8_t> gmap; int gw = 0, gh = 0; float gx0 = 0, gz0 = 0, gtex = 1.0f; bool gmap_tried = false, gmap_is_surface = false;
	// counters for the tests and the rig
	int hits_n[N_KINDS] = {}, surf_n[N_SURF] = {}, sounds = 0, openings_hit = 0, last_surface = -1;
	String last_target;
	// the test gun
	int testgun = 0;    // 0 off, 1 on, 2 on and the crowd hears it
	bool gun_key_was = false;
	int shots = 0;

	void make();
	float rnd() { rng ^= rng << 13; rng ^= rng >> 17; rng ^= rng << 5; return (float)(rng & 0xffffff) / 16777216.0f; }
	float rnd2() { return rnd() * 2.0f - 1.0f; }
	void load_ground_map();
	int ground_surface(const Vector3 &p_at, int p_fallback) const;
	Dictionary ray(const Vector3 &p_from, const Vector3 &p_to, uint32_t p_mask, Object *p_exclude) const;
	void add_mark(const Vector3 &p_at, const Vector3 &p_n, const Vector3 &p_dir, int p_tile, float p_size, uint64_t p_target);
	void upload_mark(int p_i);
	void refade();
	void mark_bounds();
	void burst(const Vector3 &p_at, const Vector3 &p_n, const Vector3 &p_dir, int p_surf, int p_kind, float p_amount);
	void spawn(int p_tile, const Vector3 &p_at, const Vector3 &p_v, const Color &p_col, float p_size, float p_life, float p_grav, float p_drag, float p_glow = 0.0f);
	void step_parts(double p_dt);
	void impact_sound(const Vector3 &p_at, int p_surf, int p_kind, float p_amount);
	void dev_fire();

protected:
	static void _bind_methods();

public:
	CityDamage();
	~CityDamage();
	// THE CONTRACT
	Dictionary hit(const Vector3 &p_at, const Vector3 &p_normal, const Vector3 &p_dir, double p_amount, int p_kind, Object *p_source);
	Dictionary strike(const Vector3 &p_from, const Vector3 &p_to, double p_radius, double p_amount, int p_kind, Object *p_source);
	String surface_at(const Dictionary &p_ray_hit);
	// the rest
	int surface_id_at(const Dictionary &p_ray_hit);
	Dictionary shoot(const Vector3 &p_from, const Vector3 &p_dir, double p_range, double p_amount, Object *p_source);   // a hitscan bullet (the test gun; guns later)
	void set_testgun(int p_mode) { testgun = p_mode; set_process_input(p_mode > 0); }
	int get_testgun() const { return testgun; }
	void clear_marks();
	int mark_count_now() const { return mark_count; }
	Array marks_near(const Vector3 &p_at, double p_radius) const;   // [{at, tile, alpha}] (the tests)
	Dictionary get_state() const;
	void _ready() override;
	void _process(double p_delta) override;
	void _input(const Ref<InputEvent> &p_event) override;
	void _exit_tree() override;
};

} // namespace godot
