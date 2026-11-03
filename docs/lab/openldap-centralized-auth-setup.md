# Setting up OpenLDAP for centralized Linux user management

A clean, reproducible write-up of what we actually built in this lab: an
OpenLDAP **provider** + **replica (consumer)** pair serving POSIX user/group
data, secured with TLS, and consumed by **SSSD** on multiple client distros
for centralized Linux authentication (`id`/`getent`/`ssh` all resolving
directory accounts).

This is the "how to do it correctly" version. For the blow-by-blow of what
broke and how it was diagnosed, see
[`learning-log.md`](learning-log.md) and
[`troubleshooting-method.md`](troubleshooting-method.md).

## Architecture

```
ubuntu-lfcs   (192.168.56.11)  — Provider: slapd, dc=example,dc=com, also the CA
ubuntu2-lfcs  (192.168.56.14)  — Consumer/replica: syncrepl from the provider
rocky-lfcs    (192.168.56.13)  — SSSD client (NSS+PAM only, no local LDAP data)
rocky2-lfcs   (192.168.56.15)  — SSSD client
ubuntu-lfcs + ubuntu2-lfcs     — also configured as SSSD clients of themselves,
                                  so the directory servers resolve their own
                                  LDAP-backed logins too
```

Base DN throughout: `dc=example,dc=com`, with `ou=People` and `ou=Groups`
underneath.

---

## Part 1 — Base LDAP server (provider: `ubuntu-lfcs`)

```bash
sudo apt install -y slapd ldap-utils ldapscripts
```

During `slapd` install (or via `dpkg-reconfigure slapd`), set the base DN to
`dc=example,dc=com`. Create the two organizational units:

```bash
cat > /tmp/base.ldif <<'EOF'
dn: ou=People,dc=example,dc=com
objectClass: organizationalUnit
ou: People

dn: ou=Groups,dc=example,dc=com
objectClass: organizationalUnit
ou: Groups
EOF
sudo ldapadd -Q -Y EXTERNAL -H ldapi:/// -f /tmp/base.ldif
```

### Managing users/groups: `ldapscripts`

```bash
sudo apt install -y ldapscripts
```

Edit `/etc/ldapscripts/ldapscripts.conf`:
```ini
SERVER=ldap://localhost
LDAPBINOPTS=""
BINDDN="cn=admin,dc=example,dc=com"
BINDPWDFILE="/etc/ldapscripts/ldapscripts.passwd"
SUFFIX="dc=example,dc=com"
GSUFFIX="ou=Groups"
USUFFIX="ou=People"
```

```bash
echo -n 'admin123' | sudo tee /etc/ldapscripts/ldapscripts.passwd
sudo chmod 400 /etc/ldapscripts/ldapscripts.passwd
```

