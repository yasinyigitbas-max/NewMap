#!/bin/bash
# A build to DOWNLOAD, no cable (Yasin, 28 Nov: "i need a release build, i can only download the new builds. i dont
# have cables now"). On his PC, in Git Bash, from anywhere inside the NewMap clone, Godot closed:
#   bash tools/city/rig/publish_build.sh
# It copies the traversal files into the game (sync_to_game.sh), bakes the city (phone_rig.sh bake), exports the APK
# (phone_rig.sh export: builds the C++ first), and publishes it as a GitHub release of this repository, as the builds
# of 20 and 21 Nov were (tag build-<day><month>-<hhmm>). The phone downloads the .apk from the release's page.
# Needs the GitHub CLI (gh) logged in; without it the APK's path is printed: upload it by hand at
# https://github.com/yasinyigitbas-max/NewMap/releases/new
set -u
cd "$(dirname "$0")/../../.." || exit 1
bash tools/traversal/sync_to_game.sh || { echo "PUBLISH STOP: the traversal files could not be copied"; exit 2; }
# (the bake again: the damage system reads each prop's surface name and the ground surface map from it, docs/damage/STATUS.md;
#  NOBAKE=1 skips it when the city was baked after the last pull)
if [ -z "${NOBAKE:-}" ]; then bash tools/city/rig/phone_rig.sh bake || { echo "PUBLISH STOP: the bake failed (lines above; OUT/bake.log)"; exit 2; }; fi
bash tools/city/rig/phone_rig.sh export || { echo "PUBLISH STOP: the export failed (lines above)"; exit 2; }
APK=$(ls -t OUT/*/citykit_rig.apk OUT/citykit_rig.apk 2>/dev/null | head -1)
[ -f "$APK" ] || APK=$(find . -name citykit_rig.apk -newer tools/city/rig/publish_build.sh 2>/dev/null | head -1)
[ -f "$APK" ] || { echo "PUBLISH STOP: no citykit_rig.apk found after the export"; exit 2; }
TAG=build-$(date +%d%b-%H%M | tr 'A-Z' 'a-z')
BR=$(git rev-parse --abbrev-ref HEAD); AT=$(git rev-parse --short HEAD)
echo "PUBLISH: $APK ($(($(stat -c %s "$APK") / 1048576)) MB) as $TAG"
if command -v gh >/dev/null; then
  gh release create "$TAG" "$APK" --title "Build $(date '+%d %b %H:%M') (debug, $BR $AT)" --notes "New character, new people near the player, new cars. From $BR at $AT." --prerelease \
    && echo "PUBLISH OK: https://github.com/yasinyigitbas-max/NewMap/releases/tag/$TAG" || echo "PUBLISH: gh failed; upload by hand: $APK"
else
  echo "PUBLISH: the GitHub CLI (gh) is not here. Upload this file by hand at https://github.com/yasinyigitbas-max/NewMap/releases/new :"
  echo "  $(pwd)/$APK"
fi
