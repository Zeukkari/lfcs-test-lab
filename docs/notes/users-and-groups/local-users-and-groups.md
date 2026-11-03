# Users and Groups — Local Users and Groups

Domain: Users and Groups ("Create and manage local user and group
accounts").

## useradd

```
useradd -m -s /bin/bash -G wheel -u 1234 -e 2026-12-31 alice
passwd alice
useradd -r svc1               # system account: low UID, no aging, no home unless -m
```

| | deb | rpm | suse |
| --- | --- | --- | --- |
| Home created by default | **no — pass `-m`** | yes (`CREATE_HOME yes` in login.defs) | yes |
| Convenience wrapper | `adduser` (interactive) | — | — |
| Admin group for sudo | `sudo` | `wheel` | `wheel` (but see targetpw trap) |

**Trap:** on Debian/Ubuntu a plain `useradd alice` creates no home
directory. Habit: always `useradd -m` (rpm/suse tolerate the redundancy).

Defaults:

```
useradd -D                    # view: shell, skel, inactive, expire
useradd -D -s /bin/bash       # change a default
cat /etc/default/useradd      # same data on disk
grep -E 'UID_MIN|UMASK|PASS_MAX_DAYS|ENCRYPT_METHOD|CREATE_HOME' /etc/login.defs
```

- `/etc/default/useradd` — default shell, skel dir, inactive days
- `/etc/login.defs` — UID_MIN, UMASK, PASS_MAX_DAYS, ENCRYPT_METHOD

### /etc/skel

Copied into the home dir at `useradd -m` time. Classic template task:

```
echo 'export EDITOR=vim' > /etc/skel/.custom
useradd -m bob
ls -la /home/bob/.custom      # grader check: file landed
```

Existing users are not retrofitted — skel applies at creation only.
Startup-file chains: [environment-profiles.md](environment-profiles.md).

## usermod

```
usermod -aG devs alice            # APPEND supplementary group
usermod -s /usr/sbin/nologin alice
usermod -e 2026-12-31 alice       # account expiry date
usermod -f 7 alice                # inactive days after password expiry
usermod -d /srv/alice -m alice    # move home with contents
```

**Trap:** `usermod -G devs alice` without `-a` REPLACES the entire
supplementary group list — alice silently leaves every other group.
Always `-aG`, then verify with `id alice`.

### Lock / unlock

```
usermod -L alice       # prefix ! to the shadow hash
usermod -U alice
passwd -l alice        # same mechanism (! in shadow)
passwd -u alice
passwd -S alice        # status: L = locked, P = usable password
passwd -e alice        # expire password now (≈ chage -d 0)
```

Locking blocks password auth only — an SSH key still works (man
passwd). To shut the account fully, also `chage -E 0 alice` or set the
shell to nologin.

## chage — aging matrix

```
chage -l alice                  # list policy — grader runs this
chage -M 30 -m 7 -W 5 alice     # max 30d, min 7d, warn 5d
chage -E 2026-12-31 alice       # account expiry (hard cut-off)
chage -d 0 alice                # force password change at next login
```

`chage -d 0` is the canonical "must change password at first login"
answer.

## Groups

```
groupadd -g 5000 devs
groupmod -n developers devs     # rename
groupdel developers
gpasswd -a alice devs           # add member (≈ usermod -aG devs alice)
gpasswd -d alice devs           # remove member
newgrp devs                     # new shell with devs as primary group
```

## sudoers

Always edit through `visudo` — it syntax-checks before install:

```
visudo                          # edits /etc/sudoers
visudo -f /etc/sudoers.d/alice  # edit a drop-in, still syntax-checked
visudo -cf /etc/sudoers.d/alice # check-only existing file
```

Rule syntax:

```
alice ALL=(ALL) NOPASSWD: /usr/bin/systemctl restart nginx
%devs ALL=(root) /usr/bin/less
```

**Trap:** `/etc/sudoers.d/` drop-ins need mode 0440 and a filename with
no dots, or sudo ignores them.

**Trap (suse, low exam ROI):** openSUSE ships `Defaults targetpw` in
/etc/sudoers — sudo asks for *root's* password, not the caller's, until
that line is removed/overridden. wheel membership alone does not give
the expected deb/rpm behavior.

## Verification (grader-style)

```
id alice                   # uid, gid, all groups
getent passwd alice        # account resolves (files or NSS source)
getent group devs          # member list
chage -l alice             # aging policy
passwd -S alice            # lock status
sudo -l -U alice           # effective sudo rules
su - alice -c 'id'         # account actually usable
```

All state is file-backed (/etc/passwd, shadow, group, sudoers) — it
survives reboot by construction. Group changes apply at next login, not
to running sessions: re-run `id` from a fresh `su - alice` / ssh login
to prove membership took effect.
