// See city_car_lights.h.
#include "city_car_lights.h"
#include <godot_cpp/classes/camera3d.hpp>
#include <godot_cpp/classes/viewport.hpp>
#include <godot_cpp/core/class_db.hpp>
#include <godot_cpp/variant/dictionary.hpp>
#include <algorithm>
#include <cmath>

using namespace godot;

void CityCarLights::set_traffic(Node *p_traffic) { traffic_id = p_traffic ? p_traffic->get_instance_id() : 0; }

void CityCarLights::_ready() {
	for (int k = 0; k < count; k++) {
		SpotLight3D *l = memnew(SpotLight3D);
		l->set_shadow(false); l->set_visible(false);
		l->set_param(Light3D::PARAM_RANGE, (float)reach);
		l->set_param(Light3D::PARAM_SPOT_ANGLE, 34.0f);
		l->set_param(Light3D::PARAM_SPOT_ATTENUATION, 0.9f);
		l->set_param(Light3D::PARAM_ATTENUATION, 1.2f);
		l->set_color(Color(1.0f, 0.93f, 0.8f));
		add_child(l); pool.push_back(l);
	}
	set_process(true);
}

void CityCarLights::_process(double p_delta) {
	t += p_delta;
	if (t < every) return;
	t = 0.0;
	Node *trf = traffic_id ? Object::cast_to<Node>(ObjectDB::get_instance(ObjectID(traffic_id))) : nullptr;
	Viewport *vp = get_viewport();
	Camera3D *cam = vp ? vp->get_camera_3d() : nullptr;
	const float night = trf ? (float)(double)trf->get("night") : 0.0f;
	lit = 0;
	if (!trf || !cam || night < 0.2f) { for (SpotLight3D *l : pool) if (l->is_visible()) l->set_visible(false); return; }
	const Vector3 c = cam->get_global_position();
	const Vector3 look = -cam->get_global_transform().basis.get_column(2);
	const Array cars = trf->call("cars_near", c, 90.0);
	// the traffic's cars, nearest first; one the camera looks towards counts as nearer (its beam is what is seen)
	std::vector<std::pair<float, int>> order;
	for (int i = 0; i < cars.size(); i++) {
		const Dictionary d = cars[i];
		if ((bool)d.get("bike", false)) continue;      // (a car stopped at a light keeps its lights on)
		const Vector3 at = d.get("at", Vector3());
		const Vector3 to = at - c;
		const float dist = to.length();
		const float ahead = dist > 0.1f ? to.dot(look) / dist : 1.0f;
		order.push_back({ dist * (ahead > 0.0f ? 1.0f : 1.8f), i });
	}
	std::sort(order.begin(), order.end());
	const float e = (float)energy * std::min(1.0f, (night - 0.2f) / 0.4f);
	for (size_t k = 0; k < pool.size(); k++) {
		SpotLight3D *l = pool[k];
		if (k >= order.size()) { if (l->is_visible()) l->set_visible(false); continue; }
		const Dictionary d = cars[order[k].second];
		const Vector3 at = d.get("at", Vector3());
		const float yaw = (float)(double)d.get("yaw", 0.0);
		const Vector3 fwd(std::sin(yaw), 0.0f, std::cos(yaw));
		const Vector3 p = at + fwd * 2.3f + Vector3(0, 0.75f, 0);
		const Vector3 aim = p + fwd * 10.0f - Vector3(0, 1.6f, 0);      // down the road, dipped
		l->set_global_transform(Transform3D(Basis::looking_at(aim - p, Vector3(0, 1, 0)), p));
		l->set_param(Light3D::PARAM_ENERGY, e);
		if (!l->is_visible()) l->set_visible(true);
		lit++;
	}
}

void CityCarLights::_bind_methods() {
	ClassDB::bind_method(D_METHOD("set_traffic", "traffic"), &CityCarLights::set_traffic);
	ClassDB::bind_method(D_METHOD("set_count", "n"), &CityCarLights::set_count);
	ClassDB::bind_method(D_METHOD("get_count"), &CityCarLights::get_count);
	ClassDB::bind_method(D_METHOD("set_energy", "e"), &CityCarLights::set_energy);
	ClassDB::bind_method(D_METHOD("get_energy"), &CityCarLights::get_energy);
	ClassDB::bind_method(D_METHOD("get_lit"), &CityCarLights::get_lit);
	ADD_PROPERTY(PropertyInfo(Variant::INT, "count"), "set_count", "get_count");
	ADD_PROPERTY(PropertyInfo(Variant::FLOAT, "energy"), "set_energy", "get_energy");
}
