#!/usr/bin/env python3
"""Set Godot's humanoid retarget import options on a body or clip file (the standard skeleton).
   python3 -I tools/people/humanoid/set_import.py <bonemap.tres res path> <skeleton node path> <file.import>...
Then: godot --headless --path . --import"""
import re, sys
bm, node, files = sys.argv[1], sys.argv[2], sys.argv[3:]
SUB = ('_subresources={\n"nodes": {\n"PATH:%s": {\n'
       '"retarget/bone_map": Resource("%s"),\n'
       '"retarget/bone_renamer/rename_bones": true,\n'
       '"retarget/bone_renamer/unique_node/make_unique": true,\n'
       '"retarget/bone_renamer/unique_node/skeleton_name": "GeneralSkeleton",\n'
       '"retarget/remove_tracks/except_bone_transform": false,\n'
       '"retarget/remove_tracks/unimportant_positions": true,\n'
       '"retarget/remove_tracks/unmapped_bones": true,\n'
       '"retarget/rest_fixer/apply_node_transforms": true,\n'
       '"retarget/rest_fixer/normalize_position_tracks": true,\n'
       '"retarget/rest_fixer/reset_all_bone_poses_after_import": true,\n'
       '"retarget/rest_fixer/retarget_method": 1,\n'
       '"retarget/rest_fixer/keep_global_rest_on_leftovers": true,\n'
       '"retarget/rest_fixer/fix_silhouette/enable": true,\n'
       '"retarget/rest_fixer/fix_silhouette/threshold": 15.0,\n'
       '"retarget/rest_fixer/fix_silhouette/base_height_adjustment": 0.0\n'
       '}\n}\n}') % (node, bm)
for f in files:
    t = open(f).read()
    t = re.sub(r'_subresources=\{.*?\}\n(?=[a-z_]+/|\Z)', SUB + '\n', t, flags=re.S) if '_subresources={}' not in t else t.replace('_subresources={}', SUB)
    t = t.replace('animation/trimming=false', 'animation/trimming=true')
    open(f, 'w').write(t)
    print('set', f)
