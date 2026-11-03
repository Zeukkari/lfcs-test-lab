# LFCS Lab — Session Learning Log

A comprehensive record of everything built, broken, diagnosed, and learned in
this lab so far. Companion to [`troubleshooting-method.md`](troubleshooting-method.md)
(which has the general methodology + worked examples in depth); this document
is the chronological narrative plus a topic-by-topic knowledge summary.

---

## 1. Lab infrastructure (Vagrant + VirtualBox)

### What was built
- Five-node lab defined in one `Vagrantfile`, covering all three LFCS exam
  distro families:

  | Node | Box | IP | Family |
  |---|---|---|---|
  | `ubuntu` | bento/ubuntu-22.04 | 192.168.56.11 | Debian (apt) |
  | `opensuse` | bento/opensuse-leap-15.6 | 192.168.56.12 | SUSE (zypper) |
  | `rocky` | bento/rockylinux-9 | 192.168.56.13 | RHEL (dnf) |
  | `ubuntu2` | bento/ubuntu-22.04 | 192.168.56.14 | Debian (apt) |
  | `rocky2` | bento/rockylinux-9 | 192.168.56.15 | RHEL (dnf) |

- Each node: blank 5 GiB second disk (storage practice), host-only network
  with static IPs, `/etc/hosts` cross-resolution, a common tool baseline
  (parted/lvm2/cryptsetup, nfs/samba/cifs, firewalld/ufw, acl/quota, cron/at,
  sysstat, tcpdump...), and a `student` user with passwordless sudo.

### Lessons learned
- **Package names differ per family** for the "same" tool: `dnsutils` vs
  `bind-utils`, `cron` vs `cronie`, `nfs-common` vs `nfs-utils` vs
  `nfs-client`. The provisioning script maps them per family.
- **Rocky needs EPEL** for `htop` (hit live: `dnf install epel-release` first).
- **Debian/Ubuntu auto-enables services on package install** — installing
  `firewalld` as part of the baseline silently left it *running and
  enforcing* on every Ubuntu node. This caused multiple later failures (see
  §6). "I didn't configure a firewall" ≠ "no firewall is running."
- **Provisioning must be refreshable, not just idempotent**: the original
  `/etc/hosts` script skipped if its marker existed, so adding `ubuntu2`/
  `rocky2` later left stale hosts files on old nodes. Fixed to
  delete-and-reinsert the marker block so `vagrant provision` always
  converges.
- `sudo cmd >> file` fails when the *invoking* shell can't write the target:
  redirection is set up before `sudo` runs. Fix: `sudo bash -c 'cmd >> file'`.
- `pkill -f '<pattern>'` can kill its own parent shell if the pattern appears
  in the invoking command line (hit live over `vagrant ssh`). Safer:
  `fuser -k <port>/tcp` targets the actual listener.

---

## 2. Terminal/locale quirk: tmux on openSUSE

**Symptom:** `tset: unknown terminal type tmux-256color` on `sudo -i` inside
the opensuse VM when the outer terminal ran tmux.

**Root cause:** `TERM=tmux-256color` propagates through SSH; openSUSE's
minimal box ships only `terminfo-base` + `terminfo-screen`, which lack the
`tmux*` terminfo entries. openSUSE's `/etc/profile` runs `tset` on login,
which then fails. Ubuntu (`ncurses-term`) and Rocky (`ncurses-base`) ship the
full database and were unaffected.

**Fix:** install the full `terminfo` package on SUSE (now baked into
provisioning).

**Transferable lesson:** "same" base system across distros ships *different
subsets* of standard databases. When a terminal behaves weirdly over SSH,
check `infocmp $TERM` on the remote side.

---

## 3. OpenLDAP server (`slapd`) on ubuntu-lfcs

Built up across the session, following the Ubuntu Server docs series:

1. **`slapd` + `ldapscripts`** for POSIX user/group management in the
   directory (`dc=example,dc=com`, with `ou=People`, `ou=Groups`, users
   `john`/`george`, group `miners`).
2. **TLS** — own CA (`certtool`), server cert, `olcTLS*` attributes in
   `cn=config`, `ldaps:///` listener.
3. **Replication** — `syncrepl` provider/consumer with `ubuntu2-lfcs`.

### The `ldapaddgroup` failure (three stacked config bugs)
`sudo ldapaddgroup george` → "Error adding group george to LDAP". The real
errors were in `/var/log/ldapscripts.log`, not on screen. Root causes, found
one at a time:
1. `SERVER=ldap://ldap01.example.com` — placeholder hostname that doesn't
   resolve in this lab. → `ldap://localhost`.
