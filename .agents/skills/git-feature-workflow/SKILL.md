---
name: git-feature-workflow
description: >-
  Feature-branch git workflow for Gerrit repos where local master must stay a
  clean mirror of origin/master. Use this WHENEVER the user asks to commit,
  amend, rebase, restack, split commits, manage branches, or push in a git
  repository - even if they only say "commit this" or "push it". It defines how
  to route a change to the right feature branch (or create one), keep master
  clean, rebase onto current master before publishing, and push only to the
  master review ref (never feature branches) unless the user explicitly asks.
metadata:
  author: ephahoa
  version: "1.0"
---

<!-- markdownlint-disable MD013 MD041 -->

## Purpose

Keep git history clean and reviewable in a Gerrit-backed repo by treating
`master` as an immutable mirror of `origin/master` and doing all work on
feature branches that are rebased onto current master before every push.

This skill encodes hard-won rules from real restacking/rebasing sessions.
It is the ENTRY POINT for any git request: read it FIRST whenever the user
initiates a git action (commit, amend, rebase, restack, split, branch, push -
even a bare "commit this" or "push it"). It governs all branching, rebasing,
routing, and push mechanics. Then, only when you actually compose or edit a
commit message, defer to the `ai-commit-message` skill for the message format,
body conventions, Jira reference, and Change-Id rules. In short: this workflow
first, `ai-commit-message` second and only for the message itself.

## Golden rules (do not violate)

1. **`master` is sacred and always current.** Local `master` always equals
   `origin/master`. Never commit directly on `master`, never leave local commits
   on top of it, and never leave it rebased onto your feature work. Keep it
   fast-forwarded to `origin/master` (safe, since it has no local commits). Its
   only job is to be a fresh, up-to-date rebase base.
2. **All work lives on feature branches**, one logical feature per branch,
   created from `master` and never stacked on another feature's branch. By
   default a feature branch stays on its own base and a push never moves it
   (see rule 3). You MAY rebase it onto latest master yourself when you want to
   work against current master - that is safe and optional (see "Rebasing your
   feature branch onto latest master").
3. **Rebase before you publish, but only temporarily.** CI (`ci_rebase_commit`)
   rejects patchsets not rebased on current master. So the rebase onto latest
   master exists ONLY to produce the push. Do it on a throwaway branch, push
   from there, then tear it down - leaving both `master` (== `origin/master`)
   and your feature branch in their original condition. The developer's local
   branch must not be disturbed by a push.
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

## Publishing (the push sequence)

The rebase is temporary and exists only to make CI-valid patchsets. Do it on a
throwaway branch so that, once the push is done, `master` and the feature branch
are back in their original condition. Run this exact sequence:

```bash
# 0. Snapshot state + protect the working tree
git status --short                               # remember this to verify later
git rev-parse <feature-branch>                   # remember the ORIGINAL tip
git stash push --include-untracked -m wip-push   # only if the tree is dirty

# 1. Keep master current: fast-forward it to origin/master (never revert it)
git fetch origin master --quiet
git branch -f master origin/master               # safe FF; master has no local commits

# 2. Rebase for the push on a THROWAWAY branch - never move the real branch
git switch -c tmp-push <feature-branch>
git rebase master

# 3. Push the rebased commits to the master review ref (NOT a branch ref)
git push origin HEAD:refs/for/master

# 4. Tear down: delete the temp branch and restore the working tree.
#    The feature branch was never touched; master stays == origin/master.
git switch <feature-branch>
git branch -D tmp-push
git stash pop stash@{0}                          # onto the branch where the wip files live
```

After this, verify the restore:

- `git rev-parse <feature-branch>` equals the ORIGINAL tip from step 0
  (the branch is byte-for-byte unchanged - the rebase happened only on
  `tmp-push`, which is now gone).
- `master` equals `origin/master` (`git rev-parse master origin/master`).

Notes:

- "Always up-to-date with origin/master" refers to `master`: refresh it every
  push (step 1). That is its canonical condition, not a temporary change - do
  not revert it. What you restore to original condition is the **feature
  branch** (and the working tree).
- Step 3 pushes the feature branch's commits (and any ancestor commits not yet
  on origin/master) to Gerrit for review. That is the only push. Do **not**
  `git push origin <feature-branch>` (a branch ref) unless the user explicitly
  asks - then confirm first. Master advances on the server only when a reviewer
  submits; you never push `refs/heads/master` directly.
