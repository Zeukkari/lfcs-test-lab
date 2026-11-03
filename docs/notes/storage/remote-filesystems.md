# Storage — Remote filesystems and network block devices

Domain: Storage ("Use remote filesystems and network block devices").
NFS + Samba/CIFS + NBD in one note; NBD stays client-focused.

| | deb | rpm | suse |
| --- | --- | --- | --- |
| NFS server pkg | nfs-kernel-server | nfs-utils | nfs-utils |
| NFS service | nfs-server (alias of nfs-kernel-server — verify in lab) | nfs-server | nfs-server |
| Samba services | smbd (+nmbd) | smb (+nmb) | smb (+nmb) |
| CIFS client pkg | cifs-utils | cifs-utils | cifs-utils |
| NBD packages | nbd-server, nbd-client | nbd — **EPEL only** | nbd |

## NFS server

```
apt install nfs-kernel-server / dnf install nfs-utils / zypper in nfs-utils
systemctl enable --now nfs-server
```

/etc/exports — subnet or FQDN scoping is usually graded:

```
/srv/share 192.168.56.0/24(rw,sync,no_root_squash,no_subtree_check)
```

`no_root_squash` lets client root act as root on the export —
exam/lab convenience; on real systems keep the `root_squash` default
unless the task demands otherwise.

**Trap:** no space before `(`. With a space the options no longer bind
to that host/subnet (exports(5)) — the share exports world-readable and
the grader's scoping check fails.

```
exportfs -ra                    # re-export after editing
exportfs -v / exportfs -s       # verify active exports
showmount -e server             # client-side view
firewall-cmd --add-service=nfs --permanent && firewall-cmd --reload
# NFSv4 = 2049 only; add mountd + rpc-bind services for v3
```

## NFS client

```
mount -t nfs host:/srv/share /mnt
```

fstab (`_netdev` = wait for network — graders look for it; add
`nfsvers=4.2`, `ro`, `noexec` as asked):

```
host:/srv/share  /mnt  nfs  defaults,_netdev  0  0
```

Verify: `mount -a`, `findmnt /mnt`.

## Samba server

Package `samba` (all families). Minimal share in /etc/samba/smb.conf:

```
[share]
    path = /srv/smb
    writable = yes
    valid users = alice
```

```
testparm                        # syntax check before restarting
useradd alice                   # must exist as a local user first
smbpasswd -a alice              # separate Samba password database
systemctl enable --now smb nmb  # deb: smbd nmbd
firewall-cmd --add-service=samba --permanent && firewall-cmd --reload
```

SELinux (rpm) — share dir needs the right context (theory in
[selinux.md](../operations-deployment/selinux.md)):

```
semanage fcontext -a -t samba_share_t '/srv/smb(/.*)?'
restorecon -R /srv/smb
# quick non-persistent: chcon -t samba_share_t /srv/smb
# blunt boolean: setsebool -P samba_export_all_rw on
```

## CIFS client

Package `cifs-utils`. Credentials file:

```
# /root/.smbcred — then: chmod 600 /root/.smbcred
username=alice
password=secret
domain=WORKGROUP        # optional
```

**Trap:** the credentials file must be chmod 600 — and never put the
password inline in fstab.

```
mount -t cifs //host/share /mnt -o credentials=/root/.smbcred,uid=alice
```

fstab:

```
//host/share  /mnt  cifs  credentials=/root/.smbcred,_netdev  0  0
```

## NBD (network block device)

**Trap:** on rpm-family the `nbd` package is EPEL-only (verified EPEL 9)
— `dnf install epel-release && dnf install nbd`. deb ships
nbd-server/nbd-client in the archive; suse ships nbd.

Server (minimal /etc/nbd-server/config; service `nbd-server`, TCP 10809):

```
[generic]
[export1]
exportname = /srv/disk.img
```

Client — the exam-shaped side; /dev/nbd0 then behaves like any block
device (mkfs, mount, fstab with `_netdev`):

```
modprobe nbd
echo nbd > /etc/modules-load.d/nbd.conf     # persist module load
nbd-client server -N export1 /dev/nbd0
mkfs.ext4 /dev/nbd0 && mount /dev/nbd0 /mnt
nbd-client -d /dev/nbd0                     # disconnect
```

deb persistence extra: /etc/nbdtab + `nbd@nbd0.service`. qcow2 images as
block devices:

```
modprobe nbd max_part=8                     # needed for partition nodes
qemu-nbd --connect=/dev/nbd0 image.qcow2    # partitions appear as /dev/nbd0p1
qemu-nbd --disconnect /dev/nbd0
```

If nbd is already loaded (as above), `modprobe -r nbd` first — or put
`options nbd max_part=8` in /etc/modprobe.d/ — else /dev/nbd0p1 never
appears.

## Verification (grader-style)

Server: `exportfs -s` (NFS), `testparm` + `smbclient -L localhost -U alice`
(Samba — verify in lab, smbclient not research-backed).

Client, always before reboot:

```
umount /mnt && mount -a && findmnt /mnt     # fstab entry proven
```

Reboot-survivability: reboot both ends → `findmnt /mnt` returns; fstab
network mounts must carry `_netdev` or boot ordering can break them.
