// coronado_city: the new map's native module (GDExtension). Traffic and people in C++ (docs/TRAFFIC_PEOPLE_PORT.md).
// There is no script fall-back: the test app checks ClassDB.class_exists("CityNative") and says so when the module
// is missing.
#include "city_car.h"
#include "city_native.h"
#include "city_ped.h"
#include "city_traffic.h"
#include "city_crowd.h"
#include "people_bake.h"
#include "people_places.h"
#include "street_graph.h"

#include <gdextension_interface.h>
#include <godot_cpp/core/class_db.hpp>
#include <godot_cpp/core/defs.hpp>
#include <godot_cpp/godot.hpp>

using namespace godot;

void initialize_coronado_city(ModuleInitializationLevel p_level) {
	if (p_level != MODULE_INITIALIZATION_LEVEL_SCENE) {
		return;
	}
	GDREGISTER_CLASS(CityNative);
	GDREGISTER_CLASS(CityTraffic);   // the traffic: core, drawing, parked cars
	GDREGISTER_CLASS(CityCar);       // a car to drive: the physical car (veh_dyn) on the engine's body
	GDREGISTER_CLASS(CityPed);       // one person with a real body: animation, and a body that balances, falls and gets up
	GDREGISTER_CLASS(StreetGraph);   // tool time: the streets as traffic and people need them, from the baked city
	GDREGISTER_CLASS(CityCrowd);     // the people of the map: who walks where and what they do, and how they are drawn
	GDREGISTER_CLASS(PeopleBake);    // tool time: the far figures of the crowd, every body posed once
	GDREGISTER_CLASS(PeoplePlaces);  // tool time: the places people go (doors, benches, bus stops ...), from the pieces and the shop list
}

void uninitialize_coronado_city(ModuleInitializationLevel p_level) {
}

extern "C" {
GDExtensionBool GDE_EXPORT coronado_city_init(GDExtensionInterfaceGetProcAddress p_get_proc_address, const GDExtensionClassLibraryPtr p_library, GDExtensionInitialization *r_initialization) {
	godot::GDExtensionBinding::InitObject init_obj(p_get_proc_address, p_library, r_initialization);
	init_obj.register_initializer(initialize_coronado_city);
	init_obj.register_terminator(uninitialize_coronado_city);
	init_obj.set_minimum_library_initialization_level(MODULE_INITIALIZATION_LEVEL_SCENE);
	return init_obj.init();
}
}
