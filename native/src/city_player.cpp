// CityPlayer: see city_player.h.
#include "city_player.h"

#include "city_ped.h"
#include "hand_grip.h"
#include <godot_cpp/classes/skeleton3d.hpp>

#include <godot_cpp/classes/audio_effect_capture.hpp>
#include <godot_cpp/classes/audio_server.hpp>
#include <godot_cpp/classes/audio_stream_microphone.hpp>
#include <godot_cpp/classes/audio_stream_player.hpp>
#include <godot_cpp/classes/os.hpp>

#include <godot_cpp/classes/capsule_shape3d.hpp>
#include <godot_cpp/classes/collision_shape3d.hpp>
#include <godot_cpp/classes/engine.hpp>
#include <godot_cpp/classes/input.hpp>
#include <godot_cpp/classes/input_event_mouse_motion.hpp>
#include <godot_cpp/classes/input_event_screen_drag.hpp>
#include <godot_cpp/classes/scene_tree.hpp>
#include <godot_cpp/classes/window.hpp>
#include <godot_cpp/classes/input_event_screen_touch.hpp>
#include <godot_cpp/classes/viewport.hpp>
#include <godot_cpp/classes/physics_direct_space_state3d.hpp>
#include <godot_cpp/classes/physics_ray_query_parameters3d.hpp>
#include <godot_cpp/classes/world3d.hpp>
#include <godot_cpp/core/class_db.hpp>

#include <algorithm>
#include <cmath>

