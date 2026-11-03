# Operations Deployment — Kernel parameters (sysctl, modules)

Domain: Operations Deployment ("Configure kernel parameters, persistent
and non-persistent").

Scope: sysctl keys and kernel modules. The /proc and /sys tour lives in
[virtual-filesystem.md](../storage/virtual-filesystem.md).

## sysctl: runtime (non-persistent)

```
sysctl net.ipv4.ip_forward              # read one key
cat /proc/sys/net/ipv4/ip_forward       # same key via /proc
sysctl -w net.ipv4.ip_forward=1         # write — runtime only, lost on reboot
echo 1 > /proc/sys/net/ipv4/ip_forward  # equivalent write
sysctl -a | grep forward                # search keys (some hidden without root)
```

/proc/sys and the sysctl namespace are the same tree: dots map to
slashes (`net.ipv4.ip_forward` ↔ `/proc/sys/net/ipv4/ip_forward`).

## sysctl: persistent

```
echo 'net.ipv4.ip_forward = 1' > /etc/sysctl.d/99-custom.conf
sysctl --system                         # apply full directory precedence chain
```

**Trap:** bare `sysctl -p` reads **only** /etc/sysctl.conf — it ignores
/etc/sysctl.d/. After writing a drop-in, apply with `sysctl --system`,
or the file does nothing until reboot.

Classic exam pairings: `net.ipv4.ip_forward` (NAT/router tasks —
[firewalls-and-nat.md](../networking/firewalls-and-nat.md)),
`vm.swappiness` ([swap.md](../storage/swap.md)),
`net.ipv4.ip_unprivileged_port_start` (rootless containers —
[containers.md](containers.md)).

## Kernel modules: runtime

```
lsmod                                   # loaded modules
modinfo nbd                             # module info incl. parameters
modprobe nbd                            # load (resolves dependencies)
modprobe nbd max_part=8                 # load with option
modprobe -r nbd                         # unload
```

## Kernel modules: persistent

Load at boot — one module name per line in /etc/modules-load.d/:

```
echo nbd > /etc/modules-load.d/nbd.conf
```

Options and blacklisting — files in /etc/modprobe.d/:

```
# /etc/modprobe.d/local.conf
options nbd max_part=8
blacklist pcspkr
```

If the module is loaded from the initramfs (early boot), a blacklist
also needs an initramfs rebuild:

| | deb | rpm | suse |
| --- | --- | --- | --- |
| rebuild initramfs | `update-initramfs -u` | `dracut -f` | `dracut -f` |

Otherwise no family delta: /etc/sysctl.d, /etc/modules-load.d, and
/etc/modprobe.d paths and semantics are identical on all three
families.

## Grader-style verification

```
sysctl net.ipv4.ip_forward              # fresh read of the live value
sysctl --system | grep -i forward       # drop-in actually picked up
lsmod | grep nbd                        # module actually loaded
```

Reboot is the authoritative persistence check: re-run the same reads
after a reboot. A runtime-only `sysctl -w` or `modprobe` without the
matching /etc file is the classic lost-on-reboot failure.
