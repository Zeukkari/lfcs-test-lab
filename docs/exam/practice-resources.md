# Practice labs and resources

## Paid course option

- KodeKloud LFCS prep course — NOT free. Account signup is free but full
  course (8 modules, 103 lessons, labs, 2 mock exams) needs paid subscription.
  Bundled into KodeKloud's all-access plan (190+ courses, 1280+ labs).

## Free local lab environments (GitHub)

### Best: Htoowaithaw/lfcs-exam-lab

<https://github.com/Htoowaithaw/lfcs-exam-lab>

The closest free equivalent to killer.sh for LFCS. Well-engineered:

- **250 original tasks** (not a brain dump — written for the project, no
  leaked/memorized real exam content), weighted close to real exam domains:
  Essential Commands 50, Ops & Deployment 60, Networking 60, Storage 50,
  Users/Groups 30. 215 single-node + 35 two-node.
- Architecture: restore VM snapshot → `inject/<id>.sh` (sets starting
  state) → you solve it → `validate/<id>.sh` (checks real end state: file
  content, ownership, modes, services, ports, persistence across reboot,
  exits 0/`RESULT: PASS` or non-zero/`RESULT: FAIL - <reason>`).
  `solution/<id>.sh` is the reference answer, must pass its own validator.
  `questions/<id>.yaml` holds task text, domain, difficulty, hints.
- Infra: Vagrant + VirtualBox, 3 VMs — `node1` (Ubuntu 22.04 + 8 scratch
  disks for LVM/storage), `node2` (Ubuntu), `lfcs-rocky1` (Rocky 9, since
  real exam is distro-agnostic).
- CLI launcher (`lab.py`/`lab.sh`) with **Practice Mode** (free nav, hints,
  reset) and **Exam Mode** (timed, randomized, scored, approximate
  threshold).
- Built-in self-test gate per question: `python3 lab.py --gate q005`.
- **Requires x86-64** — confirmed NO Apple Silicon support (VirtualBox
  can't run x86 Ubuntu/Rocky VMs on ARM Mac). Need the other (Intel/AMD)
  laptop for this one.
- Requirements: 8GB RAM min (16GB+ recommended), ~30-50GB disk.

### Secondary: loyality7/lfcs-practice-tool

<https://github.com/loyality7/lfcs-practice-tool> — `pip install lfcs` then `lfcs start`

- 83 scenarios confirmed on disk (matches README claim), evenly spread
  ~16-18 per domain (not exam-weighted like lfcs-exam-lab).
  essential_commands 16, networking 17, operations_deployment 16,
  storage 16, users_groups 18.
- Docker-based (Ubuntu/CentOS/Rocky images), runs natively on Mac — no
  VirtualBox/x86 VM needed. Good domains: Essential Commands, Users/Groups,
  general Ops.
- Surprisingly decent storage coverage: scenarios use `dd`-created image
  files + `losetup`/`mkfs.ext4` on loop devices rather than needing real
  block devices. Works because containers run with `privileged: True` by
  default (configurable via `DOCKER_PRIVILEGED` env var) — gives real
  loop-device/mkfs/mount capability inside the container.
- Weak spot (untested, but structurally limited): networking bonding/
  bridging and SELinux need real interfaces/kernel features a container
  can't provide regardless of privilege — expect this tool to be shallow
  there.
- Verified working on this Mac: installs cleanly in an isolated venv,
  prerequisites check passes (Docker 29.8.0), menu navigation functional
  (`lfcs list`, `lfcs start --category X --difficulty Y`). Full interactive
  session (drops into container shell) needs a real TTY — not fully
  verified end-to-end, recommend trying interactively.
- CLI also has: `lfcs stats` (progress/streaks/mastery %), `lfcs learn`
  (14 structured learning modules), `lfcs reset`.

### Other repos checked — lower value, noted for completeness

- **mickotec/devops-labs-mockexams-studyguides**
  <https://github.com/mickotec/devops-labs-mockexams-studyguides> — not yet reviewed.
- **giulianopz/lfcs** <https://github.com/giulianopz/lfcs/tree/main> — not yet reviewed.
- **Ghada-Atef/LFCS-Lab-Scripts** — manual VirtualBox build (4 NICs, 5
  extra disks) + 6 numbered "Practice Exam" setup scripts you curl/run.
  No automated validation (self-grade only). Looks like companion scripts
  for a specific paid course. Skip unless pairing with that course.
- **elliotholden/lfcs-practice-exam** and **willher/LFCS-Practice-Exam**
  — identical forks. Contain personal command-history notes per question,
  not clean task/validate pairs. Spotted errors in sample content (typos,
  wrong mount paths, redundant installs). Low quality, skip as labs — rough
  inspiration only.
- **ahsfar/LFCS-guide** — markdown cheat-sheet notes per domain + some
  standalone utility scripts (log rotation, SSL cert monitor). Useful as
  reference material, not an exam simulator (no inject/validate, no VM
  automation).

## Decision / plan

- Local study lab: **this repo** — multi-distro Vagrant/VirtualBox lab for
  practicing the same task across apt/dnf/zypper (see the top-level
  [README](../../README.md)).
- Primary task simulator: **Htoowaithaw/lfcs-exam-lab** on the Intel/AMD
  laptop via VirtualBox — most exam-faithful, full domain coverage, scored
  exam mode.
- Secondary: **loyality7/lfcs-practice-tool** on the Mac via Docker — quick
  drills, especially since storage scenarios actually work (privileged
  loop devices), good for days without laptop access.
- Supplementary notes: ahsfar/LFCS-guide for cheat-sheet style review if
  useful.
