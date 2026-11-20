extends RefCounted
## The eb fill (claude/fill-high-street, 20 Nov): the MIDDLE of the east shore beyond the ring road, v -1100 .. -500, from
## the ring's east walk to the sea. Yasin: "FILL THAT RED AREA WITH GRASS > SAND AND BEYOND IT SHOULD BE THE SEA, PUT LOTS
## OF RELEVANT PROPS IN THAT AREA, MAKE THE SEA SAND CONNECTION SEAMLESS AND BUBBLY LIKE THE WATERFRONT AND AROUND THE
## ISLAND" (review/fill_east/SHORE_GUIDE.md, BUILD_GUIDE.md). This file holds the edges, the lines and the ground rule its
## pieces share, and the painter that cuts the ground exactly to them. It places nothing.
## Frame: every eb piece at grid [0, 0, 0], yaw 0: x = u, z = v, y = world height.
##
## Measured (read-only; OUT/fill/eb/edges_eb.py, site_data.py, from OUT/g_city, terrain_grid.npz, zoning/shore_foam.json):
##  - the ring's east walk: its outer edge runs u 674.3 (v -1104 .. -999.5) to u 667.6 (v -497.6), 4.150 all along, 5.2 -
##    10 cm over the land. No apron, no leg, no driveway on this side of the ring (zoning/legs_measured.json): no car
##    comes in; people walk across at the ring's junctions (v -1000, -800, -600) and along its east walk.
##  - the bridge approach (s_br_appr_3 .. 6) and its off-ramp (s_br_ramp_1) cross the north of the area from u 872, v -1112
##    to their end at u 1180, v -922 .. -893 (no deck is built beyond it: the corridor east of u 1180, v -930 .. -885 is
##    kept free of props). Their edges stand 5 - 21 cm over the land. No apron either.
##  - the land falls from 4 - 7 m at the ring and on the bluff (u 1100 - 1200, v -960 .. -860) to the sea at about 8 %;
##    its 0 m line (the foam strip x_shore_foam lies on it) runs u 1069 (v -1112) .. 1241 (v -940) .. 1403 (v -512).
## THE GROUND RULE (the same for the neighbours ea north of v -1100 and ec south of v -500, so the seams meet):
##  ground = land + 5 cm, the 5 cm easing to 0 (smoothstep) over the last 10 m before the 0 m line (distance to it, from
##  ZERO), and the land itself on the water side of it and under the water (the sand runs on under the sea to SEA_LIM, 40 m along u past
##  the 0 m line, so the sea cuts it exactly where the foam lies); within 12 m of the ring's walk or the bridge's edge
##  eased onto that edge's height keeping the land's shape (target = land + edge - land(foot), as n_fe_site.gd).
##  Grass where the land is over ~2.5 m, sand below: the DUNE line.
const LAND := preload("res://tools/city/pilot/pieces/n_eb_land.gd")
const H := preload("res://tools/city/pilot/pieces/hs_fill_lib.gd")
const K := preload("res://tools/city/pilot/kit_lib.gd")
const LIFT := 0.05
const WET := 10.0
const EASE := 12.0
const RING_Y := 4.15
const V_N := -1100.0
const V_S := -500.0

