# Essential Commands — performance monitoring

Domain: Essential Commands ("Monitor and troubleshoot system
performance and services"). This note is the system-wide half: load,
CPU, memory, swap, history. Storage-side tools (iostat -xz, pidstat
-d, iotop) live in
[storage-performance.md](../storage/storage-performance.md). Family
delta: none for the tools themselves; only sysstat enablement + data
paths differ per family — covered in the storage note.

## Load average — read it against nproc

```
uptime                        # load average: 1/5/15 min
nproc                         # core count — the comparison baseline
```

- Load counts runnable **and uninterruptible (D-state)** tasks.
- High load + high %CPU → CPU-bound: find and renice/kill the hog.
- **Trap:** high load + *low* CPU% → processes blocked in I/O
  (D-state), not CPU pressure. Confirm, then pivot to the storage
  tools:

```
ps -eo state,pid,cmd | grep '^D'      # uninterruptible sleepers
```

## top — field literacy

```
top        # P sort by CPU, M by memory, 1 per-CPU view, q quit
```

- `%us` user / `%sy` system / `%wa` iowait (storage pressure) /
  `%st` steal (hypervisor withheld CPU — relevant inside VMs).
- RES = actual RAM in use (judge by this); VIRT = address space —
  often huge and harmless.

## free — judge by "available"

```
free -h
```

**Trap:** "free" near zero is normal — buff/cache is reclaimable.
Judge memory pressure by the **available** column (same source as
MemAvailable in /proc/meminfo). Real trouble = available low *and*
active swapping (next section).

## vmstat — the swap/pressure sampler

```
vmstat 1 5
```

- `r` runqueue > core count = CPU pressure.
- `b` = blocked tasks (D-state count).
- `si`/`so` nonzero across samples = actively swapping — the classic
  exam signal that memory is the real problem.
- `wa` = iowait, same meaning as top's %wa.

## sar — history (sysstat)

When the task says "yesterday" or "between 10:00 and 11:00", live
tools can't look back — sar reads the sysstat archives:

```
sar -u                         # CPU history (today's archive)
sar -r                         # memory
sar -b                         # I/O transfer summary
sar -n DEV                     # network per interface
sar -u -f /var/log/sa/sa03     # explicit archive file (rpm path shown)
```

No history unless the sysstat package is installed *and* its
collection service/timers are enabled — per-family enablement and data
paths: [storage-performance.md](../storage/storage-performance.md).

## Quick wins

```
ps aux --sort=-%cpu | head     # top CPU consumers, scriptable
ps aux --sort=-%mem | head     # top memory consumers
ss -s                          # socket summary — connection floods
systemd-cgtop                  # live CPU/memory/tasks/io per unit/slice
```

systemd-cgtop answers "which *service* is eating resources" — the
bridge to per-service caps:
[service-constraints.md](service-constraints.md).

## Grader-style verification

Monitoring tasks usually grade a written answer ("record the
PID/unit consuming the most X") — produce reproducible evidence:

```
ps aux --sort=-%cpu | head -3           # the culprit, reproducibly
ps -eo state,pid,cmd | grep '^D'        # or the blocked process
vmstat 1 5                              # swap verdict from si/so columns
free -h                                 # "available" quoted in the answer
systemd-cgtop -b -n 1 -m                # one batch sample, memory-ordered
```
