# Research: likely exam task shapes and traps — scripting, LDAP, LVM, libvirt, nftables/iptables, SELinux

> Created: 2026-11-04 | All URLs accessed 2026-11-04 unless noted.
> Purpose: second research round focused on six self-identified weak
> spots, collecting likely exam question shapes and the traps that cost
> points, plus a stale-resource detection checklist. Grounds targeted
> drilling, not new note-writing — the notes for all six topics already
> exist (cross-linked per section).
> Audience: the study-plan owner; assumes the 2026-11-03 blueprint
> research as baseline.

## Summary

Exam-passer reports (2024–2025) confirm all six topics appear on the
real exam: LDAP, time sync, proxy/LB and **iptables "come up
regularly"** (Cloudeteer 2025, 90% scorer, who lost his points
specifically on **iptables-vs-nftables persistence**); LVM and libvirt
basics are in "the usual" list of multiple passers. The 250-task
benchmark bank (`../lfcs-exam-lab`) supplies concrete validator-checked
task shapes for every topic: 7 scripting, 4 two-node LDAP, 8 LVM, 6
libvirt/cloud-image, 17 firewall/NAT, 8 SELinux (+3 AppArmor). The
validators encode the exact traps: scripts must be executable and exit
correctly, SELinux booleans must show `(on, on)` in `semanage boolean
-l` (runtime-only `setsebool` fails), nftables chains must be **base
chains** with `type filter hook input`, libvirt domains must stay
**shut off** when the task says "do not boot". On the SELinux
resource-match worry: the exam-level scope really is narrow
(modes, booleans, fcontext+restorecon, `semanage port`, audit basics) —
the bigger risk is **stale pre-2024 study material**, which is common
even in 2026-dated guides (checklist below).

## Sources

| Title | URL | Accessed |
| --- | --- | --- |
| Cloudeteer: Passing the LFCS in 2.5 days (passed Jul 2025, 90%) | <https://engineering.cloudeteer.de/blog/2025/passing-the-linux-foundation-certified-systemsadministrator-certification-in-2.5-days/> | 2026-11-04 |
| KodeKloud: Complete LFCS Study Guide (updated 2026-06-19; matches current blueprint) | <https://kodekloud.com/blog/the-complete-lfcs-study-guide-for-system-administrator-certification/> | 2026-11-04 |
| r/linuxadmin: "Just passed LFCS with score 80" (Oct 2024; search snippet only, thread 403s) | <https://www.reddit.com/r/linuxadmin/comments/1g2hjsq/just_passed_lfcs_with_score_80/> | 2026-11-04 |
| r/linuxadmin: "Passed LFCS with 84/100" (Dec 2024; search snippet only) | <https://www.reddit.com/r/linuxadmin/comments/1hbqy5o/passed_lfcs_with_84100/> | 2026-11-04 |
| killer.sh LFCS simulator page (20 scenarios, included with exam, partial sub-task scoring) | <https://killer.sh/lfcs> | 2026-11-04 |
| sailor.sh "LFCS Exam Guide 2026" (negative example: stale pre-2024 content) | <https://sailor.sh/blog/lfcs-exam-guide-2026/> | 2026-11-04 |
| Benchmark bank: 250 tasks + validators (local checkout) | `../lfcs-exam-lab/questions/`, `validate/` | 2026-11-04 |

Benchmark-bank topic counts for the six topics (from
`grep topic: questions/*.yaml`): bash scripting 4+3, LDAP accounts 4,
LVM 8, KVM/virsh 3 + cloud-image 3, ufw/nftables 6 + firewalld 5 +
NAT 6, SELinux 4+4 + AppArmor 3.

## 1. Shell scripting (Essential Commands, implicit)

Note: [classics-shell-and-logging.md](../notes/essential-commands/classics-shell-and-logging.md)
already covers the three 2026-11-04 pain points (conditionals,
arithmetic comparison, line-by-line file loop) — drill from it.

