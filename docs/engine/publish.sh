#!/bin/bash
# Push one engine build (the .aar pair + checksums) to the private game repository as a single parentless commit
# on the branch engine-bin/<name> (a ref outside refs/heads is refused with 403 from a cloud session).
# usage: bash engine/publish.sh <name>        (after engine/build.sh <name>; reads $ENGINE_WORK/out/<name>, default /e)
# PC side: see engine/README.md "Using a build on the PC".
set -euo pipefail
NAME=${1:?usage: publish.sh <name>}
O=${ENGINE_WORK:-/e}/out/$NAME
[ -f "$O/SHA256SUMS" ] || { echo "no build at $O"; exit 1; }
cd "$(git rev-parse --show-toplevel)"
export GIT_INDEX_FILE=$(mktemp -u)
for f in libs/debug/godot-lib.template_debug.aar libs/release/godot-lib.template_release.aar SHA256SUMS build_info.txt; do
  h=$(git hash-object -w "$O/$f")
  git update-index --add --cacheinfo 100644,"$h","$f"
done
tree=$(git write-tree)
rm -f "$GIT_INDEX_FILE"; unset GIT_INDEX_FILE
commit=$(git commit-tree "$tree" -m "engine build coronado_$NAME (Godot 4.7.2-stable, Android arm64, debug + release .aar)")
REF=${ENGINE_REF_PREFIX:-refs/heads/engine-bin}/$NAME
git push origin "$commit:$REF"
echo "pushed $commit to $REF"
