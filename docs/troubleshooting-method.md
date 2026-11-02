# Troubleshooting method (no AI, exam-legal tools only)

General method for "a command/service fails mysteriously" tasks. Works for
LDAP, systemd units, mounts, networking, users/PAM — basically anything on the
exam. Two worked examples below (`ldapaddgroup` config bugs, then enabling
`slapd` TLS) were diagnosed live using exactly these steps.

## The core methodology

**1. Don't trust the tool's own error message — find the real log.**

Wrapper tools often print a useless summary ("Error adding group X to LDAP")
while the real error goes to a log. Look for:
- `journalctl -u <service> -n 50 --no-pager` or `journalctl -xe`
- Service-specific logs under `/var/log/` (check `man <service>` → **FILES**
  section, or the config file for a `LOGFILE=`-style directive)
- `systemctl status <service> -l` (`-l` avoids truncating long lines)

**2. Check if the failing command is actually a script — then read it.**

```bash
file $(which <cmd>)
head -1 $(which <cmd>)
less $(which <cmd>)
```

Anything that's a shell script you can read directly. If the logic isn't
obvious, trace its execution live:

```bash
sudo bash -x $(which <cmd>) <args>
```

`-x` prints every line and every variable's resolved value as it executes —
this alone reveals wrong/empty config variables being used.

**3. Verify the underlying service is actually there and listening.**

```bash
systemctl status <service>
sudo ss -ltnp | grep <service>
```

Confirm "is it even running, on what port" before chasing config logic.

**4. Find and read the config file(s) — don't skim them.**

- `man <command>` almost always lists the config path in **FILES**.
- `dpkg -L <package> | grep /etc` (Debian/Ubuntu) or `rpm -qc <package>`
  (RHEL/Rocky) lists every config file a package owns.
- Use `grep -n '^KEYWORD' file` to find the *active* (uncommented) line, not
  just any mention of the keyword. A careless scroll-by can miss that the
  "live" line is misspelled or shadowed by a commented-out duplicate.

**5. Test the underlying protocol/tool directly, bypassing the wrapper.**

Peel wrapper → library → protocol layer by layer to isolate where it breaks
(connectivity vs. TLS vs. credentials, etc.). Same idea applies to
`systemctl` → service → config, `mount` → fstab → block device, `useradd` →
`/etc/login.defs` → PAM.

**6. Change one thing at a time, rerun, recheck the log.**

Fix one variable, rerun, see if the error message changes — that confirms
what you just fixed and tells you what's still broken. Changing everything at
once makes it impossible to tell which fix actually mattered.

## Exam-legal tools to lean on (no internet needed)

| Tool | Use |
|---|---|
| `man <cmd>`, `man 5 <conf-file>` | official docs, FILES/EXAMPLES sections |
| `<cmd> --help` / `info <cmd>` | quick flag reference |
| `apropos <keyword>` | find commands when you don't know the exact name |
| `journalctl -u <unit> -xe` | real failure reason for systemd units |
| `systemctl status <unit> -l` | quick status + last log lines |
| `strace -f -e trace=network,open,connect <cmd>` | see every file/host a command actually touches |
| `bash -x <script>` | trace a shell script's execution and variable values |
| `dpkg -L pkg` / `rpm -qc pkg` / `rpm -ql pkg` | list a package's installed/config files |
| `diff` / `grep -n` | spot the one wrong line instead of re-reading the whole file |

The habit the exam is really testing: **read the actual error, from the
actual log, at the actual layer that failed** — not the summary message, and
not your assumption of what's configured.

## Worked example: `ldapaddgroup george` → "Error adding group george to LDAP"

