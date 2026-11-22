// mo::Motor's movement sets (Yasin, 24 Nov: "after you do these changes, we will have completed 1 set, we need at least 2
// more combination sets like this, with different animations that go well together ... there should be alternatives for
// every animation you used"). Set 0 is the approved one (festive's clips and Yasin's ledge clips). Sets 1 and 2 swap
// each clip, by its set-0 name, for one from Yasin's own library (library "yl", tools/people/make_ylib.gd) chosen as a
// different performance (tools/people/compare_clips.gd: not the same take under another name) that fits the others of
// its set (one character: the same build of walk, run, idle). A clip with no row keeps set 0's.
#include "mo_motor.h"

#include <cstring>

using namespace godot;
using namespace godot::mo;

namespace {
struct Row { const char *set0, *alt; };
#include "mo_sets_table.inc"
} // namespace

int Motor::style_count() { return 3; }

const char *Motor::style_clip(int p_style, const char *p_set0) {
	const Row *T = p_style == 1 ? SET1 : (p_style == 2 ? SET2 : nullptr);
	if (!T || !p_set0) return nullptr;
	for (int i = 0; T[i].set0; i++) if (std::strcmp(T[i].set0, p_set0) == 0) return T[i].alt;
	return nullptr;
}
