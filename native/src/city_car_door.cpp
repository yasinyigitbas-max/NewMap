// Getting into and out of a car (Yasin, 20 Nov: "WE NEED A GET INTO CAR, GET OUT OF CAR ANIMATION TOO. CARS DOORS SHOULD
// OPEN, SEATING IN, DOOR CLOSE, THEN WE CAN DRIVE OFF"). As the bicycle's rider: a figure of the car's own (the driver),
// in the player's body and clothes, plays it while the player is hidden; it stays at the wheel while he drives.
//  IN:  he walks to the door (round the front if he is on the far side), faces it, reaches and the door opens; turns his
//       back to the seat and sits in (Sitting_Enter, his root moved so his hips end on the seat), swings round to face
//       forward, the door closes: the wheel is his.
//  OUT: the door opens, he swings round to face out, stands up out of it (Sitting_Exit) by the door: he is the player
//       again (free to walk) while the door closes behind him.
// The door is drawn by car_paint.gdshader (set_door); the places come from the model (door_spot, seat_hips).
#include "city_car.h"
#include "car_models.h"
#include "city_ped.h"
#include "city_bike.h"
#include "city_player.h"

#include <godot_cpp/classes/object.hpp>

#include <algorithm>
#include <cmath>

namespace godot {

namespace {
inline float ssf(float a, float b, float x) { const float k = std::min(std::max((x - a) / (b - a), 0.0f), 1.0f); return k * k * (3.0f - 2.0f * k); }
inline float wrapa(float a) { a = std::fmod(a + 3.14159265f, 6.2831853f); if (a < 0.0f) a += 6.2831853f; return a - 3.14159265f; }
const StringName &C_WALK() { static const StringName s("ual/Walk_Loop"); return s; }
const StringName &C_IDLE() { static const StringName s("ual/Idle_Loop"); return s; }
const StringName &C_REACH() { static const StringName s("ual/Interact"); return s; }
const StringName &C_SIT_IN() { static const StringName s("ual/Sitting_Enter"); return s; }
const StringName &C_SIT() { static const StringName s("ual/Sitting_Idle_Loop"); return s; }
const StringName &C_SIT_OUT() { static const StringName s("ual/Sitting_Exit"); return s; }
const StringName &C_DRIVE() { static const StringName s("ual/Driving_Loop"); return s; }
}

Vector3 CityCar::get_driver_hips() const { return driver && driver->is_visible() ? driver->bone_world("Bip01_Pelvis") : Vector3(); }

CityPlayer *CityCar::door_player() const {
	return dr_player ? Object::cast_to<CityPlayer>(ObjectDB::get_instance(ObjectID(dr_player))) : nullptr;
}

bool CityCar::enter(CityPlayer *p_pl) {
	if (!made || !p_pl || dr_state != DR_NONE) return false;
	if (!driver) {
		driver = memnew(CityPed);
		driver->set_body_id("M1");
		add_child(driver);
		driver->set_as_top_level(true);
	}
	if (CityPed *pf = p_pl->figure()) {   // he looks as the player does
		const Ref<Mesh> m = pf->get_body_mesh(); const Ref<ShaderMaterial> lk = pf->get_look();
		if (m.is_valid()) driver->become(pf->get_body(), m, lk.is_valid() ? Ref<ShaderMaterial>(lk->duplicate()) : Ref<ShaderMaterial>(), false);
	}
	dr_player = p_pl->get_instance_id();
	dr_at = p_pl->get_global_position(); dr_at.y -= 0.05f;
	dr_yaw = p_pl->get_yaw();
	p_pl->set_riding(true);
	p_pl->view_vehicle(this);   // (his camera follows his body to the seat, then frames the car: the one camera)
	driver->set_visible(true);
	// the way to the door: straight, or round the front when he stands on the car's far side
	dr_path.clear();
	const Transform3D t = get_global_transform();
	const Vector3 l = t.affine_inverse().xform(dr_at);
	const cm::CarModel &m = cm::MODELS[std::min(std::max(model, 0), cm::N_MODELS - 1)];
	if (l.x < m.half_w * 0.5f) {
		const float zf = l.z > 0.0f ? m.half_len + 0.7f : -(m.half_len + 0.7f);
		dr_path.push_back(Vector3(-(m.half_w + 0.6f), 0.0f, zf));
		dr_path.push_back(Vector3(m.half_w + 0.6f, 0.0f, zf));
	}
	dr_path.push_back(door_spot());
	dr_state = DR_WALK; dr_t = 0.0f; dr_k = 0;
	return true;
}

bool CityCar::leave() {
	if (dr_state != DR_SEATED || get_linear_velocity().length() > 2.5f) return false;
	take_wheel(false);
	dr_state = DR_OPEN_OUT; dr_t = 0.0f;
	return true;
}

// the root that puts a clip's hips at a place (node frame of the car), the figure turned by yaw (car frame)
Transform3D CityCar::door_root(const StringName &p_clip, double p_t, const Vector3 &p_hips, float p_yaw) const {
	const Transform3D t = get_global_transform();
	const Basis b = t.basis.orthonormalized() * Basis(Vector3(0, 1, 0), p_yaw);
	const Vector3 hips_w = t.xform(p_hips);
	return Transform3D(b, hips_w - b.xform(driver->clip_hips_at(p_clip, p_t)));
}

// seated: his feet on the pedals in the footwell, his hands on the wheel (else the seated clip's legs went down through the
// floor and his feet showed under the sill: tests/game/test_car_entry.gd); p_w 0..1 as he swings in or out
void CityCar::door_reach(float p_w) {
	if (!driver || !driver->skeleton()) return;
	if (!dr_reach) { dr_reach = memnew(BikeReach); driver->skeleton()->add_child(dr_reach); }
	dr_reach->set_active(p_w > 0.001f); dr_reach->set_influence(p_w);
	if (p_w <= 0.001f) return;
	const Vector3 h = seat_hips();
	for (int s = 0; s < 2; s++) {
		const float sx = s == 0 ? 0.11f : -0.11f;
		dr_reach->foot_l[s] = Vector3(h.x + sx, door_lo.y + 0.12f, h.z + 0.80f);
		dr_reach->hand_l[s] = Vector3(h.x + (s == 0 ? 0.19f : -0.19f), h.y + 0.42f, h.z + 0.48f);
	}
	dr_reach->frame_id = get_instance_id();
	dr_reach->lean = 0.0f; dr_reach->hand_turn = 0.0f;
}

void CityCar::door_update(double p_delta) {
	if (dr_state == DR_NONE || !driver) return;
	const float dt = (float)p_delta;
	dr_t += dt;
	const Transform3D t = get_global_transform();
	const Vector3 fw = t.basis.get_column(2), sd = t.basis.get_column(0);
	const float car_yaw = std::atan2(fw.x, fw.z);
	// in the car's frame the figure faces: out of the door (+x) = yaw +pi/2, forward = 0, at the door (-x) = -pi/2
	const float Y_OUT = 1.5707963f, Y_IN = -1.5707963f, Y_FWD = 0.0f;
	const Vector3 spot = door_spot(), hips = seat_hips();
	CityPlayer *pl = door_player();
	switch (dr_state) {
		case DR_WALK: {
			Vector3 target = t.xform(dr_path[std::min(dr_k, (int)dr_path.size() - 1)]);
			Vector3 d = target - dr_at; d.y = 0.0f;
			const float dist = d.length(), v = 1.3f;
			if (dist < 0.06f) {
				if (++dr_k >= (int)dr_path.size()) { dr_state = DR_FACE; dr_t = 0.0f; }
				break;
			}
			const Vector3 step = d / dist * std::min(dist, v * dt);
			dr_at += step;
			dr_at.y = t.origin.y + (t.basis.get_column(1).normalized() * 0.0f).y;   // (on the ground the car stands on)
			const float want = std::atan2(d.x, d.z);
			dr_yaw += std::min(std::max(wrapa(want - dr_yaw), -8.0f * dt), 8.0f * dt);
			driver->drive(Transform3D(Basis(Vector3(0, 1, 0), dr_yaw), dr_at), C_WALK(), v / 0.91, -1.0);
		} break;
		case DR_FACE: {   // face the door
			const float want = car_yaw + Y_IN;
			dr_yaw += std::min(std::max(wrapa(want - dr_yaw), -6.0f * dt), 6.0f * dt);
			driver->drive(Transform3D(Basis(Vector3(0, 1, 0), dr_yaw), dr_at), C_IDLE(), 1.0, -1.0);
			if (std::fabs(wrapa(want - dr_yaw)) < 0.05f || dr_t > 0.6f) { dr_state = DR_OPEN_IN; dr_t = 0.0f; }
		} break;
		case DR_OPEN_IN: {   // he reaches for the handle and pulls it open (the door swings out round him: he steps back a little)
			const float T = 0.75f;
			set_door(ssf(0.2f, T, dr_t));
			const Vector3 back = dr_at + sd * (0.12f * ssf(0.2f, T, dr_t));
			driver->drive(Transform3D(Basis(Vector3(0, 1, 0), dr_yaw), back), C_REACH(), 1.0, -2.0);
			if (dr_t >= T) { dr_state = DR_SIT_IN; dr_t = 0.0f; dr_at = back; dr_from = driver->get_global_transform(); }
		} break;
		case DR_SIT_IN: {   // back to the seat, down into it: the root carried so the hips end on the seat
			const float L = (float)std::max(driver->clip_len(C_SIT_IN()), 0.8);
			const float u = std::min(dr_t / L, 1.0f);
			const Transform3D end = door_root(C_SIT_IN(), L, hips, Y_OUT);
			const Transform3D start(Basis(Vector3(0, 1, 0), car_yaw + Y_OUT), dr_from.origin);
			const float k = ssf(0.0f, 1.0f, u), kr = ssf(0.0f, 0.35f, u);
			const Basis b = Basis(Quaternion(dr_from.basis.orthonormalized()).slerp(Quaternion(end.basis), kr));
			driver->drive(Transform3D(b, start.origin.lerp(end.origin, k)), C_SIT_IN(), 1.0, -2.0);
			if (dr_t >= L) { dr_state = DR_TURN_IN; dr_t = 0.0f; }
		} break;
		case DR_TURN_IN: {   // seated, he swings his legs in and faces forward
			const float T = 0.7f, k = ssf(0.0f, T, dr_t);
			driver->drive(door_root(C_SIT(), 0.0, hips, Y_OUT + (Y_FWD - Y_OUT) * k), C_SIT(), 1.0, -1.0);
			door_reach(ssf(0.4f, 1.0f, k));
			if (dr_t >= T) { dr_state = DR_CLOSE_IN; dr_t = 0.0f; }
		} break;
		case DR_CLOSE_IN: {
			const float T = 0.5f;
			set_door(1.0f - ssf(0.0f, T, dr_t));
			driver->drive(door_root(C_DRIVE(), 0.0, hips, Y_FWD), C_DRIVE(), 1.0, -1.0);
			door_reach(1.0f);
			if (dr_t >= T) { dr_state = DR_SEATED; dr_t = 0.0f; take_wheel(true); }
		} break;
		case DR_SEATED:
			driver->drive(door_root(C_DRIVE(), 0.0, hips, Y_FWD), C_DRIVE(), 1.0, -1.0);
			door_reach(1.0f);
			break;
		case DR_OPEN_OUT: {
			const float T = 0.6f;
			set_door(ssf(0.0f, T, dr_t));
			driver->drive(door_root(C_SIT(), 0.0, hips, Y_FWD), C_SIT(), 1.0, -1.0);
			door_reach(1.0f);
			if (dr_t >= T) { dr_state = DR_TURN_OUT; dr_t = 0.0f; }
		} break;
		case DR_TURN_OUT: {
			const float T = 0.6f, k = ssf(0.0f, T, dr_t);
			driver->drive(door_root(C_SIT(), 0.0, hips, Y_FWD + (Y_OUT - Y_FWD) * k), C_SIT(), 1.0, -1.0);
			door_reach(1.0f - ssf(0.0f, 0.6f, k));
			if (dr_t >= T) { dr_state = DR_STAND_OUT; dr_t = 0.0f; door_reach(0.0f); }
		} break;
		case DR_STAND_OUT: {   // up and out: from the seat to standing by the door
			const float L = (float)std::max(driver->clip_len(C_SIT_OUT()), 0.8);
			const float u = std::min(dr_t / L, 1.0f);
			const Transform3D start = door_root(C_SIT_OUT(), 0.0, hips, Y_OUT);
			const Vector3 end_at = t.xform(spot + Vector3(0.1f, 0.0f, 0.0f));
			const Transform3D last = door_root(C_SIT_OUT(), L, hips, Y_OUT);   // (where the clip alone would leave him)
			const float k = ssf(0.0f, 1.0f, u);
			const Vector3 at = start.origin + (Vector3(end_at.x, start.origin.y, end_at.z) - Vector3(last.origin.x, start.origin.y, last.origin.z)) * k;
			Vector3 at2 = at; at2.y = start.origin.y + (end_at.y - start.origin.y) * k;
			driver->drive(Transform3D(start.basis, at2), C_SIT_OUT(), 1.0, -2.0);
			if (dr_t >= L) {
				const Transform3D now = driver->get_global_transform();
				const Vector3 f = now.basis.get_column(2);
				Vector3 stand = now.origin + now.basis.xform(driver->clip_hips_at(C_SIT_OUT(), L)) - now.basis.xform(driver->clip_hips_at(C_IDLE(), 0.0));
				stand.y = t.origin.y;
				driver->set_visible(false);
				if (pl) { pl->set_riding(false); pl->stand_at(stand + Vector3(0, 0.05f, 0), std::atan2(f.x, f.z)); pl->take_view(); }
				dr_state = DR_CLOSE_OUT; dr_t = 0.0f;
			}
		} break;
		case DR_CLOSE_OUT: {
			const float T = 0.5f;
			set_door(1.0f - ssf(0.15f, T, dr_t));
			if (dr_t >= T) { dr_state = DR_NONE; dr_t = 0.0f; dr_player = 0; lock_sound(); }
		} break;
		default: break;
	}
}

} // namespace godot
