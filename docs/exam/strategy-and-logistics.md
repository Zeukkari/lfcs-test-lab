# Exam strategy and logistics

Sourced from the official
[Important Instructions: LFCS](https://docs.linuxfoundation.org/tc-docs/certification/instructions-lfcs-and-lfce)
(2026-11) plus general performance-exam strategy.

## Exam environment mechanics (official)

- You start on a **base system (hostname `base`)** and `ssh <nodename>`
  to a designated host per task — an infobox at the start of each task
  says which. **Always `exit` back to base between tasks**; nested SSH
  is not supported.
- **Never reboot the base system** — it will not restart your exam
  environment (i.e., it kills it).
- The SSH hosts have vim, nano, emacs, git, sudo preinstalled; **base
  has none of these** — all real work happens on the task hosts.
- Root: `sudo -i` works on any host.
- **Do not touch the `certerminal` process** — killing it ends the exam.
- **Do not block TCP ports 8080, 4505, 4506** — these are the exam
  agent's ports. Critical trap in firewall tasks: a default-DROP INPUT
  policy without explicit accepts for these can nuke your session.
  Always scope firewall rules to exactly what the task asks, never
  broad default-deny unless the task explicitly requires it — and if it
  does, allow these ports first.
- "Installation of services and applications may require modification
  of system security policies" — official hint that SELinux will bite
  during otherwise-unrelated tasks. If a freshly configured service
  mysteriously fails: `ausearch -m avc -ts recent`, `restorecon`,
  `setsebool`.

## Console quirks (official)

- Copy/paste **in the terminal**: `Ctrl+Shift+C` / `Ctrl+Shift+V` (or
  right-click menu). In other remote-desktop apps: plain Ctrl+C/V.
- Use `Ctrl+Alt+W` instead of `Ctrl+W` (Ctrl+W closes the Chrome tab —
  and it's muscle memory for word-delete in bash; retrain this NOW
  during practice).
- The INSERT key is disabled in the remote desktop — in vim use `i`.
- International keyboard dead keys may not work; there's an on-screen
  "Virtual Keyboard" icon on the desktop for special characters.
- One active monitor only (dual monitors not supported); LF recommends
  15"+ screen at 1080p.

### On a Mac client

The exam desktop is remote Linux streamed into the PSI Secure Browser;
the Mac sends raw keystrokes into it. Physical **Ctrl = Ctrl**,
**Option = Alt**, **Cmd = not translated** (stays local to macOS/the
browser). Consequences:

- Terminal copy/paste = physical `Ctrl+Shift+C` / `Ctrl+Shift+V`;
  Cmd+C/V do nothing in the remote terminal. Retrain Cmd muscle memory.
- The Ctrl+W browser trap mostly doesn't apply (close-tab on macOS is
  Cmd+W) — Ctrl+W passes through as word-delete. The keys to fear are
  **Cmd+W / Cmd+Q**, which act on the secure browser itself.
- `Alt+.` = Option+. — if Option combos are flaky, use `Esc` then `.`
  (identical readline behavior, always transmits) or `!$`.
- **Finnish layout risk**: `| \ { } [ ] @ ~` are all Option-combos on a
  Finnish Mac layout, and browser remote desktops often mishandle
  composed/dead-key input (the official "international keyboards may
  not work as expected" warning). Mitigations, best first:
  1. Switch macOS input source to US/ABC for the exam and learn the US
     positions of those few symbols (no Option involved) — practice now.
  2. Verify real behavior during killer.sh attempt 1 (same style of
     browser-streamed console).
  3. On-screen Virtual Keyboard for one-off characters (slow).
- **Ctrl+Space conflict**: with multiple macOS input sources configured,
  macOS intercepts Ctrl+Space (input-source switching) before it reaches
  the remote session — remove the shortcut or extra input sources for
  exam day.
- macOS permissions (official): System Settings → Privacy & Security →
  allow PSI Secure Browser: Camera, Microphone, Automation, Input
  Monitoring. Run the PSI syscheck on the Mac well in advance.
- Caps Lock→Ctrl remapped in System Settings passes through fine.
- ARM Mac is fine for the exam itself (just a browser) even though the
  VirtualBox practice lab needs the Intel laptop.

## Time and scoring strategy

- 17-20 tasks in 120 min ≈ 6-7 min average. Pass is 67% — you can
  afford to drop roughly a third of the points, so **never rathole**.
- First pass: do everything quick and certain, flag anything that
  smells >10 min. Second pass: flagged items by points-per-minute.
- Copy exact names/paths from the task text into the terminal
  (Ctrl+Shift+V) — validators check literal paths/names; a typo in a
  filename is silent zero.
- Grading is on **end state**, not your history. After each task,
  re-read the task line by line and verify each requirement with a
  fresh command, like the grader would: `systemctl is-enabled`,
  `getent`, `findmnt --verify`, `curl`, `getfacl`, `semanage boolean -l`.
- Persistence reflex everywhere: `--now` + `enable`, fstab entry +
  `mount -a`, `setsebool -P`, saved firewall rules, persistent network
  config. Assume the grader reboots the node.
- Before editing any config: `cp file{,.bak}`. Cheap insurance, no
  cleanup needed.
- Verify the hostname in the prompt before every task — work done on
  the wrong node scores zero regardless of correctness.

## killer.sh simulator strategy

- 2 sessions included, 36h of access each from activation; **both
  sessions contain the same 20-25 fixed questions** (unlike the real
  exam) with graded results and solutions.
- Use attempt 1 about 2 weeks out as a diagnostic: honest timed run,
  then spend the rest of the 36h window studying the solutions and
  rerunning weak tasks (environment stays up).
- Use attempt 2 a few days before exam day purely as a timed dress
  rehearsal — same questions, so the target is speed + verification
  discipline, not discovery.

## Exam-day logistics checklist

- Run the [PSI system check](https://syscheck.bridge.psiexams.com/)
  well in advance; exam runs in the PSI Secure Browser (Chrome-based,
  download offered at launch time).
- Use a **personal machine**, not a work laptop (corporate security
  software breaks the secure browser), with rights to install apps and
  kill processes.
- Wired internet if possible; nobody else streaming/gaming on the
  connection.
- Room: private, door closed, clean desk (nothing on or under it),
  clear walls (décor ok, no papers), good lighting, no window/bright
  light behind you; webcam must be movable for the room pan.
- Government-issued photo ID whose name **exactly matches** the name
  verified on the exam checklist.
- Check-in opens 30 min before the scheduled start — use it, the ID +
  room-scan process eats time.
- Bathroom breaks are allowed with proctor permission but the clock
  keeps running.
