# Storage — Storage performance monitoring

Domain: Storage ("Monitor storage performance"). This note owns the
storage side of monitoring: iostat, pidstat -d, iotop, sar enablement.
System-wide monitoring (load average, top, vmstat, free, sar usage
against history) lives in
[performance-monitoring.md](../essential-commands/performance-monitoring.md)
— cross-linked, not repeated.

iostat/pidstat/sar come from package `sysstat` (preinstalled in the
lab).

## iostat — per-device I/O

```
iostat -xz 1        # extended stats, skip all-zero devices, 1 s interval
```

Field reading:

| Field | Meaning | Signal |
| --- | --- | --- |
| %util | device busy time | sustained near 100% = saturated device |
| await | avg ms per I/O incl. queue wait | high await = slow device or deep queue |
| aqu-sz | avg request queue size | sustained > 1 = requests backing up |
| r/s, w/s | read/write IOPS | what the load actually is |

High await with modest r/s+w/s points at the device; high %util with
high IOPS points at the workload.

## pidstat -d — which process does the I/O

```
pidstat -d 1        # per-process kB_rd/s, kB_wr/s
```

(`pidstat -u` for the CPU side — see
[performance-monitoring.md](../essential-commands/performance-monitoring.md).)

## sar — history (enablement per family)

| | deb | rpm | suse |
| --- | --- | --- | --- |
| Install | `apt install sysstat` | `dnf install sysstat` | `zypper in sysstat` |
| Extra step | **`ENABLED="true"` in /etc/default/sysstat** | — | — |
| Enable | `systemctl enable --now sysstat` | same (collect/summary timers) | same (service/timer) |
| Data path | /var/log/sysstat | /var/log/sa/saNN | verify in lab |

**Trap:** on deb, installing and enabling the service is not enough —
sar records nothing until `ENABLED="true"` is set in
/etc/default/sysstat.

```
sar -b                          # historical I/O rates (today)
sar -b -f /var/log/sa/sa03      # against an archive file (rpm path)
```

## iotop — live per-process I/O

Needs root.

**Trap (Leap 15.6):** iotop shows no SWAPIN/IO% unless the system was
booted with the `delayacct` kernel arg or `kernel.task_delayacct=1` is
set (verified in Leap 15.6 release notes) — a natural combined task with
[kernel-parameters.md](../operations-deployment/kernel-parameters.md).

## Quick wins when "storage is slow"

```
df -h               # capacity pressure — full fs masquerades as slow storage
iostat -xz 1        # live saturation per device
pidstat -d 1        # who is doing it
```

Full-filesystem troubleshooting itself (df vs du, deleted-but-open
files) belongs to
[diskspace-troubleshooting.md](../essential-commands/diskspace-troubleshooting.md).

## Verification (grader-style)

Monitoring tasks are graded on the collector being installed, enabled,
and recording:

```
systemctl status sysstat        # enabled + active
sar -b                          # returns samples, not "cannot open"
ls /var/log/sa/ /var/log/sysstat 2>/dev/null   # data files appearing
```

Reboot-survivability: reboot, then `systemctl is-enabled sysstat` and a
fresh `sar -b` — collection must resume without manual steps (on deb
that proves ENABLED="true" stuck).
