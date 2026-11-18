extends RefCounted
## The four residential VARIANTS (18 Nov, zone growth; built by rv_lib.gd). Each is a neighbourhood character a
## planner would recognise, with its own lot pattern, houses, fences, planting, yard life and inside use (sub-block D).
## A quadrant piece takes one design and its own site (slope, seed): the houses are drawn from the design's list per
## lot (no repeat until the list is used up), so no two quadrants are dressed the same.
##   V1 village bungalows  the old core of the village: craftsman and Victorian bungalows, Cape Cods, white pickets
##                         and low hedges, big shade trees; D = the block's pocket playground
##   V2 spanish hill       1920s-30s Spanish Revival and Tudor on bigger lots (two to a sub-block on B and C), iron
##                         front fences, stucco garden walls with bougainvillea; D = older ranch houses fronting the
##                         alley with their own garages (built later, when the big back lots were split)
##   V3 beach cottages     narrow 8 m lots near the ocean: two-storey narrow houses and beach cottages, vinyl rail
##                         fronts, weathered board fences, kayaks and surf in the yards, boat trailers on the pads;
##                         D = a quiet green under a Norfolk pine
##   V4 mid-century        1950s-60s ranches, contemporaries and colonials, privet hedges or chain-link, flat-roof
##                         garages with solar; D = mid-century houses fronting the alley, garage doors to the lane
const V1 := {"name": "V1 village bungalows", "wear": 0.65,
	"houses": ["houses/craftsman_olive", "houses/craftsman_stucco", "houses/craftsman_large", "houses/craftsman_cedar", "houses/craftsman_sage",
		"houses/victorian_blue", "houses/victorian_yellow", "houses/cape_grey", "houses/cape_white", "houses/ranch_porch"],
	"garages": ["garages/single_siding_comp", "garages/double_siding_comp", "garages/carport_comp", "garages/single_stucco_comp"],
	"fronts": ["picket", "picket", "hedge", ""], "back": "privacy", "A": 3, "B": 3, "C": 3, "D": "park",
	"plants": ["plant_bird_of_paradise", "plant_agave_americana_small", "plant_iceplant_patch"],
	"front_trees": ["tree_jacaranda_a", "tree_jacaranda_b", "tree_magnolia_a"], "front_tree": 0.45,
	"back_trees": ["tree_ficus_a", "tree_ficus_b", "tree_coral_a", "tree_jacaranda_b", "tree_magnolia_b"],
	"yard": ["patio", "bbq", "chairs", "arbor", "line"], "pad_extras": ["prop_golf_cart_white"], "dry": 0.2}

const V2 := {"name": "V2 spanish hill", "wear": 0.6,
	"houses": ["houses/spanish_peach", "houses/spanish_pink", "houses/spanish_white", "houses/spanish_large", "houses/spanish_small",
		"houses/tudor_brick", "houses/tudor_stucco", "houses/narrow_2sty_stucco_clay"],
	"garages": ["garages/double_stucco_clay", "garages/single_stucco_clay", "garages/carport_clay"],
	"fronts": ["iron", "iron", "", "hedge"], "back": "stucco", "side": "privacy", "A": 3, "B": 2, "C": 2, "D": "cottages", "D_n": 2,
	"d_houses": ["houses/hipranch_sand", "houses/hipranch_grey", "houses/colonial_large_garage"], "d_front": "hedge",
	"wall_plants": true,
	"plants": ["plant_bougainvillea_mound", "plant_agave_americana", "plant_agave_americana_small", "plant_iceplant_patch"],
	"front_trees": ["palm_queen_a", "palm_mexican_fan_c", "tree_coral_b"], "front_tree": 0.5,
	"back_trees": ["tree_coral_a", "tree_coral_b", "palm_canary_date_b", "tree_ficus_a"],
	"yard": ["patio", "arbor", "bbq", "chairs"], "pad_extras": ["prop_golf_cart_blue"], "dry": 0.15}

const V3 := {"name": "V3 beach cottages", "wear": 0.75,
	"houses": ["houses/narrow_2sty_siding", "houses/narrow_2sty_stucco_clay", "houses/narrow_cottage_siding", "houses/narrow_cottage_stucco_clay",
		"houses/beach_white", "houses/beach_blue", "houses/beach_teal", "houses/spanish_small"],
	"garages": ["garages/carport_comp", "garages/carport_clay", "garages/single_siding_comp"],
	"fronts": ["vinyl", "vinyl", "picket", ""], "back": "board", "side": "board", "reno": 0.08, "A": 4, "B": 5, "C": 5, "D": "green",
	"plants": ["plant_iceplant_patch", "plant_agave_americana_small", "plant_bird_of_paradise"],
	"front_trees": ["palm_queen_b", "palm_mexican_fan_a"], "front_tree": 0.3,
	"back_trees": ["tree_torrey_pine_a", "tree_coral_a", "palm_queen_b"],
	"yard": ["kayak", "chairs", "line", "bbq", "kayak"], "pad_extras": ["prop_boat_trailer", "prop_golf_cart_blue", "prop_golf_cart_white"], "dry": 0.35}

const V4 := {"name": "V4 mid-century", "wear": 0.7,
	"houses": ["houses/ranch_pink", "houses/ranch_siding", "houses/ranch_porch", "houses/ranch_peach", "houses/hipranch_nogarage",
		"houses/contemporary_grey", "houses/contemporary_white", "houses/colonial_blue", "houses/colonial_white", "houses/cape_white"],
	"garages": ["garages/single_stucco_flat", "garages/double_stucco_comp", "garages/single_stucco_flat", "garages/single_stucco_comp"],
	"fronts": ["privet", "hedge", "", "chain"], "back": "privacy", "A": 3, "B": 3, "C": 3, "D": "cottages", "D_n": 2,
	"d_houses": ["houses/mcm_shed", "houses/mcm_white", "houses/mcm_large", "houses/mcm_teal"], "d_front": "",
	"plants": ["plant_agave_americana_small", "plant_iceplant_patch", "plant_bird_of_paradise", "plant_agave_americana"],
	"front_trees": ["palm_queen_a", "tree_magnolia_b", "tree_norfolk_pine_a"], "front_tree": 0.35,
	"back_trees": ["tree_magnolia_a", "tree_jacaranda_a", "tree_ficus_b", "tree_eucalyptus_a"],
	"yard": ["patio", "bbq", "line", "chairs"], "pad_extras": ["prop_golf_cart_white", "prop_boat_trailer"], "dry": 0.3}

static func get_design(k: String) -> Dictionary:
	match k:
		"V1": return V1
		"V2": return V2
		"V3": return V3
	return V4