> ⚠️ **Watch the exact variable name.** `BINDDN` (two D's), not `BINDDDN`.
> The stock config file ships this line *commented out*; if you add your own
> copy with a typo, `ldapscripts` silently falls back to a nonexistent
> default DN and every operation fails with "Invalid credentials" regardless
> of the password — see the gotchas table at the end.

```bash
sudo ldapaddgroup george
sudo ldapadduser george george
sudo ldapsetpasswd george
```

---

## Part 2 — TLS (on the provider)

```bash
sudo apt install -y gnutls-bin ssl-cert
```

**CA (self-signed, acts as the CA for everything in this lab):**
```bash
sudo certtool --generate-privkey --bits 4096 --outfile /etc/ssl/private/mycakey.pem

cat > /etc/ssl/ca.info <<'EOF'
cn = Example Company
ca
cert_signing_key
expiration_days = 3650
EOF

sudo certtool --generate-self-signed \
  --load-privkey /etc/ssl/private/mycakey.pem \
  --template /etc/ssl/ca.info \
  --outfile /usr/local/share/ca-certificates/mycacert.crt

sudo update-ca-certificates
```
This creates a `/etc/ssl/certs/mycacert.pem` symlink automatically.

**Server certificate** — ⚠️ **CN/SAN must match the real hostname you'll
connect to**, not a placeholder:
```bash
sudo certtool --generate-privkey --bits 2048 --outfile /etc/ldap/ldap01_slapd_key.pem

cat > /etc/ssl/ldap01.info <<'EOF'
organization = Example Company
cn = ubuntu-lfcs
dns_name = ubuntu-lfcs
dns_name = localhost
tls_www_server
encryption_key
signing_key
expiration_days = 365
EOF

sudo certtool --generate-certificate \
  --load-privkey /etc/ldap/ldap01_slapd_key.pem \
  --load-ca-certificate /etc/ssl/certs/mycacert.pem \
  --load-ca-privkey /etc/ssl/private/mycakey.pem \
  --template /etc/ssl/ldap01.info \
  --outfile /etc/ldap/ldap01_slapd_cert.pem

sudo chgrp openldap /etc/ldap/ldap01_slapd_key.pem
sudo chmod 0640 /etc/ldap/ldap01_slapd_key.pem
```

**Wire it into `slapd`:**
```bash
cat > /tmp/certinfo.ldif <<'EOF'
dn: cn=config
add: olcTLSCACertificateFile
olcTLSCACertificateFile: /etc/ssl/certs/mycacert.pem
-
add: olcTLSCertificateFile
olcTLSCertificateFile: /etc/ldap/ldap01_slapd_cert.pem
-
add: olcTLSCertificateKeyFile
olcTLSCertificateKeyFile: /etc/ldap/ldap01_slapd_key.pem
EOF
sudo ldapmodify -Y EXTERNAL -H ldapi:/// -f /tmp/certinfo.ldif
```

> ⚠️ **Files must already exist before this step, and `openldap` must be able
> to read the key.** `slapd` validates these paths live; a missing file or a
> key unreadable by the `openldap` user/group produces a generic
> `ldap_modify: Other error (80)` with no useful detail. Also:
> `/etc/ssl/private` only grants traverse access to the `ssl-cert` group —
> `sudo usermod -aG ssl-cert openldap` then **restart slapd** (group
> membership is only re-read at process start).

Test:
```bash
ldapwhoami -x -ZZ -H ldap://ubuntu-lfcs   # StartTLS — anonymous
```

---

## Part 3 — Replication (consumer: `ubuntu2-lfcs`)

```bash
sudo apt install -y slapd ldap-utils gnutls-bin
```

### Fix the consumer's default suffix first

A fresh `slapd` install ships with a placeholder `olcSuffix: dc=nodomain`.
This **must** be changed to match the provider before `syncrepl` will work —
otherwise the consumer's `searchbase` in the sync config won't align with
anything it actually serves.

```bash
NEWHASH=$(sudo slappasswd -s 'admin123')
cat > /tmp/fix-suffix.ldif <<EOF
dn: olcDatabase={1}mdb,cn=config
changetype: modify
replace: olcSuffix
olcSuffix: dc=example,dc=com
-
replace: olcRootDN
olcRootDN: cn=admin,dc=example,dc=com
-
replace: olcRootPW
olcRootPW: $NEWHASH
EOF
sudo ldapmodify -Q -Y EXTERNAL -H ldapi:/// -f /tmp/fix-suffix.ldif
```

### Consumer's own TLS cert

Same process as Part 2, but **signed by the provider's CA** (the CA private
key only lives on the provider — generate the consumer's keypair+cert there,
then copy both files over):

