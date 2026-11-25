// STUDY CHECK: the human-movement study's validator (HUMAN_MOVEMENT_STUDY.md v2, Parts 1, 2, 3, 9.1, 11.2).
// LOCKED. Written outside the lab, by the session that wrote the study; the lab may not change any file in
// study_check/ (the gate compares them with origin/lab/checker and refuses a changed copy).
//
// A SkeletonModifier3D placed LAST on the body's skeleton (and a second one, role "pre", just before a modifier named
// "FinalLimiter" if the lab has one). It reads the drawn pose in world space every frame, measures every joint with a
// sign on every axis (rest-relative, anatomical frames from joint positions and axes carried by bones), the centre of
// mass (de Leva), the three leans, the sole points (taken from the skinned mesh) against the physics world, and tests
// the HARD rules of 11.2. Rules that need a smooth fit or a whole step are judged on a delayed frame (0.5 s behind).
#pragma once

#include <godot_cpp/classes/skeleton_modifier3d.hpp>
#include <godot_cpp/classes/skeleton3d.hpp>
#include <godot_cpp/variant/dictionary.hpp>
#include <godot_cpp/variant/packed_string_array.hpp>
#include <godot_cpp/variant/transform3d.hpp>

#include <deque>
#include <map>
#include <string>
#include <vector>

namespace study {

enum Ch {
	// per side (L = +0, R = +1)
	C_KNEE_FLEX = 0, C_KNEE_VARUS = 2, C_KNEE_TWIST = 4,
	C_DORSI = 6, C_INV = 8, C_FOOT_ABD = 10, C_TOE = 12,
	C_HIP_FLEX = 14, C_HIP_ABD = 16, C_HIP_ROT = 18,
	C_SH_ELEV = 20, C_SH_ACROSS = 22, C_SH_TWIST = 24, C_ELBOW = 26, C_FARM_TW = 28, C_WRIST_F = 30, C_WRIST_D = 32,
	// single
	C_LUMB_F = 34, C_LUMB_S, C_LUMB_T, C_THOR_F, C_THOR_S, C_THOR_T, C_NECK_F, C_NECK_S, C_NECK_T,
	C_PELVIS_YAW, // unwrapped, degrees
	C_COUNT
};

struct Sample {
	double t = 0, dt = 0;
	int frame = 0;
	float ch[C_COUNT];
	godot::Vector3 com, pc, neck;   // centre of mass, pelvis centre, neck base (world)
	godot::Vector3 pf_h, pl_h;      // pelvis forward / left, horizontal
	godot::Vector3 sole[2][4];      // heel, inner ball, outer ball, toe tip (world)
	bool pt_contact[2][4] = {};     // sole point within 1 cm of the ground
	godot::Vector3 ground_n[2];
	bool foot_contact[2] = {};      // any sole point in contact
	bool heel_up[2] = {};
	bool planted_intent[2] = {};    // the controller says the foot is planted (optional)
	bool has_intent = false;
	float head_roll = 0, head_pitch = 0;
	float trunk_f = 0, trunk_s = 0; // trunk lean (deg), forward / sideways(+left)
	godot::Vector2 trunk_w;         // trunk lean as a world vector (deg, x / z)
	godot::Vector3 footF[2], footU[2], shinF[2];
	float sh_fw[2] = {0, 0}, sh_la[2] = {0, 0};
	float pt_dist[2][4];
	float foot_dmin[2] = {1e9f, 1e9f};
	godot::Vector2 lean_wb;         // whole-body lean, filled at evaluation (deg: forward, left)
	bool lean_valid = false;
	bool loco = true;               // state is ordinary locomotion (walk / run / start / stop / turn)
	std::string state;
	bool evaluated = false;
	godot::Vector3 vel, acc;        // CoM fitted velocity / acceleration (filled at evaluation)
};

struct Rule {
	int count = 0;
	float worst = 0, limit = 0;
	double worst_t = -1;
	std::string worst_side;
};

class StudyCheck : public godot::SkeletonModifier3D {
	GDCLASS(StudyCheck, godot::SkeletonModifier3D)

public:
	void _process_modification_with_delta(double p_delta) override;

