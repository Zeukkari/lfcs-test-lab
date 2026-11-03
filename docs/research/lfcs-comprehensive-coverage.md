# Research: LFCS comprehensive coverage — blueprint, exam environment, per-topic exam deltas

> Created: 2026-11-03 | All URLs accessed 2026-11-03 unless noted.
> Purpose: ground the documentation expansion that adds notes for every
> competency marked "no notes yet" in [docs/README.md](../README.md).
> Audience: planner + writers who know Linux well and need exam-specific
> deltas, not tutorials.

## Summary

The repo's competency checklist matches the official LFCS blueprint with
**one correction**: Essential Commands now has **6** competencies — "Read
and use system documentation" is no longer on the official list (it was
dropped; documentation use is still implicitly required since man pages
are the only allowed reference in the exam). The exam environment is a
`base` host + per-task SSH hosts; the official instructions name **apt,
dpkg, dnf, and yum** as the package managers to know — zypper is absent,
which strongly suggests Debian- and RHEL-family hosts only. The exact
exam distro/version is deliberately undocumented (officially
"distribution independent"); community consensus points to Ubuntu-based
hosts. All three lab families (Ubuntu 22.04, Rocky 9.8, Leap 15.6) now
default to cgroup v2 and nftables backends, so drift vs the exam is
small; the one notable lab gap is Ubuntu 22.04's podman 3.4 (no
Quadlet), while Rocky 9.8 ships podman 5.8 (Quadlet fully in scope).
Benchmark repos confirm the "classic" implicit topics (tar/find/grep/
redirection/links/scripting) deserve a cross-cutting note even though
they are no longer named competencies.

## Verdict: blueprint confirmed, with corrections

Verified against the official cert page (page `dateModified`
2026-10-30, fetched 2026-11-03, including raw-HTML extraction of the
Domains & Competencies accordion):

| Domain | Weight | Repo checklist | Verdict |
| --- | ---: | --- | --- |
| Operations Deployment | 25% | 8 items | **Confirmed, exact wording match** |
| Networking | 25% | 8 items | **Confirmed, exact wording match** |
| Storage | 20% | 7 items | **Confirmed, exact wording match** |
| Essential Commands | 20% | 7 items in repo | **Corrected: official list has 6.** "Read and use system documentation" is NOT on the current official page (0 occurrences in page HTML). Official list: Basic Git Operations; Create, configure, and troubleshoot services; Monitor and troubleshoot system performance and services; Determine application and service specific constraints; Troubleshoot diskspace issues; Work with SSL certificates |
| Users and Groups | 10% | 5 items | **Confirmed, exact wording match** |

Scope wording hints:

- "network block devices" — NBD specifically. KodeKloud's current LFCS
  course has a dedicated "Use Network Block Devices: NBD" lesson and the
  lfcs-exam-lab simulator has 4 two-node NBD tasks; treat `nbd-server`/
  `nbd-client` as literally testable, not a metaphor for iSCSI.
- "Determine application and service specific constraints" — not named
  in any official course outline chapter; best-supported interpretation
  is systemd resource controls + cgroup v2 + ulimits (see topic w).
  **[UNCERTAIN]** — verify against killer.sh attempt 1.
- "virtual file system" (Storage) — matches LFS207 Chapter 19 "Linux
  Filesystems and the VFS": /proc, /sys, mounts, filesystem types —
  i.e. VFS concepts, not VFS code.
- Keep a documentation note anyway: the dropped competency is still the
  exam's only allowed reference path (man, /usr/share/doc).

## Sources

| Title | URL | Accessed |
| --- | --- | --- |
| LFCS certification page (domains, pricing, simulator) | <https://training.linuxfoundation.org/certification/linux-foundation-certified-sysadmin-lfcs/> | 2026-11-03 |
| Important Instructions: LFCS (exam env, allowed resources) | <https://docs.linuxfoundation.org/tc-docs/certification/instructions-lfcs-and-lfce> | 2026-11-03 |
| killer.sh LFCS simulator page | <https://killer.sh/lfcs> | 2026-11-03 |
| killer.sh FAQ (remote desktop, scoring, sessions) | <https://killer.sh/faq> | 2026-11-03 |
| LFS207 course outline (chapter list) | <https://training.linuxfoundation.org/training/linux-system-administration-essentials-lfs207/> | 2026-11-03 |
| tc-docs index (no LFCS-specific FAQ exists) | <https://docs.linuxfoundation.org/tc-docs/llms.txt> | 2026-11-03 |
| Rocky 9 AppStream package listing (podman 5.8.2, el9_8) | <https://dl.rockylinux.org/pub/rocky/9/AppStream/x86_64/os/Packages/p/> | 2026-11-03 |
| SLES 15 SP6 cgroups chapter (unified v2 default, TasksMax) | <https://documentation.suse.com/sles/15-SP6/html/SLES-all/cha-tuning-cgroups.html> | 2026-11-03 |
| openSUSE Leap 15.6 release notes (iotop/delayacct) | <https://doc.opensuse.org/release-notes/x86_64/openSUSE/Leap/15.6/> | 2026-11-03 |
| EPEL 9 package listing (nbd, ncdu in EPEL not base) | <https://mirror.init7.net/fedora/epel/9/Everything/x86_64/Packages/n/> | 2026-11-03 |
| KodeKloud LFCS course TOC (benchmark, secondary) | <https://kodekloud.com/courses/linux-foundation-certified-system-administrator-lfcs> | 2026-11-03 |
| giulianopz/lfcs study notes TOC (benchmark, secondary, pre-2024 objectives) | <https://github.com/giulianopz/lfcs> | 2026-11-03 |
| Htoowaithaw/lfcs-exam-lab bank coverage (benchmark, secondary) | <https://github.com/Htoowaithaw/lfcs-exam-lab/blob/main/docs/BANK_COVERAGE.md> | 2026-11-03 |

## Q1 — Blueprint details (beyond the verdict table)

Facts from the cert page worth keeping in the study guide (all already
in docs/README.md, re-verified 2026-11-03):

- $445 exam / $625 + THRIVE-ONE / $645 + LFS207. 12 months to schedule,
  one retake, cert valid 2 years. Prices flagged as likely to change.
- "The exam is independent of distribution-specific tasks, therefore
  selecting a platform in the exam preparation checklist is no longer
  required" — direct quote; the old distro-choice checkbox is gone.
- killer.sh simulator included: 2 sessions, 36 h each from activation,
  identical 20 questions (cert page says "20-25"; killer.sh FAQ says
  LFCS = 20, "more questions than in the real exams").
- killer.sh FAQ confirms **partial scoring** in the real exam: "The
  Linux Foundation will calculate a score based on successful subtasks.
  Also considering if some subtasks are harder than others." Study-guide
  consequence: partial completion of a task still earns points — never
  leave a task fully untouched.

## Q2 — Exam environment facts

