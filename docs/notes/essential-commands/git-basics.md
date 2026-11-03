# Essential Commands — Git basics

Domain: Essential Commands ("Basic Git operations").
git is preinstalled on the exam SSH hosts (official instructions); the
tested level is genuinely basic — clone, stage, commit, branch, merge,
push/pull. No family delta: git behaves identically on deb/rpm/suse
(package `git` everywhere).

## First: identity, or commits fail

**Trap:** `git commit` refuses to run until identity is configured —
fix this before anything else:

```
git config --global user.name  "Exam Candidate"
git config --global user.email "candidate@example.com"
git config --list                    # verify
```

(Written to ~/.gitconfig; `--local` inside a repo overrides per-repo.)

## Daily loop

```
git clone <url-or-path> [dir]        # existing repo
git init [dir]                       # new repo (creates .git/)
git status                           # always before and after staging
git add file1 dir/                   # stage specific paths
git add -A                           # stage everything
git commit -m "message"
git log --oneline                    # history, short form
git diff                             # working tree vs staged
git diff --staged                    # staged vs last commit
```

## Branching and merging

```
git branch                           # list (* = current)
git switch -c feature                # create + switch (= checkout -b feature)
git switch main                      # go back
git merge feature                    # merge into the current branch
git branch -d feature                # delete a merged branch
```

Older git only has `git checkout -b feature` / `git checkout main` —
both spellings work on all lab families; know both. The initial branch
is `master` or `main` depending on git version/config
(`init.defaultBranch`) — check `git branch`, don't assume.

## Remotes — local paths work offline

A remote can be a plain filesystem path; that is how a lab or exam
grades push/pull without internet:

```
git init --bare /srv/project.git     # the "server" (no working tree)
cd ~/work/project
git remote add origin /srv/project.git
git remote -v                        # verify
git push -u origin main              # -u sets upstream once, later: git push
git pull                             # fetch + merge from upstream
```

Clone side: `git clone /srv/project.git /tmp/copy` — a second working
directory doubles as a push/pull peer.

## .gitignore

One pattern per line, glob syntax, `!` negates:

```
*.log            # glob, matches anywhere
build/           # directory (trailing /)
/secret.txt      # anchored to repo root
!keep.log        # exception to an earlier pattern
```

Verify a pattern actually works: `git status` (file gone from
untracked) or `git check-ignore -v build/x.o`.

**Trap:** .gitignore does not untrack already-committed files — run
`git rm --cached file` first, then the ignore pattern applies.

## Grader-style verification

```
git -C /path/to/repo status              # clean? on the requested branch?
git -C /path/to/repo log --oneline -5    # expected commits present?
git -C /path/to/repo branch              # branch created/merged as asked?
git -C /path/to/repo remote -v           # remote configured as asked?
git -C /srv/project.git log --oneline    # did the push arrive at the remote?
```
