"""Which shop is behind every shop door of the CITY-CENTRE FILL (claude/fill-city-centre, 19 Nov; Yasin via the
session that started this one: "use the indoor generator in the pilot and do them both together"). A copy of
assign_strip.py. Hand-made: each building's businesses are chosen as part of its block's design (the piece script's
header says why); this table names them, splits rows into bays at their doors, and claims the sign boards. No real
brands.

Reads  map_dc/coronado/city_kit/interiors/cc_buildings.json, room_contracts_cc.json (room_contracts_cc.gd)
Writes map_dc/coronado/city_kit/interiors/assignment_cc.json (read by tools/city/rooms/room_gen_cc.gd). The shared
       assignment_all.json is not touched.
Run from the repo root: python3 -I tools/city/rooms/assign_cc.py
"""
import json, os

ROOT = os.path.abspath(os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "..", ".."))
IN = os.path.join(ROOT, "map_dc/coronado/city_kit/interiors")

# (piece, building label) -> list of shops: (door along of the shop's main entrance, bay [x0, x1] in the model frame or
# None = the whole floor, kind of room_gen_strip.KINDS, shop name, sign style)
SHOPS = {
    # Amber wall (n_cc_b1_am): the centre's main street, offices over shops
    ("n_cc_b1_am", "amber6_tower"): [(0.0, None, "lobby", "Sixth & Amber Tower", "black")],
    ("n_cc_b1_am", "amber_bank"): [(6.8, None, "bank", "Amber Savings Bank", "navy")],
    ("n_cc_b1_am", "amber_deli_row"): [(-4.1, [-8.7, -1.1], "restaurant", "Marlowe's Deli", "red"),
                                       (1.9, [-1.1, 4.9], "clothes", "Ferris Tailors", "navy"),
                                       (7.9, [4.9, 8.7], "keys", "Fix-It Phone Repair", "black")],
    ("n_cc_b1_am", "amber_barber_fe"): [(-1.1, [-5.7, 2.2], "salon", "Seventh Wave Barbers", "red")],
    ("n_cc_b1_am", "amber_corner_cafe"): [(4.9, [-1.8, 5.7], "cafe", "Court Side Coffee", "teal")],
    # 6th St row (n_cc_b1_n): the neighbourhood's daily errands
    ("n_cc_b1_n", "sixth_corner_shop"): [(4.9, [-1.8, 5.7], "corner_shop", "Sixth St Market", "sun")],
    ("n_cc_b1_n", "sixth_brick_row"): [(-4.1, [-8.7, -1.1], "store", "Island Hardware", "red"),
                                       (1.9, [-1.1, 4.9], "cleaners", "Sixth St Laundromat", "sea"),
                                       (7.9, [4.9, 8.7], "jewelry", "Watch & Jewel Repair", "black")],
    ("n_cc_b1_n", "sixth_diner_block"): [(0.0, [-5.4, 5.4], "restaurant", "Sixth Street Diner", "teal")],
    ("n_cc_b1_n", "sixth_pharmacy"): [(-1.1, [-5.7, 2.2], "pharmacy", "Downtown Pharmacy", "green")],
    ("n_cc_b1_n", "alleyc_print_shop"): [(None, None, "print", "Alley Sign & Print", "black")],
    ("n_cc_b1_n", "alleyc_bike_repair"): [(None, None, "bike", "Spokes Bike Repair", "sea")],
    # C Ave (n_cc_b1_west)
    ("n_cc_b1_west", "cave_corner_flats"): [(0.0, [-5.4, 5.4], "bakery", "C Avenue Bakery", "sun")],
    ("n_cc_b1_west", "downtown_church"): [(0.0, None, "church", "Sacred Heart Church", "navy")],
    # courthouse block (n_cc_b1_court)
    ("n_cc_b1_court", "courthouse"): [(0.0, None, "court", "Coronado County Courthouse", "navy")],
    ("n_cc_b1_court", "law_office_n"): [(-1.1, [-5.7, 2.2], "law", "Hale & Ortiz Attorneys", "navy")],
    ("n_cc_b1_court", "law_office_s"): [(-1.1, [-5.7, 2.2], "bail", "Bayview Bail Bonds", "red")],
    ("n_cc_b1_court", "district_attorney"): [(1.9, None, "law", "District Attorney", "navy")],
    ("n_cc_b1_court", "legal_aid"): [(-1.1, [-5.7, 2.2], "office", "Island Legal Aid", "teal")],
    # ---- block 2
    ("n_cc_b2_am", "amber_e_brick_row"): [(-4.1, [-8.7, -1.1], "ice_cream", "Scoops on Amber", "sea"),
                                          (1.9, [-1.1, 4.9], "jewelry", "Island Jewellers", "black"),
                                          (7.9, [4.9, 8.7], "gallery", "Amber Gallery", "navy")],
    ("n_cc_b2_am", "amber_e_wine_block"): [(0.0, [-5.4, 5.4], "bar", "Cork & Barrel Wine Bar", "red")],
    ("n_cc_b2_am", "amber_e_shoes_fe"): [(-1.1, [-5.7, 2.2], "shoes", "Step Lively Shoes", "teal")],
    ("n_cc_b2_n", "sixth_e_corner_cafe"): [(4.9, [-1.8, 5.7], "cafe", "Corner Grind", "black")],
    ("n_cc_b2_n", "sixth_e_thai_block"): [(0.0, [-5.4, 5.4], "restaurant", "Thai Orchid", "red")],
    ("n_cc_b2_n", "sixth_e_brick_row"): [(-4.1, [-8.7, -1.1], "books", "Sixth Street Books", "green"),
                                         (1.9, [-1.1, 4.9], "souvenir", "Paper & Gifts", "sun"),
                                         (7.9, [4.9, 8.7], "keys", "Shoe & Key Repair", "black")],
    ("n_cc_b2_n", "sixth_e_shop_row"): [(-4.1, [-8.7, -1.1], "clothes", "Thread Boutique", "navy"),
                                        (1.9, [-1.1, 4.9], "salon", "Glow Hair Studio", "red"),
                                        (7.9, [4.9, 8.7], "store", "Hobby Corner", "sun")],
    ("n_cc_b2_n", "sixth_e_corner_store_block"): [(0.0, [-5.4, 5.4], "corner_shop", "Bayside Grocery", "green")],
    ("n_cc_b2_n", "sixth_e_dentist"): [(-1.1, [-5.7, 2.2], "office", "Sixth Street Dental", "teal")],
    ("n_cc_b2_n", "sixth_e_corner_bar"): [(4.9, [-1.8, 5.7], "bar", "The Alley Cat", "black")],
    ("n_cc_b2_n", "alleyc2_upholstery"): [(None, None, "keys", "Bay Upholstery", "navy")],
    ("n_cc_b2_e", "sixth_bave_corner"): [(6.8, None, "restaurant", "Casa Bonita", "sun")],
    ("n_cc_b2_e", "sixth_bave_condo"): [(0.0, [-5.0, 5.0], "bakery", "Sunrise Bakery", "sun")],
    ("n_cc_b2_s", "alleyc2s_architects"): [(-1.1, [-5.7, 2.2], "law", "Alcala Architects", "black")],
    ("n_cc_b2_7th", "seventh_insurance"): [(6.8, None, "law", "Pacific Insurance", "navy")],
    ("n_cc_b2_7th", "seventh_burger_block"): [(0.0, [-5.4, 5.4], "fast_food", "Seventh Street Burgers", "red")],
    ("n_cc_b2_7th", "seventh_brick_row"): [(-4.1, [-8.7, -1.1], "sport", "Strand Sports", "sea"),
                                           (1.9, [-1.1, 4.9], "souvenir", "Toy Chest", "sun"),
                                           (7.9, [4.9, 8.7], "gallery", "Seventh Art Supply", "teal")],
    ("n_cc_b2_7th", "seventh_dept_store"): [(None, None, "clothes", "Harbor & Main", "navy")],
    ("n_cc_b2_7th", "alleyd2_tailor"): [(None, None, "cleaners", "Pressed Dry Cleaners", "sea")],
    ("n_cc_b2_7th", "alleyd2_pawn"): [(None, None, "store", "Island Pawn", "red")],
    ("n_cc_b2_7th", "alleyd2_locksmith"): [(None, None, "keys", "Ace Locksmith", "black")],
    # ---- block 3
    ("n_cc_b3_am", "amber8_glass_tower"): [(0.0, None, "lobby", "Eighth & Amber Tower", "black")],
    ("n_cc_b3_am", "amber_se_florist"): [(-1.1, [-5.7, 2.2], "souvenir", "Bloom & Twig Flowers", "green")],
    ("n_cc_b3_am", "amber_se_taverna_block"): [(0.0, [-5.4, 5.4], "restaurant", "Kalimera Taverna", "sea")],
    ("n_cc_b3_am", "amber_se_brick_row"): [(-4.1, [-8.7, -1.1], "jewelry", "Clear View Opticians", "navy"),
                                           (1.9, [-1.1, 4.9], "books", "Pen & Ink Stationers", "black"),
                                           (7.9, [4.9, 8.7], "clothes", "Quick Alterations", "red")],
    ("n_cc_b3_am", "amber_se_corner_cafe"): [(4.9, [-1.8, 5.7], "cafe", "Roastery on Amber", "black")],
    ("n_cc_b3_arm", "seventh_s_newsagent"): [(4.9, [-1.8, 5.7], "corner_shop", "Seventh Street News", "red")],
    ("n_cc_b3_arm", "seventh_s_pizza_block"): [(0.0, [-5.4, 5.4], "fast_food", "Slice House Pizza", "red")],
    ("n_cc_b3_arm", "seventh_s_arcade"): [(-5.08, [-11.7, 1.0], "clothes", "Arcade Outfitters", "teal"),
                                          (5.08, [1.0, 11.7], "office", "Bay Travel", "sea")],
    ("n_cc_b3_arm", "seventh_s_brick_row"): [(-4.1, [-8.7, -1.1], "sport", "Coast Surf & Skate", "sea"),
                                             (1.9, [-1.1, 4.9], "store", "Seventh Music", "black"),
                                             (7.9, [4.9, 8.7], "jewelry", "Time Works", "navy")],
    ("n_cc_b3_arm", "seventh_s_laundry_fe"): [(-1.1, [-5.7, 2.2], "cleaners", "Bubbles Laundromat", "sea")],
    ("n_cc_b3_arm", "alleyd3_print"): [(None, None, "print", "Copy Corner", "black")],
    ("n_cc_b3_arm", "alleyd3_pharm_depot"): [(4.6, [-1.0, 5.7], "pharmacy", "Bayside Pharmacy", "green")],
    ("n_cc_b3_arm", "alleyd3_bike_works"): [(None, None, "bike", "Gear Bike Works", "red")],
    ("n_cc_b3_arm", "alleyd3_sign_shop"): [(None, None, "keys", "Neon Sign Co", "navy")],
    ("n_cc_b3_main", "c3n_framer"): [(None, None, "gallery", "Frame & Hang", "black")],
    ("n_cc_b3_main", "eighth_corner_cafe"): [(4.9, [-1.8, 5.7], "cafe", "Eighth Street Coffee", "teal")],
    ("n_cc_b3_main", "eighth_trattoria_block"): [(0.0, [-5.4, 5.4], "restaurant", "Trattoria Uphill", "red")],
    ("n_cc_b3_main", "eighth_brick_row"): [(-4.1, [-8.7, -1.1], "ice_cream", "Sundae Best", "sun"),
                                           (1.9, [-1.1, 4.9], "shoes", "Sole Mates", "navy"),
                                           (7.9, [4.9, 8.7], "keys", "Key & Lock", "black")],
    ("n_cc_b3_main", "eighth_records_fe"): [(-1.1, [-5.7, 2.2], "store", "Groove Records", "black")],
    ("n_cc_b3_main", "eighth_stucco_block"): [(0.0, [-5.4, 5.4], "corner_shop", "Uphill Market", "green")],
    ("n_cc_b3_main", "eighth_hardware_row"): [(-4.1, [-8.7, -1.1], "store", "Eighth St Hardware", "red"),
                                              (1.9, [-1.1, 4.9], "salon", "Snip Barbers", "navy"),
                                              (7.9, [4.9, 8.7], "souvenir", "Gift Box", "sun")],
    ("n_cc_b3_main", "eighth_optician"): [(-1.1, [-5.7, 2.2], "office", "Uphill Dental", "teal")],
    ("n_cc_b3_main", "eighth_bakery_condo"): [(0.0, [-5.0, 5.0], "bakery", "Crumbs Bakery", "sun")],
    ("n_cc_b3_main", "eighth_corner_bar"): [(4.9, [-1.8, 5.7], "bar", "The Uphill Tap", "black")],
    ("n_cc_b3_main", "eighth_bave_pharmacy"): [(6.8, None, "pharmacy", "Corner Pharmacy", "green")],
    # ---- blocks 4-6 (hand-made shop lists; residential walk-ups have no shop)
    ("n_cc_b4_w", "cave6_condo_tower"): [(0.0, None, "lobby", "Sixth & C Residences", "black")],
    ("n_cc_b4_e", "amber6n_corner"): [(6.8, None, "pharmacy", "Northside Pharmacy", "green")],
    ("n_cc_b4_e", "sixth_n_corner_deli"): [(4.9, [-1.8, 5.7], "restaurant", "Alley Corner Deli", "red")],
    ("n_cc_b4_e", "sixth_n_brick_row"): [(-4.1, [-8.7, -1.1], "books", "Hillside Books", "green"), (1.9, [-1.1, 4.9], "salon", "Curl Up Salon", "red"), (7.9, [4.9, 8.7], "keys", "Key Point", "black")],
    ("n_cc_b4_e", "sixth_n_stucco_block"): [(0.0, [-5.4, 5.4], "restaurant", "Little Lisbon", "sea")],
    ("n_cc_b4_e", "sixth_n_florist"): [(-1.1, [-5.7, 2.2], "souvenir", "Petal & Stem", "sun")],
    ("n_cc_b4_e", "sixth_n_shop_row"): [(-4.1, [-8.7, -1.1], "clothes", "Second Thread", "navy"), (1.9, [-1.1, 4.9], "ice_cream", "Cone Zone", "sun"), (7.9, [4.9, 8.7], "jewelry", "Little Gems", "black")],
    ("n_cc_b4_e", "sixth_n_bookshop_fe"): [(-1.1, [-5.7, 2.2], "gallery", "North Wall Gallery", "black")],
    ("n_cc_b4_e", "sixth_n_beach_condo"): [(0.0, [-5.0, 5.0], "cafe", "Morning Tide Cafe", "teal")],
    ("n_cc_b4_e", "amber_n_tea"): [(-1.1, [-5.7, 2.2], "cafe", "Leaf & Kettle Tea", "green")],
    ("n_cc_b4_e", "amber_n_corner_bar"): [(4.9, [-1.8, 5.7], "bar", "The Hill Bar", "black")],
    ("n_cc_b4_e", "amber_n_records_fe"): [(-1.1, [-5.7, 2.2], "store", "Uphill Vinyl", "black")],
    ("n_cc_b4_e", "amber_n_tattoo"): [(-1.1, [-5.7, 2.2], "salon", "Ink Hill Tattoo", "red")],
    ("n_cc_b4_e", "amber_n_vintage_fe"): [(-1.1, [-5.7, 2.2], "clothes", "Amber Vintage", "navy")],
    ("n_cc_b4_e", "amber_n_bike"): [(-1.1, [-5.7, 2.2], "bike", "Climb Cycles", "sea")],
    ("n_cc_b4_e", "amber_n_corner_cafe"): [(4.9, [-1.8, 5.7], "cafe", "Top of Amber Coffee", "teal")],
    ("n_cc_b4_e", "amber_n_frames"): [(-1.1, [-5.7, 2.2], "gallery", "Hill Frames", "black")],
    ("n_cc_b4_e", "amber_n_yoga_fe"): [(-1.1, [-5.7, 2.2], "office", "Amber Yoga", "sea")],
    ("n_cc_b4_e", "l4n_joiner"): [(None, None, "keys", "Hill Joinery", "navy")],
    ("n_cc_b4_e", "l4s_upholstery"): [(None, None, "store", "Lane Upholstery", "red")],
    ("n_cc_b4_e", "l4s_glazier"): [(None, None, "keys", "Clear Glass Co", "sea")],
    ("n_cc_b5_w", "amber6ne_corner"): [(6.8, None, "bank", "Coastal Credit Union", "navy")],
    ("n_cc_b5_w", "sixth_ne_tailor"): [(-1.1, [-5.7, 2.2], "clothes", "Needle & Pin Tailors", "navy")],
    ("n_cc_b5_w", "sixth_ne_noodle_block"): [(0.0, [-5.4, 5.4], "restaurant", "Noodle Bar Six", "red")],
    ("n_cc_b5_w", "sixth_ne_brick_row"): [(-4.1, [-8.7, -1.1], "shoes", "Sole Sixth", "teal"), (1.9, [-1.1, 4.9], "books", "Comic Vault", "sun"), (7.9, [4.9, 8.7], "keys", "Phone Fix Six", "black")],
    ("n_cc_b5_w", "sixth_ne_games_fe"): [(-1.1, [-5.7, 2.2], "store", "Dice & Board Games", "sun")],
    ("n_cc_b5_w", "sixth_ne_arcade"): [(-5.08, [-11.7, 1.0], "clothes", "Arcade Threads", "teal"), (5.08, [1.0, 11.7], "office", "Sunny Travel", "sea")],
    ("n_cc_b5_w", "sixth_ne_hat_shop"): [(-1.1, [-5.7, 2.2], "clothes", "Top Hat Shop", "black")],
    ("n_cc_b5_w", "sixth_ne_shop_row"): [(-4.1, [-8.7, -1.1], "sport", "Island Running", "sea"), (1.9, [-1.1, 4.9], "souvenir", "Shell & Sand Gifts", "sun"), (7.9, [4.9, 8.7], "jewelry", "Silver Lining", "black")],
    ("n_cc_b5_w", "sixth_ne_beach_condo"): [(0.0, [-5.0, 5.0], "ice_cream", "Gelato Six", "sun")],
    ("n_cc_b5_w", "sixth_ne_taqueria_block"): [(0.0, [-5.4, 5.4], "fast_food", "Taqueria El Sol", "red")],
    ("n_cc_b5_w", "sixth_ne_alley_corner"): [(4.9, [-1.8, 5.7], "corner_shop", "B Alley Market", "green")],
    ("n_cc_b5_w", "amber_ne_camera_fe"): [(-1.1, [-5.7, 2.2], "store", "Amber Camera", "black")],
    ("n_cc_b5_w", "amber_ne_perfume"): [(-1.1, [-5.7, 2.2], "salon", "Scent & Soap", "sun")],
    ("n_cc_b5_w", "amber_ne_corner_deli"): [(4.9, [-1.8, 5.7], "restaurant", "Hilltop Deli", "red")],
    ("n_cc_b5_w", "amber_ne_luggage"): [(-1.1, [-5.7, 2.2], "store", "Carry On Luggage", "navy")],
    ("n_cc_b5_w", "amber_ne_comics_fe"): [(-1.1, [-5.7, 2.2], "books", "Panel Comics", "sun")],
    ("n_cc_b5_w", "amber_ne_violin"): [(-1.1, [-5.7, 2.2], "store", "String & Bow", "black")],
    ("n_cc_b5_w", "amber_ne_nails_fe"): [(-1.1, [-5.7, 2.2], "salon", "Polished Nails", "red")],
    ("n_cc_b5_w", "amber_ne_corner_wine"): [(4.9, [-1.8, 5.7], "bar", "Amber Wine Room", "red")],
    ("n_cc_b5_w", "amber_ne_maps"): [(-1.1, [-5.7, 2.2], "books", "Old Maps & Prints", "navy")],
    ("n_cc_b5_w", "l5n_cabinetmaker"): [(None, None, "keys", "Lane Cabinetmakers", "navy")],
    ("n_cc_b5_w", "l5s_tyre_shop"): [(None, None, "bike", "Lane Tyre & Bike", "black")],
    ("n_cc_b5_w", "l5s_bakery_depot"): [(None, None, "print", "Hill Print Works", "black")],
    ("n_cc_b5_e", "bave6_glass_tower"): [(0.0, None, "lobby", "B Avenue Tower", "black")],
    ("n_cc_b5_e", "sixth_b5_corner_optician"): [(4.9, [-1.8, 5.7], "jewelry", "Clear Sight Optician", "navy")],
    ("n_cc_b6", "amber8s_condo_tower"): [(0.0, None, "lobby", "Eighth & Amber Residences", "black")],
    ("n_cc_b6", "amber_s_bakery"): [(-1.1, [-5.7, 2.2], "bakery", "Amber Bread Co", "sun")],
    ("n_cc_b6", "amber_s_brick_row"): [(-4.1, [-8.7, -1.1], "clothes", "South Amber Outfitters", "navy"), (1.9, [-1.1, 4.9], "books", "Chapter Two Books", "green"), (7.9, [4.9, 8.7], "keys", "Amber Key & Heel", "black")],
    ("n_cc_b6", "amber_s_trattoria_block"): [(0.0, [-5.4, 5.4], "restaurant", "Trattoria del Sud", "red")],
    ("n_cc_b6", "amber_s_bookshop_fe"): [(-1.1, [-5.7, 2.2], "gallery", "Amber Prints", "black")],
    ("n_cc_b6", "amber_s_shop_row"): [(-4.1, [-8.7, -1.1], "sport", "Bay Bikes & Boards", "sea"), (1.9, [-1.1, 4.9], "souvenir", "Postcard Corner", "sun"), (7.9, [4.9, 8.7], "jewelry", "Gold Leaf", "black")],
    ("n_cc_b6", "amber_s_passage_cafe"): [(4.9, [-1.8, 5.7], "cafe", "Passage Coffee", "teal")],
    ("n_cc_b6", "amber_s_dim_sum_block"): [(0.0, [-5.4, 5.4], "restaurant", "Golden Steam Dim Sum", "red")],
    ("n_cc_b6", "amber_s_cobbler"): [(-1.1, [-5.7, 2.2], "keys", "Amber Cobbler", "black")],
    ("n_cc_b6", "amber_s_corner_bank"): [(6.8, None, "bank", "Ninth & Amber Savings", "navy")],
    ("n_cc_b6", "eighth_bave_s_corner"): [(6.8, None, "restaurant", "Corner Grill", "red")],
    ("n_cc_b6", "eighth_s_corner_juice"): [(4.9, [-1.8, 5.7], "cafe", "Press Juice Bar", "green")],
    ("n_cc_b6", "eighth_s_barber"): [(-1.1, [-5.7, 2.2], "salon", "Eighth St Barbers", "red")],
    ("n_cc_b6", "eighth_s_pho_block"): [(0.0, [-5.4, 5.4], "restaurant", "Pho Eighth", "sea")],
    ("n_cc_b6", "eighth_s_comics_fe"): [(-1.1, [-5.7, 2.2], "books", "Uphill Comics", "sun")],
    ("n_cc_b6", "eighth_s_brick_row"): [(-4.1, [-8.7, -1.1], "clothes", "Slope Streetwear", "navy"), (1.9, [-1.1, 4.9], "store", "Hobby Hill", "sun"), (7.9, [4.9, 8.7], "jewelry", "Watch Hill", "black")],
    ("n_cc_b6", "eighth_s_locksmith"): [(-1.1, [-5.7, 2.2], "keys", "Eighth St Locksmith", "black")],
    ("n_cc_b6", "eighth_s_beach_condo"): [(0.0, [-5.0, 5.0], "ice_cream", "Hill Scoops", "sun")],
    ("n_cc_b6", "eighth_s_plants_fe"): [(-1.1, [-5.7, 2.2], "souvenir", "Green Thumb Plants", "green")],
    ("n_cc_b6", "eighth_s_shop_row"): [(-4.1, [-8.7, -1.1], "shoes", "Eighth Step Shoes", "teal"), (1.9, [-1.1, 4.9], "salon", "Bloom Nails", "red"), (7.9, [4.9, 8.7], "store", "Paper Hill", "black")],
    ("n_cc_b6", "eighth_s_tailor"): [(-1.1, [-5.7, 2.2], "clothes", "Hill Tailors", "navy")],
    ("n_cc_b6", "eighth_s_grocer_block"): [(0.0, [-5.4, 5.4], "grocery", "Eighth St Grocer", "green")],
    ("n_cc_b6", "eighth_s_watch"): [(-1.1, [-5.7, 2.2], "jewelry", "Tick Tock Repairs", "black")],
    ("n_cc_b6", "bave6_laundry"): [(-1.1, [-5.7, 2.2], "cleaners", "B Ave Laundry", "sea")],
    ("n_cc_b6", "bave6_hardware_fe"): [(-1.1, [-5.7, 2.2], "store", "B Ave Hardware", "red")],
    ("n_cc_b6", "bave6_deli"): [(-1.1, [-5.7, 2.2], "restaurant", "B Ave Deli", "red")],
    ("n_cc_b6", "ninth_n_records"): [(-1.1, [-5.7, 2.2], "store", "Ninth St Records", "black")],
    ("n_cc_b6", "ninth_n_thrift_fe"): [(-1.1, [-5.7, 2.2], "clothes", "Hill Thrift", "sun")],
    ("n_cc_b6", "ninth_n_bike"): [(-1.1, [-5.7, 2.2], "bike", "Ninth St Bikes", "sea")],
    ("n_cc_b6", "ninth_n_tattoo_fe"): [(-1.1, [-5.7, 2.2], "salon", "Ninth Ink", "red")],
}
# not walk-in (no room): the coffee kiosk (a walk-up window), the garage, every flat (homes are not entered in this pass)