```bash
# on ubuntu-lfcs:
cat > /tmp/ldap02.info <<'EOF'
organization = Example Company
cn = ubuntu2-lfcs
dns_name = ubuntu2-lfcs
dns_name = localhost
tls_www_server
encryption_key
signing_key
expiration_days = 365
EOF
sudo certtool --generate-privkey --bits 2048 --outfile /tmp/ldap02_slapd_key.pem
sudo certtool --generate-certificate \
  --load-privkey /tmp/ldap02_slapd_key.pem \
  --load-ca-certificate /etc/ssl/certs/mycacert.pem \
  --load-ca-privkey /etc/ssl/private/mycakey.pem \
  --template /tmp/ldap02.info \
  --outfile /tmp/ldap02_slapd_cert.pem

scp /tmp/ldap02_slapd_key.pem /tmp/ldap02_slapd_cert.pem root@ubuntu2-lfcs:/etc/ldap/
```
```bash
# on ubuntu2-lfcs:
sudo chgrp openldap /etc/ldap/ldap02_slapd_key.pem
sudo chmod 0640 /etc/ldap/ldap02_slapd_key.pem
sudo cp /etc/ssl/certs/mycacert.pem /usr/local/share/ca-certificates/mycacert.crt
sudo update-ca-certificates
# wire into cn=config the same way as Part 2 (olcTLSCACertificateFile/Certificate/Key)
```

> ⚠️ **CN/SAN must say `ubuntu2-lfcs`, specifically** — reusing a cert
> generated for a different host (even a valid, CA-trusted one) causes
> `StartTLS` to fail with hostname verification errors that look nothing
> like a naming problem on the surface.

### Replication user (on the provider)

```bash
cat > /tmp/replicator.ldif <<'EOF'
dn: cn=replicator,dc=example,dc=com
objectClass: simpleSecurityObject
objectClass: organizationalRole
cn: replicator
description: Replication user
userPassword: {CRYPT}x
EOF
sudo ldapadd -Q -Y EXTERNAL -H ldapi:/// -f /tmp/replicator.ldif

ldappasswd -x -ZZ -H ldap://ubuntu-lfcs \
  -D cn=admin,dc=example,dc=com -w admin123 \
  -s 'ReplSecret123!' cn=replicator,dc=example,dc=com
```

### ACL + limits for the replicator (on the provider)

```bash
cat > /tmp/replicator-acl-limits.ldif <<'EOF'
dn: olcDatabase={1}mdb,cn=config
changetype: modify
add: olcAccess
olcAccess: {0}to *
  by dn.exact="cn=replicator,dc=example,dc=com" read
  by * break
-
add: olcLimits
olcLimits: dn.exact="cn=replicator,dc=example,dc=com"
  time.soft=unlimited time.hard=unlimited
  size.soft=unlimited size.hard=unlimited
EOF
sudo ldapmodify -Q -Y EXTERNAL -H ldapi:/// -f /tmp/replicator-acl-limits.ldif
```

> ⚠️ **Ordering matters.** Inserting at `{0}` with `by * break` grants the
> replicator blanket read (including `userPassword`, needed to replicate it
> faithfully) *before* the narrower pre-existing rules would otherwise
> restrict it — and `break` ensures every other identity still falls through
> to the original rules unaffected. OpenLDAP renumbers existing `{N}` entries
> automatically.

### `syncprov` overlay (on the provider)

```bash
cat > /tmp/provider_simple_sync.ldif <<'EOF'
dn: olcDatabase={1}mdb,cn=config
changetype: modify
add: olcDbIndex
olcDbIndex: entryCSN eq
-
add: olcDbIndex
olcDbIndex: entryUUID eq

dn: cn=module{0},cn=config
changetype: modify
add: olcModuleLoad
olcModuleLoad: syncprov

dn: olcOverlay=syncprov,olcDatabase={1}mdb,cn=config
changetype: add
objectClass: olcOverlayConfig
objectClass: olcSyncProvConfig
olcOverlay: syncprov
olcSpCheckpoint: 100 10
olcSpSessionLog: 100
EOF
sudo ldapadd -Q -Y EXTERNAL -H ldapi:/// -f /tmp/provider_simple_sync.ldif
```

### `syncrepl` consumer config (on the consumer)

