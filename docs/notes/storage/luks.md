# Storage — LUKS (cryptsetup)

Domain: Storage ("Create, manage, and troubleshoot filesystems").
Encrypted volumes are not a named competency; they slot under the
filesystems item. Kept lean on purpose: format → open → persist → verify.

No family delta: cryptsetup and crypttab behave identically on
deb/rpm/suse; LUKS2 is the default format on all current families
(cryptsetup ≥ 2.1).

## Format, open, close

```
cryptsetup luksFormat /dev/sdb1      # confirm with uppercase YES + passphrase
cryptsetup open /dev/sdb1 secret     # legacy alias: luksOpen
mkfs.ext4 /dev/mapper/secret
mount /dev/mapper/secret /mnt/secret
cryptsetup status secret
umount /mnt/secret && cryptsetup close secret
```

## Keys

```
cryptsetup luksAddKey /dev/sdb1      # add another passphrase
cryptsetup luksDump /dev/sdb1        # inspect key slots
```

Keyfile flow:

```
dd if=/dev/urandom of=/root/.lukskey bs=512 count=8
chmod 0400 /root/.lukskey
cryptsetup luksAddKey /dev/sdb1 /root/.lukskey
```

## Boot wiring: crypttab + fstab

/etc/crypttab (3rd field: keyfile path, or `none` = passphrase prompt at
boot):

```
secret  UUID=<luks-container-uuid>  none  luks
secret  UUID=<luks-container-uuid>  /root/.lukskey  luks   # keyfile variant
```

/etc/fstab mounts the opened mapping:

```
/dev/mapper/secret  /mnt/secret  ext4  defaults  0  2
```

**Trap:** two different UUIDs are in play. crypttab wants the LUKS
*container* UUID — `blkid /dev/sdb1` (TYPE=crypto_LUKS). fstab wants the
*inner* filesystem — use `/dev/mapper/secret`, or its own UUID from
`blkid /dev/mapper/secret` (only visible while open). Swapping them
breaks boot.

## Verification (grader-style)

```
umount /mnt/secret && cryptsetup close secret
systemctl daemon-reload
systemctl start systemd-cryptsetup@secret    # proves the crypttab wiring
mount -a && findmnt /mnt/secret              # proves fstab BEFORE reboot
```

Reboot-survivability: reboot — expect the passphrase prompt (or silent
keyfile unlock), then `findmnt /mnt/secret` and
`cryptsetup status secret` show the volume open and mounted.
