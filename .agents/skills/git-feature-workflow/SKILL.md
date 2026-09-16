---
name: git-feature-workflow
description: >-
  Feature-branch git workflow for Gerrit repos where local master must stay a
  clean mirror of origin/master. Use this WHENEVER the user asks to commit,
  amend, rebase, restack, split commits, manage branches, or push in a git
  repository - even if they only say "commit this" or "push it". It defines how
  to route a change to the right feature branch (or create one), keep master
  clean, rebase the feature branch onto current master as part of publishing,
  and push only to the master review ref (never feature branches) unless the
  user explicitly asks.
metadata:
  author: ephahoa
  version: "1.0"
---

<!-- markdownlint-disable MD013 MD041 -->

## Purpose

Keep git history clean and reviewable in a Gerrit-backed repo by treating
`master` as an immutable mirror of `origin/master` and doing all work on
feature branches, rebased onto current master before every push.

Read this FIRST for any git action (commit, amend, rebase, restack, split,
branch, push - even a bare "commit this" or "push it"). It governs branching,
rebasing, routing and push mechanics. Defer to the `ai-commit-message` skill
only for the message itself: format, body, Jira reference, Change-Id rules.

## Golden rules (do not violate)

1. **`master` is sacred and always current.** Local `master` always equals
   `origin/master`. Never commit directly on `master`, never leave local commits
   on top of it, and never leave it rebased onto your feature work. Keep it
   fast-forwarded to `origin/master` (safe, since it has no local commits). Its
   only job is to be a fresh, up-to-date rebase base.
2. **All work lives on feature branches**, one logical feature per branch,
   created from `master` and never stacked on another feature's branch. A branch
   advances onto latest master whenever it is pushed (see rule 3), so its base
   tracks upstream over time.
3. **Rebase the branch onto latest master as part of every push.** CI
   (`ci_rebase_commit`) rejects patchsets not rebased on current master, so the
   rebase is mandatory. Rebase the feature branch ITSELF and push from it - the
   branch is expected to move, so what you have locally is exactly what was
   pushed and what CI sees. Back the branch up first
   (`git branch backup-<date> <tip>`) since this rewrites its history, and drop
   the backup once verified.
4. **Push only to the master review ref.** In this repo
   `remote.origin.push = HEAD:refs/for/master`, so "push master" means push the
   feature commits to `refs/for/master` for review. **Never push feature branch
   refs** (`refs/heads/...`). If the user wants to push an actual branch, STOP
   and ask for explicit confirmation first.
5. **Pushing is a write op - confirm first.** Never push without the user
   asking for it in this turn. Flag closed Jira tickets before pushing a commit
   that references one.
6. **Preserve unrelated working-tree changes.** Stash (including untracked)
   around history rewrites and restore them afterward onto the branch where the
   touched files exist.
7. **Respect the user's staged set.** Users very often `git add` exactly the
   files they want first, then ask you to commit / amend / fixup "those files".
   When anything is already staged, treat the index as the user's explicit
   statement of intent: operate ONLY on the already-staged files, do NOT
   `git add` any additional modified or untracked files (even related-looking
   ones), and leave every other change exactly as-is (unstaged stays unstaged,
   untracked stays untracked). For an amend, run `git commit --amend` as-is (it
   commits only the index) - never stage more first. Only stage files yourself
   when nothing is staged and the user has named them; if you think an
   unstaged/untracked file belongs too, STOP and ask before adding it.

## Committing: route the change to a feature

When asked to commit, do NOT blindly commit onto the current branch. First
decide which feature the change belongs to.

1. Inspect what changed: `git status --short` and `git diff`.
2. Identify the owning feature by:
   - the area/directory touched (e.g. `tools/analytics-images/training/` vs
     `machine-learning/ami-model-training/amitraining/labeling/`),
   - the Jira ticket / Gerrit topic it relates to,
   - whether it logically extends an existing branch's commits.