2. `LDAPBINOPTS="-ZZ"` — forced StartTLS before the server had any TLS
   configured. → cleared (later re-enabled once TLS existed).
3. `BINDDDN` (typo, three D's) — the correctly-spelled `BINDDN` existed only
   commented out; ldapscripts silently fell back to a nonexistent default DN
   → persistent "Invalid credentials" regardless of password.

Plus: `ldapscripts.passwd` didn't match the actual `olcRootPW`; resynced via
the root-only `ldapi:///` + SASL EXTERNAL channel:
```bash
sudo ldapwhoami -Y EXTERNAL -H ldapi:///            # proves the channel works
HASH=$(sudo slappasswd -s 'admin123')
ldapmodify -Y EXTERNAL -H ldapi:/// <<EOF
dn: olcDatabase={1}mdb,cn=config
changetype: modify
replace: olcRootPW
olcRootPW: $HASH
EOF
```

### TLS setup lessons
- **Error 80 (`Other error`) on `ldapmodify` of `olcTLS*` attrs** usually
  means the referenced cert/key files don't exist or aren't readable —
  `slapd` validates paths live. `journalctl -u slapd` names the attributes.
- `slapd` runs as `openldap`; key files need `chgrp openldap` + mode 0640,
  and `/etc/ssl/private` requires `ssl-cert` group membership — which is only
  picked up on service restart.
- `/etc/default/slapd` (`SLAPD_SERVICES="ldap:/// ldapi:/// ldaps:///"`) is
  read **only at startup**. Editing it does nothing until
  `systemctl restart slapd`. Check `systemctl status` start time vs your edit
  time.
- **Cert CN/SAN must match the hostname clients actually use.** The guide's
  `cn = ldap01.example.com` was replaced with the lab's real hostname
  (`cn = ubuntu-lfcs`, SANs `ubuntu-lfcs` + `localhost`). A stale cert with
  `CN=opensuse-lfcs` on ubuntu2 was caught *before* it broke replication —
  verified with the A/B test `ldapwhoami -ZZ` vs
  `LDAPTLS_REQCERT=allow ldapwhoami -ZZ` (only the verification-off variant
  worked → hostname mismatch, not trust failure).
- **`-Z`/`-ZZ` (StartTLS) is only for `ldap://`** (plain, port 389, upgraded
  in-band). `ldaps://` (port 636) is implicit TLS — combining them yields
  `TLS already started`. One encryption path per connection.
- The CA's private key lives only on the CA host (`ubuntu-lfcs`). Signing a
  consumer's cert happens *there*; only the signed cert + its own key move to
  the consumer. The CA *certificate* is public and can be distributed by any
  channel.

### Replication (`syncrepl`) lessons
- Consumer config was still factory-default (`olcSuffix: dc=nodomain`, no
  `olcRootDN` for the real tree) — had to be fixed before `syncrepl` could
  deliver anything. "Installed" ≠ "configured to match the provider."
- Setup: replication user (`cn=replicator`, `simpleSecurityObject` +
  `organizationalRole`, placeholder `userPassword: {CRYPT}x` overwritten via
  `ldappasswd`), ACL `{0}` rule + unlimited `olcLimits` on the provider,
  `syncprov` overlay + `entryCSN`/`entryUUID` indexes, consumer `olcSyncrepl`
  (`rid`, `provider=`, `starttls=critical tls_reqcert=demand`,
  `type=refreshAndPersist retry="60 +"`) + `olcUpdateRef`.
- **ACL ordering matters** — the replicator rule must be inserted at `{0}`
  with `by * break` so later rules still apply to everyone else; OpenLDAP
  renumbers the rest automatically.
- **Verification is `contextCSN` equality** on provider + consumer:
  ```bash
  ldapsearch -z1 -LLL -x -s base -b dc=example,dc=com contextCSN
  ```
- First sync attempt failed: `ldap_start_tls failed (-1)` in the consumer's
  journal. Cause: the **provider's** firewall had never had LDAP opened —
  every prior test had been from the provider to itself, so the hole was
  invisible until the first genuinely external client appeared.

### `cn=config` vocabulary (etymology summary)
- `olc*` = OpenLDAP Configuration attribute namespace.
- `olcDatabase={N}suffix` — `{N}` is ordered-index notation (also used inside
  `olcAccess` values); `{-1}frontend` (catch-all), `{0}config` (config DB
  itself), `{1}mdb` (your data).
- `mdb` = Memory-mapped DB backend, built on LMDB (successor to the
  BerkeleyDB-based `bdb`/`hdb`).
- `cn=config` tree = runtime-modifiable replacement for flat `slapd.conf`.
- SASL EXTERNAL identity
  `gidNumber=0+uidNumber=0,cn=peercred,cn=external,cn=auth`: synthetic DN
  representing "root, proven by Unix socket peer credentials"; `+` joins a
  multi-valued RDN.
- `ldapi://` = LDAP over IPC (Unix socket). `-H` = URI, `-b` = search base,
  `-Q` = SASL quiet, `-LLL` = LDIF minus comments minus version banner,
  `-Y` = SASL mechanism.

---

## 4. SSH topics

### Password login failing on opensuse (keyboard-interactive/PAM)
- Symptom: password SSH to localhost failed; password was *correct*.
- Journal showed `Accepted keyboard-interactive/pam` **then**
  `fatal: PAM: pam_setcred(): Permission denied` — post-auth failure, not bad
  credentials.
- Isolated with a controlled A/B test:
  `-o PreferredAuthentications=password` worked every time;
  `keyboard-interactive` failed every time.
- OpenSSH client default order tries `keyboard-interactive` *before*
  `password`, so ordinary-looking password logins silently used the broken
  path.
- Fix: `KbdInteractiveAuthentication no` in
  `/etc/ssh/sshd_config.d/99-disable-kbdint.conf`, `sshd -t`, restart.

### `ssh-copy-id` internals
- It's a plain POSIX shell script. Core behavior ≈
  `cat key.pub | ssh user@host 'umask 077; mkdir -p ~/.ssh; cat >> ~/.ssh/authorized_keys'`
  plus: picks newest `id*.pub` (or agent keys), pre-checks which keys already
  work, handles trailing newlines/SELinux `restorecon`.
- **Trust must bootstrap from something you already have** (password, another
  key, Kerberos...). No tool manufactures trust from nothing.

### Moving a public key without ssh (nc exercise)
- Receiver: `sudo bash -c 'nc -l -p 5000 >> /root/.ssh/authorized_keys'`;
  sender: `cat key.pub | nc -N host 5000` (`-N` = shutdown socket on stdin
  EOF — without it the transfer never "finishes").
- Honest framing: in this lab we *already had* root on both machines via
  Vagrant, so `sudo tee -a` was the simpler answer. Raw `nc` is the right
  tool only when SSH is entirely unavailable but some out-of-band command
  execution exists (console, cloud user-data, first-boot provisioning).
- Public keys are public: the transfer needs integrity in theory but not
  confidentiality; `ssh-copy-id` is still strictly better when available
  (encrypted, server-authenticated, client-authenticated).

---

## 5. netcat (nc) toolbox

Verified-in-lab patterns:
- **Port test:** `nc -zv host 20-25` (and `-u` for UDP).
- **File transfer:** `nc -l -p PORT > out` ⟷ `nc -N host PORT < in`.
- **Directory transfer:** `nc -l -p PORT | tar xzf -` ⟷
  `tar czf - -C dir . | nc -N host PORT`.
- **Speak HTTP by hand:**
  `printf 'GET / HTTP/1.0\r\nHost: h\r\n\r\n' | nc -w2 host 8000`.
- `-k` keeps a listener alive across connections; mkfifo relay ≈ crude proxy.
- **`nc` is not one program**: Ubuntu ships OpenBSD netcat (no `-e`, by
  design), Rocky ships Nmap Ncat (has `-e`/`--sh-exec`), openSUSE ships
  nothing by default. Check `nc -h` before assuming flags.

---

## 6. firewalld — the recurring villain

Three separate failures this session had the identical signature:

> **TCP connect says `No route to host`, but ping works** → it's a firewall
> reject (`reject with icmpx admin-prohibited` in nftables), *not* routing.

1. `nc` key transfer to ubuntu2 port 5000 — blocked.
2. `nc`/socket to ubuntu2 port 389 (slapd) — blocked.
3. **syncrepl from ubuntu2 → ubuntu provider port 389 — blocked** (the
   provider's own firewall had simply never been opened; all earlier tests
   were loopback).

Correct responses, in order of preference:
```bash
sudo firewall-cmd --get-services               # look for a named service
sudo firewall-cmd --info-service=ldap          # see what it opens (389/tcp)
sudo firewall-cmd --add-service=ldap --permanent && sudo firewall-cmd --reload
# raw ports only when no named service exists:
sudo firewall-cmd --add-port=5000/tcp          # runtime only; --permanent + --reload to persist
```
Named services are self-documenting in `--list-services` output; prefer them.

Test reachability from the *other* side of the firewall (`nc -zv`), because
loopback tests bypass the problem entirely.

---

## 7. Certificates and trust stores

- **PEM vs DER is content; `.crt`/`.pem`/`.cer` is only naming.** Verified:
  the lab's `mycacert.crt` is PEM inside, byte-identical to its `.pem`
  symlink.
- **But Debian's `update-ca-certificates` only scans
  `/usr/local/share/ca-certificates/*.crt`** — verified empirically: the same
  content named `.pem` in that directory is silently ignored ("0 added").
- Per-distro trust stores:

  | Distro | Anchor dir | Command | Extension-sensitive? |
  |---|---|---|---|
  | Ubuntu/Debian | `/usr/local/share/ca-certificates/` | `update-ca-certificates` | yes, `.crt` only |
  | Rocky/RHEL | `/etc/pki/ca-trust/source/anchors/` | `update-ca-trust extract` | no |
  | openSUSE | `/etc/pki/trust/anchors/` | `update-ca-certificates` (p11-kit) | no |

- Current distribution state: CA cert present on `ubuntu` (origin) and
  `ubuntu2`; **not yet** on rocky/rocky2/opensuse (needed for SSSD phase).
- Fingerprint for verification when distributing:
  `sha256: DD:E1:FA:2B:...:C8:CE:B2` — compare with
  `openssl x509 -noout -fingerprint -sha256`.

---

## 8. Centralized user management — SSSD, built and verified on three clients

Decision made: **SSSD everywhere** (works identically on all three families;
`nslcd` is Debian-only). Clients configured: `rocky`, `rocky2`, `ubuntu2`.

What was actually done:
3. Distributed + trusted `mycacert.pem`/`.crt` on each client (see §7 table
   for the distro-specific anchor dirs/commands).
4. `sssd.conf` on each: `id_provider = ldap`,
   `ldap_uri = ldap://ubuntu-lfcs, ldap://ubuntu2-lfcs` (replication = real
   failover), `ldap_search_base = dc=example,dc=com`,
   `ldap_id_use_start_tls = true`, `ldap_tls_reqcert = demand`. Root-owned
   mode 0600 (confirmed required — sssd just needs the file to exist and be
   syntactically valid to start; the *backend* going offline, below, is a
   separate, later-stage failure).
5. NSS/PAM wiring differs by family: `authselect select sssd with-mkhomedir`
   (Rocky) vs `pam-auth-update` (Ubuntu) — both applied.
6. Tested NSS first (`id john`, `getent passwd john`), confirmed working on
   all three nodes after the fix below.
7. **Not yet done**: `ldap_access_filter` restriction — right now every
   directory user can log into every client. Deliberately deferred, not
   forgotten.

### The bug: `id john` returned nothing on all three clients

`systemctl is-active sssd` said `active` everywhere — the daemon was *up*,
just non-functional. `journalctl -u sssd` on each showed the real story:
```
sssd_be: Could not start TLS encryption.
sssd_be: Backend is offline
sssd.dataprovider.getAccountInfo: Error: SSSD is offline
```
i.e. `id`/`getent` weren't failing to find `john` — they were failing to ask
*at all*, because the backend couldn't even connect.

**Root cause — a config-file comment that wasn't a comment.** The example
`sssd.conf` handed over for copy-paste had included an inline advisory note
on the same line as a value:
```
ldap_tls_cacert = /etc/ssl/certs/mycacert.pem   # path will differ per distro trust store, verify it
```
`sssd.conf` is an INI-style file parsed by `libini_config`, which — unlike
shell or Python — **does not support trailing comments after a value on the
same line**. Only whole lines starting with `#`/`;` are comments. The
*entire remaining string, comment included*, became the literal value of
`ldap_tls_cacert`. Confirmed directly:
```bash
sudo grep -n ldap_tls_cacert /etc/sssd/sssd.conf | cat -A
# ldap_tls_cacert = /etc/ssl/certs/mycacert.pem   # path will differ per distro trust store, verify it$
```
That string is obviously not a valid file path on any system — hence "Could
not start TLS encryption" identically on all three nodes, even on `ubuntu2`
where the *base* path (before the comment got glued on) was actually
correct.

**Second, independent issue on Rocky/Rocky2**: even with the comment
stripped, `/etc/ssl/certs/mycacert.pem` is a *Debian* convention path — it
genuinely doesn't exist on Rocky. `update-ca-trust extract` had correctly
run and the CA *was* trusted system-wide (verified:
`grep 'Example Company' /etc/pki/tls/certs/ca-bundle.crt` found it), but
`sssd.conf`'s `ldap_tls_cacert` still needs an explicit, *correct-for-this-
distro* path — trusting a CA system-wide doesn't automatically mean every
app config that hardcodes a cert path will find it. Fixed by pointing at
Rocky's actual system bundle: `/etc/pki/tls/certs/ca-bundle.crt`.

**Fix (all three nodes):**
```bash
# ubuntu2 — just strip the bogus comment, path itself was right:
sudo sed -i 's|ldap_tls_cacert = .*|ldap_tls_cacert = /etc/ssl/certs/mycacert.pem|' /etc/sssd/sssd.conf
# rocky / rocky2 — also needed the distro-correct bundle path:
sudo sed -i 's|ldap_tls_cacert = .*|ldap_tls_cacert = /etc/pki/tls/certs/ca-bundle.crt|' /etc/sssd/sssd.conf
sudo systemctl restart sssd
```
After the fix, `journalctl -u sssd` showed clean startup with no TLS/offline
errors, and `id john` / `getent passwd john` resolved correctly
(`uid=10000(john) gid=5000(miners) ...`) on all three clients.

**Useful diagnostic discovered along the way**: manually reproducing exactly
what the backend needs (`ldapwhoami -x -ZZ -H ldap://<uri>`) succeeded the
whole time on the affected nodes — proof the problem was specifically in
*sssd's own config*, not connectivity/firewall/cert-trust in general. When a
purpose-built daemon fails but the equivalent manual command succeeds,
suspect the daemon's own config file next, not the underlying service.

Known environment facts checked in advance of this phase (still relevant,
kept for reference):
- SELinux on rocky/rocky2: **Enforcing**; LDAP/SSSD-related booleans are off
  by default (`authlogin_nsswitch_use_ldap`, `sssd_connect_all_unreserved_ports`).
  Neither turned out to be needed here — SSSD's own confined domain handled
  the LDAP networking fine once the config itself was correct. Expected
  workflow if something *does* get denied: `ausearch -m avc -ts recent` →
  `audit2why` → act on the actual denial, not a pre-emptive guess.
- AppArmor: active+enforcing on Ubuntu nodes (slapd profile already covers
  `/etc/ldap/**` and standard ssl abstractions; `sssd` processes run
  unconfined — confirmed via `aa-status`, no profile applied, so it was never
  a suspect here). On opensuse the kernel module is enabled but the service
  is inactive and `/etc/apparmor.d` doesn't exist — install/enable before
  practicing there.
- ACLs (`setfacl`/`getfacl`) work out of the box on ubuntu and rocky.

---

## 9. Cross-cutting habits (the actual exam skills)

1. **Read the real log, not the surface error** — `journalctl -u`,
   service-specific logs, `-d 1` debug flags, `sshd -d`, `nslcd -n -d`.
2. **A/B isolation: change exactly one variable** —
   `PreferredAuthentications`, `LDAPTLS_REQCERT`, `-Z` vs `ldaps://`,
   `TERM=`. The flip tells you which variable matters.
3. **Wrapper tools are often shell scripts — read or trace them**
   (`file $(which cmd)`, `bash -x`).
4. **"No route to host" + working ping = firewall**, check
   `firewall-cmd`/`nft list ruleset` before routing.
5. **Config edits don't apply to running daemons** — compare service start
   time with edit time (`/etc/default/slapd`, group membership, sshd config).
6. **Test from the right vantage point** — loopback success proves nothing
   about external reachability (provider firewall, §6.3).
7. **Verify, don't assume** — `contextCSN` equality for replication,
   `getent` for NSS, `nc -zv` for ports, `openssl x509` for cert identity,
   fingerprints for file distribution.
8. **Trust bootstraps from existing access** — every credential-installation
   method (ssh-copy-id, nc, sudo tee, console) differs only in which
   pre-existing channel it rides on.
9. **Distros differ in packaging, not fundamentals** — package names, nc
   implementations, terminfo coverage, trust-store conventions, PAM wiring
   tools (`pam-auth-update` vs `authselect`), MAC systems (AppArmor vs
   SELinux). The underlying mechanics are the same; learn the mapping table.
