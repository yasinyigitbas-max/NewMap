// The cars of the traffic: which models there are, how large (measured from the meshes in vehicles/models/lod, 19 Nov
// 2026: half length = half the mesh's z size, half width = half its x size), and how common in ambient traffic (the
// old game's mix, traffic2_data.gd; 0 = never as ambient traffic: buses and the taxi have their own roles).
#pragma once

namespace cm {

struct CarModel {
	const char *id;
	float half_len, half_w, height;
	float weight;
};

constexpr int N_MODELS = 12;
static const CarModel MODELS[N_MODELS] = {
	{ "stern_e", 2.58f, 1.04f, 1.41f, 18.0f },
	{ "volt_s", 2.16f, 0.86f, 1.46f, 12.0f },
	{ "stern_g", 2.14f, 0.94f, 1.52f, 20.0f },
	{ "volt_x", 2.14f, 0.94f, 1.52f, 14.0f },
	{ "sakura_t", 2.61f, 1.05f, 1.85f, 15.0f },
	{ "sakura", 1.92f, 0.91f, 1.45f, 11.0f },
	{ "van", 2.45f, 1.18f, 1.93f, 8.0f },
	{ "fiamma_r", 2.17f, 0.98f, 1.34f, 1.0f },
	{ "fiamma_gt", 2.20f, 0.94f, 1.38f, 1.0f },
	{ "taxi", 2.60f, 1.04f, 1.53f, 0.0f },
	{ "bus_city", 6.10f, 1.30f, 3.08f, 0.0f },   // (3.09 m wide as modelled; the old game drives it as 2.6 m)
	{ "bus_mini", 3.71f, 1.19f, 2.65f, 0.0f },
};

} // namespace cm
