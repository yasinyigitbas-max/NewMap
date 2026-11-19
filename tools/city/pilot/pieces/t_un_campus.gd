extends SceneTree
## Piece t_un_campus: the UNIVERSITY CAMPUS TREES, hand-placed (claude/sharp-ride-16u9ik, 19 Nov late; Yasin: "remove every
## tree, fill their wells with surrounding material, place new trees according to the tree plan"). docs/TREE_PLAN.md:
## trees are their own layer, one piece per area, every tree a line with its place, species, size and reason; trees only
## on grass or mulch (the campus has no tree wells any more); "civic and parks: yes, grouped" - clumps of 2-4 at the
## edges and round the seating, the lawns open in the middle; from any point of the campus streets and paths at most 8
## broadleaf crowns and 12 trees within 60 m (checked by OUT/trees_un.py: worst point 5 broadleaf, 11 trees).
## Layout row (-600, 6.0, -600) like the four quarters (local x = u + 600, z = v + 600). Each trunk stands at the ground
## height measured from the built quarters' ground (dump of 19 Nov late), more than 4 m from every wall and 1.5 m from the
## tennis cage. 81 trees: 61 broadleaf (jacaranda, coral, magnolia, ficus, eucalyptus), 20 palms and pines.
## Columns: x, z, ground height over the 6.0 datum, species, scale, reason.
const L := preload("res://tools/city/pilot/pieces/cc_fill_lib.gd")
const TREES := [
	[24.0, -148.0, 0.349, "tree_jacaranda_a", 0.85, "lecture lawn: shade over the table"],
	[36.0, -158.0, 0.317, "tree_jacaranda_b", 0.85, "lecture lawn: shade over the table"],
	[20.0, -160.0, 0.304, "tree_coral_a", 0.80, "lecture lawn: the clump's third tree"],
	[14.0, -104.0, 0.333, "tree_magnolia_a", 0.80, "quad, north-west corner: a clump by the tables"],
	[24.0, -116.0, 0.361, "tree_magnolia_b", 0.80, "quad, north-west corner: a clump by the tables"],
	[38.0, -108.0, 0.351, "tree_ficus_a", 0.80, "quad, north-west corner: a clump by the tables"],
	[88.0, -30.0, 0.210, "tree_coral_b", 0.80, "quad, south-east corner: a clump by the tables"],
	[106.0, -34.0, 0.200, "tree_jacaranda_a", 0.80, "quad, south-east corner: a clump by the tables"],
	[108.0, -16.0, 0.180, "tree_coral_a", 0.80, "quad, south-east corner: a clump by the tables"],
	[20.0, -22.0, 0.208, "palm_queen_a", 1.00, "quad, south-west corner: light palms by the table"],
	[38.0, -18.0, 0.206, "palm_queen_b", 1.00, "quad, south-west corner: light palms by the table"],
	[22.0, -40.0, 0.235, "palm_queen_a", 1.00, "quad, south-west corner: light palms by the table"],
	[100.0, -112.0, 0.330, "palm_queen_b", 1.00, "quad, north-east corner: palms by the table"],
	[86.0, -116.0, 0.358, "palm_queen_a", 1.00, "quad, north-east corner: palms by the table"],
	[162.0, -158.0, 0.252, "tree_eucalyptus_a", 0.85, "corner grove: shade for people waiting for the bus"],
	[178.0, -174.0, 0.199, "tree_eucalyptus_b", 0.85, "corner grove: shade over the table"],
	[184.0, -156.0, 0.193, "tree_torrey_pine_a", 0.85, "corner grove: a pine at the street corner"],
	[183.0, -120.0, 0.197, "tree_eucalyptus_a", 0.85, "lot screen: eucalyptus between the stalls and the east street"],
	[183.0, -82.0, 0.189, "tree_eucalyptus_b", 0.85, "lot screen: eucalyptus between the stalls and the east street"],
	[160.0, -40.0, 0.189, "tree_ficus_a", 0.80, "science lawn: shade on the lawn behind the wing"],
	[-176.0, -188.4, 0.153, "tree_coral_a", 0.80, "street lawn: coral trees between the drive and 6th St"],
	[-110.0, -188.4, 0.153, "tree_coral_b", 0.80, "street lawn: coral trees between the drive and 6th St"],
	[-80.0, -188.4, 0.153, "tree_coral_a", 0.80, "street lawn: coral trees between the drive and 6th St"],
	[-104.0, -148.0, 0.259, "tree_jacaranda_a", 0.85, "sculpture garden: shade over its benches"],
	[-130.0, -148.0, 0.239, "tree_ficus_b", 0.80, "sculpture garden: shade at the museum's side door"],
	[-108.0, -158.0, 0.240, "tree_magnolia_b", 0.80, "chapel: a magnolia on its lawn"],
	[-84.0, -164.0, 0.240, "tree_magnolia_a", 0.80, "chapel: a magnolia on its lawn"],
	[-78.0, -170.0, 0.228, "tree_jacaranda_b", 0.85, "lawn by the service lane: shade over the table"],
	[-66.0, -154.0, 0.279, "tree_jacaranda_a", 0.85, "lawn by the service lane: shade over the table"],
	[-184.0, -166.0, 0.182, "tree_torrey_pine_a", 0.85, "corner lawn: torrey pines at the street corner"],
	[-174.0, -158.0, 0.198, "tree_torrey_pine_b", 0.85, "corner lawn: torrey pines at the street corner"],
	[-183.0, -120.0, 0.186, "tree_eucalyptus_b", 0.85, "lot screen: eucalyptus between the stalls and the west street"],
	[-183.0, -80.0, 0.185, "tree_eucalyptus_a", 0.85, "lot screen: eucalyptus between the stalls and the west street"],
	[-118.0, -38.0, 0.155, "tree_magnolia_a", 0.80, "west quad, south-west corner: a clump by the tables"],
	[-132.0, -28.0, 0.139, "tree_coral_a", 0.80, "west quad, south-west corner: a clump by the tables"],
	[-104.0, -18.0, 0.113, "tree_jacaranda_b", 0.80, "west quad, south-west corner: a clump by the tables"],
	[-22.0, -110.0, 0.325, "tree_ficus_b", 0.80, "west quad, north-east corner: a clump by the tables"],
	[-36.0, -118.0, 0.325, "tree_magnolia_b", 0.80, "west quad, north-east corner: a clump by the tables"],
	[-16.0, -94.0, 0.309, "palm_queen_a", 1.00, "west quad, north-east corner: a palm"],
	[-14.0, -24.0, 0.190, "palm_queen_b", 1.00, "west quad, south-east corner: light palms by the table"],
	[-28.0, -18.0, 0.170, "palm_queen_a", 1.00, "west quad, south-east corner: light palms by the table"],
	[-12.0, -44.0, 0.220, "palm_queen_b", 1.00, "west quad, south-east corner: light palms by the table"],
	[-176.0, -40.0, 0.171, "tree_coral_a", 0.80, "arts lawn: shade over the bench"],
	[-156.0, -44.0, 0.169, "tree_jacaranda_a", 0.80, "arts lawn: shade over the bench"],
	[90.0, 26.0, 0.160, "tree_coral_a", 0.85, "lawn between the gym and the wing: shade over the table"],
	[156.0, 26.0, 0.155, "tree_ficus_a", 0.80, "east lawn: a clump by the table"],
	[174.0, 32.0, 0.170, "tree_magnolia_b", 0.80, "east lawn: a clump by the table"],
	[184.0, 14.0, 0.177, "tree_coral_b", 0.80, "east lawn: a clump by the table"],
	[131.0, 158.0, 0.118, "tree_ficus_a", 0.80, "courts terrace: shade at its east edge"],
	[131.0, 170.0, 0.140, "tree_ficus_b", 0.80, "courts terrace: shade at its east edge"],
	[134.0, 56.0, 0.117, "tree_torrey_pine_a", 0.85, "field edge: a pine between the loop and the campus drive"],
	[134.0, 96.0, 0.105, "tree_torrey_pine_b", 0.85, "field edge: a pine between the loop and the campus drive"],
	[160.0, 160.0, 0.153, "tree_torrey_pine_a", 0.85, "corner grove: tailgate shade"],
	[178.0, 178.0, 0.179, "tree_torrey_pine_b", 0.85, "corner grove: tailgate shade"],
	[184.0, 158.0, 0.177, "tree_coral_a", 0.80, "corner grove: tailgate shade"],
	[156.0, 182.0, 0.171, "tree_jacaranda_a", 0.80, "corner grove: tailgate shade"],
	[10.0, 150.0, 0.090, "tree_magnolia_b", 0.80, "lawn west of the courts"],
	[10.0, 176.0, 0.148, "tree_coral_b", 0.80, "lawn west of the courts"],
	[100.0, 186.0, 0.165, "tree_jacaranda_b", 0.80, "south street lawn: a street tree"],
	[122.0, 186.0, 0.161, "tree_coral_a", 0.80, "south street lawn: a street tree"],
	[-176.0, 18.0, 0.109, "tree_eucalyptus_a", 0.85, "grove: shade over the barbecue tables"],
	[-154.0, 20.0, 0.023, "tree_eucalyptus_b", 0.85, "grove: shade over the barbecue tables"],
	[-170.0, 36.0, -0.003, "tree_eucalyptus_b", 0.85, "grove: shade over the barbecue tables"],
	[-140.0, 30.0, -0.045, "tree_torrey_pine_b", 0.85, "grove: a pine at its east end"],
	[-108.0, 64.0, -0.210, "tree_coral_a", 0.85, "dorm green: shade by the first barbecue terrace"],
	[-82.0, 64.0, -0.140, "tree_jacaranda_a", 0.85, "dorm green: shade by the first barbecue terrace"],
	[-42.0, 118.0, -0.115, "tree_coral_b", 0.85, "dorm green: shade by the second barbecue terrace"],
	[-68.0, 118.0, -0.257, "tree_jacaranda_b", 0.85, "dorm green: shade by the second barbecue terrace"],
	[-104.0, 108.0, -0.448, "tree_magnolia_a", 0.80, "dorm green: a corner tree"],
	[-46.0, 72.0, -0.060, "tree_magnolia_b", 0.80, "dorm green: a corner tree"],
	[-183.0, 80.0, -0.463, "tree_eucalyptus_a", 0.85, "lot screen: eucalyptus between the stalls and the west street"],
	[-183.0, 120.0, -1.138, "tree_eucalyptus_b", 0.85, "lot screen: eucalyptus between the stalls and the west street"],
	[-128.0, 180.0, -1.235, "tree_coral_a", 0.85, "loop lawn: between the loop and the street"],
	[-100.0, 184.0, -0.808, "tree_torrey_pine_a", 0.85, "loop lawn: between the loop and the street"],
	[-74.0, 178.0, -0.373, "tree_coral_b", 0.85, "loop lawn: between the loop and the street"],
	[-14.0, 120.0, -0.004, "tree_magnolia_b", 0.85, "east lawn: shade"],
	[-16.0, 150.0, 0.023, "tree_jacaranda_a", 0.85, "east lawn: shade"],
	[-14.0, 60.0, 0.045, "tree_coral_a", 0.85, "east lawn: shade"],
	[-16.0, 38.0, 0.072, "tree_jacaranda_b", 0.85, "east lawn: shade"],
	[-170.0, 174.0, -1.648, "palm_mexican_fan_a", 1.00, "rain garden: a dry-garden palm"],
	[-158.0, 162.0, -1.400, "palm_mexican_fan_b", 1.00, "rain garden: a dry-garden palm"]]

func _init() -> void: _run.call_deferred()

func _run() -> void:
	var c := L.new("t_un_campus")
	for t: Array in TREES:
		c.put(String(t[3]), "normal", Vector3(float(t[0]), float(t[2]), float(t[1])), c.rr.randf_range(0, 360), String(t[5]), false, float(t[4]))
	c.root.set_meta("stalls", [])
	c.props.build(c.root, L.K)
	print("t_un_campus: trees %d" % c.props.count())
	L.K.save_piece(c.root, "t_un_campus")
	quit()
