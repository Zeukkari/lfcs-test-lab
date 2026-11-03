# Study notes by exam domain

Notes follow the five official LFCS exam domains. The full
per-competency checklist (with drill status per competency) lives
in the [study guide](../README.md).

## Operations Deployment (25%)

| Note | Covers |
| --- | --- |
| [kernel-parameters.md](operations-deployment/kernel-parameters.md) | `sysctl -w` vs persistent /etc/sysctl.d, the bare-`sysctl -p` trap (reads only sysctl.conf — use `--system`), modules runtime (modprobe) vs persistent (modules-load.d, modprobe.d options/blacklist) |
| [processes-and-signals.md](operations-deployment/processes-and-signals.md) | ps/pgrep selection, signals (`kill -9` useless on D-state), nice/renice, jobs/bg/fg, surviving logout (nohup/disown), the `pkill -f` overmatch trap |
| [job-scheduling.md](operations-deployment/job-scheduling.md) | cron fields and the /etc/cron.d user-field trap, anacron catch-up, `at` one-shots, systemd service+timer pair, same task both ways, per-family deltas |
| [package-management.md](operations-deployment/package-management.md) | apt/dnf/zypper task-mapping table; traps: `rpm -ivh` skips deps, `apt-key` dead (keyrings + signed-by), dnf versionlock needs its plugin; compile from source |
| [boot-and-recovery.md](operations-deployment/boot-and-recovery.md) | GRUB one-shot kernel args, root password reset (the `/.autorelabel` trap), rescue/emergency targets, broken-fstab boot, fsck vs xfs_repair, GRUB reinstall per family (RHEL 9 grub.cfg path trap) |
| [virtual-machines.md](operations-deployment/virtual-machines.md) | libvirt install per family, virsh lifecycle (`destroy` = hard power-off, not removal), minimal virt-install, qemu-img, exam shape |
| [containers.md](operations-deployment/containers.md) | podman basics and rootless, reboot-surviving units: Quadlet (podman ≥ 4.4, Rocky 9) vs `podman generate systemd` (3.4, Ubuntu 22.04), SELinux `:Z` volume trap |
| [selinux.md](operations-deployment/selinux.md) | Booleans (`setsebool -P`), verifying persistence, mode/status, file contexts (`chcon` vs `semanage fcontext` + `restorecon`), AppArmor hedge for Ubuntu (/etc/apparmor.d, profile modes) |

## Networking (25%)

| Note | Covers |
| --- | --- |
| [ip-ss-mtr.md](networking/ip-ss-mtr.md) | iproute2 (legacy → modern mapping), addresses/routes/neighbors, `ss`, per-distro persistent config and static routes (nmcli/netplan/wicked), hostname resolution (hostnamectl, /etc/hosts, resolvectl), `mtr` and reading its output |
| [firewalls-and-nat.md](networking/firewalls-and-nat.md) | iptables tables/chains/lifecycle, stateful INPUT recipe, DNAT worked example (OUTPUT vs PREROUTING), ip_forward, persistence, full nftables equivalent |
| [ssh.md](networking/ssh.md) | Keypairs, authorized_keys permissions, client config (`IdentitiesOnly`, `StrictHostKeyChecking`), `ssh-keyscan`, auth debugging |
| [time-sync.md](networking/time-sync.md) | chronyd vs systemd-timesyncd defaults per family, the chrony config-path delta (/etc/chrony/ on deb vs /etc/chrony.conf on rpm/suse), chronyc sources/tracking, timedatectl (`set-time` fails while NTP on), serving time + firewall |
| [bridges-and-bonding.md](networking/bridges-and-bonding.md) | Bonding modes, nmcli bridge/bond recipes (rpm), netplan (deb), wicked ifcfg (suse — Leap server defaults to wicked, not NM), grader-style verification |
| [reverse-proxy-lb.md](networking/reverse-proxy-lb.md) | nginx vhost paths per family (deb sites-available inert until symlinked), reverse-proxy server block, upstream LB, test/reload loop, SELinux `httpd_can_network_connect` 502 trap, haproxy basics |

## Storage (20%)

| Note | Covers |
| --- | --- |
| [lvm.md](storage/lvm.md) | PV/VG/LV lifecycle, exam walkthrough (pvcreate → fstab), `lvextend --resizefs`, persistent-mount trap |
| [partitioning-and-filesystems.md](storage/partitioning-and-filesystems.md) | fdisk/gdisk/parted, stale-partition-table trap (partprobe), mkfs, fstab (`mount -a`, never reboot-test), e2fsck vs xfs_repair (dirty-log refusal) |
| [raid-mdadm.md](storage/raid-mdadm.md) | mdadm create, disk replacement (fail → remove → add), persistence delta (/etc/mdadm/mdadm.conf on deb vs /etc/mdadm.conf + `--detail --scan` capture, initramfs refresh), fstab |
| [luks.md](storage/luks.md) | cryptsetup format/open/close, key management, crypttab + fstab boot wiring, the two-UUIDs trap (LUKS container vs inner filesystem) |
| [virtual-filesystem.md](storage/virtual-filesystem.md) | /proc and /sys tours, /proc/mounts vs findmnt, filesystem types, echo-into-/proc applies now but never persists (ties to kernel-parameters) |
| [remote-filesystems.md](storage/remote-filesystems.md) | NFS server/client (v4 = port 2049 only; no-space-before-`(` exports trap), Samba/CIFS (chmod 600 credentials file, SELinux samba_share_t), NBD (EPEL-only on rpm) |
| [swap.md](storage/swap.md) | Swap partition/LV and swap file (chmod 600 before swapon), fstab, btrfs NOCOW caveat (openSUSE default root fs), swappiness, zram |
| [automounters.md](storage/automounters.md) | autofs maps (indirect dirs invisible until first access), fstab x-systemd.automount, explicit unit pair (enable the .automount, not the .mount) |
| [storage-performance.md](storage/storage-performance.md) | iostat per-device, pidstat -d per-process, sar history (deb records nothing until ENABLED="true"), iotop (Leap needs delayacct boot arg), quick wins |