- The pre-push hook runs `git pull origin master --rebase` and needs a clean
  tree; that is why step 0 stashes. Do not use `SKIP_REBASE=1` to dodge a dirty
  tree - stash instead. Because `tmp-push` is already rebased on master, the
  hook's rebase is a clean no-op.
- If step 2 conflicts, the feature branch is not independent of another
  feature's commits or upstream touched its files - re-root it on master and
  resolve before pushing (check `git log --oneline master..<branch>` and
  `git log --oneline <old-base>..origin/master -- <paths>`).
- Prefer the throwaway `tmp-push` branch over rebasing the real branch and
  resetting it back; it cannot accidentally leave the feature branch moved.

## Rebasing your feature branch onto latest master (optional)

Separate from publishing, you may advance a branch onto the newest master
whenever you want to build or test against current master, or resolve upstream
conflicts early. Unlike the push flow, this permanently moves the branch - and
it rewrites ONLY the branch, never `master`:

```bash
git fetch origin master        # updates the origin/master ref only
git switch <feature-branch>    # stand on the branch you are changing
git rebase origin/master       # replay THIS branch's commits onto newest master
```

Key points:

- `git rebase` only ever rewrites the branch you are on. Rebasing *onto*
  `origin/master` leaves your local `master` pointer exactly where it is - do
  NOT `git branch -f master ...` for this. Nothing happens to `master`.
- A branch that already has its own commits cannot be "fast-forwarded" to master
  (its tip is not an ancestor of master). Rebase IS the operation that advances
  the base to master and replays your commits on top - there is no separate
  fast-forward-then-reattach step. (A real `--ff-only` only applies when the
  branch has no commits of its own yet.)
- Branch structure is preserved: commit order and content are unchanged, only
  SHAs/parents differ. Change-Ids are kept, so Gerrit changes stay linked. Add
  `--rebase-merges` only if the branch intentionally contains merge commits.
- Stash first if the tree is dirty; resolve conflicts if upstream touched your
  files.
- Verify nothing drifted using the reflog:
  `git range-diff <feature-branch>@{1} <feature-branch>` - every row should show
  `=` when there were no conflicts.

This is low-consequence because feature branches are private (never pushed as
branch refs), so rewriting their history affects no one. Choose it for
freshness; skip it to keep a stable base. Either way a later push still works -
if the branch is already on latest master, the throwaway `tmp-push` rebase in
the publish sequence is just a clean no-op.

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

## Preserving the working tree across rewrites

Uncommitted edits often outlive a rebranch. To keep them intact:

1. `git stash push --include-untracked` before rewriting history.
2. After the rewrite, pop onto the branch **where the edited files exist**. If
   an edit touches a file that only exists on feature branch A (e.g. a file
   created by one of A's commits), popping onto branch B will conflict
   (modify/delete). Reset the bad pop (`git reset --hard HEAD`, clean debris)
   and pop onto the correct branch instead - the stash is preserved on a
   conflicted pop.
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
master              == origin/master        # always current, clean, no local commits
feature-a           its own commits [a1..]  # created from master; stays put locally
feature-b           its own commits [b1..]  # independent of A
```

- A **push** never changes these: the rebase happens on a throwaway `tmp-push`
  branch, so after a push the feature branch is byte-identical to before and
  `master` is still `origin/master`. (You may still choose to rebase the branch
  onto master yourself - see the optional section above.)
- No `backup-*` branches left behind; working-tree WIP restored on its owning
  feature branch.
