# Mixamo mocap files, the Mixamo skeleton, and the Mixamo -> Godot 4 pipeline (state: 25 Nov 2026)

Method note. Every finding below comes from a page or file fetched in this session; nothing is written from memory.
Three kinds of evidence are used and labelled:
- **[inspected]** - I downloaded the file and read it myself (two real Mixamo FBX files parsed with a small binary-FBX reader; Godot C++ source and docs `.rst` read as raw text).
- **[page]** - a web page fetched and read (official docs, Adobe pages, forum threads).
- **[search snippet]** - only seen in a search result summary, page itself not opened. Treat as weak.

Godot version context: the newest stable release listed on the Godot download archive is **4.7.2-stable (18 Aug 2026)**; 4.8 is in beta (4.8-beta5, 24 Nov 2026) - [Godot download archive](https://godotengine.org/download/archive/) [page]. The "stable" docs are labelled **Godot 4.7** - [Retargeting 3D Skeletons](https://docs.godotengine.org/en/stable/tutorials/assets_pipeline/retargeting_3d_skeletons.html) [page]. So "current stable" is 4.7, not 4.5/4.6.

Sources that could NOT be read: `mixamo.com` itself (login-only app; no download dialog or animation catalogue could be inspected), `docs.readyplayer.me` (host not resolvable from this session), the RWTH Aachen wiki page (bot wall), several Adobe HelpX URLs I guessed (403). These gaps are listed per section.

---

## 1. The Mixamo skeleton: bone list, hierarchy, prefix, rest pose, units, axes

### Takeaway
The standard Mixamo rig is 65 joints rooted at `mixamorig:Hips` with **no root bone above the hips**; the full list and hierarchy below were read directly out of two real Mixamo FBX files, and match three independent published bone maps. Joint *orientations* are not the same in every Mixamo file (one sample has world-aligned joints with no pre-rotation, the other has bone-aligned joints with pre-rotations), which is exactly why Godot needs its rest fixer.

### Cited Findings

**Full hierarchy [inspected]** - read from the FBX `Objects`/`Connections` sections of `mixamo.fbx` (X Bot, written by mixamo.com 16 Sep 2024, FBX 7700): 65 `LimbNode` joints, 2 meshes (`Beta_Surface`, `Beta_Joints`), no other joint. - [three.js examples/models/fbx/mixamo.fbx](https://raw.githubusercontent.com/mrdoob/three.js/dev/examples/models/fbx/mixamo.fbx)

```
mixamorig:Hips                                (top joint - parent is the scene, no "Root"/"Armature" joint)
├─ mixamorig:Spine
│  └─ mixamorig:Spine1
│     └─ mixamorig:Spine2
│        ├─ mixamorig:Neck
│        │  └─ mixamorig:Head
│        │     └─ mixamorig:HeadTop_End
│        ├─ mixamorig:LeftShoulder
│        │  └─ mixamorig:LeftArm
│        │     └─ mixamorig:LeftForeArm
│        │        └─ mixamorig:LeftHand
│        │           ├─ mixamorig:LeftHandThumb1 → Thumb2 → Thumb3 → Thumb4
│        │           ├─ mixamorig:LeftHandIndex1 → Index2 → Index3 → Index4
│        │           ├─ mixamorig:LeftHandMiddle1 → Middle2 → Middle3 → Middle4
│        │           ├─ mixamorig:LeftHandRing1 → Ring2 → Ring3 → Ring4
│        │           └─ mixamorig:LeftHandPinky1 → Pinky2 → Pinky3 → Pinky4
│        └─ mixamorig:RightShoulder → RightArm → RightForeArm → RightHand → (same 5 fingers x 4, "RightHand...")
├─ mixamorig:LeftUpLeg
│  └─ mixamorig:LeftLeg
│     └─ mixamorig:LeftFoot
│        └─ mixamorig:LeftToeBase
│           └─ mixamorig:LeftToe_End
└─ mixamorig:RightUpLeg → RightLeg → RightFoot → RightToeBase → RightToe_End
```
Count check: 1 (Hips) + 3 (Spine, Spine1, Spine2) + 3 (Neck, Head, HeadTop_End) + 2x4 (Shoulder, Arm, ForeArm, Hand) + 2x20 (5 fingers x 4 joints) + 2x5 (UpLeg, Leg, Foot, ToeBase, Toe_End) = **65**.

- A second real Mixamo file, `Samba Dancing.fbx` (written by mixamo.com 1 May 2018, FBX 7400, character meshes `Alpha_Surface`/`Alpha_Joints`), has the same 65 joints **plus `mixamorig:LeftEye` and `mixamorig:RightEye` as children of `mixamorig:Head`** = 67 joints. So eye joints exist on some Mixamo characters and not others. [inspected] - [three.js examples/models/fbx/Samba Dancing.fbx](https://raw.githubusercontent.com/mrdoob/three.js/dev/examples/models/fbx/Samba%20Dancing.fbx)
- Both files identify themselves in the FBX header as `Original|ApplicationVendor = "Mixamo, Inc."`, `Original|ApplicationName = "mixamo.com"`, and `Original|FileName = "MotionOnlyScene; Retargeted Clip; Motion Sequence; 1 motions; Skeleton mixamorig:Hips_skin-file:..."`. [inspected] - same two files.
- Independent bone-name lists that agree with the inspection:
  - pixiv three-vrm's Mixamo->VRM map enumerates Hips, Spine, Spine1, Spine2, Neck, Head, Left/Right Shoulder, Arm, ForeArm, Hand, HandThumb1-3, HandIndex1-3, HandMiddle1-3, HandRing1-3, HandPinky1-3, UpLeg, Leg, Foot, ToeBase (written without the colon: `mixamorigHips`). [inspected] - [mixamoVRMRigMap.js](https://raw.githubusercontent.com/pixiv/three-vrm/dev/packages/three-vrm/examples/humanoidAnimation/mixamoVRMRigMap.js)
  - The Godot add-on MixaBridge ships a table with all of the above plus `HeadTop_End`, `Left/RightToe_End` and the `...Thumb4/Index4/Middle4/Ring4/Pinky4` tip joints (mapped to nothing). [inspected] - [mixamo_bone_table.gd](https://raw.githubusercontent.com/uzairdeveloper223/mixabridge/main/addons/mixabridge/mixamo_bone_table.gd)
  - The Blender add-on mixamo_converter looks for the hip under the names `'Hips', 'mixamorig:Hips', 'mixamorig_Hips', 'Pelvis'`. [inspected] - [mixamoconv.py](https://raw.githubusercontent.com/enziop/mixamo_converter/master/mixamoconv.py)

**Finger count is not fixed.** An Adobe community manager (JMathews, 24 Sep 2020): "Mixamo generates a dynamic amount of finger bones based on the mesh"; fingers modelled too close together (mitten hands) can yield one finger only. A user in the same thread calls the full rig the "standard 65 bone skeleton". [page] - [Adobe community: Mixamo standard 65 bone skeleton](https://community.adobe.com/questions-696/mixamo-standard-65-bone-skeleton-589638). Another thread: "the number of fingers is set at import stage" (user Ussnorway, 30 Nov 2021). [page] - [Adobe community thread 589202](https://community.adobe.com/questions-696/mixamo-no-longer-rigs-hands-with-corrent-number-of-fingers-pleaes-fix-589202)

**Prefix / namespace.**
- In the FBX file the joint names are literally `mixamorig:Hips` etc. (colon). [inspected] - both FBX files above.
- Godot replaces `:` and `/` in bone names with `_` on import (`bone_name.replace_chars(":/", '_')`), so in Godot the bones are `mixamorig_Hips`, `mixamorig_Spine`, ... This is in `SkinTool::_sanitize_bone_name`, the code path used when skeletons are built by the FBX (ufbx) and glTF importers. [inspected] - [godot master modules/gltf/skin_tool.cpp](https://raw.githubusercontent.com/godotengine/godot/master/modules/gltf/skin_tool.cpp), [gltf_document.cpp](https://raw.githubusercontent.com/godotengine/godot/master/modules/gltf/gltf_document.cpp)
- Tools therefore handle several spellings: `mixamorig:` and `mixamorig_` (MixaBridge, mixamo_converter - links above), and `mixamorig` with no separator (three-vrm map above).
- A PlayCanvas user had one animation file with `mixamorig1:Hips`-style names while the model used `mixamorig:Hips`, so the animation did not bind. [search snippet] - [PlayCanvas forum](https://forum.playcanvas.com/t/can-i-reuse-a-animation-on-a-different-model-with-the-same-bone-names/12347)
- "The 'Mixamorig:[name]' format has literally been there since the beginning" (forum user who says they used Mixamo in 2013). [page] - [GameDev.tv forum, 19 May 2022](https://community.gamedev.tv/t/re-mixamo-bone-names-in-3pc-t/201395)

**Axes, facing, rest pose [inspected]** (both FBX files, `GlobalSettings`):
- `UpAxis = 1` (Y), `UpAxisSign = 1`, `FrontAxis = 2` (Z), `CoordAxis = 0` (X), `UnitScaleFactor = 1.0`, `TimeMode = 6`.
- Hips rest translation is about (0, 99.7, 0.2) in the 2018 file and (0, 104.3, 1.6) in the 2024 file - i.e. the numbers are in a unit where a human hip is ~100 units up.
- 2018 file: joints have **no `PreRotation` and no rest rotation**; child offsets show the pose directly: LeftShoulder at +X (6.1), LeftArm→LeftForeArm→LeftHand offsets are (+27.4, 0, 0) and (+27.6, 0, 0) (arms straight out along +X = T-pose, left side on +X); legs go down -Y (LeftLeg offset (0.25, -40.6, -0.5)); toes go +Z (LeftToeBase offset (0.37, -10.5, +12.6)). So: **T-pose, Y up, character faces +Z, character's left is +X**.
- 2024 X Bot file: the same joints carry **`PreRotation`** (e.g. LeftShoulder (-119.98, 75.95, 147.91), LeftUpLeg (1.19, 0, 180), LeftFoot (54.74, 0, 0), LeftToeBase (39.17, 0, 0)) and every child offset is along local **+Y** (LeftArm (0, 10.84, 0), LeftForeArm (0, 27.84, 0), LeftLeg (0, 44.37, 0)). So in this file the joints are bone-aligned (local +Y points to the child) rather than world-aligned.
- Both files: `Lcl Scaling` (1, 1, 1) on joints; no scaled parent joint exists inside the FBX itself.

**Units and scale in practice.**
- Godot's ufbx importer loads every FBX with `opts.target_axes = ufbx_axes_right_handed_y_up; opts.target_unit_meters = 1.0f; opts.space_conversion = UFBX_SPACE_CONVERSION_MODIFY_GEOMETRY;` - i.e. it converts the file to metres, Y-up, and bakes the conversion into geometry rather than leaving a scaled node. [inspected] - [godot master modules/fbx/fbx_document.cpp](https://raw.githubusercontent.com/godotengine/godot/master/modules/fbx/fbx_document.cpp)
- In Blender, a Mixamo FBX arrives as "0.01 scaled armature with 100 scaled child mesh" plus a 90 degree X rotation; applying the scale also requires dividing the Hips location keys by 100 (Babylon.js forum, Joe_Kerr, Apr 2022). [page] - [Babylon.js forum](https://forum.babylonjs.com/t/if-mixamo-transformations-and-bone-alignements-messed-up/29038)
- Godot forum users report needing 0.01 scale on physical bones / collision shapes for Mixamo rigs. [search snippet] - [Godot forum: Mixamo Ragdoll bones](https://forum.godotengine.org/t/mixamo-ragdoll-bones/131168), [Create Physical Skeleton is utterly broken](https://forum.godotengine.org/t/create-physical-skeleton-is-utterly-broken/102124)
- Adobe: the auto-rigger "works best when characters are set to the (0,0,0) origin of the world. This prevents animation offsets happening from unit differences." [inspected, HTML of the page] - [Adobe Mixamo FAQ](https://helpx.adobe.com/creative-cloud/faq/mixamo-faq.html)

**Auto-rigger inputs.** Upload formats FBX, OBJ, ZIP; markers are placed on "wrists, elbows, knees, and groin"; an already rigged character must be `.fbx` and "will have their skeleton automatically mapped to the Mixamo system, allowing animations to be applied to your custom skeleton". Page last updated 14 Sep 2021. [inspected, HTML] - [Adobe HelpX: Upload and rig 3D characters with Mixamo](https://helpx.adobe.com/creative-cloud/help/mixamo-rigging-animation.html). Bipedal humanoids only. [inspected] - [Adobe Mixamo FAQ](https://helpx.adobe.com/creative-cloud/faq/mixamo-faq.html)

### Inferences
- "65" = the standard skeleton without eye joints; a library character with eyes shows 67. Any pipeline must tolerate extra `LeftEye`/`RightEye` (Godot's humanoid profile has slots for them, see section 5).
- The 13 joints `HeadTop_End`, `Left/RightToe_End` and the ten `...4` finger tips are end markers: they carry no animation in either sample (section 2) and no published map sends them anywhere.
- Because joint orientation differs between Mixamo files (world-aligned vs bone-aligned with PreRotation), raw rotation tracks from one Mixamo character are not guaranteed to be valid on another Mixamo character's rest pose. Sharing clips needs either "same character for every download" or an engine-side rest normalisation (Godot's Overwrite Axis).
- The forward axis (+Z) and T-pose of the 2018 sample already match the reference pose Godot's humanoid profile asks for (section 5), which is why Mixamo T-pose characters need no "Fix Silhouette".
- A no-fingers rig would be 65 - 40 = 25 joints by arithmetic on the list above. This is my arithmetic, not a sourced Mixamo statement.

### Gaps
- **Skeleton LOD options and their counts ("Standard Skeleton (65)", "3 Chain Fingers (49)", "2 Chain Fingers (41)", "No Fingers (25)")**: NOT verified. Search snippets confirm the labels "3 chain fingers" / "2 chain fingers" and "Skeleton LOD - No fingers" exist in user posts, but no fetched page states the counts 49 / 41 / 25. Needs a look at the live auto-rigger dialog.
- What `UnitScaleFactor = 1.0` means in FBX (centimetres) was not confirmed from a fetched spec; the cm reading rests on the ~100-unit hip height and the Blender 0.01 report.
- Bone *roll* convention as seen in Blender (how the FBX importer orients Mixamo bones) - not researched beyond the Babylon thread.
- `mixamorig1:`/`mixamorig2:` etc.: only one search snippet; when Mixamo emits a numbered namespace was not established.
- Whether the three.js sample files were re-saved after download (header says `LastSaved|ApplicationName = Maya`) is unknown; they are treated as representative Mixamo output because of the `Original|...mixamo.com` fields.

---

## 2. Animation files: formats, options, what is keyed, root motion, add-ons

### Takeaway
A Mixamo clip keys **rotation on 52 joints and translation on `Hips` only**; there is no root joint, so all travel, bob and sway live on the Hips. Clips are baked at a fixed rate (30 fps in both samples) and are retargeted by Mixamo to whichever character was selected at download. Several Blender add-ons exist purely to manufacture a root bone from the Hips motion.

### Cited Findings

**What is keyed [inspected]** (identical result in both sample files):
- 52 joints have a `Lcl Rotation` curve node; exactly **1 joint (`mixamorig:Hips`) also has `Lcl Translation`**; no joint has a scale curve pattern other than this (pattern counts: rotation-only x51, rotation+translation x1).
- Joints with **no curves at all**: `HeadTop_End`, the ten finger-tip `...4` joints, `LeftToe_End`, `RightToe_End` (and `LeftEye`/`RightEye` in the 2018 file).
- Keys are dense and uniform: 2018 file 547 keys per curve, 2024 file 506 keys per curve, key spacing 0.03333 s (= 30 fps), durations 18.2 s and 16.83 s. FBX time unit used for this conversion: 46186158000 ticks per second, and FBX `TimeMode 6` = 30 fps, both taken from Blender's FBX module. - [Blender io_scene_fbx/fbx_utils.py](https://raw.githubusercontent.com/blender/blender/main/scripts/addons_core/io_scene_fbx/fbx_utils.py)
- Hips translation is in the file's ~cm units and is absolute, not a delta: 2018 clip X -42.0..46.5, **Y 79.8..106.7**, Z -37.9..47.1; 2024 clip X -30.0..53.7, Y 76.8..103.2, Z -12.5..18.3. So vertical hip motion and lateral sway are in the same track as forward travel.
- Each file contains two animation stacks, named `Take 001` and `mixamo.com`.
- Both files are "with skin" downloads (they contain the character meshes).
- Sources: the two FBX files linked in section 1.
- Corroboration: "Mixamo appears to use location keys only on the Hips bone, with the other bones rotation-only" (Babylon.js forum thread linked in section 1) [page].

**FBX versions.**
- Adobe employee post, 9 Dec 2020: Mixamo core upgraded "from FBX2014.1 to FBX2019.0". [inspected, HTML] - [Adobe community 589679](https://community.adobe.com/questions-696/good-news-we-ve-upgraded-the-fbx-sdk-in-mixamo-core-from-fbx2014-1-to-fbx2019-0-589679)
- Adobe employee post, 18 Feb 2021: with that SDK upgrade "the output FBX file format was also upgraded from 7.4 to 7.5 ... we have added a compatibility option to enable exporting the previous FBX file version 7.4. This option is available in the download format pulldown menu." [inspected, HTML] - [Adobe community 589945](https://community.adobe.com/questions-696/additional-fbx-export-option-now-available-589945)
- Observed in files: the 2018 sample is FBX version 7400 (creator "FBX SDK/FBX Plugins version 2014.2.1"); the 2024 sample is FBX version 7700 (creator "FBX SDK/FBX Plugins version 2020.2"). [inspected] - FBX files in section 1. Note the 2024 file is 7700, not the 7.5 the 2021 post names.

**Download dialog options (third-party description only; the dialog itself could not be opened).** Animancer's (Unity plugin) manual describes: Format "FBX for Unity(.fbx)" vs "FBX(.fbx)" - the Unity variant "seems no different" for a model without animation but names the file `CharacterName@AnimationName`; Skin "With Skin"/"Without Skin" (without skin avoids a duplicate copy of the model in every animation file); Frames Per Second "30" ("60" can improve quality somewhat at larger size); Keyframe Reduction "None" recommended (reduction shrinks files but lowers quality); character download Pose "T-pose"; per-clip parameters on the right-hand panel are applied before download. [page] - [Animancer docs: Mixamo](https://kybernetik.com.au/animancer/docs/manual/getting/mixamo)

**Per-clip parameters.**
- "In Place" checkbox: a user reports "Most of the cases can be solved with the 'In place' checkbox, but this one in particular does not have it"; the accepted answer points to a different variant of the clip that does. A Blender workaround given there is to flatten the `Z Location (mixamorig:Hips)` curve. [inspected, HTML] - [Adobe community 589474](https://community.adobe.com/questions-696/fix-missing-in-place-for-animations-that-moves-589474)
- Packs cannot carry custom settings: "a pack is default animation only... you can set custom settings by downloading one animation at a time". [inspected, HTML] - [Adobe community 589782](https://community.adobe.com/questions-696/in-place-parameter-for-the-pack-589782)
- Overdrive / Character Arm-Space / Trim / Mirror: only search-snippet descriptions (overdrive changes motion intensity and is animation-specific; arm-space moves arms away from the body to reduce clipping; parameters differ per clip). [search snippet] - [Adobe community 589184](https://community.adobe.com/questions-696/how-does-the-overdrive-parameter-work-589184)

**Clips are character-specific.**
- The FBX header itself says "Retargeted Clip" and names the skin file it was retargeted to. [inspected] - FBX files in section 1.
- "The animations you download will get set up according to the character you have selected"; clips look wrong on a very different body (skinny human playing a clip downloaded for a brute). [page] - [GameDev.tv forum](https://community.gamedev.tv/t/re-mixamo-bone-names-in-3pc-t/201395)
- Godot forum (grix, Dec 2023 - Jan 2024, Godot 4.2): clips downloaded on X Bot made "the feet of the animation ... gliding across the floor" on a differently proportioned model; clips downloaded on a Mixamo character with closer proportions were better; best result came from uploading the own mesh as `.obj`, letting Mixamo auto-rig it, and using only the downloaded animations. [page] - [Godot forum 39619](https://forum.godotengine.org/t/retargeting-mixamo-animations-fails/39619)
- Same thread: when a **pre-rigged** custom character (with its own armature) was uploaded, "the root animation tracks is applied to the parent node, while the hip bones have no animation at all"; after re-uploading as `.obj` and auto-rigging, the "downloaded animations finally used the hip bone instead of the armature node". [page] - same link.
- Mixamo keeps only the last used character; no history. [inspected] - [Adobe Mixamo FAQ](https://helpx.adobe.com/creative-cloud/faq/mixamo-faq.html)

**No root bone -> add-ons that create one.**
- **mixamo_converter (enziop)** - Blender 2.80+; "Converts Mixamo animations to work in Unreal Engine 4 with root motion"; batch converts FBX/Collada; options `Use X`, `Use Y`, `Use Z`, `On Ground` ("A Root bone which stays on ground except for cases when the Hip moves higher than its restpose location"), "Only rotation along the Up Axis is transfered to the root", `Remove Namespace`, `Fix Bind` (adds a dummy mesh for skinless files "Otherwise the bindpose will not be saved properly"), `Apply Rotation`, `Apply Scale`, `Scale`. The code renames the armature object to `root` and bakes hip motion onto it via copy-location/copy-rotation constraints. [inspected] - [README](https://raw.githubusercontent.com/enziop/mixamo_converter/master/README.md), [mixamoconv.py](https://raw.githubusercontent.com/enziop/mixamo_converter/master/mixamoconv.py)
- **Mixamo Root (RichardPerry / same README under finepointcgi/Mixamo-Root)** - Blender 2.8+, built on Johngoss725's CC0 "Mixamo-To-Godot"; imports a folder of Mixamo clips, "Adds a root motion bone to the skeleton and keyframes", removes all but one armature ("assumes all animations imported are tailored to a single model"), optionally strips the prefix; "only been tested with importing fbx files and exporting to a collection for Godot 4"; forces actions to start at frame 0 "due to bugs with Godot". [inspected] - [README](https://raw.githubusercontent.com/RichardPerry/Mixamo-Root/main/README.md)
  - A Godot forum user (21 Mar 2026, Blender 2.8-4.5, Godot 4.5) says this add-on "never works for me" - "fails to install, crashes, or doesn't add/bake the root motion at all"; no working replacement was confirmed in the thread; the only reply suggests Godot's `RootMotionView` node. [page] - [Godot forum 135760](https://forum.godotengine.org/t/blender-addon-for-mixamo-root-motion-in-blender-4-5-godot-4-5/135760)
- **Import Mixamo - Root Motion (SunZiBingFa)** - Blender extension, v1.0.4, GPL-3.0-or-later, published 25 Jul 2024, listed compatibility Blender 4.2 LTS; "Batch Import Fbx (Mixamo) And Apply Root Motion", batch-removes the `mixamorig:` prefix, "batch create root bones to record Root Motion information", and a "Root Motion -> Rotation" option where the "Root bone copies Z-axis rotation from hips (world space)" and hips "Inherit Rotation" is disabled. One review: "helped me with getting root animations into Godot". [inspected, HTML] - [extensions.blender.org](https://extensions.blender.org/add-ons/import-mixamo-root-motion/)
- **Adobe's Mixamo add-on for Blender** - "Blender auto control-rig add-on" that "works with characters that have been auto-rigged with the Mixamo service"; "one-click solution to create an IK control rig" and to bake animation between control rig and skeleton; GPL v3. It does not advertise adding a root bone. [page] - [Adobe: Mixamo Blender add-on](https://www.adobe.com/products/substance3d/plugins/mixamo-in-blender.html)
  - The official add-on "is no longer supported" (official version is for Blender 3.6); a third-party continuation "Mixamo Rig" v1.2.3 (published 14 Nov 2025, GPL-3.0-or-later, says verified on Blender 5.1.2 and 5.2.2). [inspected, HTML] - [extensions.blender.org: Mixamo Rig](https://extensions.blender.org/add-ons/mixamo-rig/)
- Other tools seen only in search results: ywaby/mixamo2bl, Dig-Doug/mixamotoue4, the paid "Animexport Pro". [search snippet]

### Inferences
- Since vertical hip motion (bob, crouch, jump height) and lateral sway sit in the same Hips translation track as forward travel, using the Hips track directly as a root-motion source moves the capsule up/down and side to side with every step. A root bone that takes only ground-plane X/Z (and optionally yaw) - what `Use X/Use Y/On Ground` in mixamo_converter does - is the standard cure.
- "In Place" exists per clip and not for all clips, and packs download with defaults only; a traversal set that needs consistent in-place/not-in-place choices has to be downloaded clip by clip.
- The Babylon thread's warning that naive "divide hips location / zero it" scripts break stance changes (crouch happens "in place" instead of lowering) applies to any root-extraction that also removes Hips Y.
- Downloading every clip against the *final game character* (or a body of the same proportions) avoids most foot sliding; retargeting in-engine from X Bot is the weaker path.

### Gaps
- The exact list of Format entries (FBX Binary / FBX ASCII / FBX 7.4 / FBX 6.1 / FBX for Unity / Collada) was NOT seen on a fetched page. Verified pieces only: an "FBX 7.4" compatibility entry (Adobe post), "FBX for Unity(.fbx)" and "FBX(.fbx)" (Animancer), and Collada input being handled by mixamo_converter. "FBX Binary" appears only in search snippets.
- Frame-rate choices 24/30/60: only 30 and 60 were seen (Animancer). 24 not verified.
- Keyframe-reduction choices ("none / uniform / non-uniform"): only "None" verified.
- Precise definitions of In Place (which axes it zeroes), Overdrive, Character Arm-Space, Trim, Mirror: no authoritative page fetched.
- Whether Mixamo clips are flagged loopable or have matching first/last frames in general: not verified. (In the two samples the Hips first and last keys are nearly equal - 2018: X -0.18/-0.18, Y 95.58/95.58; 2024: X -0.26/-0.27, Y 102.60/102.61, Z 2.22/2.13 - but these are in-place dance clips, not evidence for locomotion clips.)
- A "without skin" download was not inspected, so what its bind pose / rest pose contains is unverified (mixamo_converter's `Fix Bind` text implies the bind pose is unreliable without a mesh).

---

## 3. Library content relevant to locomotion and traversal

### Takeaway
I could not open the Mixamo catalogue (login-only), so **none of the specific clip or pack names in the brief are verified**. What is verified: the library is large (a public mirror holds 2,453 animation files), it does contain climbing/hanging/shimmy material according to users, and people who built traversal on it report gaps.

### Cited Findings
- A Hugging Face dataset mirror of Mixamo lists exactly 2,453 files in its `animation/` folder (file names are hashes, so no clip names can be read from it; the dataset itself is access-gated). [inspected, file listing via API] - [huggingface.co/datasets/jasongzy/Mixamo](https://huggingface.co/datasets/jasongzy/Mixamo)
- Unreal forum, 29 Feb 2016 (user unit23): "There are root motion animations, currently for free at Mixamo.com" covering "climbing", "hanging", "climbing to surface stand...". [page] - [UE forum: Advanced Climbing System, post 36](https://forums.unrealengine.com/t/advanced-climbing-system/51566/36)
- Naming seen in search results only: "Braced Hang Idle (Braced = Feet on the wall)" and "Freehang Idle (Freehang = Feet not on the wall)" with shimmy / hop / climb-to-surface variants; a Garry's Mod extension built on Mixamo movement clips mentions "bracedhang idle and shimmy anims" and "climbing, shimmying, hanging, landing". [search snippet] - [UE forum: Climbing system that actually works?](https://forums.unrealengine.com/t/climbing-system-that-actually-works/73955/16), [Steam Workshop changelog](https://steamcommunity.com/sharedfiles/filedetails/changelog/2919093249)
- A crouch-walk clip exists in more than one variant, one with and one without the In Place option. [inspected, HTML] - [Adobe community 589474](https://community.adobe.com/questions-696/fix-missing-in-place-for-animations-that-moves-589474)
- Known limitations with a source:
  - Foot sliding / feet "still not fully grounded" when clips are played on a body with different proportions. [page] - [Godot forum 39619](https://forum.godotengine.org/t/retargeting-mixamo-animations-fails/39619)
  - Not every moving clip offers "In Place"; packs download with default parameters only. [inspected] - Adobe community 589474 and 589782 (links above).
  - Clips carry no metadata beyond the curves: the FBX files contain joints, meshes, two animation stacks and nothing describing obstacle height, contact frames or events. [inspected] - FBX files in section 1.

### Inferences
- Because every clip stores absolute Hips translation with its own start position and there is no root joint or contact metadata, start/end pose and displacement of each traversal clip must be **measured from the file** (Hips XZ at first/last key, peak Hips Y, hand positions at the grab frame) and stored in the game's own table; obstacle heights the clip "fits" have to be derived that way. This follows from section 2's inspection, not from a Mixamo statement.
- Inconsistent start/end poses between clips could not be checked without the clips; expect it and plan blend-in/blend-out or pose-matching rather than assuming clips chain.

### Gaps
- NOT verified (catalogue not reachable): existence and contents of "Locomotion Pack", "Male/Female Locomotion Pack", "Pro Rifle Pack", any "Cover" pack; clip names "Climbing", "Braced Hang", "Hanging Idle", "Braced Hang To Crouch", "Crouched To Standing", "Freehang Climb", "Shimmy", "Running Jump", "Jump Over", "Vault", "Ascending Stairs", "Descending Stairs", "Running Up Stairs", "Hard Landing", "Falling Idle", roll/drop/ledge clips. A search for pack names returned only third-party products (MoCap Online "Rifle Pro", "Cover Animset Pro"), which are not Mixamo.
- Root displacement, duration and obstacle dimensions per traversal clip: unknown until the clips are downloaded and measured.
- Whether stairs clips assume a particular step rise/run: unknown.

---

## 4. Licensing

### Takeaway
Adobe states Mixamo characters and animations may be used royalty-free in commercial projects including video games; the one thing the community-forum licensing FAQ forbids is distributing the raw character/animation files themselves.

### Cited Findings
- Adobe FAQ (last updated 14 Sep 2021): "Mixamo is available free for anyone with an Adobe ID and does not require a subscription to Creative Cloud"; "You can use both characters and animations royalty free for personal, commercial, and non-profit projects including: ... Create films. Create video games." Not available for Enterprise/Federated IDs or users with a China country code. [inspected, HTML] - [Adobe Mixamo FAQ](https://helpx.adobe.com/creative-cloud/faq/mixamo-faq.html)
- Adobe community post "Mixamo FAQ - Licensing, Royalties, Ownership, EULA and TOS" (posted by TylerG 3D, 29 Sep 2022; the poster's badge on the page is a community rank, I could not confirm Adobe staff status): Mixamo is "in a limited duration technology preview ... available for free, with no licensing or royalty fees, for unlimited commercial or non commercial use"; "Adobe retains the rights to our software and content, you retain the rights to your designs and creations". YES list includes "Video Games" and "DLC or Addon Content for Games". NO list: "Blueprints, templates, or asset packages for video game engines which redistribute character or animation raw files as the product"; "Packages for 3D stock or asset store websites where character or animation raw files will be sold or distrubuted"; "Any type of free distribution of character or animation raw files". "really the only thing you can't do is distribute the raw character and animation files ... this does not include collaborating on team-based projects ... You may not distribute the files to customers or non-team members". Credit is "not required". Projects made during the free period are not affected by later pricing changes. The post defers to the full Adobe Terms of Use. [inspected, HTML] - [Adobe community 589400](https://community.adobe.com/questions-696/mixamo-faq-licensing-royalties-ownership-eula-and-tos-589400)

### Inferences
- Shipping Mixamo-derived animation inside a packed game build is the allowed case; committing the raw downloaded FBX files to a **public** repository would be "free distribution of ... raw files". A private team repo falls under the team-collaboration allowance. (My reading of the two pages above, not legal advice.)

### Gaps
- The Adobe General Terms of Use / any Mixamo-specific additional terms were not fetched; the binding text was not read.
- No Adobe statement found on redistributing *modified* clips (e.g. root-baked, retargeted `.res`) in open-source game repos.

---

## 5. Mixamo -> Godot 4

### Takeaway
In Godot 4.3+ a Mixamo FBX imports directly (ufbx, converted to metres/Y-up, bones renamed `mixamorig_*`); retargeting is done per file in Advanced Import Settings with a `BoneMap` + `SkeletonProfileHumanoid`, and animation-only files are imported as `AnimationLibrary`. The humanoid profile expects a `Root` bone that Mixamo does not have, so root motion either reads the `Hips` track or needs a root bone added in Blender first.

### Cited Findings

**Import path.**
- "By default any FBX file added to a Godot project in Godot 4.3 or later will use the ufbx import method"; files added in 4.2 or earlier keep FBX2glTF unless switched; FBX2glTF "is generally not recommend unless you have a specific reason to use it"; `.blend` import calls Blender and goes through glTF; glTF export from Blender is the documented "recommended" route for Blender assets. [inspected, docs source for current master/4.7] - [godot-docs available_formats.rst](https://raw.githubusercontent.com/godotengine/godot-docs/master/tutorials/assets_pipeline/importing_3d_scenes/available_formats.rst)
- FBX import options in source (master): `fbx/importer` (ufbx | FBX2glTF, default ufbx), `fbx/allow_geometry_helper_nodes` (false), `fbx/embedded_image_handling`, `fbx/naming_version` ("Godot 4.0 or 4.1, Godot 4.2 to 4.4, Godot 4.5 or later", default the last). [inspected] - [editor_scene_importer_ufbx.cpp](https://raw.githubusercontent.com/godotengine/godot/master/modules/fbx/editor/editor_scene_importer_ufbx.cpp)
- With naming version >= 2 bone names only need to be unique within a skeleton ("Two skeletons with a 'Head' bone should not have one become 'Head_2'"); with older naming a bone that shares a name with a mesh/node gets a `_2` suffix. A 4.3 user hit exactly this (bone "Torso" became "Torso_2" because a mesh had the same name; renaming the mesh fixed it). [inspected] - [skin_tool.cpp](https://raw.githubusercontent.com/godotengine/godot/master/modules/gltf/skin_tool.cpp); [page] - [Godot forum 91292](https://forum.godotengine.org/t/bones-now-import-with-wrong-name-mess-up-animations-4-3-vs-4-2-issue/91292)
- Animation is re-sampled at import: ufbx is given `resample_rate` / `minimum_sample_rate` = the import "FPS" (bake fps) setting. Import dock also has "Trimming" and "Remove Immutable Tracks". [inspected] - [fbx_document.cpp](https://raw.githubusercontent.com/godotengine/godot/master/modules/fbx/fbx_document.cpp), [import_configuration.rst](https://raw.githubusercontent.com/godotengine/godot-docs/master/tutorials/assets_pipeline/importing_3d_scenes/import_configuration.rst)
- Animation libraries: set the import mode "to Animation Library in the Import dock" and the file "will be imported as an AnimationLibrary instead of a PackedScene", to be referenced from an `AnimationPlayer`. (The doc text says glTF; the retargeting blog and add-ons below do the same with FBX.) [inspected] - [import_configuration.rst](https://raw.githubusercontent.com/godotengine/godot-docs/master/tutorials/assets_pipeline/importing_3d_scenes/import_configuration.rst)

**Why retargeting is needed (Godot 4, all 4.x).** Animation tracks address bones by NodePath, and "In Godot 3, Bone Pose is relative to Bone Rest, but in Godot 4, it includes Bone Rest" - so two skeletons with the same bone names but different rests cannot share clips. "To share animations in Godot, it is necessary to match Bone Rests as well as Bone Names". [inspected] - [retargeting_3d_skeletons.rst](https://raw.githubusercontent.com/godotengine/godot-docs/master/tutorials/assets_pipeline/retargeting_3d_skeletons.rst) (HTML version labelled Godot 4.7: [docs](https://docs.godotengine.org/en/stable/tutorials/assets_pipeline/retargeting_3d_skeletons.html))

**SkeletonProfileHumanoid (Godot 4.x; read from master source and class doc).** 56 bones in 4 groups (Body, Face, LeftHand, RightHand); `root_bone = "Root"`, `scale_base_bone = "Hips"`; all parameters read-only. Hierarchy: `Root → Hips → {Spine → Chest → UpperChest → {Neck → Head → {LeftEye, RightEye, Jaw}, LeftShoulder → LeftUpperArm → LeftLowerArm → LeftHand → fingers, Right...}, LeftUpperLeg → LeftLowerLeg → LeftFoot → LeftToes, Right...}`. Fingers: `Left/Right` + `ThumbMetacarpal, ThumbProximal, ThumbDistal`, and `Index|Middle|Ring|Little` + `Proximal, Intermediate, Distal`. Bones flagged `required` in source: Hips, Spine, Head, Left/Right Shoulder, UpperArm, LowerArm, Hand, UpperLeg, LowerLeg, Foot (Neck explicitly `required = false`). [inspected] - [skeleton_profile.cpp](https://raw.githubusercontent.com/godotengine/godot/master/scene/resources/skeleton_profile.cpp), [class_skeletonprofilehumanoid.rst](https://raw.githubusercontent.com/godotengine/godot-docs/master/classes/class_skeletonprofilehumanoid.rst)

**Mixamo -> Godot humanoid name map** (from MixaBridge's table; the three-vrm map gives the same pairs in VRM spelling):

| Mixamo (after prefix) | Godot humanoid | | Mixamo | Godot humanoid |
|---|---|---|---|---|
| Hips | Hips | | LeftUpLeg / RightUpLeg | LeftUpperLeg / RightUpperLeg |
| Spine | Spine | | LeftLeg / RightLeg | LeftLowerLeg / RightLowerLeg |
| Spine1 | Chest | | LeftFoot / RightFoot | LeftFoot / RightFoot |
| Spine2 | UpperChest | | LeftToeBase / RightToeBase | LeftToes / RightToes |
| Neck | Neck | | HandThumb1 / 2 / 3 | ThumbMetacarpal / ThumbProximal / ThumbDistal |
| Head | Head | | HandIndex1 / 2 / 3 | IndexProximal / IndexIntermediate / IndexDistal |
| LeftShoulder / RightShoulder | same | | HandMiddle1 / 2 / 3 | MiddleProximal / Intermediate / Distal |
| LeftArm / RightArm | LeftUpperArm / RightUpperArm | | HandRing1 / 2 / 3 | RingProximal / Intermediate / Distal |
| LeftForeArm / RightForeArm | LeftLowerArm / RightLowerArm | | HandPinky1 / 2 / 3 | LittleProximal / Intermediate / Distal |
| LeftHand / RightHand | same | | HeadTop_End, *Toe_End, *4 finger tips | unmapped (empty string) |

Nothing maps to `Root`, `Jaw` (and eyes only if the character has `LeftEye`/`RightEye`). [inspected] - [mixamo_bone_table.gd](https://raw.githubusercontent.com/uzairdeveloper223/mixabridge/main/addons/mixabridge/mixamo_bone_table.gd), [mixamoVRMRigMap.js](https://raw.githubusercontent.com/pixiv/three-vrm/dev/packages/three-vrm/examples/humanoidAnimation/mixamoVRMRigMap.js)

**Auto-mapping (editor `BoneMapper`, master source).** Runs when the profile is set; uses regex pick-lists against the lower-cased bone name plus hierarchy: hips = `hip|pelvis|waist|torso|spine`; foot = `foot|ankle`; lower leg = `(low|under).*leg|knee|shin|calf|leg`; upper leg = `up.*leg|thigh|leg`; toes = `toe|ball`; hand = `hand|wrist|palm|fingers`; fingers = `thumb|pollex`, `index|fore`, `middle`, `ring`, `little|pinkie|pinky`; shoulder = `shoulder|clavicle|collar`; lower arm = `(low|fore).*arm|elbow|arm`; upper arm = `up.*arm|arm`; neck = `neck|head|face`; head = `head|face`; left/right from `left`/`right` or a standalone `l`/`r` after snake-casing; Chest/UpperChest/Spine are then deduced by walking parents between neck and hips; when several bones match "The one with the shortest name is probably the original". Docs: "The auto-mapping uses pattern matching for the bone names. So we recommend to use common English names". Problems show as magenta/red buttons and do not block import. [inspected] - [bone_map_editor_plugin.cpp](https://raw.githubusercontent.com/godotengine/godot/master/editor/scene/3d/bone_map_editor_plugin.cpp), [retargeting_3d_skeletons.rst](https://raw.githubusercontent.com/godotengine/godot-docs/master/tutorials/assets_pipeline/retargeting_3d_skeletons.rst)

**Retarget import options - exact keys and defaults (master source; presence of `retarget_method` checked per release tag).**

| Key (`retarget/...`) | Default | Meaning |
|---|---|---|
| `bone_map` | none | the BoneMap resource |
| `remove_tracks/except_bone_transform` | false | "Removes any tracks except the bone Transform track" |
| `remove_tracks/unimportant_positions` | true | removes Position tracks other than `root_bone` and `scale_base_bone` - for the humanoid profile "other than 'Root' and 'Hips'". If disabled "the animation may change the body shape unpredictably" |
| `remove_tracks/unmapped_bones` | 0 = None (enum `None, Remove, Separate Library`) | what to do with tracks of unmapped bones |
| `bone_renamer/rename_bones` | true | rename mapped bones to profile names (also rewrites skin bind names, animation tracks, BoneAttachment3D) |
| `bone_renamer/unique_node/make_unique` | true | make the Skeleton3D a scene-unique node |
| `bone_renamer/unique_node/skeleton_name` | `GeneralSkeleton` | so every clip's track path is `%GeneralSkeleton:BoneName` regardless of scene tree |
| `rest_fixer/apply_node_transforms` | true | bake a transform sitting on the Skeleton node into the bones |
| `rest_fixer/normalize_position_tracks` | true | divide Position values by the `scale_base_bone` (Hips) height; that height is stored on the skeleton as `motion_scale` and multiplied back on playback. Off = `motion_scale` 1.0 |
| `rest_fixer/reset_all_bone_poses_after_import` | true | |
| `rest_fixer/retarget_method` | 1 = Overwrite Axis (enum `None, Overwrite Axis, Use Retarget Modifier`) | present in tags 4.4-stable, 4.5-stable, 4.6-stable, 4.7-stable and master; **absent in 4.3-stable** (where the docs' older boolean "Overwrite Axis" applies) |
| `rest_fixer/keep_global_rest_on_leftovers` | true | only with Overwrite Axis |
| `rest_fixer/copy_bone_skin_scale`, `use_global_pose`, `original_skeleton_name` ("OriginalSkeleton") | true, true | only with Use Retarget Modifier |
| `rest_fixer/fix_silhouette/enable` | false | try to pose the model into the profile's reference pose |
| `rest_fixer/fix_silhouette/filter` | [] | profile bone names to leave alone (e.g. feet) |
| `rest_fixer/fix_silhouette/threshold` | 15 | degrees; a bone is only fixed when its direction differs from the profile by more than this |
| `rest_fixer/fix_silhouette/base_height_adjustment` | 0.0 (range -1..1) | adjust Hips height for bent knees / feet |

[inspected] - [post_import_plugin_skeleton_rest_fixer.cpp (master)](https://raw.githubusercontent.com/godotengine/godot/master/editor/import/3d/post_import_plugin_skeleton_rest_fixer.cpp), [4.7-stable](https://raw.githubusercontent.com/godotengine/godot/4.7-stable/editor/import/3d/post_import_plugin_skeleton_rest_fixer.cpp), [4.3-stable](https://raw.githubusercontent.com/godotengine/godot/4.3-stable/editor/import/3d/post_import_plugin_skeleton_rest_fixer.cpp), [post_import_plugin_skeleton_track_organizer.cpp](https://raw.githubusercontent.com/godotengine/godot/master/editor/import/3d/post_import_plugin_skeleton_track_organizer.cpp); renamer defaults [page summary of] [post_import_plugin_skeleton_renamer.cpp](https://raw.githubusercontent.com/godotengine/godot/master/editor/import/3d/post_import_plugin_skeleton_renamer.cpp)

Docs wording on the key options (Godot 4.7 docs):
- Reference pose rules of SkeletonProfileHumanoid: "The humanoid is T-pose"; "facing +Z in the Right-Handed Y-UP Coordinate System"; "should not have a Transform as Node"; "Directs the +Y axis from the parent joint to the child joint"; "+X rotation bends the joint like a muscle contracting".
- Overwrite Axis: "Unifies the models' Bone Rests by overwriting it to match the reference poses defined in the SkeletonProfile ... the most important option for sharing animations in Godot 4", but "can produce horrible results if the original Bone Rest set externally is important".
- Fix Silhouette: "does not need to be enabled for T-pose models, but should be enabled for A-pose models"; cannot fix very different silhouettes and "may not work for fixing bone roll"; foot results can be bad depending on heel height -> add bones to `filter`.
- Remove Tracks: recommended on for shared AnimationLibraries; for scenes with animated accessories they may need to be off.
[inspected] - [retargeting_3d_skeletons.rst](https://raw.githubusercontent.com/godotengine/godot-docs/master/tutorials/assets_pipeline/retargeting_3d_skeletons.rst)

**RetargetModifier3D (the "Use Retarget Modifier" method, Godot 4.4+).** "Retrieves the pose (or global pose) relative to the parent Skeleton's rest in model space and transfers it to the child Skeleton"; it overwrites mapped bone poses on the target skeleton during the parent skeleton's update; import warning text: "The skeleton modifier option uses SkeletonProfile as a list of bone names and retargets by name matching. Without renaming, retargeting by modifier will not work". [inspected] - [class_retargetmodifier3d.rst](https://raw.githubusercontent.com/godotengine/godot-docs/master/classes/class_retargetmodifier3d.rst), rest fixer source above.

**Official workflow (Godot blog, 7 Nov 2022, by Silc "Tokage" Renew, written for 4.0 beta 3):** import the character as a scene and assign BoneMap + SkeletonProfileHumanoid; import the animation file "As AnimationLibrary" with the same BoneMap/profile; add an AnimationPlayer and play from the library. The profile "allows for shared animation of common T and A-pose models with lesser effort". The post does not mention Mixamo, FBX or root motion. [page] - [Animation Retargeting in Godot 4.0](https://godotengine.org/article/animation-retargeting-in-godot-4-0/)

**Root motion in Godot (4.x class reference, master).**
- `AnimationMixer.root_motion_track`: path to the track used for root motion; "note that a bone must be specified"; position/rotation/scale tracks of that bone are "canceled visually, and the animation will appear to stay in place"; deltas come from `get_root_motion_position()`, `get_root_motion_rotation()`, `get_root_motion_scale()`; `get_root_motion_position_accumulator()` exposes the blended absolute value; `root_motion_local` (default false) extracts translation "as a local translation value before blending"; `RootMotionView` visualises it. [inspected] - [class_animationmixer.rst](https://raw.githubusercontent.com/godotengine/godot-docs/master/classes/class_animationmixer.rst)
- Tutorial: animators "use the root skeleton bone to give motion to the rest of the skeleton"; select this bone as the root motion track. [inspected] - [animation_tree.rst](https://raw.githubusercontent.com/godotengine/godot-docs/master/tutorials/animation/animation_tree.rst)
- Godot forum (Dec 2023): "With Mixamo characters, the root animation tracks are applied to the root bone (hips)". [page] - [Godot forum 39619](https://forum.godotengine.org/t/retargeting-mixamo-animations-fails/39619)

**Community tools (Godot side).**
- **MixaBridge** v1.0.2 (31 May 2026, MIT, Godot 4.4+): loads the model FBX, maps `mixamorig:`/`mixamorig_` bones with a static table, writes a BoneMap `.tres` into each file's `.import` `[params]`, calls `EditorFileSystem.reimport_files()`, extracts the Animation resources into an AnimationLibrary. Settings it writes: `rename_bones = true`, `make_unique = true`, `apply_node_transforms = true`, `normalize_position_tracks = true`, `reset_all_bone_poses_after_import = true`, `retarget_method = 1` (Overwrite Axis). Wants animation FBX "exported without skin from Mixamo"; has per-clip loop and "strip translation from the root bone (in-place)" checkboxes. Stated limits: Mixamo rigs only; edits `.import` files directly; reimport blocks the editor. [page] - [Godot Asset Library 5096](https://godotengine.org/asset-library/asset/5096); [inspected] - [README](https://raw.githubusercontent.com/uzairdeveloper223/mixabridge/main/README.md), [import_configurator.gd](https://raw.githubusercontent.com/uzairdeveloper223/mixabridge/main/addons/mixabridge/import_configurator.gd)
- **Mixamo Animation Retargeter** (Matt Marcin @ RaidTheory, GPLv3, "for Godot 4.3"): right-click FBX -> "Retarget Mixamo Animation", batch, saves `.res` animations; requires ufbx import, a character Skeleton3D "named 'Skeleton'" and the character also bone-mapped; ships `mixamo_bone_map.tres`. [inspected] - [README (Wiechciu fork)](https://raw.githubusercontent.com/Wiechciu/Godot-Mixamo-Animation-Retargeter/main/README.md). A forum user warns it "may not work in Godot 4.5+"; their fork targets 4.4/4.5 and was untested on 4.6. [page] - [Godot forum 137067](https://forum.godotengine.org/t/mixamo-animation-retarget/137067)

**Community pitfalls (Godot forum).**
- Godot 4.6.2, Apr 2026: Mixamo-auto-rigged model + separately downloaded run clip, both humanoid-mapped, clip imported as library: "the character's arms behave incorrectly - they clip through the body". No confirmed cause; one experienced user says "I never had that issue IF I tried on an T - Pose model" and describes his working pipeline: FBX from Mixamo -> clean in Blender to "only one armature and model" -> split/remove root motion -> import with Humanoid retarget -> import as library. [page] - [Godot forum 137067](https://forum.godotengine.org/t/mixamo-animation-retarget/137067)
- Godot 4.2, Dec 2023: third-party model + Mixamo clips, all bone-map buttons green, yet "the root transform rotating and translating all over the place" / "appendages flailing wildly"; traced to Mixamo putting motion on the armature node instead of Hips for an uploaded pre-rigged character (see section 2) and to proportion mismatch. [page] - [Godot forum 39619](https://forum.godotengine.org/t/retargeting-mixamo-animations-fails/39619)
- Godot 4.4, May 2025: a Mixamo clip looked broken until "Re-import once" with adjusted options (unspecific). [page] - [Godot forum 111135](https://forum.godotengine.org/t/animations-from-mixamo-wont-work/111135)

### Inferences
- A raw Mixamo skeleton would auto-map in Godot's BoneMapper: every Mixamo name contains one of the pick-list words (`Hips`→hip, `UpLeg`→`up.*leg`, `Leg`→leg, `ToeBase`→toe, `ForeArm`→`(low|fore).*arm`, `Arm`→arm, `HandThumb1`→thumb ...), `Left`/`Right` are present, and `Spine/Spine1/Spine2` fill Spine/Chest/UpperChest by the parent walk. `Root` stays empty. I did not run the editor to confirm; the forum reports of "all green" maps on Mixamo rigs agree.
- With `unimportant_positions = true` and Mixamo's Hips-only translation, the surviving position track after retarget is exactly `%GeneralSkeleton:Hips`. That is the only candidate for `root_motion_track` unless a root bone was added in Blender and mapped to `Root`.
- `normalize_position_tracks` stores Hips height as `motion_scale`, so a clip downloaded for one body scales its Hips travel to another body's leg length. That reduces, but cannot remove, foot sliding from proportion mismatch.
- Mixamo's T-pose/+Z rest matches the profile's reference pose, so the expected settings for Mixamo are: Overwrite Axis on, Fix Silhouette off. The X Bot sample's bone-aligned PreRotations and the 2018 sample's world-aligned joints both get normalised by Overwrite Axis, which is why it is needed even between Mixamo files.
- Three workable pipelines, in order of how much they rely on Godot only:
  1. FBX straight into Godot 4.3+ (ufbx) → BoneMap/humanoid on the character and on each skinless clip → clips as AnimationLibrary → root motion from the `Hips` track (must discard Y and filter sway in gameplay code, or use in-place clips and code-driven movement).
  2. Blender pre-pass: batch import, add root bone (Import Mixamo - Root Motion / mixamo_converter / own script), strip prefix, export glTF → same Godot retarget with `Root` mapped → root motion from `Root`.
  3. MixaBridge or the Retargeter fork to automate (1).
- For traversal (vault/climb), precise displacement matters more than for locomotion, so pipeline 2 (a real root bone with only XZ + yaw, hips keeping Y) is the safer choice; pipeline 1 leaves vertical travel of a climb in the Hips track where "in place" visual cancelling would also remove the body's rise.

### Gaps
- Not run in an actual Godot build this session: none of the import behaviour was tested hands-on; all Godot facts are from docs/source text.
- How Godot's root-motion extraction behaves when the root motion bone is `Hips` and its position track is normalised by `motion_scale` (are deltas returned in metres?) - not found in the fetched class reference text.
- No official Godot statement on "root motion from Hips" for rigs without a root bone, and no Godot import option that synthesises a root bone, was found.
- The stable HTML docs still describe "Overwrite Axis" as its own option while 4.4+ source has the `retarget_method` enum; I did not find a changelog entry dating the change (established only by diffing release tags 4.3 vs 4.4).
- `retarget/remove_tracks/unmapped_bones` being a 3-value enum was read on master only; not checked per release tag.
- A "without skin" Mixamo FBX imported as an AnimationLibrary: whether Godot gets a usable rest pose from a mesh-less file was not verified (mixamo_converter's `Fix Bind` note suggests bind pose can be unreliable without a mesh).
- No dedicated, current, step-by-step official tutorial for Mixamo specifically was found; guidance is forum-level.

---

## 6. General mocap / humanoid standards for context

### Takeaway
Godot's humanoid profile uses the same bone vocabulary as the VRM humanoid specification (hips, spine, chest, upperChest, neck, head, upper/lower arm, hand, upper/lower leg, foot, toes, thumb metacarpal/proximal/distal ...), and retargeting between rigs works by mapping names to that vocabulary and then reconciling rest poses.

### Cited Findings
- VRM 1.0 humanoid spec: required bones include hips, spine, head, left/right upperLeg, lowerLeg, foot, upperArm, lowerArm, hand; optional chest, upperChest ("can exist only when chest exists"), neck, shoulders, toes, eyes, jaw; note on hips: "Usually only this bone moves. Other bones rotate only". [inspected] - [VRMC_vrm-1.0 humanoid.md](https://raw.githubusercontent.com/vrm-c/vrm-specification/master/specification/VRMC_vrm-1.0/humanoid.md)
- The three-vrm project maps Mixamo names straight onto VRM humanoid names (Spine1→chest, Spine2→upperChest, Arm→upperArm, ForeArm→lowerArm, UpLeg→upperLeg, Leg→lowerLeg, ToeBase→toes, HandThumb1→thumbMetacarpal). [inspected] - [mixamoVRMRigMap.js](https://raw.githubusercontent.com/pixiv/three-vrm/dev/packages/three-vrm/examples/humanoidAnimation/mixamoVRMRigMap.js)
- Godot's SkeletonProfileHumanoid bone names are the same words in PascalCase (Hips, Spine, Chest, UpperChest, Neck, Head, LeftUpperArm, LeftLowerArm, LeftThumbMetacarpal, LeftLittleProximal, LeftToes ...) plus a `Root`. [inspected] - [skeleton_profile.cpp](https://raw.githubusercontent.com/godotengine/godot/master/scene/resources/skeleton_profile.cpp)
- Unity (manual for Unity 6.6 / 6000.6): "The Avatar system is how Unity identifies that a particular animated model is a humanoid, and which parts of the model correspond to the legs, arms, head, and body"; "Because of the similarity in bone structure between different humanoid characters, it is possible to map animations from one humanoid character to another". [page] - [Unity manual: Humanoid Avatar](https://docs.unity.com/en-us/engine/current/manual/animation-section/animation-mecanim/avatar-creationand-setup)
- How Godot reconciles differing rests: either rewrite the rest at import to the profile's reference pose (Overwrite Axis; bone +Y toward child, +X bends like a muscle, T-pose, facing +Z), optionally first posing the model into that silhouette (Fix Silhouette), or keep the original rest and transfer poses "relative to the parent Skeleton's rest in model space" at runtime (RetargetModifier3D). [inspected] - [retargeting_3d_skeletons.rst](https://raw.githubusercontent.com/godotengine/godot-docs/master/tutorials/assets_pipeline/retargeting_3d_skeletons.rst), [class_retargetmodifier3d.rst](https://raw.githubusercontent.com/godotengine/godot-docs/master/classes/class_retargetmodifier3d.rst)
- Unreal-side practice for Mixamo, for comparison: rename to mannequin names (`Hips`→`Pelvis`, added `Root`), retarget with both skeletons in the same retarget pose (Mixamo T-pose vs UE A-pose), and do not use automapping on Mixamo skeletons. [inspected] - [mixamo_converter README](https://raw.githubusercontent.com/enziop/mixamo_converter/master/README.md)

### Inferences
- Mixamo fits the VRM/Godot humanoid vocabulary one-to-one for every animated joint; the only structural mismatches are the missing `Root` and the 13 unanimated end joints.
- Proportion differences are not solved by name/rest retargeting: Hips translation is scaled by one number (hip height), limb rotations are copied. Hands-on-ledge and feet-on-ground contacts in traversal clips will therefore miss on a body with different limb ratios unless IK corrects them.

### Gaps
- BVH conventions (hierarchy + channel order text format) were not researched; no source fetched.
- Unity's minimum-bone requirement and T-pose enforcement text were not on the page fetched; not cited.
- No fetched source states in words that "Godot's SkeletonProfileHumanoid follows Unity/VRM"; the correspondence is shown by comparing the two bone lists, not by a statement from Godot.
