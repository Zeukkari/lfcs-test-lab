# Storage — Swap

Domain: Storage ("Configure and manage swap space").

Family delta is minimal — the commands are identical everywhere; what
differs is the default root filesystem you might put a swapfile on:

| | deb | rpm | suse |
| --- | --- | --- | --- |
| Default root fs | ext4 — plain swapfile flow works | xfs — plain flow works | **btrfs — mkswapfile flow required** (see below) |
| zram package | zram-tools | zram-generator | not in research — verify in lab |

## Swap partition or LV

```
mkswap /dev/vg0/swap
swapon /dev/vg0/swap
blkid /dev/vg0/swap             # UUID for fstab
```

fstab:

```
UUID=...  none  swap  defaults  0  0
```

Resizing LV-backed swap: `swapoff` it first, resize, then mkswap/swapon
again (exact re-create flow: verify in lab — mkswap may issue a new UUID,
check fstab afterwards).

## Swap file

```
fallocate -l 1G /swapfile       # or: dd if=/dev/zero of=/swapfile bs=1M count=1024
chmod 600 /swapfile
mkswap /swapfile
swapon /swapfile
```

fstab:

```
/swapfile  none  swap  defaults  0  0
```

**Trap:** `chmod 600` before swapon — mkswap/swapon warn on looser
permissions and graders check the mode.

## btrfs caveat (openSUSE default root fs)

**Trap:** on btrfs a swapfile must be NOCOW and uncompressed, and
fallocate-created holes are rejected — the plain flow above fails.

Easiest modern path:

```
btrfs filesystem mkswapfile --size 1g /swap/swapfile
swapon /swap/swapfile
```

Manual path: create an empty file, `chattr +C` on it, then fill with dd
and mkswap. Snapshots of the containing subvolume break the swapfile —
SUSE convention is a dedicated subvolume (e.g. /swap).

## swappiness and zram

`vm.swappiness` (default 60) tunes swap eagerness:

```
sysctl -w vm.swappiness=10                    # runtime
echo 'vm.swappiness=10' > /etc/sysctl.d/99-swap.conf   # persistent
sysctl --system
```

Persistence mechanics in
[kernel-parameters.md](../operations-deployment/kernel-parameters.md) —
a natural combined exam task.

zram (compressed RAM swap): mention only, not a likely exam task —
`zram-generator` (rpm), `zram-tools` (deb).

## Verification (grader-style)

```
swapon --show                   # device/file, size, prio
free -h                         # swap total reflects it
swapoff -a && swapon -a         # proves the fstab entry BEFORE reboot
swapon --show
```

Reboot-survivability: reboot, then `swapon --show` — swap must return
without manual swapon.
