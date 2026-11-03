# Operations Deployment — Processes and signals

Domain: Operations Deployment ("Diagnose, identify, manage, and
troubleshoot processes and services").

Scope: process-level tooling. System-wide monitoring (load, top, vmstat,
sar) lives in
[performance-monitoring.md](../essential-commands/performance-monitoring.md);
the diagnosis method in
[troubleshooting-method.md](../../lab/troubleshooting-method.md).

## Selecting processes

```
ps aux --sort=-%cpu | head          # top CPU consumers
ps aux --sort=-%mem | head          # top memory consumers
ps -eo state,pid,cmd | grep '^D'    # D-state: uninterruptible I/O wait
ps -eo pid,ppid,ni,state,cmd        # custom columns
ps -u alice                         # by user
pgrep -l nginx                      # PIDs + names by process name
pgrep -u alice -f 'python.*app'     # by user + full-cmdline pattern
pidof nginx
```

High load with low CPU% points at iowait / D-state processes — the
`grep '^D'` line above is the fast check.

## Signals (man 7 signal)

| Signal | Num | Use |
| --- | --- | --- |
| SIGHUP | 1 | daemon config reload / terminal hangup |
| SIGINT | 2 | Ctrl-C |
| SIGTERM | 15 | polite terminate — the default; try first |
| SIGKILL | 9 | forced kill, cannot be caught — last resort |
| SIGSTOP | 19 | pause, cannot be caught |
| SIGCONT | 18 | resume a stopped process |

```
kill PID                    # SIGTERM
kill -9 PID                 # SIGKILL (also: kill -SIGKILL PID)
kill -l                     # list all signals
pkill -f 'pattern'          # by full-cmdline pattern
killall nginx               # by exact name
```

**Trap:** `kill -9` does nothing to a D-state process — it is
uninterruptible until the blocking I/O (dead NFS server, failing disk)
completes; fix the I/O source instead. Zombies (`Z`) cannot be killed
either: they are already dead and only hold a process-table slot —
restart or signal the **parent** so it reaps them.

**Trap:** `pkill -f` matches anywhere in the full command line of every
process. Dry-run the same pattern with `pgrep -af 'pattern'` first or
you kill more than intended.

## Priorities (nice / renice)

```
nice -n 10 cmd                  # start lowered; range -20 (high) .. 19 (low)
renice -n 5 -p PID              # change a running process
ps -o pid,ni,cmd -p PID         # check niceness
```

Negative niceness requires root.

## Jobs, backgrounding, surviving logout

```
cmd &                   # start in background
jobs                    # list shell jobs
fg %1 / bg %1           # foreground / resume in background
# Ctrl-Z stops the foreground job (SIGTSTP); then bg to continue it
nohup cmd &             # survives logout; output to nohup.out
```

Anything that must survive **reboot** is not a shell job: use a systemd
unit or timer —
[systemd-services.md](../essential-commands/systemd-services.md),
[job-scheduling.md](job-scheduling.md).

No family delta: ps, pgrep, kill, nice, and job control behave
identically on deb/rpm/suse.

## Grader-style verification

```
pgrep -af 'pattern'               # process exists / is gone — fresh read
ps -o pid,ni,state -p PID         # niceness and state as graded
grep State: /proc/PID/status      # authoritative state
grep Name: /proc/PID/status       # confirm you have the right PID
```

Processes do not survive reboot. If the task says "must run after
reboot", the answer is a systemd unit/timer plus `systemctl
enable`, never a bare backgrounded process.
