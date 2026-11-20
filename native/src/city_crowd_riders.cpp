// THE TRAFFIC'S CYCLISTS UP CLOSE (Yasin, 20 Nov: "new bikes and biking animations for npcs arent in the game"). Far
// away a cyclist is a far figure in one of four riding poses on the traffic's batch of cruisers; within 22 m of the
// camera (kept to 27 m) the nearest three become real riders: a CityPed in the riding clip with BikeReach (the player's
// own: feet on the pedals going round, hands on the grips, the back over the bars) on a cruiser rig of its own, its crank,
// pedals and wheels turning with the way gone, in the far bicycle's paint. The far figure and the traffic's bicycle are
// not drawn for them. Same look as the far figure (the same person, clothes and colours).
#include "city_crowd.h"
#include "bike_look.h"
#include "city_bike.h"
#include "city_ped.h"
#include "city_traffic.h"

#include <godot_cpp/classes/resource_loader.hpp>

#include <algorithm>
#include <cmath>

namespace godot {

namespace {
const float TAKE_R = 22.0f, KEEP_R = 27.0f;
}

void CityCrowd::near_riders(const std::vector<float> &bk, const Vector3 &cam, CityTraffic *trf) {
	if (!bike_look::available()) return;
	const int STRIDE = CityTraffic::BIKE_STRIDE;
	if (rider_pool.empty()) {
		for (int k = 0; k < RIDERS_NEAR; k++) {
			NearRider nr;
			nr.paint = bike_look::material(true);
			nr.rig = bike_look::make_rig(nr.paint);
			if (!nr.rig) return;
			Node3D *holder = memnew(Node3D);   // (the riders' frame; the rig sits SHIFT forward inside it)
			holder->add_child(nr.rig);
			add_child(holder);
			nr.rig = holder;
			auto part = [&](const char *n) { return Object::cast_to<Node3D>(holder->find_child(n, true, false)); };
			nr.crank = part("crank"); nr.pedal[0] = part("pedal_l"); nr.pedal[1] = part("pedal_r");
			nr.wheel[0] = part("wheel_front"); nr.wheel[1] = part("wheel_rear");
			if (Node3D *ks = part("kickstand")) ks->set_visible(false);   // (riding: the stand is up; the model has none folded)
			if (nr.crank) nr.r_crank = nr.crank->get_transform();
			for (int s = 0; s < 2; s++) { if (nr.pedal[s]) nr.r_pedal[s] = nr.pedal[s]->get_transform(); if (nr.wheel[s]) nr.r_wheel[s] = nr.wheel[s]->get_transform(); }
			holder->set_visible(false);
			nr.ped = memnew(CityPed);
			nr.ped->set_body_id("M1");
			nr.ped->set_clip("ual/Driving_Loop");
			add_child(nr.ped);
			nr.ped->set_visible(false);
			nr.look = mat_near->duplicate();
			rider_pool.push_back(nr);
		}
	}
	// who is near: the nearest cyclists, a rider kept to KEEP_R, a new one taken within TAKE_R
	struct Cand { float d2; int k; int id; };
	std::vector<Cand> cand;
	for (size_t k = 0; k + STRIDE - 1 < bk.size(); k += STRIDE) {
		const float dx = bk[k] - cam.x, dy = bk[k + 1] - cam.y, dz = bk[k + 2] - cam.z;
		const float d2 = dx * dx + dy * dy + dz * dz;
		const int id = (int)bk[k + 6];
		bool held = false;
		for (const NearRider &nr : rider_pool) if (nr.id == id) held = true;
		if (d2 < (held ? KEEP_R * KEEP_R : TAKE_R * TAKE_R)) cand.push_back(Cand{ d2, (int)k, id });
	}
	std::sort(cand.begin(), cand.end(), [](const Cand &a, const Cand &b) { return a.d2 < b.d2; });
	if ((int)cand.size() > RIDERS_NEAR) cand.resize(RIDERS_NEAR);
	// let go of the ones no longer near (shown two frames more: the traffic hides its bicycle a frame late)
	for (NearRider &nr : rider_pool) {
		if (nr.id < 0) continue;
		bool still = false;
		for (const Cand &c : cand) if (c.id == nr.id) still = true;
		if (still) { nr.linger = 2; continue; }
		if (--nr.linger > 0) {   // (it may still be in the list beyond KEEP_R: keep posing it there)
			for (size_t k = 0; k + STRIDE - 1 < bk.size(); k += STRIDE) if ((int)bk[k + 6] == nr.id) cand.push_back(Cand{ 0.0f, (int)k, nr.id });
			continue;
		}
		nr.id = -1; nr.rig->set_visible(false); nr.ped->set_visible(false);
	}
	rider_ids.clear();
	for (const Cand &c : cand) {
		NearRider *nr = nullptr;
		for (NearRider &o : rider_pool) if (o.id == c.id) nr = &o;
		if (!nr) for (NearRider &o : rider_pool) if (o.id < 0) { nr = &o; break; }
		if (!nr) continue;
		const float *b = bk.data() + c.k;
		if (nr->id != c.id) {   // a new rider: the same person as the far figure (the far loop's hash), on a bicycle in its paint
			nr->id = c.id; nr->linger = 2; nr->seat = 0.0f;
			const uint32_t h = (uint32_t)b[6] * 2654435761u ^ 0x5bd1e995u;
			const int female = (h >> 3) % 3u == 0u ? 1 : 0;
			const std::vector<int> *pool = &pool_casual[female];
			if (pool->empty()) pool = &pool_casual[0];
			if (pool->empty()) { nr->id = -1; continue; }
			const int body = (*pool)[(h >> 4) % (uint32_t)pool->size()];
			nr->look->set_shader_parameter("person", Vector4((float)((h >> 8) % 24u), (float)((h >> 13) % 16u), (float)((h >> 17) % 8u) + 8.0f * (float)((h >> 20) % 4u), (float)((h >> 22) % 997u) / 1000.0f));
			nr->ped->become(bodies[body].id, bodies[body].near_mesh, nr->look, false);
			const float *col = CityTraffic::bike_paint((int)b[7]);
			nr->paint->set_shader_parameter("paint_u", Vector3(col[0], col[1], col[2]));
			if (!nr->reach && nr->ped->skeleton()) { nr->reach = memnew(BikeReach); nr->ped->skeleton()->add_child(nr->reach); }
			nr->rig->set_visible(true); nr->ped->set_visible(true);
		}
		rider_ids.push_back(c.id);
		// the bicycle where the traffic has it, leaning with it; its parts turning with the way gone
		const Transform3D bt(Basis(Vector3(0, 1, 0), b[3]) * Basis(Vector3(0, 0, 1), b[4]), Vector3(b[0], b[1], b[2]));
		nr->rig->set_global_transform(bt);
		const float crank = b[5] * 6.2831853f, wheel = std::fmod(b[5] * 5.2f / bike_look::WR, 6.2831853f);
		const float th = crank + 1.5707963f;   // (as CityBike::pose_parts: the model's crank rests a quarter turn on)
		if (nr->crank) nr->crank->set_transform(Transform3D(nr->r_crank.basis * Basis(Vector3(1, 0, 0), th), nr->r_crank.origin));
		for (int s = 0; s < 2; s++) {
			if (nr->pedal[s]) nr->pedal[s]->set_transform(Transform3D(nr->r_pedal[s].basis * Basis(Vector3(1, 0, 0), -th), nr->r_pedal[s].origin));
			if (nr->wheel[s]) nr->wheel[s]->set_transform(Transform3D(nr->r_wheel[s].basis * Basis(Vector3(1, 0, 0), wheel), nr->r_wheel[s].origin));
		}
		// the rider: the riding clip on the saddle, his feet and hands reached (as the player's: CityBike::place_rider)
		// (the saddle set to his legs: a foot short of the lowest pedal brings him down, as far as it lacks; skeleton cm)
		if (nr->reach) nr->seat = std::min(0.10f, nr->seat + std::max(0.0f, std::max(nr->reach->miss_foot[0], nr->reach->miss_foot[1]) * 0.01f - 0.005f) * 0.5f);
		nr->ped->drive(Transform3D(bt.basis, bt.xform(bike_look::rider_at() - Vector3(0.0f, nr->seat, 0.0f))), StringName("ual/Driving_Loop"), 1.0, -1.0);
		if (nr->reach) {
			for (int s = 0; s < 2; s++) {
				const float ang = crank + (s ? 3.14159265f : 0.0f);
				const float sx = s == 0 ? bike_look::PEDAL_X : -bike_look::PEDAL_X;
				nr->reach->foot_l[s] = Vector3(sx, bike_look::BB_Y + bike_look::CRANK_R * std::cos(ang) + 0.08f, bike_look::CRANK_R * std::sin(ang));
				nr->reach->hand_l[s] = Vector3(s == 0 ? bike_look::GRIP_X - 0.01f : -(bike_look::GRIP_X - 0.01f), bike_look::GRIP_Y + 0.11f, bike_look::GRIP_Z - 0.05f);
			}
			nr->reach->frame_id = nr->rig->get_instance_id();
			nr->reach->lean = 0.12f;
		}
	}
	riders_near = (int)rider_ids.size();
	riders_miss = 0.0f; riders_miss_hand = false; riders_limbs = String();   // (the tests) how far a near rider's foot or hand ended from its pedal or grip, last frame, m
	for (const NearRider &o : rider_pool) if (o.id >= 0 && o.reach) for (int s = 0; s < 2; s++) { riders_miss = std::max(riders_miss, std::max(o.reach->miss_foot[s], o.reach->miss_hand[s]) * 0.01f); if (o.reach->miss_hand[s] > o.reach->miss_foot[s]) riders_miss_hand = true; }
	for (const NearRider &o : rider_pool) if (o.id >= 0 && o.reach) riders_limbs += String(o.ped->get_body_id()) + String(" feet ") + String::num(o.reach->miss_foot[0] * 0.01f, 3) + String("/") + String::num(o.reach->miss_foot[1] * 0.01f, 3) + String(" hands ") + String::num(o.reach->miss_hand[0] * 0.01f, 3) + String("/") + String::num(o.reach->miss_hand[1] * 0.01f, 3) + String(" lean ") + String::num(o.reach->lean_used, 2) + String(" seat down ") + String::num(o.seat, 3) + String("; ");
	if (trf) trf->hide_bikes(rider_ids);
}

} // namespace godot
