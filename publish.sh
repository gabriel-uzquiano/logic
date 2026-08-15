#!/usr/bin/env bash
# publish.sh — build + publish the logic textbook.
#
# Assumes:
#   - You are on branch `source` in ~/GitHub/logic/
#   - The book has ALREADY been rendered (docs/ is up to date).
#     Render in RStudio (Build → Build Book) or with:
#       R -e 'bookdown::render_book("index.Rmd", "bookdown::tufte_html_book")'
#   - Remote `origin` points at github.com/gabriel-uzquiano/logic
#
# What it does:
#   1. Sanity checks (correct branch, docs/ exists, no uncommitted non-docs changes)
#   2. Commits docs/ + Rmd changes to `source` with the message you pass in
#   3. Copies docs/ into a temporary worktree checked out on `main`
#   4. Commits and pushes `main` — this is what GitHub Pages actually serves
#   5. Returns you to `source`
#
# Usage:
#   ./publish.sh "Add identity chapter + polish"

set -eo pipefail

if [[ $# -lt 1 ]]; then
  echo "Usage: $0 \"commit message\"" >&2
  exit 1
fi
MSG="$1"

REPO_ROOT="$(git rev-parse --show-toplevel)"
cd "$REPO_ROOT"

# ---- 1. Sanity checks ----
CURRENT_BRANCH="$(git symbolic-ref --short HEAD)"
if [[ "$CURRENT_BRANCH" != "source" ]]; then
  echo "✗ You must be on branch 'source' (currently on '$CURRENT_BRANCH')." >&2
  exit 1
fi

if [[ ! -d docs ]]; then
  echo "✗ docs/ not found. Render the book first (RStudio → Build → Build Book)." >&2
  exit 1
fi

if [[ ! -f docs/index.html ]]; then
  echo "✗ docs/index.html missing. Did the render finish?" >&2
  exit 1
fi

# ---- 2. Commit everything to source ----
echo "→ Committing changes to source…"
git add -A
if git diff --cached --quiet; then
  echo "  (nothing to commit on source)"
else
  git commit -m "$MSG"
fi
echo "→ Pushing source to origin…"
git push origin source

# ---- 3. Publish docs/ to main via a temporary worktree ----
WORKTREE_DIR="$(mktemp -d /tmp/logic-publish-XXXXXX)"
trap 'rm -rf "${WORKTREE_DIR:-}"; git worktree prune 2>/dev/null || true' EXIT

echo "→ Fetching origin/main…"
git fetch origin main

# Sync local main to match origin/main so the worktree is based on what is deployed.
# Any local main-only commits (which shouldn't exist in a healthy setup) are discarded
# here — origin/main is the source of truth for the published site.
echo "→ Syncing local main to origin/main…"
if git show-ref --verify --quiet refs/heads/main; then
  git branch -f main origin/main
else
  git branch main origin/main
fi

echo "→ Creating a temporary worktree on main at $WORKTREE_DIR…"
# Worktree add needs the dir to NOT exist yet, so remove the mktemp shell first
rmdir "$WORKTREE_DIR"
git worktree add "$WORKTREE_DIR" main

echo "→ Replacing docs/ on main with the freshly-built docs/…"
# Wipe the old docs/ in the main worktree, then copy the new one over.
rm -rf "$WORKTREE_DIR/docs"
cp -R docs "$WORKTREE_DIR/docs"

# Also keep .nojekyll present on main (needed for GitHub Pages to serve _files with underscore names)
if [[ -f .nojekyll ]] && [[ ! -f "$WORKTREE_DIR/.nojekyll" ]]; then
  cp .nojekyll "$WORKTREE_DIR/.nojekyll"
fi

(
  cd "$WORKTREE_DIR"
  git add -A
  if git diff --cached --quiet; then
    echo "  (docs/ on main already matches; nothing to publish)"
  else
    git commit -m "$MSG (published $(date +%Y-%m-%d))"
    git push origin main
    echo "✓ Published to main → gabriel-uzquiano.github.io/logic/"
  fi
)

# ---- 4. Cleanup ----
echo "→ Removing temporary worktree…"
git worktree remove "$WORKTREE_DIR"

echo "✓ Done. You are still on branch source."
echo "  Give GitHub Pages ~1 minute to redeploy."
