# Storage — RAID (mdadm)

Domain: Storage ("Create, manage, and troubleshoot filesystems"). RAID
is not a named competency; it slots under the filesystems item plus
failure recovery. Kept lean on purpose: create → persist → verify.

## Create

```
mdadm --create /dev/md0 --level=1 --raid-devices=2 /dev/sdb /dev/sdc
mdadm --create /dev/md0 --level=5 --raid-devices=3 /dev/sdb /dev/sdc /dev/sdd \
      --spare-devices=1 /dev/sde     # optional hot spare
```

```
cat /proc/mdstat                     # sync/rebuild progress
mdadm --detail /dev/md0              # array view
mdadm --examine /dev/sdb             # member (superblock) view
```

Then mkfs + mount as usual
([partitioning-and-filesystems.md](partitioning-and-filesystems.md)).

## Disk replacement

```
mdadm /dev/md0 --fail /dev/sdb
mdadm /dev/md0 --remove /dev/sdb
mdadm /dev/md0 --add /dev/sde
cat /proc/mdstat                     # watch the rebuild
```

Stop/reassemble:

```
mdadm --stop /dev/md0
mdadm --assemble --scan              # reassemble from superblocks
```

## Persistence per family

| | deb | rpm | suse |
| --- | --- | --- | --- |
| Config file | /etc/mdadm/mdadm.conf | /etc/mdadm.conf | /etc/mdadm.conf |
| Capture arrays | `mdadm --detail --scan >> <conf>` | same | same |
| Initramfs refresh | `update-initramfs -u` | `dracut -f` | `dracut -f` |

RHEL 9 auto-assembles data arrays from superblock metadata — the
initramfs refresh is strictly needed only when root/boot sit on RAID.
Conf + initramfs refresh together is the reboot-surviving combo; do both.

**Trap:** the conf path differs — /etc/mdadm/**mdadm.conf under
/etc/mdadm/** on deb vs /etc/mdadm.conf directly under /etc on
rpm/suse. Appending to the wrong path silently does nothing.

## fstab

By UUID of the filesystem **on the array**:

```
blkid /dev/md0                       # fs UUID
```

```
UUID=...  /data  ext4  defaults  0  2
```

## Verification (grader-style)

```
cat /proc/mdstat                     # array up, all members, no rebuild stuck
mdadm --detail /dev/md0              # state clean, spares as asked
umount /data && mount -a && findmnt /data   # fstab proven BEFORE reboot
```

Reboot-survivability: reboot, then `cat /proc/mdstat` + `findmnt /data`
— array assembled and mounted without manual steps.
