# Essential Commands — using documentation offline

Domain: Essential Commands ("Read and use system documentation").
Everything here works without internet — the loop available on exam day.

## man -k / apropos / man -K / mandb (finding docs offline)

Useful when you know the concept but not the command name (no internet
on the exam).

- `man -k <keyword>` (alias: `apropos <keyword>`) — searches man page
  **names and one-line descriptions** for a keyword. Fast, relies on the
  prebuilt man-db index.

  ```
  man -k immutable
  # chattr(1)  - change file attributes on a Linux file system
  # lsattr(1)  - list file attributes on a Linux file system
  ```

- If `man -k` returns nothing (index missing/stale, common on minimal
  installs), rebuild the index first:

  ```
  mandb
  ```

  then retry `man -k`.
- `man -K <keyword>` (capital K) — brute-force **full-text** search
  through the body of every man page, not just names/descriptions. Slower,
  but finds hits even when the index is empty/broken or the keyword only
  appears in the body text. Prompts through each matching page.

  ```
  man -K immutable
  ```

General workflow: concept → `man -k` (or `mandb` then `man -k` if empty) →
command name → `man <command>` for full details. Fall back to `man -K`
only if `man -k` truly comes up empty after a `mandb` rebuild.

Further reading: <https://ostechnix.com/learn-use-man-pages-efficiently/>

## Offline speed toolkit — exam-legal ways to work without internet

