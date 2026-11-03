# Etesian in a container

Etesian (LineageOS with the Etesian experience) as a Docker image that runs like [Redroid](https://github.com/remote-android/redroid-doc):
one container, no virtual machine. Built for the latest LineageOS only. [Cloud Companion](https://github.com/Etesian-design/cloud-companion)
uses it for its Android page.

Status: a spike. Nothing here has booted yet.

## Layout
- `manifest/etesian-redroid.xml`: a local manifest that adds Redroid's container device to a LineageOS tree.
- `device/`: the `etesian_redroid_x86_64` product (goes to `device/etesian/redroid`).
- `patches/<project>/`: Redroid's changes to Android, rebased on the LineageOS version. They switch off SELinux and seccomp and
  let Android boot without a kernel of its own, so they belong only in a tree that builds the container, never in a phone build.
- `builder/`: the build environment as a Docker image, so the build host needs only Docker.

## Host
The `binder_linux` kernel module, loaded with `devices=binder,hwbinder,vndbinder` (the same as any Redroid).

## Licences
Redroid's parts are Apache-2.0; `device/redroid-prebuilts` holds Mesa and other open-source binaries. No Nokia files: the
optional `vendor/harmattan-n9` is never part of this build.
