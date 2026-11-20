// CityTalk: see city_talk.h. The flow, the chances and the times are the old game's (npc_talk.gd).
#include "perf_marks.h"
#include "city_talk.h"

#include "city_crowd.h"
#include "ped_places.h"

#include <godot_cpp/classes/audio_stream_ogg_vorbis.hpp>
#include <godot_cpp/classes/audio_stream_player3d.hpp>
#include <godot_cpp/classes/box_container.hpp>
#include <godot_cpp/classes/button.hpp>
#include <godot_cpp/classes/camera3d.hpp>
#include <godot_cpp/classes/canvas_layer.hpp>
#include <godot_cpp/classes/control.hpp>
#include <godot_cpp/classes/engine.hpp>
#include <godot_cpp/classes/file_access.hpp>
#include <godot_cpp/classes/font.hpp>
#include <godot_cpp/classes/h_box_container.hpp>
#include <godot_cpp/classes/input.hpp>
#include <godot_cpp/classes/input_event_key.hpp>
#include <godot_cpp/classes/json.hpp>
#include <godot_cpp/classes/label.hpp>
#include <godot_cpp/classes/line_edit.hpp>
#include <godot_cpp/classes/node3d.hpp>
#include <godot_cpp/classes/os.hpp>
#include <godot_cpp/classes/panel_container.hpp>
#include <godot_cpp/classes/resource_loader.hpp>
#include <godot_cpp/classes/style_box_flat.hpp>
#include <godot_cpp/classes/theme.hpp>
#include <godot_cpp/classes/v_box_container.hpp>
#include <godot_cpp/classes/viewport.hpp>
#include <godot_cpp/core/class_db.hpp>
#include <godot_cpp/variant/utility_functions.hpp>

#include <algorithm>
#include <cmath>