3. Match to an existing feature branch:
   - `git branch --list` and, for each candidate,
     `git log --oneline master..<branch>` to see what it contains.
   - If a branch clearly owns this change, use it.
4. If no branch fits, **create a new one from clean master**:

   ```bash
   git fetch origin master --quiet
   git branch -f master origin/master          # keep master clean + current
   git switch -c <feature-name> master
   ```

   Name the branch after the feature/Jira (e.g. `etac-dump-labeling`,
   `tpsdn-50225-cuda-ldpath`). Ask the user if the feature name is unclear.
5. Commit on that branch. Read `ai-commit-message` for the message format
   (`<area>: <imperative summary>`, body explaining why, Jira reference,
   Change-Id). Stage only the files that belong to this feature - leave
   unrelated edits untouched (`git add <paths>`, not `git add .`).

If the change spans two features, split it: stage and commit each feature's
files on its own branch. Never mix features in one commit.

## Amending / restacking a commit that is not HEAD

To fold staged changes into an earlier commit in a stack:

1. Stage only the target files.
2. `git commit --fixup=<target-sha>`.
3. Stash any remaining unrelated changes so the tree is clean:
   `git stash push --include-untracked -m wip`.
4. `GIT_SEQUENCE_EDITOR=true git rebase -i --autosquash <parent-of-target>`.
5. Restore: `git stash pop stash@{0}` (be careful which stash is yours - a
   pre-existing stash must stay put; pop by explicit ref).

`--fixup`/autosquash preserves the target commit's message and `Change-Id`.

### Dropping a commit from the stack

Deleting its line from the rebase todo is enough, and it can be done
non-interactively - in the SAME rebase that autosquashes a fixup:

```bash
GIT_SEQUENCE_EDITOR='sed -i -E "/<subject pattern>/d"' GIT_EDITOR=true \
    git rebase -i --autosquash <base>
```

Match the pattern on a distinctive part of the subject. Verify afterwards that
the commit is gone (`git log --oneline <base>..HEAD | grep -i <pattern>`) and
that the survivors kept their Change-Ids.

## Splitting a commit into several

When one commit does two unrelated jobs (e.g. two pipeline steps), split it so
each commit stands on its own. Work from the parent and rebuild:

```bash
git branch backup-<date> <tip>            # cheap insurance
git stash push --include-untracked -m wip # rewrite needs a clean tree
git reset --mixed <parent-of-commit>      # content stays in the worktree
# stage subset 1 -> commit 1 ; stage subset 2 -> commit 2
git diff <original-sha> HEAD              # MUST be empty
```

Rules:

- **The final `git diff <original-sha> HEAD` must be empty.** That proves no
  content drifted, and it also guarantees a later `stash pop` applies cleanly,
  because the tree is byte-identical to what the stash was made against.
- **Change-Id: keep the original on the commit that matches the original
  subject** (that Gerrit change keeps its history and review comments); let the
  commit-msg hook mint a fresh one for the new commit. Never reuse one
  Change-Id for two commits.
- **A file touched by both commits** (typically a README) is divided by content,
  not by hunk juggling: edit the shared file down to commit 1's part, commit,
  then restore the full version from the original commit
  (`git checkout <original-sha> -- <path>`) and commit the rest.
- **Decide where a shared support file goes by who uses it.** Check imports
  rather than guessing: a constants/defaults module belongs with the commit
  whose module actually references it, so each commit builds and lints alone.
- **Staging a deletion**: `git add <deleted-path>` can fail with "did not match
  any files"; use `git rm <path>` or `git add -A <path>`.

## Moving a staged change to another branch

Switching branches with a dirty tree breaks as soon as an edited file exists
only on the current branch (a file created by one of its commits): git cannot
carry it to a branch where it does not exist. So do NOT rely on `git switch`
carrying the change over. Route it as a patch instead:

```bash
git diff --cached > /tmp/change.patch      # capture the staged work
git checkout HEAD -- <those paths>         # remove it from THIS branch
git stash push --include-untracked -m wip  # park the rest, tree now clean
git switch <target-branch>                 # or create it from clean master
git apply --3way /tmp/change.patch         # --3way survives context drift
git add <paths> && git commit ...          # or --amend for an existing commit
git switch <original-branch> && git stash pop stash@{0}
```

For a single file, `git show :./<path> > /tmp/new-content` captures the staged
version. Inside a subdirectory the index path needs the `./` prefix, otherwise
git fails with "path ... is in the index, but not ...".

Verify the patch landed intact: comparing the re-generated `git diff --cached`
against the saved patch, only the hunk header line numbers may differ (the
target branch has different surrounding content) - never the `+`/`-` lines.

## Rebasing every branch onto new master

When refreshing all local work after master advances:

1. Stash the working tree, then fast-forward master
   (`git switch master && git merge --ff-only origin/master`).
2. Before rebasing, find work that already landed upstream:
   `git cherry origin/master <branch>` marks each commit `-` when an equivalent
   patch is already in master, `+` when it is not. Confirm a `-` by locating its
   Change-Id in `origin/master`.
3. Rebase each branch (`git switch <b> && git rebase origin/master`), and check
   content survived with
   `git range-diff <old-tip>~N..<old-tip> origin/master..<b>` - every row must
   show `=`.
4. A branch whose commits all landed upstream ends up with zero commits. Delete
   it with `git branch -d` (which refuses unless it is truly merged), never
   `-D`.
5. Restore the stash last. Expect conflicts where upstream touched the same
   files: check what master actually landed before resolving (a merged version
   of your own change can differ from your local copy - review can drop parts of
   it), and resolve auto-generated files (image manifests, lock files) to
   master's version.

## Publishing (the push sequence)

Publishing rebases the feature branch onto current master and pushes from it, so
the branch, the pushed patchset and CI all agree. Run this exact sequence:

```bash
# 0. Snapshot state + protect the working tree
git status --short                               # remember this to verify later
git rev-parse <feature-branch>                   # ORIGINAL tip, for recovery
git branch backup-<date> <feature-branch>        # history rewrite ahead
git stash push --include-untracked -m wip-push   # only if the tree is dirty

# 1. Keep master current: fast-forward it to origin/master (never revert it)
git fetch origin master --quiet
git branch -f master origin/master               # safe FF; master has no local commits

# 2. Rebase the feature branch itself onto latest master
git switch <feature-branch>
git rebase master

# 3. Push the rebased commits to the master review ref (NOT a branch ref)
git push origin HEAD:refs/for/master

# 4. Restore the working tree, then drop the backup once verified
git stash pop stash@{0}                          # onto the branch where the wip files live
git branch -D backup-<date>
```

After this, verify:

- Every commit survived the rebase unchanged - each row must show `=`:
  `git range-diff <ORIGINAL-tip>~N..<ORIGINAL-tip> master..<feature-branch>`
  (N = number of commits on the branch). Only then drop the backup.
- `master` equals `origin/master` (`git rev-parse master origin/master`).
- The branch tip HAS moved (that is expected now) and its commits kept their
  Change-Ids.

Notes:

- Step 1 refreshing `master` is its canonical condition, not a temporary
  change, so do not revert it. Only the working tree gets restored - the
  **feature branch is meant to stay rebased**.
- Step 3 pushes the branch's commits (plus any ancestors not yet upstream) for
  review. That is the only push. Master advances on the server only when a
  reviewer submits; never push `refs/heads/master`, and never a feature branch
  ref unless the user explicitly asks.
- The pre-push hook runs `git pull origin master --rebase` and needs a clean
  tree - that is why step 0 stashes. Never use `SKIP_REBASE=1` to dodge a dirty
  tree. Since the branch is already rebased, the hook's rebase is a no-op.
- If step 2 conflicts, the branch is not independent of another feature or
  upstream touched its files - resolve it (or `git rebase --abort` and recover
  from `backup-<date>`) before pushing
  (`git log --oneline master..<branch>`,
  `git log --oneline <old-base>..origin/master -- <paths>`).