## the ring's east walk edge [v, u] (its outer edge, 4.150 all along; measured OUT/fill/eb/edges_eb.py, simplified 1 cm)
const RING := [[-1104.0, 674.3], [-999.462, 674.294], [-497.559, 667.6]]
## the bridge approach + off-ramp outline [u, v, height] (s_br_appr_3..6, s_br_ramp_1, its outer edges, measured; closed north
## of v -1112, outside eb). Heights are its edge's own (5 - 21 cm over the land). At the approach's end (u 1180) its two
## kerbs (verge 7.05 | road 6.90 at v -895.7 and -915.2) are held by a point either side of each (read from the dump).
const BRIDGE := [[872.22, -1111.772, 4.987], [874.444, -1109.183, 5.01], [875.54, -1107.876, 5.022], [877.525, -1105.458, 5.044], [879.475, -1103.013, 5.065], [881.563, -1100.313, 5.089], [882.591, -1098.952, 5.101], [883.609, -1097.582, 5.113], [885.282, -1095.283, 5.133], [886.274, -1093.89, 5.146], [888.225, -1091.08, 5.17], [890.121, -1088.258, 5.194], [891.674, -1085.876, 5.215], [892.591, -1084.438, 5.227], [894.392, -1081.539, 5.252], [895.275, -1080.08, 5.264], [896.866, -1077.386, 5.287], [898.418, -1074.67, 5.31], [899.249, -1073.18, 5.322], [900.876, -1070.18, 5.347], [901.672, -1068.672, 5.36], [902.973, -1066.143, 5.38], [903.738, -1064.618, 5.393], [905.232, -1061.55, 5.418], [906.68, -1058.46, 5.443], [907.849, -1055.868, 5.464], [908.535, -1054.306, 5.477], [909.871, -1051.165, 5.502], [912.343, -1045.082, 5.549], [913.155, -1043.141, 5.563], [913.983, -1041.206, 5.577], [915.688, -1037.359, 5.605], [917.46, -1033.542, 5.633], [919.109, -1030.132, 5.659], [920.811, -1026.748, 5.684], [922.417, -1023.67, 5.707], [924.04, -1020.661, 5.73], [924.932, -1019.05, 5.742], [926.75, -1015.848, 5.767], [928.348, -1013.125, 5.788], [929.979, -1010.424, 5.809], [931.086, -1008.634, 5.823], [933.346, -1005.084, 5.85], [935.08, -1002.447, 5.871], [936.255, -1000.701, 5.885], [938.65, -997.24, 5.913], [940.484, -994.672, 5.933], [942.352, -992.127, 5.954], [943.614, -990.444, 5.968], [946.183, -987.11, 5.995], [948.147, -984.639, 6.015], [949.473, -983.006, 6.029], [951.489, -980.578, 6.049], [953.536, -978.175, 6.069], [956.313, -975.013, 6.096], [958.431, -972.672, 6.116], [959.859, -971.127, 6.129], [962.027, -968.833, 6.149], [964.223, -966.566, 6.169], [967.197, -963.588, 6.195], [969.46, -961.388, 6.214], [970.985, -959.938, 6.227], [974.071, -957.076, 6.253], [976.417, -954.965, 6.272], [977.996, -953.574, 6.284], [980.387, -951.514, 6.303], [982.804, -949.484, 6.322], [986.066, -946.826, 6.346], [988.543, -944.869, 6.365], [990.208, -943.582, 6.377], [993.57, -941.052, 6.401], [995.268, -939.808, 6.413], [997.834, -937.97, 6.431], [1000.424, -936.164, 6.449], [1002.162, -934.98, 6.46], [1003.911, -933.809, 6.472], [1006.996, -931.798, 6.492], [1009.931, -929.944, 6.511], [1011.543, -928.95, 6.521], [1013.163, -927.968, 6.531], [1016.424, -926.043, 6.551], [1019.165, -924.477, 6.567], [1022.48, -922.644, 6.586], [1024.147, -921.747, 6.596], [1027.503, -919.991, 6.615], [1030.32, -918.568, 6.63], [1032.019, -917.731, 6.639], [1033.725, -916.907, 6.649], [1037.154, -915.3, 6.667], [1038.878, -914.515, 6.676], [1041.764, -913.238, 6.69], [1043.504, -912.489, 6.699], [1047.0, -911.032, 6.716], [1050.518, -909.629, 6.733], [1053.466, -908.502, 6.746], [1055.241, -907.843, 6.754], [1058.808, -906.567, 6.77], [1060.598, -905.95, 6.778], [1063.892, -904.854, 6.792], [1067.202, -903.804, 6.806], [1069.013, -903.251, 6.813], [1070.829, -902.712, 6.821], [1074.472, -901.677, 6.835], [1077.52, -900.857, 6.847], [1080.995, -899.972, 6.86], [1084.483, -899.138, 6.872], [1086.723, -898.631, 6.88], [1089.809, -897.968, 6.89], [1091.664, -897.589, 6.896], [1093.522, -897.224, 6.902], [1097.247, -896.538, 6.914], [1099.114, -896.217, 6.92], [1102.23, -895.713, 6.929], [1104.102, -895.43, 6.934], [1107.853, -894.906, 6.945], [1111.612, -894.441, 6.955], [1114.75, -894.097, 6.963], [1116.634, -893.91, 6.968], [1120.408, -893.58, 6.977], [1122.296, -893.437, 6.981], [1125.76, -893.212, 6.989], [1129.228, -893.035, 6.996], [1133.013, -892.899, 7.003], [1136.8, -892.82, 7.01], [1139.956, -892.8, 7.015], [1180.0, -892.8, 7.05], [1180.0, -894.8, 7.05], [1180.0, -895.62, 7.05], [1180.0, -895.72, 6.9], [1180.0, -915.2, 6.9], [1180.0, -915.3, 7.05], [1180.0, -917.2, 7.05], [1139.96, -917.2, 7.015], [1137.117, -917.218, 7.01], [1133.705, -917.289, 7.003], [1130.295, -917.412, 6.996], [1127.171, -917.571, 6.989], [1124.05, -917.774, 6.981], [1122.348, -917.903, 6.977], [1118.949, -918.2, 6.968], [1117.251, -918.369, 6.963], [1114.424, -918.678, 6.955], [1111.038, -919.098, 6.945], [1109.347, -919.327, 6.94], [1105.971, -919.824, 6.929], [1103.164, -920.278, 6.92], [1101.482, -920.568, 6.914], [1098.127, -921.186, 6.902], [1096.452, -921.514, 6.896], [1094.781, -921.856, 6.89], [1092.0, -922.453, 6.88], [1089.982, -922.911, 6.872], [1086.84, -923.662, 6.86], [1083.709, -924.458, 6.847], [1080.963, -925.197, 6.835], [1079.32, -925.658, 6.828], [1076.045, -926.616, 6.813], [1074.414, -927.114, 6.806], [1071.432, -928.06, 6.792], [1068.464, -929.047, 6.778], [1066.851, -929.603, 6.77], [1065.242, -930.172, 6.762], [1062.038, -931.346, 6.746], [1059.382, -932.362, 6.733], [1056.212, -933.626, 6.716], [1054.635, -934.276, 6.707], [1051.496, -935.613, 6.69], [1048.895, -936.764, 6.676], [1047.342, -937.471, 6.667], [1044.252, -938.919, 6.649], [1042.716, -939.661, 6.639], [1039.914, -941.052, 6.622], [1037.133, -942.483, 6.605], [1034.121, -944.088, 6.586], [1032.625, -944.908, 6.577], [1031.135, -945.739, 6.567], [1028.666, -947.15, 6.551], [1027.194, -948.012, 6.541], [1024.268, -949.769, 6.521], [1021.37, -951.571, 6.5], [1018.977, -953.106, 6.483], [1015.817, -955.201, 6.46], [1014.25, -956.269, 6.449], [1010.758, -958.719, 6.422], [1008.076, -960.672, 6.401], [1006.556, -961.805, 6.389], [1005.047, -962.952, 6.377], [1002.808, -964.706, 6.359], [1000.609, -966.507, 6.34], [999.164, -967.734, 6.328], [997.028, -969.61, 6.309], [994.93, -971.529, 6.291], [992.192, -974.148, 6.265], [990.182, -976.155, 6.246], [988.209, -978.197, 6.227], [986.273, -980.272, 6.208], [984.372, -982.378, 6.188], [982.506, -984.513, 6.169], [980.674, -986.674, 6.149], [978.876, -988.861, 6.129], [977.111, -991.071, 6.109], [975.377, -993.303, 6.089], [973.673, -995.555, 6.069], [971.999, -997.825, 6.049], [970.352, -1000.113, 6.029], [968.733, -1002.416, 6.009], [966.09, -1006.286, 5.975], [964.535, -1008.624, 5.954], [962.496, -1011.76, 5.926], [960.99, -1014.122, 5.906], [958.52, -1018.079, 5.871], [956.574, -1021.259, 5.844], [954.175, -1025.249, 5.809], [951.338, -1030.06, 5.767], [950.54, -1031.48, 5.754], [949.774, -1032.918, 5.742], [949.035, -1034.37, 5.73], [948.32, -1035.834, 5.718], [947.143, -1038.367, 5.696], [945.784, -1041.429, 5.671], [943.233, -1047.308, 5.623], [940.784, -1052.816, 5.577], [939.339, -1056.232, 5.549], [938.301, -1058.792, 5.528], [936.895, -1062.414, 5.502], [935.558, -1066.044, 5.477], [934.912, -1067.872, 5.464], [933.867, -1070.938, 5.443], [932.666, -1074.656, 5.418], [931.522, -1078.42, 5.393], [930.796, -1080.944, 5.376], [930.377, -1080.73, 5.376], [929.724, -1083.129, 5.376], [929.234, -1085.005, 5.376], [928.304, -1088.769, 5.376], [927.441, -1092.549, 5.376], [926.646, -1096.344, 5.374], [926.274, -1098.247, 5.373], [925.918, -1100.153, 5.372], [925.259, -1103.974, 5.367], [924.955, -1105.888, 5.364], [924.405, -1109.67, 5.358], [924.155, -1111.565, 5.355], [924.16, -1114.0, 5.36], [872.22, -1114.0, 4.99]]
## where the grass gives way to the sand [v, u]: the land's 2.5 m line (scanning in from the water), smoothed over 36 m,
## with a gentle wave of +- 2.5 m (dune lobes); sand east of it. Measured from the land; a shape, not a placement.
const DUNE := [[-1112.0, 1014.52], [-1108.0, 1015.15], [-1104.0, 1016.05], [-1100.0, 1017.39], [-1096.0, 1019.07], [-1092.0, 1021.2], [-1088.0, 1023.36], [-1084.0, 1025.8], [-1080.0, 1028.18], [-1076.0, 1030.72], [-1072.0, 1033.14], [-1068.0, 1035.73], [-1064.0, 1038.23], [-1060.0, 1040.95], [-1056.0, 1043.71], [-1052.0, 1046.89], [-1048.0, 1050.23], [-1044.0, 1054.11], [-1040.0, 1058.38], [-1036.0, 1063.07], [-1032.0, 1068.16], [-1028.0, 1073.55], [-1024.0, 1079.25], [-1020.0, 1085.28], [-1016.0, 1091.27], [-1012.0, 1097.52], [-1008.0, 1103.81], [-1004.0, 1110.04], [-1000.0, 1116.5], [-996.0, 1122.9], [-992.0, 1129.66], [-988.0, 1136.59], [-984.0, 1143.58], [-980.0, 1150.88], [-976.0, 1158.22], [-972.0, 1165.39], [-968.0, 1172.48], [-964.0, 1179.06], [-960.0, 1185.24], [-956.0, 1190.67], [-952.0, 1195.36], [-948.0, 1199.35], [-944.0, 1202.59], [-940.0, 1205.12], [-936.0, 1207.22], [-932.0, 1208.89], [-928.0, 1210.45], [-924.0, 1211.9], [-920.0, 1213.44], [-916.0, 1215.0], [-912.0, 1216.71], [-908.0, 1218.43], [-904.0, 1220.19], [-900.0, 1221.85], [-896.0, 1223.42], [-892.0, 1224.74], [-888.0, 1225.85], [-884.0, 1226.73], [-880.0, 1227.37], [-876.0, 1227.86], [-872.0, 1228.2], [-868.0, 1228.52], [-864.0, 1228.83], [-860.0, 1229.21], [-856.0, 1229.56], [-852.0, 1229.86], [-848.0, 1230.16], [-844.0, 1230.31], [-840.0, 1230.34], [-836.0, 1230.13], [-832.0, 1229.73], [-828.0, 1229.03], [-824.0, 1227.99], [-820.0, 1226.94], [-816.0, 1225.76], [-812.0, 1224.6], [-808.0, 1223.47], [-804.0, 1222.47], [-800.0, 1221.59], [-796.0, 1220.64], [-792.0, 1220.0], [-788.0, 1219.4], [-784.0, 1218.83], [-780.0, 1218.19], [-776.0, 1217.42], [-772.0, 1216.55], [-768.0, 1215.36], [-764.0, 1214.27], [-760.0, 1213.1], [-756.0, 1211.96], [-752.0, 1210.88], [-748.0, 1209.69], [-744.0, 1208.91], [-740.0, 1208.08], [-736.0, 1207.6], [-732.0, 1207.22], [-728.0, 1206.92], [-724.0, 1206.56], [-720.0, 1205.83], [-716.0, 1205.18], [-712.0, 1204.33], [-708.0, 1203.32], [-704.0, 1202.11], [-700.0, 1200.75], [-696.0, 1199.33], [-692.0, 1197.58], [-688.0, 1196.22], [-684.0, 1194.91], [-680.0, 1193.77], [-676.0, 1192.68], [-672.0, 1191.3], [-668.0, 1190.27], [-664.0, 1188.94], [-660.0, 1187.79], [-656.0, 1186.48], [-652.0, 1184.66], [-648.0, 1183.06], [-644.0, 1180.97], [-640.0, 1179.18], [-636.0, 1177.45], [-632.0, 1175.43], [-628.0, 1173.89], [-624.0, 1172.12], [-620.0, 1170.94], [-616.0, 1169.99], [-612.0, 1168.75], [-608.0, 1167.97], [-604.0, 1166.84], [-600.0, 1165.99], [-596.0, 1165.02], [-592.0, 1163.55], [-588.0, 1162.37], [-584.0, 1160.6], [-580.0, 1159.11], [-576.0, 1157.61], [-572.0, 1155.74], [-568.0, 1154.34], [-564.0, 1152.67], [-560.0, 1151.49], [-556.0, 1150.36], [-552.0, 1149.29], [-548.0, 1148.19], [-544.0, 1146.61], [-540.0, 1145.31], [-536.0, 1143.82], [-532.0, 1142.1], [-528.0, 1140.21], [-524.0, 1137.68], [-520.0, 1135.58], [-516.0, 1132.98], [-512.0, 1130.93], [-508.0, 1128.92], [-504.0, 1126.65], [-500.0, 1124.94], [-496.0, 1123.33], [-492.0, 1122.16], [-488.0, 1121.52]]
## the 0 m line [v, u] (the foam line of zoning/shore_foam.json, read every 4 m in v)
const ZERO := [[-1112.0, 1068.59], [-1108.0, 1070.01], [-1104.0, 1071.17], [-1100.0, 1072.36], [-1096.0, 1073.62], [-1092.0, 1075.0], [-1088.0, 1076.99], [-1084.0, 1078.87], [-1080.0, 1081.62], [-1076.0, 1084.78], [-1072.0, 1088.97], [-1068.0, 1093.41], [-1064.0, 1097.99], [-1060.0, 1103.46], [-1056.0, 1108.22], [-1052.0, 1113.84], [-1048.0, 1119.48], [-1044.0, 1125.1], [-1040.0, 1129.89], [-1036.0, 1135.47], [-1032.0, 1140.26], [-1028.0, 1145.86], [-1024.0, 1151.44], [-1020.0, 1156.2], [-1016.0, 1161.74], [-1012.0, 1166.49], [-1008.0, 1172.08], [-1004.0, 1177.74], [-1000.0, 1183.48], [-996.0, 1189.4], [-992.0, 1197.32], [-988.0, 1206.47], [-984.0, 1215.63], [-980.0, 1222.64], [-976.0, 1228.27], [-972.0, 1232.54], [-968.0, 1235.57], [-964.0, 1237.56], [-960.0, 1239.44], [-956.0, 1240.41], [-952.0, 1240.95], [-948.0, 1241.11], [-944.0, 1241.04], [-940.0, 1240.77], [-936.0, 1240.42], [-932.0, 1240.07], [-928.0, 1239.84], [-924.0, 1239.9], [-920.0, 1240.4], [-916.0, 1241.42], [-912.0, 1243.01], [-908.0, 1245.64], [-904.0, 1248.68], [-900.0, 1252.45], [-896.0, 1255.49], [-892.0, 1257.78], [-888.0, 1260.45], [-884.0, 1262.94], [-880.0, 1264.85], [-876.0, 1267.16], [-872.0, 1268.99], [-868.0, 1271.28], [-864.0, 1273.14], [-860.0, 1275.52], [-856.0, 1277.49], [-852.0, 1280.0], [-848.0, 1282.55], [-844.0, 1284.59], [-840.0, 1287.12], [-836.0, 1289.61], [-832.0, 1291.59], [-828.0, 1294.08], [-824.0, 1296.1], [-820.0, 1298.64], [-816.0, 1301.2], [-812.0, 1303.22], [-808.0, 1305.68], [-804.0, 1308.08], [-800.0, 1309.94], [-796.0, 1312.23], [-792.0, 1314.04], [-788.0, 1316.27], [-784.0, 1318.04], [-780.0, 1319.78], [-776.0, 1321.9], [-772.0, 1323.52], [-768.0, 1325.45], [-764.0, 1326.91], [-760.0, 1328.32], [-756.0, 1329.7], [-752.0, 1331.44], [-748.0, 1332.86], [-744.0, 1334.32], [-740.0, 1336.18], [-736.0, 1337.67], [-732.0, 1339.16], [-728.0, 1340.66], [-724.0, 1342.55], [-720.0, 1344.1], [-716.0, 1345.66], [-712.0, 1347.61], [-708.0, 1349.16], [-704.0, 1350.69], [-700.0, 1352.58], [-696.0, 1354.1], [-692.0, 1355.63], [-688.0, 1357.57], [-684.0, 1359.13], [-680.0, 1360.68], [-676.0, 1362.56], [-672.0, 1364.03], [-668.0, 1365.46], [-664.0, 1367.22], [-660.0, 1368.63], [-656.0, 1370.04], [-652.0, 1371.46], [-648.0, 1373.3], [-644.0, 1374.83], [-640.0, 1376.85], [-636.0, 1378.56], [-632.0, 1380.31], [-628.0, 1382.47], [-624.0, 1384.1], [-620.0, 1385.59], [-616.0, 1387.23], [-612.0, 1388.37], [-608.0, 1389.38], [-604.0, 1390.29], [-600.0, 1391.13], [-596.0, 1391.93], [-592.0, 1392.71], [-588.0, 1393.49], [-584.0, 1394.48], [-580.0, 1395.29], [-576.0, 1396.12], [-572.0, 1396.95], [-568.0, 1397.76], [-564.0, 1398.53], [-560.0, 1399.24], [-556.0, 1399.87], [-552.0, 1400.44], [-548.0, 1400.95], [-544.0, 1401.41], [-540.0, 1401.84], [-536.0, 1402.24], [-532.0, 1402.61], [-528.0, 1402.93], [-524.0, 1403.19], [-520.0, 1403.36], [-516.0, 1403.39], [-512.0, 1403.29], [-508.0, 1403.02], [-504.0, 1402.57], [-500.0, 1401.95], [-496.0, 1401.19], [-492.0, 1400.06], [-488.0, 1399.02]]
## how far the sand runs on under the water [v, u]: 40 m along u past the 0 m line (>= 25 m along the shore's normal)
const SEA_LIM := [[-1112.0, 1109.7], [-1108.0, 1110.42], [-1104.0, 1111.34], [-1100.0, 1112.54], [-1096.0, 1114.01], [-1092.0, 1115.66], [-1088.0, 1117.61], [-1084.0, 1119.98], [-1080.0, 1122.81], [-1076.0, 1126.09], [-1072.0, 1129.87], [-1068.0, 1134.06], [-1064.0, 1138.67], [-1060.0, 1143.62], [-1056.0, 1148.78], [-1052.0, 1154.0], [-1048.0, 1159.35], [-1044.0, 1164.61], [-1040.0, 1169.98], [-1036.0, 1175.35], [-1032.0, 1180.6], [-1028.0, 1185.84], [-1024.0, 1191.07], [-1020.0, 1196.3], [-1016.0, 1201.65], [-1012.0, 1207.02], [-1008.0, 1212.45], [-1004.0, 1218.32], [-1000.0, 1224.71], [-996.0, 1231.73], [-992.0, 1238.96], [-988.0, 1246.17], [-984.0, 1253.18], [-980.0, 1259.78], [-976.0, 1265.53], [-972.0, 1270.24], [-968.0, 1273.78], [-964.0, 1276.39], [-960.0, 1278.22], [-956.0, 1279.44], [-952.0, 1280.18], [-948.0, 1280.59], [-944.0, 1280.68], [-940.0, 1280.6], [-936.0, 1280.45], [-932.0, 1280.35], [-928.0, 1280.4], [-924.0, 1280.72], [-920.0, 1281.47], [-916.0, 1282.7], [-912.0, 1284.5], [-908.0, 1286.73], [-904.0, 1289.21], [-900.0, 1291.93], [-896.0, 1294.78], [-892.0, 1297.52], [-888.0, 1300.16], [-884.0, 1302.52], [-880.0, 1304.78], [-876.0, 1306.97], [-872.0, 1309.13], [-868.0, 1311.2], [-864.0, 1313.37], [-860.0, 1315.57], [-856.0, 1317.8], [-852.0, 1320.06], [-848.0, 1322.41], [-844.0, 1324.71], [-840.0, 1327.08], [-836.0, 1329.38], [-832.0, 1331.68], [-828.0, 1334.05], [-824.0, 1336.35], [-820.0, 1338.64], [-816.0, 1341.0], [-812.0, 1343.27], [-808.0, 1345.57], [-804.0, 1347.77], [-800.0, 1349.92], [-796.0, 1352.04], [-792.0, 1354.06], [-788.0, 1356.03], [-784.0, 1357.97], [-780.0, 1359.86], [-776.0, 1361.7], [-772.0, 1363.42], [-768.0, 1365.08], [-764.0, 1366.75], [-760.0, 1368.32], [-756.0, 1369.86], [-752.0, 1371.39], [-748.0, 1372.93], [-744.0, 1374.47], [-740.0, 1376.04], [-736.0, 1377.63], [-732.0, 1379.23], [-728.0, 1380.85], [-724.0, 1382.49], [-720.0, 1384.13], [-716.0, 1385.77], [-712.0, 1387.48], [-708.0, 1389.13], [-704.0, 1390.77], [-700.0, 1392.48], [-696.0, 1394.12], [-692.0, 1395.77], [-688.0, 1397.46], [-684.0, 1399.1], [-680.0, 1400.72], [-676.0, 1402.38], [-672.0, 1403.96], [-668.0, 1405.52], [-664.0, 1407.06], [-660.0, 1408.59], [-656.0, 1410.13], [-652.0, 1411.76], [-648.0, 1413.38], [-644.0, 1415.05], [-640.0, 1416.83], [-636.0, 1418.63], [-632.0, 1420.39], [-628.0, 1422.16], [-624.0, 1423.8], [-620.0, 1425.35], [-616.0, 1426.78], [-612.0, 1428.01], [-608.0, 1429.13], [-604.0, 1430.15], [-600.0, 1431.04], [-596.0, 1431.92], [-592.0, 1432.76], [-588.0, 1433.59], [-584.0, 1434.42], [-580.0, 1435.26], [-576.0, 1436.09], [-572.0, 1436.91], [-568.0, 1437.68], [-564.0, 1438.42], [-560.0, 1439.1], [-556.0, 1439.74], [-552.0, 1440.33], [-548.0, 1440.86], [-544.0, 1441.34], [-540.0, 1441.77], [-536.0, 1442.17], [-532.0, 1442.51], [-528.0, 1442.79], [-524.0, 1443.0], [-520.0, 1443.11], [-516.0, 1443.11], [-512.0, 1442.97], [-508.0, 1442.68], [-504.0, 1442.21], [-500.0, 1441.58], [-496.0, 1440.97], [-492.0, 1440.4], [-488.0, 1439.9]]
## the PROMENADE's centre line [v, u]: 8 m in from the dune line (on the grass), smoothed over 40 m; 3 m wide, paved
const PROM := [[-1108.0, 1008.81], [-1100.0, 1010.94], [-1092.0, 1014.05], [-1084.0, 1018.17], [-1076.0, 1022.88], [-1068.0, 1028.02], [-1060.0, 1033.68], [-1052.0, 1040.15], [-1044.0, 1047.71], [-1036.0, 1056.58], [-1028.0, 1066.71], [-1020.0, 1077.89], [-1012.0, 1089.86], [-1004.0, 1102.47], [-996.0, 1115.59], [-988.0, 1129.16], [-980.0, 1142.96], [-972.0, 1156.52], [-964.0, 1169.07], [-956.0, 1179.92], [-948.0, 1188.62], [-940.0, 1195.19], [-932.0, 1200.05], [-924.0, 1203.87], [-916.0, 1207.21], [-908.0, 1210.38], [-900.0, 1213.35], [-892.0, 1215.92], [-884.0, 1217.94], [-876.0, 1219.41], [-868.0, 1220.44], [-860.0, 1221.15], [-852.0, 1221.61], [-844.0, 1221.71], [-836.0, 1221.25], [-828.0, 1220.2], [-820.0, 1218.63], [-812.0, 1216.74], [-804.0, 1214.81], [-796.0, 1213.06], [-788.0, 1211.45], [-780.0, 1209.81], [-772.0, 1208.07], [-764.0, 1206.13], [-756.0, 1204.11], [-748.0, 1202.24], [-740.0, 1200.7], [-732.0, 1199.35], [-724.0, 1198.07], [-716.0, 1196.61], [-708.0, 1194.68], [-700.0, 1192.35], [-692.0, 1189.85], [-684.0, 1187.24], [-676.0, 1184.65], [-668.0, 1182.06], [-660.0, 1179.27], [-652.0, 1176.23], [-644.0, 1172.95], [-636.0, 1169.58], [-628.0, 1166.4], [-620.0, 1163.57], [-612.0, 1161.09], [-604.0, 1158.78], [-596.0, 1156.42], [-588.0, 1153.82], [-580.0, 1150.98], [-572.0, 1148.05], [-564.0, 1145.21], [-556.0, 1142.45], [-548.0, 1139.73], [-540.0, 1136.73], [-532.0, 1133.25], [-524.0, 1129.4], [-516.0, 1125.32], [-508.0, 1121.34], [-500.0, 1118.23], [-492.0, 1116.07]]

