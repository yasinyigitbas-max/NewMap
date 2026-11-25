#include "loco.h"

#include <godot_cpp/variant/utility_functions.hpp>

#include <algorithm>
#include <cmath>

using namespace godot;

namespace lab {

// ---- tuning (each value with its study section) ----
static const float WALK_ACCEL = 2.5f;   // m/s^2 inside the loop (2.3: walk speed in 2-3 steps)
static const float RUN_ACCEL = 4.5f;    // run speed in 3-5 steps (2.3)
static const float DECEL = 5.0f;        // loop slowing (2.4)
static const float TURN_WALK = 6.0f;    // rad/s: small turns inside the step (2.5); GTA-tight (8.3)
static const float TURN_RUN = 3.2f;     // rad/s at 4.6 m/s: ~3 m radius, lean ~35 deg max (2.5)
static const float PIVOT_ANGLE = 2.36f; // 135 deg: above it a run/walk does a pivot (2.5)
static const float START_STEER = 7.0f;  // rad/s: start orientation warp (spin on the stance foot, 2.5)
static const float RUN_GAIT = 2.3f;     // above this desired speed a start / stop / pivot uses the run clips (2.2)

float Locomotion::wrap_pi(float a) {
	a = std::fmod(a + (float)Math_PI, (float)Math_TAU);
	if (a < 0) a += (float)Math_TAU;
	return a - (float)Math_PI;
}

static const Clip *get2(const ClipLibrary *lib, const char *n) {
	const Clip *c = lib->get(n);
	if (!c) UtilityFunctions::push_warning("Locomotion: clip missing: ", n);
	return c;
}

bool Locomotion::init(const ClipLibrary *l) {
	lib = l;
	B = lib->bone_count();
	idle = get2(lib, "idle");
	const char *ln[4] = {"walk", "jog", "run", "run_fast"};
	loops.count = 0;
	for (int i = 0; i < 4; i++) {
		const Clip *c = get2(lib, ln[i]);
		if (c) loops.clip[loops.count++] = c;
	}
	auto pair = [&](const Clip **dst, const char *n) {
		dst[0] = get2(lib, n);
		dst[1] = get2(lib, (std::string(n) + "_M").c_str());
	};
	pair(walk_start, "walk_start");
	pair(walk_stop, "walk_stop");
	pair(run_start, "run_start");
	pair(run_stop, "run_stop");
	pair(run_pivot, "run_pivot");
	pair(walk_pivot, "walk_pivot");
	pair(run_start_turn, "run_start_turn");
	if (!idle || loops.count == 0) return false;
	pose.resize(B);
	pose_old.resize(B);
	src.resize(B);
	src_old.resize(B);
	inert.reset(B);
	idle->sample(0, B, pose);
	pose_old = pose;
	mode = Mode::IDLE;
	clip_name = "idle";
	return true;
}

// ---- loops: phase-synced blend by speed (study 4.1, 6.5) ----
void Locomotion::loop_speeds(float v, int &i0, int &i1, float &w) const {
	i0 = 0;
	i1 = 0;
	w = 0;
	if (v <= loops.clip[0]->speed) return;
	for (int i = 0; i + 1 < loops.count; i++) {
		const float a = loops.clip[i]->speed, b = loops.clip[i + 1]->speed;
		if (v <= b) {
			i0 = i;
			i1 = i + 1;
			w = (v - a) / (b - a);
			return;
		}
	}
	i0 = i1 = loops.count - 1;
}

float Locomotion::loop_cycle_time(float v) const {
	int i0, i1;
	float w;
	loop_speeds(v, i0, i1, w);
	return loops.clip[i0]->cycle_time + (loops.clip[i1]->cycle_time - loops.clip[i0]->cycle_time) * w;
}

void Locomotion::loop_pose(float ph, float v, Pose &out, int &dominant) {
	int i0, i1;
	float w;
	loop_speeds(v, i0, i1, w);
	const Clip *a = loops.clip[i0];
	const Clip *b = loops.clip[i1];
	a->sample(a->loop_frame(ph) / a->fps, B, tmp_a);
	if (i0 == i1 || w <= 0.001f) {
		out = tmp_a;
		dominant = i0;
		return;
	}
	b->sample(b->loop_frame(ph) / b->fps, B, tmp_b);
	pose_blend(tmp_a, tmp_b, w, out);
	dominant = w < 0.5f ? i0 : i1;
}

float Locomotion::time_to_strike(int foot) const {
	// left strike at phase 0, right at 0.5
	const float target = foot == 0 ? 1.0f : 0.5f;
	float d = target - phase;
	d -= std::floor(d);
	const float ct = loop_cycle_time(speed) / std::fmax(play_rate, 0.1f);
	return d * ct;
}

// ---- source sampling for the current mode (used for inertialization at a switch) ----
void Locomotion::sample_source(float dt_back) {
	int dom;
	switch (mode) {
		case Mode::IDLE:
			idle->sample(idle_t, B, src);
			idle->sample(std::fmax(idle_t - dt_back, 0.0f), B, src_old);
			break;
		case Mode::LOOP: {
			loop_pose(phase, speed, src, dom);
			const float back = dt_back * play_rate / loop_cycle_time(speed);
			loop_pose(phase - back, speed, src_old, dom);
			break;
		}
		default:
			cur->sample(t, B, src);
			cur->sample(std::fmax(t - dt_back * rate, 0.0f), B, src_old);
			break;
	}
}

void Locomotion::switch_to(Mode m, float dt) {
	mode = m;
	sample_source(dt);
	// the new source's pose relative to the capsule: the hips are expressed in each clip's root frame, so the offset
	// between root frames is part of what the inertializer carries away
	inert.transition(pose, pose_old, src, src_old, dt);
	switches++;
}

// ---- entering modes ----
void Locomotion::enter_start(float dt, float ang, float want_speed) {
	const bool run = want_speed > RUN_GAIT;
	const Clip *c = nullptr;
	if (run && std::fabs(ang) > 1.05f && run_start_turn[0]) {
		c = run_start_turn[ang < 0 ? 0 : 1]; // clip 0 turns right
	} else if (run && run_start[0]) {
		c = run_start[(ang >= 0) == (run_start[0]->turn >= 0) ? 0 : 1];
	} else {
		c = walk_start[ang > 0 ? 1 : 0]; // walk_start steps right first; turning left steps left first
	}
	if (!c) return;
	cur = c;
	t = std::fmax(c->move_a, 0.0f) / c->fps;
	rate = 1;
	align = yaw - c->root_at(t).yaw;
	motion_scale = 1;
	clip_name = c->name.c_str();
	switch_to(Mode::START, dt);
}

void Locomotion::enter_stop(float dt) {
	const bool run = speed > RUN_GAIT;
	const Clip **pairc = run ? run_stop : walk_stop;
	if (!pairc[0] || !pairc[1]) {
		switch_to(Mode::IDLE, dt);
		return;
	}
	// stop on whichever foot is next (study 2.4): pick the clip whose first planted foot is that foot, and time it so
	// the strike lands when ours would
	float best = 1e9f;
	const Clip *pick = nullptr;
	float pick_rate = 1;
	for (int k = 0; k < 2; k++) {
		const Clip *c = pairc[k];
		if (c->entry_foot < 0) continue;
		const float tt = time_to_strike(c->entry_foot);
		const float pre = c->entry_f / c->fps;
		float r = tt > 0.02f ? pre / tt : 2.0f;
		r = std::clamp(r, 0.7f, 1.4f);
		const float cost = std::fabs(std::log(r)) + tt * 0.5f;
		if (cost < best) {
			best = cost;
			pick = c;
			pick_rate = r;
		}
	}
	if (!pick) pick = pairc[0];
	cur = pick;
	t = 0;
	rate = pick_rate;
	// root speed of the clip near its entry, to scale its travel to our speed (stride warping, study 4.1)
	const float te = std::fmax(pick->entry_f / pick->fps, 0.05f);
	const RootSample r0 = pick->root_at(te - 0.05f), r1 = pick->root_at(te);
	const float vclip = std::hypot(r1.x - r0.x, r1.z - r0.z) / 0.05f;
	motion_scale = vclip > 0.2f ? std::clamp(speed / vclip, 0.6f, 1.4f) : 1.0f;
	align = yaw - pick->root_at(t).yaw;
	clip_name = pick->name.c_str();
	switch_to(Mode::STOP, dt);
}

void Locomotion::enter_pivot(float dt, float ang) {
	const bool run = speed > RUN_GAIT;
	const Clip **pc = run ? run_pivot : walk_pivot;
	if (!pc[0] || !pc[1]) return;
	// the clip that turns the asked way (clip 0 turns right = negative yaw)
	const Clip *c = pc[(ang < 0) == (pc[0]->turn < 0) ? 0 : 1];
	cur = c;
	float tt = c->entry_foot >= 0 ? time_to_strike(c->entry_foot) : 0.0f;
	const float pre = std::fmax(c->entry_f, 0.0f) / c->fps;
	if (mode == Mode::IDLE) {
		t = pre;
		rate = 1;
	} else {
		t = 0;
		rate = tt > 0.02f ? std::clamp(pre / tt, 0.7f, 1.4f) : 1.0f;
	}
	motion_scale = 1;
	align = yaw - c->root_at(t).yaw;
	clip_name = c->name.c_str();
	switch_to(Mode::PIVOT, dt);
}

// ---- root-motion modes: the capsule follows the clip's root, steered toward the stick (orientation warping) ----
void Locomotion::root_motion_step(float dt, float steer_rate, float target_yaw) {
	const float t0 = t;
	t = std::fmin(t + dt * rate, cur->length());
	const RootSample a = cur->root_at(t0), b = cur->root_at(t);
	if (steer_rate > 0) {
		// where the clip will face at its end, if align stays: steer align so that equals the target
		const float end_yaw = align + cur->root_at(cur->length()).yaw;
		const float err = wrap_pi(target_yaw - end_yaw);
		const float step = std::clamp(err, -steer_rate * dt, steer_rate * dt);
		align += step;
	}
	const float dx = b.x - a.x, dz = b.z - a.z;
	const float c = std::cos(align), s = std::sin(align);
	// rotate clip-space (x,z) by align around Y: x' = x cos + z sin, z' = -x sin + z cos
	const float wx = dx * c + dz * s;
	const float wz = -dx * s + dz * c;
	velocity = Vector2(wx, wz) * (motion_scale / dt);
	yaw = wrap_pi(align + b.yaw);
	speed = velocity.length();
}

void Locomotion::set_actual_velocity(Vector2 v) {
	if (mode == Mode::LOOP) {
		// blocked by a wall: the loop slows with the capsule
		const float s = v.length();
		if (s < speed - 0.05f) speed = s;
	}
}

void Locomotion::tick(float dt, Vector2 dir, float want) {
	pose_old = pose;
	prev_vel = velocity;
	prev_yaw = yaw;
	has_input = want > 0.01f && dir.length_squared() > 0.25f;
	if (has_input) desired_yaw = std::atan2(dir.x, dir.y);
	const float ang = has_input ? wrap_pi(desired_yaw - yaw) : 0.0f;

	switch (mode) {
		case Mode::IDLE: {
			idle_t += dt;
			velocity = Vector2();
			speed = 0;
			if (has_input) {
				if (std::fabs(ang) > 2.1f && walk_pivot[0] && want <= RUN_GAIT) enter_pivot(dt, ang);
				else enter_start(dt, ang, want);
			}
			break;
		}
		case Mode::START: {
			if (!has_input && t > cur->move_a / cur->fps + 0.25f) {
				// released during the start: stop on the next foot (no lock, brief: aborts allowed)
				enter_stop(dt);
				break;
			}
			if (!has_input && t <= cur->move_a / cur->fps + 0.25f) {
				switch_to(Mode::IDLE, dt);
				break;
			}
			root_motion_step(dt, START_STEER, desired_yaw);
			if (t >= cur->exit_f / cur->fps || t >= cur->length()) {
				phase = cur->exit_phase;
				speed = std::fmax(speed, loops.clip[0]->speed * 0.8f);
				const float s = speed;
				velocity = Vector2(std::sin(yaw), std::cos(yaw)) * s;
				clip_name = "loop";
				switch_to(Mode::LOOP, dt);
			}
			break;
		}
		case Mode::LOOP: {
			if (!has_input) {
				enter_stop(dt);
				break;
			}
			if (std::fabs(ang) > PIVOT_ANGLE && speed > 1.0f) {
				enter_pivot(dt, ang);
				break;
			}
			// speed toward the stick
			const float acc = want > RUN_GAIT ? RUN_ACCEL : WALK_ACCEL;
			if (speed < want) speed = std::fmin(want, speed + acc * dt);
			else speed = std::fmax(want, speed - DECEL * dt);
			// the 1.8-2.2 m/s band is crossed, never held (study 2.2)
			if (want > 2.2f && speed > 1.8f && speed < 2.2f) speed = std::fmin(2.2f, speed + acc * dt);
			// direction: turn inside the steps, rate falls with speed
			const float tr = TURN_WALK + (TURN_RUN - TURN_WALK) * std::clamp((speed - 1.5f) / 3.0f, 0.0f, 1.0f);
			const float step = std::clamp(ang, -tr * dt, tr * dt);
			yaw = wrap_pi(yaw + step);
			velocity = Vector2(std::sin(yaw), std::cos(yaw)) * speed;
			break;
		}
		case Mode::STOP: {
			if (has_input) {
				if (t < cur->still_f / cur->fps) {
					// back into the loop on the foot that is down (no input lock, brief)
					const bool l = cur->contact_at(0, t), r = cur->contact_at(1, t);
					phase = (l && !r) ? 0.15f : (r && !l) ? 0.65f : 0.0f;
					speed = std::fmax(speed, 0.8f);
					clip_name = "loop";
					switch_to(Mode::LOOP, dt);
				} else {
					idle_t = 0;
					clip_name = "idle";
					switch_to(Mode::IDLE, dt);
				}
				break;
			}
			root_motion_step(dt, 0.0f, yaw);
			if (t >= cur->still_f / cur->fps + 0.15f || t >= cur->length()) {
				velocity = Vector2();
				speed = 0;
				idle_t = 0;
				clip_name = "idle";
				switch_to(Mode::IDLE, dt);
			}
			break;
		}
		case Mode::PIVOT: {
			root_motion_step(dt, START_STEER * 0.6f, has_input ? desired_yaw : yaw);
			if (t >= cur->exit_f / cur->fps || t >= cur->length()) {
				if (!has_input) {
					enter_stop(dt);
					break;
				}
				phase = cur->exit_phase;
				speed = std::fmax(speed, 1.0f);
				velocity = Vector2(std::sin(yaw), std::cos(yaw)) * speed;
				clip_name = "loop";
				switch_to(Mode::LOOP, dt);
			}
			break;
		}
	}

	// ---- produce the source pose of the (possibly new) mode, advance its clock ----
	int dom = 0;
	switch (mode) {
		case Mode::IDLE:
			idle->sample(idle_t, B, src);
			contact[0] = contact[1] = true;
			stride_scale = 1;
			play_rate = 1;
			break;
		case Mode::LOOP: {
			int i0, i1;
			float w;
			loop_speeds(speed, i0, i1, w);
			const float vb = loops.clip[i0]->speed + (loops.clip[i1]->speed - loops.clip[i0]->speed) * w;
			// playback rate within +-20 %, the rest by stride length (study 4.1)
			play_rate = std::clamp(speed / std::fmax(vb, 0.1f), 0.8f, 1.2f);
			stride_scale = speed / std::fmax(vb * play_rate, 0.1f);
			phase += dt * play_rate / loop_cycle_time(speed);
			phase -= std::floor(phase);
			loop_pose(phase, speed, src, dom);
			const Clip *dc = loops.clip[dom];
			const float f = dc->loop_frame(phase);
			contact[0] = dc->contact_at_frame(0, f);
			contact[1] = dc->contact_at_frame(1, f);
			break;
		}
		default:
			cur->sample(t, B, src);
			contact[0] = cur->contact_at(0, t);
			contact[1] = cur->contact_at(1, t);
			stride_scale = motion_scale;
			play_rate = rate;
			clip_time = t;
			break;
	}
	inert.step(dt);
	pose = src;
	inert.apply(pose);

	// accelerations for the lean layer
	const Vector2 fwd(std::sin(yaw), std::cos(yaw));
	const Vector2 side(fwd.y, -fwd.x);
	const Vector2 a = (velocity - prev_vel) / dt;
	accel_long = a.dot(fwd);
	const float yaw_rate = wrap_pi(yaw - prev_yaw) / dt;
	accel_lat = velocity.length() * yaw_rate; // centripetal, positive = turning left (study 2.5)
	(void)side;
}

} // namespace lab