Likely task shapes (benchmark q023–q029, all "create executable
/usr/local/bin/<name>.sh"):

1. Backup script: produce a `.tar.gz` of a directory **with paths
   relative to it** (`tar -czf out.tar.gz -C /dir .`).
2. Count lines matching a pattern in a log, write **only the number**
   to a file (`grep -c PATTERN file > out`).
3. Parse a passwd-format file, select users by field (shell =
   /bin/bash), output sorted (`awk -F: '$7=="/bin/bash"{print $1}' |
   sort` or `while IFS=: read -r user _ _ _ _ _ shell`).
4. Positional arg with default: `echo "Hello, ${1:-LFCS}"`.
5. Count categories in a CSV, output `status=count` lines **in exact
   requested order** (loop over `OK WARN FAIL`, not `sort | uniq -c`).
6. mktemp workdir + cleanup via **EXIT trap**
   (`trap 'rm -rf "$tmp"' EXIT`); uppercase transform (`tr a-z A-Z`).
7. Option parsing: `--min N`, numeric filter `[ "$x" -ge "$N" ]`,
   **exit non-zero when the option is missing**.

Traps (what the validators actually catch):

- Script not executable (`chmod +x`) or missing shebang — graders
  execute the file, then check `$?`.
- `[ "$n" > 3 ]` is a **redirection**, not a comparison (creates file
  `3`, test degenerates to non-empty check); `[[ "$n" > 3 ]]` is
  **lexicographic** ("10" < "9" as strings). Numbers: `-gt/-ge/...`
  inside `[ ]`, or `(( n > 3 ))`.
- `cat file | while read` runs the loop in a subshell — counters set
  inside vanish. Use `while IFS= read -r line; do ...; done < file`.
- Output-exactness: `echo` adds `\n`; use `printf`/`echo -n` when the
  task says "exact content"; "write only the number" means no label.
- Cron/systemd minimal environment: set `PATH` inside any script a
  scheduler runs.
- No internet: find syntax via `man bash` section jumps
  (`/^SHELL GRAMMAR`, `/^ARITHMETIC EVALUATION`,
  `/^CONDITIONAL EXPRESSIONS`) — rehearse the jump, not the scroll.

## 2. LDAP (Users and Groups)

Note: [ldap.md](../notes/users-and-groups/ldap.md) (nslcd path, LDIF,
cn=config recovery) + [sssd.md](../notes/users-and-groups/sssd.md).
Exam signal: Cloudeteer lists LDAP among topics that "come up
regularly"; KodeKloud's 2026 guide teaches the **sssd** client path.

Likely task shapes (benchmark q230–q233 two-node pattern):

1. Server side: add `uid=X,ou=People,dc=...` as **posixAccount** with
   given uidNumber/homeDirectory/loginShell via `ldapadd` + LDIF.
2. Client side: point the OS at the directory — either
   `nslcd.conf` (`uri`, `base`) or `sssd.conf` — add `ldap`/`sss` to
   the `passwd:` line of `/etc/nsswitch.conf`, restart the daemon.
3. Grader check both ways: `getent passwd <user>` resolves.

Traps:

- `posixAccount` is AUXILIARY — pair with structural `person` when
  `cn`/`sn` are demanded; `gidNumber` is MUST even if unmentioned.
- `No such object (32)` + `matched DN` = parent OU missing; create
  `ou=People` first.
- Unknown suffix: root DSE `ldapsearch -x -s base -b "" namingContexts`.
  Unknown admin password: `olcRootPW` reset via
  `ldapmodify -Y EXTERNAL -H ldapi:///` (and verify it took).
- Templating a new user from `ldapsearch` output: strip operational
  attributes (entryUUID, createTimestamp...) or `ldapadd` rejects it.
- sssd path: `/etc/sssd/sssd.conf` must be **0600 root:root** or sssd
  refuses to start.
- `getent` working proves NSS only — login additionally needs PAM
  (`pam_sss`/`pam_ldap`); don't promise login verification unless
  asked.
- **[UNCERTAIN]** which client stack the exam box has pre-installed;
  the graded observable is `getent`, so either nslcd or sssd passes.
  Drill one primary (nslcd is fewer moving parts) + recognize the
  other.

## 3. LVM refresher (Storage)

Note: [lvm.md](../notes/storage/lvm.md). Exam signal: in "the usual"
list of both 2024 reddit passers; benchmark has 8 create-chain tasks
with **exact MiB sizes**.

Likely task shapes:

1. Full chain: `pvcreate /dev/X` → `vgcreate VG /dev/X` →
   `lvcreate -L <exact size> -n LV VG` → `mkfs.ext4|xfs` → mount +
   **fstab** entry (benchmark sizes like 72M/80M — exact-size checks).
2. Grow: `lvextend -r -L +2G /dev/VG/LV` (the `-r/--resizefs` matters).
3. All remaining space: `lvcreate -l 100%FREE`.
4. Extend the pool: `vgextend VG /dev/Y`, then grow the LV.
5. Snapshot: `lvcreate -s -L 1G -n snap /dev/VG/LV`;
   restore `lvconvert --merge` (KodeKloud-covered; plausible margin).

Traps:

- **Forgetting `-r`**: LV grows, filesystem doesn't — classic partial
  credit loss. Manual fallback: `resize2fs` (ext4) vs `xfs_growfs`
  (XFS, takes the **mountpoint**, must be mounted).
- **XFS cannot shrink, ever**; ext4 shrink is offline-only. `lvreduce`
  without `-r`/prior fs shrink destroys the filesystem.
- Sizes round up to extent multiples (4 MiB default) — verify with
  `lvs --units m`; create with the exact figure asked.
- fstab: test with `umount` + `mount -a` before moving on; UUID of the
  fs only exists **after** `mkfs` (re-run `blkid`).
- Reused disk prompts about existing signatures — `wipefs -a` first or
  confirm the prompt; a hung prompt in a script context looks like a
  freeze.
- Device paths: `/dev/VG/LV` and `/dev/mapper/VG-LV` are equivalent;
  graders may check either — fstab with either is fine.

## 4. libvirt refresher (Operations Deployment)

Note: [virtual-machines.md](../notes/operations-deployment/virtual-machines.md).
Exam signal: "libvirt basics such as creating a [VM]" (2024 passer);
official competency "Manage Virtual Machines (libvirt)".

Likely task shapes (benchmark q094–q099):

1. `virsh define /root/X.xml` — **"do not boot it"** (validator fails
   if `domstate` isn't `shut off`).
2. Storage pool: `virsh pool-define-as P dir --target /path` →
   `pool-build P` → `pool-start P` → `pool-autostart P` (validator:
   `pool-info` shows `State: running` + `Autostart: yes`).
3. Domain autostart: `virsh autostart dom`
   (`dominfo | grep -i autostart`).
4. qemu-img artifacts without booting anything:
   `qemu-img create -f qcow2 X.qcow2 1G`, `convert -f raw -O qcow2`,
   `resize X.qcow2 +2G`.

Traps:

- `virsh destroy` = hard power-off, **not** deletion (`undefine`
  deletes the definition; `--remove-all-storage` only when asked).
- `virsh create x.xml` makes a **transient** domain that vanishes on
  shutdown — persistence tasks need `define`.
- Starting a domain the task said to leave off fails the validator —
  read for "do not boot".
- Pool autostart and domain autostart are separate flags.
- `qemu-img resize` shrinking needs `--shrink`; conversion argument
  order is `-f <src> -O <dst> in out`.
- Grading targets virsh-visible state (`dominfo`, `dumpxml`,
  `pool-info`), not a booted guest **[UNCERTAIN]** (nested-virt
  constraints make boot-grading unlikely; carried from 2026-11-03
  research).

## 5. nftables / iptables (Networking) — untested as of 2026-11-04

Note: [firewalls-and-nat.md](../notes/networking/firewalls-and-nat.md)
is comprehensive — this is the one topic where lab time, not reading,
is the gap. Exam signal: the strongest of all six — Cloudeteer's one
lost question was **"the difference between iptables and nftables and
how to persist them"**, and he calls iptables "most important" among
the under-labbed topics.

Likely task shapes (benchmark q122–q127, qR03/13–16, q209–q214):

1. nftables from scratch: `nft add table inet X` + **base** input
   chain + `tcp dport N accept` (validator greps the live ruleset for
   `type filter hook input` — a non-base chain fails even with the
   right rule).
2. ufw: enable with given default policies + allow a port
   (`ufw default allow incoming/outgoing`, `ufw allow 18201/tcp`,
   `ufw enable`).
3. firewalld: open port **permanently** in a zone + reload
   (`--permanent --add-port=8443/tcp` + `--reload`).
4. NAT redirect with a **named custom nat chain**, DNAT to a peer, and
   `ip_forward` enabled; "locally originated" wording → nat **OUTPUT**
   hook, routed-through wording → **PREROUTING**.
5. Persist an existing runtime ruleset across reboot (the Cloudeteer
   question): deb `iptables-persistent`/`netfilter-persistent save` or
   `nft list ruleset > /etc/nftables.conf` + `systemctl enable
   nftables`; rpm `/etc/sysconfig/nftables.conf` + enable the service.

Traps:

- Base-chain requirement: `'{ type filter hook input priority 0; }'` —
  and the shell eats `{ } ;`, so single-quote it.
- firewalld dual-state: `--permanent` alone isn't active until
  `--reload`; runtime-only alone doesn't survive reboot. Graders can
  check both sides.
- Mixed-tool hosts: check what's running first (`systemctl status
  firewalld`, `ufw status`, `nft list ruleset`) and stay in one tool
  per task; iptables-nft shim rules appear inside `nft list ruleset`.
- Custom chains do nothing until a built-in/base chain **jumps** to
  them.
- `net.ipv4.ip_forward=1` runtime (`sysctl -w`) vs persistent
  (`/etc/sysctl.d/*.conf`) — NAT tasks usually want both.
- Lockout ordering on policy-drop tasks: established/related + SSH
  accept rules **before** the drop policy.
- Exact-content serving in NAT tasks: trailing newline fails
  "exact content" checks (`echo -n`/`printf`).
- `iptables-translate` converts known-iptables syntax to nft form —
  legitimate exam-time crutch, pre-installed where iptables-nft is.

Drill plan on this lab: rocky/rocky2 for firewalld + nftables
(firewalld is the RHEL default — practice disabling it before raw nft
work), ubuntu/ubuntu2 for ufw + nftables + the q209-style two-node NAT
pair.

## 6. SELinux (Operations Deployment) + "do free resources match?"

Note: [selinux.md](../notes/operations-deployment/selinux.md). Lab
constraint: SELinux drills need the **rocky/rocky2** nodes (Ubuntu
ships AppArmor).

Likely task shapes (benchmark qR01/02/07–12 + KodeKloud 2026 scope):

1. Persistently enable a boolean — validator checks
   `semanage boolean -l` shows **`(on   ,  on)`**, i.e. `setsebool`
   without `-P` fails even though `getsebool` looks right.
2. Fix a mislabeled web root: `semanage fcontext -a -t
   httpd_sys_content_t "/path(/.*)?"` + `restorecon -R` — "persistent"
   wording disqualifies bare `chcon`.
3. Ensure enforcing **persistently**: `setenforce 1` now +
   `SELINUX=enforcing` in `/etc/selinux/config`.
4. Service on a non-standard port: `semanage port -a -t http_port_t -p
   tcp 8080` (the official instructions' "may require modification of
   system security policies" warning in practice).
5. Diagnose a denial: `ausearch -m avc -ts recent | audit2why`.

Traps:

- Runtime vs persistent is the whole game: `-P` on booleans,
  fcontext-rule-then-restorecon on labels, config file on mode.
- `semanage` lives in `policycoreutils-python-utils` — may need
  installing (allowed; exam permits package installs).
- Boolean persistence proof: `semanage boolean -l -C` lists only
  customized-persistent booleans.
- AppArmor hedge: 3 benchmark tasks exist (profile file at
  `/etc/apparmor.d/usr.local.bin.X`, loaded into enforce mode in
  `aa-status`) — **[UNCERTAIN]** whether the live exam tests it;
  official wording says SELinux only. Keep it at recognition level.

Resource-match verdict: your "surprisingly uncomplicated" impression is
**correct for the current exam** — the tested surface is modes,
booleans, contexts, ports, and audit-log reading; there is no policy
writing. KodeKloud's 2026 guide depth (identical list) is the right
calibration target. The real mismatch risk is below.

## Stale-resource detection checklist

Many free guides — including some dated 2026 — still describe the
pre-June-2024 exam. Before trusting any resource, verify it states:

| Current fact | Stale tell |
| --- | --- |
| 5 domains: Ops 25 / Net 25 / Storage 20 / EC 20 / U&G 10 | 6 domains, "Essential Commands 25%", "Service Configuration" domain |
| No distro choice at scheduling (removed 2024); instructions name apt/dpkg/dnf/yum only | "choose Ubuntu/openSUSE/CentOS when scheduling", zypper emphasized |
| Cert valid 24 months (post-Apr-2024) | "valid 3 years" |
| 17–20 tasks, 67% pass, killer.sh included | "15–20 tasks, 66%", no simulator mention |
| In scope: containers, git, SSL certs, SELinux, LDAP client | Teaches BIND zones, DHCP server, Postfix, vsftpd as core topics |

Worked example: sailor.sh's "LFCS Exam Guide 2026" fails four of five
rows (old domains, distro choice, 3-year validity, Postfix/BIND/vsftpd
in scope) despite the 2026 title — treat per-topic content from such
guides as pre-rework until cross-checked. KodeKloud's blog and course
pass all rows.

## Implications for the study plan

1. Scripting: the gap is recall speed, not coverage — timed drills of
   the 7 benchmark shapes (each under 6 min) on ubuntu node; rehearse
   the `man bash` section jumps once per session.
2. LDAP: run the q230 two-node pattern once end-to-end on
   ubuntu+ubuntu2 (server LDIF + nslcd client + getent); then once
   with sssd on rocky+rocky2 for the other family.
3. LVM: one full chain + one `lvextend -r` + one 100%FREE on a fresh
   scratch disk (`vagrant destroy <node> && vagrant up <node>` resets
   it); say the XFS-no-shrink rule out loud before any resize.
4. libvirt: nested-virt lab support untested here — dry-run the virsh
   command set against a defined-but-never-booted domain XML; grading
   targets virsh state anyway **[UNCERTAIN]**.
5. nftables/iptables: highest-ROI lab time of the six (direct
   exam-loss testimony + zero hands-on so far). Order: firewalld
   (rocky) → nftables base chains (both families) → q209-style NAT
   pair → persistence on both families.
6. SELinux: current scope is as narrow as it seemed; drill the
   persistence variants on rocky and move on. Verify any new free
   resource against the checklist before absorbing its claims.
