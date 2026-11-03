# Users and Groups — Resource Limits

Domain: Users and Groups ("Configure user resource limits").

Two separate mechanisms, split per plan boundary: **pam_limits** for
PAM logins (this note) vs **systemd directives** for services —
[service-constraints.md](../essential-commands/service-constraints.md)
owns the systemd side. Picking the wrong mechanism is the main trap.

## pam_limits — limits.conf + limits.d

```
# /etc/security/limits.conf  or  /etc/security/limits.d/90-custom.conf
# <domain>   <type>   <item>    <value>
alice        soft     nofile    4096
@devs        hard     nproc     100
*            -        core      0
```

- Domain: username, `@group`, `*` (everyone)
- Type: `soft` (current value, user-raisable), `hard` (ceiling),
  `-` (sets both)
- Items: `nofile` (open files), `nproc` (processes), `memlock`,
  `core`, `as` (address space)

No family delta: paths, syntax, and pam_limits in the default PAM stack
are the same on deb/rpm/suse. (PAM stack details:
[nss-pam.md](nss-pam.md).)

**Trap:** pam_limits applies at PAM login only (ssh, console, `su -`) —
it does NOT touch systemd services. A service's nofile comes from
`LimitNOFILE=` in its unit or the systemd defaults, never from
limits.conf; editing limits.conf for nginx and restarting it changes
nothing. Use
[service-constraints.md](../essential-commands/service-constraints.md).

Also: changes apply to new logins only — sessions already open keep
their old limits.

## ulimit — the current shell

```
ulimit -n           # open files (soft)
ulimit -u           # max user processes (soft)
ulimit -c           # core file size (soft)
ulimit -Hn          # hard limit variant (-H + item)
ulimit -Sn 2048     # set soft, up to the hard ceiling
```

A user may raise the soft limit up to the hard limit; only root can
raise a hard limit.

## prlimit — live change on a running process

```
prlimit --pid 1234                       # show all limits of PID
prlimit --pid 1234 --nofile=4096:8192    # set soft:hard, no restart
```

## systemd side (what touches users)

```
# global default for every unit — /etc/systemd/system.conf
DefaultLimitNOFILE=65535
# (+ /etc/systemd/user.conf for user managers); then daemon-reexec
# or reboot — verify in lab

# cap one user's slice; persistent drop-in written automatically
systemctl set-property user-1000.slice MemoryMax=1G TasksMax=500
systemctl show -p TasksMax -p MemoryMax user-1000.slice
```

- logind's `UserTasksMax=` was removed (systemd ≥ 239) — the current
  answer is `TasksMax=` on the user slice (set-property or a
  user-.slice drop-in).

| | deb | rpm | suse |
| --- | --- | --- | --- |
| TasksMax default | upstream 15% of pid_max | upstream 15% of pid_max | `DefaultTasksMax=infinity` (SLE/Leap override) |

Expect different defaults per family when demonstrating limits.

## Verification (grader-style)

Gold standard — what a live process actually has:

```
cat /proc/$(pgrep -u alice -n bash)/limits
```

Fresh-login check (pam_limits only acts at login):

```
su - alice -c 'ulimit -n'     # soft, in a brand-new PAM session
su - alice -c 'ulimit -Hn'    # hard
```

Reboot/re-login survivability: limits.conf / limits.d are re-read at
every PAM login — persistent by construction. `systemctl set-property`
writes a drop-in under /etc/systemd/system.control/ (man systemctl) —
after reboot, confirm with
`systemctl show -p TasksMax user-1000.slice` once the user is logged
in.