namespace godot {

void CityPlayer::_ready() {
	if (Engine::get_singleton()->is_editor_hint()) return;
	Ref<CapsuleShape3D> sh; sh.instantiate();
	sh->set_radius(0.3f); sh->set_height(1.75f);
	CollisionShape3D *cs = memnew(CollisionShape3D);
	cs->set_shape(sh); cs->set_position(Vector3(0, 0.875f, 0));
	add_child(cs);
	set_collision_layer(2);              // layer 2: the player on foot
	set_collision_mask(1 | 16 | 32);     // the world, the traffic's cars, the people's capsules
	set_floor_snap_length(0.3f);
	set_max_slides(4);
	fig = memnew(CityPed);
	fig->set_body_id(body_id);
	fig->set_clip("ual/Idle_Loop");
	add_child(fig);
	cam = memnew(Camera3D);
	cam->set_as_top_level(true);
	cam->set_fov(62.0); cam->set_near(0.1); cam->set_far(1500.0);
	add_child(cam);
	cam->make_current();
	if (OS::get_singleton()->has_feature("mobile")) {   // the microphone, for the back tap's knock (its sound must agree with the motion)
		AudioServer *as = AudioServer::get_singleton();
		int b = as->get_bus_index("TapMic");
		if (b < 0) { as->add_bus(); b = as->get_bus_count() - 1; as->set_bus_name(b, "TapMic"); as->set_bus_volume_db(b, -80.0f); }
		Ref<AudioEffectCapture> cap; cap.instantiate(); cap->set_buffer_length(0.25f);
		as->add_bus_effect(b, cap);
		mic_cap = cap.ptr(); cap->reference();
		AudioStreamPlayer *mp = memnew(AudioStreamPlayer);
		Ref<AudioStreamMicrophone> ms; ms.instantiate();
		mp->set_stream(ms); mp->set_bus("TapMic");
		add_child(mp); mp->play();
	}
	cam_yaw = get_rotation().y + 3.14159265f;
	yaw = std::atan2(-std::sin(cam_yaw), -std::cos(cam_yaw));   // (he looks the way his camera looks)
	if (capture_mouse) Input::get_singleton()->set_mouse_mode(Input::MOUSE_MODE_CAPTURED);
	set_physics_process(true); set_process(true); set_process_input(true);
}

void CityPlayer::_exit_tree() {
	if (capture_mouse && !Engine::get_singleton()->is_editor_hint()) Input::get_singleton()->set_mouse_mode(Input::MOUSE_MODE_VISIBLE);
}

void CityPlayer::_input(const Ref<InputEvent> &p_event) {
	if (frozen) return;
	Viewport *vp = get_viewport();
	const Vector2 sz = vp ? vp->get_visible_rect().size : Vector2(1152, 648);
	auto on_button = [&](const Vector2 &p) { for (int k = 0; k < n_no_touch; k++) if (no_touch[k].has_point(p)) return true; return false; };
	auto sens = [&]() { Object *g = get_tree() ? get_tree()->get_root()->get_node_or_null("Game") : nullptr; return g ? (float)(double)g->call("get_setting", "cam_sens") : 1.0f; };
	auto inv = [&]() { Object *g = get_tree() ? get_tree()->get_root()->get_node_or_null("Game") : nullptr; return g ? (bool)g->call("get_setting", "invert_y") : false; };
	if (const InputEventScreenTouch *t = Object::cast_to<InputEventScreenTouch>(p_event.ptr())) {
		const int id = t->get_index();
		const Vector2 p = t->get_position();
		if (id < 0 || id >= 16) return;
		if (t->is_pressed()) {
			if (on_button(p)) return;
			const int half = p.x < sz.x * 0.5f ? 0 : 1;
			if (clock_s - tap_t[half] < 0.32 && p.distance_to(tap_p[half]) < 110.0f) {   // a double tap: crouch (left) / jump (right)
				if (half == 0) crouch = !crouch; else jump_want = true;
				tap_t[half] = -9.0;
			} else { tap_t[half] = clock_s; tap_p[half] = p; }
			if (half == 0) { move_on[id] = true; move_start[id] = p; }
		} else {
			move_on[id] = false;
			bool any = false;
			for (int k = 0; k < 16; k++) any = any || move_on[k];
			if (!any) touch_mv = Vector2();
		}
		return;
	}
	if (const InputEventScreenDrag *d = Object::cast_to<InputEventScreenDrag>(p_event.ptr())) {
		const int id = d->get_index();
		if (id >= 0 && id < 16 && move_on[id]) { touch_mv = ((d->get_position() - move_start[id]) / 80.0f).limit_length(1.0f); return; }
		Vector2 rel = d->get_relative() * 1.2f * sens();   // the look: 0.25 deg a pixel, x1.2 for a thumb
		if (inv()) rel.y = -rel.y;
		cam_yaw -= rel.x * 0.25f * 0.0174533f;
		cam_pitch = std::min(std::max(cam_pitch - rel.y * 0.25f * 0.0174533f, -1.1f), 0.5f);
		return;
	}
	const InputEventMouseMotion *mm = Object::cast_to<InputEventMouseMotion>(p_event.ptr());
	if (mm && Input::get_singleton()->get_mouse_mode() == Input::MOUSE_MODE_CAPTURED) {
		cam_yaw -= (float)mm->get_relative().x * 0.0035f;
		cam_pitch = std::min(std::max(cam_pitch - (float)mm->get_relative().y * 0.003f, -1.1f), 0.5f);
	}
}

void CityPlayer::set_move(const Vector2 &p_dir, bool p_run) { cmd = p_dir; cmd_run = p_run; scripted = true; }

// The phone's motion and the microphone: a hard swing down (the gyro over 7 rad/s with 12 m/s2 more than gravity)
// asks for combat; a tap on the back is a short sharp knock on the accelerometer (3.5 m/s2 over its own running level)
// while the gyro stays quiet (it is not a swing), with a knock on the microphone within 0.1 s: all three must agree.
void CityPlayer::sense(double p_dt) {
	Input *in = Input::get_singleton();
	swing_cd = std::max(0.0, swing_cd - p_dt); tap_cd = std::max(0.0, tap_cd - p_dt);
	const Vector3 a = in->get_accelerometer(), g = in->get_gyroscope();
	if (a.length_squared() < 1e-6f) return;   // (no sensors: a PC)
	if (!acc_init) { acc_lp = a; acc_init = true; }
	const Vector3 hp = a - acc_lp;
	acc_lp += (a - acc_lp) * (float)std::min(1.0, p_dt * 4.0);
	const float gyro = g.length();
	if (gyro > 7.0f && std::fabs(a.length() - 9.81f) > 12.0f && swing_cd <= 0.0) { combat_req = true; swing_cd = 1.5; }
	if (hp.length() > 3.5f && gyro < 3.0f) acc_spike_t = clock_s;
	if (mic_cap) {
		const int n = mic_cap->get_frames_available();
		if (n > 0) {
			const PackedVector2Array fr = mic_cap->get_buffer(n);
			float peak = 0.0f;
			for (int k = 0; k < fr.size(); k++) peak = std::max(peak, std::max(std::fabs(fr[k].x), std::fabs(fr[k].y)));
			if (peak > 0.25f && peak > mic_avg * 5.0f) mic_spike_t = clock_s;
			mic_avg += (peak - mic_avg) * 0.05f;
		}
	} else mic_spike_t = acc_spike_t;   // (no microphone: the motion alone)
	if (combat && tap_cd <= 0.0 && acc_spike_t > clock_s - 0.12 && std::fabs(acc_spike_t - mic_spike_t) < 0.1) { punch_req = true; tap_cd = 0.25; acc_spike_t = -9.0; }
}

int CityPlayer::take_punch() {
	if (!punch_req || !combat || punch_t < punch_len * 0.7) { punch_req = false; return 0; }
	punch_req = false;
	punch_t = 0.0; punch_side ^= 1; punches++;
	return 1 + punch_side;
}

void CityPlayer::_physics_process(double p_delta) {
	if (!fig) return;
	const float dt = (float)p_delta;
	sense(p_delta);
	punch_t += p_delta; hit_t += p_delta; combat_t += p_delta; uncombat_t += p_delta;
	{   // a PC: F fights, J or a left click punches
		Input *ki = Input::get_singleton();
		const bool f = ki->is_key_pressed(KEY_F), j = ki->is_key_pressed(KEY_J), m = ki->is_mouse_button_pressed(MOUSE_BUTTON_LEFT) && ki->get_mouse_mode() == Input::MOUSE_MODE_CAPTURED;
		if (f && !f_was) combat_req = true;
		if ((j && !j_was) || (m && !m_was)) punch();
		f_was = f; j_was = j; m_was = m;
	}
	Input *in = Input::get_singleton();
	Vector2 mv = cmd; bool run = cmd_run;
	if (!scripted && !frozen) {   // W A S D or the left stick; Shift (or the right trigger) runs; the arrows or the right stick turn the view
		mv = Vector2((in->is_key_pressed(KEY_D) ? 1.0f : 0.0f) - (in->is_key_pressed(KEY_A) ? 1.0f : 0.0f), (in->is_key_pressed(KEY_W) ? 1.0f : 0.0f) - (in->is_key_pressed(KEY_S) ? 1.0f : 0.0f));
		const Vector2 js((float)in->get_joy_axis(0, JOY_AXIS_LEFT_X), -(float)in->get_joy_axis(0, JOY_AXIS_LEFT_Y));
		if (js.length() > 0.2f) mv += js;
		run = in->is_key_pressed(KEY_SHIFT) || in->get_joy_axis(0, JOY_AXIS_TRIGGER_RIGHT) > 0.3;
		if (mv.length() > 0.05f && !run) mv = mv.normalized() * 0.6f;   // (the old game: a key walks at 0.6, Shift runs at 1.0)
		if (touch_mv.length() > 0.05f) { mv = Vector2(touch_mv.x, -touch_mv.y); run = touch_mv.length() > 0.9f; }   // the invisible stick (screen up = ahead)
		const bool space = in->is_key_pressed(KEY_SPACE), ck = in->is_key_pressed(KEY_C) || in->is_key_pressed(KEY_CTRL);
		if (space && !space_was) jump_want = true;
		if (ck && !c_was) crouch = !crouch;
		space_was = space; c_was = ck;
		cam_yaw += ((in->is_key_pressed(KEY_LEFT) ? 1.0f : 0.0f) - (in->is_key_pressed(KEY_RIGHT) ? 1.0f : 0.0f) - (std::fabs(in->get_joy_axis(0, JOY_AXIS_RIGHT_X)) > 0.2 ? (float)in->get_joy_axis(0, JOY_AXIS_RIGHT_X) : 0.0f)) * 2.2f * dt;
		const bool e = in->is_key_pressed(KEY_E) || in->is_joy_button_pressed(0, JOY_BUTTON_X);
		if (e && !e_was) emit_signal("interact");
		e_was = e;
	}
	if (frozen) mv = Vector2();
	if (mv.length() > 1.0f) mv = mv.normalized();
	// the way he goes: by the view (forward = away from the camera)
	const Vector3 fwd(-std::sin(cam_yaw), 0, -std::cos(cam_yaw)), right(std::cos(cam_yaw), 0, -std::sin(cam_yaw));
	// water: swimming begins where his feet are 1.15 m under the surface, and ends where the ground comes up to 0.9 m
	const Vector3 here = get_global_position();
	if (water_y > -999.0) {
		if (!swimming && here.y < water_y - 1.15) swimming = true;
		else if (swimming) {
			Ref<PhysicsRayQueryParameters3D> q = PhysicsRayQueryParameters3D::create(here + Vector3(0, 0.6f, 0), here - Vector3(0, 3.0f, 0), 1);
			const Dictionary hit = get_world_3d()->get_direct_space_state()->intersect_ray(q);
			if (!hit.is_empty() && water_y - (double)Vector3(hit["position"]).y < 0.9) swimming = false;
		}
	} else swimming = false;
	clock_s += dt;
	if (climb) {   // climbing: up first, then over the edge, as the clip plays; nothing else moves him
		climb_t += dt;
		if (climb == 2 && !hang_set && climb_t > dt * 1.5f) {   // (the clip's first pose is up: its hands over its hips)
			Skeleton3D *sk = fig->skeleton();
			const int hl = sk ? sk->find_bone("Bip01_L_Hand") : -1, hr = sk ? sk->find_bone("Bip01_R_Hand") : -1;
			if (hl >= 0 && hr >= 0) {
				const Transform3D sg = sk->get_global_transform();
				const Vector3 hands = (sg.xform(sk->get_bone_global_pose(hl).origin) + sg.xform(sk->get_bone_global_pose(hr).origin)) * 0.5f;
				const Vector3 pel = pelvis_world();
				const float up_off = hands.y - pel.y;
				const float in_off = (hands - pel).dot(-edge_out);   // (how far ahead of his hips the hands are)
				// hips: under the edge by the hands' height, back from it by their reach; feet: the hips' rest below
				Vector3 hang = edge_at + Vector3(0, 0.07f - up_off - pel_rest.y, 0) + edge_out * std::max(in_off, 0.2f);
				climb_hang = hang;   // (reached over the climb's first 15 %: walking up to the wall he rises into it, no jump of the body)
			}
			hang_set = true;
		}
		const float u = std::min(climb_t / climb_len, 1.0f);
		auto ss = [](float a, float b, float x) { const float t = std::min(std::max((x - a) / (b - a), 0.0f), 1.0f); return t * t * (3.0f - 2.0f * t); };
		Vector3 at = climb_from;
		if (climb == 4) {   // a fence: up and over the rail, down on the far side
			const float a = ss(0.0f, 0.5f, u), b = ss(0.5f, 1.0f, u);
			at = climb_from.lerp(vault_over, a).lerp(climb_to, b);
		} else if (climb == 2) {
			// (Yasin: "the hands rise with the body. They should stay pinned to the ledge's edge until he lets go"): up to
			// the hips at the edge's height just behind it (the hands held, the arms pushing), then over it and up on top
			const Vector3 mid = Vector3(edge_at.x, edge_at.y - pel_rest.y - 0.12f, edge_at.z) + edge_out * 0.26f;
			const Vector3 hang = hang_set ? climb_hang : climb_from;
			const float h0 = ss(0.0f, 0.22f, u), a = ss(0.22f, 0.58f, u), b = ss(0.58f, 1.0f, u);
			at = climb_from.lerp(hang, h0).lerp(mid, a).lerp(climb_to, b);
		} else {
			// (Yasin: "they shouldnt jump up the character so much on the approach, characters body should lift after the
			// first leg is on the collision"): forward first, the first foot up onto the top (planted there by FootPlant),
			// then the body lifts
			at.y += (climb_to.y - climb_from.y) * ss(climb == 3 ? 0.35f : 0.3f, climb == 3 ? 0.85f : 0.8f, u);
			const float over = ss(0.0f, 1.0f, u);
			at.x += (climb_to.x - climb_from.x) * over; at.z += (climb_to.z - climb_from.z) * over;
		}
		set_global_position(at); set_velocity(Vector3());
		// the hands: on the edge while he hangs and pulls (a high climb: from the grab till he is over it; a low one: while
		// he pushes himself up), let go as he stands up there; a step: no hands
		{
			float w = 0.0f;
			if (climb == 2) w = ss(0.0f, 0.06f, u) * (1.0f - ss(0.58f, 0.72f, u));   // (held till his hips are at the edge, let go as he goes over)
			else if (climb == 1) w = ss(0.12f, 0.3f, u) * (1.0f - ss(0.55f, 0.75f, u));
			else if (climb == 4) w = ss(0.05f, 0.2f, u) * (1.0f - ss(0.55f, 0.72f, u));   // (the hand on the rail as he goes over it)
			grip_w = w;
			grip_update();
		}
		const int climb_kind = climb;
		if (u >= 1.0f) { climb = 0; airborne = false; grip_w = 0.0f; grip_update(); settle_t = 0.0f; }
		speed = 0.0f;
		// (the high climb: the pull-up, ClimbUp_2m; Yasin tried a leg over the top, ClimbLedge, and chose: "old pull over long
		// climb was much better, revert to it")
		static const StringName C_LOW("ual/ClimbUp_1m"), C_HIGH("ual/ClimbUp_2m"), C_STEP("ual/StepUp"), C_VAULT("ual/SafetyVault");
		const StringName cc = climb_kind == 2 ? C_HIGH : (climb_kind == 3 ? C_STEP : (climb_kind == 4 ? C_VAULT : C_LOW));
		const double len = fig->clip_len(cc);
		// the figure placed so its hips follow the climb's path: how far the clip itself has carried the hips by now (read
		// from its tracks at the moment it is playing, not measured: the measured one came a frame late and the figure bobbed
		// up and down chasing it; Yasin: "stepup jitter is still there, find whats causing it")
		{
			const double tc = cur_clip_is(cc) ? fig->clip_pos() : 0.0;
			const Vector3 carried = fig->clip_hips_at(cc, tc) - fig->clip_hips_at(cc, 0.0);
			clip_off = Basis(Vector3(0, 1, 0), yaw).xform(carried);
		}
		Vector3 fig_at = at - clip_off;
		fig->drive(Transform3D(Basis(Vector3(0, 1, 0), yaw), fig_at), cc, len > 0.0 ? std::min(std::max(len / (double)climb_len, 0.5), 3.0) : 1.0, -2.0);
		fig_drawn_at = fig_at;
		if (climb == 0) settle_off = at - fig_at;   // (the move just ended: the ease to Idle starts exactly where the figure stands)
		if (plant) { const bool on = (climb != 2 && climb != 4) || u > 0.8f; plant->set_active(on); plant->set_influence(on ? 1.0f : 0.0f); plant->fwd = Vector3(std::sin(yaw), 0, std::cos(yaw)); }
		return;
	}
	if (settle_t < 0.45f) {   // just up from a step or climb: he stands a moment (the clip's end fading into Idle), then walks
		settle_t += dt;
		const float s0 = std::min(settle_t / 0.45f, 1.0f), f = 1.0f - s0 * s0 * (3.0f - 2.0f * s0);   // (eased: no step at its start or end)
		set_velocity(Vector3(0, -0.5f, 0)); move_and_slide(); speed = 0.0f;
		static const StringName IDLE_S("ual/Idle_Loop");
		const Vector3 fa = get_global_position() - settle_off * f;
		fig->drive(Transform3D(Basis(Vector3(0, 1, 0), yaw), fa), IDLE_S, 1.0, -1.0);
		if (plant) { plant->set_active(true); plant->set_influence(1.0f); }
		return;
	}
	if (swimming) crouch = false;
	if (crouch != crouch_prev) { crouch_prev = crouch; crouch_t = 0.0f; }
	crouch_t += dt;
	float top = swimming ? (run ? 1.7f : 1.0f) : (run ? run_speed : walk_speed);
	if (crouch && !swimming) top *= 0.45f;
	if (combat) top = std::min(top, 1.4f);   // (in his stance he steps, he does not run)
	if (settle_t < 1.1f) { settle_t += dt; top = std::min(top, walk_speed); }   // (Yasin: "ease it into idle after the climb then walk again": walking first, not running off)
	const Vector3 want = (fwd * mv.y + right * mv.x) * top;
	Vector3 v = get_velocity();
	const Vector3 hv(v.x, 0, v.z);
	const Vector3 nh = hv.move_toward(want, (want.length() > hv.length() ? 9.0f : 14.0f) * dt);
	v.x = nh.x + knock_v.x; v.z = nh.z + knock_v.z;
	knock_v = Vector3();
	if (swimming) v.y = std::min(std::max(((float)water_y - 0.38f - (float)here.y) * 4.0f, -1.5f), 1.5f);   // he floats: his body lies at the surface
	else if (is_on_floor() && jump_want && !frozen) { v.y = 4.3f; airborne = true; crouch = false; jump_y = (float)here.y; }   // a jump: 4.3 m/s up (about 0.95 m)
	else v.y = is_on_floor() ? -0.5f : v.y - 9.81f * dt;
	jump_want = false;
	set_velocity(v);
	move_and_slide();
	// STEP UP (Yasin: "make the small heights like 20 cm walkable over"): walking into something no higher than 24 cm (a
	// kerb, a step) he is lifted onto it: free to rise 24 cm, free 30 cm ahead up there, and something to stand on there
	if (!swimming && !frozen && !combat && !crouch && Vector3(want.x, 0, want.z).length() > 0.3f && try_climb(Vector3(want.x, 0, want.z).normalized())) {}
	else if (!swimming && !airborne && !frozen && is_on_wall() && Vector3(want.x, 0, want.z).length() > 0.3f) {
		const Vector3 dir = Vector3(want.x, 0, want.z).normalized();
		Transform3D t2 = get_global_transform();
		const Vector3 up(0, 0.24f, 0), ahead = dir * 0.3f;
		if (!test_move(t2, up)) {
			t2.origin += up;
			if (!test_move(t2, ahead)) {
				t2.origin += ahead;
				if (test_move(t2, Vector3(0, -0.3f, 0))) { set_global_position(t2.origin); apply_floor_snap(); steps_up++; }
			}
		}
	}
	const Vector3 got = get_velocity();
	speed = Vector3(got.x, 0, got.z).length();
	if (combat) {   // in combat he faces his target whichever way he steps
		const Vector3 to = combat_target - get_global_position();
		const float want_yaw = std::atan2(to.x, to.z);
		float d = std::fmod(want_yaw - yaw + 3.14159265f, 6.2831853f); if (d < 0.0f) d += 6.2831853f; d -= 3.14159265f;
		yaw += std::min(std::max(d, -10.0f * dt), 10.0f * dt);
	} else if (speed > 0.25f) {   // he faces the way he walks
		const float want_yaw = std::atan2(got.x, got.z);
		float d = std::fmod(want_yaw - yaw + 3.14159265f, 6.2831853f); if (d < 0.0f) d += 6.2831853f; d -= 3.14159265f;
		yaw += std::min(std::max(d, -9.0f * dt), 9.0f * dt);
	}
	// his figure: the Quaternius clips by his pace
	static const StringName IDLE("ual/Idle_Loop"), WALK("ual/Walk_Loop"), JOG("ual/Jog_Fwd_Loop"), SPRINT("ual/Sprint_Loop"), SWIM("ual/Swim_Fwd_Loop"), FLOAT("ual/Swim_Idle_Loop");
	static const StringName CR_IDLE("ual/Crouch_Idle_Loop"), CR_FWD("ual/Crouch_Fwd_Loop"), J_UP("ual/Jump_Start"), J_AIR("ual/Jump_Loop"), J_LAND("ual/Jump_Land"), CR_IN("ual/Crouch_Enter"), CR_OUT("ual/Crouch_Exit");
	StringName clip = IDLE; double cs = 1.0, hold = -1.0;
	const bool floor_now = is_on_floor();
	if (airborne && floor_now && get_velocity().y <= 0.0f) { airborne = false; land_t = 0.35f; }
	land_t = std::max(0.0f, land_t - dt);
	if (swimming) { clip = speed > 0.25f ? SWIM : FLOAT; cs = speed > 0.25f ? speed / 1.0 : 1.0; }
	else if (airborne) { clip = get_velocity().y > 1.0f ? J_UP : J_AIR; hold = get_velocity().y > 1.0f ? -2.0 : -1.0; }
	else if (land_t > 0.0f) { clip = J_LAND; hold = -2.0; }
	else if (combat) {   // his guard (the way into a fight, held on its last frame); a punch, the jab and the cross in turn
		static const StringName GUARD("ual/PunchKick_Enter"), JAB("ual/Punch_Jab"), CROSS("ual/Punch_Cross");
		static const StringName HIT("ual/Hit_Chest");
		if (hit_t < 0.45) { clip = HIT; hold = -2.0; }
		else if (punch_t < punch_len) { clip = punch_side == 0 ? JAB : CROSS; hold = -2.0; }
		else if (combat_t < fig->clip_len(GUARD)) { clip = GUARD; hold = -2.0; }   // (into the guard: played through)
		else { clip = GUARD; hold = std::max(fig->clip_len(GUARD) - 0.03, 0.0); }
	}
	else if (uncombat_t < 0.9 && speed < 0.5f) { static const StringName GUARD_OUT("ual/PunchKick_Exit"); clip = GUARD_OUT; hold = -2.0; }   // (out of the guard)
	else if (crouch && speed < 0.5f && crouch_t < fig->clip_len(CR_IN)) { clip = CR_IN; hold = -2.0; }   // (down into the crouch)
	else if (crouch) { clip = speed > 0.2f ? CR_FWD : CR_IDLE; cs = speed > 0.2f ? speed / 0.8 : 1.0; }
	else if (!crouch && speed < 0.5f && crouch_t < fig->clip_len(CR_OUT) && !airborne) { clip = CR_OUT; hold = -2.0; }   // (up out of it)
	else if (speed > 3.6f) { clip = SPRINT; cs = speed / 3.1; }
	else if (speed > 2.0f) { clip = JOG; cs = speed / 2.4; }
	else if (speed > 0.2f) { clip = WALK; cs = speed / 0.92; }
	fig->drive(Transform3D(Basis(Vector3(0, 1, 0), yaw), get_global_position()), clip, std::min(std::max(cs, 0.5), 2.0), hold);
	if (Skeleton3D *sk = fig->skeleton()) {
		if (!plant) { plant = memnew(FootPlant); sk->add_child(plant); }
		const bool on = !airborne && !swimming && !frozen;
		plant->set_active(on); plant->set_influence(on ? 1.0f : 0.0f);
		plant->skip = get_rid(); plant->fwd = Vector3(std::sin(yaw), 0, std::cos(yaw));
	}
}

// A ledge ahead: its top (a ray down just past the wall), room to stand there, how high over the ground he stands on
// (or jumped from): 24-50 cm on foot: climb onto it; 0.5-2.5 m in a jump: grab it and pull up.
bool CityPlayer::try_climb(const Vector3 &p_dir) {
	if (!fig || !get_world_3d().is_valid()) return false;
	PhysicsDirectSpaceState3D *ss = get_world_3d()->get_direct_space_state();
	if (!ss) return false;
	const Vector3 p = get_global_position();
	const float base = airborne ? jump_y : p.y;
	TypedArray<RID> ex; ex.push_back(get_rid());
	// ON THE APPROACH (Yasin: "he shouldnt wait that long to climb at the edge, when player approaches and is on the
	// trajectory to climb, it should automatically queue"; "it applies to every locomotion animation"): the face of what is
	// ahead, found by a ray at shin height (and, in a jump, at chest height) up to 45 cm from him (his front 15 cm from it); the move starts there,
	// his stride carried into it
	Vector3 face; bool has_face = false;
	for (float hgt : { 0.12f, 0.6f }) {
		Ref<PhysicsRayQueryParameters3D> qf = PhysicsRayQueryParameters3D::create(Vector3(p.x, p.y + hgt, p.z), Vector3(p.x, p.y + hgt, p.z) + p_dir * 0.45f, 1);   // (Yasin: "make sure they trigger from really up close": his front 15 cm from it)
		qf->set_exclude(ex);
		const Dictionary hf = ss->intersect_ray(qf);
		if (!hf.is_empty() && ((Vector3)hf["normal"]).dot(p_dir) < -0.5f) { face = hf["position"]; has_face = true; break; }
	}
	if (!has_face) return false;
	const float to_face = Vector2(face.x - p.x, face.z - p.z).length();
	Vector3 probe; Dictionary h;
	for (float ahead : { 0.04f, 0.12f, 0.2f }) {   // (just past the face, nearest first: a fence's rail is a few cm thick)
		probe = p + p_dir * (to_face + ahead);
		Ref<PhysicsRayQueryParameters3D> q = PhysicsRayQueryParameters3D::create(probe + Vector3(0, (base - p.y) + 2.7f, 0), probe + Vector3(0, (base - p.y) + 0.05f, 0), 1);
		q->set_exclude(ex);
		h = ss->intersect_ray(q);
		if (!h.is_empty()) break;
	}
	if (h.is_empty()) return false;
	const Vector3 top = h["position"], n = h["normal"];
	if (n.y < 0.7f) return false;   // (not a top one can stand on)
	const float rise = top.y - base;
	{   // a fence: ground beyond it lower than its top (a ray down just past it), the top thin enough to go over
		Ref<PhysicsRayQueryParameters3D> qb = PhysicsRayQueryParameters3D::create(Vector3(p.x, top.y + 0.25f, p.z) + p_dir * (to_face + 0.75f), Vector3(p.x, base - 0.6f, p.z) + p_dir * (to_face + 0.75f), 1);
		qb->set_exclude(ex);
		const Dictionary hb = ss->intersect_ray(qb);
		const bool beyond_low = !hb.is_empty() && ((Vector3)hb["position"]).y < top.y - 0.25f;
		// (Yasin: "lose those jumps at high vault and high climb and trigger them much earlier"): walking or jumping alike
		const bool fence_h = rise > 0.24f && rise <= 1.4f;
		if (beyond_low && fence_h) {
			const Vector3 land = (Vector3)hb["position"] + Vector3(0, 0.03f, 0);
			Transform3D tl = get_global_transform(); tl.origin = land;
			if (!test_move(tl, Vector3(0, 0.05f, 0))) {   // (room to land)
				const float ey = top.y - 0.03f;
				Ref<PhysicsRayQueryParameters3D> q2 = PhysicsRayQueryParameters3D::create(Vector3(p.x, ey, p.z) - p_dir * 0.3f, Vector3(p.x, ey, p.z) + p_dir * 1.2f, 1);
				q2->set_exclude(ex);
				const Dictionary hw = ss->intersect_ray(q2);
				const Vector3 face = hw.is_empty() ? Vector3(probe.x - p_dir.x * 0.2f, ey, probe.z - p_dir.z * 0.2f) : (Vector3)hw["position"];
				edge_at = Vector3(face.x, top.y, face.z); edge_out = -p_dir; edge_side = Vector3(0, 1, 0).cross(p_dir).normalized();
				pel_rest = pelvis_world() - p; if (pel_rest.y < 0.5f || pel_rest.y > 1.3f) pel_rest = Vector3(0, 0.95f, 0);
				pel_rest.x = 0.0f; pel_rest.z = 0.0f; pel_rest_set = true;
				clip_off = Vector3(); fig_drawn_at = p;
				climb = 4; climb_t = 0.0f; hang_set = true;
				climb_len = rise > 0.6f ? 1.05f : 0.9f;
				climb_from = p;
				// over the rail: his hips 25 cm over its top, a little past it; then down onto the far side
				vault_over = Vector3(edge_at.x, top.y + 0.25f - pel_rest.y, edge_at.z) + p_dir * 0.12f;
				climb_to = land;
				vaults++;
				return true;
			}
		}
	}
	const bool step = !airborne && rise > 0.08f && rise <= 0.24f;
	const bool low = !airborne && rise > 0.24f && rise <= 0.5f;
	const bool high = rise > 0.5f && rise <= 2.5f;   // (no jump needed: walking into it he climbs it)
	if (!step && !low && !high) return false;
	// (his place up there: far enough in from the edge that his whole body stands on the top, 45 cm past where its top was found)
	const Vector3 dest = Vector3(p.x, top.y + 0.002f, p.z) + p_dir * (to_face + 0.45f);   // (on the top itself: no snap down after)
	Transform3D td = get_global_transform(); td.origin = dest;
	if (test_move(td, Vector3(0, 0.05f, 0))) return false;   // (no room to stand up there)
	{   // the edge: a ray level with the top, from him toward the wall, meets its face; the hands hold there
		const float ey = top.y - 0.04f;
		Ref<PhysicsRayQueryParameters3D> q2 = PhysicsRayQueryParameters3D::create(Vector3(p.x, ey, p.z) - p_dir * 0.3f, Vector3(p.x, ey, p.z) + p_dir * 1.2f, 1);
		q2->set_exclude(ex);
		const Dictionary hw = ss->intersect_ray(q2);
		const Vector3 face = hw.is_empty() ? Vector3(probe.x - p_dir.x * 0.2f, ey, probe.z - p_dir.z * 0.2f) : (Vector3)hw["position"];
		edge_at = Vector3(face.x, top.y, face.z);
		edge_out = -p_dir;
		edge_side = Vector3(0, 1, 0).cross(p_dir).normalized();
	}
	// the hips' place over his feet as he stands now, before the climb's clip moves them (measured; a guess of 0.95 m
	// only when the figure gives none: the first climb used to take the guess and jumped 10 cm)
	pel_rest = pelvis_world() - p; clip_off = Vector3(); fig_drawn_at = p;
	if (pel_rest.y < 0.5f || pel_rest.y > 1.3f) pel_rest = Vector3(0, 0.95f, 0);
	pel_rest.x = 0.0f; pel_rest.z = 0.0f;
	pel_rest_set = true;
	climb = step ? 3 : (low ? 1 : 2); climb_t = 0.0f; hang_set = false;
	climb_len = step ? 0.5f : (low ? 0.85f : 1.7f);
	climb_from = p; climb_to = dest;
	if (step) steps_up++; else if (low) climbs_low++; else climbs_high++;
	return true;
}

bool CityPlayer::cur_clip_is(const StringName &p_clip) const { return fig && StringName(fig->current_clip()) == p_clip; }

Vector3 CityPlayer::pelvis_world() const {
	Skeleton3D *sk = fig ? fig->skeleton() : nullptr;
	if (!sk) return get_global_position() + Vector3(0, 0.95f, 0);
	const int b = sk->find_bone("Bip01_Pelvis");
	return b >= 0 ? sk->get_global_transform().xform(sk->get_bone_global_pose(b).origin) : get_global_position() + Vector3(0, 0.95f, 0);
}

// (traces) this frame: the node, where the figure was placed, its pelvis, the clip and its time
Dictionary CityPlayer::get_frame_log() const {
	Dictionary d;
	d["node"] = get_global_position(); d["fig_at"] = fig ? fig->get_global_position() : Vector3(); d["pelvis"] = pelvis_world();
	d["clip"] = get_clip(); d["climb"] = climb; d["u"] = climb ? climb_t / climb_len : -1.0f; d["settle"] = settle_t; d["clip_off"] = clip_off;
	return d;
}

Vector3 CityPlayer::get_grip_now() const { return Vector3(climb ? climb_t / climb_len : -1.0f, grip ? grip->miss[0] : 0.0f, grip ? grip->miss[1] : 0.0f); }

float CityPlayer::get_hips_drop() const { return plant ? plant->hips_drop : 0.0f; }

void CityPlayer::grip_update() {
	Skeleton3D *sk = fig ? fig->skeleton() : nullptr;
	if (!sk) return;
	if (!grip) { grip = memnew(HandGrip); sk->add_child(grip); }
	grip->set_active(grip_w > 0.001f);
	grip->set_influence(grip_w);
	if (grip_w <= 0.001f) return;
	// the hands 22 cm either side of the middle of the edge, on the edge itself
	grip->one_hand = climb == 4;
	grip->grip[0] = edge_at + edge_side * (climb == 4 ? 0.12f : 0.22f);
	grip->grip[1] = edge_at - edge_side * 0.22f;
	grip->out = edge_out; grip->side = edge_side;
	if (grip_w > 0.95f && (grip->held[0] || grip->held[1])) {
		grip_on_s += (float)get_physics_process_delta_time();
		grip_miss_most = std::max(grip_miss_most, std::max(grip->miss[0], grip->miss[1]));
		grip_tip_most = std::max(grip_tip_most, std::max(std::fabs(grip->tip_dy[0]), std::fabs(grip->tip_dy[1])));
	}
}

Array CityPlayer::get_hand_points() const {
	Array a;
	Skeleton3D *sk = fig ? fig->skeleton() : nullptr;
	if (!sk) return a;
	for (const char *n : { "Bip01_L_Hand", "Bip01_R_Hand", "Bip01_L_Finger2", "Bip01_R_Finger2", "Bip01_L_Finger22", "Bip01_R_Finger22" }) {
		const int b = sk->find_bone(n);
		a.push_back(b >= 0 ? sk->get_global_transform().xform(sk->get_bone_global_pose(b).origin) : Vector3());
	}
	return a;
}

void CityPlayer::set_riding(bool p_on) {
	frozen = p_on;
	set_visible(!p_on);
	set_collision_layer(p_on ? 0 : 2);
	set_collision_mask(p_on ? 0 : (1 | 16 | 32));
	set_velocity(Vector3());
}

void CityPlayer::stand_at(const Vector3 &p_at, double p_yaw) {
	set_global_position(p_at);
	yaw = (float)p_yaw;
	cam_yaw = (float)p_yaw + 3.14159265f;   // (his view behind him)
	set_velocity(Vector3());
	if (fig) fig->drive(Transform3D(Basis(Vector3(0, 1, 0), yaw), p_at), StringName("ual/Idle_Loop"), 1.0, -1.0);
}

String CityPlayer::get_clip() const { return fig ? String(fig->current_clip()) : String(); }

void CityPlayer::_process(double p_delta) {
	if (!cam) return;
	const float dt = (float)std::min(p_delta, 0.1);
	const Vector3 head = get_global_position() + Vector3(0, 1.55f, 0);
	const Vector3 back(std::sin(cam_yaw) * std::cos(cam_pitch), -std::sin(cam_pitch), std::cos(cam_yaw) * std::cos(cam_pitch));
	const Vector3 want = head + back * cam_dist;
	if (!cam_set) { cam_pos = want; cam_set = true; }
	cam_pos += (want - cam_pos) * (1.0f - std::exp(-dt * 14.0f));
	cam->set_global_transform(Transform3D(Basis(), cam_pos).looking_at(head, Vector3(0, 1, 0)));
}

void CityPlayer::_bind_methods() {
	ClassDB::bind_method(D_METHOD("set_move", "direction", "run"), &CityPlayer::set_move);
	ClassDB::bind_method(D_METHOD("get_speed"), &CityPlayer::get_speed);
	ClassDB::bind_method(D_METHOD("set_frozen", "on"), &CityPlayer::set_frozen);
	ClassDB::bind_method(D_METHOD("is_frozen"), &CityPlayer::is_frozen);
	ClassDB::bind_method(D_METHOD("knock", "velocity"), &CityPlayer::knock);
	ClassDB::bind_method(D_METHOD("set_water_y", "y"), &CityPlayer::set_water_y);
	ClassDB::bind_method(D_METHOD("get_water_y"), &CityPlayer::get_water_y);
	ClassDB::bind_method(D_METHOD("is_swimming"), &CityPlayer::is_swimming);
	ClassDB::bind_method(D_METHOD("get_clip"), &CityPlayer::get_clip);
	ClassDB::bind_method(D_METHOD("set_crouch", "on"), &CityPlayer::set_crouch);
	ClassDB::bind_method(D_METHOD("get_crouch"), &CityPlayer::get_crouch);
	ClassDB::bind_method(D_METHOD("jump"), &CityPlayer::jump);
	ClassDB::bind_method(D_METHOD("get_view"), &CityPlayer::get_view);
	ClassDB::bind_method(D_METHOD("set_riding", "on"), &CityPlayer::set_riding);
	ClassDB::bind_method(D_METHOD("set_view", "yaw", "cam_yaw", "cam_pitch"), &CityPlayer::set_view);
	ClassDB::bind_method(D_METHOD("request_combat"), &CityPlayer::request_combat);
	ClassDB::bind_method(D_METHOD("punch"), &CityPlayer::punch);
	ClassDB::bind_method(D_METHOD("get_combat"), &CityPlayer::get_combat);
	ClassDB::bind_method(D_METHOD("get_punches"), &CityPlayer::get_punches);
	ClassDB::bind_method(D_METHOD("get_steps_up"), &CityPlayer::get_steps_up);
	ClassDB::bind_method(D_METHOD("get_climbs_low"), &CityPlayer::get_climbs_low);
	ClassDB::bind_method(D_METHOD("get_climbs_high"), &CityPlayer::get_climbs_high);
	ClassDB::bind_method(D_METHOD("get_vaults"), &CityPlayer::get_vaults);
	ClassDB::bind_method(D_METHOD("get_grip_now"), &CityPlayer::get_grip_now);
	ClassDB::bind_method(D_METHOD("get_frame_log"), &CityPlayer::get_frame_log);
	ClassDB::bind_method(D_METHOD("is_climbing"), &CityPlayer::is_climbing);
	ClassDB::bind_method(D_METHOD("get_grip_weight"), &CityPlayer::get_grip_weight);
	ClassDB::bind_method(D_METHOD("get_hips_drop"), &CityPlayer::get_hips_drop);
	ClassDB::bind_method(D_METHOD("get_pelvis"), &CityPlayer::get_pelvis);
	ClassDB::bind_method(D_METHOD("get_grip_miss_most"), &CityPlayer::get_grip_miss_most);
	ClassDB::bind_method(D_METHOD("get_grip_seconds"), &CityPlayer::get_grip_seconds);
	ClassDB::bind_method(D_METHOD("get_grip_tip_most"), &CityPlayer::get_grip_tip_most);
	ClassDB::bind_method(D_METHOD("get_edge_at"), &CityPlayer::get_edge_at);
	ClassDB::bind_method(D_METHOD("get_hand_points"), &CityPlayer::get_hand_points);
	ClassDB::bind_method(D_METHOD("get_hits_taken"), &CityPlayer::get_hits_taken);
	ClassDB::bind_method(D_METHOD("set_no_touch", "index", "rect"), &CityPlayer::set_no_touch);
	ClassDB::bind_method(D_METHOD("get_touch_move"), &CityPlayer::get_touch_move);
	ADD_PROPERTY(PropertyInfo(Variant::FLOAT, "water_y"), "set_water_y", "get_water_y");
	ClassDB::bind_method(D_METHOD("set_body_id", "id"), &CityPlayer::set_body_id);
	ClassDB::bind_method(D_METHOD("get_body_id"), &CityPlayer::get_body_id);
	ClassDB::bind_method(D_METHOD("set_capture_mouse", "on"), &CityPlayer::set_capture_mouse);
	ClassDB::bind_method(D_METHOD("get_capture_mouse"), &CityPlayer::get_capture_mouse);
	ClassDB::bind_method(D_METHOD("set_walk_speed", "speed"), &CityPlayer::set_walk_speed);
	ClassDB::bind_method(D_METHOD("get_walk_speed"), &CityPlayer::get_walk_speed);
	ClassDB::bind_method(D_METHOD("set_run_speed", "speed"), &CityPlayer::set_run_speed);
	ClassDB::bind_method(D_METHOD("get_run_speed"), &CityPlayer::get_run_speed);
	ADD_PROPERTY(PropertyInfo(Variant::STRING, "body_id"), "set_body_id", "get_body_id");
	ADD_PROPERTY(PropertyInfo(Variant::BOOL, "capture_mouse"), "set_capture_mouse", "get_capture_mouse");
	ADD_PROPERTY(PropertyInfo(Variant::FLOAT, "walk_speed"), "set_walk_speed", "get_walk_speed");
	ADD_PROPERTY(PropertyInfo(Variant::FLOAT, "run_speed"), "set_run_speed", "get_run_speed");
	ADD_SIGNAL(MethodInfo("interact"));
}

} // namespace godot