```bash
cat > /tmp/consumer_simple_sync.ldif <<'EOF'
dn: cn=module{0},cn=config
changetype: modify
add: olcModuleLoad
olcModuleLoad: syncprov

dn: olcDatabase={1}mdb,cn=config
changetype: modify
add: olcDbIndex
olcDbIndex: entryUUID eq
-
add: olcSyncrepl
olcSyncrepl: rid=0
  provider=ldap://ubuntu-lfcs
  bindmethod=simple
  binddn="cn=replicator,dc=example,dc=com" credentials=ReplSecret123!
  searchbase="dc=example,dc=com"
  schemachecking=on
  type=refreshAndPersist retry="60 +"
  starttls=critical tls_reqcert=demand
-
add: olcUpdateRef
olcUpdateRef: ldap://ubuntu-lfcs
EOF
sudo ldapadd -Q -Y EXTERNAL -H ldapi:/// -f /tmp/consumer_simple_sync.ldif
```

> ⚠️ **Open the firewall on the *provider*, not just the consumer.** The
> consumer dials *out* to the provider on port 389/636 — if you've only ever
> tested the provider's LDAP service from itself (loopback), its firewall
> gap stays invisible until replication is the first genuinely external
> client. `sudo firewall-cmd --add-service=ldap --permanent --zone=public &&
> sudo firewall-cmd --reload` on **both** ends.

### Verify replication is real (not just configured)

```bash
# on each node:
ldapsearch -z1 -LLL -x -s base -b dc=example,dc=com contextCSN
```
Matching `contextCSN` values on both sides = actually synced. Also sanity
check actual data arrived:
```bash
ldapsearch -x -LLL -H ldap://ubuntu2-lfcs -b dc=example,dc=com '(uid=john)' uid
```

---

## Part 4 — Centralized Linux user management: SSSD clients

**Key concept:** having the directory data doesn't make any host — including
the LDAP server itself — resolve its own Unix logins from it. That's a
separate NSS/PAM subsystem that needs its own client configuration on
*every* host that should participate, provider included.

### 4.1 Distribute and trust the CA certificate

The CA cert is **public** — no secure channel required to move it, unlike
the private keys above.