namespace godot {

namespace {
const float TALK_REACH = 2.0f, WALK_AWAY = 6.0f, LINE_S = 3.2f, WALK_M_PER_MIN = 80.0f;
const double SINGLE_P = 0.8, GROUP_P = 0.2, GROUP_CAP = 0.35, BAD_MOD = 0.1, CUT_P = 0.12, REFUSE_T6_P = 0.2, UNKNOWN_T3_P = 0.1;
const double GRUDGE_H = 24.0, HI_AGAIN_H = 10.0 / 60.0;
const int MAX_TOPICS = 6;
const char *const KINDS_EAT[] = { "cafe", "bakery", "restaurant", "ice_cream", "grocery", "fast_food", nullptr };
const char *const KINDS_JOB[] = { "cafe", "bakery", "grocery", "restaurant", "books", "souvenir", "pharmacy", "ice_cream", "store", "clothes", nullptr };
const char *const KINDS_SEE[] = { "gallery", "venue", "books", "souvenir", nullptr };
const char *const KINDS_CAFE[] = { "cafe", "bakery", "ice_cream", nullptr };

Dictionary line_of(const String &p_en, const String &p_tr) { Dictionary d; d["en"] = p_en; d["tr"] = p_tr; return d; }
} // namespace

CityCrowd *CityTalk::crowd_node() const { return crowd_id ? Object::cast_to<CityCrowd>(ObjectDB::get_instance(crowd_id)) : nullptr; }

bool CityTalk::has_player() const {
	const CityCrowd *c = crowd_node();
	const uint64_t pid = player_id ? player_id : (c ? c->get_player_id() : 0);
	return pid && Object::cast_to<Node3D>(ObjectDB::get_instance(pid));
}

Vector3 CityTalk::player_pos() const {
	const CityCrowd *c = crowd_node();
	const uint64_t pid = player_id ? player_id : (c ? c->get_player_id() : 0);
	Node3D *p = pid ? Object::cast_to<Node3D>(ObjectDB::get_instance(pid)) : nullptr;
	return p && p->is_inside_tree() ? p->get_global_position() : Vector3();
}

double CityTalk::randf() {
	rng ^= rng << 13; rng ^= rng >> 17; rng ^= rng << 5;
	return (double)(rng >> 8) / 16777216.0;
}

Dictionary CityTalk::pick(const Variant &p_arr) {
	const Array a = p_arr;
	if (a.is_empty()) return Dictionary();
	return a[(int)(randf() * a.size()) % a.size()];
}

Dictionary CityTalk::sys(const char *p_key) const {
	const Dictionary s = data.get("system", Dictionary());
	return s.get(p_key, Dictionary());
}

CityTalk::Mem &CityTalk::mem_of(int p_row) {
	const uint32_t k = crowd_node()->brain()->look[p_row];
	if (!memory.has(k)) memory[k] = Mem();
	return memory[k];
}

String CityTalk::fill(const String &p_s, const Dictionary &p_sub) {
	String s = p_s;
	const Array keys = p_sub.keys();
	for (int i = 0; i < keys.size(); i++) s = s.replace("[" + String(keys[i]) + "]", String(p_sub[keys[i]]));
	return s;
}

// a clip's file name: the line in small letters and digits, everything else an underscore
String CityTalk::slug(const String &p_en) {
	String o;
	const String lo = p_en.to_lower();
	bool gap = false;
	for (int i = 0; i < lo.length(); i++) {
		const char32_t c = lo[i];
		if ((c >= 'a' && c <= 'z') || (c >= '0' && c <= '9')) { if (gap && !o.is_empty()) o += "_"; o += String::chr(c); gap = false; }
		else gap = true;
	}
	if (o.length() > 120) o = o.left(48).rstrip("_") + "_" + o.md5_text().left(8);
	return o;
}

// what was said, for comparing: small letters, no marks, the short forms written out
String CityTalk::normalize(const String &p_s) {
	static const char *const EXPAND[][2] = { { "i'm", "i am" }, { "im", "i am" }, { "i'd", "i would" }, { "i'll", "i will" }, { "i've", "i have" }, { "you're", "you are" },
		{ "we're", "we are" }, { "they're", "they are" }, { "it's", "it is" }, { "that's", "that is" }, { "what's", "what is" }, { "where's", "where is" }, { "there's", "there is" },
		{ "here's", "here is" }, { "let's", "let us" }, { "don't", "do not" }, { "doesn't", "does not" }, { "didn't", "did not" }, { "can't", "can not" }, { "cannot", "can not" },
		{ "won't", "will not" }, { "isn't", "is not" }, { "aren't", "are not" }, { "wasn't", "was not" }, { "couldn't", "could not" }, { "wouldn't", "would not" },
		{ "shouldn't", "should not" }, { "you'll", "you will" }, { "we'll", "we will" }, { "okay", "ok" }, { "alright", "all right" }, { "0", "zero" }, { "1", "one" }, { "2", "two" },
		{ "3", "three" }, { "4", "four" }, { "5", "five" }, { "6", "six" }, { "7", "seven" }, { "8", "eight" }, { "9", "nine" }, { "10", "ten" }, { "12", "twelve" }, { "20", "twenty" } };
	String o;
	const String lo = p_s.to_lower();
	for (int i = 0; i < lo.length(); i++) {
		char32_t c = lo[i];
		if (c == 0x2019 || c == 0x2018 || c == '`') c = '\'';
		const bool keep = c == '\'' || (c >= '0' && c <= '9') || (c >= 'a' && c <= 'z') || c > 0x7f;
		o += keep ? String::chr(c) : String(" ");
	}
	PackedStringArray out;
	const PackedStringArray words = o.split(" ", false);
	for (int i = 0; i < words.size(); i++) {
		String w = words[i].trim_prefix("'").trim_suffix("'");
		if (w.is_empty()) continue;
		bool ex = false;
		for (const auto &e : EXPAND) if (w == e[0]) { w = e[1]; ex = true; break; }
		if (!ex && w.ends_with("'s")) w = w.trim_suffix("'s");
		out.push_back(w);
	}
	return String(" ").join(out);
}

// did he say the line: the words of one accepted form, or four in five of its words
bool CityTalk::heard(const String &p_said, const PackedStringArray &p_accept) {
	const String s = normalize(p_said);
	if (s.is_empty()) return false;
	const PackedStringArray sw = s.split(" ", false);
	for (int i = 0; i < p_accept.size(); i++) {
		const String a = normalize(p_accept[i]);
		if (a.is_empty()) continue;
		if (s == a || s.contains(a)) return true;
		const PackedStringArray aw = a.split(" ", false);
		int got = 0;
		for (int k = 0; k < aw.size(); k++) if (sw.has(aw[k])) got++;
		if (aw.size() > 0 && (double)got / aw.size() >= 0.8) return true;
	}
	return false;
}

// a templated line as the clips it is spoken with: cut into sentences, each sentence cut round the open values (a
// place's name has a clip of its own); the closed ones (direction, minutes, the hour, the weekday) stay in theirs
PackedStringArray CityTalk::segments(const String &p_tmpl, const Dictionary &p_sub) {
	static const char *const OPEN[] = { "[place]", "[npc]", "[city]", "[dog]", "[name]" };
	PackedStringArray out;
	auto push = [&](const String &p_t) {
		const String t = p_t.strip_edges().lstrip(",;:").strip_edges();
		if (!slug(t).is_empty()) out.push_back(t);
	};
	int at = 0;
	const int n = p_tmpl.length();
	while (at < n) {
		int e = at;
		while (e < n && p_tmpl[e] != '.' && p_tmpl[e] != '!' && p_tmpl[e] != '?') e++;
		while (e < n && (p_tmpl[e] == '.' || p_tmpl[e] == '!' || p_tmpl[e] == '?')) e++;
		const String sent = p_tmpl.substr(at, e - at);
		at = e;
		int pos = 0;
		while (true) {
			int best = -1; String key;
			for (const char *o : OPEN) { const int f = sent.find(o, pos); if (f >= 0 && (best < 0 || f < best)) { best = f; key = o; } }
			if (best < 0) break;
			push(fill(sent.substr(pos, best - pos), p_sub));
			push(String(p_sub.get(key.substr(1, key.length() - 2), "")));
			pos = best + key.length();
		}
		push(fill(sent.substr(pos), p_sub));
	}
	return out;
}

Ref<AudioStream> CityTalk::clip(const String &p_voice, const String &p_text) {
	const String s = slug(p_text);
	if (s.is_empty()) return Ref<AudioStream>();
	const String path = clips_dir + p_voice + "/" + s + ".ogg";
	if (clips.has(path)) return clips[path];
	Ref<AudioStream> st;
	if (ResourceLoader::get_singleton()->exists(path)) st = ResourceLoader::get_singleton()->load(path);
	if (st.is_null() && FileAccess::file_exists(path)) st = AudioStreamOggVorbis::load_from_file(path);
	clips[path] = st;
	return st;
}

// the recorded voice of a line, at the walker: the whole line's clip, or a templated line's clips in turn; a line
// with a part that was never recorded (a new place's name) is not spoken at all
void CityTalk::speak(int p_ch, int p_row, const Dictionary &p_line, const Dictionary &p_sub) {
	CityCrowd *c = crowd_node();
	if (!c || p_row < 0) return;
	const String v = c->walker_female(p_row) ? "f" : "m";
	const String tmpl = p_line.get("en", "");
	std::vector<Ref<AudioStream>> q;
	Ref<AudioStream> whole = clip(v, fill(tmpl, p_sub));
	if (whole.is_valid()) q.push_back(whole);
	else if (tmpl.contains("[")) {
		const PackedStringArray segs = segments(tmpl, p_sub);
		for (int i = 0; i < segs.size(); i++) {
			Ref<AudioStream> s = clip(v, segs[i]);
			if (s.is_null()) { q.clear(); break; }
			q.push_back(s);
		}
	}
	if (q.empty()) { n_silent++; return; }
	n_voiced++;
	if (!audio_on || !voice[p_ch]) return;
	voice[p_ch]->stop();
	queue[p_ch] = q;
	voice_walker[p_ch] = c->brain()->id[p_row];
}

void CityTalk::caption(const String &p_who, const String &p_en, const String &p_tr, double p_seconds) {
	cap_t = p_seconds;
	if (!cap_panel) return;
	cap_who->set_text(p_who); cap_who->set_visible(!p_who.is_empty());
	cap_en->set_text(p_en); cap_tr->set_text(p_tr);
	cap_panel->set_visible(true);
}

void CityTalk::say(int p_row, const Dictionary &p_line, const Dictionary &p_sub) {
	if (p_line.is_empty()) return;
	const String en = fill(p_line.get("en", ""), p_sub), tr_s = fill(p_line.get("tr", ""), p_sub);
	n_lines++;
	last_result = en;
	speak(0, p_row, p_line, p_sub);
	CityCrowd *c = crowd_node();
	if (c && p_row >= 0 && c->brain()->mode[p_row] == pc::M_STAY && (c->brain()->act[p_row] == pc::A_SIT || c->brain()->act[p_row] == pc::A_DRINK))
		c->speaking_for(c->brain()->id[p_row], 3.0);   // (from his seat: the seated talk, he stays seated)
	else if (c && p_row >= 0 && c->brain()->mode[p_row] != pc::M_LINE) c->brain()->set_act(c->brain()->id[p_row], pc::A_TALK, 3.0f);   // (one who walks on says it as he goes)
	const Dictionary sp = data.get("speaker", Dictionary());
	caption(sp.get("en", "Passer-by"), en, tr_s, LINE_S);
	emit_signal("npc_line", en, tr_s);
}

// ---------------------------------------------------------------- the flow
int CityTalk::find_target() const {
	const CityCrowd *c = crowd_node();
	if (!c || !c->brain() || !has_player()) return -1;
	const pc::Crowd *b = c->brain();
	const Vector3 p = player_pos();
	int best = -1; float bd = TALK_REACH * TALK_REACH;
	for (int i = 0; i < b->hi; i++) {
		if (!b->alive[i]) continue;
		const int m = b->mode[i];
		if (m != pc::M_LINE && m != pc::M_STAY && m != pc::M_FOLLOW && !(m == pc::M_HELD && c->talkable_actor(b->id[i]))) continue;   // (the shop's people: CityCrowd::talkable_actor)
		if (b->flee_t[i] > 0.0f || std::fabs(b->y[i] - p.y) > 2.0f) continue;
		const float dx = b->x[i] - p.x, dz = b->z[i] - p.z, d2 = dx * dx + dz * dz;
		if (d2 < bd) { bd = d2; best = i; }
	}
	return best >= 0 ? b->id[best] : -1;
}

String CityTalk::talk_to_nearest() {
	if (active >= 0) return "busy";
	const int id = find_target();
	return id >= 0 ? begin(id) : String();
}

String CityTalk::begin(int p_id) {
	CityCrowd *c = crowd_node();
	if (!c || !loaded) return String();
	if (active >= 0) return "busy";
	pc::Crowd *b = c->brain();
	const int row = b->find(p_id);
	if (row < 0) return String();
	Mem &m = mem_of(row);
	if (m.busy_until > now_h) { say(row, pick(data["busy"])); refuse(row); return "busy"; }
	int n = 1, lead = row;
	if (b->party[row] != 0) {
		n = 0;
		for (int j = 0; j < b->hi; j++) if (b->alive[j] && b->party[j] == b->party[row]) { n++; if (b->leader[j] == j) lead = j; }
		// a group that stands talking keeps it to itself one time in four (always the same groups)
		if (b->act[lead] == pc::A_CHAT && ((uint32_t)b->party[row] * 2654435761u >> 28) < 4u) { say(row, pick(data["private"])); refuse(row); m.busy_until = now_h + GRUDGE_H; return "private"; }
		if (b->pkind[row] == pc::PK_JOGGER) { say(row, sys("jogger")); return "jogger"; }
	}
	double p = n == 1 ? SINGLE_P : std::min(GROUP_P * (1.0 + 0.25 * (n - 2)), GROUP_CAP);
	const double h = c->get_hour();
	if (h < 7.0 || h >= 21.0 || c->get_rain() > 0.5) p -= BAD_MOD;
	const double roll = force_roll >= 0.0 ? force_roll : randf();
	const double yaw = std::atan2(player_pos().x - b->x[row], player_pos().z - b->z[row]);
	if (roll >= p || !c->talk_hold(p_id, true, yaw)) {      // (street life: a shop person is held too; the animator: the refusal has a body)
		say(row, pick(data[n > 1 ? "group_reject" : "reject"])); refuse(row); m.busy_until = now_h + GRUDGE_H; return "reject";
	}
	const bool again = m.met_until > now_h;
	start(row);
	if (again) say(row, sys("hi_again"));
	else say(row, sys(n > 1 ? "greet_group" : "greet"));
	offer(three_items(row));
	return again ? "hi_again" : "talk";
}

// he and his group stand, he faces the player
void CityTalk::start(int p_row) {
	pc::Crowd *b = crowd_node()->brain();
	active = b->id[p_row];
	held.clear(); held.push_back(active);
	done.clear(); options.clear(); selected = -1; saying = false;
	if (b->party[p_row] != 0)
		for (int j = 0; j < b->hi; j++)
			if (j != p_row && b->alive[j] && b->party[j] == b->party[p_row] && b->hold(b->id[j], true, (float)std::atan2(player_pos().x - b->x[j], player_pos().z - b->z[j]))) held.push_back(b->id[j]);
	mem_of(p_row).met++;
	n_talks++;
	player_body("talk_face", true, Vector3(b->x[p_row], b->y[p_row], b->z[p_row]));   // (the player turns to him and says hello)
	player_body("gesture", 0, 1.5);
	emit_signal("started", active);
}

void CityTalk::end(const String &p_outcome) {
	if (active < 0) return;
	const int a = active;
	CityCrowd *c = crowd_node();
	if (c && c->brain()) {
		pc::Crowd *b = c->brain();
		for (int id : held) c->talk_hold(id, false, 0.0);
		if (p_outcome == "bye" || p_outcome == "cut") b->set_act(a, pc::A_NOD, 1.3f);   // (a nod as they part, then he walks on)
		const int row = b->find(a);
		if (row >= 0) {
			Mem &m = mem_of(row);
			if (p_outcome == "cut") m.busy_until = now_h + GRUDGE_H;
			else if (p_outcome != "gone" && p_outcome != "phone") m.met_until = now_h + HI_AGAIN_H;
		}
	}
	close_say();
	player_body("talk_face", false, Vector3());
	if (p_outcome == "bye" || p_outcome == "cut") player_body("gesture", 1, 1.2);   // (the player nods too)
	active = -1; held.clear(); options.clear(); selected = -1;
	show_options();
	emit_signal("ended", a, p_outcome);
}

CityTalk::Opt CityTalk::make_item(const String &p_id, const String &p_kind, const Dictionary &p_say, const Dictionary &p_sub) {
	Opt o;
	o.id = p_id; o.kind = p_kind;
	o.en = fill(p_say.get("en", ""), p_sub); o.tr = fill(p_say.get("tr", ""), p_sub);
	o.accept.push_back(o.en);
	if (p_kind == "mission") o.accept.push_back("can you help me");
	return o;
}

CityTalk::Opt CityTalk::topic_item(const String &p_tid) {
	const Dictionary topics = data["topics"];
	const bool follow = p_tid.ends_with("F");
	Dictionary T = topics.get(follow ? p_tid.left(p_tid.length() - 1) : p_tid, Dictionary());
	if (follow) T = T.get("follow", Dictionary());
	const Array says = T.get("say", Array());
	Opt o;
	if (says.is_empty()) return o;
	const Dictionary s = says[0];
	o.id = p_tid; o.kind = follow ? "followup" : "topic"; o.en = s.get("en", ""); o.tr = s.get("tr", "");
	for (int i = 0; i < says.size(); i++) o.accept.push_back(Dictionary(says[i]).get("en", ""));
	return o;
}

// the nearest shop with a name, of some kinds or of any; `p_unused_only`: not one already asked about in this talk
int CityTalk::nearest_place(const Vector2 &p_at, const char *const *p_kinds, bool p_unused_only, float *r_d) const {
	const CityCrowd *c = crowd_node();
	const pc::Crowd *b = c->brain();
	int best = -1; float bd = 1e18f;
	for (int p = 0; p < (int)b->places.size(); p++) {
		const pc::Place &P = b->places[p];
		if (P.kind != pc::PL_SHOP || P.name < 0) continue;
		if (p_kinds) {
			bool fits = false;
			for (const char *const *k = p_kinds; *k; k++) if (P.sub < pc::N_SHOP_KINDS && String(pc::SHOP_KINDS[P.sub]) == *k) fits = true;
			if (!fits) continue;
		}
		const float dx = P.x - p_at.x, dz = P.z - p_at.y, d2 = dx * dx + dz * dz;
		if (d2 >= bd) continue;
		const String nm = c->place_name(p);
		if (nm.is_empty() || (p_unused_only && done.has("P:" + nm))) continue;
		bd = d2; best = p;
	}
	if (r_d) *r_d = std::sqrt(bd);
	return best;
}

// exactly three lines: a real place near by, the mission (or a hint), one small-talk topic
std::vector<CityTalk::Opt> CityTalk::three_items(int p_row) {
	const CityCrowd *c = crowd_node();
	const pc::Crowd *b = c->brain();
	const Dictionary X = data["three"];
	const Vector2 at(b->x[p_row], b->z[p_row]);
	std::vector<Opt> items;
	const int np = nearest_place(at, nullptr, true, nullptr);
	if (np < 0) items.push_back(topic_item("T4"));
	else {
		Dictionary sub; sub["place"] = c->place_name(np);
		Opt o = make_item("P:" + c->place_name(np), "place", Dictionary(X["P"])["say"], sub);
		o.place = c->place_name(np); o.goal = Vector2(b->places[np].x, b->places[np].z); o.has_goal = true;
		items.push_back(o);
	}
	if (has_mission) {
		String lo = mission_en.trim_suffix(".");
		if (lo.length() > 1 && lo.substr(1, 1) == lo.substr(1, 1).to_lower()) lo = lo.substr(0, 1).to_lower() + lo.substr(1);
		Dictionary sub; sub["obj"] = lo; sub["obj_tr"] = (mission_tr.is_empty() ? mission_en : mission_tr).trim_suffix(".");
		Opt o = make_item("M", "mission", Dictionary(X["M"])["say"], sub);
		o.goal = Vector2(mission_at.x, mission_at.z); o.has_goal = true;
		items.push_back(o);
	} else {
		const String hk = X.has(hint) ? hint : String("HV");
		const int hp = nearest_place(at, hk == "HJ" ? KINDS_JOB : (hk == "HF" ? KINDS_EAT : KINDS_SEE), false, nullptr);
		Opt o = make_item("H:" + hk, "hint", Dictionary(X[hk])["say"], Dictionary());
		o.hint = hk;
		if (hp >= 0) { o.place = c->place_name(hp); o.goal = Vector2(b->places[hp].x, b->places[hp].z); o.has_goal = true; }
		items.push_back(o);
	}
	PackedStringArray pool;
	static const char *const SMALL[] = { "T1", "T5", "T5D", "T6", "T3", "T4C" };
	for (const char *t : SMALL) if (!done.has(t)) pool.push_back(t);
	if (pool.is_empty()) for (const char *t : SMALL) pool.push_back(t);
	const String tid = !force_small.is_empty() ? force_small : pool[(int)(randf() * pool.size()) % pool.size()];
	items.push_back(topic_item(tid));
	return items;
}

void CityTalk::offer(const std::vector<Opt> &p_items) {
	options.clear();
	for (const Opt &o : p_items) if (!o.id.is_empty() && (int)options.size() < MAX_OPTS) options.push_back(o);
	selected = -1;
	show_options();
	emit_signal("choices_offered", get_options());
}

Array CityTalk::get_options() const {
	Array out;
	for (const Opt &o : options) { Dictionary d; d["id"] = o.id; d["kind"] = o.kind; d["en"] = o.en; d["tr"] = o.tr; out.push_back(d); }
	return out;
}

void CityTalk::choose(int p_index) {
	if (active < 0 || p_index < 0 || p_index >= (int)options.size()) return;
	selected = p_index; tries = 0;
	emit_signal("say_requested", options[p_index].en, options[p_index].tr);
	if (!need_say) { said(true, "auto"); return; }
	open_say();
}

void CityTalk::say_typed(const String &p_text) {
	if (active < 0 || selected < 0) return;
	if (p_text.strip_edges().is_empty()) said(true, "skipped");
	else said(heard(p_text, options[selected].accept), "typed");
}

void CityTalk::back() {
	if (!saying) return;
	close_say(); selected = -1;
	show_options();
}

// he said it (or not): three tries, then the walker gives up on him
void CityTalk::said(bool p_ok, const String &p_how) {
	if (active < 0 || selected < 0 || selected >= (int)options.size()) return;
	if (p_ok) {
		const Opt o = options[selected];
		close_say();
		player_body("gesture", 0, 2.5);   // (the player says his line: his body talks)
		emit_signal("listen_result", true, MAX_TRIES - tries, p_how);
		answer(o);
		return;
	}
	tries++;
	emit_signal("listen_result", false, MAX_TRIES - tries, p_how);
	if (tries >= MAX_TRIES) {
		const int row = crowd_node() ? crowd_node()->brain()->find(active) : -1;
		close_say();
		say(row, sys("not_understood"));
		end("missed");
		return;
	}
	if (say_status) say_status->set_text(vformat("Try again (%d left)  ·  Tekrar dene", MAX_TRIES - tries));
	if (say_edit) say_edit->clear();
	Object *speech = speech_obj();
	if (listening || (speech && bool(speech->call("isAvailable")))) listen();
}

void CityTalk::answer(const Opt &p_o) {
	CityCrowd *c = crowd_node();
	const int row = c ? c->brain()->find(active) : -1;
	if (row < 0) { end("gone"); return; }
	options.clear(); show_options();
	if (p_o.kind == "place" || p_o.kind == "mission" || p_o.kind == "hint") {
		answer_three(row, p_o);
		done.push_back(p_o.id);
	} else {
		if (p_o.id == "T7") { say(row, pick(Dictionary(Dictionary(data["topics"])["T7"])["ans"])); end("bye"); return; }
		answer_topic(row, p_o.id);
		if (!done.has(p_o.id)) done.push_back(p_o.id);
	}
	const double cut = force_cut >= 0.0 ? force_cut : randf();
	if (done.size() >= MAX_TOPICS || (done.size() >= 2 && cut < CUT_P)) { say(row, pick(data["cut"])); end("cut"); return; }
	std::vector<Opt> next;
	if (p_o.kind == "topic" && p_o.id == "T1") next.push_back(topic_item("T1F"));
	else next = three_items(row);
	next.push_back(topic_item("T7"));
	offer(next);
}

// which way, as the player sees it
String CityTalk::dir_word(const Vector2 &p_d) const {
	Vector2 f(0, -1);
	Camera3D *cam = get_viewport() ? get_viewport()->get_camera_3d() : nullptr;
	if (cam) { const Vector3 z = -cam->get_global_transform().basis.get_column(2); if (Vector2(z.x, z.z).length() > 0.01f) f = Vector2(z.x, z.z).normalized(); }
	const Vector2 n = p_d.normalized();
	const float dot = f.dot(n), cr = f.x * n.y - f.y * n.x;
	if (dot > 0.7f) return "straight";
	if (dot < -0.6f) return "behind";
	return cr > 0.0f ? "right" : "left";
}

void CityTalk::answer_three(int p_row, const Opt &p_o) {
	const pc::Crowd *b = crowd_node()->brain();
	const Dictionary X = data["three"], T3 = Dictionary(data["topics"])["T3"];
	if (!p_o.has_goal) { say(p_row, pick(T3["ans_unknown"])); return; }
	const Vector2 d(p_o.goal.x - b->x[p_row], p_o.goal.y - b->z[p_row]);
	const String dw = dir_word(d);
	Dictionary sub;
	sub["place"] = p_o.place; sub["n"] = String::num_int64(std::max(1, (int)std::lround(d.length() / WALK_M_PER_MIN)));
	sub["dir"] = Dictionary(Dictionary(T3["dir"])[dw])["en"]; sub["dir_tr"] = Dictionary(X["dir_tr"])[dw];
	if (p_o.kind == "place") {
		say(p_row, pick(Dictionary(X["P"])[d.length() < 60.0f ? "ans_close" : "ans"]), sub);
	} else if (p_o.kind == "mission") {
		if (d.length() < 40.0f) { say(p_row, pick(T3["ans_here"])); return; }
		const Array go = Dictionary(X["dir_go"])[dw];
		sub["dir"] = go[0]; sub["dir_tr"] = go[1];
		say(p_row, pick(Dictionary(X["M"])["ans"]), sub);
	} else {
		if (p_o.place.is_empty()) { say(p_row, pick(T3["ans_unknown"])); return; }
		if (p_o.hint != "HJ") { const String t = sub["dir_tr"]; sub["dir_tr"] = t.substr(0, 1).to_upper() + t.substr(1); }
		say(p_row, pick(Dictionary(X[p_o.hint])["ans"]), sub);
	}
}

// what he is doing: by his group, how he is there, where he is going
String CityTalk::doing(int p_row, Dictionary &r_sub) const {
	const CityCrowd *c = crowd_node();
	const pc::Crowd *b = c->brain();
	if (b->party[p_row] != 0 && b->pkind[p_row] == pc::PK_SAILORS) return "navy";
	const int a = b->act[p_row];
	if (b->mode[p_row] == pc::M_STAY && (a == pc::A_SIT || a == pc::A_GSIT || a == pc::A_LIE_BACK || a == pc::A_LIE_FRONT || a == pc::A_DRINK)) return "sitting";
	const int g = b->goal[p_row];
	if (g >= 0 && g < (int)b->places.size()) {
		switch (b->places[g].kind) {
			case pc::PL_HOME: return "home";
			case pc::PL_SHOP: { const String nm = c->place_name(g); if (nm.is_empty()) return "home"; r_sub["place"] = nm; return "shop"; }
			case pc::PL_BEACH: return "beach";
			case pc::PL_PARK: return "park";
			case pc::PL_BENCH: case pc::PL_CAFE: return "sitting";
			default: break;
		}
	}
	return "home";
}

void CityTalk::answer_topic(int p_row, const String &p_tid) {
	CityCrowd *c = crowd_node();
	const pc::Crowd *b = c->brain();
	const Dictionary T = data["topics"];
	const Vector2 at(b->x[p_row], b->z[p_row]);
	Dictionary sub;
	if (p_tid == "T1") say(p_row, pick(Dictionary(T["T1"])["ans"]));
	else if (p_tid == "T1F") say(p_row, pick(Dictionary(Dictionary(T["T1"])["follow"])["ans"]));
	else if (p_tid == "T3") {   // where is the beach: the nearest place on the sand
		const Dictionary T3 = T["T3"];
		const double uk = force_unknown >= 0.0 ? force_unknown : randf();
		int best = -1; float bd = 1e18f;
		for (int p = 0; p < (int)b->places.size(); p++) if (b->places[p].kind == pc::PL_BEACH) { const float dx = b->places[p].x - at.x, dz = b->places[p].z - at.y; if (dx * dx + dz * dz < bd) { bd = dx * dx + dz * dz; best = p; } }
		if (uk < UNKNOWN_T3_P || best < 0) { say(p_row, pick(T3["ans_unknown"])); return; }
		const Vector2 d(b->places[best].x - at.x, b->places[best].z - at.y);
		if (d.length() < 40.0f) { say(p_row, pick(T3["ans_here"])); return; }
		const String dw = dir_word(d);
		sub["dir"] = Dictionary(Dictionary(T3["dir"])[dw])["en"]; sub["dir_tr"] = Dictionary(Dictionary(T3["dir"])[dw])["tr"];
		sub["n"] = String::num_int64(std::max(1, (int)std::lround(d.length() / WALK_M_PER_MIN)));
		say(p_row, pick(T3["ans"]), sub);
	} else if (p_tid == "T4" || p_tid == "T4C") {
		float d = 0.0f;
		const int np = nearest_place(at, p_tid == "T4C" ? KINDS_CAFE : nullptr, false, &d);
		if (np < 0 || (p_tid == "T4C" && d > 1200.0f)) { say(p_row, pick(Dictionary(T[p_tid])["ans_none"])); return; }
		sub["place"] = c->place_name(np); sub["n"] = String::num_int64(std::max(1, (int)std::lround(d / WALK_M_PER_MIN)));
		say(p_row, pick(Dictionary(T[p_tid])["ans"]), sub);
	} else if (p_tid == "T5") {
		const double h = c->get_hour();
		int hh = (int)h; const int mm = (int)((h - hh) * 60.0);
		int q = (int)std::lround(mm / 15.0) * 15;
		if (q == 60) { q = 0; hh++; }
		sub["h"] = String::num_int64((hh + 11) % 12 + 1); sub["h1"] = String::num_int64((hh + 12) % 12 + 1);
		say(p_row, pick(Dictionary(T["T5"])[vformat("ans_%d", q)]), sub);
	} else if (p_tid == "T5D") {
		const Array wd = data["weekdays"];
		const Dictionary w = wd[((c->get_weekday() % 7) + 7) % 7];
		sub["weekday"] = w["en"]; sub["weekday_tr"] = w["tr"];
		say(p_row, pick(Dictionary(T["T5D"])["ans"]), sub);
	} else if (p_tid == "T6") {
		const Dictionary T6 = T["T6"];
		const double rf = force_refuse >= 0.0 ? force_refuse : randf();
		if (rf < REFUSE_T6_P) { say(p_row, pick(T6["refuse"])); return; }
		const String k = doing(p_row, sub);
		say(p_row, pick(T6.has(k) ? T6[k] : T6["home"]), sub);
	}
}

// The player's body in a talk (CityPlayer: talk_face, gesture), by name, as freeze_player does
void CityTalk::player_body(const char *p_method, const Variant &p_a, const Variant &p_b) {
	const CityCrowd *c = crowd_node();
	const uint64_t pid = player_id ? player_id : (c ? c->get_player_id() : 0);
	Object *p = pid ? ObjectDB::get_instance(pid) : nullptr;
	if (p && p->has_method(p_method)) p->call(p_method, p_a, p_b);
}

// He will not talk: he stops a moment, turns to the player, shakes his head, and goes on (a jogger runs on)
void CityTalk::refuse(int p_row) {
	CityCrowd *c = crowd_node();
	if (!c || !c->brain() || p_row < 0 || !has_player()) return;
	pc::Crowd *b = c->brain();
	b->face_yaw[p_row] = (float)std::atan2(player_pos().x - b->x[p_row], player_pos().z - b->z[p_row]);
	b->flags[p_row] |= pc::F_FACE;
	b->set_act(b->id[p_row], pc::A_NO, 1.8f);
}

// ---------------------------------------------------------------- saying the line
void CityTalk::freeze_player(bool p_on) {
	const CityCrowd *c = crowd_node();
	const uint64_t pid = player_id ? player_id : (c ? c->get_player_id() : 0);
	Object *p = pid ? ObjectDB::get_instance(pid) : nullptr;
	if (p && p->has_method("set_frozen")) p->call("set_frozen", p_on);
}

void CityTalk::open_say() {
	saying = true;
	Object *speech = speech_obj();
	const bool mic = speech && bool(speech->call("isAvailable"));
	if (say_panel) {
		say_en->set_text(options[selected].en); say_tr->set_text(options[selected].tr);
		say_status->set_text(mic ? String::utf8("Listening…  ·  Dinliyorum…") : String::utf8("Type it and press Enter, or skip  ·  Yaz ve Enter'a bas, ya da geç"));
		say_edit->clear();
		say_panel->set_visible(true);
		if (opt_box) opt_box->set_visible(false);
		if (!mic) say_edit->grab_focus();
	}
	freeze_player(true);
	if (mic) listen();
}

void CityTalk::close_say() {
	Object *speech = speech_obj();
	if (listening && speech) speech->call("stopListening");
	listening = false;
	if (!saying) return;
	saying = false;
	if (say_panel) { say_panel->set_visible(false); if (say_edit->is_inside_tree()) say_edit->release_focus(); }
	freeze_player(false);
}

void CityTalk::listen() {
	Object *speech = speech_obj();
	if (!speech) return;
	if (OS::get_singleton()->get_name() == "Android") OS::get_singleton()->request_permission("android.permission.RECORD_AUDIO");
	speech->call("startListening", "en-US");
	listening = true;
	if (say_status && tries == 0) say_status->set_text(String::utf8("Listening…  ·  Dinliyorum…"));
}

void CityTalk::_on_speech_result(const String &p_text, const PackedStringArray &p_alt) {
	if (!saying || selected < 0) return;
	listening = false;
	bool ok = heard(p_text, options[selected].accept);
	for (int i = 0; i < p_alt.size() && !ok; i++) ok = heard(p_alt[i], options[selected].accept);
	said(ok, "speech");
}

void CityTalk::_on_speech_error(int p_code, const String &p_msg) {
	if (!saying) return;
	listening = false;
	if (say_status) say_status->set_text(String::utf8("The microphone heard nothing: type it, or skip  ·  Mikrofon duymadı: yaz ya da geç"));
	if (say_edit) say_edit->grab_focus();
}

void CityTalk::_on_interact() { if (active < 0) talk_to_nearest(); }
void CityTalk::_on_talk_pressed() { talk_to_nearest(); }
void CityTalk::_on_option(int p_index) { if (!saying) choose(p_index); }
void CityTalk::_on_skip() { say_typed(String()); }
void CityTalk::_on_back() { back(); }
void CityTalk::_on_typed(const String &p_text) { say_typed(p_text); }

void CityTalk::_input(const Ref<InputEvent> &p_event) {
	if (active < 0 || saying) return;
	const InputEventKey *k = Object::cast_to<InputEventKey>(p_event.ptr());
	if (!k || !k->is_pressed() || k->is_echo()) return;
	const int n = (int)k->get_keycode() - (int)KEY_1;
	if (n >= 0 && n < (int)options.size()) choose(n);
}

// ---------------------------------------------------------------- the groups' own talk (the crowd's event E_SAY)
void CityTalk::_on_crowd_event(int p_type, int p_id, int p_aux, double p_f) {
	if (p_type == 16) {   // the player shoved him: a grudge; a talk with him is over
		CityCrowd *cc = crowd_node();
		const int r = cc && cc->brain() ? cc->brain()->find(p_id) : -1;
		if (r >= 0) mem_of(r).busy_until = now_h + GRUDGE_H;
		if (active == p_id) end("cut");
		return;
	}
	if (p_type != pc::E_SAY || !loaded) return;
	CityCrowd *c = crowd_node();
	if (!c) return;
	pc::Crowd *b = c->brain();
	const int row = b->find(p_id);
	if (row < 0) return;
	const int conv = p_aux / 64, line = p_aux % 64, zone = (conv / 16) % 5, idx = conv % 16, kind = b->pkind[row];
	std::vector<int> fit;
	for (int k = 0; k < (int)convs.size(); k++) if (((convs[k].zones >> zone) & 1) && (convs[k].kinds == 0 || ((convs[k].kinds >> kind) & 1))) fit.push_back(k);
	if (fit.empty()) return;
	const Conv &cv = convs[fit[idx % (int)fit.size()]];
	if (line >= cv.lines.size()) { b->conv_end(); return; }   // (this conversation is shorter: it is over)
	const Dictionary l = cv.lines[line];
	n_conv_lines++;
	const Vector3 p = player_pos();
	const float dx = b->x[row] - p.x, dz = b->z[row] - p.z, d = std::sqrt(dx * dx + dz * dz);
	if (!has_player() || d < 25.0f) speak(1, row, l, Dictionary());
	if (active < 0 && (!has_player() || d < 8.0f)) caption(String(), l.get("en", ""), l.get("tr", ""), LINE_S);
}

// ---------------------------------------------------------------- the screen
void CityTalk::show_options() {
	if (!opt_box) return;
	for (int i = 0; i <= MAX_OPTS; i++) {
		const bool on = active >= 0 && i < (int)options.size();
		opt_btn[i]->set_visible(on);
		if (on) opt_btn[i]->set_text(String::num_int64(i + 1) + "   " + options[i].en + "\n      " + options[i].tr);
	}
	opt_box->set_visible(active >= 0 && !options.empty() && !saying);
}

void CityTalk::_on_resize() {
	if (!layer || !get_viewport()) return;
	const Vector2 vs = get_viewport()->get_visible_rect().size;
	const float s = std::max(vs.y / 720.0f, 0.4f);
	layer->set_scale(Vector2(s, s));
	root->set_position(Vector2());
	root->set_size(vs / s);
}

void CityTalk::build_ui() {
	layer = memnew(CanvasLayer); layer->set_layer(20); add_child(layer);
	root = memnew(Control); root->set_mouse_filter(Control::MOUSE_FILTER_IGNORE); layer->add_child(root);
	Ref<Theme> th; th.instantiate();
	Ref<Font> font = ResourceLoader::get_singleton()->exists("res://ui/fonts/Nunito.ttf") ? Ref<Font>(ResourceLoader::get_singleton()->load("res://ui/fonts/Nunito.ttf")) : Ref<Font>();
	if (font.is_valid()) th->set_default_font(font);
	th->set_default_font_size(20);
	root->set_theme(th);
	auto box = [](const Color &p_bg, const Color &p_edge, int p_margin) {
		Ref<StyleBoxFlat> sb; sb.instantiate();
		sb->set_bg_color(p_bg); sb->set_border_color(p_edge); sb->set_border_width_all(1);
		sb->set_corner_radius_all(14); sb->set_content_margin_all((float)p_margin);
		return sb;
	};
	const Color glass(0.06f, 0.07f, 0.10f, 0.86f), edge(1, 1, 1, 0.16f), accent(1.0f, 0.80f, 0.36f), dim(0.80f, 0.84f, 0.90f, 0.85f);
	auto label = [&](Control *p_parent, int p_size, const Color &p_col) {
		Label *l = memnew(Label);
		l->set_autowrap_mode(TextServer::AUTOWRAP_WORD_SMART);
		l->add_theme_font_size_override("font_size", p_size); l->add_theme_color_override("font_color", p_col);
		l->set_mouse_filter(Control::MOUSE_FILTER_IGNORE);
		p_parent->add_child(l);
		return l;
	};
	auto button = [&](Control *p_parent, const String &p_text) {
		Button *bt = memnew(Button);
		bt->set_text(p_text); bt->set_text_alignment(HORIZONTAL_ALIGNMENT_LEFT); bt->set_focus_mode(Control::FOCUS_NONE);
		bt->add_theme_stylebox_override("normal", box(glass, edge, 12));
		bt->add_theme_stylebox_override("hover", box(Color(0.12f, 0.14f, 0.20f, 0.92f), accent, 12));
		bt->add_theme_stylebox_override("pressed", box(Color(0.20f, 0.17f, 0.10f, 0.95f), accent, 12));
		p_parent->add_child(bt);
		return bt;
	};
	// what is said: a box at the top
	cap_panel = memnew(PanelContainer);
	cap_panel->add_theme_stylebox_override("panel", box(glass, edge, 16));
	cap_panel->set_anchor(SIDE_LEFT, 0.5f); cap_panel->set_anchor(SIDE_RIGHT, 0.5f);
	cap_panel->set_offset(SIDE_LEFT, -390); cap_panel->set_offset(SIDE_RIGHT, 390); cap_panel->set_offset(SIDE_TOP, 18); cap_panel->set_offset(SIDE_BOTTOM, 18);
	cap_panel->set_mouse_filter(Control::MOUSE_FILTER_IGNORE);
	root->add_child(cap_panel);
	VBoxContainer *cv = memnew(VBoxContainer); cv->set_mouse_filter(Control::MOUSE_FILTER_IGNORE); cap_panel->add_child(cv);
	cap_who = label(cv, 15, accent); cap_en = label(cv, 24, Color(1, 1, 1)); cap_tr = label(cv, 17, dim);
	cap_panel->set_visible(false);
	// the lines to choose from: at the bottom right, growing upward (the two who talk stay in view)
	VBoxContainer *ob = memnew(VBoxContainer);
	ob->set_anchor(SIDE_LEFT, 1.0f); ob->set_anchor(SIDE_RIGHT, 1.0f); ob->set_anchor(SIDE_TOP, 1.0f); ob->set_anchor(SIDE_BOTTOM, 1.0f);
	ob->set_offset(SIDE_LEFT, -500); ob->set_offset(SIDE_RIGHT, -24); ob->set_offset(SIDE_TOP, -26); ob->set_offset(SIDE_BOTTOM, -26);
	ob->set_v_grow_direction(Control::GROW_DIRECTION_BEGIN);
	ob->add_theme_constant_override("separation", 8);
	root->add_child(ob);
	opt_box = ob;
	for (int i = 0; i <= MAX_OPTS; i++) { opt_btn[i] = button(ob, String()); opt_btn[i]->connect("pressed", Callable(this, "_on_option").bind(i)); }
	ob->set_visible(false);
	// "say it": at the bottom
	say_panel = memnew(PanelContainer);
	say_panel->add_theme_stylebox_override("panel", box(Color(0.06f, 0.07f, 0.10f, 0.94f), accent, 20));
	say_panel->set_anchor(SIDE_LEFT, 0.5f); say_panel->set_anchor(SIDE_RIGHT, 0.5f); say_panel->set_anchor(SIDE_TOP, 1.0f); say_panel->set_anchor(SIDE_BOTTOM, 1.0f);
	say_panel->set_offset(SIDE_LEFT, -340); say_panel->set_offset(SIDE_RIGHT, 340); say_panel->set_offset(SIDE_TOP, -26); say_panel->set_offset(SIDE_BOTTOM, -26);
	say_panel->set_v_grow_direction(Control::GROW_DIRECTION_BEGIN);
	root->add_child(say_panel);
	VBoxContainer *sv = memnew(VBoxContainer); sv->add_theme_constant_override("separation", 8); say_panel->add_child(sv);
	label(sv, 15, accent)->set_text(String::utf8("Say it  ·  Söyle"));
	say_en = label(sv, 28, Color(1, 1, 1)); say_tr = label(sv, 18, dim); say_status = label(sv, 15, accent);
	say_edit = memnew(LineEdit); say_edit->set_placeholder(String::utf8("…")); sv->add_child(say_edit);
	say_edit->connect("text_submitted", Callable(this, "_on_typed"));
	HBoxContainer *hb = memnew(HBoxContainer); hb->add_theme_constant_override("separation", 10); sv->add_child(hb);
	skip_btn = button(hb, String::utf8("Skip  ·  Geç")); skip_btn->connect("pressed", Callable(this, "_on_skip"));
	back_btn = button(hb, String::utf8("Back  ·  Geri")); back_btn->connect("pressed", Callable(this, "_on_back"));
	say_panel->set_visible(false);
	// Talk: when somebody is within reach
	talk_btn = button(root, String::utf8("Talk  ·  Konuş   [E]"));
	talk_btn->set_text_alignment(HORIZONTAL_ALIGNMENT_CENTER);
	talk_btn->set_anchor(SIDE_LEFT, 0.5f); talk_btn->set_anchor(SIDE_RIGHT, 0.5f); talk_btn->set_anchor(SIDE_TOP, 1.0f); talk_btn->set_anchor(SIDE_BOTTOM, 1.0f);
	talk_btn->set_offset(SIDE_LEFT, -120); talk_btn->set_offset(SIDE_RIGHT, 120); talk_btn->set_offset(SIDE_TOP, -86); talk_btn->set_offset(SIDE_BOTTOM, -34);
	talk_btn->connect("pressed", Callable(this, "_on_talk_pressed"));
	talk_btn->set_visible(false);
	if (get_viewport()) get_viewport()->connect("size_changed", Callable(this, "_on_resize"));
	_on_resize();
}

// ---------------------------------------------------------------- the node
bool CityTalk::load_data() {
	loaded = false; convs.clear();
	if (!FileAccess::file_exists(data_path)) { UtilityFunctions::push_error("CityTalk: no talk data at " + data_path + " (tools/city/traffic/make_talk.py)"); return false; }
	const Variant v = JSON::parse_string(FileAccess::get_file_as_string(data_path));
	if (v.get_type() != Variant::DICTIONARY) { UtilityFunctions::push_error("CityTalk: " + data_path + " does not read"); return false; }
	data = v;
	const Array cs = data.get("conversations", Array());
	for (int i = 0; i < cs.size(); i++) {
		const Dictionary d = cs[i];
		Conv c;
		const Array zs = d.get("zones", Array()), ks = d.get("kinds", Array());
		for (int k = 0; k < zs.size(); k++) c.zones |= 1 << (int)zs[k];
		for (int k = 0; k < ks.size(); k++) c.kinds |= 1 << (int)ks[k];
		c.lines = d.get("lines", Array());
		convs.push_back(c);
	}
	loaded = data.has("system") && data.has("topics") && data.has("three");
	return loaded;
}

void CityTalk::set_crowd(Object *p_crowd) {
	CityCrowd *old = crowd_node();
	if (old && old->is_connected("crowd_event", Callable(this, "_on_crowd_event"))) old->disconnect("crowd_event", Callable(this, "_on_crowd_event"));
	CityCrowd *c = Object::cast_to<CityCrowd>(p_crowd);
	crowd_id = c ? (uint64_t)c->get_instance_id() : 0;
	if (!c) return;
	c->connect("crowd_event", Callable(this, "_on_crowd_event"));
	if (c->brain() && loaded) {   // how many conversations a street of each kind has, and the longest one's lines
		for (int z = 0; z < 5; z++) { int n = 0; for (const Conv &cv : convs) if ((cv.zones >> z) & 1) n++; c->brain()->conv_n[z] = (uint8_t)std::min(std::max(n, 1), 15); }
		int most = 1; for (const Conv &cv : convs) most = std::max(most, (int)cv.lines.size());
		c->brain()->conv_lines = (uint8_t)most;
	}
}

void CityTalk::set_player(Object *p_player) {
	Object *old = player_id ? ObjectDB::get_instance(player_id) : nullptr;
	if (old && old->has_signal("interact") && old->is_connected("interact", Callable(this, "_on_interact"))) old->disconnect("interact", Callable(this, "_on_interact"));
	player_id = p_player ? (uint64_t)p_player->get_instance_id() : 0;
	if (p_player && p_player->has_signal("interact")) p_player->connect("interact", Callable(this, "_on_interact"));
}

void CityTalk::set_mission(const String &p_en, const String &p_tr, const Vector3 &p_at) { mission_en = p_en; mission_tr = p_tr; mission_at = p_at; has_mission = !p_en.is_empty(); }

Dictionary CityTalk::get_memory() const {
	Dictionary d;
	for (const KeyValue<uint32_t, Mem> &kv : memory) { Array a; a.push_back(kv.value.busy_until); a.push_back(kv.value.met_until); a.push_back(kv.value.met); d[(int64_t)kv.key] = a; }
	return d;
}

void CityTalk::set_memory(const Dictionary &p_m) {
	memory.clear();
	const Array keys = p_m.keys();
	for (int i = 0; i < keys.size(); i++) {
		const Array a = p_m[keys[i]];
		if (a.size() < 3) continue;
		Mem m; m.busy_until = a[0]; m.met_until = a[1]; m.met = a[2];
		memory[(uint32_t)(int64_t)keys[i]] = m;
	}
}

Dictionary CityTalk::stats() const {
	Dictionary d;
	d["active"] = active; d["talks"] = n_talks; d["lines"] = n_lines; d["voiced"] = n_voiced; d["silent"] = n_silent; d["group_lines"] = n_conv_lines;
	d["remembered"] = (int)memory.size(); d["options"] = (int)options.size(); d["saying"] = saying; d["tries"] = tries; d["last_line"] = last_result;
	d["conversations"] = (int)convs.size(); d["clips_loaded"] = (int)clips.size(); d["target"] = target; d["speech_plugin"] = speech_obj() != nullptr;
	return d;
}

void CityTalk::_ready() {
	if (Engine::get_singleton()->is_editor_hint()) return;
	load_data();
	for (int k = 0; k < 2; k++) {
		voice[k] = memnew(AudioStreamPlayer3D);
		voice[k]->set_unit_size(k == 0 ? 5.0f : 3.5f); voice[k]->set_max_distance(k == 0 ? 40.0f : 28.0f);
		add_child(voice[k]);
	}
	if (ui_on) build_ui();
	if (Engine::get_singleton()->has_singleton("GodotSpeech")) {
		Object *speech = Engine::get_singleton()->get_singleton("GodotSpeech");
		speech_id = speech ? (uint64_t)speech->get_instance_id() : 0;
		if (speech && speech->has_signal("speech_result")) speech->connect("speech_result", Callable(this, "_on_speech_result"));
		if (speech && speech->has_signal("speech_error")) speech->connect("speech_error", Callable(this, "_on_speech_error"));
	}
	if (crowd_id) set_crowd(ObjectDB::get_instance(crowd_id));
	set_process(true); set_process_input(true);
}

void CityTalk::_exit_tree() {
	if (Engine::get_singleton()->is_editor_hint()) return;
	if (active >= 0) end("gone");
	Object *speech = speech_obj();
	speech_id = 0;
	if (speech) {
		if (speech->is_connected("speech_result", Callable(this, "_on_speech_result"))) speech->disconnect("speech_result", Callable(this, "_on_speech_result"));
		if (speech->is_connected("speech_error", Callable(this, "_on_speech_error"))) speech->disconnect("speech_error", Callable(this, "_on_speech_error"));
	}
}

void CityTalk::_process(double p_delta) {
	pm::Scope _pm(pm::TALK);   // (the slow-frame marks, perf_marks.h)
	CityCrowd *c = crowd_node();
	// the clock people remember by: the crowd's hours where its clock runs, else a game hour in two and a half minutes
	now_h += hours_per_second > 0.0 ? hours_per_second * p_delta : p_delta / 150.0;
	if (!c || !c->brain()) return;
	pc::Crowd *b = c->brain();
	if (cap_t > 0.0) { cap_t -= p_delta; if (cap_t <= 0.0 && cap_panel) cap_panel->set_visible(false); }
	// the voices stay at their speakers; a line's clips play one after the other
	for (int k = 0; k < 2; k++) {
		if (!voice[k]) continue;
		const int row = voice_walker[k] >= 0 ? b->find(voice_walker[k]) : -1;
		if (row >= 0) voice[k]->set_global_position(Vector3(b->x[row], b->y[row] + 1.6f, b->z[row]));
		if (!queue[k].empty() && !voice[k]->is_playing()) { voice[k]->set_stream(queue[k].front()); queue[k].erase(queue[k].begin()); voice[k]->play(); }
	}
	if (active < 0) {
		target = find_target();
		if (talk_btn) talk_btn->set_visible(target >= 0);
		return;
	}
	target = -1;
	if (talk_btn) talk_btn->set_visible(false);
	const int row = b->find(active);
	if (row < 0 || b->mode[row] == pc::M_BODY) { end("gone"); return; }   // he left, or was knocked over
	// they keep facing each other while they talk (the yaw was worked out once, at the start: the player stepped aside
	// and the man talked to the empty air)
	if (has_player()) {
		const Vector3 pp = player_pos();
		for (int id : held) { const int r = b->find(id); if (r >= 0) b->face_yaw[r] = (float)std::atan2(pp.x - b->x[r], pp.z - b->z[r]); }
		player_body("talk_face", true, Vector3(b->x[row], b->y[row], b->z[row]));
	}
	if (has_player()) {
		const Vector3 p = player_pos();
		const float dx = b->x[row] - p.x, dz = b->z[row] - p.z;
		if (dx * dx + dz * dz > WALK_AWAY * WALK_AWAY) { say(row, pick(Dictionary(Dictionary(data["topics"])["T7"])["ans"])); end("walked"); }
	}
}

void CityTalk::_bind_methods() {
	ClassDB::bind_method(D_METHOD("set_crowd", "crowd"), &CityTalk::set_crowd);
	ClassDB::bind_method(D_METHOD("set_player", "player"), &CityTalk::set_player);
	ClassDB::bind_method(D_METHOD("load_data"), &CityTalk::load_data);
	ClassDB::bind_method(D_METHOD("begin", "id"), &CityTalk::begin);
	ClassDB::bind_method(D_METHOD("talk_to_nearest"), &CityTalk::talk_to_nearest);
	ClassDB::bind_method(D_METHOD("choose", "index"), &CityTalk::choose);
	ClassDB::bind_method(D_METHOD("say_typed", "text"), &CityTalk::say_typed);
	ClassDB::bind_method(D_METHOD("back"), &CityTalk::back);
	ClassDB::bind_method(D_METHOD("end", "outcome"), &CityTalk::end);
	ClassDB::bind_method(D_METHOD("is_active"), &CityTalk::is_active);
	ClassDB::bind_method(D_METHOD("get_active"), &CityTalk::get_active);
	ClassDB::bind_method(D_METHOD("get_options"), &CityTalk::get_options);
	ClassDB::bind_method(D_METHOD("stats"), &CityTalk::stats);
	ClassDB::bind_method(D_METHOD("set_mission", "en", "tr", "at"), &CityTalk::set_mission);
	ClassDB::bind_method(D_METHOD("clear_mission"), &CityTalk::clear_mission);
	ClassDB::bind_method(D_METHOD("set_hint", "kind"), &CityTalk::set_hint);
	ClassDB::bind_method(D_METHOD("get_memory"), &CityTalk::get_memory);
	ClassDB::bind_method(D_METHOD("set_memory", "memory"), &CityTalk::set_memory);
	ClassDB::bind_method(D_METHOD("set_now_hours", "hours"), &CityTalk::set_now_hours);
	ClassDB::bind_method(D_METHOD("get_now_hours"), &CityTalk::get_now_hours);
	ClassDB::bind_method(D_METHOD("set_force", "roll", "cut", "refuse", "unknown", "small"), &CityTalk::set_force);
	ClassDB::bind_method(D_METHOD("_on_crowd_event", "type", "id", "aux", "f"), &CityTalk::_on_crowd_event);
	ClassDB::bind_method(D_METHOD("_on_interact"), &CityTalk::_on_interact);
	ClassDB::bind_method(D_METHOD("_on_option", "index"), &CityTalk::_on_option);
	ClassDB::bind_method(D_METHOD("_on_talk_pressed"), &CityTalk::_on_talk_pressed);
	ClassDB::bind_method(D_METHOD("_on_skip"), &CityTalk::_on_skip);
	ClassDB::bind_method(D_METHOD("_on_back"), &CityTalk::_on_back);
	ClassDB::bind_method(D_METHOD("_on_typed", "text"), &CityTalk::_on_typed);
	ClassDB::bind_method(D_METHOD("_on_speech_result", "text", "alternatives"), &CityTalk::_on_speech_result);
	ClassDB::bind_method(D_METHOD("_on_speech_error", "code", "message"), &CityTalk::_on_speech_error);
	ClassDB::bind_method(D_METHOD("_on_resize"), &CityTalk::_on_resize);
	ClassDB::bind_method(D_METHOD("set_data_path", "path"), &CityTalk::set_data_path);
	ClassDB::bind_method(D_METHOD("get_data_path"), &CityTalk::get_data_path);
	ClassDB::bind_method(D_METHOD("set_clips_dir", "dir"), &CityTalk::set_clips_dir);
	ClassDB::bind_method(D_METHOD("get_clips_dir"), &CityTalk::get_clips_dir);
	ClassDB::bind_method(D_METHOD("set_ui", "on"), &CityTalk::set_ui);
	ClassDB::bind_method(D_METHOD("get_ui"), &CityTalk::get_ui);
	ClassDB::bind_method(D_METHOD("set_audio", "on"), &CityTalk::set_audio);
	ClassDB::bind_method(D_METHOD("get_audio"), &CityTalk::get_audio);
	ClassDB::bind_method(D_METHOD("set_need_say", "on"), &CityTalk::set_need_say);
	ClassDB::bind_method(D_METHOD("get_need_say"), &CityTalk::get_need_say);
	ClassDB::bind_method(D_METHOD("set_hours_per_second", "rate"), &CityTalk::set_hours_per_second);
	ClassDB::bind_method(D_METHOD("get_hours_per_second"), &CityTalk::get_hours_per_second);
	ADD_PROPERTY(PropertyInfo(Variant::STRING, "data_path"), "set_data_path", "get_data_path");
	ADD_PROPERTY(PropertyInfo(Variant::STRING, "clips_dir"), "set_clips_dir", "get_clips_dir");
	ADD_PROPERTY(PropertyInfo(Variant::BOOL, "ui"), "set_ui", "get_ui");
	ADD_PROPERTY(PropertyInfo(Variant::BOOL, "audio"), "set_audio", "get_audio");
	ADD_PROPERTY(PropertyInfo(Variant::BOOL, "need_say"), "set_need_say", "get_need_say");
	ADD_PROPERTY(PropertyInfo(Variant::FLOAT, "hours_per_second"), "set_hours_per_second", "get_hours_per_second");
	ADD_SIGNAL(MethodInfo("started", PropertyInfo(Variant::INT, "id")));
	ADD_SIGNAL(MethodInfo("ended", PropertyInfo(Variant::INT, "id"), PropertyInfo(Variant::STRING, "outcome")));
	ADD_SIGNAL(MethodInfo("npc_line", PropertyInfo(Variant::STRING, "en"), PropertyInfo(Variant::STRING, "tr")));
	ADD_SIGNAL(MethodInfo("choices_offered", PropertyInfo(Variant::ARRAY, "items")));
	ADD_SIGNAL(MethodInfo("say_requested", PropertyInfo(Variant::STRING, "en"), PropertyInfo(Variant::STRING, "tr")));
	ADD_SIGNAL(MethodInfo("listen_result", PropertyInfo(Variant::BOOL, "ok"), PropertyInfo(Variant::INT, "tries_left"), PropertyInfo(Variant::STRING, "how")));
}

} // namespace godot
