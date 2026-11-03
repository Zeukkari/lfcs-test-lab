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
in exam time." Links point to existing notes; **no notes yet** marks
material still to assess/produce.

### Operations Deployment (25%)

- [ ] Configure kernel parameters, persistent and non-persistent — *no notes yet* (sysctl basics appear in [firewalls-and-nat.md](notes/networking/firewalls-and-nat.md) ip_forward section)
- [ ] Diagnose, identify, manage, and troubleshoot processes and services — method in [troubleshooting-method.md](lab/troubleshooting-method.md)
- [ ] Manage or schedule jobs for executing commands — *no notes yet* (cron/at template tips in [using-documentation.md](notes/essential-commands/using-documentation.md))
- [ ] Search for, install, validate, and maintain software packages or repositories — *no notes yet* (package-query tricks in [using-documentation.md](notes/essential-commands/using-documentation.md))
- [ ] Recover from hardware, operating system, or filesystem failures — *no notes yet*
- [ ] Manage Virtual Machines (libvirt) — *no notes yet*
- [ ] Configure container engines, create and manage containers — *no notes yet*
- [ ] Create and enforce MAC using SELinux — [selinux.md](notes/operations-deployment/selinux.md)

### Networking (25%)

- [ ] Configure IPv4 and IPv6 networking and hostname resolution — [ip-ss-mtr.md](notes/networking/ip-ss-mtr.md) (netplan/nmcli persistence included)
- [ ] Set and synchronize system time using time servers — *no notes yet* (chrony/timedatectl)
- [ ] Monitor and troubleshoot networking — [ip-ss-mtr.md](notes/networking/ip-ss-mtr.md); firewall-vs-routing signatures in [learning-log.md §6](lab/learning-log.md)
- [ ] Configure the OpenSSH server and client — [ssh.md](notes/networking/ssh.md); PAM/kbd-interactive debugging in [learning-log.md §4](lab/learning-log.md)
- [ ] Configure packet filtering, port redirection, and NAT — [firewalls-and-nat.md](notes/networking/firewalls-and-nat.md)
- [ ] Configure static routing — `ip route` in [ip-ss-mtr.md](notes/networking/ip-ss-mtr.md); *persistence per distro still to drill*
- [ ] Configure bridge and bonding devices — *no notes yet*
- [ ] Implement reverse proxies and load balancers — *no notes yet* (nginx/haproxy)

### Storage (20%)

- [ ] Configure and manage LVM storage — [lvm.md](notes/storage/lvm.md)
- [ ] Manage and configure the virtual file system — *no notes yet*
- [ ] Create, manage, and troubleshoot filesystems — partial in [lvm.md](notes/storage/lvm.md) (mkfs, fstab)
- [ ] Use remote filesystems and network block devices — *no notes yet* (NFS/Samba/NBD; lab has nfs/samba packages preinstalled)
- [ ] Configure and manage swap space — *no notes yet*
- [ ] Configure filesystem automounters — *no notes yet* (autofs/systemd.automount)
- [ ] Monitor storage performance — *no notes yet* (iostat/sysstat preinstalled in lab)

### Essential Commands (20%)

- [ ] Basic Git operations — *no notes yet*
- [ ] Create, configure, and troubleshoot services — systemd unit templates in [using-documentation.md](notes/essential-commands/using-documentation.md); method in [troubleshooting-method.md](lab/troubleshooting-method.md)
- [ ] Monitor and troubleshoot system performance and services — *no notes yet*
- [ ] Determine application and service specific constraints — *no notes yet*
- [ ] Troubleshoot diskspace issues — *no notes yet* (df/du/ncdu, deleted-but-open files)
- [ ] Work with SSL certificates — partial: cert formats and per-distro trust stores in [learning-log.md §7](lab/learning-log.md); *openssl drills still to do*
- [ ] Read and use system documentation — [using-documentation.md](notes/essential-commands/using-documentation.md)

### Users and Groups (10%)

- [ ] Create and manage local user and group accounts — *no notes yet* (useradd/usermod/chage/sudoers)
- [ ] Manage personal and system-wide environment profiles — *no notes yet*
- [ ] Configure user resource limits — pam_limits in [nss-pam.md](notes/users-and-groups/nss-pam.md); *ulimit/limits.conf drills still to do*
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
