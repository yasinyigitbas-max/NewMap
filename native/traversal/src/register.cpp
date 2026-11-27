// The traversal system in C++ (Yasin, 27 Nov 2026: "writing every code in c plus plus was a ground rule in the first
// place. make all the code c plus plus and make god damn sure nothing ever breaks").
// The rules of the port are in reports/TRAVERSAL JOB BOARD.md: the script version in traversal_lab/traversal is the
// reference; a layer is a line-for-line translation and replaces nothing until it gives the same numbers.
#include "trav_body.h"
#include "trav_character.h"
#include "trav_detector.h"
#include "trav_foot_place.h"
#include "trav_hand_place.h"
#include "trav_mods.h"
#include "trav_npc.h"
#include "trav_hold.h"
#include "trav_interact.h"
#include "trav_traverse.h"

#include <gdextension_interface.h>
#include <godot_cpp/core/class_db.hpp>
#include <godot_cpp/core/defs.hpp>
#include <godot_cpp/godot.hpp>

using namespace godot;

// The classes, for whichever library holds them: the lab's own (traversal_init, below), or the game's module, which
// compiles these sources in and calls this from its own start (native/src/register_types.cpp, with TRAV_IN_GAME).
void trav_register_classes() {
	GDREGISTER_CLASS(TravBody);
	GDREGISTER_CLASS(TravDetector);
	GDREGISTER_CLASS(TravArmOpen);
	GDREGISTER_CLASS(TravTrunkTurn);
	GDREGISTER_CLASS(TravHandHold);
	GDREGISTER_CLASS(TravFootOrient);
	GDREGISTER_CLASS(TravFingerGrip);
	GDREGISTER_CLASS(TravHandPlace);
	GDREGISTER_CLASS(TravFootPlace);
	GDREGISTER_CLASS(TravCharacter);
	GDREGISTER_CLASS(TravBodyFit);
	GDREGISTER_CLASS(TravNpcCharacter);
	GDREGISTER_CLASS(TravTraverse);
	GDREGISTER_CLASS(TravInteract);
	GDREGISTER_CLASS(TravHold);
}

#ifndef TRAV_IN_GAME
static void trav_init(ModuleInitializationLevel p_level) {
	if (p_level != MODULE_INITIALIZATION_LEVEL_SCENE) {
		return;
	}
	trav_register_classes();
}

static void trav_term(ModuleInitializationLevel p_level) {}

extern "C" {
GDExtensionBool GDE_EXPORT traversal_init(GDExtensionInterfaceGetProcAddress p_get_proc_address, const GDExtensionClassLibraryPtr p_library, GDExtensionInitialization *r_initialization) {
	GDExtensionBinding::InitObject init_obj(p_get_proc_address, p_library, r_initialization);
	init_obj.register_initializer(trav_init);
	init_obj.register_terminator(trav_term);
	init_obj.set_minimum_library_initialization_level(MODULE_INITIALIZATION_LEVEL_SCENE);
	return init_obj.init();
}
}
#endif // TRAV_IN_GAME