## the land NORTH-EAST of the bridge (between the off-ramp, the approach and the sea) goes whole to n_eb_ne, also where it
## lies west of u 960: this polygon (the bridge's own north-east edge, closed far outside) is taken out of n_eb_nw and kept
## by n_eb_ne, so the two meet exactly
const NCUT := [[962.496, -1011.76], [960.99, -1014.122], [958.52, -1018.079], [956.574, -1021.259], [954.175, -1025.249], [951.338, -1030.06], [950.54, -1031.48], [949.774, -1032.918], [949.035, -1034.37], [948.32, -1035.834], [947.143, -1038.367], [945.784, -1041.429], [943.233, -1047.308], [940.784, -1052.816], [939.339, -1056.232], [938.301, -1058.792], [936.895, -1062.414], [935.558, -1066.044], [934.912, -1067.872], [933.867, -1070.938], [932.666, -1074.656], [931.522, -1078.42], [930.796, -1080.944], [930.377, -1080.73], [929.724, -1083.129], [929.234, -1085.005], [928.304, -1088.769], [927.441, -1092.549], [926.646, -1096.344], [926.274, -1098.247], [925.918, -1100.153], [925.259, -1103.974], [924.955, -1105.888], [924.405, -1109.67], [924.155, -1111.565], [924.155, -1120.0], [1000.0, -1120.0], [1000.0, -1011.76]]

