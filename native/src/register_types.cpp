// coronado_city: the new map's native module (GDExtension). Traffic and people in C++ (docs/TRAFFIC_PEOPLE_PORT.md).
// There is no script fall-back: the test app checks ClassDB.class_exists("CityNative") and says so when the module
// is missing.
#include "city_native.h"

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