	void set_role(const godot::String &r);
	godot::String get_role() const { return godot::String(role.c_str()); }
	void set_peer(godot::Object *o) { peer = godot::Object::cast_to<StudyCheck>(o); }
	void set_controller(godot::Object *o) { controller = o; }
	void set_physics_rules(bool b) { physics_rules = b; }
	void set_contact_rules(bool b) { contact_rules = b; }
	void set_label(const godot::String &s) { label = s.utf8().get_data(); }
	void set_seed(int64_t s) { seed = s; }
	void set_mu(float m) { mu = m; }
	void set_log_limit(int n) { log_limit = n; }
	void set_eval_delay(float d) { eval_delay = d; }
	void set_ground_mask(int m) { ground_mask = m; }
	void set_bone_prefix(const godot::String &p) { bone_prefix = p.utf8().get_data(); }
	void set_sole_mode(const godot::String &m) { sole_mode = m.utf8().get_data(); }
	void reset();
	void flush();
	godot::Dictionary get_report() const;
	godot::PackedStringArray get_log() const { return log_lines; }
	float get_channel(const godot::String &name) const;
	godot::Dictionary get_last() const;
	bool is_setup_ok() const { return setup_ok; }
	godot::String get_setup_error() const { return godot::String(setup_error.c_str()); }
	godot::PackedVector3Array get_sole_points() const;
	godot::Vector3 get_com() const { return last.com; }
	int get_frames() const { return frame; }
	double get_time() const { return t; }
	// the samples of the last frame, for the limiter comparison (pre instance)
	const Sample &last_sample() const { return last; }
	int last_frame() const { return frame; }

protected:
	static void _bind_methods();

private:
	// ---- setup (rest pose)
	bool setup_done = false, setup_ok = false;
	std::string setup_error;
	int H = -1, LOW = -1, MID = -1, CHEST = -1, NECK = -1, HEAD = -1, HEADTOP = -1;
	int UP[2], LO[2], FOOT[2], TOE[2], SHO[2], ARM[2], FARM[2], HAND[2], MID1[2], THUMB1[2];
	int FING[2][4][3]; // index, middle, ring, pinky x 3 joints
	std::vector<godot::Basis> R0;            // rest global bases (orthonormal), skeleton space
	std::vector<godot::Vector3> P0;          // rest global origins, skeleton space (skeleton units)
	float unit = 0.01f;                      // metres per skeleton unit (from the skeleton's world scale)
	// axes carried by bones (bone-local)
	godot::Vector3 hinge_up[2], hinge_lo[2]; // knee hinge (body left, perpendicular to the rest thigh)
	float ft_sign[2] = {1, 1}, fs_sign[2] = {1, 1};
	godot::Vector3 sole_off[2][4];           // heel, inner ball, outer ball in the Foot frame; tip in the Toe frame
	godot::Vector3 elbow_hinge[2];           // carried by Arm
	float rest_ch[C_COUNT];
	godot::Vector3 palm_n0[2], thumb0[2];    // rest, skeleton space
	float u_sign[2] = {1, 1};                // sole-normal orientation per side
	std::vector<std::pair<int, int>> bone_pairs; // (parent joint, child joint) for BONE_LENGTH
	std::vector<float> rest_len;             // metres
	std::string role = "final";
	StudyCheck *peer = nullptr;
	godot::Object *controller = nullptr;
	bool physics_rules = true, contact_rules = true;
	std::string label;
	int64_t seed = 0;
	float mu = 0.8f;
	int log_limit = 40;
	float eval_delay = 0.5f;
	int ground_mask = 1 | 4 | 8;
	std::string bone_prefix, sole_mode = "mesh";

