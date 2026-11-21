// The walking crowd: street life (a phone call, a shop window, people who know each other, a coin for a beggar, shelter
// from the rain, night workers), danger (duck, run, stare; out of a car's way), and the hooks the rest of the game
// uses. See ped_crowd.h.
#include "ped_crowd.h"

#include "ped_inl.h"

namespace pc {

// What a lone walker (or a leader) does of his own accord on a pavement. May start a pause (state ST_PAUSE) or send
// him off to a shop's front (rain).
void Crowd::life_roll(int i, float h) {
	const Seg &S = segs[seg[i]];
	// a coin for a beggar: about 15 people in a hundred give, always the same ones
	const float rem0 = dir[i] > 0 ? S.len - u[i] : u[i];
	if (cfg.life && tier[i] == TIER_FULL && !party[i] && meet_cd[i] <= 0.0f && look[i] % 100u < 15u && rem0 > 4.0f && S.len - rem0 > 4.0f) {
		const int gx = (int)std::floor(x[i] * 0.5f), gz = (int)std::floor(z[i] * 0.5f);
		for (int a = -1; a <= 1; a++) for (int b = -1; b <= 1; b++) {
			for (int j = g_head[grid_ix(gx + a, gz + b)]; j >= 0; j = g_next[j]) {
				if (j == i || !alive[j] || act[j] != A_BEG) continue;
				const float dx = x[j] - x[i], dz = z[j] - z[i];
				if (dx * dx + dz * dz > 2.2f * 2.2f || dx * hx[i] + dz * hz[i] < 0.2f) continue;
				state[i] = ST_PAUSE; pause_t[i] = 1.8f; act[i] = A_GIVE; v[i] = 0.0f; meet_cd[i] = 40.0f;
				flags[i] |= F_FACE; face_yaw[i] = std::atan2(dx, dz);
				st.coins++; event(E_GIVE, id[i], id[j], 0.0f);
				return;
			}
		}
	}
	// rain: some go and stand at the nearest shop's front until it stops
	if (rain > 0.5f && cfg.goals && !party[i] && (look[i] >> 12) % 3u == 0u && !(goal[i] >= 0 && places[goal[i]].kind == PL_SHOP && !enter_goal[i]) && roll_t[i] > 0.0f) {
		int best = -1; float bd = 90.0f * 90.0f;
		const int cx = std::min(std::max((int)std::floor(x[i] / 100.0f) + 32, 0), 63), cz = std::min(std::max((int)std::floor(z[i] / 100.0f) + 32, 0), 63);
		if (!place_grid.empty()) for (int p : place_grid[cz * 64 + cx]) {
			if (places[p].kind != PL_SHOP) continue;
			const float dx = places[p].ax - x[i], dz = places[p].az - z[i], d2 = dx * dx + dz * dz;
			if (d2 < bd) { bd = d2; best = p; }
		}
		roll_t[i] = -1.0f;   // (he looks for shelter once)
		if (best >= 0) {
			free_place(i);
			if (plan(i, places[best].seg, places[best].u)) { goal[i] = best; goal_seg[i] = places[best].seg; goal_u[i] = places[best].u; enter_goal[i] = 0; stay_t[i] = 0.0f; st.sheltered++; }
			else goal[i] = -1;
		}
		return;
	}
	// every 18-50 s a roll: a phone call where he stands, or a look into a shop window
	roll_t[i] -= h;
	if (roll_t[i] > 0.0f || roll_t[i] < -0.5f) { if (roll_t[i] < -0.5f && rain < 0.3f) roll_t[i] = 18.0f + 32.0f * rnd_of(i); return; }
	roll_t[i] = 18.0f + 32.0f * rnd_of(i);
	const float rem = dir[i] > 0 ? S.len - u[i] : u[i];
	if (rem < 6.0f || S.len - rem < 6.0f || tier[i] == TIER_FAR) return;
	const float r = rnd_of(i);
	// (Yasin, 21 Nov: "make them talk on the phone or simply walk for the most, make the chances of seeing each people doing an
	// action should be logical"): most of the time he just walks; a call or a text as he walks is the next most usual
	// (a quarter of the rolls, 15-40 s), stopping for one less (a tenth)
	if (r < 0.10f) { state[i] = ST_PAUSE; pause_t[i] = 6.0f + 12.0f * rnd_of(i); act[i] = A_PHONE; v[i] = 0.0f; st.pauses++; return; }
	if (r < 0.35f) { act[i] = A_PHONE; act_t[i] = 15.0f + 25.0f * rnd_of(i); return; }   // ... or as he walks on (act_t ends it)
	if (r < 0.55f) {
		for (int p : seg_places[seg[i]]) {
			if (places[p].kind != PL_SHOP || std::fabs(places[p].u - u[i]) > 10.0f) continue;
			state[i] = ST_PAUSE; pause_t[i] = 4.0f + 6.0f * rnd_of(i); act[i] = A_WINDOW; v[i] = 0.0f; st.pauses++;
			flags[i] |= F_FACE; face_yaw[i] = std::atan2(places[p].x - x[i], places[p].z - z[i]);
			return;
		}
	}
}

// Two lone walkers who know each other meet as they pass: a wave, a chat, a hug, or a quarrel. A quarter of the
// quarrels are long ones, and of the long ones one in cfg.fight_one_in comes to blows: one meeting in eighty (Yasin,
// 20 Nov: fights "should be really rare"). How long anybody stands is the same either way, so nothing else changes. Which pairs know each other, and what they do, is fixed by who they are.
void Crowd::meet(int i, int j) {
	const uint32_t hsh = hash32((look[i] ^ look[j]) + 0x51ED270Bu);
	const int kind = (int)(hsh % 4u);
	meet_cd[i] = meet_cd[j] = 90.0f;
	st.meetings++;
	event(E_MEET, id[i], id[j], (float)kind);
	if (kind == 0) { act[i] = act[j] = A_WAVE; act_t[i] = act_t[j] = 1.6f; return; }   // a wave in passing
	const float fa = std::atan2(x[j] - x[i], z[j] - z[i]);
	float t = 8.0f + (float)((hsh >> 8) % 12u);
	uint8_t a = A_CHAT; float at_ = 0.0f;
	if (kind == 2) { a = A_HUG; at_ = 3.0f; t = 8.0f; }
	if (kind == 3) { a = A_ARGUE; t = 6.0f + (float)((hsh >> 8) % 6u); at_ = t + 10.0f; if ((hsh >> 16) % 4u == 0u) { t += cfg.fight_s; if ((hsh >> 20) % (uint32_t)std::max(cfg.fight_one_in, 1) == 0u) at_ = t - cfg.fight_s; } }   // (act_t runs out inside the pause: blows)
	for (int k = 0; k < 2; k++) {
		const int w = k ? j : i;
		state[w] = ST_PAUSE; pause_t[w] = t; act[w] = a; act_t[w] = at_; v[w] = 0.0f; pass[w] = 0;
		flags[w] |= F_FACE; face_yaw[w] = k ? fa + 3.14159265f : fa;
		mate[w] = id[k ? i : j];
	}
}

// Something frightening at a point: people close by duck, those farther turn and run for the time given, some stand
// at a safe distance and stare, film it or make a call.
void Crowd::scare(float p_x, float p_z, float p_radius, float p_seconds) {
	if (scares.size() < 8) scares.push_back(Scare{ p_x, p_z, p_radius, p_seconds });
	for (int i = 0; i < hi; i++) {
		if (!alive[i] || (flags[i] & (F_SCRIPT | F_HIDDEN)) || mode[i] == M_BODY || mode[i] == M_HELD) continue;
		// (the ones in the fight go on with it; the ones already looking, filming, calling or ducking are reacting already)
		if (act[i] == A_FIGHT || act[i] == A_ARGUE || act[i] == A_CHEER || act[i] == A_STARE || act[i] == A_FILM || act[i] == A_CALL || act[i] == A_DUCK) continue;
		const float dx = x[i] - p_x, dz = z[i] - p_z, d2 = dx * dx + dz * dz;
		if (d2 > p_radius * p_radius) continue;
		const float dd = std::sqrt(d2);
		const uint32_t roll = hash32(look[i] ^ 0x9E3779B9u) % 100u;
		if (mode[i] == M_FOLLOW) continue;   // (they do as their leader does)
		if (dd < 8.0f && mode[i] == M_LINE) {
			state[i] = ST_PAUSE; pause_t[i] = 2.5f + 1.5f * rnd_of(i); act[i] = A_DUCK; act_t[i] = 0.0f; v[i] = 0.0f; pass[i] = 0; st.ducks++;
			flee_t[i] = 0.0f;
			continue;
		}
		// far enough to feel safe: almost half of them watch; of those about a third film it and a quarter call (B31, Yasin:
		// "they were supposed to call the police or take pictures videos")
		if (roll >= 55u && dd > 12.0f && mode[i] == M_LINE && !party[i]) {
			state[i] = ST_PAUSE; pause_t[i] = p_seconds * 0.8f; act[i] = roll < 73u ? A_STARE : (roll < 88u ? A_FILM : A_CALL); act_t[i] = 0.0f; v[i] = 0.0f; pass[i] = 0;
			flags[i] |= F_FACE; face_yaw[i] = std::atan2(-dx, -dz);
			st.stared++;
			continue;
		}
		// it runs: away from the thing, along its pavement
		flee_t[i] = p_seconds; flags[i] |= F_FLEE;
		free_place(i); goal[i] = -1; route_n[i] = 0; pass[i] = 0; nxt[i] = -1;
		if (mode[i] == M_STAY) { stay_t[i] = 0.0f; flags[i] &= (uint8_t)~F_FACE; }
		if (mode[i] == M_LINE) {
			if (state[i] == ST_PAUSE) { state[i] = ST_WALK; act[i] = A_NONE; flags[i] &= (uint8_t)~F_FACE; }
			if (hx[i] * dx + hz[i] * dz < 0.0f && !on_road(i)) dir[i] = (int8_t)-dir[i];
		}
		st.fled++;
		if (roll % 10u == 0u) event(E_SCREAM, id[i], 0, dd);
	}
}

void Crowd::danger_step(float h) {
	for (size_t k = 0; k < scares.size();) {
		scares[k].t -= h;
		if (scares[k].t <= 0.0f) { scares[k] = scares.back(); scares.pop_back(); } else k++;
	}
}

// A car coming at a walker (seen up to two seconds ahead): out of its way, off the pavement if it must. Called with
// h = 0 from the pavement's line to look; with the step's time while it jumps aside. Also the "look out!" for a car
// that passes close and fast.
bool Crowd::dodge(int i, float h) {
	if (mode[i] == M_LINE || mode[i] == M_FOLLOW) {
		const int n = (int)cars.size() / 7;
		for (int c = 0; c < n; c++) {
			const float *q = &cars[(size_t)c * 7];
			const float sp = std::sqrt(q[5] * q[5] + q[6] * q[6]);
			if (sp < 3.0f) continue;
			const float wx = q[5] / sp, wz = q[6] / sp;
			const float rx = x[i] - q[0], rz = z[i] - q[1];
			const float along = rx * wx + rz * wz;
			if (along < 0.0f || along > sp * 2.0f + q[3]) continue;
			const float side = rx * wz - rz * wx;   // (+ = to the car's left)
			if (sp > 14.0f && std::fabs(side) < 5.0f && lookout_cd[i] <= 0.0f) { lookout_cd[i] = 20.0f; st.lookouts++; event(E_LOOKOUT, id[i], c, sp); }
			if (std::fabs(side) > q[4] + 0.45f) continue;
			// it will be hit: a jump to the side it is already on, clear of the car's flank
			const float sgn = side >= 0.0f ? 1.0f : -1.0f, go = q[4] + 1.3f - std::fabs(side);
			bx[i] = x[i]; bz[i] = z[i];
			tx[i] = x[i] + wz * sgn * go; tz[i] = z[i] - wx * sgn * go; ty[i] = y[i];
			mode[i] = M_DODGE; pause_t[i] = 0.0f; pass[i] = 0; blocked_t[i] = 0.0f;
			if (state[i] == ST_PAUSE) { state[i] = ST_WALK; act[i] = A_NONE; flags[i] &= (uint8_t)~F_FACE; }
			st.dodges++;
			return true;
		}
		return false;
	}
	// in the jump: there, a breath, then back to where it was, but not while a car still comes at that place
	if (pause_t[i] > 0.0f) {
		pause_t[i] -= h; v[i] = 0.0f;
		if (pause_t[i] <= 0.0f) {
			bool comes = car_at(bx[i], bz[i], RAD + 0.3f);
			const int n = (int)cars.size() / 7;
			for (int c = 0; c < n && !comes; c++) {
				const float *q = &cars[(size_t)c * 7];
				const float sp = std::sqrt(q[5] * q[5] + q[6] * q[6]);
				if (sp < 1.0f) continue;
				const float wx = q[5] / sp, wz = q[6] / sp, rx = bx[i] - q[0], rz = bz[i] - q[1];
				const float along = rx * wx + rz * wz;
				comes = along > -q[3] - 1.0f && along < sp * 3.0f + q[3] && std::fabs(rx * wz - rz * wx) < q[4] + 0.8f;
			}
			if (comes) pause_t[i] = 0.3f;
			else { mode[i] = M_BACK; tx[i] = bx[i]; tz[i] = bz[i]; blocked_t[i] = 0.0f; }
		}
		return true;
	}
	if (free_move(i, tx[i], tz[i], 3.6f, h) || blocked_t[i] > 1.2f) pause_t[i] = 0.6f;
	return true;
}

// Beggars at their spots by day, night workers at their corners by night: they are there while the place is near.
void Crowd::residents() {
	if (!cfg.life) return;
	for (int k : cand) {
		for (int p : seg_places[k]) {
			const Place &P = places[p];
			if ((P.kind != PL_BEG && P.kind != PL_NIGHT) || occ[p] != -1) continue;
			const bool on = P.kind == PL_BEG ? (hour >= 8.0f && hour < 20.0f && rain < 0.5f) : (hour >= 21.0f || hour < 5.0f);
			if (!on) continue;
			if (!cfg.whole) {
				const float dx = P.x - cam_x, dz = P.z - cam_z, dd = std::sqrt(dx * dx + dz * dz);
				if (dd > cfg.ring_out || (dd < cfg.view_r && (cam_fx != 0.0f || cam_fz != 0.0f) && dx * cam_fx + dz * cam_fz > 0.5f * dd)) continue;
			}
			const Seg &S = segs[P.seg];
			const float side = (hash32((uint32_t)p) & 1u) ? 1.0f : -1.0f;
			const float sl = P.kind == PL_NIGHT ? side * edge_off(S) : 0.0f;
			const float su = P.kind == PL_NIGHT ? clampf(P.u, 1.5f, S.len - 1.5f) : P.u;
			float sx = P.x, sz = P.z;
			if (P.kind == PL_NIGHT) { int h = 0; float sy, tx_, tz_; at(S, su, sl, h, sx, sy, sz, tx_, tz_); }
			if (!free_at(-1, sx, sz)) continue;
			const int i = new_row(P.seg, su, 1, sl, hash32((uint32_t)p * 2246822519u + 7u));
			if (i < 0) return;
			bx[i] = x[i]; bz[i] = z[i];
			move_row(i, sx, sz); if (P.kind == PL_BEG) y[i] = py[i] = P.y;
			mode[i] = M_STAY; act[i] = P.kind == PL_BEG ? A_BEG : A_NONE; flags[i] |= F_RESIDENT; v[i] = 0.0f;
			goal[i] = p; occ[p] = id[i]; stay_t[i] = BIG; enter_goal[i] = 0;
			tyaw[i] = yaw[i] = pyaw[i] = P.kind == PL_BEG ? P.yaw : (float)(hash32((uint32_t)p + 3u) % 628u) * 0.01f;
		}
	}
}

// ---------------------------------------------------------------- the hooks
int Crowd::place_walker(float p_x, float p_z, uint32_t p_look) {
	float su = 0, dd = 0, ax = 0, az = 0, ay = 0;
	const int k = nearest_walk(p_x, p_z, 60.0f, su, dd, ax, az, ay);
	if (k < 0) return -1;
	const Seg &S = segs[k];
	int h = 0; float sx, sy, sz, tx_, tz_;
	at(S, su, 0.0f, h, sx, sy, sz, tx_, tz_);
	const float sl = clampf((p_x - sx) * tz_ - (p_z - sz) * tx_, -edge_off(S), edge_off(S));
	const int i = new_row(k, su, 1, sl, p_look);
	if (i < 0) return -1;
	flags[i] |= F_SCRIPT;
	return id[i];
}

// A person set down exactly at a point (a cyclist who came off on the road), held there facing p_yaw until the game
// hands him to a body (to_body) and back; he then walks to the pavement as anybody does who was knocked over.
int Crowd::place_held_at(float p_x, float p_z, uint32_t p_look, float p_yaw) {
	const int pid = place_walker(p_x, p_z, p_look);
	const int i = find(pid);
	if (i < 0) return -1;
	mode[i] = M_HELD; v[i] = 0.0f; pass[i] = 0; face_yaw[i] = p_yaw; yaw[i] = pyaw[i] = p_yaw;
	move_row(i, p_x, p_z);
	return pid;
}

bool Crowd::remove_walker(int p_id) {
	const int i = find(p_id);
	if (i < 0) return false;
	kill(i, 9);
	return true;
}

bool Crowd::set_goal(int p_id, int p_place, float p_stay_s, bool p_enter) {
	const int i = find(p_id);
	if (i < 0 || p_place < 0 || p_place >= (int)places.size() || mode[i] != M_LINE) return false;
	const Place &P = places[p_place];
	if (seat_kind(P.kind) && occ[p_place] != -1 && occ[p_place] != p_id) return false;
	free_place(i);
	if (!plan(i, P.seg, P.u)) { goal[i] = -1; return false; }
	goal[i] = p_place; goal_seg[i] = P.seg; goal_u[i] = P.u; enter_goal[i] = p_enter ? 1 : 0; stay_t[i] = p_stay_s;
	if (seat_kind(P.kind)) occ[p_place] = p_id;
	if (state[i] == ST_PAUSE) { state[i] = ST_WALK; act[i] = A_NONE; flags[i] &= (uint8_t)~F_FACE; }
	return true;
}

bool Crowd::set_goal_point(int p_id, float p_x, float p_z, float p_stay_s) {
	const int i = find(p_id);
	if (i < 0 || mode[i] != M_LINE) return false;
	float su = 0, dd = 0, ax = 0, az = 0, ay = 0;
	const int k = nearest_walk(p_x, p_z, 60.0f, su, dd, ax, az, ay);
	if (k < 0) return false;
	free_place(i);
	if (!plan(i, k, su)) { goal[i] = -1; return false; }
	goal[i] = -2; goal_seg[i] = k; goal_u[i] = su; enter_goal[i] = 0; stay_t[i] = p_stay_s;
	return true;
}

bool Crowd::stay(int p_id, float p_seconds) {
	const int i = find(p_id);
	if (i < 0 || mode[i] != M_LINE) return false;
	state[i] = ST_PAUSE; pause_t[i] = p_seconds; v[i] = 0.0f; pass[i] = 0;
	return true;
}

bool Crowd::set_act(int p_id, int p_act, float p_seconds) {
	const int i = find(p_id);
	if (i < 0 || p_act < 0 || p_act >= A_COUNT) return false;
	act[i] = (uint8_t)p_act; act_t[i] = p_seconds;
	if (mode[i] == M_LINE && p_seconds > 0.0f && p_act != A_WAVE) { state[i] = ST_PAUSE; pause_t[i] = p_seconds; act_t[i] = 0.0f; v[i] = 0.0f; pass[i] = 0; }
	return true;
}

bool Crowd::hold(int p_id, bool p_on, float p_yaw) {
	const int i = find(p_id);
	if (i < 0) return false;
	if (p_on) {
		face_yaw[i] = p_yaw;
		if (mode[i] == M_LINE) { mode[i] = M_HELD; v[i] = 0.0f; pass[i] = 0; return true; }
		if (mode[i] == M_FOLLOW) { boarding[i] = 2; return true; }
		if (mode[i] == M_STAY) { flags[i] |= F_FACE; return true; }
		return false;
	}
	if (mode[i] == M_HELD) { mode[i] = M_LINE; still_t[i] = 0.0f; blocked_t[i] = 0.0f; }
	else if (mode[i] == M_FOLLOW && boarding[i] == 2) boarding[i] = 0;
	else if (mode[i] == M_STAY) flags[i] &= (uint8_t)~F_FACE;
	return true;
}

bool Crowd::hide(int p_id, bool p_on) {
	const int i = find(p_id);
	if (i < 0) return false;
	if (p_on) flags[i] |= F_HIDDEN; else flags[i] &= (uint8_t)~F_HIDDEN;
	return true;
}

// A physical body has it (pushed, hit: the game moves it and tells where it is), or gives it back at a place.
bool Crowd::to_body(int p_id, bool p_on, float p_x, float p_z) {
	const int i = find(p_id);
	if (i < 0) return false;
	if (p_on) {
		if (mode[i] != M_BODY) {
			if (party[i]) {
				// The people it walks with stop and look at it, and it goes back to them when it is on its feet again
				// (rejoin): whoever leads them stands for up to 14 s, turned to it, and the others gather round him.
				int mate_row = -1;
				for (int j = 0; j < hi; j++) if (alive[j] && j != i && party[j] == party[i] && (mate_row < 0 || slot[j] < slot[mate_row])) mate_row = j;
				kept_mate[i] = mate_row >= 0 ? id[mate_row] : 0; kept_kind[i] = pkind[i];
				leave_party(i);
				if (mate_row >= 0) {
					const int L = party[mate_row] != 0 && leader[mate_row] >= 0 ? leader[mate_row] : mate_row;
					if (alive[L] && mode[L] == M_LINE && state[L] == ST_WALK && segs[seg[L]].kind == 0) {
						state[L] = ST_PAUSE; pause_t[L] = 14.0f; act[L] = A_STARE; act_t[L] = 0.0f; v[L] = 0.0f; pass[L] = 0;
						flags[L] |= F_FACE; face_yaw[L] = std::atan2(p_x - x[L], p_z - z[L]);
					}
				}
			}
			kept_goal[i] = (flags[i] & F_RESIDENT) ? -1 : goal[i]; kept_stay[i] = stay_t[i]; kept_enter[i] = enter_goal[i];
			free_place(i); goal[i] = -1; route_n[i] = 0; pass[i] = 0; act[i] = A_NONE; state[i] = ST_WALK; boarding[i] = 0;
			flags[i] &= (uint8_t)~(F_FACE | F_FLEE); flee_t[i] = 0.0f;
			mode[i] = M_BODY; v[i] = 0.0f;
		}
		{ const float kx = px[i], kz = pz[i]; move_row(i, p_x, p_z); px[i] = kx; pz[i] = kz; }
		return true;
	}
	if (mode[i] != M_BODY) return false;
	float su = 0, dd = 0, ax = 0, az = 0, ay = 0;
	const int k = nearest_walk(p_x, p_z, 40.0f, su, dd, ax, az, ay);
	if (k < 0) { kill(i, 8); return false; }   // (it lies where no pavement is near: it is gone)
	seg[i] = k; u[i] = su; ls[i] = 0.0f; hint[i] = 0; nxt[i] = -1; dir[i] = 1;
	move_row(i, p_x, p_z);
	bx[i] = ax; bz[i] = az; tx[i] = ax; tz[i] = az; ty[i] = ay;
	mode[i] = M_BACK; v[i] = 0.0f; blocked_t[i] = 0.0f; still_t[i] = 0.0f; thin[i] = 0;
	return true;
}

// (the game) Two people come to blows where they stand: they turn to each other and fight for cfg.fight_s seconds.
bool Crowd::fight(int p_a, int p_b) {
	const int i = find(p_a), j = find(p_b);
	if (i < 0 || j < 0 || i == j || (mode[i] != M_LINE && mode[i] != M_HELD) || (mode[j] != M_LINE && mode[j] != M_HELD)) return false;
	const float fa = std::atan2(x[j] - x[i], z[j] - z[i]);
	for (int k = 0; k < 2; k++) {
		const int w = k ? j : i;
		state[w] = ST_PAUSE; pause_t[w] = cfg.fight_s; act[w] = A_FIGHT; act_t[w] = 0.0f; v[w] = 0.0f; pass[w] = 0;
		flags[w] |= F_FACE; face_yaw[w] = k ? fa + 3.14159265f : fa;
		mate[w] = id[k ? i : j];
	}
	st.fights++;
	event(E_FIGHT, id[i], id[j], 0.0f);
	fight_begins(i); fight_begins(j);
	return true;
}

// (after a knock) He goes back to the people he walked with: whoever leads them now leads him too. Not if they are
// more than 30 m off by then, or not on a pavement's line.
bool Crowd::rejoin(int i, int mate_id, int kind) {
	const int m = find(mate_id);
	if (m < 0 || m == i || party[i] != 0 || mode[i] != M_LINE) return false;
	const int L = party[m] != 0 && leader[m] >= 0 ? leader[m] : m;
	if (!alive[L] || mode[L] != M_LINE || pkind[L] == PK_JOGGER || L == i) return false;
	const float dx = x[L] - x[i], dz = z[L] - z[i];
	if (dx * dx + dz * dz > 30.0f * 30.0f) return false;
	if (party[L] == 0) {   // (there were two of them: the other has walked alone since)
		party[L] = next_party++; leader[L] = (int16_t)L; pkind[L] = (uint8_t)(kind != PK_NONE ? kind : PK_FRIENDS); slot[L] = 0; psize[L] = 1; abreast[L] = 0; trail_d[L] = 0.0f;
		for (int q = 0; q < TRAIL_N; q++) { trail[L][q][0] = x[L]; trail[L][q][1] = y[L]; trail[L][q][2] = z[L]; }
		trail_at[L] = 0; lagf[L] = 1.0f;
	}
	const int n = psize[L];
	if (n >= MAX_PARTY) return false;
	free_place(i); goal[i] = -1; route_n[i] = 0; act[i] = A_NONE; state[i] = ST_WALK;
	mode[i] = M_FOLLOW; leader[i] = (int16_t)L; party[i] = party[L]; pkind[i] = pkind[L]; slot[i] = (uint8_t)n; abreast[i] = 0; boarding[i] = 0;
	for (int j = 0; j < hi; j++) if (alive[j] && party[j] == party[L]) psize[j] = (uint8_t)(n + 1);
	if (state[L] == ST_PAUSE && act[L] == A_STARE) { pause_t[L] = std::min(pause_t[L], 0.8f); }   // (they were waiting for him: on they go)
	return true;
}

} // namespace pc
