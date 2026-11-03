#!/bin/bash
# Applies the container patches to a LineageOS tree (as commits, with git am). Usage: patches/apply.sh <tree>
# Each folder is a project path with / written as _ (system_fs_fs_mgr -> system/fs/fs_mgr).
set -e
HERE="$(cd "$(dirname "$0")" && pwd)"; TOP="$(cd "${1:?usage: apply.sh <LineageOS tree>}" && pwd)"
declare -A path=([system_fs_fs_mgr]=system/fs/fs_mgr [packages_modules_Connectivity]=packages/modules/Connectivity
                 [device_redroid-prebuilts]=device/redroid-prebuilts)
for dir in "$HERE"/*/; do
    proj=$(basename "$dir"); p="${path[$proj]:-${proj//_//}}"
    if git -C "$TOP/$p" am -q "$dir"*.patch; then echo "applied $proj -> $p"; else git -C "$TOP/$p" am --abort; echo "FAILED $proj -> $p"; exit 1; fi
done