## a table [[key, value], ...] sorted by key, read linearly (clamped at the ends)
static func tab(t: Array, x: float) -> float:
	if x <= float(t[0][0]): return float(t[0][1])
	for i in t.size() - 1:
		var b: Array = t[i + 1]
		if x <= float(b[0]):
			var a: Array = t[i]
			return lerpf(float(a[1]), float(b[1]), (x - float(a[0])) / maxf(float(b[0]) - float(a[0]), 1e-6))
	return float(t[t.size() - 1][1])
static func ring_u(v: float) -> float: return tab(RING, v)
static func dune_u(v: float) -> float: return tab(DUNE, v)
static func zero_u(v: float) -> float: return tab(ZERO, v)
static func prom_u(v: float) -> float: return tab(PROM, v)
## the distance from (u, v) to the 0 m line on the land side (0 on the water side): the polyline ZERO, its rows near v
static func zero_dist(u: float, v: float) -> float:
	if u >= zero_u(v): return 0.0
	var p := Vector2(u, v); var best := INF
	var i0 := clampi(int((v - float(ZERO[0][0])) / 4.0) - 4, 0, ZERO.size() - 2)
	for i in range(i0, mini(i0 + 9, ZERO.size() - 1)):
		var a := Vector2(ZERO[i][1], ZERO[i][0]); var b := Vector2(ZERO[i + 1][1], ZERO[i + 1][0])
		var t := clampf((p - a).dot(b - a) / maxf((b - a).length_squared(), 1e-9), 0.0, 1.0)
		best = minf(best, p.distance_to(a + (b - a) * t))
	return best