	// ---- run state
	double t = 0;
	int frame = 0;
	Sample last;
	std::deque<Sample> buf;
	size_t next_eval = 0;     // index in buf of the next frame to evaluate
	std::map<std::string, Rule> rules;
	std::map<std::string, int> log_count;
	std::map<std::string, double> state_time;
	godot::PackedStringArray log_lines;
	int limiter_key_frames = 0, limiter_other_frames = 0;
	float yaw_unwrapped = 0, yaw_prev_raw = 0;
	bool yaw_init = false;
	// contacts (immediate)
	bool prev_pt[2][4] = {};
	godot::Vector3 pt_start[2][4];
	bool flat_prev[2] = {};
	float flat_yaw0[2] = {0, 0};
	// delayed state
	bool ev_prev_contact[2] = {true, true};
	double ev_last_td = -1;
	struct StepAcc {
		double t0 = -1;
		int n = 0, n_lean = 0;
		godot::Vector2 lean_sum;
		godot::Vector3 v0;
		bool v0_set = false;
		float speed_min = 1e9f, speed_sum = 0;
		bool all_loco = true;
		double ds_time = 0, ds_run = 0, ds_max = 0; // double support while running on the level
		std::vector<godot::Vector2> trunk;          // per frame trunk lean (deg)
		std::vector<double> trunk_t;
		std::vector<int> trunk_f;
		float head_pitch_min = 1e9f, head_pitch_max = -1e9f;
		float yaw0 = 0;
		bool level = true;
	} step;
	struct StepRec { double t0, t1; float omega, speed, heading_change; bool exempt; };
	std::vector<StepRec> steps;
	int tight_steps = 0;
	float prev_head_pitch_range = 0;
	// flight
	bool in_flight = false;
	std::vector<std::pair<double, godot::Vector3>> flight_pts;
	double flight_t0 = 0, last_land_t = -10;
	// stop from a run
	double run_seen_t = -1;
	int td_since_run = 0;
	bool stopping = false;
	// walk flight, running double support, head pitch per stride
	double walk_flight_t = 0;
	double ds_cur = 0;
	bool ds_exempt = false;
	std::vector<std::pair<double, float>> flight_acc;
	float prev_pitch_min = 0, prev_pitch_max = 0;
	bool prev_pitch_valid = false;
	bool use_rest = false;
	std::vector<godot::Transform3D> rest_xf;  // rest global transforms with their scale (skeleton units)
	godot::Vector3 F_rest[2], U_rest[2];      // foot forward / sole up at rest (skeleton axes)
	godot::Vector3 sk_rest_xform(int b, const godot::Vector3 &local) const;
	float step_omega_now(size_t i) const;

	void setup(godot::Skeleton3D *sk);
	bool fail(const std::string &e);
	void capture_sole_points(godot::Skeleton3D *sk);
	godot::Basis Bw(int b) const;      // world basis of bone b (orthonormal), this frame
	godot::Vector3 Pw(int b) const;    // world position of bone b, this frame
	godot::Basis Rrel_now(int parent, int child) const;
	godot::Basis Rrel_rest(int parent, int child) const;
	godot::Vector3 carry(int bone, const godot::Vector3 &v_rest_skel) const;
	void measure(Sample &s, bool rest_pass);
	void contacts(godot::Skeleton3D *sk, Sample &s);
	void immediate_rules(Sample &s);
	void evaluate(size_t i);
	void step_end(size_t i, double t_td);
	bool fit(size_t c, int channel, int comp, bool exclude_center, float &v0, float &v1, float &v2) const;
	float value(const Sample &s, int channel, int comp) const;
	void violate(const std::string &id, const std::string &side, float value, float limit, double at, int fr,
			const std::string &extra = "");

	// frame cache (world)
	godot::Transform3D skw;
	godot::Skeleton3D *skc = nullptr;
};

} // namespace study
