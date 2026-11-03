# Troubleshooting method (no AI, exam-legal tools only)

General method for "a command/service fails mysteriously" tasks. Works for
LDAP, systemd units, mounts, networking, users/PAM — basically anything on the
exam. Four worked examples below (`ldapaddgroup` config bugs, enabling
`slapd` TLS, an intermittent SSH/PAM failure, and a firewalld-blocked `nc`
transfer) were diagnosed live using exactly these steps.

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

## Worked example: SSH password login fails intermittently on opensuse-lfcs

Environment: same lab, `opensuse-lfcs` node, plain `ssh user@host` with a
password (no LDAP involved this time).

1. **Surface symptom**: password login to `localhost` "just doesn't work" —
   no useful error from the client itself.
2. **Real log** (`journalctl`, same principle as every example above): auth
   actually *succeeded* — `Accepted keyboard-interactive/pam for <user>` —
   immediately followed by `fatal: PAM: pam_setcred(): Permission denied`,
   which drops the connection. So this wasn't a wrong-password problem at
   all; something broke *after* a correct password was already accepted.
3. Checked the obvious suspects first (and ruled them out one by one): group
   membership (`id <user>`), `/etc/nsswitch.conf` source (`compat`, no
   LDAP/SSSD involved), the PAM stack itself (`/etc/pam.d/sshd`,
   `common-auth`/`common-account`/`common-session` — all stock), and a
   missing `/etc/gshadow` (recreated it manually since `grpconv` wasn't even
   installed — turned out to be a red herring, didn't fix anything).
4. **`strace -f` on a one-off debug `sshd` instance** (`sudo /usr/sbin/sshd
   -d -p <port>`) pinned down the exact moment: no `EACCES`/`EPERM` on the
   process that actually logs the failure — the denial is a PAM-internal
   decision, not an OS-level permission problem on a file. That ruled out
   "just chmod something" as the fix.
5. **The deciding experiment — isolate by forcing one variable at a time.**
   Noticed the *first ever* successful password test earlier in this session
   had used `-o PreferredAuthentications=password`, while every failing
   attempt since had left the client free to pick its own method. Reran the
   identical login twice, changing only that one option:
   ```bash
   ssh -o PreferredAuthentications=password         user@host   # works, every time
   ssh -o PreferredAuthentications=keyboard-interactive user@host  # fails, every time
   ```
   That's a clean, controlled A/B test — one variable changed, result flips
   consistently — which is as close to proof as you get without reading the
   PAM module's source. Root cause confirmed: it's specifically the
   `keyboard-interactive` method (a PAM "conversation") that breaks at
   credential-establishment time on this box, not password auth itself.
6. **Why this bit without ever touching `PreferredAuthentications`**: OpenSSH
   clients try methods in this default order — `gssapi-with-mic, hostbased,
   publickey, keyboard-interactive, password`. `keyboard-interactive` is
   attempted *before* plain `password`, and the server offered it — so a
   completely ordinary `ssh host` + type-your-password login was silently
   going through the broken path the whole time, even though it looked
   identical to a normal password login from the user's side.
7. **Fix**: disable the broken method on the server so clients fall through
   to the one that works:
   ```bash
   echo 'KbdInteractiveAuthentication no' | sudo tee /etc/ssh/sshd_config.d/99-disable-kbdint.conf
   sudo sshd -t && sudo systemctl restart sshd
   ```

**Takeaway**: when two things *look* identical from the outside (a password
prompt is a password prompt, right?) but behave differently, stop guessing
and force each variant explicitly, one change at a time, until the result
flips. `-o PreferredAuthentications=`, `-o PubkeyAuthentication=no`, `-Z` vs
`ldaps://`, `TERM=x sudo ...` earlier in this doc — all the same move: pin
every variable except one, and let the behavior itself tell you which one
matters.

## Worked example: sending an SSH public key between nodes with raw `nc`

Environment: `ubuntu-lfcs` → `ubuntu2-lfcs`, manually transplanting a public
key into `authorized_keys` using only `nc`, without `ssh-copy-id`.

1. **First gotcha**: `sudo nc -l -p 5000 >> /root/.ssh/authorized_keys` failed
   with `Permission denied`, even run under `sudo`. Reason: shell redirection
   (`>>`) is set up by the *invoking, unprivileged* shell before `sudo` ever
   execs the command — only the command itself runs as root, not the
   redirect target. Fix: push the whole pipeline (command *and* redirect)
   inside `sudo bash -c '...'`, so root performs the redirection too. The
   exact same trap applies to anything like `sudo echo foo > /protected/file`.
2. **Second gotcha**: the key never arrived even once the redirection was
   fixed — `nc -vN ubuntu2-lfcs 5000` reported `No route to host`, from the
   *sender*. Ping to the same IP worked fine, ruling out basic L2/L3
   connectivity. Direct-IP vs hostname gave the identical error, ruling out
   DNS.
3. **Root cause**: `firewalld` was `active`/`enabled` on the receiving node —
   installed by the lab's own provisioning, and auto-started by the
   distro's packaging the moment it was installed, with no action needed from
   anyone. `sudo nft list ruleset` showed its default `public` zone only
   explicitly allows `tcp dport 22`; everything else falls through to
   `reject with icmpx admin-prohibited`. That specific ICMP rejection (as
   opposed to a plain dropped packet, or a port-unreachable reject) is what
   makes the *client's* TCP stack report "No route to host" instead of
   "Connection refused" — worth recognizing as a signature, since it's easy
   to mistake for a routing problem instead of a firewall one.
4. **Fix**: open the port properly with the dedicated tool instead of
   disabling the firewall —
   ```bash
   sudo firewall-cmd --add-port=5000/tcp      # before the transfer
   sudo firewall-cmd --remove-port=5000/tcp   # after — don't leave it open
   ```

**Takeaway**: "No route to host" on a TCP connect, with ICMP ping to the same
address working fine, almost always means something *between* you and the
port — a firewall reject rule — not an actual routing failure. Check
`firewall-cmd`/`nft list ruleset` before suspecting the network layer. And
remember that installing a firewall package on Debian/Ubuntu commonly
enables and starts it immediately — "I didn't configure a firewall" doesn't
mean one isn't running.
