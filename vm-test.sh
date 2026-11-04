#!/bin/bash
# Boots a finished build ONLY inside the throwaway VM (never on this host): copies the images and vm-boot.sh in and runs it.
set -e
V="ssh -q -i $HOME/vm/key -p 2232 -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null t@127.0.0.1"
S="-q -i $HOME/vm/key -P 2232 -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null"
O=~/etesian-redroid/src/out/target/product/redroid_x86_64_only
FS=~/etesian-redroid/src/out/soong/.intermediates/system/core/init/init_first_stage/android_ramdisk_x86_64/init
$V mkdir -p img
scp $S $O/system.img $O/vendor.img "$(dirname "$0")/vm-boot.sh" t@127.0.0.1:img/ && scp $S $FS t@127.0.0.1:img/first_stage_init
$V bash img/vm-boot.sh
