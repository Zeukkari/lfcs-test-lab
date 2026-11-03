# Operations Deployment — SELinux (booleans, persistence, contexts)

Domain: Operations Deployment ("Create and enforce MAC using SELinux").

## Booleans

View:

```
getsebool -a                             # all booleans, current (runtime) value
getsebool httpd_can_network_connect
```

Set:

```
setsebool httpd_can_network_connect on       # runtime only — lost on reboot
setsebool -P httpd_can_network_connect on    # -P = persistent, survives reboot
```

`-P` is the key flag: without it, the change is runtime-only (kernel
state) and reverts to the policy default on next boot. `-P` writes the
change into the policy store itself.

## Validating a boolean is actually persistent

- `semanage boolean -l | grep <name>` — shows `(current, default)`; if
  they match, it's persistent. If they differ, it was only set at
  runtime (no `-P`) and will revert on reboot.

  ```
  semanage boolean -l | grep httpd_can_network_connect
  # httpd_can_network_connect  (on   ,  on)  Allow httpd to can network connect
  ```

- `semanage boolean -l -C` — lists only booleans **customized from
  their shipped default** (i.e., confirmed persistent changes). If a
  boolean isn't in this list, `-P` was never used on it, even if
  `getsebool` currently shows it `on`.
- Most authoritative: reboot and recheck with `getsebool <name>`.

## Mode and status

```
getenforce / setenforce 0|1          # current mode / toggle enforcing-permissive (runtime only)
sestatus                             # full status: mode, policy, mount point
cat /etc/selinux/config              # persistent mode setting (SELINUX=enforcing/permissive/disabled)
```

## File contexts

```
ls -Z file                           # view SELinux context on a file
chcon -t httpd_sys_content_t file    # change context (temporary — lost on relabel/restorecon)
semanage fcontext -a -t httpd_sys_content_t "/path(/.*)?"   # persistent context rule
restorecon -Rv /path                 # apply contexts from policy (after semanage fcontext)
```

`chcon` is a quick one-off change; it does not survive `restorecon` or a
full relabel. For persistent context changes, always use `semanage
fcontext -a` followed by `restorecon` to apply it.
