#!/bin/bash
# Turns a finished build into the Docker image. Usage: make-image.sh <source tree> [tag]
# Needs Docker only: the images are loop-mounted inside a throwaway privileged container.
# Android 17's /system/bin/init is second stage only; the first stage (normally in the boot
# ramdisk) becomes the image's /init, replacing the /init -> /system/bin/init symlink.
set -e
SRC=$(cd "$1" && pwd); TAG=${2:-etesian-redroid:24.0}
OUT=$SRC/out/target/product/redroid_x86_64_only
FS=$SRC/out/soong/.intermediates/system/core/init/init_first_stage/android_ramdisk_x86_64/init
[ -f "$FS" ] || FS=$(dirname "$FS")/unstripped/init
docker run --rm --privileged -v "$OUT":/img:ro -v "$FS":/first_stage_init:ro ubuntu:24.04 bash -c '
  mkdir -p /x/system /x/vendor /x/root && mount -o ro,loop /img/system.img /x/system && mount -o ro,loop /img/vendor.img /x/vendor
  cp /first_stage_init /x/root/init && chmod 750 /x/root/init
  cd /x && tar --xattrs -c vendor -C /x/root init -C /x/system --exclude=./vendor --exclude=./init .' |
  docker import -c 'ENTRYPOINT ["/init", "qemu=1", "androidboot.hardware=redroid"]' - "$TAG"
echo "built $TAG"
