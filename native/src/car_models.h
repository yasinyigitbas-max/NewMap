// The cars of the traffic: which models there are, how large (measured from the meshes in vehicles/models/lod, 19 Nov
// 2026: half length = half the mesh's z size, half width = half its x size), and how common in ambient traffic (the
// old game's mix, traffic2_data.gd; 0 = never as ambient traffic: buses and the taxi have their own roles).
#pragma once

namespace cm {

struct CarModel {
	const char *id;
	float half_len, half_w, height;
	float weight;
	int like;   // whose physics (veh_dyn BASE) it uses: itself for the first twelve; the rebuilt newcomers borrow one
};

constexpr int N_MODELS = 19;
static const CarModel MODELS[N_MODELS] = {
	{ "stern_e", 2.58f, 1.04f, 1.41f, 18.0f, 0 },
	{ "volt_s", 2.16f, 0.86f, 1.46f, 12.0f, 1 },
	{ "stern_g", 2.14f, 0.94f, 1.52f, 20.0f, 2 },
	{ "volt_x", 2.14f, 0.94f, 1.52f, 14.0f, 3 },
	{ "sakura_t", 2.61f, 1.05f, 1.85f, 15.0f, 4 },
	{ "sakura", 1.92f, 0.91f, 1.45f, 11.0f, 5 },
	{ "van", 2.45f, 1.18f, 1.93f, 8.0f, 6 },
	{ "fiamma_r", 2.17f, 0.98f, 1.34f, 1.0f, 7 },
	{ "fiamma_gt", 2.20f, 0.94f, 1.38f, 1.0f, 8 },
	{ "taxi", 2.60f, 1.04f, 1.53f, 0.0f, 9 },
	{ "bus_city", 6.10f, 1.30f, 3.08f, 0.0f, 10 },   // (3.09 m wide as modelled; the old game drives it as 2.6 m)
	{ "bus_mini", 3.71f, 1.19f, 2.65f, 0.0f, 11 },
	// (27 Nov) the new models from Daniel Zhabotinsky's Sketchfab cars (CC BY 4.0, vehicles/CAR_CREDITS.md), rebuilt by
	// tools/vehicles_doors (sizes from their builds' info). Weight 0: not ambient traffic until their roles are wired
	{ "police_e", 2.61f, 1.04f, 1.56f, 0.0f, 0 },
	{ "police_x", 2.18f, 0.94f, 1.70f, 0.0f, 3 },
	{ "ambulance", 2.51f, 1.17f, 2.26f, 0.0f, 6 },
	{ "utility", 2.69f, 1.00f, 1.66f, 0.0f, 4 },
	{ "tow", 2.77f, 0.99f, 1.83f, 0.0f, 4 },
	{ "flatbed", 2.64f, 1.00f, 1.67f, 0.0f, 4 },
	{ "van_custom", 2.50f, 1.17f, 2.02f, 0.0f, 6 },
};

// paint colours, about as common as on a real street: white, black, silver, grey, dark blue, red, beige, dark green,
// light blue, maroon (the linear colours themselves: city_traffic_run.cpp PAINT)
constexpr int N_COLOURS = 10;
static const int PAINT_W[N_COLOURS] = { 18, 15, 15, 15, 9, 8, 5, 4, 6, 5 };   // (sum 100)
// a paint colour by its share of the street, from a hash (the same car keeps its colour)
inline int pick_colour(unsigned h) {
	int pc = (int)(h % 100u), col = 0;
	for (; col < N_COLOURS - 1; col++) { pc -= PAINT_W[col]; if (pc < 0) break; }
	return col;
}

} // namespace cm
