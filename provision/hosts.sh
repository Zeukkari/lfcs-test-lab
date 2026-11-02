#!/usr/bin/env bash
# Adds the lab's private-network hostnames to /etc/hosts on every node so they
# can resolve each other by name (handy for ssh/scp/NFS/Samba exercises).
set -euo pipefail

ENTRIES="$1"
MARKER_START="# >>> lfcs-lab hosts >>>"
MARKER_END="# <<< lfcs-lab hosts <<<"

if grep -qF "$MARKER_START" /etc/hosts 2>/dev/null; then
  exit 0
fi

{
  echo "$MARKER_START"
  echo "$ENTRIES"
  echo "$MARKER_END"
} >> /etc/hosts
