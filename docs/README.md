# LFCS Study Guide

Start here. This is the index for all study material in this repo:
exam facts, domain-by-domain competency checklist with links to notes,
and what is still uncovered. Prep notes begun 2026-10-30, after already
passing a Kubernetes cert (KodeKloud + killer.sh were helpful then).
Already experienced with Linux; the focus is closing specific gaps and
building exam-day speed.

## How this repo supports studying

| Where | What |
| --- | --- |
| [`README.md`](../README.md) | The Vagrant/VirtualBox lab: 5 VMs across all three exam distro families |
| [`docs/notes/`](notes/) | Study notes organized by the five exam domains |
| [`docs/exam/`](exam/) | [Strategy and logistics](exam/strategy-and-logistics.md), [practice labs and resources](exam/practice-resources.md) |
| [`docs/lab/`](lab/) | [Learning log](lab/learning-log.md) (everything built/broken/learned in the lab) and the [no-AI troubleshooting method](lab/troubleshooting-method.md) with worked examples |

Study loop: pick a competency below → read/write the note → drill it in
the lab on **all three distro families** → verify like a grader would
(fresh command, reboot-survivability) → tick the box when you could do
it cold in ~6 minutes.

## Exam overview

- [LFCS certification page](https://training.linuxfoundation.org/certification/linux-foundation-certified-sysadmin-lfcs/)
  - $445 exam only / $625 with THRIVE-ONE subscription / $645 with LFS207 course
  - 2-hour, performance-based, online proctored exam; distro-agnostic
  - **17-20 tasks; pass mark 67%** (per official Important Instructions, 2026-11)
  - Includes 2 killer.sh simulation attempts (20-25 fixed questions, graded)
  - One free retake; 12 months to schedule from purchase; cert valid **2 years**
  - [Learning path PDF](https://training.linuxfoundation.org/wp-content/uploads/2024/10/LFCS.pdf)
  - [Candidate Handbook](https://docs.linuxfoundation.org/tc-docs/certification/lf-handbook2)
  - [Important Instructions: LFCS](https://docs.linuxfoundation.org/tc-docs/certification/instructions-lfcs-and-lfce) — exam environment specifics, read before exam day

### Domain weighting

| Domain | Weight |
| --- | ---: |
| Operations Deployment | 25% |
| Networking | 25% |
| Storage | 20% |
| Essential Commands | 20% |
| Users and Groups | 10% |

## Competency checklist

Official competencies per domain (from the cert page, 2026-11).
Checkbox = "I can do this cold, on any of the three distro families,
in exam time." Every competency now links to notes; an unticked box
means the drilling is not done, not that material is missing.

### Operations Deployment (25%)

- [ ] Configure kernel parameters, persistent and non-persistent — [kernel-parameters.md](notes/operations-deployment/kernel-parameters.md) (sysctl basics also in [firewalls-and-nat.md](notes/networking/firewalls-and-nat.md) ip_forward section)
- [ ] Diagnose, identify, manage, and troubleshoot processes and services — [processes-and-signals.md](notes/operations-deployment/processes-and-signals.md); method in [troubleshooting-method.md](lab/troubleshooting-method.md)
- [ ] Manage or schedule jobs for executing commands — [job-scheduling.md](notes/operations-deployment/job-scheduling.md) (cron/at template tips also in [using-documentation.md](notes/essential-commands/using-documentation.md))
- [ ] Search for, install, validate, and maintain software packages or repositories — [package-management.md](notes/operations-deployment/package-management.md) (package-query tricks also in [using-documentation.md](notes/essential-commands/using-documentation.md))
- [ ] Recover from hardware, operating system, or filesystem failures — [boot-and-recovery.md](notes/operations-deployment/boot-and-recovery.md)
- [ ] Manage Virtual Machines (libvirt) — [virtual-machines.md](notes/operations-deployment/virtual-machines.md)
- [ ] Configure container engines, create and manage containers — [containers.md](notes/operations-deployment/containers.md)
- [ ] Create and enforce MAC using SELinux — [selinux.md](notes/operations-deployment/selinux.md) (includes an AppArmor hedge section for Ubuntu)

### Networking (25%)

- [ ] Configure IPv4 and IPv6 networking and hostname resolution — [ip-ss-mtr.md](notes/networking/ip-ss-mtr.md) (netplan/nmcli persistence and hostname-resolution section included)
- [ ] Set and synchronize system time using time servers — [time-sync.md](notes/networking/time-sync.md)
- [ ] Monitor and troubleshoot networking — [ip-ss-mtr.md](notes/networking/ip-ss-mtr.md); firewall-vs-routing signatures in [learning-log.md §6](lab/learning-log.md)
- [ ] Configure the OpenSSH server and client — [ssh.md](notes/networking/ssh.md); PAM/kbd-interactive debugging in [learning-log.md §4](lab/learning-log.md)
- [ ] Configure packet filtering, port redirection, and NAT — [firewalls-and-nat.md](notes/networking/firewalls-and-nat.md)
- [ ] Configure static routing — `ip route` and per-distro persistent routes in [ip-ss-mtr.md](notes/networking/ip-ss-mtr.md)
- [ ] Configure bridge and bonding devices — [bridges-and-bonding.md](notes/networking/bridges-and-bonding.md)
- [ ] Implement reverse proxies and load balancers — [reverse-proxy-lb.md](notes/networking/reverse-proxy-lb.md)

### Storage (20%)

- [ ] Configure and manage LVM storage — [lvm.md](notes/storage/lvm.md)
- [ ] Manage and configure the virtual file system — [virtual-filesystem.md](notes/storage/virtual-filesystem.md)
- [ ] Create, manage, and troubleshoot filesystems — [partitioning-and-filesystems.md](notes/storage/partitioning-and-filesystems.md); [raid-mdadm.md](notes/storage/raid-mdadm.md) and [luks.md](notes/storage/luks.md) for RAID and encrypted devices; partial overlap in [lvm.md](notes/storage/lvm.md) (mkfs, fstab)
- [ ] Use remote filesystems and network block devices — [remote-filesystems.md](notes/storage/remote-filesystems.md)
- [ ] Configure and manage swap space — [swap.md](notes/storage/swap.md)
- [ ] Configure filesystem automounters — [automounters.md](notes/storage/automounters.md)
- [ ] Monitor storage performance — [storage-performance.md](notes/storage/storage-performance.md)

### Essential Commands (20%)

- [ ] Basic Git operations — [git-basics.md](notes/essential-commands/git-basics.md)
- [ ] Create, configure, and troubleshoot services — [systemd-services.md](notes/essential-commands/systemd-services.md); systemd unit templates in [using-documentation.md](notes/essential-commands/using-documentation.md); method in [troubleshooting-method.md](lab/troubleshooting-method.md)
- [ ] Monitor and troubleshoot system performance and services — [performance-monitoring.md](notes/essential-commands/performance-monitoring.md)
- [ ] Determine application and service specific constraints — [service-constraints.md](notes/essential-commands/service-constraints.md)
- [ ] Troubleshoot diskspace issues — [diskspace-troubleshooting.md](notes/essential-commands/diskspace-troubleshooting.md)
- [ ] Work with SSL certificates — [ssl-certificates.md](notes/essential-commands/ssl-certificates.md); cert formats and per-distro trust stores also in [learning-log.md §7](lab/learning-log.md)

#### Supporting / implicitly tested

Not official competencies, but exam-relevant — benchmarks show these
carry real task weight inside other tasks:

- [using-documentation.md](notes/essential-commands/using-documentation.md) —
  man/apropos, /usr/share/doc; dropped from the official competency
  list, but still the only allowed in-exam reference
- [classics-files-and-text.md](notes/essential-commands/classics-files-and-text.md) —
  tar/rsync/dd, find, grep/sed/awk + regex, redirection, links,
  SUID/SGID/sticky
- [classics-shell-and-logging.md](notes/essential-commands/classics-shell-and-logging.md) —
  bash scripting minimums, vim speed, journalctl/rsyslog/logrotate

Checklist correction (7 → 6 items; "Read and use system documentation"
is no longer on the official list) per
[lfcs-comprehensive-coverage.md](research/lfcs-comprehensive-coverage.md)
(accessed 2026-11-03).

### Users and Groups (10%)

- [ ] Create and manage local user and group accounts — [local-users-and-groups.md](notes/users-and-groups/local-users-and-groups.md)
- [ ] Manage personal and system-wide environment profiles — [environment-profiles.md](notes/users-and-groups/environment-profiles.md)
- [ ] Configure user resource limits — [resource-limits.md](notes/users-and-groups/resource-limits.md); pam_limits in [nss-pam.md](notes/users-and-groups/nss-pam.md)
- [ ] Configure and manage ACLs — [acls.md](notes/users-and-groups/acls.md)
- [ ] Configure the system to use LDAP user and group accounts — [ldap.md](notes/users-and-groups/ldap.md), [sssd.md](notes/users-and-groups/sssd.md), [nss-pam.md](notes/users-and-groups/nss-pam.md); hands-on server build in [learning-log.md §3](lab/learning-log.md)

## Pending lab work

- Centralized user management, phases 3-7 (SSSD everywhere, CA trust
  distribution, NSS/PAM wiring per family, access filters) — plan and
  environment facts in [learning-log.md §8](lab/learning-log.md).

## Cross-cutting exam habits

The transferable skills list (read the real log, A/B isolation, verify
from the right vantage point, persistence reflex, distro mapping table)
lives in [learning-log.md §9](lab/learning-log.md) — review it before
every practice session until it's automatic.
