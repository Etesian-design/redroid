#!/bin/bash
# Runs INSIDE the throwaway test VM (see vm-test.sh): assembles the image from ~/img and boots it.
set -e
sudo modprobe binder_linux; sudo modprobe af_key; sudo mkdir -p /dev/binderfs; mountpoint -q /dev/binderfs || sudo mount -t binder binder /dev/binderfs
cd ~/img; sudo mkdir -p /x/system /x/vendor /x/root; sudo umount /x/system /x/vendor 2>/dev/null || true
sudo mount -o ro,loop system.img /x/system; sudo mount -o ro,loop vendor.img /x/vendor
sudo install -m 750 first_stage_init /x/root/init
(cd /x && sudo tar --xattrs -c vendor -C /x/root init -C /x/system --exclude=./vendor --exclude=./init .) |
  sudo docker import -c 'ENTRYPOINT ["/init", "qemu=1", "androidboot.hardware=redroid"]' - etesian-redroid:24.0 >/dev/null
sudo umount /x/system /x/vendor
sudo docker rm -f et >/dev/null 2>&1 || true; sudo docker volume rm et-data >/dev/null 2>&1 || true; sudo dmesg -C
sudo docker run -d --privileged --name et -v et-data:/data -p 127.0.0.1:5555:5555 etesian-redroid:24.0 \
  androidboot.redroid_width=1080 androidboot.redroid_height=1920 androidboot.redroid_dpi=420 androidboot.use_memfd=1 >/dev/null
for i in $(seq 60); do sleep 5
  s=$(sudo docker inspect -f '{{.State.Status}}' et); b=$(sudo docker exec et /system/bin/getprop sys.boot_completed 2>/dev/null || true)
  [ "$s" != running ] || [ "$b" = 1 ] && break; done
echo "state=$s boot=$b t=$((i*5))s"
# Cloud Companion's bridge needs adbd on TCP 5555 (2026-11-04: Lineage's userdebug left it off)
sudo docker exec et /system/bin/getprop init.svc.adbd | grep -qx running && echo "adbd running" || echo "FAIL: adbd not running"
sudo dmesg | grep -E 'reboot_on_failure|shutdown_command|failed|FAILED|E [A-Za-z]+:' | grep -v 'cgroup controller' | tail -25
