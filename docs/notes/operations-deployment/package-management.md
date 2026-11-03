# Operations Deployment — Package management (apt, dnf, zypper)

Domain: Operations Deployment ("Search for, install, validate, and
maintain software packages or repositories").

Exam ROI flag: the official instructions name **apt, dpkg, dnf, and
yum** only — zypper is absent. The suse column below is three-family
lab breadth, not exam-expected.

## Task mapping (the whole competency in one table)

| Task | deb (apt/dpkg) | rpm (dnf/rpm) | suse (zypper/rpm) |
| --- | --- | --- | --- |
| search | `apt search x` | `dnf search x` | `zypper se x` |
| info | `apt show x` | `dnf info x` | `zypper if x` |
| install specific version | `apt install x=1.2-3` (list: `apt-cache madison x`) | `dnf install x-1.2-3` (list: `dnf --showduplicates list x`) | `zypper in x=1.2-3` |
| downgrade | `apt install x=older` | `dnf downgrade x` | `zypper in --oldpackage x=older` |
| hold / lock version | `apt-mark hold x` (unhold, showhold) | `dnf versionlock add x` (plugin `python3-dnf-plugin-versionlock`) | `zypper al x` (rl, ll) |
| history / rollback | /var/log/apt/history.log (no undo) | `dnf history`; `dnf history undo <id>` | no native undo; snapper rollback on btrfs is SUSE's answer |
| add repo + GPG key | file in /etc/apt/sources.list.d/*.list (or .sources); key to /etc/apt/keyrings/x.gpg + `signed-by=`; `apt update` | `dnf config-manager --add-repo URL` or .repo in /etc/yum.repos.d/ with `gpgcheck=1 gpgkey=URL`; `rpm --import KEY` | `zypper ar -f URL alias`; `zypper refresh` (prompts to trust key); .repo in /etc/zypp/repos.d/ |
| list files of pkg | `dpkg -L x` | `rpm -ql x` | `rpm -ql x` |
| which pkg owns file | `dpkg -S /path` | `rpm -qf /path`; uninstalled: `dnf provides '*/file'` | `rpm -qf /path`; `zypper se --provides /path` |
| verify integrity | `debsums x` (pkg `debsums`; `dpkg -V` is md5-only) | `rpm -V x` / `rpm -Va` | `rpm -V x` |
| list installed | `apt list --installed`, `dpkg -l` | `dnf list installed`, `rpm -qa` | `zypper se -i`, `rpm -qa` |
| install local pkg file | `apt install ./f.deb` (or `dpkg -i f.deb; apt -f install`) | `dnf install ./f.rpm` (resolves deps) | `zypper in ./f.rpm` |
| clean cache | `apt clean` | `dnf clean all` | `zypper clean` |

`rpm -V` output codes: S size, M mode, 5 digest, U/G owner/group,
T mtime.

## Traps

**Trap:** `rpm -ivh f.rpm` does **not** resolve dependencies — use
`dnf install ./f.rpm` (the `./` matters; without it dnf searches repos
instead of the local file).

**Trap:** `apt-key` is dead. Keys go to /etc/apt/keyrings/x.gpg and are
referenced per-repo with `signed-by=` in the sources entry.

**Trap:** `dnf versionlock` fails until the plugin package
(`python3-dnf-plugin-versionlock`) is installed.

## Compile from source

Maps to the "install... software packages" wording — benchmarks carry
real tasks on it (research Q4):

```
tar -xzf app-1.0.tar.gz && cd app-1.0
./configure --prefix=/usr/local     # check README/INSTALL for options
make
make install                        # as root
```

Toolchain package names per family (gcc/make meta-packages): verify in
lab before relying on them.

## Grader-style verification

```
apt-mark showhold / dnf versionlock list / zypper ll   # hold actually set
rpm -V x / debsums x                                   # integrity as graded
dnf history info <id>                                  # what a transaction changed
dpkg -S /path / rpm -qf /path                          # ownership answer, fresh
apt update && apt policy x                             # deb repo live + version visible
dnf repolist / zypper lr                               # repo enabled
command -v app && app --version                        # source install landed on PATH
```

Package state survives reboot by nature — grading here is fresh-command
based: prove the hold blocks an upgrade (`apt install x` → "kept back"),
prove the repo resolves, prove the binary runs.
