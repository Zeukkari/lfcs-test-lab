# Users and Groups — ACLs (setfacl / getfacl)

Domain: Users and Groups ("Configure and manage ACLs"). The lab's spare
disk and any ext4/xfs filesystem work for practicing these.

ACLs let you grant permissions to specific users/groups beyond the
standard owner/group/other model, without changing actual ownership.

## Prerequisites

- Filesystem must be mounted with `acl` support (ext4 has it on by
  default on modern kernels; older systems may need `mount -o remount,acl /path`
  or an `acl` option in `/etc/fstab`).
- Package: `acl` (Debian/Ubuntu) — usually preinstalled, but note for
  minimal containers/VMs.

## getfacl — view ACLs

```
getfacl file.txt
```

Example output:

```
# file: file.txt
# owner: alice
# group: alice
user::rw-
user:bob:r--
group::r--
group:devs:rw-
mask::rw-
other::r--
```

- `user::` / `group::` / `other::` — the standard permission bits (same as `ls -l`)
- `user:bob:r--` — a named-user ACL entry
- `group:devs:rw-` — a named-group ACL entry
- `mask::` — the effective rights mask; **caps** all named user/group
  entries (and the owning group entry) to at most these bits, regardless
  of what the entry itself grants. Easy to forget and a common exam trap.

Useful flags:

- `getfacl -R dir/` — recursive
- `getfacl --omit-header file.txt` — skip the `# file/owner/group` comment lines (useful for scripting/diffing)

## setfacl — set/modify ACLs

Add or modify an entry:

```
setfacl -m u:bob:rwx file.txt       # named user
setfacl -m g:devs:rx file.txt       # named group
setfacl -m o::r file.txt            # other
setfacl -m u::rwx file.txt          # owner
```

Remove a specific entry:

```
setfacl -x u:bob file.txt
```

Remove all ACL entries (back to plain permission bits):

```
setfacl -b file.txt
```

Recursive (apply to a directory tree):

```
setfacl -R -m u:bob:rwx /some/dir
```

Default ACLs (inherited by new files/subdirs created inside a directory —
only meaningful on directories):

```
setfacl -d -m u:bob:rwx /some/dir     # set default ACL
setfacl -m d:u:bob:rwx /some/dir      # equivalent alternate syntax
getfacl /some/dir                     # default: entries shown separately
setfacl -k /some/dir                  # remove only the default ACL
```

- Without `-d`/default ACL, new files created inside a dir do **not**
  inherit the ACL — only the dir itself has it.
- `setfacl -m` on a file always recalculates and updates the `mask::`
  entry automatically unless you pass `--no-mask` / explicitly set `m::`.

Copy ACLs between files:

```
getfacl src.txt | setfacl --set-file=- dest.txt
```

## Checking "does this file have an ACL at all"

`ls -l` shows a trailing `+` on the permission string when extra ACL
entries exist:

```
-rw-rwxr--+ 1 alice alice 0 Oct 31 10:00 file.txt
```

No `+` = plain permission bits only, no named ACL entries.

## Gotchas / exam traps

- The `mask::` entry silently limits effective permissions — if you add
  `setfacl -m u:bob:rwx` but mask is `r--`, bob effectively only gets
  read, not read/write/execute. Check `getfacl` output, not just your
  `setfacl` command, to confirm effective permissions.
- `setfacl -m` recalculates the mask by default — use `setfacl -m -n` (no-mask)
  if you need to preserve an existing custom mask when adding an entry.
- Directories need `-d` (default ACL) for inheritance to new children;
  existing children are unaffected by changes to the default ACL.
- `cp` preserves ACLs only with `--preserve=all` (or `-a`); plain `cp`
  drops them. `mv` within the same filesystem preserves ACLs; across
  filesystems it behaves like `cp` + `rm`.
- `tar` needs `--acls` to preserve ACLs in an archive.
- Numeric UID/GID form also works: `setfacl -m u:1001:rwx file.txt`.
