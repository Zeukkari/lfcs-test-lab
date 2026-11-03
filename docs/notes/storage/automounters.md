# Storage — Filesystem automounters

Domain: Storage ("Configure filesystem automounters"). Two mechanisms:
autofs and systemd automount units. Know both — tasks usually accept
either, and the systemd fstab route is the fastest.

No family delta: package `autofs` and the systemd routes are identical
on deb/rpm/suse.

## autofs

```
apt/dnf/zypper install autofs
```

/etc/auto.master — one line per map:

```
/misc  /etc/auto.misc  --timeout=60     # indirect map: keys = subdirs of /misc
/-     /etc/auto.direct                 # direct map: keys = absolute paths
```

Indirect map /etc/auto.misc (result: /misc/share):

```
share  -fstype=nfs,rw  host:/srv/share
```

Direct map /etc/auto.direct:

```
/data/share  -fstype=nfs,rw  host:/srv/share
```

Drop-in alternative to editing auto.master: files in
/etc/auto.master.d/*.autofs.

```
systemctl enable --now autofs           # restart after any map edit
```

**Trap:** indirect mount dirs do not appear in `ls /misc` until
accessed. An empty-looking /misc is not a failure — trigger with
`cd /misc/share` (or `ls /misc/share`), then check `findmnt /misc/share`.

## systemd route 1 — fstab x-systemd.automount

Append automount options to a normal fstab line:

```
host:/srv/share  /data/share  nfs  x-systemd.automount,x-systemd.idle-timeout=60,_netdev  0  0
```

```
systemctl daemon-reload
mount -a                                # or: systemctl restart remote-fs.target
```

Creates an implicit `data-share.automount` unit; the filesystem mounts
on first access and unmounts after the idle timeout.

## systemd route 2 — explicit unit pair

Unit names must match the path — generate with systemd-escape:

```
systemd-escape -p --suffix=mount /data/share    # → data-share.mount
```

/etc/systemd/system/data-share.mount:

```
[Mount]
What=host:/srv/share
Where=/data/share
Type=nfs
```

/etc/systemd/system/data-share.automount:

```
[Automount]
Where=/data/share
TimeoutIdleSec=60

[Install]
WantedBy=multi-user.target
```

```
systemctl daemon-reload
systemctl enable --now data-share.automount
```

**Trap:** enable the **.automount**, not the .mount. Enabling the .mount
gives a plain boot-time mount and defeats on-demand automounting; the
.automount unit is what listens on the path.

## Verification (grader-style)

```
systemctl list-units --type=automount   # automount active and listening
findmnt -t autofs                       # autofs trigger points (autofs route)
ls /data/share                          # trigger the mount
findmnt /data/share                     # now mounted with the real fstype
```

Reboot-survivability: reboot, confirm `systemctl list-units
--type=automount` (or `systemctl status autofs`) shows the trigger armed
*before* access, then trigger and `findmnt` again. For the fstab route,
`mount -a` must run clean before you ever reboot.
