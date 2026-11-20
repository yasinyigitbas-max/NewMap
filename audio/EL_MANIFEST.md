# ElevenLabs sound effects: manifest

Generated with ElevenLabs text-to-sound (eleven_text_to_sound_v3), 20 Nov 2026, for Yasin ("Sounds in the game are terrible, start recording every sound ... Start with the highest priorities").
All files: OGG Vorbis q5, 44.1 kHz (ui_tick.wav: PCM 16-bit 22.05 kHz, as before); mono for everything except the stereo beds (amb/*.ogg except crowd_murmur, amb/zone, amb/room).
Trimmed (one-shots start within 3 ms), 2 ms fade-in, short fade-out, no clipping (peaks <= -0.6 dBFS after encoding). Loops are cut with an equal-power crossfade so the end runs into the start.
Every file and its trigger, levels and source take is in el_manifest.json next to this file. Status: "replaces" = same path already in this branch; "drop-in" = same path as the files on claude/perf-bugs (take these when merging); "new" = needs a code hookup.

## Surf, bay lapping, gulls, wind, rain, crickets, park birds, crowd murmur, far traffic, jet and helicopter flyovers (have)

| file | status | trigger | dur s | loop |
|---|---|---|---|---|
| amb/bay_lapping.ogg | drop-in (path from claude/perf-bugs) | CityAmbience bed / CityCrowd murmur (drop-in) | 28.00 | yes |
| amb/crowd_murmur.ogg | replaces (this branch) | CityAmbience bed / CityCrowd murmur (drop-in) | 28.00 | yes |
| amb/gull_call_1.ogg | drop-in (path from claude/perf-bugs) | CityAmbience gull one-shot (drop-in, 5 needed) | 1.48 |  |
| amb/gull_call_2.ogg | drop-in (path from claude/perf-bugs) | CityAmbience gull one-shot (drop-in, 5 needed) | 1.48 |  |
| amb/gull_call_3.ogg | drop-in (path from claude/perf-bugs) | CityAmbience gull one-shot (drop-in, 5 needed) | 1.48 |  |
| amb/gull_call_4.ogg | drop-in (path from claude/perf-bugs) | CityAmbience gull one-shot (drop-in, 5 needed) | 1.94 |  |
| amb/gull_call_5.ogg | drop-in (path from claude/perf-bugs) | CityAmbience gull one-shot (drop-in, 5 needed) | 1.99 |  |
| amb/gulls_shore.ogg | drop-in (path from claude/perf-bugs) | CityAmbience bed / CityCrowd murmur (drop-in) | 28.00 | yes |
| amb/helicopter_flyover.ogg | drop-in (path from claude/perf-bugs) | CityAmbience helicopter flyover (drop-in) | 30.00 |  |
| amb/navy_jet_flyover_1.ogg | drop-in (path from claude/perf-bugs) | CityAmbience jet flyover (drop-in) | 29.57 |  |
| amb/navy_jet_flyover_2.ogg | drop-in (path from claude/perf-bugs) | CityAmbience jet flyover (drop-in) | 29.40 |  |
| amb/night_crickets.ogg | drop-in (path from claude/perf-bugs) | CityAmbience bed / CityCrowd murmur (drop-in) | 28.00 | yes |
| amb/pacific_surf.ogg | drop-in (path from claude/perf-bugs) | CityAmbience bed / CityCrowd murmur (drop-in) | 28.00 | yes |
| amb/park_birds.ogg | drop-in (path from claude/perf-bugs) | CityAmbience bed / CityCrowd murmur (drop-in) | 28.00 | yes |
| amb/rain_loop.ogg | drop-in (path from claude/perf-bugs) | CityAmbience bed / CityCrowd murmur (drop-in) | 28.00 | yes |
| amb/traffic_far.ogg | drop-in (path from claude/perf-bugs) | CityAmbience bed / CityCrowd murmur (drop-in) | 28.00 | yes |
| amb/wind.ogg | drop-in (path from claude/perf-bugs) | CityAmbience bed / CityCrowd murmur (drop-in) | 28.00 | yes |

## Room tones: shops, homes, offices (P1)

| file | status | trigger | dur s | loop |
|---|---|---|---|---|
| amb/room/room_home_0.ogg | new | player inside a room of that kind (CityRooms) | 36.00 | yes |
| amb/room/room_office_0.ogg | new | player inside a room of that kind (CityRooms) | 36.00 | yes |
| amb/room/room_shop_0.ogg | new | player inside a room of that kind (CityRooms) | 36.00 | yes |

## Zone beds: downtown, homes, industrial, marina, beach, parks, hospital, campus (P1)

| file | status | trigger | dur s | loop |
|---|---|---|---|---|
| amb/zone/zone_beach_0.ogg | new | CityAmbience bed by zone (needs zone map) | 28.00 | yes |
| amb/zone/zone_campus_0.ogg | new | CityAmbience bed by zone (needs zone map) | 28.00 | yes |
| amb/zone/zone_downtown_0.ogg | new | CityAmbience bed by zone (needs zone map) | 28.00 | yes |
| amb/zone/zone_homes_0.ogg | new | CityAmbience bed by zone (needs zone map) | 28.00 | yes |
| amb/zone/zone_hospital_0.ogg | new | CityAmbience bed by zone (needs zone map) | 28.00 | yes |
| amb/zone/zone_industrial_0.ogg | new | CityAmbience bed by zone (needs zone map) | 28.00 | yes |
| amb/zone/zone_marina_0.ogg | new | CityAmbience bed by zone (needs zone map) | 28.00 | yes |
| amb/zone/zone_parks_0.ogg | new | CityAmbience bed by zone (needs zone map) | 28.00 | yes |

## Bike freewheel, chain, bell, brake squeal (P1)

| file | status | trigger | dur s | loop |
|---|---|---|---|---|
| sfx/bike/bike_bell_0.ogg | new | bike horn key | 1.00 |  |
| sfx/bike/bike_bell_1.ogg | new | bike horn key | 1.00 |  |
| sfx/bike/bike_bell_2.ogg | new | bike horn key | 1.00 |  |
| sfx/bike/bike_bell_3.ogg | new | bike horn key | 1.00 |  |
| sfx/bike/bike_brake_squeal_0.ogg | new | bike brake | 1.18 |  |
| sfx/bike/bike_brake_squeal_1.ogg | new | bike brake | 1.26 |  |
| sfx/bike/bike_brake_squeal_2.ogg | new | bike brake | 1.28 |  |
| sfx/bike/bike_brake_squeal_3.ogg | new | bike brake | 0.92 |  |
| sfx/bike/bike_chain_loop_0.ogg | new | bike pedalling (loop) | 2.69 | yes |
| sfx/bike/bike_chain_loop_1.ogg | new | bike pedalling (loop) | 2.70 | yes |
| sfx/bike/bike_chain_loop_2.ogg | new | bike pedalling (loop) | 2.70 | yes |
| sfx/bike/bike_freewheel_loop_0.ogg | new | bike coasting (loop, rate by speed) | 2.70 | yes |
| sfx/bike/bike_freewheel_loop_1.ogg | new | bike coasting (loop, rate by speed) | 2.70 | yes |
| sfx/bike/bike_freewheel_loop_2.ogg | new | bike coasting (loop, rate by speed) | 2.70 | yes |

## Bus air brakes, door hiss, kneeling beep, fare chime (P1)

| file | status | trigger | dur s | loop |
|---|---|---|---|---|
| sfx/bus/bus_air_brake_0.ogg | new | bus stops at a stop | 1.60 |  |
| sfx/bus/bus_air_brake_1.ogg | new | bus stops at a stop | 1.55 |  |
| sfx/bus/bus_air_brake_2.ogg | new | bus stops at a stop | 1.56 |  |
| sfx/bus/bus_air_brake_3.ogg | new | bus stops at a stop | 1.60 |  |
| sfx/bus/bus_door_close_0.ogg | new | bus door closes | 1.73 |  |
| sfx/bus/bus_door_close_1.ogg | new | bus door closes | 1.76 |  |
| sfx/bus/bus_door_close_2.ogg | new | bus door closes | 1.74 |  |
| sfx/bus/bus_door_close_3.ogg | new | bus door closes | 1.74 |  |
| sfx/bus/bus_door_open_0.ogg | new | bus door opens (traffic bus_stop_tag) | 1.76 |  |
| sfx/bus/bus_door_open_1.ogg | new | bus door opens (traffic bus_stop_tag) | 1.76 |  |
| sfx/bus/bus_door_open_2.ogg | new | bus door opens (traffic bus_stop_tag) | 1.75 |  |
| sfx/bus/bus_door_open_3.ogg | new | bus door opens (traffic bus_stop_tag) | 1.76 |  |
| sfx/bus/bus_fare_chime_0.ogg | new | player pays fare / boards | 0.56 |  |
| sfx/bus/bus_fare_chime_1.ogg | new | player pays fare / boards | 0.48 |  |
| sfx/bus/bus_fare_chime_2.ogg | new | player pays fare / boards | 0.65 |  |
| sfx/bus/bus_fare_chime_3.ogg | new | player pays fare / boards | 0.63 |  |
| sfx/bus/bus_kneel_beep_0.ogg | new | bus kneels at a stop | 2.47 |  |
| sfx/bus/bus_kneel_beep_1.ogg | new | bus kneels at a stop | 2.40 |  |
| sfx/bus/bus_kneel_beep_2.ogg | new | bus kneels at a stop | 2.48 |  |
| sfx/bus/bus_kneel_beep_3.ogg | new | bus kneels at a stop | 2.44 |  |

## Car doors open / close, locks, seatbelt (P1)

| file | status | trigger | dur s | loop |
|---|---|---|---|---|
| sfx/car/car_door_close_0.ogg | new | enter / exit car end | 0.81 |  |
| sfx/car/car_door_close_1.ogg | new | enter / exit car end | 0.59 |  |
| sfx/car/car_door_close_2.ogg | new | enter / exit car end | 0.71 |  |
| sfx/car/car_door_close_3.ogg | new | enter / exit car end | 0.61 |  |
| sfx/car/car_door_open_0.ogg | new | enter / exit car start | 0.95 |  |
| sfx/car/car_door_open_1.ogg | new | enter / exit car start | 0.97 |  |
| sfx/car/car_door_open_2.ogg | new | enter / exit car start | 1.00 |  |
| sfx/car/car_door_open_3.ogg | new | enter / exit car start | 0.95 |  |
| sfx/car/car_lock_chirp_0.ogg | new | lock car | 0.59 |  |
| sfx/car/car_lock_chirp_1.ogg | new | lock car | 0.67 |  |
| sfx/car/car_lock_chirp_2.ogg | new | lock car | 0.64 |  |
| sfx/car/car_lock_chirp_3.ogg | new | lock car | 0.60 |  |
| sfx/car/car_lock_mech_0.ogg | new | lock / unlock car | 0.68 |  |
| sfx/car/car_lock_mech_1.ogg | new | lock / unlock car | 0.68 |  |
| sfx/car/car_lock_mech_2.ogg | new | lock / unlock car | 0.68 |  |
| sfx/car/car_lock_mech_3.ogg | new | lock / unlock car | 0.68 |  |
| sfx/car/seatbelt_buckle_0.ogg | new | enter car (driver) | 0.97 |  |
| sfx/car/seatbelt_buckle_1.ogg | new | enter car (driver) | 1.01 |  |
| sfx/car/seatbelt_buckle_2.ogg | new | enter car (driver) | 0.99 |  |
| sfx/car/seatbelt_buckle_3.ogg | new | enter car (driver) | 0.98 |  |
| sfx/car/seatbelt_unbuckle_0.ogg | new | exit car | 0.90 |  |
| sfx/car/seatbelt_unbuckle_1.ogg | new | exit car | 0.79 |  |
| sfx/car/seatbelt_unbuckle_2.ogg | new | exit car | 0.89 |  |
| sfx/car/seatbelt_unbuckle_3.ogg | new | exit car | 0.72 |  |

## Engine layers per price class: start, idle, rev, stall (P1)

| file | status | trigger | dur s | loop |
|---|---|---|---|---|
| sfx/car/engine_stall_0.ogg | new | engine stalls / switched off | 1.73 |  |
| sfx/car/engine_stall_1.ogg | new | engine stalls / switched off | 1.69 |  |
| sfx/car/engine_stall_2.ogg | new | engine stalls / switched off | 1.65 |  |
| sfx/car/engine_stall_3.ogg | new | engine stalls / switched off | 1.69 |  |
| sfx/car/engine_start_compact_0.ogg | new | CityCar enter / ignition (class: compact) | 2.41 |  |
| sfx/car/engine_start_compact_1.ogg | new | CityCar enter / ignition (class: compact) | 2.48 |  |
| sfx/car/engine_start_compact_2.ogg | new | CityCar enter / ignition (class: compact) | 2.48 |  |
| sfx/car/engine_start_compact_3.ogg | new | CityCar enter / ignition (class: compact) | 2.48 |  |
| sfx/car/engine_start_diesel_0.ogg | new | CityCar enter / ignition (class: diesel) | 2.48 |  |
| sfx/car/engine_start_diesel_1.ogg | new | CityCar enter / ignition (class: diesel) | 2.48 |  |
| sfx/car/engine_start_diesel_2.ogg | new | CityCar enter / ignition (class: diesel) | 2.46 |  |
| sfx/car/engine_start_diesel_3.ogg | new | CityCar enter / ignition (class: diesel) | 2.48 |  |
| sfx/car/engine_start_ev_0.ogg | new | EV ignition (volt_s / volt_x) | 1.74 |  |
| sfx/car/engine_start_ev_1.ogg | new | EV ignition (volt_s / volt_x) | 1.73 |  |
| sfx/car/engine_start_ev_2.ogg | new | EV ignition (volt_s / volt_x) | 1.76 |  |
| sfx/car/engine_start_ev_3.ogg | new | EV ignition (volt_s / volt_x) | 1.76 |  |
| sfx/car/engine_start_v6_0.ogg | new | CityCar enter / ignition (class: v6) | 2.48 |  |
| sfx/car/engine_start_v6_1.ogg | new | CityCar enter / ignition (class: v6) | 2.45 |  |
| sfx/car/engine_start_v6_2.ogg | new | CityCar enter / ignition (class: v6) | 2.48 |  |
| sfx/car/engine_start_v6_3.ogg | new | CityCar enter / ignition (class: v6) | 2.48 |  |
| sfx/car/engine_start_v8_0.ogg | new | CityCar enter / ignition (class: v8) | 2.46 |  |
| sfx/car/engine_start_v8_1.ogg | new | CityCar enter / ignition (class: v8) | 2.48 |  |
| sfx/car/engine_start_v8_2.ogg | new | CityCar enter / ignition (class: v8) | 2.48 |  |
| sfx/car/engine_start_v8_3.ogg | new | CityCar enter / ignition (class: v8) | 2.45 |  |

## Glass shatter, scrape, metal creak, hits on poles / fences / bins (P1)

| file | status | trigger | dur s | loop |
|---|---|---|---|---|
| sfx/car/glass_shatter_0.ogg | new | crash sev >= 10 (glass) / window smash | 1.32 |  |
| sfx/car/glass_shatter_1.ogg | new | crash sev >= 10 (glass) / window smash | 1.05 |  |
| sfx/car/glass_shatter_2.ogg | new | crash sev >= 10 (glass) / window smash | 1.18 |  |
| sfx/car/glass_shatter_3.ogg | new | crash sev >= 10 (glass) / window smash | 1.18 |  |
| sfx/car/hit_bin_0.ogg | new | breakable: bin / cone | 1.04 |  |
| sfx/car/hit_bin_1.ogg | new | breakable: bin / cone | 1.17 |  |
| sfx/car/hit_bin_2.ogg | new | breakable: bin / cone | 0.86 |  |
| sfx/car/hit_fence_0.ogg | new | breakable: fence | 1.28 |  |
| sfx/car/hit_fence_1.ogg | new | breakable: fence | 1.28 |  |
| sfx/car/hit_fence_2.ogg | new | breakable: fence | 1.28 |  |
| sfx/car/hit_fence_3.ogg | new | breakable: fence | 1.28 |  |
| sfx/car/hit_pole_0.ogg | new | breakable: pole / sign | 0.73 |  |
| sfx/car/hit_pole_1.ogg | new | breakable: pole / sign | 0.72 |  |
| sfx/car/hit_pole_2.ogg | new | breakable: pole / sign | 0.69 |  |
| sfx/car/hit_pole_3.ogg | new | breakable: pole / sign | 0.92 |  |
| sfx/car/metal_creak_0.ogg | new | after a heavy crash / damaged car settling | 1.34 |  |
| sfx/car/metal_creak_1.ogg | new | after a heavy crash / damaged car settling | 1.36 |  |
| sfx/car/metal_creak_2.ogg | new | after a heavy crash / damaged car settling | 1.41 |  |
| sfx/car/metal_creak_3.ogg | new | after a heavy crash / damaged car settling | 1.16 |  |
| sfx/car/metal_scrape_0.ogg | new | side contact with a wall | 1.43 |  |
| sfx/car/metal_scrape_1.ogg | new | side contact with a wall | 1.44 |  |
| sfx/car/metal_scrape_2.ogg | new | side contact with a wall | 1.48 |  |
| sfx/car/metal_scrape_3.ogg | new | side contact with a wall | 1.43 |  |
| sfx/car/metal_scrape_loop_0.ogg | new | sustained wall contact (loop) | 2.67 | yes |
| sfx/car/metal_scrape_loop_1.ogg | new | sustained wall contact (loop) | 1.64 | yes |
| sfx/car/metal_scrape_loop_2.ogg | new | sustained wall contact (loop) | 2.70 | yes |

## Horns per class (P1)

| file | status | trigger | dur s | loop |
|---|---|---|---|---|
| sfx/car/horn_bus_0.ogg | new | horn key (class bus) | 0.90 |  |
| sfx/car/horn_bus_1.ogg | new | horn key (class bus) | 0.90 |  |
| sfx/car/horn_bus_2.ogg | new | horn key (class bus) | 0.90 |  |
| sfx/car/horn_bus_3.ogg | new | horn key (class bus) | 0.88 |  |
| sfx/car/horn_compact_0.ogg | new | horn key (class compact) | 0.81 |  |
| sfx/car/horn_compact_1.ogg | new | horn key (class compact) | 0.38 |  |
| sfx/car/horn_compact_2.ogg | new | horn key (class compact) | 0.77 |  |
| sfx/car/horn_compact_3.ogg | new | horn key (class compact) | 0.44 |  |
| sfx/car/horn_sedan_0.ogg | new | horn key (class sedan) | 0.88 |  |
| sfx/car/horn_sedan_1.ogg | new | horn key (class sedan) | 0.88 |  |
| sfx/car/horn_sedan_2.ogg | new | horn key (class sedan) | 0.83 |  |
| sfx/car/horn_sedan_3.ogg | new | horn key (class sedan) | 0.81 |  |
| sfx/car/horn_sport_0.ogg | new | horn key (class sport) | 0.46 |  |
| sfx/car/horn_sport_1.ogg | new | horn key (class sport) | 0.36 |  |
| sfx/car/horn_sport_2.ogg | new | horn key (class sport) | 0.50 |  |
| sfx/car/horn_sport_3.ogg | new | horn key (class sport) | 0.71 |  |
| sfx/car/horn_van_0.ogg | new | horn key (class van) | 0.44 |  |
| sfx/car/horn_van_1.ogg | new | horn key (class van) | 0.90 |  |
| sfx/car/horn_van_2.ogg | new | horn key (class van) | 0.90 |  |
| sfx/car/horn_van_3.ogg | new | horn key (class van) | 0.51 |  |

## Tyre squeal and skids on asphalt and sand (P1)

| file | status | trigger | dur s | loop |
|---|---|---|---|---|
| sfx/car/skid_asphalt_0.ogg | new | hard brake with wheel lock | 1.95 |  |
| sfx/car/skid_asphalt_1.ogg | new | hard brake with wheel lock | 2.03 |  |
| sfx/car/skid_asphalt_2.ogg | new | hard brake with wheel lock | 2.03 |  |
| sfx/car/skid_asphalt_3.ogg | new | hard brake with wheel lock | 1.86 |  |
| sfx/car/skid_sand_0.ogg | new | hard brake / slide on sand | 2.01 |  |
| sfx/car/skid_sand_1.ogg | new | hard brake / slide on sand | 2.10 |  |
| sfx/car/skid_sand_2.ogg | new | hard brake / slide on sand | 2.02 |  |
| sfx/car/slide_sand_loop_0.ogg | new | slip on sand (loop) | 3.70 | yes |
| sfx/car/slide_sand_loop_1.ogg | new | slip on sand (loop) | 3.70 | yes |
| sfx/car/slide_sand_loop_2.ogg | new | slip on sand (loop) | 3.62 | yes |
| sfx/car/tyre_squeal_loop_0.ogg | new | lateral slip > threshold (loop, volume by slip) | 1.75 | yes |
| sfx/car/tyre_squeal_loop_1.ogg | new | lateral slip > threshold (loop, volume by slip) | 1.45 | yes |
| sfx/car/tyre_squeal_loop_2.ogg | new | lateral slip > threshold (loop, volume by slip) | 1.34 | yes |

## Crash heavy / mid and bump sets (have)

| file | status | trigger | dur s | loop |
|---|---|---|---|---|
| sfx/car_bump_0.ogg | replaces (this branch) | CityCar::crash_sound sev < 5 (drop-in) | 0.38 |  |
| sfx/car_bump_1.ogg | replaces (this branch) | CityCar::crash_sound sev < 5 (drop-in) | 0.46 |  |
| sfx/car_bump_2.ogg | replaces (this branch) | CityCar::crash_sound sev < 5 (drop-in) | 0.51 |  |
| sfx/car_crash_heavy_0.ogg | replaces (this branch) | CityCar::crash_sound sev >= 10 (drop-in) | 2.02 |  |
| sfx/car_crash_heavy_1.ogg | replaces (this branch) | CityCar::crash_sound sev >= 10 (drop-in) | 2.14 |  |
| sfx/car_crash_heavy_2.ogg | replaces (this branch) | CityCar::crash_sound sev >= 10 (drop-in) | 1.92 |  |
| sfx/car_crash_mid_0.ogg | replaces (this branch) | CityCar::crash_sound sev 5-10 (drop-in) | 1.51 |  |
| sfx/car_crash_mid_1.ogg | replaces (this branch) | CityCar::crash_sound sev 5-10 (drop-in) | 1.47 |  |
| sfx/car_crash_mid_2.ogg | replaces (this branch) | CityCar::crash_sound sev 5-10 (drop-in) | 1.46 |  |

## Doors: wood, glass, metal, shop door with bell, locked rattle (P1)

| file | status | trigger | dur s | loop |
|---|---|---|---|---|
| sfx/door/door_glass_close_0.ogg | new | door closes | 1.19 |  |
| sfx/door/door_glass_close_1.ogg | new | door closes | 1.19 |  |
| sfx/door/door_glass_close_2.ogg | new | door closes | 1.20 |  |
| sfx/door/door_glass_close_3.ogg | new | door closes | 1.20 |  |
| sfx/door/door_glass_open_0.ogg | new | CityRooms door opens (B34) | 1.14 |  |
| sfx/door/door_glass_open_1.ogg | new | CityRooms door opens (B34) | 1.20 |  |
| sfx/door/door_glass_open_2.ogg | new | CityRooms door opens (B34) | 1.08 |  |
| sfx/door/door_glass_open_3.ogg | new | CityRooms door opens (B34) | 1.14 |  |
| sfx/door/door_locked_rattle_0.ogg | new | player tries a locked door | 1.19 |  |
| sfx/door/door_locked_rattle_1.ogg | new | player tries a locked door | 1.26 |  |
| sfx/door/door_locked_rattle_2.ogg | new | player tries a locked door | 1.24 |  |
| sfx/door/door_locked_rattle_3.ogg | new | player tries a locked door | 1.27 |  |
| sfx/door/door_metal_close_0.ogg | new | door closes | 1.20 |  |
| sfx/door/door_metal_close_1.ogg | new | door closes | 1.14 |  |
| sfx/door/door_metal_close_2.ogg | new | door closes | 1.18 |  |
| sfx/door/door_metal_close_3.ogg | new | door closes | 1.17 |  |
| sfx/door/door_metal_open_0.ogg | new | CityRooms door opens (B34) | 1.12 |  |
| sfx/door/door_metal_open_1.ogg | new | CityRooms door opens (B34) | 1.11 |  |
| sfx/door/door_metal_open_2.ogg | new | CityRooms door opens (B34) | 1.17 |  |
| sfx/door/door_metal_open_3.ogg | new | CityRooms door opens (B34) | 1.06 |  |
| sfx/door/door_shop_bell_0.ogg | new | shop door opens | 1.76 |  |
| sfx/door/door_shop_bell_1.ogg | new | shop door opens | 1.76 |  |
| sfx/door/door_shop_bell_2.ogg | new | shop door opens | 1.76 |  |
| sfx/door/door_shop_bell_3.ogg | new | shop door opens | 1.76 |  |
| sfx/door/door_wood_close_0.ogg | new | door closes | 1.16 |  |
| sfx/door/door_wood_close_1.ogg | new | door closes | 1.13 |  |
| sfx/door/door_wood_close_2.ogg | new | door closes | 1.18 |  |
| sfx/door/door_wood_close_3.ogg | new | door closes | 1.17 |  |
| sfx/door/door_wood_open_0.ogg | new | CityRooms door opens (B34) | 1.20 |  |
| sfx/door/door_wood_open_1.ogg | new | CityRooms door opens (B34) | 1.20 |  |
| sfx/door/door_wood_open_2.ogg | new | CityRooms door opens (B34) | 1.06 |  |
| sfx/door/door_wood_open_3.ogg | new | CityRooms door opens (B34) | 1.20 |  |

## UI tick (have)

| file | status | trigger | dur s | loop |
|---|---|---|---|---|
| sfx/ui_tick.wav | replaces (this branch) | CityHud tick (drop-in, WAV 22.05 kHz) | 0.12 |  |

## Footsteps walk on concrete, dirt, grass, metal, sand, tile, wood (have)

| file | status | trigger | dur s | loop |
|---|---|---|---|---|
| steps/footstep_concrete_000.ogg | drop-in (path from claude/perf-bugs) | FootSteps::step (drop-in, 5 per surface) | 0.30 |  |
| steps/footstep_concrete_001.ogg | drop-in (path from claude/perf-bugs) | FootSteps::step (drop-in, 5 per surface) | 0.30 |  |
| steps/footstep_concrete_002.ogg | drop-in (path from claude/perf-bugs) | FootSteps::step (drop-in, 5 per surface) | 0.30 |  |
| steps/footstep_concrete_003.ogg | drop-in (path from claude/perf-bugs) | FootSteps::step (drop-in, 5 per surface) | 0.30 |  |
| steps/footstep_concrete_004.ogg | drop-in (path from claude/perf-bugs) | FootSteps::step (drop-in, 5 per surface) | 0.16 |  |
| steps/footstep_dirt_000.ogg | drop-in (path from claude/perf-bugs) | FootSteps::step (drop-in, 5 per surface) | 0.30 |  |
| steps/footstep_dirt_001.ogg | drop-in (path from claude/perf-bugs) | FootSteps::step (drop-in, 5 per surface) | 0.30 |  |
| steps/footstep_dirt_002.ogg | drop-in (path from claude/perf-bugs) | FootSteps::step (drop-in, 5 per surface) | 0.25 |  |
| steps/footstep_dirt_003.ogg | drop-in (path from claude/perf-bugs) | FootSteps::step (drop-in, 5 per surface) | 0.25 |  |
| steps/footstep_dirt_004.ogg | drop-in (path from claude/perf-bugs) | FootSteps::step (drop-in, 5 per surface) | 0.27 |  |
| steps/footstep_grass_000.ogg | drop-in (path from claude/perf-bugs) | FootSteps::step (drop-in, 5 per surface) | 0.30 |  |
| steps/footstep_grass_001.ogg | drop-in (path from claude/perf-bugs) | FootSteps::step (drop-in, 5 per surface) | 0.30 |  |
| steps/footstep_grass_002.ogg | drop-in (path from claude/perf-bugs) | FootSteps::step (drop-in, 5 per surface) | 0.30 |  |
| steps/footstep_grass_003.ogg | drop-in (path from claude/perf-bugs) | FootSteps::step (drop-in, 5 per surface) | 0.32 |  |
| steps/footstep_grass_004.ogg | drop-in (path from claude/perf-bugs) | FootSteps::step (drop-in, 5 per surface) | 0.32 |  |
| steps/footstep_metal_000.ogg | drop-in (path from claude/perf-bugs) | FootSteps::step (drop-in, 5 per surface) | 0.25 |  |
| steps/footstep_metal_001.ogg | drop-in (path from claude/perf-bugs) | FootSteps::step (drop-in, 5 per surface) | 0.30 |  |
| steps/footstep_metal_002.ogg | drop-in (path from claude/perf-bugs) | FootSteps::step (drop-in, 5 per surface) | 0.30 |  |
| steps/footstep_metal_003.ogg | drop-in (path from claude/perf-bugs) | FootSteps::step (drop-in, 5 per surface) | 0.30 |  |
| steps/footstep_metal_004.ogg | drop-in (path from claude/perf-bugs) | FootSteps::step (drop-in, 5 per surface) | 0.30 |  |
| steps/footstep_sand_000.ogg | drop-in (path from claude/perf-bugs) | FootSteps::step (drop-in, 5 per surface) | 0.30 |  |
| steps/footstep_sand_001.ogg | drop-in (path from claude/perf-bugs) | FootSteps::step (drop-in, 5 per surface) | 0.32 |  |
| steps/footstep_sand_002.ogg | drop-in (path from claude/perf-bugs) | FootSteps::step (drop-in, 5 per surface) | 0.32 |  |
| steps/footstep_sand_003.ogg | drop-in (path from claude/perf-bugs) | FootSteps::step (drop-in, 5 per surface) | 0.27 |  |
| steps/footstep_sand_004.ogg | drop-in (path from claude/perf-bugs) | FootSteps::step (drop-in, 5 per surface) | 0.29 |  |
| steps/footstep_tile_000.ogg | drop-in (path from claude/perf-bugs) | FootSteps::step (drop-in, 5 per surface) | 0.30 |  |
| steps/footstep_tile_001.ogg | drop-in (path from claude/perf-bugs) | FootSteps::step (drop-in, 5 per surface) | 0.30 |  |
| steps/footstep_tile_002.ogg | drop-in (path from claude/perf-bugs) | FootSteps::step (drop-in, 5 per surface) | 0.30 |  |
| steps/footstep_tile_003.ogg | drop-in (path from claude/perf-bugs) | FootSteps::step (drop-in, 5 per surface) | 0.30 |  |
| steps/footstep_tile_004.ogg | drop-in (path from claude/perf-bugs) | FootSteps::step (drop-in, 5 per surface) | 0.32 |  |
| steps/footstep_wood_000.ogg | drop-in (path from claude/perf-bugs) | FootSteps::step (drop-in, 5 per surface) | 0.30 |  |
| steps/footstep_wood_001.ogg | drop-in (path from claude/perf-bugs) | FootSteps::step (drop-in, 5 per surface) | 0.32 |  |
| steps/footstep_wood_002.ogg | drop-in (path from claude/perf-bugs) | FootSteps::step (drop-in, 5 per surface) | 0.30 |  |
| steps/footstep_wood_003.ogg | drop-in (path from claude/perf-bugs) | FootSteps::step (drop-in, 5 per surface) | 0.29 |  |
| steps/footstep_wood_004.ogg | drop-in (path from claude/perf-bugs) | FootSteps::step (drop-in, 5 per surface) | 0.11 |  |

## Footsteps run / sprint / land variants (P1)

| file | status | trigger | dur s | loop |
|---|---|---|---|---|
| steps/footstep_land_concrete_000.ogg | new | player lands from a jump / fall | 0.37 |  |
| steps/footstep_land_concrete_001.ogg | new | player lands from a jump / fall | 0.30 |  |
| steps/footstep_land_concrete_002.ogg | new | player lands from a jump / fall | 0.44 |  |
| steps/footstep_land_concrete_003.ogg | new | player lands from a jump / fall | 0.58 |  |
| steps/footstep_land_dirt_000.ogg | new | player lands from a jump / fall | 0.82 |  |
| steps/footstep_land_dirt_001.ogg | new | player lands from a jump / fall | 0.84 |  |
| steps/footstep_land_dirt_002.ogg | new | player lands from a jump / fall | 0.79 |  |
| steps/footstep_land_dirt_003.ogg | new | player lands from a jump / fall | 0.84 |  |
| steps/footstep_land_grass_000.ogg | new | player lands from a jump / fall | 0.59 |  |
| steps/footstep_land_grass_001.ogg | new | player lands from a jump / fall | 0.69 |  |
| steps/footstep_land_grass_002.ogg | new | player lands from a jump / fall | 0.50 |  |
| steps/footstep_land_grass_003.ogg | new | player lands from a jump / fall | 0.52 |  |
| steps/footstep_land_metal_000.ogg | new | player lands from a jump / fall | 0.70 |  |
| steps/footstep_land_metal_001.ogg | new | player lands from a jump / fall | 0.61 |  |
| steps/footstep_land_metal_002.ogg | new | player lands from a jump / fall | 0.78 |  |
| steps/footstep_land_metal_003.ogg | new | player lands from a jump / fall | 0.74 |  |
| steps/footstep_land_sand_000.ogg | new | player lands from a jump / fall | 0.80 |  |
| steps/footstep_land_sand_001.ogg | new | player lands from a jump / fall | 0.88 |  |
| steps/footstep_land_sand_002.ogg | new | player lands from a jump / fall | 0.78 |  |
| steps/footstep_land_sand_003.ogg | new | player lands from a jump / fall | 0.90 |  |
| steps/footstep_land_tile_000.ogg | new | player lands from a jump / fall | 0.76 |  |
| steps/footstep_land_tile_001.ogg | new | player lands from a jump / fall | 0.73 |  |
| steps/footstep_land_tile_002.ogg | new | player lands from a jump / fall | 0.74 |  |
| steps/footstep_land_tile_003.ogg | new | player lands from a jump / fall | 0.59 |  |
| steps/footstep_land_wood_000.ogg | new | player lands from a jump / fall | 0.54 |  |
| steps/footstep_land_wood_001.ogg | new | player lands from a jump / fall | 0.35 |  |
| steps/footstep_land_wood_002.ogg | new | player lands from a jump / fall | 1.00 |  |
| steps/footstep_land_wood_003.ogg | new | player lands from a jump / fall | 0.53 |  |
| steps/footstep_run_concrete_000.ogg | new | FootSteps::step when speed > 3 m/s (run blend) | 0.24 |  |
| steps/footstep_run_concrete_001.ogg | new | FootSteps::step when speed > 3 m/s (run blend) | 0.24 |  |
| steps/footstep_run_concrete_002.ogg | new | FootSteps::step when speed > 3 m/s (run blend) | 0.26 |  |
| steps/footstep_run_concrete_003.ogg | new | FootSteps::step when speed > 3 m/s (run blend) | 0.23 |  |
| steps/footstep_run_concrete_004.ogg | new | FootSteps::step when speed > 3 m/s (run blend) | 0.24 |  |
| steps/footstep_run_dirt_000.ogg | new | FootSteps::step when speed > 3 m/s (run blend) | 0.24 |  |
| steps/footstep_run_dirt_001.ogg | new | FootSteps::step when speed > 3 m/s (run blend) | 0.24 |  |
| steps/footstep_run_dirt_002.ogg | new | FootSteps::step when speed > 3 m/s (run blend) | 0.24 |  |
| steps/footstep_run_dirt_003.ogg | new | FootSteps::step when speed > 3 m/s (run blend) | 0.24 |  |
| steps/footstep_run_dirt_004.ogg | new | FootSteps::step when speed > 3 m/s (run blend) | 0.24 |  |
| steps/footstep_run_grass_000.ogg | new | FootSteps::step when speed > 3 m/s (run blend) | 0.24 |  |
| steps/footstep_run_grass_001.ogg | new | FootSteps::step when speed > 3 m/s (run blend) | 0.24 |  |
| steps/footstep_run_grass_002.ogg | new | FootSteps::step when speed > 3 m/s (run blend) | 0.24 |  |
| steps/footstep_run_grass_003.ogg | new | FootSteps::step when speed > 3 m/s (run blend) | 0.24 |  |
| steps/footstep_run_grass_004.ogg | new | FootSteps::step when speed > 3 m/s (run blend) | 0.24 |  |
| steps/footstep_run_metal_000.ogg | new | FootSteps::step when speed > 3 m/s (run blend) | 0.24 |  |
| steps/footstep_run_metal_001.ogg | new | FootSteps::step when speed > 3 m/s (run blend) | 0.24 |  |
| steps/footstep_run_metal_002.ogg | new | FootSteps::step when speed > 3 m/s (run blend) | 0.20 |  |
| steps/footstep_run_metal_003.ogg | new | FootSteps::step when speed > 3 m/s (run blend) | 0.24 |  |
| steps/footstep_run_metal_004.ogg | new | FootSteps::step when speed > 3 m/s (run blend) | 0.24 |  |
| steps/footstep_run_sand_000.ogg | new | FootSteps::step when speed > 3 m/s (run blend) | 0.24 |  |
| steps/footstep_run_sand_001.ogg | new | FootSteps::step when speed > 3 m/s (run blend) | 0.24 |  |
| steps/footstep_run_sand_002.ogg | new | FootSteps::step when speed > 3 m/s (run blend) | 0.24 |  |
| steps/footstep_run_sand_003.ogg | new | FootSteps::step when speed > 3 m/s (run blend) | 0.24 |  |
| steps/footstep_run_sand_004.ogg | new | FootSteps::step when speed > 3 m/s (run blend) | 0.21 |  |
| steps/footstep_run_tile_000.ogg | new | FootSteps::step when speed > 3 m/s (run blend) | 0.23 |  |
| steps/footstep_run_tile_001.ogg | new | FootSteps::step when speed > 3 m/s (run blend) | 0.24 |  |
| steps/footstep_run_tile_002.ogg | new | FootSteps::step when speed > 3 m/s (run blend) | 0.22 |  |
| steps/footstep_run_tile_003.ogg | new | FootSteps::step when speed > 3 m/s (run blend) | 0.24 |  |
| steps/footstep_run_tile_004.ogg | new | FootSteps::step when speed > 3 m/s (run blend) | 0.22 |  |
| steps/footstep_run_wood_000.ogg | new | FootSteps::step when speed > 3 m/s (run blend) | 0.12 |  |
| steps/footstep_run_wood_001.ogg | new | FootSteps::step when speed > 3 m/s (run blend) | 0.13 |  |
| steps/footstep_run_wood_002.ogg | new | FootSteps::step when speed > 3 m/s (run blend) | 0.24 |  |
| steps/footstep_run_wood_003.ogg | new | FootSteps::step when speed > 3 m/s (run blend) | 0.13 |  |
| steps/footstep_run_wood_004.ogg | new | FootSteps::step when speed > 3 m/s (run blend) | 0.14 |  |

## Ringtones, message ping, app taps, notifications (P1)

| file | status | trigger | dur s | loop |
|---|---|---|---|---|
| ui/app_tap_0.ogg | new | phone app button press | 0.11 |  |
| ui/app_tap_1.ogg | new | phone app button press | 0.11 |  |
| ui/app_tap_2.ogg | new | phone app button press | 0.10 |  |
| ui/app_tap_3.ogg | new | phone app button press | 0.12 |  |
| ui/msg_ping_0.ogg | new | message received | 0.68 |  |
| ui/msg_ping_1.ogg | new | message received | 0.47 |  |
| ui/msg_ping_2.ogg | new | message received | 0.67 |  |
| ui/msg_ping_3.ogg | new | message received | 0.59 |  |
| ui/notify_0.ogg | new | app notification / mission update | 0.79 |  |
| ui/notify_1.ogg | new | app notification / mission update | 0.73 |  |
| ui/notify_2.ogg | new | app notification / mission update | 0.79 |  |
| ui/notify_3.ogg | new | app notification / mission update | 0.49 |  |
| ui/ringtone_0.ogg | new | incoming call (loop until answered) | 1.98 | yes |
| ui/ringtone_1.ogg | new | incoming call (loop until answered) | 4.00 | yes |
| ui/ringtone_2.ogg | new | incoming call (loop until answered) | 1.97 | yes |

## Camera shutter (P1)

| file | status | trigger | dur s | loop |
|---|---|---|---|---|
| ui/camera_shutter_0.ogg | new | phone camera photo | 0.29 |  |
| ui/camera_shutter_1.ogg | new | phone camera photo | 0.35 |  |
| ui/camera_shutter_2.ogg | new | phone camera photo | 0.53 |  |
| ui/camera_shutter_3.ogg | new | phone camera photo | 0.27 |  |

## Mission start, pass, fail (P1)

| file | status | trigger | dur s | loop |
|---|---|---|---|---|
| ui/mission_fail_0.ogg | new | mission failed | 2.21 |  |
| ui/mission_fail_1.ogg | new | mission failed | 2.10 |  |
| ui/mission_fail_2.ogg | new | mission failed | 1.96 |  |
| ui/mission_fail_3.ogg | new | mission failed | 1.87 |  |
| ui/mission_pass_0.ogg | new | mission passed | 2.10 |  |
| ui/mission_pass_1.ogg | new | mission passed | 2.21 |  |
| ui/mission_pass_2.ogg | new | mission passed | 2.13 |  |
| ui/mission_pass_3.ogg | new | mission passed | 2.00 |  |
| ui/mission_start_0.ogg | new | mission begins | 2.03 |  |
| ui/mission_start_1.ogg | new | mission begins | 2.12 |  |
| ui/mission_start_2.ogg | new | mission begins | 2.09 |  |
| ui/mission_start_3.ogg | new | mission begins | 1.81 |  |
