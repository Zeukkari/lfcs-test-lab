# Storage — Virtual filesystem (/proc, /sys)

Domain: Storage ("Manage and configure the virtual file system"). Scope
matches LFS207 ch. 19 "Linux Filesystems and the VFS": /proc, /sys,
mounts, filesystem types — VFS concepts, not kernel code. The *write*
side (sysctl persistence, module loading/options) lives in
[kernel-parameters.md](../operations-deployment/kernel-parameters.md);
this note is the inspect/read side.

No family delta: /proc and /sys are kernel interfaces, identical on
deb/rpm/suse.

## /proc tour

| Path | What it answers |
| --- | --- |
| /proc/cmdline | kernel args of *this* boot (was `rd.break` passed? which root=?) |
| /proc/meminfo | memory truth; judge by `MemAvailable` (same source as `free`) |
| /proc/mounts | authoritative list of current mounts |
| /proc/sys/** | sysctl namespace as files (dots ↔ slashes) |
| /proc/PID/status | process state, UIDs, threads |
| /proc/PID/limits | effective ulimits of a *running* process (gold verifier) |
| /proc/PID/fd | open file descriptors (deleted-but-open files) |
| /proc/PID/environ | process environment (`tr '\0' '\n'` to read) |
| /proc/mdstat | RAID state — see [raid-mdadm.md](raid-mdadm.md) |
| /proc/net/bonding/* | bonding state (gold verifier for bonds) |

sysctl ↔ /proc/sys mapping:

```
sysctl net.ipv4.ip_forward
cat /proc/sys/net/ipv4/ip_forward    # same value, dots become slashes
```

**Trap:** `echo 1 > /proc/sys/...` (or `sysctl -w`) applies immediately
but does NOT survive reboot. Persistence is /etc/sysctl.d/ +
`sysctl --system` — mechanics and the `sysctl -p` trap in
[kernel-parameters.md](../operations-deployment/kernel-parameters.md).

## /sys tour

| Path | What it answers |
| --- | --- |
| /sys/class/net/*/ | NIC device state (operstate, speed, mtu) |
| /sys/block/<dev>/queue/scheduler | active I/O scheduler (brackets mark current) |
| /sys/fs/cgroup | cgroup v2 unified tree (all three families) |
| /sys/firmware/efi | directory exists = booted via UEFI — decides GRUB reinstall path in recovery tasks |

```
cat /sys/class/net/eth1/operstate
cat /sys/block/sda/queue/scheduler
[ -d /sys/firmware/efi ] && echo UEFI || echo BIOS
```

## Mounts: /proc/mounts vs findmnt

```
cat /proc/mounts                # raw, authoritative
findmnt                         # same data as a tree
findmnt /data                   # one mountpoint: source, fstype, options
findmnt -t nfs,cifs             # filter by type
findmnt --verify                # lint /etc/fstab against reality
```

/etc/mtab is a compatibility symlink to /proc/self/mounts (standard
stable knowledge) — never edit it; fstab is the config, /proc/mounts the
state.

## Filesystem types

```
cat /proc/filesystems           # fs types the running kernel supports
lsblk -f                        # which fs is actually on each device
findmnt -t btrfs                # where a given type is mounted
```

## Verification (grader-style)

VFS files are state, not config — verification means proving a *setting*
reached the kernel and (where asked) persists:

```
cat /proc/sys/vm/swappiness     # fresh read of the live value
sysctl vm.swappiness            # same number
findmnt --verify                # fstab sane
```

Reboot-survivability: values set only via /proc/sys revert on reboot —
after reboot, re-read the /proc path and expect the persisted value from
/etc/sysctl.d/ (see
[kernel-parameters.md](../operations-deployment/kernel-parameters.md)).
