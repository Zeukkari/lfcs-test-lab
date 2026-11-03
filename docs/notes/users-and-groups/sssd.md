# Users and Groups — SSSD (modern LDAP client daemon, alternative to nslcd)

Same job as nslcd — resolve LDAP users/groups via NSS and authenticate
them via PAM — but more modern: one daemon handles NSS + PAM + caching,
so users can still authenticate if the LDAP server is briefly
unreachable (offline auth). Default choice on RHEL-family systems; the
exam is distro-agnostic, so know both (nslcd config is in
[ldap.md](ldap.md)).

See also the lab's
[centralized-auth setup guide](../../lab/openldap-centralized-auth-setup.md)
for a real multi-distro SSSD build (including the `sssd.conf` inline-comment
trap and per-distro `ldap_tls_cacert` paths) and
[learning log](../../lab/learning-log.md) for the full diagnosis.

## Install

```bash
apt install sssd sssd-ldap        # Debian/Ubuntu
dnf install sssd                  # RHEL/Rocky
```

## Minimal LDAP domain config — /etc/sssd/sssd.conf

```ini
[sssd]
config_file_version = 2
domains = lfcs.lab
services = nss, pam

[domain/lfcs.lab]
id_provider = ldap
auth_provider = ldap
ldap_uri = ldap://192.168.56.12/
ldap_search_base = dc=lfcs,dc=lab
cache_credentials = true
```

Note: by default sssd **refuses to send passwords over an unencrypted
connection** — plain `ldap://` with no TLS lets `id`/`getent` lookups
work but blocks actual authentication. In a certless lab, either set up
TLS or explicitly override (`ldap_auth_disable_tls_never_use_in_production
= true` — the option name says it all). Lookups-only tasks don't hit this.

## Permissions — sssd refuses to start otherwise

```bash
chown root:root /etc/sssd/sssd.conf
chmod 600 /etc/sssd/sssd.conf
```

## Enable and wire into NSS/PAM

```bash
systemctl enable --now sssd
```

`/etc/nsswitch.conf` — the source name is `sss` (not `ldap`):

```
passwd: files sss
group:  files sss
shadow: files sss
```

Distro helpers that wire NSS + PAM consistently instead of hand-editing:

- RHEL/Rocky: `authselect select sssd with-mkhomedir`
- Debian/Ubuntu: `pam-auth-update` (toggle SSS auth + mkhomedir)

## Verify / debug

```bash
getent passwd ldapuser1
id ldapuser1
sssctl domain-status lfcs.lab     # domain online/offline, server status
sssctl user-checks ldapuser1      # simulates NSS + PAM for one user
```

Caching gotcha: sssd caches aggressively (that's its point). After
fixing something on the LDAP server, a stale cache entry can mask the
fix — expire the cache before concluding anything:

```bash
sss_cache -E                      # expire all cached entries
# heavier reset: systemctl stop sssd; rm -f /var/lib/sss/db/*; systemctl start sssd
```

Logs: `/var/log/sssd/sssd_<domain>.log` (set `debug_level = 6` in the
domain section for detail).