From Important Instructions (primary, accessed 2026-11-03) — these
confirm what docs/exam/strategy-and-logistics.md already captures
(17-20 tasks, 67 %, base host, certerminal, ports 8080/4505/4506,
Ctrl+Alt+W, INSERT disabled, virtual keyboard, vim/nano/emacs/git/sudo
on SSH hosts only). New or sharpened points:

- **Allowed resources**: man pages; docs installed by the distro
  (/usr/share and subdirectories); packages that are part of the
  distribution — *candidates may install packages* ("not required to
  complete tasks"). Nothing browser-based for LFCS (unlike the K8s
  exams): resources must be reachable *from the terminal*.
- **Package-manager hint**: "you will want to be familiar with standard
  package managers (**apt, dpkg, dnf, and yum**)". zypper is not
  mentioned. This is the strongest official signal about the exam
  platform mix: expect Debian-family and RHEL-family hosts;
  **openSUSE/zypper is almost certainly not in the exam environment**.
- "Installation of services and applications included in this exam may
  require modification of system security policies" — official SELinux
  trap warning (already captured in strategy doc).
- **Exam distro/version: not officially documented anywhere** (tc-docs
  has no LFCS FAQ; checked the full tc-docs index). **[UNCERTAIN]**
  Community consensus since the June-2024 exam rework is Ubuntu-based
  task hosts (older public notes, e.g. giulianopz/lfcs, used Ubuntu
  18.04/20.04; 2025-2026 reports commonly assume 24.04). No primary
  source names a version — write notes distro-neutrally and treat
  Ubuntu as the likeliest host family, RHEL-family second.
- killer.sh environment (primary for the simulator): Remote Desktop
  (XFCE) over VNC, same as the real ExamUI; simulator extras not in the
  real exam: switchable Remote Terminal, unrestricted browser. LFCS
  simulator = 20 scenarios, each question in its own encapsulated VM,
  score + Brain analysis, solutions after countdown, 36 h window.
- No 2025-2026 exam-version change announcements found on the cert page
  or tc-docs; the current exam iteration dates from the June-2024
  rework (reviews on the cert page through Apr 2026 describe the same
  format). **[UNCERTAIN]** — negative evidence only.

### Lab-vs-exam drift (Ubuntu 22.04 / Rocky 9 / Leap 15.6 lab)

| Area | Lab state | Exam-relevant delta |
| --- | --- | --- |
| cgroups | All three: cgroup v2 unified default (Ubuntu since 21.10; RHEL 9; SLE 15 SP6/Leap 15.6 — verified in SUSE docs, hybrid deprecated) | None — practice matches exam |
| Firewall backend | Ubuntu 22.04 iptables-nft default, ufw; Rocky firewalld/nft; Leap firewalld | None significant |
| netplan | 22.04 ships netplan 0.10x; 24.04 ships netplan 1.0 | YAML syntax for bonds/bridges unchanged for exam purposes; `netplan status` is new-ish (≥0.106) — don't build notes around it **[UNCERTAIN exact 22.04 point version]** |
| podman | Ubuntu 22.04 = podman 3.4.4: **no Quadlet**, `generate systemd` is the only unit path; Rocky 9.8 = podman **5.8.2** (verified in AppStream listing): Quadlet native, `generate systemd` deprecated (warns) | If the exam host is Ubuntu 24.04 (podman 4.9), Quadlet works there too; drill Quadlet on Rocky, `generate systemd` on Ubuntu 22.04, know both |
| Rocky point release | Lab "Rocky 9" boxes; current is 9.8 (el9_8) | `dnf update` brings the lab to 9.8; no exam-relevant behavior change |
| openSUSE | Leap 15.6 in lab | Likely absent from exam (zypper not named); keep as third-family breadth, deprioritize SUSE-only quirks |
| time sync | Ubuntu default systemd-timesyncd; Rocky/Leap chronyd | Matches expected exam mix; know both |

## Q3 — Per-topic exam-relevant facts

Per-family notation: **deb** = Debian/Ubuntu, **rpm** = RHEL/Rocky,
**suse** = openSUSE Leap. Facts below are standard, stable behavior;
anything version-sensitive or unverified is flagged.

### a. libvirt / virsh

- Install: deb `apt install qemu-kvm libvirt-daemon-system
  libvirt-clients virtinst` (user → group `libvirt`); rpm `dnf install
  qemu-kvm libvirt virt-install` (or `dnf group install
  "Virtualization Host"`); suse `zypper in -t pattern kvm_server
  kvm_tools`. Enable: `systemctl enable --now libvirtd` (RHEL 9 uses
  socket-activated modular daemons underneath; `libvirtd` still the
  exam-safe name).
- virsh: `list --all`, `start|shutdown|destroy|reboot DOM`,
  `autostart DOM` / `autostart --disable DOM`, `define x.xml`,
  `undefine DOM [--remove-all-storage]`, `dumpxml DOM > x.xml`,
  `edit DOM`, `console DOM`, `net-list --all`, `pool-list`,
  `domifaddr DOM`. Verify autostart: `virsh dominfo DOM | grep -i
  autostart` or /etc/libvirt/qemu/autostart/ symlink.
- virt-install minimal: `virt-install --name vm1 --memory 1024
  --vcpus 1 --disk size=5 --import --os-variant generic
  --network network=default --graphics none --noautoconsole`
  (`--cdrom`/`--location` for real installs).
- qemu-img: `create -f qcow2 disk.qcow2 5G`, `info`, `convert -f raw
  -O qcow2 in out`, `resize disk.qcow2 +2G`.
- Exam shape: define/manage an existing or XML-provided domain, set
  autostart, resize/convert an image. Nested virtualization in the
  exam VMs makes full OS installs unlikely **[UNCERTAIN]** — grading
  probably targets virsh state + persistence, not a booted guest.

### b. Container engines

- Availability: rpm → podman only in base (docker requires third-party
  repo — assume podman on RHEL-family); deb → both `docker.io` and
  `podman` in archive; suse → podman in main repo. podman = drop-in
  docker CLI (`alias docker=podman`).
- Rootless: needs /etc/subuid + /etc/subgid entries (created on modern
  useradd), `loginctl enable-linger USER` for services that outlive the
  session; rootless ports <1024 need
  `net.ipv4.ip_unprivileged_port_start` lowered.
- **Quadlet** (podman ≥ 4.4 — in scope for Rocky 9, which ships 5.8.2,
  verified): drop `web.container` into /etc/containers/systemd/ (root)
  or ~/.config/containers/systemd/ (user):
  `[Container] Image=docker.io/nginx PublishPort=8080:80
  Volume=/srv/web:/usr/share/nginx/html:Z` + `[Install]
  WantedBy=multi-user.target` → `systemctl daemon-reload` →
  `systemctl start web.service`. Unit name = file stem + `.service`.
- `podman generate systemd --new --files --name web` — deprecated in
  podman ≥ 4.7 (prints warning) but the **only** option on Ubuntu
  22.04's podman 3.4.4; place in /etc/systemd/system, `enable --now`.
