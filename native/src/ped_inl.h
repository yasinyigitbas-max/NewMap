// Small things the crowd's files share (ped_crowd.cpp, ped_goals.cpp, ped_party.cpp, ped_life.cpp).
#pragma once

#include "ped_crowd.h"

#include <algorithm>
#include <cmath>

namespace pc {

static inline float clampf(float v, float a, float b) { return v < a ? a : (v > b ? b : v); }
static inline float wrap_pi(float a) { a = std::fmod(a + 3.14159265f, 6.2831853f); if (a < 0.0f) a += 6.2831853f; return a - 3.14159265f; }
static inline uint32_t hash32(uint32_t h) { h ^= h >> 16; h *= 0x7feb352du; h ^= h >> 15; h *= 0x846ca68bu; h ^= h >> 16; return h; }
static inline int grid_ix(int gx, int gz) { return (int)(((uint32_t)(gx * 73856093) ^ (uint32_t)(gz * 19349663)) & 8191u); }

// people on 100 m of ONE pavement at the busiest hour: quiet street, ordinary, busy (high street, centre, strip), promenade, main road
static const float DENS[5] = { 2.5f, 4.0f, 9.0f, 12.0f, 5.0f };
// On a crossing people step out: at least this pace, a quarter faster than their own, and a jog when the light runs out.
// (The map's crossings are 13 to 29 m long and its signals give 15 s: at a stroll nobody would ever get over.)
static inline float cross_pace(float v0) { return std::max(v0 * 1.25f, 1.6f); }
static const float JOG = 3.2f;
static const float FLEE_V = 3.3f;

// the two files of a pavement lie this far either side of its middle; a person may go this far at most
static inline float file_off(const Seg &S) { return clampf(S.hw - RAD - 0.07f, 0.10f, 0.42f); }
static inline float edge_off(const Seg &S) { return std::max(S.hw - RAD, 0.10f); }

static inline bool seat_kind(int k) { return k == PL_BENCH || k == PL_PARK || k == PL_BEACH || k == PL_CAFE; }
static inline bool door_kind(int k) { return k == PL_HOME || k == PL_SHOP || k == PL_GATE; }

} // namespace pc
