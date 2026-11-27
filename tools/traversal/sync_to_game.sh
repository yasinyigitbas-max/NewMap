#!/bin/bash
# Copies what the traversal system loads at run time from the lab project (traversal_lab/traversal: his model, the
# clips and their library, the props, the NPC bodies) to res://traversal/ of the GAME project, under the same paths,
# so that the same C++ (compiled into the game's module) finds them. The lab is a project inside the project: Godot
# does not read into it. The copy is not in git (57 MB that is already there once): run this after any change to
# those files, before a bake or an export, then let Godot import (the first start, or --import).
#   bash tools/traversal/sync_to_game.sh
set -eu
cd "$(dirname "$0")/../.."
SRC=traversal_lab/traversal
DST=traversal
mkdir -p "$DST"
n=0
for d in character character/clips props npc; do
  mkdir -p "$DST/$d"
  for f in "$SRC/$d"/*.res "$SRC/$d"/*.scn "$SRC/$d"/*.jpg "$SRC/$d"/*.png "$SRC/$d"/*.material "$SRC/$d"/*.json "$SRC/$d"/*.jpg.import "$SRC/$d"/*.png.import; do
    [ -f "$f" ] || continue
    t="$DST/$d/$(basename "$f")"
    if [ ! -f "$t" ] || ! cmp -s "$f" "$t"; then cp "$f" "$t"; n=$((n + 1)); fi
  done
done
# (the baked clips are data resources of this small script: it holds their numbers and nothing runs in it each tick)
for f in "$SRC/character/clip_data.gd" "$SRC/character/clip_data.gd.uid"; do
  t="$DST/character/$(basename "$f")"
  if [ -f "$f" ] && { [ ! -f "$t" ] || ! cmp -s "$f" "$t"; }; then cp "$f" "$t"; n=$((n + 1)); fi
done
echo "SYNC_TO_GAME: $n files copied to res://traversal/ ($(du -sh "$DST" | cut -f1))"
