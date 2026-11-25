# Mixamo clips to download (run this on the PC)

Paste this into a Claude Code session on the PC, the same way the "Animator" session ran on 20–21 Nov 2026. A cloud session cannot do it: the Mixamo login is only on the PC.

---

Download the Mixamo clips listed below, using the Mixamo login on this PC, the same way the earlier "Animator" session downloaded the 310 clips indexed in `characters/mixamo/_index.json`.

**Settings (must match the existing clips):** same character as the existing downloads, FBX Binary, Without Skin, 30 frames per second, no keyframe reduction, "In Place" off.

**Clips.** Many Mixamo clips share a name, so pick the one whose description matches. Names come from a third-party copy of the catalogue and may differ slightly on the live site.

| Mixamo name | Description to match |
|---|---|
| Walking | Male Standard Walk |
| Jumping | Male Jumping Over An Obstacle With 1 Hand Planted |
| Jumping | Male Jumping Over An Obstacle With 2 Hands Planted |
| Jumping | Step Up To Jump Over Object |
| Jumping | Male Stepping Onto Platform |
| Idle To Braced Hang | Jump To A Braced Hang From Standing Idle |
| Drop To Freehang | Standing Drop To Freehang |
| Freehang Drop | Freehang Drop To Standing |
| Braced Hang Drop | Braced Hang Drop To Standing |
| Braced Hang Shimmy | Left Braced Hang Shimmy |
| Braced Hang Shimmy | Right Braced Hang Shimmy |
| Left Shimmy | Free Hanging Shimmy Left |
| Right Shimmy | Free Hanging Shimmy Right |
| Braced To Free Hang | Braced Idle To Free Hang Idle |
| Free Hang To Braced | Free Hang Idle To Braced Idle |
| Descending Stairs | Running Down A Set Of Stairs |
| Freehang Climb | Freehang Climb To Standing |

While logged in, also search Mixamo for these four, which the catalogue copy did not show, and download any real match: a mantle onto a chest-high ledge (about 1.1 to 1.45 m), a low crouch walk (head near 1.0 m), walking along a narrow beam or sidling along a wall ledge, and sliding over a car bonnet.

**Where to put them:** save each file with a name that says what it is (for example `Vault 1 Hand.fbx`, `Braced Hang Shimmy Left.fbx`) into `characters/mixamo/` (FBX files there are git-ignored; do not commit raw Mixamo files) and upload copies to the shared Google Drive folder "mixamo". Update `characters/mixamo/_index.json` in the same format as the existing entries.

**Done when:** each clip above is downloaded or reported as not found on the live site, with the exact Mixamo name used, and it is reported which of the four extra searches found something. Do not change any game code.
