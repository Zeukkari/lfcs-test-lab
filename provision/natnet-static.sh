#!/usr/bin/env bash
# Assigns a static IP to the second NIC (the VirtualBox NAT Network adapter
# added via the Vagrantfile's `--nic2 natnetwork` customize call) so the nodes
# can reach each other on the lab's private subnet. Used on every host
# platform - NAT Network replaces Vagrant's built-in `private_network`
# (host-only) helper everywhere, not just on Apple Silicon, since it needs
# no host-level driver/system-extension approval on any OS. See the
# Vagrantfile header comment for why.
#
# Static-IP mechanism is picked per distro family; Ubuntu and Rocky were
# verified end-to-end (ping + raw TCP:22) on an Apple Silicon Mac under a
# Jamf-managed, system-extension-restricted profile. The openSUSE (wicked)
# path follows the same pattern documented in
# docs/notes/networking/bridges-and-bonding.md but was NOT live-booted in
# that verification session - treat it as "verify in lab" until confirmed.
set -euo pipefail

IP="$1"

. /etc/os-release
FAMILY="unknown"
case "$ID" in
  ubuntu|debian) FAMILY="debian" ;;
  rocky|almalinux|centos|rhel|fedora) FAMILY="rhel" ;;
  opensuse*|sles) FAMILY="suse" ;;
esac

# Find the NIC that has no IPv4 address yet (the fresh NAT Network adapter;
# the box's default first NIC already has a NAT-assigned address from boot).
IFACE=""
for dev in /sys/class/net/*; do
  n=$(basename "$dev")
  [ "$n" = "lo" ] && continue
  if ! ip -4 addr show dev "$n" | grep -q "inet "; then
    IFACE="$n"
    break
  fi
done

if [ -z "$IFACE" ]; then
  echo "natnet-static: no unconfigured interface found - already configured or NIC2 missing?" >&2
  exit 0
fi

echo "==> Assigning $IP/24 to $IFACE (family: $FAMILY)"

case "$FAMILY" in
  debian)
    cat > /etc/netplan/90-natnet-static.yaml <<EOF
network:
  version: 2
  ethernets:
    ${IFACE}:
      dhcp4: no
      addresses: [${IP}/24]
EOF
    chmod 600 /etc/netplan/90-natnet-static.yaml
    netplan apply
    ;;
  rhel)
    nmcli con show natnet-static >/dev/null 2>&1 && nmcli con delete natnet-static >/dev/null 2>&1 || true
    nmcli con add type ethernet ifname "$IFACE" con-name natnet-static ip4 "${IP}/24"
    nmcli con up natnet-static
    ;;
  suse)
    # verify in lab - not live-booted in the session this script was written in.
    cat > "/etc/sysconfig/network/ifcfg-${IFACE}" <<EOF
BOOTPROTO='static'
IPADDR='${IP}/24'
STARTMODE='auto'
EOF
    wicked ifup "$IFACE" || systemctl restart wicked
    ;;
  *)
    echo "natnet-static: unknown distro family, skipping static IP assignment" >&2
    ;;
esac

sleep 1
ip -4 addr show dev "$IFACE"
