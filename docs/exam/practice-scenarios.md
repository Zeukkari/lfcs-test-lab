# Practice scenarios (original, 2026-relevant)

30 original task-shaped scenarios for drilling in this repo's lab, written
from the public 2026 blueprint (per-competency weighting in
[docs/README.md](../README.md)) and the per-topic exam-shape facts in
[docs/research/lfcs-comprehensive-coverage.md](../research/lfcs-comprehensive-coverage.md).
**Not** real exam questions — the Linux Foundation's exam policy prohibits
sharing or memorizing actual exam content (same reasoning
[practice-resources.md](practice-resources.md) used to prefer
Htoowaithaw/lfcs-exam-lab's "250 original tasks" over brain-dump repos).
These scenarios copy that approach at a smaller scale, scoped to this
repo's own 5-node lab.

Scenario count is weighted to the domain split (30 scenarios ≈
Operations Deployment 8, Networking 7, Storage 6, Essential Commands 6,
Users and Groups 3 → 27%/23%/20%/20%/10%, close to the official
25/25/20/20/10).

## How to use these

1. Pick a scenario, `vagrant up <node>` if it's not already running.
2. Set a timer: **6-7 minutes** (the real exam's average per-task budget,
   see [strategy-and-logistics.md](strategy-and-logistics.md)).
3. Man pages and `--help` only — no browser, no AI, matching the real
   exam's allowed-resources policy.
4. Run the **Verify** command(s) yourself before checking anything else —
   that's what graders actually do (end-state, not your command history).
5. Reboot the node (`vagrant reload <node>`) for any scenario that touches
   persistence (fstab, systemd enable, network config, firewall rules) —
   "works now" and "works after reboot" are different scores on the real
   exam (confirmed partial-subtask scoring, see strategy doc).
6. `vagrant destroy <node> -f && vagrant up <node>` resets a node to a
   clean slate between scenarios, including a fresh blank disk.

Each scenario: target node (family in parens), the task as it would be
phrased in an exam infobox, a **Setup** step only where the scenario needs
a fault or precondition you inject yourself first, a grader-style
**Verify**, and a cross-link to the note with the full command reference.

## Operations Deployment (25%)

### OD-1 — Diagnose and fix a failing systemd service

Node: `ubuntu-lfcs` (apt)

Setup:

```sh
sudo tee /etc/systemd/system/webapp.service <<'EOF'
[Unit]
Description=Demo webapp
[Service]
ExecStart=/usr/bin/pythonz -m http.server 8088
Restart=on-failure
[Install]
WantedBy=multi-user.target
EOF
sudo systemctl daemon-reload
sudo systemctl enable --now webapp.service
```

Task: `webapp.service` is supposed to serve on port 8088 and start on
boot, but it's failing. Find the cause, fix it, and make sure it comes up
automatically after a reboot.

Verify:

```sh
systemctl is-enabled webapp.service
systemctl is-active webapp.service
curl -s localhost:8088 | head -1
```

Note: [systemd-services.md](../notes/essential-commands/systemd-services.md),
triage order in [troubleshooting-method.md](../lab/troubleshooting-method.md).

### OD-2 — Schedule a job for another user, stdout only

Node: `rocky-lfcs` (dnf)

Task: As root, schedule a cron job for user `student` that runs
`/usr/bin/date` every day at 02:15 and appends **only** standard output
(not errors) to `/home/student/date.log`.

Trap: `crontab -e` edits *your* crontab — this needs `-u student`.

Verify:

```sh
sudo crontab -u student -l
# force a run and check the log got exactly one line, no stderr noise
sudo -u student bash -c '/usr/bin/date >> /home/student/date.log'
cat /home/student/date.log
```

Note: [job-scheduling.md](../notes/operations-deployment/job-scheduling.md).

### OD-3 — Same job, as a systemd timer with catch-up

Node: `opensuse-lfcs` (zypper)

Task: Replace the cron job from OD-2 with a `backup.timer` +
`backup.service` pair that runs `/usr/bin/date >> /var/log/date-timer.log`
every weekday at 02:15, and still runs once (late) if the machine was
powered off at that time.

Verify:

```sh
systemd-analyze calendar 'Mon..Fri 02:15'
systemctl list-timers backup.timer
systemctl show backup.timer -p Persistent
```

Note: [job-scheduling.md](../notes/operations-deployment/job-scheduling.md)
(`Persistent=true` is the catch-up flag).

### OD-4 — Pin a package version against accidental upgrade

Nodes: `ubuntu2-lfcs` (apt) **and** `rocky2-lfcs` (dnf) — do both.

Task: Install `tree` at its currently available version on both nodes,
then lock/hold it so a routine `apt upgrade` / `dnf upgrade` leaves it
alone, without blocking upgrades of anything else.

Verify:

```sh
# deb
apt-mark showhold
sudo apt update && sudo apt upgrade -s | grep -i tree   # should show nothing
# rpm
dnf versionlock list
sudo dnf upgrade --assumeno | grep -i tree               # should show nothing
```

Note: [package-management.md](../notes/operations-deployment/package-management.md).

### OD-5 — Persistent IP forwarding

Node: `rocky-lfcs`

Task: Enable IPv4 forwarding immediately and make sure it's still on
after a reboot — don't just edit `/etc/sysctl.conf` and call it done.

Trap: bare `sysctl -p` only re-reads `/etc/sysctl.conf`, not the
`/etc/sysctl.d/*.conf` precedence chain.

Verify:

```sh
cat /proc/sys/net/ipv4/ip_forward
sudo sysctl --system 2>&1 | grep -i forward
# after vagrant reload rocky:
sysctl net.ipv4.ip_forward
```

Note: [kernel-parameters.md](../notes/operations-deployment/kernel-parameters.md).

### OD-6 — Containerized service that survives reboot

Nodes: `rocky2-lfcs` (podman ≥ 4.4 → Quadlet) **and** `ubuntu-lfcs`
(podman 3.4 → no Quadlet) — do both, note the different mechanism.

Task: Run an nginx container named `web`, publish host port 8080 to
container port 80, bind-mount `/srv/web` read-only into
`/usr/share/nginx/html`, and make it start on boot without a login
session.

Verify:

```sh
curl -s -o /dev/null -w '%{http_code}\n' localhost:8080
systemctl list-units '*web*' --all
# after vagrant reload <node>:
podman ps --filter name=web
```

Note: [containers.md](../notes/operations-deployment/containers.md)
(both the Quadlet `.container` unit path and `podman generate systemd`
are covered; `:Z` on the volume is the SELinux trap on Rocky).

### OD-7 — Autostart an existing VM and grow its disk

Node: `rocky-lfcs`

Task: Given an existing libvirt domain `demo1` (defined but not set to
autostart) and its backing `demo1.qcow2` image, make the domain start
automatically on host boot and grow the disk image by 2G without
destroying existing data.

Verify:

```sh
virsh dominfo demo1 | grep -i autostart
qemu-img info /var/lib/libvirt/images/demo1.qcow2 | grep -i 'virtual size'
```

Note: [virtual-machines.md](../notes/operations-deployment/virtual-machines.md)
(grading likely targets virsh/image state, not a booted guest —
`[UNCERTAIN]`, flagged in the research doc).

### OD-8 — Reset a lost root password

Nodes: `rocky-lfcs` (`rd.break` path) and `ubuntu-lfcs` (`init=/bin/bash`
path) — do both, they're genuinely different.

Task: You've lost the root password. Recover access and set it to a new
known value, without breaking SELinux login on the RHEL-family node.

Trap: on Rocky, skipping `touch /.autorelabel` before reboot leaves the
new shadow entry with an unreadable SELinux context — login fails again
on the next boot even though the password "worked" in the emergency
shell.

Verify: reboot normally, log in as root with the new password.

Note: [boot-and-recovery.md](../notes/operations-deployment/boot-and-recovery.md).

## Networking (25%)

### NW-1 — Fix and persist a static IP

Node: `ubuntu2-lfcs`

Setup: temporarily change the node's private-network address with
`sudo ip addr add 192.168.56.99/24 dev eth1` (don't touch the netplan
file yet) — this now disagrees with the saved config.

Task: Make `192.168.56.99/24` the **actual persistent** configuration on
`eth1`, surviving a reboot, without leaving the old `.14` address
reachable.

Verify:

```sh
ip -4 addr show eth1
# after vagrant reload ubuntu2:
ip -4 addr show eth1   # still .99, not .14
```

Note: [ip-ss-mtr.md](../notes/networking/ip-ss-mtr.md).

### NW-2 — Scoped NAT port redirect

Node: `rocky2-lfcs`

Task: Redirect incoming TCP port 80 to port 8080 on this host, but
**only** for traffic from the `192.168.56.0/24` subnet — traffic from
anywhere else to port 80 should behave normally (no redirect). Make the
rule persistent.

Verify:

```sh
sudo nft list ruleset | grep -A2 redirect
# from ubuntu-lfcs (same subnet):
curl -s -o /dev/null -w '%{http_code}\n' rocky2-lfcs:80
```

Note: [firewalls-and-nat.md](../notes/networking/firewalls-and-nat.md)
(DNAT/REDIRECT worked example, nftables equivalent).

### NW-3 — SSH: global hardening with one exception

Node: `ubuntu-lfcs`

Task: Disable password authentication for SSH globally, but keep it
enabled for user `student` only (everyone else must use keys).

Verify:

```sh
sudo sshd -T | grep -i passwordauthentication
sudo sshd -T -C user=student,host=localhost,addr=127.0.0.1 2>/dev/null \
  | grep -i passwordauthentication
```

Note: [ssh.md](../notes/networking/ssh.md) (`Match User` block).

### NW-4 — Passwordless SSH trust between two nodes

Nodes: `ubuntu-lfcs` → `ubuntu2-lfcs`

Task: Set up key-based SSH from the `student` user on `ubuntu-lfcs` to
the `student` user on `ubuntu2-lfcs`, then disable password
authentication on `ubuntu2-lfcs` entirely.

Verify:

```sh
# from ubuntu-lfcs as student:
ssh ubuntu2-lfcs 'hostname'          # no password prompt
ssh -o PreferredAuthentications=password ubuntu2-lfcs 'echo should-fail'
```

Note: [ssh.md](../notes/networking/ssh.md).

### NW-5 — Point time sync at explicit servers and force it

Node: `opensuse-lfcs`

Task: Configure chrony to use `pool 2.pool.ntp.org iburst` as its only
time source, set the system timezone to `Europe/Helsinki`, and force an
immediate step if the clock is more than a second off.

Verify:

```sh
chronyc sources -v
chronyc tracking
timedatectl | grep -i 'time zone\|synchronized'
```

Note: [time-sync.md](../notes/networking/time-sync.md).

### NW-6 — Active-backup bond, persistent

Node: `rocky-lfcs`

Task: Bond a second interface to the existing `eth1` in active-backup
mode, name it `bond0`, give it `192.168.56.60/24`, and make it survive a
reboot. (No second NIC in the base lab config — add one in the
Vagrantfile for this drill, or practice the config against a spare
loopback-style dummy interface if you just want the syntax.)

Verify:

```sh
cat /proc/net/bonding/bond0
ip -d link show bond0
```

Note: [bridges-and-bonding.md](../notes/networking/bridges-and-bonding.md).

### NW-7 — nginx reverse proxy + round-robin load balancer

Nodes: `ubuntu-lfcs` (proxy) in front of `ubuntu2-lfcs` and `rocky-lfcs`
(backends, each serving a distinct string on port 8080)

Task: Configure nginx on `ubuntu-lfcs` to load-balance requests across
both backends on port 80, round-robin, and reload without downtime.

Verify:

```sh
for i in 1 2 3 4; do curl -s localhost; done   # alternates backend strings
sudo nginx -t
```

Note: [reverse-proxy-lb.md](../notes/networking/reverse-proxy-lb.md)
(SELinux `httpd_can_network_connect` is the classic 502 trap on the
RHEL-family backend).

## Storage (20%)

### ST-1 — LVM: exact size, mount, then extend online

Node: `rocky-lfcs` (blank 5 GiB disk, usually `/dev/sdb`)

Task: Build a volume group `vg_data` on the blank disk, carve out a
logical volume `lv_app` of **exactly 2G**, format it ext4, mount it at
`/srv/app` persistently, then grow it by 1G without unmounting or losing
data.

Verify:

```sh
lvs vg_data/lv_app
df -h /srv/app
sudo umount /srv/app && sudo mount -a && findmnt /srv/app
```

Note: [lvm.md](../notes/storage/lvm.md) (`lvextend -L +1G ... --resizefs`
handles resize+grow in one step for both ext4 and XFS).

### ST-2 — Partition, pick a filesystem, persist the mount

Node: `ubuntu-lfcs`

Task: Partition the blank disk with a single primary partition, format
it XFS, and mount it at `/data` persistently by UUID (not by device
name).

Trap: a stale in-kernel partition table after `parted` means `mkfs` on
the new partition sometimes fails until `partprobe` runs.

Verify:

```sh
blkid /dev/sdb1
findmnt /data
sudo mount -a   # must be silent/no-op, not an error
```

Note: [partitioning-and-filesystems.md](../notes/storage/partitioning-and-filesystems.md).

### ST-3 — LUKS-encrypt the scratch disk, auto-unlock

Node: `opensuse-lfcs`

Task: Encrypt the blank disk with LUKS, store the unlock key in a
root-only keyfile (not an interactive passphrase at boot), and mount the
decrypted volume at `/secure` persistently.

Verify:

```sh
sudo cryptsetup status secure
findmnt /secure
# after vagrant reload opensuse: should mount with no passphrase prompt
```

Note: [luks.md](../notes/storage/luks.md) (two different UUIDs trap:
`blkid` on the raw partition gives the LUKS container UUID for
`/etc/crypttab`, not the inner filesystem's).

### ST-4 — Software RAID1 from loopback files

Node: `rocky2-lfcs`

Setup (the lab only gives one scratch disk per node, so fake two members
with loop files — the same trick `loyality7/lfcs-practice-tool` uses for
container-only storage drills, see
[practice-resources.md](practice-resources.md)):

```sh
sudo mkdir -p /raid-test
sudo dd if=/dev/zero of=/raid-test/d1.img bs=1M count=512
sudo dd if=/dev/zero of=/raid-test/d2.img bs=1M count=512
sudo losetup -fP /raid-test/d1.img
sudo losetup -fP /raid-test/d2.img
losetup -a   # note the /dev/loopN names
```

Task: Build a RAID1 array from the two loop devices, format it ext4,
mount it persistently, and make sure the array reassembles automatically
after a reboot.

Verify:

```sh
cat /proc/mdstat
sudo mdadm --detail /dev/md0
findmnt /dev/md0
```

Note: [raid-mdadm.md](../notes/storage/raid-mdadm.md) (persistence
needs `mdadm --detail --scan >> /etc/mdadm.conf`, no initramfs rebuild
required for a data-only array on RHEL 9).

### ST-5 — Swap file, persistent

Node: `opensuse-lfcs` (openSUSE often ends up on a btrfs root —
confirm first with `findmnt -no FSTYPE /`)

Task: Add a 512M swap file and enable it persistently.

Trap: if `/` is btrfs, a plain `fallocate`-created swapfile is rejected
(CoW + holes); use the btrfs-native path instead.

Verify:

```sh
swapon --show
free -h
```

Note: [swap.md](../notes/storage/swap.md) (`btrfs filesystem
mkswapfile` is the one-line modern fix for the btrfs case).

### ST-6 — NFS export, subnet-scoped, client with `_netdev`

Nodes: `rocky-lfcs` (server) → `rocky2-lfcs` (client)

Task: Export `/srv/nfsshare` from `rocky-lfcs` read-write to the
`192.168.56.0/24` subnet only, then mount it on `rocky2-lfcs` at
`/mnt/nfsshare` persistently, tolerating the network not being up yet at
boot.

Trap: no space before the `(` in `/etc/exports` — `host(rw)` parses,
`host (rw)` silently grants default (ro) options to everyone instead.

Verify:

```sh
# server:
exportfs -v
# client:
findmnt /mnt/nfsshare
sudo mount -a
```

Note: [remote-filesystems.md](../notes/storage/remote-filesystems.md).

## Essential Commands (20%)

### EC-1 — find + xargs cleanup, dry-run first

Node: `ubuntu-lfcs`

Setup:

```sh
sudo mkdir -p /var/log/app
for i in $(seq 1 5); do sudo dd if=/dev/zero of=/var/log/app/svc$i.log bs=1M count=$((i*2)) 2>/dev/null; done
sudo touch -d '40 days ago' /var/log/app/svc1.log /var/log/app/svc2.log
```

Task: Under `/var/log/app`, list (don't delete yet) every `.log` file
larger than 5M **or** older than 30 days, then delete exactly that set.

Verify:

```sh
find /var/log/app -type f -name '*.log' \( -size +5M -o -mtime +30 \)
# after the real delete:
find /var/log/app -type f -name '*.log' \( -size +5M -o -mtime +30 \)   # empty
```

Note: [classics-files-and-text.md](../notes/essential-commands/classics-files-and-text.md).

### EC-2 — grep/sed/awk report pipeline

Node: `rocky-lfcs`

Setup: `sudo cp /var/log/secure /tmp/auth-sample.log` (or
`/var/log/auth.log` on deb/suse nodes).

Task: From the auth log, produce a file `/tmp/failed-users.txt` listing
each username that had a failed SSH login attempt, with a count, sorted
most-frequent first, one `user count` pair per line.

Verify:

```sh
cat /tmp/failed-users.txt
wc -l /tmp/failed-users.txt
```

Note: [classics-files-and-text.md](../notes/essential-commands/classics-files-and-text.md)
(`grep -E` → `awk '{print $N}'` → `sort | uniq -c` → `sort -rn` chain).

### EC-3 — tar + rsync with exact extraction path

Node: `opensuse-lfcs`

Task: Archive `/etc/nginx` (excluding `*.bak` files) into
`/root/nginx-backup.tar.gz`, then extract it into `/tmp/restore` such
that `/tmp/restore/nginx/nginx.conf` exists (not
`/tmp/restore/etc/nginx/nginx.conf`).

Verify:

```sh
tar tzf /root/nginx-backup.tar.gz | grep -c '\.bak$'   # 0
test -f /tmp/restore/nginx/nginx.conf && echo OK
```

Note: [classics-files-and-text.md](../notes/essential-commands/classics-files-and-text.md)
(the stored-name-vs-`--directory` extraction trap).

### EC-4 — Diskspace: deleted-but-open file

Node: `ubuntu2-lfcs`

Setup:

```sh
sudo dd if=/dev/zero of=/tmp/bigfile bs=1M count=200
sudo tail -f /tmp/bigfile > /dev/null &
sudo rm /tmp/bigfile
```

Task: `df -h /tmp` still shows the space as used even though
`/tmp/bigfile` is gone. Find out why and reclaim the space — without
rebooting the node, and ideally without killing the holding process if
avoidable.

Verify:

```sh
df -h /tmp
sudo lsof +L1 | grep -i deleted   # should be empty after the fix
```

Note: [diskspace-troubleshooting.md](../notes/essential-commands/diskspace-troubleshooting.md)
(`: > /proc/PID/fd/N` truncates through the still-open fd).

### EC-5 — Self-signed cert with SAN, trusted locally

Node: `rocky2-lfcs`

Task: Generate a self-signed certificate for `app.lab.internal` valid
365 days with a SAN entry (not just the CN), then install it into the
system CA trust store so `curl` validates it without `-k`.

Verify:

```sh
openssl x509 -in /etc/pki/tls/certs/app.crt -noout -ext subjectAltName
curl --cacert /etc/pki/tls/certs/app.crt https://app.lab.internal -o /dev/null -s -w '%{http_code}\n'
```

Note: [ssl-certificates.md](../notes/essential-commands/ssl-certificates.md)
(clients validate against SAN, a bare CN-only cert fails modern
verification).

### EC-6 — Cap a service's memory and CPU, prove it live

Node: `ubuntu-lfcs`

Task: Limit `webapp.service` (from OD-1) to 256M of memory and 50% of
one CPU, applied persistently, and confirm the limits are actually
enforced by the cgroup, not just set in the unit file.

Verify:

```sh
systemctl show webapp.service -p MemoryMax -p CPUQuotaPerSecUSec
cat /sys/fs/cgroup/system.slice/webapp.service/memory.max
cat /sys/fs/cgroup/system.slice/webapp.service/cpu.max
```

Note: [service-constraints.md](../notes/essential-commands/service-constraints.md).

## Users and Groups (10%)

### UG-1 — User with specific UID, group, and scoped sudo

Node: `rocky-lfcs`

Task: Create user `devops` with UID `5500`, home directory created, a
supplementary group `deployers` (create it first), and a sudoers rule
that lets `devops` run `systemctl restart webapp.service` with no
password — nothing else.

Verify:

```sh
id devops
sudo -l -U devops
# as devops, this must prompt for nothing:
sudo -u devops sudo systemctl restart webapp.service
# this must fail:
sudo -u devops sudo systemctl restart sshd
```

Note: [local-users-and-groups.md](../notes/users-and-groups/local-users-and-groups.md)
(sudoers drop-in in `/etc/sudoers.d/`, mode `0440`, no dot in filename).

### UG-2 — Password aging policy

Node: `ubuntu-lfcs`

Task: For user `student`: passwords expire every 90 days, a 7-day
warning before expiry, the account itself expires on `2027-01-01`, and
force a password change at the very next login right now.

Verify:

```sh
sudo chage -l student
```

Note: [local-users-and-groups.md](../notes/users-and-groups/local-users-and-groups.md)
(`chage -M 90 -W 7 -E 2027-01-01 -d 0 student`).

### UG-3 — Per-user process limit

Node: `opensuse-lfcs`

Task: Limit user `student` to a maximum of 50 simultaneous processes,
persistently (survives new logins, not just the current shell).

Trap: this is a PAM-login limit — it does **not** apply to systemd
services run under that user's slice, and `ulimit` in the current shell
won't show the new cap until a fresh login.

Verify:

```sh
su - student -c 'ulimit -u'
cat /proc/$(pgrep -u student -n)/limits | grep -i 'max processes'
```

Note: [resource-limits.md](../notes/users-and-groups/resource-limits.md).

## Sources

All accessed 2026-11-03 unless noted. Facts (pricing, task counts,
domain names) are cross-checked against the authoritative
[docs/research/lfcs-comprehensive-coverage.md](../research/lfcs-comprehensive-coverage.md)
rather than any single source below — several of these sources disagree
with each other and with the official page on stale details (noted
inline).

| Source | URL | Use / caveat |
| --- | --- | --- |
| Official LFCS certification page | <https://training.linuxfoundation.org/certification/linux-foundation-certified-sysadmin-lfcs/> | Domain weighting, task count, authoritative |
| killer.sh LFCS simulator page | <https://killer.sh/lfcs> | Confirms 20-25 fixed scenarios, graded, solutions provided |
| Killercoda LFCS practice page | <https://killercoda.com/lfcs> | Free in-browser Ubuntu playground + pointer to killer.sh; no curated per-topic scenario list (unlike Killercoda's CKA/CKAD pages) — only a blank sandbox, added to practice-resources.md |
| "How I Passed the LFCS" (Anyira, Medium, 2025-11-14) | <https://eodenyire.medium.com/how-i-passed-the-lfcs-a-sysadmins-guide-to-conquering-the-linux-foundation-exam-b3e2e8e919fa> | Recent (passed Aug 2024) pass report; explicitly does **not** share real questions, instead gives domain-by-domain "pro-tip" task shapes — used to ground scenario realism (cron for another user, iptables REDIRECT scoped by subnet, SSH `Match` block, LVM online resize, useradd with explicit GID, `limits.conf` nproc) without copying exam content |
| Linux Foundation forum: "Practice Questions for LFCS" | <https://forum.linuxfoundation.org/discussion/856260/practice-questions-for-lfcs> | LF staff confirm no official downloadable practice-question file exists beyond the old 2019 PDF sample; LFCS is "hands-on performance exam, not multiple choice" — reinforces why this doc writes original scenarios instead of citing a braindump |
| sailor.sh LFCS exam guide, dated 2026-05-25 | <https://sailor.sh/blog/lfcs-exam-guide-2026/> | **Unreliable for facts** — despite the 2026 date, states $395/3-year validity/choose-your-distro at signup, all contradicted by the official page and this repo's research doc (post-2024-rework exam is distro-independent, 2-year validity, ~$445). Marketing content; used only as a negative data point, not a source of facts in this doc |

See [practice-resources.md](practice-resources.md) for the evaluated
full task-bank simulators (Htoowaithaw/lfcs-exam-lab,
loyality7/lfcs-practice-tool) this doc's scenarios are modeled after in
spirit, scaled down to this repo's own lab.