Environment: Ubuntu node, `slapd` + `ldapscripts` installed and configured by
hand (not part of the lab's baseline provisioning).

1. **Surface error** (unhelpful): `Error adding group george to LDAP`.
2. **Real log** (`/var/log/ldapscripts.log`):
   `ldap_start_tls: Can't contact LDAP server (-1)`
3. **Root cause #1** — `/etc/ldapscripts/ldapscripts.conf` had
   `SERVER=ldap://ldap01.example.com`, a hostname that doesn't resolve in
   this lab. The real server was local (`slapd` listening on `0.0.0.0:389`).
   Fix: `SERVER=ldap://localhost`.
4. **Root cause #2** — `LDAPBINOPTS="-ZZ"` forces StartTLS, but `slapd` had
   no TLS certificate configured (`slapcat -n0 | grep -i tls` showed
   nothing), so StartTLS could never succeed. Fix: `LDAPBINOPTS=""`.
5. Rerunning changed the error to `ldap_bind: Invalid credentials (49)` —
   confirming steps 3-4 were fixed and narrowing the problem to auth.
6. **Root cause #3** — `grep -n '^BINDDN' ldapscripts.conf` found nothing;
   the active line was actually `BINDDDN="cn=admin,dc=example,dc=com"` (typo,
   three D's), while the correctly spelled `BINDDN` only existed commented
   out with a different, nonexistent value (`cn=Manager,...`). ldapscripts
   silently fell back to its internal default DN, which doesn't exist, so
   every bind failed with "Invalid credentials" regardless of the password.
   Fix: correct the variable name/value: `BINDDN="cn=admin,dc=example,dc=com"`.
7. Also had to resync `/etc/ldapscripts/ldapscripts.passwd` with slapd's
   actual `olcRootPW`, using the local `ldapi:///` socket + SASL `EXTERNAL`
   bind (root authenticates without a password over the Unix socket):
   ```bash
   sudo ldapwhoami -Y EXTERNAL -H ldapi:///
   HASH=$(sudo slappasswd -s 'admin123')
   ldapmodify -Y EXTERNAL -H ldapi:/// <<EOF
   dn: olcDatabase={1}mdb,cn=config
   changetype: modify
   replace: olcRootPW
   olcRootPW: $HASH
   EOF
   ```
8. After all three config fixes + password resync: `ldapaddgroup george`
   succeeded.

## Worked example: enabling `ldaps://` for `slapd`, then `ldapwhoami -ZZ` over it fails

Environment: same Ubuntu node, enabling TLS on `slapd` (self-signed CA +
server cert via `certtool`, loaded into `cn=config`).

1. **Config attributes added to `cn=config` pointed at files that didn't
   exist yet** (`olcTLSCertificateFile`/`olcTLSCertificateKeyFile`). `slapd`
   validates these paths live, so the modify failed with a generic
   `ldap_modify: Other (e.g., implementation specific) error (80)`.
   `journalctl -u slapd` showed the exact attribute names involved even
   though the client-side error gave none. Fix: actually generate the
   server key/cert with `certtool`, matching what the LDIF referenced.
2. **Permissions** — `slapd` runs as the `openldap` user/group
   (`cat /etc/default/slapd`), and `/etc/ssl/private` only grants the
   `ssl-cert` group traverse access. Needed `chgrp openldap` on the key file
   and `usermod -aG ssl-cert openldap`, then `systemctl restart slapd` —
   group membership is only re-read at process start, so a running daemon
   won't pick it up without a restart.
3. **Enabled the `ldaps:///` listener** by adding it to `SLAPD_SERVICES` in
   `/etc/default/slapd`. This file is only read at startup — editing it does
   nothing to an already-running `slapd`. Caught by comparing
   `systemctl status slapd`'s `Active: ... since <time>` against the time of
   the edit, then confirming with `sudo ss -ltnp | grep slapd` that `636`
   wasn't listening yet.
4. **After restart, port 636 was listening**, but
   `ldapwhoami -x -H ldaps://ldap01.example.com` still failed — turned out to
   be the *client's* hostname, not the server: `ldap01.example.com` doesn't
   resolve anywhere in this lab (same placeholder-hostname issue as the
   first worked example). Using the real hostname (`ubuntu-lfcs`) got past
   that.
5. **Final failure**: `ldapwhoami -x -H ldaps://ubuntu-lfcs -ZZ` still errored
   with `ldap_start_tls: Operations error (1), additional info: TLS already
   started`. Root cause: `-Z`/`-ZZ` requests the **STARTTLS extended
   operation** — upgrading an already-open plaintext connection to TLS
   in-band. That only makes sense on `ldap://` (plaintext, port 389).
   `ldaps://` (port 636) is **implicit TLS** — the handshake happens
   immediately as part of connecting, so there's no plaintext phase left to
   "start" TLS on. Asking for both at once is a contradiction, and the server
   correctly refuses. Fix: use one encryption path per connection —
   ```bash
   ldapwhoami -x -H ldap://ubuntu-lfcs  -ZZ   # STARTTLS: upgrade in-band
   ldapwhoami -x -H ldaps://ubuntu-lfcs       # implicit TLS: no -Z needed
   ```

**Takeaway beyond the specific fixes:** two config-file edits in this example
(`cn=config` TLS attrs, `/etc/default/slapd`) looked instantly "wrong"
superficially but were actually fine — the real issues were a file that
didn't exist yet, group membership not refreshed, and a service not
restarted. When an edit "doesn't work," check whether the running process
has actually picked up the new config before assuming the config itself is
wrong.
