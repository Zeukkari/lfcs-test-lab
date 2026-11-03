# Study notes by exam domain

Notes follow the five official LFCS exam domains. The full
per-competency checklist (including topics with **no notes yet**) lives
in the [study guide](../README.md).

## Operations Deployment (25%)

| Note | Covers |
|---|---|
| [selinux.md](operations-deployment/selinux.md) | Booleans (`setsebool -P`), verifying persistence, mode/status, file contexts (`chcon` vs `semanage fcontext` + `restorecon`) |

## Networking (25%)

| Note | Covers |
| --- | --- |
| [ip-ss-mtr.md](networking/ip-ss-mtr.md) | iproute2 (legacy → modern mapping), addresses/routes/neighbors, `ss`, per-distro persistent config (netplan/nmcli), `mtr` and reading its output |
| [firewalls-and-nat.md](networking/firewalls-and-nat.md) | iptables tables/chains/lifecycle, stateful INPUT recipe, DNAT worked example (OUTPUT vs PREROUTING), ip_forward, persistence, full nftables equivalent |
| [ssh.md](networking/ssh.md) | Keypairs, authorized_keys permissions, client config (`IdentitiesOnly`, `StrictHostKeyChecking`), `ssh-keyscan`, auth debugging |

## Storage (20%)

| Note | Covers |
|---|---|
| [lvm.md](storage/lvm.md) | PV/VG/LV lifecycle, exam walkthrough (pvcreate → fstab), `lvextend --resizefs`, persistent-mount trap |

## Essential Commands (20%)

| Note | Covers |
|---|---|
| [using-documentation.md](essential-commands/using-documentation.md) | `man -k`/`apropos`/`man -K`, offline speed toolkit (tab completion, readline tricks, info, /usr/share/doc, config templates, validators), exam-legal policy |

## Users and Groups (10%)

| Note | Covers |
| --- | --- |
| [acls.md](users-and-groups/acls.md) | `getfacl`/`setfacl`, the `mask::` trap, default ACLs, cp/mv/tar behavior |
| [ldap.md](users-and-groups/ldap.md) | posixAccount LDIF, parent-OU errors, rootPW reset via SASL EXTERNAL, nslcd client, core concepts (DIT/DN/objectClass/schema), cn=config vocabulary |
| [sssd.md](users-and-groups/sssd.md) | sssd.conf minimal LDAP domain, permissions, NSS/PAM wiring helpers, cache gotchas, `sssctl` |
| [nss-pam.md](users-and-groups/nss-pam.md) | Lookup-vs-login mental model, nsswitch.conf, PAM types/control flags/common modules, editing PAM safely |