## the bridge outline's segments, bucketed on a 16 m grid (a vertex looks only at the segments near it)
static var _seg: Array = []
static var _bk := {}
static func _bridge_init() -> void:
	if not _seg.is_empty(): return
	for i in BRIDGE.size() - 1:
		var a: Array = BRIDGE[i]; var b: Array = BRIDGE[i + 1]
		if absf(float(a[1]) + 1114.0) < 0.01 and absf(float(b[1]) + 1114.0) < 0.01: continue      # the closing line north of eb
		var s := [Vector2(a[0], a[1]), Vector2(b[0], b[1]), float(a[2]), float(b[2])]
		_seg.append(s)
		var lo := Vector2(minf(a[0], b[0]), minf(a[1], b[1])) - Vector2(EASE, EASE)
		var hi := Vector2(maxf(a[0], b[0]), maxf(a[1], b[1])) + Vector2(EASE, EASE)
		for bx in range(floori(lo.x / 16.0), floori(hi.x / 16.0) + 1):
			for bz in range(floori(lo.y / 16.0), floori(hi.y / 16.0) + 1):
				var k := Vector2i(bx, bz)
				if not _bk.has(k): _bk[k] = []
				_bk[k].append(_seg.size() - 1)
## [distance, foot (Vector2), edge height at the foot] of the nearest bridge edge, or [INF] when none within EASE
static func bridge_near(u: float, v: float) -> Array:
	_bridge_init()
	var k := Vector2i(floori(u / 16.0), floori(v / 16.0))
	if not _bk.has(k): return [INF]
	var p := Vector2(u, v); var best := [INF]
	for i: int in _bk[k]:
		var s: Array = _seg[i]
		var a: Vector2 = s[0]; var b: Vector2 = s[1]
		var t := clampf((p - a).dot(b - a) / maxf((b - a).length_squared(), 1e-9), 0.0, 1.0)
		var f := a + (b - a) * t; var d := p.distance_to(f)
		if d < float(best[0]): best = [d, f, lerpf(float(s[2]), float(s[3]), t)]
	return best

