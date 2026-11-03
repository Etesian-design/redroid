# Etesian in a container

Etesian (LineageOS with the Etesian experience) as a Docker image that runs like [Redroid](https://github.com/remote-android/redroid-doc):
one container, no virtual machine. Built for the latest LineageOS only. [Cloud Companion](https://github.com/Etesian-design/cloud-companion)
uses it for its Android page.

Status: a spike. Nothing here has booted yet.

## Layout
- `manifest/etesian-redroid.xml`: a local manifest that adds Redroid's container device to a LineageOS tree.
- `device/`: the `lineage_etesian_x86_64` product (goes to `device/etesian/redroid`).
- `patches/<project>/`: Redroid's changes to Android, rebased on the LineageOS version. They switch off SELinux and seccomp and
  let Android boot without a kernel of its own, so they belong only in a tree that builds the container, never in a phone build.
- `builder/`: the build environment as a Docker image, so the build host needs only Docker.

## Host
The `binder_linux` kernel module, loaded with `devices=binder,hwbinder,vndbinder` (the same as any Redroid).

## Image and running it
`make-image.sh <tree>` turns a finished build into `etesian-redroid:24.0`. Run it like Redroid:

```
docker run -d --privileged -v etesian-data:/data -p 127.0.0.1:5555:5555 \
  etesian-redroid:24.0 androidboot.redroid_width=1080 androidboot.redroid_height=1920 androidboot.redroid_dpi=420 \
  androidboot.use_memfd=1
```

A privileged container shares the host's kernel. Android's shutdown writes to `/proc/sysrq-trigger` (signal every process,
remount read-only, crash), which would hit the whole host: on a test machine it once sent SIGTERM to sshd, Docker and every
other container. Docker refuses mounts inside `/proc`, so the image guards itself: `system_core` patch 0007 points init's
reboot code away from it, and patch 0009 hides it behind `/dev/null` at the top of `init.rc`, before anything else can write
to it (the system server's watchdog and `llkd` also can), and leaves the host's sysrq setting alone.

## Licences
Redroid's parts are Apache-2.0; `device/redroid-prebuilts` holds Mesa and other open-source binaries. No Nokia files: the
optional `vendor/harmattan-n9` is never part of this build.
