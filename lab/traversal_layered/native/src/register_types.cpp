// Lab B native module registration.
#include "clip_library.h"
#include "lab_camera.h"
#include "lab_player.h"
#include "pose_layer.h"

#include <gdextension_interface.h>
#include <godot_cpp/core/class_db.hpp>
#include <godot_cpp/core/defs.hpp>
#include <godot_cpp/godot.hpp>

using namespace godot;

static void init_module(ModuleInitializationLevel level) {
	if (level != MODULE_INITIALIZATION_LEVEL_SCENE) return;
	GDREGISTER_CLASS(lab::ClipLibrary);
	GDREGISTER_CLASS(lab::PoseLayer);
	GDREGISTER_CLASS(lab::LabCamera);
	GDREGISTER_CLASS(lab::LabPlayer);
}

static void uninit_module(ModuleInitializationLevel level) {}

extern "C" {
GDExtensionBool GDE_EXPORT layered_library_init(GDExtensionInterfaceGetProcAddress get_proc, GDExtensionClassLibraryPtr lib,
		GDExtensionInitialization *init) {
	GDExtensionBinding::InitObject obj(get_proc, lib, init);
	obj.register_initializer(init_module);
	obj.register_terminator(uninit_module);
	obj.set_minimum_library_initialization_level(MODULE_INITIALIZATION_LEVEL_SCENE);
	return obj.init();
}
}
