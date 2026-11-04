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

### Iterate over each line of a file

```bash
while IFS= read -r line; do
    echo "got: $line"
done < /etc/passwd
```

- `IFS=` stops leading/trailing whitespace being stripped from `$line`.
- `-r` stops `read` eating backslashes (treats `\` literally).
- Redirect the file **into the `while`** (`< file`, after `done`), not
  via `cat file | while ...` — the pipe form runs the loop in a
  subshell, so variables set inside it vanish once the loop ends.
- Field-splitting a line as you read it: `while IFS=: read -r user _ uid
  gid _ home shell; do ...; done < /etc/passwd` — unwanted fields go to
  `_`, matching `/etc/passwd`'s `:`-separated columns.
- Processing command output instead of a file: `done < <(command)`
  (process substitution) keeps the same no-subshell property; a trailing
  `| while read ...` pipe does not.

### Arithmetic comparison

```bash
n=5
if [ "$n" -gt 3 ]; then echo "bigger"; fi     # POSIX test: -eq -ne -gt -lt -ge -le
if (( n > 3 )); then echo "bigger"; fi        # arithmetic context: normal < > == !=
(( n == 5 )) && echo "equal"
```

- Inside `[ ]`/`[[ ]]` use the **named** operators (`-eq`, `-ne`,
  `-gt`, `-ge`, `-lt`, `-le`) for numbers. `>`/`<` mean something else
  in both: in `[ "$n" > 3 ]` the shell parses `>` as **redirection**
  before `[` ever runs — it silently creates/truncates a file called
  `3` and the test only checks whether `$n` is non-empty. In
  `[[ "$n" > 3 ]]` (no escaping needed there) it's a lexicographic
  **string** comparison, not numeric — `"10" > "9"` is false as
  strings though true as numbers.
- Inside `(( ))` use the **normal** C-style operators (`>` `<` `>=`
  `<=` `==` `!=`) — no quoting of variables needed, `$n` is optional
  inside `(( ))`.
- `(( expr ))` exits non-zero (false) when `expr` evaluates to `0`,
  zero (true) otherwise — opposite of what shell truthiness usually
  "feels" like, matters when chaining with `&&`/`||`.

## Finding bash syntax in `man bash` (no internet in the exam)

`man bash` is one huge page, but the syntax you forget under pressure —
loop/`if` forms, `[[ ]]` tests, `$(( ))`, `trap` — lives under a handful
of named sections. Jump straight to them instead of scrolling:

```bash
man bash
/^SHELL GRAMMAR          # Enter, then n/N to cycle matches
```

- **Loops and `if`/`case` syntax** — section **"Compound Commands"**
  (inside SHELL GRAMMAR): exact grammar for `for`, `while`, `until`,
  `if`/`elif`/`else`, `case`, `select`, `((...))`, `[[...]]`.
  `/Compound Commands` from the top of the man page.
- **Arithmetic (`$(( ))`, `let`, `((...))`, operators, bases)** —
  section **"ARITHMETIC EVALUATION"**. `/^ARITHMETIC EVALUATION`.
- **`[[ ]]`/`test`/`[` operators** (`-f`, `-z`, `-eq`, `&&`, `||`
  inside `[[ ]]` vs needing `-a`/`-o` inside `[ ]`) — section
  **"CONDITIONAL EXPRESSIONS"**. `/^CONDITIONAL EXPRESSIONS`.
- **`trap` (signal names, `EXIT`/`ERR`/`DEBUG` pseudo-signals, reset
  with `trap - SIGNAL`)** — it's a builtin, not its own heading: go to
  **"SHELL BUILTIN COMMANDS"** then search *inside* that section,
  since a bare `/trap` from the top also matches unrelated prose about
  traps earlier in the page:

  ```bash
  man bash
  /^SHELL BUILTIN COMMANDS    # Enter to jump there
  /^       trap               # then search from that point on
  ```

- **Positional params, `$#`, `$@` vs `$*`, `${var:-default}` forms** —
  section **"PARAMETERS"** (plain params) and **"EXPANSION"** →
  "Parameter Expansion" subsection (the `${...}` forms).
- **Exit status conventions** (`$?`, `&&`/`||` short-circuiting) —
  section **"EXIT STATUS"**.

General technique: `man bash`, then `/^SECTION NAME` (the `^` anchors
to section headers so you don't match the word inside body text), `n`
for next match. `man -P 'less -p "^ARITHMETIC EVALUATION"' bash` opens
straight at a section in one command if typing the search after isn't
needed. Same approach works for other man pages under time
pressure — jump by section header, don't read linearly.

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
