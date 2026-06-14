#!/bin/zsh

set -euo pipefail

usage() {
  cat <<'EOF'
Usage:
  ./publish-appcast-gh-pages.sh \
    [--appcast /absolute/or/relative/path/to/appcast.xml] \
    [--branch gh-pages] \
    [--message "Update appcast for v1.2.3"] \
    [--keep-worktree]

Defaults:
  --appcast build/manual-release/pages/appcast.xml
  --branch gh-pages

What this script does:
  1. Checks out the Pages branch into a temporary git worktree
  2. Copies appcast.xml to the branch root
  3. Commits the change if needed
  4. Pushes the branch to origin
EOF
}

fail() {
  print -u2 -- "$1"
  exit 1
}

require_command() {
  local name="$1"
  if ! command -v "$name" >/dev/null 2>&1; then
    fail "Missing required command: $name"
  fi
}

APPCAST_PATH="build/manual-release/pages/appcast.xml"
BRANCH_NAME="gh-pages"
COMMIT_MESSAGE="Update appcast"
KEEP_WORKTREE=0

while [[ $# -gt 0 ]]; do
  case "$1" in
    --appcast)
      APPCAST_PATH="$2"
      shift 2
      ;;
    --branch)
      BRANCH_NAME="$2"
      shift 2
      ;;
    --message)
      COMMIT_MESSAGE="$2"
      shift 2
      ;;
    --keep-worktree)
      KEEP_WORKTREE=1
      shift
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      fail "Unknown argument: $1"
      ;;
  esac
done

require_command git

SCRIPT_DIR="${0:A:h}"
REPO_ROOT="$SCRIPT_DIR"
APPCAST_ABS="${APPCAST_PATH:A}"

[[ -f "$APPCAST_ABS" ]] || fail "Appcast file not found: $APPCAST_ABS"

git -C "$REPO_ROOT" rev-parse --is-inside-work-tree >/dev/null 2>&1 || fail "Not inside a git repository"
git -C "$REPO_ROOT" remote get-url origin >/dev/null 2>&1 || fail "Git remote 'origin' is not configured"

TEMP_PARENT="$(mktemp -d /tmp/txtmemo-pages.XXXXXX)"
WORKTREE_PATH="$TEMP_PARENT/$BRANCH_NAME"
REMOTE_BRANCH_EXISTS=0

cleanup() {
  if [[ $KEEP_WORKTREE -eq 0 ]]; then
    git -C "$REPO_ROOT" worktree remove --force "$WORKTREE_PATH" >/dev/null 2>&1 || true
    rm -rf "$TEMP_PARENT"
  else
    print -- "Kept worktree at $WORKTREE_PATH"
  fi
}
trap cleanup EXIT

if git -C "$REPO_ROOT" ls-remote --exit-code --heads origin "$BRANCH_NAME" >/dev/null 2>&1; then
  REMOTE_BRANCH_EXISTS=1
fi

if [[ $REMOTE_BRANCH_EXISTS -eq 1 ]]; then
  print -- "==> Checking out existing origin/$BRANCH_NAME into worktree"
  git -C "$REPO_ROOT" fetch origin "$BRANCH_NAME"
  git -C "$REPO_ROOT" worktree add --track -B "$BRANCH_NAME" "$WORKTREE_PATH" "origin/$BRANCH_NAME"
else
  print -- "==> Creating new $BRANCH_NAME worktree"
  git -C "$REPO_ROOT" worktree add -b "$BRANCH_NAME" "$WORKTREE_PATH"
fi

cp "$APPCAST_ABS" "$WORKTREE_PATH/appcast.xml"

if git -C "$WORKTREE_PATH" diff --quiet -- appcast.xml && git -C "$WORKTREE_PATH" diff --cached --quiet -- appcast.xml; then
  print -- "==> No appcast.xml changes to publish"
  exit 0
fi

print -- "==> Committing updated appcast.xml"
git -C "$WORKTREE_PATH" add appcast.xml
git -C "$WORKTREE_PATH" commit -m "$COMMIT_MESSAGE"

print -- "==> Pushing $BRANCH_NAME to origin"
git -C "$WORKTREE_PATH" push -u origin "$BRANCH_NAME"

print -- "Published appcast.xml to origin/$BRANCH_NAME"
