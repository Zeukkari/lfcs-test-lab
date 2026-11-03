# Users and Groups — NSS and PAM (lookup vs login — two separate systems)

Key mental model: **NSS answers "who is this user"** (uid/gid/home/shell
— what `getent`, `id`, `ls -l` need); **PAM answers "may they log in,
and what happens around login"** (password verification, account
restrictions, session setup). Configured independently. `getent passwd
ldapuser1` succeeding while `su - ldapuser1` fails = NSS fine, PAM (or
home dir) not.

## NSS — /etc/nsswitch.conf

Each line: database → ordered list of sources, consulted left to right;
first source that answers wins:

```
passwd:  files sss          # or: files ldap (nslcd)
group:   files sss
shadow:  files sss
hosts:   files dns myhostname
```

- Sources: `files` (/etc/passwd etc.), `sss` (SSSD), `ldap` (nslcd),
  `dns`, `compat`, `db`
- Action modifiers exist (`hosts: dns [NOTFOUND=return] files`) — rare,
  but recognize the syntax.

Test resolution per database:

```bash
getent passwd ldapuser1     # passwd database
getent group devs           # group database
getent hosts node2          # hosts database
id ldapuser1                # end-to-end uid + all gids
```

## PAM — /etc/pam.d/<service>

Each service (`sshd`, `login`, `su`, `sudo`...) has a file; shared
stacks live in `common-*` (Debian) or `system-auth`/`password-auth`
(RHEL), pulled in via `@include`/`include`/`substack`.

Line format: `type control module [args]`

Four module types (stacks evaluated independently):

- `auth` — verify identity (password/key), set credentials
- `account` — is the account allowed at all? (expiry, time, access rules)
- `password` — change/update auth tokens (the `passwd` command path)
- `session` — around-login actions: home dir creation, limits, logging

Control flags (what a module's result does to the stack):

- `required` — must pass; on failure the rest still runs, but the stack
  fails at the end (failure remembered, not immediate)
- `requisite` — must pass; failure aborts the stack immediately
- `sufficient` — success ends the stack with success (unless an earlier
  `required` already failed); failure is ignored
- `optional` — result ignored unless it's the only module of its type
- `include` / `substack` — pull in another file

Common modules worth recognizing on sight:

- `pam_unix.so` — classic /etc/passwd + /etc/shadow auth
- `pam_sss.so` / `pam_ldap.so` — SSSD / nslcd authentication
- `pam_mkhomedir.so` — create home on first login; **critical for
  LDAP/SSSD users whose home dirs don't pre-exist**:

  ```
  session  required  pam_mkhomedir.so  skel=/etc/skel umask=0022
  ```

- `pam_limits.so` — applies /etc/security/limits.conf (nofile, nproc)
- `pam_pwquality.so` — password complexity (/etc/security/pwquality.conf)
- `pam_faillock.so` — lockout after N failures (`faillock` to inspect/reset)
- `pam_wheel.so` — restrict `su` to the wheel group

## Editing PAM safely

- Prefer distro helpers over hand-editing shared stacks:
  `pam-auth-update` (Debian/Ubuntu), `authselect` (RHEL) — they
  regenerate the common files consistently.
- **Keep a root shell open in a separate terminal** while changing PAM
  and test login from a new session before closing it — a broken auth
  stack locks out everyone, including root.
- LDAP-user-can't-log-in checklist: `getent passwd` works? (NSS ok) →
  `pam_sss`/`pam_ldap` in the auth stack? → account stack passing? →
  home dir exists or `pam_mkhomedir` in session stack? → sshd
  `AllowUsers`/`AllowGroups` not excluding the user?
