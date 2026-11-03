# Storage — Partitioning and filesystems

Domain: Storage ("Create, manage, and troubleshoot filesystems").
Partition tables, mkfs, fstab, filesystem repair. LVM has its own note
([lvm.md](lvm.md)); RAID and LUKS also slot under this competency:
[raid-mdadm.md](raid-mdadm.md), [luks.md](luks.md).

No family delta for the commands below — fdisk/parted/mkfs/blkid/findmnt
are identical on deb/rpm/suse. Default root filesystem differs: ext4
(deb), xfs (rpm), btrfs (suse) — matters for the repair tool choice and
the btrfs swapfile caveat in [swap.md](swap.md).

## Partitioning (fdisk, gdisk, parted)

Standard stable knowledge, not research-backed — verify each flow in the
lab before ticking the checklist box.

```
lsblk -f                        # start here: devices, fstype, UUID, mountpoint
fdisk /dev/sdb                  # interactive; handles MBR and GPT
  g=new GPT  o=new MBR  n=new part  t=type  p=print  w=write  q=quit
gdisk /dev/sdb                  # GPT-focused, same letter commands
parted -s /dev/sdb mklabel gpt mkpart data ext4 1MiB 100%   # scriptable
partprobe /dev/sdb              # make kernel re-read the partition table
```

Partition type (`t` in fdisk) matters for clarity/autodetection (swap,
lvm), not for mkfs to work.

**Trap:** after editing a partition table the kernel may still use the
old one — the new node is missing or stale. Run `partprobe` and confirm
with `lsblk` before any mkfs; otherwise you format the wrong thing or
fail with "device busy".

## mkfs

```
mkfs.ext4 /dev/sdb1
mkfs.xfs /dev/sdb1              # -f to overwrite an existing filesystem
mkfs.btrfs /dev/sdb1
mkfs.ext4 -L data /dev/sdb1     # optional label (xfs: also -L)
```

## /etc/fstab

Fields: `device  mountpoint  type  options  dump  pass`.

```
UUID=0a3f...  /data  ext4  defaults  0  2
```

- Device by `UUID=` (from `blkid /dev/sdb1`) — survives device
  renumbering; `/dev/vg/lv` paths are stable too (LVM).
- Options: `defaults`, plus as asked: `ro`, `noexec`, `nofail` (don't
  hang boot if absent), `_netdev` (network filesystems — see
  [remote-filesystems.md](remote-filesystems.md)).
- dump: `0`. pass: `1` for `/`, `2` for other ext filesystems, `0` to
  skip (xfs self-checks at mount; fsck.xfs is a no-op — standard man-page
  knowledge).

```
blkid /dev/sdb1                 # UUID for the fstab line
findmnt --verify                # lint fstab (catches typos, bad types)
mount -a                        # mount everything in fstab not yet mounted
```

**Trap:** never reboot to test an fstab entry — a broken line drops boot
into emergency mode. Always:

```
umount /data && mount -a && findmnt /data
```

If you do land in emergency mode: fix or `nofail` the entry,
`systemctl daemon-reload`, `mount -a` (recovery flow in
[boot-and-recovery.md](../operations-deployment/boot-and-recovery.md)).

## Repair: e2fsck vs xfs_repair

Only on **unmounted** filesystems.

```
fsck -y /dev/vg0/data           # ext4 → dispatches to e2fsck, -y auto-fix
xfs_repair /dev/sdb1            # xfs
xfs_repair -L /dev/sdb1         # zeroes the log — LAST RESORT, can lose data
```

Root filesystem: repair from rescue media/initramfs, or boot with the
`fsck.mode=force` kernel parameter (see
[boot-and-recovery.md](../operations-deployment/boot-and-recovery.md)).

**Trap:** `xfs_repair` refuses a dirty log and suggests mounting once to
replay it; reach for `-L` only when a mount is impossible — it discards
the log.

Growing a filesystem after lvextend: use `lvextend --resizefs` and the
tool choice (resize2fs vs xfs_growfs) is handled for you — see
[lvm.md](lvm.md).

## Verification (grader-style)

```
lsblk -f                        # partition + fs + UUID as intended
findmnt /data                   # mounted, right source and options
findmnt --verify                # fstab lints clean
umount /data && mount -a        # fstab entry proven BEFORE reboot
```

Reboot-survivability: reboot, then `findmnt /data` again — the mount
must come back on its own.
