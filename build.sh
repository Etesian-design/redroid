#!/bin/bash
# Sets up and builds the container image on a Docker host. Usage: ./build.sh <work dir> <vendor/etesian checkout>
# The tree, ccache and logs live in <work dir>; the build runs in the builder image (builder/), capped so the host stays usable.
set -e
W="$(mkdir -p "$1" && cd "$1" && pwd)"; ETESIAN="$(cd "${2:?usage: build.sh <work dir> <vendor/etesian>}" && pwd)"; HERE="$(cd "$(dirname "$0")" && pwd)"
docker build -q -t etesian-builder "$HERE/builder" >/dev/null
run() { docker run --rm --cpus "${CPUS:-12}" --memory "${MEM:-44g}" -e USE_CCACHE=1 -e CCACHE_DIR=/ccache -v "$W/ccache:/ccache" -v "$W/src:/src" -v "$HERE:/etesian-redroid:ro" etesian-builder bash -c "$1"; }
mkdir -p "$W/src/.repo/local_manifests" "$W/ccache"
if [ ! -d "$W/src/frameworks" ]; then
    cp "$HERE/manifest/etesian-redroid.xml" "$W/src/.repo/local_manifests/"
    run "repo init -q -u https://github.com/LineageOS/android.git -b lineage-24.0 --git-lfs --depth=1 && repo sync -c -j8 --no-tags --no-clone-bundle --optimized-fetch"
    rsync -a --exclude .git --exclude n9-files "$ETESIAN/" "$W/src/vendor/etesian/"     # never the Nokia reference files
    mkdir -p "$W/src/device/etesian" && cp -r "$HERE/device" "$W/src/device/etesian/redroid"
    run "/etesian-redroid/patches/apply.sh /src && bash /src/vendor/etesian/patches/apply.sh"
fi
run "cd /src && source build/envsetup.sh >/dev/null && lunch lineage_etesian_x86_64-cp2a-userdebug >/dev/null && m -j\$(nproc)" 2>&1 | tail -40
