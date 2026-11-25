# Rig player_v4 on Mixamo and download his clips (run on the PC)

Decided 25 Nov 2026: Mixamo rigs the new character and fits every clip to him, so clips drop in with nothing to correct. This needs the Mixamo login, so it has to be done on the PC. This file replaces `Mixamo download list.md` for the player.

What I could and could not check: Mixamo's site needs a login, so the steps below follow Adobe's help page and user reports, not the live screens. Button names may differ slightly.

## What you need

`player_v4_for_mixamo.zip` (sent with this file). It holds the unrigged v4 body as an OBJ with its texture: 15,587 triangles, T-pose, 181 units tall, feet on the ground at the origin, facing forward. Upload the zip as it is; do not unpack it.

## Step 1. Upload and rig

1. Go to mixamo.com, sign in, and choose **Upload Character**. Pick `player_v4_for_mixamo.zip`.
2. Check the preview: he should stand upright facing you. If he lies down or faces away, use the rotate arrows until he does.
3. Place the markers. Mixamo asks for the chin, both wrists, both elbows, both knees and the groin. Keep **Use Symmetry** on. Where you put them decides where his joints go, so take care with three:
   - **Groin:** at the top of the gap between the legs, not lower down on the trousers.
   - **Wrists:** where the hand meets the forearm, not inside the forearm.
   - **Knees:** on the middle of each knee.
4. For **Skeleton LOD** choose **Standard Skeleton (65)**, the one with full fingers.
5. Finish. Watch the test animation: fingers should bend separately, feet should stay flat, and nothing should stretch. If the hands or feet look wrong, go back and move the markers.

## Step 2. Download the character

Download him once with these settings: **FBX Binary, T-pose, With Skin**. Name the file `player_v4_mixamo.fbx`.

## Step 3. Download the clips for him

With him as the active character, download each clip below with: **FBX Binary, Without Skin, 30 frames per second, keyframe reduction none, "In Place" off**. Download clips one at a time; packs ignore these settings.

Each line is the file name in the Drive folder; download the same Mixamo clip again and keep the same file name. Put them in a new folder called `player_v4`, so they do not mix with the X Bot versions.

**First batch: needed for Stages 2 to 7 (35 clips)**

- Standing: `Standing Idle`, `Idle`
- Walk and run: `Walking (4)`, `Walking`, `Slow Run`, `Running (3)`, `Running`, `Sprint`, `Walking Backwards`
- Curves: `Walking Left Turn`, `Running Left Turn (2)`, `Running Right Turn`
- Strafe (from the Male Locomotion Pack, downloaded singly): `left strafe walking`, `right strafe walking`, `left strafe`, `right strafe`
- Starts and stops: `Female Start Walking`, `Female Stop Walking`, `Start Walking`, `Stop Walking`, `Idle To Sprint`, `Run To Stop`
- Turns: `Left Turn 90`, `Right Turn 90`, `Walking Turn 180`, `Running Turn 180`
- Crouch: `Crouching Idle`, `Crouched Walking`, `Standing To Crouched`, `Crouched To Standing`, `Sneaking Forward`
- Stairs: `Ascending Stairs`, `Descending Stairs`, `Running Up Stairs`, `Run Down Stairs`

**Second batch: the traversal moves, Stage 8 onward (33 clips)**

- Air and landing: `Falling Idle`, `Falling To Landing`, `Hard Landing`, `falling to roll` (Action Adventure Pack), `Jumping Down (2)`, `Jump`, `Running Jump`
- Up onto things: `Step Onto Platform`, `Jumping (2)`, `Running Jump Climb`, `Sprint To Wall Climb`
- Vaults: `Vault 1 Hand`, `Vault 2 Hands`
- Braced hang: `Jump To Braced Hang`, `Braced Hang To Crouch`, `Braced Hang Shimmy Left`, `Braced Hang Shimmy Right`, `Braced Hang Drop`, `Braced To Freehang`, `Freehang To Braced`
- Free hang: `Stand To Freehang`, `Hanging Idle`, `Freehang Shimmy Left`, `Freehang Shimmy Right`, `Freehang Climb`, `Climbing single`, `Drop To Freehang`, `Freehang Drop`
- Down: `Climbing Down`, `Climbing Down (2)`
- Getting up: `Getting Up`, `Standing Up`, `Push Up To Idle`

**Third batch: cover, doors and cars, the last stages (17 clips)**

- Cover: `Cover Idle`, `Crouch cover idle`, `stand to cover`, `stand to cover (2)`, `cover to stand`, `cover to stand (2)`, `Left Cover Sneak (1)`, `Right Cover Sneak`, `Crouch Cover To Cover`, `Standing Cover Turn`, `Crouch Cover Turn`, `Crouch Look Around Corner`
- Doors: `Open Door Outwards`, `Opening Door Inwards`
- Cars: `Entering Car`, `Exiting Car`
- Ladder, if wanted: `Start Climbing Ladder`

The first batch is enough to start building. The others can follow later.

## Step 4. Send them back

Upload `player_v4_mixamo.fbx` and the `player_v4` folder to the shared Google Drive folder "mixamo". Keep raw Mixamo files out of git.

Once they are there, the cloud session will:
- measure his new skeleton (leg, arm, ankle, hip) and the clips on it, and add them to the report;
- remake the seven Kimodo clips (crouch walk, mantles, beam walk, sidle, squeeze) on his skeleton, since the current ones are on X Bot.

## If something goes wrong

- **Mixamo refuses the zip:** unpack it and upload `player_v4.obj` alone; the texture is only for looks and can be put back in Godot.
- **The auto-rigger fails or the result is badly bent:** tell the cloud session what you saw. The fallback is route 2 in the report: keep Meshy's rig of v4 and correct in the game.
