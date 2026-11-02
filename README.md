# LFCS Study Lab

A local Vagrant + VirtualBox lab for hands-on practice toward the
**Linux Foundation Certified System Administrator (LFCS)** exam.

The real exam lets you pick your distribution from **Ubuntu, openSUSE, or
CentOS Stream** (any RHEL-family clone works the same way). This lab spins up
one VM per family so you can practice the same task three different ways and
stop relying on muscle memory from a single distro.

| Node       | Box                       | Hostname        | IP             | Family           |
|------------|---------------------------|------------------|----------------|------------------|
| `ubuntu`   | bento/ubuntu-22.04        | ubuntu-lfcs      | 192.168.56.11  | Debian (apt)     |
| `opensuse` | bento/opensuse-leap-15.6  | opensuse-lfcs    | 192.168.56.12  | SUSE (zypper)    |
| `rocky`    | bento/rockylinux-9        | rocky-lfcs       | 192.168.56.13  | RHEL (dnf)       |

Each VM has:

- A second **blank disk** (5 GiB by default) attached, untouched — for
  `fdisk`/`parted`/`mkfs`/LVM/`cryptsetup` practice without touching the OS disk.
- A **private network** address so the nodes can reach each other — for
  firewall, NFS, Samba, SSH, and routing exercises.
- A baseline toolset installed (vim/nano/tmux/git, `parted`/`lvm2`/`cryptsetup`,
  `nfs-utils`/samba/cifs-utils, `firewalld`/ufw, `quota`, `acl`, cron/at,
  `sysstat`, `tcpdump`, etc.).
- A `student` user (password `student`) with passwordless sudo, separate from
  the `vagrant` management account — mirrors the exam's `sudo -i` workflow.

## Requirements

- [Vagrant](https://www.vagrantup.com/) and [VirtualBox](https://www.virtualbox.org/) installed.
- A few GB of free RAM/CPU if running all three VMs at once (2 vCPU / 1.5 GiB
  each by default).

## Getting started

```bash
# bring up everything
vagrant up

# or just one distro at a time
vagrant up ubuntu
vagrant up opensuse
vagrant up rocky

# log in
vagrant ssh ubuntu     # (or opensuse / rocky)
sudo -i                # same elevation pattern as the real exam

# tear down
vagrant halt           # stop
vagrant destroy -f      # delete (keeps the Vagrantfile/box cache)
```

Tune resources if needed:

```bash
LFCS_CPUS=1 LFCS_MEM=1024 vagrant up
```

### Fresh disk for storage practice

Each VM's second disk shows up as a plain unformatted block device (usually
`/dev/sdb`, check with `lsblk`). Re-running `vagrant destroy node && vagrant up
node` gives you a clean disk again, since the `.vagrant/disks/*.vdi` files are
recreated from scratch after `destroy`.

### Networking between nodes

The nodes resolve each other by hostname already (`ubuntu-lfcs`,
`opensuse-lfcs`, `rocky-lfcs`) via `/etc/hosts`. SSH key trust between nodes is
deliberately **not** pre-configured — generating keys and setting up
passwordless SSH (`ssh-keygen`, `ssh-copy-id`) is itself a good exam drill, so
it's left for you to do inside the lab.

## Suggested practice mapped to exam domains

The LFCS exam covers five domains. Use the three nodes to practice the same
task across apt/dnf/zypper until the differences stop tripping you up.

- **Essential Commands** — file permissions/ACLs, `tar`/`gzip`, `grep`/`sed`/`awk`,
  process management, `systemd` units/timers, job control, `find`/`xargs`.
- **Operating Running Systems** — boot targets, `systemctl`, package
  management (`apt`/`dnf`/`zypper`), kernel modules, logging (`journalctl`,
  `rsyslog`), cron/at, performance basics (`top`, `vmstat`, `sysstat`).
- **User and Group Management** — `useradd`/`usermod`/`groupadd`, password
  aging (`chage`), `sudo`/`sudoers`, PAM/quota basics, `/etc/skel`.
- **Networking** — static IP config (netplan/NetworkManager/wicked),
  `firewalld`/`ufw`/`nftables`, routing, DNS resolution, SSH hardening, NFS and
  Samba shares between nodes over the private network.
- **Storage** — partitioning (`fdisk`/`parted`/`gdisk`), filesystems
  (ext4/xfs/btrfs), LVM (`pvcreate`/`vgcreate`/`lvcreate`/`lvextend`),
  `cryptsetup` LUKS volumes, swap, `/etc/fstab`, quotas, RAID (`mdadm`) all on
  the lab's spare disk.

## Troubleshooting

- **`storageattach` fails / controller not found**: some custom boxes name
  their VirtualBox storage controller differently. Run
  `VBoxManage showvminfo lfcs-<node> | grep Controller` and adjust the
  `--storagectl` name in `Vagrantfile` if it isn't `SATA Controller`.
- **Low RAM host**: lower `LFCS_MEM`/`LFCS_CPUS`, or only bring up one node at
  a time instead of all three.
- **Box download is slow**: boxes are large cloud images; run `vagrant up`
  once per node ahead of a study session rather than tearing everything down
  each time (use `vagrant halt`/`vagrant up` instead of `destroy` when you
  just want a clean OS state but don't need a fresh storage disk).