## THE GROUND (world height) at (u, v): see the rule in the header. Cached per point (the painter asks for each vertex
## of every cell several times).
static var _gc := {}
static func g(u: float, v: float) -> float:
	var key := Vector2(u, v)
	if _gc.has(key): return _gc[key]
	var land := LAND.at(u, v)
	var y := land + LIFT * smoothstep(0.0, WET, zero_dist(u, v))
	var ru := ring_u(v); var d := u - ru
	if d < EASE:
		var target := land + (RING_Y - LAND.at(ru, v))
		y = lerpf(target, y, smoothstep(0.0, EASE, maxf(d, 0.0)))
	var bn := bridge_near(u, v)
	if float(bn[0]) < EASE:
		var f: Vector2 = bn[1]
		var target2 := land + (float(bn[2]) - LAND.at(f.x, f.y))
		y = lerpf(target2, y, smoothstep(0.0, EASE, float(bn[0])))
	_gc[key] = y
	return y

## ---------------------------------------------------------------- the painter
## The piece's own land: the rectangle [x0, x1] x [z0, z1] cut to the ring's walk edge on the west, to SEA_LIM on the
## east, and with the bridge's outline taken out. Polygons in (u, v).
static func region(x0: float, z0: float, x1: float, z1: float) -> Array:
	var pts := PackedVector2Array()
	var west := func(z: float) -> float: return maxf(x0, ring_u(z))
	var east := func(z: float) -> float: return minf(x1, tab(SEA_LIM, z))
	pts.append(Vector2(west.call(z0), z0))
	pts.append(Vector2(east.call(z0), z0))
	for r: Array in SEA_LIM:
		if float(r[0]) > z0 + 0.01 and float(r[0]) < z1 - 0.01: pts.append(Vector2(east.call(float(r[0])), float(r[0])))
	pts.append(Vector2(east.call(z1), z1))
	pts.append(Vector2(west.call(z1), z1))
	var ring_in: Array = []
	for r: Array in RING:
		if float(r[0]) > z0 + 0.01 and float(r[0]) < z1 - 0.01: ring_in.append(Vector2(west.call(float(r[0])), float(r[0])))
	ring_in.reverse()
	for q: Vector2 in ring_in: pts.append(q)
	var br := PackedVector2Array()
	for r: Array in BRIDGE: br.append(Vector2(r[0], r[1]))
	return Geometry2D.clip_polygons(pts, br)

## mask "minus_ncut": without the land north-east of the bridge; "ncut_or_east": only that land, or u >= 960
static func masked(regs: Array, mask: String) -> Array:
	if mask == "": return regs
	var nc := PackedVector2Array()
	for q: Array in NCUT: nc.append(Vector2(q[0], q[1]))
	var out: Array = []
	for r: PackedVector2Array in regs:
		if mask == "minus_ncut": out.append_array(Geometry2D.clip_polygons(r, nc))
		else:
			var east := PackedVector2Array([Vector2(960.0, -1200.0), Vector2(1700.0, -1200.0), Vector2(1700.0, -400.0), Vector2(960.0, -400.0)])
			out.append_array(Geometry2D.intersect_polygons(r, nc))
			for q: PackedVector2Array in Geometry2D.intersect_polygons(r, east): out.append_array(Geometry2D.clip_polygons(q, nc))
	return out
static func _bbox(p: PackedVector2Array) -> Rect2:
	var r := Rect2(p[0], Vector2.ZERO)
	for q: Vector2 in p: r = r.expand(q)
	return r
static func _area(p: PackedVector2Array) -> float:
	var a := 0.0
	for i in p.size(): a += p[i].x * p[(i + 1) % p.size()].y - p[(i + 1) % p.size()].x * p[i].y
	return absf(a) * 0.5
## a polygon built along a polyline (a path): [mat, polygon] pieces of ~40 m each (each its own small box for the painter)
static func path_layers(mat: String, line: PackedVector2Array, w: float) -> Array:
	var out: Array = []
	var i := 0
	while i < line.size() - 1:
		var part := PackedVector2Array()
		var j := i; var ln := 0.0
		part.append(line[i])
		while j < line.size() - 1 and ln < 40.0:
			ln += line[j].distance_to(line[j + 1]); j += 1; part.append(line[j])
		# reach 0.3 m past both ends, so two parts overlap where they meet (no gap at the bend)
		var d0 := (part[0] - part[1]).normalized(); var d1 := (part[part.size() - 1] - part[part.size() - 2]).normalized()
		part[0] = part[0] + d0 * 0.3; part[part.size() - 1] = part[part.size() - 1] + d1 * 0.3
		for poly: PackedVector2Array in Geometry2D.offset_polyline(part, w * 0.5, Geometry2D.JOIN_ROUND, Geometry2D.END_BUTT):
			out.append([mat, poly])
		i = j
	return out
static func rect_layer(mat: String, x0: float, z0: float, x1: float, z1: float) -> Array:
	return [mat, PackedVector2Array([Vector2(x0, z0), Vector2(x1, z0), Vector2(x1, z1), Vector2(x0, z1)])]
## the sand: east of the DUNE line
static func sand_layer() -> Array:
	var p := PackedVector2Array()
	for r: Array in DUNE: p.append(Vector2(r[1], r[0]))
	p.append(Vector2(1600.0, float(DUNE[DUNE.size() - 1][0]))); p.append(Vector2(1600.0, float(DUNE[0][0])))
	return ["sand", p]

