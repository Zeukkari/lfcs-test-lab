# Essential Commands — classics: shell and logging

Domain: Essential Commands (supporting — implicitly tested classics).
Bash scripting, vim speed, and logging are no longer named
competencies but appear inside tasks across all benchmarks.

## Bash scripting minimums

/usr/local/bin/check.sh:

```
#!/bin/bash
PATH=/usr/sbin:/usr/bin:/sbin:/bin     # cron-safe PATH — see trap below
LOGFILE="/var/log/check.log"           # quote variable *uses*: "$LOGFILE"

if [ -f "$LOGFILE" ]; then             # test: -f file, -d dir, -z empty
    echo "exists" >> "$LOGFILE"
else
    touch "$LOGFILE" || exit 1         # exit non-zero on failure
fi

for svc in sshd crond; do
    systemctl is-active "$svc" >/dev/null || echo "$svc down"
done

exit 0
```

- `chmod +x` to run it; `bash -n script` syntax-check only;
  `bash -x script` traces execution.
- Exit codes: `$?` = last command's status; scripts exit 0 on success,
  non-zero on failure — graders check `echo $?`.
- `$1 $2` positional args, `$#` count, `"$@"` all args (quoted).
- Command substitution: `now=$(date +%F)`.
- **Trap:** cron and systemd run with a minimal environment — a script
  that works interactively but fails when scheduled almost always
  means unset PATH/vars. Set PATH inside the script or in the crontab.

## vim speed essentials

- **Trap (exam terminal):** the INSERT key is disabled in the exam UI
  (official instructions) — enter insert mode with `i` (insert),
  `a` (append), `o` (open line below).
- Mode exit: Esc. Save/quit `:wq` (or `:x`); discard `:q!`.
- Move: `gg` top, `G` bottom, `:42` line 42, `0`/`$` line start/end.
- Edit: `dd` delete line, `yy` yank, `p` paste, `u` undo, `Ctrl-r`
  redo.
- Search/replace: `/pattern` then `n`; `:%s/old/new/g` whole file.
- `:set number`; visual select `V`, then `d`/`y`.

## journalctl filter kit

```
journalctl -u nginx                    # one unit
journalctl -u nginx -p err             # priority err and worse (names or 0-7)
journalctl -b                          # this boot; -b -1 = previous boot
journalctl --since "2026-11-03 10:00" --until "2026-11-03 11:00"
journalctl --since -1h                 # relative; also: today, yesterday
journalctl -f                          # follow; -k = kernel messages only
journalctl --list-boots                # which boots the journal still holds
```

## Persistent journal — per family

| | deb | rpm | suse |
| --- | --- | --- | --- |
| default | persistent (20.04+, /var/log/journal exists) | volatile (+ rsyslog persistent in /var/log/messages) | volatile (+ rsyslog persistent in /var/log/messages) |

(verify in lab)

If `journalctl --list-boots` shows only the current boot, journald is
running volatile — enable persistence:

```
mkdir -p /var/log/journal              # presence of the dir is the switch
systemctl restart systemd-journald     # or Storage=persistent in
                                       # /etc/systemd/journald.conf
journalctl --list-boots                # now accumulates across reboots
```

## rsyslog basics — facility.priority

Selectors in /etc/rsyslog.conf + /etc/rsyslog.d/*.conf:

```
authpriv.*                        /var/log/secure    # facility.priority  action
*.info;mail.none;cron.none        /var/log/messages
local0.*                          /var/log/custom.log
```

Facilities: auth(priv), cron, daemon, kern, mail, local0–7.
Priorities ascending: debug info notice warning err crit alert emerg —
a selector matches its priority *and worse*. `systemctl restart
rsyslog` after edits.

Default log files per family:

| | deb | rpm | suse |
| --- | --- | --- | --- |
| general log | /var/log/syslog | /var/log/messages | /var/log/messages (rsyslog, if installed) |
| cron log | journal + syslog (`grep CRON`) | /var/log/cron | journal |

## logrotate

Config shape — /etc/logrotate.d/custom:

```
/var/log/custom.log {
    weekly
    rotate 4
    compress
    missingok
    notifempty
    create 0640 root adm
    postrotate
        systemctl kill -s HUP rsyslog.service
    endscript
}
```

Test without rotating: `logrotate -d /etc/logrotate.conf` (debug/dry
run); force now: `logrotate -f /etc/logrotate.d/custom`. Driven by
logrotate.timer on current families (`systemctl list-timers` — verify
in lab; older setups use /etc/cron.daily/logrotate).

## Grader-style verification

```
bash -n /usr/local/bin/check.sh && /usr/local/bin/check.sh; echo $?
logger -p local0.info "lfcs test"       # then prove the routing:
journalctl --since -2min | grep "lfcs test"
grep "lfcs test" /var/log/custom.log
journalctl --list-boots | head          # persistence survives reboots
logrotate -d /etc/logrotate.d/custom    # parses, would rotate as asked
```
