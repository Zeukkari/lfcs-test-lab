#!/usr/bin/env bash
# Adds the lab's private-network hostnames to /etc/hosts on every node so they
# can resolve each other by name (handy for ssh/scp/NFS/Samba exercises).
set -euo pipefail

ENTRIES="$1"
MARKER_START="# >>> lfcs-lab hosts >>>"
MARKER_END="# <<< lfcs-lab hosts <<<"

# Idempotent AND refreshable: strip any previous block (e.g. from before a
# node was added to the Vagrantfile) before reinserting the current one, so
# `vagrant provision` always leaves every node's /etc/hosts up to date.
sed -i "/^${MARKER_START}$/,/^${MARKER_END}$/d" /etc/hosts

{
  echo "$MARKER_START"
  echo "$ENTRIES"
  echo "$MARKER_END"
} >> /etc/hosts
