# Operations Deployment — Job scheduling (cron, at, systemd timers)

Domain: Operations Deployment ("Manage or schedule jobs for executing
commands").

## cron

```
crontab -e / -l / -r            # edit / list / remove own crontab
crontab -e -u alice             # another user's (root)
```

Fields: `m h dom mon dow command` — user crontabs have **no** user
field.

```
*/5 * * * *       /usr/local/bin/x     # every 5 minutes
0 2 * * Mon-Fri   /usr/local/bin/x     # 02:00 weekdays
```

System locations:

- /etc/crontab and /etc/cron.d/* — 6 fields: a **user field** sits
  between time and command (`0 2 * * * root /usr/local/bin/x`).
- /etc/cron.{hourly,daily,weekly,monthly}/ — plain executables run via
  run-parts, no crontab syntax.

**Trap:** forgetting the user field in /etc/cron.d (or adding one in a
user crontab) breaks the job. A cron.d file must be root-owned, not
world-writable, and have **no dot in its name**, or cron ignores it.

## anacron (catch-up for missed periodic runs)

/etc/anacrontab: `period delay job-id command`; variables RANDOM_DELAY,
START_HOURS_RANGE. Catches up missed daily/weekly/monthly runs after
downtime.

## at (one-shot jobs)

```
echo 'systemctl restart nginx' | at 10:00
at now + 5 minutes              # interactive, end with Ctrl-D
atq                             # queue
atrm 3                          # remove job 3
batch                           # run when load allows
```

Package `at`, service `atd` must be running.

## systemd timers

Pair with matching stems: backup.timer activates backup.service.

```
# /etc/systemd/system/backup.service
[Unit]
Description=Backup job
[Service]
Type=oneshot
ExecStart=/usr/local/bin/backup.sh

# /etc/systemd/system/backup.timer
[Unit]
Description=Run backup on schedule
[Timer]
OnCalendar=Mon..Fri 10:00
Persistent=true
[Install]
WantedBy=timers.target
```

```
systemd-analyze calendar 'Mon..Fri 10:00'   # validate expression first
systemctl daemon-reload
systemctl enable --now backup.timer         # enable the TIMER, not the service
systemctl list-timers --all
```

- `Persistent=true` — anacron-style catch-up of runs missed while down.
- Monotonic alternatives: `OnBootSec=`, `OnUnitActiveSec=`; spread load
  with `RandomizedDelaySec=`.
- Transient, no files: `systemd-run --on-calendar='*:0/5' /usr/local/bin/x`
  or `systemd-run --on-active=30s /usr/local/bin/x`.

Unit-file anatomy details:
[systemd-services.md](../essential-commands/systemd-services.md).

## Same task both ways

The exam may dictate the mechanism — know the 1:1 translation:

```
0 10 * * 1-5 /usr/local/bin/backup.sh     # cron line (user crontab)
OnCalendar=Mon..Fri 10:00                 # timer equivalent
```

## Per-family deltas

| | deb | rpm | suse |
| --- | --- | --- | --- |
| cron service name | `cron` | `crond` | `cron` |
| cron execution log | journal + /var/log/syslog (`grep CRON`) | /var/log/cron | journal (/var/log/messages via rsyslog if installed) |
| anacron package | `anacron` | `cronie-anacron` | verify in lab |

## Grader-style verification

```
systemctl list-timers --all             # timer loaded + next/last run
journalctl -u backup.service            # job actually ran (all families)
cat /var/log/cron                       # rpm: cron executions
grep CRON /var/log/syslog               # deb: cron executions
crontab -l -u alice                     # the entry exists as asked
atq                                     # at job queued
systemctl status cron|crond             # daemon alive (name per family)
```

Reboot survivability: `enable --now` on the timer + `Persistent=true`
where catch-up is wanted; crontab entries persist by nature but the
cron/atd services must be enabled.
