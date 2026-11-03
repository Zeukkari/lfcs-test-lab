# Users and Groups — Environment Profiles

Domain: Users and Groups ("Manage personal and system-wide environment
profiles").

## Startup chains — login vs non-login

Login shell (ssh session, console login, `su -`):

```
/etc/profile
  → /etc/profile.d/*.sh
  → first existing of: ~/.bash_profile, ~/.bash_login, ~/.profile
```

Interactive non-login shell (new terminal, plain `su`):

```
system bashrc (see table)  →  ~/.bashrc
```

| | deb | rpm | suse |
| --- | --- | --- | --- |
| System non-login rc | `/etc/bash.bashrc` | `/etc/bashrc` | `/etc/bash.bashrc` |
| Stock chaining | `~/.profile` sources `~/.bashrc` | `~/.bash_profile` sources `~/.bashrc` | verify in lab |

Stock dotfiles chain the two worlds, so interactive settings usually
appear in both shell types — but the profile chain only ever runs for
login shells.

**Trap — the `su` vs `su -` classic:** `su alice` starts a non-login
shell; /etc/profile, /etc/profile.d/ and ~/.profile are all skipped, so
profile-set variables are missing. `su - alice` runs the full login
chain. "Variable set in /etc/profile doesn't show up" on the exam is
almost always a missing `-`.

## System-wide custom variable — the portable answer

```
echo 'export APP_ENV=prod' > /etc/profile.d/custom.sh
```

A drop-in under /etc/profile.d/ works identically on all three families
— the exam-safe answer for "set VAR for every user". Needs a login
shell (or a bashrc that is chained from it) to take effect.

## /etc/environment — pam_env

```
APP_ENV=prod
JAVA_HOME=/usr/lib/jvm/default
```

- Plain `KEY=value` lines only — no `export`, no shell syntax.
- Read by pam_env at PAM session start → applies to all PAM logins,
  including non-bash shells.

**Trap:** /etc/environment is not a script — there is no variable
expansion. `PATH=$PATH:/opt/bin` puts the literal string `$PATH` in the
value. Anything needing expansion goes in /etc/profile.d/*.sh instead.

## Per-user files

- `~/.bashrc` — aliases, functions, interactive settings
- `~/.bash_profile` / `~/.profile` — login-time exports (and chaining)
- New users receive these from /etc/skel at `useradd -m` time — see
  [local-users-and-groups.md](local-users-and-groups.md).

## Cron and ssh minimal environments

Cron jobs and ssh remote commands (`ssh host cmd`) do not run login
shells — the profile chain is skipped and the environment is minimal.
Set PATH/vars inside the crontab (or unit) itself, not in profiles:

```
PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin
0 2 * * * /usr/local/bin/backup.sh
```

## Verification (grader-style)

```
su - alice -c 'echo $APP_ENV'    # login chain → value present
su alice -c 'echo $APP_ENV'      # non-login → empty if profile-only
```

The difference between those two outputs is exactly what a grader (and
the `su` classic) tests. Re-login survivability: profile files and
/etc/environment are on-disk config re-read at every login — after a
reboot, a fresh `ssh alice@localhost 'echo $APP_ENV'` or
`su - alice -c 'env | grep APP_ENV'` must still show the value.
