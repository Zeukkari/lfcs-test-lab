# Users and Groups — LDAP (posixAccount entries, nslcd client, admin auth troubleshooting)

Domain: Users and Groups ("Configure the system to use LDAP user and
group accounts").

Related: [sssd.md](sssd.md) (modern client daemon),
[nss-pam.md](nss-pam.md) (lookup vs login wiring), and the lab's
[`ldapaddgroup` worked example](../../lab/troubleshooting-method.md)
plus [OpenLDAP server build log](../../lab/learning-log.md) (TLS,
replication, ldapscripts debugging).

## Server side (node holding the directory): add a posixAccount entry

`posixAccount` is an AUXILIARY objectClass — it needs a structural class
too. Since `cn`/`sn` are required by the task, pair it with `person`:

```bash
cat > /root/ldapuser1.ldif <<'EOF'
dn: uid=ldapuser1,ou=People,dc=lfcs,dc=lab
objectClass: top
objectClass: person
objectClass: posixAccount
cn: ldapuser1
sn: ldapuser1
uid: ldapuser1
uidNumber: 3101
gidNumber: 3101
homeDirectory: /home/ldapuser1
loginShell: /bin/bash
EOF

ldapadd -x -D "cn=admin,dc=lfcs,dc=lab" -W -f /root/ldapuser1.ldif
```

`gidNumber` is mandatory for `posixAccount` even if a task doesn't
mention it explicitly — pick something sane (matching uidNumber is a
common convention) and check if the grading validator expects a
specific value/existing group.

Verify:

```bash
ldapsearch -x -b "dc=lfcs,dc=lab" "uid=ldapuser1"
```

## "No such object (32)" when adding an entry

`matched DN: dc=lfcs,dc=lab` means the **parent** of the DN you're
adding doesn't exist yet (e.g. `ou=People,dc=lfcs,dc=lab` missing).
Create the parent OU first:

```bash
cat > /root/ou-people.ldif <<'EOF'
dn: ou=People,dc=lfcs,dc=lab
objectClass: organizationalUnit
ou: People
EOF
ldapadd -Y EXTERNAL -H ldapi:/// -f /root/ou-people.ldif
```

Check what actually exists under a base DN:

```bash
ldapsearch -Y EXTERNAL -H ldapi:/// -b "dc=lfcs,dc=lab" -s one "(objectClass=*)" dn
```

## Don't know / forgot the admin bind password

**Bypass with SASL EXTERNAL over the local socket** (uses OS root
identity instead of a bind DN/password):

```bash
sudo ldapadd -Y EXTERNAL -H ldapi:/// -f /root/ldapuser1.ldif
```

Caveat: EXTERNAL via `ldapi://` authenticates against `cn=config` and
may only have **partial** rights on the data database depending on ACLs
— can succeed on some operations (e.g. adding under an existing OU) and
fail with `Insufficient access (50)` on others (e.g. adding at the
base). Don't assume full rootDN-equivalent access from EXTERNAL alone.

**Reliable fix: set/reset the rootpw on the actual data database, then
bind normally as admin.**

1. Find the right database entry (must match the actual data suffix,
   not `cn=config` itself):

   ```bash
   ldapsearch -Y EXTERNAL -H ldapi:/// -b "cn=config" "(olcSuffix=dc=lfcs,dc=lab)" dn
   # dn: olcDatabase={1}mdb,cn=config   <- use this exact DN below
   ```

2. Set the password non-interactively (avoids typos from copy-pasting
   a `slappasswd` hash or mismatched prompts):

   ```bash
   cat > /root/rootpw.ldif <<EOF
   dn: olcDatabase={1}mdb,cn=config
   changetype: modify
   replace: olcRootPW
   olcRootPW: $(slappasswd -s admin123)
   EOF
   ldapmodify -Y EXTERNAL -H ldapi:/// -f /root/rootpw.ldif
   ```

3. **Verify it actually took effect** before trusting it:

   ```bash
   ldapsearch -Y EXTERNAL -H ldapi:/// -b "cn=config" "(olcDatabase={1}mdb)" olcRootPW
   ```

4. Bind as the real admin DN with the inline password (skip `-W`
   prompt to remove any typo risk while debugging):

   ```bash
   ldapadd -x -D "cn=admin,dc=lfcs,dc=lab" -w admin123 -f ou-people.ldif
   ldapadd -x -D "cn=admin,dc=lfcs,dc=lab" -w admin123 -f ldapuser1.ldif
   ```

Note: `olcRootDN` (e.g. `cn=admin,dc=lfcs,dc=lab`) is a **virtual**
admin identity recognized by the database config — it does not need to
exist as a real directory entry for this bind to work.

## Client side (node consuming LDAP): nslcd + nsswitch

`/etc/nslcd.conf`:

```
uri ldap://192.168.56.12/
base dc=lfcs,dc=lab
```

(install `libnss-ldapd` on Debian/Ubuntu if `nslcd` isn't present)

`/etc/nsswitch.conf` — add `ldap` to the passwd database:

```
passwd: files ldap
```

Restart and verify:

```bash
systemctl restart nslcd
systemctl restart nscd 2>/dev/null || true
getent passwd ldapuser1
# ldapuser1:*:3101:3101::/home/ldapuser1:/bin/bash
```

## Study materials — LDAP concepts to review

Given this was unfamiliar territory, worth studying the underlying
concepts rather than just memorizing commands — the exam can vary the
scenario (different OUs, attributes, client configs) and pure command
recall won't transfer.

**Core concepts to understand:**

- **DIT (Directory Information Tree)** — the hierarchical structure of
  entries, analogous to a filesystem tree. `dc=lfcs,dc=lab` is the root/base.
- **DN (Distinguished Name) vs RDN (Relative Distinguished Name)** —
  `uid=ldapuser1,ou=People,dc=lfcs,dc=lab` is the full DN; `uid=ldapuser1`
  is the RDN (unique only relative to its parent).
- **objectClass: STRUCTURAL vs AUXILIARY vs ABSTRACT** — every entry needs
  exactly one structural class (defines its fundamental type, e.g.
  `person`, `organizationalUnit`) and can have zero or more auxiliary
  classes layered on top (e.g. `posixAccount`, `shadowAccount`) that add
  extra optional/mandatory attributes. This is exactly what caused the
  "need `person` + `posixAccount` together" issue above — worth being
  able to explain *why*, not just pattern-match it.
- **Schema** — defines which objectClasses/attributes exist and their
  MUST/MAY rules. Check a schema definition:

  ```bash
  ldapsearch -Y EXTERNAL -H ldapi:/// -b cn=schema,cn=config "(objectClass=olcSchemaConfig)" dn
  ```

- **LDIF format** — the plain-text format used for all add/modify
  operations (`dn:`, `objectClass:`, `changetype:`, attribute: value
  pairs). Get comfortable writing these from scratch, not just editing
  templates.

**Server architecture (OpenLDAP specifically, slapd):**

- **cn=config (dynamic config backend) vs slapd.conf (legacy static
  file)** — modern OpenLDAP uses `cn=config`, a live LDAP tree you query/
  modify with `ldapsearch`/`ldapmodify -b cn=config`, instead of editing
  a flat file and restarting. This is why debugging required `ldapsearch
  -b cn=config` rather than `cat /etc/ldap/slapd.conf`.
- **olcDatabase entries** (`{0}config`, `{1}mdb`, etc.) — each backend
  database (including the config database itself) is represented as an
  entry under `cn=config`. Know how to find the right one:
  `(olcSuffix=dc=lfcs,dc=lab)`.
- **olcAccess / ACLs** — control what each bind identity can read/write,
  per-database. This is what silently limited the EXTERNAL identity
  earlier. Worth reading `man slapd.access` to understand ACL syntax
  (`to * by * read`, `by dn.exact="..." write`, etc.) rather than just
  reactively working around denials.
- **olcRootDN / olcRootPW** — the "break glass" superuser identity per
  database, bypasses all ACLs. Distinct from any regular `cn=admin`
  *entry* that might also exist in the data tree — rootDN doesn't need
  to exist as a real LDAP object.

**Authentication mechanisms:**

- **Anonymous bind** — no credentials; what unauthenticated `ldapsearch -x`
  (no `-D`) uses. Whether it can read anything depends entirely on ACLs.
- **Simple bind** — `-x -D "<dn>" -w/-W` — plaintext DN + password (over
  TLS in production; plaintext LDAP is fine for a lab/exam environment).
- **SASL EXTERNAL** — `-Y EXTERNAL -H ldapi:///` — authenticates using
  the OS-level identity over a local Unix socket, mapped to an LDAP
  identity via `cn=config` authz rules. Useful for config-backend admin
  access, but (as seen above) not automatically equivalent to full
  rootDN rights on every database.

**Client-side integration (how a Linux host actually consumes LDAP for
user/group lookups and login):**

- **NSS (Name Service Switch)** — `/etc/nsswitch.conf` controls which
  backends (`files`, `ldap`, `sss`, etc.) are consulted for `passwd`,
  `group`, `shadow` databases, and in what order.
- **nslcd** (what was used here) — a daemon that proxies NSS/PAM lookups
  to LDAP; configured via `/etc/nslcd.conf` (`uri`, `base`, optional
  `binddn`/`bindpw` for non-anonymous lookups). Alternative: **SSSD**
  (more modern, more common in RHEL-family exam scenarios) — configured
  via `/etc/sssd/sssd.conf` instead, worth knowing both since the
  real exam is distro-agnostic.
- **PAM integration** — for LDAP accounts to actually be able to *log in*
  (not just resolve via `getent`), `/etc/pam.d/common-auth` (Debian) or
  equivalent needs `pam_ldap.so`/`pam_sss.so` in the stack — separate
  from the NSS lookup config. `getent passwd` working doesn't
  automatically mean `su - ldapuser1` or SSH login will work.

**Useful commands to practice beyond what came up today:**

```bash
ldapmodify         # modify existing entries (vs ldapadd for new ones)
ldapdelete         # remove entries
ldappasswd         # change a user's userPassword attribute
ldapwhoami -x -D "<dn>" -W      # confirm what identity a bind resolves to
getent group       # same resolution check as passwd, for groups
id ldapuser1       # confirms uid/gid resolution end-to-end via NSS
```

**Recommended reading:**

- `man slapd-config` — the cn=config backend itself
- `man slapd.access` — ACL syntax
- `man ldap.conf` — client-side defaults (`/etc/ldap/ldap.conf`,
  separate from `nslcd.conf`)
- `man nslcd.conf`
- OpenLDAP Administrator's Guide (the canonical, if dense, reference) —
  look up locally first (`man -k ldap`), external copy at
  <https://www.openldap.org/doc/admin26/> if offline docs are insufficient
  during study (not available during the actual exam, but fine now).

## cn=config vocabulary (olc*, olcDatabase, {N}, mdb)

How OpenLDAP designed `cn=config`, decoded:

- **olc prefix** — OpenLDAP Configuration. Every attribute/objectClass
  that belongs to the `cn=config` schema is prefixed `olc*`
  (`olcDatabase`, `olcAccess`, `olcSuffix`, `olcRootDN`,
  `olcTLSCertificateFile`...) purely as a namespace — it instantly
  signals "this is OpenLDAP's own config schema," distinct from ordinary
  directory-data attributes like `cn` or `mail`.
- **olcDatabase** — each value represents one storage backend slapd has
  loaded, e.g.:

  ```
  olcDatabase={-1}frontend,cn=config
  olcDatabase={0}config,cn=config
  olcDatabase={1}mdb,cn=config
  ```

  "Database" here just means "a backend instance," not necessarily your
  actual data — `frontend` is a virtual catch-all, `config` is the
  config subtree describing itself, and `mdb` is the actual data tree.
- **{N}** — OpenLDAP's ordered-index notation. Since `cn=config` needs
  individually-addressable DNs for what would otherwise be an unordered
  multi-valued list, it invented `{N}value` as the RDN, where N is the
  position in a meaningful order — the order slapd checks incoming
  requests against each database's suffix (first match wins), which is
  why `frontend` is `{-1}` (always checked, catch-all) and `config` is
  `{0}` (checked before the real data at `{1}`). The same `{N}` notation
  reappears inside `olcAccess` values (`{0}to * by ...`,
  `{1}to attrs=userPassword...`) — there it preserves ACL rule order,
  which matters because ACL evaluation is also first-match-wins.
- **mdb** — Memory-mapped Database, OpenLDAP's modern default storage
  backend, built on LMDB (Lightning Memory-Mapped Database), a B+tree
  key-value store written by Howard Chu (OpenLDAP's chief architect)
  around 2011. It replaced the older `bdb`/`hdb` backends (both built on
  Oracle BerkeleyDB, hence those names) because LMDB is faster and needs
  no separate transaction log — just one mmap'd file.
- **olcAccess** — the attribute holding that database's Access Control
  List rules, i.e. the LDAP-native equivalent of the old
  `access to ... by ...` lines from legacy flat-file `slapd.conf` —
  same syntax, just stored as an attribute value on an entry instead of
  a line in a text file.
- **SASL EXTERNAL identity string**
  `gidNumber=0+uidNumber=0,cn=peercred,cn=external,cn=auth` follows the
  same logic: `cn=auth` is a synthetic root OpenLDAP invents to
  represent "authenticated identities" as DNs even though they're not
  real stored entries; `cn=external`/`cn=peercred` narrow that down to
  "identity obtained via SASL EXTERNAL, specifically via Unix socket
  peer credentials"; and `gidNumber=0+uidNumber=0` is a multi-valued RDN
  (the `+` joins two attribute=value pairs into one DN component)
  spelling out "uid 0, gid 0" — root — exactly what the kernel handed
  slapd over the socket.
