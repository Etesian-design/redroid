#!/bin/bash
# Boots a finished build ONLY inside the throwaway VM (never on this host): copies the images and vm-boot.sh in and runs it.
# Usage: vm-test.sh [source tree]. Fails unless Android finishes booting with adbd up.
# ssh runs in a container on the host's network, so this works from the CI runner's container as from a shell.
set -euo pipefail
SRC=$(cd "${1:-$HOME/etesian-redroid/src}" && pwd); VM_DIR=${VM_DIR:-$HOME/vm}; HERE=$(cd "$(dirname "$0")" && pwd)
O=$SRC/out/target/product/redroid_x86_64_only
FS=$SRC/out/soong/.intermediates/system/core/init/init_first_stage/android_ramdisk_x86_64/init
[ -f "$FS" ] || FS=$(dirname "$FS")/unstripped/init
docker run --rm --network host -v "$VM_DIR/key:/key:ro" -v "$O/system.img:/img/system.img:ro" -v "$O/vendor.img:/img/vendor.img:ro" \
    -v "$FS:/img/first_stage_init:ro" -v "$HERE/vm-boot.sh:/img/vm-boot.sh:ro" etesian-vmhost bash -eo pipefail -c '
O="-q -i /key -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -o ConnectTimeout=5"
for i in $(seq 60); do ssh $O -p 2232 t@127.0.0.1 true 2>/dev/null && break; sleep 5; done
ssh $O -p 2232 t@127.0.0.1 mkdir -p img
scp $O -P 2232 /img/system.img /img/vendor.img /img/first_stage_init /img/vm-boot.sh t@127.0.0.1:img/
ssh $O -p 2232 t@127.0.0.1 bash img/vm-boot.sh'
