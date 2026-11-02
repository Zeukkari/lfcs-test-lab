#!/usr/bin/env bash
# Baseline toolset for LFCS practice, installed on every node regardless of
# distro family. Keeps package names mapped per family so apt/dnf/zypper all
# end up with roughly the same capabilities available.
set -euo pipefail

. /etc/os-release
FAMILY="unknown"
case "$ID" in
  ubuntu|debian) FAMILY="debian" ;;
  rocky|almalinux|centos|rhel|fedora) FAMILY="rhel" ;;
  opensuse*|sles) FAMILY="suse" ;;
esac

echo "==> Detected distro: $PRETTY_NAME (family: $FAMILY)"

case "$FAMILY" in
  debian)
    export DEBIAN_FRONTEND=noninteractive
    apt-get update -qq
    apt-get install -qq -y \
      vim nano tmux git rsync curl wget tree htop lsof strace \
      net-tools iproute2 dnsutils tcpdump \
      acl attr quota cron at sysstat \
      parted lvm2 cryptsetup xfsprogs e2fsprogs \
      nfs-common nfs-kernel-server samba samba-common-bin cifs-utils \
      ufw firewalld \
      chrony openssh-server unzip bzip2 >/dev/null
    ;;
  rhel)
    dnf install -y -q epel-release >/dev/null || true
    dnf install -y -q \
      vim nano tmux git rsync curl wget tree htop lsof strace \
      net-tools iproute bind-utils tcpdump \
      acl attr quota cronie at sysstat \
      parted lvm2 cryptsetup xfsprogs e2fsprogs \
      nfs-utils samba samba-client cifs-utils \
      firewalld \
      chrony openssh-server unzip bzip2 >/dev/null
    systemctl enable --now crond >/dev/null 2>&1 || true
    ;;
  suse)
    zypper --non-interactive --quiet refresh
    zypper --non-interactive --quiet install \
      vim nano tmux git rsync curl wget tree htop lsof strace \
      net-tools-deprecated iproute2 bind-utils tcpdump \
      acl attr quota cronie at sysstat \
      parted lvm2 cryptsetup xfsprogs e2fsprogs \
      nfs-client nfs-kernel-server samba samba-client cifs-utils \
      firewalld \
      chrony openssh unzip bzip2 >/dev/null || true
    systemctl enable --now cron >/dev/null 2>&1 || true
    ;;
  *)
    echo "Unknown distro family, skipping package install" >&2
    ;;
esac

# A dedicated non-root practice user (separate from the vagrant management
# account) with sudo, matching the "sudo -i" workflow used on the real exam.
if ! id student >/dev/null 2>&1; then
  useradd -m -s /bin/bash student
  echo 'student:student' | chpasswd
  case "$FAMILY" in
    debian) getent group sudo >/dev/null && usermod -aG sudo student ;;
    rhel|suse) getent group wheel >/dev/null && usermod -aG wheel student ;;
  esac
  echo 'student ALL=(ALL) NOPASSWD:ALL' > /etc/sudoers.d/90-student
  chmod 440 /etc/sudoers.d/90-student
fi

echo "==> Provisioning complete on $(hostname)"