def main():
    blds = json.load(open(os.path.join(IN, "cc_buildings.json")))["buildings"]
    rc = json.load(open(os.path.join(IN, "room_contracts_cc.json")))["models"]
    rooms = []; missing = []
    for b in blds:
        key = (b["piece"], b["label"])
        if key not in SHOPS:
            missing.append(key); continue
        c = rc[b["model"]]
        fl = c["floors"][0]
        for k, (along, bay, kind, name, style) in enumerate(SHOPS[key]):
            if kind is None: continue        # a second door of the shop before it
            fronts = [e for e in c["entrances"] if e["facade"] == "front" and e["floor"] == 0 and e["kind"] in ("shop", "civic", "residential")]
            ent = fronts[0] if along is None else min(fronts, key=lambda e: abs(e["along"] - along))
            bx = bay if bay is not None else [fl["box_min"][0], fl["box_max"][0]]
            # the shop's boards: every front board over its bay; a building with one shop also takes its side boards
            signs = [{"facade": s["facade"], "along": s["along"], "w": s["w"]} for s in c.get("signs", [])
                     if (s["facade"] == "front" and bx[0] - 0.3 <= s["along"] <= bx[1] + 0.3) or (len(SHOPS[key]) == 1 and s["facade"] != "back")]
            rid = "cc_%s__%s__%d" % (b["piece"][5:], b["label"], k)
            rooms.append({"id": rid, "piece": b["piece"], "label": b["label"], "model": b["model"], "pos": b["pos"], "yaw": b["yaw"],
                          "door_index": k, "door_along": ent["along"], "door_w": ent["w"], "bay": bx, "kind": kind, "name": name,
                          "style": style, "signs": signs, "source": "city-centre fill (hand-made shop list)", "built": ""})
    json.dump({"_doc": __doc__.strip().split("\n")[0], "count": len(rooms), "rooms": rooms}, open(os.path.join(IN, "assignment_cc.json"), "w"), indent=1)
    print("ASSIGN cc rooms=%d" % len(rooms))
    for m in missing: print("  no shop listed for", m)


if __name__ == "__main__":
    main()
