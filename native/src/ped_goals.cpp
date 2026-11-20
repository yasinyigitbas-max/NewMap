// The walking crowd: going somewhere. The shortest way over the walk graph, the choice of a place by the hour and the
// weather, the last metres off the pavement, what one does there (go in, sit, lie, drink, wait for the bus), and the
// way back. See ped_crowd.h.
#include "ped_crowd.h"

#include "ped_inl.h"

namespace pc {

void Crowd::set_places(const PlaceData &p) {
	places.clear();
	place_names = p.names;   // (the shops' names: the phone's map)
	place_from_file.assign(p.places.size(), -1);
	swim_of.clear();
	for (size_t fi = 0; fi < p.places.size(); fi++) {
		const Place &q = p.places[fi];
		if (q.seg < 0 || q.seg >= (int)segs.size() || segs[q.seg].np < 2 || segs[q.seg].kind != 0 || q.kind >= PL_KINDS) continue;
		place_from_file[fi] = (int32_t)places.size();
		places.push_back(q);
	}
	swim_of.assign(places.size(), -1);
	for (int k = 0; k < (int)places.size(); k++) {   // (a spot in the sea names its place on the beach by that one's number in the file)
		const Place &q = places[k];
		if (q.kind != PL_SWIM || q.name < 0 || q.name >= (int)place_from_file.size()) continue;
		const int b = place_from_file[q.name];
		if (b >= 0 && places[b].kind == PL_BEACH) swim_of[b] = k;
	}
	occ.assign(places.size(), -1); inside.assign(places.size(), 0); place_off.assign(places.size(), 0);
	for (auto &v_ : seg_places) v_.clear();
	place_grid.assign(64 * 64, std::vector<int32_t>());
	for (int k = 0; k < PL_KINDS; k++) n_place_kind[k] = 0;
	for (int k = 0; k < (int)places.size(); k++) {
		const Place &q = places[k];
		seg_places[q.seg].push_back(k);
		n_place_kind[q.kind]++;
		const int cx = std::min(std::max((int)std::floor(q.ax / 100.0f) + 32, 0), 63), cz = std::min(std::max((int)std::floor(q.az / 100.0f) + 32, 0), 63);
		place_grid[cz * 64 + cx].push_back(k);
	}
	reset(1);
}

// Opening hours by the kind of shop and the day of the week (0 = Monday): from, to (over 24 = past midnight), the day it is shut (-1 = none)
bool Crowd::shop_open(int p_place) const {
	static const float H[N_SHOP_KINDS][3] = {
		{ 16, 26, -1 },   // bar
		{ 9, 17, 6 },     // office (and shut on Saturday too, below)
		{ 9, 24, -1 },    // fast_food
		{ 8, 18, 6 },     // cleaners
		{ 11, 23, 0 },    // restaurant
		{ 9, 19, 0 },     // salon
		{ 7, 19, -1 },    // cafe
		{ 9, 20, -1 },    // store
		{ 6, 18, -1 },    // bakery
		{ 8, 21, -1 },    // pharmacy
		{ 10, 19, 6 },    // books
		{ 10, 19, 6 },    // clothes
		{ 9, 18, 6 },     // keys
		{ 10, 18, 6 },    // jewelry
		{ 9, 19, 6 },     // sport
		{ 7, 22, -1 },    // grocery
		{ 10, 19, 6 },    // shoes
		{ 11, 18, 0 },    // gallery
		{ 7, 23, -1 },    // corner_shop
		{ 11, 21, -1 },   // ice_cream
		{ 10, 19, -1 },   // souvenir
		{ 18, 25, 0 },    // venue
		{ 0, 24, -1 } };  // gas
	if (p_place < 0 || p_place >= (int)places.size() || places[p_place].kind != PL_SHOP) return true;
	const int k = std::min((int)places[p_place].sub, N_SHOP_KINDS - 1);
	const float hh = std::fmod(std::max(hour, 0.0f), 24.0f);
	if (hh + 24.0f < H[k][1]) return (int)H[k][2] != (weekday + 6) % 7 && !(k == 1 && (weekday + 6) % 7 >= 5);   // (past midnight: yesterday's evening)
	if ((int)H[k][2] == weekday || (k == 1 && weekday >= 5)) return false;
	return hh >= H[k][0] && hh < H[k][1];
}

// The shortest way over the walk graph from where walker i is to (to_seg, to_u). Sets its route and the way it walks
// on its own pavement. false = no way, or too long a one.
bool Crowd::plan(int i, int to_seg, float to_u) {
	st.plans++;
	if (to_seg < 0 || to_seg >= (int)segs.size() || segs[to_seg].np < 2) { st.plan_fails++; return false; }
	const Seg &S = segs[seg[i]];
	route_n[i] = 0; route_i[i] = 0;
	if (to_seg == seg[i]) {
		const int nd = to_u >= u[i] ? 1 : -1;
		if (nd != dir[i]) { dir[i] = (int8_t)nd; pass[i] = 0; }
		nxt[i] = -1;
		return true;
	}
	static thread_local std::vector<uint64_t> heap;
	heap.clear();
	std::fill(pl_cost.begin(), pl_cost.end(), BIG);
	std::fill(pl_from.begin(), pl_from.end(), -1);
	auto push = [&](int n, float c, int from) {
		if (c >= pl_cost[n]) return;
		pl_cost[n] = c; pl_from[n] = from;
		heap.push_back(((uint64_t)(c * 64.0f) << 20) | (uint64_t)n);
		std::push_heap(heap.begin(), heap.end(), std::greater<uint64_t>());
	};
	const float u0 = clampf(u[i], 0.0f, S.len);
	push(S.a, u0, -2); push(S.b, S.len - u0, -3);   // (-2 / -3: the start, leaving its own pavement at a / at b)
	const Seg &T = segs[to_seg];
	const float tu_ = clampf(to_u, 0.0f, T.len);
	float best = BIG; int best_n = -1;
	while (!heap.empty()) {
		std::pop_heap(heap.begin(), heap.end(), std::greater<uint64_t>());
		const uint64_t top = heap.back(); heap.pop_back();
		const int n = (int)(top & 0xFFFFFu);
		const float c = pl_cost[n];
		if ((float)(top >> 20) / 64.0f > c + 0.05f) continue;   // (an older, dearer entry)
		if (c >= best) break;
		if (n == T.a && c + tu_ < best) { best = c + tu_; best_n = n; }
		if (n == T.b && c + T.len - tu_ < best) { best = c + T.len - tu_; best_n = n; }
		for (int k : node_segs[n]) {
			const Seg &E = segs[k];
			if (k == seg[i] || k == to_seg || E.np < 2) continue;
			push(E.a == n ? E.b : E.a, c + E.len + (E.kind == 1 ? 12.0f : 0.0f), k);   // (a crossing costs the wait at its kerb too)
		}
	}
	if (best_n < 0) { st.plan_fails++; return false; }
	// back along the way found
	int16_t back[ROUTE_N];
	int nb = 0, n = best_n, first = -2;
	while (true) {
		const int f = pl_from[n];
		if (f < 0) { first = f; break; }
		if (nb >= ROUTE_N - 1) { st.plan_fails++; return false; }
		back[nb++] = (int16_t)f;
		n = segs[f].a == n ? segs[f].b : segs[f].a;
	}
	for (int k = 0; k < nb; k++) route[i][k] = back[nb - 1 - k];
	route[i][nb] = (int16_t)to_seg;
	route_n[i] = (int8_t)(nb + 1); route_i[i] = 0;
	const int nd = first == -2 ? -1 : 1;
	if (nd != dir[i]) { dir[i] = (int8_t)nd; pass[i] = 0; }
	nxt[i] = -1;
	return true;
}

// Where to? A kind of place by the hour and the weather, then one of that kind 120-520 m off that is open and free;
// failing that a spot on some pavement that far off.
void Crowd::pick_goal(int i) {
	goal[i] = -3;   // (if nothing is found: it wanders to the next corner and chooses again there)
	if (places.empty()) return;
	const bool day = hour >= sunrise && hour < sunset, wet = rain > 0.5f;
	float w[PL_KINDS] = { 0 };
	w[PL_SHOP] = wet ? 4.5f : 3.0f;
	w[PL_HOME] = hour >= 21.0f || hour < 5.0f ? 6.0f : (hour >= 17.0f ? 3.5f : 1.5f);
	w[PL_BENCH] = wet ? 0.0f : 1.2f;
	w[PL_PARK] = wet ? 0.0f : (day ? 1.0f : 0.1f);
	w[PL_BEACH] = wet ? 0.0f : (day ? 1.0f : 0.1f);
	w[PL_CAFE] = wet || hour < 7.0f || hour >= 22.0f ? 0.0f : 0.9f;
	w[PL_BUS] = 0.7f;
	w[PL_GATE] = 0.15f;
	float sum = 0.0f;
	for (int k = 0; k < PL_KINDS; k++) { if (n_place_kind[k] == 0) w[k] = 0.0f; sum += w[k]; }
	for (int t = 0; t < 8 && sum > 0.0f; t++) {
		float r = rnd_of(i) * sum;
		int kind = PL_SHOP;
		for (int k = 0; k < PL_KINDS; k++) { r -= w[k]; if (r <= 0.0f && w[k] > 0.0f) { kind = k; break; } }
		const float ang = rnd_of(i) * 6.2831853f, far_ = 120.0f + rnd_of(i) * 400.0f;
		const int cx = (int)std::floor((x[i] + std::sin(ang) * far_) / 100.0f) + 32, cz = (int)std::floor((z[i] + std::cos(ang) * far_) / 100.0f) + 32;
		if (cx < 0 || cz < 0 || cx >= 64 || cz >= 64) continue;
		const std::vector<int32_t> &lst = place_grid[cz * 64 + cx];
		if (lst.empty()) continue;
		const int n = (int)lst.size(), k0 = std::min((int)(rnd_of(i) * (float)n), n - 1);
		for (int q = 0; q < n; q++) {
			const int p = lst[(k0 + q) % n];
			const Place &P = places[p];
			if (P.kind != kind || place_off[p]) continue;
			if (seat_kind(kind) && occ[p] != -1) continue;
			if (kind == PL_SHOP && !shop_open(p)) continue;
			if (!cell_ok.empty() && (segs[P.seg].cell < 0 || !cell_ok[segs[P.seg].cell])) continue;
			const float dx = P.ax - x[i], dz = P.az - z[i], d2 = dx * dx + dz * dz;
			if (d2 < 60.0f * 60.0f || d2 > 600.0f * 600.0f) continue;
			if (!plan(i, P.seg, P.u)) break;
			goal[i] = p; goal_seg[i] = P.seg; goal_u[i] = P.u; enter_goal[i] = door_kind(kind) ? 1 : 0; stay_t[i] = 0.0f;
			if (seat_kind(kind)) occ[p] = id[i];
			return;
		}
	}
	// a spot on some pavement
	for (int t = 0; t < 6; t++) {
		const int k = std::min((int)(rnd_of(i) * (float)segs.size()), (int)segs.size() - 1);
		const Seg &S = segs[k];
		if (S.np < 2 || S.kind != 0 || S.len < 8.0f) continue;
		if (!cell_ok.empty() && (S.cell < 0 || !cell_ok[S.cell])) continue;
		const float dx = S.mx - x[i], dz = S.mz - z[i], d2 = dx * dx + dz * dz;
		if (d2 < 120.0f * 120.0f || d2 > 520.0f * 520.0f) continue;
		const float gu = 2.0f + rnd_of(i) * (S.len - 4.0f);
		if (!plan(i, k, gu)) continue;
		goal[i] = -2; goal_seg[i] = k; goal_u[i] = gu; enter_goal[i] = 0; stay_t[i] = 0.0f;
		return;
	}
}

void Crowd::free_place(int i) {
	if (goal[i] >= 0 && goal[i] < (int)occ.size() && occ[goal[i]] == id[i]) occ[goal[i]] = -1;
}

// At the place where it leaves the pavement for its goal: the last metres go straight to the door, the seat, the spot.
void Crowd::leave_line(int i) {
	const Place &P = places[goal[i]];
	bx[i] = x[i]; bz[i] = z[i];
	mode[i] = M_OFF; pass[i] = 0; state[i] = ST_WALK; blocked_t[i] = 0.0f;
	tx[i] = P.x; tz[i] = P.z; ty[i] = P.y; tyaw[i] = P.yaw;
	if (P.kind == PL_BUS) {   // people stand along the kerb by the sign, not on one spot
		const Seg &S = segs[P.seg];
		int h = 0; float ax, ay, az, sx, sz;
		at(S, P.u, 0.0f, h, ax, ay, az, sx, sz);
		const float along = ((float)(look[i] % 7u) - 3.0f) * 0.55f;
		tx[i] = P.ax + (P.x - P.ax) * 0.55f + sx * along; tz[i] = P.az + (P.z - P.az) * 0.55f + sz * along; ty[i] = ay;
	}
}

// It is there.
void Crowd::arrive(int i) {
	st.arrivals++;
	event(E_ARRIVE, id[i], goal[i], 0.0f);
	if (boarding[i]) {   // at the bus's door: a hand to it (0.8 s), then in (M_OFF counts it and takes him)
		door_t[i] = 0.8f; act[i] = A_DOOR; v[i] = 0.0f;
		return;
	}
	if (goal[i] < 0) {   // a spot on the pavement: it stands a moment (or as long as the game said), then chooses again
		state[i] = ST_PAUSE; pause_t[i] = stay_t[i] > 0.0f ? stay_t[i] : 0.3f + rnd_of(i) * 2.0f;
		goal[i] = -1; route_n[i] = 0;
		return;
	}
	const Place &P = places[goal[i]];
	mode[i] = M_STAY; v[i] = 0.0f; blocked_t[i] = 0.0f;
	const bool told = (flags[i] & F_SCRIPT) && stay_t[i] > 0.0f;   // (the game said how long)
	if (enter_goal[i]) { act[i] = A_DOOR; stay_t[i] = 1.2f; return; }   // it opens the door, then it is gone
	if (P.pose != POSE_STAND && free_at(i, tx[i], tz[i])) { const float sx = tx[i], sz = tz[i]; const float kx = px[i], kz = pz[i]; move_row(i, sx, sz); px[i] = kx; pz[i] = kz; }
	y[i] = ty[i];
	const bool wet = rain > 0.5f;
	float s = 30.0f;
	switch (P.kind) {
		case PL_BENCH: act[i] = A_SIT; s = 30.0f + rnd_of(i) * 90.0f; st.sat++; if (wet) s = 0.0f; break;
		case PL_PARK: act[i] = P.pose == POSE_SIT ? A_GSIT : A_NONE; s = 25.0f + rnd_of(i) * 65.0f; if (P.pose == POSE_SIT) st.sat++; if (wet) s = 0.0f; break;
		case PL_BEACH: act[i] = (look[i] >> 9) & 1u ? A_LIE_FRONT : ((look[i] >> 10) & 1u ? A_GSIT : A_LIE_BACK); s = 25.0f + rnd_of(i) * 65.0f; st.lay++; if (wet) s = 0.0f; break;
		case PL_CAFE: act[i] = A_DRINK; s = 60.0f + rnd_of(i) * 140.0f; st.drank++; if (wet) s = 0.0f; break;
		case PL_BUS: act[i] = A_WAIT; s = 240.0f; st.bus_waits++; break;
		case PL_SWIM: act[i] = A_NONE; s = 25.0f + rnd_of(i) * 45.0f; break;   // (in the sea: what it looks like is the game's, by how deep the water is)
		case PL_SHOP: act[i] = A_SHELTER; s = 900.0f; break;   // (at a shop's front without going in: out of the rain)
		default: act[i] = A_NONE; s = 5.0f + rnd_of(i) * 20.0f; break;
	}
	// (in the rain nobody sits or lies down even for a moment: he comes, sees the wet seat, and turns back)
	if (wet && (act[i] == A_SIT || act[i] == A_GSIT || act[i] == A_LIE_BACK || act[i] == A_LIE_FRONT || act[i] == A_DRINK)) act[i] = A_NONE;
	if (!told) stay_t[i] = s;
}

// At a place.
void Crowd::stay_step(int i, float h) {
	v[i] = 0.0f; still_t[i] = 0.0f;
	if (thin[i] && free_at(-1, x[i], z[i], i)) thin[i] = 0;
	yaw[i] += clampf(wrap_pi(((flags[i] & F_FACE) ? face_yaw[i] : tyaw[i]) - yaw[i]), -5.0f * h, 5.0f * h);
	const int g = goal[i];
	if (g < 0 || g >= (int)places.size()) { mode[i] = M_BACK; tx[i] = bx[i]; tz[i] = bz[i]; return; }
	const Place &P = places[g];
	if (flags[i] & F_FACE) return;   // (the game holds it: a talk)
	if (flags[i] & F_RESIDENT) {     // a beggar by day and in the dry, a night worker by night
		const bool on = P.kind == PL_BEG ? (hour >= 8.0f && hour < 20.0f && rain < 0.5f) : (hour >= 21.0f || hour < 5.0f);
		if (!on) kill(i, 5);
		return;
	}
	stay_t[i] -= h;
	if (enter_goal[i]) {
		if (stay_t[i] > 0.0f) return;
		if (P.kind == PL_SHOP) inside[g] = (int16_t)std::min((int)inside[g] + (int)psize[i], 30000);
		st.went_in++;
		if (leader[i] == i) for (int j = 0; j < hi; j++) if (alive[j] && j != i && leader[j] == i) { leader[j] = -1; party[j] = 0; st.went_in++; kill(j, 3); }   // its people go in with it
		party[i] = 0; leader[i] = -1;
		kill(i, 3);
		return;
	}
	if (P.kind == PL_BUS) {   // the bus is there: to its front door and in
		for (const Bus &b : buses) {
			if (!b.on || b.place != g || b.off > 0) continue;   // (first the people on it get off)
			boarding[i] = 1; mode[i] = M_OFF; act[i] = A_NONE; tx[i] = b.dx; tz[i] = b.dz; ty[i] = y[i];
			return;
		}
	}
	if (rain > 0.5f && (act[i] == A_SIT || act[i] == A_GSIT || act[i] == A_LIE_BACK || act[i] == A_LIE_FRONT || act[i] == A_DRINK)) stay_t[i] = 0.0f;   // nobody sits in the rain
	if (act[i] == A_SHELTER && rain < 0.3f) stay_t[i] = 0.0f;
	if (place_off[g] || flee_t[i] > 0.0f) stay_t[i] = 0.0f;
	if (stay_t[i] > 0.0f) return;
	if (rising(i, h)) return;   // (getting up takes a moment)
	// from the beach into the sea: half of the people there, once, by day and in the dry
	if (cfg.swim && P.kind == PL_BEACH && g < (int)swim_of.size() && swim_of[g] >= 0 && !swam[i] && ((look[i] >> 15) & 1u) && rain < 0.3f && hour >= 9.0f && hour < 19.0f && flee_t[i] <= 0.0f && !place_off[g]) {
		const int sw = swim_of[g];
		free_place(i);
		swam[i] = 1; goal[i] = sw; enter_goal[i] = 0; act[i] = A_NONE;
		mode[i] = M_OFF; tx[i] = places[sw].x; tz[i] = places[sw].z; ty[i] = places[sw].y; tyaw[i] = places[sw].yaw;
		return;
	}
	// up, and back to the pavement where it left it
	act[i] = A_NONE; mode[i] = M_BACK; tx[i] = bx[i]; tz[i] = bz[i];
	int hh = hint[i]; float ax, ay, az, sx, sz;
	at(segs[seg[i]], u[i], 0.0f, hh, ax, ay, az, sx, sz);
	ty[i] = ay;
	free_place(i);
	goal[i] = -1; route_n[i] = 0;
}

// Somebody comes out of a door (or off a bus, at its door) and walks to the pavement.
void Crowd::come_out(int place, bool from_bus, float dx_, float dz_) {
	if (place < 0 || place >= (int)places.size()) return;
	const Place &P = places[place];
	const float ox = from_bus ? dx_ : P.x, oz = from_bus ? dz_ : P.z;
	if (!cfg.whole) {   // never close in front of the camera
		const float dx = ox - cam_x, dz = oz - cam_z, dd = std::sqrt(dx * dx + dz * dz);
		if (dd > cfg.despawn_r - 10.0f) return;
		if (!from_bus && dd < 35.0f && (cam_fx != 0.0f || cam_fz != 0.0f) && dx * cam_fx + dz * cam_fz > 0.3f * dd) return;
	}
	if (!free_at(-1, ox, oz)) return;
	const int i = new_row(P.seg, P.u, rnd() < 0.5f ? 1 : -1, 0.0f, 0);
	if (i < 0) return;
	bx[i] = x[i]; bz[i] = z[i]; tx[i] = x[i]; tz[i] = z[i]; ty[i] = y[i];
	move_row(i, ox, oz); y[i] = py[i] = from_bus ? y[i] : P.y;
	mode[i] = M_BACK; v[i] = 0.0f;
	yaw[i] = pyaw[i] = std::atan2(bx[i] - ox, bz[i] - oz);
	if (!from_bus) {   // out of a shop: a moment in its doorway (the door), and one in three carries what he bought
		door_t[i] = 0.9f; act[i] = A_DOOR;
		carry[i] = (places[place].kind == PL_SHOP && rnd() < 0.34f) ? 1 : 0;
	}
	if (from_bus) { st.alighted++; event(E_ALIGHT, id[i], place, 0.0f); } else st.came_out++;
}

// Once a second: shops let people out again (all of them at closing time); a bus lets people off.
void Crowd::doors_step(float h) {
	(void)h;
	if (tick % 20 != 7) return;
	for (int p : door_cand) {
		if (places[p].kind != PL_SHOP || inside[p] <= 0) continue;
		if (shop_open(p) && rnd() > (float)inside[p] / 90.0f) continue;
		const int before = n_alive;
		come_out(p, false, 0.0f, 0.0f);
		if (n_alive > before) inside[p]--;
	}
	for (Bus &b : buses) {
		if (!b.on || b.off <= 0) continue;
		const int before = n_alive;
		come_out(b.place, true, b.dx, b.dz);
		if (n_alive > before) b.off--;
	}
}

void Crowd::bus_at(int p_place, bool p_on, float p_door_x, float p_door_z, int p_get_off) {
	for (size_t k = 0; k < buses.size(); k++) {
		if (buses[k].place != p_place) continue;
		if (p_on) { buses[k].dx = p_door_x; buses[k].dz = p_door_z; buses[k].on = 1; }
		else { buses[k] = buses.back(); buses.pop_back(); }
		return;
	}
	if (p_on && p_place >= 0 && p_place < (int)places.size() && places[p_place].kind == PL_BUS && buses.size() < 16)
		buses.push_back(Bus{ p_place, p_door_x, p_door_z, (int16_t)std::max(p_get_off, 0), 1 });
}

void Crowd::bench_off(int p_place, bool p_off) {
	if (p_place >= 0 && p_place < (int)place_off.size()) place_off[p_place] = p_off ? 1 : 0;
}

} // namespace pc
