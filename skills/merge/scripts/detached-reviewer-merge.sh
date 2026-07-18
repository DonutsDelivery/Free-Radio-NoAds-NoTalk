#!/usr/bin/env bash
# Detached Reviewer Merge Helper
#
# Merges the reviewed canonical branch into the integration target from a
# detached reviewer snapshot. This is the one supported merge path for
# reviewers in manual_merge publication mode.
#
# Required dispatch environment variables:
#   KSPEC_DISPATCH_CANONICAL_BRANCH  — the task branch to merge
#   KSPEC_DISPATCH_MERGE_TARGET      — the integration branch name (e.g. "dev")
#   KSPEC_DISPATCH_CANONICAL_HEAD    — the reviewed commit SHA to merge (pinned at snapshot time)
#
# Exit codes:
#   0  — merge succeeded (or no-op: already integrated)
#   1  — error (missing env, dirty target, conflict, etc.)

set -euo pipefail

# --- Environment contract ---------------------------------------------------

if [ -z "${KSPEC_DISPATCH_CANONICAL_BRANCH:-}" ]; then
  echo "error: KSPEC_DISPATCH_CANONICAL_BRANCH is not set." >&2
  echo "This script must be run from a dispatch reviewer invocation." >&2
  exit 1
fi

if [ -z "${KSPEC_DISPATCH_MERGE_TARGET:-}" ]; then
  echo "error: KSPEC_DISPATCH_MERGE_TARGET is not set." >&2
  echo "This script must be run from a dispatch reviewer invocation." >&2
  exit 1
fi

if [ -z "${KSPEC_DISPATCH_CANONICAL_HEAD:-}" ]; then
  echo "error: KSPEC_DISPATCH_CANONICAL_HEAD is not set." >&2
  echo "This script must be run from a dispatch reviewer invocation." >&2
  exit 1
fi

CANONICAL_BRANCH="$KSPEC_DISPATCH_CANONICAL_BRANCH"
MERGE_TARGET="$KSPEC_DISPATCH_MERGE_TARGET"

# --- Verify the pinned canonical head ----------------------------------------

CANONICAL_HEAD="$KSPEC_DISPATCH_CANONICAL_HEAD"

# Verify the pinned commit exists in the repository
git cat-file -t "$CANONICAL_HEAD" >/dev/null 2>&1 || {
  echo "error: pinned canonical head '$CANONICAL_HEAD' does not exist in the repository." >&2
  exit 1
}

# Verify the pinned commit matches the current branch tip (detect drift)
BRANCH_TIP=$(git rev-parse --verify "refs/heads/$CANONICAL_BRANCH" 2>/dev/null) || {
  echo "error: canonical branch '$CANONICAL_BRANCH' does not exist." >&2
  exit 1
}

if [ "$CANONICAL_HEAD" != "$BRANCH_TIP" ]; then
  echo "warning: canonical branch '$CANONICAL_BRANCH' has advanced past the reviewed commit." >&2
  echo "  reviewed commit: $CANONICAL_HEAD" >&2
  echo "  current tip:     $BRANCH_TIP" >&2
  echo "Merging the reviewed commit as pinned." >&2
fi

# --- Resolve the integration target ref --------------------------------------

TARGET_HEAD=$(git rev-parse --verify "refs/heads/$MERGE_TARGET" 2>/dev/null) || {
  echo "error: integration target branch '$MERGE_TARGET' does not exist." >&2
  exit 1
}

# --- No-op detection: is canonical already integrated? -----------------------

if git merge-base --is-ancestor "$CANONICAL_HEAD" "$TARGET_HEAD" 2>/dev/null; then
  echo "no-op: canonical branch '$CANONICAL_BRANCH' ($CANONICAL_HEAD) is already integrated at '$MERGE_TARGET' ($TARGET_HEAD)."
  exit 0
fi

# --- Locate the occupied worktree for the integration target -----------------

OCCUPIED_WORKTREE=""
TARGET_REF="refs/heads/$MERGE_TARGET"

while IFS= read -r line; do
  case "$line" in
    "worktree "*)
      current_path="${line#worktree }"
      current_branch=""
      ;;
    "branch "*)
      current_branch="${line#branch }"
      ;;
    "")
      if [ "$current_branch" = "$TARGET_REF" ] && [ -n "$current_path" ]; then
        OCCUPIED_WORKTREE="$current_path"
      fi
      current_path=""
      current_branch=""
      ;;
  esac
done < <(git worktree list --porcelain; echo "")

# If the last block didn't end with blank line
if [ "$current_branch" = "$TARGET_REF" ] && [ -n "$current_path" ]; then
  OCCUPIED_WORKTREE="$current_path"
fi

