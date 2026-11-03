# Operations Deployment — Virtual machines (libvirt)

Domain: Operations Deployment ("Manage Virtual Machines (libvirt)").

## Install and enable per family

| | deb | rpm | suse |
| --- | --- | --- | --- |
| packages | `apt install qemu-kvm libvirt-daemon-system libvirt-clients virtinst` | `dnf install qemu-kvm libvirt virt-install` (or `dnf group install "Virtualization Host"`) | `zypper in -t pattern kvm_server kvm_tools` |
| non-root use | add user to group `libvirt` | — | — |

```
systemctl enable --now libvirtd
```

RHEL 9 actually runs socket-activated modular daemons underneath;
`libvirtd` remains the exam-safe name to enable.

## virsh lifecycle

```
virsh list --all
virsh start dom / shutdown dom / reboot dom
virsh destroy dom                    # hard power-off — NOT deletion
virsh define x.xml                   # register persistent domain from XML
virsh undefine dom                   # remove definition (--remove-all-storage to also delete disks)
virsh dumpxml dom > x.xml            # export definition
virsh edit dom                       # edit definition (validated on save)
virsh console dom
virsh autostart dom                  # start at host boot
virsh autostart --disable dom
virsh dominfo dom
virsh domifaddr dom                  # guest IP
virsh net-list --all / pool-list     # networks / storage pools
```

**Trap:** `virsh destroy` is a hard power-off, not removal — the domain
definition survives and the VM can be started again. Deleting is
`undefine`; add `--remove-all-storage` only when the task explicitly
asks for disk removal.

## virt-install minimal

```
virt-install --name vm1 --memory 1024 --vcpus 1 --disk size=5 \
  --import --os-variant generic --network network=default \
  --graphics none --noautoconsole
```

`--import` boots an existing disk image; use `--cdrom`/`--location` for
real OS installs.

## qemu-img

```
qemu-img create -f qcow2 disk.qcow2 5G
qemu-img info disk.qcow2
qemu-img convert -f raw -O qcow2 in.img out.qcow2
qemu-img resize disk.qcow2 +2G
```

## Exam shape

Define/manage an existing or XML-provided domain, set autostart,
resize/convert an image. Nested virtualization in the exam VMs makes
full OS installs unlikely **[UNCERTAIN]** — grading probably targets
virsh state + persistence, not a booted guest.

No further family delta: virsh/virt-install/qemu-img syntax is
identical on all three families — only install packaging differs (table
above).

## Grader-style verification

```
virsh list --all                           # domain state as asked
virsh dominfo dom | grep -i autostart      # Autostart: enable
ls -l /etc/libvirt/qemu/autostart/         # autostart symlink persisted
virsh dumpxml dom | grep -iE 'memory|vcpu' # settings landed in the definition
qemu-img info disk.qcow2                   # format/size after convert/resize
```

Reboot survivability: a defined (not transient) domain plus
`virsh autostart` is what makes the VM come back after a host reboot —
verify with `virsh list --all` after rebooting the host.
