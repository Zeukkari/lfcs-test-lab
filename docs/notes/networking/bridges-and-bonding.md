# Networking — bridges and bonding (nmcli, netplan, wicked)

Domain: Networking ("Configure bridge and bonding devices").

## Tool per family

| | deb | rpm | suse (low exam ROI) |
| --- | --- | --- | --- |
| Tool | netplan YAML | nmcli (NetworkManager) | wicked + ifcfg files |
| Config lives in | `/etc/netplan/*.yaml` (chmod 600) | NM connection profiles | `/etc/sysconfig/network/ifcfg-*` |
| Apply | `netplan try` / `netplan apply` | `nmcli con up` | `wicked ifup bond0` |

**Trap:** openSUSE Leap *server* installs default to **wicked**, not
NetworkManager — nmcli finds nothing to manage there. Check which one
the host runs before picking the tool.

## Bonding modes

- `active-backup` — failover only, no switch config needed: the exam
  default guess when the task names no mode
- `802.3ad` — LACP aggregation, needs switch-side support
- `balance-rr` — round-robin

## rpm — nmcli

Bond (master + one connection per slave + IP + up):

```bash
nmcli con add type bond ifname bond0 con-name bond0 \
    bond.options "mode=active-backup,miimon=100"
nmcli con add type ethernet ifname eth1 master bond0
nmcli con add type ethernet ifname eth2 master bond0
nmcli con mod bond0 ipv4.addresses 192.168.56.50/24 ipv4.method manual
nmcli con up bond0
```

Bridge — same pattern with `type bridge`:

```bash
nmcli con add type bridge ifname br0 con-name br0
nmcli con add type ethernet ifname eth1 master br0
nmcli con mod br0 ipv4.addresses 192.168.56.60/24 ipv4.method manual
nmcli con up br0
```

## deb — netplan

`/etc/netplan/60-bond.yaml` — file must be `chmod 600` (modern netplan
rejects/warns on looser permissions):

```yaml
network:
  version: 2
  ethernets:
    eth1: {}
    eth2: {}
    eth3: {}
  bonds:
    bond0:
      interfaces: [eth1, eth2]
      addresses: [192.168.56.50/24]
      parameters:
        mode: active-backup
        primary: eth1
        mii-monitor-interval: 100
  bridges:
    br0:
      interfaces: [eth3]
      addresses: [192.168.56.60/24]
```

Apply with `netplan try` (auto-rollback if connectivity dies — safer)
or `netplan apply`. A NIC can be slave to only one master (bond *or*
bridge — hence eth3 for the bridge here). `netplan status` is new-ish
(≥0.106) — don't build answers on it
**[UNCERTAIN exact 22.04 point version]**.

## suse — wicked ifcfg (low exam ROI)

`/etc/sysconfig/network/ifcfg-bond0`:

```
STARTMODE=auto
BOOTPROTO=static
IPADDR=192.168.56.50/24
BONDING_MASTER=yes
BONDING_SLAVE_0=eth1
BONDING_SLAVE_1=eth2
BONDING_MODULE_OPTS='mode=active-backup miimon=100'
```

Bridge: `ifcfg-br0` with `BRIDGE=yes` + `BRIDGE_PORTS=eth1`. Apply:
`wicked ifup bond0` / `wicked ifup br0`. (STARTMODE/BOOTPROTO/IPADDR
boilerplate is standard ifcfg but not in the research doc — verify in
lab.)

## Verification (grader-style)

```bash
cat /proc/net/bonding/bond0    # gold: mode, MII status, slaves, active slave
ip -d link show bond0
bridge link                    # bridge port membership
ip -d link show br0
```

Reboot survivability: all three mechanisms are persistent config (NM
profiles, netplan YAML, ifcfg files). After reboot, re-run
`cat /proc/net/bonding/bond0` and `bridge link` — a bond built with
runtime `ip link` commands alone disappears, which is exactly what a
grader's reboot catches.