- Because the branch itself moves, expect the stash pop in step 4 to meet
  upstream changes in the same files. That is normal: see "Preserving the
  working tree across rewrites".

## Rebasing a feature branch outside a push

The push sequence already rebases the branch, so a separate rebase is only
needed to build or test against current master before publishing:

```bash
git fetch origin master        # updates the origin/master ref only
git switch <feature-branch>    # stash first if the tree is dirty
git rebase origin/master       # do NOT 'git branch -f master' for this
git range-diff <feature-branch>@{1} <feature-branch>   # every row must be '='
```

Safe to do freely: feature branches are never pushed as branch refs, so
rewriting their history affects no one, and Change-Ids survive so Gerrit changes
stay linked. Add `--rebase-merges` only if the branch intentionally contains
merge commits.

## Rebase safety checklist

- **Preserve Change-Ids.** They tie a commit to its Gerrit change. `cherry-pick`,
  `rebase`, and `--fixup` autosquash all keep them. Verify:
  `git log --format="%h %s | %(trailers:key=Change-Id,valueonly)" master..<branch>`.
- **Verify content is unchanged after a rebase/restack** with range-diff -
  every line should show `=`:
  `git range-diff <old-base>..<old-tip> <new-base>..<new-tip>`.
- **Back up before risky rewrites**, then remove the backups when done and
  verified (the user wants no lingering `backup-*` branches):
  `git branch backup-<date> <tip>` … `git branch -D backup-<date>`.
- **Anticipate conflicts** before moving a base: check whether upstream touched
  your files, e.g. `git log --oneline <old-base>..origin/master -- <paths>`.
- **Take reference copies of file content from the commit, not the worktree.**
  A `cp`/snapshot of a working file taken before stashing silently includes the
  unstaged edits too, which then leak into the rewrite. Use
  `git show <sha>:<path>` or `git checkout <sha> -- <path>`.

## Preserving the working tree across rewrites

Uncommitted edits often outlive a rebranch. To keep them intact:

1. `git stash push --include-untracked` before rewriting history.
2. After the rewrite, pop onto the branch **where the edited files exist**. If
   an edit touches a file that only exists on feature branch A (e.g. a file
   created by one of A's commits), popping onto branch B will conflict
   (modify/delete). Reset the bad pop (`git reset --hard HEAD`, clean debris)
   and pop onto the correct branch instead - the stash is preserved on a
   conflicted pop.
   Because the stash survives, `git reset --hard HEAD` is the safe way to abort
   a half-applied pop: it clears the unmerged paths (`UU`/`DU`) that block a
   branch switch and loses nothing. Verify the stash is still listed first, then
   re-apply it on the right branch (`git stash apply`, keeping the entry until
   the result is confirmed).
3. Never disturb a pre-existing stash you did not create. Check
   `git stash list` first and pop your entry by explicit `stash@{n}`.
4. After popping, diff the restored files against the pre-rewrite state to
   confirm they are byte-identical (3-way merges can silently absorb upstream
   changes - that is expected for rebased context, but verify your own edits
   survived unchanged).

## When to stop and ask

- Before pushing anything (confirm the user asked this turn).
- Before pushing any branch ref instead of `refs/for/master`.
- Before any destructive op the user did not request: `reset --hard` on a branch
  with unsaved work, `push --force`, `branch -D` of something that is not a
  known backup, force-updating a shared branch.
- When a commit references a **closed** Jira ticket - flag it and let the user
  decide.
- When the feature a change belongs to is genuinely ambiguous.

## Quick reference: end-state you are aiming for

```
master              == origin/master        # current, clean, no local commits
feature-a           its own commits [a1..]  # rebased onto master at each push
feature-b           its own commits [b1..]  # independent of A
```

A push advances the branch onto current master and leaves no `backup-*`
branches or stranded WIP behind.
