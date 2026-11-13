#!/bin/bash
# SPDX-License-Identifier: Apache-2.0
# Builds a release of the container image on the DeskMini and boot-tests it in the throwaway VM. The release workflow runs it
# with the next version; the keys' passphrase comes on stdin, never as an argument or a variable Docker can show.
#   printf %s "$ETESIAN_KEYS_PASS" | ci/release.sh <version> <vendor/etesian checkout>
# Leaves the image as etesian-redroid:<version>; the workflow pushes it.
#
# ${CI_DIR}/redroid/src is the LineageOS tree (repo) kept between runs, ${CI_DIR}/redroid/ccache its compiler cache.
# The release keys (${CI_DIR}/keys/etesian-keys.tar.gpg) are unpacked into memory under vendor/lineage-priv for the build,
# where LineageOS looks for its own (keys.mk), and go with the container.
set -euo pipefail
VERSION="${1:?usage: release.sh <version> <vendor/etesian>, the passphrase on stdin}"
ETESIAN="$(cd "${2:?usage: release.sh <version> <vendor/etesian>}" && pwd)"
CI="${CI_DIR:?CI_DIR: ~/ci of the host, as the runner sees it}"
HERE="$(cd "$(dirname "$0")/.." && pwd)"
W="$CI/redroid"; KEYS="${KEYS:-$CI/keys/etesian-keys.tar.gpg}"; TAG="etesian-redroid:$VERSION"
# BUILD_ONLY=1: sync, patch and build with the test keys (no keys or passphrase needed); a check before a release.
if [ -z "${BUILD_ONLY:-}" ]; then
    [ -f "$KEYS" ] || { echo "no release keys at $KEYS" >&2; exit 1; }
    IFS= read -r PASS || true
    [ -n "$PASS" ] || { echo "no passphrase on stdin" >&2; exit 1; }
fi
mkdir -p "$W/ccache"
docker build -q -t etesian-builder "$HERE/builder" >/dev/null

# The build needs most of the machine's memory: the test VM is stopped for it and started again after, whatever the outcome.
vm_was_up=
if [ "$(docker inspect -f '{{.State.Running}}' etesian-vm 2>/dev/null)" = true ]; then
    docker stop -t 120 etesian-vm >/dev/null && vm_was_up=1 && trap 'docker start etesian-vm >/dev/null' EXIT
fi

printf '%s\n' "${PASS:-}" | docker run --rm -i \
    --tmpfs /src/vendor/lineage-priv:size=64m,mode=700,uid=1000,gid=1000 \
    -e USE_CCACHE=1 -e CCACHE_EXEC=/usr/bin/ccache -e CCACHE_DIR=/ccache -e BUILD_ONLY="${BUILD_ONLY:-}" \
    -v "$W/ccache:/ccache" -v "$W/src:/src" -v "$HERE:/etesian-redroid:ro" -v "$ETESIAN:/etesian:ro" -v "$KEYS:/keys.tar.gpg:ro" \
    etesian-builder bash -eo pipefail -c '
IFS= read -r PASS || true
if [ -z "$BUILD_ONLY" ]; then
    P=/src/vendor/lineage-priv; mkdir $P/new $P/keys
    printf %s "$PASS" | gpg --batch --quiet --pinentry-mode loopback --passphrase-fd 0 -d /keys.tar.gpg | tar -x -C $P/new
    # The folder is named after the keys: other keys, another path, so every app is signed again. At one fixed path an
    # incremental build re-signs only what it rebuilds, and apps sharing a user id end up with different keys.
    K=keys-$(sha256sum $P/new/releasekey.x509.pem | cut -c1-12); mv $P/new $P/$K
    # userdebug: the SELinux app keys (keys.conf) name the release key testkey
    for f in x509.pem pk8; do cp $P/$K/releasekey.$f $P/$K/testkey.$f; done
    echo "PRODUCT_DEFAULT_DEV_CERTIFICATE := vendor/lineage-priv/$K/releasekey" > $P/keys/keys.mk
fi
unset PASS
cd /src
ccache -M 60G >/dev/null
# Upstream, then ours. The container patches are commits (git am), the Etesian patches uncommitted changes: both are undone
# first, and repo sync -d puts every project back on its manifest revision.
cp /etesian-redroid/manifest/etesian-redroid.xml .repo/local_manifests/
repo forall -c "git am --abort 2>/dev/null; git reset -q --hard && git clean -fdq"
repo sync -d -c -j8 --no-tags --no-clone-bundle --optimized-fetch --force-sync
# Never the N9 reference files or old snapshots. Etesian Mail is built outside the ROM: the copy already in the tree stays.
rsync -a --delete --exclude .git --exclude node_modules --exclude /n9-files --exclude /backups --exclude /notes --exclude /local --exclude /release \
    --filter "P /mail/EtesianMail.apk" --filter "P /mail/Android.bp" /etesian/ vendor/etesian/
mkdir -p device/etesian && rsync -a --delete /etesian-redroid/device/ device/etesian/redroid/
/etesian-redroid/patches/apply.sh /src
bash vendor/etesian/patches/apply.sh
source build/envsetup.sh >/dev/null
lunch lineage_etesian_x86_64-cp2a-userdebug >/dev/null
m -j$(nproc)
'

"$HERE/make-image.sh" "$W/src" "$TAG"

# Boot test: only inside the VM, never on this host (README, Testing).
[ -n "$vm_was_up" ] || { echo "etesian-vm was not running: no boot test" >&2; exit 1; }
docker start etesian-vm >/dev/null; trap - EXIT
VM_DIR="$(dirname "$CI")/vm" "$HERE/vm-test.sh" "$W/src"
echo "built and boot-tested $TAG"
