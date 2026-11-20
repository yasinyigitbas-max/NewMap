// coronado_city: the new map's native module (GDExtension). Traffic and people in C++ (docs/TRAFFIC_PEOPLE_PORT.md).
// There is no script fall-back: the test app checks ClassDB.class_exists("CityNative") and says so when the module
// is missing.
#include "city_bike.h"
#include "city_car.h"
#include "city_game.h"
#include "city_hud.h"
#include "hand_grip.h"
#include "city_native.h"
#include "city_ped.h"
#include "city_traffic.h"
#include "anim_retarget.h"
#include "city_crowd.h"
#include "city_player.h"
#include "city_talk.h"
#include "people_bake.h"
#include "people_places.h"
#include "street_graph.h"
#include "foot_steps.h"
#include "city_ambience.h"

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
	GDREGISTER_CLASS(BikeReach);
	GDREGISTER_CLASS(HandGrip);
	GDREGISTER_CLASS(FootPlant);     // the player's feet on the ground under them      // the player's hands on a ledge's edge while he climbs     // the player's bicycle: the rider's feet and hands to the pedals and grips
	GDREGISTER_CLASS(CityBike);      // a bicycle the player rides (touch controls, the view wobbles, crashes throw him)
	GDREGISTER_CLASS(CityCar);
	GDREGISTER_CLASS(HudArrow);
	GDREGISTER_CLASS(HudMap);
	GDREGISTER_CLASS(CityHud);       // the HUD in play: money / clock, the arrow, the inventory, the phone (animated panels)
	GDREGISTER_CLASS(CityGame);      // the game's shell: text, clock, settings, saves, loading screen, menus, pause, game over       // a car to drive: the physical car (veh_dyn) on the engine's body
	GDREGISTER_CLASS(CityPed);       // one person with a real body: animation, and a body that balances, falls and gets up
	GDREGISTER_CLASS(StreetGraph);   // tool time: the streets as traffic and people need them, from the baked city
	GDREGISTER_CLASS(CityCrowd);     // the people of the map: who walks where and what they do, and how they are drawn
	GDREGISTER_CLASS(CityAmbience);  // the sound of the place: surf, bay, gulls, birds, crickets, wind, traffic hum, rain (B3)
	GDREGISTER_CLASS(FootSteps);     // footsteps by what the ground is made of (B16)
	GDREGISTER_CLASS(CityPlayer);    // a person to walk the city with (the test app's stand-in for the game's player)
	GDREGISTER_CLASS(CityTalk);      // talking to the people: the lines, who remembers the player, captions, choices, the recorded voices
	GDREGISTER_CLASS(AnimRetarget);  // tool time: the Quaternius animation library's clips fitted to the game's figure
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
