# Networking — SSH (key-based auth, client config, host key trust)

Domain: Networking ("Configure the OpenSSH server and client").

## Generating a keypair

```bash
ssh-keygen -t ed25519 -f /root/.ssh/keyname -N "" -C "comment"
```

- `-t ed25519` — preferred modern key type (smaller, fast, secure);
  `rsa` (with `-b 4096`) still common/accepted if a task specifies it.
- `-N ""` — empty passphrase. Required for fully non-interactive auth
  (scripts, automation, `ssh host true` with no prompt). Omit `-N` and
  it'll interactively prompt for a passphrase instead.
- `-f` — output path; produces `<path>` (private, mode 600) and
  `<path>.pub` (public, mode 644).

## Authorizing a key for a user

```bash
mkdir -p /home/user/.ssh
cat pubkey.pub >> /home/user/.ssh/authorized_keys
chmod 700 /home/user/.ssh
chmod 600 /home/user/.ssh/authorized_keys
chown -R user:user /home/user/.ssh
```

**Permissions are not optional** — sshd silently refuses pubkey auth
(falls through to password/fails, no error toward the client) if:

- `~/.ssh` is more permissive than `700`
- `authorized_keys` is more permissive than `600`
- the home directory itself or any parent is group/world-writable
- ownership doesn't match the target user

`ssh-copy-id -i pubkey.pub user@host` automates all of the above
correctly in one step, if you already have some access path (password or
another key) to do it remotely.

## Client-side alias config (`~/.ssh/config` or `/root/.ssh/config`)

```
Host myalias
    HostName 192.168.56.12
    User remoteuser
    IdentityFile /root/.ssh/keyname
    IdentitiesOnly yes
    StrictHostKeyChecking yes
```

- `IdentitiesOnly yes` — forces ssh to use **only** the specified
  `IdentityFile`, not every key loaded in an agent or found in
  `~/.ssh/`. Important when multiple keys exist and you need a specific
  one tested/used (common exam requirement, easy to forget and have ssh
  silently try a different key that happens to also be authorized).
- `StrictHostKeyChecking yes` — refuses to connect to a host not already
  in `known_hosts` (no auto-accept prompt). This means `known_hosts`
  **must be pre-populated** before the first connection, or the
  connection fails outright rather than prompting.
- Config file itself needs `chmod 600` (ssh ignores/warns on
  group/world-readable config files, same spirit as key files).

## Pre-populating known_hosts (required when StrictHostKeyChecking=yes)

```bash
ssh-keyscan -H 192.168.56.12 >> /root/.ssh/known_hosts
```

`-H` hashes the hostname in the stored entry (doesn't change matching
behavior, just obscures the hostname in the file). Without this step
and with strict checking on, the very first connection fails instead of
prompting — there's no interactive fallback.

## Non-interactive verification pattern

```bash
ssh alias true
echo $?
```

`true` is a no-op remote command — this tests that auth + connection
succeed without needing a real remote task. Exit code `0` = success.
Any password/passphrase prompt appearing here means key auth isn't
fully configured (wrong permissions, wrong `IdentityFile` path, or key
not actually authorized on the server).

## Debugging auth failures

```bash
ssh -v alias true          # -vv or -vvv for more detail
```

Shows exactly which key(s) were offered and why the server
accepted/rejected each one — far faster than guessing. On the server
side, also check `/etc/ssh/sshd_config` for `PubkeyAuthentication yes`
and `PasswordAuthentication` (shouldn't block pubkey auth, but good to
confirm pubkey isn't disabled), and SELinux context if enforcing:

```bash
restorecon -Rv /home/user/.ssh
```

(mislabeled `.ssh`/`authorized_keys` context after manual creation is a
classic SELinux-enforcing gotcha — same category as the
[SELinux notes](../operations-deployment/selinux.md), worth connecting
the two mentally.)
