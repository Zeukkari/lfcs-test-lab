# Essential Commands — diskspace troubleshooting

Domain: Essential Commands ("Troubleshoot diskspace issues").

## Triage order

```
df -h                                   # which filesystem is actually full
df -i                                   # ...or out of inodes (ENOSPC with free blocks)
du -xh --max-depth=1 / | sort -rh | head       # where the bytes are (-x: stay on fs)
find / -xdev -type f -size +100M -exec ls -lh {} +    # the big files
```

ncdu is convenient but **EPEL-only on the RHEL family** — don't build
the workflow on it (family table below).

## The canonical scenario: df says full, du disagrees

df-vs-du mismatch = deleted-but-still-open files: a process holds an
fd to a log someone `rm`-ed; the blocks are freed only when the fd
closes.

```
lsof +L1                            # all open files with link count 0
lsof /var | grep -i deleted         # scoped to one mountpoint
```

Fix — either close the holder or truncate through its fd:

```
systemctl restart <holder>          # closes the fd the clean way
: > /proc/<PID>/fd/<N>              # truncate in place, no restart needed
```

**Trap:** `rm` on a live log frees nothing while the writer keeps its
fd open. Truncate instead of removing: `truncate -s 0 big.log` (or
`: > big.log`) — the file stays valid for the writer *and* the space
returns immediately.

## Inode exhaustion

`df -i` near 100% with blocks free = millions of tiny files:

```
du --inodes -x / | sort -rn | head          # coreutils ≥ 8.22
find /var -xdev -type d \
  -exec sh -c 'echo "$(ls -a "$1" | wc -l) $1"' _ {} \; |
  sort -rn | head                           # per-dir file counts (fallback)
```

Then delete/archive the spam (mail queues, session dirs, tmp).

## Reclaiming space fast

```
journalctl --disk-usage
journalctl --vacuum-size=200M        # cap the journal right now
journalctl --vacuum-time=2weeks
```

Persist the journal cap: `SystemMaxUse=200M` in
/etc/systemd/journald.conf + `systemctl restart systemd-journald`.
Package caches per family: table below. Rotation of other logs is
logrotate's job —
[classics-shell-and-logging.md](classics-shell-and-logging.md).

## Family delta

| | deb | rpm | suse |
| --- | --- | --- | --- |
| package cache clean | `apt clean` | `dnf clean all` | `zypper clean` |
| ncdu | main repo | **EPEL only** | main repo |

Everything else in this note is family-identical.

## Grader-style verification

```
df -h /var                       # before/after: usage actually dropped
lsof +L1                         # empty = no deleted-but-open files remain
df -i /var                       # inode% back to sane
journalctl --disk-usage          # under the requested cap
touch /var/log/testfile && rm /var/log/testfile    # writes work again
```
