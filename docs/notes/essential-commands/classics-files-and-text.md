# Essential Commands — classics: files and text

Domain: Essential Commands (supporting — implicitly tested classics).
No longer named competencies, but benchmarks show these carry real task
weight inside other tasks. No family delta: GNU
coreutils/findutils/tar behave identically on deb/rpm/suse.

## tar — create, list, extract

```
tar cf etc.tar /etc                   # create
tar czf etc.tar.gz -C / etc           # -z gzip; -C/--directory: cd first
tar cjf x.tar.bz2 dir/                # -j bzip2
tar cJf x.tar.xz dir/                 # -J xz
tar tf etc.tar.gz                     # list without extracting
tar xf etc.tar.gz                     # extract (compression auto-detected)
tar xf etc.tar.gz -C /tmp/restore     # extract elsewhere
tar xf etc.tar.gz etc/hosts           # extract a single file
```

**Trap:** single-file extraction must match the stored name exactly —
check `tar tf` first; a `./` prefix or absolute-vs-relative mismatch
makes it silently extract nothing. On create you must pick the
compression flag yourself; only extraction auto-detects.

## rsync and dd

```
rsync -a /src/dir/ /dst/dir/          # -a: perms, owners, times, links
dd if=/dev/zero of=/swapfile bs=1M count=1024 status=progress
```

**Trap:** rsync trailing slash — `src/` copies the *contents* into
dst; `src` (no slash) creates dst/src.

## find — the deep dive

```
find /var -name '*.log'               # -iname = case-insensitive
find / -xdev -type f -size +100M      # -xdev: stay on this filesystem
find /etc -mtime -7                   # modified <7 days ago (+30 = older)
find /home -user alice -type d
find /srv -size +1M -user bob -name '*.tmp'    # tests AND together
find /var/log -name '*.gz' -exec rm {} +       # + batches args (fast)
find /etc -name '*.conf' -exec grep -l PAT {} \;   # \; one exec per file
```

**Trap:** -perm semantics — `-perm 644` matches mode *exactly* 644;
`-perm -644` = "all of these bits set" (644, 755, ...); `-perm /644` =
"any of these bits". SUID hunting is always `find / -perm -4000`.

## grep and regex — BRE vs ERE

```
grep -r PATTERN /etc                  # recursive
grep -rEivl 'err(or)?' /var/log       # -E ERE, -i no-case, -v invert, -l names
grep -nw root /etc/passwd             # -n line numbers, -w whole word
```

BRE (default) vs ERE (`-E`): in BRE the metacharacters `? + { } | ( )`
are **literal** unless backslashed; ERE makes them operators —
`grep 'a\|b'` (BRE) = `grep -E 'a|b'`. When a regex "doesn't work",
try -E first.

## sed and awk

```
sed -i 's/old/new/g' file.conf        # in-place substitution, all hits
sed -i.bak 's/^#Port 22/Port 2222/' sshd_config    # keep a backup
sed -n '5,10p' file                   # print a line range
sed -i '/pattern/d' file              # delete matching lines
awk '{print $1, $3}' file             # whitespace-split columns
awk -F: '{print $1}' /etc/passwd      # -F sets the delimiter
awk -F: '$3 >= 1000 {print $1}' /etc/passwd    # condition + action
```

**Trap:** `sed -i` alone keeps no backup; `sed -i.bak` (no space)
writes file.bak first — the safe habit before editing configs.

## Text toolbox one-liners

```
sort file | uniq -c | sort -rn | head   # frequency count (uniq needs sorted)
cut -d: -f1,7 /etc/passwd
tr 'a-z' 'A-Z' < file
tr -d '\r' < dosfile > unixfile
wc -l /etc/passwd
diff -u old.conf new.conf > change.patch
patch /etc/app.conf < change.patch      # -pN strips path components
```

## Redirection

```
cmd > out.txt            # stdout (truncate); >> appends
cmd 2> err.txt           # stderr
cmd > all.txt 2>&1       # both — ORDER MATTERS
cmd &> all.txt           # bash shorthand for the same
cmd | tee out.txt        # screen + file (tee -a appends)
cmd > /dev/null 2>&1     # discard everything
cat <<'EOF' > /etc/motd  # here-doc; quoted 'EOF' = no $ expansion
text here
EOF
```

**Trap:** `cmd 2>&1 > file` does NOT capture stderr in the file — fd 2
is duplicated to the *current* stdout (terminal) before stdout is
redirected. Always `> file 2>&1`.

## Hard vs soft links

```
ln /data/file /data/hardlink       # same inode; survives deleting the original
ln -s /data/file /tmp/symlink      # path pointer; can dangle, can cross fs
ls -li                             # -i inode numbers; link count in column 3
readlink -f /tmp/symlink           # resolve to the final absolute target
find / -xdev -samefile /data/file  # locate all hardlinks to one inode
```

Hard links: same filesystem only, not for directories. A symlink's own
permissions are ignored — the target's apply.

## SUID / SGID / sticky + umask math

```
chmod 4755 /usr/local/bin/tool     # SUID: runs as file owner   (u+s)
chmod 2775 /srv/shared             # SGID dir: files inherit group (g+s)
chmod 1777 /srv/tmp                # sticky: only owner deletes   (+t)
find / -xdev -perm -4000 -type f   # audit SUID binaries
```

umask math: files start from 666, dirs from 777, minus umask.
umask 022 → 644/755; umask 027 → 640/750. Set per-session with
`umask 027`; persist via shell profile.

## Grader-style verification

```
tar tf backup.tar.gz | head              # archive holds what was asked
diff -r /srcdir /restored && echo OK     # extraction matches the source
stat -c '%h %i %n' file hardlink         # same inode, link count 2
ls -l /usr/local/bin/tool                # -rwsr-xr-x = SUID really set
umask; touch /tmp/t && stat -c '%a' /tmp/t   # umask actually applied
```
