# Git Cheatsheet for New Statistical Programmers

> **Why this exists:** Git can feel scary when you're new — especially when you're working on clinical programs that need to be right. This guide covers the exact scenarios that trip up new SPs, with copy-paste commands and plain-English explanations. You won't break anything if you follow these steps.

---

## Before You Start: Key Concepts (30-Second Version)

- **Repository (repo):** A folder tracked by git. Your study programs live here.
- **Branch:** A parallel copy of the code where you make changes without affecting anyone else's work.
- **Commit:** A snapshot of your changes with a message describing what you did.
- **Push:** Send your commits to the remote repository (GitHub/GitLab) so others can see them.
- **Pull:** Download the latest changes from the remote repository to your local machine.
- **Merge conflict:** Two people changed the same line of code. Git needs you to decide which version to keep.

---

## Daily Workflow: The Basics

### Starting your day
```bash
# 1. Make sure you're on the main branch
git checkout main

# 2. Pull the latest changes from the team
git pull origin main

# 3. Create a new branch for today's work
git checkout -b feature/adsl-baseline-derivation
```

### Saving your work
```bash
# 1. See what files you changed
git status

# 2. Add the specific files you want to save
git add pgm/adam/adsl.sas

# 3. Commit with a clear message
git commit -m "Add baseline flag derivation for ADSL per ADaM spec v2.0"

# 4. Push to the remote repository
git push origin feature/adsl-baseline-derivation
```

### Writing good commit messages for clinical programs
```
Good:
  "Add TRTEMFL derivation in ADAE per SAP section 5.2"
  "Fix visit windowing logic for AVISIT in ADVS — was using VISITNUM instead of ADY"
  "Update DM mapping to handle missing BRTHDTC per SDTM spec amendment"

Bad:
  "updated code"
  "fixed stuff"
  "WIP"
```

---

## Panic Scenarios

### "I committed to main by accident!"

If you **haven't pushed yet** — easy fix:

```bash
# Undo the last commit but keep all your code changes
git reset --soft HEAD~1

# Now create the branch you should have been on
git checkout -b feature/your-work-description

# Re-commit on the correct branch
git add .
git commit -m "Your descriptive message"
```

If you **already pushed** — ask your lead for help. Don't try to force-push.

---

### "I have a merge conflict and I'm scared"

Don't panic. A merge conflict just means two people edited the same lines. Git is asking you to pick the right version.

**Step 1:** Open the conflicted file. You'll see markers like this:
```
<<<<<<< HEAD
  baseline_val = input(vsorres, best.);
=======
  baseline_val = input(strip(vsorres), best12.);
>>>>>>> origin/main
```

- **Above `=======`** = your changes
- **Below `=======`** = the other person's changes

**Step 2:** Decide which version is correct (or combine them). Delete the conflict markers.

**Step 3:** Ask Claude if you're unsure:
```
I have a merge conflict in my ADaM program. Here are the two versions:

Version A (mine): baseline_val = input(vsorres, best.);
Version B (theirs): baseline_val = input(strip(vsorres), best12.);

Which is safer and why? Could the difference affect my derivation results?
```

**Step 4:** After resolving, save the file and complete the merge:
```bash
git add the-conflicted-file.sas
git commit -m "Resolve merge conflict in ADSL baseline derivation"
```

---

### "I made changes to the wrong file and want to undo"

If you **haven't committed yet:**
```bash
# Discard changes to a specific file (goes back to last commit)
git checkout -- pgm/adam/adsl.sas
```

If you **already committed but haven't pushed:**
```bash
# Undo the last commit, keep the changes as uncommitted
git reset --soft HEAD~1
```

---

### "I want to see what changed between my version and the team's version"

```bash
# See all files you've changed
git status

# See the exact line-by-line changes you made (before committing)
git diff

# See the exact changes in a specific file
git diff pgm/adam/adsl.sas

# Compare your branch to main
git diff main..your-branch-name
```

---

### "I need to switch to someone else's branch to review their code"

```bash
# Save your current work first (even if it's not ready to commit)
git stash

# Switch to their branch
git checkout their-branch-name

# When you're done reviewing, come back to your branch
git checkout your-branch-name

# Get your saved work back
git stash pop
```

---

### "I accidentally deleted a file"

If you **haven't committed** the deletion:
```bash
# Restore the file from the last commit
git checkout -- path/to/deleted-file.sas
```

If you **already committed** the deletion:
```bash
# Bring back the file from the commit before you deleted it
git checkout HEAD~1 -- path/to/deleted-file.sas
```

---

## .gitignore: What NOT to Track in a Clinical Repo

Create a `.gitignore` file in your repo root. This tells git to ignore files that shouldn't be version-controlled.

```gitignore
# Data files — NEVER commit patient data to git
*.sas7bdat
*.xpt
*.csv
*.xlsx

# SAS output and temp files
*.log
*.lst
*.sas7bcat

# R output
*.RData
*.rds
*.Rhistory

# OS files
.DS_Store
Thumbs.db

# IDE files
.Rproj.user/
.vscode/

# Data folders (if you have a data directory)
data/
```

> **Why this matters:** Accidentally committing patient data to a git repository is a serious compliance issue. The `.gitignore` file is your safety net — set it up on day one.

---

## Branch Naming Conventions

Use a consistent pattern so your team knows what each branch is for:

```
feature/adsl-baseline-derivation    ← New work
fix/advs-visit-windowing-bug        ← Bug fix
qc/adae-trtemfl-review              ← QC-related changes
```

<!-- CUSTOMIZE: Replace with your company's branching convention if different -->

---

## Quick Reference Card

| I want to... | Command |
|---|---|
| See what I changed | `git status` |
| See line-by-line changes | `git diff` |
| Save my changes | `git add file.sas` then `git commit -m "message"` |
| Send changes to the team | `git push origin my-branch` |
| Get the latest from the team | `git pull origin main` |
| Start a new task | `git checkout -b feature/description` |
| Undo uncommitted changes | `git checkout -- file.sas` |
| Undo last commit (keep changes) | `git reset --soft HEAD~1` |
| Temporarily save work | `git stash` / `git stash pop` |
| See commit history | `git log --oneline` |

---

> **Golden rule:** When in doubt, run `git status` first. It will always tell you where you are and what's going on. And if you're truly stuck, ask Claude — paste the output of `git status` and describe what you were trying to do.