- Basics to drill: `run -d --name web -p 8080:80 -v /src:/dst:Z
  --restart=always IMAGE` (`:Z`/`:z` relabel is the SELinux trap on
  rpm), `ps -a`, `images`, `logs`, `exec -it`, `inspect`,
  `login registry.example.com`, `pull/tag/push`;
  /etc/containers/registries.conf for unqualified-search registries.
- Exam shape: run a container with specific name/port/volume that
  survives reboot (quadlet or generated unit + enable).

### c. nginx reverse proxy + load balancer (and haproxy)

- Packages/paths: deb `apt install nginx`, vhosts in
  /etc/nginx/sites-available/ + symlink into sites-enabled/ (remove
  `default` when it conflicts); rpm `dnf install nginx`, drop
  /etc/nginx/conf.d/*.conf (default server lives in nginx.conf); suse
  `zypper in nginx`, vhosts in /etc/nginx/vhosts.d/*.conf.
- Minimal reverse proxy:
  `server { listen 80; server_name _;
  location / { proxy_pass http://127.0.0.1:8080;
  proxy_set_header Host $host;
  proxy_set_header X-Real-IP $remote_addr; } }`
- Load balancer: `upstream backend { server n1:8080; server n2:8080; }`
  → `proxy_pass http://backend;`. Methods: round-robin (default),
  `least_conn;`, `ip_hash;`, per-server `weight=N`,
  `backup`/`down` flags.
- Always: `nginx -t` then `systemctl reload nginx`; verify with
  `curl -s localhost | grep ...` from the right vantage point.
- **SELinux (rpm)**: proxying to a network backend fails with default
  policy → `setsebool -P httpd_can_network_connect on`. Non-standard
  listen port → `semanage port -a -t http_port_t -p tcp 8081`.
  firewalld: `--add-service=http --permanent && --reload`.
- haproxy (all families package `haproxy`): /etc/haproxy/haproxy.cfg —
  `frontend fe bind *:80 default_backend be` / `backend be balance
  roundrobin server n1 10.0.0.11:8080 check ...`; check config
  `haproxy -c -f /etc/haproxy/haproxy.cfg`. SELinux boolean
  `haproxy_connect_any` on rpm.

### d. Bridges and bonding

- nmcli (rpm; suse only if NetworkManager is active — Leap server
  installs default to **wicked**, a per-family trap):
  - Bond: `nmcli con add type bond ifname bond0 con-name bond0
    bond.options "mode=active-backup,miimon=100"` → `nmcli con add
    type ethernet ifname eth1 master bond0` (repeat per slave) →
    `nmcli con mod bond0 ipv4.addresses 192.168.56.50/24 ipv4.method
    manual` → `nmcli con up bond0`.
  - Bridge: same pattern with `type bridge ifname br0` + slaves
    `master br0`.
- netplan (deb): under `network:` —
  `bonds: { bond0: { interfaces: [eth1, eth2], parameters: { mode:
  active-backup, primary: eth1, mii-monitor-interval: 100 } } }`;
  `bridges: { br0: { interfaces: [eth1], addresses: [.../24] } }`;
  apply with `netplan try` (safer) or `netplan apply`. File perms must
  be 600 on modern netplan.
- suse/wicked: /etc/sysconfig/network/ifcfg-bond0 with
  `BONDING_MASTER=yes`, `BONDING_SLAVE_0=eth1`,
  `BONDING_MODULE_OPTS='mode=active-backup miimon=100'`; bridge via
  `BRIDGE=yes BRIDGE_PORTS=eth1`; `wicked ifup bond0`.
- Modes that matter: `active-backup` (failover, no switch config — the
  exam default guess) vs `802.3ad` (LACP, needs switch support);
  `balance-rr` for round-robin. Verify: `cat /proc/net/bonding/bond0`
  (gold), `ip -d link show bond0`, bridge: `bridge link`,
  `ip -d link show br0`.

### e. Time sync

- Default daemon: deb = systemd-timesyncd (sntp client only); rpm &
  suse = chronyd. Installing chrony on Ubuntu disables timesyncd.
- Config paths: rpm & suse /etc/chrony.conf; deb
  /etc/chrony/chrony.conf (+conf.d). Directives: `server ntp1.example
  iburst`, `pool 2.rocky.pool.ntp.org iburst`, `makestep 1.0 3`
  (step clock in first 3 updates — RHEL default config), `allow
  192.168.56.0/24` + firewalld `--add-service=ntp` when serving.
- timesyncd: /etc/systemd/timesyncd.conf `[Time] NTP=server` then
  `systemctl restart systemd-timesyncd`.
- Verify: `chronyc sources -v`, `chronyc tracking`, `chronyc makestep`
  (force), `timedatectl` ("System clock synchronized: yes", "NTP
  service: active").
- timedatectl: `set-timezone Europe/Helsinki` (list-timezones),
  `set-ntp true` (enables timesyncd *or* chronyd depending on what's
  installed), `set-time` only works with NTP off.
- Exam shape: point chrony at a given server/pool + set timezone +
  prove sync.

### f. NFS and Samba

- NFS server: deb `nfs-kernel-server`, rpm/suse `nfs-utils` →
  `nfs-server.service`. /etc/exports:
  `/srv/share 192.168.56.0/24(rw,sync,no_root_squash,no_subtree_check)`
  — no space before `(`; subnet or FQDN scoping is usually graded.
  `exportfs -ra` (reexport), `exportfs -v` / `-s`, `showmount -e host`.
  firewalld: `--add-service=nfs` (NFSv4 = 2049 only; add `mountd` +
  `rpc-bind` for v3).
- NFS client: `mount -t nfs host:/srv/share /mnt`; fstab:
  `host:/srv/share /mnt nfs defaults,_netdev 0 0` (add
  `nfsvers=4.2`, `ro`, `noexec` etc. as asked). `_netdev` = wait for
  network — graders look for it. Verify `findmnt /mnt`, `mount -a`.
- Samba server (`samba` pkg): /etc/samba/smb.conf minimal share:
  `[share] path = /srv/smb writable = yes valid users = alice`;
  `testparm` to syntax-check; user must exist locally then
  `smbpasswd -a alice`; services: rpm/suse `smb` (+`nmb`), deb `smbd`
  (+`nmbd`). SELinux (rpm): `chcon -t samba_share_t` /
  `semanage fcontext -a -t samba_share_t '/srv/smb(/.*)?'` +
  `restorecon -R`, or boolean `samba_export_all_rw` (blunt).
  firewalld `--add-service=samba`.
- CIFS client (`cifs-utils`): `mount -t cifs //host/share /mnt -o
  credentials=/root/.smbcred,uid=alice`; credentials file
  (`username=`, `password=`, optional `domain=`), `chmod 600`; fstab:
  `//host/share /mnt cifs credentials=/root/.smbcred,_netdev 0 0`.

### g. NBD

- Server (package `nbd` on rpm — **EPEL only**, verified
  nbd-3.25-1.el9 in EPEL 9; deb ships `nbd-server`/`nbd-client`; suse
  ships `nbd`): /etc/nbd-server/config:
  `[generic]` section (can be empty / `allowlist = true`) +
  `[export1]` with `exportname = /srv/disk.img`. Service
  `nbd-server`, TCP 10809.
- Client: `modprobe nbd` (persist via /etc/modules-load.d/nbd.conf),
  `nbd-client server -N export1 /dev/nbd0`, then treat /dev/nbd0 as a
  normal block device (mkfs, mount, fstab with `_netdev`). Disconnect
  `nbd-client -d /dev/nbd0`. Debian/Ubuntu also support /etc/nbdtab +
  `nbd@nbd0.service` for persistence.
- `qemu-nbd --connect=/dev/nbd0 image.qcow2` to access qcow2 images as
  block devices (then partitions appear as /dev/nbd0p1 if
  `modprobe nbd max_part=8`); `qemu-nbd --disconnect`.
- Realistic exam shape (matches KodeKloud lesson + lfcs-exam-lab's 4
  two-node tasks): server exports a file/device, client connects,
  formats, mounts, persists. Keep notes client-focused.

### h. Automounters: autofs and systemd.automount

- autofs (package `autofs`, all families): /etc/auto.master line
  `/misc /etc/auto.misc --timeout=60` (indirect map: key = subdir of
  /misc) or `/- /etc/auto.direct` (direct map: key = absolute path).
  Map entry: `share -fstype=nfs,rw host:/srv/share`. Drop-ins in
  /etc/auto.master.d/*.autofs. `systemctl enable --now autofs`.
  Gotcha: indirect mount dirs don't appear in `ls` until accessed —
  verify with `cd /misc/share` then `findmnt`.
- systemd route 1 (fstab): append options
  `x-systemd.automount,x-systemd.idle-timeout=60,_netdev` → `systemctl
  daemon-reload` + `mount -a` or `systemctl restart
  remote-fs.target`. Creates an implicit .automount unit.
- systemd route 2 (units): pair `data-share.mount` (+`.automount`) —
  unit name must match path (`systemd-escape -p --suffix=mount
  /data/share`); enable the **.automount**, not the .mount.
- Verify: `systemctl list-units '*.automount'`, `findmnt -t autofs`,
  access the path, `findmnt` again.

### i. mdadm RAID

- Create: `mdadm --create /dev/md0 --level=1 --raid-devices=2
  /dev/sdb /dev/sdc [--spare-devices=1 /dev/sdd]`; RAID5 =
  `--level=5 --raid-devices=3`. Watch `/proc/mdstat` (sync progress);
  `mdadm --detail /dev/md0`; member view `mdadm --examine /dev/sdb`.
- Manage: `--fail` + `--remove` + `--add` for disk replacement;
  `--stop`; `--assemble --scan`.
- Persistence per family: deb → `mdadm --detail --scan >>
  /etc/mdadm/mdadm.conf` then `update-initramfs -u`; rpm & suse →
  /etc/mdadm.conf, regen initramfs with `dracut -f` (only strictly
  needed if root/boot on RAID — RHEL 9 auto-assembles from superblock
  metadata for data arrays). fstab by UUID of the *array* filesystem.
  Keep brief in notes: conf + initramfs refresh is the reboot-surviving
  combo.

### j. cryptsetup / LUKS

- `cryptsetup luksFormat /dev/sdb1` (LUKS2 is the default format on
  all current families, cryptsetup ≥ 2.1), confirm with uppercase YES +
  passphrase. Open: `cryptsetup open /dev/sdb1 secret` (legacy alias
  luksOpen) → /dev/mapper/secret → mkfs/mount as usual. `close`,
  `luksAddKey`, `luksDump` (slots), `cryptsetup status secret`.
- Boot wiring: /etc/crypttab
  `secret UUID=<luks-partition-uuid> none luks` (3rd field = keyfile
  path or `none` → passphrase prompt at boot); fstab mounts
  `/dev/mapper/secret`. Keyfile flow: `dd if=/dev/urandom
  of=/root/.lukskey bs=512 count=8`, `chmod 0400`, `cryptsetup
  luksAddKey /dev/sdb1 /root/.lukskey`, keyfile path into crypttab.
- UUID source: `blkid /dev/sdb1` (the LUKS container UUID, not the
  inner fs). Verify end state: reboot or `cryptsetup close` + `systemd
  daemon-reload` + `systemctl start systemd-cryptsetup@secret`.

### k. Swap

- Partition/LV: `mkswap /dev/vg0/swap`, `swapon /dev/vg0/swap`,
  fstab `UUID=... none swap defaults 0 0`; verify `swapon --show`,
  `free -h`. `swapoff` before resizing an LV-backed swap.
- Swap file: `fallocate -l 1G /swapfile` (or dd), `chmod 600`,
  `mkswap`, `swapon`, fstab `/swapfile none swap defaults 0 0`.
- **btrfs caveat (openSUSE default root fs)**: swapfile must be NOCOW
  and uncompressed — easiest modern path `btrfs filesystem mkswapfile
  --size 1g /swap/swapfile`; manual path: create empty file,
  `chattr +C`, then fill + mkswap. Snapshots of the containing
  subvolume break it; SUSE convention is a dedicated subvolume.
  fallocate-created holes are also rejected on btrfs.
- `vm.swappiness` (default 60) via `sysctl -w` + /etc/sysctl.d for
  persistence — a natural combined task with topic o.
- zram: mention only — `zram-generator` (rpm) / `zram-tools` (deb);
  not a likely exam task.

### l. Job scheduling

- cron: `crontab -e|-l|-r [-u user]`; fields `m h dom mon dow`.
  /etc/crontab and /etc/cron.d/* include the **user field** (classic
  trap vs user crontabs); /etc/cron.{hourly,daily,weekly,monthly} run
  via run-parts; file in cron.d must be root-owned, not world-writable,
  no dot in name.
- anacron (`cronie-anacron` on rpm, `anacron` on deb):
  /etc/anacrontab `period delay job-id command`, RANDOM_DELAY,
  START_HOURS_RANGE — catches up missed daily/weekly/monthly runs.
- at (`at` pkg, service `atd`): `echo 'cmd' | at 10:00`,
  `at now + 5 minutes`, `atq`, `atrm N`, `batch` (load-based).
- systemd timers: pair backup.timer + backup.service;
  `[Timer] OnCalendar=Mon..Fri 10:00` (validate with
  `systemd-analyze calendar 'Mon..Fri 10:00'`), `Persistent=true`
  (anacron-equivalent catch-up), `OnBootSec=`/`OnUnitActiveSec=`
  (monotonic), `RandomizedDelaySec=`. `systemctl enable --now
  backup.timer`; inspect `systemctl list-timers --all`. Transient:
  `systemd-run --on-calendar='*:0/5' /usr/local/bin/x` or
  `--on-active=30s`.
- Verifying completion per family: `journalctl -u backup.service`
  everywhere; cron logs → rpm /var/log/cron; deb journal +
  /var/log/syslog (`grep CRON`); suse journal (/var/log/messages via
  rsyslog if installed). `systemctl status cron|crond|cronie` naming:
  deb `cron`, rpm `crond`, suse `cron`.

### m. Package management mapping (apt/dpkg vs dnf/rpm vs zypper)

| Task | deb (apt/dpkg) | rpm (dnf/rpm) | suse (zypper/rpm) |
| --- | --- | --- | --- |
| search | `apt search x` | `dnf search x` | `zypper se x` |
| info | `apt show x` | `dnf info x` | `zypper if x` |
| install specific version | `apt install x=1.2-3` (`apt-cache madison x` to list) | `dnf install x-1.2-3` (`dnf --showduplicates list x`) | `zypper in x=1.2-3` |
| downgrade | `apt install x=older` | `dnf downgrade x` | `zypper in --oldpackage x=older` |
| hold / lock | `apt-mark hold x` (unhold, showhold) | `dnf versionlock add x` (plugin `python3-dnf-plugin-versionlock`) | `zypper al x` (rl, ll) |
| history / rollback | /var/log/apt/history.log (no undo) | `dnf history`; `dnf history undo <id>` | `zypper` has no native undo; snapper rollback on btrfs is SUSE's answer |
| add repo + GPG key | file in /etc/apt/sources.list.d/*.list (or .sources); key to /etc/apt/keyrings/x.gpg + `signed-by=` (apt-key is dead); `apt update` | `dnf config-manager --add-repo URL` or .repo in /etc/yum.repos.d/ with `gpgcheck=1 gpgkey=URL`; `rpm --import KEY` | `zypper ar -f URL alias`; `zypper refresh` (prompts to trust key); .repo in /etc/zypp/repos.d/ |
| list files of pkg | `dpkg -L x` | `rpm -ql x` | `rpm -ql x` |
| which pkg owns file | `dpkg -S /path` | `rpm -qf /path`; for uninstalled: `dnf provides '*/file'` | `rpm -qf /path`; `zypper se --provides /path` |
| verify integrity | `debsums x` (pkg `debsums`; `dpkg -V` exists but md5-only) | `rpm -V x` / `rpm -Va` (S size, M mode, 5 digest, U/G owner, T mtime) | `rpm -V x` |
| list installed | `apt list --installed`, `dpkg -l` | `dnf list installed`, `rpm -qa` | `zypper se -i`, `rpm -qa` |
| local pkg file | `dpkg -i f.deb; apt -f install` or `apt install ./f.deb` | `dnf install ./f.rpm` (resolves deps; `rpm -ivh` doesn't) | `zypper in ./f.rpm` |
| clean cache | `apt clean` | `dnf clean all` | `zypper clean` |

Official instructions name only apt/dpkg/dnf/yum — keep the zypper
column for lab breadth, flag it as not exam-expected.

### n. Boot / failure recovery

- GRUB edit at boot: `e` on the menu entry (Shift/Esc to reveal menu on
  Ubuntu BIOS boots), edit the `linux`/`linuxefi` line, boot with
  Ctrl-X / F10.
- Root password reset, RHEL-family canonical: append `rd.break` →
  emergency shell in initramfs → `mount -o remount,rw /sysroot` →
  `chroot /sysroot` → `passwd root` → **`touch /.autorelabel`**
  (SELinux — without it the new shadow entry gets an unreadable
  context and logins keep failing) → `exit`, `exit`. Note: RHEL 9
  console may require clearing `console=` args for the prompt to show.
- Generic alternative (works deb/suse, and rpm with
  `enforcing=0`): `init=/bin/bash` → `mount -o remount,rw /` →
  `passwd` → `exec /sbin/init` (or force reboot). Ubuntu also has the
  recovery-mode menu (root shell, remount rw first).
- systemd targets: `systemd.unit=rescue.target` (single-user-ish,
  needs root password) / `emergency.target` (minimal, / read-only —
  also where systemd throws you when fstab is broken; fix entry or add
  `nofail`, `daemon-reload`, `mount -a`). Runtime: `systemctl rescue`,
  `systemctl emergency`; defaults: `systemctl get-default`,
  `set-default multi-user.target`.
- fsck: only on unmounted fs — `fsck -y /dev/vg/data` (ext4 =
  e2fsck); XFS uses `xfs_repair` (`-L` zeroes the log, last resort);
  root fs → from rescue media/initramfs or `fsck.mode=force` kernel
  param.
- GRUB reinstall + regen per family (BIOS vs UEFI):
  - deb: `grub-install /dev/sda` (BIOS; UEFI installs via
    grub-efi-amd64 to /boot/efi) + `update-grub`
    (= grub-mkconfig -o /boot/grub/grub.cfg).
  - rpm: BIOS `grub2-install /dev/sda`; UEFI: do **not** run
    grub2-install (shim/grubx64.efi come from RPMs — reinstall
    `shim-x64 grub2-efi-x64` if missing). Config: `grub2-mkconfig -o
    /boot/grub2/grub.cfg` on **both** BIOS and UEFI in RHEL 9 (the
    /boot/efi/EFI/redhat/grub.cfg is a stub). Kernel args the RHEL way:
    `grubby --update-kernel=ALL --args="foo=bar"`.
  - suse: `grub2-install /dev/sda` / `grub2-mkconfig -o
    /boot/grub2/grub.cfg`, convenience wrapper `update-bootloader`.
- Forensics: `journalctl -b -1 -p err`, `journalctl --list-boots`
  (persistent journal is default on rpm/suse; Ubuntu too since 20.04+
  via /var/log/journal).
  [ERRATUM 2026-11-03: reviewer correction — rpm/suse default is
  volatile journald (no /var/log/journal by default; rsyslog provides
  persistent /var/log/messages); deb is the persistent-by-default
  family. Verify in lab.]

### o. Kernel parameters + virtual filesystem

- Runtime: `sysctl -w net.ipv4.ip_forward=1`; read `sysctl key` or
  `cat /proc/sys/net/ipv4/ip_forward`. Persist: /etc/sysctl.d/
  99-custom.conf, apply with **`sysctl --system`** (reads the full dir
  precedence chain; bare `sysctl -p` only reads /etc/sysctl.conf).
  Search: `sysctl -a | grep pattern` (note some keys hidden without
  root).
- /proc essentials: /proc/sys ↔ sysctl namespace (dots↔slashes),
  /proc/cmdline (booted kernel args), /proc/meminfo, /proc/mounts,
  /proc/PID/{status,limits,fd,environ}, /proc/mdstat,
  /proc/net/bonding/*.
- /sys essentials: /sys/class/net/*/ (device state),
  /sys/block/*/queue/scheduler, /sys/fs/cgroup (v2 tree),
  /sys/firmware/efi (presence = UEFI boot — handy in recovery tasks).
- Modules: `lsmod`, `modinfo mod` (parameters!), `modprobe mod
  opt=val`, `modprobe -r`; persist load: /etc/modules-load.d/*.conf
  (one name per line); options/blacklist: /etc/modprobe.d/*.conf
  (`options mod opt=val`, `blacklist mod` + rebuild initramfs if
  early-boot).

### p. Performance monitoring

- Load average: 1/5/15 min runnable+uninterruptible tasks; compare to
  `nproc`. High load + low CPU% → iowait or D-state processes
  (`ps -eo state,pid,cmd | grep '^D'`).
- top: `%us/%sy/%wa/%st`, RES vs VIRT, `P`/`M` sort keys, `1` per-CPU.
  free -h: judge by **available**, not free; buff/cache reclaimable.
  /proc/meminfo MemAvailable is the same source.
- vmstat 1: r (runq > cores = CPU pressure), b (blocked), si/so
  (nonzero = actively swapping — the classic exam signal), wa.
- iostat -xz 1 (sysstat): %util, await (ms), r/s, w/s, aqu-sz —
  storage-performance competency's main tool. pidstat -u/-d 1 for
  per-process CPU/disk.
- sar (sysstat history): `sar -u`, `-r`, `-b`, `-n DEV`, `-f` against
  archives. Enablement per family: rpm `dnf install sysstat &&
  systemctl enable --now sysstat` (collect/summary timers; data in
  /var/log/sa/saNN); deb `apt install sysstat`, set `ENABLED="true"`
  in /etc/default/sysstat, `systemctl enable --now sysstat` (data
  /var/log/sysstat); suse `zypper in sysstat` + enable service/timer.
- iotop needs root; **on Leap 15.6 it shows no SWAPIN/IO% unless
  booted with `delayacct` or `kernel.task_delayacct=1`** (verified in
  Leap 15.6 release notes) — nice cross-topic sysctl drill.
- Quick wins: `ps aux --sort=-%cpu | head`, `ss -s`, `systemd-cgtop`
  (bridges to topic w), `df -h`/`iostat` for storage pressure.

### q. SSL certificates with openssl

- Self-signed one-liner: `openssl req -x509 -newkey rsa:4096 -nodes
  -keyout key.pem -out cert.pem -days 365 -subj "/CN=www.example.com"
  [-addext "subjectAltName=DNS:www.example.com"]`.
- CSR: `openssl req -new -newkey rsa:4096 -nodes -keyout key.pem -out
  site.csr -subj "/C=FI/O=Org/CN=www.example.com"`; inspect
  `openssl req -in site.csr -noout -text`.
- Inspect cert: `openssl x509 -in cert.pem -noout -text` (and
  `-subject -issuer -dates -enddate -serial -fingerprint`).
- Verify chain: `openssl verify -CAfile ca.pem cert.pem`. Live
  endpoint: `openssl s_client -connect host:443 -servername host
  </dev/null 2>/dev/null | openssl x509 -noout -dates`.
- Key↔cert match: `openssl x509 -noout -modulus -in cert.pem |
  openssl md5` vs `openssl rsa -noout -modulus -in key.pem | openssl
  md5` (identical hash = pair).
- PEM↔DER: `openssl x509 -in cert.pem -outform der -out cert.der`;
  reverse with `-inform der`. PKCS12: `openssl pkcs12 -export`.
- CA trust stores per family (already partly in learning-log §7):
  deb → cp *as .crt* to /usr/local/share/ca-certificates/ +
  `update-ca-certificates`; rpm → /etc/pki/ca-trust/source/anchors/ +
  `update-ca-trust`; suse → /etc/pki/trust/anchors/ +
  `update-ca-certificates` (SUSE's own tool of the same name).
  Verify: `trust list | grep -i label` (rpm/suse) or curl against the
  endpoint without `-k`.

### r. Git (exam level)

- Preinstalled on all exam SSH hosts (official instructions). Level
  tested is genuinely basic — lfcs-exam-lab allocates only 2/250 tasks;
  KodeKloud teaches clone/stage/commit/branch/remote. Expect: `git
  clone URL [dir]`, `git init`, `status`, `add file|-A`, `commit -m`,
  `log --oneline`, `diff` / `diff --staged`, `branch`, `switch -c x` /
  `checkout -b x`, `merge x`, `push`/`pull` (`remote add origin URL`,
  `push -u origin main`), .gitignore (glob patterns, `!negate`).
- Trap: commits fail without identity — `git config --global
  user.email a@b` + `user.name`. Local-only remotes (file paths /
  second directory) are how a lab/exam grades push/pull without
  internet.

### s. Users and groups (local)

- useradd: `-m -s /bin/bash -G wheel -u 1234 -e 2026-12-31 user`.
  Family deltas: deb useradd does **not** create home by default
  (`-m` required; interactive `adduser` is the deb convenience), rpm &
  suse do (login.defs CREATE_HOME yes). Defaults: `useradd -D` ↔
  /etc/default/useradd (shell, skel, inactive); /etc/login.defs
  (UID_MIN, UMASK, PASS_MAX_DAYS, ENCRYPT_METHOD).
- Admin group: deb `sudo`, rpm `wheel`, suse `wheel` but **openSUSE
  ships `Defaults targetpw` in /etc/sudoers** — sudo asks for *root's*
  password until that line is removed/overridden (classic SUSE trap).
- usermod: `-aG grp` (**append** — forgetting -a wipes groups), `-L/-U`
  lock/unlock, `-s /usr/sbin/nologin`, `-e`/`-f`, `-d -m` move home.
  passwd `-l/-u` (prefixes ! in shadow), `-S` status, `-e` expire now.
- chage: `-l` list; `-M max -m min -W warn`, `-E YYYY-MM-DD` account
  expiry, `-d 0` force password change at next login.
- Groups: `groupadd -g 5000 g`, `groupmod -n new old`, `groupdel`;
  `gpasswd -a user g` / `-d`; `newgrp g`; `id user`,
  `getent passwd|group x` as the grader-style verification.
- sudoers: always `visudo` (or `visudo -cf file` for drop-ins);
  drop-ins /etc/sudoers.d/name (no dots, 0440). Syntax:
  `alice ALL=(ALL) NOPASSWD: /usr/bin/systemctl restart nginx`,
  `%devs ALL=(root) /usr/bin/less`. Verify as grader: `sudo -l -U
  alice`.
- /etc/skel → copied on `useradd -m` (template-env tasks: drop file in
  skel, create user, prove it landed). System accounts: `useradd -r`
  (low UID, no aging, no home unless -m).

### t. Environment profiles (login vs non-login)

- Login shells (ssh, su -): /etc/profile → /etc/profile.d/*.sh →
  first of ~/.bash_profile, ~/.bash_login, ~/.profile. Interactive
  non-login (new terminal): /etc/bash.bashrc (deb, suse) or
  /etc/bashrc (rpm) → ~/.bashrc. Stock dotfiles chain them (deb
  ~/.profile sources ~/.bashrc; rpm ~/.bash_profile sources ~/.bashrc)
  — but `su` without `-` still skips profile: the classic exam
  explanation for "variable missing".
- System-wide custom vars: drop /etc/profile.d/custom.sh (portable
  across all three families — the exam-safe answer). /etc/environment
  is pam_env: plain `KEY=value`, no shell expansion, applies to all
  PAM sessions including non-bash.
- Cron/ssh-command environments are minimal: set PATH/vars inside
  crontab or the unit, not in profiles.
- Verification: `su - user -c 'echo $VAR'` (login) vs `su user -c`
  (non-login) shows the difference a grader would check.

### u. Resource limits (user-level and systemd-level)

- pam_limits: /etc/security/limits.conf or limits.d/*.conf —
  `alice soft nofile 4096`, `@devs hard nproc 100`, `* - core 0`.
  Items: nofile, nproc, memlock, core, as. Applies on PAM login only —
  **not** to systemd services; needs pam_limits in the PAM stack
  (default on all three families).
- ulimit: `-n` files, `-u` procs, `-c` core (soft); `-Hn` hard; soft
  can be raised up to hard by the user. Live change for a running
  process: `prlimit --pid PID --nofile=4096:8192`.
- Gold verification: `cat /proc/PID/limits`; or `su - alice -c
  'ulimit -n'`.
- systemd side: per-service `[Service] LimitNOFILE=65535` (via
  `systemctl edit`); global defaults DefaultLimitNOFILE= in
  /etc/systemd/system.conf (+user.conf for user managers). User
  slices: `systemctl set-property user-1000.slice MemoryMax=1G
  TasksMax=500` (persistent drop-in created automatically). Historical
  note: logind's UserTasksMax was removed (systemd ≥ 239) → use
  TasksMax on user-.slice drop-ins. SLE/Leap ships
  DefaultTasksMax=infinity overriding the upstream 15%-of-pid_max
  default (verified in SUSE docs) — expect different defaults per
  family when demonstrating.

### v. Diskspace troubleshooting

- df vs du mismatch = deleted-but-open files: `lsof +L1` (or
  `lsof /mountpoint | grep -i deleted`); fix by restarting the holder
  or `: > /proc/PID/fd/N` (truncate through the fd). This is the
  canonical exam scenario.
- Inode exhaustion: `df -i` (ENOSPC with free blocks); find the
  culprit dir: `find /var -xdev -type d -exec sh -c 'echo "$(ls -a
  "$1" | wc -l) $1"' _ {} \; | sort -rn | head` or du --inodes
  (coreutils ≥ 8.22: `du --inodes -x / | sort -rn | head`).
- Finding bulk: `du -xh --max-depth=1 / | sort -rh | head`,
  `find / -xdev -type f -size +100M -exec ls -lh {} +`; ncdu is
  convenient but **EPEL-only on RHEL-family** (verified ncdu in EPEL
  9) — don't depend on it in notes.
- Journald: `journalctl --disk-usage`, `--vacuum-size=200M`,
  `--vacuum-time=2weeks`; persist cap via journald.conf
  `SystemMaxUse=`.
- Also: `truncate -s 0 big.log` (not rm, keeps fd valid), package
  caches (`dnf clean all` / `apt clean` / `zypper clean`), logrotate
  awareness (/etc/logrotate.d/*).

### w. "Determine application and service specific constraints"

- **Interpretation [UNCERTAIN]** — no official course chapter names it.
  KodeKloud's current TOC has no matching lesson (nearest: "Verify
  Integrity and Availability of Resources and Processes"); LFS207's
  outline has no matching chapter. Best-supported reading, consistent
  with cgroup-v2-era systemd and the Essential Commands context:
  1. systemd resource directives: `CPUQuota=50%`, `MemoryMax=512M`
     (v2 — MemoryLimit= is the v1 legacy spelling), `TasksMax=`,
     `IOReadBandwidthMax=/dev/sda 1M`, LimitNOFILE.
  2. Applying them: `systemctl set-property [--runtime] unit
     Prop=Val` (writes persistent drop-in), `systemctl edit unit`,
     `systemd-run --scope -p MemoryMax=256M cmd` for ad-hoc.
  3. Observing them: `systemd-cgtop`, `systemctl show -p MemoryMax
     -p CPUQuotaPerSecUSec unit`, `systemctl status` (Tasks/Memory
     lines), /sys/fs/cgroup/system.slice/unit/{memory.max,cpu.max}.
  4. Secondary reading: *diagnose* a constrained/failing app — ulimits
     (/proc/PID/limits), `ldd`/missing libs, ports in use (`ss
     -tlnp`), app-config limits (nginx worker_connections, db
     max_connections).
- Write the note covering 1-3 as the core and 4 as a diagnosis
  checklist; mark the scope for re-verification during killer.sh
  attempt 1 (its 20 scenarios will reveal the intended shape).

## Q4 — Content benchmarks (what other guides cover that the checklist doesn't name)

Benchmarks examined: KodeKloud LFCS course TOC (current, secondary),
Htoowaithaw/lfcs-exam-lab BANK_COVERAGE.md (250 tasks, secondary),
giulianopz/lfcs (pre-2024 objectives — historical only).

Classic topics all benchmarks drill that the current official list no
longer names explicitly (implicitly tested inside other tasks):

- **tar/compression/transfer**: tar (c/x/t, -z/-j/-J, --directory),
  gzip/bzip2/xz/zstd, rsync -a, dd. lfcs-exam-lab: 4 tasks; KodeKloud
  keeps them as "(Optional)" lessons.
- **find deep dive**: -name/-type/-size/-mtime/-perm (exact vs -/
  prefix!)/-user, -exec {} +, -xdev. 4 dedicated tasks in
  lfcs-exam-lab.
- **Text processing**: grep -rEivl, basic vs extended regex, sed -i
  substitution, awk '{print $N}', sort/uniq -c/wc/cut/tr, diff/patch.
  ~16 tasks in lfcs-exam-lab.
- **Redirection**: >, >>, 2>, 2>&1, |, tee, here-docs, /dev/null.
- **Links**: ln vs ln -s, hard-link inode semantics, readlink -f.
- **Permissions beyond ACLs**: chmod/chown/chgrp recursion, umask,
  SUID/SGID/sticky (chmod 4755/2775/1777, find / -perm -4000).
- **vim speed + bash scripting basics**: lfcs-exam-lab has 3 vim + 7
  scripting tasks (shebang, variables, if/for, exit codes, cron-safe
  PATH).
- **Logging**: journalctl filters (-u, -p, -b, --since), persistent
  journal, rsyslog basics, logrotate. 4 tasks in lfcs-exam-lab.
- **Compile from source**: ./configure && make && make install
  (KodeKloud lesson + 3 lfcs-exam-lab tasks) — maps to "install...
  software packages" wording.
- **AppArmor**: lfcs-exam-lab has 3 Ubuntu AppArmor tasks (aa-status,
  aa-complain/enforce) even though the official item names SELinux
  only. Cheap to add as a short section in the existing MAC note.
  **[UNCERTAIN]** whether the current exam tests AppArmor at all.
- Dropped from old objectives (do NOT spend effort): DNS server/zone,
  IMAP/email aliases, HTTP-server-as-topic, disk quotas
  (edquota/repquota — one-liner awareness at most), encrypted storage
  stays relevant only via LUKS (topic j).
- Primary-simulator gaps worth knowing: lfcs-exam-lab has **no
  samba/cifs, autofs, or LUKS tasks** — this repo's notes on those
  (topics f/h/j) will exceed the simulator; use the lab VMs to drill
  them.

## Options considered (ambiguity resolutions)

| Question | Options | Chosen reading | Why |
| --- | --- | --- | --- |
| "network block devices" | NBD vs generic (iSCSI etc.) | NBD literally | KodeKloud dedicated NBD lesson; nbd packages exist on all families (EPEL on rpm); simulator has NBD tasks |
| "constraints" | systemd/cgroup controls vs app-requirements diagnosis | systemd resource controls core + diagnosis checklist | cgroup-v2 era; systemctl set-property is the only exam-shaped, gradeable form |
| Exam distro | Document a version vs stay neutral | Stay neutral, Ubuntu-first + RHEL-family second | Officially undocumented; apt/dpkg/dnf/yum named, zypper absent |
| "Read and use system documentation" | Keep as competency vs drop | Keep the note, drop the checkbox claim | Removed from official list but man/-k, apropos, /usr/share/doc remain the only in-exam reference |

## Risks and unknowns

- **[UNCERTAIN]** Exact exam-host distro/version (likely Ubuntu 24.04
  family; no primary source). Mitigation: distro-neutral notes,
  killer.sh attempt 1 will reveal the real environment.
- **[UNCERTAIN]** Whether AppArmor appears on the current exam; the
  official competency says SELinux. Low-cost hedge: one short AppArmor
  subsection.
- **[UNCERTAIN]** The intended scope of "application and service
  specific constraints" — interpretation documented above; re-verify
  against killer.sh content.
- **[UNCERTAIN]** Whether libvirt tasks can require actually booting a
  guest (nested virt) — assume state/persistence grading only.
- Pricing, task counts (17-20), and killer.sh question count (20) are
  point-in-time (2026-11-03) and change without notice.
- Ubuntu 22.04 lab VMs run podman 3.4 (no Quadlet) — if the exam host
  is 24.04, Quadlet is available there; drill Quadlet on Rocky.
- openSUSE/zypper effort has low exam ROI (not named in instructions);
  it remains valuable for the repo's three-family pedagogy — a
  deliberate scope decision, not an error.
- No file outside docs/research/ was modified; the docs/README.md
  checklist correction (6 vs 7 Essential Commands items) is left for
  the planner/writers to apply.

## Implications for the study guide

1. **Fix the checklist**: Essential Commands has 6 official items;
   move "Read and use system documentation" out of the competency list
   (keep using-documentation.md as a cross-cutting exam-skills note —
   man/apropos remain the only allowed in-exam reference).
2. **Add one "implicit classics" note** (or extend
   using-documentation.md): tar/compression/rsync, find, grep/sed/awk
   - regex, redirection, links, SUID/SGID/sticky, vim speed, bash
   scripting minimums, journalctl/logging. Benchmarks show these carry
   real task weight even without a named competency.
3. **Per-family framing**: lead with Ubuntu + Rocky (the families the
   official instructions name); mark SUSE deltas as lab-only breadth.
   Highest-value per-family traps to surface in notes: deb useradd
   needs -m; openSUSE `Defaults targetpw`; Leap server uses wicked not
   NetworkManager; `:Z` volume labels on rpm; EPEL needed for
   nbd/ncdu on rpm; conf paths (sites-available vs conf.d vs
   vhosts.d; /etc/chrony/chrony.conf vs /etc/chrony.conf;
   /etc/mdadm/mdadm.conf vs /etc/mdadm.conf).
4. **Containers note must cover both unit paths**: Quadlet
   (.container files — Rocky 9 / podman ≥ 4.4) *and* podman generate
   systemd (Ubuntu 22.04 / podman 3.4), with the deprecation called
   out.
5. **Every note ends with grader-style verification** (fresh command +
   reboot-survival), matching the repo's existing habit: findmnt
   --verify, swapon --show, /proc/net/bonding/bond0, chronyc tracking,
   systemctl list-timers, sudo -l -U, /proc/PID/limits, lsof +L1,
   exportfs -s, virsh dominfo, systemctl show -p.
6. **SELinux cross-links**: reverse-proxy note needs
   httpd_can_network_connect + semanage port; containers need :Z;
   samba needs samba_share_t; recovery needs /.autorelabel. Link each
   back to selinux.md instead of repeating theory.
7. **Scheduling note should pair cron and systemd timers** with the
   same task expressed both ways + verification of completion per
   family (journalctl -u vs /var/log/cron).
8. **Storage notes**: NBD gets a small but real note (client focus);
   automounter note covers both autofs maps and x-systemd.automount;
   swap note includes the btrfs/openSUSE caveat; mdadm/LUKS notes stay
   lean (create → persist → verify).
9. **"Constraints" note**: write as systemd resource-controls
   (set-property/edit/systemd-run, systemd-cgtop, cgroup v2 paths)
   plus a short diagnosis checklist; flag for post-killer.sh revision.
10. **Boot-recovery note is per-family by design**: rd.break +
    autorelabel (rpm) vs init=/bin/bash (generic), grub2-mkconfig
    paths, grubby, update-grub, update-bootloader; UEFI-vs-BIOS GRUB
    reinstall differences.
11. **Exam-strategy doc addition**: partial scoring is confirmed —
    attempt every task's cheap subtasks (create the file, enable the
    unit) even when the full task looks long.

## Suggested follow-up checks

- [ ] During killer.sh attempt 1: record actual distro/version of the
      task hosts, presence of zypper/AppArmor/libvirt tasks, and the
      real shape of any "constraints" question; update this doc.
- [ ] Re-fetch the cert page before exam day — re-verify the 6-item
      Essential Commands list and task-count/pass-mark facts.
- [ ] Confirm Ubuntu 24.04 netplan 1.0 has no YAML syntax deltas for
      the bond/bridge snippets used in notes (lab runs 22.04).
- [ ] Spot-check Leap 15.6 podman version in the lab VM
      (`podman --version`) before writing the container note's SUSE
      column.
- [ ] Apply the docs/README.md checklist correction (Essential
      Commands: remove the 7th competency checkbox) — outside this
      agent's write scope.
