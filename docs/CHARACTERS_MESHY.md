# Characters by Meshy (plan, 25 Nov - read before making or importing any character)

Yasin dropped MakeHuman (too many problems shown in the preview: arms into the body, crooked fingers, sunk feet - mostly
the preview's pose copy onto a differently shaped body, `tools/people/pose_follow.gd`) and Character Creator (too
complicated). He chose **Meshy** (AI text/image to 3D, remesh, auto-rig) and has an API key.

## The key
- Stored as a **network secret** on the environment "NewMap": host `api.meshy.ai`, header `Authorization`,
  `Bearer <key>` (Yasin adds it in the environment's settings: Network secrets). The proxy injects it; never ask for
  it in chat, never put it in a file or a commit. `api.meshy.ai` is allowed by saving the secret.
- Check it works with one cheap call (e.g. list tasks) before any batch.

## Budget (from docs/BUDGET.md and docs/PERF_BUDGET.md - the phone, Redmi)
- A view: <= 150 draws, <= 300k triangles (the city alone is already 400k-1M in its measured views: people must be lean).
- People's share: 15 draws, 8-10 animated bodies near the player, the rest batched; ~2 ms GPU; part of ~300 MB memory.
- Old people (Rocketbox): 2,500 / 1,500 / 500 triangles, 512 x 512 texture layers.

| Character | Triangles near / mid / far | Draws | Textures |
|---|---|---|---|
| The player (one, always seen) | 10-15k / 5k | 1-2 (more with swappable clothes: 3-5) | 1024 (2048 face only) |
| Near NPCs (8-10 at once) | 3-5k / 1.5k / 500 | 1 each | 512-1024, shared |
| Crowd far | 500 | batched | shared |

## The pipeline (to build: a script, `tools/people/meshy/`)
1. A cast list with Yasin (role, sex, age, build, skin, clothes, one fixed style text for all - a coherent cast).
2. Per character through the API: generate (text or image to 3D, A / T pose) -> remesh to the target triangles ->
   auto-rig humanoid -> download FBX / GLB with the **Mixamo skeleton** (Meshy's default; our clip library and
   retargeter already know Mixamo names: `mx` clips, `anim_retarget.cpp`).
3. Automatic checks: triangle count, one material, finger bones present and separate fingers, skeleton complete, our
   animations played with no clipping (a proper fit to its own skeleton, NOT the pose copy of pose_follow.gd).
   Failures regenerated or dropped; plan ~1.5x the credits.
4. A page with every character side by side for Yasin to approve; only approved ones go in.
5. Cost (Meshy API pricing page, check live): image-to-3D 20 + texture 10 + rig 5 (+ remesh 0-5) credits each.
- Start: the main character + 5 different NPCs, shown in a film, before any bigger batch.

## Clothing (proposal, Yasin to answer the questions below)
- Meshy makes ONE fused mesh (body + clothes + hair), one texture.
- Crowd / NPCs: COLOUR variation - a region mask per model (top, bottom, shoes, skin, hair) and one shader recolouring
  from colour tables (the old game's Rocketbox way: 24 tops x 16 bottoms) - one mesh, one material, one draw. Shapes
  vary by generating more people.
- The player: real swappable clothes - a base body (generated in tight simple clothes) + separate garments fitted in
  Blender (bpy is installed: /home/user/mpfb/bpylib, may need reinstalling in a new container), weights from the body,
  skin hidden under each garment; in Godot each garment a mesh on the same Skeleton3D. Garment source to test: (a)
  Meshy-generated garments fitted automatically, (b) the same character generated in several outfits with the clothes
  cut out, (c) ready-made modular clothes (MakeHuman CC0 packs, or a bought pack).
- Questions for Yasin: shops / a wardrobe for the player, how many items? hats, glasses, bags? do NPCs change clothes?

## Still open from the animation work (see .claude/skills/coronado-animation/SKILL.md)
- Step off 0.6 m: Ledge_Drop's hand cannot reach the corner of a low ledge (the take is over a railing). Yasin to
  choose: a hop down with no hand below ~0.8 m, or a crouch and the hand on the edge.
- Motor tests (tests/people/test_motor_*.gd): all PASS but test_motor_air (that 0.6 m hand).
