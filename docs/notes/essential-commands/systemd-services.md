# Essential Commands — systemd services

Domain: Essential Commands ("Create, configure, and troubleshoot
services"). Grounded in `man systemd.unit`, `man systemd.service`,
`man systemctl` — verify details against man pages (available in the
exam; `man systemd.directives` indexes every directive). No family
delta: systemd unit syntax, paths, and tools are identical on
deb/rpm/suse.

## Where units live

| Path | Role |
| --- | --- |
| /etc/systemd/system/ | admin units + overrides — **wins** |
| /run/systemd/system/ | runtime-generated |
| /usr/lib/systemd/system/ | package-shipped — never edit in place |

`systemctl cat <unit>` prints the effective file(s) plus drop-ins with
their paths. Never write a unit from scratch — copy a shipped one; see
the templates workflow in
[using-documentation.md](using-documentation.md).

## Unit anatomy — minimal working service

/etc/systemd/system/myapp.service:

```
[Unit]
Description=My app
After=network.target

[Service]
Type=simple
ExecStart=/usr/local/bin/myapp --flag
Restart=on-failure
User=appuser
Environment=KEY=value

[Install]
WantedBy=multi-user.target
```

Then `systemctl daemon-reload && systemctl enable --now myapp.service`.

- `[Unit]`: Description=, After=/Before= (ordering only),
  Wants=/Requires= (dependency; Requires= fails the unit with its
  dependency).
- `[Service]`: ExecStart= (exactly one unless Type=oneshot),
  ExecStartPre=, ExecReload=, Restart=/RestartSec=, User=/Group=,
  WorkingDirectory=, Environment=/EnvironmentFile=.
- `[Install]`: WantedBy=multi-user.target — what `enable` hooks into.
  Without this section, `systemctl enable` has nothing to do.

### Type= cheat table (man systemd.service)

| Type | Use when | Pairs with |
| --- | --- | --- |
| simple | ExecStart *is* the long-running process (default with ExecStart=) | |
| oneshot | script runs and exits | RemainAfterExit=yes to stay "active" |
| forking | daemon forks and parent exits (classic SysV) | PIDFile= |
| notify | app signals readiness via sd_notify | |

## Change an existing service

```
systemctl edit myapp          # drop-in: /etc/systemd/system/myapp.service.d/override.conf
systemctl edit --full myapp   # full copy into /etc/systemd/system/
systemctl revert myapp        # delete overrides, back to vendor unit
```

Drop-in = only the keys you set; everything else inherits.

**Trap:** list-type settings append instead of replacing. To change
ExecStart= in a drop-in, reset it with an empty assignment first:

```
[Service]
ExecStart=
ExecStart=/usr/local/bin/myapp --new-flag
```

**Trap:** any on-disk edit made with a plain editor needs
`systemctl daemon-reload` before restart (`systemctl edit` reloads for
you) — without it the old definition keeps running and the grader sees
stale config.

## enable / disable / mask

```
systemctl enable --now myapp    # persist + start in one step
systemctl disable --now myapp
systemctl mask myapp            # symlink to /dev/null — cannot start at all
systemctl unmask myapp
systemctl is-enabled myapp      # enabled | disabled | masked | static
```

**Trap:** `disable` only removes the boot symlink — the unit can still
be started manually or by a dependency. `mask` is the real "never
runs". `static` means no [Install] section: nothing to enable, it is
pulled in by other units.

## Failure triage (in order)

```
systemctl status myapp                 # state, exit code, last log lines
journalctl -xeu myapp                  # full unit log, explanations, end of log
systemd-analyze verify myapp.service   # unit syntax/reference errors
systemctl cat myapp                    # what is actually loaded, incl. drop-ins
systemctl show myapp -p FragmentPath -p ExecStart
systemctl list-dependencies myapp
```

Common findings: wrong ExecStart path (exit 203/EXEC), missing
daemon-reload, masked unit, failed dependency, wrong User=. After
fixing a crash loop: `systemctl reset-failed myapp`. General approach:
[troubleshooting-method.md](../../lab/troubleshooting-method.md).

## Grader-style verification

```
systemctl is-active myapp && systemctl is-enabled myapp
systemctl cat myapp                    # requested config is the live config
journalctl -u myapp -n 5               # started cleanly, no error spam
systemd-analyze verify myapp.service   # no unit-file errors
# reboot, then:
systemctl is-active myapp              # survives reboot (enabled, not just started)
```
