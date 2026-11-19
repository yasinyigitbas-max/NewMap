// CityBike and BikeReach: see city_bike.h.
#include "city_bike.h"

#include "city_ped.h"
#include "ped_body.h"
#include "city_player.h"
#include "city_traffic.h"
#include "ui_plate.h"

#include <godot_cpp/classes/box_shape3d.hpp>
#include <godot_cpp/classes/collision_shape3d.hpp>
#include <godot_cpp/classes/color_rect.hpp>
#include <godot_cpp/classes/engine.hpp>
#include <godot_cpp/classes/input.hpp>
#include <godot_cpp/classes/input_event_screen_drag.hpp>
#include <godot_cpp/classes/input_event_screen_touch.hpp>
#include <godot_cpp/classes/label.hpp>
#include <godot_cpp/classes/panel_container.hpp>
#include <godot_cpp/classes/style_box_flat.hpp>
#include <godot_cpp/classes/texture_rect.hpp>
#include <godot_cpp/classes/mesh_instance3d.hpp>
#include <godot_cpp/classes/physics_direct_space_state3d.hpp>
#include <godot_cpp/classes/physics_shape_query_parameters3d.hpp>
#include <godot_cpp/classes/shader.hpp>
#include <godot_cpp/classes/sphere_shape3d.hpp>
#include <godot_cpp/classes/skeleton3d.hpp>
#include <godot_cpp/classes/v_box_container.hpp>
#include <godot_cpp/classes/viewport.hpp>
#include <godot_cpp/classes/world3d.hpp>
#include <godot_cpp/core/class_db.hpp>

#include <algorithm>
#include <cmath>