static var stats := {"cells": 0, "polys": 0, "holes": 0, "tri_fail": 0}
## Paint the piece's region on the global 4 m grid (the land's own nodes; finer lines may be added), each cell cut
## exactly to the region and to every layer polygon (first layer wins; "-" = a hole, a pad drawn by itself), the rest
## grass. Heights from yfn (world = local: the pieces stand at [0, 0, 0]).
static func paint_region(g: K.Ground, x0: float, z0: float, x1: float, z1: float, layers: Array, yfn: Callable, step := 4.0, base := "grass", mask := "", zextra: Array = []) -> void:
	var regs: Array = masked(region(x0, z0, x1, z1), mask)
	var rb: Array = []
	var all := Rect2()
	for r: PackedVector2Array in regs:
		rb.append(_bbox(r)); all = rb[0] if all.size == Vector2.ZERO else all.merge(rb[rb.size() - 1])
	var lb: Array = []
	for L: Array in layers: lb.append(_bbox(L[1]))
	var xs := H._lines(maxf(x0, all.position.x), minf(x1, all.end.x), step)
	var zs := H._lines(z0, z1, step, zextra)
	for i in xs.size() - 1:
		for j in zs.size() - 1:
			var xa: float = xs[i]; var xb: float = xs[i + 1]; var za: float = zs[j]; var zb: float = zs[j + 1]
			var cell := PackedVector2Array([Vector2(xa, za), Vector2(xb, za), Vector2(xb, zb), Vector2(xa, zb)])
			var cr := Rect2(xa, za, xb - xa, zb - za)
			var parts: Array = []
			for k in regs.size():
				if not (rb[k] as Rect2).intersects(cr): continue
				parts.append_array(Geometry2D.intersect_polygons(cell, regs[k]))
			if parts.is_empty(): continue
			stats.cells += 1
			var ls: Array = []
			for k in layers.size():
				if (lb[k] as Rect2).intersects(cr): ls.append(layers[k])
			_emit(g, parts, ls, yfn, base, 0)

static func _has_hole(ps: Array) -> bool:
	if ps.size() < 2: return false
	var cw := Geometry2D.is_polygon_clockwise(ps[0])
	for p: PackedVector2Array in ps:
		if Geometry2D.is_polygon_clockwise(p) != cw: return true
	return false
static func _emit(g: K.Ground, parts: Array, ls: Array, yfn: Callable, base: String, depth: int) -> void:
	var rem: Array = parts
	for L: Array in ls:
		var nr: Array = []
		for r: PackedVector2Array in rem:
			var ins := Geometry2D.intersect_polygons(r, L[1])
			var outs := Geometry2D.clip_polygons(r, L[1])
			if _has_hole(outs) or _has_hole(ins):
				if depth < 4:
					# a layer wholly inside this bit: cut the bit in four and paint each (no polygon with a hole)
					var bb := _bbox(r); var c := bb.get_center()
					var q4: Array = []
					for qr: Rect2 in [Rect2(bb.position, c - bb.position), Rect2(Vector2(c.x, bb.position.y), Vector2(bb.end.x - c.x, c.y - bb.position.y)),
							Rect2(Vector2(bb.position.x, c.y), Vector2(c.x - bb.position.x, bb.end.y - c.y)), Rect2(c, bb.end - c)]:
						var qp := PackedVector2Array([qr.position, Vector2(qr.end.x, qr.position.y), qr.end, Vector2(qr.position.x, qr.end.y)])
						q4.append_array(Geometry2D.intersect_polygons(r, qp))
					_emit(g, q4, ls, yfn, base, depth + 1)
					continue
				stats.holes += 1
			for p: PackedVector2Array in ins:
				if L[0] != "-": _poly(g, String(L[0]), p, yfn)
			nr.append_array(outs)
		rem = nr
		if rem.is_empty(): return
	for r: PackedVector2Array in rem: _poly(g, base, r, yfn)
static func _poly(g: K.Ground, m: String, p0: PackedVector2Array, yfn: Callable) -> void:
	var p := PackedVector2Array()
	for q: Vector2 in p0:
		if p.is_empty() or p[p.size() - 1].distance_to(q) > 1e-3: p.append(q)
	if p.size() > 1 and p[0].distance_to(p[p.size() - 1]) <= 1e-3: p.remove_at(p.size() - 1)
	if p.size() < 3 or _area(p) < 1e-4: return
	stats.polys += 1
	# a whole grid cell: split along the diagonal whose two corners stand higher together, so the two flat triangles
	# never dip under the land's own (bilinear) surface between the 4 m nodes (the ground meets the land exactly at
	# the water's edge, so this is what keeps the land from showing through there)
	if p.size() == 4 and absf(p[0].y - p[1].y) + absf(p[2].y - p[3].y) < 1e-6 or p.size() == 4 and absf(p[0].x - p[1].x) + absf(p[2].x - p[3].x) < 1e-6:
		var hy: Array = []
		for q: Vector2 in p: hy.append(float(yfn.call(q.x, q.y)))
		var P3: Array = []
		for k in 4: P3.append(Vector3(p[k].x, hy[k], p[k].y))
		if hy[0] + hy[2] >= hy[1] + hy[3]:
			g.tri(m, P3[0], P3[1], P3[2]); g.tri(m, P3[0], P3[2], P3[3])
		else:
			g.tri(m, P3[1], P3[2], P3[3]); g.tri(m, P3[1], P3[3], P3[0])
		return
	var idx := Geometry2D.triangulate_polygon(p)
	if idx.is_empty():
		stats.tri_fail += 1
		for k in range(1, p.size() - 1): idx.append_array([0, k, k + 1])
	for k in range(0, idx.size(), 3):
		var a := p[idx[k]]; var b := p[idx[k + 1]]; var c := p[idx[k + 2]]
		g.tri(m, Vector3(a.x, yfn.call(a.x, a.y), a.y), Vector3(b.x, yfn.call(b.x, b.y), b.y), Vector3(c.x, yfn.call(c.x, c.y), c.y))

## ---------------------------------------------------------------- buildings (as n_fe_r5.gd)
static func bbox(f: String) -> Array:
	var st := K.building_stats(f)
	if st.has("near") and (st.near as Dictionary).has("bbox"): return (st.near as Dictionary).bbox
	var wd: Array = st.footprint_wd
	return [[-float(wd[0]) * 0.5, 0.0, -float(wd[1]) * 0.5], [float(wd[0]) * 0.5, float(st.get("height", 6.0)), float(wd[1]) * 0.5]]
static func fp(b: Array) -> Array:
	var x := bbox(String(b[1])); var cu: float = b[2]; var cv: float = b[3]; var yaw: float = b[4]
	if absf(yaw) < 1.0: return [cu + float(x[0][0]), cv + float(x[0][2]), cu + float(x[1][0]), cv + float(x[1][2])]
	if absf(yaw - 180.0) < 1.0: return [cu - float(x[1][0]), cv - float(x[1][2]), cu - float(x[0][0]), cv - float(x[0][2])]
	if absf(yaw - 90.0) < 1.0: return [cu + float(x[0][2]), cv - float(x[1][0]), cu + float(x[1][2]), cv - float(x[0][0])]
	return [cu - float(x[1][2]), cv + float(x[0][0]), cu - float(x[0][2]), cv + float(x[1][0])]

