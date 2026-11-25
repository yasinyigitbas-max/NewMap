// Lab A (procedural): GDExtension entry.
#include "lab_camera.h"
#include "lab_player.h"
#include "lab_poser.h"

#include <gdextension_interface.h>
#include <godot_cpp/core/class_db.hpp>
#include <godot_cpp/core/defs.hpp>
#include <godot_cpp/godot.hpp>

using namespace godot;

static void init_labproc(ModuleInitializationLevel level) {
	if (level != MODULE_INITIALIZATION_LEVEL_SCENE) return;
	GDREGISTER_CLASS(LabPoser);
	GDREGISTER_CLASS(LabPlayer);
	GDREGISTER_CLASS(LabCamera);
}
static void uninit_labproc(ModuleInitializationLevel level) {}

extern "C" {
GDExtensionBool GDE_EXPORT labproc_library_init(GDExtensionInterfaceGetProcAddress p_get_proc_address,
		const GDExtensionClassLibraryPtr p_library, GDExtensionInitialization *r_initialization) {
	GDExtensionBinding::InitObject init_obj(p_get_proc_address, p_library, r_initialization);
	init_obj.register_initializer(init_labproc);
	init_obj.register_terminator(uninit_labproc);
	init_obj.set_minimum_library_initialization_level(MODULE_INITIALIZATION_LEVEL_SCENE);
	return init_obj.init();
}
}