| Distro | Where to put it | Command |
|---|---|---|
| Ubuntu/Debian | `/usr/local/share/ca-certificates/mycacert.crt` (must end in `.crt` — this directory's tool ignores anything else) | `sudo update-ca-certificates` |
| Rocky/RHEL | `/etc/pki/ca-trust/source/anchors/mycacert.crt` (any filename works) | `sudo update-ca-trust extract` |
| openSUSE | `/etc/pki/trust/anchors/` | `sudo update-ca-certificates` |

Verify you've got the right file wherever it lands:
```bash
openssl x509 -in mycacert.pem -noout -fingerprint -sha256
```

### 4.2 Install SSSD

```bash
# Ubuntu (ubuntu-lfcs, ubuntu2-lfcs):
sudo apt install -y sssd sssd-ldap libnss-sss libpam-sss

# Rocky (rocky-lfcs, rocky2-lfcs):
sudo dnf install -y sssd sssd-ldap openldap-clients oddjob-mkhomedir authselect
```

### 4.3 `/etc/sssd/sssd.conf` — identical content on every distro

```ini
[sssd]
services = nss, pam
domains = example.com

[domain/example.com]
id_provider = ldap
auth_provider = ldap
ldap_uri = ldap://ubuntu-lfcs, ldap://ubuntu2-lfcs
ldap_search_base = dc=example,dc=com
ldap_tls_reqcert = demand
ldap_tls_cacert = /etc/ssl/certs/mycacert.pem
ldap_id_use_start_tls = true
cache_credentials = true
enumerate = false
fallback_homedir = /home/%u
```

> ⚠️ **`ldap_tls_cacert` must be an exact, bare path on its own line — no
> trailing comments.** `sssd.conf` is parsed by `libini_config`, which,
> unlike shell/Python, does **not** strip inline `# ...` comments after a
> value. Anything after `=` on that line — comment included — becomes part
> of the literal path, which then fails to open as a file. Result:
> `sssd_be: Could not start TLS encryption` → `Backend is offline` → `id`/
> `getent` silently return nothing (not "user not found" — "couldn't even
> ask"). Only whole-line `#`-prefixed comments are safe in this file.

> ⚠️ **The path itself is distro-specific, too** — trusting a CA
> system-wide (`update-ca-trust extract`) does *not* mean every app config
> that hardcodes a cert path will find it:
> - Ubuntu: `/etc/ssl/certs/mycacert.pem` (the symlink `update-ca-certificates` creates)
> - Rocky: `/etc/pki/tls/certs/ca-bundle.crt` (the full system bundle; `/etc/ssl/certs/` doesn't exist on Rocky at all)

```bash
sudo chmod 600 /etc/sssd/sssd.conf   # required — sssd refuses to start otherwise
sudo systemctl enable --now sssd
```

### 4.4 Wire up NSS/PAM — this step is genuinely distro-specific

```bash
# Rocky 9+ (authselect, not pam-auth-update):
sudo authselect select sssd with-mkhomedir --force

# Ubuntu/Debian (pam-auth-update):
sudo pam-auth-update   # enable "SSS authentication" + "Create home directory on login"
```

### 4.5 Test — NSS first, then PAM (separate failure domains)

```bash
id john                      # NSS: does the client even see the user?
getent passwd john
getent group miners
ssh john@rocky-lfcs          # PAM: can they actually log in?
```

### 4.6 Optional hardening — restrict who can actually log in

Without this, **every** directory user can SSH into **every** client:
```ini
# add to the [domain/example.com] section:
ldap_access_filter = (memberOf=cn=admins,ou=Groups,dc=example,dc=com)
access_provider = ldap
```

---

## Quick-reference: every real bug hit while building this, and its fix

| Symptom | Root cause | Fix |
|---|---|---|
| `ldapaddgroup` → "Error adding group X to LDAP" | `SERVER=ldap://ldap01.example.com` doesn't resolve | `SERVER=ldap://localhost` |
| Same, now "Invalid credentials" | `BINDDDN` typo (3 D's); real `BINDDN` only existed commented out | Fix the variable name/value |
| `ldap_modify: Other error (80)` on `cn=config` TLS attrs | Cert/key files referenced don't exist yet | Actually generate them with `certtool` first |
| TLS works sometimes, `openldap` can't read key | `/etc/ssl/private` only grants `ssl-cert` group traverse | `usermod -aG ssl-cert openldap` + **restart slapd** |
| `ldaps:///` edit to `/etc/default/slapd` has no effect | File only read at startup | `systemctl restart slapd` |
| `ldapwhoami -ZZ` fails hostname verification | Cert CN/SAN doesn't match the hostname connected to | Regenerate cert with correct `cn`/`dns_name` |
| `ldap_start_tls: Operations error, TLS already started` | `-ZZ` (StartTLS) combined with `ldaps://` (already implicit TLS) | Use one encryption path per connection |
| Consumer never catches up; `contextCSN` missing | Consumer's `olcSuffix` still the default `dc=nodomain` | `replace: olcSuffix` to the real suffix *before* configuring syncrepl |
| `syncrepl` → `ldap_start_tls failed (-1)` in consumer journal | Provider's own firewall never had LDAP opened (only ever tested from itself) | `firewall-cmd --add-service=ldap` on the **provider** too |
| `id john` returns nothing on an SSSD client, service shows `active` | `sssd_be: Could not start TLS encryption` — inline comment in `sssd.conf` became part of the cert path value | Strip the comment; one value per line, no trailing `#...` |
| Same fix applied, still fails on Rocky specifically | `/etc/ssl/certs/mycacert.pem` is a Debian path; doesn't exist on Rocky | Point at `/etc/pki/tls/certs/ca-bundle.crt` instead |
| `id john` works on every client *except the LDAP server itself* | The directory server was never configured as its own SSSD client | Install/configure SSSD there too, exactly like any other client |
