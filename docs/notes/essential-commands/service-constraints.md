# Essential Commands — service constraints

Domain: Essential Commands ("Determine application and service specific
constraints").

Scope **[UNCERTAIN]** — no official course chapter names this
competency; the best-supported reading is systemd resource controls
(cgroup v2) plus a constraint-diagnosis checklist. Re-verify the real
task shape after killer.sh attempt 1. No family delta: all three lab
families default to cgroup v2.

The login-session side (pam_limits, ulimit, user slices) belongs to
Users and Groups:
[resource-limits.md](../users-and-groups/resource-limits.md).

## The directives (cgroup v2 era)

| Directive | Limits | Example |
| --- | --- | --- |
| CPUQuota= | CPU time | `CPUQuota=50%` (half of one core) |
| MemoryMax= | RAM hard cap (OOM-kill above it) | `MemoryMax=512M` |
| TasksMax= | threads + processes | `TasksMax=100` |
| IOReadBandwidthMax= / IOWriteBandwidthMax= | per-device I/O | `IOReadBandwidthMax=/dev/sda 1M` |
| IOWeight= | relative I/O share (1–10000) | `IOWeight=50` |
| LimitNOFILE= | open files (ulimit -n equivalent) | `LimitNOFILE=65535` |

**Trap:** `MemoryLimit=` is the cgroup-v1 legacy spelling — on v2 use
`MemoryMax=` (and `MemoryHigh=` for soft pressure). Current systems
expect the v2 names.

## Applying limits — three routes

```
# 1. Live + persistent drop-in in one step:
systemctl set-property nginx.service MemoryMax=512M CPUQuota=50%
systemctl set-property --runtime nginx.service TasksMax=100   # until reboot

# 2. Unit drop-in, then restart:
systemctl edit nginx           # add:  [Service]  MemoryMax=512M
systemctl restart nginx

# 3. Ad-hoc command under limits:
systemd-run --scope -p MemoryMax=256M -p TasksMax=50 ./batchjob
systemd-run -p CPUQuota=25% --unit=batch1 ./batchjob   # transient service
```

`set-property` writes its persistent drop-in under
/etc/systemd/system.control/ (`--runtime` → /run/systemd/...);
`systemctl edit` drop-ins live in /etc/systemd/system/<unit>.d/.

## Observing limits

```
systemctl show nginx -p MemoryMax -p TasksMax -p CPUQuotaPerSecUSec
systemctl status nginx         # Tasks:/Memory: lines = usage vs cap
systemd-cgtop                  # live per-unit CPU/memory/tasks/io
cat /sys/fs/cgroup/system.slice/nginx.service/memory.max
cat /sys/fs/cgroup/system.slice/nginx.service/cpu.max   # "50000 100000" = 50%
```

**Trap:** `CPUQuota=50%` reads back as `CPUQuotaPerSecUSec=500ms` in
`systemctl show` — same setting, different unit.

## Diagnosis checklist — "the app won't start / won't perform"

Cheapest first:

```
systemctl status app; journalctl -xeu app     # OOM-killed? "Too many open files"?
cat /proc/$(pidof app)/limits                 # effective ulimits of the live PID
ldd /usr/sbin/app | grep 'not found'          # missing shared libraries
ss -tlnp                                      # port taken? listening at all?
systemctl show app -p MemoryMax -p TasksMax -p LimitNOFILE   # systemd caps
```

Last stop: application-level limits in the app's own config (nginx
`worker_connections`, database `max_connections`) — systemd can't see
those.

## Grader-style verification

```
systemctl show app -p MemoryMax                           # asked cap is set
systemctl cat app                                         # drop-in exists on disk
cat /sys/fs/cgroup/system.slice/app.service/memory.max    # kernel enforces it
systemctl restart app && systemctl show app -p MemoryMax  # survives restart
# reboot, then:
systemctl show app -p MemoryMax                           # persistent, not --runtime
```
