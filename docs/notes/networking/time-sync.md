# Networking — time synchronization (chrony, timesyncd, timedatectl)

Domain: Networking ("Set and synchronize system time using time
servers").

## Default daemon and config path (per-family delta)

| | deb | rpm | suse (low exam ROI) |
| --- | --- | --- | --- |
| Default daemon | systemd-timesyncd (SNTP client only) | chronyd | chronyd |
| chrony config | `/etc/chrony/chrony.conf` (+ `conf.d/`) | `/etc/chrony.conf` | `/etc/chrony.conf` |
| Serve time to clients | not with timesyncd — install chrony | yes (`allow`) | yes (`allow`) |

Installing chrony on Ubuntu disables timesyncd. Service name is
`chronyd` on rpm/suse vs `chrony` on deb — verify in lab.

**Trap:** the chrony config path is the per-family delta —
`/etc/chrony/chrony.conf` on deb vs `/etc/chrony.conf` on rpm/suse.
Editing the other family's path silently changes nothing.

## chronyd (rpm/suse default; installable on deb)

Directives in the config file:

```
server ntp1.example.com iburst     # single server; iburst = fast initial sync
pool 2.rocky.pool.ntp.org iburst   # pool of servers
makestep 1.0 3                     # step clock if off >1s in first 3 updates (RHEL default)
allow 192.168.56.0/24              # act as server for this subnet
```

```bash
systemctl restart chronyd && systemctl enable chronyd
# when serving time, open the firewall too (rpm/suse):
firewall-cmd --add-service=ntp --permanent && firewall-cmd --reload
```

## systemd-timesyncd (deb default)

/etc/systemd/timesyncd.conf:

```ini
[Time]
NTP=ntp1.example.com
```

```bash
systemctl restart systemd-timesyncd
```

SNTP client only — it cannot serve time to other hosts. A "serve the
subnet" task on Ubuntu means: install chrony (timesyncd gets disabled),
then configure `allow`.

## timedatectl (no family delta)

```bash
timedatectl list-timezones | grep -i helsinki
timedatectl set-timezone Europe/Helsinki
timedatectl set-ntp true    # enables timesyncd *or* chronyd — whichever is installed
timedatectl                 # status summary
```

**Trap:** `timedatectl set-time` only works with NTP sync off — run
`timedatectl set-ntp false` first, or it refuses.

## Verification (grader-style)

```bash
chronyc sources -v     # ^* marks the currently selected source
chronyc tracking       # offset, stratum, "Leap status: Normal"
chronyc makestep       # force an immediate step when testing impatiently
timedatectl            # "System clock synchronized: yes", "NTP service: active"
```

Reboot survivability: server/pool lines live in the config file and the
service is enabled — after a reboot, `chronyc sources -v` must show a
selected (`^*`) source and `timedatectl` must again report
"synchronized: yes" with no manual steps.

Exam shape: point chrony at a given server/pool, set the timezone,
prove sync.