if [ -z "$OCCUPIED_WORKTREE" ]; then
  echo "error: integration target branch '$MERGE_TARGET' is not checked out in any worktree." >&2
  echo "The merge helper requires the target branch to be checked out somewhere." >&2
  echo "Recovery: check out '$MERGE_TARGET' in a worktree, then re-run." >&2
  exit 1
fi

# --- Dirty-target check: refuse if occupied worktree has modifications -------
# Only check for tracked modifications and staged drift per the spec.
# Untracked files are harmless and should not block the merge.

HAS_TRACKED_MODS=0
HAS_STAGED_DRIFT=0
DIRTY_DETAILS=""

# Check for unstaged tracked modifications (modified/deleted working tree files)
if ! git -C "$OCCUPIED_WORKTREE" diff --quiet 2>/dev/null; then
  HAS_TRACKED_MODS=1
  DIRTY_DETAILS+="Tracked modifications:"$'\n'
  DIRTY_DETAILS+="$(git -C "$OCCUPIED_WORKTREE" diff --name-status 2>/dev/null)"$'\n'
fi

# Check for staged drift (changes in the index not yet committed)
if ! git -C "$OCCUPIED_WORKTREE" diff --cached --quiet 2>/dev/null; then
  HAS_STAGED_DRIFT=1
  DIRTY_DETAILS+="Staged drift:"$'\n'
  DIRTY_DETAILS+="$(git -C "$OCCUPIED_WORKTREE" diff --cached --name-status 2>/dev/null)"$'\n'
fi

if [ "$HAS_TRACKED_MODS" -eq 1 ] || [ "$HAS_STAGED_DRIFT" -eq 1 ]; then
  echo "error: integration target worktree at '$OCCUPIED_WORKTREE' has uncommitted changes." >&2
  echo "" >&2
  echo "$DIRTY_DETAILS" >&2
  echo "Recovery:" >&2
  echo "  1. Save or stash changes in the target worktree:" >&2
  echo "       cd $OCCUPIED_WORKTREE && git stash" >&2
  echo "  2. Re-run this merge helper." >&2
  echo "  3. After merge, restore changes if needed:" >&2
  echo "       cd $OCCUPIED_WORKTREE && git stash pop" >&2
  exit 1
fi

# --- Perform the merge in the occupied worktree ------------------------------

MERGE_MSG="Merge branch '$CANONICAL_BRANCH' into $MERGE_TARGET"

if ! MERGE_OUTPUT=$(git -C "$OCCUPIED_WORKTREE" merge --no-ff "$CANONICAL_HEAD" -m "$MERGE_MSG" 2>&1); then
  # Merge failed — check if it's a conflict
  if git -C "$OCCUPIED_WORKTREE" diff --name-only --diff-filter=U 2>/dev/null | head -1 | grep -q .; then
    # Merge conflict — abort to restore clean state
    git -C "$OCCUPIED_WORKTREE" merge --abort 2>/dev/null || true

    echo "error: merge conflict detected." >&2
    echo "" >&2
    echo "Conflicting output:" >&2
    echo "$MERGE_OUTPUT" >&2
    echo "" >&2
    echo "The integration target ref has NOT been advanced." >&2
    echo "The occupied worktree at '$OCCUPIED_WORKTREE' has been restored to its pre-merge state." >&2
    echo "" >&2
    echo "Next step:" >&2
    echo "  Move the task to needs_work with a note describing the conflicting files" >&2
    echo "  and what both sides changed. Do not attempt to resolve merge conflicts" >&2
    echo "  inside the detached snapshot." >&2
    exit 1
  else
    # Non-conflict merge failure
    echo "error: merge failed." >&2
    echo "$MERGE_OUTPUT" >&2
    exit 1
  fi
fi

# --- Post-merge verification -------------------------------------------------

NEW_TARGET_HEAD=$(git -C "$OCCUPIED_WORKTREE" rev-parse HEAD 2>/dev/null)

if [ "$NEW_TARGET_HEAD" = "$TARGET_HEAD" ]; then
  echo "warning: target ref did not advance after merge. This is unexpected." >&2
  exit 1
fi

# Verify the occupied worktree index is clean after the merge
POST_MERGE_STATUS=$(git -C "$OCCUPIED_WORKTREE" status --porcelain 2>/dev/null)
if [ -n "$POST_MERGE_STATUS" ]; then
  echo "warning: occupied worktree has unexpected dirty state after merge." >&2
  echo "$POST_MERGE_STATUS" >&2
fi

echo "success: merged '$CANONICAL_BRANCH' into '$MERGE_TARGET'."
echo "  previous target: $TARGET_HEAD"
echo "  new target:      $NEW_TARGET_HEAD"
echo "  occupied worktree refreshed: $OCCUPIED_WORKTREE"