## Essential Commands (20%)

| Note | Covers |
| --- | --- |
| [git-basics.md](essential-commands/git-basics.md) | Identity-before-first-commit trap, add/commit/log loop, branching and merging, local-path remotes (work offline), .gitignore (does not untrack already-committed files) |
| [systemd-services.md](essential-commands/systemd-services.md) | Unit locations/precedence, minimal unit + Type= cheat table, drop-in edits (list settings append — clear then set), daemon-reload after on-disk edits, enable/disable/mask semantics, failure-triage order |
| [performance-monitoring.md](essential-commands/performance-monitoring.md) | Load average vs nproc (high load + low CPU = blocked on I/O), top field literacy, free (judge by "available"), vmstat si/so swap signal, sar history, quick wins |
| [service-constraints.md](essential-commands/service-constraints.md) | cgroup-v2 directives (`MemoryMax`, not legacy `MemoryLimit`), three routes (set-property / drop-in / systemd-run), `CPUQuota` reads back as `CPUQuotaPerSecUSec`, observing limits, diagnosis checklist |
| [diskspace-troubleshooting.md](essential-commands/diskspace-troubleshooting.md) | Triage order, df-vs-du deleted-but-open classic (`rm` on a live log frees nothing — truncate instead), inode exhaustion, fast reclaim, family delta |
| [ssl-certificates.md](essential-commands/ssl-certificates.md) | One-shot self-signed + CSR recipes, inspect/verify (clients validate SAN, not CN), live s_client checks, format conversion, per-family CA trust (deb only picks up .crt files) |

### Supporting / implicitly tested

| Note | Covers |
| --- | --- |
| [using-documentation.md](essential-commands/using-documentation.md) | `man -k`/`apropos`/`man -K`, offline speed toolkit (tab completion, readline tricks, info, /usr/share/doc, config templates, validators), exam-legal policy |
| [classics-files-and-text.md](essential-commands/classics-files-and-text.md) | tar (stored-name extraction trap), rsync trailing slash, dd, find (`-perm` semantics), grep BRE vs ERE, sed/awk (`sed -i.bak`, no space), redirection order (`2>&1` placement), hard vs soft links, SUID/SGID/sticky + umask math |
| [classics-shell-and-logging.md](essential-commands/classics-shell-and-logging.md) | Bash scripting minimums (cron-safe PATH), vim speed (exam UI disables the INSERT key), journalctl filter kit, persistent journal per family, rsyslog facility.priority, logrotate |

## Users and Groups (10%)

| Note | Covers |
| --- | --- |
| [local-users-and-groups.md](users-and-groups/local-users-and-groups.md) | useradd per-family deltas (deb creates no home without `-m`), /etc/skel, `usermod -aG` (missing `-a` replaces all groups), lock/unlock, chage aging matrix, sudoers drop-ins (mode 0440; suse `targetpw` trap) |
| [environment-profiles.md](users-and-groups/environment-profiles.md) | Login vs non-login startup chains, the `su` vs `su -` classic, /etc/profile.d drop-in as the portable answer, /etc/environment is not a script (pam_env), per-user files, cron/ssh minimal environments |
| [resource-limits.md](users-and-groups/resource-limits.md) | pam_limits (limits.conf/limits.d, soft vs hard), ulimit shell scope, prlimit on running processes, systemd side (services get Limit*/slice caps, never limits.conf) |
| [acls.md](users-and-groups/acls.md) | `getfacl`/`setfacl`, the `mask::` trap, default ACLs, cp/mv/tar behavior |
| [ldap.md](users-and-groups/ldap.md) | posixAccount LDIF, parent-OU errors, rootPW reset via SASL EXTERNAL, nslcd client, core concepts (DIT/DN/objectClass/schema), cn=config vocabulary |
| [sssd.md](users-and-groups/sssd.md) | sssd.conf minimal LDAP domain, permissions, NSS/PAM wiring helpers, cache gotchas, `sssctl` |
| [nss-pam.md](users-and-groups/nss-pam.md) | Lookup-vs-login mental model, nsswitch.conf, PAM types/control flags/common modules, editing PAM safely |
