# Networking — ip / ss / mtr (monitoring and troubleshooting)

Domain: Networking ("Configure IPv4 and IPv6 networking", "Monitor and
troubleshoot networking", "Configure static routing").

## ip / ss (iproute2, replacing legacy net-tools)

`ifconfig`, `route`, `netstat`, `arp` come from net-tools: deprecated,
frozen, and often **not installed at all** on modern minimal systems
(exam images included). The iproute2 equivalents are worth retraining
muscle memory on.

### Legacy → modern mapping

| Legacy (net-tools) | Modern (iproute2) |
| --- | --- |
| `ifconfig` | `ip addr` / `ip link` |
| `ifconfig eth0 up` | `ip link set eth0 up` |
| `ifconfig eth0 192.168.1.10 netmask 255.255.255.0` | `ip addr add 192.168.1.10/24 dev eth0` |
| `route -n` | `ip route` |
| `route add default gw 192.168.1.1` | `ip route add default via 192.168.1.1` |
| `arp -n` | `ip neigh` |
| `netstat -tulpn` | `ss -tulpn` |
| `netstat -i` | `ip -s link` |

### Addresses and links

```bash
ip addr show                        # or just: ip a
ip -br addr                         # brief table — fastest overview
ip -br link
ip addr add 192.168.56.20/24 dev eth1
ip addr del 192.168.56.20/24 dev eth1
ip addr flush dev eth1
ip link set eth1 up
ip link set eth1 down
ip link set eth1 mtu 9000
ip -s link show eth1                # RX/TX counters, errors, drops
```

### Routes

```bash
ip route                            # or: ip r
ip route add default via 192.168.56.1
ip route add 10.0.0.0/8 via 192.168.56.1 dev eth1
ip route del 10.0.0.0/8
ip route get 8.8.8.8                # which iface/gw/source IP would be used
```

`ip route get` is the underrated one: shows exactly which interface,
gateway, and source address the kernel picks for a given destination —
faster than reasoning about the route table by eye.

### Neighbors (ARP)

```bash
ip neigh
ip neigh flush dev eth1
```

### Sockets — ss (replaces netstat)

```bash
ss -tulpn                  # TCP+UDP listeners, numeric, owning process
ss -tan                    # all TCP, numeric
ss -tan state established
ss -s                      # summary counters
```

Flag mnemonic: `t` tcp, `u` udp, `l` listening, `p` process, `n`
numeric, `a` all.

### Persistence — the exam trap

Everything above is runtime-only, lost on reboot. Persistent config is
distro-specific — know all of these since the exam mixes distros:

Ubuntu (netplan) — `/etc/netplan/*.yaml`, then `netplan try`
(auto-rollback safety net) or `netplan apply`:

```yaml
network:
  version: 2
  ethernets:
    eth1:
      addresses: [192.168.56.20/24]
      routes:
        - to: default
          via: 192.168.56.1
      nameservers:
        addresses: [1.1.1.1]
```

RHEL/Rocky (NetworkManager):

```bash
nmcli con show
nmcli con add type ethernet ifname eth1 con-name static-eth1 \
    ipv4.addresses 192.168.56.20/24 ipv4.gateway 192.168.56.1 \
    ipv4.method manual
nmcli con mod static-eth1 ipv4.dns 1.1.1.1
nmcli con up static-eth1
```

(`nmtui` is the menu-driven fallback if nmcli syntax escapes you under
exam pressure.)

Debian legacy: `/etc/network/interfaces` + `ifup`/`ifdown`.

Same grading logic as fstab / `setsebool -P` / iptables persistence: if
the grader reboots and the address/route is gone, the task fails.

## mtr (continuous traceroute + ping)

Combines traceroute (path discovery) and ping (per-hop loss/latency),
continuously updating statistics for every hop. Package: `mtr`
(`mtr-tiny` on minimal Debian).

### Usage

```bash
mtr 192.168.56.12          # interactive, live-updating (q quits)
mtr -n host                # numeric — skip DNS
mtr -b host                # show both hostnames and IPs
mtr -r -c 10 host          # report mode: 10 cycles, print, exit
mtr -rw -c 10 host         # wide report (don't truncate hostnames)
mtr -T -P 443 host         # TCP SYN probes to port 443 (vs default ICMP)
mtr -u host                # UDP probes (traceroute-style)
mtr -i 0.2 -c 50 host      # faster probe interval
```

Report mode is the scriptable/shareable form — closest to what an exam
task would ask to capture into a file:

```bash
mtr -rn -c 10 192.168.56.12 > /root/mtr-report.txt
```

### Reading the output

Columns: `Loss%` (lost probes at that hop), `Snt` (sent), `Last`/`Avg`/
`Best`/`Wrst` (RTT ms), `StDev` (jitter).

The classic interpretation trap:

- Loss at an intermediate hop that does **not** continue to later hops =
  that router rate-limiting its own ICMP TTL-exceeded replies (control
  plane), not real forwarding loss. Ignore it.
- **Real** loss starts at some hop and persists through every subsequent
  hop including the final destination.
- Likewise a high Avg RTT at one hop that doesn't carry forward is just
  that router replying slowly itself.

Judge by the destination row first; use intermediate hops only to
localize where a genuine persistent-loss pattern begins.

### Relatives

- `traceroute` — one-shot path discovery (UDP default, `-I` ICMP, `-T` TCP)
- `tracepath` — no root needed, also discovers path MTU; more often
  preinstalled on minimal systems than traceroute