namespace godot {

namespace {
const float G = 9.81f;
const float WB = 1.02f;              // wheelbase, m (the bicycle mesh: rear axle z -0.42, front z +0.60)
const float WR = 0.34f;              // wheel radius
const float M_BIKE = 14.0f, M_RIDER = 75.0f;
const Vector3 RIDER_AT(0.0f, 0.42f, 0.14f);    // the rider's figure (seated clip) in the bicycle's frame: his hips over the saddle (measured: the clip's hips sit 0.31 m behind its origin)
inline float clampf(float v, float a, float b) { return v < a ? a : (v > b ? b : v); }
inline Basis arc(Vector3 a, Vector3 b) {
	if (a.length_squared() < 1e-10f || b.length_squared() < 1e-10f) return Basis();
	a.normalize(); b.normalize();
	const Vector3 ax = a.cross(b);
	const float sn = ax.length(), cs = a.dot(b);
	if (sn < 1e-6f) return Basis();
	return Basis(ax / sn, std::atan2(sn, cs));
}
} // namespace

// ---------------------------------------------------------------- BikeReach
void BikeReach::find_bones(Skeleton3D *sk) {
	found = true;
	b_spine = sk->find_bone("Bip01_Spine1") >= 0 ? sk->find_bone("Bip01_Spine1") : sk->find_bone("Bip01_Spine");
	const char *th[2] = { "Bip01_L_Thigh", "Bip01_R_Thigh" }, *ca[2] = { "Bip01_L_Calf", "Bip01_R_Calf" }, *ft[2] = { "Bip01_L_Foot", "Bip01_R_Foot" };
	const char *ua[2] = { "Bip01_L_UpperArm", "Bip01_R_UpperArm" }, *fa[2] = { "Bip01_L_Forearm", "Bip01_R_Forearm" }, *hd[2] = { "Bip01_L_Hand", "Bip01_R_Hand" };
	for (int s = 0; s < 2; s++) {
		b_th[s] = sk->find_bone(th[s]); b_ca[s] = sk->find_bone(ca[s]); b_ft[s] = sk->find_bone(ft[s]);
		b_ua[s] = sk->find_bone(ua[s]); b_fa[s] = sk->find_bone(fa[s]); b_hd[s] = sk->find_bone(hd[s]);
	}
}

// A two-bone reach in the skeleton's own space: the upper bone turned so that the middle joint lies where the pole
// says, then the lower bone turned onto the target (or as near as the limb reaches). Global poses are set one after
// the other (the skeleton works out the children from each).
void BikeReach::reach(Skeleton3D *sk, int a, int b, int c, const Vector3 &target, const Vector3 &pole) {
	if (a < 0 || b < 0 || c < 0) return;
	const Transform3D Ga = sk->get_bone_global_pose(a), Gb = sk->get_bone_global_pose(b), Gc = sk->get_bone_global_pose(c);
	const Vector3 pa = Ga.origin, pb = Gb.origin, pc = Gc.origin;
	const float la = (pb - pa).length(), lb = (pc - pb).length();
	if (la < 1e-4f || lb < 1e-4f) return;
	const Vector3 tv = target - pa;
	const float d = clampf(tv.length(), std::fabs(la - lb) + 1e-3f, la + lb - 1e-3f);
	const Vector3 u = tv.normalized();
	Vector3 v = pole - u * pole.dot(u);
	if (v.length_squared() < 1e-8f) v = Vector3(0, 0, 1) - u * u.z;
	v.normalize();
	const float ca = clampf((la * la + d * d - lb * lb) / (2.0f * la * d), -1.0f, 1.0f);
	const Vector3 knee = pa + (u * ca + v * std::sqrt(std::max(0.0f, 1.0f - ca * ca))) * la;
	sk->set_bone_global_pose(a, Transform3D(arc(pb - pa, knee - pa) * Ga.basis, pa));
	const Transform3D Gb2 = sk->get_bone_global_pose(b), Gc2 = sk->get_bone_global_pose(c);
	sk->set_bone_global_pose(b, Transform3D(arc(Gc2.origin - Gb2.origin, pa + u * d - Gb2.origin) * Gb2.basis, Gb2.origin));
}

void BikeReach::_process_modification_with_delta(double p_delta) {
	Skeleton3D *sk = get_skeleton();
	if (!sk) return;
	if (!found) find_bones(sk);
	const Transform3D to_sk = sk->get_global_transform().affine_inverse();
	if (b_spine >= 0) {   // the back over the bars: leant at least `lean`, more if the arms need it to reach the grips
		const Transform3D Gs = sk->get_bone_global_pose(b_spine);
		const Vector3 ax = to_sk.basis.xform(lean_axis).normalized();
		float L = lean;
		for (int it = 0; it < 14 && b_ua[0] >= 0 && b_fa[0] >= 0 && b_hd[0] >= 0; it++) {
			float worst = 0.0f;
			for (int sd = 0; sd < 2; sd++) {
				const Vector3 sh0 = sk->get_bone_global_pose(b_ua[sd]).origin;
				const float arm = sk->get_bone_global_pose(b_fa[sd]).origin.distance_to(sh0) + sk->get_bone_global_pose(b_hd[sd]).origin.distance_to(sk->get_bone_global_pose(b_fa[sd]).origin);
				const Vector3 sh = Gs.origin + Basis(ax, L).xform(sh0 - Gs.origin);
				worst = std::max(worst, sh.distance_to(to_sk.xform(hand[sd])) - arm * 0.94f);
			}
			if (worst <= 0.0f || L >= 0.9f) break;
			L += 0.05f;
		}
		lean_used = L;
		sk->set_bone_global_pose(b_spine, Transform3D(Basis(ax, L) * Gs.basis, Gs.origin));
	}
	const Vector3 fwd_s = to_sk.basis.xform(lean_axis.cross(Vector3(0, 1, 0))).normalized();   // the bicycle's forward, in skeleton space
	for (int s = 0; s < 2; s++) {
		const Vector3 side = to_sk.basis.xform(lean_axis).normalized() * (s == 0 ? 1.0f : -1.0f);
		reach(sk, b_th[s], b_ca[s], b_ft[s], to_sk.xform(foot[s]), fwd_s + side * 0.25f + Vector3(0, 0.2f, 0));
		reach(sk, b_ua[s], b_fa[s], b_hd[s], to_sk.xform(hand[s]), side * 1.6f - fwd_s * 0.5f + Vector3(0, -0.6f, 0));
		if (b_fa[s] >= 0 && b_hd[s] >= 0 && std::fabs(hand_turn) > 1e-3f) {   // each hand turned about its forearm onto the grip (Yasin: "turn the left hand 90 degree right and right hand 90 degree right")
			const Transform3D Gh = sk->get_bone_global_pose(b_hd[s]);
			const Vector3 d = (Gh.origin - sk->get_bone_global_pose(b_fa[s]).origin).normalized();
			sk->set_bone_global_pose(b_hd[s], Transform3D(Basis(d, hand_turn) * Gh.basis, Gh.origin));
		}
		if (b_ft[s] >= 0) miss_foot[s] = sk->get_bone_global_pose(b_ft[s]).origin.distance_to(to_sk.xform(foot[s]));
		if (b_hd[s] >= 0) miss_hand[s] = sk->get_bone_global_pose(b_hd[s]).origin.distance_to(to_sk.xform(hand[s]));
	}
	{
		const Transform3D sg = sk->get_global_transform();
		const int pel = sk->find_bone("Bip01_Pelvis");
		if (pel >= 0) hips_w = sg.xform(sk->get_bone_global_pose(pel).origin);
		if (b_ua[0] >= 0) shoulder_w = sg.xform(sk->get_bone_global_pose(b_ua[0]).origin);
		if (b_ft[0] >= 0) foot_w = sg.xform(sk->get_bone_global_pose(b_ft[0]).origin);
	}
	(void)p_delta;
}

// ---------------------------------------------------------------- CityBike
void CityBike::make() {
	if (made) return;
	made = true;
	set_mass(M_BIKE);
	set_collision_layer(16);         // (the traffic's layer: a thrown rider's balancing body looks through it for the road)
	set_collision_mask(1 | 16);      // the world and the traffic's cars
	set_can_sleep(false);
	CollisionShape3D *cs = memnew(CollisionShape3D);
	Ref<BoxShape3D> bx; bx.instantiate(); bx->set_size(Vector3(0.16f, 0.95f, 1.70f));
	cs->set_shape(bx); cs->set_position(Vector3(0, 0.55f, 0.09f));
	add_child(cs);
	mi = memnew(MeshInstance3D);
	mi->set_mesh(CityTraffic::bike_mesh());
	Ref<Shader> sh; sh.instantiate(); sh->set_code(CityTraffic::bike_shader_code());
	mat.instantiate(); mat->set_shader(sh);
	mat->set_shader_parameter("paint_u", Vector3(paint.r, paint.g, paint.b));
	mi->set_material_override(mat);
	add_child(mi);
	rq.instantiate();
	rq->set_collision_mask(1);
	rider = memnew(CityPed);
	rider->set_body_id(rider_body);
	rider->set_clip("ual/Driving_Loop");
	rider->set_as_top_level(true);
	add_child(rider);
	rider->set_visible(false);
	cam = memnew(Camera3D);
	cam->set_as_top_level(true);
	cam->set_fov(64.0); cam->set_near(0.08); cam->set_far(1500.0);
	add_child(cam);
	y_ground = get_global_position().y;
}

void CityBike::_ready() {
	if (Engine::get_singleton()->is_editor_hint()) return;
	make();
	set_process(true); set_process_input(true);
}

void CityBike::set_rider_player(Object *p_player) { player_id = p_player ? (uint64_t)p_player->get_instance_id() : 0; }

CityPlayer *CityBike::the_player() const {
	return player_id ? Object::cast_to<CityPlayer>(ObjectDB::get_instance(ObjectID(player_id))) : nullptr;
}

bool CityBike::get_on() {
	if (state != ST_PARKED || damage >= 100.0f) return false;
	CityPlayer *pl = the_player();
	if (!pl || pl->get_global_position().distance_to(get_global_position()) > 2.5f) return false;
	mount();
	return true;
}

bool CityBike::get_off() {
	if (state != ST_RIDE || std::fabs(speed) > 1.5f) return false;
	dismount();
	return true;
}

// Getting on: a fallen bicycle is stood up first; the player's figure is the rider's (he is hidden while he rides)
void CityBike::mount() {
	CityPlayer *pl = the_player();
	if (fallen || std::fabs(get_global_basis().get_column(1).y) < 0.85f) {   // stood up where it lies (the player lifts it)
		const Vector3 f = get_global_basis().get_column(2);
		const float yw = std::atan2(f.x, f.z);
		set_global_transform(Transform3D(Basis(Vector3(0, 1, 0), yw), get_global_position() + Vector3(0, 0.05f, 0)));
		set_linear_velocity(Vector3()); set_angular_velocity(Vector3());
		fallen = false;
	}
	if (pl) pl->set_riding(true);
	set_mass(M_BIKE + M_RIDER);
	state = ST_MOUNT; st_t = 0.0f;
	clip_in = rider ? (float)std::max(rider->clip_len("ual/Sitting_Enter"), 0.6) : 1.0f;
	lean = lean_v = 0.0f;
	if (rider) rider->set_visible(true);
	if (cam && chase_camera) { cam->make_current(); cam_set = false; }
}

void CityBike::dismount() {
	state = ST_DISMOUNT; st_t = 0.0f;
	clip_out = rider ? (float)std::max(rider->clip_len("ual/Sitting_Exit"), 0.6) : 1.0f;
}

void CityBike::set_controls(double p_pedal, double p_brake, double p_steer, double p_sprint) {
	c_pedal = (float)p_pedal; c_brake = (float)p_brake; c_steer = (float)p_steer; c_sprint = (float)p_sprint; scripted = true;
}

// Touch: left half steers (a thumb slid from where it landed); right half: brake (inner), pedals (outer; slide up to
// sprint); the top right corner gets on or off. Many fingers at once.
void CityBike::_input(const Ref<InputEvent> &p_event) {
	if (!player) return;
	Viewport *vp = get_viewport();
	if (!vp) return;
	const Vector2 sz = vp->get_visible_rect().size;
	if (sz.x < 1.0f || sz.y < 1.0f) return;
	Rect2 z[4];
	zones(sz, z);
	auto zone = [&](const Vector2 &p) { for (int k = 1; k < 4; k++) if (z[k].grow(16.0f).has_point(p)) return k; return 0; };
	if (const InputEventScreenTouch *t = Object::cast_to<InputEventScreenTouch>(p_event.ptr())) {
		const int id = t->get_index();
		const Vector2 p = t->get_position();
		if (t->is_pressed()) {
			const int zk = zone(p);
			if (zk == 0 && z[0].has_point(p)) { if (t_steer_id < 0) { t_steer_id = id; t_steer_x0 = p.x; t_steer = 0.0f; } }
			else if (zk > 0 && id >= 0 && id < 16) { t_zone[id] = zk; t_y0[id] = p.y; if (zk == 3) want_toggle = true; }
		} else {
			if (id == t_steer_id) { t_steer_id = -1; t_steer = 0.0f; }
			if (id >= 0 && id < 16) { if (t_zone[id] == 2) t_sprint = false; t_zone[id] = 0; }
		}
		return;
	}
	if (const InputEventScreenDrag *d = Object::cast_to<InputEventScreenDrag>(p_event.ptr())) {
		const int id = d->get_index();
		const Vector2 p = d->get_position();
		if (id == t_steer_id) {   // the old stick: full at 80 px (of the 648 px canvas), a dead zone of 0.08
			const float k = std::max(sz.y / 648.0f, 0.5f);
			const float sx = clampf(-(p.x - t_steer_x0) / (80.0f * k), -1.0f, 1.0f);
			t_steer = std::fabs(sx) > 0.08f ? sx : 0.0f;
		}
		else if (id >= 0 && id < 16 && (t_zone[id] == 1 || t_zone[id] == 2)) {
			const int zk = zone(p);
			if (zk == 1 || zk == 2) t_zone[id] = zk;   // (a thumb may slide from one pedal to the other)
			if (t_zone[id] == 2) t_sprint = t_y0[id] - p.y > sz.y * 0.10f;
		}
	}
}

// Where the controls are (Yasin: "only activate after we get onto it and it should be much more subtle. two pedals to
// acc and brk on the lower right and left side of the screen for steering"): 0 steer (the lower left: a thumb slid
// sideways), 1 brake and 2 pedal (two pedals side by side at the lower right; slide up on the pedal to sprint), 3 off
// (a small button at the top right). The touch and the drawing both come from here.
void CityBike::zones(const Vector2 &sz, Rect2 r[4]) {
	// the old game's car scheme (docs/OLD_CONTROLS_SPEC.md): the left half an invisible stick for the bar; BRAKE and the
	// pedal where the car's BRAKE and GAS plates were; getting off where the Use plate was
	r[0] = Rect2(0, 0, sz.x * 0.5f, sz.y);
	r[1] = plate::brake_rect(sz);
	r[2] = plate::gas_rect(sz);
	r[3] = plate::use_rect(sz);
}

void CityBike::read_player() {
	Input *in = Input::get_singleton();
	bool tb = false, tp = false;
	for (int i = 0; i < 16; i++) { tb = tb || t_zone[i] == 1; tp = tp || t_zone[i] == 2; }
	const float up = std::max(in->is_key_pressed(KEY_W) || in->is_key_pressed(KEY_UP) || tp ? 1.0f : 0.0f, std::max(0.0f, (float)in->get_joy_axis(0, JOY_AXIS_TRIGGER_RIGHT)));
	const float down = std::max(in->is_key_pressed(KEY_S) || in->is_key_pressed(KEY_DOWN) || tb ? 1.0f : 0.0f, std::max(0.0f, (float)in->get_joy_axis(0, JOY_AXIS_TRIGGER_LEFT)));
	float st = (in->is_key_pressed(KEY_A) || in->is_key_pressed(KEY_LEFT) ? 1.0f : 0.0f) - (in->is_key_pressed(KEY_D) || in->is_key_pressed(KEY_RIGHT) ? 1.0f : 0.0f) + t_steer;
	const float jx = (float)in->get_joy_axis(0, JOY_AXIS_LEFT_X);
	if (std::fabs(jx) > 0.12f) st -= jx;
	c_pedal = up; c_brake = down; c_steer = clampf(st, -1.0f, 1.0f);
	c_sprint = (in->is_key_pressed(KEY_SHIFT) || in->is_joy_button_pressed(0, JOY_BUTTON_A) || t_sprint) ? 1.0f : 0.0f;
	const bool e = in->is_key_pressed(KEY_E) || in->is_joy_button_pressed(0, JOY_BUTTON_X);
	if (e && !e_was) want_toggle = true;
	e_was = e;
}

void CityBike::_integrate_forces(PhysicsDirectBodyState3D *p_state) {
	if (!made) return;
	const float dt = (float)p_state->get_step();
	if (dt <= 0.0f) return;
	const Transform3D t = p_state->get_transform();
	const Vector3 lv = p_state->get_linear_velocity();
	const Vector3 fwd = t.basis.get_column(2).normalized(), left = t.basis.get_column(0).normalized();
	Vector3 fh(fwd.x, 0.0f, fwd.z);
	if (fh.length_squared() < 0.04f) { fh = Vector3(-left.z, 0.0f, left.x); }   // (standing on its end: its forward from its side)
	fh.normalize();
	const Vector3 lh(fh.z, 0.0f, -fh.x);
	const bool control = state == ST_MOUNT || state == ST_RIDE || state == ST_DISMOUNT || (state == ST_PARKED && !fallen);
	// a knock: what changed its speed that it did not do itself (the engine's crash with a car, a wall, a kerb)
	{
		const Vector3 dv = lv - last_set_v - Vector3(0.0f, -G * dt, 0.0f);
		const float imp = control ? dv.length() : 0.0f;
		if (imp > 1.2f) { damage = std::min(100.0f, damage + (imp - 1.2f) * 11.0f); hardest = std::max(hardest, imp); }
		if (imp > 4.5f && state == ST_RIDE && !hit_now) { hit_now = true; hit_v = dv; pre_hit_v = last_set_v; }
	}
	// the wheels on the ground: one ray each, straight down from the hub
	float gh[2] = { 0, 0 }; bool on[2] = { false, false };
	PhysicsDirectSpaceState3D *ss = p_state->get_space_state();
	const Vector3 hub[2] = { t.xform(Vector3(0, WR, 0.60f)), t.xform(Vector3(0, WR, -0.42f)) };
	for (int k = 0; k < 2 && ss; k++) {
		rq->set_from(hub[k] + Vector3(0, 0.35f, 0)); rq->set_to(hub[k] - Vector3(0, 0.75f, 0));
		rq->set_exclude(TypedArray<RID>::make(get_rid()));
		const Dictionary h = ss->intersect_ray(rq);
		if (!h.is_empty()) { gh[k] = ((Vector3)h["position"]).y; on[k] = gh[k] > hub[k].y - WR - 0.25f; }
	}
	on_ground = on[0] || on[1];
	if (!control) { last_set_v = lv; speed = lv.dot(fh); return; }   // thrown, or lying: the engine has it
	float slope = 0.0f, gy = t.origin.y;
	if (on[0] && on[1]) { slope = (gh[0] - gh[1]) / WB; gy = gh[1] + (gh[0] - gh[1]) * (0.42f / WB); }
	else if (on[0]) gy = gh[0];
	else if (on[1]) gy = gh[1];
	if (on_ground) y_ground = gy;
	const bool riding = state == ST_RIDE;
	const float m = state == ST_PARKED ? M_BIKE : M_BIKE + M_RIDER;
	float u = lv.dot(fh);
	// the front wheel: as far as the speed allows, turned at a hand's pace; a bent wheel wobbles the bar as it turns
	const float smax = 0.55f / (1.0f + 0.35f * std::max(u, 0.0f));
	const float st_in = riding ? c_steer : 0.0f;
	steer += clampf(st_in * smax - steer, -2.5f * dt, 2.5f * dt);
	const float wobble = damage > 30.0f ? (0.02f + 0.0004f * (damage - 30.0f)) * std::sin(wheel_ang) * std::min(1.0f, std::fabs(u) / 3.0f) : 0.0f;
	const float eff = steer + wobble;
	// the turn: the bicycle's own geometry, as long as the tyres hold (0.85 g); past that it slides
	float rr = u * std::tan(eff) / WB;
	bool slide = false;
	if (std::fabs(u * rr) > 0.85f * G) { rr = (rr > 0.0f ? 1.0f : -1.0f) * 0.85f * G / std::max(std::fabs(u), 0.1f); slide = true; }
	const bool locked = riding && c_brake > 0.9f && u > 3.0f;   // the rear wheel locks: it skids
	if (locked) slide = true;
	// the lean a rider takes into the turn, with a little lag and overshoot (second order)
	const float lt = on_ground ? -std::atan(u * rr / G) : lean;
	lean_v += (40.0f * (lt - lean) - 9.0f * lean_v) * dt;
	lean += lean_v * dt;
	lean = clampf(lean, -0.75f, 0.75f);
	// along the way: the rider's power (sprinting: more), brakes, rolling, the air, the slope
	float pedal_f = 0.0f;
	if (riding && damage < 70.0f && on_ground) pedal_f = c_pedal * std::min((300.0f + 350.0f * c_sprint) / std::max(u, 1.2f), 320.0f) * (damage > 30.0f ? 0.85f : 1.0f);
	const float drag = 0.5f * 1.2f * 0.55f * u * std::fabs(u);
	const float roll_r = std::fabs(u) > 0.05f ? 0.006f * m * G * (u > 0.0f ? 1.0f : -1.0f) : 0.0f;
	const float sl = slope / std::sqrt(1.0f + slope * slope);
	float a = (pedal_f - drag - roll_r) / m - (on_ground ? G * sl : 0.0f);
	u += a * dt;
	const float decel = riding ? c_brake * 0.78f * G : (state == ST_PARKED ? 8.0f : 5.0f);   // (on its stand, getting on or off: held)
	if (u > 0.0f) u = std::max(0.0f, u - decel * dt); else u = std::min(0.0f, u + decel * dt);
	// sideways: the tyres stop it, unless it slides
	float vl = lv.dot(lh);
	vl *= std::exp(-dt * (slide ? 2.5f : 14.0f));
	// up and down: on its wheels it follows the road (a stiff spring); in the air the engine's gravity
	float vy = lv.y;
	if (on_ground) {
		const float spring = clampf((gy - t.origin.y) * 14.0f, -6.0f, 4.0f);
		vy = u * sl + spring;
		bump += (std::fabs(spring) - bump) * std::min(1.0f, dt * 6.0f);
	}
	const Vector3 nv = fh * (u / std::sqrt(1.0f + slope * slope)) + lh * vl + Vector3(0.0f, vy, 0.0f);
	// turning: the yaw of the turn, the lean (rolled about its forward), the pitch of the road
	const float roll_now = std::asin(clampf(left.y, -1.0f, 1.0f));
	const float pitch_now = std::asin(clampf(fwd.y, -1.0f, 1.0f));
	const float pitch_want = on_ground ? std::atan(slope) : pitch_now;
	const Vector3 av = Vector3(0, 1, 0) * rr + fh * ((lean - roll_now) * 14.0f) - lh * ((pitch_want - pitch_now) * 12.0f);
	p_state->set_linear_velocity(nv);
	p_state->set_angular_velocity(av);
	last_set_v = nv;
	speed = u;
	wheel_ang += u / WR * dt;
	if (riding && c_pedal > 0.05f && u > 0.2f && damage < 70.0f) crank += 6.2831853f * u * dt / 5.2f;
	odo += std::fabs(u) * dt;
	if (std::fabs(roll_now) > 1.05f && riding && !hit_now) { hit_now = true; hit_v = Vector3(); pre_hit_v = nv; }   // it went over: the rider comes off
}

// The rider leaves the bicycle: his figure's balancing body takes him with the speed he had and the blow; the bicycle
// is a loose body from here on
void CityBike::throw_rider(const Vector3 &p_blow) {
	state = ST_THROWN; st_t = 0.0f; throws++;
	set_mass(M_BIKE);
	fallen = true;
	if (reach_mod) { reach_mod->set_influence(0.0f); reach_mod->set_active(false); }
	if (!rider) return;
	// the whole body goes on as it went (the bicycle stopped, he did not); a blow from behind or the side adds half of
	// itself. What he rode into decides the rest (Yasin: "they should still end up somersaulting to the other side of
	// the car"): something he can go over (its top under 2 m, a car) catches his legs and he goes over it head first,
	// with just the rise that clears its top and a push at the chest that turns him over; a wall stops him.
	Vector3 v = pre_hit_v;
	if (p_blow.dot(pre_hit_v) > 0.0f) v += p_blow * 0.5f;
	v.y = std::min(v.y, 0.5f);
	Vector3 f = pre_hit_v; f.y = 0.0f;
	const float sp = f.length();
	Vector3 pitch;
	if (sp > 0.1f) {
		f /= sp;
		pitch = f * 45.0f;
		float top = -1e9f;   // the top of what is just ahead of the front wheel
		Ref<World3D> w = get_world_3d();
		PhysicsDirectSpaceState3D *ss = w.is_valid() ? w->get_direct_space_state() : nullptr;
		const Vector3 nose = get_global_position() + f * 1.25f;
		for (int k = 0; k < 3 && ss; k++) {
			const Vector3 at = nose + f * (0.4f * (float)k);
			Ref<PhysicsRayQueryParameters3D> q = PhysicsRayQueryParameters3D::create(at + Vector3(0, 3.0f, 0), at - Vector3(0, 0.5f, 0), 1 | 16);
			q->set_exclude(TypedArray<RID>::make(get_rid()));
			const Dictionary h = ss->intersect_ray(q);
			if (!h.is_empty()) top = std::max(top, (float)((Vector3)h["position"]).y);
		}
		const float hips = rider->get_global_position().y + 0.50f;
		const float over = top - y_ground;
		if (over > 0.35f && over < 2.0f && sp > 3.0f) {   // over it: rise to clear its top by 0.35 m, forward a little slowed by the knock on his legs
			const float rise = std::max(0.0f, top + 0.35f - hips);
			v = f * (sp * 0.85f);
			v.y = std::min(std::sqrt(2.0f * G * rise) + 0.6f, 5.5f);
			pitch = f * 70.0f;   // (his legs are caught, his chest goes on: head over heels)
			vaults++;
		}
	}
	rider->launch(v, pitch, rider->get_global_position() + Vector3(0.0f, 1.25f, 0.0f));
	thrown_v = v;
}

void CityBike::place_rider(double p_delta) {
	if (!rider) return;
	if (!reach_mod && rider->skeleton()) {
		reach_mod = memnew(BikeReach);
		rider->skeleton()->add_child(reach_mod);
		reach_mod->set_influence(0.0f);
	}
	if (state == ST_PARKED || state == ST_THROWN) {
		if (reach_mod && state == ST_PARKED) { reach_mod->set_influence(0.0f); reach_mod->set_active(false); }
		return;
	}
	const Transform3D bt = get_global_transform();
	const Transform3D at(bt.basis, bt.xform(RIDER_AT));
	static const StringName IN("ual/Sitting_Enter"), RIDE("ual/Driving_Loop"), OUT("ual/Sitting_Exit");
	if (state == ST_MOUNT) rider->drive(at, IN, 1.0, -2.0);
	else if (state == ST_DISMOUNT) rider->drive(at, OUT, 1.0, -2.0);
	else rider->drive(at, RIDE, 1.0, -1.0);
	if (!reach_mod) return;
	float w = 1.0f;
	if (state == ST_MOUNT) w = clampf((st_t / clip_in - 0.35f) / 0.6f, 0.0f, 1.0f);
	else if (state == ST_DISMOUNT) w = clampf(1.0f - st_t / (clip_out * 0.5f), 0.0f, 1.0f);
	reach_mod->set_active(w > 0.001f);
	reach_mod->set_influence(w);
	for (int s = 0; s < 2; s++) {
		const float ang = crank + (s ? 3.14159265f : 0.0f);
		const float sx = s == 0 ? 0.11f : -0.11f;
		reach_mod->foot[s] = bt.xform(Vector3(sx, 0.28f + 0.17f * std::cos(ang) + 0.08f, 0.17f * std::sin(ang)));
		reach_mod->hand[s] = bt.xform(Vector3(s == 0 ? 0.22f : -0.22f, 1.07f, 0.39f));
	}
	reach_mod->lean_axis = bt.basis.get_column(0).normalized();
	reach_mod->lean = 0.30f + 0.10f * c_sprint;
	(void)p_delta;
}

// Behind and above, swinging round as it turns; it rolls with the lean, sways and bobs with the pedalling, shakes over
// bumps. After a throw it follows the rider's body.
void CityBike::view(double p_delta) {
	if (!cam || !chase_camera || state == ST_PARKED) return;
	const float dt = (float)std::min(p_delta, 0.1);
	const Transform3D bt = get_global_transform();
	Vector3 target = bt.origin;
	if (state == ST_THROWN && rider) target = rider->body_at();
	const Vector3 f = bt.basis.get_column(2);
	const float want_yaw = std::atan2(f.x, f.z);
	if (!cam_set) cam_yaw = want_yaw;
	if (state != ST_THROWN) {
		float dy = std::fmod(want_yaw - cam_yaw + 3.14159265f, 6.2831853f); if (dy < 0) dy += 6.2831853f; dy -= 3.14159265f;
		cam_yaw += dy * (1.0f - std::exp(-dt * (1.8f + std::fabs(speed) * 0.15f)));
	}
	const float sp = std::fabs(speed);
	const float dist = 3.6f + sp * 0.06f, h = 1.85f;
	const Vector3 look = target + Vector3(0, 1.25f, 0);
	const Vector3 want = look - Vector3(std::sin(cam_yaw), 0, std::cos(cam_yaw)) * dist + Vector3(0, h - 1.25f, 0);
	if (!cam_set) { cam_pos = want; cam_look = look; cam_set = true; }
	cam_pos += (want - cam_pos) * (1.0f - std::exp(-dt * 8.0f));
	cam_look += (look - cam_look) * (1.0f - std::exp(-dt * 12.0f));
	// the wobble
	const float effort = state == ST_RIDE ? c_pedal * (1.0f + 0.8f * c_sprint) : 0.0f;
	const float roll_want = lean * 0.45f + std::sin(crank) * 0.014f * effort + std::sin(st_t * 29.0f) * std::min(bump, 1.0f) * 0.02f;
	cam_roll += (roll_want - cam_roll) * (1.0f - std::exp(-dt * 10.0f));
	cam_bob = std::sin(crank * 2.0f) * 0.028f * effort + std::sin(st_t * 31.0f) * std::min(bump, 1.0f) * 0.03f;
	wobble_most = std::max(wobble_most, std::fabs(cam_roll) + std::fabs(cam_bob));
	Transform3D ct = Transform3D(Basis(), cam_pos + Vector3(0, cam_bob, 0)).looking_at(cam_look, Vector3(0, 1, 0));
	ct.basis = ct.basis * Basis(Vector3(0, 0, 1), cam_roll);
	cam->set_global_transform(ct);
	cam->set_fov(64.0 + std::min(sp, 14.0f) * 0.55);
}

// The touch zones, drawn while the player rides (or stands by his bicycle): steer, brake, pedal, on / off
void CityBike::make_hud() {
	hud = memnew(CanvasLayer);
	hud->set_layer(40);
	add_child(hud);
	Control *blank = memnew(Control); blank->set_mouse_filter(Control::MOUSE_FILTER_IGNORE); hud->add_child(blank);   // (the left: nothing drawn)
	const char *en_[3] = { "BRAKE", "PEDAL", "GET OFF" }, *tr_[3] = { "FREN", "PEDAL", String::utf8("İN").utf8().get_data() };
	const char *look[3] = { "plate", "plate_go", "green" };
	for (int k = 0; k < 3; k++) {
		PanelContainer *p = plate::panel(look[k]);
		p->set_mouse_filter(Control::MOUSE_FILTER_IGNORE);
		VBoxContainer *v = memnew(VBoxContainer);
		v->set_alignment(k == 2 ? BoxContainer::ALIGNMENT_CENTER : BoxContainer::ALIGNMENT_END);
		v->add_theme_constant_override("separation", -2);
		v->set_mouse_filter(Control::MOUSE_FILTER_IGNORE);
		Label *a = plate::label(en_[k], k == 2 ? plate::FS_ACTION : plate::FS_ACTION, plate::TEXT, 700);
		a->set_horizontal_alignment(HORIZONTAL_ALIGNMENT_CENTER); a->set_mouse_filter(Control::MOUSE_FILTER_IGNORE);
		Label *b = plate::label(String::utf8(tr_[k]), plate::FS_HELP, k == 2 ? Color(1, 1, 1, 0.85f) : plate::DIM, 600);
		b->set_horizontal_alignment(HORIZONTAL_ALIGNMENT_CENTER); b->set_mouse_filter(Control::MOUSE_FILTER_IGNORE);
		v->add_child(a); v->add_child(b);
		p->add_child(v);
		hud->add_child(p);
	}
}

void CityBike::_process(double p_delta) {
	if (!made) return;
	st_t += (float)p_delta;
	if (player && !scripted) read_player();
	if (hit_now && state == ST_RIDE) { hit_now = false; throw_rider(hit_v); }
	CityPlayer *pl = the_player();
	if (want_toggle) {
		want_toggle = false;
		if (state == ST_PARKED) get_on(); else if (state == ST_RIDE) get_off();
	}
	if (state == ST_MOUNT && st_t >= clip_in * 0.95f) { state = ST_RIDE; st_t = 0.0f; }
	if (state == ST_DISMOUNT && st_t >= clip_out) {   // off, standing by its left side
		state = ST_PARKED; st_t = 0.0f;
		set_mass(M_BIKE);
		if (rider) rider->set_visible(false);
		if (pl) {
			const Transform3D bt = get_global_transform();
			const Vector3 f = bt.basis.get_column(2);
			pl->set_riding(false);
			pl->stand_at(bt.xform(Vector3(0.75f, 0.0f, 0.0f)), std::atan2(f.x, f.z));
			pl->take_view();
		}
	}
	if (state == ST_THROWN && rider && rider->get_mode() != CityPed::MODE_ANIM) {   // the cars round him are solid to his body (he slams into one and goes over it)
		Ref<World3D> w = get_world_3d();
		PhysicsDirectSpaceState3D *ss = w.is_valid() ? w->get_direct_space_state() : nullptr;
		int nb = 0;
		if (ss) {
			if (q_sphere.is_null()) { q_sphere.instantiate(); q_sphere->set_radius(4.0f); q_shape.instantiate(); q_shape->set_shape(q_sphere); q_shape->set_collision_mask(1 | 16); }
			q_shape->set_transform(Transform3D(Basis(), rider->body_at()));
			q_shape->set_exclude(TypedArray<RID>::make(get_rid()));
			const TypedArray<Dictionary> hits = ss->intersect_shape(q_shape, 8);
			for (int k = 0; k < hits.size() && nb < pb::MAX_BOXES; k++) {
				RigidBody3D *rb = Object::cast_to<RigidBody3D>(Object::cast_to<Object>(((Dictionary)hits[k]).get("collider", Variant())));
				if (!rb) continue;
				const Vector3 rv = rb->get_linear_velocity();
				for (int c = 0; c < rb->get_child_count() && nb < pb::MAX_BOXES; c++) {
					CollisionShape3D *cs = Object::cast_to<CollisionShape3D>(rb->get_child(c));
					if (!cs || cs->is_disabled()) continue;
					Ref<BoxShape3D> bxs = cs->get_shape();
					if (bxs.is_null()) continue;
					const Transform3D gt = cs->get_global_transform();
					const Vector3 half = bxs->get_size() * 0.5f * gt.basis.get_scale();
					const Vector3 fz = gt.basis.get_column(2);
					rider->set_box(nb, gt.origin, half, std::atan2(fz.x, fz.z), rv, nb + 1);
					nb++;
				}
			}
		}
		if (nb == 0) rider->set_box(0, Vector3(), Vector3(), 0.0, Vector3(), 0);
	}
	if (state == ST_THROWN && rider && st_t > 1.5f && rider->get_mode() == CityPed::MODE_ANIM) {   // he is up: the player walks from there
		state = ST_PARKED; st_t = 0.0f;
		rider->set_visible(false);
		if (pl) {
			pl->set_riding(false);
			pl->stand_at(rider->body_at(), rider->body_yaw());
			pl->take_view();
		}
	}
	if (state == ST_PARKED && fallen && on_ground && get_linear_velocity().length() < 0.2f && std::fabs(get_global_basis().get_column(1).y) > 0.85f) fallen = false;   // (it came to rest on its wheels)
	place_rider(p_delta);
	view(p_delta);
	// the touch controls: only while he rides, faint
	if (touch_hud && player) {
		if (!hud) make_hud();
		const bool show = state == ST_RIDE;
		hud->set_visible(show);
		Viewport *vp = get_viewport();
		if (show && vp) {
			const Vector2 sz = vp->get_visible_rect().size;
			Rect2 z[4]; zones(sz, z);
			for (int k = 1; k < 4 && k < hud->get_child_count(); k++) {
				Control *c = Object::cast_to<Control>(hud->get_child(k));
				if (c) { c->set_position(z[k].position); c->set_size(z[k].size); }
			}
			{   // pressed plates show the pressed look (raised_hi), as the old pedals did
				bool tb = false, tp = false;
				for (int i = 0; i < 16; i++) { tb = tb || t_zone[i] == 1; tp = tp || t_zone[i] == 2; }
				if (PanelContainer *pb = Object::cast_to<PanelContainer>(hud->get_child(1))) pb->add_theme_stylebox_override("panel", plate::box(tb || c_brake > 0.5f ? "raised_hi" : "plate"));
				if (PanelContainer *pp = Object::cast_to<PanelContainer>(hud->get_child(2))) pp->add_theme_stylebox_override("panel", plate::box(tp || c_pedal > 0.5f ? "raised_hi" : "plate_go"));
			}
			if (Control *off = Object::cast_to<Control>(hud->get_child(3))) off->set_visible(std::fabs(speed) < 1.5f);   // (the Use plate's "Get off": only when it can be done)
		}
	}
}

Dictionary CityBike::get_state() const {
	Dictionary d;
	static const char *const NAMES[5] = { "parked", "getting on", "riding", "getting off", "thrown" };
	d["state"] = NAMES[state]; d["state_id"] = state;
	d["speed"] = speed; d["kmh"] = speed * 3.6f; d["lean"] = lean; d["steer"] = steer; d["crank"] = crank;
	d["on_ground"] = on_ground; d["fallen"] = fallen; d["upright"] = get_global_basis().get_column(1).y;
	d["damage"] = damage; d["wheel_bent"] = damage > 30.0f; d["chain_off"] = damage >= 70.0f; d["wrecked"] = damage >= 100.0f;
	d["hardest_knock"] = hardest; d["thrown_at"] = thrown_v; d["rider_body"] = rider ? rider->get_state() : Dictionary(); d["throws"] = throws; d["vaults"] = vaults; d["metres"] = odo;
	d["view_roll"] = cam_roll; d["view_bob"] = cam_bob; d["view_wobble_most"] = wobble_most;
	d["rider_mode"] = rider ? rider->get_mode() : -1;
	d["rider_at"] = rider ? rider->body_at() : Vector3();
	d["rider_clip"] = rider ? String(rider->current_clip()) : String();
	if (reach_mod) { d["foot_miss"] = Vector2(reach_mod->miss_foot[0], reach_mod->miss_foot[1]); d["hand_miss"] = Vector2(reach_mod->miss_hand[0], reach_mod->miss_hand[1]); d["reach_on"] = reach_mod->is_active(); d["reach_influence"] = reach_mod->get_influence(); d["back_lean"] = reach_mod->lean_used; const Transform3D inv = get_global_transform().affine_inverse(); d["hips_on_bike"] = inv.xform(reach_mod->hips_w); d["shoulder_on_bike"] = inv.xform(reach_mod->shoulder_w); d["foot_on_bike"] = inv.xform(reach_mod->foot_w); d["foot_target_on_bike"] = inv.xform(reach_mod->foot[0]); }
	return d;
}

void CityBike::_bind_methods() {
	ClassDB::bind_method(D_METHOD("set_player", "on"), &CityBike::set_player);
	ClassDB::bind_method(D_METHOD("get_player"), &CityBike::get_player);
	ClassDB::bind_method(D_METHOD("set_chase_camera", "on"), &CityBike::set_chase_camera);
	ClassDB::bind_method(D_METHOD("get_chase_camera"), &CityBike::get_chase_camera);
	ClassDB::bind_method(D_METHOD("set_touch_hud", "on"), &CityBike::set_touch_hud);
	ClassDB::bind_method(D_METHOD("get_touch_hud"), &CityBike::get_touch_hud);
	ClassDB::bind_method(D_METHOD("set_paint", "colour"), &CityBike::set_paint);
	ClassDB::bind_method(D_METHOD("get_paint"), &CityBike::get_paint);
	ClassDB::bind_method(D_METHOD("set_rider_body", "id"), &CityBike::set_rider_body);
	ClassDB::bind_method(D_METHOD("get_rider_body"), &CityBike::get_rider_body);
	ClassDB::bind_method(D_METHOD("set_rider_player", "player"), &CityBike::set_rider_player);
	ClassDB::bind_method(D_METHOD("get_on"), &CityBike::get_on);
	ClassDB::bind_method(D_METHOD("get_off"), &CityBike::get_off);
	ClassDB::bind_method(D_METHOD("set_controls", "pedal", "brake", "steer", "sprint"), &CityBike::set_controls);
	ClassDB::bind_method(D_METHOD("get_state"), &CityBike::get_state);
	ADD_PROPERTY(PropertyInfo(Variant::BOOL, "player"), "set_player", "get_player");
	ADD_PROPERTY(PropertyInfo(Variant::BOOL, "chase_camera"), "set_chase_camera", "get_chase_camera");
	ADD_PROPERTY(PropertyInfo(Variant::BOOL, "touch_hud"), "set_touch_hud", "get_touch_hud");
	ADD_PROPERTY(PropertyInfo(Variant::COLOR, "paint"), "set_paint", "get_paint");
	ADD_PROPERTY(PropertyInfo(Variant::STRING, "rider_body"), "set_rider_body", "get_rider_body");
}

} // namespace godot