## the field graded up to the pads (as hs_fill_lib.graded: 6 % up to each pad), but only within REACH m of a pad, faded
## out over its last 3 m: on this shore the land falls 6 m to the sea, and hs_fill_lib's cone (pad - 6 % x distance,
## unbounded) lifted the beach 75 m from the bluff's overlook by 2 m
const REACH := 8.0
static func graded(field: Callable, pads: Array, slope := 0.06) -> Callable:
	return func(x: float, z: float) -> float:
		var y0: float = field.call(x, z)
		var y := y0
		for p: Array in pads:
			var dx := maxf(maxf(float(p[0]) - x, x - float(p[2])), 0.0); var dz := maxf(maxf(float(p[1]) - z, z - float(p[3])), 0.0)
			var d := sqrt(dx * dx + dz * dz)
			if d >= REACH: continue
			y = maxf(y, y0 + maxf(float(p[4]) - slope * d - y0, 0.0) * (1.0 - smoothstep(REACH - 3.0, REACH, d)))
		return y

## A closed fence round `pts` (each side from pts[i] to pts[i + 1], the last back to the first): H.fence's panels (never
## stretched, each standing at the lower ground of its ends), and ONE post at every joint, the corners included (H.fence
## would put two posts at each corner). gaps: [[side index, distance along that side from its start, width]] leave the
## panel(s) out there (a gate or an opening: the two ends face each other across it).
static func fence_loop(props: K.Props, panel: String, post: String, cond: String, pts: Array, gaps: Array, y: Callable) -> void:
	var joints := {}
	for i in pts.size():
		var a := Vector2(pts[i][0], pts[i][1]); var b := Vector2(pts[(i + 1) % pts.size()][0], pts[(i + 1) % pts.size()][1])
		var gs: Array = []
		for gp: Array in gaps:
			if int(gp[0]) == i: gs.append([float(gp[1]), float(gp[2])])
		H.fence(props, panel, "", a, b, y, 2.0, cond, gs)
		var n := maxi(1, ceili(a.distance_to(b) / 2.0 - 0.02)); var d := (b - a).normalized(); var seg := a.distance_to(b) / n
		var drawn: Array = []
		for k in n:
			var sk := false
			for gp: Array in gs:
				if absf(seg * (k + 0.5) - float(gp[0])) < float(gp[1]) * 0.5: sk = true
			drawn.append(not sk)
		for k in n + 1:
			if not ((k > 0 and drawn[k - 1]) or (k < n and drawn[k])): continue     # no post standing alone in an opening
			var p := a + d * seg * k
			var key := Vector2i(roundi(p.x * 100.0), roundi(p.y * 100.0))
			if not joints.has(key): joints[key] = [p, rad_to_deg(atan2(d.x, d.y))]
	for jv: Array in joints.values():
		var p: Vector2 = jv[0]
		props.add(post, cond, Vector3(p.x, float(y.call(p.x, p.y)) - 0.02, p.y), float(jv[1]))

## ---------------------------------------------------------------- one piece, drawn from its own hand lists
## Every list comes from the piece script (each line with its reason there); this only draws them:
##  B      buildings [label, model, u, v, yaw]: each on a level concrete pad at the highest ground under it (+0.3 m margin)
##  TERR   level plaza terraces [u0, v0, u1, v1]: at the highest ground under them, faces down to the field
##  PAVE   paved rects [u0, v0, u1, v1, mat] at the field's height (paths, landings, forecourts)
##  FENCES [panel, post, cond, corners [[u, v], ...], gaps [[side, at, width]]]: a CLOSED fence round the corners (every
##         end meets the next run; an opening only where a gap is listed), fence_loop below
##  ITEMS  [base, cond, u, v, yaw(, collide)] on the field
## The field: the ground rule g() graded up to the pads and terraces at 6 % within 8 m (graded() above). The promenade (PROM, 3 m, plaza)
## and the sand (east of DUNE) are painted everywhere they fall in the piece. Returns the building pad heights.
static func run_piece(name: String, rect: Array, mask: String, B: Array, TERR: Array, PAVE: Array, FENCES: Array, ITEMS: Array, SC: Dictionary) -> Array:
	var root := Node3D.new(); root.name = name
	var bl := Node3D.new(); bl.name = "Buildings"; root.add_child(bl)
	var gr := K.Ground.new(); var props := K.Props.new(); var dec := K.Decals.new()
	var yb := func(x: float, z: float) -> float: return g(x, z)
	var PY: Array = []; var pe: Array = []; var holes: Array = []
	for b: Array in B:
		var f := fp(b)
		PY.append(H.pad_height(f, float(b[4]), yb)); pe.append(H.pad_entry(f, float(PY[PY.size() - 1])))
		var r := H.pad_rect(f); holes.append(rect_layer("-", r[0], r[1], r[2], r[3]))
	var TY: Array = []
	for t: Array in TERR:
		var ty := H.pad_height([t[0], t[1], t[2], t[3]], 0.0, yb, 0.0)
		TY.append(ty); pe.append([t[0], t[1], t[2], t[3], ty]); holes.append(rect_layer("-", t[0], t[1], t[2], t[3]))
	var yf := graded(yb, pe)
	var layers: Array = holes.duplicate()
	for p: Array in PAVE: layers.append(rect_layer(String(p[4]), p[0], p[1], p[2], p[3]))
	var pl := PackedVector2Array()
	for r: Array in PROM: pl.append(Vector2(r[1], r[0]))
	layers.append_array(path_layers("plaza", pl, 3.0))
	layers.append(sand_layer())
	# rows also at the approach end's kerbs (u 1180), so the ground holds the verge | road steps there exactly
	paint_region(gr, rect[0], rect[1], rect[2], rect[3], layers, yf, 4.0, "grass", mask, [-917.2, -915.3, -915.2, -895.72, -895.62, -892.8])
	for i in B.size(): H.pad_at(gr, fp(B[i]), float(PY[i]), yf)
	for i in TERR.size():
		var t: Array = TERR[i]
		H.level_pad(gr, "plaza", t[0], t[1], t[2], t[3], float(TY[i]), yf)
	for i in B.size():
		var b: Array = B[i]
		K.building(bl, String(b[1]), Vector3(b[2], float(PY[i]), b[3]), float(b[4]), String(b[0]))
		print("BUILDING %s %s at (%.2f, %.4f, %.2f) yaw %.0f" % [b[0], b[1], b[2], PY[i], b[3], b[4]])
	for f: Array in FENCES:
		fence_loop(props, String(f[0]), String(f[1]), String(f[2]), f[3], f[4], yf)
	for it: Array in ITEMS:
		H.put(props, String(it[0]), String(it[1]), float(it[2]), float(it[3]), yf, float(it[4]), bool(it[5]) if it.size() > 5 else true)
	H.sc_apply(root, props, dec, SC)
	print("%s painter: %s" % [name, stats])
	H.finish(root, gr, props, dec, name)
	return PY
