// The walking crowd: people who walk together. One leads and walks the way; the others keep their places beside or
// behind him ON HIS OWN TRAIL (so they turn the corner where he turned it), abreast where there is room and nobody
// comes, in single file where not. They wait for each other, stop in a circle to talk, and the group nearest the
// player says a conversation's lines in turn. See ped_crowd.h.
#include "ped_crowd.h"

#include "ped_inl.h"

namespace pc {

// The leader `lead` gets company of a kind (or becomes a jogger, who runs alone).
void Crowd::make_party(int lead, int kind) {
	if (kind == PK_JOGGER) { pkind[lead] = PK_JOGGER; v0[lead] = 2.9f + 0.5f * rnd_of(lead); v[lead] = v0[lead]; return; }
	const int want = kind == PK_COUPLE ? 2 : (kind == PK_FAMILY ? 3 + (rnd_of(lead) < 0.5f ? 1 : 0) : 2 + (rnd_of(lead) < 0.5f ? 1 : 0));
	const Seg &S = segs[seg[lead]];
	party[lead] = next_party++; leader[lead] = (int16_t)lead; pkind[lead] = (uint8_t)kind; slot[lead] = 0; psize[lead] = 1; abreast[lead] = 0; trail_d[lead] = 0.0f;
	float slow = v0[lead];
	for (int k = 1; k < want && k < MAX_PARTY; k++) {
		const float su = u[lead] - (float)dir[lead] * 0.8f * (float)k;
		if (su < 1.0f || su > S.len - 1.0f) break;
		int h = hint[lead]; float sx, sy, sz, tx_, tz_;
		at(S, su, ls[lead], h, sx, sy, sz, tx_, tz_);
		if (!free_at(-1, sx, sz)) break;
		const int j = new_row(seg[lead], su, dir[lead], ls[lead], 0);
		if (j < 0) break;
		mode[j] = M_FOLLOW; leader[j] = (int16_t)lead; party[j] = party[lead]; pkind[j] = (uint8_t)kind; slot[j] = psize[lead]; psize[lead]++;
		slow = std::min(slow, v0[j]);
	}
	if (psize[lead] < 2) { party[lead] = 0; leader[lead] = -1; pkind[lead] = PK_NONE; return; }
	v0[lead] = slow * (kind == PK_FAMILY ? 0.85f : 1.0f);   // a group walks at its slowest one's pace; families slower still
	v[lead] = std::min(v[lead], v0[lead]);
	for (int j = 0; j < hi; j++) if (alive[j] && leader[j] == lead) psize[j] = psize[lead];
	st.parties++;
}

// A leader's trail: a point every quarter metre it has gone.
void Crowd::trail_push(int i) {
	const float *n = trail[i][trail_at[i]];
	const float dx = x[i] - n[0], dz = z[i] - n[2];
	if (dx * dx + dz * dz < TRAIL_STEP * TRAIL_STEP) return;
	trail_at[i] = (uint8_t)((trail_at[i] + 1) % TRAIL_N);
	float *w = trail[i][trail_at[i]];
	w[0] = x[i]; w[1] = y[i]; w[2] = z[i];
}

// One of a party leaves it (it is taken away, lost, or the party breaks up). If it led, the next one leads.
void Crowd::leave_party(int i) {
	const int L = leader[i];
	const int pid = party[i];
	party[i] = 0; leader[i] = -1; pkind[i] = PK_NONE; psize[i] = 1; abreast[i] = 0;
	if (pid == 0) return;
	thin[i] = 1; thin_t[i] = 0.0f;
	for (int j = 0; j < hi; j++) {
		if (!alive[j] || party[j] != pid) continue;
		thin[j] = 1; thin_t[j] = 0.0f;   // (they stood closer than strangers do: each is "sideways" until it has room)
		const float dx = x[i] - x[j], dz = z[i] - z[j], d2 = dx * dx + dz * dz;
		if (alive[i] && d2 < 0.30f * 0.30f) {   // nearer than two people sideways: the one who leaves steps that much away
			const float dl = std::sqrt(d2), ux = dl > 1.0e-3f ? dx / dl : hz[j], uz = dl > 1.0e-3f ? dz / dl : -hx[j];
			const float nx = x[j] + ux * 0.31f, nz = z[j] + uz * 0.31f, kx = px[i], kz = pz[i];
			move_row(i, nx, nz); px[i] = kx; pz[i] = kz;
		}
	}
	auto to_line = [&](int j) {   // from a place beside the leader's trail back onto the pavement's own line
		const Seg &S = segs[seg[j]];
		int hh = hint[j]; float ax, ay, az, tx_, tz_;
		at(S, u[j], 0.0f, hh, ax, ay, az, tx_, tz_);
		u[j] = clampf(u[j] + (x[j] - ax) * tx_ + (z[j] - az) * tz_, 0.0f, S.len);   // (its books said its leader's place: now its own)
		at(S, u[j], 0.0f, hh, ax, ay, az, tx_, tz_);
		ls[j] = clampf((x[j] - ax) * tz_ - (z[j] - az) * tx_, -edge_off(S), edge_off(S));
		hint[j] = hh; mode[j] = M_LINE; looked[j] = S.kind == 1 ? 1 : 0; state[j] = ST_WALK; act[j] = A_NONE; nxt[j] = -1; boarding[j] = 0;
		bx[j] = x[j]; bz[j] = z[j];
	};
	if (L == i) {   // the leader goes: the next in line leads, with the way the leader had
		int nl = -1, left = 0;
		for (int j = 0; j < hi; j++) if (alive[j] && j != i && party[j] == pid) { left++; if (nl < 0 || slot[j] < slot[nl]) nl = j; }
		if (nl < 0) return;
		const bool on_line = mode[i] == M_LINE;
		to_line(nl);
		if (on_line) {
			goal[nl] = -1; route_n[nl] = 0;
			for (int k = 0; k < route_n[i] && k < ROUTE_N; k++) route[nl][k] = route[i][k];
			if (goal[i] < 0 || !seat_kind(places[goal[i]].kind)) { goal[nl] = goal[i]; goal_seg[nl] = goal_seg[i]; goal_u[nl] = goal_u[i]; route_n[nl] = route_n[i]; route_i[nl] = route_i[i]; enter_goal[nl] = enter_goal[i]; }
		}
		for (int q = 0; q < TRAIL_N; q++) { trail[nl][q][0] = x[nl]; trail[nl][q][1] = y[nl]; trail[nl][q][2] = z[nl]; }
		trail_at[nl] = 0; lagf[nl] = 1.0f;
		if (left == 1) { party[nl] = 0; leader[nl] = -1; pkind[nl] = PK_NONE; psize[nl] = 1; return; }
		const int s0 = slot[nl];
		for (int j = 0; j < hi; j++) if (alive[j] && party[j] == pid) { leader[j] = (int16_t)nl; psize[j] = (uint8_t)left; if (slot[j] > s0) slot[j]--; }
		slot[nl] = 0;
	} else {        // one of the others goes
		const int s0 = slot[i];
		int left = 0;
		for (int j = 0; j < hi; j++) if (alive[j] && party[j] == pid) left++;
		for (int j = 0; j < hi; j++) if (alive[j] && party[j] == pid) { psize[j] = (uint8_t)left; if (slot[j] > s0) slot[j]--; }
		if (left == 1 && L >= 0 && alive[L]) { party[L] = 0; leader[L] = -1; pkind[L] = PK_NONE; psize[L] = 1; lagf[L] = 1.0f; }
		if (alive[i] && mode[i] == M_FOLLOW) to_line(i);
	}
}

// One who follows: to its place on the leader's trail.
void Crowd::follow(int i, float h) {
	const int L = leader[i];
	if (L < 0 || !alive[L] || party[L] != party[i] || L == i) { leave_party(i); return; }
	// it is where its leader is, as far as the pavement's books go (which pavement, how far along, on the road or not)
	seg[i] = seg[L]; u[i] = u[L]; dir[i] = dir[L]; hint[i] = hint[L]; looked[i] = looked[L]; state[i] = state[L]; why[i] = why[L];
	if (act_t[i] > 0.0f) { act_t[i] -= h; if (act_t[i] <= 0.0f) act[i] = A_NONE; }
	if (boarding[i] == 2) { v[i] = 0.0f; lagf[L] = 0.0f; yaw[i] += clampf(wrap_pi(face_yaw[i] - yaw[i]), -5.0f * h, 5.0f * h); return; }   // the game holds it (a talk): its people wait
	float gx, gz, gy = y[L];
	bool gather = false;
	const bool stands = mode[L] == M_STAY || mode[L] == M_HELD || (mode[L] == M_LINE && state[L] == ST_PAUSE);
	if (stands) {   // the leader stands: they stand round in front of him and face him
		gather = true;
		static const float ANG[MAX_PARTY] = { 0.0f, 0.75f, -0.75f, 0.0f }, RR[MAX_PARTY] = { 0.0f, 0.78f, 0.78f, 1.25f };
		const float a = yaw[L] + ANG[slot[i] % MAX_PARTY], r = RR[slot[i] % MAX_PARTY];
		gx = x[L] + std::sin(a) * r; gz = z[L] + std::cos(a) * r;
		if (act[L] == A_CHAT || act[L] == A_TALK) { if (act_t[i] <= 0.0f) act[i] = A_CHAT; } else if (act_t[i] <= 0.0f) act[i] = A_NONE;
	} else {
		if (act_t[i] <= 0.0f) act[i] = A_NONE;
		const bool ab = abreast[L] != 0;
		const int s = slot[i];
		const float back = ab ? (s >= 2 ? 0.95f : 0.0f) : 0.8f * (float)s;
		const float lat = ab ? ((s & 1) ? 0.64f : 0.0f) : 0.0f;
		// the point of the trail `back` metres behind the leader, and the way the trail runs there
		float ax = x[L], az = z[L], dxn = hx[L], dzn = hz[L], acc = 0.0f;
		gy = y[L];
		int at_ = trail_at[L];
		bool turned = false;
		{   // the leader has turned round: its trail lies in FRONT of it now. Then its people fall in straight behind it.
			const float *p0 = trail[L][at_], *p1 = trail[L][(at_ + TRAIL_N - 4) % TRAIL_N];
			const float ex = p0[0] - p1[0], ez = p0[2] - p1[2];
			turned = ex * hx[L] + ez * hz[L] < -0.05f;
		}
		for (int q = 0; q < TRAIL_N - 1 && acc < back && !turned; q++) {
			const float *p = trail[L][at_];
			const float ex = ax - p[0], ez = az - p[2], el = std::sqrt(ex * ex + ez * ez);
			if (el > 1.0e-4f) {
				dxn = ex / el; dzn = ez / el;
				if (acc + el >= back) { const float f = (back - acc) / el; ax -= ex * f; az -= ez * f; gy = p[1]; acc = back; break; }
				acc += el;
			}
			ax = p[0]; az = p[2]; gy = p[1];
			at_ = (at_ + TRAIL_N - 1) % TRAIL_N;
		}
		if (acc < back) { ax -= dxn * (back - acc); az -= dzn * (back - acc); }   // (the trail is shorter than that: straight behind)
		gx = ax + dzn * lat; gz = az - dxn * lat;   // (left of the way the trail runs)
	}
	const float dx = gx - x[i], dz = gz - z[i], dd = std::sqrt(dx * dx + dz * dz);
	wait_t[i] = dd > 3.0f ? wait_t[i] + h : 0.0f;
	if (dd > 14.0f || blocked_t[i] > 6.0f || wait_t[i] > 12.0f) { blocked_t[i] = 0.0f; wait_t[i] = 0.0f; leave_party(i); return; }   // lost, held, or behind for too long: it goes its own way
	if (dd > 2.0f) lagf[L] = std::min(lagf[L], dd > 3.5f ? 0.0f : 0.5f);   // the leader slows for it, and waits
	if (!cars.empty() && tier[i] == TIER_FULL && dodge(i, 0.0f)) return;   // a car comes at it: out of the way
	ty[i] = gy;
	if (dd < 0.12f) {
		v[i] = 0.0f; still_t[i] = 0.0f;
		if (gather) yaw[i] += clampf(wrap_pi(std::atan2(x[L] - x[i], z[L] - z[i]) - yaw[i]), -5.0f * h, 5.0f * h);
		else yaw[i] += clampf(wrap_pi(yaw[L] - yaw[i]), -4.0f * h, 4.0f * h);
		return;
	}
	const bool road = segs[seg[L]].kind == 1 && looked[L];   // (on a crossing nobody hangs back: a run to keep up)
	const float want = gather ? std::min(v0[i], dd * 2.0f + 0.2f) : clampf(v[L] + (dd - 0.15f) * (road ? 3.5f : 2.2f), 0.0f, road ? JOG + 0.4f : std::max(v[L] + 0.7f, v0[i] * 1.35f));
	free_move(i, gx, gz, want, h);
	if (!gather && v[i] < 0.05f) yaw[i] += clampf(wrap_pi(yaw[L] - yaw[i]), -4.0f * h, 4.0f * h);
}

// Once a step, for every party: abreast or in single file, a stop to talk in a circle, the conversation near the player.
void Crowd::party_step(float h) {
	int circles = 0;
	int near_l = -1; float near_d = 9.0f * 9.0f;
	bool conv_alive = false;
	for (int L = 0; L < hi; L++) {
		if (!alive[L] || leader[L] != L) continue;
		const Seg &S = segs[seg[L]];
		const bool on_line = mode[L] == M_LINE;
		// abreast where there is room, nobody comes and nothing holds the leader; else behind each other
		const bool room = S.kind == 1 || S.hw >= 0.80f;
		const bool calm = on_line && (state[L] == ST_WALK || state[L] == ST_CROSS) && why[L] == WHY_NONE && !pass[L] && blocked_t[L] <= 0.0f && !left_far[L];
		trail_d[L] = (room && calm) ? std::min(trail_d[L] + h, 3.0f) : 0.0f;
		abreast[L] = trail_d[L] > 1.0f ? 1 : 0;
		if (on_line && state[L] == ST_PAUSE && act[L] == A_CHAT) circles++;
		if (party[L] == conv_party) conv_alive = true;
		if (!cfg.life) continue;
		// a stop to talk, standing in a small circle: at most two such circles near the player at a time
		if (on_line && state[L] == ST_WALK && S.kind == 0 && tier[L] == TIER_FULL && circles_now < 2 && pkind[L] != PK_JOGGER && flee_t[L] <= 0.0f) {
			const float rem = dir[L] > 0 ? S.len - u[L] : u[L];
			if (rem > 8.0f && S.len - rem > 8.0f && rnd_of(L) < h / 150.0f) {
				state[L] = ST_PAUSE; pause_t[L] = 15.0f + 20.0f * rnd_of(L); act[L] = A_CHAT; v[L] = 0.0f; st.circles++; circles++;
			}
		}
		if (has_player) {
			const float dx = x[L] - pl_x, dz = z[L] - pl_z, d2 = dx * dx + dz * dz;
			if (d2 < near_d) { near_d = d2; near_l = L; }
		} else if (cfg.whole && near_l < 0) near_l = L;   // (tests without a player: any group)
	}
	circles_now = circles;
	if (!cfg.life) return;
	// the conversation: the group nearest the player (within 9 m) says a conversation's lines in turn, 3.2 s a line,
	// 20-40 s between conversations; which conversation fits the street they are in
	if (conv_party != 0 && !conv_alive) { conv_party = 0; conv_cd = 20.0f + 20.0f * rnd(); }
	if (conv_party == 0) {
		conv_cd -= h;
		if (conv_cd <= 0.0f && near_l >= 0) {
			const int zone = segs[seg[near_l]].zone;
			conv_party = party[near_l];
			conv_id = zone * 16 + (int)(hash32((uint32_t)conv_party * 2654435761u ^ (uint32_t)tick) % (uint32_t)std::max((int)conv_n[zone], 1));
			conv_line = 0; conv_t = 0.5f;
		}
		return;
	}
	conv_t -= h;
	if (conv_t > 0.0f) return;
	int speaker = -1, lead = -1;
	for (int j = 0; j < hi; j++) if (alive[j] && party[j] == conv_party) { if (leader[j] == j) lead = j; if (psize[j] > 0 && (int)slot[j] == conv_line % (int)psize[j]) speaker = j; }
	bool far_ = lead < 0;
	if (!far_ && has_player) { const float dx = x[lead] - pl_x, dz = z[lead] - pl_z; far_ = dx * dx + dz * dz > 14.0f * 14.0f; }
	if (far_ || speaker < 0 || conv_line >= (int)conv_lines) { conv_party = 0; conv_cd = 20.0f + 20.0f * rnd(); return; }
	event(E_SAY, id[speaker], conv_id * 64 + conv_line, 0.0f);
	st.lines_said++;
	act[speaker] = A_TALK; act_t[speaker] = 3.0f;
	conv_line++; conv_t = 3.2f;
}

} // namespace pc
