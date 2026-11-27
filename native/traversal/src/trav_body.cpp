#include "trav_body.h"

#include <godot_cpp/core/class_db.hpp>

using namespace godot;

void TravBody::_bind_methods() {
	ClassDB::bind_method(D_METHOD("native_version"), &TravBody::native_version);
}

String TravBody::native_version() const {
	return "traversal native, step 0";
}