What the official policy actually allows (verified from the
[Exam Rules and Policies](https://docs.linuxfoundation.org/tc-docs/certification/lf-handbook2/exam-rules-and-policies),
2026-11):

> Allowed: man pages; documents installed by the distribution (i.e.
> /usr/share and its subdirectories); **packages that are part of the
> distribution (may also be installed by Candidate if not available by
> default)** — as long as used to work independently, accessed from
> within the exam terminal.

> Forbidden: notes, external documentation, browsing the internet using
> installed tools such as Vim/Emacs, anything not accessible from the
> terminal.

So: everything in distro repos is fair game, including installing extra
documentation packages mid-exam. Third-party content fetched from the
internet (tldr pages, cheat.sh) is not — and is likely network-blocked
anyway.

### First 2 minutes of the exam — environment setup

Worth doing on each node you touch:

```bash
# bash-completion: subcommand/unit-name/option completion
apt install bash-completion || dnf install bash-completion
source /usr/share/bash-completion/bash_completion   # or re-login

# man page index (man -k depends on it)
mandb

# extra kernel/API/config-format man pages if missing
apt install man-db manpages || dnf install man-db man-pages
```

If a minimal image has man pages stripped (common in cloud images —
`tsflags=nodocs` in dnf.conf): reinstall the package with docs enabled:

```bash
dnf reinstall --setopt=tsflags='' <package>
```

### Tab completion — more than filenames

With bash-completion loaded, tab completes things that save real time:

- `systemctl start <tab><tab>` — completes **unit names** (no more
  guessing whether it's `sshd` or `ssh`)
- `systemctl <tab><tab>` — lists subcommands
- `ip ro<tab>`, `nmcli con <tab>`, `virsh <tab>`, `git <tab>` — subcommand
  completion for most admin tools
- `mount <tab>`, `umount <tab>` — completes devices/mountpoints
- half-remembered command names: type the prefix + `<tab><tab>`:
  `lv<tab><tab>` lists lvchange/lvcreate/lvdisplay/lvextend...; same for
  `vg`, `pv`, `se` (semanage/sestatus/setsebool...)
- `compgen -c | grep -i <fragment>` — grep every executable in PATH when
  you only remember a middle fragment of the name:

  ```bash
  compgen -c | grep -i facl     # getfacl setfacl
  compgen -c | grep -i boo      # getsebool setsebool ...
  ```

- `echo $SOME<tab>` completes variable names; `ssh <tab>` completes
  hosts from known_hosts/config

### Readline / history speed tricks

- `Ctrl+R` — reverse-search history (repeat Ctrl+R to cycle); the single
  biggest time-saver for repeated verify commands
- `!!` — rerun last command; `sudo !!` — the classic
- `!$` / `Alt+.` — last argument of previous command (Alt+. inserts it
  interactively, repeatable to go further back)
- `^old^new` — rerun last command substituting first `old` with `new`
- `Ctrl+X Ctrl+E` — open the current command line in $EDITOR (great for
  building long one-liners safely); `fc` edits the previous command
- `cp /etc/fstab{,.bak}` — brace-expansion backup before editing any
  config. Make this a reflex: backup → edit → validate
- `Ctrl+A`/`Ctrl+E`/`Ctrl+W`/`Ctrl+U` — line navigation basics

### Man pages — beyond man -k

- **Jump straight to examples:** inside man, type `/EXAMPLES` then
  Enter (`n` for next match). Or open directly at that section:

  ```bash
  man -P 'less +/^EXAMPLES' lvextend
  ```

- **Section numbers matter** — config-file formats live in section 5,
  and those pages are effectively offline reference docs with examples:

  ```bash
  man 5 fstab       man 5 crontab      man 5 sudoers
  man 5 sshd_config man 5 nsswitch.conf
  man systemd.service   # has full [Service] examples
  man systemd.unit
  ```

  List every config-format man page installed: `man -k . -s 5`

- **`man systemd.directives`** — index of *every* systemd directive and
  which man page documents it. The answer to "where is `After=`
  documented?"
- `man 8 iptables-extensions` — all the `-m`/`-j` extension modules
  (conntrack, multiport...) are documented here, not in `man iptables`
- Inside less: `&pattern` filters to only matching lines (un-filter with
  `&` + Enter) — faster than paging through a huge page
- `whatis <cmd>` / `man -f` — one-line description when you just need to
  confirm a command is the right one

### info pages — the coreutils deep docs

GNU coreutils man pages are terse summaries; the **full manuals with
worked examples** are in info:

```bash
info coreutils                     # full manual, menu-driven
info '(coreutils) chmod invocation'
info find                          # findutils full manual — rich examples
```

Navigation: `u` up, `n`/`p` next/prev node, `/` search, `q` quit. If
info's UI is hostile, `info --subnodes find | less` dumps it linearly.

### /usr/share/doc — the distro-shipped examples goldmine

Explicitly allowed by the policy. Many packages ship READMEs, sample
configs, and `examples/` directories:

```bash
ls /usr/share/doc/<package>/
ls /usr/share/doc/nftables/examples/      # Debian: ready nft rulesets
ls /usr/share/doc/netplan*/examples/      # Ubuntu: YAML examples
zless /usr/share/doc/<pkg>/README.gz      # much of it is gzipped
```

Query which doc files a package shipped, per packaging system:

```bash
rpm -qd <package>                  # RHEL: list ONLY the doc files — superb
rpm -qc <package>                  # list its config files
dpkg -L <package> | grep -i -e doc -e example   # Debian equivalent
```

### Finding the command / package you can't remember

- "Command not found — which package has it?":

  ```bash
  dnf provides '*/semanage'        # RHEL: -> policycoreutils-python-utils
  dpkg -S $(which getfacl)         # Debian: which package owns a file
  apt-file search bin/semanage     # Debian (needs: apt install apt-file; apt-file update)
  ```

  (Ubuntu's `command-not-found` handler often prints the needed package
  automatically when you mistype.)

- `dnf repoquery -l <pkg>` / `apt-file list <pkg>` — list files of a
  **not-yet-installed** package (is the tool really in there?)
- `type -a <cmd>` — builtin vs alias vs binary, and which one wins

### Templates already on disk — never write configs from scratch

- **systemd units**: copy an existing one instead of recalling syntax:

  ```bash
  systemctl cat sshd.service              # shows unit + drop-ins, with paths
  cp /usr/lib/systemd/system/sshd.service /etc/systemd/system/myapp.service
  systemctl edit --full myapp.service     # or edit the copy
  ```

- **cron**: `cat /etc/crontab` — the field-order legend is printed right
  in the file header. `man 5 crontab` has examples including shortcuts
  (`@reboot`, `@daily`).
- **fstab**: existing entries are the template; `blkid` for UUIDs.
- **SELinux contexts**: steal existing policy patterns instead of
  inventing them: `semanage fcontext -l | grep httpd` shows the exact
  pattern syntax used by the shipped policy.
- **LDAP schemas**: `/etc/ldap/schema/*.schema` (Debian) documents which
  attributes each objectClass MUST/MAY have.
- **Pristine config recovery** if you mangle a file and need the
  original:

  ```bash
  # Debian: download + extract without installing
  cd /tmp && apt download openssh-server
  dpkg-deb -x openssh-server_*.deb extracted/

  # RHEL:
  dnf download openssh-server
  rpm2cpio openssh-server*.rpm | cpio -idmv
  ```

### Config validators — check before you break (or reboot)

Same philosophy as `mount -a` after editing fstab. Run the validator
every time; a typo found at reboot/grading time is points lost:

```bash
visudo -c                        # sudoers (and visudo to edit safely at all)
sshd -t                          # sshd_config syntax; sshd -T dumps effective config
findmnt --verify                 # fstab sanity check (better than mount -a alone)
mount -a                         # does fstab actually mount
nft -c -f /etc/nftables.conf     # nftables ruleset check-only
systemd-analyze verify myapp.service
named-checkconf / named-checkzone zone file   # BIND
httpd -t / apachectl configtest  # Apache
nginx -t                         # nginx
sysctl -p                        # errors loudly on bad lines
```

## Find config templates — bulk-install doc packages (practice-VM prep)

Bulk-install every available `-doc` companion package for software
already installed (practice-VM prep; during the exam install the single
`<pkg>-doc` you need instead — bulk wastes clock on bandwidth):

```bash
# Debian/Ubuntu
comm -12 \
  <(dpkg-query -W -f '${binary:Package}\n' | sed 's/:.*$//; s/$/-doc/' | sort -u) \
  <(apt-cache pkgnames | sort -u) \
| xargs -r sudo apt-get install -y

# RHEL/Rocky (expect a smaller yield — fewer -doc splits than Debian)
comm -12 \
  <(rpm -qa --qf '%{NAME}\n' | sed 's/$/-doc/' | sort -u) \
  <(dnf -q repoquery --qf '%{name}\n' '*-doc' | sort -u) \
| xargs -r sudo dnf install -y
```

(A few packages use `-docs` plural; rerun with that suffix to be
thorough.)

If docs for already-installed packages are missing because the *image*
stripped them (not because of `-doc` splits):

```bash
# Ubuntu minimized images (check: ls /etc/dpkg/dpkg.cfg.d/excludes)
sudo unminimize                    # 24.04+: apt install unminimize first

# RHEL with tsflags=nodocs in /etc/dnf/dnf.conf
sudo dnf reinstall --setopt=tsflags='' -y '*'
```

Then survey the haul: `find /usr/share/doc -type d -name examples`

## Practice-at-home only (needs internet — NOT for the exam)

Useful now to build recall, but they fetch content from the internet at
runtime, so they're both unreachable and against policy in the exam:

- `tldr` / `tealdeer` — community example-first cheat pages (the client
  is in distro repos, but pages download from GitHub)
- `cheat.sh` (`curl cht.sh/lvextend`) — same category
- `navi` — interactive cheat-sheet runner

Train with them, but during practice sessions regularly force yourself
to answer the same questions via `man -k` + `/EXAMPLES` +
`/usr/share/doc` instead, since that's the loop available on exam day.
