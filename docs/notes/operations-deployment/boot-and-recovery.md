# Operations Deployment — Boot and recovery

Domain: Operations Deployment ("Recover from hardware, operating
system, or filesystem failures").

## GRUB edit at boot (one-shot kernel args)

Press `e` on the menu entry (Shift or Esc reveals the hidden menu on
Ubuntu BIOS boots), edit the `linux`/`linuxefi` line, boot with Ctrl-X
or F10. Edits are one-shot — nothing is persisted.

## Root password reset

RHEL-family canonical path (SELinux-aware) — append `rd.break` to the
linux line, then from the initramfs emergency shell:

```
mount -o remount,rw /sysroot
chroot /sysroot
passwd root
touch /.autorelabel
exit
exit
```

**Trap:** skipping `touch /.autorelabel` leaves the rewritten
/etc/shadow with an unreadable SELinux context — logins keep failing
even though the password is set. Theory in [selinux.md](selinux.md).
RHEL 9 note: clearing `console=` args may be needed for the prompt to
show.

Generic alternative (deb/suse; rpm too if booted with `enforcing=0`) —
append `init=/bin/bash`:

```
mount -o remount,rw /
passwd
exec /sbin/init        # or force reboot
```

Ubuntu extra: recovery-mode menu gives a root shell — remount rw first.

## systemd targets and the broken-fstab boot

```
systemd.unit=rescue.target        # kernel arg: single-user-ish, needs root pw
systemd.unit=emergency.target     # kernel arg: minimal, / read-only
systemctl rescue / emergency      # switch at runtime
systemctl get-default             # inspect default target
systemctl set-default multi-user.target
```

A broken fstab entry drops boot into emergency mode. Fix: remount rw,
correct the entry (or add `nofail`), then

```
systemctl daemon-reload
mount -a                          # must come back clean before rebooting
```

## fsck and xfs_repair

Only on **unmounted** filesystems:

```
fsck -y /dev/vg0/data             # ext4 → runs e2fsck
xfs_repair /dev/vg0/data          # XFS
xfs_repair -L /dev/vg0/data       # zeroes the log — last resort only
```

Root filesystem: repair from rescue media/initramfs, or boot once with
kernel param `fsck.mode=force`.

## GRUB reinstall and config regen per family

| | deb | rpm | suse |
| --- | --- | --- | --- |
| BIOS install | `grub-install /dev/sda` | `grub2-install /dev/sda` | `grub2-install /dev/sda` |
| UEFI install | via grub-efi-amd64 to /boot/efi | **do not run grub2-install** — reinstall `shim-x64 grub2-efi-x64` packages if missing | `grub2-install` |
| regen config | `update-grub` (= `grub-mkconfig -o /boot/grub/grub.cfg`) | `grub2-mkconfig -o /boot/grub2/grub.cfg` | `grub2-mkconfig -o /boot/grub2/grub.cfg`, or wrapper `update-bootloader` |

**Trap:** on RHEL 9 the config path is /boot/grub2/grub.cfg on **both**
BIOS and UEFI — /boot/efi/EFI/redhat/grub.cfg is only a stub; and
running `grub2-install` on a UEFI RHEL system breaks the shim boot
chain.

Persistent kernel args the RHEL way:

```
grubby --update-kernel=ALL --args="foo=bar"
grubby --info=ALL
```

UEFI-vs-BIOS check: `/sys/firmware/efi` exists → UEFI boot.

## Forensics after a bad boot

```
journalctl --list-boots
journalctl -b -1 -p err           # errors from the previous boot
```

Persistent journal is default on deb (Ubuntu 20.04+, /var/log/journal
exists); rpm/suse default to volatile (no /var/log/journal → journal in
/run/log/journal, lost on reboot) — there `journalctl -b -1` returns
nothing until persistence is enabled (that IS the exam trap), and
rsyslog's /var/log/messages is the fallback forensic source. Enable:
`mkdir /var/log/journal && systemd-tmpfiles --create --prefix
/var/log/journal`, or Storage=persistent + restart. (verify in lab)

## Grader-style verification

```
systemctl get-default             # intended default target set
mount -a && findmnt /data         # fstab parses clean + mounts fresh
journalctl -b -1 -p err           # previous boot had the failure, current is clean
grubby --info=ALL | grep args     # kernel args actually persisted (rpm)
```

The only real proof of a password reset or bootloader fix is the
reboot: boot must reach the default target and the new credentials must
log in.
