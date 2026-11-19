// The places people go on the new map (plain C++, no engine types): doors of homes and shops, benches, bus stops,
// beach and park spots, cafe seats, the spots of beggars and night workers, the map's gates. Made once by the tool
// (class PeoplePlaces, tools/city/traffic/make_places.gd) from the pieces' own props and buildings and the interiors'
// shop list, saved as traffic/places.bin, read by the crowd (ped_crowd.h).
#pragma once

#include <cstdint>
#include <cstring>
#include <string>
#include <vector>

namespace pc {

enum { PL_HOME = 0, PL_SHOP = 1, PL_BEACH = 2, PL_PARK = 3, PL_GATE = 4, PL_BUS = 5, PL_BENCH = 6, PL_CAFE = 7, PL_BEG = 8, PL_NIGHT = 9,
	PL_SWIM = 10,   // a spot in the sea off a place on the beach (its `name` is that beach place's number): there one swims
	PL_KINDS = 11 };
enum { POSE_STAND = 0, POSE_SIT = 1, POSE_LIE = 2 };

// the shops' kinds, in the order of the interiors' list (assignment_all.json "kinds")
static const char *const SHOP_KINDS[] = { "bar", "office", "fast_food", "cleaners", "restaurant", "salon", "cafe", "store", "bakery", "pharmacy", "books", "clothes",
	"keys", "jewelry", "sport", "grocery", "shoes", "gallery", "corner_shop", "ice_cream", "souvenir", "venue", "gas" };
constexpr int N_SHOP_KINDS = 23;

struct Place {
	uint8_t kind = 0;
	uint8_t sub = 0;       // a shop's kind (SHOP_KINDS); a home: how many live there (1 a house, more a block of flats)
	uint8_t zone = 0;      // the pavement's zone where one leaves it (ped_crowd.h Seg::zone)
	uint8_t pose = 0;      // how one is there: POSE_*
	float x = 0, y = 0, z = 0, yaw = 0;   // where the person ends up (door, seat, spot) and which way he faces there
	int32_t seg = -1;      // the pavement he leaves for it
	float u = 0;           // ... and where along it
	float ax = 0, az = 0;  // that point on the pavement's line
	int32_t name = -1;     // a shop's name (PlaceData::names)
	int32_t lane = -1;     // a bus stop: the lane the bus stands in
	float lane_s = 0;      // ... and where along it
};

struct PlaceData {
	std::vector<Place> places;
	std::vector<std::string> names;

	void save(std::vector<uint8_t> &o) const {
		auto put = [&](const void *p, size_t n) { const uint8_t *b = (const uint8_t *)p; o.insert(o.end(), b, b + n); };
		const uint32_t magic = 0x31434C50u, np = (uint32_t)places.size(), nn = (uint32_t)names.size();   // "PLC1"
		put(&magic, 4); put(&np, 4); put(&nn, 4);
		for (const Place &p : places) {
			put(&p.kind, 1); put(&p.sub, 1); put(&p.zone, 1); put(&p.pose, 1);
			put(&p.x, 4); put(&p.y, 4); put(&p.z, 4); put(&p.yaw, 4); put(&p.seg, 4); put(&p.u, 4); put(&p.ax, 4); put(&p.az, 4); put(&p.name, 4); put(&p.lane, 4); put(&p.lane_s, 4);
		}
		for (const std::string &s : names) { const uint32_t l = (uint32_t)s.size(); put(&l, 4); put(s.data(), l); }
	}
	bool load(const uint8_t *d, size_t size) {
		size_t at = 0;
		auto get = [&](void *p, size_t n) { if (at + n > size) return false; std::memcpy(p, d + at, n); at += n; return true; };
		uint32_t magic = 0, np = 0, nn = 0;
		if (!get(&magic, 4) || magic != 0x31434C50u || !get(&np, 4) || !get(&nn, 4) || np > 200000u || nn > 200000u) return false;
		places.assign(np, Place());
		for (Place &p : places) {
			if (!(get(&p.kind, 1) && get(&p.sub, 1) && get(&p.zone, 1) && get(&p.pose, 1) && get(&p.x, 4) && get(&p.y, 4) && get(&p.z, 4) && get(&p.yaw, 4) && get(&p.seg, 4) && get(&p.u, 4) &&
						get(&p.ax, 4) && get(&p.az, 4) && get(&p.name, 4) && get(&p.lane, 4) && get(&p.lane_s, 4))) return false;
		}
		names.assign(nn, std::string());
		for (std::string &s : names) { uint32_t l = 0; if (!get(&l, 4) || at + l > size) return false; s.assign((const char *)d + at, l); at += l; }
		return true;
	}
};

} // namespace pc
